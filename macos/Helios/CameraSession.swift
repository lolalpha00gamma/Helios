import AVFoundation
import AppKit
import CoreImage
import CoreMedia
import Foundation
import QuartzCore

final class CameraSession: NSObject, ObservableObject, @unchecked Sendable {
    @Published var isRunning = false
    @Published var errorMessage: String?
    @Published var deviceName = "—"

    /// Vision-Buffer, optionales Preview, Helligkeit 0…1, Ankunftszeit
    var onFrame: ((CVPixelBuffer, NSImage?, CGFloat, TimeInterval) -> Void)? {
        get {
            handlerLock.lock()
            defer { handlerLock.unlock() }
            return frameHandler
        }
        set {
            handlerLock.lock()
            frameHandler = newValue
            handlerLock.unlock()
        }
    }

    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let cameraQueue = DispatchQueue(label: "helios.camera", qos: .userInteractive)
    private let pump = FramePump()
    private var tap: FrameSink?
    private var lastPreview: TimeInterval = 0
    private let enhancer = FrameEnhancer()
    private let ring = GPUFrameRing()
    private var mirroredFlag = false
    var isMirrored: Bool { mirroredFlag }
    private let handlerLock = NSLock()
    private var frameHandler: ((CVPixelBuffer, NSImage?, CGFloat, TimeInterval) -> Void)?
    let depthTap = DepthCapture()
    var latestDepth: DepthSample? { depthTap.latest }
    var hasDepth: Bool { depthTap.attached }

    func start() {
        DispatchQueue.main.async { self.errorMessage = nil }
        pump.reset()
        cameraQueue.async { [weak self] in
            self?.configureAndRun()
        }
    }

    func stop() {
        cameraQueue.async { [weak self] in
            guard let self else { return }
            self.pump.cancel()
            HeliosCatch({ self.session.stopRunning() }, nil)
            DispatchQueue.main.async { self.isRunning = false }
        }
    }

    private func configureAndRun() {
        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        if session.canSetSessionPreset(.hd1280x720) {
            session.sessionPreset = .hd1280x720
        } else if session.canSetSessionPreset(.high) {
            session.sessionPreset = .high
        }

        guard let device = preferredDevice() else {
            DispatchQueue.main.async { self.errorMessage = "Keine Kamera gefunden." }
            session.commitConfiguration()
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) { session.addInput(input) }
        } catch {
            DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
            session.commitConfiguration()
            return
        }

        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:] as CFDictionary
        ]
        let sink = FrameSink { [weak self] buffer in
            self?.accept(buffer)
        }
        tap = sink
        output.setSampleBufferDelegate(sink, queue: cameraQueue)
        if session.canAddOutput(output) { session.addOutput(output) }
        depthTap.attach(session: session, device: device, queue: cameraQueue)
        HeliosCatch({
            if let conn = self.output.connection(with: .video), conn.isVideoMirroringSupported {
                let front = device.position == .front || device.deviceType == .builtInWideAngleCamera
                conn.isVideoMirrored = front
                self.mirroredFlag = conn.isVideoMirrored
            } else {
                self.mirroredFlag = false
            }
        }, nil)
        session.commitConfiguration()

        configureDevice(device)

        var startErr: NSError?
        _ = HeliosCatch({ self.session.startRunning() }, &startErr)
        if let startErr {
            DispatchQueue.main.async { self.errorMessage = startErr.localizedDescription }
        }
        let name = device.localizedName
        DispatchQueue.main.async {
            self.deviceName = name
            self.isRunning = true
        }
    }

    private func preferredDevice() -> AVCaptureDevice? {
        var types: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera,
            .continuityCamera,
            .external
        ]
        if #available(macOS 14.0, *) {
            types.append(.deskViewCamera)
        }
        let discovered = AVCaptureDevice.DiscoverySession(
            deviceTypes: types,
            mediaType: .video,
            position: .unspecified
        ).devices
        if let builtIn = discovered.first(where: { $0.deviceType == .builtInWideAngleCamera }) {
            return builtIn
        }
        return discovered.first ?? AVCaptureDevice.default(for: .video)
    }

    /// Format + Framerate nur mit Werten aus dem unterstützten Bereich, plus NSException-Fang.
    private func configureDevice(_ device: AVCaptureDevice) {
        var locked = false
        var err: NSError?
        _ = HeliosCatch({
            do {
                try device.lockForConfiguration()
            } catch {
                return
            }
            locked = true
            if let format = Self.bestFormat(on: device) {
                device.activeFormat = format
            }
            self.depthTap.applyActiveFormat(device)
            if let range = device.activeFormat.videoSupportedFrameRateRanges.max(by: {
                $0.maxFrameRate < $1.maxFrameRate
            }) {
                let dur = range.minFrameDuration
                device.activeVideoMinFrameDuration = dur
                device.activeVideoMaxFrameDuration = dur
            }
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
        }, &err)
        if locked {
            HeliosCatch({ device.unlockForConfiguration() }, nil)
        }
        if let err {
            DispatchQueue.main.async { self.errorMessage = err.localizedDescription }
        }
    }

    /// 720p / hoher fps schlägt 1080p — Vision ist der Flaschenhals, nicht die Auflösung.
    /// Formate mit Tiefenkanal gewinnen leicht, damit echte z-Werte ankommen.
    private static func bestFormat(on device: AVCaptureDevice) -> AVCaptureDevice.Format? {
        var best: AVCaptureDevice.Format?
        var bestScore = -1.0
        for format in device.formats {
            let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let w = Double(dims.width)
            let h = Double(dims.height)
            guard w >= 640, h >= 360, w <= 1280, h <= 800 else { continue }
            let fps = format.videoSupportedFrameRateRanges.map(\.maxFrameRate).max() ?? 0
            guard fps >= 24 else { continue }
            let fpsTerm = min(fps, 120)
            let near720 = 1.0 - min(abs(h - 720) / 720, 1)
            let depthBonus = format.supportedDepthDataFormats.isEmpty ? 0.0 : 80.0
            let score = fpsTerm * 12 + near720 * 30 + depthBonus
            if score > bestScore {
                bestScore = score
                best = format
            }
        }
        return best
    }

    private func accept(_ buffer: CMSampleBuffer) {
        guard let pb = CMSampleBufferGetImageBuffer(buffer) else { return }
        let (owned, slot) = ring.copy(pb)
        pump.push(owned, slot: slot, arrived: CACurrentMediaTime(), drop: { [weak self] s in
            self?.ring.release(s)
        }) { [weak self] latest, arrived, doneSlot in
            self?.process(latest, arrived: arrived)
            self?.ring.release(doneSlot)
        }
    }

    private let previewQueue = DispatchQueue(label: "helios.preview", qos: .utility)

    private func process(_ pb: CVPixelBuffer, arrived: TimeInterval) {
        let luma = enhancer.luma(of: pb)
        let vision = enhancer.enhance(pb, luma: luma)
        handlerLock.lock()
        let handler = frameHandler
        handlerLock.unlock()
        handler?(vision, nil, luma, arrived)
        let now = CACurrentMediaTime()
        if now - lastPreview >= 0.12 {
            lastPreview = now
            previewQueue.async { [weak self] in
                guard let img = self?.makePreview(pb) else { return }
                DispatchQueue.main.async { self?.pushPreview(img) }
            }
        }
    }

    private var previewSink: ((NSImage) -> Void)?
    func setPreviewSink(_ sink: @escaping (NSImage) -> Void) { previewSink = sink }
    private func pushPreview(_ img: NSImage) { previewSink?(img) }

    private func makePreview(_ pb: CVPixelBuffer) -> NSImage? {
        let w = CVPixelBufferGetWidth(pb)
        let h = CVPixelBufferGetHeight(pb)
        guard w > 1, h > 1 else { return nil }
        let scale = min(1, 480 / CGFloat(w))
        let tw = max(2, Int((CGFloat(w) * scale).rounded()))
        let th = max(2, Int((CGFloat(h) * scale).rounded()))
        let src = CIImage(cvPixelBuffer: pb)
        let scaled = src.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cg = MetalHub.ci.createCGImage(scaled, from: CGRect(x: 0, y: 0, width: tw, height: th)) else {
            return nil
        }
        return NSImage(cgImage: cg, size: NSSize(width: tw, height: th))
    }
}

/// Behält nur den neuesten Frame — Vision läuft nie hinter der Kamera hinterher.
private final class FramePump: @unchecked Sendable {
    private let queue = DispatchQueue(label: "helios.vision", qos: .userInteractive)
    private let lock = NSLock()
    private var latest: (CVPixelBuffer, TimeInterval, Int)?
    private var scheduled = false
    private var cancelled = false
    private var dropFn: ((Int) -> Void)?

    func push(
        _ pb: CVPixelBuffer,
        slot: Int,
        arrived: TimeInterval,
        drop: @escaping (Int) -> Void,
        process: @escaping (CVPixelBuffer, TimeInterval, Int) -> Void
    ) {
        var dropped: Int?
        lock.lock()
        if cancelled {
            lock.unlock()
            drop(slot)
            return
        }
        if let prev = latest { dropped = prev.2 }
        latest = (pb, arrived, slot)
        dropFn = drop
        let need = !scheduled
        if need { scheduled = true }
        lock.unlock()
        if let dropped { drop(dropped) }
        if need {
            queue.async { self.drain(process) }
        }
    }

    func cancel() {
        lock.lock()
        cancelled = true
        let slot = latest?.2
        latest = nil
        scheduled = false
        let drop = dropFn
        lock.unlock()
        if let slot { drop?(slot) }
    }

    func reset() {
        lock.lock()
        cancelled = false
        let slot = latest?.2
        latest = nil
        scheduled = false
        let drop = dropFn
        lock.unlock()
        if let slot { drop?(slot) }
    }

    private func drain(_ process: @escaping (CVPixelBuffer, TimeInterval, Int) -> Void) {
        while true {
            lock.lock()
            if cancelled {
                scheduled = false
                let slot = latest?.2
                latest = nil
                let drop = dropFn
                lock.unlock()
                if let slot { drop?(slot) }
                return
            }
            let item = latest
            latest = nil
            if item == nil { scheduled = false }
            lock.unlock()
            guard let item else { return }
            process(item.0, item.1, item.2)
        }
    }
}

private final class FrameSink: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let emit: (CMSampleBuffer) -> Void
    init(emit: @escaping (CMSampleBuffer) -> Void) { self.emit = emit }
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        emit(sampleBuffer)
    }
}

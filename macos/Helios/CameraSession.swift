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
    var onFrame: ((CVPixelBuffer, NSImage?, CGFloat, TimeInterval) -> Void)?

    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let cameraQueue = DispatchQueue(label: "helios.camera", qos: .userInteractive)
    private let pump = FramePump()
    private var tap: FrameSink?
    private var lastPreview: TimeInterval = 0
    private let ci = CIContext(options: [
        .useSoftwareRenderer: false,
        .cacheIntermediates: false
    ])
    private let enhancer = FrameEnhancer()

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
        if session.canSetSessionPreset(.hd1920x1080) {
            session.sessionPreset = .hd1920x1080
        } else if session.canSetSessionPreset(.hd1280x720) {
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
        let sink = FrameSink { [weak self] buffer in
            self?.accept(buffer)
        }
        tap = sink
        output.setSampleBufferDelegate(sink, queue: cameraQueue)
        if session.canAddOutput(output) { session.addOutput(output) }
        HeliosCatch({
            if let conn = self.output.connection(with: .video), conn.isVideoMirroringSupported {
                let front = device.position == .front || device.deviceType == .builtInWideAngleCamera
                conn.isVideoMirrored = front
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

    /// 60 fps / 720p schlägt 30 fps / 1080p — Handpose braucht Tempo, kein 4K.
    private static func bestFormat(on device: AVCaptureDevice) -> AVCaptureDevice.Format? {
        var best: AVCaptureDevice.Format?
        var bestScore = -1.0
        for format in device.formats {
            let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let w = Double(dims.width)
            let h = Double(dims.height)
            guard w >= 640, h >= 480, w <= 1920, h <= 1080 else { continue }
            let fps = format.videoSupportedFrameRateRanges.map(\.maxFrameRate).max() ?? 0
            guard fps >= 24 else { continue }
            let fpsTerm = min(fps, 90)
            let resTerm = min(w * h / (1280 * 720), 1.25)
            let score = fpsTerm * 8 + resTerm * 20
            if score > bestScore {
                bestScore = score
                best = format
            }
        }
        return best
    }

    private func accept(_ buffer: CMSampleBuffer) {
        guard let pb = CMSampleBufferGetImageBuffer(buffer) else { return }
        pump.push(pb, arrived: CACurrentMediaTime()) { [weak self] latest, arrived in
            self?.process(latest, arrived: arrived)
        }
    }

    private func process(_ pb: CVPixelBuffer, arrived: TimeInterval) {
        let luma = enhancer.luma(of: pb)
        let vision = enhancer.enhance(pb, luma: luma)
        var preview: NSImage?
        let now = CACurrentMediaTime()
        if now - lastPreview >= 0.05 {
            lastPreview = now
            preview = makePreview(pb)
        }
        onFrame?(vision, preview, luma, arrived)
    }

    private func makePreview(_ pb: CVPixelBuffer) -> NSImage? {
        let w = CVPixelBufferGetWidth(pb)
        let h = CVPixelBufferGetHeight(pb)
        guard w > 1, h > 1 else { return nil }
        let scale = min(1, 480 / CGFloat(w))
        let tw = max(2, Int((CGFloat(w) * scale).rounded()))
        let th = max(2, Int((CGFloat(h) * scale).rounded()))
        let src = CIImage(cvPixelBuffer: pb)
        let scaled = src.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cg = ci.createCGImage(scaled, from: CGRect(x: 0, y: 0, width: tw, height: th)) else {
            return nil
        }
        return NSImage(cgImage: cg, size: NSSize(width: tw, height: th))
    }
}

/// Behält nur den neuesten Frame — Vision läuft nie hinter der Kamera hinterher.
private final class FramePump: @unchecked Sendable {
    private let queue = DispatchQueue(label: "helios.vision", qos: .userInteractive)
    private let lock = NSLock()
    private var latest: (CVPixelBuffer, TimeInterval)?
    private var scheduled = false
    private var cancelled = false

    func push(
        _ pb: CVPixelBuffer,
        arrived: TimeInterval,
        process: @escaping (CVPixelBuffer, TimeInterval) -> Void
    ) {
        lock.lock()
        if cancelled {
            lock.unlock()
            return
        }
        latest = (pb, arrived)
        let need = !scheduled
        if need { scheduled = true }
        lock.unlock()
        if need {
            queue.async { self.drain(process) }
        }
    }

    func cancel() {
        lock.lock()
        cancelled = true
        latest = nil
        scheduled = false
        lock.unlock()
    }

    func reset() {
        lock.lock()
        cancelled = false
        latest = nil
        scheduled = false
        lock.unlock()
    }

    private func drain(_ process: @escaping (CVPixelBuffer, TimeInterval) -> Void) {
        while true {
            lock.lock()
            if cancelled {
                scheduled = false
                lock.unlock()
                return
            }
            let item = latest
            latest = nil
            if item == nil { scheduled = false }
            lock.unlock()
            guard let item else { return }
            process(item.0, item.1)
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

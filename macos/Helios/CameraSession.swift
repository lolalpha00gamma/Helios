import AVFoundation
import AppKit
import CoreImage
import CoreMedia
import Foundation
import ImageIO
import QuartzCore
#if canImport(Darwin)
import Darwin
#endif

enum CameraChoice: String, CaseIterable, Identifiable {
    case auto, builtIn, continuity
    var id: String { rawValue }
    var titleDE: String {
        switch self {
        case .auto: return "Auto (Built-in zuerst)"
        case .builtIn: return "Built-in Front"
        case .continuity: return "Continuity / Desk-View"
        }
    }
}

final class CameraSession: NSObject, ObservableObject, @unchecked Sendable {
    @Published var isRunning = false
    @Published var errorMessage: String?
    @Published var deviceName = "—"
    /// Kein Built-in-Front-Wide — Continuity/Desk-View oder externe Cam.
    @Published var usingFallback = false
    /// Built-in und Continuity/Desk-View gleichzeitig da.
    @Published var dualCamAvailable = false
    /// AVCaptureDevice.uniqueID — Homographie je Kamera.
    @Published var uniqueID = ""
    /// HUD `420f 15–30` / `BGRA 8`.
    @Published var formatChip = ""
    /// Nutzerwahl. Auto = Built-in zuerst.
    var choice: CameraChoice = .auto

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
    private var visionOrientationFlag: CGImagePropertyOrientation = .up
    var visionOrientation: CGImagePropertyOrientation { visionOrientationFlag }
    private let handlerLock = NSLock()
    private var frameHandler: ((CVPixelBuffer, NSImage?, CGFloat, TimeInterval) -> Void)?
    private var exposureUnlockWork: DispatchWorkItem?
    private var activeDevice: AVCaptureDevice?
    private var geometryTick = 0
    private var lastRotationAngle: CGFloat = 0

    func start() {
        DispatchQueue.main.async { self.errorMessage = nil }
        cameraQueue.async { [weak self] in
            self?.configureAndRun()
        }
    }

    func stop() {
        cameraQueue.async { [weak self] in
            guard let self else { return }
            self.pump.cancel()
            HeliosCatch({ self.session.stopRunning() }, nil)
            self.releaseCameraMutex()
            self.activeDevice = nil
            DispatchQueue.main.async {
                self.isRunning = false
                self.usingFallback = false
                self.dualCamAvailable = false
            }
        }
    }

    private func configureAndRun() {
        pump.reset()
        var cfgErr: NSError?
        let began = HeliosCatch({ self.session.beginConfiguration() }, &cfgErr)
        guard began else {
            HeliosCatch({ self.session.commitConfiguration() }, nil)
            DispatchQueue.main.async {
                self.isRunning = false
                if let cfgErr { self.errorMessage = cfgErr.localizedDescription }
            }
            return
        }

        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        func abort(_ msg: String) {
            HeliosCatch({ self.session.commitConfiguration() }, nil)
            DispatchQueue.main.async {
                self.isRunning = false
                self.errorMessage = msg
            }
        }

        guard let device = preferredDevice() else {
            abort("Keine Kamera gefunden.")
            return
        }

        let continuity = Self.isContinuityDevice(device)
        if !GestureMath.sessionPresetClampsContinuity(continuity) {
            if session.canSetSessionPreset(.hd1280x720) {
                session.sessionPreset = .hd1280x720
            } else if session.canSetSessionPreset(.high) {
                session.sessionPreset = .high
            }
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                abort("Kamera-Eingang nicht möglich.")
                return
            }
            session.addInput(input)
        } catch {
            abort(error.localizedDescription)
            return
        }

        output.alwaysDiscardsLateVideoFrames = true
        let sink = FrameSink { [weak self] buffer, angle in
            self?.accept(buffer, angle: angle)
        }
        tap = sink
        output.setSampleBufferDelegate(sink, queue: cameraQueue)
        guard session.canAddOutput(output) else {
            abort("Kamera-Ausgang nicht möglich.")
            return
        }
        session.addOutput(output)
        HeliosCatch({ self.session.commitConfiguration() }, nil)

        configureDevice(device)
        applyNativePixelFormat(output)
        applyCaptureGeometry(device)

        var startErr: NSError?
        let started = HeliosCatch({ self.session.startRunning() }, &startErr)
        applyCaptureGeometry(device)
        applyCenterStage(force: true)
        claimCameraMutex()
        activeDevice = device
        let running = started && startErr == nil && session.isRunning
        let name = device.localizedName
        let id = device.uniqueID
        let fallback = !(device.deviceType == .builtInWideAngleCamera && (device.position == .front || device.position == .unspecified))
        let dual = Self.hasBuiltInAndContinuity()
        DispatchQueue.main.async {
            self.deviceName = name
            self.uniqueID = id
            self.isRunning = running
            self.usingFallback = fallback
            self.dualCamAvailable = dual
            if !running {
                self.errorMessage = startErr?.localizedDescription ?? "Kamera startet nicht."
            }
        }
    }

    private func applyCaptureGeometry(_ device: AVCaptureDevice) {
        HeliosCatch({
            if let conn = self.output.connection(with: .video) {
                if conn.isVideoMirroringSupported {
                    let desk: Bool
                    if #available(macOS 14.0, *) {
                        desk = device.deviceType == .deskViewCamera
                    } else {
                        desk = false
                    }
                    let front = GestureMath.mirrorAsFront(
                        positionFront: device.position == .front,
                        unspecified: device.position == .unspecified,
                        deskView: desk
                    )
                    conn.isVideoMirrored = front
                    self.mirroredFlag = conn.isVideoMirrored
                } else {
                    self.mirroredFlag = false
                }
                // Kein RotationCoordinator / landscapeRight: physisches Drehen
                // macht Latenz, vertauscht Palm-Achsen, Faust/Cursor tot.
                let angle = GestureMath.videoRotationAngleFallback()
                if !GestureMath.physicalCaptureRotation(), conn.isVideoRotationAngleSupported(angle) {
                    conn.videoRotationAngle = angle
                }
                #if os(iOS) || os(tvOS)
                if GestureMath.videoStabilizationOff(Self.isContinuityDevice(device)),
                   conn.isVideoStabilizationSupported
                {
                    conn.preferredVideoStabilizationMode = .off
                }
                #endif
            } else {
                self.mirroredFlag = false
            }
        }, nil)
    }

    private func preferredDevice() -> AVCaptureDevice? {
        let discovered = Self.discoveredDevices()
        let front = discovered.first(where: {
            $0.deviceType == .builtInWideAngleCamera && $0.position == .front
        })
        let builtIn = discovered.first(where: { $0.deviceType == .builtInWideAngleCamera })
        let extra = discovered.first(where: {
            $0.deviceType == .continuityCamera || $0.deviceType == .deskViewCamera
        })
        switch choice {
        case .continuity:
            return extra ?? front ?? builtIn ?? discovered.first ?? AVCaptureDevice.default(for: .video)
        case .builtIn:
            return front ?? builtIn ?? extra ?? discovered.first ?? AVCaptureDevice.default(for: .video)
        case .auto:
            if let front { return front }
            if let builtIn { return builtIn }
            return extra ?? discovered.first ?? AVCaptureDevice.default(for: .video)
        }
    }

    private func cameraMutexURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(GestureMath.cameraMutexName())
    }

    private func claimCameraMutex() {
        let url = cameraMutexURL()
        let holder: String?
        if let text = try? String(contentsOf: url, encoding: .utf8) {
            let pid = GestureMath.cameraMutexPid(text)
            let live = pid.map { p in p > 0 && (kill(p, 0) == 0 || errno == EPERM) }
            holder = GestureMath.cameraMutexParse(
                text, now: Date().timeIntervalSince1970, pidLive: live
            )
        } else {
            holder = nil
        }
        guard GestureMath.cameraMutexClaimWrites(
            holder: holder,
            owner: GestureMath.cameraMutexOwnerHelios()
        ) else { return }
        let line = GestureMath.cameraMutexLine(
            owner: GestureMath.cameraMutexOwnerHelios(),
            pid: ProcessInfo.processInfo.processIdentifier,
            now: Date().timeIntervalSince1970
        )
        try? line.write(to: url, atomically: true, encoding: .utf8)
    }

    private func releaseCameraMutex() {
        let url = cameraMutexURL()
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return }
        if GestureMath.cameraMutexParse(text, now: Date().timeIntervalSince1970, stale: 9_999) == GestureMath.cameraMutexOwnerHelios() {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static func discoveredDevices() -> [AVCaptureDevice] {
        var types: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera,
            .continuityCamera,
            .external
        ]
        if #available(macOS 14.0, *) {
            types.append(.deskViewCamera)
        }
        return AVCaptureDevice.DiscoverySession(
            deviceTypes: types,
            mediaType: .video,
            position: .unspecified
        ).devices
    }

    static func hasBuiltInAndContinuity() -> Bool {
        let devices = discoveredDevices()
        let builtIn = devices.contains { $0.deviceType == .builtInWideAngleCamera }
        let extra = devices.contains { isContinuityDevice($0) }
        return builtIn && extra
    }

    static func isContinuityDevice(_ device: AVCaptureDevice) -> Bool {
        if device.deviceType == .continuityCamera { return true }
        if #available(macOS 14.0, *) {
            return device.deviceType == .deskViewCamera
        }
        return false
    }

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
            if GestureMath.centerStageOff {
                self.applyCenterStage(force: true)
            }
            if let format = Self.bestFormat(on: device) {
                device.activeFormat = format
            }
            if GestureMath.centerStageOff {
                self.applyCenterStage(force: true)
                if let format = Self.bestFormat(on: device) {
                    device.activeFormat = format
                }
            }
            if let range = device.activeFormat.videoSupportedFrameRateRanges.max(by: {
                $0.maxFrameRate < $1.maxFrameRate
            }) {
                let continuity = Self.isContinuityDevice(device)
                let hi = GestureMath.lockFrameRate(range.maxFrameRate, continuity: continuity)
                let lo = GestureMath.lockFrameLo(range.maxFrameRate, rangeMin: range.minFrameRate, continuity: continuity)
                var minDur = CMTimeMake(value: 1, timescale: CMTimeScale(max(1, Int(hi.rounded()))))
                var maxDur = CMTimeMake(value: 1, timescale: CMTimeScale(max(1, Int(lo.rounded()))))
                if minDur < range.minFrameDuration { minDur = range.minFrameDuration }
                if maxDur > range.maxFrameDuration { maxDur = range.maxFrameDuration }
                if minDur > maxDur { minDur = maxDur }
                device.activeVideoMinFrameDuration = minDur
                device.activeVideoMaxFrameDuration = maxDur
                let osType = CMFormatDescriptionGetMediaSubType(device.activeFormat.formatDescription)
                let usb = GestureMath.continuityIsUSB(
                    device.uniqueID,
                    transportUSB: GestureMath.continuityTransportIsUSB(device.transportType),
                    modelID: device.modelID,
                    localizedName: device.localizedName
                )
                let chip = GestureMath.formatTransportChip(
                    band: GestureMath.formatBandChip(osType: osType, lo: lo, hi: hi),
                    continuity: continuity,
                    usb: usb
                )
                self.lastFormatBand = chip
                DispatchQueue.main.async { self.formatChip = chip }
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

    /// Faust-Scharf: AE 0,8 s locken, sonst Luma-Sprung = Warp.
    func lockExposure(seconds: TimeInterval) {
        cameraQueue.async { [weak self] in
            guard let self else { return }
            let device = self.session.inputs.compactMap { ($0 as? AVCaptureDeviceInput)?.device }.first
            guard let device, device.isExposureModeSupported(.locked) else { return }
            HeliosCatch({
                do { try device.lockForConfiguration() } catch { return }
                device.exposureMode = .locked
                device.unlockForConfiguration()
            }, nil)
            self.exposureUnlockWork?.cancel()
            let work = DispatchWorkItem { [weak self] in
                self?.unlockExposure()
            }
            self.exposureUnlockWork = work
            self.cameraQueue.asyncAfter(deadline: .now() + max(0.05, seconds), execute: work)
        }
    }

    func unlockExposure() {
        cameraQueue.async { [weak self] in
            guard let self else { return }
            let device = self.session.inputs.compactMap { ($0 as? AVCaptureDeviceInput)?.device }.first
            guard let device, device.isExposureModeSupported(.continuousAutoExposure) else { return }
            HeliosCatch({
                do { try device.lockForConfiguration() } catch { return }
                device.exposureMode = .continuousAutoExposure
                device.unlockForConfiguration()
            }, nil)
        }
    }

    /// Continuity steckt bei 8 fps: Format neu wählen, Session bleibt.
    func reselectFormat() {
        cameraQueue.async { [weak self] in
            guard let self else { return }
            let device = self.session.inputs.compactMap { ($0 as? AVCaptureDeviceInput)?.device }.first
            guard let device else { return }
            self.applyCenterStage(force: true)
            self.configureDevice(device)
            self.applyCaptureGeometry(device)
        }
    }

    /// macOS schaltet Center Stage nach Sleep/Clamshell wieder an.
    /// Default-Control-Mode ist `.user` — der Setter wirft dann eine NSException
    /// (`+[AVCaptureDevice_Tundra _setCenterStageEnabled:forcedSet:]`) und tötet Helios.
    func applyCenterStage(force: Bool = false) {
        guard GestureMath.centerStageOff else { return }
        if #available(macOS 12.3, *) {
            _ = HeliosCatch({
                let modeRaw = Int(AVCaptureDevice.centerStageControlMode.rawValue)
                if GestureMath.centerStageNeedsAppControl(currentModeRaw: modeRaw) {
                    AVCaptureDevice.centerStageControlMode = .app
                }
                if force {
                    AVCaptureDevice.isCenterStageEnabled = false
                    return
                }
                let enabled = AVCaptureDevice.isCenterStageEnabled
                if GestureMath.centerStageNeedsReassert(enabled: enabled)
                    || GestureMath.reconnectCenterStageOff(continuity: self.usingFallback, enabled: enabled)
                {
                    AVCaptureDevice.isCenterStageEnabled = false
                }
            }, nil)
        }
    }

    private static func bestFormat(on device: AVCaptureDevice) -> AVCaptureDevice.Format? {
        var best: AVCaptureDevice.Format?
        var bestScore = -1.0
        var bestMin = 0.0
        for format in device.formats {
            let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let ranges = format.videoSupportedFrameRateRanges
            let fps = ranges.map(\.maxFrameRate).max() ?? 0
            let minFps = ranges.map(\.minFrameRate).max() ?? 0
            let osType = CMFormatDescriptionGetMediaSubType(format.formatDescription)
            let s = GestureMath.formatScore(width: Double(dims.width), height: Double(dims.height), fps: fps)
                + GestureMath.formatPixelBonus(osType: osType, fps: fps)
            if GestureMath.formatPrefers(score: s, minFps: minFps, otherScore: bestScore, otherMinFps: bestMin) {
                bestScore = s
                bestMin = minFps
                best = format
            }
        }
        return best
    }

    /// Continuity 15–30 nur als 420f. 32BGRA erzwingt oft 8 fps + Software-Konvert.
    /// GPUFrameRing hält 420f/420v nativ — Enhance skaliert nur bei Nacht.
    /// Swift-Overlay: `availableVideoPixelFormatTypes` ([OSType]), nicht das ObjC-CV-Infix.
    private func applyNativePixelFormat(_ videoOut: AVCaptureVideoDataOutput) {
        let preferred: [OSType] = [
            kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
            kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            kCVPixelFormatType_422YpCbCr8,
            kCVPixelFormatType_32BGRA,
        ]
        let types = videoOut.availableVideoPixelFormatTypes
        guard let fmt = preferred.first(where: { types.contains($0) }) ?? types.first else { return }
        videoOut.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: fmt,
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:] as CFDictionary
        ]
    }

    private var lastCopyMs: Double = 0
    private var lastFormatBand = ""
    private var lastPushedFormatChip = ""
    private var stealDrops = 0

    private func accept(_ buffer: CMSampleBuffer, angle: CGFloat) {
        lastRotationAngle = angle
        guard let pb = CMSampleBufferGetImageBuffer(buffer) else { return }
        let t0 = CACurrentMediaTime()
        let (owned, slot) = ring.copy(pb)
        lastCopyMs = (CACurrentMediaTime() - t0) * 1000
        let dropped = GestureMath.ringSlotStealDrops(slot)
        stealDrops = GestureMath.ringSlotStealCount(prev: stealDrops, dropped: dropped)
        if dropped {
            pushFormatChip()
            return
        }
        pump.push(owned, slot: slot, arrived: CACurrentMediaTime(), drop: { [weak self] s in
            self?.ring.release(s)
        }) { [weak self] latest, arrived, doneSlot in
            self?.process(latest, arrived: arrived)
            self?.ring.release(doneSlot)
        }
    }

    private let previewQueue = DispatchQueue(label: "helios.preview", qos: .utility)

    private func pushFormatChip() {
        let chip = GestureMath.formatStealChip(band: lastFormatBand, drops: stealDrops)
        if chip != lastPushedFormatChip {
            lastPushedFormatChip = chip
            DispatchQueue.main.async { self.formatChip = chip }
        }
    }

    private func process(_ pb: CVPixelBuffer, arrived: TimeInterval) {
        geometryTick += 1
        if geometryTick % 8 == 0 {
            claimCameraMutex()
        }
        if geometryTick % 32 == 0, let device = activeDevice {
            applyCaptureGeometry(device)
            applyCenterStage(force: false)
        }
        let applied = GestureMath.visionRotationApplied(lastRotationAngle)
        let orientRaw = GestureMath.visionOrientationLive(angle: lastRotationAngle, applied: applied)
        visionOrientationFlag = CGImagePropertyOrientation(rawValue: orientRaw) ?? .up
        let luma = enhancer.luma(of: pb)
        let osType = CVPixelBufferGetPixelFormatType(pb)
        let converts = GestureMath.ringCopyConverts(osType: osType)
        let vision = GestureMath.enhanceSkipsCopy(copyMs: lastCopyMs, converts: converts) ? pb : enhancer.enhance(pb, luma: luma)
        let chip = GestureMath.formatStealChip(
            band: GestureMath.formatCopyChip(band: lastFormatBand, copyMs: lastCopyMs, converts: converts),
            drops: stealDrops
        )
        if chip != lastPushedFormatChip {
            lastPushedFormatChip = chip
            DispatchQueue.main.async { self.formatChip = chip }
        }
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
        let orientRaw = GestureMath.visionOrientationLive(
            angle: lastRotationAngle,
            applied: GestureMath.visionRotationApplied(lastRotationAngle)
        )
        let sized = GestureMath.orientedPixelSize(width: w, height: h, orientationRaw: orientRaw)
        let scale = min(1, 480 / CGFloat(sized.width))
        let tw = max(2, Int((CGFloat(sized.width) * scale).rounded()))
        let th = max(2, Int((CGFloat(sized.height) * scale).rounded()))
        var src = CIImage(cvPixelBuffer: pb)
        if let orient = CGImagePropertyOrientation(rawValue: orientRaw), orient != .up {
            src = src.oriented(orient)
        }
        let scaled = src.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cg = MetalHub.ci.createCGImage(scaled, from: CGRect(x: 0, y: 0, width: tw, height: th)) else {
            return nil
        }
        return NSImage(cgImage: cg, size: NSSize(width: tw, height: th))
    }
}

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
    let emit: (CMSampleBuffer, CGFloat) -> Void
    init(emit: @escaping (CMSampleBuffer, CGFloat) -> Void) { self.emit = emit }
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        emit(sampleBuffer, connection.videoRotationAngle)
    }
}

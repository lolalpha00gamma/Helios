import AVFoundation
import AppKit
import CoreImage
import CoreMedia
import Foundation
import ImageIO
import QuartzCore

struct CameraChoice: Identifiable, Hashable {
    var id: String { uniqueID }
    var uniqueID: String
    var name: String
    var kindDE: String
    var hasDepth: Bool
    var role: CameraRole
}

final class CameraSession: NSObject, ObservableObject, @unchecked Sendable {
    @Published var isRunning = false
    @Published var errorMessage: String?
    @Published var deviceName = "—"
    @Published var devices: [CameraChoice] = []
    @Published var selectedID = ""
    @Published var coverID = ""
    @Published var coverName = "—"
    @Published var coverRunning = false
    @Published var coverError: String?
    @Published var pair: CameraPair = .single

    private var preferredID: String = UserDefaults.standard.string(forKey: "helios.cameraID") ?? ""
    private var preferredCoverID: String = UserDefaults.standard.string(forKey: "helios.coverID") ?? ""
    let coverPipe = CoverCapture()

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
    private let handlerLock = NSLock()
    private var mirroredFlag = false
    var isMirrored: Bool {
        handlerLock.lock()
        defer { handlerLock.unlock() }
        return mirroredFlag
    }
    private func setMirrored(_ v: Bool) {
        handlerLock.lock()
        mirroredFlag = v
        handlerLock.unlock()
    }
    private var visionOrientationFlag: CGImagePropertyOrientation = .up
    var visionOrientation: CGImagePropertyOrientation {
        handlerLock.lock()
        defer { handlerLock.unlock() }
        return visionOrientationFlag
    }
    private func setVisionOrientation(_ v: CGImagePropertyOrientation) {
        handlerLock.lock()
        visionOrientationFlag = v
        handlerLock.unlock()
    }
    private var frameHandler: ((CVPixelBuffer, NSImage?, CGFloat, TimeInterval) -> Void)?
    let depthTap = DepthCapture()
    var latestDepth: DepthSample? { depthTap.latest }
    var hasDepth: Bool { depthTap.attached }
    private var keepAlive: NSObjectProtocol?

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
            self.coverPipe.stop()
            self.releaseKeepAlive()
            DispatchQueue.main.async {
                self.isRunning = false
                self.coverRunning = false
            }
        }
    }

    func selectDevice(_ id: String) {
        UserDefaults.standard.set(id, forKey: "helios.cameraID")
        cameraQueue.async { [weak self] in
            guard let self else { return }
            self.preferredID = id
            self.preferredCoverID = ""
            self.coverPipe.stop()
            DispatchQueue.main.async {
                self.coverID = ""
                self.coverRunning = false
                self.pair = .single
            }
            if self.session.isRunning {
                self.pump.cancel()
                HeliosCatch({ self.session.stopRunning() }, nil)
                self.pump.reset()
                self.configureAndRun()
            }
        }
    }

    func preparePair(_ pair: CameraPair, devices: [CameraChoice]) {
        self.pair = pair
        if pair == .single {
            preferredCoverID = ""
            return
        }
        let mac = Self.pick(devices, role: .mac)?.id
        let phone = Self.pick(devices, role: .phone, preferDesk: pair == .macPhone)?.id
        let osmo = Self.pick(devices, role: .osmo)?.id
        if let ids = CameraRig.resolve(pair: pair, mac: mac, phone: phone, osmo: osmo) {
            preferredID = ids.lead
            preferredCoverID = ids.cover ?? ""
            UserDefaults.standard.set(ids.lead, forKey: "helios.cameraID")
            UserDefaults.standard.set(ids.cover ?? "", forKey: "helios.coverID")
        }
    }

    func selectPair(_ pair: CameraPair, devices: [CameraChoice], fallbackLead: String) {
        UserDefaults.standard.set(pair.rawValue, forKey: "helios.cameraPair")
        let mac = Self.pick(devices, role: .mac)?.id
        let phone = Self.pick(devices, role: .phone, preferDesk: pair == .macPhone)?.id
        let osmo = Self.pick(devices, role: .osmo)?.id
        cameraQueue.async { [weak self] in
            guard let self else { return }
            if pair == .single {
                self.preferredCoverID = ""
                UserDefaults.standard.set("", forKey: "helios.coverID")
                self.coverPipe.stop()
                DispatchQueue.main.async {
                    self.pair = .single
                    self.coverID = ""
                    self.coverRunning = false
                    self.coverError = nil
                }
                if self.session.isRunning {
                    self.pump.cancel()
                    HeliosCatch({ self.session.stopRunning() }, nil)
                    self.pump.reset()
                    self.configureAndRun()
                }
                return
            }
            guard let ids = CameraRig.resolve(pair: pair, mac: mac, phone: phone, osmo: osmo) else {
                DispatchQueue.main.async {
                    self.pair = pair
                    self.coverError = "Paar unvollständig — fehlende Kamera anschließen (iPhone Kontinuität / Osmo Webcam)."
                    self.coverRunning = false
                }
                return
            }
            self.preferredID = ids.lead
            self.preferredCoverID = ids.cover ?? ""
            UserDefaults.standard.set(ids.lead, forKey: "helios.cameraID")
            UserDefaults.standard.set(ids.cover ?? "", forKey: "helios.coverID")
            DispatchQueue.main.async {
                self.pair = pair
                self.coverError = nil
            }
            if self.session.isRunning {
                self.pump.cancel()
                HeliosCatch({ self.session.stopRunning() }, nil)
                self.coverPipe.stop()
                self.pump.reset()
                self.configureAndRun()
            }
        }
        _ = fallbackLead
    }

    func assign(lead: String, cover: String) {
        cameraQueue.async { [weak self] in
            guard let self else { return }
            self.preferredID = lead
            self.preferredCoverID = cover == lead ? "" : cover
            UserDefaults.standard.set(lead, forKey: "helios.cameraID")
            UserDefaults.standard.set(self.preferredCoverID, forKey: "helios.coverID")
            if self.session.isRunning {
                self.pump.cancel()
                HeliosCatch({ self.session.stopRunning() }, nil)
                self.coverPipe.stop()
                self.pump.reset()
                self.configureAndRun()
            } else if !self.preferredCoverID.isEmpty {
                self.startCoverIfNeeded()
            }
        }
    }

    static func discover() -> [CameraChoice] {
        var types: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera,
            .continuityCamera,
            .external
        ]
        if #available(macOS 14.0, *) {
            types.append(.deskViewCamera)
        }
        let found = AVCaptureDevice.DiscoverySession(
            deviceTypes: types,
            mediaType: .video,
            position: .unspecified
        ).devices
        var seen = Set<String>()
        var out: [CameraChoice] = []
        for d in found {
            if seen.contains(d.uniqueID) { continue }
            seen.insert(d.uniqueID)
            out.append(CameraChoice(
                uniqueID: d.uniqueID,
                name: d.localizedName,
                kindDE: kindDE(d),
                hasDepth: false,
                role: role(d)
            ))
        }
        return out
    }

    private static func kindDE(_ d: AVCaptureDevice) -> String {
        let n = d.localizedName.lowercased()
        if n.contains("osmo") || n.contains("dji") {
            return "Osmo / DJI (USB-Webcam)"
        }
        if #available(macOS 14.0, *), d.deviceType == .deskViewCamera {
            return "Desk View — iPhone von oben"
        }
        switch d.deviceType {
        case .builtInWideAngleCamera: return "Mac-Kamera"
        case .continuityCamera: return "iPhone (Kontinuität)"
        case .external: return "Extern (USB / Osmo)"
        default: return "Kamera"
        }
    }

    static func role(_ d: AVCaptureDevice) -> CameraRole {
        let n = d.localizedName.lowercased()
        if n.contains("osmo") || n.contains("dji") { return .osmo }
        if n.contains("iphone") || n.contains("continuity") { return .phone }
        if #available(macOS 14.0, *), d.deviceType == .deskViewCamera {
            return .phone
        }
        switch d.deviceType {
        case .builtInWideAngleCamera: return .mac
        case .continuityCamera: return .phone
        case .external: return .osmo
        default: return .mac
        }
    }

    static func pick(_ devices: [CameraChoice], role: CameraRole, preferDesk: Bool = false) -> CameraChoice? {
        let xs = devices.filter { $0.role == role }
        if role == .phone {
            if preferDesk, let d = xs.first(where: { $0.kindDE.contains("Desk") }) { return d }
            if let c = xs.first(where: { $0.kindDE.contains("Kontinuität") }) { return c }
        }
        if role == .osmo {
            if let named = xs.first(where: {
                $0.name.localizedCaseInsensitiveContains("osmo")
                    || $0.name.localizedCaseInsensitiveContains("dji")
            }) { return named }
            if let x = xs.first { return x }
            return devices.first { $0.kindDE.contains("Extern") || $0.kindDE.contains("Osmo") }
        }
        return xs.first
    }

    static func shouldMirror(_ d: AVCaptureDevice) -> Bool {
        if d.deviceType == .external { return false }
        if #available(macOS 14.0, *), d.deviceType == .deskViewCamera { return false }
        if d.deviceType == .continuityCamera {
            return d.position != .back
        }
        return d.position == .front || d.deviceType == .builtInWideAngleCamera
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
                conn.isVideoMirrored = Self.shouldMirror(device)
                self.setMirrored(conn.isVideoMirrored)
            } else {
                self.setMirrored(false)
            }
        }, nil)
        session.commitConfiguration()

        configureDevice(device)
        applyCaptureGeometry()

        var startErr: NSError?
        _ = HeliosCatch({ self.session.startRunning() }, &startErr)
        applyCaptureGeometry()
        if let startErr {
            DispatchQueue.main.async { self.errorMessage = startErr.localizedDescription }
        }
        let name = device.localizedName
        let list = Self.discover()
        let depth = depthTap.attached
        DispatchQueue.main.async {
            self.deviceName = name
            self.selectedID = device.uniqueID
            self.devices = list
            self.isRunning = true
            if depth {
                self.deviceName = name + " · Tiefe"
            }
        }
        retainKeepAlive()
        startCoverIfNeeded()
    }

    private func startCoverIfNeeded() {
        coverPipe.stop()
        guard !preferredCoverID.isEmpty, preferredCoverID != preferredID else {
            DispatchQueue.main.async {
                self.coverID = ""
                self.coverName = "—"
                self.coverRunning = false
            }
            return
        }
        let types: [AVCaptureDevice.DeviceType] = {
            var t: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera, .continuityCamera, .external]
            if #available(macOS 14.0, *) { t.append(.deskViewCamera) }
            return t
        }()
        let found = AVCaptureDevice.DiscoverySession(
            deviceTypes: types,
            mediaType: .video,
            position: .unspecified
        ).devices
        guard let device = found.first(where: { $0.uniqueID == preferredCoverID }) else {
            DispatchQueue.main.async {
                self.coverError = "Zweite Kamera nicht gefunden."
                self.coverRunning = false
            }
            return
        }
        if let err = coverPipe.start(device: device) {
            DispatchQueue.main.async {
                self.coverError = err
                self.coverRunning = false
                self.coverID = device.uniqueID
                self.coverName = device.localizedName
            }
            return
        }
        let cname = device.localizedName
        let cid = device.uniqueID
        DispatchQueue.main.async {
            self.coverID = cid
            self.coverName = cname
            self.coverRunning = true
            self.coverError = nil
        }
    }

    private func retainKeepAlive() {
        if keepAlive != nil { return }
        keepAlive = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled],
            reason: "Helios-Kamera liest Gesten im Hintergrund"
        )
    }

    private func releaseKeepAlive() {
        if let a = keepAlive {
            ProcessInfo.processInfo.endActivity(a)
            keepAlive = nil
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
        if !preferredID.isEmpty, let chosen = discovered.first(where: { $0.uniqueID == preferredID }) {
            return chosen
        }
        if let builtIn = discovered.first(where: { $0.deviceType == .builtInWideAngleCamera }) {
            return builtIn
        }
        return discovered.first ?? AVCaptureDevice.default(for: .video)
    }

    /// Nach dem Format: `videoRotationAngle` statt deprecated `videoOrientation`.
    private func applyCaptureGeometry() {
        HeliosCatch({
            if let conn = self.output.connection(with: .video) {
                self.setVisionOrientation(Self.visionOrientation(from: conn))
            } else {
                self.setVisionOrientation(.up)
            }
        }, nil)
    }

    private static func visionOrientation(from conn: AVCaptureConnection) -> CGImagePropertyOrientation {
        if #available(macOS 14.0, *) {
            let angle = conn.videoRotationAngle
            let wrapped = Int(((angle.truncatingRemainder(dividingBy: 360)) + 360)
                .truncatingRemainder(dividingBy: 360).rounded())
            switch wrapped {
            case 90: return .right
            case 180: return .down
            case 270: return .left
            default: return .up
            }
        }
        return .up
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
    /// Tiefenformate gibt es auf dem Mac nicht (`AVCaptureDepthDataOutput` ist iOS).
    fileprivate static func bestFormat(on device: AVCaptureDevice) -> AVCaptureDevice.Format? {
        var best: AVCaptureDevice.Format?
        var bestScore = -1.0
        for format in device.formats {
            let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let w = Double(dims.width)
            let h = Double(dims.height)
            guard w >= 640, h >= 360, w <= 1920, h <= 1088 else { continue }
            let fps = format.videoSupportedFrameRateRanges.map(\.maxFrameRate).max() ?? 0
            guard fps >= 15 else { continue }
            let fpsTerm = min(fps, 120)
            let near720 = 1.0 - min(abs(h - 720) / 720, 1)
            let score = fpsTerm * 12 + near720 * 30
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

/// Zweite AVCaptureSession — anderer Blickwinkel. Vision gedrosselt, kein Depth.
final class CoverCapture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    var onBuffer: ((CVPixelBuffer, TimeInterval, Bool, CGImagePropertyOrientation) -> Void)?
    var onPreview: ((NSImage) -> Void)?
    private(set) var isMirrored = false
    private(set) var visionOrientation: CGImagePropertyOrientation = .up

    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "helios.cover", qos: .userInitiated)
    private var last: TimeInterval = 0
    private var lastPreview: TimeInterval = 0

    func start(device: AVCaptureDevice) -> String? {
        stop()
        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        if session.canSetSessionPreset(.hd1280x720) {
            session.sessionPreset = .hd1280x720
        } else if session.canSetSessionPreset(.high) {
            session.sessionPreset = .high
        }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                session.commitConfiguration()
                return "Zweite Kamera blockiert (Continuity oft exklusiv zur Mac-Kamera). Osmo: Webcam-Modus am Gerät, USB-C, in der Konsole als Cover wählen."
            }
            session.addInput(input)
        } catch {
            session.commitConfiguration()
            return error.localizedDescription
        }
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: queue)
        if session.canAddOutput(output) { session.addOutput(output) }
        HeliosCatch({
            if let conn = self.output.connection(with: .video), conn.isVideoMirroringSupported {
                conn.isVideoMirrored = CameraSession.shouldMirror(device)
                self.isMirrored = conn.isVideoMirrored
            } else {
                self.isMirrored = false
            }
        }, nil)
        if #available(macOS 14.0, *), let conn = output.connection(with: .video) {
            let angle = conn.videoRotationAngle
            let wrapped = Int(((angle.truncatingRemainder(dividingBy: 360)) + 360)
                .truncatingRemainder(dividingBy: 360).rounded())
            switch wrapped {
            case 90: visionOrientation = .right
            case 180: visionOrientation = .down
            case 270: visionOrientation = .left
            default: visionOrientation = .up
            }
        } else {
            visionOrientation = .up
        }
        session.commitConfiguration()
        Self.tuneDevice(device)
        var err: NSError?
        _ = HeliosCatch({ self.session.startRunning() }, &err)
        if let err { return err.localizedDescription }
        if !session.isRunning {
            return "Zweite Session läuft nicht. Osmo: Webcam-Modus, USB-C. Continuity blockt oft die Mac-Kamera."
        }
        lastPreview = 0
        return nil
    }

    private static func tuneDevice(_ device: AVCaptureDevice) {
        var locked = false
        HeliosCatch({
            do { try device.lockForConfiguration() } catch { return }
            locked = true
            if let format = CameraSession.bestFormat(on: device) {
                device.activeFormat = format
            }
            if let range = device.activeFormat.videoSupportedFrameRateRanges.max(by: {
                $0.maxFrameRate < $1.maxFrameRate
            }) {
                device.activeVideoMinFrameDuration = range.minFrameDuration
                device.activeVideoMaxFrameDuration = range.minFrameDuration
            }
        }, nil)
        if locked {
            HeliosCatch({ device.unlockForConfiguration() }, nil)
        }
    }

    func stop() {
        HeliosCatch({ self.session.stopRunning() }, nil)
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let now = CACurrentMediaTime()
        guard now - last >= 0.05 else { return }
        last = now
        guard let pb = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        onBuffer?(pb, now, isMirrored, visionOrientation)
        if lastPreview == 0 || now - lastPreview >= 0.12 {
            lastPreview = now
            if let img = Self.preview(pb) {
                DispatchQueue.main.async { self.onPreview?(img) }
            }
        }
    }

    private static func preview(_ pb: CVPixelBuffer) -> NSImage? {
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

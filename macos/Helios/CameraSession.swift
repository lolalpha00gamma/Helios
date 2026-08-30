import AVFoundation
import AppKit
import CoreImage
import CoreMedia
import Foundation
import QuartzCore

final class CameraSession: NSObject, ObservableObject, @unchecked Sendable {
    @Published var isRunning = false
    @Published var errorMessage: String?
    @Published var preview: NSImage?
    @Published var deviceName = "—"
    @Published var luma: CGFloat = 1

    /// Vision-Buffer, optionales Preview (Original), Helligkeit 0…1
    var onFrame: ((CVPixelBuffer, NSImage?, CGFloat) -> Void)?

    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "helios.camera", qos: .userInteractive)
    private var tap: FrameSink?
    private var lastPreview: TimeInterval = 0
    private let ci = CIContext(options: [.useSoftwareRenderer: false])
    private let enhancer = FrameEnhancer()

    func start() {
        DispatchQueue.main.async { self.errorMessage = nil }
        queue.async { [weak self] in
            self?.configureAndRun()
        }
    }

    func stop() {
        queue.async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async { self?.isRunning = false }
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
        lockDevice(device)

        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        let sink = FrameSink { [weak self] buffer in
            self?.handle(buffer)
        }
        tap = sink
        output.setSampleBufferDelegate(sink, queue: queue)
        if session.canAddOutput(output) { session.addOutput(output) }
        HeliosCatch({
            if let conn = self.output.connection(with: .video), conn.isVideoMirroringSupported {
                let front = device.position == .front || device.deviceType == .builtInWideAngleCamera
                conn.isVideoMirrored = front
            }
        }, nil)
        session.commitConfiguration()
        var startErr: NSError?
        _ = HeliosCatch({
            self.session.startRunning()
        }, &startErr)
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

    /// macOS 27 DAL wirft NSException bei ungültiger Framerate — nicht setzen, Default nutzen.
    private func lockDevice(_ device: AVCaptureDevice) {
        var err: NSError?
        _ = HeliosCatch({
            do {
                try device.lockForConfiguration()
            } catch {
                return
            }
            defer { device.unlockForConfiguration() }
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
        if let err {
            DispatchQueue.main.async { self.errorMessage = err.localizedDescription }
        }
    }

    private func handle(_ buffer: CMSampleBuffer) {
        guard let pb = CMSampleBufferGetImageBuffer(buffer) else { return }
        let luma = enhancer.luma(of: pb)
        let vision = enhancer.enhance(pb, luma: luma)

        var preview: NSImage?
        let now = CACurrentMediaTime()
        if now - lastPreview >= 0.033 {
            lastPreview = now
            preview = makePreview(pb)
        }
        onFrame?(vision, preview, luma)
    }

    private func makePreview(_ pb: CVPixelBuffer) -> NSImage? {
        let ciImage = CIImage(cvPixelBuffer: pb)
        let w = CVPixelBufferGetWidth(pb)
        let h = CVPixelBufferGetHeight(pb)
        guard let cg = ci.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: w, height: h)) else {
            return nil
        }
        return NSImage(cgImage: cg, size: NSSize(width: w, height: h))
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

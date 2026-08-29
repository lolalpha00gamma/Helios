import AVFoundation
import AppKit
import CoreImage
import CoreMedia
import Foundation
import QuartzCore

final class CameraSession: NSObject, ObservableObject {
    @Published var isRunning = false
    @Published var errorMessage: String?
    @Published var preview: NSImage?
    @Published var deviceName = "—"

    var onBuffer: ((CMSampleBuffer) -> Void)?

    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "helios.camera", qos: .userInteractive)
    private var tap: FrameSink?
    private var lastPreview: TimeInterval = 0
    private let ci = CIContext(options: [.useSoftwareRenderer: false])

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
            try lock60(device)
        } catch {
            DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
            session.commitConfiguration()
            return
        }

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
        if let conn = output.connection(with: .video), conn.isVideoMirroringSupported {
            conn.isVideoMirrored = true
        }
        session.commitConfiguration()
        session.startRunning()
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

    private func lock60(_ device: AVCaptureDevice) throws {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        let target = CMTime(value: 1, timescale: 60)
        if device.activeFormat.videoSupportedFrameRateRanges.contains(where: { $0.maxFrameRate >= 59 }) {
            device.activeVideoMinFrameDuration = target
            device.activeVideoMaxFrameDuration = target
        } else {
            let t30 = CMTime(value: 1, timescale: 30)
            device.activeVideoMinFrameDuration = t30
            device.activeVideoMaxFrameDuration = t30
        }
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }
    }

    private func handle(_ buffer: CMSampleBuffer) {
        onBuffer?(buffer)
        let now = CACurrentMediaTime()
        if now - lastPreview < 0.08 { return }
        lastPreview = now
        guard let pb = CMSampleBufferGetImageBuffer(buffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pb)
        let w = CVPixelBufferGetWidth(pb)
        let h = CVPixelBufferGetHeight(pb)
        guard let cg = ci.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: w, height: h)) else { return }
        let ns = NSImage(cgImage: cg, size: NSSize(width: w, height: h))
        DispatchQueue.main.async { self.preview = ns }
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

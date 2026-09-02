import AVFoundation
import CoreVideo
import Foundation

final class DepthCapture: NSObject, AVCaptureDepthDataOutputDelegate, @unchecked Sendable {
    private let output = AVCaptureDepthDataOutput()
    private let lock = NSLock()
    private var sample: DepthSample?
    var latest: DepthSample? {
        lock.lock(); defer { lock.unlock() }; return sample
    }
    var attached = false
    func attach(session: AVCaptureSession, device: AVCaptureDevice, queue: DispatchQueue) {
        attached = false
        let formats = device.activeFormat.supportedDepthDataFormats
        guard !formats.isEmpty else { return }
        HeliosCatch({
            do { try device.lockForConfiguration() } catch { return }
            if let best = formats.max(by: { CMVideoFormatDescriptionGetDimensions($0.formatDescription).width < CMVideoFormatDescriptionGetDimensions($1.formatDescription).width }) {
                device.activeDepthDataFormat = best
            }
            device.unlockForConfiguration()
        }, nil)
        output.isFilteringEnabled = true
        output.setDelegate(self, callbackQueue: queue)
        if session.canAddOutput(output) {
            session.addOutput(output)
            attached = true
        }
    }
    func captureOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        let converted = depthData.converting(toDepthDataType: kCVPixelFormatType_DepthFloat32)
        lock.lock()
        sample = DepthSample(map: converted.depthDataMap)
        lock.unlock()
    }
}

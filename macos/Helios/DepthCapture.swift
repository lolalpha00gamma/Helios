import AVFoundation
import CoreVideo
import Foundation

/// Auf dem Mac gibt es kein `AVCaptureDepthDataOutput` (iOS-only).
/// Fusion setzt das Tiefengewicht auf 0, solange `latest` nil bleibt.
final class DepthCapture: NSObject, @unchecked Sendable {
    var latest: DepthSample? { nil }
    var attached = false

    func attach(session: AVCaptureSession, device: AVCaptureDevice, queue: DispatchQueue) {
        attached = false
    }

    func applyActiveFormat(_ device: AVCaptureDevice) {}
}

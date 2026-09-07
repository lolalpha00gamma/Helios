import CoreGraphics
import Vision

/// Roh durchreichen. One-Euro lag und zog nach.
struct LandmarkSmoothing {
    mutating func reset() {}
    mutating func apply(
        _ joints: [VNHumanHandPoseObservation.JointName: CGPoint],
        now: TimeInterval
    ) -> [VNHumanHandPoseObservation.JointName: CGPoint] {
        _ = now
        return joints
    }
}

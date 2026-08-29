import CoreGraphics
import Vision

/// EMA-Glättung gegen Landmark-Jitter (Cursor zuckt sonst).
struct LandmarkSmoothing {
    private var previous: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
    var alpha: CGFloat = 0.38

    mutating func reset() {
        previous.removeAll()
    }

    mutating func apply(
        _ joints: [VNHumanHandPoseObservation.JointName: CGPoint]
    ) -> [VNHumanHandPoseObservation.JointName: CGPoint] {
        var out: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
        out.reserveCapacity(joints.count)
        for (name, point) in joints {
            if let old = previous[name] {
                out[name] = CGPoint(
                    x: alpha * point.x + (1 - alpha) * old.x,
                    y: alpha * point.y + (1 - alpha) * old.y
                )
            } else {
                out[name] = point
            }
        }
        previous = out
        return out
    }
}

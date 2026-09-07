import CoreGraphics
import Vision

/// Leichte EMA. Kein One-Euro, kein Nachziehen: still = dämpfen, Flick = folgen.
struct LandmarkSmoothing {
    private var prev: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]

    mutating func reset() { prev.removeAll() }

    mutating func apply(
        _ joints: [VNHumanHandPoseObservation.JointName: CGPoint],
        now: TimeInterval
    ) -> [VNHumanHandPoseObservation.JointName: CGPoint] {
        _ = now
        var out: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
        out.reserveCapacity(joints.count)
        for (name, p) in joints {
            if let q = prev[name] {
                let d = hypot(p.x - q.x, p.y - q.y)
                if d > 0.18 {
                    out[name] = p
                    prev[name] = p
                } else {
                    let a: CGFloat = d > 0.028 ? 0.78 : (d > 0.010 ? 0.52 : 0.34)
                    let s = CGPoint(x: q.x + a * (p.x - q.x), y: q.y + a * (p.y - q.y))
                    out[name] = s
                    prev[name] = s
                }
            } else {
                out[name] = p
                prev[name] = p
            }
        }
        prev = prev.filter { joints[$0.key] != nil }
        return out
    }
}

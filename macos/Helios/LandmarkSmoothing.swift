import CoreGraphics
import Vision

/// One-Euro-Filter: folgt schnellen Bewegungen, dämpft Jitter in Ruhe.
struct LandmarkSmoothing {
    private var previous: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
    private var deriv: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
    private var lastT: TimeInterval?
    var minCutoff: CGFloat = 6.2
    var beta: CGFloat = 0.16
    var dCutoff: CGFloat = 1.8

    mutating func reset() {
        previous.removeAll()
        deriv.removeAll()
        lastT = nil
    }

    mutating func apply(
        _ joints: [VNHumanHandPoseObservation.JointName: CGPoint],
        now: TimeInterval
    ) -> [VNHumanHandPoseObservation.JointName: CGPoint] {
        defer { lastT = now }
        guard let lastT else {
            previous = joints
            return joints
        }
        let dt = max(0.008, min(0.08, now - lastT))
        var out: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
        out.reserveCapacity(joints.count)
        for (name, point) in joints {
            if let old = previous[name] {
                let rawD = CGPoint(x: (point.x - old.x) / dt, y: (point.y - old.y) / dt)
                let prevD = deriv[name] ?? .zero
                let ad = alpha(dCutoff, dt)
                let edx = lerp(rawD.x, prevD.x, ad)
                let edy = lerp(rawD.y, prevD.y, ad)
                deriv[name] = CGPoint(x: edx, y: edy)
                let cutoff = minCutoff + beta * hypot(edx, edy)
                let a = alpha(cutoff, dt)
                out[name] = CGPoint(x: lerp(point.x, old.x, a), y: lerp(point.y, old.y, a))
            } else {
                out[name] = point
            }
        }
        previous = out
        return out
    }

    private func alpha(_ cutoff: CGFloat, _ dt: CGFloat) -> CGFloat {
        let tau = 1 / (2 * .pi * max(0.01, cutoff))
        return 1 / (1 + tau / dt)
    }

    private func lerp(_ x: CGFloat, _ old: CGFloat, _ a: CGFloat) -> CGFloat {
        a * x + (1 - a) * old
    }
}

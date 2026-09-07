import CoreGraphics
import Vision

/// One-Euro-Filter plus Ausreißerabwehr.
/// minCutoff niedrig = ruhiger Zeiger. beta hoch = schnelle Wischer kommen durch.
struct LandmarkSmoothing {
    private var previous: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
    private var deriv: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
    private var lastT: TimeInterval?
    private var jumps: [CGFloat] = []
    var minCutoff: CGFloat = 2.4
    var beta: CGFloat = 0.55
    var dCutoff: CGFloat = 1.4
    var space = AspectSpace.hd720

    mutating func reset() {
        previous.removeAll()
        deriv.removeAll()
        lastT = nil
        jumps.removeAll()
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
        let dt = GestureMath.sampleDt(now: now, last: lastT)
        var cleaned: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
        var frameJumps: [CGFloat] = []
        for (name, point) in joints {
            if let old = previous[name] {
                frameJumps.append(space.dist(old, point) / CGFloat(dt))
            }
        }
        jumps.append(contentsOf: frameJumps)
        if jumps.count > 80 { jumps.removeFirst(jumps.count - 80) }
        let med = JointGeom.median(jumps)
        let cap = max(0.55, 2.8 * med)
        for (name, point) in joints {
            if let old = previous[name] {
                let speed = space.dist(old, point) / CGFloat(dt)
                if speed > cap, med > 0.04 {
                    let isoOld = space.iso(old)
                    let isoNew = space.iso(point)
                    let v = deriv[name] ?? .zero
                    let pred = CGPoint(x: isoOld.x + v.x * dt, y: isoOld.y + v.y * dt)
                    let blend = CGPoint(x: pred.x * 0.82 + isoNew.x * 0.18, y: pred.y * 0.82 + isoNew.y * 0.18)
                    cleaned[name] = space.fromIso(blend)
                } else {
                    cleaned[name] = point
                }
            } else {
                cleaned[name] = point
            }
        }

        var out: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
        out.reserveCapacity(cleaned.count)
        for (name, point) in cleaned {
            if let old = previous[name] {
                let rawD = CGPoint(x: (point.x - old.x) / dt, y: (point.y - old.y) / dt)
                let prevD = deriv[name] ?? .zero
                let ad = alpha(dCutoff, dt)
                let edx = lerp(rawD.x, prevD.x, ad)
                let edy = lerp(rawD.y, prevD.y, ad)
                deriv[name] = CGPoint(x: edx, y: edy)
                let cutoff = minCutoff + beta * hypot(edx * space.aspect, edy)
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

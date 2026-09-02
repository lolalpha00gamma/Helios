import CoreGraphics
import Vision

/// One-Euro-Filter plus Ausreißerabwehr (3,5 · Median-Sprung **dieses** Frames).
/// 80 Frames Idle-History als Cap hat Flicks als Ausreißer behandelt und
/// die Bewegung abgeschliffen — genau dann, wenn Track-ID und Wischen sie brauchen.
struct LandmarkSmoothing {
    private var previous: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
    private var deriv: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
    private var lastT: TimeInterval?
    private var jumps: [CGFloat] = []
    var minCutoff: CGFloat = 6.2
    var beta: CGFloat = 0.16
    var dCutoff: CGFloat = 1.8
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
        let dt = max(0.008, min(0.08, now - lastT))
        var cleaned: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
        var frameJumps: [CGFloat] = []
        for (name, point) in joints {
            if let old = previous[name] {
                frameJumps.append(space.dist(old, point) / CGFloat(dt))
            }
        }
        // Cap aus dem aktuellen Frame. History nur, wenn der Frame zu dünn ist.
        let medFrame = JointGeom.median(frameJumps)
        let medHist = JointGeom.median(jumps)
        let med = frameJumps.count >= 4 ? medFrame : (medFrame > 0 ? medFrame : medHist)
        let cap = max(1.2, 3.5 * max(med, 0.15))
        for (name, point) in joints {
            if let old = previous[name] {
                let speed = space.dist(old, point) / CGFloat(dt)
                if speed > cap, med > 0.08 {
                    let isoOld = space.iso(old)
                    let isoNew = space.iso(point)
                    let v = deriv[name] ?? .zero
                    let pred = CGPoint(x: isoOld.x + v.x * dt, y: isoOld.y + v.y * dt)
                    let blend = CGPoint(x: pred.x * 0.55 + isoNew.x * 0.45, y: pred.y * 0.55 + isoNew.y * 0.45)
                    cleaned[name] = space.fromIso(blend)
                } else {
                    cleaned[name] = point
                }
            } else {
                cleaned[name] = point
            }
        }
        jumps.append(contentsOf: frameJumps)
        if jumps.count > 40 { jumps.removeFirst(jumps.count - 40) }

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

import CoreGraphics
import Vision

enum HandPose: String, Equatable {
    case unknown
    case fist
    case openPalm
    case pinch
    case point
    case thumbsUp
    case peace

    var labelDE: String {
        switch self {
        case .unknown: return "—"
        case .fist: return "Faust"
        case .openPalm: return "Offene Hand"
        case .pinch: return "Pinzette"
        case .point: return "Zeigen"
        case .thumbsUp: return "Daumen hoch"
        case .peace: return "Zwei Finger"
        }
    }
}

enum GestureClassifier {
    static func palmScale(_ joints: [VNHumanHandPoseObservation.JointName: CGPoint]) -> CGFloat {
        if let w = joints[.wrist], let m = joints[.middleMCP] {
            return max(0.05, hypot(w.x - m.x, w.y - m.y))
        }
        if let a = joints[.indexMCP], let b = joints[.littleMCP] {
            return max(0.04, hypot(a.x - b.x, a.y - b.y))
        }
        return 0.12
    }

    static func pinchRatio(
        joints: [VNHumanHandPoseObservation.JointName: CGPoint],
        pinch: CGFloat
    ) -> CGFloat {
        pinch / palmScale(joints)
    }

    static func palmCenter(_ joints: [VNHumanHandPoseObservation.JointName: CGPoint]) -> CGPoint {
        let mcp: [VNHumanHandPoseObservation.JointName] = [.indexMCP, .middleMCP, .ringMCP, .littleMCP]
        let pts = mcp.compactMap { joints[$0] }
        if pts.count >= 2 {
            let x = pts.map(\.x).reduce(0, +) / CGFloat(pts.count)
            let y = pts.map(\.y).reduce(0, +) / CGFloat(pts.count)
            return CGPoint(x: x, y: y)
        }
        return joints[.wrist] ?? joints[.indexMCP] ?? .zero
    }

    static func classify(
        joints: [VNHumanHandPoseObservation.JointName: CGPoint],
        pinch: CGFloat
    ) -> HandPose {
        let thumb = isExtended(joints, tip: .thumbTip, pip: .thumbIP, mcp: .thumbMP, slack: 0.012)
        let index = isExtended(joints, tip: .indexTip, pip: .indexPIP, mcp: .indexMCP, slack: 0.016)
        let middle = isExtended(joints, tip: .middleTip, pip: .middlePIP, mcp: .middleMCP, slack: 0.016)
        let ring = isExtended(joints, tip: .ringTip, pip: .ringPIP, mcp: .ringMCP, slack: 0.016)
        let little = isExtended(joints, tip: .littleTip, pip: .littlePIP, mcp: .littleMCP, slack: 0.016)

        let fingers = [index, middle, ring, little].filter { $0 }.count
        let scale = palmScale(joints)
        let ratio = pinch / scale

        // Pinzette: Spitzen nah. Zeigefinger darf leicht gebeugt sein (sonst wird's Faust).
        let pinchPtReach: CGFloat = {
            guard let t = joints[.thumbTip], let i = joints[.indexTip], let w = joints[.wrist] else { return 0 }
            let mid = CGPoint(x: (t.x + i.x) / 2, y: (t.y + i.y) / 2)
            return hypot(mid.x - w.x, mid.y - w.y) / scale
        }()
        if ratio < 0.42, fingers <= 2, pinchPtReach > 0.82 {
            return .pinch
        }
        if index && middle && !ring && !little {
            return .peace
        }
        if index && !middle && !ring && !little {
            return .point
        }
        if fingers == 0, thumb, let tip = joints[.thumbTip], let wrist = joints[.wrist],
           tip.y > wrist.y + 0.08, ratio > 0.35
        {
            return .thumbsUp
        }
        // Faust: keine klaren Finger. Daumen darf „falsch offen“ sein.
        if fingers == 0 {
            return .fist
        }
        if fingers >= 3 {
            return .openPalm
        }
        return .unknown
    }

    static func openScore(joints: [VNHumanHandPoseObservation.JointName: CGPoint]) -> Int {
        var n = 0
        if isExtended(joints, tip: .indexTip, pip: .indexPIP, mcp: .indexMCP, slack: 0.012) { n += 1 }
        if isExtended(joints, tip: .middleTip, pip: .middlePIP, mcp: .middleMCP, slack: 0.012) { n += 1 }
        if isExtended(joints, tip: .ringTip, pip: .ringPIP, mcp: .ringMCP, slack: 0.012) { n += 1 }
        if isExtended(joints, tip: .littleTip, pip: .littlePIP, mcp: .littleMCP, slack: 0.012) { n += 1 }
        return n
    }

    static func isExtended(
        _ joints: [VNHumanHandPoseObservation.JointName: CGPoint],
        tip: VNHumanHandPoseObservation.JointName,
        pip: VNHumanHandPoseObservation.JointName,
        mcp: VNHumanHandPoseObservation.JointName,
        slack: CGFloat = 0.008
    ) -> Bool {
        guard let t = joints[tip], let p = joints[pip], let m = joints[mcp], let w = joints[.wrist] else {
            return false
        }
        let tipD = hypot(t.x - w.x, t.y - w.y)
        let pipD = hypot(p.x - w.x, p.y - w.y)
        let mcpD = hypot(m.x - w.x, m.y - w.y)
        return tipD > pipD + slack && pipD > mcpD * 0.86
    }
}

/// Hysterese auf Roh-Abstand Daumen/Zeigefinger. Fehlende Spitzen (echte Berührung) halten den Zustand.
struct PinchGate {
    private(set) var closed = false
    private var lastRatio: CGFloat = 1
    private var lastT: TimeInterval = 0
    private var streak = 0

    mutating func reset() {
        closed = false
        lastRatio = 1
        lastT = 0
        streak = 0
    }

    mutating func update(
        raw: [VNHumanHandPoseObservation.JointName: CGPoint],
        conf: [VNHumanHandPoseObservation.JointName: Float],
        now: TimeInterval
    ) -> (closed: Bool, ratio: CGFloat, distance: CGFloat) {
        let scale = max(GestureClassifier.palmScale(raw), 0.05)
        let tipConf = min(conf[.thumbTip] ?? 0, conf[.indexTip] ?? 0)
        var dTips: CGFloat?
        if let a = raw[.thumbTip], let b = raw[.indexTip], tipConf > 0.18 {
            dTips = hypot(a.x - b.x, a.y - b.y)
        }
        var dProx: CGFloat?
        if let a = raw[.thumbIP] ?? raw[.thumbTip], let b = raw[.indexDIP] ?? raw[.indexPIP] ?? raw[.indexTip] {
            dProx = hypot(a.x - b.x, a.y - b.y)
        }
        let dist = dTips ?? ((dProx ?? 1) * 1.12)
        let ratio = dist / scale
        let proxRatio = (dProx ?? dist) / scale
        let wrist = raw[.wrist]
        let reach: CGFloat = {
            guard let w = wrist else { return 1 }
            if let t = raw[.thumbTip], let i = raw[.indexTip] {
                let m = CGPoint(x: (t.x + i.x) / 2, y: (t.y + i.y) / 2)
                return hypot(m.x - w.x, m.y - w.y) / scale
            }
            if let i = raw[.indexPIP] {
                return hypot(i.x - w.x, i.y - w.y) / scale
            }
            return 1
        }()
        let dt = lastT == 0 ? 0.016 : max(0.008, min(0.08, now - lastT))
        let vel = (ratio - lastRatio) / CGFloat(dt)
        lastRatio = ratio
        lastT = now

        let awayFromPalm = reach > 0.78
        let wantClose = awayFromPalm && (
            ratio < 0.33
                || proxRatio < 0.36
                || (ratio < 0.44 && vel < -2.0)
        )
        let wantOpen = ratio > 0.54 && proxRatio > 0.50 && vel > -0.5

        if dTips == nil {
            if closed {
                streak = 0
                return (true, min(ratio, 0.30), dist)
            }
            let closeByProxy = awayFromPalm && proxRatio < 0.30
            if closeByProxy { streak += 1 } else { streak = 0 }
            if streak >= 3 {
                closed = true
                streak = 0
            }
            return (closed, ratio, dist)
        }

        if closed {
            if wantOpen { streak += 1 } else { streak = 0 }
            if streak >= 3 {
                closed = false
                streak = 0
            }
        } else {
            if wantClose { streak += 1 } else { streak = 0 }
            if streak >= 2 {
                closed = true
                streak = 0
            }
        }
        return (closed, ratio, dist)
    }
}

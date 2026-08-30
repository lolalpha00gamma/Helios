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
        let indexReach: CGFloat = {
            guard let t = joints[.indexTip], let w = joints[.wrist] else { return 0 }
            return hypot(t.x - w.x, t.y - w.y) / scale
        }()

        // Pinzette: Spitzen nah UND Zeigefinger noch raus (sonst ist es eine Faust).
        if ratio < 0.45, pinch < 0.13, fingers <= 2, indexReach > 0.95 {
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

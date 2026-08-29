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
    static func classify(
        joints: [VNHumanHandPoseObservation.JointName: CGPoint],
        pinch: CGFloat
    ) -> HandPose {
        let thumb = extended(joints, tip: .thumbTip, pip: .thumbIP, mcp: .thumbMP, wrist: .wrist)
        let index = extended(joints, tip: .indexTip, pip: .indexPIP, mcp: .indexMCP, wrist: .wrist)
        let middle = extended(joints, tip: .middleTip, pip: .middlePIP, mcp: .middleMCP, wrist: .wrist)
        let ring = extended(joints, tip: .ringTip, pip: .ringPIP, mcp: .ringMCP, wrist: .wrist)
        let little = extended(joints, tip: .littleTip, pip: .littlePIP, mcp: .littleMCP, wrist: .wrist)

        let fingers = [index, middle, ring, little].filter { $0 }.count

        if pinch < 0.048 && index {
            return .pinch
        }
        if index && !middle && !ring && !little {
            return .point
        }
        if index && middle && !ring && !little {
            return .peace
        }
        if thumb && fingers == 0, let tip = joints[.thumbTip], let wrist = joints[.wrist], tip.y > wrist.y + 0.06 {
            return .thumbsUp
        }
        if fingers == 0 && !thumb {
            return .fist
        }
        if fingers >= 4 {
            return .openPalm
        }
        return .unknown
    }

    private static func extended(
        _ joints: [VNHumanHandPoseObservation.JointName: CGPoint],
        tip: VNHumanHandPoseObservation.JointName,
        pip: VNHumanHandPoseObservation.JointName,
        mcp: VNHumanHandPoseObservation.JointName,
        wrist: VNHumanHandPoseObservation.JointName
    ) -> Bool {
        guard let t = joints[tip], let p = joints[pip], let m = joints[mcp], let w = joints[wrist] else {
            return false
        }
        let tipD = hypot(t.x - w.x, t.y - w.y)
        let pipD = hypot(p.x - w.x, p.y - w.y)
        let mcpD = hypot(m.x - w.x, m.y - w.y)
        return tipD > pipD + 0.012 && pipD > mcpD * 0.92
    }
}

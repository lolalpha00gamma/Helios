import CoreGraphics
import Darwin
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
        let wrist = joints[.wrist]
        let mcps = [joints[.indexMCP], joints[.middleMCP], joints[.ringMCP], joints[.littleMCP]].compactMap { $0 }
        if let med = GestureMath.palmScaleWristMCP(wrist: wrist, mcps: mcps) {
            let span = GestureMath.palmScaleSpanOf(mcps)
            if GestureMath.palmScaleSpanVeto(wristMCP: med, span: span) {
                return GestureMath.obsScaleMarksProp(med)
            }
            return med
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

        // Peace vor Pinzette: Daumen kann am Zeigefinger kleben, ohne dass
        // zwei ausgestreckte Finger eine Pinzette sind.
        if index && middle && !ring && !little {
            return .peace
        }
        let pinchPtReach: CGFloat = {
            guard let t = joints[.thumbTip], let i = joints[.indexTip], let w = joints[.wrist] else { return 0 }
            let mid = CGPoint(x: (t.x + i.x) / 2, y: (t.y + i.y) / 2)
            return hypot(mid.x - w.x, mid.y - w.y) / scale
        }()
        // Pinzette vor Zeigen: Vision hält den Zeigefinger oft „extended“, obwohl die Spitzen zu sind.
        if ratio < 0.42, fingers <= 1, pinchPtReach > 0.82 {
            return .pinch
        }
        if index && !middle && !ring && !little {
            return .point
        }

        if fingers == 0, thumb, let tip = joints[.thumbTip], let wrist = joints[.wrist],
           tip.y > wrist.y + 0.08, ratio > 0.35
        {
            return .thumbsUp
        }
        // Geschlossene Spitzen ohne Reach sind keine Faust — sonst arming während Pinch.
        if fingers == 0, ratio < 0.38 {
            return .pinch
        }
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

    static let fingerOpenMaxBend: CGFloat = 18
    /// MCP→Tip kürzer als 1,52× Palma: 40°-Kralle zur Kamera, 2D-Winkel ≈ 0°.
    static let fingerOpenMinSpan: CGFloat = 1.52

    /// PIP-Beugung gegen die Streckung, nicht der Innenwinkel.
    /// Gerade: 0°. Faust ~90°+. 40°-Kralle darf nicht als offen zählen.
    static func pipBendDegrees(
        _ joints: [VNHumanHandPoseObservation.JointName: CGPoint],
        tip: VNHumanHandPoseObservation.JointName,
        pip: VNHumanHandPoseObservation.JointName,
        mcp: VNHumanHandPoseObservation.JointName
    ) -> CGFloat? {
        guard let t = joints[tip], let p = joints[pip], let m = joints[mcp] else { return nil }
        let v1 = CGPoint(x: p.x - m.x, y: p.y - m.y)
        let v2 = CGPoint(x: t.x - p.x, y: t.y - p.y)
        let n1 = hypot(v1.x, v1.y)
        let n2 = hypot(v2.x, v2.y)
        guard n1 > 1e-6, n2 > 1e-6 else { return nil }
        let c = max(-1, min(1, (v1.x * v2.x + v1.y * v2.y) / (n1 * n2)))
        return acos(c) * 180 / .pi
    }

    static func dipJoint(forTip tip: VNHumanHandPoseObservation.JointName) -> VNHumanHandPoseObservation.JointName? {
        switch tip {
        case .indexTip: return .indexDIP
        case .middleTip: return .middleDIP
        case .ringTip: return .ringDIP
        case .littleTip: return .littleDIP
        default: return nil
        }
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
        guard tipD > pipD + slack, pipD > mcpD * 0.86 else { return false }
        // Radial allein zählt 40°-Kralle noch als offen — Not-Aus an fast gestreckten Fingern.
        if let bend = pipBendDegrees(joints, tip: tip, pip: pip, mcp: mcp), bend > fingerOpenMaxBend {
            return false
        }
        if let dip = dipJoint(forTip: tip),
           let dipBend = pipBendDegrees(joints, tip: tip, pip: dip, mcp: pip),
           dipBend > fingerOpenMaxBend
        {
            return false
        }
        // Kralle zur Kamera: Segmente kollinear in 2D, Winkel 0°, Finger nur kürzer.
        let span = hypot(t.x - m.x, t.y - m.y)
        let pal = palmScale(joints)
        if span < pal * fingerOpenMinSpan { return false }
        return true
    }
}

/// Hysterese auf Roh-Abstand Daumen/Zeigefinger. Fehlende Spitzen (echte Berührung) halten kurz zu, dann auf.
struct PinchGate {
    private(set) var closed = false
    private var lastRatio: CGFloat = 1
    private var lastT: TimeInterval = 0
    private var streak = 0
    private var missingTipsSince: TimeInterval?
    private var justOpened = false

    mutating func reset() {
        closed = false
        lastRatio = 1
        lastT = 0
        streak = 0
        missingTipsSince = nil
        justOpened = false
    }

    mutating func update(
        raw: [VNHumanHandPoseObservation.JointName: CGPoint],
        conf: [VNHumanHandPoseObservation.JointName: Float],
        now: TimeInterval,
        tipZ: Float? = nil,
        dt: TimeInterval = 0.016,
        continuity: Bool = false
    ) -> (closed: Bool, ratio: CGFloat, distance: CGFloat) {
        let scale = max(GestureClassifier.palmScale(raw), 0.05)
        var dTips: CGFloat?
        if let a = raw[.thumbTip], let b = raw[.indexTip],
           GestureMath.pinchTipConfidenceOk(
            thumb: conf[.thumbTip],
            index: conf[.indexTip],
            floor: GestureMath.pinchTipFloorOf(dt: dt, continuity: continuity)
           )
        {
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
        let dt = GestureMath.sampleDt(now: now, last: lastT)
        let vel = (ratio - lastRatio) / CGFloat(dt)
        lastRatio = ratio
        lastT = now

        let closeR = GestureMath.pinchCloseRatio(scale: scale)
        let awayFromPalm = reach > 0.78
        let closeVel = GestureMath.pinchCloseVel(dt: dt, palmScale: scale)
        let tipClosed = GestureMath.pinchUsesTipZ(revision2: true, tipZ: tipZ)
            && GestureMath.pinchTipZClosed(tipZ: tipZ)
        let wantClose = awayFromPalm && (
            ratio < closeR
                || proxRatio < closeR + 0.03
                || (ratio < closeR + 0.11 && vel < closeVel)
                || tipClosed
        )
        let wantOpen = GestureMath.pinchWantOpen(
            ratio: ratio,
            proxRatio: proxRatio,
            vel: vel,
            dt: dt,
            scale: scale
        )

        if dTips == nil {
            if missingTipsSince == nil { missingTipsSince = now }
            if closed {
                if now - (missingTipsSince ?? now) > GestureMath.missingTipsOpen {
                    closed = false
                    streak = 0
                    return (false, ratio, dist)
                }
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
        missingTipsSince = nil

        if closed {
            if wantOpen { streak += 1 } else { streak = 0 }
            let ratioOnly = vel <= GestureMath.pinchOpenVel(dt: dt)
            if GestureMath.pinchOpenHolds(frames: streak, dt: dt, ratioOnly: ratioOnly) {
                closed = false
                streak = 0
                justOpened = true
            }
        } else {
            if wantClose { streak += 1 } else { streak = 0; justOpened = false }
            if streak >= GestureMath.pinchCloseNeed(dt: dt, justOpened: justOpened) {
                closed = true
                streak = 0
                justOpened = false
            }
        }
        return (closed, ratio, dist)
    }
}

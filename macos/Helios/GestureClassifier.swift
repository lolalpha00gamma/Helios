import CoreGraphics
import simd
import Vision

enum HandPose: String, Equatable, CaseIterable, Hashable {
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
        case .peace: return "Zwei Finger"
        case .thumbsUp: return "Daumen hoch"
        }
    }
}

struct PoseFeatures {
    var probs: [HandPose: Double]
    var pinchClosedness: Double
    var pinchRatio: CGFloat
    var pinchDistance: CGFloat
    var palm: CGPoint
    var palmWidth: CGFloat
    var quality: Double
    var extensions: [String: CGFloat]
    var openScore: Int
}

enum GestureClassifier {
    static var space = AspectSpace.hd720

    static func palmScale(
        _ joints: [VNHumanHandPoseObservation.JointName: CGPoint],
        space: AspectSpace = space
    ) -> CGFloat {
        var spans: [CGFloat] = []
        if let w = joints[.wrist] {
            for m in [VNHumanHandPoseObservation.JointName.middleMCP, .indexMCP, .ringMCP, .littleMCP] {
                if let p = joints[m] { spans.append(space.dist(w, p)) }
            }
        }
        if let a = joints[.indexMCP], let b = joints[.littleMCP] {
            spans.append(space.dist(a, b))
        }
        let med = JointGeom.median(spans)
        var scale = max(0.04, med)
        if let w = joints[.wrist], let m = joints[.middleMCP], let i = joints[.indexMCP] {
            let axis = space.vec(w, m)
            let al = hypot(axis.x, axis.y)
            let across = space.vec(i, joints[.littleMCP] ?? i)
            let ac = hypot(across.x, across.y)
            if al > 1e-4, ac > 1e-4 {
                let foreshort = min(1, al / max(ac, 0.01) * 0.55)
                scale = max(scale, scale / max(0.45, min(1, foreshort + 0.4)))
            }
        }
        return scale
    }

    /// Finger nach unten = Rest, kein Scroll.
    static func palmDown(wrist: CGPoint, tip: CGPoint, openScore: Int, pose: HandPose) -> Bool {
        let pointingDown = tip.y + 0.06 < wrist.y
        let open = openScore >= 3 && (pose == .openPalm || pose == .unknown)
        return open && pointingDown
    }

    /// Ein-Hand-Zwei-Finger-Scroll, wenn die zweite Hand ruht oder fehlt.
    /// Zwei offene Palmen bleiben der Zwei-Hand-Pfad (`openPalms >= 2`).
    static func twoFingerScroll(peace: Int, openPalms: Int, resting: Int, hands: Int) -> Bool {
        guard openPalms < 2 else { return false }
        guard peace >= 1 else { return false }
        return resting >= 1 || hands == 1
    }

    /// Pinch über Text (nicht Titelleiste) nach so vielen Handbreiten = Auswahl, kein Fenster.
    static func textSelectMoved(_ handwidths: CGFloat) -> Bool {
        handwidths >= CoordMath.textSelectHandwidths
    }

    static func pinchRatio(
        joints: [VNHumanHandPoseObservation.JointName: CGPoint],
        pinch: CGFloat,
        space: AspectSpace = space
    ) -> CGFloat {
        pinch / palmScale(joints, space: space)
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
        pinch: CGFloat,
        conf: [VNHumanHandPoseObservation.JointName: Float] = [:],
        space: AspectSpace = space
    ) -> HandPose {
        features(joints: joints, pinch: pinch, conf: conf, space: space).probs
            .max(by: { $0.value < $1.value })?.key ?? .unknown
    }

    static func features(
        joints: [VNHumanHandPoseObservation.JointName: CGPoint],
        pinch: CGFloat,
        conf: [VNHumanHandPoseObservation.JointName: Float] = [:],
        space: AspectSpace = space
    ) -> PoseFeatures {
        let scale = palmScale(joints, space: space)
        let palm = palmCenter(joints)
        let thumb = fingerExtension(joints, .thumb, space: space, conf: conf)
        let index = fingerExtension(joints, .index, space: space, conf: conf)
        let middle = fingerExtension(joints, .middle, space: space, conf: conf)
        let ring = fingerExtension(joints, .ring, space: space, conf: conf)
        let little = fingerExtension(joints, .little, space: space, conf: conf)

        let dist: CGFloat = {
            if let a = joints[.thumbTip], let b = joints[.indexTip] {
                return space.dist(a, b)
            }
            if let a = joints[.thumbIP], let b = joints[.indexPIP] {
                return space.dist(a, b) * 1.12
            }
            return pinch
        }()
        let ratio = dist / max(0.03, scale)
        let closedness = max(0, min(1, (0.52 - ratio) / 0.40))
        let reach: CGFloat = {
            guard let w = joints[.wrist], let t = joints[.thumbTip], let i = joints[.indexTip] else { return 1 }
            let m = CGPoint(x: (t.x + i.x) / 2, y: (t.y + i.y) / 2)
            return space.dist(m, w) / max(0.03, scale)
        }()

        let thumbUp: CGFloat = {
            guard let tip = joints[.thumbTip], let wrist = joints[.wrist] else { return 0 }
            let dy = (tip.y - wrist.y) / max(0.03, scale)
            return max(0, min(1, (dy - 0.35) / 0.7)) * thumb.score
        }()

        var logits: [HandPose: Double] = [:]
        logits[.fist] = Double((1 - index.score) + (1 - middle.score) + (1 - ring.score) + (1 - little.score)) * 1.1
            - Double(closedness) * 0.4
        logits[.openPalm] = Double(index.score + middle.score + ring.score + little.score) * 1.15
        logits[.pinch] = Double(closedness) * 4.4 + Double(reach) * 0.8
            - Double(middle.score + ring.score) * 0.7
        logits[.point] = Double(index.score) * 3.4 - Double(middle.score + ring.score + little.score) * 1.5
            + Double(max(0, 0.48 - middle.score)) * 1.3
            + Double(max(0, 0.50 - thumb.score)) * 0.8
        // Peace braucht gespreizte Zeige+Mittel. Daumen-an-MCP ist ein Zwei-Finger-Point,
        // kein Victory — sonst feuert die 0,9-s-Aufnahme beim Zeigen.
        let spread: CGFloat = {
            guard let a = joints[.indexTip], let b = joints[.middleTip] else { return 0.12 }
            return space.dist(a, b) / max(0.03, scale)
        }()
        logits[.peace] = Double(index.score + middle.score) * 2.1 - Double(ring.score + little.score) * 2.2
            - Double(max(0, 0.55 - thumb.score)) * 2.6
            - Double(max(0, 0.58 - middle.score)) * 1.9
            + Double(min(1, max(0, spread - 0.16) / 0.20)) * 1.8
        logits[.thumbsUp] = Double(thumbUp) * 4.2
            + Double((1 - index.score) + (1 - middle.score) + (1 - ring.score)) * 0.7
            - Double(closedness) * 1.4
        logits[.unknown] = 0.35

        let keys = HandPose.allCases
        let sm = JointGeom.softmax(keys.map { logits[$0] ?? 0 }, temperature: 0.72)
        var probs: [HandPose: Double] = [:]
        for (i, k) in keys.enumerated() { probs[k] = sm[i] }

        let used: [VNHumanHandPoseObservation.JointName] = [
            .wrist, .thumbTip, .indexTip, .middleTip, .ringTip, .littleTip,
            .indexMCP, .middleMCP, .indexPIP, .middlePIP
        ]
        var wsum: Double = 0
        var csum: Double = 0
        for n in used {
            let c = Double(conf[n] ?? 0.5)
            wsum += c
            csum += c * c
        }
        let quality = wsum > 0 ? min(1, csum / max(0.01, wsum)) : 0.4
        let openScore = [index, middle, ring, little].filter { $0.score > 0.55 }.count

        return PoseFeatures(
            probs: probs,
            pinchClosedness: Double(closedness),
            pinchRatio: ratio,
            pinchDistance: dist,
            palm: palm,
            palmWidth: scale,
            quality: quality,
            extensions: [
                "thumb": thumb.score,
                "index": index.score,
                "middle": middle.score,
                "ring": ring.score,
                "little": little.score
            ],
            openScore: openScore
        )
    }

    static func openScore(
        joints: [VNHumanHandPoseObservation.JointName: CGPoint],
        space: AspectSpace = space
    ) -> Int {
        features(joints: joints, pinch: 0.2, space: space).openScore
    }

    static func isExtended(
        _ joints: [VNHumanHandPoseObservation.JointName: CGPoint],
        tip: VNHumanHandPoseObservation.JointName,
        pip: VNHumanHandPoseObservation.JointName,
        mcp: VNHumanHandPoseObservation.JointName,
        slack: CGFloat = 0.008
    ) -> Bool {
        let finger: FingerKind? = {
            switch tip {
            case .thumbTip: return .thumb
            case .indexTip: return .index
            case .middleTip: return .middle
            case .ringTip: return .ring
            case .littleTip: return .little
            default: return nil
            }
        }()
        if let finger {
            return fingerExtension(joints, finger, space: space, conf: [:]).score > 0.52
        }
        guard let t = joints[tip], let p = joints[pip], let m = joints[mcp], let w = joints[.wrist] else {
            return false
        }
        let tipD = space.dist(t, w)
        let pipD = space.dist(p, w)
        let mcpD = space.dist(m, w)
        return tipD > pipD + slack && pipD > mcpD * 0.86
    }

    static func fingerExtension(
        _ joints: [VNHumanHandPoseObservation.JointName: CGPoint],
        _ finger: FingerKind,
        space: AspectSpace,
        conf: [VNHumanHandPoseObservation.JointName: Float]
    ) -> (score: CGFloat, weight: CGFloat) {
        let tip = finger.tip
        let pip = finger.pip
        let mcp = finger.mcp
        guard let t = joints[tip], let p = joints[pip], let m = joints[mcp] else {
            return (0, 0)
        }
        let ang = JointGeom.angle(m, p, t, space: space)
        var score = JointGeom.extensionScore(angleRadians: ang)
        if let w = joints[.wrist] {
            let tipD = space.dist(t, w)
            let pipD = space.dist(p, w)
            let radial = tipD > pipD ? min(1, (tipD - pipD) / max(0.02, palmScale(joints, space: space) * 0.45)) : 0
            score = score * 0.72 + radial * 0.28
        }
        let wgt = CGFloat((conf[tip] ?? 0.5) + (conf[pip] ?? 0.5) + (conf[mcp] ?? 0.5)) / 3
        return (max(0, min(1, score)) * max(0.35, min(1, wgt + 0.35)), wgt)
    }

    static func features3D(
        _ pts: [VNHumanHandPoseObservation.JointName: Joint3],
        palmWidth: CGFloat
    ) -> PoseFeatures {
        func p(_ n: VNHumanHandPoseObservation.JointName) -> SIMD3<Float>? {
            guard let j = pts[n] else { return nil }
            return SIMD3(Float(j.x), Float(j.y), Float(j.z))
        }
        func ang(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>) -> CGFloat {
            let ba = a - b
            let bc = c - b
            let na = simd_length(ba)
            let nc = simd_length(bc)
            guard na > 1e-6, nc > 1e-6 else { return .pi }
            let cosv = max(-1, min(1, simd_dot(ba, bc) / (na * nc)))
            return CGFloat(acos(cosv))
        }
        func ext(_ mcp: VNHumanHandPoseObservation.JointName, _ pip: VNHumanHandPoseObservation.JointName, _ tip: VNHumanHandPoseObservation.JointName) -> CGFloat {
            guard let a = p(mcp), let b = p(pip), let c = p(tip) else { return 0 }
            return JointGeom.extensionScore(angleRadians: ang(a, b, c))
        }
        let thumb = ext(.thumbMP, .thumbIP, .thumbTip)
        let index = ext(.indexMCP, .indexPIP, .indexTip)
        let middle = ext(.middleMCP, .middlePIP, .middleTip)
        let ring = ext(.ringMCP, .ringPIP, .ringTip)
        let little = ext(.littleMCP, .littlePIP, .littleTip)
        var pinch: CGFloat = 1
        if let a = p(.thumbTip), let b = p(.indexTip) {
            pinch = CGFloat(simd_distance(a, b)) / max(0.03, palmWidth)
        }
        let closedness = max(0, min(1, (0.50 - pinch) / 0.38))
        var xy: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
        for (k, v) in pts { xy[k] = v.xy }
        var f = features(joints: xy, pinch: pinch * palmWidth, space: AspectSpace(width: 1, height: 1))
        f.extensions = ["thumb": thumb, "index": index, "middle": middle, "ring": ring, "little": little]
        f.pinchClosedness = Double(closedness)
        f.pinchRatio = pinch
        // 2D-Peace braucht Spreizung + Daumen weg von MCP. Ohne das hat 3D-Fusion
        // Victory beim Zwei-Finger-Point zurückgebracht.
        let spread3: CGFloat = {
            guard let a = p(.indexTip), let b = p(.middleTip) else { return 0.12 }
            return CGFloat(simd_distance(a, b)) / max(0.03, palmWidth)
        }()
        let thumbAtMCP: CGFloat = {
            guard let t = p(.thumbTip), let m = p(.indexMCP) else { return 0 }
            let d = CGFloat(simd_distance(t, m)) / max(0.03, palmWidth)
            return max(0, min(1, (0.35 - d) / 0.35))
        }()
        let logits: [HandPose: Double] = [
            .fist: Double((1 - index) + (1 - middle) + (1 - ring) + (1 - little)),
            .openPalm: Double(index + middle + ring + little),
            .pinch: Double(closedness) * 4.0,
            .point: Double(index) * 3 - Double(middle + ring) * 1.4
                + Double(max(0, 0.48 - middle)) * 1.2
                + Double(max(0, 0.50 - thumb)) * 0.7,
            .peace: Double(index + middle) * 2 - Double(ring + little) * 2
                - Double(max(0, 0.55 - thumb)) * 2.4
                - Double(max(0, 0.58 - middle)) * 1.6
                + Double(min(1, max(0, spread3 - 0.16) / 0.20)) * 1.8
                - Double(thumbAtMCP) * 2.2,
            .thumbsUp: Double(thumb) * 2.8
                + Double((1 - index) + (1 - middle) + (1 - ring)) * 0.85
                - Double(closedness) * 1.3,
            .unknown: 0.3
        ]
        let keys = HandPose.allCases
        let sm = JointGeom.softmax(keys.map { logits[$0] ?? 0 }, temperature: 0.7)
        var probs: [HandPose: Double] = [:]
        for (i, k) in keys.enumerated() { probs[k] = sm[i] }
        f.probs = probs
        return f
    }
}

/// Pinzettenmaß 0…1 mit Zeit-Hysterese. Kein Entscheider mehr.
struct PinchGate {
    private(set) var closed = false
    private var lastRatio: CGFloat = 1
    private var lastT: TimeInterval = 0
    private var closeFor: TimeInterval = 0
    private var openFor: TimeInterval = 0
    private var missingSince: TimeInterval = 0
    private var space = AspectSpace.hd720

    mutating func reset() {
        closed = false
        lastRatio = 1
        lastT = 0
        closeFor = 0
        openFor = 0
        missingSince = 0
    }

    mutating func setSpace(_ s: AspectSpace) { space = s }

    mutating func update(
        raw: [VNHumanHandPoseObservation.JointName: CGPoint],
        conf: [VNHumanHandPoseObservation.JointName: Float],
        now: TimeInterval
    ) -> (closed: Bool, ratio: CGFloat, distance: CGFloat, closedness: Double) {
        GestureClassifier.space = space
        let scale = max(GestureClassifier.palmScale(raw, space: space), 0.04)
        let tipConf = min(conf[.thumbTip] ?? 0, conf[.indexTip] ?? 0)
        var dTips: CGFloat?
        if let a = raw[.thumbTip], let b = raw[.indexTip], tipConf > 0.18 {
            dTips = space.dist(a, b)
        }
        var dProx: CGFloat?
        if let a = raw[.thumbIP] ?? raw[.thumbTip], let b = raw[.indexDIP] ?? raw[.indexPIP] ?? raw[.indexTip] {
            dProx = space.dist(a, b)
        }
        let dist = dTips ?? ((dProx ?? 1) * 1.12)
        let ratio = dist / scale
        let proxRatio = (dProx ?? dist) / scale
        let dt = lastT == 0 ? 0.016 : max(0.008, min(0.08, now - lastT))
        let vel = (ratio - lastRatio) / CGFloat(dt)
        lastRatio = ratio
        lastT = now
        let closedness = max(0, min(1, (0.52 - min(ratio, proxRatio)) / 0.40))

        let wantClose = closedness > 0.55 || (ratio < 0.44 && vel < -1.6)
        let wantOpen = ratio > 0.56 && proxRatio > 0.50 && vel > -0.4

        if dTips == nil {
            if missingSince == 0 { missingSince = now }
            if now - missingSince > 0.32 {
                closed = false
                closeFor = 0
                openFor = 0
                return (false, ratio, dist, closedness)
            }
            if closed { return (true, min(ratio, 0.30), dist, max(closedness, 0.7)) }
            if wantClose { closeFor += dt } else { closeFor = 0 }
            if closeFor >= 0.045 { closed = true; closeFor = 0 }
            return (closed, ratio, dist, closedness)
        }
        missingSince = 0
        if closed {
            if wantOpen { openFor += dt; closeFor = 0 } else { openFor = 0 }
            if openFor >= 0.055 { closed = false; openFor = 0 }
        } else {
            if wantClose { closeFor += dt; openFor = 0 } else { closeFor = 0 }
            if closeFor >= 0.032 { closed = true; closeFor = 0 }
        }
        return (closed, ratio, dist, closedness)
    }
}

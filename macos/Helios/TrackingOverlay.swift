import SwiftUI
import Vision

enum FingerKind: String, CaseIterable, Identifiable {
    case thumb, index, middle, ring, little

    var id: String { rawValue }

    var labelDE: String {
        switch self {
        case .thumb: return "Daumen"
        case .index: return "Zeige"
        case .middle: return "Mittel"
        case .ring: return "Ring"
        case .little: return "Klein"
        }
    }

    var shortDE: String {
        switch self {
        case .thumb: return "D"
        case .index: return "Z"
        case .middle: return "M"
        case .ring: return "R"
        case .little: return "K"
        }
    }

    var tip: VNHumanHandPoseObservation.JointName {
        switch self {
        case .thumb: return .thumbTip
        case .index: return .indexTip
        case .middle: return .middleTip
        case .ring: return .ringTip
        case .little: return .littleTip
        }
    }

    var pip: VNHumanHandPoseObservation.JointName {
        switch self {
        case .thumb: return .thumbIP
        case .index: return .indexPIP
        case .middle: return .middlePIP
        case .ring: return .ringPIP
        case .little: return .littlePIP
        }
    }

    var mcp: VNHumanHandPoseObservation.JointName {
        switch self {
        case .thumb: return .thumbMP
        case .index: return .indexMCP
        case .middle: return .middleMCP
        case .ring: return .ringMCP
        case .little: return .littleMCP
        }
    }

    var chain: [VNHumanHandPoseObservation.JointName] {
        switch self {
        case .thumb: return [.wrist, .thumbCMC, .thumbMP, .thumbIP, .thumbTip]
        case .index: return [.wrist, .indexMCP, .indexPIP, .indexDIP, .indexTip]
        case .middle: return [.wrist, .middleMCP, .middlePIP, .middleDIP, .middleTip]
        case .ring: return [.wrist, .ringMCP, .ringPIP, .ringDIP, .ringTip]
        case .little: return [.wrist, .littleMCP, .littlePIP, .littleDIP, .littleTip]
        }
    }

    var color: Color {
        switch self {
        case .thumb: return Color(red: 1.00, green: 0.72, blue: 0.22)
        case .index: return Color(red: 0.31, green: 0.90, blue: 1.00)
        case .middle: return Color(red: 0.95, green: 0.95, blue: 0.98)
        case .ring: return Color(red: 0.40, green: 0.95, blue: 0.55)
        case .little: return Color(red: 0.95, green: 0.45, blue: 0.95)
        }
    }

    /// Farbenblind: Strichmuster je Finger, nicht nur Hue.
    var overlayDash: [CGFloat] {
        switch self {
        case .thumb: return []
        case .index: return [3, 2]
        case .middle: return [8, 3]
        case .ring: return [3, 2, 8, 2]
        case .little: return [1.5, 3]
        }
    }
}

struct JointLabel: Identifiable {
    var id: String
    var text: String
    var point: CGPoint
    var color: Color
}

struct TrackingOverlay: View {
    var hands: [TrackedHand]
    var showLabels: Bool
    var compact: Bool
    var actorHandID: String? = nil

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                Canvas { ctx, canvasSize in
                    for hand in hands where GestureMath.overlayDrawsGhost() || !hand.isGhost {
                        drawHand(hand, in: &ctx, size: canvasSize)
                    }
                }
                if showLabels {
                    ForEach(labels(in: size)) { item in
                        Text(item.text)
                            .font(.system(size: compact ? 8 : 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(item.color)
                            .shadow(color: .black.opacity(0.85), radius: 2)
                            .position(vis(item.point, size))
                            .offset(y: compact ? -8 : -11)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func drawHand(_ hand: TrackedHand, in ctx: inout GraphicsContext, size: CGSize) {
        let joints = hand.overlayJoints
        let isActor = actorHandID != nil && hand.id == actorHandID
        let hue = GestureMath.slotHue(hand.id)
        let slotCol: Color = hue == "amber" ? HeliosTheme.amber : HeliosTheme.cyan
        let side = isActor ? HeliosTheme.amber : slotCol
        let oldOp = ctx.opacity
        ctx.opacity = oldOp * hand.ghostBlend
        defer { ctx.opacity = oldOp }
        let pts = joints.compactMap { $0.value.confidence > 0.10 ? vis($0.value.point, size) : nil }
        if pts.count >= 3 {
            let xs = pts.map(\.x)
            let ys = pts.map(\.y)
            let pad: CGFloat = compact ? 10 : 16
            let rect = CGRect(
                x: (xs.min() ?? 0) - pad,
                y: (ys.min() ?? 0) - pad,
                width: (xs.max() ?? 0) - (xs.min() ?? 0) + pad * 2,
                height: (ys.max() ?? 0) - (ys.min() ?? 0) + pad * 2
            )
            ctx.stroke(
                Path(roundedRect: rect, cornerRadius: 4),
                with: .color(side.opacity(isActor ? 0.9 : 0.55)),
                style: StrokeStyle(lineWidth: isActor ? (compact ? 2.2 : 2.8) : 1, dash: (isActor && !hand.isGhost) ? [] : [4, 3])
            )
        }

        for finger in FingerKind.allCases {
            var path = Path()
            var started = false
            for name in finger.chain {
                guard let j = joints[name], j.confidence > 0.18 else { continue }
                if name == finger.tip, GestureMath.tipOccluded(
                    tip: j.point, palm: hand.palm, scale: hand.palmScale, extended: hand.isExtended(finger)
                ) { continue }
                let p = vis(j.point, size)
                if started { path.addLine(to: p) } else { path.move(to: p); started = true }
            }
            ctx.stroke(
                path,
                with: .color(finger.color.opacity(0.95)),
                style: StrokeStyle(lineWidth: compact ? 1.6 : 2.4, dash: finger.overlayDash)
            )
        }

        for (name, j) in joints where j.confidence > 0.18 {
            if let finger = FingerKind.allCases.first(where: { $0.tip == name }),
               GestureMath.tipOccluded(tip: j.point, palm: hand.palm, scale: hand.palmScale, extended: hand.isExtended(finger)) {
                continue
            }
            let p = vis(j.point, size)
            let isTip = FingerKind.allCases.contains { $0.tip == name }
            let r: CGFloat = isTip ? (compact ? 4 : 5.5) : (compact ? 2.2 : 3.2)
            let col = FingerKind.allCases.first { $0.chain.contains(name) }?.color ?? side
            let alpha = CGFloat(min(1, max(0.35, j.confidence)))
            ctx.fill(
                Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                with: .color(col.opacity(alpha))
            )
            if isTip {
                ctx.stroke(
                    Path(ellipseIn: CGRect(x: p.x - r - 2, y: p.y - r - 2, width: (r + 2) * 2, height: (r + 2) * 2)),
                    with: .color(col.opacity(0.8)),
                    lineWidth: 1
                )
            }
        }

        if let t = hand.overlayPoint(.thumbTip), let i = hand.overlayPoint(.indexTip) {
            let a = vis(t, size)
            let b = vis(i, size)
            var bar = Path()
            bar.move(to: a)
            bar.addLine(to: b)
            let closed = hand.pinchClosed
            ctx.stroke(
                bar,
                with: .color(closed ? HeliosTheme.amber : HeliosTheme.cyan.opacity(0.55)),
                style: StrokeStyle(lineWidth: closed ? (compact ? 3 : 4) : (compact ? 1.2 : 1.6), lineCap: .round)
            )
        }
    }

    private func labels(in size: CGSize) -> [JointLabel] {
        var out: [JointLabel] = []
        for hand in hands {
            if hand.isGhost {
                if GestureMath.overlayDrawsGhost(), let w = hand.overlayPoint(.wrist) {
                    let slot = GestureMath.slotChip(id: hand.id).map { " \($0)" } ?? ""
                    out.append(JointLabel(
                        id: "\(hand.id)-ghost",
                        text: compact ? "\(hand.id) Ghost" : "Ghost\(slot)",
                        point: w,
                        color: HeliosTheme.amber.opacity(0.7)
                    ))
                }
                continue
            }
            let hue = GestureMath.slotHue(hand.id)
            let sideColor: Color = hue == "amber" ? HeliosTheme.amber : HeliosTheme.cyan
            let side = hand.chirality == .left ? "L" : "R"
            if let w = hand.overlayPoint(.wrist) {
                let pose = hand.isGhost ? "Ghost" : hand.pose.labelDE
                let slot = GestureMath.slotChip(id: hand.id).map { " \($0)" } ?? ""
                out.append(JointLabel(
                    id: "\(hand.id)-wrist",
                    text: compact ? "\(hand.id) \(pose)" : "\(side == "L" ? "Links" : "Rechts") · \(pose)\(slot)",
                    point: w,
                    color: sideColor
                ))
            }
            for finger in FingerKind.allCases {
                guard let j = hand.overlayJoints[finger.tip], j.confidence > 0.28 else { continue }
                let mark = hand.isExtended(finger) ? "↑" : "·"
                out.append(JointLabel(
                    id: "\(hand.id)-\(finger.rawValue)",
                    text: compact ? "\(finger.shortDE)" : "\(finger.labelDE) \(mark)",
                    point: j.point,
                    color: finger.color
                ))
            }
        }
        return out
    }

    private func vis(_ p: CGPoint, _ size: CGSize) -> CGPoint {
        CGPoint(x: p.x * size.width, y: (1 - p.y) * size.height)
    }
}

struct CameraPreview: View {
    var image: NSImage?
    var hands: [TrackedHand]
    var showLabels: Bool
    var compact: Bool = false
    var placeholder: String = "Kamera starten"
    var actorHandID: String? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack {
                HeliosTheme.void
                if let image {
                    let rect = fitted(image.size, in: geo.size)
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.medium)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                    TrackingOverlay(hands: hands, showLabels: showLabels, compact: compact, actorHandID: actorHandID)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                }
            }
        }
    }

    private func fitted(_ image: CGSize, in box: CGSize) -> CGRect {
        guard image.width > 0, image.height > 0, box.width > 0, box.height > 0 else {
            return CGRect(origin: .zero, size: box)
        }
        let s = min(box.width / image.width, box.height / image.height)
        let w = image.width * s
        let h = image.height * s
        return CGRect(x: (box.width - w) / 2, y: (box.height - h) / 2, width: w, height: h)
    }
}

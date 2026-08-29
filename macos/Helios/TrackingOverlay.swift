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

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                Canvas { ctx, canvasSize in
                    for hand in hands {
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
        let side = hand.chirality == .left ? HeliosTheme.amber : HeliosTheme.cyan
        let pts = hand.joints.compactMap { $0.value.confidence > 0.2 ? vis($0.value.point, size) : nil }
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
                with: .color(side.opacity(0.55)),
                style: StrokeStyle(lineWidth: 1, dash: [4, 3])
            )
        }

        for finger in FingerKind.allCases {
            var path = Path()
            var started = false
            for name in finger.chain {
                guard let j = hand.joints[name], j.confidence > 0.22 else { continue }
                let p = vis(j.point, size)
                if started { path.addLine(to: p) } else { path.move(to: p); started = true }
            }
            ctx.stroke(path, with: .color(finger.color.opacity(0.95)), lineWidth: compact ? 1.6 : 2.4)
        }

        for (name, j) in hand.joints where j.confidence > 0.22 {
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
    }

    private func labels(in size: CGSize) -> [JointLabel] {
        var out: [JointLabel] = []
        for hand in hands {
            let sideColor = hand.chirality == .left ? HeliosTheme.amber : HeliosTheme.cyan
            let side = hand.chirality == .left ? "L" : "R"
            if let w = hand.point(.wrist) {
                out.append(JointLabel(
                    id: "\(hand.id)-wrist",
                    text: compact ? "\(side) \(hand.pose.labelDE)" : "\(side == "L" ? "Links" : "Rechts") · \(hand.pose.labelDE)",
                    point: w,
                    color: sideColor
                ))
            }
            for finger in FingerKind.allCases {
                guard let j = hand.joints[finger.tip], j.confidence > 0.35 else { continue }
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

    var body: some View {
        GeometryReader { geo in
            ZStack {
                HeliosTheme.void
                if let image {
                    let rect = fitted(image.size, in: geo.size)
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                    TrackingOverlay(hands: hands, showLabels: showLabels, compact: compact)
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

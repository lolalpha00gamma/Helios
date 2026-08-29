import SwiftUI
import Vision

struct HUDView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                if state.showReticle, let c = state.engineCursor {
                    let local = quartzToLocal(c, in: geo.size)
                    Reticle(armed: state.mode == .armed)
                        .position(x: local.x, y: local.y)
                }

                VStack {
                    topBar
                        .padding(.top, 18)
                    Spacer()
                    HStack(alignment: .bottom) {
                        cheatSheet
                        Spacer()
                        cameraChip
                    }
                    .padding(22)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
    }

    private func quartzToLocal(_ c: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(c.x, 8), size.width - 8),
            y: min(max(c.y, 8), size.height - 8)
        )
    }

    private var topBar: some View {
        HStack(spacing: 18) {
            Text("HELIOS")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(HeliosTheme.cyan)
                .shadow(color: HeliosTheme.cyan.opacity(0.8), radius: 8)
            statusPill
            Text(state.lastAction.uppercased())
                .font(HeliosTheme.mono)
                .foregroundStyle(HeliosTheme.amber)
            Spacer()
            Text(String(format: "%.0f ms   %.0f fps", state.latencyMs, state.fps))
                .font(HeliosTheme.mono)
                .foregroundStyle(HeliosTheme.cyan.opacity(0.8))
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(HeliosTheme.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(HeliosTheme.cyan.opacity(0.35), lineWidth: 1)
                )
        )
        .padding(.horizontal, 40)
    }

    private var statusPill: some View {
        Text(state.mode.labelDE)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundStyle(state.mode == .armed ? HeliosTheme.void : HeliosTheme.cyan)
            .background(state.mode == .armed ? HeliosTheme.amber : HeliosTheme.cyan.opacity(0.15))
            .overlay(
                Rectangle()
                    .stroke(state.mode == .armed ? HeliosTheme.amber : HeliosTheme.cyan, lineWidth: 1)
            )
    }

    private var cheatSheet: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("GESTEN")
                .font(HeliosTheme.mono)
                .foregroundStyle(HeliosTheme.cyan)
            Text("Faust halten   Scharf / Idle")
            Text("Zeigen         Cursor")
            Text("Pinzette       Klick / Fenster")
            Text("Zwei Hände     Skalieren")
            Text("Wischen        App wechseln")
            Text("Beide offen    Not-Aus")
        }
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .foregroundStyle(HeliosTheme.cyan.opacity(0.75))
        .padding(12)
        .background(HeliosTheme.panel)
        .overlay(Rectangle().stroke(HeliosTheme.cyan.opacity(0.25), lineWidth: 1))
        .opacity(state.showCheats ? 1 : 0)
    }

    private var cameraChip: some View {
        ZStack {
            if let img = state.preview {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                HeliosTheme.void
            }
            SkeletonOverlay(hands: state.hands)
        }
        .frame(width: 280, height: 158)
        .clipped()
        .overlay(Rectangle().stroke(HeliosTheme.cyan.opacity(0.5), lineWidth: 1))
        .overlay(alignment: .topLeading) {
            Text(state.deviceName)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(HeliosTheme.cyan)
                .padding(6)
        }
        .opacity(state.showPreviewChip ? 1 : 0)
    }
}

struct Reticle: View {
    var armed: Bool
    var body: some View {
        ZStack {
            Circle()
                .stroke(armed ? HeliosTheme.amber : HeliosTheme.cyan, lineWidth: 1.2)
                .frame(width: 28, height: 28)
            Circle()
                .fill(armed ? HeliosTheme.amber : HeliosTheme.cyan)
                .frame(width: 4, height: 4)
            ForEach(0..<4, id: \.self) { i in
                Rectangle()
                    .fill(armed ? HeliosTheme.amber : HeliosTheme.cyan)
                    .frame(width: i % 2 == 0 ? 10 : 1, height: i % 2 == 0 ? 1 : 10)
                    .offset(
                        x: i == 0 ? -22 : i == 1 ? 22 : 0,
                        y: i == 2 ? -22 : i == 3 ? 22 : 0
                    )
            }
        }
        .shadow(color: (armed ? HeliosTheme.amber : HeliosTheme.cyan).opacity(0.7), radius: 6)
    }
}

struct SkeletonOverlay: View {
    var hands: [TrackedHand]
    private let links: [(VNHumanHandPoseObservation.JointName, VNHumanHandPoseObservation.JointName)] = [
        (.wrist, .thumbCMC), (.thumbCMC, .thumbMP), (.thumbMP, .thumbIP), (.thumbIP, .thumbTip),
        (.wrist, .indexMCP), (.indexMCP, .indexPIP), (.indexPIP, .indexDIP), (.indexDIP, .indexTip),
        (.wrist, .middleMCP), (.middleMCP, .middlePIP), (.middlePIP, .middleDIP), (.middleDIP, .middleTip),
        (.wrist, .ringMCP), (.ringMCP, .ringPIP), (.ringPIP, .ringDIP), (.ringDIP, .ringTip),
        (.wrist, .littleMCP), (.littleMCP, .littlePIP), (.littlePIP, .littleDIP), (.littleDIP, .littleTip)
    ]

    var body: some View {
        Canvas { ctx, size in
            for hand in hands {
                let color: Color = hand.chirality == .left ? HeliosTheme.amber : HeliosTheme.cyan
                var path = Path()
                for (a, b) in links {
                    guard let pa = hand.point(a), let pb = hand.point(b) else { continue }
                    path.move(to: vis(pa, size))
                    path.addLine(to: vis(pb, size))
                }
                ctx.stroke(path, with: .color(color), lineWidth: 1.4)
                for j in hand.joints.values where j.confidence > 0.4 {
                    let p = vis(j.point, size)
                    ctx.fill(Path(ellipseIn: CGRect(x: p.x - 2, y: p.y - 2, width: 4, height: 4)), with: .color(color))
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func vis(_ p: CGPoint, _ size: CGSize) -> CGPoint {
        CGPoint(x: p.x * size.width, y: (1 - p.y) * size.height)
    }
}

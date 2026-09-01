import SwiftUI
import Vision

struct HUDView: View {
    @EnvironmentObject private var state: AppState
    var screenFrame: CGRect
    var isPrimary: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                if state.killFlash {
                    HeliosTheme.danger.opacity(0.18)
                }

                if state.showOutline, let target = state.focused,
                   target.quartzBounds.width > 40,
                   ScreenGeometry.intersects(quartz: target.quartzBounds, screen: screenFrame)
                {
                    windowOutline(target)
                }

                if state.calibActive {
                    calibOverlay
                }

                trashZone

                if isPrimary {
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
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
    }

    private var calibOverlay: some View {
        let target = state.calibSession.targetQuartz()
        let localRaw = ScreenGeometry.local(quartz: target, on: screenFrame)
        let local = CGPoint(
            x: min(max(localRaw.x, 70), screenFrame.width - 70),
            y: min(max(localRaw.y, 70), screenFrame.height - 70)
        )
        let onScreen = ScreenGeometry.contains(quartz: target, screen: screenFrame, pad: 40)
        return ZStack {
            HeliosTheme.void.opacity(0.28)
            if onScreen {
                CornerMark()
                    .stroke(HeliosTheme.cyan, lineWidth: 5)
                    .frame(width: 110, height: 110)
                    .position(x: local.x, y: local.y)
                Circle()
                    .trim(from: 0, to: max(0.02, state.calibHold))
                    .stroke(HeliosTheme.amber, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .frame(width: 86, height: 86)
                    .rotationEffect(.degrees(-90))
                    .position(x: local.x, y: local.y)
            }
            if isPrimary {
                VStack(spacing: 8) {
                    Text("KALIBRIERUNG")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(HeliosTheme.amber)
                    Text("Ecke \(state.calibCorner)   ·   \(state.calibSession.samples.count)/4")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(HeliosTheme.cyan)
                    Text(state.calibSession.hint)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.9))
                    Text("Nur Pinzette bestätigt. Danach öffnen und zur nächsten Ecke gehen.")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(HeliosTheme.amber)
                }
                .padding(16)
                .background(HeliosTheme.void.opacity(0.72))
                .padding(.top, 72)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private func windowOutline(_ target: FocusedTarget) -> some View {
        let r = ScreenGeometry.localRect(quartz: target.quartzBounds, on: screenFrame).insetBy(dx: -6, dy: -6)
        let grabbing = state.grabPhase == .grab
        let holding = state.grabPhase == .hold
        let col = grabbing ? HeliosTheme.amber : holding ? HeliosTheme.amber.opacity(0.85) : HeliosTheme.cyan
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6)
                .stroke(col, lineWidth: grabbing ? 4 : 2)
                .shadow(color: col.opacity(0.55), radius: grabbing ? 14 : 8)
                .frame(width: r.width, height: r.height)
            HStack(spacing: 8) {
                Image(systemName: grabbing ? "hand.raised.fill" : "app.fill")
                    .font(.system(size: 10))
                Text(grabbing ? "GREIFT · \(target.appName.uppercased())" : holding ? "HALTEN · \(target.appName.uppercased())" : target.appName.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                if !target.title.isEmpty {
                    Text("· \(target.title)")
                        .font(.system(size: 11, design: .monospaced))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(col)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(HeliosTheme.panel)
            .overlay(Rectangle().stroke(col.opacity(0.5), lineWidth: 1))
            .offset(x: 10, y: -28)
        }
        .position(x: r.midX, y: r.midY)
    }

    private var trashZone: some View {
        let r: CGRect = {
            if let s = ScreenGeometry.screen(matchingCocoa: screenFrame) {
                return ScreenGeometry.trashLocal(screen: s)
            }
            return ScreenGeometry.trashLocal(on: screenFrame)
        }()
        let hot = state.trashHot
        return VStack(spacing: 6) {
            Image(systemName: hot ? "trash.fill" : "trash")
                .font(.system(size: 28, weight: .medium))
            Text("WEGWERFEN")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
        }
        .foregroundStyle(hot ? HeliosTheme.void : HeliosTheme.cyan.opacity(0.8))
        .frame(width: r.width, height: r.height)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(hot ? HeliosTheme.danger.opacity(0.9) : HeliosTheme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(hot ? HeliosTheme.danger : HeliosTheme.cyan.opacity(0.35), lineWidth: hot ? 2 : 1)
        )
        .shadow(color: (hot ? HeliosTheme.danger : HeliosTheme.cyan).opacity(hot ? 0.7 : 0.2), radius: hot ? 16 : 4)
        .position(x: r.midX, y: r.midY)
        .opacity(state.showTrashZone ? 1 : 0)
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Text("HELIOS")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(HeliosTheme.cyan)
                .shadow(color: HeliosTheme.cyan.opacity(0.8), radius: 8)
            statusPill
            grabPill
            if state.testMode {
                Text("TEST")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .foregroundStyle(HeliosTheme.void)
                    .background(HeliosTheme.cyan)
            } else if state.fromDiskImage {
                Text("CURSOR FREI — NACH PROGRAMME ZIEHEN")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(HeliosTheme.amber)
            } else if state.mousePaused {
                Text("MAUS HAT VORRANG")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(HeliosTheme.amber)
            } else if state.mode == .armed && state.engineCursor == nil {
                Text("MAUS FREI — HAND IN DIE KAMERA")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(HeliosTheme.cyan)
            } else if state.mode == .idle {
                Text("FAUST HALTEN → SCHARF")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(HeliosTheme.amber)
            }
            if let app = state.focused {
                Text(app.appName.uppercased())
                    .font(HeliosTheme.mono)
                    .foregroundStyle(HeliosTheme.cyan)
            }
            Text(state.lastAction.uppercased())
                .font(HeliosTheme.mono)
                .foregroundStyle(HeliosTheme.amber)
            Spacer()
            Text("\(NSScreen.screens.count) MON")
                .font(HeliosTheme.mono)
                .foregroundStyle(HeliosTheme.cyan.opacity(0.7))
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
            .foregroundStyle(state.mode == .armed && !state.testMode ? HeliosTheme.void : HeliosTheme.cyan)
            .background(state.mode == .armed && !state.testMode ? HeliosTheme.amber : HeliosTheme.cyan.opacity(0.15))
            .overlay(
                Rectangle()
                    .stroke(state.mode == .armed && !state.testMode ? HeliosTheme.amber : HeliosTheme.cyan, lineWidth: 1)
            )
    }

    private var grabPill: some View {
        let phase = state.grabPhase
        let col: Color = {
            switch phase {
            case .grab: return HeliosTheme.amber
            case .hold: return HeliosTheme.amber.opacity(0.85)
            case .follow: return HeliosTheme.cyan
            case .none: return HeliosTheme.cyan.opacity(0.45)
            }
        }()
        let text: String = {
            switch phase {
            case .grab:
                let n = state.grabTargetName.isEmpty ? "FENSTER" : state.grabTargetName.uppercased()
                return "GREIFT · \(n)"
            case .hold: return "HALTEN — NOCH NICHT GEGRIFFEN"
            case .follow:
                let h = state.cursorHand == "—" ? "HAND" : state.cursorHand.uppercased()
                return "HIER · \(h)"
            case .none: return "KEINE HAND"
            }
        }()
        return Text(text)
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .foregroundStyle(phase == .grab || phase == .hold ? HeliosTheme.void : col)
            .background(phase == .grab || phase == .hold ? HeliosTheme.amber : col.opacity(0.15))
            .overlay(Rectangle().stroke(col, lineWidth: 1.5))
    }

    private var cheatSheet: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(state.testMode ? "TEST · GESTEN" : "GESTEN")
                .font(HeliosTheme.mono)
                .foregroundStyle(HeliosTheme.cyan)
            Text("Faust halten     Scharf")
            Text("Pinzette halten  Fenster unter der Hand ziehen")
            Text("Pinzette / Faust Greifen · Klick")
            Text("Werfen oben      Wegwerfen")
            Text("Werfen unten     Minimieren")
            Text("Offene Hand wischen  App wechseln")
            Text("Werfen L/R       Andocken")
            Text("Zwei Pinzetten   Skalieren")
            Text("Peace halten     Aufnahme")
            Text("Beide offen      Not-Aus")
        }
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .foregroundStyle(HeliosTheme.cyan.opacity(0.75))
        .padding(12)
        .background(HeliosTheme.panel)
        .overlay(Rectangle().stroke(HeliosTheme.cyan.opacity(0.25), lineWidth: 1))
        .opacity(state.showCheats ? 1 : 0)
    }

    private var cameraChip: some View {
        CameraPreview(
            image: state.preview,
            hands: state.hands,
            showLabels: state.showJointLabels,
            compact: true
        )
        .frame(width: 360, height: 202)
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

struct HandBeacon: View {
    var phase: GrabPhase
    var hand: String
    var target: String
    var local: CGPoint

    var body: some View {
        let grab = phase == .grab
        let hold = phase == .hold
        let col = grab || hold ? HeliosTheme.amber : HeliosTheme.cyan
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(col.opacity(0.35), lineWidth: 2)
                    .frame(width: grab ? 120 : 96, height: grab ? 120 : 96)
                Circle()
                    .stroke(col, lineWidth: grab ? 4 : 2.5)
                    .frame(width: 64, height: 64)
                Image(systemName: grab ? "hand.raised.fill" : hold ? "hand.point.up.left.fill" : "circle.fill")
                    .font(.system(size: grab ? 22 : 16, weight: .bold))
                    .foregroundStyle(col)
            }
            .shadow(color: col.opacity(0.9), radius: grab ? 16 : 8)
            Text(phase.labelDE)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(col)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(HeliosTheme.void.opacity(0.78))
            Text(hand.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(col)
            if grab, !target.isEmpty {
                Text(target.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(HeliosTheme.amber)
            }
            Text(String(format: "%.0f  %.0f", local.x, local.y))
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(col.opacity(0.8))
        }
    }
}

struct Reticle: View {
    var armed: Bool
    var body: some View {
        ZStack {
            Circle()
                .stroke(armed ? HeliosTheme.amber : HeliosTheme.cyan, lineWidth: 2)
                .frame(width: 56, height: 56)
            Circle()
                .stroke((armed ? HeliosTheme.amber : HeliosTheme.cyan).opacity(0.35), lineWidth: 1)
                .frame(width: 88, height: 88)
            Circle()
                .fill(armed ? HeliosTheme.amber : HeliosTheme.cyan)
                .frame(width: 7, height: 7)
            ForEach(0..<4, id: \.self) { i in
                Rectangle()
                    .fill(armed ? HeliosTheme.amber : HeliosTheme.cyan)
                    .frame(width: i % 2 == 0 ? 16 : 2, height: i % 2 == 0 ? 2 : 16)
                    .offset(
                        x: i == 0 ? -40 : i == 1 ? 40 : 0,
                        y: i == 2 ? -40 : i == 3 ? 40 : 0
                    )
            }
        }
        .shadow(color: (armed ? HeliosTheme.amber : HeliosTheme.cyan).opacity(0.85), radius: 10)
    }
}

struct CornerMark: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let l: CGFloat = min(rect.width, rect.height)
        p.move(to: CGPoint(x: 0, y: l * 0.45))
        p.addLine(to: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: l * 0.45, y: 0))
        p.move(to: CGPoint(x: l * 0.55, y: 0))
        p.addLine(to: CGPoint(x: l, y: 0))
        p.addLine(to: CGPoint(x: l, y: l * 0.45))
        p.move(to: CGPoint(x: l, y: l * 0.55))
        p.addLine(to: CGPoint(x: l, y: l))
        p.addLine(to: CGPoint(x: l * 0.55, y: l))
        p.move(to: CGPoint(x: l * 0.45, y: l))
        p.addLine(to: CGPoint(x: 0, y: l))
        p.addLine(to: CGPoint(x: 0, y: l * 0.55))
        return p
    }
}

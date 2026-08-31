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

                if state.showReticle, let c = state.engineCursor,
                   ScreenGeometry.contains(quartz: c, screen: screenFrame)
                {
                    let local = ScreenGeometry.local(quartz: c, on: screenFrame)
                    VStack(spacing: 6) {
                        Reticle(armed: state.mode == .armed && !state.testMode)
                        Text(state.cursorHand.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(state.mode == .armed && !state.testMode ? HeliosTheme.amber : HeliosTheme.cyan)
                        Text(String(format: "%.0f  %.0f", local.x, local.y))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(HeliosTheme.cyan.opacity(0.8))
                    }
                    .position(x: local.x, y: local.y)
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

    private func windowOutline(_ target: FocusedTarget) -> some View {
        let r = ScreenGeometry.localRect(quartz: target.quartzBounds, on: screenFrame).insetBy(dx: -6, dy: -6)
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6)
                .stroke(HeliosTheme.cyan, lineWidth: 2)
                .shadow(color: HeliosTheme.cyan.opacity(0.55), radius: 8)
                .frame(width: r.width, height: r.height)
            HStack(spacing: 8) {
                Image(systemName: "app.fill")
                    .font(.system(size: 10))
                Text(target.appName.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                if !target.title.isEmpty {
                    Text("· \(target.title)")
                        .font(.system(size: 11, design: .monospaced))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(HeliosTheme.cyan)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(HeliosTheme.panel)
            .overlay(Rectangle().stroke(HeliosTheme.cyan.opacity(0.4), lineWidth: 1))
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
            if state.testMode {
                Text("TEST")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .foregroundStyle(HeliosTheme.void)
                    .background(HeliosTheme.cyan)
            } else if state.fromDiskImage {
                Text("DMG — NACH PROGRAMME KOPIEREN")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(HeliosTheme.danger)
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

    private var cheatSheet: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(state.testMode ? "TEST · GESTEN" : "GESTEN")
                .font(HeliosTheme.mono)
                .foregroundStyle(HeliosTheme.cyan)
            Text("Faust halten     Scharf")
            Text("Handfläche       Ziehen (heben = neu ansetzen)")
            Text("Pinzette / Faust Greifen · Klick")
            Text("Werfen           Papierkorb / zu")
            Text("Offene Hand wischen  App wechseln")
            Text("Werfen L/R       Andocken")
            Text("Zwei Pinzetten   Skalieren")
            Text("Peace halten     Aufnahme")
            Text("Eine Hand offen  Mission Control")
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
            hands: state.displayHands,
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

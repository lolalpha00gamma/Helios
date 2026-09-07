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
                   (state.grabPhase == .hold || state.grabPhase == .grab),
                   target.quartzBounds.width > 40,
                   ScreenGeometry.intersects(quartz: target.quartzBounds, screen: screenFrame)
                {
                    windowOutline(target)
                        .transaction { $0.animation = nil }
                }

                if state.calibActive {
                    calibOverlay
                }

                if isPrimary, state.drill.phase != .idle {
                    drillOverlay
                }

                chromeLoupe

                if isPrimary {
                    airKeyboard
                }

                if state.showTrashZone {
                    trashZone
                }

                if isPrimary {
                    VStack {
                        topBar
                            .padding(.top, 18)
                        Spacer()
                        HStack(alignment: .bottom) {
                            if state.showCheats {
                                cheatSheet
                            }
                            Spacer()
                            if state.showPreviewChip {
                                cameraChip
                            }
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
                    Text(state.calibSession.cameraLabel.isEmpty
                         ? "KALIBRIERUNG · ANSCHLAG, NICHT KAMERARAND"
                         : "KALIBRIERUNG · \(state.calibSession.cameraLabel.uppercased())")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(HeliosTheme.amber)
                    Text("Ecke \(state.calibCorner)   ·   \(state.calibSession.samples.count)/4")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(HeliosTheme.cyan)
                    Text(state.calibSession.hint)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.9))
                    Text("Blickwinkel dieser Quelle. 4 Bildschirmecken, Anschlag in DIESEM Bild. Nur Pinzette bestätigt.")
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
            let s: CGFloat = 138
            return CGRect(x: screenFrame.width - s - 24, y: screenFrame.height - s - 24, width: s, height: s)
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
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Text("HELIOS")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(HeliosTheme.cyan)
                .shadow(color: HeliosTheme.cyan.opacity(0.8), radius: 8)
            statusPill
            grabPill
            clutchLED
            peaceRing
            if !state.lockFreeze.isEmpty {
                Text(state.lockFreeze.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .foregroundStyle(HeliosTheme.void)
                    .background(HeliosTheme.amber)
                    .overlay(Rectangle().stroke(HeliosTheme.amber, lineWidth: 1))
                    .help("Lock-ID hält einen Fehlframe — R1/R2 = Recover nach Dropout, kein Teleport")
            }
            if !state.permissionBanner.isEmpty {
                Text(state.permissionBanner.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(HeliosTheme.amber)
            } else if state.testMode {
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
            } else if state.mode == .armed && !state.mapReady && !state.testMode {
                Text("RELATIV — KALIBRIEREN · AUSSEN ABSOLUT")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(HeliosTheme.amber)
            } else if state.mode == .armed && state.engineCursor == nil {
                Text("MAUS FREI — HAND IN DIE KAMERA")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(HeliosTheme.cyan)
            } else if state.mode == .armed && !state.testMode {
                Text("☀ MENÜ → KONSOLE · BEENDEN")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(HeliosTheme.amber)
            } else if state.mode == .idle {
                Text(state.lastAction.localizedCaseInsensitiveContains("Not-Aus")
                     ? "NOT-AUS · FAUST ODER 2× KLATSCHEN"
                     : "FAUST ODER 2× KLATSCHEN → SCHARF")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(HeliosTheme.amber)
            }
            if let app = state.focused {
                let p = AppInjectProfile.of(bundleId: app.bundleId)
                Text(p == .full ? app.appName.uppercased() : "\(app.appName.uppercased()) · \(p.titleDE.uppercased())")
                    .font(HeliosTheme.mono)
                    .foregroundStyle(p == .off ? HeliosTheme.amber : HeliosTheme.cyan)
                    .lineLimit(1)
            }
            Text(state.lastAction.uppercased())
                .font(HeliosTheme.mono)
                .foregroundStyle(HeliosTheme.amber)
                .lineLimit(1)
            Spacer()
            Text("\(state.screenCount) MON")
                .font(HeliosTheme.mono)
                .foregroundStyle(HeliosTheme.cyan.opacity(0.7))
            Text(String(format: "%.0f ms   %.0f fps", state.latencyMs, state.fps))
                .font(HeliosTheme.mono)
                .foregroundStyle(state.fpsAmber ? HeliosTheme.amber : HeliosTheme.cyan.opacity(0.8))
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
        .frame(height: 48)
        .clipped()
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

    private var clutchLED: some View {
        Circle()
            .fill(state.mousePaused ? HeliosTheme.amber : HeliosTheme.ok)
            .frame(width: 8, height: 8)
            .shadow(color: (state.mousePaused ? HeliosTheme.amber : HeliosTheme.ok).opacity(0.8), radius: 4)
            .help(state.mousePaused ? "Maus hat Vorrang" : "Helios steuert")
    }

    private var peaceRing: some View {
        Circle()
            .trim(from: 0, to: max(0.02, state.peaceProgress))
            .stroke(HeliosTheme.amber, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .frame(width: 16, height: 16)
            .rotationEffect(.degrees(-90))
            .opacity(state.peaceProgress > 0 ? 1 : 0)
    }

    private var cheatSheet: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(state.testMode ? "TEST · GESTEN" : "GESTEN")
                .font(HeliosTheme.mono)
                .foregroundStyle(HeliosTheme.cyan)
            Text("Faust halten     Scharf")
            Text("2× Klatschen     Scharf (Kamera)")
            Text("Pinzette kurz    Klick")
            Text("Pinzette ziehen  Fenster")
            Text("Werfen nur Ruck  Dock / Mini")
            Text("Zeigen 0,85 s    Tastatur")
            Text("Taste verweilen  Tippen")
            Text("Offene Hand wischen  App")
            Text("Eine Hand hoch/runter  Scroll")
            Text("Zwei Hände        zwei Zeiger")
            Text("Pinzette + Ring  Rechtsklick")
            Text("Zwei Pinzetten   Skalieren")
            Text("Peace allein     Aufnahme")
            Text("Beide offen      Not-Aus")
        }
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .foregroundStyle(HeliosTheme.cyan.opacity(0.75))
        .padding(12)
        .background(HeliosTheme.panel)
        .overlay(Rectangle().stroke(HeliosTheme.cyan.opacity(0.25), lineWidth: 1))
    }

    private var cameraChip: some View {
        let coverCalib = state.calibActive && state.calibSession.cameraID == state.coverID && !state.coverID.isEmpty
        let pair = state.cameraPair != .single
        return HStack(alignment: .bottom, spacing: 8) {
            chip(
                image: coverCalib ? nil : state.preview,
                hands: state.hands.filter { !$0.id.hasPrefix("C.") },
                label: state.deviceName,
                width: pair ? 220 : 360,
                height: pair ? 124 : 202
            )
            .opacity(coverCalib ? 0.35 : 1)
            if pair {
                chip(
                    image: state.coverPreview,
                    hands: state.coverHands,
                    label: state.coverRunning
                        ? "\(state.coverName) · Ergänzung"
                        : (state.coverError ?? "Osmo nicht live"),
                    width: 220,
                    height: 124
                )
                .overlay(Rectangle().stroke(
                    coverCalib || state.actorSource == "cover" ? HeliosTheme.amber : HeliosTheme.cyan.opacity(0.5),
                    lineWidth: coverCalib ? 2 : 1
                ))
            }
        }
    }

    private func chip(
        image: NSImage?,
        hands: [TrackedHand],
        label: String,
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        CameraPreview(
            image: image,
            hands: hands,
            showLabels: state.showJointLabels,
            compact: true
        )
        .frame(width: width, height: height)
        .clipped()
        .overlay(Rectangle().stroke(HeliosTheme.cyan.opacity(0.5), lineWidth: 1))
        .overlay(alignment: .topLeading) {
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(HeliosTheme.cyan)
                .padding(6)
        }
    }

    @ViewBuilder
    private var drillOverlay: some View {
        let d = state.drill
        ZStack {
            HeliosTheme.void.opacity(0.45)
            VStack(spacing: 14) {
                Text("AKTIONSKALIBRIERUNG")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(HeliosTheme.cyan)
                Text("\(d.stepLabel)  ·  \(d.current.titleDE.uppercased())")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("Wiederholung \(min(d.repeatIndex + 1, 3)) / 3")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(HeliosTheme.amber)
                Text(d.current.hint)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 640)
                if d.phase == .countdown {
                    Text("\(max(1, d.countdown))")
                        .font(.system(size: 96, weight: .bold, design: .monospaced))
                        .foregroundStyle(HeliosTheme.cyan)
                } else if d.phase == .capture {
                    Text("AUFNAHME")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(HeliosTheme.void)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(HeliosTheme.amber)
                    Text(String(format: "%.1f s", d.captureLeft))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(HeliosTheme.amber)
                } else if d.phase == .rest || d.phase == .done {
                    Text(d.lastEvidence)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(HeliosTheme.cyan)
                        .multilineTextAlignment(.center)
                }
                ProgressView(value: d.progress)
                    .tint(HeliosTheme.cyan)
                    .frame(width: 360)
                if d.phase == .done {
                    Text("FERTIG — IN DER KONSOLE FÜR GROK KOPIEREN")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(HeliosTheme.amber)
                }
            }
            .padding(28)
            .background(HeliosTheme.panel)
            .overlay(Rectangle().stroke(HeliosTheme.cyan.opacity(0.5), lineWidth: 1))
        }
    }

    @ViewBuilder
    private var chromeLoupe: some View {
        if !state.chromeKnobs.isEmpty, let cursor = state.engineCursor {
            let knobs = state.chromeKnobs
            let near = knobs.contains {
                hypot(cursor.x - $0.center.x, cursor.y - $0.center.y) < GestureMath.chromeLoupe
            }
            if near {
                ZStack {
                    ForEach(Array(knobs.enumerated()), id: \.offset) { _, knob in
                        let local = ScreenGeometry.local(quartz: knob.center, on: screenFrame)
                        let hot = state.chromeHot == knob.labelDE
                        let size: CGFloat = hot ? 88 : 76
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(hot ? HeliosTheme.amber : HeliosTheme.void.opacity(0.78))
                                    .overlay(
                                        Circle().stroke(hot ? HeliosTheme.amber : HeliosTheme.cyan, lineWidth: hot ? 5 : 2)
                                    )
                                    .frame(width: size, height: size)
                                if hot, state.chromeDwell > 0.02 {
                                    Circle()
                                        .trim(from: 0, to: max(0.02, state.chromeDwell))
                                        .stroke(HeliosTheme.cyan, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                        .rotationEffect(.degrees(-90))
                                        .frame(width: size - 10, height: size - 10)
                                }
                                Text(knob.kind == .close ? "✕" : (knob.kind == .min ? "—" : "+"))
                                    .font(.system(size: hot ? 28 : 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(hot ? HeliosTheme.void : HeliosTheme.cyan)
                            }
                            Text(knob.labelDE.uppercased())
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(hot ? HeliosTheme.amber : HeliosTheme.cyan)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(HeliosTheme.panel)
                        }
                        .position(x: local.x, y: local.y)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var airKeyboard: some View {
        if state.keyboardVisible {
            ZStack {
                ForEach(state.keyboardHits) { key in
                    let r = ScreenGeometry.localRect(quartz: key.frame, on: screenFrame)
                    let hot = state.keyboardHover == key.id
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(hot ? HeliosTheme.amber.opacity(0.92) : HeliosTheme.void.opacity(0.78))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(hot ? HeliosTheme.amber : HeliosTheme.cyan.opacity(0.55), lineWidth: hot ? 3 : 1)
                            )
                        if hot, state.keyboardDwell > 0.02 {
                            RoundedRectangle(cornerRadius: 8)
                                .trim(from: 0, to: max(0.02, state.keyboardDwell))
                                .stroke(HeliosTheme.cyan, lineWidth: 3)
                        }
                        Text(key.label)
                            .font(.system(size: min(22, max(13, r.height * 0.42)), weight: .bold, design: .monospaced))
                            .foregroundStyle(hot ? HeliosTheme.void : .white)
                    }
                    .frame(width: r.width, height: r.height)
                    .position(x: r.midX, y: r.midY)
                }
                VStack(spacing: 4) {
                    Text("LUFT-TASTATUR  ·  0,12 s VERWEILEN TIPPT  ·  FAUST SCHLIESST")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(HeliosTheme.cyan)
                    Text("Taste halten — kein Pinzetten")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(10)
                .background(HeliosTheme.panel)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 8)
            }
        }
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

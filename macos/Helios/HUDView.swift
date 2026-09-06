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
                    HeliosTheme.danger.opacity(0.22)
                    if GestureMath.killRingOnAllDisplays() {
                        Rectangle()
                            .strokeBorder(HeliosTheme.danger.opacity(0.92), lineWidth: 16)
                    }
                }

                if state.mousePaused, isPrimary {
                    mousePriorityBanner
                } else if state.mode == .idle, state.awaitingRearm, isPrimary, !state.testMode {
                    rearmBanner
                } else if isPrimary, state.mapDrifted, !state.calibActive, !state.testMode {
                    mapDriftBanner
                } else if isPrimary, state.engine.mapMissingChip != nil, state.mapReady, !state.calibActive, !state.testMode {
                    mapMissingBanner
                } else if isPrimary, !state.mapReady, !state.calibActive, !state.testMode {
                    calibHintBanner
                }

                if isPrimary, state.cameraFallback, !state.calibActive {
                    cameraFallbackBanner
                }

                if isPrimary, state.dualCamAvailable, state.cameraFallback, !state.calibActive {
                    dualCamBanner
                }

                if isPrimary, state.cameraSlow, state.cameraRunning, !state.calibActive {
                    cameraSlowBanner
                }


                if isPrimary, state.lumaLow, state.cameraRunning, !state.calibActive {
                    lumaBanner
                }

                if isPrimary, state.accessDropped, !state.testMode {
                    accessDroppedBanner
                }

                if state.showOutline, let target = state.focused,
                   (state.grabPhase == .hold || state.grabPhase == .grab),
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
            .opacity(state.hudDim && !state.killFlash ? GestureMath.hudDimOpacity : 1)
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
                    if let rms = GestureMath.mapRMSLabel(state.calibSession.liveRMS) {
                        Text(rms)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(
                                GestureMath.mapRMSReady(state.calibSession.liveRMS ?? .infinity)
                                    ? HeliosTheme.cyan
                                    : HeliosTheme.danger
                            )
                    }
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

    private var statusChips: [String] {
        GestureMath.overlayChipCap([
            state.roiLatchChip,
            state.engine.palmHighpassChip,
            state.engine.palmVelChip,
            state.engine.palmLateralityChip,
            state.engine.occlusionChip,
            state.engine.pointerPredictChip,
            state.engine.warpWriterChip
        ].compactMap { $0 }.filter { !$0.isEmpty })
    }

    private func statusChipFill(_ chip: String) -> Color {
        switch GestureMath.overlayChipTone(chip) {
        case 1: return HeliosTheme.danger
        case 2: return HeliosTheme.cyan
        default: return HeliosTheme.amber
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Text("HELIOS")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(HeliosTheme.cyan)
                .shadow(color: HeliosTheme.cyan.opacity(0.8), radius: 8)
            statusPill
            grabPill
            Text(state.engine.phaseChip)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .foregroundStyle(HeliosTheme.void)
                .background(HeliosTheme.cyan)
            if let game = state.engine.gameChip {
                Text(game)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .foregroundStyle(HeliosTheme.void)
                    .background(HeliosTheme.danger)
            }
            if let steal = state.engine.stealChip {
                Text(steal)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .foregroundStyle(HeliosTheme.void)
                    .background(HeliosTheme.amber)
            }
            if let slot = state.engine.slotChip {
                Text(slot)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .foregroundStyle(HeliosTheme.void)
                    .background(HeliosTheme.cyan.opacity(0.85))
            }
            if let kalib = state.engine.mapMissingChip {
                Text(kalib)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .foregroundStyle(HeliosTheme.void)
                    .background(HeliosTheme.amber)
            }
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
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .foregroundStyle(HeliosTheme.void)
                    .background(HeliosTheme.amber)
            } else if state.mode == .idle, state.awaitingRearm {
                Text("NACH NOT-AUS · FAUST \(Self.rearmHoldDE) s")
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
            if let latch = state.engine.latchChip {
                Text(latch)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .foregroundStyle(HeliosTheme.void)
                    .background(HeliosTheme.amber)
            }
            if state.engine.rightHeld {
                Text("RECHTS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .foregroundStyle(HeliosTheme.void)
                    .background(HeliosTheme.amber)
            }
            if let arm = state.engine.fistArmChip {
                Text(arm)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .foregroundStyle(HeliosTheme.void)
                    .background(HeliosTheme.cyan)
            }
            if let idle = state.engine.deadManChip {
                Text(idle)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .foregroundStyle(HeliosTheme.void)
                    .background(HeliosTheme.danger)
            }
            if let mod = state.engine.modifierChip {
                Text(mod)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .foregroundStyle(HeliosTheme.void)
                    .background(HeliosTheme.cyan)
            }
            if let ring = GestureMath.hoverRingLabel(state.engine.hoverKind) {
                Text(ring)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .foregroundStyle(HeliosTheme.void)
                    .background(state.engine.hoverKind == .magnet ? HeliosTheme.danger : HeliosTheme.amber)
            }
            if let weg = GestureMath.travelHUDLabel(state.engine.travelProgress) {
                Text(weg)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(HeliosTheme.danger)
            }
            if state.engine.pointerClutch, state.grabPhase == .follow {
                Text("CLUTCH")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .foregroundStyle(HeliosTheme.void)
                    .background(HeliosTheme.amber)
            }
            if let edge = state.engine.destEdgeChip {
                Text(edge)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .foregroundStyle(HeliosTheme.void)
                    .background(HeliosTheme.amber)
            }
            if let slot = state.actorHandID {
                if let g = state.hands.first(where: { $0.id == slot && $0.isGhost }) {
                    Text(String(format: "%@ Ghost %.1f s · %@ %@", slot, g.ghostRemaining, GestureMath.fpsLatchChip(fps: state.fps, ghosting: true, frozen: state.engine.pointerClutch, edge: state.engine.destEdgeChip != nil, band: state.formatChip.isEmpty ? nil : state.formatChip), state.fpsSpark))
                        .font(HeliosTheme.mono)
                        .foregroundStyle(HeliosTheme.amber.opacity(0.9))
                } else {
                    Text(String(format: "%@ · %@ %@", slot, GestureMath.fpsLatchChip(fps: state.fps, ghosting: false, frozen: state.engine.pointerClutch, edge: state.engine.destEdgeChip != nil, band: state.formatChip.isEmpty ? nil : state.formatChip), state.fpsSpark))
                        .font(HeliosTheme.mono)
                        .foregroundStyle(HeliosTheme.cyan.opacity(0.7))
                }
            }
            Spacer()
            Text("\(NSScreen.screens.count) MON")
                .font(HeliosTheme.mono)
                .foregroundStyle(HeliosTheme.cyan.opacity(0.7))
            Text(String(format: "%.0f ms   %.0f fps   %@", state.latencyMs, state.fps, GestureMath.visionMsSpark(state.visionMs)))
                .font(HeliosTheme.mono)
                .foregroundStyle(state.visionMs > GestureMath.axBudgetMs ? HeliosTheme.amber : HeliosTheme.cyan.opacity(0.8))
            if !state.formatChip.isEmpty {
                Text(state.formatChip)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(HeliosTheme.amber.opacity(0.9))
            }
            ForEach(Array(statusChips.enumerated()), id: \.offset) { _, chip in
                Text(chip)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .foregroundStyle(HeliosTheme.void)
                    .background(statusChipFill(chip).opacity(0.85))
            }
            if state.cameraSlow {
                Text("KAMERA ZU LANGSAM")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(HeliosTheme.danger)
            }
            if state.cameraFallback {
                Text("FALLBACK-CAM")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(HeliosTheme.amber)
            }
            if state.mapDrifted {
                Text("MAP DRIFT")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(HeliosTheme.danger)
            }
            if state.hudDim {
                Text("DIM")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(HeliosTheme.cyan.opacity(0.7))
            }
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
                if let fling = GestureMath.flingGhostLabel(state.engine.flingGhostKind) {
                    return fling
                }
                let n = state.grabTargetName.isEmpty ? "FENSTER" : state.grabTargetName.uppercased()
                return "GREIFT · \(n)"
            case .hold:
                if let label = GestureMath.hoverRingLabel(state.engine.hoverKind) {
                    return label
                }
                if let s = state.engine.clickSettle, s < 1 {
                    return "KLICK \(Int((s * 100).rounded())) %"
                }
                if let weg = GestureMath.travelHUDLabel(state.engine.travelProgress) {
                    return weg
                }
                if let h = state.engine.hoverProgress, h > 0 {
                    return "HOVER \(Int((h * 100).rounded())) %"
                }
                return "HALTEN — NOCH NICHT GEGRIFFEN"
            case .follow:
                if let label = GestureMath.hoverRingLabel(state.engine.hoverKind) {
                    if let h = state.engine.hoverProgress, h > 0.15 {
                        return "\(label) \(Int((h * 100).rounded())) %"
                    }
                    return label
                }
                if let h = state.engine.hoverProgress, h > 0.15 {
                    return "HOVER \(Int((h * 100).rounded())) %"
                }
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
            Text("Escape           Pinch abbrechen")
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
            compact: true,
            actorHandID: state.actorHandID
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

    private var mousePriorityBanner: some View {
        VStack(spacing: 10) {
            Text("MAUS HAT VORRANG")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundStyle(HeliosTheme.void)
            Text("Echte Mausbewegung — Gesten pausiert")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(HeliosTheme.void.opacity(0.8))
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 22)
        .background(HeliosTheme.amber.opacity(0.92))
        .overlay(Rectangle().stroke(HeliosTheme.void.opacity(0.35), lineWidth: 2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var rearmBanner: some View {
        VStack(spacing: 8) {
            Text("NOT-AUS")
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(HeliosTheme.amber)
            Text("Faust \(Self.rearmHoldDE) s halten → wieder scharf")
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
        .background(HeliosTheme.void.opacity(0.78))
        .overlay(Rectangle().stroke(HeliosTheme.amber.opacity(0.7), lineWidth: 2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var mapDriftBanner: some View {
        HStack(spacing: 10) {
            Text("KALIBRIERUNG VERRUTSCHT")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(HeliosTheme.amber)
            Text("Homographie treibt > 2 s — Relativzeiger. 4 Ecken neu.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(HeliosTheme.void.opacity(0.72))
        .overlay(Rectangle().stroke(HeliosTheme.amber.opacity(0.45), lineWidth: 1))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 86)
    }

    private var mapMissingBanner: some View {
        HStack(spacing: 10) {
            Text("KALIB HIER")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(HeliosTheme.void)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(HeliosTheme.amber)
            Text("Dieser Bildschirm hat keine Homographie — 4 Ecken hier, nicht die Laptop-Map.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(HeliosTheme.void.opacity(0.72))
        .overlay(Rectangle().stroke(HeliosTheme.amber.opacity(0.7), lineWidth: 1))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 86)
    }

    private var cameraFallbackBanner: some View {
        HStack(spacing: 10) {
            Text("CONTINUITY / DESK-VIEW")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(HeliosTheme.amber)
            Text("Keine Built-in-Frontkamera — Gesten ungenauer")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(HeliosTheme.void.opacity(0.72))
        .overlay(Rectangle().stroke(HeliosTheme.amber.opacity(0.45), lineWidth: 1))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, state.mapReady && !state.mapDrifted ? 86 : 122)
    }

    private var dualCamBanner: some View {
        HStack(spacing: 10) {
            Text("FRONTKAMERA DA")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(HeliosTheme.amber)
            Text("Continuity aktiv — Built-in wäre genauer. Kamera im Panel wählen.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(HeliosTheme.void.opacity(0.72))
        .overlay(Rectangle().stroke(HeliosTheme.amber.opacity(0.45), lineWidth: 1))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 158)
    }

    private var cameraSlowBanner: some View {
        HStack(spacing: 10) {
            Text("KAMERA ZU LANGSAM")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(HeliosTheme.danger)
            Text("unter 6 fps — Zeiger gedämpft")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(HeliosTheme.void.opacity(0.72))
        .overlay(Rectangle().stroke(HeliosTheme.danger.opacity(0.45), lineWidth: 1))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 122)
    }

    private var lumaBanner: some View {
        HStack(spacing: 10) {
            Text("ZU DUNKEL")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(HeliosTheme.amber)
            Text("Kein Vision — Licht oder Kamera")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(HeliosTheme.void.opacity(0.72))
        .overlay(Rectangle().stroke(HeliosTheme.amber.opacity(0.7), lineWidth: 1))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 86)
    }

    private var accessDroppedBanner: some View {
        HStack(spacing: 10) {
            Text("BEDIENUNGSHILFEN AUS")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(HeliosTheme.danger)
            Text("Datenschutz · Schalter aus und wieder an")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(HeliosTheme.void.opacity(0.72))
        .overlay(Rectangle().stroke(HeliosTheme.danger.opacity(0.7), lineWidth: 1))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 86)
    }

    private var calibHintBanner: some View {
        HStack(spacing: 10) {
            Text("RELATIVZEIGER")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(HeliosTheme.amber)
            Text("Kalibrierung: 4 Ecken — genauer, weniger Drift")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(HeliosTheme.void.opacity(0.72))
        .overlay(Rectangle().stroke(HeliosTheme.amber.opacity(0.45), lineWidth: 1))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 86)
    }

    private static var rearmHoldDE: String {
        String(format: "%.2f", GestureMath.rearmHold).replacingOccurrences(of: ".", with: ",")
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

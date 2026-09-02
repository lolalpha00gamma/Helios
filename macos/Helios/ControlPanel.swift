import SwiftUI

struct ControlPanel: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        HSplitView {
            left
                .frame(minWidth: 280, idealWidth: 310)
            preview
                .frame(minWidth: 440)
            inspector
                .frame(minWidth: 250, idealWidth: 300)
        }
        .background(HeliosTheme.void)
        .preferredColorScheme(.dark)
    }

    private var left: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("HELIOS")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(HeliosTheme.cyan)
                Spacer()
                Text(state.mode.labelDE)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(state.mode == .armed && !state.testMode ? HeliosTheme.amber : HeliosTheme.cyan.opacity(0.15))
                    .foregroundStyle(state.mode == .armed && !state.testMode ? HeliosTheme.void : HeliosTheme.cyan)
            }

            Toggle(isOn: Binding(
                get: { state.leftHanded },
                set: { state.setLeftHanded($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Linkshänder")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Dominante Hand. Standard: rechts — sonst folgt der Cursor der falschen Hand.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)

            Toggle(isOn: Binding(
                get: { state.protocolMode },
                set: { state.setProtocolMode($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Protokollmodus")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Zeigt Erkennung und ob das System die Aktion wirklich ausgeführt hat.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)

            Toggle(isOn: Binding(
                get: { state.dwellEnabled },
                set: { state.setDwellEnabled($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dwell-Klick")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Offene Hand eine Sekunde still = Klick. Aus by default.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)

            Toggle(isOn: Binding(
                get: { state.testMode },
                set: { state.setTestMode($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Testmodus")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Erkennung anzeigen, keine Klicks und kein Fensterzugriff.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)
            .padding(10)
            .background(state.testMode ? HeliosTheme.cyan.opacity(0.12) : Color.white.opacity(0.04))
            .overlay(
                Rectangle().stroke(state.testMode ? HeliosTheme.cyan.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
            )

            GroupBox("Rechte") {
                VStack(alignment: .leading, spacing: 8) {
                    permRow(.camera, ok: state.cameraOK)
                    permRow(.accessibility, ok: state.accessOK)
                    permRow(.inputMonitoring, ok: state.inputOK)
                    Text("Diese Kopie: \(state.installPath)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(state.fromDiskImage ? HeliosTheme.danger : .secondary)
                        .textSelection(.enabled)
                    if AppInstall.isTranslocated && AppInstall.originalIsInApplications {
                        Text("macOS startet eine Quarantäne-Kopie. Rechte gelten erst nach Entfernen der Quarantäne. Helios versucht das selbst; sonst im Terminal:")
                            .font(.system(size: 11))
                            .foregroundStyle(HeliosTheme.amber)
                        Text("xattr -dr com.apple.quarantine /Applications/Helios.app")
                            .font(.system(size: 10, design: .monospaced))
                            .textSelection(.enabled)
                    } else if state.fromDiskImage {
                        Text("Cursor-Steuerung ist aus, damit du Helios.app mit der Maus nach Programme ziehen kannst. Starte danach nur die Kopie in Programme.")
                            .font(.system(size: 11))
                            .foregroundStyle(HeliosTheme.amber)
                        Button("Nach Programme kopieren und öffnen") {
                            AppInstall.installAndRelaunch()
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Text("Nach einem Update den Schalter Bedienungshilfen einmal aus- und wieder einschalten.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Button("Systemeinstellungen öffnen") {
                            Permissions.openPrivacyPane(.accessibility)
                            Permissions.openPrivacyPane(.inputMonitoring)
                        }
                    }
                }
                .padding(.top, 4)
            }

            GroupBox("Sitzung") {
                VStack(alignment: .leading, spacing: 8) {
                    Button(state.cameraRunning ? "Kamera stoppen" : "Kamera starten") {
                        if state.cameraRunning { state.stopCamera() } else { Task { await state.startCamera() } }
                    }
                    HStack {
                        Button("Scharf") { state.engine.forceArm() }
                        Button("Idle") { state.engine.forceIdle() }
                    }
                    Toggle("HUD-Overlay", isOn: $state.hudVisible)
                    Toggle("Fadenkreuz", isOn: $state.showReticle)
                    Toggle("Kamera-Chip", isOn: $state.showPreviewChip)
                    Toggle("Gelenk-Beschriftung", isOn: $state.showJointLabels)
                    Toggle("Gestenhilfe", isOn: $state.showCheats)
                    Toggle("App-Umriss", isOn: $state.showOutline)
                    Toggle("Papierkorb-Zone", isOn: $state.showTrashZone)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Zeiger-Empfindlichkeit")
                            Spacer()
                            Text(String(format: "%.1f×", state.pointerGain))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(HeliosTheme.cyan)
                        }
                        Slider(
                            value: Binding(
                                get: { state.pointerGain },
                                set: { state.setPointerGain($0) }
                            ),
                            in: 0.6...3.2,
                            step: 0.1
                        )
                        Text("Wie ein Trackpad: Hand heben, in der Kamera neu ansetzen, weiterziehen — so erreichst du jeden Bildschirmrand, ohne aus dem Bild zu gehen.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Button("Zeiger neu ansetzen") {
                            state.engine.recenterPointer()
                        }
                        .buttonStyle(.borderless)
                        HStack {
                            Text("Fusion-Temperatur")
                            Spacer()
                            Text(String(format: "%.2f", state.fusionTemperature))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(HeliosTheme.cyan)
                        }
                        Slider(
                            value: Binding(
                                get: { state.fusionTemperature },
                                set: { state.setFusionTemperature($0) }
                            ),
                            in: 0.35...1.20,
                            step: 0.05
                        )
                        Text("Niedriger = schärfere Pose, höher = weicher. 0,75 ist der Default.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            GroupBox("Kalibrierung") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(state.mapReady ? "Karte gespeichert — Handfläche = dieser Schirm." : "Noch nicht kalibriert — Zeiger relativ.")
                        .font(.system(size: 11))
                        .foregroundStyle(state.mapReady ? HeliosTheme.cyan : .secondary)
                    if let rmse = state.mapRMSE, state.mapReady {
                        Text(rmse > 12
                             ? String(format: "RMSE %.0f px — Mitte nochmal", rmse)
                             : String(format: "RMSE %.0f px", rmse))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(rmse > 12 ? HeliosTheme.amber : HeliosTheme.cyan)
                    }
                    if state.calibActive {
                        Text("Jetzt: \(state.calibCorner). \(state.calibSession.samples.count)/\(state.calibSession.totalSpots)")
                            .font(.system(size: 11))
                            .foregroundStyle(HeliosTheme.amber)
                        if let live = state.liveRMSE {
                            Text(String(format: "live RMSE %.0f px", live))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(live > 12 ? HeliosTheme.amber : HeliosTheme.cyan)
                        }
                        HStack {
                            Button("Diesen Punkt überspringen") { state.skipCalibrationPoint() }
                            Button("Zurück") { state.undoCalibrationPoint() }
                                .disabled(!state.calibSession.canUndo)
                            Button("Abbrechen") { state.cancelCalibration() }
                        }
                    } else {
                        Button("9 Punkte kalibrieren") { state.startCalibration(ninePoint: true) }
                            .buttonStyle(.borderedProminent)
                        Button("Nur vier Ecken") { state.startCalibration(ninePoint: false) }
                            .buttonStyle(.borderless)
                    }
                    if state.mapReady {
                        Button("Kalibrierung löschen") { state.clearCalibration() }
                            .buttonStyle(.borderless)
                    }
                    Text("Je Punkt die Hand dorthin halten, wo für dich die Stelle auf DIESEM Schirm ist. 9 Punkte glätten die Homographie (DLT). Pro Display ein eigenes Gitter. Punkt hinter dem Deckel überspringen, falschen Punkt zurück.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        ForEach(Array(NSScreen.screens.enumerated()), id: \.offset) { i, screen in
                            let id = ScreenGeometry.displayID(of: screen)
                            let ready = SpaceMap.isCalibrated(displayID: id)
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(ready ? HeliosTheme.cyan : HeliosTheme.danger)
                                    .frame(width: 8, height: 8)
                                Text("M\(i + 1)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(ready ? HeliosTheme.cyan : .secondary)
                            }
                        }
                    }
                }
            }

            GroupBox("Profil") {
                VStack(alignment: .leading, spacing: 8) {
                    if let app = state.focused {
                        Text("\(app.appName) · \(state.profileName)")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Safari blockt Werfen by default. Hier darfst du Gesten wieder anmachen — Defaults bleiben konservativ.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        ForEach(GestureAction.allCases, id: \.self) { action in
                            Toggle(isOn: Binding(
                                get: { state.engine.profile.allows(action) },
                                set: { state.setProfileAction(action, on: $0) }
                            )) {
                                Text(action.titleDE)
                                    .font(.system(size: 11))
                            }
                            .toggleStyle(.checkbox)
                            .disabled(app.bundleId.isEmpty)
                        }
                        Toggle(isOn: Binding(
                            get: { state.engine.profile.invertScroll },
                            set: { state.setInvertScroll($0) }
                        )) {
                            Text("Scroll invertieren")
                                .font(.system(size: 11))
                        }
                        .toggleStyle(.checkbox)
                        .disabled(app.bundleId.isEmpty)
                        Text("Browser default an (wie Natural-Scroll). Finder aus.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Kein Vordergrund-Fenster — Profil folgt der App unter dem Cursor.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            GroupBox("Erkennung") {
                LabeledContent("Hände", value: "\(state.hands.count)")
                LabeledContent("Aktion", value: state.lastAction)
                LabeledContent("Latenz", value: String(format: "%.0f ms · %.0f fps", state.latencyMs, state.fps))
                LatencySpark(values: state.latencyHistory)
                LabeledContent("Licht", value: state.luma < 0.20 ? "Dunkel — nur Scroll" : state.luma < 0.28 ? "Dämmer — Klick gedämpft" : state.luma < 0.45 ? "Gedämpft" : "OK")
                LabeledContent("Monitore", value: "\(state.screenCount)")
                LabeledContent("Tiefe", value: state.hasDepth ? "Kanal aktiv" : "nur 3D-Lift")
                if let app = state.focused {
                    LabeledContent("App", value: "\(app.appName) · \(state.profileName)")
                }
                if state.hands.isEmpty {
                    Text("Keine Hand im Bild — Handfläche zur Kamera, guter Kontrast.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
            Text(state.testMode
                 ? "Testmodus: Gesten werden erkannt, das System bleibt unangetastet."
                 : "Live · \(state.leftHanded ? "Linke" : "Rechte") Hand = Position. Pinzette greift. Wischen = App. Beide still offen = Not-Aus. Safari blockt Werfen.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
    }

    private func permRow(_ kind: PermissionKind, ok: Bool) -> some View {
        HStack {
            Circle()
                .fill(ok ? HeliosTheme.ok : HeliosTheme.danger)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 1) {
                Text(kind.title).font(.system(size: 12, weight: .semibold))
                Text(kind.hint).font(.system(size: 10)).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Erlauben") {
                switch kind {
                case .camera:
                    Task { await state.startCamera() }
                case .accessibility:
                    Permissions.promptAccessibility()
                    Permissions.openPrivacyPane(.accessibility)
                case .inputMonitoring:
                    Permissions.openPrivacyPane(.inputMonitoring)
                }
            }
            .buttonStyle(.borderless)
        }
    }

    private var preview: some View {
        ZStack {
            CameraPreview(
                image: state.preview,
                hands: state.hands,
                showLabels: state.showJointLabels,
                compact: false,
                placeholder: state.cameraError ?? "Kamera starten"
            )
            if state.preview == nil {
                VStack(spacing: 8) {
                    Image(systemName: "sun.max")
                        .font(.system(size: 36))
                        .foregroundStyle(HeliosTheme.cyan)
                    Text(state.cameraError ?? "Kamera starten")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .overlay(alignment: .topLeading) {
            if state.testMode {
                Text("TESTMODUS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .foregroundStyle(HeliosTheme.void)
                    .background(HeliosTheme.cyan)
                    .padding(10)
            }
        }
        .overlay(alignment: .topTrailing) {
            Text(state.deviceName)
                .font(HeliosTheme.mono)
                .padding(10)
                .foregroundStyle(HeliosTheme.cyan)
        }
        .padding(8)
    }

    private var inspector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HÄNDE · FINGER")
                .font(HeliosTheme.mono)
                .foregroundStyle(HeliosTheme.cyan)
            FusionStrip(fusion: state.fusion, hasDepth: state.hasDepth)
            if state.hands.isEmpty {
                Text("Warte auf Erkennung…")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(state.hands) { hand in
                        handCard(hand)
                    }
                    Divider()
                    Text("PROTOKOLL")
                        .font(HeliosTheme.mono)
                        .foregroundStyle(HeliosTheme.cyan)
                    HStack {
                        Button("Leeren") { state.log.clear() }
                            .buttonStyle(.borderless)
                            .font(.system(size: 11))
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Button("Sitzung exportieren…") { state.exportSession() }
                            .keyboardShortcut("e", modifiers: [.command])
                        Button("Protokoll kopieren") { state.copyProtocol() }
                        Button("Filmstreifen kopieren") { state.copyFilmstrip() }
                        Divider()
                        Button(state.replayActive ? "Replay aus" : "Replay im HUD") {
                            if state.replayActive { state.stopReplay() } else { state.startReplay() }
                        }
                        Button("gesten.jsonl laden…") { state.loadReplayFile() }
                        if state.replayActive, !state.replayFrames.isEmpty {
                            HStack {
                                Button(state.replayPlaying ? "Pause" : "Play") {
                                    state.setReplayPlaying(!state.replayPlaying)
                                }
                                Button("−") { state.setReplayIndex(state.replayIndex - 1) }
                                Button("+") { state.setReplayIndex(state.replayIndex + 1) }
                            }
                            Slider(
                                value: Binding(
                                    get: { Double(state.replayIndex) },
                                    set: { state.setReplayIndex(Int($0.rounded())) }
                                ),
                                in: 0...Double(max(state.replayFrames.count - 1, 1)),
                                step: 1
                            )
                            Text("Frame \(state.replayIndex + 1)/\(state.replayFrames.count)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        Text("JSONL/TXT + PNG. Replay spielt Landmark-Frames im HUD — ohne Xcode.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    ForEach(Array(state.log.entries.suffix(120).reversed())) { e in
                        HStack(alignment: .top, spacing: 6) {
                            Text(e.at, style: .time)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 54, alignment: .leading)
                            Text(e.kind.labelDE)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(protocolColor(e.kind))
                                .frame(width: 88, alignment: .leading)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(e.text)
                                    .font(.system(size: 11))
                                if let c = e.confidence {
                                    Text("Konfidenz \(c)%")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
    }

    private func protocolColor(_ kind: ProtocolKind) -> Color {
        switch kind {
        case .executed: return HeliosTheme.ok
        case .failed: return HeliosTheme.danger
        case .blocked: return HeliosTheme.amber
        case .recognized: return HeliosTheme.cyan
        case .info: return HeliosTheme.cyan.opacity(0.7)
        }
    }

    private func handCard(_ hand: TrackedHand) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(hand.id) · \(hand.sideDE)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(hand.chirality == .left ? HeliosTheme.amber : HeliosTheme.cyan)
                Spacer()
                Text(hand.pose.labelDE)
                    .font(.system(size: 12, weight: .semibold))
            }
            ProgressView(value: hand.poseProb)
                .tint(hand.chirality == .left ? HeliosTheme.amber : HeliosTheme.cyan)
            Text(
                String(
                    format: "Pose %.0f %%  ·  Pinzette %@  %.2f  ·  q %.2f",
                    hand.poseProb * 100,
                    hand.pinchClosed ? "ZU" : "OFFEN",
                    hand.pinchRatio,
                    hand.quality
                )
            )
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
            ForEach(FingerKind.allCases) { finger in
                let conf = hand.confidence(finger.tip)
                HStack(spacing: 6) {
                    Circle().fill(finger.color).frame(width: 7, height: 7)
                    Text(finger.labelDE)
                        .font(.system(size: 11, weight: .medium))
                        .frame(width: 52, alignment: .leading)
                    Text(hand.isExtended(finger) ? "offen" : "zu")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(hand.isExtended(finger) ? HeliosTheme.ok : .secondary)
                        .frame(width: 40, alignment: .leading)
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(Color.white.opacity(0.08))
                            Rectangle()
                                .fill(finger.color.opacity(0.85))
                                .frame(width: g.size.width * CGFloat(conf))
                        }
                    }
                    .frame(height: 6)
                    Text("\(Int(conf * 100))%")
                        .font(.system(size: 10, design: .monospaced))
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.04))
        .overlay(Rectangle().stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

struct LatencySpark: View {
    var values: [Double]

    var body: some View {
        GeometryReader { g in
            let maxV = max(values.max() ?? 1, 1)
            Path { p in
                guard values.count > 1 else { return }
                for (i, v) in values.enumerated() {
                    let x = g.size.width * CGFloat(i) / CGFloat(max(values.count - 1, 1))
                    let y = g.size.height * (1 - CGFloat(v / maxV))
                    if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                    else { p.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(HeliosTheme.cyan.opacity(0.85), lineWidth: 1.2)
        }
        .frame(height: 28)
        .background(Color.white.opacity(0.04))
        .overlay(Rectangle().stroke(Color.white.opacity(0.08), lineWidth: 1))
        .accessibilityLabel("Latenz der letzten Frames")
    }
}

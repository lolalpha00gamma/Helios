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
                    Text("Linke Hand steuert Position und Greifen.")
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
            .keyboardShortcut("t", modifiers: [.command])
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
                    if state.fromDiskImage {
                        Text("Du startest aus dem DMG. Die Schalter in den Systemeinstellungen gelten dann nicht für diese Datei.")
                            .font(.system(size: 11))
                            .foregroundStyle(HeliosTheme.amber)
                        Button("Nach Programme kopieren und neu starten") {
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
                    .keyboardShortcut("k", modifiers: [.command])
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
                    }
                }
            }

            GroupBox("Erkennung") {
                LabeledContent("Hände", value: "\(state.hands.count)")
                LabeledContent("Aktion", value: state.lastAction)
                LabeledContent("Latenz", value: String(format: "%.0f ms · %.0f fps", state.latencyMs, state.fps))
                LabeledContent("Licht", value: state.luma < 0.28 ? "Dunkel — Verstärkung" : state.luma < 0.45 ? "Gedämpft" : "OK")
                LabeledContent("Monitore", value: "\(state.screenCount)")
                if let app = state.focused {
                    LabeledContent("App", value: app.appName)
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
                 : "Live · Linke Handfläche = Position. Pinzette/Faust greift das Fenster unter der Markierung. Offene Hand wischen = App. Beide offen = Not-Aus (bleibt Idle).")
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
                hands: state.displayHands,
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
                    VStack(alignment: .leading, spacing: 6) {
                        Button("Sitzung exportieren…") { state.exportSession() }
                            .keyboardShortcut("e", modifiers: [.command])
                        Button("Protokoll kopieren") { state.copyProtocol() }
                        Button("Filmstreifen kopieren") { state.copyFilmstrip() }
                        Text("Ein PNG mit der Geste + JSONL/TXT. In Grok einfügen, keine Screenshots.")
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
                Text(hand.sideDE)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(hand.chirality == .left ? HeliosTheme.amber : HeliosTheme.cyan)
                Spacer()
                Text(hand.pose.labelDE)
                    .font(.system(size: 12, weight: .semibold))
            }
            ProgressView(value: Double(hand.meanConfidence))
                .tint(hand.chirality == .left ? HeliosTheme.amber : HeliosTheme.cyan)
            Text(String(format: "Konfidenz %.0f %%  ·  Pinzette %.3f", hand.meanConfidence * 100, hand.pinchDistance))
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

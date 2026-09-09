import SwiftUI

struct ControlPanel: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        HSplitView {
            ScrollView {
                left
            }
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
            if let f = state.focused {
                let p = AppInjectProfile.of(bundleId: f.bundleId)
                Text("\(f.appName) · Profil \(p.titleDE)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(p == .off ? HeliosTheme.amber : .secondary)
            }

            Toggle(isOn: Binding(
                get: { state.leftHanded },
                set: { state.setLeftHanded($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Linkshänder")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Standard aus — rechte Hand steuert. Nur einschalten, wenn du mit links greifst.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)

            Toggle(isOn: Binding(
                get: { state.faceRecognition },
                set: { state.setFaceRecognition($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gesichtserkennung")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Standard aus. Nur eigene Hand filtern — erst wenn die Steuerung steht.")
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

            Toggle(isOn: $state.beakGrab) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Schnabel-Ziehen")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Standard aus. Finger zur Kamera = Ziehen. Nur einschalten, wenn du das bewusst nutzt.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)

            Button(action: { state.openGestureGuide() }) {
                Text("Gesten-Test öffnen")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(HeliosTheme.cyan)

            if !state.folderOrbs.isEmpty {
                Button(action: { state.closeFolderOverlay() }) {
                    Text("Datei-Overlay schließen")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(HeliosTheme.amber)
            }

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
                get: { state.keyboardVisible },
                set: { on in
                    if on != state.engine.keyboardVisible { state.engine.toggleKeyboard() }
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Luft-Tastatur")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Zeigen 0,85 s öffnet QWERTZ in der Luft. Taste 0,12 s halten tippt — ohne Pinzette. Faust schließt.")
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
                    Toggle("Lupe am Cursor", isOn: $state.showLoupe)
                    Text("Großer Kreis um den Zeiger — Ziel sehen, klein kneifen.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Toggle("Kamera-Chip", isOn: $state.showPreviewChip)
                    Toggle("Gelenk-Beschriftung", isOn: $state.showJointLabels)
                    Toggle("Gestenhilfe", isOn: $state.showCheats)
                    VStack(alignment: .leading, spacing: 2) {
                        Toggle("App-Umriss", isOn: $state.showOutline)
                        Text("Nur beim Greifen: Cyan-Rahmen um das Zielfenster. Kein eigenes Fenster, kein App-Wechsel. Standard aus.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    Toggle("Papierkorb-Zone", isOn: $state.showTrashZone)
                    Toggle(isOn: Binding(
                        get: { state.hideConsoleWhenArmed },
                        set: { state.setHideConsoleWhenArmed($0) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Konsole bei Scharf ausblenden")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Standard aus. Die Konsole bleibt stehen und stiehlt nicht den Vordergrund — Gesten laufen in der App darunter. Nur einschalten, wenn das Fenster komplett weg soll.")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                    cameraPicker
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
                    VStack(alignment: .leading, spacing: 4) {
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
                            in: 0.35...1.40,
                            step: 0.05
                        )
                        Text("Debug. 0,75 Default. Niedriger = Pose spitzer (leichter über 62 %), höher = weicher.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            GroupBox("Kalibrierung") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(state.mapReady ? "Ecken gespeichert — außen absolut, innen relativ (Trackpad)." : "Noch nicht kalibriert — Zeiger relativ.")
                        .font(.system(size: 11))
                        .foregroundStyle(state.mapReady ? HeliosTheme.cyan : .secondary)
                    if state.cameraPair != .single {
                        Text("Lead: \(state.deviceName)\(state.mapReady ? " · kalibriert" : " · 4 Ecken fehlen")")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Text("Cover: \(state.coverName)\(state.coverMapReady ? " · kalibriert" : " · 4 Ecken fehlen")")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    if state.calibActive {
                        Text("Jetzt: \(state.calibSession.cameraLabel.isEmpty ? state.deviceName : state.calibSession.cameraLabel) · \(state.calibCorner). Pinzette 1 s halten.")
                            .font(.system(size: 11))
                            .foregroundStyle(HeliosTheme.amber)
                        Button("Abbrechen") { state.cancelCalibration() }
                    } else {
                        Button("Vier Ecken kalibrieren") { state.startCalibration() }
                            .buttonStyle(.borderedProminent)
                        Button("Beamer / externe Kamera") { state.startEdgeCalibration() }
                    }
                    if state.mapReady {
                        Button("Kalibrierung löschen") { state.clearCalibration() }
                            .buttonStyle(.borderless)
                    }
                    Text("Vier Ecken: Kamera sieht den Mac-Schirm. Beamer: Kamera (Handy, Osmo, USB) sieht die Leinwand oder den gespiegelten Schirm. An jeden sichtbaren Bildrand gehen, so weit die Hand kommt, Pinzette halten — Reihenfolge egal. Homographie, Abstand und Gesten berechnet Helios.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text("Mac (Lead) führt alle Aktionen. Osmo/iPhone ist nur zweite Sicht: bessere Fingerlage, kein eigenes Klicken/Ziehen. Kalibrierung: erst Mac 4 Ecken, dann Cover dieselben Bildschirmecken — Pinzette zählt nur, wenn die Mac-Kamera sie auch sieht. Weichen die gemappten Lagen stark ab, bleibt die Mac-Lage.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            GroupBox("Aktionskalibrierung") {
                VStack(alignment: .leading, spacing: 8) {
                    if state.drill.phase == .idle {
                        Button("Übung starten — 12 Gesten × 3") { state.startDrill() }
                            .buttonStyle(.borderedProminent)
                    } else {
                        Text(state.drill.status)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(HeliosTheme.amber)
                        Text("\(state.drill.current.titleDE) · Wiederholung \(min(state.drill.repeatIndex + 1, 3))/3")
                            .font(.system(size: 13, weight: .semibold))
                        ProgressView(value: state.drill.progress)
                        HStack {
                            Button("Abbrechen") { state.cancelDrill() }
                            if state.drill.phase == .done || !state.drill.trials.isEmpty {
                                Button("Für Grok kopieren") { state.copyDrillForGrok() }
                                    .buttonStyle(.borderedProminent)
                                Button("Dateien…") { state.exportDrill() }
                            }
                        }
                    }
                    Text("Countdown, dann 2 s Aufnahme, drei Wiederholungen. Kein Klick/Fensterzugriff. Danach hier kopieren und in diesen Chat einfügen.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            GroupBox("Erkennung") {
                LabeledContent("Hände", value: "\(state.hands.count)")
                LabeledContent("Aktion", value: state.lastAction)
                LabeledContent("Latenz", value: String(format: "%.0f ms · %.0f fps", state.latencyMs, state.fps))
                LatencySpark(values: state.latencyHistory)
                LabeledContent("Licht", value: state.luma < 0.28 ? "Dunkel — Verstärkung" : state.luma < 0.45 ? "Gedämpft" : "OK")
                LabeledContent("Monitore", value: "\(state.screenCount)")
                LabeledContent("Tiefe", value: state.hasDepth ? "Kanal aktiv (LiDAR/TrueDepth)" : "nur 3D-Lift")
                if let app = state.focused {
                    LabeledContent("App", value: app.appName)
                }
                if state.hands.isEmpty {
                    Text("Keine Hand im Bild — Handfläche zur Kamera, guter Kontrast.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Text(state.testMode
                 ? "Testmodus: Gesten werden erkannt, das System bleibt unangetastet."
                 : "Live · \(state.leftHanded ? "Linke" : "Rechte") Handfläche = Position. 2× klatschen (sichtbar, kein Mikrofon) weckt Helios im Hintergrund. Pinzette/Faust greift das Fenster unter der Markierung. Offene Hand wischen = App. Beide offen = Not-Aus (bleibt Idle).")
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

    private var cameraPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Kameras")
                .font(.system(size: 13, weight: .semibold))
            Button("Quellen neu suchen") {
                state.rescanCameras()
            }
            .buttonStyle(.borderless)
            .font(.system(size: 11))
            Picker("Paar", selection: Binding(
                get: { state.cameraPair },
                set: { state.selectPair($0) }
            )) {
                ForEach(CameraPair.allCases) { p in
                    Text(p.titleDE).tag(p)
                }
            }
            .labelsHidden()
            Text(state.cameraPair.detailDE)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            if state.watchdogChip != "—" {
                Text(state.watchdogChip)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(HeliosTheme.amber)
                    .help("Kamera liefert Frames, Vision sieht 8 s keine Palme.")
            }
            if state.mutexChip != "—" && state.mutexChip != "MUTEX —" {
                Text(state.mutexChip)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(HeliosTheme.cyan)
                    .help("Helios hält die Continuity-Kamera. Aegis füllt PTS und skippt Palme.")
            }
            if state.cameraPair == .single {
                if state.cameraDevices.isEmpty {
                    Text(state.deviceName)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Quelle", selection: Binding(
                        get: { state.selectedCameraID },
                        set: { state.selectCamera($0) }
                    )) {
                        ForEach(state.cameraDevices) { d in
                            Text("\(d.name) · \(d.kindDE)\(d.hasDepth ? " · Tiefe" : "")")
                                .tag(d.id)
                        }
                    }
                    .labelsHidden()
                }
            } else {
                Text("Lead \(state.deviceName)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(HeliosTheme.cyan)
                if !state.cameraDevices.isEmpty {
                    Picker("Lead", selection: Binding(
                        get: { state.selectedCameraID },
                        set: { state.selectLead($0) }
                    )) {
                        ForEach(state.cameraDevices) { d in
                            Text("Lead · \(d.name) · \(d.kindDE)").tag(d.id)
                        }
                    }
                    .labelsHidden()
                    Picker("Cover / Osmo", selection: Binding(
                        get: { state.coverID },
                        set: { state.selectCover($0) }
                    )) {
                        Text("— Cover wählen —").tag("")
                        ForEach(state.cameraDevices.filter { $0.id != state.selectedCameraID }) { d in
                            Text("Cover · \(d.name) · \(d.kindDE)").tag(d.id)
                        }
                    }
                    .labelsHidden()
                }
                Text("Cover \(state.coverRunning ? state.coverName : (state.coverError ?? "nicht aktiv"))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(state.coverRunning ? HeliosTheme.cyan : HeliosTheme.amber)
            }
            if let err = state.coverError, !err.isEmpty {
                Text(err)
                    .font(.system(size: 10))
                    .foregroundStyle(HeliosTheme.amber)
            }
            Text("iPhone: Kontinuität (gleicher iCloud-Account, Kamera-App zu) oder Desk View von oben. Osmo Action 3: am Gerät Webcam-Modus, dann USB-C — der Livestream erscheint rechts unter der Mac-Kamera. Fehlt er: Cover-Picker oben, nicht nur das Paar. Continuity ist oft exklusiv zur Mac-Kamera.")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }

    private var preview: some View {
        VStack(spacing: 8) {
            cameraPane(
                image: state.preview,
                hands: state.hands.filter { !$0.id.hasPrefix("C.") },
                name: state.deviceName,
                live: state.cameraRunning,
                placeholder: state.cameraError ?? "Kamera starten"
            )
            if state.cameraPair != .single {
                cameraPane(
                    image: state.coverPreview,
                    hands: state.coverHands,
                    name: state.coverRunning
                        ? "\(state.coverName) · 2. WINKEL"
                        : (state.coverError ?? "Osmo / Cover"),
                    live: state.coverRunning,
                    placeholder: state.coverError
                        ?? "Osmo: Webcam-Modus am Gerät, USB-C, dann Cover wählen"
                )
                .frame(minHeight: 160, idealHeight: 210)
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
        .padding(8)
    }

    private func cameraPane(
        image: NSImage?,
        hands: [TrackedHand],
        name: String,
        live: Bool,
        placeholder: String
    ) -> some View {
        ZStack {
            CameraPreview(
                image: image,
                hands: hands,
                showLabels: state.showJointLabels,
                compact: false,
                placeholder: placeholder,
                dim: GestureMath.skeletonFreezeDim(state.lockFreeze.lowercased().contains("freeze"))
            )
            if image == nil {
                VStack(spacing: 8) {
                    Image(systemName: live ? "video" : "video.slash")
                        .font(.system(size: 28))
                        .foregroundStyle(HeliosTheme.cyan)
                    Text(placeholder)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 6) {
                Circle()
                    .fill(live && image != nil ? HeliosTheme.ok : HeliosTheme.amber)
                    .frame(width: 7, height: 7)
                Text(name)
                    .font(HeliosTheme.mono)
                    .foregroundStyle(HeliosTheme.cyan)
            }
            .padding(10)
        }
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
                        Text("Ein PNG mit der Geste + JSONL/TXT. Label-Feld in gesten.jsonl ist für Create ML.")
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

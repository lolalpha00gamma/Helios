import SwiftUI

struct ControlPanel: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        HSplitView {
            left
                .frame(minWidth: 280, idealWidth: 300)
            preview
                .frame(minWidth: 420)
            log
                .frame(minWidth: 240, idealWidth: 280)
        }
        .background(HeliosTheme.void)
        .preferredColorScheme(.dark)
    }

    private var left: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("HELIOS")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(HeliosTheme.cyan)
                Spacer()
                Text(state.mode.labelDE)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(state.mode == .armed ? HeliosTheme.amber : HeliosTheme.cyan.opacity(0.15))
                    .foregroundStyle(state.mode == .armed ? HeliosTheme.void : HeliosTheme.cyan)
            }
            Text("Gestensteuerung über Kamera-Livestream. macOS 27 · Apple Silicon.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            GroupBox("Rechte") {
                VStack(alignment: .leading, spacing: 8) {
                    permRow(.camera, ok: state.cameraOK)
                    permRow(.accessibility, ok: state.accessOK)
                    permRow(.inputMonitoring, ok: true)
                }
                .padding(.top, 4)
            }

            GroupBox("Sitzung") {
                VStack(spacing: 8) {
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
                    Toggle("Gestenhilfe", isOn: $state.showCheats)
                }
            }

            GroupBox("Aktive Hand") {
                if let h = state.hands.first {
                    LabeledContent("Pose", value: h.pose.labelDE)
                    LabeledContent("Seite", value: h.chirality == .left ? "Links" : "Rechts")
                    LabeledContent("Pinzette", value: String(format: "%.3f", h.pinchDistance))
                } else {
                    Text("Keine Hand im Bild")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Letzte Aktion", value: state.lastAction)
                LabeledContent("Latenz", value: String(format: "%.0f ms", state.latencyMs))
            }

            Spacer()
            Text("Faust 0,8 s halten schaltet Scharf. Beide Handflächen = Not-Aus. Keine Dateiaktionen in dieser Version.")
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
            HeliosTheme.void
            if let img = state.preview {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFit()
                    .overlay(SkeletonOverlay(hands: state.hands))
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "sun.max")
                        .font(.system(size: 36))
                        .foregroundStyle(HeliosTheme.cyan)
                    Text(state.cameraError ?? "Kamera starten")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Text(state.deviceName)
                .font(HeliosTheme.mono)
                .padding(8)
                .foregroundStyle(HeliosTheme.cyan)
        }
        .padding(8)
    }

    private var log: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PROTOKOLL")
                .font(HeliosTheme.mono)
                .foregroundStyle(HeliosTheme.cyan)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(state.log.entries) { e in
                        HStack(alignment: .top) {
                            Text(e.at, style: .time)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(HeliosTheme.amber)
                            Text(e.text)
                                .font(.system(size: 11))
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
        .padding(12)
    }
}

import SwiftUI
import AppKit

@main
struct HeliosApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        Window("Helios", id: "konsole") {
            ControlPanel()
                .environmentObject(state)
                .frame(minWidth: 980, minHeight: 620)
                .onAppear { state.start() }
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1180, height: 720)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Kamera starten") {
                    Task { await state.startCamera() }
                }
                .keyboardShortcut("k", modifiers: [.command])
                Button("Scharf") { state.engine.forceArm() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
                Button("Idle") { state.engine.forceIdle() }
                    .keyboardShortcut("i", modifiers: [.command, .shift])
                Button(state.testMode ? "Testmodus aus" : "Testmodus an") {
                    state.setTestMode(!state.testMode)
                }
                .keyboardShortcut("t", modifiers: [.command])
            }
        }

        MenuBarExtra("Helios", systemImage: "sun.max.fill") {
            MenuBarMenu(state: state)
        }
    }
}

private struct MenuBarMenu: View {
    @ObservedObject var state: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(state.mode.labelDE) {}
            .disabled(true)
        Divider()
        Button("Konsole") {
            NSApp.activate()
            openWindow(id: "konsole")
        }
        Button(state.cameraRunning ? "Kamera stoppen" : "Kamera starten") {
            if state.cameraRunning { state.stopCamera() } else { Task { await state.startCamera() } }
        }
        Button("Scharf") { state.engine.forceArm() }
        Button("Idle") { state.engine.forceIdle() }
        Button(state.testMode ? "Testmodus aus" : "Testmodus an") {
            state.setTestMode(!state.testMode)
        }
        Divider()
        Button("Beenden") { NSApp.terminate(nil) }
    }
}

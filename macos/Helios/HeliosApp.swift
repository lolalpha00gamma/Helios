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
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    state.shutdown()
                }
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

enum ConsolePolicy {
    static func isHUD(_ w: NSWindow) -> Bool {
        w is HUDPanel || w.level.rawValue >= Int(CGWindowLevelForKey(.assistiveTechHighWindow))
    }

    static func hide() {
        for w in NSApp.windows where !isHUD(w) {
            w.orderOut(nil)
        }
        NSApp.setActivationPolicy(.accessory)
    }

    static func show() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        for w in NSApp.windows where !isHUD(w) {
            w.makeKeyAndOrderFront(nil)
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
            ConsolePolicy.show()
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

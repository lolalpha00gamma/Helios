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
        .windowResizability(.contentMinSize)
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

@MainActor
enum ConsolePolicy {
    private static var hiding = false
    private static var observers: [NSObjectProtocol] = []

    static func isHUD(_ w: NSWindow) -> Bool {
        w is HUDPanel || w.level.rawValue >= Int(CGWindowLevelForKey(.assistiveTechHighWindow))
    }

    static func installGuard() {
        guard observers.isEmpty else { return }
        let bounce: (Notification) -> Void = { note in
            Task { @MainActor in
                guard hiding, let w = note.object as? NSWindow, !isHUD(w) else { return }
                w.orderOut(nil)
                NSApp.setActivationPolicy(.accessory)
            }
        }
        observers.append(NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main, using: bounce
        ))
        observers.append(NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeMainNotification, object: nil, queue: .main, using: bounce
        ))
    }

    static func hide() {
        hiding = true
        for w in NSApp.windows where !isHUD(w) {
            w.collectionBehavior.insert(.ignoresCycle)
            w.orderOut(nil)
        }
        NSApp.setActivationPolicy(.accessory)
    }

    /// SwiftUI zeigt die Konsole nach State-Updates wieder. Solange scharf: wieder weg.
    static func enforce() {
        guard hiding else { return }
        var shown = false
        for w in NSApp.windows where !isHUD(w) {
            w.collectionBehavior.insert(.ignoresCycle)
            if w.isVisible || w.isKeyWindow || w.isMainWindow {
                w.orderOut(nil)
                shown = true
            }
        }
        if shown {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    static func show() {
        hiding = false
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        for w in NSApp.windows where !isHUD(w) {
            w.collectionBehavior.insert(.ignoresCycle)
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

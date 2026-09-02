import SwiftUI
import AppKit

extension Notification.Name {
    static let heliosOpenConsole = Notification.Name("helios.openConsole")
}

@MainActor
final class HeliosAppDelegate: NSObject, NSApplicationDelegate {
    nonisolated(unsafe) static weak var state: AppState?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Nie .accessory — das reißt das SwiftUI-Fenster ein, löscht das Dock
        // und Cmd+Q trifft dann die App darunter. Helios bleibt erreichbar.
        NSApp.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        ConsolePolicy.prepareQuit()
        HeliosAppDelegate.state?.shutdown()
        return .terminateNow
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        ConsolePolicy.show()
        NotificationCenter.default.post(name: .heliosOpenConsole, object: nil)
        return true
    }
}

@main
struct HeliosApp: App {
    @NSApplicationDelegateAdaptor(HeliosAppDelegate.self) var appDelegate
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
            CommandGroup(after: .appInfo) {
                Button("Helios beenden") {
                    ConsolePolicy.prepareQuit()
                    state.shutdown()
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            CommandGroup(replacing: .newItem) {
                Button("Konsole") {
                    ConsolePolicy.show()
                }
                .keyboardShortcut("1", modifiers: [.command])
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
    private static var pinned = false
    private static var observers: [NSObjectProtocol] = []

    static func isHUD(_ w: NSWindow) -> Bool {
        w is HUDPanel || w.level.rawValue >= Int(CGWindowLevelForKey(.assistiveTechHighWindow))
    }

    static func installGuard() {
        guard observers.isEmpty else { return }
        let bounce: (Notification) -> Void = { note in
            MainActor.assumeIsolated {
                guard hiding, !pinned, let w = note.object as? NSWindow, !isHUD(w) else { return }
                w.orderOut(nil)
            }
        }
        observers.append(NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main, using: bounce
        ))
        observers.append(NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeMainNotification, object: nil, queue: .main, using: bounce
        ))
        observers.append(NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification, object: nil, queue: .main
        ) { note in
            let hud = note.object is HUDPanel
            if hud { return }
            Task { @MainActor in
                pinned = false
            }
        })
    }

    /// Konsole weg — App bleibt im Dock, Cmd+Q und Beenden funktionieren.
    static func hide() {
        if pinned { return }
        hiding = true
        NSApp.setActivationPolicy(.regular)
        for w in NSApp.windows where !isHUD(w) {
            w.collectionBehavior.insert(.ignoresCycle)
            w.orderOut(nil)
        }
    }

    static func enforce() {
        guard hiding, !pinned else { return }
        for w in NSApp.windows where !isHUD(w) {
            w.collectionBehavior.insert(.ignoresCycle)
            if w.isVisible || w.isKeyWindow || w.isMainWindow {
                w.orderOut(nil)
            }
        }
    }

    static func show() {
        pinned = true
        hiding = false
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        var found = false
        for w in NSApp.windows where !isHUD(w) {
            w.collectionBehavior.remove(.ignoresCycle)
            w.makeKeyAndOrderFront(nil)
            found = true
        }
        if !found {
            NotificationCenter.default.post(name: .heliosOpenConsole, object: nil)
        }
    }

    static func prepareQuit() {
        pinned = true
        hiding = false
        NSApp.setActivationPolicy(.regular)
    }
}


private struct MenuBarMenu: View {
    @ObservedObject var state: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(state.mode.labelDE) {}
            .disabled(true)
        if state.cameraPair != .single {
            Text(state.coverRunning
                 ? "Osmo/Cover: \(state.coverName)"
                 : (state.coverError ?? "Cover nicht aktiv"))
        }
        Divider()
        Button("Konsole") {
            ConsolePolicy.show()
            openWindow(id: "konsole")
        }
        .keyboardShortcut("1", modifiers: [.command])
        Button(state.cameraRunning ? "Kamera stoppen" : "Kamera starten") {
            if state.cameraRunning { state.stopCamera() } else { Task { await state.startCamera() } }
        }
        Button("Scharf") { state.engine.forceArm() }
        Button("Idle") { state.engine.forceIdle() }
        Button(state.testMode ? "Testmodus aus" : "Testmodus an") {
            state.setTestMode(!state.testMode)
        }
        Divider()
        Button("Helios beenden") {
            ConsolePolicy.prepareQuit()
            state.shutdown()
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
        .onReceive(NotificationCenter.default.publisher(for: .heliosOpenConsole)) { _ in
            ConsolePolicy.show()
            openWindow(id: "konsole")
        }
    }
}

import SwiftUI
import AppKit

extension Notification.Name {
    static let heliosOpenConsole = Notification.Name("helios.openConsole")
}

@MainActor
final class HeliosAppDelegate: NSObject, NSApplicationDelegate {
    nonisolated(unsafe) static weak var state: AppState?
    nonisolated(unsafe) static var openConsole: (() -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        ConsolePolicy.dressAll()
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
        HeliosAppDelegate.openConsole?()
        return true
    }
}

@main
struct HeliosApp: App {
    @NSApplicationDelegateAdaptor(HeliosAppDelegate.self) var appDelegate
    @StateObject private var state = AppState()

    var body: some Scene {
        Window("Helios", id: "konsole") {
            ConsoleRoot(state: state)
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
                Button("Aktionskalibrierung") {
                    state.startDrill()
                }
                Button(state.keyboardVisible ? "Tastatur aus" : "Tastatur in der Luft") {
                    state.engine.toggleKeyboard()
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
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

private struct ConsoleRoot: View {
    @ObservedObject var state: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ControlPanel()
            .environmentObject(state)
            .frame(minWidth: 980, minHeight: 620)
            .onAppear {
                state.start()
                ConsolePolicy.dressAll()
                HeliosAppDelegate.openConsole = {
                    ConsolePolicy.show()
                    openWindow(id: "konsole")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .heliosOpenConsole)) { _ in
                openWindow(id: "konsole")
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                state.shutdown()
            }
    }
}

/// Konsole bleibt stehen. Kein Stehlen nach vorn, kein Zurückschub zu einer anderen App.
@MainActor
enum ConsolePolicy {
    private static var hiding = false
    private static var pinned = false
    private static var consoleHeld = false
    private static var observers: [(NotificationCenter, NSObjectProtocol)] = []
    private static var clickMonitor: Any?

    static func isHUD(_ w: NSWindow) -> Bool {
        w is HUDPanel || w.level.rawValue >= Int(CGWindowLevelForKey(.assistiveTechHighWindow))
    }

    static func installGuard() {
        guard observers.isEmpty else { return }
        let bounce: (Notification) -> Void = { note in
            MainActor.assumeIsolated {
                guard let w = note.object as? NSWindow, !isHUD(w) else { return }
                dress(w)
                if hiding {
                    w.orderOut(nil)
                    return
                }
                if pointerInConsole(w) {
                    consoleHeld = true
                    return
                }
                if consoleHeld { return }
                if w.isKeyWindow { w.resignKey() }
                if w.isMainWindow { w.resignMain() }
            }
        }
        observers.append((
            NotificationCenter.default,
            NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main, using: bounce
            )
        ))
        observers.append((
            NotificationCenter.default,
            NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeMainNotification, object: nil, queue: .main, using: bounce
            )
        ))
        observers.append((
            NSWorkspace.shared.notificationCenter,
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
            ) { note in
                let bid = (note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.bundleIdentifier
                Task { @MainActor in
                    if let bid, bid != Bundle.main.bundleIdentifier {
                        consoleHeld = false
                    }
                }
            }
        ))
        observers.append((
            NotificationCenter.default,
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification, object: nil, queue: .main
            ) { note in
                let hud = note.object is HUDPanel
                if hud { return }
                Task { @MainActor in
                    pinned = false
                    consoleHeld = false
                }
            }
        ))
        if clickMonitor == nil {
            clickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
                let ok = event.window != nil && !(event.window is HUDPanel)
                if ok {
                    Task { @MainActor in
                        consoleHeld = true
                    }
                }
                return event
            }
        }
        dressAll()
    }

    static func uninstall() {
        for (center, token) in observers {
            center.removeObserver(token)
        }
        observers = []
        if let clickMonitor {
            NSEvent.removeMonitor(clickMonitor)
            self.clickMonitor = nil
        }
    }

    static func dressAll() {
        for w in NSApp.windows where !isHUD(w) {
            dress(w)
        }
    }

    static func dress(_ w: NSWindow) {
        w.hidesOnDeactivate = false
        w.collectionBehavior.insert([.canJoinAllSpaces, .stationary, .ignoresCycle])
    }

    private static func pointerInConsole(_ w: NSWindow) -> Bool {
        w.frame.contains(NSEvent.mouseLocation)
    }

    static func hide() {
        pinned = false
        hiding = true
        NSApp.setActivationPolicy(.regular)
        for w in NSApp.windows where !isHUD(w) {
            dress(w)
            w.orderOut(nil)
        }
    }

    static func enforce() {
        guard hiding, !pinned else { return }
        for w in NSApp.windows where !isHUD(w) {
            dress(w)
            if w.isVisible || w.isKeyWindow || w.isMainWindow {
                w.orderOut(nil)
            }
        }
    }

    static func openedByUser() {
        consoleHeld = true
        pinned = true
        hiding = false
    }

    static func show() {
        openedByUser()
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        var found = false
        for w in NSApp.windows where !isHUD(w) {
            dress(w)
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
        consoleHeld = true
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
        Button("Aktionskalibrierung") { state.startDrill() }
        Button(state.keyboardVisible ? "Tastatur aus" : "Tastatur in der Luft") {
            state.engine.toggleKeyboard()
        }
        Divider()
        Button("Helios beenden") {
            ConsolePolicy.prepareQuit()
            state.shutdown()
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
        .onAppear {
            HeliosAppDelegate.openConsole = {
                ConsolePolicy.show()
                openWindow(id: "konsole")
            }
        }
    }
}

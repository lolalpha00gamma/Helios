import SwiftUI
import AppKit

extension Notification.Name {
    static let heliosOpenConsole = Notification.Name("helios.openConsole")
}

@MainActor
final class HeliosAppDelegate: NSObject, NSApplicationDelegate {
    nonisolated(unsafe) static weak var state: AppState?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        ConsolePolicy.openedByUser()
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
                .onAppear {
                    state.start()
                    ConsolePolicy.dressAll()
                }
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

/// Konsole bleibt sichtbar, stiehlt aber nicht den Vordergrund.
/// SwiftUI macht das Fenster bei jedem State-Tick key — das fangen wir ab.
@MainActor
enum ConsolePolicy {
    private static var hiding = false
    private static var pinned = false
    /// Nur true, wenn die Konsole selbst angeklickt oder über Menü/Dock geöffnet wurde.
    private static var consoleHeld = false
    private static var lastOtherPID: pid_t = 0
    private static var observers: [NSObjectProtocol] = []
    private static var clickMonitor: Any?
    private static var lastYield: TimeInterval = 0

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
                demoteIfStolen(w)
            }
        }
        observers.append(NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main, using: bounce
        ))
        observers.append(NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeMainNotification, object: nil, queue: .main, using: bounce
        ))
        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { _ in
            Task { @MainActor in
                dressAll()
                if !hiding { yieldStolenFocus() }
            }
        })
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            let bid = app?.bundleIdentifier
            let pid = app?.processIdentifier ?? 0
            Task { @MainActor in
                if let bid, bid != Bundle.main.bundleIdentifier, pid != 0 {
                    lastOtherPID = pid
                    consoleHeld = false
                }
            }
        })
        observers.append(NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification, object: nil, queue: .main
        ) { note in
            let hud = note.object is HUDPanel
            if hud { return }
            Task { @MainActor in
                pinned = false
            }
        })
        if clickMonitor == nil {
            clickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
                let hud = event.window is HUDPanel
                if event.window != nil, !hud {
                    Task { @MainActor in
                        consoleHeld = true
                    }
                }
                return event
            }
        }
        if let front = NSWorkspace.shared.frontmostApplication,
           front.bundleIdentifier != Bundle.main.bundleIdentifier
        {
            lastOtherPID = front.processIdentifier
        }
        dressAll()
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

    private static func userChoseConsole() -> Bool {
        consoleHeld
    }

    private static func demoteIfStolen(_ w: NSWindow) {
        if hiding {
            w.orderOut(nil)
            return
        }
        guard !userChoseConsole() else { return }
        if w.isKeyWindow { w.resignKey() }
        if w.isMainWindow { w.resignMain() }
        yieldStolenFocus()
    }

    private static func yieldStolenFocus() {
        guard !userChoseConsole() else { return }
        guard lastOtherPID != 0 else { return }
        let now = CACurrentMediaTime()
        if now - lastYield < 0.28 { return }
        lastYield = now
        guard let other = NSRunningApplication(processIdentifier: lastOtherPID),
              !other.isTerminated,
              other.bundleIdentifier != Bundle.main.bundleIdentifier
        else { return }
        other.activate()
    }

    /// Nur wenn der Schalter „Konsole bei Scharf ausblenden“ an ist.
    static func hide() {
        if pinned { return }
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

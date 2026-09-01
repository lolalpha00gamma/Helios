import ApplicationServices
import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum SnapEdge {
    case left, right, fill
}

struct ActionResult {
    var ok: Bool
    var detail: String
    static func ok(_ detail: String = "OK") -> ActionResult { ActionResult(ok: true, detail: detail) }
    static func fail(_ detail: String) -> ActionResult { ActionResult(ok: false, detail: detail) }
}

@MainActor
final class SystemControl {
    private var dragElement: AXUIElement?
    private var dragOriginMouse: CGPoint = .zero
    private var dragOriginWindow: CGPoint = .zero
    private var lastClick: TimeInterval = 0
    private var lastKey: TimeInterval = 0
    private var lastPosted: CGPoint?
    private var lastPostedAt: TimeInterval = 0
    private let dragPump = AXDragPump()
    /// Ergebnis einer Aktion, die erst nach ihrem Aufruf feststeht (z. B. Aufnahme).
    var onLate: ((String, ProtocolKind) -> Void)?

    /// Die zuletzt von Helios gesetzte Position gilt nur kurz. Danach zählt wieder
    /// die echte Maus — sonst klickt eine Geste dorthin, wo der Zeiger vor Minuten stand.
    private var postedCursor: CGPoint? {
        guard let lastPosted, CACurrentMediaTime() - lastPostedAt < 0.5 else { return nil }
        return lastPosted
    }

    private var aimPoint: CGPoint {
        postedCursor ?? NSEvent.mouseLocation.screenFlipped
    }

    func moveCursor(to point: CGPoint) {
        let p = ScreenGeometry.clampQuartz(point)
        lastPosted = p
        lastPostedAt = CACurrentMediaTime()
        let src = CGEventSource(stateID: .hidSystemState)
        let e = CGEvent(mouseEventSource: src, mouseType: .mouseMoved, mouseCursorPosition: p, mouseButton: .left)
        e?.post(tap: .cghidEventTap)
    }

    @discardableResult
    func click() -> ActionResult {
        let now = CACurrentMediaTime()
        guard now - lastClick > 0.12 else { return .fail("Klick-Pause") }
        lastClick = now
        let loc = aimPoint
        guard postMouse(.leftMouseDown, at: loc), postMouse(.leftMouseUp, at: loc) else {
            return .fail("CGEvent Klick")
        }
        return .ok("Klick")
    }

    @discardableResult
    func beginWindowDrag() -> ActionResult {
        let loc = aimPoint
        guard let win = targetWindow(at: loc) else {
            if AppInstall.isFromDiskImage {
                return .fail("Läuft aus dem DMG — nach Programme kopieren")
            }
            return .fail("Kein Fenster unter der Hand")
        }
        guard let pos = position(of: win) else { return .fail("AXPosition") }
        dragElement = win
        dragOriginMouse = loc
        dragOriginWindow = pos
        return .ok("Greifen")
    }

    func updateWindowDrag() {
        guard let win = dragElement else { return }
        let loc = aimPoint
        let dx = loc.x - dragOriginMouse.x
        let dy = loc.y - dragOriginMouse.y
        dragPump.submit(win, CGPoint(x: dragOriginWindow.x + dx, y: dragOriginWindow.y + dy))
    }

    func endWindowDrag() {
        dragPump.cancel()
        dragElement = nil
    }

    var isDragging: Bool { dragElement != nil }

    @discardableResult
    func resizeFocused(scale: CGFloat) -> ActionResult {
        guard let win = targetWindow(), let size = size(of: win), let pos = position(of: win) else {
            return .fail("Kein Fenster zum Skalieren")
        }
        let s = max(0.82, min(1.22, scale))
        let nw = max(280, size.width * s)
        let nh = max(180, size.height * s)
        let nx = pos.x - (nw - size.width) / 2
        let ny = pos.y - (nh - size.height) / 2
        guard setPosition(win, CGPoint(x: nx, y: ny)), setSize(win, CGSize(width: nw, height: nh)) else {
            return .fail("AX Größe")
        }
        return .ok(String(format: "×%.2f", s))
    }

    @discardableResult
    func minimizeFocused() -> ActionResult {
        guard let win = targetWindow() else { return .fail("Kein Fenster") }
        return pressButton(win, "AXMinimizeButton" as CFString)
    }

    @discardableResult
    func closeFocused() -> ActionResult {
        guard let win = targetWindow() else { return .fail("Kein Fenster") }
        return pressButton(win, "AXCloseButton" as CFString)
    }

    @discardableResult
    func snapFocused(_ edge: SnapEdge) -> ActionResult {
        guard let win = targetWindow() else { return .fail("Kein Fenster") }
        let loc = aimPoint
        let screen = ScreenGeometry.screenContaining(quartz: loc) ?? NSScreen.main
        guard let screen else { return .fail("Kein Bildschirm") }
        let vis = ScreenGeometry.quartzRect(fromCocoa: screen.visibleFrame)
        switch edge {
        case .left:
            _ = setPosition(win, vis.origin)
            _ = setSize(win, CGSize(width: vis.width / 2, height: vis.height))
            return .ok("Links")
        case .right:
            _ = setPosition(win, CGPoint(x: vis.midX, y: vis.minY))
            _ = setSize(win, CGSize(width: vis.width / 2, height: vis.height))
            return .ok("Rechts")
        case .fill:
            _ = setPosition(win, vis.origin)
            _ = setSize(win, vis.size)
            return .ok("Füllen")
        }
    }

    @discardableResult
    func throwAway(finder: Bool) -> ActionResult {
        if finder, trashFinderSelection() {
            return .ok("Finder → Papierkorb")
        }
        return closeFocused()
    }

    @discardableResult
    func screenshotFocused(windowID: CGWindowID, bounds: CGRect) -> ActionResult {
        if windowID == 0 && bounds.width < 8 {
            return .fail("Kein Zielfenster")
        }
        return WindowCapture.launch(windowID: windowID) { [weak self] done in
            self?.onLate?(
                done.ok ? "Aufnahme · \(done.detail)" : "Aufnahme — NICHT AUSGEFÜHRT: \(done.detail)",
                done.ok ? .executed : .failed
            )
        }
    }

    @discardableResult
    func missionControl() -> ActionResult {
        let paths = [
            "/System/Applications/Mission Control.app",
            "/System/Library/CoreServices/Mission Control.app",
            "/Applications/Mission Control.app"
        ]
        for p in paths where FileManager.default.fileExists(atPath: p) {
            if NSWorkspace.shared.open(URL(fileURLWithPath: p)) {
                return .ok("Mission Control.app")
            }
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.exposelauncher") {
            if NSWorkspace.shared.open(url) { return .ok("exposelauncher") }
        }
        guard chord(key: 0x7E, flags: .maskControl) else { return .fail("Control-Auf") }
        return .ok("Control-Auf")
    }

    @discardableResult
    func unhideFront() -> ActionResult {
        if let t = TargetProbe.windowUnderCursor(skipSelf: true),
           let app = NSRunningApplication(processIdentifier: t.pid)
        {
            app.unhide()
            return activate(app)
        }
        return .fail("Keine App unter der Hand")
    }

    @discardableResult
    func switchApp(forward: Bool) -> ActionResult {
        let selfPID = TargetProbe.selfPID
        var seen = Set<pid_t>()
        var ordered: [NSRunningApplication] = []
        if let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] {
            for item in list {
                let pid = (item[kCGWindowOwnerPID as String] as? pid_t) ?? 0
                if pid == 0 || pid == selfPID || seen.contains(pid) { continue }
                let layer = item[kCGWindowLayer as String] as? Int ?? 0
                guard layer == 0 else { continue }
                guard let app = NSRunningApplication(processIdentifier: pid),
                      app.activationPolicy == .regular,
                      !app.isTerminated
                else { continue }
                seen.insert(pid)
                ordered.append(app)
            }
        }
        guard ordered.count >= 2 else {
            _ = chord(key: 0x30, flags: forward ? .maskCommand : [.maskCommand, .maskShift])
            return ordered.isEmpty ? .fail("Keine andere App") : activate(ordered[0])
        }
        let idx = forward ? 1 : ordered.count - 1
        return activate(ordered[idx])
    }

    private func activate(_ app: NSRunningApplication) -> ActionResult {
        let name = app.localizedName ?? "App"
        app.unhide()
        app.activate()
        return .ok(name)
    }

    private func trashFinderSelection() -> Bool {
        let source = """
        tell application "Finder"
          if (count of selection) is 0 then return false
          delete selection
          return true
        end tell
        """
        var err: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return false }
        let result = script.executeAndReturnError(&err)
        return err == nil && result.booleanValue
    }

    @discardableResult
    private func chord(key: CGKeyCode, flags: CGEventFlags) -> Bool {
        let now = CACurrentMediaTime()
        guard now - lastKey > 0.28 else { return false }
        lastKey = now
        let src = CGEventSource(stateID: .hidSystemState)
        guard let down = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: true),
              let up = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: false)
        else { return false }
        down.flags = flags
        up.flags = flags
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        return true
    }

    @discardableResult
    private func postMouse(_ type: CGEventType, at point: CGPoint) -> Bool {
        let src = CGEventSource(stateID: .hidSystemState)
        guard let e = CGEvent(
            mouseEventSource: src,
            mouseType: type,
            mouseCursorPosition: ScreenGeometry.clampQuartz(point),
            mouseButton: .left
        ) else { return false }
        e.post(tap: .cghidEventTap)
        return true
    }

    private func targetWindow(at point: CGPoint? = nil) -> AXUIElement? {
        let loc = point ?? aimPoint
        if let win = window(at: loc), pid(of: win) != TargetProbe.selfPID {
            return win
        }
        guard let t = TargetProbe.windowUnderCursor(skipSelf: true) else { return nil }
        return axWindow(pid: t.pid, bounds: t.quartzBounds)
    }

    private func pid(of el: AXUIElement) -> pid_t {
        var pid: pid_t = 0
        AXUIElementGetPid(el, &pid)
        return pid
    }

    private func axWindow(pid: pid_t, bounds: CGRect) -> AXUIElement? {
        let app = ax(AXUIElementCreateApplication(pid))
        var ref: CFTypeRef?
        if AXUIElementCopyAttributeValue(app, "AXWindows" as CFString, &ref) == .success,
           let any = ref as? [AnyObject]
        {
            let windows = any.compactMap { $0 as? AXUIElement }
            // AXPosition liegt im selben Raum wie CGWindowList: oben links am
            // Hauptbildschirm, y nach unten. `bounds` ist bereits genau das.
            var best: AXUIElement?
            var bestArea: CGFloat = 0
            for w in windows {
                guard let pos = position(of: w), let size = size(of: w) else { continue }
                let r = CGRect(origin: pos, size: size)
                let inter = r.intersection(bounds)
                let area = inter.width * inter.height
                if area > bestArea, area > 40 {
                    bestArea = area
                    best = w
                }
            }
            if let best { return best }
            return windows.first
        }
        var focused: CFTypeRef?
        if AXUIElementCopyAttributeValue(app, "AXFocusedWindow" as CFString, &focused) == .success {
            return focused as? AXUIElement
        }
        return nil
    }

    private func window(at point: CGPoint) -> AXUIElement? {
        let sys = ax(AXUIElementCreateSystemWide())
        var ref: AXUIElement?
        let err = AXUIElementCopyElementAtPosition(sys, Float(point.x), Float(point.y), &ref)
        guard err == .success, let start = ref else { return nil }
        return ancestorWindow(start)
    }

    private func ancestorWindow(_ el: AXUIElement) -> AXUIElement? {
        var current: AXUIElement? = el
        for _ in 0..<12 {
            guard let c = current else { return nil }
            var role: CFTypeRef?
            AXUIElementCopyAttributeValue(c, "AXRole" as CFString, &role)
            if let r = role as? String, r == "AXWindow" {
                return c
            }
            var parent: CFTypeRef?
            let err = AXUIElementCopyAttributeValue(c, "AXParent" as CFString, &parent)
            if err != .success { return c }
            guard let next = parent as? AXUIElement else { return c }
            current = next
        }
        return current
    }

    private func ax(_ el: AXUIElement) -> AXUIElement {
        AXUIElementSetMessagingTimeout(el, 0.25)
        return el
    }

    private func position(of el: AXUIElement) -> CGPoint? {
        var v: CFTypeRef?
        guard AXUIElementCopyAttributeValue(el, "AXPosition" as CFString, &v) == .success else { return nil }
        guard let value = v as? AXValue else { return nil }
        var p = CGPoint.zero
        guard AXValueGetValue(value, .cgPoint, &p) else { return nil }
        return p
    }

    private func size(of el: AXUIElement) -> CGSize? {
        var v: CFTypeRef?
        guard AXUIElementCopyAttributeValue(el, "AXSize" as CFString, &v) == .success else { return nil }
        guard let value = v as? AXValue else { return nil }
        var s = CGSize.zero
        guard AXValueGetValue(value, .cgSize, &s) else { return nil }
        return s
    }

    @discardableResult
    private func setPosition(_ el: AXUIElement, _ p: CGPoint) -> Bool {
        Self.setPositionRaw(el, p)
    }

    nonisolated fileprivate static func setPositionRaw(_ el: AXUIElement, _ p: CGPoint) -> Bool {
        var point = p
        guard let val = AXValueCreate(.cgPoint, &point) else { return false }
        return AXUIElementSetAttributeValue(el, "AXPosition" as CFString, val) == .success
    }

    @discardableResult
    private func setSize(_ el: AXUIElement, _ s: CGSize) -> Bool {
        var size = s
        guard let val = AXValueCreate(.cgSize, &size) else { return false }
        return AXUIElementSetAttributeValue(el, "AXSize" as CFString, val) == .success
    }

    @discardableResult
    private func pressButton(_ win: AXUIElement, _ attr: CFString) -> ActionResult {
        var btn: CFTypeRef?
        let copy = AXUIElementCopyAttributeValue(win, attr, &btn)
        guard copy == .success, let button = btn as? AXUIElement else {
            return .fail("Kein Knopf \(attr)")
        }
        let act = AXUIElementPerformAction(button, "AXPress" as CFString)
        return act == .success ? .ok(attr as String) : .fail("AXPress \(act.rawValue)")
    }
}

/// Fensterziehen: nur die jüngste Position zählt. Ohne Koaleszieren staut sich
/// die AX-Queue auf und das Fenster hängt Sekunden hinter der Hand.
private final class AXDragPump: @unchecked Sendable {
    private let queue = DispatchQueue(label: "helios.ax", qos: .userInteractive)
    private let lock = NSLock()
    private var pending: (AXUIElement, CGPoint)?
    private var busy = false

    func submit(_ element: AXUIElement, _ point: CGPoint) {
        lock.lock()
        pending = (element, point)
        let start = !busy
        if start { busy = true }
        lock.unlock()
        guard start else { return }
        queue.async { self.drain() }
    }

    func cancel() {
        lock.lock()
        pending = nil
        lock.unlock()
    }

    private func drain() {
        while true {
            lock.lock()
            let item = pending
            pending = nil
            if item == nil { busy = false }
            lock.unlock()
            guard let item else { return }
            _ = SystemControl.setPositionRaw(item.0, item.1)
        }
    }
}

/// Hält den laufenden Prozess fest, bis er beendet ist. Ohne starke Referenz
/// kann der terminationHandler ausbleiben; ihn im Handler selbst zu halten wäre
/// ein Zyklus.
private final class ProcessKeeper: @unchecked Sendable {
    static let shared = ProcessKeeper()
    private let lock = NSLock()
    private var live: [ObjectIdentifier: Process] = [:]

    func hold(_ process: Process) {
        lock.lock()
        live[ObjectIdentifier(process)] = process
        lock.unlock()
    }

    func drop(_ process: Process) {
        lock.lock()
        live[ObjectIdentifier(process)] = nil
        lock.unlock()
    }
}

enum WindowCapture {
    /// Startet screencapture, ohne auf das Ende zu warten — `waitUntilExit` auf dem
    /// Main-Thread friert HUD und Kamerabild für die Dauer der Aufnahme ein.
    /// Das echte Ergebnis kommt über `done` nach.
    static func launch(
        windowID: CGWindowID,
        done: @escaping @MainActor @Sendable (ActionResult) -> Void
    ) -> ActionResult {
        let dir = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyyMMdd-HHmmss"
        let url = dir.appendingPathComponent("Helios-\(fmt.string(from: Date())).png")
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        if windowID != 0 {
            proc.arguments = ["-l\(windowID)", "-x", url.path]
        } else {
            proc.arguments = ["-x", url.path]
        }
        proc.terminationHandler = { finished in
            let status = finished.terminationStatus
            ProcessKeeper.shared.drop(finished)
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    if status == 0, FileManager.default.fileExists(atPath: url.path) {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                        done(.ok(url.lastPathComponent))
                    } else {
                        done(.fail("screencapture \(status)"))
                    }
                }
            }
        }
        // Vor dem Start festhalten: ein sofort beendeter Prozess würde sonst
        // `drop` vor `hold` ausführen und den Eintrag dauerhaft liegen lassen.
        ProcessKeeper.shared.hold(proc)
        do {
            try proc.run()
            return .ok("läuft")
        } catch {
            ProcessKeeper.shared.drop(proc)
            return .fail("screencapture: \(error.localizedDescription)")
        }
    }
}

extension NSPoint {
    var screenFlipped: CGPoint {
        ScreenGeometry.quartz(fromCocoa: self)
    }
}

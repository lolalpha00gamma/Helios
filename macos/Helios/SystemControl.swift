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
    private var dragGrabOffset: CGPoint = .zero
    private var dragBeganAt: TimeInterval = 0
    private var dragBeganQuartz: CGPoint?
    private var lastClick: TimeInterval = 0
    private var lastKey: TimeInterval = 0
    private var lastPosted: CGPoint?
    private var lastPostAt: TimeInterval = 0
    private var pauseUntil: TimeInterval = 0
    private var keyPauseUntil: TimeInterval = 0
    private var monitors: [Any] = []
    private(set) var mouseHasControl = false
    private let axQ = DispatchQueue(label: "helios.ax", qos: .userInteractive)
    /// Markiert eigene CGEvents. Clutch filtert darüber, nicht nur über 120 ms.
    private static let stampMagic: Int64 = 0x48454C49

    var fromInstallMedia: Bool {
        AppInstall.isFromDiskImage
    }

    var allowsInjection: Bool {
        if fromInstallMedia { return false }
        if CACurrentMediaTime() < pauseUntil {
            mouseHasControl = true
            return false
        }
        if CACurrentMediaTime() < keyPauseUntil {
            return false
        }
        mouseHasControl = false
        return true
    }

    /// Sichtbar im HUD: warum Injektion gerade steht.
    var clutchReason: String? {
        if fromInstallMedia { return nil }
        if CACurrentMediaTime() < pauseUntil { return "Maus" }
        if CACurrentMediaTime() < keyPauseUntil { return "Tastatur" }
        return nil
    }

    /// Restzeit 0…1 für den Clutch-Ring (Maus 850 ms, Tastatur 400 ms).
    var clutchRemain: CGFloat {
        let now = CACurrentMediaTime()
        if now < pauseUntil {
            return CGFloat(min(1, max(0, (pauseUntil - now) / 0.85)))
        }
        if now < keyPauseUntil {
            return CGFloat(min(1, max(0, (keyPauseUntil - now) / 0.40)))
        }
        return 0
    }

    func startClutch() {
        guard monitors.isEmpty else { return }
        let mouse: NSEvent.EventTypeMask = [.leftMouseDragged, .mouseMoved]
        let keys: NSEvent.EventTypeMask = [.keyDown]
        let noteMouse: (NSEvent) -> Void = { [weak self] e in
            Task { @MainActor in self?.noteHardware(e) }
        }
        let noteKey: (NSEvent) -> Void = { [weak self] _ in
            Task { @MainActor in self?.noteKeyboard() }
        }
        if let g = NSEvent.addGlobalMonitorForEvents(matching: mouse, handler: noteMouse) {
            monitors.append(g)
        }
        if let g = NSEvent.addGlobalMonitorForEvents(matching: keys, handler: noteKey) {
            monitors.append(g)
        }
        if let l = NSEvent.addLocalMonitorForEvents(matching: keys, handler: { [weak self] e in
            Task { @MainActor in self?.noteKeyboard() }
            return e
        }) {
            monitors.append(l)
        }
    }

    private func noteKeyboard() {
        keyPauseUntil = CACurrentMediaTime() + 0.40
    }

    private func noteHardware(_ e: NSEvent) {
        guard e.type == .leftMouseDragged || e.type == .mouseMoved else { return }
        let now = CACurrentMediaTime()
        let d = hypot(e.deltaX, e.deltaY)
        if isOwnEvent(e), d <= 12 { return }
        // Fallback: UserData überlebt den HID-Tap nicht immer.
        if now - lastPostAt < 0.12, d <= 9 { return }
        guard d > 3.5 else { return }
        seize(now)
    }

    private func isOwnEvent(_ e: NSEvent) -> Bool {
        guard let cg = e.cgEvent else { return false }
        if cg.getIntegerValueField(.eventSourceUserData) == Self.stampMagic { return true }
        let pid = cg.getIntegerValueField(.eventSourceUnixProcessID)
        return pid == Int64(ProcessInfo.processInfo.processIdentifier)
    }

    private func stamp(_ e: CGEvent) {
        e.setIntegerValueField(.eventSourceUserData, Self.stampMagic)
    }

    private func seize(_ now: TimeInterval) {
        pauseUntil = now + 0.85
        mouseHasControl = true
    }

    func moveCursor(to point: CGPoint) {
        guard allowsInjection else { return }
        let p = ScreenGeometry.clampQuartz(point)
        lastPosted = p
        lastPostAt = CACurrentMediaTime()
        let src = CGEventSource(stateID: .hidSystemState)
        let e = CGEvent(mouseEventSource: src, mouseType: .mouseMoved, mouseCursorPosition: p, mouseButton: .left)
        if let e {
            stamp(e)
            e.post(tap: .cghidEventTap)
        }
    }

    @discardableResult
    func click() -> ActionResult {
        let now = CACurrentMediaTime()
        guard now - lastClick > 0.12 else { return .fail("Klick-Pause") }
        lastClick = now
        guard allowsInjection else { return .fail("Maus hat Vorrang") }
        let loc = lastPosted ?? NSEvent.mouseLocation.screenFlipped
        guard postMouse(.leftMouseDown, at: loc), postMouse(.leftMouseUp, at: loc) else {
            return .fail("CGEvent Klick")
        }
        return .ok("Klick")
    }

    @discardableResult
    func rightClick() -> ActionResult {
        let now = CACurrentMediaTime()
        guard now - lastClick > 0.12 else { return .fail("Klick-Pause") }
        lastClick = now
        guard allowsInjection else { return .fail("Maus hat Vorrang") }
        let loc = lastPosted ?? NSEvent.mouseLocation.screenFlipped
        guard postMouse(.rightMouseDown, at: loc, button: .right),
              postMouse(.rightMouseUp, at: loc, button: .right)
        else {
            return .fail("CGEvent Rechtsklick")
        }
        return .ok("Rechtsklick")
    }

    @discardableResult
    func scroll(ticks: Int32) -> ActionResult {
        guard allowsInjection else { return .fail("Maus hat Vorrang") }
        guard ticks != 0 else { return .ok("0") }
        let src = CGEventSource(stateID: .hidSystemState)
        guard let e = CGEvent(
            scrollWheelEvent2Source: src,
            units: .pixel,
            wheelCount: 1,
            wheel1: ticks,
            wheel2: 0,
            wheel3: 0
        ) else {
            return .fail("CGEvent Scroll")
        }
        stamp(e)
        e.post(tap: .cghidEventTap)
        return .ok(String(format: "%+d", ticks))
    }

    @discardableResult
    func beginWindowDrag(at quartz: CGPoint? = nil) -> ActionResult {
        guard allowsInjection else { return .fail("Maus hat Vorrang — Steuerung pausiert") }
        let loc = quartz ?? lastPosted ?? NSEvent.mouseLocation.screenFlipped
        guard let win = targetWindow(at: loc, allowFrontmost: false) else {
            if AppInstall.needsCopy {
                return .fail("Läuft nicht aus Programme")
            }
            return .fail("Kein Fenster unter der Hand")
        }
        guard let pos = position(of: win) else { return .fail("AXPosition") }
        dragElement = win
        let cocoa = ScreenGeometry.cocoa(fromQuartz: loc)
        dragGrabOffset = CGPoint(x: cocoa.x - pos.x, y: cocoa.y - pos.y)
        lastPosted = loc
        dragBeganAt = CACurrentMediaTime()
        dragBeganQuartz = loc
        return .ok("Greifen")
    }

    func updateWindowDrag(to quartz: CGPoint? = nil) {
        guard allowsInjection else {
            endWindowDrag()
            return
        }
        guard let win = dragElement else { return }
        let loc = quartz ?? lastPosted ?? NSEvent.mouseLocation.screenFlipped
        // 80 ms nach Griff: Bewegungen unter 4 px sind Pinch-Jitter, kein Zug.
        if CACurrentMediaTime() - dragBeganAt < 0.08, let start = dragBeganQuartz,
           hypot(loc.x - start.x, loc.y - start.y) < 4
        {
            return
        }
        lastPosted = loc
        let cocoa = ScreenGeometry.cocoa(fromQuartz: loc)
        let dest = CGPoint(x: cocoa.x - dragGrabOffset.x, y: cocoa.y - dragGrabOffset.y)
        let captured = win
        axQ.async {
            _ = SystemControl.setPositionRaw(captured, dest)
        }
    }

    func endWindowDrag() {
        dragElement = nil
        dragBeganQuartz = nil
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
    func nudgeWindow(dLeft: CGFloat, dRight: CGFloat) -> ActionResult {
        guard let win = targetWindow(), let size = size(of: win), let pos = position(of: win) else {
            return .fail("Kein Fenster zum Skalieren")
        }
        let nx = pos.x + dLeft
        let nw = max(280, size.width - dLeft + dRight)
        guard setPosition(win, CGPoint(x: nx, y: pos.y)), setSize(win, CGSize(width: nw, height: size.height)) else {
            return .fail("AX Kante")
        }
        return .ok(String(format: "Kanten %+0.f/%+0.f", dLeft, dRight))
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
        let loc = NSEvent.mouseLocation.screenFlipped
        let screen = ScreenGeometry.screenContaining(quartz: loc) ?? NSScreen.main
        guard let screen else { return .fail("Kein Bildschirm") }
        let vis = screen.visibleFrame
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
        let r = WindowCapture.captureSync(windowID: windowID, bounds: bounds)
        return r
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
    private func postMouse(_ type: CGEventType, at point: CGPoint, button: CGMouseButton = .left) -> Bool {
        let src = CGEventSource(stateID: .hidSystemState)
        guard let e = CGEvent(
            mouseEventSource: src,
            mouseType: type,
            mouseCursorPosition: ScreenGeometry.clampQuartz(point),
            mouseButton: button
        ) else { return false }
        stamp(e)
        e.post(tap: .cghidEventTap)
        return true
    }

    private func targetWindow(at point: CGPoint? = nil, allowFrontmost: Bool = true) -> AXUIElement? {
        let loc = point ?? lastPosted ?? NSEvent.mouseLocation.screenFlipped
        if let win = window(at: loc), pid(of: win) != TargetProbe.selfPID {
            return win
        }
        if let t = TargetProbe.windowAt(quartz: loc, skipSelf: true) {
            return axWindow(pid: t.pid, bounds: t.quartzBounds)
        }
        // Greifen: nie frontmost, wenn unter der Hand ein anderes CGWindow liegt.
        // Minimize/Snap dürfen weiter das Fokusfenster nehmen.
        guard allowFrontmost else { return nil }
        return frontWindow()
    }

    private func frontWindow() -> AXUIElement? {
        guard let t = TargetProbe.frontmost(skipSelf: true) else { return nil }
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
            let windows = any.map { $0 as! AXUIElement }
            // AXPosition ist Cocoa (unten links am Hauptbildschirm).
            let cocoa = ScreenGeometry.cocoaRect(fromQuartz: bounds)
            var best: AXUIElement?
            var bestArea: CGFloat = 0
            for w in windows {
                guard let pos = position(of: w), let size = size(of: w) else { continue }
                let r = CGRect(origin: pos, size: size)
                let inter = r.intersection(cocoa)
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
            return focused.map { $0 as! AXUIElement }
        }
        return nil
    }

    private func window(at point: CGPoint) -> AXUIElement? {
        let sys = ax(AXUIElementCreateSystemWide())
        var ref: AXUIElement?
        // AXUIElementCopyElementAtPosition ist Cocoa (unten links), Cursor ist Quartz.
        let cocoa = ScreenGeometry.cocoa(fromQuartz: point)
        let err = AXUIElementCopyElementAtPosition(sys, Float(cocoa.x), Float(cocoa.y), &ref)
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
            current = parent.map { $0 as! AXUIElement }
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
        var p = CGPoint.zero
        AXValueGetValue(v as! AXValue, .cgPoint, &p)
        return p
    }

    private func size(of el: AXUIElement) -> CGSize? {
        var v: CFTypeRef?
        guard AXUIElementCopyAttributeValue(el, "AXSize" as CFString, &v) == .success else { return nil }
        var s = CGSize.zero
        AXValueGetValue(v as! AXValue, .cgSize, &s)
        return s
    }

    @discardableResult
    private func setPosition(_ el: AXUIElement, _ p: CGPoint) -> Bool {
        Self.setPositionRaw(el, p)
    }

    nonisolated private static func setPositionRaw(_ el: AXUIElement, _ p: CGPoint) -> Bool {
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
        guard copy == .success, let btn else { return .fail("Kein Knopf \(attr)") }
        let act = AXUIElementPerformAction(btn as! AXUIElement, "AXPress" as CFString)
        return act == .success ? .ok(attr as String) : .fail("AXPress \(act.rawValue)")
    }
}

enum WindowCapture {
    static func captureSync(windowID: CGWindowID, bounds: CGRect) -> ActionResult {
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
        do {
            try proc.run()
            proc.waitUntilExit()
            if proc.terminationStatus == 0, FileManager.default.fileExists(atPath: url.path) {
                NSWorkspace.shared.activateFileViewerSelecting([url])
                return .ok(url.lastPathComponent)
            }
            return .fail("screencapture \(proc.terminationStatus)")
        } catch {
            return .fail("screencapture: \(error.localizedDescription)")
        }
    }
}

extension NSPoint {
    var screenFlipped: CGPoint {
        ScreenGeometry.quartz(fromCocoa: self)
    }
}

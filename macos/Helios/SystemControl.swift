import ApplicationServices
import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum SnapEdge {
    case left, right, fill
}

struct ChromeKnob: Equatable {
    enum Kind: String {
        case close, min, zoom
    }

    var kind: Kind
    var quartz: CGRect

    var center: CGPoint { CGPoint(x: quartz.midX, y: quartz.midY) }

    var labelDE: String {
        switch kind {
        case .close: return "Schließen"
        case .min: return "Minimieren"
        case .zoom: return "Vollbild"
        }
    }
}

struct ActionResult {
    var ok: Bool
    var detail: String
    var skipped: Bool = false

    static func ok(_ detail: String = "OK") -> ActionResult { ActionResult(ok: true, detail: detail) }
    static func fail(_ detail: String) -> ActionResult { ActionResult(ok: false, detail: detail) }
    static func skip(_ detail: String) -> ActionResult { ActionResult(ok: true, detail: detail, skipped: true) }
}

@MainActor
final class SystemControl {
    private var dragElement: AXUIElement?
    private var dragGrabOffset: CGPoint = .zero
    private var dragDest: CGPoint?
    private var dragInFlight = false
    private var lastClick: TimeInterval = 0
    private var lastKey: TimeInterval = 0
    private var lastPosted: CGPoint?
    private var lastPostAt: TimeInterval = 0
    private var pauseUntil: TimeInterval = 0
    private var monitors: [Any] = []
    private(set) var mouseHasControl = false
    private let axQ = DispatchQueue(label: "helios.ax", qos: .userInteractive)

    var fromInstallMedia: Bool { AppInstall.isFromDiskImage }

    var allowsInjection: Bool {
        if fromInstallMedia { return false }
        if CACurrentMediaTime() < pauseUntil {
            mouseHasControl = true
            return false
        }
        mouseHasControl = false
        return true
    }

    func startClutch() {
        guard monitors.isEmpty else { return }
        let mask: NSEvent.EventTypeMask = [.leftMouseDragged, .mouseMoved]
        let note: (NSEvent) -> Void = { [weak self] e in
            Task { @MainActor in self?.noteHardware(e) }
        }
        if let g = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: note) {
            monitors.append(g)
        }
        if let l = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { e in
            note(e)
            return e
        }) {
            monitors.append(l)
        }
    }

    func stopClutch() {
        for m in monitors { NSEvent.removeMonitor(m) }
        monitors.removeAll()
    }

    private func noteHardware(_ e: NSEvent) {
        guard e.type == .leftMouseDragged || e.type == .mouseMoved else { return }
        let d = hypot(e.deltaX, e.deltaY)
        guard d > 3.5 else { return }
        if let posted = lastPosted {
            let nowLoc = NSEvent.mouseLocation.screenFlipped
            if hypot(nowLoc.x - posted.x, nowLoc.y - posted.y) < 10 { return }
        }
        seize(CACurrentMediaTime())
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
        e?.post(tap: .cghidEventTap)
    }

    @discardableResult
    func click() -> ActionResult {
        let now = CACurrentMediaTime()
        guard now - lastClick > 0.12 else { return .skip("Klick-Pause") }
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
        guard now - lastClick > 0.12 else { return .skip("Klick-Pause") }
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
        e.post(tap: .cghidEventTap)
        return .ok(String(format: "%+d", ticks))
    }

    func chromeKnobs(at quartz: CGPoint? = nil) -> [ChromeKnob] {
        guard let win = targetWindow(at: quartz) else { return [] }
        let specs: [(ChromeKnob.Kind, CFString)] = [
            (.close, "AXCloseButton" as CFString),
            (.min, "AXMinimizeButton" as CFString),
            (.zoom, "AXFullScreenButton" as CFString),
            (.zoom, "AXZoomButton" as CFString)
        ]
        var out: [ChromeKnob] = []
        var seen = Set<ChromeKnob.Kind>()
        for (kind, attr) in specs {
            if seen.contains(kind) { continue }
            var ref: CFTypeRef?
            guard AXUIElementCopyAttributeValue(win, attr, &ref) == .success,
                  let el = Self.asElement(ref),
                  let pos = position(of: el),
                  let size = size(of: el),
                  size.width > 4, size.height > 4
            else { continue }
            let cocoa = CGRect(origin: pos, size: size)
            let q = ScreenGeometry.quartzRect(fromCocoa: cocoa)
            out.append(ChromeKnob(kind: kind, quartz: q))
            seen.insert(kind)
        }
        return out
    }

    @discardableResult
    func beginWindowDrag(at quartz: CGPoint? = nil) -> ActionResult {
        guard allowsInjection else { return .fail("Maus hat Vorrang — Steuerung pausiert") }
        let loc = quartz ?? lastPosted ?? NSEvent.mouseLocation.screenFlipped
        guard let win = targetWindow(at: loc) ?? frontWindow() else {
            if AppInstall.needsCopy {
                return .fail("Läuft nicht aus Programme")
            }
            return .fail("Kein Fenster unter der Hand")
        }
        guard let pos = position(of: win) else { return .fail("AXPosition") }
        dragElement = ax(win)
        dragDest = nil
        dragInFlight = false
        let cocoa = ScreenGeometry.cocoa(fromQuartz: loc)
        dragGrabOffset = CGPoint(x: cocoa.x - pos.x, y: cocoa.y - pos.y)
        lastPosted = loc
        return .ok("Greifen")
    }

    func updateWindowDrag(to quartz: CGPoint? = nil) {
        guard allowsInjection else {
            endWindowDrag()
            return
        }
        guard dragElement != nil else { return }
        let loc = quartz ?? lastPosted ?? NSEvent.mouseLocation.screenFlipped
        lastPosted = loc
        let cocoa = ScreenGeometry.cocoa(fromQuartz: loc)
        dragDest = CGPoint(x: cocoa.x - dragGrabOffset.x, y: cocoa.y - dragGrabOffset.y)
        pumpDrag()
    }

    private func pumpDrag() {
        guard let win = dragElement, let dest = dragDest else { return }
        if dragInFlight { return }
        dragInFlight = true
        dragDest = nil
        let captured = win
        axQ.async {
            _ = SystemControl.setPositionRaw(captured, dest)
            Task { @MainActor in
                self.dragInFlight = false
                if self.dragElement != nil, self.dragDest != nil {
                    self.pumpDrag()
                }
            }
        }
    }

    func endWindowDrag() {
        dragElement = nil
        dragDest = nil
        dragInFlight = false
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
    func snapFocused(_ edge: SnapEdge, at quartz: CGPoint? = nil) -> ActionResult {
        guard let win = targetWindow() else { return .fail("Kein Fenster") }
        let loc = quartz ?? lastPosted ?? NSEvent.mouseLocation.screenFlipped
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
        if finder {
            axQ.async { _ = SystemControl.trashFinderSelection() }
            return .ok("Finder → Papierkorb")
        }
        return closeFocused()
    }

    @discardableResult
    func screenshotFocused(windowID: CGWindowID, bounds: CGRect) -> ActionResult {
        if windowID == 0 && bounds.width < 8 {
            return .fail("Kein Zielfenster")
        }
        return WindowCapture.captureAsync(windowID: windowID, bounds: bounds)
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
        if app.processIdentifier == TargetProbe.selfPID {
            return .fail("Helios selbst")
        }
        let name = app.localizedName ?? "App"
        app.unhide()
        app.activate()
        return .ok(name)
    }

    nonisolated private static func trashFinderSelection() -> Bool {
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
        e.post(tap: .cghidEventTap)
        return true
    }

    private func targetWindow(at point: CGPoint? = nil) -> AXUIElement? {
        let loc = point ?? lastPosted ?? NSEvent.mouseLocation.screenFlipped
        if let win = window(at: loc), pid(of: win) != TargetProbe.selfPID {
            return win
        }
        guard let t = TargetProbe.windowAt(quartz: loc, skipSelf: true) ?? TargetProbe.frontmost(skipSelf: true) else {
            return nil
        }
        return axWindow(pid: t.pid, bounds: t.quartzBounds)
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
            let windows = any.compactMap(Self.asElement)
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
            return focused.flatMap(Self.asElement)
        }
        return nil
    }

    private func window(at point: CGPoint) -> AXUIElement? {
        let sys = ax(AXUIElementCreateSystemWide())
        var ref: AXUIElement?
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
            current = parent.flatMap(Self.asElement)
        }
        return current
    }

    private func ax(_ el: AXUIElement) -> AXUIElement {
        AXUIElementSetMessagingTimeout(el, 0.25)
        return el
    }

    private func position(of el: AXUIElement) -> CGPoint? {
        var v: CFTypeRef?
        guard AXUIElementCopyAttributeValue(el, "AXPosition" as CFString, &v) == .success,
              let val = Self.asValue(v)
        else { return nil }
        var p = CGPoint.zero
        AXValueGetValue(val, .cgPoint, &p)
        return p
    }

    private func size(of el: AXUIElement) -> CGSize? {
        var v: CFTypeRef?
        guard AXUIElementCopyAttributeValue(el, "AXSize" as CFString, &v) == .success,
              let val = Self.asValue(v)
        else { return nil }
        var s = CGSize.zero
        AXValueGetValue(val, .cgSize, &s)
        return s
    }

    @discardableResult
    private func setPosition(_ el: AXUIElement, _ p: CGPoint) -> Bool {
        Self.setPositionRaw(el, p)
    }

    nonisolated private static func setPositionRaw(_ el: AXUIElement, _ p: CGPoint) -> Bool {
        var point = p
        guard let val = AXValueCreate(.cgPoint, &point) else { return false }
        AXUIElementSetMessagingTimeout(el, 0.25)
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
        guard copy == .success, let el = Self.asElement(btn) else { return .fail("Kein Knopf \(attr)") }
        let act = AXUIElementPerformAction(el, "AXPress" as CFString)
        return act == .success ? .ok(attr as String) : .fail("AXPress \(act.rawValue)")
    }

    nonisolated private static func asElement(_ ref: CFTypeRef?) -> AXUIElement? {
        guard let ref, CFGetTypeID(ref) == AXUIElementGetTypeID() else { return nil }
        return (ref as! AXUIElement)
    }

    nonisolated private static func asValue(_ ref: CFTypeRef?) -> AXValue? {
        guard let ref, CFGetTypeID(ref) == AXValueGetTypeID() else { return nil }
        return (ref as! AXValue)
    }
}

enum WindowCapture {
    static func captureAsync(windowID: CGWindowID, bounds: CGRect) -> ActionResult {
        let dir = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyyMMdd-HHmmss"
        let url = dir.appendingPathComponent("Helios-\(fmt.string(from: Date())).png")
        let args: [String] = windowID != 0 ? ["-l\(windowID)", "-x", url.path] : ["-x", url.path]
        DispatchQueue.global(qos: .userInitiated).async {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            proc.arguments = args
            do {
                try proc.run()
                proc.waitUntilExit()
                if proc.terminationStatus == 0, FileManager.default.fileExists(atPath: url.path) {
                    DispatchQueue.main.async {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                }
            } catch {}
        }
        return .ok(url.lastPathComponent)
    }
}

extension NSPoint {
    var screenFlipped: CGPoint {
        ScreenGeometry.quartz(fromCocoa: self)
    }
}

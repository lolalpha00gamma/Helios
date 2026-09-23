import ApplicationServices
import AppKit
import CoreGraphics
import Foundation
import ImageIO
import QuartzCore
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
    var hit: CGRect

    var center: CGPoint { CGPoint(x: hit.midX, y: hit.midY) }

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

/// Hält den Event-Tap. Der C-Callback darf SystemControl nicht direkt anfassen.
private let heliosOwnTag: Int64 = 0x48454C494F53

private final class ClutchTap {
    weak var owner: SystemControl?
    var port: CFMachPort?
    var source: CFRunLoopSource?
}

private func heliosClutchCallback(
    _: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let box = Unmanaged<ClutchTap>.fromOpaque(userInfo).takeUnretainedValue()
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let port = box.port { CGEvent.tapEnable(tap: port, enable: true) }
        return Unmanaged.passUnretained(event)
    }
    let tagged = event.getIntegerValueField(.eventSourceUserData) == heliosOwnTag
    if tagged { return Unmanaged.passUnretained(event) }
    let loc = event.location
    let kind: String
    let delta: CGFloat
    switch type {
    case .keyDown:
        kind = "key"
        delta = 0
    case .scrollWheel:
        var d = abs(CGFloat(event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1)))
            + abs(CGFloat(event.getDoubleValueField(.scrollWheelEventPointDeltaAxis2)))
        if d < 0.1 {
            d = abs(CGFloat(event.getIntegerValueField(.scrollWheelEventDeltaAxis1)))
                + abs(CGFloat(event.getIntegerValueField(.scrollWheelEventDeltaAxis2)))
        }
        kind = "scroll"
        delta = d
    case .leftMouseDown, .rightMouseDown, .otherMouseDown:
        kind = "button"
        delta = 0
    case .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
        let dx = CGFloat(event.getIntegerValueField(.mouseEventDeltaX))
        let dy = CGFloat(event.getIntegerValueField(.mouseEventDeltaY))
        kind = "move"
        delta = hypot(dx, dy)
    default:
        return Unmanaged.passUnretained(event)
    }
    let owner = box.owner
    Task { @MainActor in
        owner?.noteClutch(kind: kind, tagged: tagged, delta: delta, loc: loc)
    }
    return Unmanaged.passUnretained(event)
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
    private let clutchTap = ClutchTap()
    private(set) var mouseHasControl = false
    /// Markiert injizierte Events, damit die Kupplung sie nicht als echte Maus liest.
    private static let ownTag: Int64 = heliosOwnTag
    private var ownSource: CGEventSource?
    private var postingDepth = 0
    private let axQ = DispatchQueue(label: "helios.ax", qos: .userInteractive)
    private var chromeCache: (at: TimeInterval, point: CGPoint, knobs: [ChromeKnob])?
    private var axHitAt: TimeInterval = 0
    private var axHitKey = ""
    private var axHitEl: AXUIElement?
    private var axHitBounds: CGRect = .null
    /// Freeze-Geisterhand: Jiggler seize tot.
    var freezeLive = false
    /// Continuity 8 fps: axHitCacheFresh(dt: 0,04) tot vor dem nächsten Frame.
    var sampleDt: TimeInterval = 0.04

    var fromInstallMedia: Bool { AppInstall.isFromDiskImage }

    var allowsInjection: Bool {
        if CACurrentMediaTime() < pauseUntil {
            mouseHasControl = true
            return false
        }
        mouseHasControl = false
        return true
    }

    func startClutch() {
        guard clutchTap.port == nil, monitors.isEmpty else { return }
        clutchTap.owner = self
        let ptr = Unmanaged.passUnretained(clutchTap).toOpaque()
        if let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: Self.clutchEventMask,
            callback: heliosClutchCallback,
            userInfo: ptr
        ) {
            clutchTap.port = port
            let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
            clutchTap.source = src
            CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
            CGEvent.tapEnable(tap: port, enable: true)
            return
        }
        installMonitorFallback()
    }

    func stopClutch() {
        if let port = clutchTap.port {
            CGEvent.tapEnable(tap: port, enable: false)
            CFMachPortInvalidate(port)
        }
        if let source = clutchTap.source {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        clutchTap.port = nil
        clutchTap.source = nil
        clutchTap.owner = nil
        for m in monitors { NSEvent.removeMonitor(m) }
        monitors.removeAll()
    }

    private static var clutchEventMask: CGEventMask {
        let types: [CGEventType] = [
            .mouseMoved,
            .leftMouseDown, .leftMouseDragged,
            .rightMouseDown, .rightMouseDragged,
            .otherMouseDown, .otherMouseDragged,
            .scrollWheel,
            .keyDown
        ]
        return types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
    }

    /// Wenn der Event-Tap fehlt: lokale und globale Monitore, sonst gewinnt die Maus nur außerhalb der App.
    private func installMonitorFallback() {
        let mask: NSEvent.EventTypeMask = [
            .mouseMoved,
            .leftMouseDown, .leftMouseDragged,
            .rightMouseDown, .rightMouseDragged,
            .otherMouseDown, .otherMouseDragged,
            .scrollWheel,
            .keyDown
        ]
        let note: (NSEvent) -> Void = { [weak self] e in
            let tagged = e.cgEvent?.getIntegerValueField(.eventSourceUserData) == Self.ownTag
            let kind: String
            let delta: CGFloat
            switch e.type {
            case .keyDown:
                kind = "key"
                delta = 0
            case .scrollWheel:
                kind = "scroll"
                delta = abs(e.scrollingDeltaY) + abs(e.scrollingDeltaX)
            case .leftMouseDown, .rightMouseDown, .otherMouseDown:
                kind = "button"
                delta = 0
            default:
                kind = "move"
                delta = hypot(e.deltaX, e.deltaY)
            }
            let loc = e.cgEvent?.location ?? NSEvent.mouseLocation.screenFlipped
            Task { @MainActor in
                self?.noteClutch(kind: kind, tagged: tagged, delta: delta, loc: loc)
            }
        }
        if let g = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: note) {
            monitors.append(g)
        }
        if let local = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { e in
            note(e)
            return e
        }) {
            monitors.append(local)
        }
    }

    fileprivate func noteClutch(kind: String, tagged: Bool, delta: CGFloat, loc: CGPoint) {
        let now = CACurrentMediaTime()
        if GestureMath.clutchIgnoresFreeze(freezeLive: freezeLive) { return }
        let dist: CGFloat = {
            guard let posted = lastPosted else { return 10_000 }
            return hypot(loc.x - posted.x, loc.y - posted.y)
        }()
        let since = lastPostAt > 0 ? now - lastPostAt : -1
        if GestureMath.clutchIsOwn(
            tagged: tagged,
            posting: postingDepth > 0,
            kind: kind,
            dist: dist,
            sincePost: since
        ) {
            return
        }
        let scale = ScreenGeometry.backingScale(quartz: loc)
        guard GestureMath.hardwareClutch(own: false, kind: kind, delta: delta, scale: scale) else { return }
        let hold = (kind == "scroll") ? GestureMath.clutchScrollHold : GestureMath.clutchKeyHold
        seize(now, hold: hold)
    }

    private func seize(_ now: TimeInterval, hold: TimeInterval = 0.85) {
        pauseUntil = now + hold
        mouseHasControl = true
        if buttonDown || pointerDrag {
            endWindowDrag()
        }
    }

    private func eventSource() -> CGEventSource? {
        if ownSource == nil {
            let src = CGEventSource(stateID: .hidSystemState)
            src?.userData = Self.ownTag
            ownSource = src
        }
        return ownSource
    }

    private func postEvent(_ event: CGEvent) {
        event.setIntegerValueField(.eventSourceUserData, value: Self.ownTag)
        postingDepth += 1
        event.post(tap: .cghidEventTap)
        postingDepth -= 1
    }

    func moveCursor(to point: CGPoint) {
        guard GestureMath.pointerWarpAllowed(axTrusted: AXIsProcessTrusted()) else { return }
        let p = ScreenGeometry.clampQuartz(point)
        let now = CACurrentMediaTime()
        if let posted = lastPosted,
           !GestureMath.cgEventCoalesceDue(lastPost: lastPostAt, now: now),
           hypot(p.x - posted.x, p.y - posted.y) < 0.6
        {
            return
        }
        lastPosted = p
        lastPostAt = now
        if let e = CGEvent(mouseEventSource: eventSource(), mouseType: .mouseMoved, mouseCursorPosition: p, mouseButton: .left) {
            postEvent(e)
        }
    }

    @discardableResult
    func click(force: Bool = false, at point: CGPoint? = nil) -> ActionResult {
        let now = CACurrentMediaTime()
        if !force, GestureMath.clickHitchBlocks(lastClick: lastClick, now: now, dt: sampleDt) {
            return .skip("Klick-Hitch")
        }
        lastClick = now
        if !force, !allowsInjection { return .fail("Maus hat Vorrang") }
        let loc = ScreenGeometry.clampQuartz(point ?? lastPosted ?? NSEvent.mouseLocation.screenFlipped)
        lastPosted = loc
        lastPostAt = now
        if buttonDown {
            guard postMouse(.leftMouseUp, at: loc) else { return .fail("CGEvent Up") }
            buttonDown = false
            pointerDrag = false
            return .ok("Klick")
        }
        _ = postMouse(.mouseMoved, at: loc)
        guard postMouse(.leftMouseDown, at: loc), postMouse(.leftMouseUp, at: loc) else {
            return .fail("CGEvent Klick")
        }
        return .ok("Klick")
    }

    @discardableResult
    func press(at point: CGPoint, force: Bool = true) -> ActionResult {
        if !force, !allowsInjection { return .fail("Maus hat Vorrang") }
        if buttonDown { return .ok("Halten") }
        let loc = ScreenGeometry.clampQuartz(point)
        lastPosted = loc
        lastPostAt = CACurrentMediaTime()
        _ = postMouse(.mouseMoved, at: loc)
        guard postMouse(.leftMouseDown, at: loc) else { return .fail("CGEvent Down") }
        buttonDown = true
        return .ok("Halten")
    }

    @discardableResult
    func openFolder(_ url: URL) -> ActionResult {
        guard NSWorkspace.shared.open(url) else { return .fail("Finder") }
        return .ok(url.lastPathComponent)
    }

    @discardableResult
    func rightClick() -> ActionResult {
        let now = CACurrentMediaTime()
        if GestureMath.clickHitchBlocks(lastClick: lastClick, now: now, dt: sampleDt) {
            return .skip("Klick-Hitch")
        }
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
        guard let e = CGEvent(
            scrollWheelEvent2Source: eventSource(),
            units: .pixel,
            wheelCount: 1,
            wheel1: ticks,
            wheel2: 0,
            wheel3: 0
        ) else {
            return .fail("CGEvent Scroll")
        }
        postEvent(e)
        return .ok(String(format: "%+d", ticks))
    }

    func chromeKnobs(at quartz: CGPoint? = nil) -> [ChromeKnob] {
        let loc = quartz ?? lastPosted ?? NSEvent.mouseLocation.screenFlipped
        let now = CACurrentMediaTime()
        if let c = chromeCache, now - c.at < 0.26, hypot(c.point.x - loc.x, c.point.y - loc.y) < 16 {
            return c.knobs
        }
        var out: [ChromeKnob] = []
        var seen = Set<ChromeKnob.Kind>()
        if let win = targetWindow(at: loc) {
            let specs: [(ChromeKnob.Kind, CFString)] = [
                (.close, "AXCloseButton" as CFString),
                (.min, "AXMinimizeButton" as CFString),
                (.zoom, "AXFullScreenButton" as CFString),
                (.zoom, "AXZoomButton" as CFString)
            ]
            for (kind, attr) in specs {
                if seen.contains(kind) { continue }
                var ref: CFTypeRef?
                guard AXUIElementCopyAttributeValue(win, attr, &ref) == .success,
                      let el = Self.asElement(ref),
                      let pos = position(of: el),
                      let size = size(of: el),
                      size.width > 4, size.height > 4
                else { continue }
                let q = CGRect(origin: pos, size: size)
                out.append(ChromeKnob(kind: kind, quartz: q, hit: q))
                seen.insert(kind)
            }
        }
        if out.count < 3 {
            for k in geometricTrafficLights(at: loc) where !seen.contains(k.kind) {
                out.append(k)
                seen.insert(k.kind)
            }
        }
        let spread = GestureMath.spreadChrome(centers: out.map { CGPoint(x: $0.quartz.midX, y: $0.quartz.midY) })
        for i in out.indices where i < spread.count {
            out[i].hit = spread[i]
        }
        chromeCache = (now, loc, out)
        return out
    }

    private func geometricTrafficLights(at loc: CGPoint) -> [ChromeKnob] {
        guard let t = TargetProbe.windowAt(quartz: loc, skipSelf: true) ?? TargetProbe.frontmost(skipSelf: true) else {
            return []
        }
        return GestureMath.trafficLights(bounds: t.quartzBounds).compactMap { item in
            guard let kind = ChromeKnob.Kind(rawValue: item.kind) else { return nil }
            return ChromeKnob(kind: kind, quartz: item.rect, hit: item.rect)
        }
    }

    private var pointerDrag = false
    private var buttonDown = false

    @discardableResult
    func beginWindowDrag(at quartz: CGPoint? = nil, force: Bool = false) -> ActionResult {
        if !force, !allowsInjection { return .fail("Maus hat Vorrang — Steuerung pausiert") }
        let loc = quartz ?? lastPosted ?? NSEvent.mouseLocation.screenFlipped
        lastPosted = loc
        if !buttonDown {
            _ = postMouse(.mouseMoved, at: loc)
            guard postMouse(.leftMouseDown, at: loc) else { return .fail("CGEvent Down") }
            buttonDown = true
        }
        pointerDrag = true
        return .ok("Ziehen")
    }

    func updateWindowDrag(to quartz: CGPoint? = nil) {
        if !buttonDown, !pointerDrag { return }
        if !allowsInjection, !buttonDown {
            endWindowDrag()
            return
        }
        let loc = quartz ?? lastPosted ?? NSEvent.mouseLocation.screenFlipped
        lastPosted = loc
        _ = postMouse(.leftMouseDragged, at: loc)
    }

    func endWindowDrag() {
        if buttonDown || pointerDrag {
            let loc = lastPosted ?? NSEvent.mouseLocation.screenFlipped
            _ = postMouse(.leftMouseUp, at: loc)
        }
        buttonDown = false
        pointerDrag = false
        dragElement = nil
        dragDest = nil
        dragInFlight = false
    }

    var isDragging: Bool { pointerDrag }
    var isPressed: Bool { buttonDown }

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
        clickChrome(.min)
    }

    @discardableResult
    func closeFocused() -> ActionResult {
        clickChrome(.close)
    }

    @discardableResult
    func zoomFocused() -> ActionResult {
        clickChrome(.zoom)
    }

    @discardableResult
    private func clickChrome(_ kind: ChromeKnob.Kind, at quartz: CGPoint? = nil) -> ActionResult {
        let knobs = chromeKnobs(at: quartz)
        guard let k = knobs.first(where: { $0.kind == kind }) else { return .fail("Keine Ampel") }
        moveCursor(to: k.center)
        return click()
    }

    @discardableResult
    func snapFocused(_ edge: SnapEdge, at quartz: CGPoint? = nil) -> ActionResult {
        guard let win = targetWindow() else { return .fail("Kein Fenster") }
        let loc = quartz ?? lastPosted ?? NSEvent.mouseLocation.screenFlipped
        let screen = ScreenGeometry.screenContaining(quartz: loc) ?? NSScreen.main
        guard let screen else { return .fail("Kein Bildschirm") }
        // visibleFrame is Cocoa; AXPosition wants Quartz (top-left).
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
    func unhideFront(at quartz: CGPoint? = nil) -> ActionResult {
        let loc = quartz ?? lastPosted ?? TargetProbe.cursorInWindowList()
        if let t = TargetProbe.windowAt(quartz: loc, skipSelf: true)
            ?? TargetProbe.frontmost(skipSelf: true),
           let app = NSRunningApplication(processIdentifier: t.pid)
        {
            app.unhide()
            return activate(app)
        }
        return .fail("Keine App unter der Hand")
    }

    @discardableResult
    func switchDesktop(forward: Bool) -> ActionResult {
        // ctrl+← / ctrl+→  Mission Control Spaces
        let key: CGKeyCode = forward ? 124 : 123
        if chord(key: key, flags: .maskControl) {
            return .ok(forward ? "→" : "←")
        }
        return .fail("Schreibtisch-Taste")
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
                guard let dict = item[kCGWindowBounds as String] as? [String: CGFloat] else { continue }
                let r = CGRect(
                    x: dict["X"] ?? 0,
                    y: dict["Y"] ?? 0,
                    width: dict["Width"] ?? 0,
                    height: dict["Height"] ?? 0
                )
                if TargetProbe.isWallpaper(item: item, bounds: r, pid: pid) { continue }
                guard let app = NSRunningApplication(processIdentifier: pid),
                      app.activationPolicy == .regular,
                      !app.isTerminated
                else { continue }
                seen.insert(pid)
                ordered.append(app)
            }
        }
        guard ordered.count >= 2 else {
            return .fail("Keine andere App")
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
    func typeKey(_ code: CGKeyCode, flags: CGEventFlags = []) -> ActionResult {
        let now = CACurrentMediaTime()
        guard now - lastKey > 0.08 else { return .skip("Taste-Pause") }
        lastKey = now
        guard allowsInjection else { return .fail("Maus hat Vorrang") }
        guard let down = CGEvent(keyboardEventSource: eventSource(), virtualKey: code, keyDown: true),
              let up = CGEvent(keyboardEventSource: eventSource(), virtualKey: code, keyDown: false)
        else {
            return .fail("CGEvent Taste")
        }
        down.flags = flags
        up.flags = flags
        postEvent(down)
        postEvent(up)
        return .ok("\(code)")
    }

    @discardableResult
    private func chord(key: CGKeyCode, flags: CGEventFlags) -> Bool {
        let now = CACurrentMediaTime()
        guard now - lastKey > 0.28 else { return false }
        lastKey = now
        guard let down = CGEvent(keyboardEventSource: eventSource(), virtualKey: key, keyDown: true),
              let up = CGEvent(keyboardEventSource: eventSource(), virtualKey: key, keyDown: false)
        else { return false }
        down.flags = flags
        up.flags = flags
        postEvent(down)
        postEvent(up)
        return true
    }

    @discardableResult
    private func postMouse(_ type: CGEventType, at point: CGPoint, button: CGMouseButton = .left) -> Bool {
        let loc = ScreenGeometry.clampQuartz(point)
        guard let e = CGEvent(
            mouseEventSource: eventSource(),
            mouseType: type,
            mouseCursorPosition: loc,
            mouseButton: button
        ) else { return false }
        e.setIntegerValueField(.mouseEventClickState, value: 1)
        postEvent(e)
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
            return focused.flatMap(Self.asElement)
        }
        return nil
    }

    private func window(at point: CGPoint) -> AXUIElement? {
        let now = CACurrentMediaTime()
        if let held = axHitEl,
           GestureMath.axWindowCacheHolds(cursor: point, bounds: axHitBounds)
        {
            axHitAt = now
            return held
        }
        let key = GestureMath.axHitCacheKey(cursor: point)
        if GestureMath.axHitCacheFresh(cachedAt: axHitAt, now: now, dt: sampleDt), key == axHitKey {
            return axHitEl
        }
        let sys = ax(AXUIElementCreateSystemWide())
        var ref: AXUIElement?
        let err = AXUIElementCopyElementAtPosition(sys, Float(point.x), Float(point.y), &ref)
        let found: AXUIElement?
        if err == .success, let start = ref {
            found = ancestorWindow(start)
        } else {
            found = nil
        }
        axHitAt = now
        axHitKey = key
        axHitEl = found
        if let found, let pos = position(of: found), let sz = size(of: found) {
            axHitBounds = CGRect(origin: pos, size: sz)
        } else {
            axHitBounds = .null
        }
        return found
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

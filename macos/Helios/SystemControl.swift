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
    private var dragOwnWindow: NSWindow?
    private var dragGrabOffset: CGPoint = .zero
    private var dragSize: CGSize = .zero
    private var dragFailStreak = 0
    private var axInFlight = false
    private var axPending: CGPoint?
    private var dragGen: UInt64 = 0
    private var lastClick: TimeInterval = 0
    private var lastKey: TimeInterval = 0
    private var lastPosted: CGPoint?
    private var lastPostAt: TimeInterval = 0
    private var pauseUntil: TimeInterval = 0
    private var monitors: [Any] = []
    private(set) var mouseHasControl = false
    /// Engine: Palm-Speed. Trackpad-Clutch braucht ruhige Hand.
    var palmSpeed: CGFloat = 0
    private var mousePressed = false
    private var pressPoint: CGPoint?
    private var pressFrame: CGRect?
    private var pressRole: String?
    private var pressSubrole: String?
    private let axQ = DispatchQueue(label: "helios.ax", qos: .userInteractive)
    var onEscape: (() -> Void)?
    private var hitCache: HitProbe?
    /// Continuity 180 ms, Built-in 90 ms. Engine setzt das aus dt.
    var probeTTL: TimeInterval = 0.09
    /// Luma-Skip: letzten Probe behalten, keinen Roundtrip.
    var skipProbe = false
    private var lightsCacheAt: TimeInterval = 0
    private var lightsCacheLoc: CGPoint = .zero
    private var lightsCached: [CGPoint] = []

    func invalidateProbe() {
        hitCache = nil
        lightsCacheAt = 0
        lightsCached = []
    }

    private struct HitProbe {
        var loc: CGPoint
        var at: TimeInterval
        var role: String?
        var subrole: String?
        var frame: CGRect?
        var lights: [CGPoint]
    }

    var fromInstallMedia: Bool {
        AppInstall.isFromDiskImage
    }

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
        let mask: NSEvent.EventTypeMask = [.leftMouseDragged, .rightMouseDragged, .otherMouseDragged, .mouseMoved]
        let note: (NSEvent) -> Void = { [weak self] e in
            Task { @MainActor in self?.noteHardware(e) }
        }
        if let g = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: note) {
            monitors.append(g)
        }
        if let local = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { [weak self] e in
            Task { @MainActor in self?.noteHardware(e) }
            return e
        }) {
            monitors.append(local)
        }
        if let gKey = NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: { [weak self] e in
            Task { @MainActor in self?.noteKey(e) }
        }) {
            monitors.append(gKey)
        }
        if let localKey = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { [weak self] e in
            Task { @MainActor in self?.noteKey(e) }
            return e
        }) {
            monitors.append(localKey)
        }
    }

    private func noteKey(_ e: NSEvent) {
        if e.keyCode == 53 { onEscape?() }
        if GestureMath.cmdPeriodCancels(
            keyCode: e.keyCode,
            command: e.modifierFlags.contains(.command)
        ) {
            onEscape?()
        }
    }

    private func noteHardware(_ e: NSEvent) {
        let now = CACurrentMediaTime()
        let loc = NSEvent.mouseLocation.screenFlipped
        if let posted = lastPosted, hypot(loc.x - posted.x, loc.y - posted.y) < 10, now - lastPostAt < 0.28 {
            return
        }
        if now - lastPostAt < 0.12 { return }
        let d = hypot(e.deltaX, e.deltaY)
        let dragged = e.type != .mouseMoved
        guard GestureMath.trackpadClutch(mouseDelta: d, palmSpeed: palmSpeed, dragged: dragged) else { return }
        seize(now)
    }

    private func seize(_ now: TimeInterval) {
        pauseUntil = now + 0.85
        mouseHasControl = true
        cancelPress()
    }

    func moveCursor(to point: CGPoint) {
        guard allowsInjection else { return }
        let p = ScreenGeometry.clampQuartz(point)
        lastPosted = p
        lastPostAt = CACurrentMediaTime()
        CGWarpMouseCursorPosition(p)
        let src = CGEventSource(stateID: .privateState)
        let type: CGEventType = mousePressed ? .leftMouseDragged : .mouseMoved
        let e = CGEvent(mouseEventSource: src, mouseType: type, mouseCursorPosition: p, mouseButton: .left)
        e?.post(tap: .cghidEventTap)
    }

    var isMousePressed: Bool { mousePressed }

    /// Ein AX-Roundtrip pro Tick: Rolle, Subrole, Frame, Traffic-Lights.
    private func loadProbe(at loc: CGPoint) -> HitProbe {
        let now = CACurrentMediaTime()
        if skipProbe {
            if let c = hitCache { return c }
            let empty = HitProbe(loc: loc, at: now, role: nil, subrole: nil, frame: nil, lights: [])
            if GestureMath.skipProbeStoresEmpty() {
                hitCache = empty
            }
            return empty
        }
        if let c = hitCache, hypot(c.loc.x - loc.x, c.loc.y - loc.y) < GestureMath.axHitCacheDistTTL(probeTTL), now - c.at < probeTTL {
            return c
        }
        let sys = ax(AXUIElementCreateSystemWide())
        var ref: AXUIElement?
        let err = AXUIElementCopyElementAtPosition(sys, Float(loc.x), Float(loc.y), &ref)
        var role: String?
        var sub: String?
        var frame: CGRect?
        var lights: [CGPoint] = []
        if err == .success, let el = ref, GestureMath.axTypeIDHolds(CFGetTypeID(el) == AXUIElementGetTypeID()) {
            var r: CFTypeRef?
            AXUIElementCopyAttributeValue(el, "AXRole" as CFString, &r)
            role = r as? String
            var s: CFTypeRef?
            AXUIElementCopyAttributeValue(el, "AXSubrole" as CFString, &s)
            sub = s as? String
            frame = quartzFrame(of: el)
            if GestureMath.axChromeSkipsTraffic(role) {
                lights = []
            } else if GestureMath.trafficCacheFresh(now: now, cachedAt: lightsCacheAt),
                      hypot(lightsCacheLoc.x - loc.x, lightsCacheLoc.y - loc.y) < 48
            {
                lights = lightsCached
            } else if let win = ancestorWindow(el), pid(of: win) != TargetProbe.selfPID {
                lights = trafficLights(of: win)
                lightsCacheAt = now
                lightsCacheLoc = loc
                lightsCached = lights
            } else {
                lights = fetchTrafficLights(at: loc)
                lightsCacheAt = now
                lightsCacheLoc = loc
                lightsCached = lights
            }
        } else if GestureMath.trafficCacheFresh(now: now, cachedAt: lightsCacheAt),
                  hypot(lightsCacheLoc.x - loc.x, lightsCacheLoc.y - loc.y) < 48
        {
            lights = lightsCached
        } else {
            lights = fetchTrafficLights(at: loc)
            lightsCacheAt = now
            lightsCacheLoc = loc
            lightsCached = lights
        }
        let p = HitProbe(loc: loc, at: now, role: role, subrole: sub, frame: frame, lights: lights)
        hitCache = p
        return p
    }

    /// AX-Rolle unter dem HUD-Cursor. Button/Link/Feld → Klick, kein Fenster-Drag.
    func hitRole(at point: CGPoint? = nil) -> String? {
        loadProbe(at: mousePoint(point)).role
    }

    func hitLocksClick(at point: CGPoint? = nil, palmScale: CGFloat = 0.12) -> Bool {
        let loc = mousePoint(point)
        let p = loadProbe(at: loc)
        if GestureMath.axLocksClick(p.role) { return true }
        if GestureMath.axSubroleLocksClick(p.subrole) { return true }
        let maxD = GestureMath.trafficMaxDist(palmScale: palmScale)
        return GestureMath.trafficSnap(cursor: loc, lights: p.lights, maxDist: maxD) != nil
    }

    func trafficMagnet(at point: CGPoint?, palmScale: CGFloat) -> Bool {
        let loc = mousePoint(point)
        let p = loadProbe(at: loc)
        let maxD = GestureMath.trafficMaxDist(palmScale: palmScale)
        return GestureMath.trafficSnap(cursor: loc, lights: p.lights, maxDist: maxD) != nil
    }

    func hitSubrole(at point: CGPoint? = nil) -> String? {
        loadProbe(at: mousePoint(point)).subrole
    }

    func hitFrame(at point: CGPoint? = nil) -> CGRect? {
        loadProbe(at: mousePoint(point)).frame
    }

    /// Traffic-Lights der Fenstertitelzeile. Quartz-Mitte jedes Knopfes.
    func trafficLightPoints(at point: CGPoint? = nil) -> [CGPoint] {
        loadProbe(at: mousePoint(point)).lights
    }

    private func trafficLights(of win: AXUIElement) -> [CGPoint] {
        var pts: [CGPoint] = []
        for attr in ["AXCloseButton", "AXMinimizeButton", "AXZoomButton", "AXFullScreenButton"] as [CFString] {
            var btn: CFTypeRef?
            guard AXUIElementCopyAttributeValue(win, attr, &btn) == .success, let btn else { continue }
            guard let button = Self.axElement(btn), let q = quartzFrame(of: button) else { continue }
            pts.append(CGPoint(x: q.midX, y: q.midY))
        }
        return pts
    }

    private func fetchTrafficLights(at point: CGPoint?) -> [CGPoint] {
        guard let win = targetWindow(at: point) else { return [] }
        return trafficLights(of: win)
    }

    /// Magnet + AX-Mitte. Down/Up treffen den Knopf, nicht den Titelbalken daneben.
    func aimPoint(from cursor: CGPoint?, palmScale: CGFloat = 0.12) -> CGPoint {
        let loc = mousePoint(cursor)
        let p = loadProbe(at: loc)
        let maxD = GestureMath.trafficMaxDist(palmScale: palmScale)
        if let snap = GestureMath.trafficSnap(cursor: loc, lights: p.lights, maxDist: maxD) {
            return snap
        }
        return GestureMath.pressTarget(cursor: loc, frame: p.frame)
    }

    @discardableResult
    func click(at point: CGPoint? = nil, flags: CGEventFlags = []) -> ActionResult {
        let now = CACurrentMediaTime()
        guard now - lastClick > 0.12 else { return .fail("Klick-Pause") }
        lastClick = now
        guard allowsInjection else { return .fail("Maus hat Vorrang") }
        if mousePressed {
            return releaseMouse()
        }
        let loc = aimPoint(from: point)
        warpCursor(to: loc)
        guard postMouse(.leftMouseDown, at: loc, flags: flags), postMouse(.leftMouseUp, at: loc, flags: flags) else {
            return .fail("CGEvent Klick")
        }
        lastPosted = loc
        lastPostAt = now
        tapHaptic(.generic)
        return .ok("Klick")
    }

    @discardableResult
    func rightClick(at point: CGPoint? = nil) -> ActionResult {
        let now = CACurrentMediaTime()
        guard now - lastClick > 0.12 else { return .fail("Klick-Pause") }
        lastClick = now
        guard allowsInjection else { return .fail("Maus hat Vorrang") }
        if mousePressed { cancelPress() }
        let loc = aimPoint(from: point)
        warpCursor(to: loc)
        guard postMouse(.rightMouseDown, at: loc, button: .right),
              postMouse(.rightMouseUp, at: loc, button: .right)
        else {
            return .fail("CGEvent Rechtsklick")
        }
        lastPosted = loc
        lastPostAt = now
        tapHaptic(.alignment)
        return .ok("Rechtsklick")
    }

    @discardableResult
    func doubleClick(at point: CGPoint? = nil) -> ActionResult {
        let now = CACurrentMediaTime()
        guard allowsInjection else { return .fail("Maus hat Vorrang") }
        if mousePressed { cancelPress() }
        let loc = aimPoint(from: point)
        warpCursor(to: loc)
        guard postMouse(.leftMouseDown, at: loc, clickState: 1),
              postMouse(.leftMouseUp, at: loc, clickState: 1),
              postMouse(.leftMouseDown, at: loc, clickState: 2),
              postMouse(.leftMouseUp, at: loc, clickState: 2)
        else {
            return .fail("CGEvent Doppelklick")
        }
        lastClick = now
        lastPosted = loc
        lastPostAt = now
        tapHaptic(.generic)
        return .ok("Doppelklick")
    }

    /// Gate-Schluss: Warp auf HUD-Cursor, dann Down. lastPosted allein trifft nach Freeze/Erst-Pinch daneben.
    @discardableResult
    func pressMouse(at point: CGPoint? = nil, flags: CGEventFlags = []) -> ActionResult {
        guard allowsInjection else { return .fail("Maus hat Vorrang") }
        if mousePressed { return .ok("unten") }
        let loc = mousePoint(point)
        warpCursor(to: loc)
        guard postMouse(.leftMouseDown, at: loc, flags: flags) else { return .fail("CGEvent Down") }
        mousePressed = true
        pressPoint = loc
        pressFrame = hitFrame(at: loc)
        let probe = loadProbe(at: loc)
        pressRole = probe.role
        pressSubrole = probe.subrole
        lastClick = CACurrentMediaTime()
        lastPosted = loc
        lastPostAt = lastClick
        tapHaptic(.generic)
        return .ok("Down")
    }

    @discardableResult
    func releaseMouse(snapToPress: Bool = true) -> ActionResult {
        guard mousePressed else { return .ok("oben") }
        let current = lastPosted ?? NSEvent.mouseLocation.screenFlipped
        let nowProbe = loadProbe(at: current)
        if !GestureMath.samePressElement(
            downRole: pressRole,
            downSub: pressSubrole,
            nowRole: nowProbe.role,
            nowSub: nowProbe.subrole
        ) {
            cancelPress()
            return .ok("anderes Control — kein Klick")
        }
        let loc: CGPoint
        if snapToPress, let down = pressPoint {
            let centered = GestureMath.pressTarget(cursor: down, frame: pressFrame)
            loc = GestureMath.clickReleasePoint(down: centered, current: current, wasDrag: false)
        } else {
            loc = current
        }
        mousePressed = false
        pressPoint = nil
        pressFrame = nil
        pressRole = nil
        pressSubrole = nil
        if snapToPress { warpCursor(to: loc) }
        guard postMouse(.leftMouseUp, at: loc) else { return .fail("CGEvent Up") }
        lastPosted = loc
        lastPostAt = CACurrentMediaTime()
        tapHaptic(.generic)
        return .ok("Up")
    }

    func tapHaptic(_ kind: GestureMath.ClickHapticKind = .generic) {
        let pattern: NSHapticFeedbackManager.FeedbackPattern
        switch kind {
        case .none: return
        case .generic: pattern = .generic
        case .alignment: pattern = .alignment
        }
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
    }

    func cancelPress() {
        guard mousePressed else {
            pressPoint = nil
            pressFrame = nil
            pressRole = nil
            pressSubrole = nil
            return
        }
        let restore = lastPosted ?? pressPoint
        mousePressed = false
        pressPoint = nil
        pressFrame = nil
        pressRole = nil
        pressSubrole = nil
        let dump = CGPoint(x: -8000, y: -8000)
        _ = postMouse(.leftMouseUp, at: dump, clamp: false)
        if let restore { warpCursor(to: restore) }
    }

    @discardableResult
    func beginWindowDrag(at quartz: CGPoint? = nil) -> ActionResult {
        guard allowsInjection else { return .fail("Maus hat Vorrang — Steuerung pausiert") }
        let loc = quartz ?? lastPosted ?? NSEvent.mouseLocation.screenFlipped
        if TargetProbe.windowAt(quartz: loc, skipSelf: false)?.pid == TargetProbe.selfPID,
           let w = ownControlPanel()
        {
            return beginOwnWindowDrag(w, at: loc)
        }
        guard let win = targetWindow(at: loc) ?? frontWindow() else {
            if AppInstall.needsCopy {
                return .fail("Läuft nicht aus Programme")
            }
            return .fail("Kein Fenster unter der Hand")
        }
        if pid(of: win) == TargetProbe.selfPID, let w = ownControlPanel() {
            return beginOwnWindowDrag(w, at: loc)
        }
        guard let pos = position(of: win) else { return .fail("AXPosition") }
        dragGen += 1
        dragElement = win
        dragOwnWindow = nil
        dragFailStreak = 0
        // AXPosition ist Quartz, wie der Engine-Cursor. Cocoa-Offset hat Y invertiert —
        // HUD-Umriss (CGWindowList) und gezogenes Fenster liefen auseinander.
        dragGrabOffset = GestureMath.axGrabOffset(cursorQuartz: loc, axPosition: pos)
        dragSize = size(of: win) ?? .zero
        lastPosted = loc
        return .ok("Greifen")
    }

    private func beginOwnWindowDrag(_ w: NSWindow, at loc: CGPoint) -> ActionResult {
        dragGen += 1
        dragElement = nil
        dragOwnWindow = w
        dragFailStreak = 0
        let cocoa = ScreenGeometry.cocoa(fromQuartz: loc)
        dragGrabOffset = CGPoint(x: cocoa.x - w.frame.minX, y: cocoa.y - w.frame.minY)
        dragSize = w.frame.size
        lastPosted = loc
        return .ok("Greifen Helios")
    }

    private func ownControlPanel() -> NSWindow? {
        NSApp.windows.filter {
            $0.isVisible && $0.level == .normal && !$0.ignoresMouseEvents && $0.frame.width > 80
        }.max(by: { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height })
    }

    func updateWindowDrag(to quartz: CGPoint? = nil) {
        guard allowsInjection else {
            endWindowDrag()
            return
        }
        if let w = dragOwnWindow {
            let loc = quartz ?? lastPosted ?? NSEvent.mouseLocation.screenFlipped
            lastPosted = loc
            let cocoa = ScreenGeometry.cocoa(fromQuartz: loc)
            var dest = CGPoint(x: cocoa.x - dragGrabOffset.x, y: cocoa.y - dragGrabOffset.y)
            let vis = (ScreenGeometry.screenContaining(quartz: loc) ?? NSScreen.main)?.visibleFrame ?? .zero
            dest = GestureMath.edgeMagnet(origin: dest, size: w.frame.size, vis: vis)
            w.setFrameOrigin(dest)
            return
        }
        guard let win = dragElement else { return }
        let loc = quartz ?? lastPosted ?? NSEvent.mouseLocation.screenFlipped
        lastPosted = loc
        var dest = GestureMath.axGrabDest(cursorQuartz: loc, offset: dragGrabOffset)
        if let sz = size(of: win) {
            let vis = (ScreenGeometry.screenContaining(quartz: loc) ?? NSScreen.main)?.visibleFrame ?? .zero
            let cocoaDest = ScreenGeometry.cocoa(fromQuartz: dest)
            dest = ScreenGeometry.quartz(fromCocoa: GestureMath.edgeMagnet(origin: cocoaDest, size: sz, vis: vis))
        }
        if axInFlight {
            axPending = dest
            return
        }
        axInFlight = true
        axPending = nil
        let captured = win
        let queue = axQ
        let gen = dragGen
        Task { [weak self] in
            let ok = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
                queue.async {
                    cont.resume(returning: SystemControl.setPositionRaw(captured, dest))
                }
            }
            guard let self, self.dragGen == gen else { return }
            self.axInFlight = false
            if let pending = self.axPending, self.dragElement != nil {
                self.axPending = nil
                self.flushPendingDrag(pending)
            }
            self.noteAxWrite(ok)
        }
    }

    private func flushPendingDrag(_ dest: CGPoint) {
        guard let win = dragElement else { return }
        axInFlight = true
        let captured = win
        let queue = axQ
        let gen = dragGen
        Task { [weak self] in
            let ok = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
                queue.async {
                    cont.resume(returning: SystemControl.setPositionRaw(captured, dest))
                }
            }
            guard let self, self.dragGen == gen else { return }
            self.axInFlight = false
            if let pending = self.axPending, self.dragElement != nil {
                self.axPending = nil
                self.flushPendingDrag(pending)
                return
            }
            self.noteAxWrite(ok)
        }
    }

    /// AX-Timeout ist kein Loslassen. Nachbar unter dem Cursor greifen = Fensterwechsel ohne Bewegung.
    private func noteAxWrite(_ ok: Bool) {
        guard dragElement != nil else { return }
        if ok {
            dragFailStreak = 0
            return
        }
        dragFailStreak += 1
        if dragFailStreak >= 2 {
            if !GestureMath.axDragRebindsNeighbor() {
                endWindowDrag()
                return
            }
            let loc = lastPosted ?? NSEvent.mouseLocation.screenFlipped
            if let win = targetWindow(at: loc) ?? frontWindow() {
                if pid(of: win) == TargetProbe.selfPID, let w = ownControlPanel() {
                    _ = beginOwnWindowDrag(w, at: loc)
                    return
                }
                if let pos = position(of: win) {
                    dragElement = win
                    dragOwnWindow = nil
                    dragFailStreak = 0
                    dragGrabOffset = GestureMath.axGrabOffset(cursorQuartz: loc, axPosition: pos)
                    dragSize = size(of: win) ?? .zero
                    return
                }
            }
            endWindowDrag()
        }
    }

    func endWindowDrag() {
        dragGen += 1
        dragElement = nil
        dragOwnWindow = nil
        dragFailStreak = 0
        dragGrabOffset = .zero
        dragSize = .zero
        axInFlight = false
        axPending = nil
    }

    var isDragging: Bool { dragElement != nil || dragOwnWindow != nil }

    /// HUD-Maske = vorhergesagter AX-Dest, nicht CGWindowList unter dem Cursor.
    func dragQuartzFrame(cursor: CGPoint?) -> CGRect? {
        guard isDragging, dragSize.width > 1, dragSize.height > 1 else { return nil }
        let loc = cursor ?? lastPosted ?? NSEvent.mouseLocation.screenFlipped
        if dragOwnWindow != nil {
            let cocoa = ScreenGeometry.cocoa(fromQuartz: loc)
            let dest = CGPoint(x: cocoa.x - dragGrabOffset.x, y: cocoa.y - dragGrabOffset.y)
            return ScreenGeometry.quartzRect(fromCocoa: CGRect(origin: dest, size: dragSize))
        }
        let dest = GestureMath.axGrabDest(cursorQuartz: loc, offset: dragGrabOffset)
        return CGRect(origin: dest, size: dragSize)
    }

    @discardableResult
    func resizeFocused(scale: CGFloat, anchor: CGPoint? = nil) -> ActionResult {
        let loc = anchor ?? lastPosted ?? NSEvent.mouseLocation.screenFlipped
        let s = max(0.82, min(1.22, scale))
        if let win = targetWindow(at: loc), pid(of: win) == TargetProbe.selfPID {
            return resizeOwnWindow(scale: s, anchor: anchor)
        }
        if TargetProbe.windowAt(quartz: loc, skipSelf: false)?.pid == TargetProbe.selfPID {
            return resizeOwnWindow(scale: s, anchor: anchor)
        }
        guard let win = targetWindow(at: loc), let size = size(of: win), let pos = position(of: win) else {
            return .fail("Kein Fenster zum Skalieren")
        }
        let nw = max(280, size.width * s)
        let nh = max(180, size.height * s)
        // pos ist Quartz. Cocoa-Anchor mischt Y — Maske springt beim Skalieren.
        let axAnchor = anchor ?? CGPoint(x: pos.x + size.width / 2, y: pos.y + size.height / 2)
        let origin = GestureMath.resizeOrigin(pos: pos, size: size, scale: s, anchor: axAnchor)
        let posOk = setPosition(win, origin)
        let sizeOk = setSize(win, CGSize(width: nw, height: nh))
        guard posOk || sizeOk else {
            return .fail("AX Größe")
        }
        return .ok(String(format: "×%.2f", s))
    }

    /// SwiftUI-Window setzt AXSize oft nicht. Eigenes ControlPanel über NSWindow.
    private func resizeOwnWindow(scale: CGFloat, anchor: CGPoint?) -> ActionResult {
        guard let w = ownControlPanel() else {
            return .fail("Kein Helios-Fenster")
        }
        let f = w.frame
        let nw = max(280, f.width * scale)
        let nh = max(180, f.height * scale)
        let cocoaAnchor = anchor.map { ScreenGeometry.cocoa(fromQuartz: $0) }
            ?? CGPoint(x: f.midX, y: f.midY)
        let origin = GestureMath.resizeOrigin(pos: f.origin, size: f.size, scale: scale, anchor: cocoaAnchor)
        w.setFrame(CGRect(origin: origin, size: CGSize(width: nw, height: nh)), display: true, animate: false)
        return .ok(String(format: "Helios ×%.2f", scale))
    }

    @discardableResult
    func minimizeFocused() -> ActionResult {
        let loc = lastPosted ?? NSEvent.mouseLocation.screenFlipped
        if TargetProbe.windowAt(quartz: loc, skipSelf: false)?.pid == TargetProbe.selfPID,
           let w = ownControlPanel()
        {
            w.miniaturize(nil)
            return .ok("Helios Mini")
        }
        guard let win = targetWindow() else { return .fail("Kein Fenster") }
        return pressButton(win, "AXMinimizeButton" as CFString)
    }

    @discardableResult
    func closeFocused() -> ActionResult {
        let loc = lastPosted ?? NSEvent.mouseLocation.screenFlipped
        if TargetProbe.windowAt(quartz: loc, skipSelf: false)?.pid == TargetProbe.selfPID,
           let w = ownControlPanel()
        {
            w.performClose(nil)
            return .ok("Helios Close")
        }
        guard let win = targetWindow() else { return .fail("Kein Fenster") }
        return pressButton(win, "AXCloseButton" as CFString)
    }

    @discardableResult
    func snapFocused(_ edge: SnapEdge) -> ActionResult {
        let loc = lastPosted ?? NSEvent.mouseLocation.screenFlipped
        let screen = ScreenGeometry.screenContaining(quartz: loc) ?? NSScreen.main
        guard let screen else { return .fail("Kein Bildschirm") }
        let visCocoa = screen.visibleFrame
        let vis = ScreenGeometry.quartzRect(fromCocoa: visCocoa)
        let origin: CGPoint
        let size: CGSize
        switch edge {
        case .left:
            origin = vis.origin
            size = CGSize(width: vis.width / 2, height: vis.height)
        case .right:
            origin = CGPoint(x: vis.midX, y: vis.minY)
            size = CGSize(width: vis.width / 2, height: vis.height)
        case .fill:
            origin = vis.origin
            size = vis.size
        }
        if TargetProbe.windowAt(quartz: loc, skipSelf: false)?.pid == TargetProbe.selfPID,
           let w = ownControlPanel()
        {
            let cocoa: CGRect
            switch edge {
            case .left:
                cocoa = CGRect(origin: visCocoa.origin, size: CGSize(width: visCocoa.width / 2, height: visCocoa.height))
            case .right:
                cocoa = CGRect(
                    origin: CGPoint(x: visCocoa.midX, y: visCocoa.origin.y),
                    size: CGSize(width: visCocoa.width / 2, height: visCocoa.height)
                )
            case .fill:
                cocoa = visCocoa
            }
            w.setFrame(cocoa, display: true, animate: false)
            switch edge {
            case .left: return .ok("Links Helios")
            case .right: return .ok("Rechts Helios")
            case .fill: return .ok("Füllen Helios")
            }
        }
        guard let win = targetWindow() else { return .fail("Kein Fenster") }
        let posOk = setPosition(win, origin)
        let sizeOk = setSize(win, size)
        guard posOk || sizeOk else { return .fail("AX Größe") }
        switch edge {
        case .left: return .ok("Links")
        case .right: return .ok("Rechts")
        case .fill: return .ok("Füllen")
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
        let src = CGEventSource(stateID: .privateState)
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
    private func postMouse(
        _ type: CGEventType,
        at point: CGPoint,
        clamp: Bool = true,
        button: CGMouseButton = .left,
        clickState: Int64 = 1,
        flags: CGEventFlags = []
    ) -> Bool {
        let p = clamp ? ScreenGeometry.clampQuartz(point) : point
        let src = CGEventSource(stateID: .privateState)
        guard let e = CGEvent(
            mouseEventSource: src,
            mouseType: type,
            mouseCursorPosition: p,
            mouseButton: button
        ) else { return false }
        e.setIntegerValueField(.mouseEventClickState, value: clickState)
        if flags.rawValue != 0 { e.flags = flags }
        e.post(tap: .cghidEventTap)
        return true
    }

    private func mousePoint(_ point: CGPoint?) -> CGPoint {
        ScreenGeometry.clampQuartz(point ?? lastPosted ?? NSEvent.mouseLocation.screenFlipped)
    }

    /// Down/Klick ohne Warp landet auf lastPosted oder der Hardware-Maus, nicht auf dem HUD-Cursor.
    private func warpCursor(to loc: CGPoint) {
        if let posted = lastPosted, hypot(loc.x - posted.x, loc.y - posted.y) < 0.5 {
            return
        }
        _ = postMouse(.mouseMoved, at: loc)
        lastPosted = loc
        lastPostAt = CACurrentMediaTime()
    }

    private func targetWindow(at point: CGPoint? = nil) -> AXUIElement? {
        let loc = point ?? lastPosted ?? NSEvent.mouseLocation.screenFlipped
        if let win = window(at: loc), pid(of: win) != TargetProbe.selfPID {
            return win
        }
        // Overlay oder eigenes ControlPanel: layer-0 inklusive Helios, HUD (layer ≠ 0) raus.
        if let t = TargetProbe.windowAt(quartz: loc, skipSelf: false) {
            return axWindow(pid: t.pid, bounds: t.quartzBounds)
        }
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
            let windows = any.compactMap { Self.axElement($0) }
            // AXPosition ist Quartz (oben links), wie CGWindowList-bounds.
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
            return Self.axElement(focused)
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
            current = Self.axElement(parent)
        }
        return current
    }

    private func ax(_ el: AXUIElement) -> AXUIElement {
        AXUIElementSetMessagingTimeout(el, 0.25)
        return el
    }

    /// Swift 6: `as? AXUIElement` auf CFType immer true — TypeID prüfen.
    nonisolated private static func axElement(_ ref: CFTypeRef?) -> AXUIElement? {
        guard let ref, CFGetTypeID(ref) == AXUIElementGetTypeID() else { return nil }
        return unsafeBitCast(ref, to: AXUIElement.self)
    }

    nonisolated private static func axValue(_ ref: CFTypeRef?) -> AXValue? {
        guard let ref, CFGetTypeID(ref) == AXValueGetTypeID() else { return nil }
        return unsafeBitCast(ref, to: AXValue.self)
    }

    private func position(of el: AXUIElement) -> CGPoint? {
        var v: CFTypeRef?
        guard AXUIElementCopyAttributeValue(el, "AXPosition" as CFString, &v) == .success else { return nil }
        guard let value = Self.axValue(v) else { return nil }
        var p = CGPoint.zero
        AXValueGetValue(value, .cgPoint, &p)
        return p
    }

    private func size(of el: AXUIElement) -> CGSize? {
        var v: CFTypeRef?
        guard AXUIElementCopyAttributeValue(el, "AXSize" as CFString, &v) == .success else { return nil }
        guard let value = Self.axValue(v) else { return nil }
        var s = CGSize.zero
        AXValueGetValue(value, .cgSize, &s)
        return s
    }

    private func quartzFrame(of el: AXUIElement) -> CGRect? {
        guard let pos = position(of: el), let size = size(of: el) else { return nil }
        return CGRect(origin: pos, size: size)
    }

    @discardableResult
    private func setPosition(_ el: AXUIElement, _ p: CGPoint) -> Bool {
        Self.setPositionRaw(el, p)
    }

    nonisolated private static func setPositionRaw(_ el: AXUIElement, _ p: CGPoint) -> Bool {
        var point = p
        guard let val = AXValueCreate(.cgPoint, &point) else { return false }
        guard AXUIElementSetAttributeValue(el, "AXPosition" as CFString, val) == .success else { return false }
        var v: CFTypeRef?
        guard AXUIElementCopyAttributeValue(el, "AXPosition" as CFString, &v) == .success else { return true }
        guard let value = axValue(v) else { return true }
        var got = CGPoint.zero
        AXValueGetValue(value, .cgPoint, &got)
        return GestureMath.axWriteTook(want: p, got: got)
    }

    @discardableResult
    private func setSize(_ el: AXUIElement, _ s: CGSize) -> Bool {
        Self.setSizeRaw(el, s)
    }

    nonisolated private static func setSizeRaw(_ el: AXUIElement, _ s: CGSize) -> Bool {
        var size = s
        guard let val = AXValueCreate(.cgSize, &size) else { return false }
        guard AXUIElementSetAttributeValue(el, "AXSize" as CFString, val) == .success else { return false }
        var v: CFTypeRef?
        guard AXUIElementCopyAttributeValue(el, "AXSize" as CFString, &v) == .success else { return true }
        guard let value = axValue(v) else { return true }
        var got = CGSize.zero
        AXValueGetValue(value, .cgSize, &got)
        return GestureMath.axWriteTook(want: s, got: got)
    }

    @discardableResult
    private func pressButton(_ win: AXUIElement, _ attr: CFString) -> ActionResult {
        var btn: CFTypeRef?
        let copy = AXUIElementCopyAttributeValue(win, attr, &btn)
        guard copy == .success, let button = Self.axElement(btn) else { return .fail("Kein Knopf \(attr)") }
        let act = AXUIElementPerformAction(button, "AXPress" as CFString)
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

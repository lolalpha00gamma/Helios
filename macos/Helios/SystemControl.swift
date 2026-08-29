import ApplicationServices
import AppKit
import CoreGraphics
import Foundation

@MainActor
final class SystemControl {
    private var dragElement: AXUIElement?
    private var dragOriginMouse: CGPoint = .zero
    private var dragOriginWindow: CGPoint = .zero
    private var lastClick: TimeInterval = 0

    func moveCursor(to point: CGPoint) {
        let e = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: clamped(point),
            mouseButton: .left
        )
        e?.post(tap: .cghidEventTap)
    }

    func click() {
        let now = CACurrentMediaTime()
        guard now - lastClick > 0.28 else { return }
        lastClick = now
        let loc = NSEvent.mouseLocation.screenFlipped
        postMouse(.leftMouseDown, at: loc)
        postMouse(.leftMouseUp, at: loc)
    }

    func beginWindowDrag() {
        let loc = NSEvent.mouseLocation.screenFlipped
        guard let win = window(at: loc), let pos = position(of: win) else { return }
        dragElement = win
        dragOriginMouse = loc
        dragOriginWindow = pos
    }

    func updateWindowDrag() {
        guard let win = dragElement else { return }
        let loc = NSEvent.mouseLocation.screenFlipped
        let dx = loc.x - dragOriginMouse.x
        let dy = loc.y - dragOriginMouse.y
        setPosition(win, CGPoint(x: dragOriginWindow.x + dx, y: dragOriginWindow.y + dy))
    }

    func endWindowDrag() {
        dragElement = nil
    }

    var isDragging: Bool { dragElement != nil }

    func resizeFocused(scale: CGFloat) {
        guard let win = focusedWindow() ?? window(at: NSEvent.mouseLocation.screenFlipped) else { return }
        guard let size = size(of: win), let pos = position(of: win) else { return }
        let s = max(0.85, min(1.18, scale))
        let nw = max(280, size.width * s)
        let nh = max(180, size.height * s)
        let nx = pos.x - (nw - size.width) / 2
        let ny = pos.y - (nh - size.height) / 2
        setPosition(win, CGPoint(x: nx, y: ny))
        setSize(win, CGSize(width: nw, height: nh))
    }

    func zoomFocused() {
        guard let win = focusedWindow() ?? window(at: NSEvent.mouseLocation.screenFlipped) else { return }
        pressButton(win, kAXZoomButtonAttribute as CFString)
    }

    func minimizeFocused() {
        guard let win = focusedWindow() ?? window(at: NSEvent.mouseLocation.screenFlipped) else { return }
        pressButton(win, kAXMinimizeButtonAttribute as CFString)
    }

    func switchApp(forward: Bool) {
        let src = CGEventSource(stateID: .hidSystemState)
        let flags: CGEventFlags = forward
            ? .maskCommand
            : [.maskCommand, .maskShift]
        let down = CGEvent(keyboardEventSource: src, virtualKey: 0x30, keyDown: true)
        down?.flags = flags
        down?.post(tap: .cghidEventTap)
        let up = CGEvent(keyboardEventSource: src, virtualKey: 0x30, keyDown: false)
        up?.flags = flags
        up?.post(tap: .cghidEventTap)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            let cmdUp = CGEvent(keyboardEventSource: src, virtualKey: 0x37, keyDown: false)
            cmdUp?.post(tap: .cghidEventTap)
        }
    }

    private func postMouse(_ type: CGEventType, at point: CGPoint) {
        let e = CGEvent(
            mouseEventSource: nil,
            mouseType: type,
            mouseCursorPosition: clamped(point),
            mouseButton: .left
        )
        e?.post(tap: .cghidEventTap)
    }

    private func clamped(_ p: CGPoint) -> CGPoint {
        guard let screen = NSScreen.main else { return p }
        let f = screen.frame
        return CGPoint(
            x: min(max(p.x, f.minX + 2), f.maxX - 2),
            y: min(max(p.y, f.minY + 2), f.maxY - 2)
        )
    }

    private func window(at point: CGPoint) -> AXUIElement? {
        let sys = AXUIElementCreateSystemWide()
        var ref: AXUIElement?
        let err = AXUIElementCopyElementAtPosition(sys, Float(point.x), Float(point.y), &ref)
        guard err == .success, let start = ref else { return nil }
        return ancestorWindow(start)
    }

    private func focusedWindow() -> AXUIElement? {
        let sys = AXUIElementCreateSystemWide()
        var app: CFTypeRef?
        guard AXUIElementCopyAttributeValue(sys, kAXFocusedApplicationAttribute as CFString, &app) == .success,
              let appEl = app
        else { return nil }
        var win: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appEl as! AXUIElement, kAXFocusedWindowAttribute as CFString, &win) == .success else {
            return nil
        }
        return (win as! AXUIElement)
    }

    private func ancestorWindow(_ el: AXUIElement) -> AXUIElement? {
        var current: AXUIElement? = el
        for _ in 0..<12 {
            guard let c = current else { return nil }
            var role: CFTypeRef?
            AXUIElementCopyAttributeValue(c, kAXRoleAttribute as CFString, &role)
            if let r = role as? String, r == (kAXWindowRole as String) {
                return c
            }
            var parent: CFTypeRef?
            let err = AXUIElementCopyAttributeValue(c, kAXParentAttribute as CFString, &parent)
            if err != .success { return c }
            current = parent.map { $0 as! AXUIElement }
        }
        return current
    }

    private func position(of el: AXUIElement) -> CGPoint? {
        var v: CFTypeRef?
        guard AXUIElementCopyAttributeValue(el, kAXPositionAttribute as CFString, &v) == .success else { return nil }
        var p = CGPoint.zero
        AXValueGetValue(v as! AXValue, .cgPoint, &p)
        return p
    }

    private func size(of el: AXUIElement) -> CGSize? {
        var v: CFTypeRef?
        guard AXUIElementCopyAttributeValue(el, kAXSizeAttribute as CFString, &v) == .success else { return nil }
        var s = CGSize.zero
        AXValueGetValue(v as! AXValue, .cgSize, &s)
        return s
    }

    private func setPosition(_ el: AXUIElement, _ p: CGPoint) {
        var point = p
        if let val = AXValueCreate(.cgPoint, &point) {
            AXUIElementSetAttributeValue(el, kAXPositionAttribute as CFString, val)
        }
    }

    private func setSize(_ el: AXUIElement, _ s: CGSize) {
        var size = s
        if let val = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(el, kAXSizeAttribute as CFString, val)
        }
    }

    private func pressButton(_ win: AXUIElement, _ attr: CFString) {
        var btn: CFTypeRef?
        guard AXUIElementCopyAttributeValue(win, attr, &btn) == .success else { return }
        AXUIElementPerformAction(btn as! AXUIElement, kAXPressAction as CFString)
    }
}

extension NSPoint {
    var screenFlipped: CGPoint {
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(self, $0.frame, false) }) ?? NSScreen.main else {
            return CGPoint(x: x, y: y)
        }
        let y = screen.frame.maxY - self.y
        return CGPoint(x: x, y: y)
    }
}

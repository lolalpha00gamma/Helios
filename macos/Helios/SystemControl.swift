import ApplicationServices
import AppKit
import CoreGraphics
import Foundation
import ImageIO
import ScreenCaptureKit
import UniformTypeIdentifiers

enum SnapEdge {
    case left, right, fill
}

@MainActor
final class SystemControl {
    private var dragElement: AXUIElement?
    private var dragOriginMouse: CGPoint = .zero
    private var dragOriginWindow: CGPoint = .zero
    private var lastClick: TimeInterval = 0
    private var lastKey: TimeInterval = 0

    func moveCursor(to point: CGPoint) {
        let e = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: ScreenGeometry.clampQuartz(point),
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
        pressButton(win, "AXZoomButton" as CFString)
    }

    func minimizeFocused() {
        guard let win = focusedWindow() ?? window(at: NSEvent.mouseLocation.screenFlipped) else { return }
        pressButton(win, "AXMinimizeButton" as CFString)
    }

    func closeFocused() {
        guard let win = focusedWindow() ?? window(at: NSEvent.mouseLocation.screenFlipped) else { return }
        pressButton(win, "AXCloseButton" as CFString)
    }

    func snapFocused(_ edge: SnapEdge) {
        guard let win = focusedWindow() ?? window(at: NSEvent.mouseLocation.screenFlipped) else { return }
        let loc = NSEvent.mouseLocation.screenFlipped
        let screen = ScreenGeometry.screenContaining(quartz: loc) ?? NSScreen.main
        guard let screen else { return }
        let vis = ScreenGeometry.quartzRect(fromCocoa: screen.visibleFrame)
        switch edge {
        case .left:
            setPosition(win, vis.origin)
            setSize(win, CGSize(width: vis.width / 2, height: vis.height))
        case .right:
            setPosition(win, CGPoint(x: vis.midX, y: vis.minY))
            setSize(win, CGSize(width: vis.width / 2, height: vis.height))
        case .fill:
            setPosition(win, vis.origin)
            setSize(win, vis.size)
        }
    }

    func throwAway(finder: Bool) {
        if finder, trashFinderSelection() {
            return
        }
        closeFocused()
    }

    func screenshotFocused(windowID: CGWindowID, bounds: CGRect) {
        Task.detached {
            await WindowCapture.run(windowID: windowID, bounds: bounds)
        }
    }

    func missionControl() {
        chord(key: 0x7E, flags: .maskControl)
    }

    func desktopReveal() {
        chord(key: 0x7D, flags: .maskControl)
    }

    func unhideFront() {
        NSWorkspace.shared.frontmostApplication?.unhide()
        NSWorkspace.shared.frontmostApplication?.activate()
    }

    func switchApp(forward: Bool) {
        let flags: CGEventFlags = forward ? .maskCommand : [.maskCommand, .maskShift]
        chord(key: 0x30, flags: flags)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            let src = CGEventSource(stateID: .hidSystemState)
            let cmdUp = CGEvent(keyboardEventSource: src, virtualKey: 0x37, keyDown: false)
            cmdUp?.post(tap: .cghidEventTap)
        }
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

    private func chord(key: CGKeyCode, flags: CGEventFlags) {
        let now = CACurrentMediaTime()
        guard now - lastKey > 0.45 else { return }
        lastKey = now
        let src = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: true)
        down?.flags = flags
        down?.post(tap: .cghidEventTap)
        let up = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: false)
        up?.flags = flags
        up?.post(tap: .cghidEventTap)
    }

    private func postMouse(_ type: CGEventType, at point: CGPoint) {
        let e = CGEvent(
            mouseEventSource: nil,
            mouseType: type,
            mouseCursorPosition: ScreenGeometry.clampQuartz(point),
            mouseButton: .left
        )
        e?.post(tap: .cghidEventTap)
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
        guard AXUIElementCopyAttributeValue(sys, "AXFocusedApplication" as CFString, &app) == .success,
              let appEl = app
        else { return nil }
        var win: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appEl as! AXUIElement, "AXFocusedWindow" as CFString, &win) == .success else {
            return nil
        }
        return (win as! AXUIElement)
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

    private func setPosition(_ el: AXUIElement, _ p: CGPoint) {
        var point = p
        if let val = AXValueCreate(.cgPoint, &point) {
            AXUIElementSetAttributeValue(el, "AXPosition" as CFString, val)
        }
    }

    private func setSize(_ el: AXUIElement, _ s: CGSize) {
        var size = s
        if let val = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(el, "AXSize" as CFString, val)
        }
    }

    private func pressButton(_ win: AXUIElement, _ attr: CFString) {
        var btn: CFTypeRef?
        guard AXUIElementCopyAttributeValue(win, attr, &btn) == .success else { return }
        AXUIElementPerformAction(btn as! AXUIElement, "AXPress" as CFString)
    }
}

enum WindowCapture {
    static func run(windowID: CGWindowID, bounds: CGRect) async {
        let dir = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyyMMdd-HHmmss"
        let url = dir.appendingPathComponent("Helios-\(fmt.string(from: Date())).png")
        if windowID != 0 {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            proc.arguments = ["-l\(windowID)", "-x", url.path]
            do {
                try proc.run()
                proc.waitUntilExit()
                if proc.terminationStatus == 0, FileManager.default.fileExists(atPath: url.path) {
                    await MainActor.run { NSWorkspace.shared.activateFileViewerSelecting([url]) }
                    return
                }
            } catch {}
        }
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            let filter: SCContentFilter
            if let window = content.windows.first(where: { $0.windowID == windowID }) {
                filter = SCContentFilter(desktopIndependentWindow: window)
            } else if let display = content.displays.first {
                filter = SCContentFilter(display: display, excludingWindows: [])
            } else {
                return
            }
            let cfg = SCStreamConfiguration()
            cfg.showsCursor = false
            let scale: CGFloat = 2
            cfg.width = max(2, Int(bounds.width * scale))
            cfg.height = max(2, Int(bounds.height * scale))
            let img = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: cfg)
            guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
                return
            }
            CGImageDestinationAddImage(dest, img, nil)
            CGImageDestinationFinalize(dest)
            await MainActor.run { NSWorkspace.shared.activateFileViewerSelecting([url]) }
        } catch {}
    }
}

extension NSPoint {
    var screenFlipped: CGPoint {
        ScreenGeometry.quartz(fromCocoa: self)
    }
}

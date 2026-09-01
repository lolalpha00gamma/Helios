import AppKit
import CoreGraphics

/// `NSScreen.screens` fragt den Window-Server und legt bei jedem Zugriff ein neues
/// Array an. In der 60-Hz-Schleife wird die Geometrie hunderte Male pro Sekunde
/// gebraucht, ändert sich aber nur beim Umstecken eines Monitors.
private final class ScreenCache: @unchecked Sendable {
    static let shared = ScreenCache()

    private let lock = NSLock()
    private var cachedFrames: [CGRect]?
    private var cachedPrimaryMaxY: CGFloat?
    private var cachedUnion: CGRect?

    private init() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.invalidate()
        }
    }

    func invalidate() {
        lock.lock()
        cachedFrames = nil
        cachedPrimaryMaxY = nil
        cachedUnion = nil
        lock.unlock()
    }

    var frames: [CGRect] {
        lock.lock()
        defer { lock.unlock() }
        if let cachedFrames { return cachedFrames }
        let f = NSScreen.screens.map(\.frame)
        cachedFrames = f
        return f
    }

    var primaryMaxY: CGFloat {
        lock.lock()
        defer { lock.unlock() }
        if let cachedPrimaryMaxY { return cachedPrimaryMaxY }
        let screens = NSScreen.screens
        let v = screens.first {
            abs($0.frame.minX) < 0.5 && abs($0.frame.minY) < 0.5
        }?.frame.maxY ?? NSScreen.main?.frame.maxY ?? 0
        cachedPrimaryMaxY = v
        return v
    }

    var union: CGRect {
        lock.lock()
        defer { lock.unlock() }
        if let cachedUnion { return cachedUnion }
        let u = NSScreen.screens.map(\.frame).reduce(CGRect.null) { $0.union($1) }
        cachedUnion = u
        return u
    }
}

enum ScreenGeometry {
    static var cocoaUnion: CGRect { ScreenCache.shared.union }

    /// Cocoa-Y des oberen Rands am Hauptbildschirm (Ursprung 0,0). Nicht die Union.
    static var primaryCocoaMaxY: CGFloat { ScreenCache.shared.primaryMaxY }

    /// Beim Wechsel der Bildschirmanordnung von außen aufzurufen.
    static func invalidateScreenCache() { ScreenCache.shared.invalidate() }

    static func quartz(fromCocoa p: CGPoint) -> CGPoint {
        CoordMath.quartz(fromCocoa: p, primaryMaxY: primaryCocoaMaxY)
    }

    static func cocoa(fromQuartz p: CGPoint) -> CGPoint {
        CoordMath.cocoa(fromQuartz: p, primaryMaxY: primaryCocoaMaxY)
    }

    static func quartzRect(fromCocoa r: CGRect) -> CGRect {
        CoordMath.quartzRect(fromCocoa: r, primaryMaxY: primaryCocoaMaxY)
    }

    static func cocoaRect(fromQuartz r: CGRect) -> CGRect {
        CoordMath.cocoaRect(fromQuartz: r, primaryMaxY: primaryCocoaMaxY)
    }

    static func local(quartz: CGPoint, on screen: CGRect) -> CGPoint {
        let c = cocoa(fromQuartz: quartz)
        return CGPoint(x: c.x - screen.minX, y: screen.maxY - c.y)
    }

    static func localRect(quartz: CGRect, on screen: CGRect) -> CGRect {
        let topLeft = local(quartz: CGPoint(x: quartz.minX, y: quartz.maxY), on: screen)
        return CGRect(x: topLeft.x, y: topLeft.y, width: quartz.width, height: quartz.height)
    }

    static func contains(quartz: CGPoint, screen: CGRect, pad: CGFloat = 24) -> Bool {
        let p = local(quartz: quartz, on: screen)
        return p.x >= -pad && p.y >= -pad && p.x <= screen.width + pad && p.y <= screen.height + pad
    }

    static func intersects(quartz: CGRect, screen: CGRect) -> Bool {
        let r = localRect(quartz: quartz, on: screen)
        return r.intersects(CGRect(origin: .zero, size: screen.size))
    }

    static func trashLocal(on screen: CGRect) -> CGRect {
        let s: CGFloat = 138
        return CGRect(x: screen.width - s - 24, y: screen.height - s - 24, width: s, height: s)
    }

    static func trashLocal(screen: NSScreen) -> CGRect {
        let frame = screen.frame
        let vis = screen.visibleFrame
        let s: CGFloat = 138
        let localVis = CGRect(
            x: vis.minX - frame.minX,
            y: frame.maxY - vis.maxY,
            width: vis.width,
            height: vis.height
        )
        return CGRect(
            x: localVis.maxX - s - 18,
            y: localVis.maxY - s - 18,
            width: s,
            height: s
        )
    }

    static func screen(matchingCocoa frame: CGRect) -> NSScreen? {
        NSScreen.screens.first {
            abs($0.frame.minX - frame.minX) < 2 && abs($0.frame.minY - frame.minY) < 2
        }
    }

    /// Relativ: Handbewegung → Cursor. Hand heben = neu ansetzen (Trackpad).
    static func stepCursor(from quartz: CGPoint, dPalm: CGPoint, gain: CGFloat) -> CGPoint {
        let u = cocoaUnion
        let g = max(0.4, gain)
        var p = quartz
        p.x += dPalm.x * u.width * g
        p.y -= dPalm.y * u.height * g
        return clampQuartz(p)
    }

    static func clampQuartz(_ p: CGPoint) -> CGPoint {
        let screens = ScreenCache.shared.frames
        if screens.contains(where: { contains(quartz: p, screen: $0, pad: 0) }) {
            return p
        }
        var best = p
        var bestD = CGFloat.greatestFiniteMagnitude
        for frame in screens {
            let r = quartzRect(fromCocoa: frame)
            let q = CGPoint(
                x: min(max(p.x, r.minX + 2), r.maxX - 2),
                y: min(max(p.y, r.minY + 2), r.maxY - 2)
            )
            let d = hypot(q.x - p.x, q.y - p.y)
            if d < bestD {
                bestD = d
                best = q
            }
        }
        return best
    }

    static func screenContaining(quartz: CGPoint) -> NSScreen? {
        NSScreen.screens.first { contains(quartz: quartz, screen: $0.frame, pad: 4) } ?? NSScreen.main
    }

    /// CGWindowList liefert bereits Quartz (Ursprung oben links am Hauptbildschirm).
    static func fromWindowList(_ r: CGRect) -> CGRect { r }

    static func displayID(of screen: NSScreen) -> CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return (screen.deviceDescription[key] as? CGDirectDisplayID) ?? 0
    }
}

import AppKit
import CoreGraphics

enum ScreenGeometry {
    nonisolated(unsafe) private static var cachedUnion: CGRect = .null
    nonisolated(unsafe) private static var cachedMaxY: CGFloat = 0
    nonisolated(unsafe) private static var dirty = true
    nonisolated(unsafe) private static var observing = false
    nonisolated(unsafe) private static var observer: NSObjectProtocol?
    private static let lock = NSLock()

    private static func watch() {
        lock.lock()
        let already = observing
        observing = true
        lock.unlock()
        guard !already else { return }
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { _ in
            lock.lock()
            dirty = true
            lock.unlock()
        }
    }

    private static func refresh() {
        watch()
        lock.lock()
        if !dirty, cachedMaxY > 0 {
            lock.unlock()
            return
        }
        lock.unlock()
        let screens = NSScreen.screens
        let union = screens.map(\.frame).reduce(CGRect.null) { $0.union($1) }
        let maxY = screens.first {
            abs($0.frame.minX) < 0.5 && abs($0.frame.minY) < 0.5
        }?.frame.maxY ?? NSScreen.main?.frame.maxY ?? 0
        lock.lock()
        cachedUnion = union
        cachedMaxY = maxY
        dirty = false
        lock.unlock()
    }

    static var cocoaUnion: CGRect {
        refresh()
        return cachedUnion
    }

    /// Quartz-Höhe des Hauptbildschirms. Predict-Cap × Höhe, nicht hart 48 pt.
    static var mainHeight: CGFloat {
        refresh()
        if let s = NSScreen.main { return s.frame.height }
        return max(1, cachedUnion.height)
    }

    /// Cocoa-Y des oberen Rands am Hauptbildschirm (Ursprung 0,0). Nicht die Union.
    static var primaryCocoaMaxY: CGFloat {
        refresh()
        return cachedMaxY
    }

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
        CoordMath.localPoint(quartz: quartz, screen: screen, primaryMaxY: primaryCocoaMaxY)
    }

    static func localRect(quartz: CGRect, on screen: CGRect) -> CGRect {
        CoordMath.localRect(quartz: quartz, screen: screen, primaryMaxY: primaryCocoaMaxY)
    }

    static func contains(quartz: CGPoint, screen: CGRect, pad: CGFloat = 24) -> Bool {
        let p = local(quartz: quartz, on: screen)
        return p.x >= -pad && p.y >= -pad && p.x <= screen.width + pad && p.y <= screen.height + pad
    }

    static func intersects(quartz: CGRect, screen: CGRect) -> Bool {
        let r = localRect(quartz: quartz, on: screen)
        return r.intersects(CGRect(origin: .zero, size: screen.size))
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
    /// Aktueller Schirm, nicht Union — Union enthält die Bezel-Lücke (5K↔Sidecar tot).
    /// Nichtlinear: Feinzielen in der Mitte, Schwung am Rand. Rand dämpft.
    static func stepCursor(from quartz: CGPoint, dPalm: CGPoint, gain: CGFloat) -> CGPoint {
        let host = screenContaining(quartz: quartz)
        let hostFrame = host.map { quartzRect(fromCocoa: $0.frame) }
            ?? quartzRect(fromCocoa: cocoaUnion)
        let local = CGPoint(x: quartz.x - hostFrame.minX, y: quartz.y - hostFrame.minY)
        let resist = GestureMath.edgeResistance(
            localX: local.x,
            localY: local.y,
            width: hostFrame.width,
            height: hostFrame.height
        )
        let g = max(0.4, gain) * resist
        let mag = hypot(dPalm.x, dPalm.y)
        let accel = CoordMath.pointerAccelScale(magnitude: mag)
        var p = quartz
        p.x += dPalm.x * hostFrame.width * g * accel
        p.y -= dPalm.y * hostFrame.height * g * accel
        let onHost = host.map { contains(quartz: p, screen: $0.frame, pad: 0) } ?? false
        if onHost {
            if let host {
                let vis = quartzRect(fromCocoa: host.visibleFrame)
                if GestureMath.stageManagerOffspace(proposed: p, visible: vis) {
                    return GestureMath.stageManagerClamp(proposed: p, visible: vis)
                }
            }
            return p
        }
        let other = NSScreen.screens.first { contains(quartz: p, screen: $0.frame, pad: 0) }
        if let other {
            let of = quartzRect(fromCocoa: other.frame)
            if GestureMath.bezelHopAllows(proposed: p, otherFrame: of) {
                return clampQuartz(p)
            }
            return CGPoint(
                x: min(max(p.x, hostFrame.minX + 2), hostFrame.maxX - 2),
                y: min(max(p.y, hostFrame.minY + 2), hostFrame.maxY - 2)
            )
        }
        if GestureMath.displayGapWarp(fromOnScreen: true, proposedOnScreen: false) {
            return CGPoint(
                x: min(max(p.x, hostFrame.minX + 2), hostFrame.maxX - 2),
                y: min(max(p.y, hostFrame.minY + 2), hostFrame.maxY - 2)
            )
        }
        return clampQuartz(p)
    }

    static func clampQuartz(_ p: CGPoint) -> CGPoint {
        let screens = NSScreen.screens
        if screens.contains(where: { contains(quartz: p, screen: $0.frame, pad: 0) }) {
            return p
        }
        var best = p
        var bestD = CGFloat.greatestFiniteMagnitude
        for s in screens {
            let r = quartzRect(fromCocoa: s.frame)
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

    /// Scale des Schirms unter dem Punkt. 5K ≠ Sidecar 1×.
    static func backingScale(quartz: CGPoint) -> CGFloat {
        screenContaining(quartz: quartz)?.backingScaleFactor
            ?? NSScreen.main?.backingScaleFactor
            ?? 1
    }

    /// CGWindowList liefert bereits Quartz (Ursprung oben links am Hauptbildschirm).
    static func fromWindowList(_ r: CGRect) -> CGRect { r }

    static func displayID(of screen: NSScreen) -> CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return (screen.deviceDescription[key] as? CGDirectDisplayID) ?? 0
    }

    static var mainDisplayID: CGDirectDisplayID {
        NSScreen.main.map { displayID(of: $0) } ?? 0
    }

    static func isBuiltIn(_ screen: NSScreen) -> Bool {
        let n = screen.localizedName.lowercased()
        return n.contains("built-in") || n.contains("color lcd")
            || n.contains("liquid retina") || n.contains("macbook")
    }

    /// Beamer / externer Schirm: größte Fläche, die nicht Built-in ist. Spiegelung = ein Schirm.
    static var projectionDisplayID: CGDirectDisplayID {
        let screens = NSScreen.screens
        let extern = screens.filter { !isBuiltIn($0) }
        let pick = (extern.max { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height })
            ?? screens.max { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }
            ?? NSScreen.main
        return pick.map { displayID(of: $0) } ?? mainDisplayID
    }

    static func displayName(_ id: CGDirectDisplayID) -> String {
        NSScreen.screens.first { displayID(of: $0) == id }?.localizedName ?? "Bildschirm"
    }

    /// Cursor in Union-Norm [0,1], Y Quartz (oben = 0).
    static func unitInUnion(quartz: CGPoint) -> CGPoint {
        let r = quartzRect(fromCocoa: cocoaUnion)
        guard r.width > 1, r.height > 1 else { return CGPoint(x: 0.5, y: 0.5) }
        return CGPoint(
            x: (quartz.x - r.minX) / r.width,
            y: (quartz.y - r.minY) / r.height
        )
    }
}

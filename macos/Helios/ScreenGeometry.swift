import AppKit
import CoreGraphics

enum ScreenGeometry {
    static var cocoaUnion: CGRect {
        NSScreen.screens.map(\.frame).reduce(.null) { $0.union($1) }
    }

    /// Cocoa-Y des oberen Rands am Hauptbildschirm (Ursprung 0,0). Nicht die Union.
    static var primaryCocoaMaxY: CGFloat {
        NSScreen.screens.first {
            abs($0.frame.minX) < 0.5 && abs($0.frame.minY) < 0.5
        }?.frame.maxY ?? NSScreen.main?.frame.maxY ?? 0
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
        let c = cocoa(fromQuartz: quartz)
        return CGPoint(x: c.x - screen.minX, y: screen.maxY - c.y)
    }

    static func localRect(quartz: CGRect, on screen: CGRect) -> CGRect {
        let topLeft = local(quartz: CoordMath.quartzTopLeft(quartz), on: screen)
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
        let screens = quartzScreens
        let union = quartzRect(fromCocoa: cocoaUnion)
        let span = GestureMath.relativeStepSpan(cursor: quartz, screens: screens, union: union)
        let g = max(0.4, gain)
        var p = quartz
        p.x += dPalm.x * span.width * g
        p.y -= dPalm.y * span.height * g
        return clampQuartz(p)
    }

    static func clampQuartz(_ p: CGPoint) -> CGPoint {
        let screens = quartzScreens
        if let hit = GestureMath.destEdgeNearest(p, screens: screens) {
            if hit.dist <= 0 { return p }
        }
        var best = p
        var bestD = CGFloat.greatestFiniteMagnitude
        for r in screens {
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
        let rects = quartzScreens
        guard let hit = GestureMath.destEdgeNearest(quartz, screens: rects)?.screen else {
            return NSScreen.main
        }
        return NSScreen.screens.first {
            let r = quartzBounds(of: $0)
            return abs(r.minX - hit.minX) < 1
                && abs(r.minY - hit.minY) < 1
                && abs(r.width - hit.width) < 1
                && abs(r.height - hit.height) < 1
        } ?? NSScreen.main
    }

    /// CGWindowList liefert bereits Quartz (Ursprung oben links am Hauptbildschirm).
    static func fromWindowList(_ r: CGRect) -> CGRect { r }

    static func displayID(of screen: NSScreen) -> CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return (screen.deviceDescription[key] as? CGDirectDisplayID) ?? 0
    }

    /// Hardware-Bounds in Quartz. CGDisplayBounds ist schon Y-down (Ursprung oben links).
    /// `quartzRect(fromCocoa:)` darauf = doppelter Flip, 5K landet unter dem Laptop.
    /// NSScreen.frame Cocoa→Quartz erzeugt oft 16 px Seam-Overlap, das CGDisplayBounds nicht hat.
    static func quartzBounds(of screen: NSScreen) -> CGRect {
        let id = displayID(of: screen)
        if id != 0 {
            return CGDisplayBounds(id)
        }
        return quartzRect(fromCocoa: screen.frame)
    }

    static var quartzScreens: [CGRect] {
        NSScreen.screens.map { quartzBounds(of: $0) }
    }

    /// Sichtbare Fläche in Quartz, abgeleitet von CGDisplayBounds + Menüleiste/Dock.
    /// fromCocoa(visibleFrame) war eine zweite Seam-Welt neben destEdge.
    static func visQuartz(of screen: NSScreen) -> CGRect {
        let q = quartzBounds(of: screen)
        let frame = screen.frame
        let vis = screen.visibleFrame
        guard frame.width > 1, frame.height > 1 else { return q }
        let top = max(0, frame.maxY - vis.maxY)
        let bottom = max(0, vis.minY - frame.minY)
        let left = max(0, vis.minX - frame.minX)
        let right = max(0, frame.maxX - vis.maxX)
        return CGRect(
            x: q.minX + left,
            y: q.minY + top,
            width: max(1, q.width - left - right),
            height: max(1, q.height - top - bottom)
        )
    }
}

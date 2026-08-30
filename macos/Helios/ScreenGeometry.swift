import AppKit
import CoreGraphics

enum ScreenGeometry {
    static var cocoaUnion: CGRect {
        NSScreen.screens.map(\.frame).reduce(.null) { $0.union($1) }
    }

    static var globalMaxY: CGFloat {
        NSScreen.screens.map(\.frame.maxY).max() ?? 0
    }

    static func quartz(fromCocoa p: CGPoint) -> CGPoint {
        CGPoint(x: p.x, y: globalMaxY - p.y)
    }

    static func cocoa(fromQuartz p: CGPoint) -> CGPoint {
        CGPoint(x: p.x, y: globalMaxY - p.y)
    }

    static func quartzRect(fromCocoa r: CGRect) -> CGRect {
        CGRect(x: r.origin.x, y: globalMaxY - r.origin.y - r.height, width: r.width, height: r.height)
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

    static func mapNormalizedToQuartz(_ p: CGPoint) -> CGPoint {
        let u = cocoaUnion
        guard u.width > 1, u.height > 1 else {
            return CGPoint(x: p.x * 1920, y: (1 - p.y) * 1080)
        }
        let cocoa = CGPoint(x: u.minX + p.x * u.width, y: u.minY + p.y * u.height)
        return quartz(fromCocoa: cocoa)
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

    static func displayID(of screen: NSScreen) -> CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return (screen.deviceDescription[key] as? CGDirectDisplayID) ?? 0
    }
}

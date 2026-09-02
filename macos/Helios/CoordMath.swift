import CoreGraphics
import Foundation

/// Reine Cocoa↔Quartz-Rechnung. Quartz-Ursprung = oben links am **Hauptbildschirm**.
enum CoordMath {
    static func quartz(fromCocoa p: CGPoint, primaryMaxY: CGFloat) -> CGPoint {
        CGPoint(x: p.x, y: primaryMaxY - p.y)
    }

    static func cocoa(fromQuartz p: CGPoint, primaryMaxY: CGFloat) -> CGPoint {
        CGPoint(x: p.x, y: primaryMaxY - p.y)
    }

    static func quartzRect(fromCocoa r: CGRect, primaryMaxY: CGFloat) -> CGRect {
        CGRect(
            x: r.origin.x,
            y: primaryMaxY - r.origin.y - r.height,
            width: r.width,
            height: r.height
        )
    }

    static func cocoaRect(fromQuartz r: CGRect, primaryMaxY: CGFloat) -> CGRect {
        quartzRect(fromCocoa: r, primaryMaxY: primaryMaxY)
    }

    /// Overlay-Koordinaten: Ursprung oben links am Schirm, y nach unten.
    /// Quartz-Fenster: origin = oben links (minY), maxY = untere Kante.
    static func localPoint(quartz: CGPoint, screen: CGRect, primaryMaxY: CGFloat) -> CGPoint {
        let c = cocoa(fromQuartz: quartz, primaryMaxY: primaryMaxY)
        return CGPoint(x: c.x - screen.minX, y: screen.maxY - c.y)
    }

    static func localRect(quartz: CGRect, screen: CGRect, primaryMaxY: CGFloat) -> CGRect {
        let topLeft = localPoint(
            quartz: CGPoint(x: quartz.minX, y: quartz.minY),
            screen: screen,
            primaryMaxY: primaryMaxY
        )
        return CGRect(x: topLeft.x, y: topLeft.y, width: quartz.width, height: quartz.height)
    }
}

enum FlingKind: Equatable {
    case none, throwUp, minimize, dockLeft, dockRight
}

/// Schwellen, die Engine und Tests teilen. Fling/Wischen in **Handbreiten**.
enum GestureMath {
    static let flingWindow: TimeInterval = 0.12
    static let flingMinSpeed: CGFloat = 2.6
    static let flingMinDist: CGFloat = 0.55
    /// Mini-Zucken um die Bildmitte, nicht „Werfen aus der Mitte verboten“.
    static let flingCenter: CGFloat = 0.22
    static let palmDead: CGFloat = 0.012
    static let palmHighpass: CGFloat = 0.08
    static let deadMan: TimeInterval = 8.0
    static let killGrace: TimeInterval = 0.14
    static let swipeOpenNeed = 3
    static let thumbsHold: TimeInterval = 0.70

    /// Letzte `flingWindow` Sekunden in Handbreiten, nicht first→last über das Halten.
    /// `x/y` sind Vision-[0,1]; `aspect` = w/h macht x isotrop.
    static func flingFromTrail(
        _ trail: [(t: TimeInterval, x: CGFloat, y: CGFloat)],
        palmWidth: CGFloat,
        aspect: CGFloat = 16 / 9,
        centerDead: Bool = true
    ) -> FlingKind {
        guard let last = trail.last else { return .none }
        let window = trail.filter { last.t - $0.t <= flingWindow }
        guard let first = window.first, last.t > first.t + 0.04 else { return .none }
        let dt = max(0.04, last.t - first.t)
        let unit = max(0.04, palmWidth)
        let dx = (last.x - first.x) * aspect / unit
        let dy = (last.y - first.y) / unit
        let dist = hypot(dx, dy)
        let speed = dist / CGFloat(dt)
        if centerDead {
            let fromCenter = hypot(last.x - 0.5, last.y - 0.5)
            if fromCenter < flingCenter, dist < flingMinDist * 1.7 {
                return .none
            }
        }
        return classifyFling(dx: dx, dy: dy, speed: speed, dist: dist)
    }

    static func classifyFling(dx: CGFloat, dy: CGFloat, speed: CGFloat, dist: CGFloat) -> FlingKind {
        guard speed > flingMinSpeed, dist > flingMinDist else { return .none }
        if abs(dy) >= abs(dx) {
            if dy > 0.55 { return .throwUp }
            if dy < -0.35 { return .minimize }
            return .none
        }
        if dx < -0.50 { return .dockLeft }
        if dx > 0.50 { return .dockRight }
        return .none
    }
}

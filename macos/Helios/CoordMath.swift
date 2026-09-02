import CoreGraphics
import Foundation

/// Reine Cocoa↔Quartz-Rechnung. Quartz-Ursprung = oben links am **Hauptbildschirm**.
enum CoordMath {
    /// Traffic-Lights / Titelleiste. Pinch darunter ist Text, kein Fenstergriff.
    static let titleBarHeight: CGFloat = 36

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

    /// AXPosition ist Cocoa (unten links). Titelleiste = oberer Streifen.
    static func titleBar(windowPos: CGPoint, windowSize: CGSize, height: CGFloat = titleBarHeight) -> CGRect {
        CGRect(
            x: windowPos.x,
            y: windowPos.y + windowSize.height - height,
            width: windowSize.width,
            height: height
        )
    }

    static func cocoaInTitleBar(
        point: CGPoint,
        windowPos: CGPoint,
        windowSize: CGSize,
        height: CGFloat = titleBarHeight
    ) -> Bool {
        titleBar(windowPos: windowPos, windowSize: windowSize, height: height).contains(point)
    }

    /// Micro-Dwell-Magnet: sitzt `from` in `radius` von `toward`, rastet ein.
    static func magnetSnap(from: CGPoint, toward: CGPoint, radius: CGFloat = 4) -> CGPoint? {
        let d = hypot(from.x - toward.x, from.y - toward.y)
        guard d > 0.5, d <= radius else { return nil }
        return toward
    }

    /// Clutch-Nachlauf: Injektion bleibt tot, bis `endedAt + grace`.
    static func clutchInjects(now: Double, clutchEndedAt: Double, grace: Double = 0.15) -> Bool {
        now >= clutchEndedAt + grace
    }
}

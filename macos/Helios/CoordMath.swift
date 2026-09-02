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
}

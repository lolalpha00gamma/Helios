import CoreGraphics
import Foundation

/// Standalone: `swift macos/HeliosTests/CoordTests.swift`
/// Muss mit CoordMath.swift übereinstimmen.

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
        let origin = cocoa(fromQuartz: CGPoint(x: r.minX, y: r.maxY), primaryMaxY: primaryMaxY)
        return CGRect(x: origin.x, y: origin.y - r.height, width: r.width, height: r.height)
    }
}

var fails = 0

func eq(_ a: CGFloat, _ b: CGFloat, _ msg: String) {
    if abs(a - b) > 0.001 {
        fputs("FAIL \(msg): \(a) != \(b)\n", stderr)
        fails += 1
    }
}

func pointEq(_ a: CGPoint, _ b: CGPoint, _ msg: String) {
    eq(a.x, b.x, msg + " x")
    eq(a.y, b.y, msg + " y")
}

let primaryH: CGFloat = 1080

// Cocoa-Ursprung unten links am Hauptbildschirm → Quartz oben links.
pointEq(
    CoordMath.quartz(fromCocoa: CGPoint(x: 10, y: 1080), primaryMaxY: primaryH),
    CGPoint(x: 10, y: 0),
    "oben Hauptbildschirm"
)
pointEq(
    CoordMath.quartz(fromCocoa: CGPoint(x: 10, y: 0), primaryMaxY: primaryH),
    CGPoint(x: 10, y: 1080),
    "unten Hauptbildschirm"
)

// Monitor über dem Hauptschirm: Cocoa-y > primaryH → Quartz-y negativ.
pointEq(
    CoordMath.quartz(fromCocoa: CGPoint(x: 100, y: 1080 + 400), primaryMaxY: primaryH),
    CGPoint(x: 100, y: -400),
    "Schirm oben"
)

// Roundtrip.
let p = CGPoint(x: -200, y: 500)
let q = CoordMath.quartz(fromCocoa: p, primaryMaxY: primaryH)
pointEq(CoordMath.cocoa(fromQuartz: q, primaryMaxY: primaryH), p, "Roundtrip Punkt")

let cocoaWin = CGRect(x: 100, y: 200, width: 800, height: 600)
let quartzWin = CoordMath.quartzRect(fromCocoa: cocoaWin, primaryMaxY: primaryH)
eq(quartzWin.origin.x, 100, "rect x")
eq(quartzWin.origin.y, primaryH - 200 - 600, "rect y top-left quartz")
eq(quartzWin.height, 600, "rect h")
let back = CoordMath.cocoaRect(fromQuartz: quartzWin, primaryMaxY: primaryH)
eq(back.origin.x, cocoaWin.origin.x, "rect roundtrip x")
eq(back.origin.y, cocoaWin.origin.y, "rect roundtrip y")
eq(back.width, cocoaWin.width, "rect roundtrip w")
eq(back.height, cocoaWin.height, "rect roundtrip h")

// AXPosition ist Cocoa. Quartz-Bounds (CGWindow) → Cocoa muss AX treffen.
let cgWindow = CGRect(x: 50, y: 80, width: 400, height: 300) // quartz
let ax = CoordMath.cocoaRect(fromQuartz: cgWindow, primaryMaxY: primaryH)
eq(ax.minX, 50, "AX x")
eq(ax.height, 300, "AX h")
eq(ax.maxY, primaryH - 80, "AX top in cocoa")

if fails > 0 {
    fputs("\(fails) Tests fehlgeschlagen\n", stderr)
    exit(1)
}
print("CoordTests OK")

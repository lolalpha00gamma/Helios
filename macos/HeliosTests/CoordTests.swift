import CoreGraphics
import Foundation

/// `swiftc macos/Helios/CoordMath.swift macos/HeliosTests/CoordTests.swift -o /tmp/coordtests && /tmp/coordtests`

@main
enum CoordTests {
    static var fails = 0

    static func eq(_ a: CGFloat, _ b: CGFloat, _ msg: String) {
        if abs(a - b) > 0.001 {
            fputs("FAIL \(msg): \(a) != \(b)\n", stderr)
            fails += 1
        }
    }

    static func pointEq(_ a: CGPoint, _ b: CGPoint, _ msg: String) {
        eq(a.x, b.x, msg + " x")
        eq(a.y, b.y, msg + " y")
    }

    static func ok(_ cond: Bool, _ msg: String) {
        if !cond {
            fputs("FAIL \(msg)\n", stderr)
            fails += 1
        }
    }

    static func main() {
        let primaryH: CGFloat = 1080
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
        pointEq(
            CoordMath.quartz(fromCocoa: CGPoint(x: 100, y: 1080 + 400), primaryMaxY: primaryH),
            CGPoint(x: 100, y: -400),
            "Schirm oben"
        )
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

        let cgWindow = CGRect(x: 50, y: 80, width: 400, height: 300)
        let ax = CoordMath.cocoaRect(fromQuartz: cgWindow, primaryMaxY: primaryH)
        eq(ax.minX, 50, "AX x")
        eq(ax.height, 300, "AX h")
        eq(ax.maxY, primaryH - 80, "AX top in cocoa")

        // AXUIElementCopyElementAtPosition und AXPosition sind Cocoa, nicht Quartz.
        let quartzCursor = CGPoint(x: 200, y: 100)
        let axHit = CoordMath.cocoa(fromQuartz: quartzCursor, primaryMaxY: primaryH)
        eq(axHit.x, 200, "AX hit-test x")
        eq(axHit.y, primaryH - 100, "AX hit-test y (nicht Quartz)")

        let pos = CGPoint(x: 100, y: 200)
        let size = CGSize(width: 800, height: 600)
        let bar = CoordMath.titleBar(windowPos: pos, windowSize: size)
        eq(bar.height, 36, "Titelleiste 36 pt")
        eq(bar.origin.y, 200 + 600 - 36, "Titelleiste oben (Cocoa)")
        ok(CoordMath.cocoaInTitleBar(point: CGPoint(x: 140, y: 200 + 600 - 10), windowPos: pos, windowSize: size), "Traffic-Lights-Zone")
        ok(!CoordMath.cocoaInTitleBar(point: CGPoint(x: 140, y: 200 + 300), windowPos: pos, windowSize: size), "Textkörper nicht Titelleiste")
        ok(!CoordMath.cocoaInTitleBar(point: CGPoint(x: 50, y: 200 + 600 - 10), windowPos: pos, windowSize: size), "links neben dem Fenster")

        let magnetHit = CoordMath.magnetSnap(
            from: CGPoint(x: 100, y: 100),
            toward: CGPoint(x: 103, y: 101),
            radius: 4
        )
        ok(magnetHit == CGPoint(x: 103, y: 101), "Magnet rastet in 4 px")
        ok(CoordMath.magnetSnap(from: CGPoint(x: 0, y: 0), toward: CGPoint(x: 10, y: 0), radius: 4) == nil, "Magnet außerhalb")
        ok(CoordMath.magnetSnap(from: CGPoint(x: 5, y: 5), toward: CGPoint(x: 5, y: 5), radius: 4) == nil, "Magnet nicht auf dem Punkt selbst")

        ok(!CoordMath.clutchInjects(now: 1.10, clutchEndedAt: 1.00, grace: 0.15), "Clutch-Grace hält 150 ms")
        ok(CoordMath.clutchInjects(now: 1.16, clutchEndedAt: 1.00, grace: 0.15), "Clutch-Grace vorbei")

        if fails > 0 {
            fputs("\(fails) Tests fehlgeschlagen\n", stderr)
            exit(1)
        }
        print("CoordTests OK")
    }
}

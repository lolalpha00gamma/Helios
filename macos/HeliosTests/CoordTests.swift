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

        // Overlay: Quartz-minY ist die obere Kante, nicht maxY.
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let win = CGRect(x: 100, y: 80, width: 400, height: 300)
        let local = CoordMath.localRect(quartz: win, screen: screen, primaryMaxY: primaryH)
        eq(local.minX, 100, "localRect x")
        eq(local.minY, 80, "localRect oben = quartz.minY, nicht maxY")
        eq(local.height, 300, "localRect h")
        eq(local.width, 400, "localRect w")
        let wrong = CoordMath.localPoint(quartz: CGPoint(x: win.minX, y: win.maxY), screen: screen, primaryMaxY: primaryH)
        eq(wrong.y, 80 + 300, "maxY ist die Unterkante")
        if abs(local.minY - wrong.y) < 1 {
            fputs("FAIL localRect darf nicht maxY als oben nehmen\n", stderr)
            fails += 1
        }

        // Zweiter Schirm rechts: Overlay-Ursprung = screen.minX / screen.maxY.
        let screen2 = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let win2 = CGRect(x: 2000, y: 80, width: 400, height: 300)
        let local2 = CoordMath.localRect(quartz: win2, screen: screen2, primaryMaxY: primaryH)
        eq(local2.minX, 80, "localRect 2. Schirm x")
        eq(local2.minY, 80, "localRect 2. Schirm oben = quartz.minY")
        eq(local2.height, 300, "localRect 2. Schirm h")

        let holdThenFlick: [(t: TimeInterval, x: CGFloat, y: CGFloat)] = [
            (0.00, 0.50, 0.40),
            (0.40, 0.50, 0.41),
            (0.80, 0.50, 0.42),
            (0.92, 0.50, 0.52),
            (1.00, 0.50, 0.70)
        ]
        let kind = GestureMath.flingFromTrail(holdThenFlick, palmWidth: 0.12, aspect: 16 / 9, centerDead: false)
        if kind != .throwUp {
            fputs("FAIL Werfen aus letztem 120-ms-Fenster, nicht Mittel übers Halten: \(kind)\n", stderr)
            fails += 1
        }
        let whole = GestureMath.classifyFling(dx: 0, dy: 0.30 / 0.12, speed: (0.30 / 0.12) / 1.0, dist: 0.30 / 0.12)
        if whole != .none {
            fputs("FAIL dasselbe über 1 s Halten ist zu langsam\n", stderr)
            fails += 1
        }
        let twitch: [(t: TimeInterval, x: CGFloat, y: CGFloat)] = [
            (0.00, 0.50, 0.50),
            (0.08, 0.52, 0.51)
        ]
        if GestureMath.flingFromTrail(twitch, palmWidth: 0.12) != .none {
            fputs("FAIL Mini-Zucken in der Mitte dockt nicht\n", stderr)
            fails += 1
        }
        if GestureMath.deadMan < 6 {
            fputs("FAIL Dead-Man mindestens 6 s\n", stderr)
            fails += 1
        }
        if GestureMath.swipeOpenNeed < 3 {
            fputs("FAIL Wischen braucht offene Hand, nicht Peace\n", stderr)
            fails += 1
        }
        if GestureMath.palmDead < 0.01 {
            fputs("FAIL Palm-Deadzone gegen Atem\n", stderr)
            fails += 1
        }
        if GestureMath.killGrace > 0.18 {
            fputs("FAIL Not-Aus-Grace nicht 0,28 s\n", stderr)
            fails += 1
        }

        if fails > 0 {
            fputs("\(fails) Tests fehlgeschlagen\n", stderr)
            exit(1)
        }
        print("CoordTests OK")
    }
}

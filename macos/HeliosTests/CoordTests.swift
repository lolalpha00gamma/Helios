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

        let warpHit = CoordMath.warpGuarded(from: CGPoint(x: 10, y: 10), to: CGPoint(x: 200, y: 10))
        pointEq(warpHit, CGPoint(x: 10, y: 10), "Warp > 80 px verwerfen")
        let warpOk = CoordMath.warpGuarded(from: CGPoint(x: 10, y: 10), to: CGPoint(x: 50, y: 10))
        pointEq(warpOk, CGPoint(x: 50, y: 10), "Warp unter 80 px durch")

        let nachlauf = CoordMath.clutchChip(reason: "Nachlauf", remain: 1)
        ok(nachlauf.label == "NACHLAUF", "Nachlauf-Chip nicht TASTATUR")
        eq(nachlauf.ms, 150, "Nachlauf 150 ms")
        let kbd = CoordMath.clutchChip(reason: "Tastatur", remain: 0.5)
        ok(kbd.label == "TASTATUR", "Tastatur-Chip")
        eq(kbd.ms, 200, "Tastatur 400 ms · 0,5")
        let maus = CoordMath.clutchChip(reason: "Maus", remain: 1)
        ok(maus.label == "MAUS", "Maus-Chip")
        eq(maus.ms, 850, "Maus 850 ms")

        ok(CoordMath.peaceHoldSeconds(sinceScroll: 0.20) == nil, "Peace tot während Scroll")
        ok(CoordMath.peaceHoldSeconds(sinceScroll: 0.80) == 1.20, "Peace 1,2 s nach Scroll")
        ok(CoordMath.peaceHoldSeconds(sinceScroll: 2.00) == 0.90, "Peace 0,9 s idle")

        ok(CoordMath.scrollCoastTicks(last: 10, elapsed: 0) == 10, "Coast t=0 voll")
        ok(CoordMath.scrollCoastTicks(last: 10, elapsed: 0.09) == 5, "Coast halb")
        ok(CoordMath.scrollCoastTicks(last: 10, elapsed: 0.18) == 0, "Coast tot bei window")
        ok(CoordMath.scrollCoastTicks(last: 10, elapsed: 0.30) == 0, "Coast tot danach")
        ok(CoordMath.scrollCoastTicks(last: 0, elapsed: 0.01) == 0, "Coast ohne Ticks")
        ok(CoordMath.scrollCoastTicks(last: -8, elapsed: 0.09) == -4, "Coast vorzeichen")

        ok(
            CoordMath.magnetCacheHit(
                cachedAt: 1.0,
                cachedAtPoint: .zero,
                now: 1.02,
                point: CGPoint(x: 3, y: 0)
            ),
            "Magnet-Cache 20 ms 3 px"
        )
        ok(
            !CoordMath.magnetCacheHit(
                cachedAt: 1.0,
                cachedAtPoint: .zero,
                now: 1.05,
                point: .zero
            ),
            "Magnet-Cache tot nach 50 ms"
        )
        ok(
            !CoordMath.magnetCacheHit(
                cachedAt: 1.0,
                cachedAtPoint: .zero,
                now: 1.01,
                point: CGPoint(x: 20, y: 0)
            ),
            "Magnet-Cache tot bei 20 px"
        )

        if fails > 0 {
            fputs("\(fails) Tests fehlgeschlagen\n", stderr)
            exit(1)
        }
        print("CoordTests OK")
    }
}

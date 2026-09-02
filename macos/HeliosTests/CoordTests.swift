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
        ok(!CoordMath.peaceScrollMoves(moved: 0.05), "Peace-Jitter 0,05 kein Scroll")
        ok(!CoordMath.peaceScrollMoves(moved: 0.11), "Peace unter Deadzone kein Scroll")
        ok(CoordMath.peaceScrollMoves(moved: 0.12), "Peace 0,12 Handbreiten = Scroll")
        ok(CoordMath.peaceScrollMoves(moved: 0.40), "Peace-Zug bleibt Scroll")

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

        ok(CoordMath.peaceCooldown(succeeded: true) == 4, "Aufnahme-Pause 4 s nach Treffer")
        ok(CoordMath.peaceCooldown(succeeded: false) == 0.80, "Aufnahme-Pause 0,8 s nach Fehlschlag")
        ok(CoordMath.clickLockHolds(moved: 0.10, role: "AXSlider"), "Slider-Lock hält Zitter")
        ok(!CoordMath.clickLockHolds(moved: 0.40, role: "AXSlider"), "Slider-Lock löst bei Zug")
        ok(CoordMath.clickLockHolds(moved: 0.10, role: "AXButton"), "Knopf-Lock hält Zitter")
        ok(CoordMath.clickLockHolds(moved: 0.18, role: "AXCloseButton"), "Schließen-Lock hält Titlebar-Zitter")
        ok(CoordMath.clickLockHolds(moved: 0.10, role: "AXCheckBox"), "Checkbox-Lock")
        ok(CoordMath.clickLockHolds(moved: 0.10, role: "AXRadioButton"), "Radio-Lock")
        ok(!CoordMath.clickLockHolds(moved: 0.40, role: "AXCloseButton"), "Schließen-Lock löst bei Zug")
        ok(!CoordMath.clickLockHolds(moved: 0.10, role: "AXTextArea"), "Text ist kein Click-Lock")
        ok(CoordMath.magnetLabel("AXCloseButton") == "Schließen", "Magnet-Chip Schließen")
        ok(CoordMath.magnetLabel("AXSlider") == "Slider", "Magnet-Chip Slider")
        ok(CoordMath.magnetLabel("AXMinimizeButton") == "Mini", "Magnet-Chip Mini")
        ok(CoordMath.magnetLabel(nil) == "Magnet", "Magnet ohne Rolle")
        ok(CoordMath.stillInText(role: "AXTextArea"), "TextArea bleibt Auswahl")
        ok(CoordMath.stillInText(role: "AXWebArea"), "WebArea bleibt Auswahl")
        ok(!CoordMath.stillInText(role: "AXButton"), "Button bricht Text-Drag")
        ok(!CoordMath.stillInText(role: "AXToolbar"), "Toolbar bricht Text-Drag")
        ok(CoordMath.stillInText(role: nil), "unbekannte Rolle hält Auswahl")
        let vert = CoordMath.scrollDelta(dx: 0.02, dy: 0.20)
        ok(vert.horizontal == 0 && vert.vertical == 0.20, "Scroll default vertikal")
        let hor = CoordMath.scrollDelta(dx: 0.30, dy: 0.05)
        ok(hor.horizontal == 0.30 && hor.vertical == 0, "Scroll klar waagerecht")
        let tiny = CoordMath.scrollDelta(dx: 0.05, dy: 0.04)
        ok(tiny.horizontal == 0, "Mini-dx kein Horizontal-Scroll")
        ok(CoordMath.naturalScrollEnabled(true), "Natural default-an")
        ok(!CoordMath.naturalScrollEnabled(false), "Natural aus")
        ok(CoordMath.naturalScrollEnabled(nil), "Natural ohne Key an")
        ok(CoordMath.signedScrollTicks(10, profileInverts: true, natural: true) == -10, "Safari Natural invertiert")
        ok(CoordMath.signedScrollTicks(10, profileInverts: true, natural: false) == 10, "Safari Natural-aus nicht doppelt")
        ok(CoordMath.signedScrollTicks(10, profileInverts: false, natural: true) == 10, "Finder Natural roh")
        ok(CoordMath.signedScrollTicks(10, profileInverts: false, natural: false) == -10, "Finder Natural-aus")
        ok(CoordMath.signedScrollTicks(10, profileInverts: true, natural: true, horizontal: true) == 10, "Safari wheel2 ohne Profil-XOR")
        ok(CoordMath.signedScrollTicks(10, profileInverts: true, natural: false, horizontal: true) == -10, "Safari wheel2 nur Natural")
        ok(CoordMath.signedScrollTicks(10, profileInverts: false, natural: true, horizontal: true, invertHorizontal: true) == -10, "Terminal wheel2 XOR")
        ok(CoordMath.signedScrollTicks(10, profileInverts: true, natural: true, horizontal: true, invertHorizontal: false) == 10, "Safari wheel2 bleibt")
        ok(CoordMath.signedScrollTicks(10, profileInverts: true, natural: true, invertHorizontal: true) == -10, "vertikal ignoriert invertHorizontal")
        ok(CoordMath.modifiersBlockInjection(1 << 17), "Shift blockt")
        ok(CoordMath.modifiersBlockInjection(1 << 20), "Cmd blockt")
        ok(!CoordMath.modifiersBlockInjection(1 << 16), "CapsLock blockt nicht")
        ok(!CoordMath.modifiersBlockInjection(0), "keine Modifier")
        ok(CoordMath.keyClutchSeconds(isRepeat: false, modifiersDown: false) == 0.40, "Tasten-Clutch 400 ms")
        ok(CoordMath.keyClutchSeconds(isRepeat: true, modifiersDown: false) == 0.55, "Repeat 550 ms")
        ok(CoordMath.keyClutchSeconds(isRepeat: false, modifiersDown: true) == 0.55, "Modifier 550 ms")
        ok(CoordMath.textSelectReady(held: 0.08), "Text-Dwell 80 ms")
        ok(!CoordMath.textSelectReady(held: 0.04), "unter 80 ms kein HID-Down")
        ok(CoordMath.ibeamRole("AXTextArea"), "TextArea I-Beam")
        ok(CoordMath.ibeamRole("AXWebArea"), "WebArea I-Beam")
        ok(!CoordMath.ibeamRole("AXButton"), "Button kein I-Beam")
        ok(!CoordMath.ibeamRole(nil), "ohne Rolle kein I-Beam")
        ok(CoordMath.shiftClick(otherFist: true), "zweite Faust = Shift-Klick")
        ok(!CoordMath.shiftClick(otherFist: false), "ohne Faust kein Shift")
        let cmd = CoordMath.clickFlags(otherFist: false, otherPeace: true, otherPoint: false)
        ok(cmd.command && !cmd.shift && !cmd.option, "Peace = Cmd-Klick")
        let opt = CoordMath.clickFlags(otherFist: false, otherPeace: false, otherPoint: true)
        ok(opt.option && !opt.command && !opt.shift, "Point = Opt-Klick")
        let fistWins = CoordMath.clickFlags(otherFist: true, otherPeace: true, otherPoint: true)
        ok(fistWins.shift && !fistWins.command && !fistWins.option, "Faust gewinnt vor Peace/Point")
        ok(CoordMath.clickName(shift: false, command: true, option: false) == "Cmd-Klick", "Cmd-Name")
        ok(CoordMath.clickName(shift: false, command: false, option: true) == "Opt-Klick", "Opt-Name")
        ok(CoordMath.clickName(shift: true, command: false, option: false) == "Shift-Klick", "Shift-Name")
        ok(CoordMath.clickName(shift: false, command: false, option: false) == "Klick", "plain Klick")
        let win = CGRect(x: 10, y: 20, width: 800, height: 600)
        let captured = CoordMath.peaceCaptureBounds(
            window: win,
            cursor: CGPoint(x: 100, y: 100),
            screen: CGRect(x: 0, y: 0, width: 1920, height: 1080)
        )
        ok(captured == win, "Peace nimmt Fenster unter Cursor")
        let fallback = CoordMath.peaceCaptureBounds(
            window: nil,
            cursor: CGPoint(x: 100, y: 100),
            screen: CGRect(x: 0, y: 0, width: 1920, height: 1080)
        )
        eq(fallback.width, 720, "Peace-Fallback Region Breite")
        ok(fallback.contains(CGPoint(x: 100, y: 100)), "Peace-Fallback um den Cursor")
        eq(CoordMath.peaceCooldownFraction(leftover: 0.80, span: 0.80), 1, "Fail-Ring startet voll")
        eq(CoordMath.peaceCooldownFraction(leftover: 0.80, span: 4), 0.20, "Treffer 0,8/4 = 0,20")
        eq(CGFloat(CoordMath.peaceCooldownSeconds(leftover: 0.80)), 0.80, "HUD 0,8 s nicht ×4")
        let region = CoordMath.peaceRegion(
            around: CGPoint(x: 100, y: 100),
            screen: CGRect(x: 0, y: 0, width: 1920, height: 1080)
        )
        eq(region.width, 720, "Peace-Region Breite")
        eq(region.height, 450, "Peace-Region Höhe")
        ok(region.contains(CGPoint(x: 100, y: 100)), "Peace-Region um den Cursor")
        let edge = CoordMath.peaceRegion(
            around: CGPoint(x: 10, y: 10),
            screen: CGRect(x: 0, y: 0, width: 1920, height: 1080)
        )
        eq(edge.minX, 0, "Peace-Region klebt am Schirmrand")
        eq(edge.minY, 0, "Peace-Region klebt oben")

        if fails > 0 {
            fputs("\(fails) Tests fehlgeschlagen\n", stderr)
            exit(1)
        }
        print("CoordTests OK")
    }
}

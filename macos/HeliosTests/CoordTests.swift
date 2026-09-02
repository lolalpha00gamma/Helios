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

        if GestureMath.flingFromTrail(holdThenFlick, palmWidth: 0.12, aspect: 16 / 9, centerDead: false, afterDrag: true) != .throwUp {
            fputs("FAIL echter Ruck nach Zug bleibt Werfen\n", stderr)
            fails += 1
        }
        let slowDrop: [(t: TimeInterval, x: CGFloat, y: CGFloat)] = [
            (0.00, 0.40, 0.62),
            (0.20, 0.40, 0.55),
            (0.40, 0.40, 0.48),
            (0.52, 0.40, 0.46),
            (0.60, 0.40, 0.38)
        ]
        if GestureMath.flingFromTrail(slowDrop, palmWidth: 0.12, aspect: 16 / 9, centerDead: false, afterDrag: false) != .minimize {
            fputs("FAIL Abwärtsruck ohne Zug ist Minimieren\n", stderr)
            fails += 1
        }
        if GestureMath.flingFromTrail(slowDrop, palmWidth: 0.12, aspect: 16 / 9, centerDead: false, afterDrag: true) != .none {
            fputs("FAIL langsames Loslassen nach Zug ist kein Minimieren\n", stderr)
            fails += 1
        }
        if GestureMath.isClick(held: 0.22, palmMovedHW: 0.12, cursorMovedPx: 4) != true {
            fputs("FAIL stillstehende Pinzette ist Klick\n", stderr)
            fails += 1
        }
        if GestureMath.isClick(held: 0.22, palmMovedHW: 0.60, cursorMovedPx: 4) != false {
            fputs("FAIL Zug ist kein Klick\n", stderr)
            fails += 1
        }
        if GestureMath.isDrag(palmMovedHW: 0.12, cursorMovedPx: 3) != false {
            fputs("FAIL 0,12 Handbreiten Zittern ist kein Zug\n", stderr)
            fails += 1
        }
        if GestureMath.swipeBlocked(now: 10.2, muteUntil: 10.5, dx: -1, lastDx: 0, lastAt: 0) != true {
            fputs("FAIL Mute nach Pinzette blockt Wischen\n", stderr)
            fails += 1
        }
        if GestureMath.swipeBlocked(now: 12.0, muteUntil: 0, dx: 1.2, lastDx: -1.1, lastAt: 11.2) != true {
            fputs("FAIL Gegenwischen in 1 s blocken\n", stderr)
            fails += 1
        }
        if GestureMath.swipeBlocked(now: 14.0, muteUntil: 0, dx: 1.2, lastDx: -1.1, lastAt: 11.2) != false {
            fputs("FAIL nach Reverse-Lock darf wieder gewischt werden\n", stderr)
            fails += 1
        }
        let mag = GestureMath.magnet(
            cursor: CGPoint(x: 100, y: 100),
            targets: [CGPoint(x: 110, y: 104), CGPoint(x: 400, y: 400)]
        )
        if mag == nil || abs(mag!.x - 110) > 0.1 {
            fputs("FAIL Magnet zieht zum nahen Chrom-Knopf\n", stderr)
            fails += 1
        }
        if GestureMath.pinchDragNeed < 0.35 {
            fputs("FAIL Drag-Schwelle muss über Palm-Zittern liegen\n", stderr)
            fails += 1
        }
        if GestureMath.peaceHold < 1.0 {
            fputs("FAIL Peace länger halten, sonst Öffnen = Aufnahme\n", stderr)
            fails += 1
        }
        if GestureMath.calibMinArea > 0.02 {
            fputs("FAIL Kalibrierung muss kleinen Anschlag akzeptieren\n", stderr)
            fails += 1
        }
        if GestureMath.twoPinchScaleNeed < 0.4 {
            fputs("FAIL Skalieren darf nicht bei 0,28 Handbreiten pumpen\n", stderr)
            fails += 1
        }
        if GestureMath.twoPinchReverseMul < 1.5 {
            fputs("FAIL Gegenrichtung beim Skalieren braucht extra Weg\n", stderr)
            fails += 1
        }
        let desk = CGRect(x: 0, y: 0, width: 1440, height: 900)
        if !GestureMath.fillsScreen(CGRect(x: 0, y: 0, width: 1440, height: 900), screen: desk) {
            fputs("FAIL schirmfüllend erkennen\n", stderr)
            fails += 1
        }
        if GestureMath.fillsScreen(CGRect(x: 100, y: 80, width: 800, height: 600), screen: desk) {
            fputs("FAIL normales Fenster ist kein Schreibtisch\n", stderr)
            fails += 1
        }
        if !GestureMath.isWallpaperTitle("") || !GestureMath.isWallpaperTitle("Schreibtisch") {
            fputs("FAIL Schreibtisch-Titel\n", stderr)
            fails += 1
        }
        if GestureMath.isWallpaperTitle("Dokumente") {
            fputs("FAIL Finder-Ordner ist kein Wallpaper\n", stderr)
            fails += 1
        }
        if !GestureMath.isClapPulse(prevSpan: 3.2, prevT: 1.00, span: 1.05, now: 1.14) {
            fputs("FAIL schneller Palmen-Schlag ist Klatschen\n", stderr)
            fails += 1
        }
        if GestureMath.isClapPulse(prevSpan: 3.0, prevT: 1.00, span: 1.2, now: 1.80) {
            fputs("FAIL langsames Zusammenführen ist kein Klatschen\n", stderr)
            fails += 1
        }
        if !GestureMath.isDoubleClap(first: 2.00, second: 2.45) {
            fputs("FAIL zweites Klatschen in 0,45 s zählt\n", stderr)
            fails += 1
        }
        if GestureMath.isDoubleClap(first: 2.00, second: 2.08) {
            fputs("FAIL Doppelklatschen braucht Abstand, kein Zittern\n", stderr)
            fails += 1
        }
        if GestureMath.clapMinSpeed < 4 {
            fputs("FAIL Klatschen muss ein Schlag sein, nicht halten\n", stderr)
            fails += 1
        }

        let edgeIn = CoordMath.edgeAbsoluteWeight(u: 0.5, v: 0.5, band: 0.15)
        if edgeIn > 0.01 {
            fputs("FAIL Hybrid-Mitte muss relativ sein (\(edgeIn))\n", stderr)
            fails += 1
        }
        let edgeOut = CoordMath.edgeAbsoluteWeight(u: 0.02, v: 0.5, band: 0.15)
        if edgeOut < 0.85 {
            fputs("FAIL Hybrid-Rand muss absolut sein (\(edgeOut))\n", stderr)
            fails += 1
        }
        let accelSlow = CoordMath.pointerAccelScale(magnitude: 0.004)
        let accelFast = CoordMath.pointerAccelScale(magnitude: 0.05)
        if accelSlow >= accelFast {
            fputs("FAIL Pointer-Accel: langsam muss kleiner als schnell sein \(accelSlow) vs \(accelFast)\n", stderr)
            fails += 1
        }
        if accelSlow > 0.7 {
            fputs("FAIL Mini-Zucken darf nicht beschleunigen (\(accelSlow))\n", stderr)
            fails += 1
        }
        if !CoordMath.nearUnitCenter(u: 0.50, v: 0.50) {
            fputs("FAIL Bildschirmmitte ist tot\n", stderr)
            fails += 1
        }
        if CoordMath.nearUnitCenter(u: 0.90, v: 0.10) {
            fputs("FAIL Ecke ist keine Totzone\n", stderr)
            fails += 1
        }
        let midFling: [(t: TimeInterval, x: CGFloat, y: CGFloat)] = [
            (0.00, 0.20, 0.20),
            (0.08, 0.20, 0.40)
        ]
        if GestureMath.flingFromTrail(midFling, palmWidth: 0.12, centerDead: true, screenUV: CGPoint(x: 0.50, y: 0.50)) != .none {
            fputs("FAIL kalibrierte Totzone am Schirmmittelpunkt, nicht Kameramitte\n", stderr)
            fails += 1
        }
        if GestureMath.clutchOwnRadius < 40 {
            fputs("FAIL Clutch-Radius gegen eigene Events zu klein\n", stderr)
            fails += 1
        }
        if GestureMath.clutchOwnWindow < 0.08 {
            fputs("FAIL Clutch-Fenster gegen eigene Events zu kurz\n", stderr)
            fails += 1
        }
        if GestureMath.hybridBand < 0.10 || GestureMath.hybridBand > 0.25 {
            fputs("FAIL Hybrid-Band 15 %\n", stderr)
            fails += 1
        }
        if GestureMath.killHold < 1.2 {
            fputs("FAIL Not-Aus muss länger als 0,80 s halten\n", stderr)
            fails += 1
        }
        if GestureMath.killSwitchCandidate(openPalms: 2, spanHW: 1.5, pinchHeld: false, twoPinch: false) {
            fputs("FAIL Not-Aus bei Kontaktabstand (Klatschen)\n", stderr)
            fails += 1
        }
        if !GestureMath.killSwitchCandidate(openPalms: 2, spanHW: 2.5, pinchHeld: false, twoPinch: false) {
            fputs("FAIL zwei offene Hände weit auseinander sind Not-Aus-Kandidat\n", stderr)
            fails += 1
        }
        if GestureMath.killSwitchCandidate(openPalms: 2, spanHW: 3.0, pinchHeld: true, twoPinch: false) {
            fputs("FAIL Not-Aus während Pinzette\n", stderr)
            fails += 1
        }
        if GestureMath.killSwitchCandidate(openPalms: 2, spanHW: 3.0, pinchHeld: false, twoPinch: true) {
            fputs("FAIL Not-Aus während Zwei-Pinzette\n", stderr)
            fails += 1
        }
        if GestureMath.killSwitchCandidate(openPalms: 1, spanHW: 3.0, pinchHeld: false, twoPinch: false) {
            fputs("FAIL eine offene Hand ist kein Not-Aus\n", stderr)
            fails += 1
        }
        if !GestureMath.bodyOverridesVision(visionUnknown: true, ratio: 0.60, disagree: false) {
            fputs("FAIL unbekannte Vision darf Körper-Vote 0,60 nehmen\n", stderr)
            fails += 1
        }
        if GestureMath.bodyOverridesVision(visionUnknown: false, ratio: 0.60, disagree: true) {
            fputs("FAIL Vision L/R bleibt bei schwachem Körper-Vote 0,60\n", stderr)
            fails += 1
        }
        if !GestureMath.bodyOverridesVision(visionUnknown: false, ratio: 0.40, disagree: true) {
            fputs("FAIL klarer Körper-Vote 0,40 überstimmt Vision\n", stderr)
            fails += 1
        }
        if GestureMath.bodyOverridesVision(visionUnknown: false, ratio: 0.40, disagree: false) {
            fputs("FAIL einig kein Override\n", stderr)
            fails += 1
        }
        let ema = GestureMath.palmWidthEMA(prev: 0.12, next: 0.20, alpha: 0.22)
        if abs(ema - (0.22 * 0.20 + 0.78 * 0.12)) > 0.0001 {
            fputs("FAIL palmWidth-EMA \(ema)\n", stderr)
            fails += 1
        }
        let emaFirst = GestureMath.palmWidthEMA(prev: 0, next: 0.15)
        if abs(emaFirst - 0.15) > 0.0001 {
            fputs("FAIL palmWidth-EMA erster Sample\n", stderr)
            fails += 1
        }

        if CameraRig.resolve(pair: .macPhone, mac: "m", phone: "p", osmo: nil)?.cover != "p" {
            fputs("FAIL Mac+iPhone Cover ist iPhone\n", stderr)
            fails += 1
        }
        if CameraRig.resolve(pair: .macOsmo, mac: "m", phone: nil, osmo: "o")?.cover != "o" {
            fputs("FAIL Mac+Osmo Cover ist Osmo\n", stderr)
            fails += 1
        }
        if CameraRig.resolve(pair: .phoneOsmo, mac: "m", phone: "p", osmo: "o")?.lead != "p" {
            fputs("FAIL iPhone+Osmo Lead ist iPhone, kein Mac\n", stderr)
            fails += 1
        }
        if CameraRig.resolve(pair: .macPhone, mac: "m", phone: nil, osmo: "o") != nil {
            fputs("FAIL Mac+iPhone ohne iPhone ist unvollständig\n", stderr)
            fails += 1
        }
        if CameraRig.useCover(leadQ: 0.8, coverQ: 0.5, leadN: 1, coverN: 1, usingCover: false) {
            fputs("FAIL Cover nicht bei gutem Lead\n", stderr)
            fails += 1
        }
        if !CameraRig.useCover(leadQ: 0.1, coverQ: 0.7, leadN: 1, coverN: 1, usingCover: false) {
            fputs("FAIL Cover wenn Lead die Hand fast verliert\n", stderr)
            fails += 1
        }
        if !CameraRig.useCover(leadQ: 0.0, coverQ: 0.4, leadN: 0, coverN: 1, usingCover: false) {
            fputs("FAIL Cover wenn Lead leer\n", stderr)
            fails += 1
        }
        if CameraRig.mapsDisagree(CGPoint(x: 0, y: 0), CGPoint(x: 40, y: 40)) {
            fputs("FAIL 56 px ist kein Winkel-Unco\n", stderr)
            fails += 1
        }
        if !CameraRig.mapsDisagree(CGPoint(x: 0, y: 0), CGPoint(x: 200, y: 0)) {
            fputs("FAIL 200 px ist Winkel-Unco, Lead gewinnt\n", stderr)
            fails += 1
        }
        if GestureMath.rigDisagreePx < 80 {
            fputs("FAIL Unco-Schwelle zu eng\n", stderr)
            fails += 1
        }

        if fails > 0 {
            fputs("\(fails) Tests fehlgeschlagen\n", stderr)
            exit(1)
        }
        print("CoordTests OK")
    }
}

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

        // AXPosition / CopyElementAtPosition sind Quartz (Ursprung oben links).
        // Cocoa-Y = primaryMaxY − Quartz-Y — nur NSScreen / NSEvent brauchen die Drehung.
        let quartzCursor = CGPoint(x: 200, y: 100)
        let axHit = CoordMath.cocoa(fromQuartz: quartzCursor, primaryMaxY: primaryH)
        eq(axHit.x, 200, "Cocoa-Y x")
        eq(axHit.y, primaryH - 100, "Cocoa-Y = primaryMaxY − Quartz-Y")

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
        // Mini-Ruck (0,60 HW): tot in der Schirmmitte, Werfen am Kamerarand / in der Ecke.
        let midFling: [(t: TimeInterval, x: CGFloat, y: CGFloat)] = [
            (0.00, 0.20, 0.20),
            (0.08, 0.20, 0.272)
        ]
        if GestureMath.flingFromTrail(midFling, palmWidth: 0.12, centerDead: true, screenUV: CGPoint(x: 0.50, y: 0.50)) != .none {
            fputs("FAIL kalibrierte Totzone am Schirmmittelpunkt, nicht Kameramitte\n", stderr)
            fails += 1
        }
        if GestureMath.flingFromTrail(midFling, palmWidth: 0.12, centerDead: true) != .throwUp {
            fputs("FAIL ohne Kalibrierung zählt Kameraposition — Rand ist kein Tot\n", stderr)
            fails += 1
        }
        if GestureMath.flingFromTrail(midFling, palmWidth: 0.12, centerDead: true, screenUV: CGPoint(x: 0.90, y: 0.10)) != .throwUp {
            fputs("FAIL Totzone nur in der Schirmmitte, Ecke bleibt Werfen\n", stderr)
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
        if CameraRig.useCover(leadQ: 0.1, coverQ: 0.7, leadN: 1, coverN: 1, usingCover: false) {
            fputs("FAIL Cover nie Aktor, auch wenn Lead schwach\n", stderr)
            fails += 1
        }
        if CameraRig.useCover(leadQ: 0.0, coverQ: 0.4, leadN: 0, coverN: 1, usingCover: false) {
            fputs("FAIL Cover nie Aktor wenn Lead leer\n", stderr)
            fails += 1
        }
        if CameraRig.pinchAssist(lead: 0.10, cover: 0.95) > 0.12 {
            fputs("FAIL Cover erfindet keinen Pinch\n", stderr)
            fails += 1
        }
        if CameraRig.pinchAssist(lead: 0.60, cover: 0.90) <= 0.60 {
            fputs("FAIL Cover darf Pinch der Lead-Hand bestätigen\n", stderr)
            fails += 1
        }
        if CameraRig.blendScreen(CGPoint(x: 0, y: 0), CGPoint(x: 200, y: 0)) != nil {
            fputs("FAIL Winkel-Unco nicht mischen\n", stderr)
            fails += 1
        }
        if CameraRig.blendScreen(CGPoint(x: 10, y: 10), CGPoint(x: 20, y: 12)) == nil {
            fputs("FAIL kleine Lage-Differenz mischen\n", stderr)
            fails += 1
        }
        let ident: [CGFloat] = [1, 0, 0, 0, 1, 0, 0, 0, 1]
        if let q = CoordMath.apply3x3(ident, CGPoint(x: 0.4, y: 0.7)) {
            pointEq(q, CGPoint(x: 0.4, y: 0.7), "Homographie Identität")
        } else {
            fputs("FAIL apply3x3 Identität\n", stderr)
            fails += 1
        }
        if let inv = CoordMath.invert3x3([2, 0, 1, 0, 3, 4, 0, 0, 1]),
           let p = CoordMath.apply3x3([2, 0, 1, 0, 3, 4, 0, 0, 1], CGPoint(x: 0.2, y: 0.3)),
           let back = CoordMath.apply3x3(inv, p)
        {
            pointEq(back, CGPoint(x: 0.2, y: 0.3), "Homographie Roundtrip")
        } else {
            fputs("FAIL invert3x3 Roundtrip\n", stderr)
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

        let peakH = GestureMath.fusionEntropy([0.92, 0.02, 0.02, 0.01, 0.01, 0.01, 0.01])
        let flatH = GestureMath.fusionEntropy([1.0 / 7, 1.0 / 7, 1.0 / 7, 1.0 / 7, 1.0 / 7, 1.0 / 7, 1.0 / 7])
        if peakH >= flatH {
            fputs("FAIL spitze Verteilung hat kleinere Entropie (\(peakH) vs \(flatH))\n", stderr)
            fails += 1
        }
        let floorPeak = GestureMath.entropyActionFloor(entropy: peakH)
        let floorFlat = GestureMath.entropyActionFloor(entropy: flatH)
        if floorPeak > 0.56 {
            fputs("FAIL spitze Pose Floor ≤ 0,56 (ist \(floorPeak))\n", stderr)
            fails += 1
        }
        if floorFlat <= floorPeak {
            fputs("FAIL flache Pose Floor über spitzer (\(floorFlat) vs \(floorPeak))\n", stderr)
            fails += 1
        }
        if floorFlat < 0.66 {
            fputs("FAIL flache Pose Floor ≥ 0,66 (ist \(floorFlat))\n", stderr)
            fails += 1
        }
        let a24 = GestureMath.palmHighpassAlpha(dt: 0.04)
        let a8 = GestureMath.palmHighpassAlpha(dt: 0.125)
        if a8 <= a24 {
            fputs("FAIL Continuity-Hochpass muss größer sein als 24 fps (\(a8) vs \(a24))\n", stderr)
            fails += 1
        }
        if GestureMath.palmDeadZone(dt: 0.125) <= GestureMath.palmDead {
            fputs("FAIL 8 fps Deadzone größer\n", stderr)
            fails += 1
        }
        if !GestureMath.inCornerRest(u: 0.01, v: 0.01) {
            fputs("FAIL Ecke 1 % ist Ruhezone\n", stderr)
            fails += 1
        }
        if GestureMath.inCornerRest(u: 0.50, v: 0.50) {
            fputs("FAIL Mitte ist keine Ruhezone\n", stderr)
            fails += 1
        }
        if GestureMath.inCornerRest(u: 0.01, v: 0.50) {
            fputs("FAIL nur eine Kante ist keine Ecke\n", stderr)
            fails += 1
        }
        if GestureMath.pinchFollowID(held: true, locked: "T1", liveIDs: ["T2"]) != nil {
            fputs("FAIL fehlende Pinzette-ID nicht auf primary\n", stderr)
            fails += 1
        }
        if GestureMath.pinchFollowID(held: true, locked: "T1", liveIDs: ["T1", "T2"]) != "T1" {
            fputs("FAIL sichtbare Pinzette bleibt T1\n", stderr)
            fails += 1
        }
        if GestureMath.pinchFollowID(held: false, locked: "T1", liveIDs: ["T2"]) != nil {
            fputs("FAIL ohne Hold kein Follow\n", stderr)
            fails += 1
        }
        if !GestureMath.tableIdleCandidate(palmsY: [0.04, 0.05], stillHW: 0.04, pinchHeld: false) {
            fputs("FAIL zwei Palmen unten still sind Tisch-Idle\n", stderr)
            fails += 1
        }
        if GestureMath.tableIdleCandidate(palmsY: [0.04, 0.05], stillHW: 0.04, pinchHeld: true) {
            fputs("FAIL Pinzette ist kein Tisch-Idle\n", stderr)
            fails += 1
        }
        if GestureMath.tableIdleCandidate(palmsY: [0.12], stillHW: 0.02, pinchHeld: false) {
            fputs("FAIL eine Hand ist kein Tisch-Idle\n", stderr)
            fails += 1
        }
        if GestureMath.tableIdleCandidate(palmsY: [0.12, 0.15], stillHW: 0.02, pinchHeld: false) {
            fputs("FAIL Palmen in der Luft sind kein Tisch\n", stderr)
            fails += 1
        }
        if AppInjectProfile.of(bundleId: "com.apple.dt.Xcode") != .full {
            fputs("FAIL Xcode nicht mehr aus — voll\n", stderr)
            fails += 1
        }
        if !AppInjectProfile.of(bundleId: "com.apple.Safari").allows("Wegwerfen") {
            fputs("FAIL Safari voll, nicht nur Klick\n", stderr)
            fails += 1
        }
        if !AppInjectProfile.of(bundleId: "com.apple.Safari").allowsWindowDrag {
            fputs("FAIL Safari Fensterzug wieder an\n", stderr)
            fails += 1
        }
        if !AppInjectProfile.of(bundleId: "com.apple.finder").allows("Wegwerfen") {
            fputs("FAIL Finder darf werfen\n", stderr)
            fails += 1
        }
        let uv = CoordMath.unitInRect(CGPoint(x: 100, y: 50), rect: CGRect(x: 0, y: 0, width: 200, height: 100))
        if abs(uv.x - 0.5) > 0.001 || abs(uv.y - 0.5) > 0.001 {
            fputs("FAIL unitInRect Mitte \(uv)\n", stderr)
            fails += 1
        }

        if GestureMath.chromeSpreadGap < 96 {
            fputs("FAIL Chrome-Abstand zu eng\n", stderr)
            fails += 1
        }
        if GestureMath.chromeHit < 64 {
            fputs("FAIL Chrome-Treffer zu klein\n", stderr)
            fails += 1
        }
        let spread = GestureMath.spreadChrome(centers: [
            CGPoint(x: 100, y: 80),
            CGPoint(x: 118, y: 80),
            CGPoint(x: 136, y: 80)
        ])
        if spread.count != 3 {
            fputs("FAIL Spread 3 Knöpfe\n", stderr)
            fails += 1
        } else if spread[1].midX - spread[0].midX < 90 {
            fputs("FAIL Spread-Abstand \(spread[1].midX - spread[0].midX)\n", stderr)
            fails += 1
        }
        let z = GestureMath.deadzone2D(dx: 0.04, dy: 0.01, dead: 0.02)
        if z == .zero {
            fputs("FAIL Schrägzug darf nicht je Achse sterben\n", stderr)
            fails += 1
        }
        let still = GestureMath.deadzone2D(dx: 0.004, dy: 0.003, dead: 0.02)
        if still != .zero {
            fputs("FAIL kleine Strecke bleibt tot\n", stderr)
            fails += 1
        }
        if GestureMath.swipeMinDx > 0.70 {
            fputs("FAIL Wischen-Schwelle zu hoch\n", stderr)
            fails += 1
        }
        if GestureMath.swipeAxis > 1.4 {
            fputs("FAIL Wischen zu streng in der Achse\n", stderr)
            fails += 1
        }
        let diag = GestureMath.classifyFling(
            dx: 1.2, dy: 1.1, speed: 8, dist: 2, afterDrag: true
        )
        if diag != .none {
            fputs("FAIL Schrägzug nach Drag ist Ablegen, kein Dock\n", stderr)
            fails += 1
        }

        if abs(GestureMath.sampleDtCap - 0.20) > 0.001 {
            fputs("FAIL sampleDtCap 0,20 nicht 0,08\n", stderr)
            fails += 1
        }
        if GestureMath.sampleDt(now: 1.125, last: 1.000) < 0.12 {
            fputs("FAIL Continuity-dt 125 ms nicht auf 80 ms kappen\n", stderr)
            fails += 1
        }
        if GestureMath.sampleDt(now: 2.0, last: 1.0) > 0.21 {
            fputs("FAIL dt-Cap 0,20\n", stderr)
            fails += 1
        }
        if GestureMath.pinchCloseVel(dt: 0.04) > -1.5 {
            fputs("FAIL 24 fps Close-Vel bleibt −1,6\n", stderr)
            fails += 1
        }
        if GestureMath.pinchCloseVel(dt: 0.125) <= GestureMath.pinchCloseVel(dt: 0.04) {
            fputs("FAIL 8 fps Close-Vel weicher (weniger negativ)\n", stderr)
            fails += 1
        }
        if GestureMath.flingWindowLen(medianDt: 0.04) > 0.13 {
            fputs("FAIL 24 fps Fling-Fenster bleibt 120 ms\n", stderr)
            fails += 1
        }
        if GestureMath.flingWindowLen(medianDt: 0.125) < 0.24 {
            fputs("FAIL 8 fps Fling-Fenster braucht ≥ 2 Frames\n", stderr)
            fails += 1
        }
        let eightFpsFling: [(t: TimeInterval, x: CGFloat, y: CGFloat)] = [
            (0.00, 0.50, 0.40),
            (0.125, 0.50, 0.70)
        ]
        if GestureMath.flingFromTrail(eightFpsFling, palmWidth: 0.12, aspect: 16 / 9, centerDead: false) != .none {
            fputs("FAIL 120-ms-Fenster ist bei 8 fps leer / ein Sample\n", stderr)
            fails += 1
        }
        if GestureMath.flingFromTrail(eightFpsFling, palmWidth: 0.12, aspect: 16 / 9, centerDead: false, windowSec: GestureMath.flingWindowLen(medianDt: 0.125)) != .throwUp {
            fputs("FAIL Continuity-Fling im 2,5-Frame-Fenster\n", stderr)
            fails += 1
        }
        if GestureMath.preferredID(locked: "T1", liveIDs: ["T1", "T2"], leftID: "T2", rightID: "T1", leftHanded: false) != "T1" {
            fputs("FAIL preferred bleibt Lock-ID, nicht nur L/R\n", stderr)
            fails += 1
        }
        if GestureMath.preferredID(locked: "T9", liveIDs: ["T1", "T2"], leftID: "T2", rightID: "T1", leftHanded: false) != "T1" {
            fputs("FAIL tote Lock-ID fällt auf rechte Hand\n", stderr)
            fails += 1
        }
        if GestureMath.preferredID(locked: "T9", liveIDs: ["T1", "T2"], leftID: "T2", rightID: "T1", leftHanded: true) != "T2" {
            fputs("FAIL Linkshänder ohne Lock nimmt links\n", stderr)
            fails += 1
        }
        if GestureMath.pinchFollowID(held: true, locked: "T1", liveIDs: ["T2"]) != nil {
            fputs("FAIL Pinch-Follow nie auf die andere Hand\n", stderr)
            fails += 1
        }
        if !GestureMath.pullTowardSelf(startY: 0.55, nowY: 0.40) {
            fputs("FAIL Palm-Y −0,15 ist Heranziehen\n", stderr)
            fails += 1
        }
        if GestureMath.pullTowardSelf(startY: 0.50, nowY: 0.46) {
            fputs("FAIL Mini-Y ist kein Heranziehen\n", stderr)
            fails += 1
        }
        if GestureMath.airKeyboardPointHold < 0.80 {
            fputs("FAIL Tastatur-Hold nicht 0,40 s\n", stderr)
            fails += 1
        }
        if !GestureMath.airKeyboardSummon(v: 0.90) {
            fputs("FAIL unten ruft Tastatur\n", stderr)
            fails += 1
        }
        if GestureMath.airKeyboardSummon(v: 0.20) {
            fputs("FAIL oben/Mitte öffnet keine Tastatur\n", stderr)
            fails += 1
        }
        if GestureMath.keyboardDwell > 0.18 {
            fputs("FAIL Tastatur-Dwell muss unter 0,18 s bleiben\n", stderr)
            fails += 1
        }
        if GestureMath.flipLeft(true, mirrored: true) != false {
            fputs("FAIL Spiegel dreht links nach rechts\n", stderr)
            fails += 1
        }
        if GestureMath.flipLeft(true, mirrored: false) != true {
            fputs("FAIL ohne Spiegel bleibt links\n", stderr)
            fails += 1
        }
        let throwUp = GestureMath.drillMatch(
            action: "throwUp",
            poses: ["pinch", "pinch", "openPalm"],
            sides: ["Rechts"],
            pinchMax: 0.8,
            dx: 0.02,
            dy: 0.22,
            openMax: 2,
            twoHands: false
        )
        if !throwUp.ok {
            fputs("FAIL Wurf hoch erkannt\n", stderr)
            fails += 1
        }
        let swipeL = GestureMath.drillMatch(
            action: "swipeLeft",
            poses: ["openPalm"],
            sides: ["Rechts"],
            pinchMax: 0.1,
            dx: -0.2,
            dy: 0.02,
            openMax: 4,
            twoHands: false
        )
        if !swipeL.ok {
            fputs("FAIL Wischen links erkannt\n", stderr)
            fails += 1
        }

        if GestureMath.pinchStartsGrab(gate: false, closedness: 0.30) {
            fputs("FAIL Faust/Pose startet keine Pinzette\n", stderr)
            fails += 1
        }
        if !GestureMath.pinchStartsGrab(gate: true, closedness: 0.20) {
            fputs("FAIL Gate muss Greifen starten\n", stderr)
            fails += 1
        }
        if GestureMath.pinchStartsGrab(gate: true, closedness: 0.90, reach: 0.40, index: 0.10) {
            fputs("FAIL Faust-Reach startet keine Pinzette\n", stderr)
            fails += 1
        }
        if !GestureMath.pinchStartsGrab(gate: true, closedness: 0.20, reach: 1.10, index: 0.70) {
            fputs("FAIL Pinzette mit Reach/Zeigefinger startet\n", stderr)
            fails += 1
        }
        let fistReach = GestureMath.pinchReach(
            wrist: CGPoint(x: 0.50, y: 0.50),
            thumb: CGPoint(x: 0.52, y: 0.53),
            index: CGPoint(x: 0.51, y: 0.54),
            scale: 0.12
        )
        if GestureMath.pinchLooksLikePinch(reach: fistReach, index: 0.10) {
            fputs("FAIL Faust-Spitzen an der Palme sind keine Pinzette\n", stderr)
            fails += 1
        }
        let pinchReach = GestureMath.pinchReach(
            wrist: CGPoint(x: 0.50, y: 0.80),
            thumb: CGPoint(x: 0.48, y: 0.28),
            index: CGPoint(x: 0.52, y: 0.28),
            scale: 0.12
        )
        if !GestureMath.pinchLooksLikePinch(reach: pinchReach, index: 0.20) {
            fputs("FAIL lange Pinzette hat Reach\n", stderr)
            fails += 1
        }
        if GestureMath.chromeDwellMoved(from: CGPoint(x: 100, y: 100), to: CGPoint(x: 108, y: 104)) {
            fputs("FAIL Ampel-Zielen 10 px ist still\n", stderr)
            fails += 1
        }
        if !GestureMath.chromeDwellMoved(from: CGPoint(x: 100, y: 100), to: CGPoint(x: 130, y: 100)) {
            fputs("FAIL Ampel 30 px setzt Verweilen zurück\n", stderr)
            fails += 1
        }
        if GestureMath.preferredHoldID(
            locked: "T1",
            liveIDs: ["T2"],
            missHeld: true,
            leftID: "T2",
            rightID: "T2",
            leftHanded: false
        ) != "T1" {
            fputs("FAIL fehlender Frame hält Lock-ID\n", stderr)
            fails += 1
        }
        if GestureMath.preferredHoldID(
            locked: "T9",
            liveIDs: ["T1", "T2"],
            missHeld: false,
            leftID: "T2",
            rightID: "T1",
            leftHanded: false
        ) != "T1" {
            fputs("FAIL tote Lock ohne Hold fällt auf rechts\n", stderr)
            fails += 1
        }
        if GestureMath.twoPinchSorted(ids: ["T2", "T1"]) != ["T1", "T2"] {
            fputs("FAIL Zwei-Pinzetten IDs sortiert\n", stderr)
            fails += 1
        }
        if GestureMath.emptyHandsHold(dt: 0.04) < 0.21 {
            fputs("FAIL 24 fps empty-hold bleibt pinchLockMiss\n", stderr)
            fails += 1
        }
        if GestureMath.emptyHandsHold(dt: 0.125) < 0.26 {
            fputs("FAIL Continuity empty-hold deckt zwei Fehlframes\n", stderr)
            fails += 1
        }
        if AppInjectProfile.of(bundleId: "com.apple.dt.Xcode") != .full {
            fputs("FAIL Xcode nicht mehr aus — voll\n", stderr)
            fails += 1
        }
        if GestureMath.entropyActionFloor(entropy: 0) < 0.51 {
            fputs("FAIL spitzes Tor nicht unter 0,52\n", stderr)
            fails += 1
        }
        if GestureMath.entropyActionFloor(entropy: log(7.0)) < 0.66 {
            fputs("FAIL flaches Tor nicht 0,68\n", stderr)
            fails += 1
        }
        if CameraRig.pinchAssist(lead: 0.20, cover: 0.90) != 0.20 {
            fputs("FAIL Cover erfindet keine Pinzette\n", stderr)
            fails += 1
        }
        if CameraRig.pinchAssist(lead: 0.80, cover: 0.90) != 0.80 {
            fputs("FAIL Cover boostet keine schon klare Pinzette\n", stderr)
            fails += 1
        }
        let assisted = CameraRig.pinchAssist(lead: 0.50, cover: 0.80)
        if abs(assisted - 0.59) > 0.01 {
            fputs("FAIL Cover-Band 0,50/0,80 → 0,59, nicht \(assisted)\n", stderr)
            fails += 1
        }
        if GestureMath.pinchHoldsGrab(gate: true, closedness: 0.90, reach: 0.40, index: 0.10) {
            fputs("FAIL Faust hält Klick-Pinzette nicht\n", stderr)
            fails += 1
        }
        if !GestureMath.pinchHoldsGrab(gate: true, closedness: 0.90, reach: 0.40, index: 0.10, allowFist: true) {
            fputs("FAIL Zug darf Faust tragen\n", stderr)
            fails += 1
        }
        if !GestureMath.pinchHoldsGrab(gate: true, closedness: 0.50, reach: 1.05, index: 0.20) {
            fputs("FAIL Pinzette mit Reach hält\n", stderr)
            fails += 1
        }
        if GestureMath.pinchHoldsGrab(gate: false, closedness: 0.20) {
            fputs("FAIL offene Hand hält keine Pinzette\n", stderr)
            fails += 1
        }
        if GestureMath.keyboardStill(movedPx: 24) {
            fputs("FAIL Tastatur tippt nicht beim Zielen\n", stderr)
            fails += 1
        }
        if GestureMath.killPalmStill > 0.18 {
            fputs("FAIL Not-Aus-Still muss Scroll erlauben\n", stderr)
            fails += 1
        }
        if !GestureMath.scrollAllowed(openPalms: 1, pinchHeld: false) {
            fputs("FAIL eine offene Hand scrollt\n", stderr)
            fails += 1
        }
        if GestureMath.scrollAllowed(openPalms: 2, pinchHeld: false) {
            fputs("FAIL zwei offene Hände sind Not-Aus, kein Scroll\n", stderr)
            fails += 1
        }
        if GestureMath.scrollAllowed(openPalms: 0, pinchHeld: false) {
            fputs("FAIL ohne offene Hand kein Scroll\n", stderr)
            fails += 1
        }
        if GestureMath.scrollAllowed(openPalms: 1, pinchHeld: true) {
            fputs("FAIL Pinzette blockt Scroll\n", stderr)
            fails += 1
        }
        if GestureMath.pinchReleaseDead < 0.08 || GestureMath.pinchReleaseDead > 0.18 {
            fputs("FAIL pinchReleaseDead 80–180 ms\n", stderr)
            fails += 1
        }
        if !GestureMath.pinchReleaseBlocks(now: 1.05, releasedAt: 1.0) {
            fputs("FAIL 50 ms nach Gate-Auf tot\n", stderr)
            fails += 1
        }
        if GestureMath.pinchReleaseBlocks(now: 1.20, releasedAt: 1.0) {
            fputs("FAIL 200 ms nach Gate-Auf frei\n", stderr)
            fails += 1
        }
        if GestureMath.pinchReleaseBlocks(now: 1.0, releasedAt: nil) {
            fputs("FAIL ohne Release kein Tot\n", stderr)
            fails += 1
        }
        if !GestureMath.missHeld(now: 10.10, since: 10.0) {
            fputs("FAIL Miss 100 ms hält Lock\n", stderr)
            fails += 1
        }
        if GestureMath.missHeld(now: 10.50, since: 10.0) {
            fputs("FAIL Miss 500 ms gibt Lock frei\n", stderr)
            fails += 1
        }
        if GestureMath.missHeld(now: 10.0, since: nil) {
            fputs("FAIL ohne Miss-Stempel kein Hold\n", stderr)
            fails += 1
        }
        if GestureMath.lockFreezeLabel(locked: "T1", missHeld: true) != "T1 freeze" {
            fputs("FAIL HUD Lock-Chip T1 freeze\n", stderr)
            fails += 1
        }
        if GestureMath.lockFreezeLabel(locked: "T1", missHeld: false) != nil {
            fputs("FAIL ohne Miss kein Freeze-Chip\n", stderr)
            fails += 1
        }
        if GestureMath.lockFreezeLabel(locked: nil, missHeld: true) != nil {
            fputs("FAIL ohne Lock-ID kein Freeze-Chip\n", stderr)
            fails += 1
        }
        if !GestureMath.clutchIgnores(delta: 1.0) {
            fputs("FAIL 1 px Jiggler ignorieren\n", stderr)
            fails += 1
        }
        if GestureMath.clutchIgnores(delta: 3.0) {
            fputs("FAIL 3 px ist Hardware\n", stderr)
            fails += 1
        }
        let pinchWin = CGRect(x: 0, y: 0, width: 800, height: 600)
        if !GestureMath.twoPinchOppositeHalves(CGPoint(x: 80, y: 300), CGPoint(x: 720, y: 300), window: pinchWin) {
            fputs("FAIL gegenüberliegende Hälften\n", stderr)
            fails += 1
        }
        if GestureMath.twoPinchOppositeHalves(CGPoint(x: 80, y: 100), CGPoint(x: 90, y: 120), window: pinchWin) {
            fputs("FAIL gleiche Ecke ist nicht gegenüber\n", stderr)
            fails += 1
        }
        let tailFlick: [(t: TimeInterval, x: CGFloat, y: CGFloat)] = [
            (0.00, 0.50, 0.40),
            (0.10, 0.50, 0.41),
            (0.20, 0.50, 0.42),
            (0.28, 0.50, 0.55),
            (0.32, 0.50, 0.72)
        ]
        if GestureMath.flingVelFromTail(
            tailFlick, palmWidth: 0.12, aspect: 16 / 9, centerDead: false, windowSec: 0.36
        ) != .throwUp {
            fputs("FAIL Tail-Vel wirft aus dem letzten Ruck\n", stderr)
            fails += 1
        }
        if abs(GestureMath.emptyHandsHoldGain(elapsed: 0, hold: 0.25) - 1) > 0.01 {
            fputs("FAIL Freeze-Gain Start 1\n", stderr)
            fails += 1
        }
        if GestureMath.emptyHandsHoldGain(elapsed: 0.25, hold: 0.25) > 0.01 {
            fputs("FAIL Freeze-Gain Ende 0\n", stderr)
            fails += 1
        }
        if GestureMath.emptyHandsRecover(elapsed: 0.25, hold: 0.25) < 0.14 {
            fputs("FAIL Recover nicht unter 0,15\n", stderr)
            fails += 1
        }
        if GestureMath.twoPinchConfirmFrames(dt: 0.04) != 3 {
            fputs("FAIL Built-in 3 Frames Kanten\n", stderr)
            fails += 1
        }
        if GestureMath.twoPinchConfirmFrames(dt: 0.125) != 2 {
            fputs("FAIL Continuity 2 Frames Kanten\n", stderr)
            fails += 1
        }
        if GestureMath.twoPinchEdgeHold(ok: true, streak: 0, need: 3) != 1 {
            fputs("FAIL Edge-Streak zählt\n", stderr)
            fails += 1
        }
        if GestureMath.twoPinchEdgeHold(ok: false, streak: 2, need: 3) != 0 {
            fputs("FAIL Edge-Streak bricht ab\n", stderr)
            fails += 1
        }
        if !GestureMath.twoPinchEdgeReady(streak: 3, need: 3) {
            fputs("FAIL 3 Frames Kanten bereit\n", stderr)
            fails += 1
        }
        if GestureMath.twoPinchEdgeReady(streak: 1, need: 3) {
            fputs("FAIL 1 Frame Kanten nicht bereit\n", stderr)
            fails += 1
        }
        if abs(GestureMath.scrollDeadHW - 0.08) > 0.001 {
            fputs("FAIL Scroll-Totzone 0,08\n", stderr)
            fails += 1
        }
        if GestureMath.scrollCoastTicks(velHW: 0.4, remain: 0.20) == 0 {
            fputs("FAIL Scroll-Inertia startet\n", stderr)
            fails += 1
        }
        if GestureMath.scrollCoastTicks(velHW: 0.4, remain: 0) != 0 {
            fputs("FAIL Scroll-Inertia tot nach Fenster\n", stderr)
            fails += 1
        }
        if !GestureMath.fpsAmber(8) {
            fputs("FAIL 8 fps amber\n", stderr)
            fails += 1
        }
        if GestureMath.fpsAmber(24) {
            fputs("FAIL 24 fps nicht amber\n", stderr)
            fails += 1
        }
        if GestureMath.fpsAmber(0) {
            fputs("FAIL 0 fps (noch kein Sample) nicht amber\n", stderr)
            fails += 1
        }
        if abs(GestureMath.emptyHandsRecoverLive(now: 1.0, until: 1.0, span: 0.25) - 1) > 0.01 {
            fputs("FAIL Recover am Ende voller Gain\n", stderr)
            fails += 1
        }
        if GestureMath.emptyHandsRecoverLive(now: 1.0, until: 1.25, span: 0.25) > 0.30 {
            fputs("FAIL Recover am Start gedämpft\n", stderr)
            fails += 1
        }
        if GestureMath.emptyHandsRecoverSpan(dt: 0.125) < 0.25 {
            fputs("FAIL Recover-Span 8 fps zwei Frames\n", stderr)
            fails += 1
        }
        if !GestureMath.emptyHandsHoldReleaseAX(isDragging: true) {
            fputs("FAIL Dropout gibt AX frei\n", stderr)
            fails += 1
        }
        if GestureMath.emptyHandsHoldReleaseAX(isDragging: false) {
            fputs("FAIL ohne Drag kein AX-Release\n", stderr)
            fails += 1
        }
        if !GestureMath.scrollCoastBreaks(pinchHeld: true) {
            fputs("FAIL Coast bricht bei Pinch\n", stderr)
            fails += 1
        }
        if GestureMath.scrollCoastBreaks(pinchHeld: false) {
            fputs("FAIL Coast ohne Pinch bleibt\n", stderr)
            fails += 1
        }
        let wide = CGRect(x: 0, y: 0, width: 800, height: 600)
        if GestureMath.twoPinchAxis(CGPoint(x: 80, y: 300), CGPoint(x: 720, y: 300), window: wide) != .horizontal {
            fputs("FAIL Kanten links/rechts = horizontal\n", stderr)
            fails += 1
        }
        if GestureMath.twoPinchAxis(CGPoint(x: 400, y: 40), CGPoint(x: 400, y: 560), window: wide) != .vertical {
            fputs("FAIL Kanten oben/unten = vertical\n", stderr)
            fails += 1
        }
        if GestureMath.twoPinchAxisHolds(locked: .horizontal, next: .vertical) {
            fputs("FAIL Achsenwechsel hält nicht\n", stderr)
            fails += 1
        }
        if !GestureMath.twoPinchAxisHolds(locked: .horizontal, next: .horizontal) {
            fputs("FAIL gleiche Achse hält\n", stderr)
            fails += 1
        }
        if !GestureMath.twoPinchAxisHolds(locked: .none, next: .horizontal) {
            fputs("FAIL erste Achse lockt\n", stderr)
            fails += 1
        }
        if GestureMath.twoPinchAxisHolds(locked: .vertical, next: .none) {
            fputs("FAIL none hält keine Achse\n", stderr)
            fails += 1
        }
        let spark: [(t: TimeInterval, fps: Double)] = [
            (0.0, 8), (2.0, 8), (4.0, 9), (6.0, 8)
        ]
        if !GestureMath.fpsSparkAmber(spark, now: 7) {
            fputs("FAIL 8-s Spark 8 fps amber\n", stderr)
            fails += 1
        }
        let spark24: [(t: TimeInterval, fps: Double)] = [(0.0, 24), (4.0, 24)]
        if GestureMath.fpsSparkAmber(spark24, now: 5) {
            fputs("FAIL 24 fps Spark nicht amber\n", stderr)
            fails += 1
        }
        if !GestureMath.emptyHandsHoldDropsPinch() {
            fputs("FAIL Freeze droppt Pinch\n", stderr)
            fails += 1
        }
        if GestureMath.emptyHandsRecoverChip(now: 1.0, until: 1.0, span: 0.25) != nil {
            fputs("FAIL Recover-Chip tot am Ende\n", stderr)
            fails += 1
        }
        if GestureMath.emptyHandsRecoverChip(now: 1.0, until: 1.25, span: 0.25) != "R1" {
            fputs("FAIL Recover-Chip R1 am Start\n", stderr)
            fails += 1
        }
        if GestureMath.emptyHandsRecoverChip(now: 1.20, until: 1.25, span: 0.25) != "R2" {
            fputs("FAIL Recover-Chip R2 am Ende\n", stderr)
            fails += 1
        }
        if GestureMath.emptyHandsHoldDropsPinchChip(dropped: true) != "P drop" {
            fputs("FAIL P-drop Chip\n", stderr)
            fails += 1
        }
        if GestureMath.emptyHandsHoldDropsPinchChip(dropped: false) != nil {
            fputs("FAIL P-drop Chip tot\n", stderr)
            fails += 1
        }
        if abs(GestureMath.emptyHandsRecoverPalmMul(prev: 0.12, next: 0.12) - 1) > 0.01 {
            fputs("FAIL Palm-Mul gleich = 1\n", stderr)
            fails += 1
        }
        if GestureMath.emptyHandsRecoverPalmMul(prev: 0.12, next: 0.22) > 0.80 {
            fputs("FAIL Palm-Mul Sprung dämpft\n", stderr)
            fails += 1
        }
        if GestureMath.pinchReleaseNeed(dt: 0.016) > 0.13 {
            fputs("FAIL Release-Need 24 fps bleibt 120 ms\n", stderr)
            fails += 1
        }
        if GestureMath.pinchReleaseNeed(dt: 0.125) < 0.18 {
            fputs("FAIL Release-Need 8 fps ≥ 200 ms\n", stderr)
            fails += 1
        }
        if !GestureMath.pinchReleaseBlocks(now: 1.15, releasedAt: 1.0, dt: 0.125) {
            fputs("FAIL Release 8 fps blockt 150 ms\n", stderr)
            fails += 1
        }
        if GestureMath.pinchClickMinNeed(dt: 0.016) > 0.06 {
            fputs("FAIL Click-Min 24 fps bleibt 50 ms\n", stderr)
            fails += 1
        }
        if GestureMath.pinchClickMinNeed(dt: 0.125) < 0.15 {
            fputs("FAIL Click-Min 8 fps ≥ 150 ms\n", stderr)
            fails += 1
        }
        if GestureMath.isClick(held: 0.08, palmMovedHW: 0.10, cursorMovedPx: 3, dt: 0.125) {
            fputs("FAIL 80 ms kein Klick bei 8 fps\n", stderr)
            fails += 1
        }
        if !GestureMath.isClick(held: 0.08, palmMovedHW: 0.10, cursorMovedPx: 3, dt: 0.016) {
            fputs("FAIL 80 ms Klick bei 24 fps\n", stderr)
            fails += 1
        }
        if GestureMath.twoPinchConfirmNeed(dt: 0.016) > 0.13 {
            fputs("FAIL Zwei-Pinzetten 24 fps 120 ms\n", stderr)
            fails += 1
        }
        if GestureMath.twoPinchConfirmNeed(dt: 0.125) < 0.18 {
            fputs("FAIL Zwei-Pinzetten 8 fps ≥ 200 ms\n", stderr)
            fails += 1
        }
        if GestureMath.keyboardDwellNeed(dt: 0.016) > 0.13 {
            fputs("FAIL Tastatur 24 fps 120 ms\n", stderr)
            fails += 1
        }
        if GestureMath.keyboardDwellNeed(dt: 0.125) < 0.20 {
            fputs("FAIL Tastatur 8 fps ≥ 200 ms\n", stderr)
            fails += 1
        }
        if GestureMath.chromeDwellNeed(dt: 0.016) > 0.56 {
            fputs("FAIL Ampel-Dwell 24 fps bleibt 0,55 s\n", stderr)
            fails += 1
        }
        if GestureMath.chromeDwellNeed(dt: 0.125) < 0.65 {
            fputs("FAIL Ampel-Dwell 8 fps ≥ 0,65 s\n", stderr)
            fails += 1
        }
        if GestureMath.chromeDwellStillNeed(dt: 0.016, screenMin: 1080) > 20 {
            fputs("FAIL Ampel-Still 24 fps 1080 bleibt ~18\n", stderr)
            fails += 1
        }
        if GestureMath.chromeDwellStillNeed(dt: 0.125, screenMin: 1080) < 40 {
            fputs("FAIL Ampel-Still 8 fps ≥ 40 px\n", stderr)
            fails += 1
        }
        if GestureMath.chromeDwellStillNeed(dt: 0.016, screenMin: 2880) < 30 {
            fputs("FAIL Ampel-Still 5K ≥ 30 px\n", stderr)
            fails += 1
        }
        if GestureMath.twoPinchAxisChip(.horizontal) != "H" {
            fputs("FAIL Achse H\n", stderr)
            fails += 1
        }
        if GestureMath.twoPinchAxisChip(.vertical) != "V" {
            fputs("FAIL Achse V\n", stderr)
            fails += 1
        }
        if GestureMath.twoPinchAxisChip(.none) != nil {
            fputs("FAIL Achse none tot\n", stderr)
            fails += 1
        }
        if GestureMath.pinch3DSep(thumbZ: 0.12, indexZ: 0.12, palmWidth: 0.10) > 0.05 {
            fputs("FAIL 3D-Sep gleich tot\n", stderr)
            fails += 1
        }
        if GestureMath.pinch3DSep(thumbZ: 0.02, indexZ: 0.14, palmWidth: 0.10) < 1.0 {
            fputs("FAIL 3D-Sep Faust-in-Kamera groß\n", stderr)
            fails += 1
        }
        if !GestureMath.pinch3DVeto(sep: 1.2, closedness2D: 0.70) {
            fputs("FAIL 3D-Veto bei 2D-Pinzette\n", stderr)
            fails += 1
        }
        if !GestureMath.pinchLooksLikePinch(reach: 1.1, index: 0.9, zSep: 1.2) {
            fputs("FAIL echte Pinzette mit z-Rauschen tot\n", stderr)
            fails += 1
        }
        if GestureMath.pinchLooksLikePinch(reach: 0.90, index: 0.9, zSep: 1.2) {
            fputs("FAIL Faust-Projektion 3D-Veto tot\n", stderr)
            fails += 1
        }
        if !GestureMath.pinchLooksLikePinch(reach: 1.1, index: 0.9, zSep: 0.10, approach: 1.4) {
            fputs("FAIL Approach+Reach echte Pinzette tot\n", stderr)
            fails += 1
        }
        if GestureMath.pinchLooksLikePinch(reach: 0.70, index: 0.20, zSep: 0.10, approach: 1.4) {
            fputs("FAIL Approach-Veto Faust-in-Kamera tot\n", stderr)
            fails += 1
        }
        if !GestureMath.pinchLooksLikePinch(reach: 1.1, index: 0.9, zSep: 0.10) {
            fputs("FAIL 3D klein Reach hält\n", stderr)
            fails += 1
        }
        if GestureMath.pinchClosednessNeed(quality: 0.80, start: true) > 0.59 {
            fputs("FAIL Closedness q 0,80 bleibt 0,58\n", stderr)
            fails += 1
        }
        if GestureMath.pinchClosednessNeed(quality: 0.20, start: true) < 0.70 {
            fputs("FAIL Closedness q 0,20 hebt Tor\n", stderr)
            fails += 1
        }
        if GestureMath.pinchStartsGrab(gate: false, closedness: 0.62, quality: 0.20) {
            fputs("FAIL q tot Closedness 0,62 kein Start\n", stderr)
            fails += 1
        }
        if !GestureMath.pinchStartsGrab(gate: false, closedness: 0.62, quality: 0.90) {
            fputs("FAIL q scharf Closedness 0,62 Start\n", stderr)
            fails += 1
        }
        let pred = GestureMath.freezePalmPredict(palm: CGPoint(x: 0.4, y: 0.5), vx: 0.20, vy: 0, dt: 0.125)
        if pred.palm.x <= 0.40 {
            fputs("FAIL Freeze Predict +x\n", stderr)
            fails += 1
        }
        if pred.vx >= 0.20 {
            fputs("FAIL Freeze Vel Decay\n", stderr)
            fails += 1
        }
        if GestureMath.chromeDwellRingWidth(dt: 0.016) > 7 {
            fputs("FAIL Ampel-Ring 24 fps ~6\n", stderr)
            fails += 1
        }
        if GestureMath.chromeDwellRingWidth(dt: 0.125) < 8 {
            fputs("FAIL Ampel-Ring 8 fps dicker\n", stderr)
            fails += 1
        }
        if GestureMath.emptyHandsRecoverPalmJump(
            prev: CGPoint(x: 0.2, y: 0.2),
            next: CGPoint(x: 0.8, y: 0.8),
            palmWidth: 0.12
        ) > 0.50 {
            fputs("FAIL Palm-Sprung dämpft Recover\n", stderr)
            fails += 1
        }
        if GestureMath.emptyHandsRecoverPalmJump(
            prev: CGPoint(x: 0.4, y: 0.4),
            next: CGPoint(x: 0.41, y: 0.40),
            palmWidth: 0.12
        ) < 0.99 {
            fputs("FAIL Palm-Sprung klein voller Gain\n", stderr)
            fails += 1
        }
        if !GestureMath.pullTowardPalmGrow(startW: 0.10, nowW: 0.13) {
            fputs("FAIL Palme wächst = Heranziehen\n", stderr)
            fails += 1
        }
        if GestureMath.pullTowardPalmGrow(startW: 0.10, nowW: 0.11) {
            fputs("FAIL Palme +10 % kein Zug\n", stderr)
            fails += 1
        }
        if GestureMath.fistScharfGrace(dt: 0.016) > 0.23 {
            fputs("FAIL Faust-Grace 24 fps 0,22\n", stderr)
            fails += 1
        }
        if GestureMath.fistScharfGrace(dt: 0.125) < 0.27 {
            fputs("FAIL Faust-Grace 8 fps ≥ 0,27\n", stderr)
            fails += 1
        }
        if GestureMath.pinch3DApproach(thumbZ: 0.12, indexZ: 0.12, palmWidth: 0.10) < 1.1 {
            fputs("FAIL Approach Faust-in-Kamera groß\n", stderr)
            fails += 1
        }
        if GestureMath.pinch3DApproach(thumbZ: 0.01, indexZ: 0.01, palmWidth: 0.10) > 0.20 {
            fputs("FAIL Approach flach tot\n", stderr)
            fails += 1
        }
        if GestureMath.pinch3DVeto(sep: 1.2, closedness2D: 0.70, approach: 0, reach: 1.1) {
            fputs("FAIL Reach hält z-Rauschen\n", stderr)
            fails += 1
        }
        if GestureMath.skeletonFreezeDim(true) > 0.5 {
            fputs("FAIL Freeze dimmt Skeleton\n", stderr)
            fails += 1
        }
        if GestureMath.skeletonFreezeDim(false) < 0.99 {
            fputs("FAIL Live Skeleton voll\n", stderr)
            fails += 1
        }
        let sparkBars = GestureMath.fpsSparkBars(
            [(0.0, 8), (4.0, 24), (7.5, 9)],
            now: 8.0,
            buckets: 8
        )
        if sparkBars.count != 8 {
            fputs("FAIL Spark Bars 8\n", stderr)
            fails += 1
        }
        if sparkBars.allSatisfy({ $0 == 0 }) {
            fputs("FAIL Spark Bars nicht leer\n", stderr)
            fails += 1
        }
        if GestureMath.qualityChip(0.40) != "q tot" {
            fputs("FAIL q tot Chip\n", stderr)
            fails += 1
        }
        if GestureMath.qualityChip(0.80) != nil {
            fputs("FAIL q scharf kein Chip\n", stderr)
            fails += 1
        }
        if GestureMath.pinch3DTrusts(residual: 0.10) == false {
            fputs("FAIL Residual klein vertraut z\n", stderr)
            fails += 1
        }
        if GestureMath.pinch3DTrusts(residual: 0.40) {
            fputs("FAIL Residual groß z tot\n", stderr)
            fails += 1
        }
        if GestureMath.liftSignHolds(previousDz: 0.01, mag: 0.50) != nil {
            fputs("FAIL kleines pred fällt auf Anatomie\n", stderr)
            fails += 1
        }
        if GestureMath.liftSignHolds(previousDz: 0.40, mag: 0.50) != 0.50 {
            fputs("FAIL Lift-Sign hält +\n", stderr)
            fails += 1
        }
        if GestureMath.liftSignHolds(previousDz: -0.40, mag: 0.50) != -0.50 {
            fputs("FAIL Lift-Sign hält −\n", stderr)
            fails += 1
        }
        if GestureMath.cameraFormatScore(width: 1920, height: 1080, maxFps: 8)
            >= GestureMath.cameraFormatScore(width: 1280, height: 720, maxFps: 24) {
            fputs("FAIL 720p24 schlägt 1080p8\n", stderr)
            fails += 1
        }
        if GestureMath.cameraFormatScore(width: 1920, height: 1080, maxFps: 8) < 0 {
            fputs("FAIL 8 fps Format nicht verwerfen\n", stderr)
            fails += 1
        }
        let smoothed = GestureMath.pinchRatioSmooth(prev: 0.50, next: 0.20, dt: 0.125)
        if smoothed <= 0.20 || smoothed >= 0.50 {
            fputs("FAIL One-Euro pinchRatio glättet\n", stderr)
            fails += 1
        }
        if GestureMath.pinchLooksLikePinch(reach: 1.1, index: 0.9, zSep: 0.10, approach: 1.4, residual: 1.0) == false {
            fputs("FAIL Residual tot kein Approach-Veto\n", stderr)
            fails += 1
        }
        if !GestureMath.pinchLooksLikePinch(reach: 1.1, index: 0.9, zSep: 0.10, approach: 1.4) {
            fputs("FAIL Approach+Reach ohne Residual hält\n", stderr)
            fails += 1
        }
        if GestureMath.pinchLooksLikePinch(reach: 0.70, index: 0.20, zSep: 0.10, approach: 1.4) {
            fputs("FAIL Approach-Veto Faust ohne Residual tot\n", stderr)
            fails += 1
        }
        if !GestureMath.pinchStartsGrab(
            gate: true, closedness: 0.20, reach: 1.10, index: 0.70, residual: 1.0
        ) {
            fputs("FAIL Residual tot Start über 2D\n", stderr)
            fails += 1
        }
        if GestureMath.liftSignKeepsPrevious(residual: 0.10) {
            fputs("FAIL Residual klein schreibt z\n", stderr)
            fails += 1
        }
        if !GestureMath.liftSignKeepsPrevious(residual: 0.40) {
            fputs("FAIL Residual Occlusion hält previous\n", stderr)
            fails += 1
        }
        if !GestureMath.clutchIgnoresFreeze(freezeLive: true) {
            fputs("FAIL Clutch Freeze seize tot\n", stderr)
            fails += 1
        }
        if GestureMath.clutchIgnoresFreeze(freezeLive: false) {
            fputs("FAIL Clutch Live seize darf\n", stderr)
            fails += 1
        }
        let two = GestureMath.freezePalmsPredict(
            palms: [
                ("T1", CGPoint(x: 0.2, y: 0.5), 0.20, 0),
                ("T2", CGPoint(x: 0.8, y: 0.5), 0, 0)
            ],
            dt: 0.125
        )
        if two.count != 2 || two[0].palm.x <= 0.20 {
            fputs("FAIL Zwei-Hand T1 Predict +x\n", stderr)
            fails += 1
        }
        if abs(two[1].palm.x - 0.80) > 0.01 {
            fputs("FAIL Zwei-Hand T2 still\n", stderr)
            fails += 1
        }
        if GestureMath.freezeVelChip(dx: 0.02, dy: 0) != "→" {
            fputs("FAIL Freeze-Vel →\n", stderr)
            fails += 1
        }
        if GestureMath.freezeVelChip(dx: 0, dy: 0) != nil {
            fputs("FAIL Freeze-Vel still tot\n", stderr)
            fails += 1
        }
        if GestureMath.pinchFingerContact(thumb: CGPoint(x: 0.40, y: 0.40), index: CGPoint(x: 0.41, y: 0.40), palmWidth: 0.10) < 0.85 {
            fputs("FAIL Finger-Kontakt nah\n", stderr)
            fails += 1
        }
        if GestureMath.pinchFingerContact(thumb: CGPoint(x: 0.20, y: 0.20), index: CGPoint(x: 0.80, y: 0.80), palmWidth: 0.10) > 0.10 {
            fputs("FAIL Finger-Kontakt weit tot\n", stderr)
            fails += 1
        }
        if GestureMath.pinchRatioSmooth(prev: 0.50, next: 0.10, dt: 0.125, quality: 0.40)
            >= GestureMath.pinchRatioSmooth(prev: 0.50, next: 0.10, dt: 0.125, quality: 1) {
            fputs("FAIL q tot dämpft pinchRatio α\n", stderr)
            fails += 1
        }
        if GestureMath.pinch3DVeto(sep: 0.10, closedness2D: 0.70, approach: 1.4, reach: 1.1) {
            fputs("FAIL Approach+Reach kein Veto\n", stderr)
            fails += 1
        }
        if !GestureMath.pinch3DVeto(sep: 0.10, closedness2D: 0.70, approach: 1.4, reach: 0.70) {
            fputs("FAIL Approach Faust-Reach Veto tot\n", stderr)
            fails += 1
        }
        let kal = GestureMath.freezeKalmanPredict(
            palm: CGPoint(x: 0.4, y: 0.5), vx: 0.20, vy: 0, dt: 0.125
        )
        if kal.palm.x <= 0.40 {
            fputs("FAIL Kalman Predict +x\n", stderr)
            fails += 1
        }
        if kal.vx >= 0.20 {
            fputs("FAIL Kalman Reibung\n", stderr)
            fails += 1
        }
        if kal.pPos <= 0.0004 {
            fputs("FAIL Kalman P wächst\n", stderr)
            fails += 1
        }
        let decay = GestureMath.freezePalmPredict(
            palm: CGPoint(x: 0.4, y: 0.5), vx: 0.20, vy: 0, dt: 0.125
        )
        var kx = 0.20 as CGFloat
        var dx = 0.20 as CGFloat
        for _ in 0..<3 {
            kx = GestureMath.freezeKalmanPredict(
                palm: CGPoint(x: 0.4, y: 0.5), vx: kx, vy: 0, dt: 0.125
            ).vx
            dx = GestureMath.freezePalmPredict(
                palm: CGPoint(x: 0.4, y: 0.5), vx: dx, vy: 0, dt: 0.125
            ).vx
        }
        if kx <= dx {
            fputs("FAIL Kalman hält Vel länger als Decay 0,82\n", stderr)
            fails += 1
        }
        let upd = GestureMath.freezeKalmanUpdate(
            pred: CGPoint(x: 0.40, y: 0.50),
            meas: CGPoint(x: 0.80, y: 0.50),
            pPos: 0.04
        )
        if abs(upd.palm.x - 0.80) > abs(0.40 - 0.80) {
            fputs("FAIL Kalman Update zieht zur Messung\n", stderr)
            fails += 1
        }
        if GestureMath.qualityChipHand(id: "T2", quality: 0.40) != "T2 q tot" {
            fputs("FAIL Per-Hand q-Chip T2\n", stderr)
            fails += 1
        }
        if GestureMath.qualityChipHand(id: "T1", quality: 0.90) != nil {
            fputs("FAIL Per-Hand q scharf tot\n", stderr)
            fails += 1
        }
        let chips = GestureMath.qualityChips([("T1", 0.40), ("T2", 0.90)])
        if chips != "T1 q tot" {
            fputs("FAIL qualityChips nur tot\n", stderr)
            fails += 1
        }
        if GestureMath.pointerGainDt(dt: 0.04) < 0.99 {
            fputs("FAIL Pointer-Gain 24 fps = 1\n", stderr)
            fails += 1
        }
        if GestureMath.pointerGainDt(dt: 0.125) >= 0.40 {
            fputs("FAIL Pointer-Gain 8 fps dämpft\n", stderr)
            fails += 1
        }
        if !GestureMath.axHitCacheFresh(cachedAt: 1.00, now: 1.04, dt: 0.04) {
            fputs("FAIL AX-Cache 1 Frame frisch\n", stderr)
            fails += 1
        }
        if GestureMath.axHitCacheFresh(cachedAt: 1.00, now: 1.20, dt: 0.04) {
            fputs("FAIL AX-Cache alt tot\n", stderr)
            fails += 1
        }
        if GestureMath.axHitCacheKey(cursor: CGPoint(x: 12, y: 20), quant: 8)
            != GestureMath.axHitCacheKey(cursor: CGPoint(x: 13, y: 18), quant: 8) {
            fputs("FAIL AX-Cache Key Quant\n", stderr)
            fails += 1
        }
        if GestureMath.palmWidthEMAAlpha(dt: 0.125) >= GestureMath.palmWidthEMAAlpha(dt: 0.04) {
            fputs("FAIL Palm-EMA 8 fps kleineres α\n", stderr)
            fails += 1
        }
        let emaFast = GestureMath.palmWidthEMA(prev: 0.10, next: 0.20, dt: 0.04)
        let emaSlow = GestureMath.palmWidthEMA(prev: 0.10, next: 0.20, dt: 0.125)
        if emaSlow >= emaFast {
            fputs("FAIL Palm-EMA 8 fps glättet\n", stderr)
            fails += 1
        }
        if !GestureMath.cameraFormatRenegotiate(measuredFps: 8) {
            fputs("FAIL Format neu bei 8 fps\n", stderr)
            fails += 1
        }
        if GestureMath.cameraFormatRenegotiate(measuredFps: 24) {
            fputs("FAIL Format 24 fps hält\n", stderr)
            fails += 1
        }
        if GestureMath.cameraFormatRenegotiate(measuredFps: 8, already: true) {
            fputs("FAIL Format already tot\n", stderr)
            fails += 1
        }
        if !GestureMath.axHitCacheFresh(cachedAt: 1.00, now: 1.12, dt: 0.125) {
            fputs("FAIL AX-Cache 8 fps 1 Frame frisch\n", stderr)
            fails += 1
        }
        if GestureMath.pinchDragNeedOf(dt: 0.125) <= GestureMath.pinchDragNeedOf(dt: 0.04) {
            fputs("FAIL Drag-Need 8 fps höher\n", stderr)
            fails += 1
        }
        if !GestureMath.isDrag(palmMovedHW: 0.50, cursorMovedPx: 3, dt: 0.04) {
            fputs("FAIL Drag 24 fps 0,50 HW\n", stderr)
            fails += 1
        }
        if GestureMath.isDrag(palmMovedHW: 0.50, cursorMovedPx: 3, dt: 0.125) {
            fputs("FAIL Drag 8 fps 0,50 HW tot (Klick)\n", stderr)
            fails += 1
        }
        if GestureMath.trackDropoutNeed(dt: 0.125) < 0.35 {
            fputs("FAIL Track-Dropout ≥ 0,35\n", stderr)
            fails += 1
        }
        if GestureMath.cameraFormatScoreMeasured(width: 1920, height: 1080, maxFps: 30, measuredFps: 8)
            >= GestureMath.cameraFormatScoreMeasured(width: 1280, height: 720, maxFps: 24, measuredFps: 8)
        {
            fputs("FAIL gemessen 8 fps 720p vor 1080p\n", stderr)
            fails += 1
        }
        if !GestureMath.cameraFormatRenegotiateRetry(measuredFps: 8, lastAt: 1, now: 4.2) {
            fputs("FAIL Format Retry nach 3 s\n", stderr)
            fails += 1
        }
        if GestureMath.cameraFormatRenegotiateRetry(measuredFps: 8, lastAt: 1, now: 2) {
            fputs("FAIL Format Retry cooldown hält\n", stderr)
            fails += 1
        }
        if GestureMath.cameraFormatRenegotiateRetry(measuredFps: 24, lastAt: 1, now: 10) {
            fputs("FAIL Format Retry 24 fps tot\n", stderr)
            fails += 1
        }
        let q8 = GestureMath.freezeKalmanQ(dt: 0.125)
        let q24 = GestureMath.freezeKalmanQ(dt: 0.04)
        if q8.qPos <= q24.qPos {
            fputs("FAIL Kalman-Q 8 fps größer\n", stderr)
            fails += 1
        }
        if q8.friction >= q24.friction {
            fputs("FAIL Kalman-Reibung 8 fps kleiner\n", stderr)
            fails += 1
        }
        if GestureMath.cameraFormatLadderNext(height: 1080, measuredFps: 8)?.height != 720 {
            fputs("FAIL Leiter 1080p@8 → 720p\n", stderr)
            fails += 1
        }
        if GestureMath.cameraFormatLadderNext(height: 720, measuredFps: 8)?.height != 540 {
            fputs("FAIL Leiter 720p@8 → 960p/540\n", stderr)
            fails += 1
        }
        if GestureMath.cameraFormatLadderNext(height: 360, measuredFps: 8) != nil {
            fputs("FAIL Leiter 640p Ende\n", stderr)
            fails += 1
        }
        if GestureMath.cameraFormatLadderNext(height: 1080, measuredFps: 24) != nil {
            fputs("FAIL Leiter 24 fps tot\n", stderr)
            fails += 1
        }
        if GestureMath.cameraFormatLadderBias(height: 720, currentHeight: 1080, measuredFps: 8)
            <= GestureMath.cameraFormatLadderBias(height: 1080, currentHeight: 1080, measuredFps: 8)
        {
            fputs("FAIL Leiter-Bias 720 vor 1080\n", stderr)
            fails += 1
        }
        var pinch = GestureMath.pinchHoldAdvance(phase: .unseen, closed: true, heldFor: 0, dt: 0.04)
        if pinch.phase != .tentative {
            fputs("FAIL Pinch unseen→tentative\n", stderr)
            fails += 1
        }
        pinch = GestureMath.pinchHoldAdvance(phase: pinch.phase, closed: true, heldFor: pinch.heldFor, dt: 0.10)
        if pinch.phase != .held || !GestureMath.pinchHoldFire(pinch.phase) {
            fputs("FAIL Pinch tentative→held\n", stderr)
            fails += 1
        }
        pinch = GestureMath.pinchHoldAdvance(phase: .held, closed: false, heldFor: 0.4, dt: 0.04)
        if pinch.phase != .released {
            fputs("FAIL Pinch held→released\n", stderr)
            fails += 1
        }
        pinch = GestureMath.pinchHoldAdvance(phase: .released, closed: false, heldFor: 0.04, dt: 0.20)
        if pinch.phase != .unseen {
            fputs("FAIL Pinch released→unseen\n", stderr)
            fails += 1
        }
        if GestureMath.pointerWarpAllowed(axTrusted: false) {
            fputs("FAIL Warp ohne AX tot\n", stderr)
            fails += 1
        }
        if !GestureMath.pointerWarpAllowed(axTrusted: true) {
            fputs("FAIL Warp mit AX\n", stderr)
            fails += 1
        }
        let lerp0 = GestureMath.hudLerpT(prevAt: 1.0, nextAt: 1.125, now: 1.125, freeze: false)
        if abs(lerp0 - 0) > 0.02 {
            fputs("FAIL HUD-Lerp t=0 am Sample\n", stderr)
            fails += 1
        }
        let lerp1 = GestureMath.hudLerpT(prevAt: 1.0, nextAt: 1.125, now: 1.25, freeze: false)
        if abs(lerp1 - 1) > 0.02 {
            fputs("FAIL HUD-Lerp t=1 nach Intervall\n", stderr)
            fails += 1
        }
        let freezeT = GestureMath.hudLerpT(prevAt: 1.0, nextAt: 1.125, now: 1.13, freeze: true)
        if freezeT != 1 {
            fputs("FAIL HUD-Lerp Freeze snap\n", stderr)
            fails += 1
        }
        let mid = GestureMath.hudLerpPoint(prev: CGPoint(x: 0, y: 0), next: CGPoint(x: 10, y: 20), t: 0.5)
        if abs(mid.x - 5) > 0.01 || abs(mid.y - 10) > 0.01 {
            fputs("FAIL HUD-Lerp Punkt Mitte\n", stderr)
            fails += 1
        }
        var engine = GestureMath.pinchHoldAdvance(phase: .unseen, closed: true, heldFor: 0, dt: 0.04)
        if GestureMath.pinchHoldFire(engine.phase) {
            fputs("FAIL Engine Pinch Fire nicht in tentative\n", stderr)
            fails += 1
        }
        engine = GestureMath.pinchHoldAdvance(phase: engine.phase, closed: true, heldFor: engine.heldFor, dt: 0.125)
        if !GestureMath.pinchHoldFire(engine.phase) {
            fputs("FAIL Engine Pinch Fire nach einem Continuity-Frame\n", stderr)
            fails += 1
        }
        if !GestureMath.pinchHoldClosed(.tentative) || GestureMath.pinchHoldFire(.tentative) {
            fputs("FAIL Engine Tentative closed ohne Fire\n", stderr)
            fails += 1
        }

        if fails > 0 {
            fputs("\(fails) Tests fehlgeschlagen\n", stderr)
            exit(1)
        }
        print("CoordTests OK")
    }
}

import CoreGraphics
import Foundation

enum TwoPinchAxis: Equatable {
    case none, horizontal, vertical
}

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

    /// 1 am Rand (äußere `band`), 0 innen. Kalibrierter Zeiger: außen absolut, innen relativ.
    static func edgeAbsoluteWeight(u: CGFloat, v: CGFloat, band: CGFloat = 0.15) -> CGFloat {
        let b = min(0.45, max(0.04, band))
        func edge(_ t: CGFloat) -> CGFloat {
            if t <= b { return 1 - t / b }
            if t >= 1 - b { return (t - (1 - b)) / b }
            return 0
        }
        return min(1, max(edge(u), edge(v)))
    }

    /// Punkt in Rect → [0,1]². Union-UV für Ecken-Ruhezonen.
    static func unitInRect(_ p: CGPoint, rect: CGRect) -> CGPoint {
        let w = max(1, rect.width)
        let h = max(1, rect.height)
        return CGPoint(x: (p.x - rect.minX) / w, y: (p.y - rect.minY) / h)
    }

    /// Trackpad-Beschleunigung: Mini-Zucken bleibt langsam, Wisch wird schneller.
    static func pointerAccelScale(magnitude: CGFloat) -> CGFloat {
        let mag = max(0, magnitude)
        let t = min(1, mag / 0.038)
        return 0.48 + 1.42 * t * t
    }

    static func nearUnitCenter(u: CGFloat, v: CGFloat, radius: CGFloat = 0.22) -> Bool {
        hypot(u - 0.5, v - 0.5) < radius
    }

    /// 3×3 zeilenweise. Inverse oder nil.
    static func invert3x3(_ H: [CGFloat]) -> [CGFloat]? {
        guard H.count == 9 else { return nil }
        let a = H[0], b = H[1], c = H[2]
        let d = H[3], e = H[4], f = H[5]
        let g = H[6], h = H[7], i = H[8]
        let A = e * i - f * h
        let B = f * g - d * i
        let C = d * h - e * g
        let det = a * A + b * B + c * C
        guard abs(det) > 1e-12 else { return nil }
        let s = 1 / det
        return [
            A * s, (c * h - b * i) * s, (b * f - c * e) * s,
            B * s, (a * i - c * g) * s, (c * d - a * f) * s,
            C * s, (b * g - a * h) * s, (a * e - b * d) * s
        ]
    }

    static func apply3x3(_ H: [CGFloat], _ p: CGPoint) -> CGPoint? {
        guard H.count == 9 else { return nil }
        let w = H[6] * p.x + H[7] * p.y + H[8]
        guard abs(w) > 1e-8 else { return nil }
        return CGPoint(
            x: (H[0] * p.x + H[1] * p.y + H[2]) / w,
            y: (H[3] * p.x + H[4] * p.y + H[5]) / w
        )
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
    /// Nach echtem Fensterzug: Loslassen ist Ablegen, kein Dock/Minimize, außer der Ruck ist klar.
    static let flingAfterDragMul: CGFloat = 2.4
    static let flingAfterDragDist: CGFloat = 1.65
    static let palmDead: CGFloat = 0.012
    static let palmHighpass: CGFloat = 0.08
    static let deadMan: TimeInterval = 8.0
    static let killGrace: TimeInterval = 0.14
    /// Zwei offene Hände müssen still und getrennt halten — 0,80 s hat Klick/Swipe mitgetötet.
    static let killHold: TimeInterval = 1.35
    static let killPalmStill: CGFloat = 0.14
    /// Körperpose: Vision unbekannt → lose (0,72). Vision widerspricht → nur klarer Sieger (0,50).
    static let bodyVoteLoose: Double = 0.72
    static let bodyVoteStrict: Double = 0.50
    static let swipeOpenNeed = 3
    static let thumbsHold: TimeInterval = 0.70
    /// Sitzung 12:59:50: Öffnen nach Pinzette wurde zum Wischen, Rückkehr zur Gegenrichtung.
    static let swipeMuteAfterPinch: TimeInterval = 0.45
    static let swipeReverseLock: TimeInterval = 0.90
    /// 0,18 Handbreiten war Palm-Zittern. Klick braucht eine stillstehende Pinzette.
    static let pinchDragNeed: CGFloat = 0.45
    static let pinchClickMinHold: TimeInterval = 0.05
    static let pinchClickMaxHold: TimeInterval = 0.90
    static let pinchClickStillPx: CGFloat = 22
    static let pinchLockMiss: TimeInterval = 0.22
    /// Nach Gate-Auf: kein Folge-Klick aus dem Öffnen. Continuity 8 fps ≈ 1 Frame.
    static let pinchReleaseDead: TimeInterval = 0.12
    static let twoPinchConfirm: TimeInterval = 0.12
    static let twoPinchClosed: CGFloat = 0.55
    static let twoPinchScaleNeed: CGFloat = 0.55
    static let twoPinchReverseMul: CGFloat = 1.8
    static let peaceHold: TimeInterval = 1.10
    static let chromeMagnet: CGFloat = 48
    static let chromeLoupe: CGFloat = 168
    static let chromeSpreadGap: CGFloat = 118
    static let chromeHit: CGFloat = 80
    static let chromeDwellHold: TimeInterval = 0.55
    /// Ampel nur bei stillstehendem Cursor — sonst Schließen beim Zielen.
    static let chromeDwellStillPx: CGFloat = 18
    static let swipeMinDx: CGFloat = 0.55
    static let swipeAxis: CGFloat = 1.15
    static let swipeMinSpeed: CGFloat = 1.8
    static let swipeMinDt: TimeInterval = 0.06
    static let swipeMaxDt: TimeInterval = 0.55
    static let keyboardDwell: TimeInterval = 0.22
    static let keyboardRepeat: TimeInterval = 0.28
    static let calibMinArea: CGFloat = 0.012
    static let calibCornerSep: CGFloat = 0.06
    static let hybridBand: CGFloat = 0.15
    static let clutchOwnRadius: CGFloat = 48
    static let clutchOwnWindow: TimeInterval = 0.12
    /// Idle-Jiggler / 1-px Maus-Ticks. 0,5 hat Trackpads und eigene CGEvents durchgelassen.
    static let clutchJiggle: CGFloat = 1.2
    /// Zwei Kameras: gemappte Zeiger > so viele Pixel auseinander = Winkel-Unco, Lead gewinnt.
    static let rigDisagreePx: CGFloat = 140
    static let rigCoverEnter: Double = 0.18
    static let rigCoverExit: Double = 0.12
    /// Continuity 125 ms darf nicht auf 80 ms gekappt werden — Filter/Vel lügen sonst.
    static let sampleDtCap: TimeInterval = 0.20
    /// Palm-Y fällt um so viel (Vision-[0,1]) = zu sich ziehen. Nicht Mittelfinger-Spannweite.
    static let pullToward: CGFloat = 0.11
    /// Zeigen so lange unten, bevor die Luft-Tastatur aufgeht. 0,40 s feuerte beim Zielen.
    static let airKeyboardPointHold: TimeInterval = 0.85
    /// Quartz-v ≥ dieser Wert (unten) darf die Tastatur rufen. Mitte/oben = Fenster.
    static let airKeyboardBottom: CGFloat = 0.72
    /// 24 fps Pinch-Close-Vel. Continuity weicher — ein Frame ist der ganze Close.
    static let pinchCloseVel24: CGFloat = -1.6
    static let pinchCloseVel8: CGFloat = -0.90
    static let pinchOpenVel24: CGFloat = -0.4
    static let pinchOpenVel8: CGFloat = -0.15
    /// Faust: Spitzen nah an der Palme. Pinzette: Daumen+Zeigefinger weg vom Handgelenk.
    static let pinchReachNeed: CGFloat = 0.88
    static let pinchIndexNeed: Double = 0.38

    static func sampleDt(now: TimeInterval, last: TimeInterval, cap: TimeInterval = sampleDtCap) -> TimeInterval {
        last <= 0 ? 0.04 : min(cap, max(0.008, now - last))
    }

    static func pinchCloseVel(dt: TimeInterval) -> CGFloat {
        dt >= 0.10 ? pinchCloseVel8 : pinchCloseVel24
    }

    static func pinchOpenVel(dt: TimeInterval) -> CGFloat {
        dt >= 0.10 ? pinchOpenVel8 : pinchOpenVel24
    }

    /// 24 fps bleibt 120 ms. 8 fps braucht ≥ 2 Frames, sonst ist das Fling-Fenster leer.
    static func flingWindowLen(medianDt: TimeInterval) -> TimeInterval {
        let dt = max(0.04, medianDt)
        return min(0.36, max(flingWindow, dt * 2.5))
    }

    /// Steuerhand: Lock-ID zuerst, dann L/R. Chirality-Flip teleportiert sonst den Cursor.
    static func preferredID(
        locked: String?,
        liveIDs: [String],
        leftID: String?,
        rightID: String?,
        leftHanded: Bool
    ) -> String? {
        if let locked, liveIDs.contains(locked) { return locked }
        if leftHanded { return leftID ?? rightID ?? liveIDs.first }
        return rightID ?? leftID ?? liveIDs.first
    }

    /// Ein Fehlframe hält die Lock-ID. Sonst Teleport auf L/R.
    static func preferredHoldID(
        locked: String?,
        liveIDs: [String],
        missHeld: Bool,
        leftID: String?,
        rightID: String?,
        leftHanded: Bool
    ) -> String? {
        if let locked, liveIDs.contains(locked) { return locked }
        if let locked, missHeld { return locked }
        return preferredID(locked: nil, liveIDs: liveIDs, leftID: leftID, rightID: rightID, leftHanded: leftHanded)
    }

    /// Miss-Dauer auf dem Tick-Takt (`now`), nicht `CACurrentMediaTime`.
    /// testMode / Continuity-Dropout lügen sonst um Hunderte Millisekunden.
    static func missHeld(now: TimeInterval, since: TimeInterval?, window: TimeInterval = pinchLockMiss) -> Bool {
        guard let since else { return false }
        return now - since < window
    }

    /// HUD-Chip wenn preferredHold / pinchActor einen Fehlframe friert.
    static func lockFreezeLabel(locked: String?, missHeld: Bool) -> String? {
        guard missHeld, let locked, !locked.isEmpty else { return nil }
        return "\(locked) freeze"
    }

    /// Scroll nur mit genau einer offenen Hand. Zwei offene gehören dem Not-Aus.
    static func scrollAllowed(openPalms: Int, pinchHeld: Bool, twoPinch: Bool = false) -> Bool {
        if pinchHeld || twoPinch { return false }
        return openPalms == 1
    }

    static func pinchReleaseBlocks(now: TimeInterval, releasedAt: TimeInterval?) -> Bool {
        pinchReleaseBlocks(now: now, releasedAt: releasedAt, dt: 0.016)
    }

    /// 24 fps bleibt 120 ms. 8 fps sonst ein Frame tot — Folge-Klick nach Dropout.
    static func pinchReleaseNeed(dt: TimeInterval) -> TimeInterval {
        max(pinchReleaseDead, min(0.32, max(0.008, dt) * 1.6))
    }

    /// 24 fps 50 ms. 8 fps ≥ 1,4 Frames — Jitter-Pinzette ist kein Klick.
    static func pinchClickMinNeed(dt: TimeInterval) -> TimeInterval {
        max(pinchClickMinHold, min(0.22, max(0.008, dt) * 1.4))
    }

    /// 24 fps 22 px. 8 fps ein Landmark-Tick sonst „gehalten — kein Zug“.
    static func pinchClickStillNeed(dt: TimeInterval) -> CGFloat {
        max(pinchClickStillPx, min(56, CGFloat(max(0.008, dt) * 380)))
    }

    /// 24 fps 120 ms. 8 fps zwei Frames, sonst ein Tick startet Zoom.
    static func twoPinchConfirmNeed(dt: TimeInterval) -> TimeInterval {
        max(twoPinchConfirm, min(0.32, max(0.008, dt) * 1.6))
    }

    /// 24 fps 120 ms. 8 fps sonst Tastatur am Vorbeifliegen.
    static func keyboardDwellNeed(dt: TimeInterval) -> TimeInterval {
        max(keyboardDwell, min(0.40, max(0.008, dt) * 2.4))
    }

    /// 24 fps bleibt 0,55 s. 8 fps sonst Ampel nach 4 Frames — Zielen ist kein Schließen.
    static func chromeDwellNeed(dt: TimeInterval) -> TimeInterval {
        max(chromeDwellHold, min(0.90, max(0.008, dt) * 5.5))
    }

    /// 18 px bei 24 fps. Continuity 8 fps × Gain 1,6: ein Landmark-Tick ist 40–80 px.
    /// 5K 5120: 18 px ist Zielen tot. Floor in px, Skala aus dt und Schirmkante.
    static func chromeDwellStillNeed(dt: TimeInterval, screenMin: CGFloat = 1080) -> CGFloat {
        let noise = CGFloat(max(0.008, dt) * 420)
        let wide = max(0, screenMin) * 0.012
        return max(chromeDwellStillPx, min(96, max(noise, wide)))
    }

    static func twoPinchAxisChip(_ axis: TwoPinchAxis) -> String? {
        switch axis {
        case .horizontal: return "H"
        case .vertical: return "V"
        case .none: return nil
        }
    }

    /// Faust in die Kamera: 2D-Reach lügt (Spitzen überlappen). z-Abstand hält Pinzette tot.
    static func pinch3DSep(thumbZ: CGFloat, indexZ: CGFloat, palmWidth: CGFloat) -> CGFloat {
        abs(thumbZ - indexZ) / max(0.03, palmWidth)
    }

    static func pinch3DVeto(sep: CGFloat, closedness2D: Double, need: CGFloat = 0.55, approach: CGFloat = 0, reach: CGFloat = 0.5) -> Bool {
        if closedness2D < 0.50 { return false }
        let reachOk = reach >= pinchReachNeed + 0.15
        // Faust-in-Kamera: 2D-Reach lügt. Echte Pinzette hat Reach — Approach allein tot.
        if approach >= need * 1.15 && !reachOk { return true }
        if reachOk { return false }
        return sep >= need
    }

    /// Faust in die Kamera: beide Spitzen gleich tief, Sep tot. Mittel |z| / Palme.
    static func pinch3DApproach(thumbZ: CGFloat, indexZ: CGFloat, palmWidth: CGFloat) -> CGFloat {
        ((abs(thumbZ) + abs(indexZ)) * 0.5) / max(0.03, palmWidth)
    }

    /// Daumen–Index in Palmenbreiten → 1 Kontakt, 0 offen. Closedness-Skalar allein jittert bei 8 fps.
    static func pinchFingerContact(thumb: CGPoint, index: CGPoint, palmWidth: CGFloat) -> CGFloat {
        let d = hypot(thumb.x - index.x, thumb.y - index.y) / max(0.03, palmWidth)
        return max(0, min(1, (0.55 - d) / 0.40))
    }

    /// Lift-Residual hoch: z ist Rauschen. Veto/Approach sonst tot-Pinzette oder Faust-Klick.
    static func pinch3DTrusts(residual: CGFloat, floor: CGFloat = 0.22) -> Bool {
        residual < floor
    }

    /// Continuity oft nur 8 fps @ 1080p. 720p@24 schlägt 1080p@8. Unter 24 fps nicht verwerfen.
    static func cameraFormatScore(width: Double, height: Double, maxFps: Double) -> Double {
        guard width >= 640, height >= 360, width <= 1920, height <= 1088 else { return -1 }
        let fps = max(0, maxFps)
        let fpsTerm = min(fps, 30) * 8
        let near1080 = 1.0 - min(abs(height - 1080) / 1080, 1)
        let near720 = 1.0 - min(abs(height - 720) / 720, 1)
        let resTerm: Double
        if fps >= 24 {
            resTerm = near1080 * 48 + near720 * 12
        } else {
            resTerm = near720 * 36 + near1080 * 8
        }
        return fpsTerm + resTerm
    }

    /// q < 0,55: Landmark tot. HUD sonst unsichtbare tot-Pinzette.
    static func qualityChip(_ quality: Double, floor: Double = 0.55) -> String? {
        quality < floor ? "q tot" : nil
    }

    /// qualityChip 1.6.37 nur Actor. Zweite Hand tot unsichtbar.
    static func qualityChipHand(id: String, quality: Double, floor: Double = 0.55) -> String? {
        guard let chip = qualityChip(quality, floor: floor) else { return nil }
        let short = id.count <= 3 ? id : String(id.prefix(2))
        return "\(short) \(chip)"
    }

    static func qualityChips(_ hands: [(id: String, quality: Double)], floor: Double = 0.55) -> String {
        hands.compactMap { qualityChipHand(id: $0.id, quality: $0.quality, floor: floor) }.joined(separator: " · ")
    }

    /// Continuity-Tick sonst Teleport: Gain × (ref/dt). 24 fps = 1, 8 fps ≈ 0,32.
    static func pointerGainDt(dt: TimeInterval, ref: TimeInterval = 0.04) -> CGFloat {
        let t = max(0.008, min(0.20, dt <= 0 ? ref : dt))
        let r = max(0.008, ref)
        return CGFloat(min(1, r / t))
    }

    /// UV bleibt. Gain in pt: Retina-Scale sonst Teleport (CGEvent-Echo in px).
    static func pointerGainScaled(gain: CGFloat, scale: CGFloat) -> CGFloat {
        gain / backingScaleClamped(scale)
    }

    /// 1× bleibt 1, Retina 2–3. Sidecar 1× darf 5K-Scale nicht erben.
    static func backingScaleClamped(_ scale: CGFloat) -> CGFloat {
        max(1, min(3, scale))
    }

    /// UV-Totzone wächst mit Scale — sonst leckt Jitter als CGEvent-Echo.
    static func deadzoneScaled(dead: CGFloat, scale: CGFloat) -> CGFloat {
        dead * backingScaleClamped(scale)
    }

    /// Fest+still klickt früher. Wackel-Pinzette blockt trotz Dauer.
    static func clickEnergy(
        closedness: Double,
        palmMovedHW: CGFloat,
        held: TimeInterval,
        dt: TimeInterval
    ) -> Double {
        let drag = Double(max(0.01, pinchDragNeedOf(dt: dt)))
        let still = max(0, 1 - Double(palmMovedHW) / drag)
        let hold = min(1, held / max(0.04, pinchClickMinNeed(dt: dt)))
        let close = max(0, min(1, closedness))
        return max(0, min(1, close * still * max(0.45, hold)))
    }

    /// Palmen-Jitter RMS. Continuity 8 Hz: Rauschen ≠ Intent.
    static func jitterRms(_ samples: [CGFloat]) -> CGFloat {
        let n = samples.count
        guard n >= 2 else { return 0 }
        let mean = samples.reduce(0, +) / CGFloat(n)
        var acc: CGFloat = 0
        for s in samples {
            let d = s - mean
            acc += d * d
        }
        return sqrt(max(0, acc / CGFloat(n)))
    }

    /// Gain fällt bei Jitter. Intent (niedrig RMS) bleibt voll.
    static func pointerGainAdaptive(
        gain: CGFloat,
        jitterRms: CGFloat,
        lo: CGFloat = 0.004,
        hi: CGFloat = 0.028
    ) -> CGFloat {
        let span = max(0.001, hi - lo)
        let t = min(1, max(0, (jitterRms - lo) / span))
        return gain * (1 - 0.72 * t)
    }

    /// HUD nicht in Screenshot / Bildschirmaufnahme.
    static func hudSharingExcluded() -> Bool { true }

    /// Gain am Rand 0,35. Hartes Clamp lässt den Cursor am Bezel sterben.
    static func edgeResistance(
        localX: CGFloat,
        localY: CGFloat,
        width: CGFloat,
        height: CGFloat,
        band: CGFloat = 56
    ) -> CGFloat {
        let b = max(8, band)
        let dx = min(localX, width - localX)
        let dy = min(localY, height - localY)
        let d = min(dx, dy)
        if d >= b { return 1 }
        return 0.35 + 0.65 * max(0, d / b)
    }

    /// Start auf einem Schirm, Vorschlag in der Lücke → nicht durch den Bezel warpen.
    static func displayGapWarp(fromOnScreen: Bool, proposedOnScreen: Bool) -> Bool {
        fromOnScreen && !proposedOnScreen
    }

    /// One-Euro α. Höherer Cutoff = weniger Glättung.
    static func oneEuroAlpha(dt: TimeInterval, cutoff: Double) -> CGFloat {
        let te = max(0.001, dt)
        let tau = 1.0 / (2 * Double.pi * max(0.05, cutoff))
        return CGFloat(1.0 / (1.0 + tau / te))
    }

    /// min-cutoff fällt mit Jitter — 8 Hz Rauschen glättet, Intent bleibt.
    static func oneEuroMinCutoff(jitterRms: CGFloat, base: Double = 1.15, k: Double = 28) -> Double {
        let j = max(0, Double(jitterRms))
        return max(0.35, base / (1 + k * j))
    }

    static func oneEuroFilter(
        prev: CGFloat,
        sample: CGFloat,
        dt: TimeInterval,
        minCutoff: Double,
        dPrev: CGFloat,
        beta: Double = 0.007
    ) -> (value: CGFloat, deriv: CGFloat) {
        let te = CGFloat(max(0.001, dt))
        let dx = (sample - prev) / te
        let aD = oneEuroAlpha(dt: dt, cutoff: 1.0)
        let hatD = aD * dx + (1 - aD) * dPrev
        let fc = minCutoff + beta * Double(abs(hatD))
        let a = oneEuroAlpha(dt: dt, cutoff: fc)
        return (a * sample + (1 - a) * prev, hatD)
    }

    /// Hop nur wenn der Vorschlag ≥ need pt im anderen Schirm sitzt.
    static func bezelHopNeed() -> CGFloat { 80 }

    static func bezelHopAllows(proposed: CGPoint, otherFrame: CGRect, need: CGFloat = 80) -> Bool {
        let n = max(8, need)
        guard otherFrame.width > 2 * n, otherFrame.height > 2 * n else { return false }
        return proposed.x >= otherFrame.minX + n
            && proposed.x <= otherFrame.maxX - n
            && proposed.y >= otherFrame.minY + n
            && proposed.y <= otherFrame.maxY - n
    }

    /// Homographie driftet an der Naht. 20 Hops → Recalib-Chip, nicht Wipe.
    static func bezelHopCountNeed() -> Int { 20 }

    static func bezelHopRecalib(count: Int, need: Int = 20) -> Bool {
        count >= need
    }

    static func bezelHopChip(count: Int, need: Int = 20) -> String? {
        count >= need ? "RECAL · \(need) hops" : nil
    }

    /// 2 s still → Clutch, nicht Kill. Continuity-Drift sonst Klick.
    static func palmDeadmanNeed() -> TimeInterval { 2.0 }

    static func palmDeadmanClutch(stillFor: TimeInterval, need: TimeInterval = 2) -> Bool {
        stillFor >= need
    }

    static func palmDeadmanStill(delta: CGFloat, dead: CGFloat) -> Bool {
        delta < max(0.0004, dead * 1.15)
    }

    /// Kaltstart: Continuity claimed 1080@30, liefert 8. 720@24 vor 1080, ohne Messung.
    static func cameraFormatColdStartBias(height: Double, currentHeight: Double, role: String) -> Double {
        let phone = role == "phone" || role == "continuity"
        guard phone else { return 0 }
        if height >= 1000 { return -90 }
        if abs(height - 720) < 80 { return 110 }
        if currentHeight >= 700, currentHeight < 1000, abs(height - currentHeight) < 40 { return 40 }
        return 0
    }

    /// 8 Hz: Sample ist 1 Frame hinter der Palme. Predict aus geglätteter Vel, Cap gegen Teleport.
    static func pointerPredictDt(_ dt: TimeInterval) -> CGFloat {
        CGFloat(max(0.04, min(0.20, dt)))
    }

    static func pointerPredictCap(_ clutch: Bool = false, screenH: CGFloat = 0) -> CGFloat {
        if clutch { return 0 }
        return 48
    }

    /// Deadman/Zwei-Hand: Predict aus. Sonst coastet One-Euro-Deriv 48 pt trotz dx=0.
    static func pointerPredictArmed(deadman: Bool, clutch: Bool) -> Bool {
        !deadman && !clutch
    }

    static func pointerPredict(sample: CGFloat, vel: CGFloat, dt: TimeInterval, cap: CGFloat = 48) -> CGFloat {
        let t = pointerPredictDt(dt)
        let d = vel * t
        let c = max(1, cap)
        let clamped = max(-c, min(c, d))
        return sample + clamped
    }

    static func pointerPredictPoint(sample: CGPoint, vel: CGPoint, dt: TimeInterval, cap: CGFloat = 48) -> CGPoint {
        CGPoint(
            x: pointerPredict(sample: sample.x, vel: vel.x, dt: dt, cap: cap),
            y: pointerPredict(sample: sample.y, vel: vel.y, dt: dt, cap: cap)
        )
    }

    /// Zweite Palme, kein Zwei-Pinch → Actor clutcht. Sonst stiehlt die zweite Hand den Klick.
    static func twoHandClutch(livePalms: Int, twoPinch: Bool) -> Bool {
        livePalms >= 2 && !twoPinch
    }

    /// Stage Manager / Dock / Menüleiste: Cursor bleibt im visibleFrame.
    static func stageManagerOffspace(proposed: CGPoint, visible: CGRect, pad: CGFloat = 8) -> Bool {
        proposed.x < visible.minX - pad
            || proposed.x > visible.maxX + pad
            || proposed.y < visible.minY - pad
            || proposed.y > visible.maxY + pad
    }

    static func stageManagerClamp(proposed: CGPoint, visible: CGRect) -> CGPoint {
        guard visible.width > 8, visible.height > 8 else { return proposed }
        return CGPoint(
            x: min(max(proposed.x, visible.minX + 2), visible.maxX - 2),
            y: min(max(proposed.y, visible.minY + 2), visible.maxY - 2)
        )
    }

    /// Hand-Box aus Palme. VNTrack fehlt — IoU hält die Slot-ID zwischen 8-Hz-Detect.
    static func handBoxFromPalm(palm: CGPoint, width: CGFloat) -> CGRect {
        let w = max(0.04, width)
        return CGRect(x: palm.x - w * 0.55, y: palm.y - w * 0.70, width: w * 1.10, height: w * 1.40)
    }

    static func handBoxIoU(_ a: CGRect, _ b: CGRect) -> Double {
        let inter = a.intersection(b)
        if inter.isNull || inter.isEmpty { return 0 }
        let u = a.width * a.height + b.width * b.height - inter.width * inter.height
        guard u > 1e-9 else { return 0 }
        return Double(inter.width * inter.height / u)
    }

    static func handBoxTrackKeeps(track: CGRect, detect: CGRect, floor: Double = 0.28) -> Bool {
        guard track.width > 0.01, track.height > 0.01 else { return false }
        return handBoxIoU(track, detect) >= floor
    }

    static func handBoxTrackStep(prev: CGRect, detect: CGRect) -> CGRect {
        if prev.width < 0.01 || prev.height < 0.01 { return detect }
        let iou = handBoxIoU(prev, detect)
        if iou < 0.10 { return detect }
        let a: CGFloat = iou >= 0.28 ? 0.42 : 0.78
        return CGRect(
            x: prev.minX + a * (detect.minX - prev.minX),
            y: prev.minY + a * (detect.minY - prev.minY),
            width: prev.width + a * (detect.width - prev.width),
            height: prev.height + a * (detect.height - prev.height)
        )
    }

    /// 90°-Raster für Homographie-Cache. Nudge ohne Store-Wipe.
    static func spaceMapRotationKey(_ r: Double) -> Int {
        var a = r.truncatingRemainder(dividingBy: 360)
        if a < 0 { a += 360 }
        let q = Int((a / 90.0).rounded()) % 4
        return ((q + 4) % 4) * 90
    }

    /// AX-Hit 1 Frame. Continuity 8 fps sonst hitTest jeden Tick.
    static func axHitCacheFresh(cachedAt: TimeInterval, now: TimeInterval, dt: TimeInterval) -> Bool {
        guard cachedAt > 0, now >= cachedAt else { return false }
        return now - cachedAt < max(0.04, dt) * 1.15
    }

    static func axHitCacheKey(cursor: CGPoint, quant: CGFloat = 8) -> String {
        let q = max(1, quant)
        let x = Int((cursor.x / q).rounded())
        let y = Int((cursor.y / q).rounded())
        return "\(x):\(y)"
    }

    /// Gemessene fps < 12 trotz cameraFormatScore → Format neu verhandeln.
    static func cameraFormatRenegotiate(measuredFps: Double, floor: Double = 12, already: Bool = false) -> Bool {
        !already && measuredFps > 0 && measuredFps < floor
    }

    /// Continuity meldet maxFps 30, liefert 8. Score ohne Messung bleibt 1080p.
    static func cameraFormatScoreMeasured(
        width: Double,
        height: Double,
        maxFps: Double,
        measuredFps: Double
    ) -> Double {
        var s = cameraFormatScore(width: width, height: height, maxFps: maxFps)
        if measuredFps > 0 && measuredFps < 12 {
            s -= (12 - measuredFps) * (height >= 1000 ? 22 : 6)
        }
        return s
    }

    /// Einmal reicht nicht — zweiter Drop bleibt 8 fps. Nach cooldown erneut.
    static func cameraFormatRenegotiateRetry(
        measuredFps: Double,
        lastAt: TimeInterval,
        now: TimeInterval,
        cooldown: TimeInterval = 3,
        floor: Double = 12
    ) -> Bool {
        measuredFps > 0 && measuredFps < floor && lastAt > 0 && now - lastAt >= cooldown
    }

    /// 720p@24 → 960p@15 → 640p@30. Nicht denselben 1080p@8-Retry.
    struct CameraFormatStep: Equatable {
        var width: Double
        var height: Double
        var fps: Double
    }

    static let cameraFormatLadder: [CameraFormatStep] = [
        CameraFormatStep(width: 1280, height: 720, fps: 24),
        CameraFormatStep(width: 960, height: 540, fps: 15),
        CameraFormatStep(width: 640, height: 360, fps: 30)
    ]

    /// 1080p = −1, 720p = 0, 540p = 1, 360p = 2.
    static func cameraFormatLadderIndex(height: Double) -> Int {
        if height >= 1000 { return -1 }
        if height >= 700 { return 0 }
        if height >= 500 { return 1 }
        return 2
    }

    static func cameraFormatLadderNext(height: Double, measuredFps: Double) -> CameraFormatStep? {
        guard measuredFps > 0, measuredFps < 12 else { return nil }
        let next = cameraFormatLadderIndex(height: height) + 1
        guard next >= 0, next < cameraFormatLadder.count else { return nil }
        return cameraFormatLadder[next]
    }

    /// bestFormat: Leiter-Höhe +90, aktuelle Höhe −50 wenn gemessen tot.
    static func cameraFormatLadderBias(height: Double, currentHeight: Double, measuredFps: Double) -> Double {
        guard let step = cameraFormatLadderNext(height: currentHeight, measuredFps: measuredFps) else { return 0 }
        var b = 0.0
        if abs(height - step.height) < 80 { b += 90 }
        if currentHeight > 0, abs(height - currentHeight) < 40 { b -= 50 }
        return b
    }

    /// Continuity uniqueID flackert. Homographie nur bei echtem Cam-Wechsel.
    static func cameraNameBare(_ name: String) -> String {
        let t = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let r = t.range(of: " · ") { return String(t[..<r.lowerBound]) }
        return t
    }

    static func cameraIDSticky(prev: String, next: String, prevName: String = "", nextName: String = "", prevRole: String = "", nextRole: String = "") -> Bool {
        if prev.isEmpty || next.isEmpty { return false }
        if prev == next { return true }
        if prevRole == "mac" || nextRole == "mac" { return false }
        let a = cameraNameBare(prevName)
        let b = cameraNameBare(nextName)
        if a.isEmpty || a != b { return false }
        if !prevRole.isEmpty && !nextRole.isEmpty && prevRole != nextRole { return false }
        return true
    }

    static func cameraIDHomographyResets(
        prev: String,
        next: String,
        prevName: String = "",
        nextName: String = "",
        prevRole: String = "",
        nextRole: String = ""
    ) -> Bool {
        if prev.isEmpty || next.isEmpty { return false }
        return !cameraIDSticky(prev: prev, next: next, prevName: prevName, nextName: nextName, prevRole: prevRole, nextRole: nextRole)
    }

    /// Leiter nur bei echtem Cam-Wechsel, nicht uniqueID-Reconnect.
    static func lastFormatHeightResets(
        prevID: String,
        nextID: String,
        prevName: String = "",
        nextName: String = "",
        prevRole: String = "",
        nextRole: String = ""
    ) -> Bool {
        if prevID.isEmpty || nextID.isEmpty { return false }
        if prevID == nextID { return false }
        return !cameraIDSticky(
            prev: prevID, next: nextID,
            prevName: prevName, nextName: nextName,
            prevRole: prevRole, nextRole: nextRole
        )
    }

    /// Continuity Reconnect: uniqueID tot, Name bleibt. Sonst fällt preferredDevice auf Built-in.
    static func cameraPreferredID(
        preferredID: String,
        preferredName: String,
        devices: [(id: String, name: String)]
    ) -> String? {
        if !preferredID.isEmpty, devices.contains(where: { $0.id == preferredID }) {
            return preferredID
        }
        let n = cameraNameBare(preferredName)
        if !n.isEmpty, let hit = devices.first(where: { cameraNameBare($0.name) == n }) {
            return hit.id
        }
        return nil
    }

    /// PTS-Sprung (Continuity-Uhr) = Freeze, nicht Dropout. d ≤ 0 oder > 0,50 s.
    static func ptsJumpIsFreeze(
        pts: TimeInterval,
        prevPts: TimeInterval,
        maxFrame: TimeInterval = 0.50
    ) -> Bool {
        guard prevPts > 0, pts > 0, pts.isFinite, prevPts.isFinite else { return false }
        let d = pts - prevPts
        return d <= 1e-4 || d > maxFrame
    }

    /// Sample-PTS auf Wall. Sprung sonst lastHandSeen um Sekunden → Dropout.
    static func ptsWallStamp(
        pts: TimeInterval,
        wall: TimeInterval,
        prevPts: TimeInterval?,
        prevWall: TimeInterval?
    ) -> TimeInterval {
        guard
            let prevPts, let prevWall,
            pts.isFinite, pts > 0, prevPts > 0,
            wall.isFinite, prevWall > 0
        else { return wall }
        if ptsJumpIsFreeze(pts: pts, prevPts: prevPts) { return wall }
        return prevWall + (pts - prevPts)
    }

    /// Pinzette als Hold-SM. Sechs Uhren + Bool bleibt die Uhr.
    enum PinchHoldPhase: String, Equatable {
        case unseen, tentative, held, released
    }

    static func pinchHoldAdvance(
        phase: PinchHoldPhase,
        closed: Bool,
        heldFor: TimeInterval,
        dt: TimeInterval,
        tentativeNeed: TimeInterval = 0.12,
        releaseNeed: TimeInterval = 0.20
    ) -> (phase: PinchHoldPhase, heldFor: TimeInterval) {
        let t = max(0, dt)
        switch phase {
        case .unseen:
            return closed ? (.tentative, t) : (.unseen, 0)
        case .tentative:
            if !closed { return (.unseen, 0) }
            let h = heldFor + t
            return h >= tentativeNeed ? (.held, h) : (.tentative, h)
        case .held:
            if closed { return (.held, heldFor + t) }
            return (.released, t)
        case .released:
            if closed { return (.tentative, t) }
            return heldFor + t >= releaseNeed ? (.unseen, 0) : (.released, heldFor + t)
        }
    }

    static func pinchHoldFire(_ phase: PinchHoldPhase) -> Bool { phase == .held }

    static func pinchHoldClosed(_ phase: PinchHoldPhase) -> Bool {
        phase == .held || phase == .tentative
    }

    /// HUD zwischen Detect-Ticks. t=0 am Sample (zeigt prev), t=1 nach einem Intervall.
    static func hudLerpT(
        prevAt: TimeInterval,
        nextAt: TimeInterval,
        now: TimeInterval,
        freeze: Bool
    ) -> CGFloat {
        if freeze { return 1 }
        let span = nextAt - prevAt
        if span <= 1e-6 { return 1 }
        return CGFloat(max(0, min(1, (now - nextAt) / span)))
    }

    static func hudLerpPoint(prev: CGPoint, next: CGPoint, t: CGFloat) -> CGPoint {
        let u = max(0, min(1, t))
        return CGPoint(
            x: prev.x + (next.x - prev.x) * u,
            y: prev.y + (next.y - prev.y) * u
        )
    }

    /// AX-Drop: freeze, nie Warp auf (0,0).
    static func pointerWarpAllowed(axTrusted: Bool) -> Bool { axTrusted }

    /// 8 fps Palm-Jitter: kleineres α, sonst Reach/Gate skaliert mit einem Tick.
    static func palmWidthEMAAlpha(dt: TimeInterval, base: CGFloat = 0.22) -> CGFloat {
        dt >= 0.10 ? min(0.12, base * 0.55) : base
    }


    /// One-Euro auf pinchRatio. 8 fps Gate-Jitter sonst Klick. q tot dämpft cutoff.
    static func pinchRatioSmooth(prev: CGFloat, next: CGFloat, dt: TimeInterval, minCutoff: CGFloat = 1, quality: Double = 1) -> CGFloat {
        let t = CGFloat(max(0.008, dt))
        let q = CGFloat(max(0.35, min(1, quality)))
        var cutoff: CGFloat = dt >= 0.10 ? max(0.6, minCutoff * 0.85) : max(1.8, minCutoff * 2.2)
        cutoff = max(0.35, cutoff * q)
        let tau = 1 / (2 * .pi * cutoff)
        let a = t / (t + tau)
        return prev + a * (next - prev)
    }

    /// Lift-z-Vorzeichen: Occlusion kippt previous[]. Kleines pred fällt auf Anatomie.
    static func liftSignHolds(previousDz: CGFloat, mag: CGFloat, band: CGFloat = 0.15) -> CGFloat? {
        if mag <= 0 { return 0 }
        guard abs(previousDz) > mag * band else { return nil }
        return previousDz >= 0 ? mag : -mag
    }

    /// q < 0,55: Landmark tot, 2D-Closedness lügt. Tor hoch, sonst Faust-Klick.
    /// Kleine Palme (weit weg) hebt die Schwelle — 8-Hz-Jitter schließt sonst.
    static func pinchClosednessNeed(quality: Double, start: Bool, palmWidth: CGFloat = 0.12) -> Double {
        let base = start ? 0.58 : 0.42
        let q = max(0, min(1, quality))
        var need = base
        if q < 0.55 {
            let lift = (0.55 - q) * (start ? 0.55 : 0.45)
            need = min(start ? 0.84 : 0.70, base + lift)
        }
        let w = max(0.04, min(0.28, palmWidth))
        let adj = (0.12 / w - 1) * (start ? 0.08 : 0.05)
        let lo = start ? 0.50 : 0.36
        let hi = start ? 0.88 : 0.76
        return min(hi, max(lo, need + adj))
    }

    /// Freeze-Palme: Geisterhand folgt letzter Vel, decay. Recover sonst Teleport.
    static func freezePalmPredict(
        palm: CGPoint,
        vx: CGFloat,
        vy: CGFloat,
        dt: TimeInterval,
        decay: CGFloat = 0.82
    ) -> (palm: CGPoint, vx: CGFloat, vy: CGFloat) {
        let d = max(0, min(1, decay))
        let t = CGFloat(max(0, dt))
        let nvx = vx * d
        let nvy = vy * d
        return (CGPoint(x: palm.x + nvx * t, y: palm.y + nvy * t), nvx, nvy)
    }

    /// Kalman-Palme während Freeze. Vel-Decay 0,82 stirbt in 3 Continuity-Ticks.
    /// Q folgt fps: 24 fps weniger Process-Noise als 8 fps.
    static func freezeKalmanQ(dt: TimeInterval) -> (qPos: CGFloat, qVel: CGFloat, friction: CGFloat) {
        let t = max(0.008, min(0.20, dt <= 0 ? 0.04 : dt))
        let slow = CGFloat(min(1, max(0, (t - 0.04) / 0.085)))
        return (
            0.0008 + slow * 0.0012,
            0.004 + slow * 0.006,
            max(0.88, 0.94 - slow * 0.04)
        )
    }

    static func freezeKalmanPredict(
        palm: CGPoint,
        vx: CGFloat,
        vy: CGFloat,
        pPos: CGFloat = 0.0004,
        pVel: CGFloat = 0.008,
        dt: TimeInterval,
        friction: CGFloat? = nil,
        qPos: CGFloat? = nil,
        qVel: CGFloat? = nil
    ) -> (palm: CGPoint, vx: CGFloat, vy: CGFloat, pPos: CGFloat, pVel: CGFloat) {
        let q = freezeKalmanQ(dt: dt)
        let t = CGFloat(max(0, min(0.20, dt)))
        let f = max(0.80, min(1, friction ?? q.friction))
        let nvx = vx * f
        let nvy = vy * f
        let next = CGPoint(x: palm.x + nvx * t, y: palm.y + nvy * t)
        let npPos = max(0, pPos + t * t * max(0, pVel) + max(0, qPos ?? q.qPos))
        let npVel = max(0, pVel * f * f + max(0, qVel ?? q.qVel))
        return (next, nvx, nvy, npPos, npVel)
    }

    static func freezeKalmanUpdate(
        pred: CGPoint,
        meas: CGPoint,
        pPos: CGFloat,
        r: CGFloat = 0.002
    ) -> (palm: CGPoint, pPos: CGFloat) {
        let p = max(0, pPos)
        let noise = max(1e-9, r)
        let k = p / (p + noise)
        let palm = CGPoint(
            x: pred.x + k * (meas.x - pred.x),
            y: pred.y + k * (meas.y - pred.y)
        )
        return (palm, (1 - k) * p)
    }

    /// Zwei-Hand Kalman. Actor-Δ auf die zweite Hand bleibt tot.
    static func freezeKalmanPalms(
        palms: [(id: String, palm: CGPoint, vx: CGFloat, vy: CGFloat, pPos: CGFloat, pVel: CGFloat)],
        dt: TimeInterval
    ) -> [(id: String, palm: CGPoint, vx: CGFloat, vy: CGFloat, pPos: CGFloat, pVel: CGFloat)] {
        palms.map { row in
            let p = freezeKalmanPredict(
                palm: row.palm, vx: row.vx, vy: row.vy, pPos: row.pPos, pVel: row.pVel, dt: dt
            )
            return (row.id, p.palm, p.vx, p.vy, p.pPos, p.pVel)
        }
    }


    /// Zwei-Hand Freeze: jede Palme eigene Vel. Actor-Δ auf die zweite Hand = Teleport.
    static func freezePalmsPredict(
        palms: [(id: String, palm: CGPoint, vx: CGFloat, vy: CGFloat)],
        dt: TimeInterval,
        decay: CGFloat = 0.82
    ) -> [(id: String, palm: CGPoint, vx: CGFloat, vy: CGFloat)] {
        palms.map { row in
            let p = freezePalmPredict(palm: row.palm, vx: row.vx, vy: row.vy, dt: dt, decay: decay)
            return (row.id, p.palm, p.vx, p.vy)
        }
    }

    /// Predict sichtbar: Richtung an der Geisterhand. Still = tot.
    static func freezeVelChip(dx: CGFloat, dy: CGFloat, floor: CGFloat = 0.002) -> String? {
        let m = hypot(dx, dy)
        guard m >= floor else { return nil }
        if abs(dx) >= abs(dy) { return dx > 0 ? "→" : "←" }
        return dy > 0 ? "↓" : "↑"
    }

    /// Residual hoch = Occlusion. lastZ nicht überschreiben, sonst Sign kippt trotz liftSignHolds.
    static func liftSignKeepsPrevious(residual: CGFloat, floor: CGFloat = 0.28) -> Bool {
        residual >= floor
    }

    /// Freeze: Jiggler darf Geisterhand nicht wecken.
    static func clutchIgnoresFreeze(freezeLive: Bool) -> Bool { freezeLive }

    /// Ampel-Ring: 8 fps dicker, sonst 4 Frames unsichtbar.
    static func chromeDwellRingWidth(dt: TimeInterval, hot: Bool = true) -> CGFloat {
        let base: CGFloat = hot ? 6 : 4
        return max(base, min(14, base + CGFloat(max(0, dt - 0.04) * 48)))
    }

    static func skeletonFreezeDim(_ freeze: Bool) -> CGFloat {
        freeze ? 0.38 : 1
    }

    static func fpsSparkBars(
        _ samples: [(t: TimeInterval, fps: Double)],
        now: TimeInterval,
        buckets: Int = 16,
        cap: Double = 30
    ) -> [CGFloat] {
        let n = max(4, buckets)
        var bars = [CGFloat](repeating: 0, count: n)
        let slice = samples.filter { now - $0.t <= fpsSparkSec && $0.fps > 0 }
        guard !slice.isEmpty else { return bars }
        let start = now - fpsSparkSec
        for s in slice {
            let u = (s.t - start) / fpsSparkSec
            let i = min(n - 1, max(0, Int(u * Double(n))))
            bars[i] = max(bars[i], CGFloat(min(1, s.fps / max(1, cap))))
        }
        return bars
    }

    static func pinchReleaseBlocks(now: TimeInterval, releasedAt: TimeInterval?, dt: TimeInterval) -> Bool {
        guard let t = releasedAt else { return false }
        return now - t < pinchReleaseNeed(dt: dt)
    }

    static func clutchIgnores(delta: CGFloat, scale: CGFloat = 1) -> Bool {
        delta < clutchJiggleScaled(scale: scale)
    }

    /// Zwei-Pinzetten an gegenüberliegenden Fensterhälften, nicht am Palmenabstand.
    static func twoPinchOppositeHalves(_ a: CGPoint, _ b: CGPoint, window: CGRect) -> Bool {
        twoPinchAxis(a, b, window: window) != .none
    }

    /// Links/rechts vs oben/unten merken — ein Jitter darf die Achse nicht drehen.
    static func twoPinchAxis(_ a: CGPoint, _ b: CGPoint, window: CGRect) -> TwoPinchAxis {
        guard window.width > 40, window.height > 40 else { return .none }
        let dx = abs(a.x - b.x) / window.width
        let dy = abs(a.y - b.y) / window.height
        if dx < 0.10, dy < 0.10 { return .none }
        return dx >= dy ? .horizontal : .vertical
    }

    static func twoPinchAxisHolds(locked: TwoPinchAxis, next: TwoPinchAxis) -> Bool {
        if next == .none { return false }
        if locked == .none { return true }
        return locked == next
    }

    /// Ein Jitter-Frame darf die Achse nicht auf .none setzen — sonst Scroll↔Scale-Flip.
    static func twoPinchAxisHysteresis(
        locked: TwoPinchAxis,
        next: TwoPinchAxis,
        dx: CGFloat,
        dy: CGFloat,
        ratio: CGFloat = 1.35
    ) -> TwoPinchAxis {
        if locked == .none { return next }
        if next == .none { return locked }
        if next == locked { return locked }
        let strong: Bool
        switch locked {
        case .horizontal: strong = dy >= dx * ratio
        case .vertical: strong = dx >= dy * ratio
        case .none: strong = true
        }
        return strong ? next : locked
    }

    /// Kleine Span-Änderung bei gelockter Achse = Scroll, nicht Fenster-Scale.
    static func twoPinchPrefersScroll(spanDelta: CGFloat, scaleNeed: CGFloat = twoPinchScaleNeed) -> Bool {
        abs(spanDelta) < scaleNeed * 0.42
    }

    static func twoPinchScrollTicks(
        axis: TwoPinchAxis,
        a: CGPoint,
        b: CGPoint,
        prevA: CGPoint,
        prevB: CGPoint,
        scale: CGFloat = 1,
        gain: CGFloat = 1
    ) -> Int32 {
        guard axis != .none else { return 0 }
        let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        let prev = CGPoint(x: (prevA.x + prevB.x) / 2, y: (prevA.y + prevB.y) / 2)
        let d = axis == .horizontal ? (mid.x - prev.x) : (mid.y - prev.y)
        let g = max(0.25, min(2, gain))
        let ticks = Int32((d * 0.42 * backingScaleClamped(scale) * g).rounded())
        return max(-24, min(24, ticks))
    }

    /// Safari zu dünn, Xcode-Caret zu grob. Finder 1×.
    static func scrollGainFor(bundleId: String) -> CGFloat {
        let b = bundleId.lowercased()
        if b.contains("safari") { return 1.35 }
        if b.contains("dt.xcode") || b.hasSuffix(".xcode") { return 0.55 }
        return 1.0
    }

    /// Zwei-Pinzetten: IDs sortieren, sonst Vision-Reorder → Span-Sprung.
    static func twoPinchSorted(ids: [String]) -> [String] {
        ids.sorted()
    }

    /// Continuity 8 fps: zwei Fehlframes ≈ 250 ms. 0,18 s hat den Zug getötet.
    /// Pointer-Hold gilt auch ohne Pinzette — sonst stirbt der Zeiger beim Zeigen.
    static func emptyHandsHold(dt: TimeInterval, base: TimeInterval = pinchLockMiss) -> TimeInterval {
        max(base, min(0.45, dt * 2.2))
    }

    /// HMM-Reset hart 0,35 s. Freeze-Hold + Recover sonst tot nach Dropout.
    static func trackDropoutNeed(dt: TimeInterval) -> TimeInterval {
        max(0.35, emptyHandsHold(dt: dt) * 1.4)
    }

    /// Freeze-Decay: 1 am ersten Fehlframe, 0 am Ende des Holds.
    static func emptyHandsHoldGain(elapsed: TimeInterval, hold: TimeInterval) -> CGFloat {
        let h = max(0.08, hold)
        let t = min(1, max(0, elapsed / h))
        return CGFloat(1 - t)
    }

    /// Erste Frames nach Dropout: nicht voller Gain — sonst teleportiert die Palme.
    static func emptyHandsRecover(elapsed: TimeInterval, hold: TimeInterval) -> CGFloat {
        max(0.15, emptyHandsHoldGain(elapsed: elapsed, hold: hold))
    }

    /// Recover über 2 Frames, nicht nur den ersten Tick nach Dropout.
    static func emptyHandsRecoverSpan(dt: TimeInterval) -> TimeInterval {
        max(0.08, dt) * 2.2
    }

    static func emptyHandsRecoverLive(now: TimeInterval, until: TimeInterval, span: TimeInterval) -> CGFloat {
        let s = max(0.08, span)
        let remain = until - now
        if remain <= 0 { return 1 }
        let t = min(1, max(0, 1 - remain / s))
        return 0.25 + 0.75 * CGFloat(t)
    }

    /// Dropout: Cursor einfrieren, AX-Zug nicht. Fenster klebt sonst in der Luft.
    /// Freeze (beyondHold false) hält den Zug — Continuity-Hitch sonst droppt das Fenster.
    static func emptyHandsHoldReleaseAX(isDragging: Bool, beyondHold: Bool = false) -> Bool {
        isDragging && beyondHold
    }

    /// Freeze trägt pinchHeld. Nur Dropout jenseits Hold droppt Gate.
    static func emptyHandsHoldDropsPinch(beyondHold: Bool = false) -> Bool { beyondHold }

    /// Kalman-Palme bewegt den Cursor während Freeze. Return-ohne-Zeiger = tot bei 8 fps.
    static func freezeDrivesCursor(hasHands: Bool) -> Bool { hasHands }

    /// 1080p-Preset klemmt Continuity auf 8 fps. Leiter kann activeFormat nicht lösen.
    static func captureSessionPresetClamps1080() -> Bool { true }

    static func capturePrefersInputPriority() -> Bool { true }

    /// Native 420 vor BGRA — Continuity konvertiert sonst 1080p BGRA @ 8.
    static func capturePrefersNative420() -> Bool { true }

    /// Sleep/Wake: Session neu, Leiter halten.
    static func cameraRecoversOnWake() -> Bool { true }

    /// Leiter-Höhe über Launches. 1080 nach Restart sonst wieder 8 fps.
    static func cameraFormatHeightPersist(height: Double) -> Double {
        if height >= 1000 { return 1080 }
        if height >= 700 { return 720 }
        if height >= 500 { return 540 }
        return 360
    }

    /// Continuity: 720 zuerst, nicht claimed 1080@30. Mac nicht auf 720 der Phone-Session kleben.
    static func cameraFormatHeightPrefers720(role: String, stored: Double) -> Double {
        if role == "phone" || role == "continuity" { return 720 }
        if role == "mac" { return 1080 }
        return stored >= 360 ? stored : 1080
    }

    /// Continuity 30-fps-Request fällt auf 8. 24 bleibt.
    static func cameraLockFps(maxFps: Double, prefer: Double = 24) -> Double {
        let cap = max(1, maxFps)
        if cap >= prefer { return prefer }
        return cap
    }

    static func cameraLockDuration(
        maxFps: Double,
        minFps: Double,
        prefer: Double = 24,
        measuredFps: Double = 0,
        role: String = ""
    ) -> Double {
        let fps = min(
            max(minFps, cameraLockFpsPromote(maxFps: maxFps, measuredFps: measuredFps, prefer: prefer, role: role)),
            max(1, maxFps)
        )
        return 1.0 / max(1, fps)
    }

    /// USB-C/Osmo: 30 nur nach Messung. Continuity-Phone bleibt 24, auch bei kurz 24 fps.
    static func cameraFormatUsbRole(_ role: String) -> Bool {
        if role.isEmpty { return true }
        return role == "osmo" || role == "external" || role == "usb"
    }

    /// USB-C/Osmo claimed 30 → 8. 30 nur nach gemessenen ≥ 22 fps und USB-Rolle.
    static func cameraLockFpsPromote(
        maxFps: Double,
        measuredFps: Double,
        prefer: Double = 24,
        promote: Double = 30,
        floor: Double = 22,
        role: String = ""
    ) -> Double {
        let cap = max(1, maxFps)
        if cameraFormatUsbRole(role), measuredFps >= floor, cap >= promote { return min(cap, promote) }
        return cameraLockFps(maxFps: maxFps, prefer: prefer)
    }

    static func cameraFormatPromoteReady(
        measuredFps: Double,
        already: Bool = false,
        floor: Double = 22,
        role: String = ""
    ) -> Bool {
        cameraFormatUsbRole(role) && !already && measuredFps >= floor
    }

    /// 8 fps: Body-Pose jedes 4. Frame = 500 ms tot + extra Vision.
    static func visionSkipsBody(dt: TimeInterval) -> Bool { dt >= 0.10 }

    /// Continuity Center Stage croppt aufs Gesicht — Palme fällt raus. Wie Aegis.
    static let centerStageOff = true

    static func centerStageNeedsAppControl(currentModeRaw: Int) -> Bool {
        centerStageOff && currentModeRaw != 1
    }

    static func centerStageNeedsReassert(enabled: Bool) -> Bool {
        centerStageOff && enabled
    }

    /// iPhone-AE-Jagd kippt Homographie und Kalman. Built-in bleibt continuous.
    static func cameraLocksExposure(role: String) -> Bool { role == "phone" }

    static func cameraLocksWhiteBalance(role: String) -> Bool { role == "phone" }

    /// 0 unknown, 1 left, 2 right. Dropout-Flicker hält die letzte Seite.
    static func chiralityLock(prev: Int, live: Int, dropped: Bool) -> Int {
        if live == 0 { return prev }
        if dropped, prev != 0, live != prev { return prev }
        return live
    }

    static func visionRoiEnabled() -> Bool { false }

    static func visionRoiFromPalm(palm: CGPoint, width: CGFloat, scale: CGFloat = 2) -> CGRect {
        let s = max(0.16, min(1, max(0.04, width) * max(1, scale)))
        let x = min(1, max(0, palm.x - s / 2))
        let y = min(1, max(0, palm.y - s / 2))
        return CGRect(x: x, y: y, width: min(1 - x, s), height: min(1 - y, s))
    }

    static func visionRoiUnion(_ boxes: [CGRect]) -> CGRect {
        guard var u = boxes.first else { return visionRoiFull() }
        for b in boxes.dropFirst() { u = u.union(b) }
        let x = min(1, max(0, u.origin.x))
        let y = min(1, max(0, u.origin.y))
        return CGRect(
            x: x, y: y,
            width: min(1 - x, max(0.16, u.width)),
            height: min(1 - y, max(0.16, u.height))
        )
    }

    static func visionRoiFull() -> CGRect { CGRect(x: 0, y: 0, width: 1, height: 1) }

    /// FramePump drop: alte Vision-Gen tot.
    static func visionCancelOnDrop(dropped: Bool) -> Bool { dropped }

    /// DisplayLink 90 Hz darf den OS-Cursor treiben. Clutch dann Radius, nicht Zeitfenster.
    static func hudLerpDrivesCursor() -> Bool { true }

    /// Accessibility: reduced-motion = HUD ohne Coast, Sample bleibt.
    static func hudCoastAllowed(reduceMotion: Bool) -> Bool { !reduceMotion }

    /// Retina 2×: 48 pt zu eng nach 90 Hz Coast. Scale 1 bleibt 48, 2× = 96.
    static func clutchOwnRadiusScaled(scale: CGFloat) -> CGFloat {
        clutchOwnRadius * backingScaleClamped(scale)
    }

    /// Coast: Fenster-ID halten solange Cursor in Bounds+Pad. Nicht 90 Hz hitTest.
    static func axWindowCacheHolds(cursor: CGPoint, bounds: CGRect, pad: CGFloat = 28) -> Bool {
        guard bounds.width > 8, bounds.height > 8 else { return false }
        return bounds.insetBy(dx: -pad, dy: -pad).contains(cursor)
    }

    /// VN unkündbar. Frame älter als 400 ms = tot, nächsten nehmen.
    static func visionStale(arrived: TimeInterval, now: TimeInterval, limit: TimeInterval = 0.40) -> Bool {
        arrived > 0 && now - arrived >= limit
    }

    /// Analog-Pinch: Closedness × z-Nähe. Bool-Gate allein zittert bei 8 fps.
    static func pinchAnalog(closedness: Double, zSep: CGFloat) -> Double {
        let c = max(0, min(1, closedness))
        let z = max(0, min(1, 1 - Double(zSep) / 1.20))
        return 0.55 * c + 0.45 * z
    }

    static func pinchAnalogClosed(_ analog: Double) -> Bool { analog >= 0.58 }

    /// Sample-Cursor nicht posten wenn DisplayLink-Coast den OS-Zeiger treibt.
    static func sampleCursorYieldsToCoast(coastDrives: Bool, dragging: Bool, freeze: Bool) -> Bool {
        coastDrives && !dragging && !freeze
    }

    /// 90 Hz coalesced, unabhängig vom Vision-Tick. Kleiner als Coast-Cap.
    static func cgEventCoalesceDt(displayHz: Double = 90) -> TimeInterval {
        1.0 / max(30, displayHz)
    }

    static func cgEventCoalesceDue(lastPost: TimeInterval, now: TimeInterval, dt: TimeInterval? = nil) -> Bool {
        lastPost <= 0 || now - lastPost >= (dt ?? cgEventCoalesceDt())
    }

    /// Nach Display-Drehung ist die Homographie tot. Zirkuläre Δ ≥ 15°.
    static func spaceMapRotationDelta(_ a: Double, _ b: Double) -> Double {
        var d = abs(a - b).truncatingRemainder(dividingBy: 360)
        if d > 180 { d = 360 - d }
        return d
    }

    static func spaceMapNeedsRecalib(stored: Double, live: Double, need: Double = 15) -> Bool {
        spaceMapRotationDelta(stored, live) >= need
    }

    /// 90/180/270°: Palmen halten, Homographie auf neue screenCorners. Wipe nur schräg.
    static func spaceMapRotationNudge(stored: Double, live: Double, snap: Double = 15) -> Bool {
        let d = spaceMapRotationDelta(stored, live)
        guard d >= snap else { return false }
        return [90.0, 180.0, 270.0].contains { abs(d - $0) < snap }
    }

    static func spaceMapRotationWipe(stored: Double, live: Double, snap: Double = 15) -> Bool {
        spaceMapNeedsRecalib(stored: stored, live: live, need: snap)
            && !spaceMapRotationNudge(stored: stored, live: live, snap: snap)
    }

    /// Continuity-Miss ≠ Double-Click. 0,12 s < 1 Frame @ 8 fps.
    static func clickHitchNeed(dt: TimeInterval) -> TimeInterval {
        max(0.22, min(0.45, max(0.008, dt) * 1.8))
    }

    static func clickHitchBlocks(lastClick: TimeInterval, now: TimeInterval, dt: TimeInterval) -> Bool {
        lastClick > 0 && now - lastClick < clickHitchNeed(dt: dt)
    }

    static func clickHitchFromFreeze(freezeEnded: TimeInterval?, now: TimeInterval, dt: TimeInterval) -> Bool {
        guard let t = freezeEnded else { return false }
        return now - t >= 0 && now - t < clickHitchNeed(dt: dt)
    }

    static func spaceMapRotation(displayID: UInt32) -> Double {
        CGDisplayRotation(CGDirectDisplayID(displayID))
    }

    /// 5K / Retina: 80 pt Coast zu kurz, Sample warpt. Scale 1 bleibt 80, 2× = 160.
    static func hudCoastCapScaled(scale: CGFloat, base: CGFloat = 80) -> CGFloat {
        base * backingScaleClamped(scale)
    }

    /// Echo der eigenen CGEvents auf Retina größer als 1,2 pt.
    static func clutchJiggleScaled(scale: CGFloat) -> CGFloat {
        clutchJiggle * backingScaleClamped(scale)
    }

    /// Nach Zoom kein sofortiger Scroll. 0,28 s Hysterese.
    static func scrollMuteAfterTwoPinch(
        now: TimeInterval,
        endedAt: TimeInterval?,
        hold: TimeInterval = 0.28
    ) -> Bool {
        guard let t = endedAt else { return false }
        return now - t >= 0 && now - t < hold
    }

    /// Nach dem Sample coasten, nicht 1 Frame hinterher interpolieren.
    static func hudCoastVel(prev: CGPoint, next: CGPoint, dt: TimeInterval) -> CGPoint {
        let t = CGFloat(max(0.008, dt))
        return CGPoint(x: (next.x - prev.x) / t, y: (next.y - prev.y) / t)
    }

    static func hudCoastPoint(sample: CGPoint, vel: CGPoint, elapsed: TimeInterval, cap: CGFloat = 80) -> CGPoint {
        let t = CGFloat(max(0, min(0.20, elapsed)))
        var dx = vel.x * t
        var dy = vel.y * t
        let m = hypot(dx, dy)
        if m > cap {
            dx *= cap / m
            dy *= cap / m
        }
        return CGPoint(x: sample.x + dx, y: sample.y + dy)
    }

    /// Cursor-Screen, nicht immer Main. Homographie sonst auf dem falschen Display.
    static func spaceMapDisplayID(cursor: CGPoint, screens: [(id: UInt32, quartz: CGRect)], fallback: UInt32) -> UInt32 {
        for s in screens where s.quartz.contains(cursor) { return s.id }
        return fallback
    }

    /// Instantane Palm-Vel in Handbreiten/s.
    static func pinchPalmVel(movedHW: CGFloat, dt: TimeInterval) -> CGFloat {
        CGFloat(movedHW) / CGFloat(max(0.008, dt))
    }

    /// Darüber Drag, auch kurze Distanz. 8 fps 2,0 HW/s.
    static func pinchDragVelNeed(dt: TimeInterval) -> CGFloat {
        dt >= 0.08 ? 2.0 : 3.0
    }

    /// Darunter Klick trotz akkumulierter Distanz. 8 fps Drift ≠ Zug.
    static func pinchDragVelClick(dt: TimeInterval) -> CGFloat {
        dt >= 0.08 ? 1.20 : 1.80
    }

    /// R1 erste Recover-Hälfte, R2 zweite. HUD sonst nur freeze während Miss.
    static func emptyHandsRecoverChip(now: TimeInterval, until: TimeInterval, span: TimeInterval) -> String? {
        guard until > now else { return nil }
        let s = max(0.08, span)
        let remain = until - now
        return remain / s > 0.5 ? "R1" : "R2"
    }

    /// Dropout-Mute sichtbar — sonst sieht man nur freeze, der Klick ist schon tot.
    static func emptyHandsHoldDropsPinchChip(dropped: Bool) -> String? {
        dropped ? "P drop" : nil
    }

    /// Hand kommt näher/weiter nach Dropout: Gain klein halten, sonst Teleport.
    static func emptyHandsRecoverPalmMul(prev: CGFloat, next: CGFloat) -> CGFloat {
        let p = max(0.02, prev)
        let n = max(0.02, next)
        let jump = max(n / p, p / n)
        if jump < 1.28 { return 1 }
        return CGFloat(max(0.35, min(1, 1.28 / Double(jump))))
    }

    /// Palme springt nach Dropout (nicht nur Breite). Relativ-Zeiger sonst 50 px trotz freezeGain.
    static func emptyHandsRecoverPalmJump(prev: CGPoint, next: CGPoint, palmWidth: CGFloat) -> CGFloat {
        let d = hypot(next.x - prev.x, next.y - prev.y) / max(0.02, palmWidth)
        if d < 0.35 { return 1 }
        return max(0.12, 1 - min(1, (d - 0.35) / 1.4))
    }

    /// 24 fps bleibt 0,22 s. 8 fps sonst ein unknown-Tick = Faust-Scharf tot.
    static func fistScharfGrace(dt: TimeInterval) -> TimeInterval {
        max(0.22, min(0.40, max(0.008, dt) * 2.2))
    }

    /// Continuity 8 fps: 2 Frames. Built-in: 3, sonst ein Jitter-Tick skaliert.
    static let twoPinchEdgeNeed = 3
    static func twoPinchConfirmFrames(dt: TimeInterval, builtIn: Int = twoPinchEdgeNeed) -> Int {
        dt >= 0.10 ? 2 : max(2, builtIn)
    }

    static func twoPinchEdgeHold(ok: Bool, streak: Int, need: Int = twoPinchEdgeNeed) -> Int {
        ok ? min(need + 2, streak + 1) : 0
    }

    static func twoPinchEdgeReady(streak: Int, need: Int = twoPinchEdgeNeed) -> Bool {
        streak >= need
    }

    /// Continuity-Jitter dreht das Vorzeichen — Streak darf nur gleichsinnig zählen.
    static func twoPinchZoomHolds(delta: CGFloat, lastSign: CGFloat) -> Bool {
        lastSign == 0 || delta * lastSign >= 0
    }

    /// Palm-Zittern einer Hand darf nicht scrollen.
    static let scrollDeadHW: CGFloat = 0.08
    /// Nach Loslassen noch 200 ms Coast, sonst stirbt der Wisch bei 8 fps.
    static let scrollInertia: TimeInterval = 0.20

    static func scrollCoastTicks(
        velHW: CGFloat,
        remain: TimeInterval,
        window: TimeInterval = scrollInertia
    ) -> Int32 {
        guard window > 0, remain > 0, abs(velHW) > 0.02 else { return 0 }
        let frac = CGFloat(remain / window)
        return Int32(max(-16, min(16, -velHW * 18 * frac)))
    }

    /// Two-pinch Loslassen → gleiche Coast wie Ein-Finger. ticks 0 = nil.
    static func twoPinchScrollMomentum(
        ticks: Int32,
        now: TimeInterval,
        inertia: TimeInterval = scrollInertia
    ) -> (until: TimeInterval, vel: CGFloat)? {
        guard ticks != 0, inertia > 0 else { return nil }
        return (now + inertia, CGFloat(-ticks) / 18)
    }

    /// Inertia darf keinen Klick-Start überdecken.
    static func scrollCoastBreaks(pinchHeld: Bool, twoPinch: Bool = false) -> Bool {
        pinchHeld || twoPinch
    }

    /// Continuity-Dropout sichtbar ohne Konsole.
    static func fpsAmber(_ fps: Double, floor: Double = 10) -> Bool {
        fps > 0 && fps < floor
    }

    static let fpsSparkSec: TimeInterval = 8

    static func fpsSparkAmber(
        _ samples: [(t: TimeInterval, fps: Double)],
        now: TimeInterval,
        floor: Double = 10
    ) -> Bool {
        let slice = samples.filter { now - $0.t <= fpsSparkSec && $0.fps > 0 }
        guard !slice.isEmpty else { return false }
        let mean = slice.map(\.fps).reduce(0, +) / Double(slice.count)
        return mean > 0 && mean < floor
    }

    static func airKeyboardSummon(v: CGFloat, band: CGFloat = airKeyboardBottom) -> Bool {
        v >= band
    }

    static func pullTowardSelf(startY: CGFloat, nowY: CGFloat, need: CGFloat = pullToward) -> Bool {
        startY - nowY >= need
    }

    /// Hand kommt auf die Kamera zu: Palme wächst. Palm-Y allein sieht das nicht.
    static func pullTowardPalmGrow(startW: CGFloat, nowW: CGFloat, need: CGFloat = 1.22) -> Bool {
        guard startW > 0.02 else { return false }
        return nowW / startW >= need
    }

    /// Schreibtisch / Wallpaper: fast schirmfüllend, ohne Fenstertitel.
    static func fillsScreen(_ window: CGRect, screen: CGRect, heightSlop: CGFloat = 80) -> Bool {
        abs(window.midX - screen.midX) < 8
            && abs(window.midY - screen.midY) < 8
            && abs(window.width - screen.width) < 16
            && abs(window.height - screen.height) < heightSlop
    }

    static func isWallpaperTitle(_ title: String) -> Bool {
        title.isEmpty || title == "Desktop" || title == "Schreibtisch"
    }

    /// Sichtbares Doppelklatschen (kein Mikrofon): Palmenabstand in Handbreiten.
    static let clapContact: CGFloat = 1.40
    static let clapOpen: CGFloat = 2.20
    static let clapMinSpeed: CGFloat = 5.5
    static let clapMinGap: TimeInterval = 0.14
    static let clapMaxGap: TimeInterval = 0.90

    /// Ein Klatscher: Abstand fällt schnell unter Kontakt.
    static func isClapPulse(
        prevSpan: CGFloat,
        prevT: TimeInterval,
        span: CGFloat,
        now: TimeInterval,
        contact: CGFloat = clapContact,
        open: CGFloat = clapOpen,
        minSpeed: CGFloat = clapMinSpeed
    ) -> Bool {
        let dt = now - prevT
        guard dt >= 0.04, dt <= 0.28 else { return false }
        let speed = (prevSpan - span) / CGFloat(dt)
        return span <= contact && prevSpan >= open * 0.85 && speed >= minSpeed
    }

    static func isDoubleClap(first: TimeInterval, second: TimeInterval) -> Bool {
        let g = second - first
        return g >= clapMinGap && g <= clapMaxGap
    }

    /// Letzte `flingWindow` Sekunden in Handbreiten, nicht first→last über das Halten.
    /// `x/y` sind Vision-[0,1]; `aspect` = w/h macht x isotrop.
    /// `screenUV` = Cursor in Union-Norm [0,1], wenn kalibriert — Totzone dann am Schirmmittelpunkt.
    static func flingFromTrail(
        _ trail: [(t: TimeInterval, x: CGFloat, y: CGFloat)],
        palmWidth: CGFloat,
        aspect: CGFloat = 16 / 9,
        centerDead: Bool = true,
        afterDrag: Bool = false,
        screenUV: CGPoint? = nil,
        windowSec: TimeInterval = flingWindow,
        screenHeight: CGFloat = 0
    ) -> FlingKind {
        guard let last = trail.last else { return .none }
        let slice = trail.filter { last.t - $0.t <= windowSec }
        guard let first = slice.first, last.t > first.t + 0.04 else { return .none }
        let dt = max(0.04, last.t - first.t)
        let unit = max(0.04, palmWidth)
        let dx = (last.x - first.x) * aspect / unit
        let dy = (last.y - first.y) / unit
        let dist = hypot(dx, dy)
        let speed = dist / CGFloat(dt)
        if flingTeleport(distHW: dist, palmWidth: unit, screenHeight: screenHeight) {
            return .none
        }
        if centerDead {
            let u = screenUV?.x ?? last.x
            let v = screenUV?.y ?? last.y
            if CoordMath.nearUnitCenter(u: u, v: v, radius: flingCenter), dist < flingMinDist * 1.7 {
                return .none
            }
        }
        let speedNeed = flingMinSpeed * (afterDrag ? flingAfterDragMul : 1)
        let distNeed = flingMinDist * (afterDrag ? flingAfterDragDist : 1)
        return classifyFling(
            dx: dx,
            dy: dy,
            speed: speed,
            dist: dist,
            speedNeed: speedNeed,
            distNeed: distNeed,
            afterDrag: afterDrag,
            palmWidth: unit
        )
    }

    /// Velocity from the last 2–3 samples of the window. first→last of a long
    /// Continuity slice dilutes the flick; the tail is the actual throw.
    static func flingVelFromTail(
        _ trail: [(t: TimeInterval, x: CGFloat, y: CGFloat)],
        palmWidth: CGFloat,
        aspect: CGFloat = 16 / 9,
        centerDead: Bool = true,
        afterDrag: Bool = false,
        screenUV: CGPoint? = nil,
        windowSec: TimeInterval = flingWindow,
        screenHeight: CGFloat = 0
    ) -> FlingKind {
        guard let last = trail.last else { return .none }
        let slice = trail.filter { last.t - $0.t <= windowSec }
        guard let first = slice.first, last.t > first.t + 0.04 else { return .none }
        let unit = max(0.04, palmWidth)
        let dx = (last.x - first.x) * aspect / unit
        let dy = (last.y - first.y) / unit
        let dist = hypot(dx, dy)
        if flingTeleport(distHW: dist, palmWidth: unit, screenHeight: screenHeight) {
            return .none
        }
        let tail = Array(slice.suffix(3))
        let t0 = tail.first?.t ?? first.t
        let x0 = tail.first?.x ?? first.x
        let y0 = tail.first?.y ?? first.y
        let dt = max(0.04, last.t - t0)
        let tdx = (last.x - x0) * aspect / unit
        let tdy = (last.y - y0) / unit
        let speed = hypot(tdx, tdy) / CGFloat(dt)
        if centerDead {
            let u = screenUV?.x ?? last.x
            let v = screenUV?.y ?? last.y
            if CoordMath.nearUnitCenter(u: u, v: v, radius: flingCenter), dist < flingMinDist * 1.7 {
                return .none
            }
        }
        let speedNeed = flingMinSpeed * (afterDrag ? flingAfterDragMul : 1)
        let distNeed = flingMinDist * (afterDrag ? flingAfterDragDist : 1)
        return classifyFling(
            dx: dx,
            dy: dy,
            speed: speed,
            dist: dist,
            speedNeed: speedNeed,
            distNeed: distNeed,
            afterDrag: afterDrag,
            palmWidth: unit
        )
    }

    static func classifyFling(
        dx: CGFloat,
        dy: CGFloat,
        speed: CGFloat,
        dist: CGFloat,
        speedNeed: CGFloat = flingMinSpeed,
        distNeed: CGFloat = flingMinDist,
        afterDrag: Bool = false,
        palmWidth: CGFloat = 0.12
    ) -> FlingKind {
        guard speed > speedNeed, dist > distNeed else { return .none }
        if flingAxisDead(dx: dx, dy: dy, palmWidth: palmWidth) { return .none }
        if afterDrag, abs(dx) > 0.28, abs(dy) > 0.28 {
            return .none
        }
        if abs(dy) >= abs(dx) {
            if dy > 0.55 { return .throwUp }
            if dy < -0.35 { return .minimize }
            return .none
        }
        if dx < -0.50 { return .dockLeft }
        if dx > 0.50 { return .dockRight }
        return .none
    }

    /// Diagonale Dropout-Rucke docken sonst. Kleine Palme → strengere Achse.
    static func flingAxisDead(dx: CGFloat, dy: CGFloat, palmWidth: CGFloat) -> Bool {
        let unit = max(0.04, palmWidth)
        let major = max(abs(dx), abs(dy))
        if major < 1e-6 { return true }
        let ratio = min(abs(dx), abs(dy)) / major
        let dead = min(0.72, 0.38 + (0.12 / unit) * 0.10)
        return ratio > dead
    }

    /// Continuity-Dropout = Palme springt über den Schirm. Cap 42 % Höhe, nicht Dock.
    static func flingCapPx(screenHeight: CGFloat) -> CGFloat {
        max(160, min(960, screenHeight * 0.42))
    }

    static func flingPx(distHW: CGFloat, palmWidth: CGFloat, screenHeight: CGFloat) -> CGFloat {
        max(0, distHW) * max(0.04, palmWidth) * max(1, screenHeight)
    }

    static func flingTeleport(distHW: CGFloat, palmWidth: CGFloat, screenHeight: CGFloat) -> Bool {
        guard screenHeight > 8 else { return false }
        return flingPx(distHW: distHW, palmWidth: palmWidth, screenHeight: screenHeight) > flingCapPx(screenHeight: screenHeight)
    }

    /// 8 fps: ein Tick Palm-Jitter ≥ 0,45 HW = Drag statt Klick.
    static func pinchDragNeedOf(dt: TimeInterval) -> CGFloat {
        let t = max(0.008, min(0.20, dt))
        return pinchDragNeed * CGFloat(t >= 0.08 ? 1.35 : 1)
    }

    static func pinchDragCursorNeed(dt: TimeInterval) -> CGFloat {
        dt >= 0.08 ? 40 : 28
    }

    /// Kurze, stillstehende Pinzette = Klick, nicht Greifen. Energy blockt Wackeln.
    static func isClick(
        held: TimeInterval,
        palmMovedHW: CGFloat,
        cursorMovedPx: CGFloat,
        dt: TimeInterval = 0.016,
        closedness: Double = 1
    ) -> Bool {
        let energy = clickEnergy(
            closedness: closedness, palmMovedHW: palmMovedHW, held: held, dt: dt
        )
        if energy < 0.35 { return false }
        let minHold = pinchClickMinNeed(dt: dt) * (energy >= 0.62 ? 0.55 : 1)
        guard held >= minHold, held <= pinchClickMaxHold else { return false }
        return palmMovedHW < pinchDragNeedOf(dt: dt) && cursorMovedPx < pinchClickStillNeed(dt: dt)
    }

    static func isDrag(
        palmMovedHW: CGFloat,
        cursorMovedPx: CGFloat,
        dt: TimeInterval = 0.016,
        palmVelHW: CGFloat? = nil
    ) -> Bool {
        if let v = palmVelHW {
            if v < pinchDragVelClick(dt: dt) {
                return cursorMovedPx >= max(80, pinchDragCursorNeed(dt: dt) * 2)
            }
            if v >= pinchDragVelNeed(dt: dt) { return true }
        }
        return palmMovedHW >= pinchDragNeedOf(dt: dt) || cursorMovedPx >= pinchDragCursorNeed(dt: dt)
    }

    /// Nach Pinzette-Öffnen und Gegenwischen in derselben Sekunde nicht schalten.
    static func swipeBlocked(
        now: TimeInterval,
        muteUntil: TimeInterval,
        dx: CGFloat,
        lastDx: CGFloat,
        lastAt: TimeInterval
    ) -> Bool {
        if now < muteUntil { return true }
        if lastAt > 0, now - lastAt < swipeReverseLock, lastDx != 0, dx * lastDx < 0 {
            return true
        }
        return false
    }

    static func spreadChrome(centers: [CGPoint], gap: CGFloat = chromeSpreadGap, hit: CGFloat = chromeHit) -> [CGRect] {
        guard !centers.isEmpty else { return [] }
        let sorted = centers.enumerated().sorted { $0.element.x < $1.element.x }
        let midX = centers.map(\.x).reduce(0, +) / CGFloat(centers.count)
        let midY = centers.map(\.y).reduce(0, +) / CGFloat(centers.count) + 56
        let total = gap * CGFloat(max(0, centers.count - 1))
        let x0 = midX - total / 2
        var out = Array(repeating: CGRect.zero, count: centers.count)
        for (i, pair) in sorted.enumerated() {
            let c = CGPoint(x: x0 + CGFloat(i) * gap, y: midY)
            out[pair.offset] = CGRect(x: c.x - hit / 2, y: c.y - hit / 2, width: hit, height: hit)
        }
        return out
    }

    /// Totzone auf die Strecke, nicht je Achse — sonst stirbt Schrägzug.
    static func deadzone2D(dx: CGFloat, dy: CGFloat, dead: CGFloat) -> CGPoint {
        if hypot(dx, dy) < dead { return .zero }
        return CGPoint(x: dx, y: dy)
    }

    static func magnet(cursor: CGPoint, targets: [CGPoint], radius: CGFloat = chromeMagnet) -> CGPoint? {
        var best: CGPoint?
        var bestD = radius
        for t in targets {
            let d = hypot(cursor.x - t.x, cursor.y - t.y)
            if d < bestD {
                bestD = d
                best = t
            }
        }
        return best
    }

    /// Not-Aus-Kandidat: zwei offene Palmen, Abstand ≥ Klatschen-offen, keine Pinzette.
    /// Haltezeit prüft die Engine — hier nur die Form, damit Tests ohne Vision laufen.
    static func killSwitchCandidate(
        openPalms: Int,
        spanHW: CGFloat,
        pinchHeld: Bool,
        twoPinch: Bool
    ) -> Bool {
        if pinchHeld || twoPinch { return false }
        if openPalms < 2 { return false }
        return spanHW >= clapOpen
    }

    /// Vision L/R bleibt, solange der Körper-Vote nicht klar gewinnt.
    static func bodyOverridesVision(visionUnknown: Bool, ratio: Double, disagree: Bool) -> Bool {
        if visionUnknown { return ratio < bodyVoteLoose && ratio > 0 }
        if disagree { return ratio < bodyVoteStrict && ratio > 0 }
        return false
    }

    static func palmWidthEMA(prev: CGFloat, next: CGFloat, alpha: CGFloat = 0.22) -> CGFloat {
        if prev <= 0.001 { return next }
        let a = min(1, max(0, alpha))
        return a * next + (1 - a) * prev
    }

    static func palmWidthEMA(prev: CGFloat, next: CGFloat, dt: TimeInterval) -> CGFloat {
        palmWidthEMA(prev: prev, next: next, alpha: palmWidthEMAAlpha(dt: dt))
    }


    /// Shannon-Entropie der Softmax-Pose. Flach ≈ ln(n), spitz ≈ 0.
    static func fusionEntropy(_ probs: [Double]) -> Double {
        var h = 0.0
        for p in probs {
            let x = max(1e-12, p)
            h -= x * log(x)
        }
        return h
    }

    static let entropyFloorLo: Double = 0.52
    static let entropyFloorHi: Double = 0.68

    /// Flache Verteilung → höherer Floor (0,68), spitze → 0,52 statt hart 0,62.
    static func entropyActionFloor(entropy: Double, poseCount: Int = 7) -> Double {
        let hMax = log(Double(max(2, poseCount)))
        let t = min(1, max(0, entropy / max(1e-9, hMax)))
        return entropyFloorLo + (entropyFloorHi - entropyFloorLo) * t
    }

    /// Hochpass-Alpha an Frame-dt. 0,08 ist 24 fps; Continuity 8 fps sonst tot.
    static func palmHighpassAlpha(dt: TimeInterval, base: CGFloat = palmHighpass) -> CGFloat {
        let ref: TimeInterval = 0.04
        let scale = CGFloat(min(3.2, max(0.55, max(0.008, dt) / ref)))
        return min(0.42, max(0.04, base * scale))
    }

    static func palmDeadZone(dt: TimeInterval, base: CGFloat = palmDead) -> CGFloat {
        dt >= 0.10 ? base * 1.55 : base
    }

    static let cornerRestBand: CGFloat = 0.02

    /// Schirmecken 2 %: Mikro-Motion ignorieren, Anschlag bleibt.
    static func inCornerRest(u: CGFloat, v: CGFloat, band: CGFloat = cornerRestBand) -> Bool {
        let b = min(0.12, max(0.008, band))
        return (u <= b || u >= 1 - b) && (v <= b || v >= 1 - b)
    }

    /// Locked-Pinzette fehlt im Frame → nil (einfrieren). Nie auf primary/andere Hand.
    static func pinchFollowID(held: Bool, locked: String?, liveIDs: [String]) -> String? {
        guard held, let id = locked else { return nil }
        return liveIDs.contains(id) ? id : nil
    }

    static let tablePalmY: CGFloat = 0.10
    static let tableIdleHold: TimeInterval = 2.80
    static let tableStillHW: CGFloat = 0.10

    /// Beide Palmen unten im Bild, wenig Bewegung, keine Pinzette.
    static func tableIdleCandidate(palmsY: [CGFloat], stillHW: CGFloat, pinchHeld: Bool) -> Bool {
        if pinchHeld { return false }
        guard palmsY.count >= 2 else { return false }
        return palmsY.allSatisfy { $0 < tablePalmY } && stillHW < tableStillHW
    }

    /// Pinzette starten: Gate oder klare Closedness, und es muss wie Pinzette aussehen
    /// (Reach / Zeigefinger). Faust hat geschlossene Spitzen — das ist kein Klick.
    static func pinchStartsGrab(gate: Bool, closedness: Double, reach: CGFloat = 1.2, index: Double = 1, zSep: CGFloat = 0, quality: Double = 1, approach: CGFloat = 0, residual: CGFloat = 0, palmWidth: CGFloat = 0.12) -> Bool {
        guard pinchLooksLikePinch(reach: reach, index: index, zSep: zSep, approach: approach, closedness: closedness, residual: residual) else { return false }
        return gate || closedness > pinchClosednessNeed(quality: quality, start: true, palmWidth: palmWidth)
    }

    /// Pinzette halten: weicher, aber Faust (kein Reach) gibt frei — außer Zug darf Faust tragen.
    static func pinchHoldsGrab(
        gate: Bool,
        closedness: Double,
        reach: CGFloat = 1.2,
        index: Double = 1,
        allowFist: Bool = false,
        zSep: CGFloat = 0,
        quality: Double = 1,
        approach: CGFloat = 0,
        residual: CGFloat = 0,
        palmWidth: CGFloat = 0.12
    ) -> Bool {
        if !allowFist, !pinchLooksLikePinch(reach: reach, index: index, zSep: zSep, approach: approach, closedness: closedness, residual: residual) { return false }
        return gate || closedness > pinchClosednessNeed(quality: quality, start: false, palmWidth: palmWidth)
    }

    static func pinchLooksLikePinch(reach: CGFloat, index: Double = 1, zSep: CGFloat = 0, approach: CGFloat = 0, closedness: Double = 0.70, residual: CGFloat = 0) -> Bool {
        let trust = pinch3DTrusts(residual: residual)
        if pinch3DVeto(sep: trust ? zSep : 0, closedness2D: closedness, approach: trust ? approach : 0, reach: reach) { return false }
        return reach >= pinchReachNeed || index >= pinchIndexNeed
    }

    /// Wrist → Mitte Daumen/Zeigefinger in Palmenbreiten. Faust < 0,8, Pinzette ≥ 0,9.
    static func pinchReach(wrist: CGPoint, thumb: CGPoint, index: CGPoint, scale: CGFloat) -> CGFloat {
        let m = CGPoint(x: (thumb.x + index.x) / 2, y: (thumb.y + index.y) / 2)
        return hypot(m.x - wrist.x, m.y - wrist.y) / max(0.03, scale)
    }

    static func chromeDwellMoved(from origin: CGPoint, to cursor: CGPoint, need: CGFloat = chromeDwellStillPx) -> Bool {
        hypot(cursor.x - origin.x, cursor.y - origin.y) >= need
    }

    static func keyboardStill(movedPx: CGFloat, need: CGFloat = 16) -> Bool {
        movedPx < need
    }

    static func flipLeft(_ isLeft: Bool, mirrored: Bool) -> Bool {
        mirrored ? !isLeft : isLeft
    }

    static func trailDelta(xs: [Double], ys: [Double], dt: Double) -> (dx: Double, dy: Double, speed: Double) {
        guard let x0 = xs.first, let x1 = xs.last, let y0 = ys.first, let y1 = ys.last else {
            return (0, 0, 0)
        }
        let dx = x1 - x0
        let dy = y1 - y0
        return (dx, dy, hypot(dx, dy) / max(0.05, dt))
    }

    static func drillMatch(
        action: String,
        poses: [String],
        sides: [String],
        pinchMax: Double,
        dx: Double,
        dy: Double,
        openMax: Int,
        twoHands: Bool
    ) -> (ok: Bool, text: String) {
        let has = { (p: String) in poses.contains(p) }
        switch action {
        case "openRight":
            let ok = sides.contains(where: { $0 == "Rechts" || $0 == "right" }) && (has("openPalm") || openMax >= 3)
            return (ok, ok ? "rechte offene Hand" : "keine rechte offene Hand")
        case "openLeft":
            let ok = sides.contains(where: { $0 == "Links" || $0 == "left" }) && (has("openPalm") || openMax >= 3)
            return (ok, ok ? "linke offene Hand" : "keine linke offene Hand")
        case "pinch":
            let ok = has("pinch") || pinchMax > 0.55
            return (ok, ok ? String(format: "Pinzette %.0f %%", pinchMax * 100) : "keine Pinzette")
        case "drag":
            let ok = (has("pinch") || pinchMax > 0.45) && abs(dx) > 0.08
            return (ok, ok ? String(format: "Zug dx %.2f", dx) : "kein seitlicher Zug")
        case "throwUp":
            let ok = dy > 0.10 && (has("pinch") || pinchMax > 0.4)
            return (ok, ok ? String(format: "hoch dy +%.2f", dy) : "kein Wurf nach oben")
        case "throwDown":
            let ok = dy < -0.10 && (has("pinch") || pinchMax > 0.4)
            return (ok, ok ? String(format: "runter dy %.2f", dy) : "kein Wurf nach unten")
        case "swipeLeft":
            let ok = dx < -0.10 && (has("openPalm") || openMax >= 3)
            return (ok, ok ? String(format: "wischen L dx %.2f", dx) : "kein Wischen nach links")
        case "swipeRight":
            let ok = dx > 0.10 && (has("openPalm") || openMax >= 3)
            return (ok, ok ? String(format: "wischen R dx %.2f", dx) : "kein Wischen nach rechts")
        case "fist":
            return (has("fist"), has("fist") ? "Faust" : "keine Faust")
        case "point":
            return (has("point"), has("point") ? "Zeigen" : "kein Zeigen")
        case "peace":
            return (has("peace"), has("peace") ? "Zwei Finger" : "kein Peace")
        case "clap":
            return (twoHands, twoHands ? "zwei Hände im Bild" : "keine zwei Hände")
        default:
            return (false, "unbekannte Aktion")
        }
    }

    /// Continuity 8 Hz, Kamera läuft, keine Palme: Session tot, nicht nur HUD still.
    static func sessionWatchdogEmpty(fps: Double, lastHand: TimeInterval, now: TimeInterval, need: TimeInterval = 8) -> Bool {
        fps > 0.5 && lastHand > 0 && now - lastHand >= need
    }

    static func sessionWatchdogChip(empty: Bool) -> String? {
        empty ? "WATCH · 8s leer" : nil
    }

    /// Homographie-Cache keyed by Screen-Größe. 5K→Sidecar sonst alte H.
    static func spaceMapSizeKey(width: CGFloat, height: CGFloat) -> Int {
        let w = max(0, Int(width.rounded()))
        let h = max(0, Int(height.rounded()))
        return w &* 10_000 &+ h
    }

    static func spaceMapSizeChanged(stored: Int, live: Int) -> Bool {
        stored != 0 && live != 0 && stored != live
    }

    /// Helios↔Aegis AVCapture Mutex. Gleiches Protokoll wie Aegis MatchMath.
    static func cameraMutexOwnerHelios() -> String { "helios" }
    static func cameraMutexOwnerAegis() -> String { "aegis" }
    static func cameraMutexName() -> String { "helios.aegis.camera.lock" }
    static func cameraMutexCacheFolder() -> String { "HeliosAegis" }
    static func cameraMutexStale() -> TimeInterval { 12 }
    static func cameraMutexHeartbeatSec() -> TimeInterval { 2 }
    static func cameraMutexClaimMinDt() -> TimeInterval { 0.08 }

    static func cameraMutexLine(owner: String, pid: Int32, now: TimeInterval, gen: UInt32 = 0, pts: TimeInterval? = nil, palm: (x: CGFloat, y: CGFloat, w: CGFloat)? = nil) -> String {
        let p: TimeInterval
        if let pts, pts > 0, pts.isFinite { p = pts } else { p = 0 }
        if let palm {
            return String(format: "%@ %d %.3f %u %.3f %.3f %.3f %.3f v2", owner, pid, now, gen, p, Double(palm.x), Double(palm.y), Double(palm.w))
        }
        return String(format: "%@ %d %.3f %u %.3f v2", owner, pid, now, gen, p)
    }

    /// Unix-Wall, nie CMSampleBuffer-PTS. Media < 1e6 ist Session-Zeit — Aegis obsFill sonst tot.
    static func cameraMutexPtsWall(now: TimeInterval, mediaPts: TimeInterval = 0) -> TimeInterval {
        if now > 1_000_000 { return now }
        if mediaPts > 1_000_000 { return mediaPts }
        return now > 0 ? now : mediaPts
    }

    static func cameraMutexPts(_ text: String) -> TimeInterval? {
        let parts = text.split(whereSeparator: { $0 == " " || $0 == "\n" }).map(String.init)
        guard parts.count >= 5, let v = TimeInterval(parts[4]), v.isFinite, v > 0 else { return nil }
        return v
    }

    /// Palme UV vor v2. Alte 6-Felder-Zeile bleibt lesbar.
    static func cameraMutexPalm(_ text: String) -> (x: CGFloat, y: CGFloat, w: CGFloat)? {
        let parts = text.split(whereSeparator: { $0 == " " || $0 == "\n" }).map(String.init)
        guard parts.count >= 9, parts.last == "v2" else { return nil }
        guard let x = Double(parts[5]), let y = Double(parts[6]), let w = Double(parts[7]) else { return nil }
        guard x.isFinite, y.isFinite, w.isFinite, w > 0 else { return nil }
        return (CGFloat(x), CGFloat(y), CGFloat(w))
    }

    static func cameraMutexParse(_ text: String, now: TimeInterval, stale: TimeInterval = cameraMutexStale(), pidLive: Bool? = nil) -> String? {
        let parts = text.split(whereSeparator: { $0 == " " || $0 == "\n" }).map(String.init)
        guard parts.count >= 3, let stamp = TimeInterval(parts[2]) else { return nil }
        if now - stamp > stale { return nil }
        if let pidLive, !pidLive { return nil }
        let owner = parts[0]
        if owner != cameraMutexOwnerHelios() && owner != cameraMutexOwnerAegis() { return nil }
        return owner
    }

    static func cameraMutexGen(_ text: String) -> UInt32? {
        let parts = text.split(whereSeparator: { $0 == " " || $0 == "\n" }).map(String.init)
        guard parts.count >= 4, let g = UInt32(parts[3]) else { return nil }
        return g
    }

    static func cameraMutexPid(_ text: String) -> Int32? {
        let parts = text.split(whereSeparator: { $0 == " " || $0 == "\n" }).map(String.init)
        guard parts.count >= 2, let p = Int32(parts[1]) else { return nil }
        return p
    }

    static func cameraMutexClaimDue(last: TimeInterval, now: TimeInterval, minDt: TimeInterval = cameraMutexClaimMinDt()) -> Bool {
        now - last >= minDt
    }

    /// Helios hat Continuity-Vorrang. Aegis weicht.
    static func cameraMutexClaimWrites(holder: String?, owner: String) -> Bool {
        if owner == cameraMutexOwnerHelios() { return true }
        if owner == cameraMutexOwnerAegis() {
            return holder == nil || holder == cameraMutexOwnerAegis()
        }
        return false
    }

    static func cameraMutexLockedLine(
        existing: String?,
        owner: String,
        pid: Int32,
        now: TimeInterval,
        pidLive: Bool? = nil,
        pts: TimeInterval? = nil,
        palm: (x: CGFloat, y: CGFloat, w: CGFloat)? = nil
    ) -> String? {
        let holder = existing.flatMap { cameraMutexParse($0, now: now, pidLive: pidLive) }
        guard cameraMutexClaimWrites(holder: holder, owner: owner) else { return nil }
        let gen = ((existing.flatMap { cameraMutexGen($0) }) ?? 0) &+ 1
        return cameraMutexLine(owner: owner, pid: pid, now: now, gen: gen, pts: pts, palm: palm)
    }

    static func cameraMutexChip(holder: String?, yielded: Bool) -> String {
        if yielded { return "MUTEX yield \(holder ?? "—")" }
        if let holder { return "MUTEX \(holder)" }
        return "MUTEX —"
    }

}

/// Safari nur Klick/Scroll, Finder Werfen, Xcode aus. Sonst voll.
enum AppInjectProfile: Equatable {
    case full, clickScroll, finder, off

    var titleDE: String {
        switch self {
        case .full: return "voll"
        case .clickScroll: return "Klick/Scroll"
        case .finder: return "Finder"
        case .off: return "aus"
        }
    }

    static func of(bundleId: String) -> AppInjectProfile {
        // 1.6.17/1.6.21: Profile aus. 1.6.22 hat sie wieder an — Xcode tot, Safari ohne Zug,
        // und CoordTests verlangt gleichzeitig .full und .off.
        _ = bundleId
        return .full
    }

    func allows(_ name: String) -> Bool {
        switch self {
        case .full: return true
        case .off: return false
        case .clickScroll:
            return name == "Klick" || name == "Scroll" || name == "Rechtsklick" || name == "Dwell-Klick"
        case .finder:
            return name == "Klick" || name == "Rechtsklick" || name == "Wegwerfen"
                || name == "Minimieren" || name == "Links andocken" || name == "Rechts andocken"
                || name == "Heranziehen" || name == "Scroll"
        }
    }

    var allowsWindowDrag: Bool {
        switch self {
        case .full, .finder: return true
        case .clickScroll, .off: return false
        }
    }
}

/// mac = Built-in, phone = Kontinuität/Desk View, osmo = USB-Extern.
enum CameraRole: String, CaseIterable {
    case mac, phone, osmo
}

enum CameraPair: String, CaseIterable, Identifiable {
    case single, macPhone, macOsmo, phoneOsmo

    var id: String { rawValue }

    var titleDE: String {
        switch self {
        case .single: return "Eine Kamera"
        case .macPhone: return "Mac + iPhone"
        case .macOsmo: return "Mac + Osmo"
        case .phoneOsmo: return "iPhone + Osmo (ohne Mac)"
        }
    }

    var detailDE: String {
        switch self {
        case .single: return "Nur die gewählte Quelle. Blickwinkel = diese eine Kamera."
        case .macPhone: return "Mac führt. iPhone ergänzt Fingerlage, keine eigenen Aktionen."
        case .macOsmo: return "Mac führt. Osmo ergänzt Fingerlage aus dem zweiten Winkel, keine eigenen Aktionen."
        case .phoneOsmo: return "iPhone führt. Osmo ergänzt den toten Winkel, keine eigenen Aktionen."
        }
    }
}

enum CameraRig {
    static func resolve(pair: CameraPair, mac: String?, phone: String?, osmo: String?) -> (lead: String, cover: String?)? {
        switch pair {
        case .single:
            return nil
        case .macPhone:
            guard let mac, let phone else { return nil }
            return (mac, phone)
        case .macOsmo:
            guard let mac, let osmo else { return nil }
            return (mac, osmo)
        case .phoneOsmo:
            guard let phone, let osmo else { return nil }
            return (phone, osmo)
        }
    }

    /// Cover wird nie Aktor. Nur Lage/Pinch-Bestätigung am Lead.
    static func useCover(
        leadQ: Double,
        coverQ: Double,
        leadN: Int,
        coverN: Int,
        usingCover: Bool
    ) -> Bool {
        _ = (leadQ, coverQ, leadN, coverN, usingCover)
        return false
    }

    static func mapsDisagree(_ a: CGPoint, _ b: CGPoint, limit: CGFloat = GestureMath.rigDisagreePx) -> Bool {
        hypot(a.x - b.x, a.y - b.y) > limit
    }

    /// Cover darf den Zeiger leicht ziehen, nie wegspringen.
    static func blendScreen(_ lead: CGPoint, _ cover: CGPoint) -> CGPoint? {
        if mapsDisagree(lead, cover) { return nil }
        return CGPoint(
            x: lead.x * 0.72 + cover.x * 0.28,
            y: lead.y * 0.72 + cover.y * 0.28
        )
    }

    /// Cover darf Pinch nur im unsicheren Band bestätigen, nie erfinden.
    static func pinchAssist(lead: Double, cover: Double) -> Double {
        guard lead >= 0.40, lead <= 0.62, cover > 0.48 else { return lead }
        return min(1, 0.70 * lead + 0.30 * cover)
    }
}

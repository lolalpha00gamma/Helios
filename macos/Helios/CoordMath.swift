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
    static let pinchClickStillPx: CGFloat = 14
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
    static let keyboardDwell: TimeInterval = 0.12
    static let keyboardRepeat: TimeInterval = 0.20
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
    static func scrollAllowed(openPalms: Int, pinchHeld: Bool) -> Bool {
        if pinchHeld { return false }
        return openPalms == 1
    }

    static func pinchReleaseBlocks(now: TimeInterval, releasedAt: TimeInterval?) -> Bool {
        pinchReleaseBlocks(now: now, releasedAt: releasedAt, dt: 0.016)
    }

    /// 24 fps bleibt 120 ms. 8 fps sonst ein Frame tot — Folge-Klick nach Dropout.
    static func pinchReleaseNeed(dt: TimeInterval) -> TimeInterval {
        max(pinchReleaseDead, min(0.32, max(0.008, dt) * 1.6))
    }

    static func pinchReleaseBlocks(now: TimeInterval, releasedAt: TimeInterval?, dt: TimeInterval) -> Bool {
        guard let t = releasedAt else { return false }
        return now - t < pinchReleaseNeed(dt: dt)
    }

    static func clutchIgnores(delta: CGFloat) -> Bool {
        delta < clutchJiggle
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

    /// Zwei-Pinzetten: IDs sortieren, sonst Vision-Reorder → Span-Sprung.
    static func twoPinchSorted(ids: [String]) -> [String] {
        ids.sorted()
    }

    /// Continuity 8 fps: zwei Fehlframes ≈ 250 ms. 0,18 s hat den Zug getötet.
    /// Pointer-Hold gilt auch ohne Pinzette — sonst stirbt der Zeiger beim Zeigen.
    static func emptyHandsHold(dt: TimeInterval, base: TimeInterval = pinchLockMiss) -> TimeInterval {
        max(base, min(0.45, dt * 2.2))
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
    static func emptyHandsHoldReleaseAX(isDragging: Bool) -> Bool {
        isDragging
    }

    /// Freeze trägt pinchHeld. Hands zurück → Gate-Auf = Klick. AX ist schon frei.
    static func emptyHandsHoldDropsPinch() -> Bool { true }

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

    /// Inertia darf keinen Klick-Start überdecken.
    static func scrollCoastBreaks(pinchHeld: Bool) -> Bool {
        pinchHeld
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
        windowSec: TimeInterval = flingWindow
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
            afterDrag: afterDrag
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
        windowSec: TimeInterval = flingWindow
    ) -> FlingKind {
        guard let last = trail.last else { return .none }
        let slice = trail.filter { last.t - $0.t <= windowSec }
        guard let first = slice.first, last.t > first.t + 0.04 else { return .none }
        let unit = max(0.04, palmWidth)
        let dx = (last.x - first.x) * aspect / unit
        let dy = (last.y - first.y) / unit
        let dist = hypot(dx, dy)
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
            afterDrag: afterDrag
        )
    }

    static func classifyFling(
        dx: CGFloat,
        dy: CGFloat,
        speed: CGFloat,
        dist: CGFloat,
        speedNeed: CGFloat = flingMinSpeed,
        distNeed: CGFloat = flingMinDist,
        afterDrag: Bool = false
    ) -> FlingKind {
        guard speed > speedNeed, dist > distNeed else { return .none }
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

    /// Kurze, stillstehende Pinzette = Klick, nicht Greifen.
    static func isClick(held: TimeInterval, palmMovedHW: CGFloat, cursorMovedPx: CGFloat) -> Bool {
        guard held >= pinchClickMinHold, held <= pinchClickMaxHold else { return false }
        return palmMovedHW < pinchDragNeed && cursorMovedPx < pinchClickStillPx
    }

    static func isDrag(palmMovedHW: CGFloat, cursorMovedPx: CGFloat) -> Bool {
        palmMovedHW >= pinchDragNeed || cursorMovedPx >= 28
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
    static func pinchStartsGrab(gate: Bool, closedness: Double, reach: CGFloat = 1.2, index: Double = 1) -> Bool {
        guard pinchLooksLikePinch(reach: reach, index: index) else { return false }
        return gate || closedness > 0.58
    }

    /// Pinzette halten: weicher, aber Faust (kein Reach) gibt frei — außer Zug darf Faust tragen.
    static func pinchHoldsGrab(
        gate: Bool,
        closedness: Double,
        reach: CGFloat = 1.2,
        index: Double = 1,
        allowFist: Bool = false
    ) -> Bool {
        if !allowFist, !pinchLooksLikePinch(reach: reach, index: index) { return false }
        return gate || closedness > 0.42
    }

    static func pinchLooksLikePinch(reach: CGFloat, index: Double = 1) -> Bool {
        reach >= pinchReachNeed || index >= pinchIndexNeed
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

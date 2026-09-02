import CoreGraphics
import Foundation

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

    /// Trackpad-Beschleunigung: Mini-Zucken bleibt langsam, Wisch wird schneller.
    static func pointerAccelScale(magnitude: CGFloat) -> CGFloat {
        let mag = max(0, magnitude)
        let t = min(1, mag / 0.038)
        return 0.48 + 1.42 * t * t
    }

    static func nearUnitCenter(u: CGFloat, v: CGFloat, radius: CGFloat = 0.22) -> Bool {
        hypot(u - 0.5, v - 0.5) < radius
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
    static let killPalmStill: CGFloat = 0.28
    /// Körperpose: Vision unbekannt → lose (0,72). Vision widerspricht → nur klarer Sieger (0,50).
    static let bodyVoteLoose: Double = 0.72
    static let bodyVoteStrict: Double = 0.50
    static let swipeOpenNeed = 3
    static let thumbsHold: TimeInterval = 0.70
    /// Sitzung 12:59:50: Öffnen nach Pinzette wurde zum Wischen, Rückkehr zur Gegenrichtung.
    static let swipeMuteAfterPinch: TimeInterval = 0.75
    static let swipeReverseLock: TimeInterval = 1.10
    /// 0,18 Handbreiten war Palm-Zittern. Klick braucht eine stillstehende Pinzette.
    static let pinchDragNeed: CGFloat = 0.45
    static let pinchClickMinHold: TimeInterval = 0.05
    static let pinchClickMaxHold: TimeInterval = 0.90
    static let pinchClickStillPx: CGFloat = 14
    static let pinchLockMiss: TimeInterval = 0.22
    static let twoPinchConfirm: TimeInterval = 0.12
    static let twoPinchClosed: CGFloat = 0.55
    static let twoPinchScaleNeed: CGFloat = 0.55
    static let twoPinchReverseMul: CGFloat = 1.8
    static let peaceHold: TimeInterval = 1.10
    static let chromeMagnet: CGFloat = 28
    static let chromeLoupe: CGFloat = 64
    static let calibMinArea: CGFloat = 0.012
    static let calibCornerSep: CGFloat = 0.06
    static let hybridBand: CGFloat = 0.15
    static let clutchOwnRadius: CGFloat = 48
    static let clutchOwnWindow: TimeInterval = 0.12

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
        screenUV: CGPoint? = nil
    ) -> FlingKind {
        guard let last = trail.last else { return .none }
        let window = trail.filter { last.t - $0.t <= flingWindow }
        guard let first = window.first, last.t > first.t + 0.04 else { return .none }
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
        return classifyFling(dx: dx, dy: dy, speed: speed, dist: dist, speedNeed: speedNeed, distNeed: distNeed)
    }

    static func classifyFling(
        dx: CGFloat,
        dy: CGFloat,
        speed: CGFloat,
        dist: CGFloat,
        speedNeed: CGFloat = flingMinSpeed,
        distNeed: CGFloat = flingMinDist
    ) -> FlingKind {
        guard speed > speedNeed, dist > distNeed else { return .none }
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
}

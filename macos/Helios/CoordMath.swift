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
    static let killPalmStill: CGFloat = 0.28
    /// Körperpose: Vision unbekannt → lose (0,72). Vision widerspricht → nur klarer Sieger (0,50).
    static let bodyVoteLoose: Double = 0.72
    static let bodyVoteStrict: Double = 0.50
    static let swipeOpenNeed = 3
    static let thumbsHold: TimeInterval = 0.70
    /// Sitzung 12:59:50: Öffnen nach Pinzette wurde zum Wischen, Rückkehr zur Gegenrichtung.
    static let swipeMuteAfterPinch: TimeInterval = 0.45
    static let swipeReverseLock: TimeInterval = 0.55
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
    static let chromeMagnet: CGFloat = 48
    static let chromeLoupe: CGFloat = 168
    static let chromeSpreadGap: CGFloat = 118
    static let chromeHit: CGFloat = 80
    static let chromeDwellHold: TimeInterval = 0.55
    static let swipeMinDx: CGFloat = 0.55
    static let swipeAxis: CGFloat = 1.15
    static let swipeMinSpeed: CGFloat = 1.8
    static let swipeMinDt: TimeInterval = 0.06
    static let swipeMaxDt: TimeInterval = 0.55
    static let calibMinArea: CGFloat = 0.012
    static let calibCornerSep: CGFloat = 0.06
    static let hybridBand: CGFloat = 0.15
    static let clutchOwnRadius: CGFloat = 48
    static let clutchOwnWindow: TimeInterval = 0.12
    /// Zwei Kameras: gemappte Zeiger > so viele Pixel auseinander = Winkel-Unco, Lead gewinnt.
    static let rigDisagreePx: CGFloat = 140
    static let rigCoverEnter: Double = 0.18
    static let rigCoverExit: Double = 0.12

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

    static let entropyFloorLo: Double = 0.48
    static let entropyFloorHi: Double = 0.60

    /// Flache Verteilung → höherer Floor (0,72), spitze → 0,55 statt hart 0,62.
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

    /// Cover darf Pinch bestätigen, nie erfinden.
    static func pinchAssist(lead: Double, cover: Double) -> Double {
        guard lead > 0.28, cover > 0.40 else { return lead }
        return min(1, 0.70 * lead + 0.30 * cover)
    }
}

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

    /// Quartz Y-down: Ursprung oben links. minY ist die Fensteroberkante, maxY die Unterkante.
    static func quartzTopLeft(_ r: CGRect) -> CGPoint {
        CGPoint(x: r.minX, y: r.minY)
    }
}

enum FlingKind: String {
    case none
    case throwUp
    case minimize
    case dockLeft
    case dockRight
}

/// Eine Quelle für Schwellen. Engine, Tests und HUD lesen dieselben Zahlen.
enum GestureMath {
    static let swipeAxis: CGFloat = 1.8
    static let swipeMinDx: CGFloat = 0.14
    static let swipeMinDt: TimeInterval = 0.16
    static let swipeTrail: TimeInterval = 0.28
    static let killHold: TimeInterval = 0.55
    /// Fallback wenn dt unbekannt. Continuity nutzt pinchClickNeed(dt:).
    static let pinchClickMin: TimeInterval = 0.12
    static let pinchClickMax: TimeInterval = 0.55
    static let pinchDragPalm: CGFloat = 0.05
    static let scaleRel: CGFloat = 0.08
    static let scaleHold: TimeInterval = 0.35
    static let scaleCooldown: TimeInterval = 0.50
    /// Absolute Totzone zwischen den Palmen — Rel 0,08 allein zittert bei engem Abstand.
    static let scalePalmDead: CGFloat = 0.04
    static let flingAxis: CGFloat = 1.4
    static let flingMinSpeed: CGFloat = 0.38
    static let flingMinDist: CGFloat = 0.08
    /// Unter flingMinSpeed, aber schnell genug: kein Klick (sonst „fast Wurf“ klickt).
    static let flingClickGuard: CGFloat = 0.70
    /// 0,005 ließ Atem/Schulter als 20–40 px Cursor durch. 0,014 schluckt Jitter.
    static let palmDead: CGFloat = 0.014
    static let palmDeadRest: CGFloat = 0.008
    static let palmDeadTense: CGFloat = 0.020
    /// Adaptive Totzone aus Jitter um den Median. Flick hat hohen Median, jit=0 → Rest 0,008.
    /// Zittrige Hand: Median klein, Abweichung groß → bis 0,020.
    /// RMS nach einem Flick bleibt 0,020 für das ganze Fenster. MAD ignoriert den Ausreißer.
    static func palmDeadWindow(dt: TimeInterval) -> Int { dt >= 0.08 ? 6 : 12 }

    static func palmDeadAdaptive(
        _ steps: [CGFloat],
        rest: CGFloat = palmDeadRest,
        tense: CGFloat = palmDeadTense,
        window: Int = 12
    ) -> CGFloat {
        let mad = palmMad(steps, window: window)
        if mad <= 0, Array(steps.suffix(max(3, window))).filter({ $0 >= 0 }).count < 3 {
            return palmDead
        }
        return min(tense, max(rest, rest + mad * 1.6))
    }
    /// Totzone einer Achse. Hypot-Dead 0,020 schluckt X-Flick 0,015 während Y atmet.
    static func palmDeadOf(mad: CGFloat, rest: CGFloat = palmDeadRest, tense: CGFloat = palmDeadTense) -> CGFloat {
        if mad <= 0 { return rest }
        return min(tense, max(rest, rest + mad * 1.6))
    }
    /// MAD einer Achse. Hypot-MAD hebt Q auf X und Y — Atem in Y wird Flick in X.
    static func palmMad(_ steps: [CGFloat], window: Int = 12) -> CGFloat {
        let ok = Array(steps.suffix(max(3, window))).filter { $0 >= 0 }
        guard ok.count >= 3 else { return 0 }
        let sorted = ok.sorted()
        let median = sorted[sorted.count / 2]
        let absd = ok.map { abs($0 - median) }.sorted()
        return absd[absd.count / 2]
    }

    static let palmStill: CGFloat = 0.012
    static let palmUnstill: CGFloat = 0.022
    static let palmStillHold: TimeInterval = 0.22
    /// Per-Achse Aufwachen. Hypot-Unstill 0,022 schluckt X-Flick 0,015 während Y atmet.
    static let palmUnstillAxis: CGFloat = 0.014

    /// HOLD-Eingang: beide Achsen tot.
    /// Atem/Schulter: langsamer Anteil raus. Cursor folgt dem Flick, nicht der Atmung.
    static let palmHighpassAlphaDefault: CGFloat = 0.15

    /// Pref 0,08–0,25. 0,15 schluckt Schulter; 0,08 lässt Atem durch.
    static func palmHighpassAlpha(_ pref: CGFloat) -> CGFloat {
        min(0.25, max(0.08, pref))
    }

    static func palmHighpass(dx: CGFloat, slow: CGFloat, alpha: CGFloat = 0.15) -> (fast: CGFloat, slow: CGFloat) {
        let a = palmHighpassAlpha(alpha)
        let next = slow + a * (dx - slow)
        return (dx - next, next)
    }

    static func palmStillOf(dx: CGFloat, dy: CGFloat, still: CGFloat = palmStill) -> Bool {
        abs(dx) < still && abs(dy) < still
    }

    /// HOLD-Ausgang: eine Achse flickt. Hypot 0,019 < 0,022 wacht sonst nicht auf.
    static func palmUnstillOf(dx: CGFloat, dy: CGFloat, axis: CGFloat = palmUnstillAxis) -> Bool {
        abs(dx) >= axis || abs(dy) >= axis
    }
    static let missingTipsOpen: TimeInterval = 0.32
    static let rearmHold: TimeInterval = 0.85
    static let armHold: TimeInterval = 0.55
    static let clickCooldown: TimeInterval = 0.16
    static let swipeCooldown: TimeInterval = 0.45
    static let killCooldown: TimeInterval = 0.80
    static let armCooldown: TimeInterval = 0.40
    static let peaceHold: TimeInterval = 0.55
    static let thumbsHold: TimeInterval = 0.55
    static let deadMan: TimeInterval = 8.0
    /// Faust weg: Idle nach 1,6 s statt 8 s tote Hand. bugfix 1.5.8, Pref auf main.
    static let deadManFist: TimeInterval = 1.6
    static let flingCenter: CGFloat = 0.18
    /// Homographie: 0,86 folgte dem Jitter. 0,55 glättet ohne den Zeiger zu ertränken.
    static let mapSmooth: CGFloat = 0.55
    /// Klick nur wenn der Cursor seit Gate-Schluss unter dieser Distanz (Quartz-px) blieb.
    static let pinchClickMaxPx: CGFloat = 12
    /// Continuity / Relativzeiger: hart 12 px tötet Klicks durch Jitter.
    static func pinchClickTravelPx(dt: TimeInterval, mapped: Bool, palmScale: CGFloat = 0.12) -> CGFloat {
        var px = pinchClickMaxPx
        if !mapped { px += 8 }
        if dt >= 0.08 { px += 8 }
        if palmScale < 0.08 { px += 6 }
        return min(36, px)
    }
    /// Palm-Speed während pinchClickMin: darüber kein Down (sonst Klick mitten im Flick).
    static let pinchDownSpeed: CGFloat = 0.20
    /// Einhand-Wischen muss deutlich größer sein als Cursor-Gain, sonst App-Wechsel beim Zielen.
    static let swipeVsPointerMul: CGFloat = 2.2
    /// Unbekannte Chirality: Palmen näher als das gelten als dieselbe Hand.
    static let unknownPalmBind: CGFloat = 0.22
    static let mapDriftResidual: CGFloat = 480
    static let mapDriftHold: TimeInterval = 2.0
    /// Wurf-Geschwindigkeit nur aus dem letzten Fenster, nicht 0,5 s Halten.
    static let flingWindow: TimeInterval = 0.12
    /// Pinzette + Hand zu sich (Vision-Y fällt) = Fenster füllen. Nicht Mittelfinger-Spannweite.
    static let pullToward: CGFloat = 0.11
    /// Unter diesem Luma keine Vision — tote Frames, GPU sparen.
    static let lumaSkip: CGFloat = 0.08
    /// Nach beiden offenen Händen kurz blocken, nicht 280 ms tot.
    static let killGrace: TimeInterval = 0.14
    /// Nach Grab-Abbruch (Hand weg) nicht im selben Tick die andere Hand erben.
    static let grabAbortHold: TimeInterval = 0.22
    /// Peace bricht ab, wenn die Hand den Bildrand verlässt.
    static let peaceEdge: CGFloat = 0.08
    /// Overlay-Skelett nach Dunkel leeren — die letzte Pose nicht einfrieren.
    static let overlayDarkHold: TimeInterval = 0.40
    /// Homographie-Residual: ab hier Gain dämpfen (Quartz-px).
    static let mapGainStart: CGFloat = 240
    /// Bei Residual ≥ mapDriftResidual bleibt dieser Anteil vom Follow.
    static let mapGainFloor: CGFloat = 0.35
    /// Fling-Fenster mindestens so, und mindestens 2,5 × Median-dt (8 fps).
    static let flingWindowMul: CGFloat = 2.5
    /// Wisch-Fenster: 3,2 × Median-dt, sonst 8 fps nur 2 Samples.
    static let swipeTrailMul: CGFloat = 3.2
    /// Sample-dt-Deckel: 8 fps ≈ 125 ms, 0,08 hat PinchGate/Smoother erwürgt.
    static let sampleDtCap: TimeInterval = 0.20
    /// Slot ohne Observation: 0,22 s (Abort-Hold) tötete S1 bei einem Continuity-Frame.
    static let slotHold: TimeInterval = 0.60
    /// S1 nach Pause bleibt S1. expire 0,60 mintet S3 sobald Continuity länger dunkel ist.
    static let slotLatch: TimeInterval = 4.0
    /// Map-Sprung > 80 px in 1 Frame = Vision-Dropout, nicht die Hand.
    static let cursorWarpPx: CGFloat = 80
    /// Continuity/Desk-View: Vision-Confidence oft 0,12–0,18.
    static let continuityConfidence: Float = 0.12
    static let builtInConfidence: Float = 0.18
    /// Faust-Scharf nur wenn die Hand vorher wirklich offen war.
    static let openBeforeArm = 2
    /// Ohne Hand vergisst sawOpen, sonst gilt eine alte Öffnung ewig.
    static let openMemory: TimeInterval = 2.0
    /// Relativzeiger: 8 fps extra dämpfen (Kompression).
    static let continuityGainMul: CGFloat = 0.72
    /// Unter 6 fps fünf Sekunden: Banner + Gain-Mul.
    static let watchdogFps: Double = 6
    static let watchdogHold: TimeInterval = 5
    static let watchdogGain: CGFloat = 0.50
    /// Homographie: 8 fps etwas höherer Alpha, sonst hängt der Zeiger.
    static let mapSmoothContinuity: CGFloat = 0.67

    /// Peace ist Screenshot, nicht App-Wechsel. openScore ≥ 2 wäre Peace.
    static func swipeEligible(isOpenPalm: Bool, isPeace: Bool, openScore: Int, openOnly: Bool = false) -> Bool {
        if isPeace { return false }
        if openOnly { return isOpenPalm }
        return isOpenPalm || openScore >= 3
    }

    /// Zwei-Pinzetten-Scale zählt PinchGate, nicht Classifier-Faust-als-Pinch.
    static func scaleHandCount(closed: [Bool]) -> Int {
        closed.filter { $0 }.count
    }

    /// Zwei PinchGates gewinnen immer — auch wenn die erste Hand schon pinchHeld gesetzt hat.
    /// Lose zweite Faust zählt nicht (nur PinchGate / pinchClosed).
    static func scaleBlocksGrab(pinchHeld: Bool, closedCount: Int) -> Bool {
        _ = pinchHeld
        return closedCount >= 2
    }

    /// Cooldown darf den Span nicht auffressen, sonst feuert Scale nach dem Gate nie.
    static func scaleKeepsSpan(old: CGFloat, span: CGFloat, gated: Bool) -> CGFloat {
        gated ? old : span
    }

    /// Wisch-Grace: dieselbe Hand, nicht `hands.first` (sonst Faust/Pinzette wischt).
    static func swipeGraceID(openID: String?, lastID: String?, lastStillPresent: Bool) -> String? {
        if let openID { return openID }
        if lastStillPresent { return lastID }
        return nil
    }

    /// Ghost-Tick darf Rebase nicht verbrauchen — sonst teleportiert der erste Live-Frame.
    static func ghostLeavesRebase() -> Bool { true }

    /// Knie/Schulter am Bildrand zünden Not-Aus. Nur Palmen im Innenraum zählen.
    static let killEdge: CGFloat = 0.08

    static func killCounts(x: CGFloat, y: CGFloat, edge: CGFloat = killEdge) -> Bool {
        x >= edge && x <= 1 - edge && y >= edge && y <= 1 - edge
    }

    /// Not-Aus-Windup und Grace dürfen den Cursor nicht frieren.
    static func killKeepsCursor() -> Bool { true }

    /// Klick-Up ohne Drag immer am Down-Punkt. lastPosted nach Jitter klickt durchs Fenster.
    static func clickReleasePoint(down: CGPoint, current: CGPoint, wasDrag: Bool) -> CGPoint {
        wasDrag ? current : down
    }

    /// HUD-Ring während pinchClickMin. 0 = Gate-Schluss, 1 = Down erlaubt.
    static func clickSettleProgress(held: TimeInterval, need: TimeInterval = pinchClickMin) -> CGFloat {
        guard need > 0 else { return 1 }
        return min(1, max(0, CGFloat(held / need)))
    }

    /// CAShapeLayer.strokeEnd: nil = voll, sonst 4 % Minimum damit der Ring sichtbar startet.
    static func clickSettleStrokeEnd(_ progress: CGFloat?) -> CGFloat {
        guard let progress else { return 1 }
        return min(1, max(0.04, progress))
    }

    /// Während Pinch gehalten: Atmen (ratio 0,34–0,48) darf den Grab nicht töten.
    static let pinchKeepRatio: CGFloat = 0.48

    /// Ferne Hand (klein) atmet lauter — Gate weicher. Stetig, nicht nur < 0,08.
    static func pinchCloseRatio(scale: CGFloat) -> CGFloat {
        let lo: CGFloat = 0.06
        let hi: CGFloat = 0.12
        if scale <= lo { return 0.40 }
        if scale >= hi { return 0.33 }
        let t = (scale - lo) / (hi - lo)
        return 0.40 + (0.33 - 0.40) * t
    }

    static func pinchKeepRatioFor(scale: CGFloat) -> CGFloat {
        let lo: CGFloat = 0.06
        let hi: CGFloat = 0.12
        if scale <= lo { return 0.56 }
        if scale >= hi { return pinchKeepRatio }
        let t = (scale - lo) / (hi - lo)
        return 0.56 + (pinchKeepRatio - 0.56) * t
    }

    /// Loslassen ohne Vel: 0,58 nahe / 0,64 fern. 0,54∧0,62 ließ 8 fps nach dem ersten Sample kleben.
    static func pinchOpenRatio(scale: CGFloat) -> CGFloat {
        scale < 0.08 ? 0.64 : 0.58
    }

    static func pinchWantOpen(
        ratio: CGFloat,
        proxRatio: CGFloat,
        vel: CGFloat,
        dt: TimeInterval,
        scale: CGFloat
    ) -> Bool {
        let keep = pinchKeepRatioFor(scale: scale)
        let openR = pinchOpenRatio(scale: scale)
        // 8 fps und Continuity 15 fps: ratio-only + Need 1 = ein Sample öffnet.
        // Extra-Margin, Vel bleibt. 24 fps (dt < 0,055) bleibt openR.
        let openNeed = dt >= 0.055 ? openR + 0.06 : openR
        return ratio > keep && proxRatio > keep - 0.06 && (
            vel > pinchOpenVel(dt: dt) || ratio > openNeed
        )
    }

    static func pinchKeepsGrab(
        held: Bool,
        closed: Bool,
        ratio: CGFloat,
        fisting: Bool,
        rebind: Bool,
        palmScale: CGFloat = 0.12
    ) -> Bool {
        if rebind { return true }
        if closed { return true }
        let keep = pinchKeepRatioFor(scale: palmScale)
        if held {
            if ratio < keep { return true }
            if fisting && ratio < keep + 0.07 { return true }
            return false
        }
        return fisting && ratio < pinchCloseRatio(scale: palmScale) + 0.01
    }

    /// CGWindowList: HUD-Overlay (layer ≠ 0) nie. Eigenes ControlPanel (layer 0) nur wenn skipSelf false.
    static func cgWindowIsGrabTarget(pid: Int32, layer: Int, skipSelf: Bool, selfPID: Int32) -> Bool {
        guard pid != 0 else { return false }
        guard layer == 0 else { return false }
        if skipSelf, pid == selfPID { return false }
        return true
    }

    /// CGWindowList `kCGWindowBounds` kommt als CFDictionary mit NSNumber, nicht `[String: CGFloat]`.
    static func windowListRect(_ raw: Any?) -> CGRect? {
        if let r = raw as? CGRect {
            return r.width > 0 && r.height > 0 ? r : nil
        }
        guard let d = raw as? [String: Any] else { return nil }
        func num(_ key: String) -> CGFloat? {
            if let v = d[key] as? CGFloat { return v }
            if let v = d[key] as? Double { return CGFloat(v) }
            if let v = d[key] as? Float { return CGFloat(v) }
            if let v = d[key] as? Int { return CGFloat(v) }
            if let v = d[key] as? Int64 { return CGFloat(v) }
            if let v = d[key] as? NSNumber { return CGFloat(v.doubleValue) }
            return nil
        }
        guard let x = num("X"), let y = num("Y"), let w = num("Width"), let h = num("Height") else {
            return nil
        }
        guard w > 0, h > 0 else { return nil }
        return CGRect(x: x, y: y, width: w, height: h)
    }

    /// AX SetAttributeValue kann `.success` liefern ohne dass das Fenster sich bewegt (SwiftUI/Electron).
    static let axWriteSlop: CGFloat = 12

    static func axWriteTook(want: CGPoint, got: CGPoint, slop: CGFloat = axWriteSlop) -> Bool {
        hypot(want.x - got.x, want.y - got.y) <= slop
    }

    static func axWriteTook(want: CGSize, got: CGSize, slop: CGFloat = axWriteSlop) -> Bool {
        abs(want.width - got.width) <= slop && abs(want.height - got.height) <= slop
    }

    /// Skip-AX: letzten echten Probe behalten. Leere Probe nicht in den Cache.
    static func skipProbeStoresEmpty() -> Bool { false }

    /// Release-Klick nach Dunkel: derselbe Latch wie Down.
    static func releaseBlockedBySkipAX(blockPress: Bool) -> Bool { blockPress }

    /// Button/Link/Feld: immer Klick, nie Fenster-Drag.
    static func axLocksClick(_ role: String?) -> Bool {
        guard let role, !role.isEmpty else { return false }
        switch role {
        case "AXButton", "AXLink", "AXCheckBox", "AXRadioButton", "AXPopUpButton",
             "AXMenuItem", "AXMenuButton", "AXTextField", "AXTextArea", "AXComboBox",
             "AXSlider", "AXIncrementor", "AXDisclosureTriangle", "AXTabButton",
             "AXSearchField", "AXSwitch", "AXDockItem", "AXMenuBarItem", "AXMenuBar",
             "AXMenu", "AXMenuExtra", "AXToolbarButton", "AXColorWell":
            return true
        default:
            return role.contains("Button") || role.contains("Link")
        }
    }

    /// Dock/Menü: Traffic-Lights der Fenster-Titelzeile sind tot — kein zweites AX-Walk.
    static func axChromeSkipsTraffic(_ role: String?) -> Bool {
        switch role ?? "" {
        case "AXDockItem", "AXMenuBarItem", "AXMenuBar", "AXMenu", "AXMenuExtra":
            return true
        default:
            return false
        }
    }

    /// Close/Mini/Zoom: Rolle ist AXButton, Subrole entscheidet den Magnet.
    static func axSubroleLocksClick(_ subrole: String?) -> Bool {
        guard let subrole, !subrole.isEmpty else { return false }
        switch subrole {
        case "AXCloseButton", "AXMinimizeButton", "AXZoomButton", "AXFullScreenButton":
            return true
        default:
            return subrole.contains("Button")
        }
    }

    /// Down/Up in der AX-Mitte, nicht am Rand nach Jitter. pad in Quartz-px.
    /// Große AX-Gruppen/Fenster: kein Warp zur Mitte — sonst landet jeder Klick im Fensterzentrum.
    static let pressMaxShift: CGFloat = 56

    static func pressTarget(
        cursor: CGPoint,
        frame: CGRect?,
        pad: CGFloat = 8,
        maxShift: CGFloat = pressMaxShift
    ) -> CGPoint {
        guard let frame, frame.width > 2, frame.height > 2 else { return cursor }
        let hit = frame.insetBy(dx: -pad, dy: -pad)
        guard hit.contains(cursor) else { return cursor }
        let mid = CGPoint(x: frame.midX, y: frame.midY)
        if hypot(mid.x - cursor.x, mid.y - cursor.y) > maxShift { return cursor }
        return mid
    }

    /// Overlay-Ring über der Hardware-Maus verdeckt den echten Cursor.
    static func overlayShowsCursor(mousePaused: Bool) -> Bool { !mousePaused }

    /// Nächster Traffic-Light innerhalb maxDist. Sonst nil — Titelbalken bleibt Drag.
    static func trafficSnap(cursor: CGPoint, lights: [CGPoint], maxDist: CGFloat) -> CGPoint? {
        var best: CGPoint?
        var bestD = maxDist
        for p in lights {
            let d = hypot(p.x - cursor.x, p.y - cursor.y)
            if d < bestD {
                bestD = d
                best = p
            }
        }
        return best
    }

    static let trafficMagnetPx: CGFloat = 36
    static let trafficMagnetPalm: CGFloat = 0.30

    static func trafficMaxDist(palmScale: CGFloat, screenWidth: CGFloat = 1440) -> CGFloat {
        max(trafficMagnetPx, trafficMagnetPalm * palmScale * screenWidth)
    }

    /// HUD wenn Klick gelockt — sonst wirkt der stillstehende Cursor tot.
    /// Traffic-Lights: MAGNET, damit Pinch neben Close nicht wie ein toter Hover wirkt.
    static func clickLockLabel(locks: Bool, magnet: Bool = false) -> String {
        if magnet { return "MAGNET" }
        return locks ? "BUTTON" : "Halten"
    }

    /// Down nur auf Control. Fenster-Fläche: Down nach 120 ms + cancelPress-Up = Klick, dann Drag.
    static func pressDuringHold(locksClick: Bool) -> Bool { locksClick }

    /// Fenster-Drag: Ursprung 12 px am sichtbaren Rand → bündig, ohne Wurf.
    static let edgeMagnetPad: CGFloat = 12

    static func edgeMagnet(origin: CGPoint, size: CGSize, vis: CGRect, pad: CGFloat = edgeMagnetPad) -> CGPoint {
        guard vis.width > 8, vis.height > 8 else { return origin }
        var p = origin
        let maxX = vis.maxX - size.width
        let maxY = vis.maxY - size.height
        if abs(p.x - vis.minX) <= pad { p.x = vis.minX }
        else if abs(p.x - maxX) <= pad { p.x = maxX }
        if abs(p.y - vis.minY) <= pad { p.y = vis.minY }
        else if abs(p.y - maxY) <= pad { p.y = maxY }
        return p
    }

    /// Vor Gate: ratio 0,55 → 0,28. nil = keine Hover-Vorschau.
    static let pinchHoverOpen: CGFloat = 0.55
    static let pinchHoverShut: CGFloat = 0.28

    static func pinchHoverProgress(ratio: CGFloat, closed: Bool) -> CGFloat? {
        if closed { return nil }
        if ratio >= pinchHoverOpen { return nil }
        let span = pinchHoverOpen - pinchHoverShut
        let t = (pinchHoverOpen - ratio) / max(0.04, span)
        return min(1, max(0, t))
    }

    /// Letzte fps-Samples als Spark. 8 fps ▂, 24 fps ▆.
    static func fpsSpark(_ samples: [Double], low: Double = 6, high: Double = 30) -> String {
        guard !samples.isEmpty else { return "" }
        let bars = Array("▁▂▃▄▅▆▇█")
        return samples.suffix(8).map { v -> String in
            let t = (v - low) / max(1, high - low)
            let i = min(bars.count - 1, max(0, Int((t * Double(bars.count - 1)).rounded())))
            return String(bars[i])
        }.joined()
    }

    /// Trackpad-Kurve: kleine Palm-Wege dämpfen, große flickig.
    static func pointerAccel(_ d: CGFloat) -> CGFloat {
        let a = abs(d)
        if a < 1e-6 { return 0 }
        let t = min(1, a / 0.10)
        let mul = 0.55 + 0.90 * t * t
        return d * mul
    }

    /// Ferne kleine Palmen (Continuity am Schreibtisch) brauchen mehr Gain.
    static func depthGain(palmScale: CGFloat) -> CGFloat {
        max(1, min(2.4, 0.12 / max(0.035, palmScale)))
    }

    /// Kalibrierung außerhalb Testmodus blockt Scharf — sonst zündet Faust die Ecken.
    static func calibBlocksArm(active: Bool, testMode: Bool) -> Bool {
        active && !testMode
    }

    /// Not-Aus-Ring auf jedem Display, nicht nur Fill auf Primary.
    static func killRingOnAllDisplays() -> Bool { true }

    /// Still-Clutch während Pinch/Down: die Hand ist 0,22 s still — Cursor stirbt nach Klick.
    static func clutchWhilePinch(pinchHeld: Bool, mouseDown: Bool) -> Bool {
        !(pinchHeld || mouseDown)
    }

    /// Gate-Schluss: Rolle unter dem Cursor, nicht die vom Pinch-Start (Zielen in 120 ms).
    static func hitLocksAtGate(startLocked: Bool, gateLocked: Bool, settled: Bool) -> Bool {
        settled ? gateLocked : startLocked
    }

    /// Homographie: kleine Palm-Wege dämpfen Follow. pointerAccel galt nur dem Relativzeiger.
    static func mapFollowMul(_ palmDelta: CGFloat) -> CGFloat {
        let a = abs(palmDelta)
        if a < 1e-6 { return 0 }
        let t = min(1, a / 0.10)
        return 0.45 + 0.55 * t * t
    }

    /// Settle darf zielen. Freeze nur Abort oder Down auf Button (sonst Drag statt Klick).
    static func pointerFrozenWhile(
        abortHold: Bool,
        mouseDown: Bool,
        clickLocked: Bool,
        becameDrag: Bool
    ) -> Bool {
        if abortHold { return true }
        if becameDrag { return false }
        return mouseDown && clickLocked
    }

    /// Klick-Weg nach Gate, nicht vom Pinch-Start — sonst tötet Zielen pinchClickMaxPx.
    static func cursorTravelOrigin(start: CGPoint?, gate: CGPoint?, settled: Bool) -> CGPoint? {
        settled ? (gate ?? start) : start
    }

    /// Nach Klick/Loslassen 0,35 s kein Still-Clutch — die Hand ruht, der Zeiger darf.
    static let clutchGraceHold: TimeInterval = 0.35

    static func clutchInGrace(now: TimeInterval, until: TimeInterval) -> Bool {
        until > 0 && now < until
    }

    static func clutchHUD(frozen: Bool) -> String? {
        frozen ? "CLUTCH" : nil
    }

    /// Continuity 8 fps = 125 ms. 2 Frames Cache, sonst jeder zweite Tick tot.
    static func axProbeTTL(dt: TimeInterval) -> TimeInterval {
        dt >= 0.08 ? 0.26 : 0.09
    }

    /// Luma-Skip / kein Vision: AX nicht anfassen. Sonst Roundtrip auf totem Cursor.
    static func axProbeSkip(visionRan: Bool) -> Bool { !visionRan }

    /// Vision > 18 ms: Probe skip, Cursor läuft. AX auf Main sonst 20–50 ms extra.
    /// 8 fps (dt ≥ 80 ms): 125 ms Budget, AX passt — Skip würde MAGNET/BUTTON totlegen.
    static let axBudgetMs: Double = 18

    static func axBudgetSkip(visionMs: Double, dt: TimeInterval = 0.016) -> Bool {
        if dt >= 0.08 { return false }
        return visionMs > axBudgetMs
    }

    /// 8 fps: hart 120 ms = Down im ersten Frame, Zielen tot.
    /// 24 fps: 90 ms, nicht 120 — sonst klebt der Hover.
    /// 15 fps (dt 0,055–0,08): zwischen 90 und 180 interpolieren, nicht die 24er Need.
    /// Engine reicht Median-dt, nicht den Spike-Frame.
    /// Speed: Flick streckt Need, Zielen (still) bleibt kurz.
    /// Open-Need in Frames × dt: 15 fps 2 Frames = 110 ms, interpolierte 90 ms feuert sonst vor Gate.
    static func pinchClickNeed(dt: TimeInterval, speed: CGFloat = 0) -> TimeInterval {
        let base: TimeInterval
        if dt >= 0.08 {
            base = 0.18
        } else if dt >= 0.055 {
            let t = min(1, max(0, (dt - 0.055) / 0.025))
            base = 0.09 + 0.09 * t
        } else {
            base = 0.09
        }
        var need = base
        if speed >= pinchDownSpeed {
            need = min(pinchClickMax, base + 0.12)
        } else if speed > palmStill {
            let t = min(1, speed / pinchDownSpeed)
            need = base + TimeInterval(0.12 * t)
        }
        let open = TimeInterval(pinchOpenNeed(dt: dt)) * max(0.008, dt)
        return max(need, open)
    }

    /// Letzte 8 Sample-dts. Ein 200-ms-Spike darf Need nicht auf 180 ms kippen.
    static func medianSampleDt(_ dts: [TimeInterval], fallback: TimeInterval = 0.016) -> TimeInterval {
        let ok = dts.filter { $0 > 0.004 }
        guard !ok.isEmpty else { return fallback }
        let sorted = ok.sorted()
        return sorted[sorted.count / 2]
    }

    /// Zwei-Hand-Scale analog Need. Continuity erstes Tick (125 ms) darf nicht skalieren.
    static func scaleSettleNeed(dt: TimeInterval) -> TimeInterval {
        dt >= 0.08 ? 0.35 : 0.18
    }

    /// meanConfidence über alle Joints lässt eine tote Spitze durch — Gate schließt falsch.
    static let pinchTipFloor: Float = 0.18
    /// Vision liefert bei Occlusion oft einen Phantom-Tip 0,19–0,35 statt nil.
    static let pinchOcclusionFloor: Float = 0.40

    /// Continuity/8 fps: Tip 0,12 ist live, Floor 0,18 war Dropout.
    static func pinchTipFloorOf(dt: TimeInterval, continuity: Bool = false) -> Float {
        (dt >= 0.08 || continuity) ? 0.10 : pinchTipFloor
    }

    static func pinchTipConfidenceOk(thumb: Float?, index: Float?, floor: Float = pinchTipFloor) -> Bool {
        guard let thumb, let index else { return false }
        return thumb >= floor && index >= floor
    }

    /// Während Pinch-Drag: HUD FLING bevor Loslassen wirft. Sonst nur „Ziehen“.
    static func flingGhost(kind: FlingKind, dragging: Bool) -> Bool {
        dragging && kind != .none
    }

    static func flingGhostLabel(_ kind: FlingKind) -> String? {
        switch kind {
        case .none: return nil
        case .throwUp: return "FLING ↑"
        case .minimize: return "FLING ↓"
        case .dockLeft: return "FLING ←"
        case .dockRight: return "FLING →"
        }
    }

    /// Continuity hängt bei dt > 200 ms vier Sekunden: Format neu, Gain-Halbierung reicht nicht.
    static func continuityStuck(dt: TimeInterval, hold: TimeInterval) -> Bool {
        dt > 0.20 && hold >= 4.0
    }

    static func continuityReselectCooldown() -> TimeInterval { 8.0 }

    /// iPhone-Lock: Roh-dt > 400 ms für 2 s → Format neu. sampleDtCap 200 ms würde nie feuern.
    static func continuityLockRetry(dt: TimeInterval, hold: TimeInterval) -> Bool {
        dt > 0.40 && hold >= 2.0
    }

    /// Ungedeckelt. Need/Smoother bleiben hinter sampleDtCap.
    static func rawFrameDt(now: TimeInterval, last: TimeInterval) -> TimeInterval {
        last == 0 ? 0.016 : max(0.008, now - last)
    }

    /// Homographie je Kamera und Display. Continuity/Built-in und Laptop/Extern sonst eine Map.
    static func spaceMapKey(_ cameraID: String?, screenID: String? = nil) -> String {
        let cam = (cameraID?.isEmpty == false) ? cameraID : nil
        let scr = (screenID?.isEmpty == false) ? screenID : nil
        switch (cam, scr) {
        case let (c?, s?): return "helios.spaceMap.\(c).\(s)"
        case let (c?, nil): return "helios.spaceMap.\(c)"
        case let (nil, s?): return "helios.spaceMap.screen.\(s)"
        case (nil, nil): return "helios.spaceMap"
        }
    }

    /// Zweite Faust (andere Hand) bricht Pinch wie Escape — ohne Klick.
    static func fistCancelsHold(pinchHeld: Bool, otherFist: Bool) -> Bool {
        pinchHeld && otherFist
    }

    /// Cmd-Punkt (keyCode 47 + Command) = Escape.
    static func cmdPeriodCancels(keyCode: UInt16, command: Bool) -> Bool {
        keyCode == 47 && command
    }

    /// Nach Gate: Lock folgt dem Control unter dem Zeiger.
    static func clickLockRefresh(settled: Bool, wasLocked: Bool, nowLocked: Bool) -> Bool {
        settled ? nowLocked : wasLocked
    }

    /// AX flackert 2 Frames auf Safari-Toolbar: BUTTON nicht droppen.
    static let clickLockMissFrames = 2

    static func clickLockMissHold(
        wasLocked: Bool,
        nowLocked: Bool,
        misses: Int,
        hold: Int = clickLockMissFrames
    ) -> (locked: Bool, misses: Int) {
        if nowLocked { return (true, 0) }
        if wasLocked && misses < hold { return (true, misses + 1) }
        return (false, 0)
    }

    /// Up nur wenn dasselbe Control noch unter dem Punkt liegt.
    /// Down auf Close, Up auf Mini = cancelPress, kein Klick.
    static func samePressElement(
        downRole: String?,
        downSub: String?,
        nowRole: String?,
        nowSub: String?
    ) -> Bool {
        let downLock = axLocksClick(downRole) || axSubroleLocksClick(downSub)
        if !downLock { return true }
        return downRole == nowRole && downSub == nowSub
    }

    /// Overlay-Ring um Close/Mini/Zoom. Radius in Quartz-px.
    static let trafficRingRadius: CGFloat = 11

    static func trafficLightRings(lights: [CGPoint], magnet: Bool) -> [(CGPoint, CGFloat)] {
        guard magnet, !lights.isEmpty else { return [] }
        return lights.map { ($0, trafficRingRadius) }
    }

    /// Klick-Settle: Bewegung vor pinchClickMin ist Zielen, nicht Drag.
    static func pinchSettled(held: TimeInterval, need: TimeInterval = pinchClickMin) -> Bool {
        held >= need
    }

    static func pinchDragMoved(from: CGPoint, to: CGPoint) -> Bool {
        hypot(to.x - from.x, to.y - from.y) > pinchDragPalm
    }

    static func isHorizontalSwipe(dx: CGFloat, dy: CGFloat, dt: TimeInterval, medianDt: TimeInterval = 0.016) -> Bool {
        dt > swipeMinDt(medianDt: medianDt) && abs(dx) > swipeMinDx && abs(dx) > abs(dy) * swipeAxis
    }

    /// 8 fps: 2 Samples spannen 125 ms < 160 ms — Wischen war tot. minDt folgt dem Takt.
    static func swipeMinDt(medianDt: TimeInterval) -> TimeInterval {
        min(Self.swipeMinDt, max(0.08, 0.95 * medianDt))
    }

    /// PinchGate Close-Vel: −2 bei 16 ms. 8 fps sonst nie (ein Frame = 125 ms).
    static func pinchCloseVel(dt: TimeInterval) -> CGFloat {
        let scale = max(1, CGFloat(dt) / 0.016)
        return -2.0 / min(scale, 8)
    }

    /// PinchGate Open-Vel: +0,40 bei 16 ms (24 fps öffnet sonst zu leicht), weicher bei 8 fps.
    static func pinchOpenVel(dt: TimeInterval) -> CGFloat {
        let scale = max(1, CGFloat(dt) / 0.016)
        return 0.40 / min(scale, 8)
    }

    static func confidenceFloor(fallback: Bool) -> Float {
        fallback ? continuityConfidence : builtInConfidence
    }

    static func pointerGainMul(dt: TimeInterval) -> CGFloat {
        dt >= 0.10 ? continuityGainMul : 1
    }

    static func watchdogGainMul(slow: Bool) -> CGFloat {
        slow ? watchdogGain : 1
    }

    static func mapSmoothAlpha(dt: TimeInterval) -> CGFloat {
        dt >= 0.10 ? mapSmoothContinuity : mapSmooth
    }

    /// PinchGate Open-Streak: 8 fps Vel 1 Frame, ratio-only 2 (ein Jitter öffnet sonst).
    /// 15 fps Continuity: 2, nicht die 24er 3 — sonst 200 ms klebrig.
    /// 24 fps 3 (ein Rauschen öffnet nicht).
    static func pinchOpenNeed(dt: TimeInterval, ratioOnly: Bool = false) -> Int {
        if dt >= 0.08 { return ratioOnly ? 2 : 1 }
        if dt >= 0.055 { return 2 }
        return 3
    }

    /// Open-Need in Sekunden — dieselbe Uhr wie pinchClickNeed, nicht Frames vs ms.
    static func pinchOpenNeedSec(dt: TimeInterval, ratioOnly: Bool = false) -> TimeInterval {
        let step = max(0.016, dt <= 0 ? 0.016 : dt)
        return TimeInterval(pinchOpenNeed(dt: dt, ratioOnly: ratioOnly)) * step
    }

    /// Frame-Zählen bei dt-Jitter 0,05↔0,07 sprang 3↔2. Sekunden-Uhr wie pinchClickNeed.
    static func pinchOpenHolds(frames: Int, dt: TimeInterval, ratioOnly: Bool = false) -> Bool {
        TimeInterval(max(0, frames)) * max(0.016, dt <= 0 ? 0.016 : dt)
            + 1e-9 >= pinchOpenNeedSec(dt: dt, ratioOnly: ratioOnly)
    }

    static func pinchCloseNeed(dt: TimeInterval, justOpened: Bool = false) -> Int {
        if justOpened, dt < 0.20 { return 2 }
        return dt >= 0.055 ? 1 : 2
    }

    /// Pose-Hold nach PinchGate. 8/15 fps: Gate schon zu → 0 Extra-Frames.
    /// Sonst doppelte Hysterese = 250 ms klebrige Pinzette.
    static func pinchPoseHoldNeed(dt: TimeInterval, gateClosed: Bool = false) -> Int {
        if gateClosed, dt >= 0.055 { return 0 }
        return dt >= 0.055 ? 1 : 2
    }

    /// Peace/Daumen: 8/15 fps 2 Frames, sonst 4.
    static func poseHoldNeed(dt: TimeInterval) -> Int {
        dt >= 0.055 ? 2 : 4
    }

    /// Leere Vision: ein Frame halten, nicht 4 s Skelett in der Luft.
    static func ghostHands(emptyFor: TimeInterval, hold: TimeInterval = 0.10) -> Bool {
        emptyFor >= 0 && emptyFor < hold
    }

    /// HUD: „S1 Ghost 0,4 s“. remaining = latch − emptyFor.
    static func ghostHUD(id: String?, remaining: TimeInterval) -> String {
        let s = max(0, remaining)
        if let id, !id.isEmpty {
            return String(format: "%@ Ghost %.1f s", id, s)
        }
        return String(format: "Ghost %.1f s", s)
    }

    /// Cocoa-Ursprung nach Scale um einen Anker (Cursor), nicht Fenstermittelpunkt.
    static func resizeOrigin(pos: CGPoint, size: CGSize, scale: CGFloat, anchor: CGPoint) -> CGPoint {
        let s = max(0.82, min(1.22, scale))
        return CGPoint(
            x: anchor.x - (anchor.x - pos.x) * s,
            y: anchor.y - (anchor.y - pos.y) * s
        )
    }

    /// Kamera-Format: 720p @ 60 schlägt 720p @ 30. 360p @ 60 bleibt hinter 720p @ 24.
    static func formatScore(width: Double, height: Double, fps: Double) -> Double {
        let long = max(width, height)
        let short = min(width, height)
        guard short >= 360, long >= 640, long <= 1920, short <= 1440, fps >= 7 else { return -1 }
        let near720 = 1.0 - min(abs(short - 720) / 720, 1)
        let res = near720 * 80 + min(long / 1280, 1.1) * 20
        let fpsTerm: Double
        if fps >= 60 {
            fpsTerm = 92
        } else if fps >= 30 {
            fpsTerm = 70 + min(fps, 60) - 30
        } else if fps >= 24 {
            fpsTerm = 55 + min(fps, 30) - 24
        } else if fps >= 15 {
            fpsTerm = 38 + (fps - 15) * 1.5
        } else if fps >= 12 {
            fpsTerm = 22
        } else {
            fpsTerm = fps * 1.5
        }
        let lowFpsPenalty = fps < 12 ? 40.0 : 0
        let tinyPenalty = short < 480 ? 50.0 : 0
        let aspect = long / max(1, short)
        let deskBonus = (aspect > 1.20 && aspect < 1.45 && fps >= 15) ? 12.0 : 0
        return res + fpsTerm - lowFpsPenalty - tinyPenalty + deskBonus
    }

    /// 420f/420v @ ≥15 schlägt BGRA @ 8. Continuity liefert 15 nur nativ, 32BGRA zwingt 8.
    static let formatFourCC420f: UInt32 = 0x34323066
    static let formatFourCC420v: UInt32 = 0x34323076
    static let formatFourCCBGRA: UInt32 = 0x42475241

    static func formatPixelBonus(osType: UInt32, fps: Double) -> Double {
        let is420 = osType == formatFourCC420f || osType == formatFourCC420v
        if is420 && fps >= 24 { return 32 }
        if is420 && fps >= 15 { return 25 }
        if osType == formatFourCCBGRA && fps < 12 { return -35 }
        return 0
    }

    static func formatFourCCName(_ osType: UInt32) -> String {
        if osType == formatFourCC420f { return "420f" }
        if osType == formatFourCC420v { return "420v" }
        if osType == formatFourCCBGRA { return "BGRA" }
        return "PIX"
    }

    /// HUD `420f 15–30` / `BGRA 8`. Nutzer sieht warum Continuity tot ist.
    static func formatBandChip(osType: UInt32, lo: Double, hi: Double, fps: Double? = nil) -> String {
        if let fps, fps > 0, fps < 12 {
            return String(format: "%@ %.0f", formatFourCCName(osType), fps)
        }
        return String(format: "%@ %.0f–%.0f", formatFourCCName(osType), lo, hi)
    }

    /// Continuity USB vs Wi-Fi. Ohne Chip sieht der Nutzer nur `420f 15–24`.
    static func continuityTransportChip(continuity: Bool, usb: Bool) -> String? {
        guard continuity else { return nil }
        return usb ? "USB" : "WIFI"
    }

    static func continuityIsUSB(_ uniqueID: String, transportUSB: Bool = false, modelID: String = "", localizedName: String = "") -> Bool {
        if transportUSB { return true }
        let blob = "\(uniqueID) \(modelID) \(localizedName)".lowercased()
        if blob.contains("wifi") || blob.contains("wi-fi") || blob.contains("wireless") { return false }
        return blob.contains("usb") || blob.contains("uvc")
    }

    /// AVCaptureDevice.transportType FourCC `'usb '` / `'uvc '`. uniqueID/modelID lügen sonst WIFI.
    static let continuityFourCCUSB: Int32 = 0x75736220
    static let continuityFourCCUVC: Int32 = 0x75766320

    static func continuityTransportIsUSB(_ transportType: Int32) -> Bool {
        transportType == continuityFourCCUSB || transportType == continuityFourCCUVC
    }

    static func formatTransportChip(band: String, continuity: Bool, usb: Bool) -> String {
        guard let t = continuityTransportChip(continuity: continuity, usb: usb) else { return band }
        return "\(band) · \(t)"
    }

    static func formatPrefers420(osType: UInt32, fps: Double) -> Bool {
        (osType == formatFourCC420f || osType == formatFourCC420v) && fps >= 15
    }

    /// Gleicher Score: höheres minFrameRate gewinnt (720p@24–30 vor 720p@1–30).
    static let formatTieEps = 0.5

    static func formatPrefers(
        score: Double,
        minFps: Double,
        otherScore: Double,
        otherMinFps: Double
    ) -> Bool {
        if abs(score - otherScore) < formatTieEps {
            return minFps > otherMinFps
        }
        return score > otherScore
    }

    /// 420v VideoRange 16–235. Roh 16/255 = Nacht, Enhance/AE jagen.
    static func luma420Lift(osType: UInt32, luma: CGFloat) -> CGFloat {
        if osType == formatFourCC420v {
            return min(1, max(0, (luma * 255 - 16) / 219))
        }
        return luma
    }

    /// Ring 420f→BGRA > 8 ms: Enhance skippen, Tick bleibt.
    /// Native 420: Kopie ist Blit, Enhance darf.
    static func enhanceSkipsCopy(copyMs: Double, budget: Double = 8, converts: Bool = true) -> Bool {
        converts && copyMs > budget
    }

    /// Desk-View 1920 nur bei Nacht runterskalieren. Sonst Vision auf 960 = Landmark tot.
    static func enhanceDownscales(luma: CGFloat, floor: CGFloat = 0.30) -> Bool {
        luma < floor
    }

    /// VNDetectHumanHandPoseRequest nimmt 420f/420v. Ring darf nicht nach BGRA wandeln.
    static func visionTakesNative(osType: UInt32) -> Bool {
        osType == formatFourCC420f || osType == formatFourCC420v
    }

    static func ringCopyConverts(osType: UInt32) -> Bool {
        !visionTakesNative(osType: osType)
    }

    /// HUD `420f 15–24 · COPY 12` — sonst sieht der Nutzer nur das Format, nicht den Ring.
    /// Native 420-Blit: kein COPY, auch wenn der Blit > 8 ms misst.
    static func formatCopyChip(band: String, copyMs: Double, budget: Double = 8, converts: Bool = true) -> String {
        if !converts { return band }
        if band.isEmpty { return enhanceSkipsCopy(copyMs: copyMs, budget: budget, converts: converts) ? String(format: "COPY %.0f", copyMs) : "" }
        if enhanceSkipsCopy(copyMs: copyMs, budget: budget, converts: converts) {
            return String(format: "%@ · COPY %.0f", band, copyMs)
        }
        return band
    }

    /// HUD `WARP Y 48` — sonst Blindflug warum Y hakelt.
    static func cursorWarpChip(from: CGPoint, to: CGPoint, capX: CGFloat, capY: CGFloat) -> String? {
        let dx = abs(to.x - from.x)
        let dy = abs(to.y - from.y)
        if dx <= capX && dy <= capY { return nil }
        if dx > capX && dy <= capY { return String(format: "WARP X %.0f", dx) }
        if dy > capY && dx <= capX { return String(format: "WARP Y %.0f", dy) }
        return String(format: "WARP %.0f", hypot(dx, dy))
    }

    /// 8 fps HUD flackert WARP/EDGE. Ein Extra-Frame peak-hold.
    static func hudChipPeakHold(current: String?, held: String?, remaining: Int, need: Int = 1) -> (chip: String?, remaining: Int) {
        if let c = current, !c.isEmpty { return (c, need) }
        if remaining > 0, let h = held, !h.isEmpty { return (h, remaining - 1) }
        return (nil, 0)
    }

    /// Down nur wenn Need UND still. Interpolierte Need allein reicht, wenn der Wrist zittert.
    static func pinchClickNeedsStill(speed: CGFloat, frozen: Bool = false) -> Bool {
        frozen || speed <= palmStill * 2.5
    }

    static func pinchClickFires(held: TimeInterval, need: TimeInterval, speed: CGFloat, frozen: Bool = false, occ: Bool = false) -> Bool {
        held >= need && !pinchDownBlocked(speed: speed) && pinchClickNeedsStill(speed: speed, frozen: frozen) && !pinchClickAbortsOcc(occ)
    }

    /// Nach Dunkel: zwei helle Frames, bevor AX wieder läuft. Ein Blitz spamt nicht.
    static let lumaSkipNeed = 2

    static func lumaSkipHold(dark: Bool, skip: Bool, brightStreak: Int, need: Int = lumaSkipNeed) -> (skip: Bool, streak: Int) {
        if dark { return (true, 0) }
        if !skip { return (false, 0) }
        let n = brightStreak + 1
        if n >= need { return (false, 0) }
        return (true, n)
    }

    /// Vision erst nach 2 dunklen Frames tot. Ein Blitz skippt die Pose nicht.
    static func lumaSkipEnter(dark: Bool, streak: Int, need: Int = lumaSkipNeed) -> (skip: Bool, streak: Int) {
        if !dark { return (false, 0) }
        let n = streak + 1
        return n >= need ? (true, 0) : (false, n)
    }

    /// Kalib-Ziel: visibleFrame, nicht Cocoa-Union (Menüleiste / zweiter Monitor).
    static func screenAwareCorners(of q: CGRect, inset: CGFloat = 8) -> [CGPoint] {
        let pad = min(inset, max(2, min(q.width, q.height) / 8))
        return [
            CGPoint(x: q.minX + pad, y: q.minY + pad),
            CGPoint(x: q.maxX - pad, y: q.minY + pad),
            CGPoint(x: q.maxX - pad, y: q.maxY - pad),
            CGPoint(x: q.minX + pad, y: q.maxY - pad)
        ]
    }

    static func calibCornerDrift(mapped: CGPoint, target: CGPoint) -> CGFloat {
        hypot(mapped.x - target.x, mapped.y - target.y)
    }

    static func calibAborts(drift: CGFloat, limit: CGFloat = 80) -> Bool {
        drift > limit
    }

    static func medianFps(_ samples: [Double]) -> Double {
        let ok = samples.filter { $0 > 0.5 }
        guard !ok.isEmpty else { return 0 }
        let sorted = ok.sorted()
        return sorted[sorted.count / 2]
    }

    static func cameraSlowNow(medianFps: Double, floor: Double = watchdogFps) -> Bool {
        medianFps > 0 && medianFps < floor
    }

    static let hudDimIdle: TimeInterval = 8
    static let hudDimOpacity: CGFloat = 0.40

    static func hudDims(idleFor: TimeInterval, armed: Bool) -> Bool {
        !armed && idleFor >= hudDimIdle
    }

    static func darkHoldsRebind(now: TimeInterval, hold: TimeInterval = grabAbortHold) -> TimeInterval {
        now + hold
    }

    /// Skip-AX: Need-Uhr steht. Sonst Down nach 2 s Dunkel im ersten hellen Tick.
    static func pinchClockAdvance(beganAt: TimeInterval, skipAX: Bool, dt: TimeInterval) -> TimeInterval {
        skipAX ? beganAt + max(0, dt) : beganAt
    }

    /// Skip oder erster Tick danach: kein Down (stale/leere Probe).
    static func pressBlockedBySkipAX(skipAX: Bool, latched: Bool) -> Bool {
        skipAX || latched
    }

    /// Kein onFrame 2 s → Format neu. apply()-Tick feuert dann nicht.
    static func frameSilenceRetry(age: TimeInterval, need: TimeInterval = 2.0) -> Bool {
        age >= need
    }

    /// Testmodus: Pinch-Drag ohne AX darf nicht wie tot wirken.
    static func testGrabHUD(becameDrag: Bool) -> String {
        becameDrag ? "GREIFT · KEINE AKTION" : "Test: Halten"
    }

    /// Overlay-Strahl an den Titelbalken, nicht Fenstermitte.
    static let titleBarMidY: CGFloat = 14

    static func beamAim(windowLocal: CGRect, title: CGFloat = titleBarMidY) -> CGPoint {
        guard windowLocal.width > 8, windowLocal.height > 8 else {
            return CGPoint(x: windowLocal.midX, y: windowLocal.midY)
        }
        let y = windowLocal.minY + min(title, max(4, windowLocal.height * 0.12))
        return CGPoint(x: windowLocal.midX, y: y)
    }

    /// Built-in 60. Continuity 30 wenn das Format es trägt — 24 droppt oft auf 8.
    static func lockFrameRate(_ maxFps: Double, continuity: Bool = false) -> Double {
        if continuity {
            if maxFps >= 30 { return 30 }
            if maxFps >= 24 { return min(24, maxFps) }
            if maxFps >= 15 { return max(15, min(24, maxFps)) }
            return max(7, maxFps)
        }
        if maxFps >= 60 { return 60 }
        if maxFps >= 30 { return min(maxFps, 60) }
        if maxFps >= 24 { return max(24, min(30, maxFps)) }
        if maxFps >= 15 { return max(15, min(24, maxFps)) }
        return max(7, maxFps)
    }

    /// Continuity 1–30 hart auf 30 droppt auf 8. Band Floor 15 atmet.
    static let lockFrameFloor: Double = 15

    static func lockFrameLo(_ maxFps: Double, rangeMin: Double, continuity: Bool = false) -> Double {
        let hi = lockFrameRate(maxFps, continuity: continuity)
        if hi + 1e-9 < lockFrameFloor { return hi }
        if !continuity, hi >= 60 {
            return min(hi, max(rangeMin, 30))
        }
        return min(hi, max(rangeMin, lockFrameFloor))
    }

    /// iOS-landscapeRight (180°) auf VideoDataOutput stellt die Mac-Cam auf die Seite / den Kopf.
    static func captureForcesLandscapeRight() -> Bool { false }

    /// VideoDataOutput nicht drehen — Latenz, Palm-X/Y vertauscht, Faust tot.
    static func physicalCaptureRotation() -> Bool { false }

    /// Ohne Coordinator: Puffer 0°. FaceTime ist schon aufrecht.
    static func videoRotationAngleFallback() -> CGFloat { 0 }

    /// Preview + Vision dieselbe Orientierung. Portrait-Buffer → .right (6), sonst .up (1).
    static func previewOrientationRaw(width: Int, height: Int) -> UInt32 {
        height > width ? 6 : 1
    }

    /// left/right (5…8) tauschen Breite und Höhe.
    static func orientedPixelSize(width: Int, height: Int, orientationRaw: UInt32) -> (width: Int, height: Int) {
        switch orientationRaw {
        case 5, 6, 7, 8: return (height, width)
        default: return (width, height)
        }
    }

    /// CGImagePropertyOrientation raw: up=1 down=3 right=6 left=8.
    /// Physische Rotation (macOS 14+ VideoDataOutput) → Vision sieht aufrechte Pixel.
    static func visionOrientationRaw(physicalRotationApplied: Bool, angle: CGFloat) -> UInt32 {
        if physicalRotationApplied { return 1 }
        let wrapped = Int((angle.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360))
        switch wrapped {
        case 90: return 6
        case 180: return 3
        case 270: return 8
        default: return 1
        }
    }

    /// Connection-Winkel live. Applied = physisch gedreht, Vision sieht aufrechte Pixel.
    static func visionRotationApplied(_ angle: CGFloat) -> Bool {
        physicalCaptureRotation() && abs(angle) > 0.5
    }

    static func visionOrientationLive(angle: CGFloat, applied: Bool) -> UInt32 {
        visionOrientationRaw(physicalRotationApplied: applied, angle: angle)
    }

    /// Palm-Slot: ferne kleine Hände enger binden, sonst kleben zwei auf einem Slot.
    static func palmBind(scale: CGFloat) -> CGFloat {
        max(0.08, min(unknownPalmBind, scale * 1.8))
    }

    /// Sample-dt für Gate/Smoother. Roh-Lücke, aber gedeckelt.
    static func sampleDt(now: TimeInterval, last: TimeInterval) -> TimeInterval {
        last == 0 ? 0.016 : max(0.008, min(sampleDtCap, now - last))
    }

    /// 1 Frame voraus (Continuity 8 fps ≈ 125 ms). lead 0,7 dämpft Overshoot.
    static let predictLeadDefault: CGFloat = 0.7

    static func predictLead(_ v: CGFloat) -> CGFloat {
        min(1.0, max(0.3, v))
    }

    /// Continuity 8 fps: 0,7. Built-in 24 fps: 0,35 — Clamp 0,4 overshootete.
    static func predictLeadDt(_ dt: TimeInterval) -> CGFloat {
        dt >= 0.08 ? 0.7 : 0.35
    }

    /// Kalman hat schon vel·dt. 0,7 Lead danach = Cursor vor der Hand.
    static func predictLeadAfterKalman(_ dt: TimeInterval) -> CGFloat {
        dt >= 0.08 ? 0.22 : 0.10
    }

    static func predictPalm(current: CGPoint, prev: CGPoint?, dt: TimeInterval, lead: CGFloat = predictLeadDefault) -> CGPoint {
        guard let prev, dt > 0.004, dt < 0.25 else { return current }
        let l = predictLead(lead)
        return CGPoint(
            x: current.x + (current.x - prev.x) * l,
            y: current.y + (current.y - prev.y) * l
        )
    }

    /// Desk-View / Continuity mit unspecified ist kein Front-Selfie — Spiegeln kippt die Homographie.
    static func mirrorAsFront(positionFront: Bool, unspecified: Bool, deskView: Bool) -> Bool {
        if deskView { return false }
        return positionFront || unspecified
    }

    /// Ferne Hand: Close-Vel-Rauschen schließt das Gate falsch. Weicher als −2 / dt.
    static func pinchCloseVel(dt: TimeInterval, palmScale: CGFloat) -> CGFloat {
        let base = pinchCloseVel(dt: dt)
        return palmScale < 0.08 ? base * 0.55 : base
    }

    /// Click-Lock erst wenn Hover weit genug oder die Pinzette schon zu ist.
    /// Sonst Down auf dem Weg zum Button (hover 0,2).
    static let clickLockHoverNeed: CGFloat = 0.70

    static func clickLockNeedsHover(_ hover: CGFloat?, closed: Bool, need: CGFloat = clickLockHoverNeed) -> Bool {
        if closed { return true }
        guard let hover else { return false }
        return hover >= need
    }

    /// Beide Hände voll offen (4 Finger) = Panic, ohne 0,55 s Hold.
    static func panicKill(openScores: [Int]) -> Bool {
        openScores.filter { $0 >= 4 }.count >= 2
    }

    /// Faust-Scharf nur nach offener Hand im Innenraum. Rand-Knie zählt nicht.
    static func armOpenCounts(x: CGFloat, y: CGFloat) -> Bool {
        killCounts(x: x, y: y)
    }

    /// Nach Escape/⌘. 200 ms: nächster Pinch nicht sofort Klick.
    static let escapeLatchHold: TimeInterval = 0.20

    static func escapeLatches(now: TimeInterval, until: TimeInterval) -> Bool {
        until > 0 && now < until
    }

    /// 1 teurer Vision-Tick skippt AX. 2 billige, dann Probe — nicht jeder Spike.
    static let skipAXCheapNeed = 2

    static func skipAXLatch(
        expensive: Bool,
        skip: Bool,
        cheapStreak: Int,
        need: Int = skipAXCheapNeed
    ) -> (skip: Bool, streak: Int) {
        if expensive { return (true, 0) }
        if !skip { return (false, 0) }
        let n = cheapStreak + 1
        if n >= need { return (false, 0) }
        return (true, n)
    }

    /// Overlay WEG n% während Settle. Continuity-Klick wirkt sonst tot.
    static func travelHUD(travel: CGFloat, limit: CGFloat) -> CGFloat? {
        guard limit > 1 else { return nil }
        let t = min(1, max(0, travel / limit))
        return t > 0.04 ? t : nil
    }

    static func travelHUDLabel(_ progress: CGFloat?) -> String? {
        guard let progress else { return nil }
        return String(format: "WEG %.0f%%", progress * 100)
    }

    /// Kein Innenraum-Hand 1,2 s → Idle. Knie am Rand halten Dead-Man nicht.
    static let gazeIdleNeed: TimeInterval = 1.20

    static func gazeIdle(lastInterior: TimeInterval, now: TimeInterval, need: TimeInterval = gazeIdleNeed) -> Bool {
        lastInterior > 0 && now - lastInterior >= need
    }

    /// Relativzeiger: Predict nur bei großem dt, sonst Overshoot bei 24 fps.
    static func relativePredicts(dt: TimeInterval) -> Bool {
        dt >= 0.08
    }

    /// 24 fps Kalman nicht skippen — sonst vel=0, nur Totzone, Zeiger zittert.
    static func palmKalmanUses(dt: TimeInterval) -> Bool {
        dt >= 0.012
    }

    enum HoverRingKind: String {
        case magnet, button, travel, hover, none
    }

    /// MAGNET / BUTTON / WEG sonst unleserlich — drei Overlays eine Farbe.
    static func hoverRingKind(
        magnet: Bool,
        locked: Bool,
        travel: CGFloat?,
        hover: CGFloat?
    ) -> HoverRingKind {
        if magnet { return .magnet }
        if let t = travel, t > 0.04 { return .travel }
        if locked { return .button }
        if let h = hover, h > 0.15 { return .hover }
        return .none
    }

    static func hoverRingLabel(_ kind: HoverRingKind) -> String? {
        switch kind {
        case .magnet: return "MAGNET"
        case .button: return "BUTTON"
        case .travel, .hover, .none: return nil
        }
    }

    /// Escape-Latch Overlay. Sonst wirkt der nächste Pinch tot.
    static func escapeLatchHUD(now: TimeInterval, until: TimeInterval) -> String? {
        escapeLatches(now: now, until: until) ? "LATCH" : nil
    }

    /// Vision-ms neben fps, damit AX-Budget sichtbar ist.
    static func visionMsSpark(_ ms: Double, budget: Double = axBudgetMs) -> String {
        if ms > budget { return String(format: "%.0f ms!", ms) }
        return String(format: "%.0f ms", ms)
    }

    /// Traffic-Lights 400 ms am ancestor, nicht jeden Tick Walk.
    static let trafficCacheTTL: TimeInterval = 0.40

    static func trafficCacheFresh(
        now: TimeInterval,
        cachedAt: TimeInterval,
        ttl: TimeInterval = trafficCacheTTL
    ) -> Bool {
        now - cachedAt < ttl && cachedAt > 0
    }

    static func axProbeCoalesced() -> Bool { true }

    /// Letzte Pose Faust, Hand weg ≥ 1,6 s. 8 s Dead-Man bleibt Fallback ohne Faust.
    static func deadManFistIdle(
        lastFist: TimeInterval,
        lastHand: TimeInterval,
        now: TimeInterval,
        need: TimeInterval = deadManFist
    ) -> Bool {
        let used = deadManFistPref(need)
        return lastFist > 0 && lastHand > 0 && now - lastHand >= used && lastFist + 0.30 >= lastHand
    }

    /// HUD `IDLE 1,2` analog KLICK n %. Gaze-IDLE % bleibt Fallback ohne Faust.
    static func deadManFistChip(
        lastFist: TimeInterval,
        lastHand: TimeInterval,
        now: TimeInterval,
        need: TimeInterval = deadManFist
    ) -> String? {
        let used = deadManFistPref(need)
        guard lastFist > 0, lastHand > 0, lastFist + 0.30 >= lastHand else { return nil }
        let left = used - (now - lastHand)
        guard left > 0, left <= used else { return nil }
        return String(format: "IDLE %.1f", left).replacingOccurrences(of: ".", with: ",")
    }

    /// Fling in Quartz-px/s. Dual-Monitor 5k vs Laptop.
    static func flingSpeedPx(dx: CGFloat, dy: CGFloat, dt: TimeInterval) -> CGFloat {
        guard dt > 1e-4 else { return 0 }
        return hypot(dx, dy) / CGFloat(dt)
    }

    static func flingMinSpeedPx(screenHeight: CGFloat) -> CGFloat {
        max(280, screenHeight * flingMinSpeed)
    }

    /// Overlay-Ring nach Dunkel 2 Frames nicht rebase-warpen.
    static func darkRingHolds(darkStreak: Int, need: Int = 2) -> Bool {
        darkStreak > 0 && darkStreak < need
    }

    /// Dead-Man die letzten 3 s, bevor Gaze-Idle.
    static let deadManWindow: TimeInterval = 3

    static func deadManProgress(
        lastInterior: TimeInterval,
        now: TimeInterval,
        need: TimeInterval = gazeIdleNeed,
        window: TimeInterval = deadManWindow
    ) -> CGFloat? {
        guard lastInterior > 0, window > 0 else { return nil }
        let gone = now - lastInterior
        let left = need - gone
        guard left > 0, left <= window, gone > 0.05 else { return nil }
        return CGFloat(min(1, max(0, 1 - left / window)))
    }

    static func deadManLabel(_ p: CGFloat?) -> String? {
        guard let p else { return nil }
        return String(format: "IDLE %.0f%%", p * 100)
    }

    /// Faust-Scharf Countdown analog KLICK n %.
    static func fistArmProgress(held: TimeInterval, need: TimeInterval) -> CGFloat? {
        guard need > 0, held > 0.02, held < need else { return nil }
        return CGFloat(min(1, held / need))
    }

    static func fistArmLabel(_ p: CGFloat?) -> String? {
        guard let p else { return nil }
        return String(format: "SCHARF %.0f%%", p * 100)
    }

    /// Continuity 8→24 Hz: smoothstep zwischen zwei Palmen.
    static func palmInterp(prev: CGPoint, curr: CGPoint, t: CGFloat) -> CGPoint {
        let u = min(1, max(0, t))
        let s = u * u * (3 - 2 * u)
        return CGPoint(
            x: prev.x + (curr.x - prev.x) * s,
            y: prev.y + (curr.y - prev.y) * s
        )
    }

    /// Extra-Hold 0,55 s ohne Bewegung → Rechtsklick.
    static let rightClickExtra: TimeInterval = 0.55

    static func rightClickHold(
        held: TimeInterval,
        need: TimeInterval,
        extra: TimeInterval = rightClickExtra
    ) -> Bool {
        held >= extra && held >= need
    }

    static func rightClickChipLabel(right: Bool) -> String? {
        right ? "RECHTS" : nil
    }

    static let doublePinchWindow: TimeInterval = 0.32

    static func doublePinch(
        now: TimeInterval,
        lastClick: TimeInterval,
        window: TimeInterval = doublePinchWindow
    ) -> Bool {
        lastClick > 0 && now - lastClick <= window
    }

    /// Pinch während Travel ist Flick, kein Doppel. 45 % der Travel-Grenze reicht.
    static func doublePinchBlocksTravel(travel: CGFloat, limit: CGFloat, ratio: CGFloat = 0.45) -> Bool {
        limit > 1 && travel >= limit * ratio
    }

    /// Continuity 8 fps: Palm vor Predict glätten, sonst Overshoot + Warp.
    static func continuityPalm(
        prev: CGPoint?,
        current: CGPoint,
        dt: TimeInterval
    ) -> CGPoint {
        guard let prev, relativePredicts(dt: dt) else { return current }
        return palmInterp(prev: prev, curr: current, t: 0.62)
    }

    /// Catmull-Rom zwischen prev und current. 8 fps Display-Link-Ersatz.
    static func palmInterpCubic(p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, t: CGFloat) -> CGPoint {
        let u = min(1, max(0, t))
        let u2 = u * u
        let u3 = u2 * u
        func cr(_ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ d: CGFloat) -> CGFloat {
            0.5 * ((2 * b) + (-a + c) * u + (2 * a - 5 * b + 4 * c - d) * u2 + (-a + 3 * b - 3 * c + d) * u3)
        }
        return CGPoint(x: cr(p0.x, p1.x, p2.x, p3.x), y: cr(p0.y, p1.y, p2.y, p3.y))
    }

    /// 8 fps: cubic wenn 3 Palmen da, sonst smoothstep. 24 fps roh.
    static func continuityPalmCubic(
        older: CGPoint?,
        prev: CGPoint?,
        current: CGPoint,
        dt: TimeInterval
    ) -> CGPoint {
        guard relativePredicts(dt: dt) else { return current }
        guard let prev else { return current }
        guard let older else { return palmInterp(prev: prev, curr: current, t: 0.62) }
        let extra = CGPoint(x: current.x + (current.x - prev.x), y: current.y + (current.y - prev.y))
        return palmInterpCubic(p0: older, p1: prev, p2: current, p3: extra, t: 0.62)
    }

    /// Hell: weniger Process-Noise. Luma-Sprung nur während Faust-AE: Freeze.
    /// MAD hoch (zittrig): mehr q, Kalman folgt. MAD tot: weniger q, Zeiger klebt nicht nach.
    static func palmKalmanQ(luma: CGFloat, base: CGFloat = 0.10, mad: CGFloat = 0) -> CGFloat {
        var q = luma >= 0.45 ? base * 0.55 : base
        if mad >= palmDeadTense * 0.6 { q *= 1.55 }
        else if mad > 0, mad <= palmDeadRest * 0.55 { q *= 0.62 }
        return q
    }

    /// Unsicherer Landmark: mehr Measurement-Noise, weniger Warp.
    static func palmKalmanR(tipConf: CGFloat = 1, base: CGFloat = 0.045) -> CGFloat {
        let c = min(1, max(0.20, tipConf))
        return base / c
    }

    static let fistAELock: TimeInterval = 1.2

    /// Built-in 24 fps braucht den Lock selten; Locked-AE macht Indoor dumpf.
    static func fistAELockApplies(continuity: Bool) -> Bool { continuity }

    static func lumaWarp(prev: CGFloat, next: CGFloat, floor: CGFloat = 0.18) -> Bool {
        abs(next - prev) >= floor
    }

    static func fistAELockActive(armedAt: TimeInterval?, now: TimeInterval, hold: TimeInterval = fistAELock) -> Bool {
        guard let armedAt else { return false }
        return now - armedAt >= 0 && now - armedAt < hold
    }

    /// Freeze nur mit AE-Fenster. Sonst Fensterlicht = Cursor tot.
    static func palmKalmanFreeze(
        armedAt: TimeInterval?,
        now: TimeInterval,
        luma: CGFloat,
        prevLuma: CGFloat
    ) -> Bool {
        fistAELockActive(armedAt: armedAt, now: now) && lumaWarp(prev: prevLuma, next: luma)
    }

    /// Occlusion / DIP-Fake: Cursor halten, nicht den Sprung cappen.
    /// Continuity-Joints 0,12–0,25 sind live, nicht tot — Floor 0,30 freeze den Zeiger.
    static func palmLowConfFloor(continuity: Bool) -> CGFloat {
        continuity ? 0.10 : 0.30
    }

    static func palmTipConf(tip: CGFloat, mean: CGFloat) -> CGFloat {
        tip > 0 ? tip : mean
    }

    static func palmLowConfFreeze(conf: CGFloat, floor: CGFloat = 0.30, tipHeld: Bool = false) -> Bool {
        _ = tipHeld
        return conf > 0 && conf < floor
    }

    /// AE-Warp oder Landmark tot: Kalman freeze.
    static func palmHolds(
        armedAt: TimeInterval?,
        now: TimeInterval,
        luma: CGFloat,
        prevLuma: CGFloat,
        conf: CGFloat,
        continuity: Bool = false,
        tipHeld: Bool = false
    ) -> Bool {
        palmKalmanFreeze(armedAt: armedAt, now: now, luma: luma, prevLuma: prevLuma)
            || palmLowConfFreeze(
                conf: conf,
                floor: palmLowConfFloor(continuity: continuity),
                tipHeld: tipHeld
            )
    }

    /// Filter-Ausgang ist der nächste prev. Roh als prev = Ein-Frame-Blend, Warp bleibt.
    static func palmKalmanKeepsState(_ pos: CGPoint) -> CGPoint { pos }

    /// Freeze mit alter Vel: Display-Link kriecht während Occlusion/AE.
    static func palmKalmanFreezeVel(_ vel: CGPoint, freeze: Bool) -> CGPoint {
        freeze ? .zero : vel
    }

    /// 2×2 P-Schritt. p=0 → k = q/(q+r) wie der alte Skalar.
    static func palmKalmanStep(p: CGFloat, q: CGFloat, r: CGFloat) -> (k: CGFloat, p: CGFloat) {
        let pPred = p + q
        let k = pPred / max(0.0001, pPred + r)
        return (k, (1 - k) * pPred)
    }

    /// Tiny Residual: k runter, Zeiger klebt. Flick: k voll. One-Euro ohne extra State.
    static func palmKalmanResidualMul(residual: CGFloat, rest: CGFloat = 0.002, flick: CGFloat = 0.035) -> CGFloat {
        let u = min(1, max(0, (residual - rest) / max(0.001, flick - rest)))
        return 0.35 + 0.65 * u
    }

    /// 8 fps cv-Kalman. Cubic p3 = 2× Extrapolation overshootet, dann Warp.
    /// P je Achse: Atem (Y) dämpft nicht den Flick (X).
    static func palmKalman(
        prev: CGPoint?,
        meas: CGPoint,
        vel: CGPoint,
        dt: TimeInterval,
        luma: CGFloat = 1,
        tipConf: CGFloat = 1,
        freeze: Bool = false,
        mad: CGFloat = 0,
        madX: CGFloat? = nil,
        madY: CGFloat? = nil,
        pX: CGFloat = 0,
        pY: CGFloat = 0
    ) -> (pos: CGPoint, vel: CGPoint, pX: CGFloat, pY: CGFloat) {
        guard palmKalmanUses(dt: dt), let prev else { return (meas, .zero, pX, pY) }
        if freeze { return (prev, palmKalmanFreezeVel(vel, freeze: true), pX, pY) }
        let dtx = CGFloat(max(0.008, dt))
        let qx = palmKalmanQ(luma: luma, mad: madX ?? mad)
        let qy = palmKalmanQ(luma: luma, mad: madY ?? mad)
        let r = palmKalmanR(tipConf: tipConf)
        let pred = CGPoint(x: prev.x + vel.x * dtx, y: prev.y + vel.y * dtx)
        let sx = palmKalmanStep(p: pX, q: qx, r: r)
        let sy = palmKalmanStep(p: pY, q: qy, r: r)
        let mx = palmKalmanResidualMul(residual: abs(meas.x - pred.x))
        let my = palmKalmanResidualMul(residual: abs(meas.y - pred.y))
        let kx = sx.k * mx
        let ky = sy.k * my
        let x = pred.x + kx * (meas.x - pred.x)
        let y = pred.y + ky * (meas.y - pred.y)
        let rawV = CGPoint(x: (x - prev.x) / dtx, y: (y - prev.y) / dtx)
        let a: CGFloat = 0.55
        return (
            CGPoint(x: x, y: y),
            CGPoint(x: a * rawV.x + (1 - a) * vel.x, y: a * rawV.y + (1 - a) * vel.y),
            sx.p,
            sy.p
        )
    }

    /// VNFace alle 4 Frames — Vision-Budget.
    static let faceScanEvery = 4

    static func faceScanDue(tick: Int, every: Int = faceScanEvery) -> Bool {
        every > 0 && tick % every == 0
    }

    /// Echter VNFace-Count: kein Gesicht 1,2 s → Idle.
    static func faceCountIdle(
        faces: Int,
        lastSeen: TimeInterval,
        now: TimeInterval,
        need: TimeInterval = gazeIdleNeed
    ) -> Bool {
        if faces > 0 { return false }
        return lastSeen > 0 && now - lastSeen >= need
    }

    /// Snapshot-Count überlebt dunkle Frames. Stale Count darf lastFaceSeen nicht auffrischen.
    static func faceCountFresh(
        count: Int,
        lastSeen: TimeInterval,
        now: TimeInterval,
        need: TimeInterval = gazeIdleNeed
    ) -> Int {
        if count <= 0 { return 0 }
        if lastSeen > 0, now - lastSeen >= need { return 0 }
        return count
    }

    /// Continuity in der Tasche: kein Innenraum 1,2 s → Idle. Built-in bleibt beim 6 s Dead-Man.
    static func pocketIdle(
        cameraFallback: Bool,
        lastInterior: TimeInterval,
        now: TimeInterval,
        need: TimeInterval = gazeIdleNeed
    ) -> Bool {
        cameraFallback && gazeIdle(lastInterior: lastInterior, now: now, need: need)
    }

    static func liveHandRefreshesDeadMan(ghost: Bool) -> Bool { !ghost }

    enum PointerSide: String {
        case left, right, any
    }

    /// Zweite Hand nur Modifier. Pointer bleibt auf der Scharf-Hand.
    /// Unknown (`.any`) ist nicht die Lock-Seite — sonst stiehlt die zweite Hand ohne Chirality.
    static func pointerStaysSide(locked: PointerSide, candidate: PointerSide) -> Bool {
        if locked == .any { return true }
        if candidate == .any { return false }
        return locked == candidate
    }

    /// Lock-Seite zuerst. Fehlt sie: nur die Scharf-Slot-ID, nicht die andere Hand.
    static func pointerPool(
        locked: PointerSide,
        candidates: [(id: String, side: PointerSide)],
        keepID: String?
    ) -> [String] {
        if locked == .any { return candidates.map(\.id) }
        let matching = candidates.filter { pointerStaysSide(locked: locked, candidate: $0.side) }.map(\.id)
        if !matching.isEmpty { return matching }
        if let keepID, candidates.contains(where: { $0.id == keepID }) { return [keepID] }
        return []
    }

    /// Continuity-Reconnect: Vision-ID tot, Chirality `.any`. Palm-Nähe statt keepID.
    /// Sonst Pool leer → LOCK tot, obwohl die Lock-Hand da ist.
    /// 8 fps: Bind weiter + last-3 Palm (last2), sonst ein Sprung > 0,22 verliert den Slot.
    static func reconnectBind(dt: TimeInterval, base: CGFloat = unknownPalmBind) -> CGFloat {
        dt >= 0.08 ? min(0.40, base * 1.85) : base
    }

    static func pointerPoolReconnect(
        locked: PointerSide,
        candidates: [(id: String, side: PointerSide, x: CGFloat, y: CGFloat)],
        keepID: String?,
        lastX: CGFloat?,
        lastY: CGFloat?,
        bind: CGFloat = unknownPalmBind,
        last2X: CGFloat? = nil,
        last2Y: CGFloat? = nil,
        dt: TimeInterval = 0.016
    ) -> [String] {
        let simple = pointerPool(
            locked: locked,
            candidates: candidates.map { ($0.id, $0.side) },
            keepID: keepID
        )
        if !simple.isEmpty { return simple }
        let radius = reconnectBind(dt: dt, base: bind)
        let pts = candidates.map { (id: $0.id, x: $0.x, y: $0.y) }
        if let lastX, let lastY, let id = actorRebind(
            lostID: keepID ?? "",
            candidates: pts,
            lastX: lastX,
            lastY: lastY,
            bind: radius
        ) {
            return [id]
        }
        if let last2X, let last2Y, let id = actorRebind(
            lostID: keepID ?? "",
            candidates: pts,
            lastX: last2X,
            lastY: last2Y,
            bind: radius
        ) {
            return [id]
        }
        return []
    }

    /// pinchActor darf bei leerem Pool nicht alle Hände scannen — sonst stiehlt die andere Pinzette.
    static func pinchActorKeeps(id: String, poolIDs: [String]) -> Bool {
        poolIDs.contains(id)
    }

    static func pinchActorScanPool(poolIDs: [String]) -> Bool {
        !poolIDs.isEmpty
    }

    /// Pool.first ist Observation-Reihenfolge. Keep im Pool bleibt, sonst S1 (Hand), nicht die Gitarre.
    static func pointerKeepPrefersHand(_ poolIDs: [String]) -> String? {
        if let s1 = poolIDs.first(where: { $0 == "S1" }) { return s1 }
        return poolIDs.first
    }

    static func pointerKeepInPool(keepID: String?, poolIDs: [String]) -> String? {
        if let keepID, poolIDs.contains(keepID) { return keepID }
        return pointerKeepPrefersHand(poolIDs)
    }

    /// Keep-Bits je Slot, nicht nur lastS1. Gitarre als S2 darf S1 nicht stehlen.
    static func pointerKeepPerHand(keepIDs: [String], poolIDs: [String]) -> String? {
        if let s1 = keepIDs.first(where: { $0 == "S1" && poolIDs.contains($0) }) { return s1 }
        if let hit = keepIDs.first(where: { poolIDs.contains($0) }) { return hit }
        return pointerKeepPrefersHand(poolIDs)
    }

    /// preferred() bei leerem Pool nicht alle Hände — sonst stiehlt die andere.
    static func preferredKeepsPool(poolEmpty: Bool) -> Bool { !poolEmpty }

    /// Freeze: lastPalm nicht von der anderen Hand. Sonst Reconnect an sie.
    static func stealHoldsPalm(poolEmpty: Bool) -> Bool { poolEmpty }

    /// Slot-Bind 8 fps wie reconnectBind, sonst S1 stirbt und S3 erscheint.
    static func slotBind(dt: TimeInterval, scale: CGFloat) -> CGFloat {
        reconnectBind(dt: dt, base: palmBind(scale: scale))
    }

    /// Unclaimed S1 nach Palm-Sprung wiederverwenden, nicht S3 minten.
    static func slotLatchBind(dt: TimeInterval, scale: CGFloat) -> CGFloat {
        min(0.72, slotBind(dt: dt, scale: scale) * 1.8)
    }

    static func slotReusesUnclaimed(
        unclaimed: Int,
        nearest: CGFloat,
        bind: CGFloat,
        latch: CGFloat
    ) -> Bool {
        if nearest < bind { return true }
        return unclaimed >= 1 && nearest < latch
    }

    /// Abgelaufene IDs wiederverwenden, sonst S47 nach einer Stunde.
    /// Latch lebt: nicht S3 minten — S1/S2 halten, sonst Overlay-Hue springt.
    static func slotMintsNew(existing: Int, latching: Bool, cap: Int = 2) -> Bool {
        if latching, existing >= cap { return false }
        return true
    }

    static func slotAllocCap(latching: Bool, cap: Int = 2) -> Int? {
        latching ? cap : nil
    }

    /// Prop (Gitarre/Rumpf) nie S1. Observation-first sonst Overlay und Cursor auf der Gitarre.
    /// Keep nur beim Rebind: 8 fps zittert um 0,28. Neu-Alloc 0,29 ist Prop.
    static func slotAllocMinID(scale: CGFloat, keep: Bool = false) -> Int {
        palmScaleIsHand(scale, keep: keep) ? 1 : 2
    }

    static func slotBindSkipsProp(slotID: Int, scale: CGFloat, prev: [Int: Bool] = [:], prevScale: [Int: CGFloat] = [:]) -> Bool {
        let keep = prev[slotID] ?? true
        return slotID == 1 && !slotKeepBit(id: slotID, scale: scale, prev: [slotID: keep], prevScale: prevScale)
    }

    /// Pro Slot Keep, nicht nur lastS1. S2 0,29 bleibt Prop, S1 Keep hält.
    /// Scale-Jump 0,12→0,29 ist Objektwechsel, nicht Hysterese.
    static func slotKeepBit(id: Int, scale: CGFloat, prev: [Int: Bool] = [:], prevScale: [Int: CGFloat] = [:]) -> Bool {
        if let p = prevScale[id], slotScaleJumpVeto(prev: p, live: scale) {
            return palmScaleIsHand(scale, keep: false)
        }
        return palmScaleIsHand(scale, keep: prev[id] ?? false)
    }

    /// S1 0,12 → 0,29 ist Gitarre, nicht Keep. Continuity 8 fps zittert ~0,03.
    static func slotScaleJumpVeto(prev: CGFloat, live: CGFloat, jump: CGFloat = 0.12) -> Bool {
        abs(live - prev) + 1e-12 >= jump
    }

    /// S1 vor Observation-first. Prop (Gitarre/Rumpf, scale ≥ 0,28) kein S1-Crop —
    /// erste handgroße Observation (S2) statt Full, sonst 8 fps Tick tot.
    static let palmHandScaleMin: CGFloat = 0.035
    static let palmHandScaleMax: CGFloat = 0.28
    /// Continuity 8 fps zittert um 0,28. Keep 0,03 hält die Hand, Prop allein bleibt tot.
    static let palmHandScaleHyst: CGFloat = 0.03

    static func palmScaleIsHand(_ scale: CGFloat, keep: Bool = false) -> Bool {
        let max = keep ? palmHandScaleMax + palmHandScaleHyst : palmHandScaleMax
        return scale >= palmHandScaleMin && scale < max
    }

    /// 8 fps zittert um 0,28. EMA hält die Hand, Prop allein bleibt tot.
    /// Hand darf nicht in Prop kriechen — sonst Keep 0,29 = Gitarre.
    static func palmScaleKalman(prev: CGFloat, live: CGFloat, q: CGFloat = 0.18) -> CGFloat {
        if prev < palmHandScaleMin { return live }
        let next = prev + q * (live - prev)
        if prev < palmHandScaleMax && next >= palmHandScaleMax {
            return palmHandScaleMax - 0.001
        }
        return next
    }

    /// S1-Miss 2 Ticks: lastS1 nicht von S2/Prop stehlen. 8 fps Dropout sonst Cursor-Sprung.
    static func palmCoastAdvance(prev: Int, hit: Bool) -> Int {
        hit ? 0 : prev + 1
    }

    static func palmCoastNeedPref(_ pref: Int) -> Int {
        min(4, max(1, pref))
    }

    /// Indoor 4 fps Dropout 3 Ticks. Pref 2 tot. Auto aus dt, Slider Override Floor.
    static func palmCoastNeedAuto(dt: TimeInterval, pref: Int) -> Int {
        let p = palmCoastNeedPref(pref)
        if dt >= 0.20 { return max(p, 3) }
        if dt <= 0.04 { return 1 }
        return p
    }

    static func palmCoastKeepsS1(miss: Int, need: Int = 2) -> Bool {
        let n = palmCoastNeedPref(need)
        return miss > 0 && miss <= n
    }

    /// Dropout leer: emitEmpty wischte lastS1 vor Coast. Gleicher Need wie S1-Miss.
    static func palmCoastEmptyKeeps(miss: Int, need: Int = 2) -> Bool {
        palmCoastKeepsS1(miss: miss, need: need)
    }

    /// Ghost-Pose still = Cursor-Halt, dann Sprung. Vel je Tick, Cap 0,08 Bild.
    static func palmCoastPredict(palm: CGPoint, vel: CGPoint, cap: CGFloat = 0.08) -> CGPoint {
        CGPoint(
            x: palm.x + max(-cap, min(cap, vel.x)),
            y: palm.y + max(-cap, min(cap, vel.y))
        )
    }

    /// Miss 1 voll, danach α 0,82. 4-Tick-Coast fliegt sonst mit lastVel.
    static func palmCoastVelDecay(vel: CGPoint, miss: Int, alpha: CGFloat = 0.82) -> CGPoint {
        if miss <= 1 { return vel }
        return CGPoint(x: vel.x * alpha, y: vel.y * alpha)
    }

    /// Ein Token, ein Writer. Drei Bool-Skips waren derselbe Test.
    enum WarpWriter: String {
        case fill = "FILL"
        case vision = "VISION"
    }

    static func warpWriter(linkArmed: Bool) -> WarpWriter {
        linkArmed ? .fill : .vision
    }

    static func warpWriterSkips(_ writer: WarpWriter) -> Bool {
        writer == .fill
    }

    /// Vision-Tick und displayTick beide CGWarp: Double-Warp an der Seam.
    static func warpWriterVisionSkips(linkArmed: Bool) -> Bool {
        warpWriterSkips(warpWriter(linkArmed: linkArmed))
    }

    /// Press-Pfad umging den Skip — 8 fps Klick vs Fill 60 Hz.
    static func warpWriterPressSkips(linkArmed: Bool) -> Bool {
        warpWriterSkips(warpWriter(linkArmed: linkArmed))
    }

    /// Fill während mouseDown, nicht AX-Drag. displayTick guard isDragging schon.
    static func displayTickFillsPress(pressed: Bool, dragging: Bool) -> Bool {
        !dragging
    }

    /// Not-Aus injectCursor umging den Skip — 8 fps Warp vs Fill.
    static func warpWriterInjectSkips(linkArmed: Bool) -> Bool {
        warpWriterSkips(warpWriter(linkArmed: linkArmed))
    }

    static func warpWriterChip(linkArmed: Bool) -> String {
        warpWriter(linkArmed: linkArmed).rawValue
    }

    /// Coast-Ghost 50 %, Latch-Ghost 35 %. Overlay sonst voll S1.
    static func overlayGhostAlpha(coast: Bool) -> CGFloat {
        coast ? 0.50 : 0.35
    }

    /// Latch remaining > 0. Coast setzt remaining 0.
    static func overlayGhostIsCoast(remaining: TimeInterval) -> Bool {
        remaining <= 0
    }

    /// Coast-Return: lastS1Palm noch pre-coast → Vel-Sprung.
    static func palmCoastVelOnHit(live: CGPoint, stored: CGPoint, wasCoast: Bool, lastVel: CGPoint) -> CGPoint {
        if wasCoast { return lastVel }
        return CGPoint(x: live.x - stored.x, y: live.y - stored.y)
    }

    /// Return-Vel Cap 0,08. lastVel nach Coast sonst JUMP über 2 Ticks.
    static func palmCoastReturnVel(
        live: CGPoint,
        stored: CGPoint,
        wasCoast: Bool,
        lastVel: CGPoint,
        cap: CGFloat = 0.08
    ) -> CGPoint {
        let v = palmCoastVelOnHit(live: live, stored: stored, wasCoast: wasCoast, lastVel: lastVel)
        return CGPoint(x: max(-cap, min(cap, v.x)), y: max(-cap, min(cap, v.y)))
    }

    static func palmCoastDelta(from: CGPoint, to: CGPoint) -> CGPoint {
        CGPoint(x: to.x - from.x, y: to.y - from.y)
    }

    static func palmCoastShift(_ point: CGPoint, delta: CGPoint) -> CGPoint {
        CGPoint(x: point.x + delta.x, y: point.y + delta.y)
    }

    /// Lock/Coast: Crop steht. Center Stage wandert sonst auf die Gitarre.
    static func palmROIFreeze(keepHand: Bool, coast: Bool, secondHand: Bool = false) -> Bool {
        !secondHand && (keepHand || coast)
    }

    static func palmROILocked(live: CGRect?, frozen: CGRect?, freeze: Bool) -> CGRect? {
        if freeze { return frozen ?? live }
        return live
    }

    static func palmROISlotPalm(
        hands: [(id: String, palm: CGPoint, scale: CGFloat)],
        keepPalm: CGPoint? = nil,
        keepScale: CGFloat = 0.12
    ) -> (palm: CGPoint, scale: CGFloat)? {
        if let s1 = hands.first(where: { $0.id == "S1" }), palmScaleIsHand(s1.scale, keep: true) {
            return (s1.palm, s1.scale)
        }
        if let keepPalm, palmScaleIsHand(keepScale, keep: true) {
            return (keepPalm, keepScale)
        }
        if let hand = hands.first(where: { palmScaleIsHand($0.scale, keep: true) }) {
            return (hand.palm, hand.scale)
        }
        return nil
    }

    static func palmVisionROI(
        palm: CGPoint?,
        scale: CGFloat,
        secondHand: Bool,
        pad: CGFloat = 1.8,
        dt: TimeInterval = 0.016
    ) -> CGRect? {
        if secondHand, palmROISecondNils(dt: dt) { return nil }
        guard let palm, scale > 0.01 else { return nil }
        let half = max(palmROIMinFrac, min(0.46, scale * pad))
        let x = min(max(0, palm.x - half), 1 - 0.01)
        let y = min(max(0, palm.y - half), 1 - 0.01)
        let w = min(1 - x, half * 2)
        let h = min(1 - y, half * 2)
        if w < palmROIMinFrac || h < palmROIMinFrac { return nil }
        return CGRect(x: x, y: y, width: w, height: h)
    }

    /// Crop um S1. 1.5.67–141: Gitarre im Crop, Overlay volles Preview. 1.5.66/1.6 Vollbild.
    static func palmVisionUsesROI() -> Bool { false }

    /// Vision rankt Gitarre+Rumpf vor der Hand. 2 Slots = echte Hand nie in results.
    static func obsHandCountCap(_ pref: Int = 4) -> Int {
        min(8, max(2, pref))
    }

    /// Span-Veto tot in Classifier: beide Äste gaben med. Prop-Scale > 0,28.
    static func obsScaleMarksProp(_ live: CGFloat) -> CGFloat {
        max(live, palmHandScaleMax + 0.02)
    }

    /// BBox der Gelenke in Vision 0…1.
    static func obsJointSpan(_ pts: [CGPoint]) -> (w: CGFloat, h: CGFloat) {
        guard let minX = pts.map(\.x).min(), let maxX = pts.map(\.x).max(),
              let minY = pts.map(\.y).min(), let maxY = pts.map(\.y).max()
        else { return (0, 0) }
        return (max(0, maxX - minX), max(0, maxY - minY))
    }

    /// 3 Finger Tip > MCP vom Wrist. Gitarre halluziniert Kollinear, nicht Ketten.
    /// Paare nach Finger-Index, nicht compactMap-Zip — fehlender Middle-Tip sonst Ring vs Middle.
    static func obsFingerChainOk(
        wrist: CGPoint?,
        mcps: [CGPoint],
        tips: [CGPoint],
        need: Int = 3
    ) -> Bool {
        guard let wrist else { return false }
        let n = min(mcps.count, tips.count)
        if n < 2 { return false }
        var ok = 0
        for i in 0..<n {
            let dM = hypot(mcps[i].x - wrist.x, mcps[i].y - wrist.y)
            let dT = hypot(tips[i].x - wrist.x, tips[i].y - wrist.y)
            if dT > dM + 0.01 { ok += 1 }
        }
        return ok >= min(need, n)
    }

    static func obsFingerChainPairs(
        wrist: CGPoint?,
        mcps: [CGPoint?],
        tips: [CGPoint?],
        need: Int = 3
    ) -> Bool {
        var pairedM: [CGPoint] = []
        var pairedT: [CGPoint] = []
        let n = min(mcps.count, tips.count)
        for i in 0..<n {
            if let m = mcps[i], let t = tips[i] {
                pairedM.append(m)
                pairedT.append(t)
            }
        }
        return obsFingerChainOk(wrist: wrist, mcps: pairedM, tips: pairedT, need: need)
    }

    /// Screenshot-Gitarre spannt das Preview. Close-Hand darf groß sein.
    /// Sparse 8 fps: jointCount < 8 ohne Flag tot — fingerSparse sonst tot.
    /// keep:true: Gitarre 0,29 bindet als Hand. Default hart 0,28.
    /// chainOk: Mid-Gitarre 0,50×0,44 kompakt ohne Fingerkette — Close-Hand hält.
    static func obsLooksLikeHand(
        spanW: CGFloat,
        spanH: CGFloat,
        palmScale: CGFloat,
        jointCount: Int,
        keep: Bool = false,
        sparse: Bool = false,
        chainOk: Bool = true,
        fanOk: Bool = true
    ) -> Bool {
        if jointCount < 8 && !sparse { return false }
        if !palmScaleIsHand(palmScale, keep: keep) { return false }
        if !sparse && !chainOk { return false }
        if !sparse && !fanOk { return false }
        if spanW > 0.70 && spanH > 0.58 { return false }
        return true
    }

    /// 0,22 war Flick. Continuity 8 fps 20 cm = Overlay-Snap jede Geste.
    /// 0,35 = Slot-Steal Gitarre→Hand, nicht One-Euro-Reset.
    static let obsSmoothJump: CGFloat = 0.35

    static func obsSmoothJumpOf(dt: TimeInterval) -> CGFloat {
        let d = CGFloat(max(0.040, min(0.20, dt)))
        return obsSmoothJump * (d / 0.125)
    }

    static func obsSmoothResets(
        prevPalm: CGPoint,
        nextPalm: CGPoint,
        hadPrev: Bool,
        chiralityHolds: Bool = true,
        dt: TimeInterval = 0.125
    ) -> Bool {
        guard hadPrev else { return false }
        if !chiralityHolds { return false }
        return hypot(prevPalm.x - nextPalm.x, prevPalm.y - nextPalm.y) > obsSmoothJumpOf(dt: dt)
    }

    /// Vision L/R-Label ist Rauschen. 1↔2 kein neuer Slot, One-Euro hält.
    static func obsSmoothChiralityHolds(prev: Int, live: Int) -> Bool {
        if prev == 0 || live == 0 { return true }
        return prev == live
    }

    /// Wrist+MCP Mittel. Indoor-Blur < 0,40 tot. Sparse weicher 0,22.
    /// Tips tot: Gitarre hohe Wrist-Conf, tote Tips — Mittel allein ließ Prop durch.
    static func obsJointConfOk(
        wrist: Float?,
        mcps: [Float],
        tips: [Float] = [],
        floor: Float = 0.40,
        sparse: Bool = false
    ) -> Bool {
        let used: Float = sparse ? min(floor, 0.22) : floor
        var vals = mcps
        if let wrist { vals.insert(wrist, at: 0) }
        guard !vals.isEmpty else { return sparse }
        let mean = vals.reduce(0, +) / Float(vals.count)
        if mean + 1e-6 < used { return false }
        if !tips.isEmpty {
            let tMean = tips.reduce(0, +) / Float(tips.count)
            if tMean + 1e-6 < used { return false }
        }
        return true
    }

    /// ROI tot: Freeze-Clock / lastFrozenROI nicht schreiben. Coast sonst Crop-Altlast.
    static func palmROIFrozenWrite(_ freeze: Bool, usesROI: Bool? = nil) -> Bool {
        (usesROI ?? palmVisionUsesROI()) && freeze
    }

    /// Crop-Kante: 0,22 ließ 80 px-Hand am Rand tot (w 0,20). 0,10 analog Aegis liveRoi.
    static let palmROIMinFrac: CGFloat = 0.10

    static func palmROIAllows(secondHand: Bool) -> Bool { !secondHand }

    /// Zweite echte Hand Full. Prop zählt nicht — sonst Gitarre+Hand immer Full.
    static func palmROISecondNils(dt: TimeInterval) -> Bool { true }

    static func palmROISecondHands(handSized: Int) -> Bool { handSized >= 2 }

    /// Crop-Miss: ROI 1,8×, dann volles Bild nur bei 24 fps. 8 fps Full-Pass frisst den Tick.
    static func palmROIMissRetries(hadROI: Bool, empty: Bool) -> Bool { hadROI && empty }

    /// 8 fps: nicht Full-Frame. Expand 1,8× zur Bildmitte.
    static func palmROIMissGoesFull(dt: TimeInterval) -> Bool { false }

    /// Zweiter Pass volles Bild nur wenn der Tick es trägt (24 fps).
    static func palmROIMissAllowsFull(dt: TimeInterval) -> Bool { dt < 0.08 }

    /// Continuity 8 fps: Expand leer → nächster Tick Full. Same-Tick Full frisst 125 ms.
    static func palmROIMissFullNext(dt: TimeInterval, expanded: Bool) -> Bool {
        expanded && dt >= 0.08
    }

    /// 24 fps: Full nach 2 Expand-Ticks, nicht nur 8 fps Next. Same-Tick Full leer, Freeze bleibt.
    static func palmROIMissFullAfter(expandMiss: Int, dt: TimeInterval, need: Int = 2) -> Bool {
        expandMiss >= need
    }

    static func palmROIMissExpandAdvance(prev: Int, expandedEmpty: Bool) -> Int {
        expandedEmpty ? min(8, prev + 1) : 0
    }

    /// FullNext Hit: Freeze bleibt alt, nächster Tick miss. Thaw auf Live.
    /// 24 fps Same-Tick Full und Expand-Hit taut sonst nicht — Frozen-Crop ping-pong.
    static func palmROIThawHit(
        didFull: Bool,
        hit: Bool,
        sameTickFull: Bool = false,
        expandHit: Bool = false
    ) -> Bool {
        (didFull || sameTickFull || expandHit) && hit
    }

    /// 24 fps Same-Tick Full leer: Freeze bleibt, FullNext nie. 2 Frozen-Miss → Thaw.
    static func palmROIThawMiss(frozenMiss: Int, need: Int = 2) -> Bool {
        frozenMiss >= need
    }

    static func palmROIThawMissAdvance(prev: Int, frozenEmpty: Bool) -> Int {
        frozenEmpty ? min(8, prev + 1) : 0
    }

    /// Frozen-Crop trifft Gitarre: observations nicht leer, Thaw-Miss tot. Prop-Hit taut.
    static func palmROIThawProp(frozen: Bool, hit: Bool, handHit: Bool, usesROI: Bool? = nil) -> Bool {
        let on = usesROI ?? palmVisionUsesROI()
        return on && frozen && hit && !handHit
    }

    /// Frozen-Crop stirbt nach 400 ms auch ohne Thaw-Hit. Gitarre hält sonst ewig.
    static let palmROIFreezeTTLSec: TimeInterval = 0.40

    static func palmROIFreezeTTL(
        frozenAt: TimeInterval,
        now: TimeInterval,
        ttl: TimeInterval = palmROIFreezeTTLSec
    ) -> Bool {
        frozenAt > 0 && now - frozenAt + 1e-12 >= ttl
    }

    /// Nur während Freeze läuft die Clock. Unfrozen-Snapshot sonst TTL sofort.
    static func palmROIFreezeClock(frozen: Bool, prev: TimeInterval, now: TimeInterval) -> TimeInterval {
        guard frozen else { return 0 }
        return prev > 0 ? prev : now
    }

    static func palmROIIsFull(_ roi: CGRect) -> Bool {
        visionROIIsFull(roi)
    }

    /// Coast: Frozen-ROI folgt Predict, nicht Center Stage.
    static func palmROICoastFollows(_ coast: Bool, usesROI: Bool? = nil) -> Bool {
        coast && (usesROI ?? palmVisionUsesROI())
    }

    static func palmROIFollow(palm: CGPoint?, scale: CGFloat, dt: TimeInterval = 0.016) -> CGRect? {
        palmVisionROI(palm: palm, scale: scale, secondHand: false, dt: dt)
    }

    static func palmROIExpand(_ roi: CGRect, factor: CGFloat = 1.8) -> CGRect {
        let cx = roi.midX
        let cy = roi.midY
        let w = min(1, roi.width * factor)
        let h = min(1, roi.height * factor)
        let x = min(max(0, cx - w / 2), 1 - w)
        let y = min(max(0, cy - h / 2), 1 - h)
        return CGRect(x: x, y: y, width: w, height: h)
    }

    static func palmROIFull() -> CGRect { CGRect(x: 0, y: 0, width: 1, height: 1) }

    /// Vision-Punkte unter regionOfInterest sind 0…1 der ROI. Overlay/SpaceMap erwarten Bild 0…1.
    static func visionROIIsFull(_ roi: CGRect) -> Bool {
        roi.origin.x <= 0.001 && roi.origin.y <= 0.001 && roi.width >= 0.999 && roi.height >= 0.999
    }

    static func visionPointFromROI(_ p: CGPoint, roi: CGRect) -> CGPoint {
        if visionROIIsFull(roi) { return p }
        return CGPoint(x: roi.origin.x + p.x * roi.width, y: roi.origin.y + p.y * roi.height)
    }

    /// Image-space: BBox sitzt in der ROI. ROI-space: BBox füllt 0…1 und ragt aus der ROI.
    static func visionROIPointsNeedMap(
        minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat, roi: CGRect
    ) -> Bool {
        if visionROIIsFull(roi) { return false }
        let pad: CGFloat = 0.06
        if minX >= roi.minX - pad, maxX <= roi.maxX + pad,
           minY >= roi.minY - pad, maxY <= roi.maxY + pad {
            return false
        }
        return true
    }

    static func visionROIMap(roi: CGRect, sample: [CGPoint]) -> CGRect? {
        guard !visionROIIsFull(roi) else { return nil }
        guard !sample.isEmpty else { return roi }
        let xs = sample.map(\.x)
        let ys = sample.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max() else { return roi }
        if visionROIPointsNeedMap(minX: minX, maxX: maxX, minY: minY, maxY: maxY, roi: roi) {
            return roi
        }
        return nil
    }

    /// Tip hinter Palme: Overlay-Knochen aus, Pinch-Bar bleibt.
    static func tipOccluded(tip: CGPoint, palm: CGPoint, scale: CGFloat, extended: Bool) -> Bool {
        if extended { return false }
        guard scale > 0.01 else { return false }
        return hypot(tip.x - palm.x, tip.y - palm.y) < scale * 0.55
    }

    /// Landmark-One-Euro: 8 fps höhere Cutoff, sonst hängt der Tip hinter dem Flick.
    static func oneEuroLandmarkCutoff(base: CGFloat, dt: CGFloat) -> CGFloat {
        dt >= 0.08 ? max(base, 14) : max(base, 10)
    }

    /// HUD: Continuity 8 fps zeigt Hz, Ghost = LATCH. Still-Clutch = HOLD.
    static func fpsLatchChip(fps: Double, ghosting: Bool, frozen: Bool = false, edge: Bool = false, band: String? = nil) -> String {
        let hold = frozen ? " · HOLD" : ""
        let rim = edge ? " · EDGE" : ""
        let bandPart = (band?.isEmpty == false) ? " · \(band!)" : ""
        if fps > 0, fps < 12 {
            return ghosting
                ? String(format: "%.0f Hz · LATCH%@%@%@", fps, hold, rim, bandPart)
                : String(format: "%.0f Hz%@%@%@", fps, hold, rim, bandPart)
        }
        return String(format: "%.0f fps%@%@%@", fps, hold, rim, bandPart)
    }

    static func stillChip(frozen: Bool) -> String? { frozen ? "HOLD" : nil }

    static func slotKeepsID(emptyFor: TimeInterval, latch: TimeInterval = slotLatch) -> Bool {
        emptyFor < latch
    }

    /// preferred() bei Keep-tot: nächste Palme, nicht Observation-first.
    static func preferredNearest(
        keepID: String?,
        poolEmpty: Bool,
        hands: [(id: String, x: CGFloat, y: CGFloat)],
        lastX: CGFloat?,
        lastY: CGFloat?
    ) -> String? {
        if !poolEmpty { return keepID }
        if let keepID, hands.contains(where: { $0.id == keepID }) { return keepID }
        guard let lastX, let lastY, !hands.isEmpty else { return hands.first?.id }
        return hands.min {
            hypot($0.x - lastX, $0.y - lastY) < hypot($1.x - lastX, $1.y - lastY)
        }?.id
    }

    static func cursorWarpHeld(from: CGPoint, to: CGPoint, cap: CGFloat = cursorWarpPx) -> Bool {
        hypot(to.x - from.x, to.y - from.y) > cap
    }

    /// Teleport/Reconnect. 3× Cap: 400 px bei Floor 48. Ein-Achsen-Flick bleibt Axis.
    static func cursorWarpIsTeleport(from: CGPoint, to: CGPoint, cap: CGFloat, mul: CGFloat = 3) -> Bool {
        hypot(to.x - from.x, to.y - from.y) > cap * mul
    }

    /// Je Achse. Hypot-Cap klemmt Y-Flick am X-Rand (destEdge Y frei, Warp tot).
    static func cursorWarpAxis(from: CGPoint, to: CGPoint, cap: CGFloat) -> CGPoint {
        cursorWarpAxis(from: from, to: to, capX: cap, capY: cap)
    }

    static func cursorWarpAxis(from: CGPoint, to: CGPoint, capX: CGFloat, capY: CGFloat) -> CGPoint {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let x: CGFloat = abs(dx) > capX && capX > 0 ? from.x + capX * (dx >= 0 ? 1 : -1) : to.x
        let y: CGFloat = abs(dy) > capY && capY > 0 ? from.y + capY * (dy >= 0 ? 1 : -1) : to.y
        return CGPoint(x: x, y: y)
    }

    /// X-Rand und Warp dieselbe Zahl. destEdgePadOf, nicht hart 40 — 5K sonst Warp 40 / EDGE 64.
    static func cursorWarpCapX(pad: CGFloat = destEdgePad, width: CGFloat? = nil) -> CGFloat {
        destEdgePadOf(width: width ?? 0, floor: pad)
    }

    /// 1 Frame nach Axis-Clamp. Sonst 48 px/Tick sichtbar bei 15 fps.
    static func pointerPredict(from: CGPoint, vel: CGPoint, dt: TimeInterval) -> CGPoint {
        CGPoint(x: from.x + vel.x * CGFloat(dt), y: from.y + vel.y * CGFloat(dt))
    }

    /// Nach destEdgeCross schießt Predict mit der Sprung-Vel über die Seam.
    static func pointerPredictSkipsCross(_ crosses: Bool) -> Bool { crosses }

    static func cursorWarpReject(from: CGPoint, to: CGPoint, cap: CGFloat = cursorWarpPx) -> CGPoint {
        cursorWarpHeld(from: from, to: to, cap: cap) ? from : to
    }

    /// Warp: Smooth auf `from` schreiben. Sonst interpoliert displayTick Richtung Dropout.
    static func cursorWarpHoldsSmooth(from: CGPoint, to: CGPoint, cap: CGFloat = cursorWarpPx) -> CGPoint? {
        cursorWarpHoldsSmoothOf(from: from, to: to, capX: cap, capY: cap)
    }

    /// Hypot-Freeze hält Y mit, obwohl nur X über Cap. destEdge lässt Y entlang der Bezel.
    static func cursorWarpHoldsSmoothOf(from: CGPoint, to: CGPoint, capX: CGFloat, capY: CGFloat) -> CGPoint? {
        let wx = abs(to.x - from.x) > capX
        let wy = abs(to.y - from.y) > capY
        if !wx && !wy { return nil }
        return CGPoint(x: wx ? from.x : to.x, y: wy ? from.y : to.y)
    }

    /// 8 fps Flick 120 px war 80-Cap = kleben. Still 4 px: Cap 48 gegen Reconnect.
    static func medianCursorStep(_ steps: [CGFloat], fallback: CGFloat = 24) -> CGFloat {
        let ok = steps.filter { $0 > 0.5 }
        guard !ok.isEmpty else { return fallback }
        let sorted = ok.sorted()
        return sorted[sorted.count / 2]
    }

    static func cursorWarpCap(medianStep: CGFloat, floor: CGFloat = 48, mul: CGFloat = 3) -> CGFloat {
        max(floor, medianStep * mul)
    }

    /// Warp-Cap je Screen-Diagonale. Fest 48/96 px klebt auf 5K und schießt aufs 13″.
    static func cursorWarpCapScreen(screen: CGRect?, rest: CGFloat = 48, flick: CGFloat = 96) -> CGFloat {
        guard let s = screen, s.width > 1, s.height > 1 else { return rest }
        let diag = hypot(s.width, s.height)
        return min(flick, max(rest, diag * 0.035))
    }

    /// Relock wischt stealScreen. Floor 48 statt der Screen-Diagonale — 5K klebt.
    static func cursorWarpCapScreenOf(steal: CGRect?, map: CGRect?) -> CGFloat {
        cursorWarpCapScreen(screen: steal ?? map)
    }

    /// Laptop-Breite ≠ Höhe. Isotrop-Cap klebt Y auf 13″ und schießt X auf 5K.
    static func cursorWarpCapAxis(steal: CGRect?, map: CGRect?, rest: CGFloat = 48, flick: CGFloat = 96) -> (x: CGFloat, y: CGFloat) {
        let s = steal ?? map
        guard let s, s.width > 1, s.height > 1 else { return (rest, rest) }
        return (
            min(flick, max(rest, s.width * 0.035)),
            min(flick, max(rest, s.height * 0.035))
        )
    }

    /// Relock: Map-Cap 3 Frames halten, auch wenn spaceMap nil bis Load.
    static func cursorWarpCapHold(prev: CGFloat?, live: CGFloat, frames: Int, hold: Int = 3) -> CGFloat {
        if frames > 0, frames <= hold, let prev { return max(prev, live) }
        return live
    }

    /// Continuity 8 fps / Desk-View: Reconnect 60 px war unter Floor 48 = Warp-Kleben.
    /// AE-Fenster: Floor 96 — Faust-AE jagt Luma, Flick ist kein Warp.
    static func cursorWarpFloor(dt: TimeInterval, continuity: Bool = false, lumaWarp: Bool = false) -> CGFloat {
        if lumaWarp { return 96 }
        return (dt >= 0.08 || continuity) ? 64 : 48
    }

    /// Continuity Center Stage croppt der Hand hinterher. Aus, sonst Slot-Sprung.
    static let centerStageOff = true

    static func centerStageDisabled(_ enabled: Bool) -> Bool {
        centerStageOff && !enabled
    }

    /// `.user` (0) wirft beim Setter. `.app` (1) darf Helios abschalten.
    /// `.cooperative` (2) lässt Control Center wieder an — auch dort `.app`.
    static func centerStageNeedsAppControl(currentModeRaw: Int) -> Bool {
        centerStageOff && currentModeRaw != 1
    }

    /// macOS schaltet Center Stage nach Sleep/Clamshell wieder an. Jeder Start/Reselect.
    static func centerStageNeedsReassert(enabled: Bool) -> Bool {
        centerStageOff && enabled
    }

    /// Engine ohne Ghosts (Confidence-Floor): lastPalm 4 s halten, nicht releasePointer.
    static func slotLatchEmptyKeepsPointer(emptyFor: TimeInterval, latch: TimeInterval = 0.25) -> Bool {
        emptyFor >= 0 && emptyFor < latch
    }

    /// Observation da, aber alles unter minConf / Joint-Floor: wie leer geistern, nicht lastHands wischen.
    static func trackerEmptyKeepsGhost(kept: Int) -> Bool {
        kept == 0
    }

    /// Finger tot, Wrist oder 2 MCP da: Palme halten, nicht Slot droppen.
    static func fingerSparseKeepsPalm(
        rawCount: Int,
        hasWrist: Bool,
        mcpCount: Int,
        floor: Int = 8
    ) -> Bool {
        if rawCount >= floor { return false }
        return hasWrist || mcpCount >= 2
    }

    /// MCP tot: Wrist. Wrist tot: MCP. Nicht .zero.
    static func palmCenterFallsBackToWrist(mcpCount: Int, hasWrist: Bool) -> Bool {
        mcpCount < 2 && hasWrist
    }

    static func palmCenterFallsBackToMCP(mcpCount: Int, hasWrist: Bool) -> Bool {
        mcpCount >= 2 && !hasWrist
    }

    /// Sparse-Merge: nur Palme (Wrist/MCP). Tips/DIP kopieren = Phantom-Pinch.
    static func sparseMergeKeeps(isPalmBone: Bool) -> Bool { isPalmBone }

    /// Engine-Filter: Ghosts nicht am Confidence-Floor sterben. Sonst 1.5.65 Tracker tot.
    static func tickKeepsGhost(
        isGhost: Bool,
        joints: Int,
        confidence: Float,
        floor: Float,
        need: Int = 8
    ) -> Bool {
        if isGhost { return true }
        return joints >= need && confidence >= floor
    }

    /// Ghost-Frames lastPoolIDs halten. Wipe → pinchActor/Reconnect tot.
    static func ghostKeepsPool(ghosting: Bool) -> Bool { ghosting }

    /// 6 Joints = 0,45 (Jitter), 21 = 1. Sparse volle Gain = Sprung.
    static func jointGain(count: Int, full: Int = 21) -> CGFloat {
        let n = CGFloat(max(0, min(full, count)))
        let lo: CGFloat = 6
        if n <= lo { return 0.45 }
        return 0.45 + 0.55 * (n - lo) / max(1, CGFloat(full) - lo)
    }

    /// Zweite offene Palme = Gain 0,4 (Zielen). Lock-Hand allein = 1.
    static func twoHandClutchGain(secondOpen: Bool) -> CGFloat {
        secondOpen ? 0.4 : 1
    }

    /// Index-Tip tot, DIP da: letzte DIP-Pose halten, nicht unknown.
    /// Floor 0,40 — 0,18 war identisch zum Joint-Filter, Phantom-Tip 0,22 blieb.
    static func fingerOcclusionHoldsDIP(
        tipConf: Float?,
        hasDIP: Bool,
        floor: Float = pinchOcclusionFloor
    ) -> Bool {
        guard hasDIP else { return false }
        guard let tipConf else { return true }
        return tipConf < floor
    }

    /// Letzter echter Tip vor DIP — DIP als Fake-Tip drückt Pinch-Ratio.
    static func fingerOcclusionUsesLastTip(lastTip: CGPoint?) -> Bool {
        lastTip != nil
    }

    /// 0,40 s: letzter Tip nach Dropout ist tot. 8 fps Ghost sonst Phantom-Pinch.
    static let fingerOcclusionTTL: TimeInterval = 0.40
    /// Ein Frame Occlusion = Jitter. Zwei Ticks = echte Verdeckung.
    static let fingerOcclusionNeed = 2

    static func fingerOcclusionFresh(savedAt: TimeInterval?, now: TimeInterval, ttl: TimeInterval = fingerOcclusionTTL) -> Bool {
        guard let savedAt, savedAt > 0 else { return false }
        return now - savedAt <= ttl
    }

    static func fingerOcclusionConfirm(ticks: Int, need: Int = fingerOcclusionNeed) -> Bool {
        ticks >= need
    }

    /// Nur frischer lastTip. DIP als Tip drückt Pinch-Ratio (Phantom-Klick).
    static func fingerOcclusionTip(lastTip: CGPoint?, dip: CGPoint?, lastTipFresh: Bool = true) -> CGPoint? {
        if lastTipFresh, let t = lastTip { return t }
        return nil
    }

    static func fingerOcclusionChip(held: Bool) -> String? {
        held ? "OCC" : nil
    }

    /// OCC lastTip laggt, Palme wandert: Pinch-Ratio fällt → Phantom-Klick.
    static func fingerOcclusionFollows(lastTip: CGPoint, lastPalm: CGPoint, palm: CGPoint) -> CGPoint {
        if lastPalm.x == 0 && lastPalm.y == 0 { return lastTip }
        return CGPoint(x: lastTip.x + (palm.x - lastPalm.x), y: lastTip.y + (palm.y - lastPalm.y))
    }

    /// OCC-Release kein Klick. Follow hält Ratio, Jitter bleibt.
    static func pinchClickAbortsOcc(_ occ: Bool) -> Bool { occ }


    /// pinchActor last-3 analog pointerPoolReconnect.
    static func actorRebindRing(
        lostID: String,
        candidates: [(id: String, x: CGFloat, y: CGFloat)],
        lastX: CGFloat?,
        lastY: CGFloat?,
        last2X: CGFloat? = nil,
        last2Y: CGFloat? = nil,
        dt: TimeInterval = 0.016
    ) -> String? {
        let radius = reconnectBind(dt: dt)
        if let lastX, let lastY, let id = actorRebind(
            lostID: lostID, candidates: candidates, lastX: lastX, lastY: lastY, bind: radius
        ) {
            return id
        }
        if let last2X, let last2Y, let id = actorRebind(
            lostID: lostID, candidates: candidates, lastX: last2X, lastY: last2Y, bind: radius
        ) {
            return id
        }
        return nil
    }

    /// Overlay-Knochen: S1 cyan, S2 amber — unabhängig von Chirality.
    static func slotHue(_ id: String?) -> String? {
        guard let chip = slotChip(id: id) else { return nil }
        if chip.hasSuffix("2") { return "amber" }
        return "cyan"
    }

    /// Zu: roh (snappy). Auf: geglättet (kein Fern-Flackern bei Continuity).
    static func pinchGateUsesSmoothed(closed: Bool) -> Bool { closed }

    /// Overlay/HUD: Slot-ID S1/S2, sonst Reconnect unsichtbar.
    static func slotChip(id: String?) -> String? {
        guard let id, id.hasPrefix("S"), id.count >= 2, id.count <= 4 else { return nil }
        return id
    }

    /// Actor sitzt im Lock-Pool (Reconnect-ID): sameSlot, nicht Freeze trotz `.any`.
    static func pointerSameSlot(keepID: String?, actorID: String, poolIDs: [String]) -> Bool {
        if keepID == actorID { return true }
        return poolIDs.contains(actorID)
    }

    /// Lock-Hand weg: zweite Hand nicht folgen. Sonst teleportiert der Zeiger.
    static func pointerFreezesSteal(locked: PointerSide, candidate: PointerSide, sameSlot: Bool) -> Bool {
        if sameSlot { return false }
        if locked == .any { return false }
        return !pointerStaysSide(locked: locked, candidate: candidate)
    }

    /// Freeze ohne Chip wirkt tot. HUD „LOCK L/R“. Countdown: „IDLE in 0,8 s“.
    static func pointerStealHUD(
        locked: PointerSide,
        emptySince: TimeInterval? = nil,
        now: TimeInterval = 0,
        dragging: Bool = false,
        need: TimeInterval = pointerStealIdle
    ) -> String {
        let base: String
        switch locked {
        case .left: base = "LOCK L"
        case .right: base = "LOCK R"
        case .any: base = "LOCK"
        }
        if dragging { return "\(base) · DRAG" }
        guard let t = emptySince else { return base }
        let left = need - (now - t)
        guard left > 0, left < need else { return base }
        return "IDLE in \(commaTenths(left)) s"
    }

    static func commaTenths(_ value: TimeInterval) -> String {
        let tenths = max(0, Int((value * 10).rounded()))
        return "\(tenths / 10),\(tenths % 10)"
    }

    /// Faust-Relock: „LOCK … 70%“, analog SCHARF n%.
    static func pointerStealRelockHUD(
        held: TimeInterval?,
        need: TimeInterval = pointerStealRelockHold
    ) -> String? {
        guard let held, held > 0, held < need, need > 0 else { return nil }
        let pct = Int((held / need * 100).rounded())
        return "LOCK … \(pct)%"
    }

    static func scaleStealHUD() -> String { "SCALE" }

    /// Pool leer oder Freeze: andere Hand nicht klicken/wischen. Overlay darf sie zeigen.
    static func pointerStealBlocksActor(poolEmpty: Bool, freeze: Bool) -> Bool {
        poolEmpty || freeze
    }

    /// Faust der anderen Hand nach Freeze: Lock umlegen, nicht tot bleiben.
    /// Default `held` = Need, damit ein Aufruf ohne Zeit wie bisher feuert.
    /// Ein Frame Rauschen (held 0) legt nicht um — 0,35 s Faust.
    /// ⌥-Faust: sofort, ohne Hold.
    static let pointerStealRelockHold: TimeInterval = 0.35
    static let pointerStealIdle: TimeInterval = 1.2

    static func pointerStealRelock(
        freeze: Bool,
        otherFist: Bool,
        held: TimeInterval = pointerStealRelockHold,
        need: TimeInterval = pointerStealRelockHold,
        modifierSkip: Bool = false
    ) -> Bool {
        freeze && otherFist && (modifierSkip || held >= need)
    }

    /// Pool leer 1,2 s: Idle statt ewig LOCK. Lock-Hand da: kein Timeout.
    /// Pinch-Drag: Fenster nicht fallen lassen — Clock läuft nach Up.
    static func pointerStealTimesOut(
        emptySince: TimeInterval?,
        now: TimeInterval,
        poolEmpty: Bool,
        need: TimeInterval = pointerStealIdle,
        dragging: Bool = false,
        ghosting: Bool = false
    ) -> Bool {
        if ghosting { return false }
        if dragging { return false }
        guard poolEmpty, let t = emptySince else { return false }
        return now - t >= need
    }

    /// Freeze: andere Hand darf den Cursor nicht treiben. Nur wenn der Pool leer ist —
    /// Lock-Hand da: Cursor folgt ihr, Grab der anderen bleibt tot.
    static func pointerStealBlocksCursor(steal: Bool) -> Bool { steal }

    /// Continuity 8 fps: displayTick während Freeze interpoliert auf den Externen.
    /// Latch (Lock-Hand da) füllt sonst trotzdem.
    /// Pool leer: Kamera freeze — Tick darf den Cursor nicht in die Bezel laufen, auch bei 24 fps.
    /// Lock-Hand da: interpolieren. destClamp + stealScreen halten den Screen — der 8-fps-Latch
    /// hat den Zeiger bei Continuity auf 8 Hz gedrosselt, obwohl die Map sitzt.
    static func displayTickBlocksSteal(steal: Bool, frameDt: TimeInterval, poolEmpty: Bool = false) -> Bool {
        steal && poolEmpty
    }

    /// Tasche/Gaze darf LOCK nicht vor Steal-Timeout killen. lastInterior war schon alt.
    static func stealHoldsPocket(steal: Bool) -> Bool { steal }

    /// Relock-Hold 8 fps: Velocity halb, nicht nur Freeze-Block.
    static func displayTickCapSteal(base: CGFloat, relock: Bool) -> CGFloat {
        relock ? base * 0.5 : base
    }

    /// Zwei-Hand-Scale ist Scale, nicht Pointer. Steal darf sie nicht killen.
    static func scaleAllowsSteal() -> Bool { true }

    /// Offene Hand zur Kamera (palmScale groß) = Not-Aus, wenn die zweite fehlt.
    /// 3 Finger war eine 40°-Kralle: Not-Aus ohne Stopp-Geste. Immer 4.
    /// Lock-Hand darf nah an die Linse — sonst Continuity-Desk tot sobald die Faust groß ist.
    static func palmReachKills(
        palmScale: CGFloat,
        openScore: Int,
        threshold: CGFloat = 0.28,
        dt: TimeInterval = 0.016,
        side: PointerSide = .any,
        locked: PointerSide = .any
    ) -> Bool {
        if locked != .any, side != .any, pointerStaysSide(locked: locked, candidate: side) {
            return false
        }
        _ = dt
        return openScore >= 4 && palmScale >= threshold
    }

    /// Fill unter 28 px/s ist Jitter, kein Coast in fremde Fenster.
    static func displayTickCoasts(_ speed: CGFloat, floor: CGFloat = 28) -> Bool {
        speed >= floor
    }

    /// Focus-PID hält, solange die Hand still ist oder ein Grab läuft.
    static func pollFocusHolds(moved: Bool, dragging: Bool, hadFocus: Bool) -> Bool {
        if dragging { return true }
        if !hadFocus { return false }
        return !moved
    }

    static func focusStealLatches(prevPID: Int32?, nextPID: Int32?, pinchHeld: Bool) -> Bool {
        guard pinchHeld, let prevPID, let nextPID, prevPID != 0, nextPID != 0 else { return false }
        return prevPID != nextPID
    }

    /// Relativzeiger: Span des Screens unter dem Cursor, nicht die Union.
    static func relativeStepSpan(cursor: CGPoint, screens: [CGRect], union: CGRect) -> CGSize {
        let hit = screens.first { $0.insetBy(dx: -8, dy: -8).contains(cursor) }
        let r = hit ?? union
        guard r.width > 1, r.height > 1 else { return union.size }
        return r.size
    }

    /// Median der positiven Frame-Lücken. 8 fps vs 24 fps an einer Stelle.
    static func medianDt(_ samples: [(t: TimeInterval, x: CGFloat, y: CGFloat)], fallback: TimeInterval = 0.016) -> TimeInterval {
        guard samples.count >= 2 else { return fallback }
        var dts: [TimeInterval] = []
        dts.reserveCapacity(samples.count - 1)
        for i in 1..<samples.count {
            let d = samples[i].t - samples[i - 1].t
            if d > 0.004 { dts.append(d) }
        }
        guard !dts.isEmpty else { return fallback }
        dts.sort()
        return dts[dts.count / 2]
    }

    /// Zeigerhand wischen: nur wenn der Zeiger still ist oder der Weg klar ein Flick ist.
    static func swipeBlockedByPointer(dx: CGFloat, pointerMoving: Bool) -> Bool {
        pointerMoving && abs(dx) < swipeMinDx * swipeVsPointerMul
    }

    static func nearFlingClick(speed: CGFloat) -> Bool {
        speed >= flingMinSpeed * flingClickGuard && speed < flingMinSpeed
    }

    /// Down nur bei stiller Pinzette. Cursor ist während Hold eingefroren — Palm-Speed ist der Proxy.
    static func pinchDownBlocked(speed: CGFloat) -> Bool {
        speed > pinchDownSpeed
    }

    /// Zwei-Pinzetten-Scale: Relativ **und** absolute Totzone, sonst zittert die zweite Hand.
    /// 8 fps Dead × 1,8 — sonst jeder Continuity-Tick ein Scale.
    static func scaleMoved(old: CGFloat, span: CGFloat, dt: TimeInterval = 0.016) -> Bool {
        let dead = dt >= 0.08 ? scalePalmDead * 1.8 : scalePalmDead
        return abs(span - old) > max(scaleRel * max(old, span), dead)
    }

    /// Pinch-Hold: Wrist-MAD > Rest × 2,8. Zitter-Hand sonst zieht Fenster.
    static func pinchHoldAborts(mad: CGFloat, rest: CGFloat = palmStill) -> Bool {
        mad > max(rest * 2.8, 0.022)
    }

    static func fling(
        dx: CGFloat,
        dy: CGFloat,
        speed: CGFloat,
        dist: CGFloat,
        speedPx: CGFloat = 0,
        minPx: CGFloat = 0
    ) -> FlingKind {
        let fast = minPx > 1 ? speedPx > minPx : speed > flingMinSpeed
        let far = dist > flingMinDist || (minPx > 1 && speedPx > minPx * 0.45)
        guard fast, far else { return .none }
        if abs(dy) >= abs(dx) * flingAxis {
            if dy > 0.08 { return .throwUp }
            if dy < -0.05 { return .minimize }
            return .none
        }
        if abs(dx) >= abs(dy) * flingAxis {
            if dx < -0.07 { return .dockLeft }
            if dx > 0.07 { return .dockRight }
            return .none
        }
        return .none
    }

    /// Residual 0…mapGainStart → 1. Residual ≥ mapDriftResidual → mapGainFloor.
    /// Homographie im Void darf den Zeiger nicht voll mitziehen.
    static func mapGain(residual: CGFloat) -> CGFloat {
        if residual <= mapGainStart { return 1 }
        if residual >= mapDriftResidual { return mapGainFloor }
        let span = max(1, mapDriftResidual - mapGainStart)
        let t = (residual - mapGainStart) / span
        return 1 - (1 - mapGainFloor) * t
    }

    /// 8 fps vs 24 fps: Fenster = max(120 ms, 2,5 × Median-dt).
    static func adaptiveFlingWindow(
        _ samples: [(t: TimeInterval, x: CGFloat, y: CGFloat)],
        pref: TimeInterval = flingWindow
    ) -> TimeInterval {
        let base = flingWindowPref(pref)
        let median = medianDt(samples, fallback: 0)
        if median <= 0 { return base }
        return max(base, TimeInterval(flingWindowMul) * median)
    }

    /// 8 fps: 0,28 s Trail hält oft nur 2 Samples, minDt 0,16 fällt. Länger halten.
    static func adaptiveSwipeTrail(_ samples: [(t: TimeInterval, x: CGFloat, y: CGFloat)]) -> TimeInterval {
        let median = medianDt(samples, fallback: 0)
        if median <= 0 { return swipeTrail }
        return max(swipeTrail, TimeInterval(swipeTrailMul) * median)
    }

    /// Geschwindigkeit/Weg nur aus dem adaptiven Fling-Fenster, nicht 0,5 s Halten.
    /// Der 0,5-s-Trail verdünnt einen 120-ms-Flick unter flingMinSpeed.
    /// Bei 8–12 fps hat das 120-ms-Fenster oft nur 1 Sample — dann die letzten 4.
    static func trailMotion(
        _ samples: [(t: TimeInterval, x: CGFloat, y: CGFloat)],
        window: TimeInterval = flingWindow
    ) -> (dx: CGFloat, dy: CGFloat, speed: CGFloat, dist: CGFloat) {
        guard let last = samples.last else { return (0, 0, 0, 0) }
        let win = adaptiveFlingWindow(samples, pref: window)
        var window = samples.filter { last.t - $0.t <= win }
        let windowDt = (window.last?.t ?? last.t) - (window.first?.t ?? last.t)
        if window.count < 2 || windowDt <= 0.04 {
            window = Array(samples.suffix(4))
        }
        guard let first = window.first, last.t > first.t + 0.02 else { return (0, 0, 0, 0) }
        let dt = max(0.04, last.t - first.t)
        let dx = last.x - first.x
        let dy = last.y - first.y
        return (dx, dy, hypot(dx, dy) / dt, hypot(dx, dy))
    }

    /// bugfix 1.5.8: Werfen nur aus dem Fling-Fenster. Center-Dead am letzten Sample, nicht Trail-Anfang.
    static func flingFromTrail(
        _ trail: [(t: TimeInterval, x: CGFloat, y: CGFloat)],
        screenHeight: CGFloat = 900,
        centerDead: Bool = true,
        window: TimeInterval = flingWindow
    ) -> FlingKind {
        guard let last = trail.last else { return .none }
        if centerDead {
            let fromCenter = hypot(last.x - 0.5, last.y - 0.5)
            if fromCenter < flingCenter { return .none }
        }
        let motion = trailMotion(trail, window: window)
        return fling(
            dx: motion.dx,
            dy: motion.dy,
            speed: motion.speed,
            dist: motion.dist,
            speedPx: motion.speed * screenHeight,
            minPx: flingMinSpeedPx(screenHeight: screenHeight)
        )
    }

    /// 8 fps vs 24 fps: höherer Cutoff bei großem dt, sonst hängt der Zeiger einen Frame hinterher.
    static func oneEuroCutoff(base: CGFloat, dt: CGFloat) -> CGFloat {
        dt >= 0.10 ? base * 1.7 : base
    }

    /// Chirality sprang (R→L): dieselbe Palm, nicht die andere Hand.
    static func actorRebind(
        lostID _: String,
        candidates: [(id: String, x: CGFloat, y: CGFloat)],
        lastX: CGFloat,
        lastY: CGFloat,
        bind: CGFloat = unknownPalmBind
    ) -> String? {
        var best: String?
        var bestD = bind
        for c in candidates {
            let d = hypot(c.x - lastX, c.y - lastY)
            if d < bestD {
                bestD = d
                best = c.id
            }
        }
        return best
    }

    /// RMS der 4 Kalib-Lücken. 70 px × 4 Ecken war „fertig“ — Map wirft.
    static let mapRMSLimit: CGFloat = 40

    static func mapRMS(_ errors: [CGFloat]) -> CGFloat {
        let ok = errors.filter { $0.isFinite && $0 >= 0 }
        guard !ok.isEmpty else { return .infinity }
        let s = ok.reduce(CGFloat(0)) { $0 + $1 * $1 }
        return sqrt(s / CGFloat(ok.count))
    }

    static func mapRMSReady(_ rms: CGFloat, limit: CGFloat = mapRMSLimit) -> Bool {
        rms.isFinite && rms < limit
    }

    static func mapRMSLabel(_ rms: CGFloat?) -> String? {
        guard let rms, rms.isFinite else { return nil }
        let n = Int(rms.rounded())
        if mapRMSReady(rms) { return "RMS \(n)" }
        return "RMS \(n)!"
    }

    /// Knie am Rand darf Scharf halten wenn VNFace sitzt. Clamshell immer Idle.
    static func armedIdle(
        faces: Int,
        lastFace: TimeInterval,
        lastInterior: TimeInterval,
        now: TimeInterval,
        lidClosed: Bool = false,
        cameraFallback: Bool = false,
        extraScreens: Bool = false
    ) -> Bool {
        if lidBlocksArm(lidClosed: lidClosed, cameraFallback: cameraFallback, extraScreens: extraScreens) { return true }
        if pocketIdle(cameraFallback: cameraFallback, lastInterior: lastInterior, now: now) { return true }
        if faceCountIdle(faces: faces, lastSeen: lastFace, now: now) { return true }
        if faces > 0 { return false }
        return gazeIdle(lastInterior: lastInterior, now: now)
    }

    static func lidClosedIdle(_ closed: Bool) -> Bool { closed }

    /// Zweite Hand: Peace = ⌘, Point = ⌥, Faust = ⇧.
    enum ModKind: String {
        case none, command, option, shift
    }

    static func modifierKind(peace: Bool, point: Bool, fist: Bool) -> ModKind {
        if peace { return .command }
        if point { return .option }
        if fist { return .shift }
        return .none
    }

    static func modifierChip(_ kind: ModKind) -> String? {
        switch kind {
        case .none: return nil
        case .command: return "⌘"
        case .option: return "⌥"
        case .shift: return "⇧"
        }
    }

    /// CGEventFlags raw: command 0x100000, option 0x80000, shift 0x20000.
    static func modifierFlagBits(_ kind: ModKind) -> UInt64 {
        switch kind {
        case .none: return 0
        case .command: return 0x100000
        case .option: return 0x80000
        case .shift: return 0x20000
        }
    }

    /// AX ElementAtPosition über 8 ms: Probe tot, Cursor läuft.
    static let axHitTimeoutMs: Double = 8

    static func axProbeTimesOut(ms: Double, budget: Double = axHitTimeoutMs) -> Bool {
        ms > budget
    }

    static let flingUndoNeed: TimeInterval = 0.40

    static func flingUndo(now: TimeInterval, lastFling: TimeInterval, peace: Bool, pinch: Bool) -> Bool {
        lastFling > 0 && now - lastFling <= flingUndoNeed && peace && pinch
    }

    static let dwellNeed: TimeInterval = 0.70

    static func dwellClick(held: TimeInterval, dock: Bool, enabled: Bool, need: TimeInterval = dwellNeed) -> Bool {
        enabled && dock && held >= need
    }

    static func pinchNeedMul(speed: CGFloat) -> CGFloat {
        if speed >= pinchDownSpeed { return 1 }
        if speed <= palmStill { return 0 }
        return min(1, speed / pinchDownSpeed)
    }

    /// Hardware-Maus stiehlt nur bei ruhiger Palm. Sonst warpt Helios den Trackpad-Jitter weg.
    static let clutchMouseStill: CGFloat = 8
    static let clutchMouseMoving: CGFloat = 28
    static let clutchDragStill: CGFloat = 4
    static let clutchDragMoving: CGFloat = 16

    static func trackpadClutch(
        mouseDelta: CGFloat,
        palmSpeed: CGFloat,
        dragged: Bool = false
    ) -> Bool {
        let stillNeed = dragged ? clutchDragStill : clutchMouseStill
        let movingNeed = dragged ? clutchDragMoving : clutchMouseMoving
        let need = palmSpeed < palmUnstill ? stillNeed : movingNeed
        return mouseDelta > need
    }

    static func clamshellIdle(_ closed: Bool) -> Bool { lidClosedIdle(closed) }

    /// Eine Phase, eine Clock. HUD und Gatter lesen dasselbe.
    enum EnginePhase: String {
        case idle, armed, pinch, drag, scale, kill

        var labelDE: String {
            switch self {
            case .idle: return "IDLE"
            case .armed: return "SCHARF"
            case .pinch: return "PINCH"
            case .drag: return "ZIEHEN"
            case .scale: return "SCALE"
            case .kill: return "KILL"
            }
        }
    }

    static func enginePhase(
        modeArmed: Bool,
        pinchHeld: Bool,
        dragging: Bool,
        scaleActive: Bool,
        kill: Bool = false
    ) -> EnginePhase {
        if kill { return .kill }
        if !modeArmed { return .idle }
        if scaleActive { return .scale }
        if dragging { return .drag }
        if pinchHeld { return .pinch }
        return .armed
    }

    static func enginePhaseChip(_ phase: EnginePhase) -> String { phase.labelDE }

    /// Idle und Kill klicken nicht. Phase treibt das Gatter, nicht vier Bools.
    static func phaseBlocksClick(_ phase: EnginePhase) -> Bool {
        switch phase {
        case .idle, .kill: return true
        case .armed, .pinch, .drag, .scale: return false
        }
    }

    enum ClickHapticKind: String {
        case none, generic, alignment
    }

    static func clickHapticKind(ok: Bool, alignment: Bool = false) -> ClickHapticKind {
        guard ok else { return .none }
        return alignment ? .alignment : .generic
    }

    static func tickClock(now: TimeInterval, lastTick: TimeInterval, fallback: TimeInterval = 0.016) -> TimeInterval {
        lastTick == 0 ? fallback : max(0.008, now - lastTick)
    }

    static let screenBlendNeed: TimeInterval = 0.12

    static func screenBlendT(elapsed: TimeInterval, need: TimeInterval = screenBlendNeed) -> CGFloat {
        CGFloat(min(1, max(0, elapsed / need)))
    }

    /// destEdgeCross: Blend 0,12 s zieht den Cursor auf den alten Schirm zurück.
    static func screenBlendSkipsCross(_ crosses: Bool) -> Bool { crosses }

    static func screenBlend(from: CGPoint, to: CGPoint, t: CGFloat) -> CGPoint {
        let u = min(max(t, 0), 1)
        let s = u * u * (3 - 2 * u)
        return CGPoint(x: from.x + (to.x - from.x) * s, y: from.y + (to.y - from.y) * s)
    }

    static func screenChanged(prevID: String?, nextID: String?) -> Bool {
        guard let prevID, let nextID else { return false }
        return prevID != nextID
    }

    /// first-contains = screens.first: 16 px Überlapp → Laptop stiehlt den 5K.
    static func screenKey(point: CGPoint, screens: [(id: String, bounds: CGRect)]) -> String? {
        let rects = screens.map(\.bounds)
        guard let hit = destEdgeNearest(point, screens: rects)?.screen else { return nil }
        return screens.first {
            abs($0.bounds.minX - hit.minX) < 1
                && abs($0.bounds.minY - hit.minY) < 1
                && abs($0.bounds.width - hit.width) < 1
                && abs($0.bounds.height - hit.height) < 1
        }?.id
    }

    /// Relativ-Pfad schreibt lastScreenID sonst nie. destClampMapHolds sieht current=nil, Map tot.
    /// Nach Seed muss current folgen, sonst Laptop-Map auf dem 5K. Seam hält per Interior-Hysterese.
    static func screenKeySeed(point: CGPoint, screens: [(id: String, bounds: CGRect)], current: String?) -> String? {
        let next = screenKey(point: point, screens: screens)
        guard let current, !current.isEmpty else { return next }
        if next == current { return current }
        guard let next,
              let curB = screens.first(where: { $0.id == current })?.bounds,
              let nextB = screens.first(where: { $0.id == next })?.bounds
        else { return current }
        let innCur = destEdgeInterior(point, in: curB)
        let innNext = destEdgeInterior(point, in: nextB)
        let gap = destEdgeOverlapGap(screens: screens.map(\.bounds))
        if innNext > gap && innCur < gap { return next }
        if innNext > innCur + gap { return next }
        return current
    }

    /// Overlap Laptop+5K aus CGDisplayBounds, nicht hart 16/40. Floor 16, Cap 64.
    static func destEdgeOverlapGap(screens: [CGRect], floor: CGFloat = 16, cap: CGFloat = 64) -> CGFloat {
        var g = floor
        guard screens.count >= 2 else { return g }
        for i in 0..<screens.count {
            for j in (i + 1)..<screens.count {
                let inter = screens[i].intersection(screens[j])
                if inter.isNull || inter.isInfinite || inter.width < 1 || inter.height < 1 { continue }
                g = max(g, min(cap, max(inter.width, inter.height)))
            }
        }
        return g
    }

    /// 8 fps Faust-Zittern sonst Klick-Burst. Zwei Frames Pflicht.
    static func fistClickDebounce(frames: Int, need: Int = 2) -> Bool { frames >= need }

    /// CGWarp driftet. NSEvent.mouseLocation Ground-Truth, RMS > 8 px Reanchor.
    static func pointerReanchor(warped: CGPoint, truth: CGPoint, rms: CGFloat = 8) -> CGPoint? {
        hypot(warped.x - truth.x, warped.y - truth.y) > rms ? truth : nil
    }

    /// Overlay 90 Hz zwischen zwei Vision-Poses. Continuity 8 fps sonst Skelett-Ruck.
    static func overlayPalmLerp(prev: CGPoint, next: CGPoint, t: CGFloat) -> CGPoint {
        let u = min(1, max(0, t))
        return CGPoint(x: prev.x + (next.x - prev.x) * u, y: prev.y + (next.y - prev.y) * u)
    }

    static func overlayLerpT(elapsed: TimeInterval, frameDt: TimeInterval) -> CGFloat {
        guard frameDt > 0.001 else { return 1 }
        return CGFloat(min(1, max(0, elapsed / frameDt)))
    }

    /// Nur echtes 8–20 fps. Ab 24 fps Snap — Lerp + Extrapolate hängt in der Luft.
    static func overlayLerpShould(dt: TimeInterval) -> Bool { false }

    /// Smoothstep — linear Lerp ruckt 8 fps. Bezier zwischen zwei Vision-Poses.
    static func overlayBezierEase(_ t: CGFloat) -> CGFloat {
        let u = min(1, max(0, t))
        return u * u * (3 - 2 * u)
    }

    /// Per-Frame Delta. Overlay-Extrapolate nach t=1, sonst Freeze bis zum nächsten Vision-Tick.
    static func overlayVel(from: CGPoint, to: CGPoint) -> CGPoint {
        CGPoint(x: to.x - from.x, y: to.y - from.y)
    }

    /// t>1: next + vel·(t−1), Cap 0,08 Bild. Coast-Ghost Overlay 90 Hz.
    static func overlayExtrapolate(prev: CGPoint, vel: CGPoint, extra: CGFloat, cap: CGFloat = 0.08) -> CGPoint {
        let d = CGPoint(x: vel.x * extra, y: vel.y * extra)
        let mag = hypot(d.x, d.y)
        if mag > cap && mag > 0 {
            return CGPoint(x: prev.x + d.x / mag * cap, y: prev.y + d.y / mag * cap)
        }
        return CGPoint(x: prev.x + d.x, y: prev.y + d.y)
    }

    static func overlayBezier(prev: CGPoint, next: CGPoint, t: CGFloat, vel: CGPoint = .zero) -> CGPoint {
        if t <= 1 {
            return overlayPalmLerp(prev: prev, next: next, t: overlayBezierEase(t))
        }
        return next
    }

    /// Overlay-Skelett 90 Hz. IDs aus `to`, Pose aus prev→next, t>1 Extrapolate.
    static func overlayLerpHands(
        from: [(id: String, palm: CGPoint)],
        to: [(id: String, palm: CGPoint)],
        t: CGFloat
    ) -> [(id: String, palm: CGPoint)] {
        return to.map { next in
            guard let prev = from.first(where: { $0.id == next.id }) else { return next }
            let vel = overlayVel(from: prev.palm, to: next.palm)
            return (id: next.id, palm: overlayBezier(prev: prev.palm, next: next.palm, t: t, vel: vel))
        }
    }

    /// Wrist–MCP Median, nicht nur Mittel. Gitarre halluziniert denselben Span.
    static func palmScaleWristMCP(wrist: CGPoint?, mcps: [CGPoint], floor: CGFloat = 0.05) -> CGFloat? {
        guard let wrist, !mcps.isEmpty else { return nil }
        let spans = mcps.map { hypot(wrist.x - $0.x, wrist.y - $0.y) }.sorted()
        return max(floor, spans[spans.count / 2])
    }

    /// Finger-span vs Wrist–MCP. Span handgroß, Wrist Prop → Gitarre. Span ≥ 1,8× Wrist ebenfalls.
    static func palmScaleSpanVeto(wristMCP: CGFloat, span: CGFloat, ratio: CGFloat = 1.8) -> Bool {
        if palmScaleIsHand(span) && !palmScaleIsHand(wristMCP) { return true }
        return span + 1e-12 >= wristMCP * ratio && wristMCP > 0
    }

    /// Max-Paar über alle MCP, nicht nur Index–Klein. Gitarre ohne die zwei Gelenke sonst Hand.
    static func palmScaleSpanOf(_ mcps: [CGPoint]) -> CGFloat {
        guard mcps.count >= 2 else { return 0 }
        var best: CGFloat = 0
        for i in 0..<mcps.count {
            for j in (i + 1)..<mcps.count {
                best = max(best, hypot(mcps[i].x - mcps[j].x, mcps[i].y - mcps[j].y))
            }
        }
        return best
    }

    /// Winkel Wrist–MCP-Paar. Hand fächert, Gitarrenhals ist eine Linie.
    static func palmMCPPairDeg(wrist: CGPoint, a: CGPoint, b: CGPoint) -> CGFloat {
        let ax = a.x - wrist.x, ay = a.y - wrist.y
        let bx = b.x - wrist.x, by = b.y - wrist.y
        let da = hypot(ax, ay), db = hypot(bx, by)
        guard da > 1e-6, db > 1e-6 else { return 0 }
        let c = max(-1, min(1, (ax * bx + ay * by) / (da * db)))
        return acos(c) * 180 / .pi
    }

    /// Max-Fächer über MCP. Hand 30–90°, Gitarre/Hals < 18°.
    static func palmMCPFanDeg(wrist: CGPoint?, mcps: [CGPoint]) -> CGFloat {
        guard let wrist, mcps.count >= 2 else { return 0 }
        var best: CGFloat = 0
        for i in 0..<mcps.count {
            for j in (i + 1)..<mcps.count {
                best = max(best, palmMCPPairDeg(wrist: wrist, a: mcps[i], b: mcps[j]))
            }
        }
        return best
    }

    static let palmMCPFanHand: CGFloat = 18

    static func palmMCPCollinearVeto(fan: CGFloat, floor: CGFloat = palmMCPFanHand) -> Bool {
        fan + 1e-6 < floor
    }

    /// Bind-Scale 3 Ticks EMA auf lastS1. Gitarre-Flicker 0,29 sonst jeden Tick neu.
    static func palmBindScaleOf(live: CGFloat, last: CGFloat?, ticks: Int, alpha: CGFloat = 0.45, need: Int = 3) -> CGFloat {
        guard let last, ticks >= need else { return live }
        return alpha * live + (1 - alpha) * last
    }

    static let palmScaleMedianCap = 8

    static func palmScaleMedian(_ samples: [CGFloat]) -> CGFloat? {
        let s = Array(samples.suffix(palmScaleMedianCap)).sorted()
        guard !s.isEmpty else { return nil }
        return s[s.count / 2]
    }

    /// Nur S1 live. S2/Prop nach Coast stiehlt sonst den Median-Ring.
    static func palmScaleMedianKeeps(s1Live: Bool) -> Bool { s1Live }

    /// Observation-first: Gitarre vor Hand. Hands (klein) zuerst binden.
    /// lastS1: unter 0,28 gewinnt Näher, nicht kleiner — Gitarre 0,25 sonst vor Hand 0,27.
    /// counts: dichte Hand vor sparsamer Gitarre, wenn last fehlt.
    static func palmBindHandsFirst(
        scales: [CGFloat],
        palms: [CGPoint] = [],
        last: CGPoint? = nil,
        counts: [Int] = []
    ) -> [Int] {
        scales.indices.sorted { a, b in
            let ha = palmScaleIsHand(scales[a])
            let hb = palmScaleIsHand(scales[b])
            if ha != hb { return ha && !hb }
            if ha, let last, a < palms.count, b < palms.count {
                let da = hypot(palms[a].x - last.x, palms[a].y - last.y)
                let db = hypot(palms[b].x - last.x, palms[b].y - last.y)
                if abs(da - db) > 1e-6 { return da < db }
            }
            if ha, a < counts.count, b < counts.count, counts[a] != counts[b] {
                return counts[a] > counts[b]
            }
            return scales[a] < scales[b]
        }
    }

    /// Pinch-Click vs Drag getrennte Hysterese. Band dazwischen tot — Drag stiehlt sonst Click-Lock.
    static func pinchClickVsDrag(moved: CGFloat, clickMax: CGFloat = 6, dragMin: CGFloat = 12) -> String? {
        if moved < clickMax { return "click" }
        if moved >= dragMin { return "drag" }
        return nil
    }

    /// Fill-Cap Laptop vs 5K, getrennt von Warp-Cap.
    static func fillCapPref(width: CGFloat, small: CGFloat = 12, large: CGFloat = 28) -> CGFloat {
        width >= 2560 ? large : small
    }

    static func fillCapLaptopPref(_ v: CGFloat) -> CGFloat { min(24, max(8, v)) }
    static func fillCapStudioPref(_ v: CGFloat) -> CGFloat { min(48, max(12, v)) }

    static func fillCapPrefOf(width: CGFloat, laptop: CGFloat, studio: CGFloat) -> CGFloat {
        fillCapPref(width: width, small: fillCapLaptopPref(laptop), large: fillCapStudioPref(studio))
    }

    /// Fill-Cap je Display-UUID. Clamshell sonst Studio-28 auf dem Laptop.
    static func fillCapByUUID(
        id: String,
        width: CGFloat,
        stored: [String: CGFloat],
        laptop: CGFloat,
        studio: CGFloat
    ) -> CGFloat {
        if let s = stored[id], s > 0 { return s }
        return fillCapPrefOf(width: width, laptop: laptop, studio: studio)
    }

    static func fillCapMapPut(id: String, cap: CGFloat, width: CGFloat, onto: [String: CGFloat]) -> [String: CGFloat] {
        guard !id.isEmpty else { return onto }
        var out = onto
        out[id] = width >= 2560 ? fillCapStudioPref(cap) : fillCapLaptopPref(cap)
        return out
    }

    /// Pad-Slider: welcher Schirm. lastScreenID sonst still.
    static func destEdgePadScreenName(id: String, names: [(id: String, name: String)]) -> String {
        if id.isEmpty { return "—" }
        return names.first(where: { $0.id == id })?.name ?? id
    }

    /// Pad je Display-UUID. Clamshell vs Studio sonst Laptop-24 auf dem 5K.
    static func destEdgePadByUUID(id: String, width: CGFloat, stored: [String: CGFloat], floor: CGFloat) -> CGFloat {
        if let s = stored[id], s > 0 { return destEdgePadPref(s) }
        return destEdgePadLive(width: width, pref: floor)
    }

    static func destEdgePadMapPut(id: String, pad: CGFloat, onto: [String: CGFloat]) -> [String: CGFloat] {
        guard !id.isEmpty else { return onto }
        var out = onto
        out[id] = destEdgePadPref(pad)
        return out
    }

    static func screenArrangementHash(_ screens: [(id: String, bounds: CGRect)]) -> String {
        screens.map {
            "\($0.id):\(Int($0.bounds.minX)),\(Int($0.bounds.minY)),\(Int($0.bounds.width)),\(Int($0.bounds.height))"
        }.joined(separator: "|")
    }

    static func screenArrangementChanged(prev: String, next: String) -> Bool {
        !prev.isEmpty && prev != next && !next.isEmpty
    }

    /// CADisplayLink 120 Hz ProMotion. Timer.common coalesced gegen vsync.
    static func displayLinkUsesCA() -> Bool { true }

    /// Pulse tot: Vision muss warpen. lastDisplayTick 0 = Start, Fill noch nicht.
    static func displayLinkPulseAlive(lastPulse: TimeInterval, now: TimeInterval, stale: TimeInterval = 0.08) -> Bool {
        lastPulse > 0 && (now - lastPulse) <= stale
    }

    static func displayLinkPulseStale(_ alive: Bool) -> Bool { !alive }

    static func displayLinkPreferredHz(_ screenHz: Double = 120) -> Double {
        min(120, max(30, screenHz))
    }

    /// Studio 60, ProMotion 120. Ein hartes 120 auf 60-Hz-Panel skippt vsync.
    static func displayLinkHzOf(fps: Int) -> Double {
        displayLinkPreferredHz(Double(max(1, fps)))
    }

    /// NSScreen.main neben 5K: Laptop 120, Studio 60. Max, nicht main.
    static func displayLinkHzOf(fpsList: [Int]) -> Double {
        displayLinkHzOf(fps: fpsList.filter { $0 > 0 }.max() ?? 120)
    }

    /// Dual 60+120: beide Links feuern. Unter minGap kein zweiter Fill — Cursor-Sprung tot.
    static func displayLinkDebounce(last: TimeInterval, now: TimeInterval, minGap: TimeInterval = 0.004) -> Bool {
        now - last >= minGap
    }

    /// Clamshell / 5K: DisplayID+Hz. Unsortiert sonst falsches Rearm.
    static func displayLinkLayoutToken(_ screens: [(id: UInt32, hz: Int)]) -> String {
        screens.sorted { $0.id < $1.id }.map { "\($0.id):\($0.hz)" }.joined(separator: "|")
    }

    static func displayLinkLayoutChanged(prev: String, next: String) -> Bool {
        prev != next
    }

    /// Warp nur Zielschirm. Overlay-Lerp läuft trotzdem — Gate auf den ganzen Tick fror das HUD.
    static func displayLinkIsDest(screenIndex: Int?, cursor: CGPoint?, screens: [CGRect]) -> Bool {
        guard let screenIndex else { return true }
        return displayLinkScreenIndex(cursor: cursor, screens: screens) == screenIndex
    }

    /// Cursor-Schirm zuerst. main lügt neben 5K.
    static func displayLinkScreenIndex(cursor: CGPoint?, screens: [CGRect]) -> Int {
        guard !screens.isEmpty else { return 0 }
        if let cursor {
            var best = 0
            var bestArea = CGFloat.greatestFiniteMagnitude
            var hit = false
            for (i, r) in screens.enumerated() {
                if r.contains(cursor) {
                    let area = r.width * r.height
                    if !hit || area < bestArea {
                        best = i
                        bestArea = area
                        hit = true
                    }
                }
            }
            if hit { return best }
            var near = 0
            var dBest = CGFloat.greatestFiniteMagnitude
            for (i, r) in screens.enumerated() {
                let dx = max(r.minX - cursor.x, 0, cursor.x - r.maxX)
                let dy = max(r.minY - cursor.y, 0, cursor.y - r.maxY)
                let d = hypot(dx, dy)
                if d < dBest {
                    dBest = d
                    near = i
                }
            }
            return near
        }
        var maxI = 0
        var maxHzDummy = screens[0].width * screens[0].height
        for (i, r) in screens.enumerated() where i > 0 {
            let a = r.width * r.height
            if a > maxHzDummy {
                maxHzDummy = a
                maxI = i
            }
        }
        return maxI
    }

    static func cameraMutexOwnerHelios() -> String { "helios" }
    static func cameraMutexOwnerAegis() -> String { "aegis" }
    static func cameraMutexName() -> String { "helios.aegis.camera.lock" }
    /// 3 s war kürzer als Continuity-Frame + 32-Tick Geometry. Heartbeat 2 s, Stale 12.
    static func cameraMutexStale() -> TimeInterval { 12 }

    static func cameraMutexLine(owner: String, pid: Int32, now: TimeInterval) -> String {
        "\(owner) \(pid) \(Int(now))"
    }

    static func cameraMutexParse(_ text: String, now: TimeInterval, stale: TimeInterval = cameraMutexStale()) -> String? {
        let parts = text.split(whereSeparator: { $0 == " " || $0 == "\n" }).map(String.init)
        guard parts.count >= 3, let stamp = TimeInterval(parts[2]) else { return nil }
        if now - stamp > stale { return nil }
        let owner = parts[0]
        if owner != cameraMutexOwnerHelios() && owner != cameraMutexOwnerAegis() { return nil }
        return owner
    }

    static func cameraMutexBlocks(holder: String?, owner: String) -> Bool {
        guard let holder else { return false }
        return holder != owner
    }

    static func cameraMutexYieldsContinuity(holder: String?, owner: String) -> Bool {
        holder == cameraMutexOwnerHelios() && owner == cameraMutexOwnerAegis()
    }

    /// bugfix 1.5.8: Dead-Man Faust-Timeout 2–8 s. Default bleibt 1,6.
    static func deadManFistPref(_ pref: TimeInterval) -> TimeInterval {
        min(8, max(1.6, pref))
    }

    /// bugfix 1.5.8: Fling-Fenster 0,12–0,55 s.
    static func flingWindowPref(_ pref: TimeInterval) -> TimeInterval {
        min(0.55, max(flingWindow, pref))
    }

    static func gameModeFullscreen(window: CGRect, screen: CGRect, cover: CGFloat = 0.92) -> Bool {
        guard screen.width > 1, screen.height > 1 else { return false }
        let inter = window.intersection(screen)
        guard !inter.isNull, !inter.isInfinite else { return false }
        let area = inter.width * inter.height
        let screenArea = screen.width * screen.height
        return area / screenArea >= cover
    }

    /// Safari/Keynote/Finder sind kein Spiel. Steam und Unbekanntes Vollbild schon.
    static func gameModeExempt(bundle: String?) -> Bool {
        guard let b = bundle, !b.isEmpty else { return false }
        switch b {
        case "com.apple.Safari", "com.apple.SafariTechnologyPreview",
             "com.google.Chrome", "com.google.Chrome.canary",
             "org.mozilla.firefox", "company.thebrowser.Browser",
             "com.apple.finder", "com.apple.dt.Xcode", "com.microsoft.VSCode",
             "com.apple.Preview", "com.apple.TV", "com.apple.Music",
             "com.apple.Photos", "com.apple.iWork.Keynote", "com.apple.iWork.Pages",
             "com.apple.QuickTimePlayerX", "us.zoom.xos", "com.tinyspeck.slackmacgap",
             "com.microsoft.Word", "com.microsoft.Excel", "com.microsoft.Powerpoint",
             "com.apple.TextEdit", "com.apple.mail",
             "com.microsoft.edgemac", "com.brave.Browser",
             "com.hnc.Discord", "notion.id", "md.obsidian":
            return true
        default:
            let low = b.lowercased()
            return low.contains("chrome") || low.contains("firefox") || low.contains("safari")
                || low.contains("edge") || low.contains("brave")
        }
    }

    static func gameModePause(
        fullscreen: Bool,
        enabled: Bool = true,
        bundle: String? = nil,
        extraLock: Set<String> = []
    ) -> Bool {
        guard enabled, fullscreen else { return false }
        if let bundle, extraLock.contains(bundle) { return true }
        if gameModeExempt(bundle: bundle) { return false }
        return true
    }

    static func gameModeChip(_ paused: Bool) -> String? { paused ? "GAME" : nil }

    /// Erster Continuity-Frame nach Lock: letzte Palm halten, kein Cubic-Sprung.
    static func continuityReconnectHolds(firstAfterLock: Bool, hasHistory: Bool) -> Bool {
        firstAfterLock && hasHistory
    }

    static func continuityReconnectPalm(prev: CGPoint?, current: CGPoint, firstAfterLock: Bool) -> CGPoint {
        if continuityReconnectHolds(firstAfterLock: firstAfterLock, hasHistory: prev != nil), let prev {
            return prev
        }
        return current
    }

    /// Vision Revision 2: Tip-Z statt 2D-Ratio. Fallback bleibt PinchGate.
    static func pinchTipZClosed(tipZ: Float?, floor: Float = 0.035) -> Bool {
        guard let tipZ else { return false }
        return abs(tipZ) >= floor
    }

    static func pinchUsesTipZ(revision2: Bool, tipZ: Float?) -> Bool {
        revision2 && tipZ != nil
    }

    /// Wrist-Z minus Tip-Mittel. Vision-3D: +Z zur Kamera. Pinch bringt Spitzen nach vorn.
    static func pinchTipZ(thumbZ: Float?, indexZ: Float?, wristZ: Float?) -> Float? {
        guard let t = thumbZ, let i = indexZ, let w = wristZ else { return nil }
        return ((t + i) / 2) - w
    }

    /// Revision 2 + Tip-Z zu: Grab hält, auch wenn 2D-Ratio atmet.
    static func pinchKeepsGrabTipZ(
        held: Bool,
        closed: Bool,
        ratio: CGFloat,
        fisting: Bool,
        rebind: Bool,
        palmScale: CGFloat,
        tipZ: Float?,
        revision2: Bool
    ) -> Bool {
        if pinchUsesTipZ(revision2: revision2, tipZ: tipZ), pinchTipZClosed(tipZ: tipZ) {
            return true
        }
        return pinchKeepsGrab(
            held: held,
            closed: closed,
            ratio: ratio,
            fisting: fisting,
            rebind: rebind,
            palmScale: palmScale
        )
    }

    /// Continuity 8 fps: Display-Link füllt 60 Hz zwischen den Kamera-Ticks.
    /// 24 Hz war 3 Fills / Frame — Cursor hakte. 60 Hz × StepMul 0,4 hält das px-Budget.
    static let displayLinkPeriod: TimeInterval = 1.0 / 60.0

    /// Kamera-Tick: lastDisplayTick = 0, sonst erster Fill mit Rest-dt (oft 2×).
    static func displayLinkRebase() -> TimeInterval { 0 }

    /// Freeze/Occlusion: Fill tot. Sonst stale Vel kriecht.
    static func displayTickBlocksHold(freeze: Bool) -> Bool { freeze }

    /// Atem-Clutch: Kamera hält den Cursor. Fill mit Rest-Vel kriecht sonst weiter.
    static func displayTickBlocksStill(frozen: Bool) -> Bool { frozen }

    /// Velocity aus lastMapped (Kamera), nicht cursorSmooth (der Fill selbst).
    /// Fill als current: Distanz zu lastMapped2 wächst, Vel compoundet, Zeiger läuft weg.
    static func displayLinkVelCamera(from: CGPoint, camera: CGPoint?) -> CGPoint {
        camera ?? from
    }

    /// Timer driftet. Immer period = Burst 2× Speed. Echter dt, Cap 1,5×.
    static func displayLinkElapsed(
        now: TimeInterval,
        last: TimeInterval,
        period: TimeInterval = displayLinkPeriod
    ) -> TimeInterval {
        if last <= 0 { return period }
        return min(period * 1.5, max(period * 0.5, now - last))
    }

    /// 24 Hz-Caps (12/28 px) waren pro Tick. 60 Hz sonst 2,5× Overshoot.
    static func displayLinkStepMul(period: TimeInterval = displayLinkPeriod, ref: TimeInterval = 1.0 / 24.0) -> CGFloat {
        CGFloat(period / max(0.001, ref))
    }

    static func displayLinkFires(
        frameDt: TimeInterval,
        elapsed: TimeInterval,
        period: TimeInterval = displayLinkPeriod
    ) -> Bool {
        frameDt >= 0.08 && elapsed >= period * 0.80 && elapsed < frameDt * 0.92
    }

    /// Cubic-t nach dem Kamera-Tick (0,62) weiter Richtung 1,0.
    static func displayLinkCubicT(elapsed: TimeInterval, frameDt: TimeInterval) -> CGFloat {
        let u = CGFloat(min(1, max(0, elapsed / max(0.08, frameDt))))
        return 0.62 + 0.38 * u
    }

    static func displayLinkCursor(
        from: CGPoint,
        velocity: CGPoint,
        elapsed: TimeInterval,
        maxStep: CGFloat = 28
    ) -> CGPoint {
        displayLinkCursorOf(from: from, velocity: velocity, elapsed: elapsed, capX: maxStep, capY: maxStep)
    }

    /// Hypot-Scale dämpft Y mit, wenn X den Cap sprengt. destEdge Y entlang Bezel sonst tot im Fill.
    static func displayLinkCursorOf(
        from: CGPoint,
        velocity: CGPoint,
        elapsed: TimeInterval,
        capX: CGFloat,
        capY: CGFloat
    ) -> CGPoint {
        let dt = CGFloat(max(0, elapsed))
        var dx = velocity.x * dt
        var dy = velocity.y * dt
        if capX > 0, abs(dx) > capX { dx = capX * (dx >= 0 ? 1 : -1) }
        if capY > 0, abs(dy) > capY { dy = capY * (dy >= 0 ? 1 : -1) }
        return CGPoint(x: from.x + dx, y: from.y + dy)
    }

    static func displayLinkMappedScale(bounds: CGRect?, fallbackW: CGFloat = 1440, fallbackH: CGFloat = 900) -> (x: CGFloat, y: CGFloat) {
        guard let b = bounds, b.width > 1, b.height > 1 else {
            return (fallbackW, fallbackH)
        }
        return (b.width, b.height)
    }

    static func displayLinkVelocity(
        prev: CGPoint,
        current: CGPoint,
        frameDt: TimeInterval,
        palmVel: CGPoint = .zero,
        mappedScale: CGFloat = 0,
        mappedScaleY: CGFloat = 0,
        palmVelScreen: CGPoint = .zero,
        still: Bool = false,
        mad: CGFloat = 0,
        fresh: Bool = true
    ) -> CGPoint {
        if still { return .zero }
        let dt = CGFloat(max(0.08, frameDt))
        let fromMap = CGPoint(x: (current.x - prev.x) / dt, y: (current.y - prev.y) / dt)
        if hypot(fromMap.x, fromMap.y) < 8 {
            if !fresh { return .zero }
            if palmVelScreenStale(moved: false, mad: mad) { return .zero }
            if hypot(palmVelScreen.x, palmVelScreen.y) > 1 {
                return palmVelScreen
            }
            let sx = mappedScale
            let sy = mappedScaleY > 1 ? mappedScaleY : mappedScale
            if sx > 1, hypot(palmVel.x, palmVel.y) > 0.002 {
                return CGPoint(x: palmVel.x * sx, y: palmVel.y * sy)
            }
        }
        return fromMap
    }

    /// Nach Flick: MAD Rest + tot = leftover Screen-Vel. Fill schießt sonst 125 ms weiter.
    static func palmVelScreenStale(moved: Bool, mad: CGFloat) -> Bool {
        !moved && mad > 0 && mad <= palmDeadRest * 1.15
    }

    static func palmVelScreenKeep(moved: Bool, mad: CGFloat, vel: CGPoint, hold: Bool = false, fresh: Bool = true) -> CGPoint {
        if hold || !fresh { return .zero }
        if palmVelScreenStale(moved: moved, mad: mad) { return .zero }
        return vel
    }

    /// Fill-Vel ohne Reibung: 8 Ticks × Cap nach Stopp = Overshoot. τ 55 ms.
    static func displayLinkCoast(_ vel: CGPoint, elapsed: TimeInterval, tau: TimeInterval = 0.055) -> CGPoint {
        displayLinkCoast(vel, elapsed: elapsed, tauX: tau, tauY: tau)
    }

    /// Bezel: X-τ kürzer, Y frei. destEdgeFillAxis analog für Coast — sonst X kriecht auf den Nachbarschirm.
    static func displayLinkCoast(_ vel: CGPoint, elapsed: TimeInterval, tauX: TimeInterval, tauY: TimeInterval) -> CGPoint {
        let ax = CGFloat(exp(-elapsed / max(0.008, tauX)))
        let ay = CGFloat(exp(-elapsed / max(0.008, tauY)))
        return CGPoint(x: vel.x * ax, y: vel.y * ay)
    }

    /// destEdgeMul × Coast-τ. Floor destEdgeFloor, sonst τ 0 am Pad.
    static func displayLinkCoastTauAxis(base: TimeInterval, mul: CGFloat) -> TimeInterval {
        max(0.012, base * TimeInterval(min(1, max(destEdgeFloor, mul))))
    }

    /// 13″ 40 ms, 5K 70 ms. Fest 55 klebt auf Laptop und schießt auf 5K.
    static func displayLinkCoastTau(screen: CGRect?, small: TimeInterval = 0.040, large: TimeInterval = 0.070) -> TimeInterval {
        guard let s = screen, s.width > 1, s.height > 1 else { return 0.055 }
        let diag = hypot(s.width, s.height)
        let u = min(1, max(0, (Double(diag) - 1680) / 4200))
        return small + (large - small) * u
    }

    static func displayLinkPeriodAdaptive(frameDt: TimeInterval) -> TimeInterval {
        frameDt >= 0.08 ? 1.0 / 90.0 : 1.0 / 30.0
    }

    /// Timer 90 Hz, damit 8 fps Fill nicht auf 60 coalesced. displayLinkPeriod bleibt 1/60 für StepMul-Tests.
    static func displayLinkTimerPeriod(frameDt: TimeInterval = 0.125) -> TimeInterval {
        min(displayLinkPeriod, displayLinkPeriodAdaptive(frameDt: frameDt))
    }

    /// .common feuert während Tracking/AX. scheduledTimer nur .default = Coalesce-Loch.
    static func displayLinkTimerCommonMode() -> Bool { true }

    /// Timer neu wenn medianFps 8↔24 kreuzt. displayLinkTimerPeriod ist Capture-Start, nicht live.
    static func displayLinkTimerRetarget(current: TimeInterval, frameDt: TimeInterval) -> TimeInterval? {
        let want = displayLinkTimerPeriod(frameDt: frameDt)
        if abs(want - current) < 0.002 { return nil }
        return want
    }

    /// Continuity thermal: 2 s unter 12 fps → Format halten, nicht Watchdog-Hopping.
    static func thermalHoldsFormat(medianFps: Double, slowFor: TimeInterval, need: TimeInterval = 2.0) -> Bool {
        medianFps > 0 && medianFps < 12 && slowFor >= need
    }

    /// Preset hd1280x720 clampte Continuity auf 8. Built-in darf 720p.
    static func sessionPresetClampsContinuity(_ continuity: Bool) -> Bool { continuity }

    /// Kamera hat AX gerade gesetzt: Fill im selben vsync compoundet. slop 8 ms.
    static func displayTickCoalesced(
        now: TimeInterval,
        lastMove: TimeInterval,
        slop: TimeInterval = 0.008
    ) -> Bool {
        lastMove > 0 && now - lastMove < slop
    }

    /// Fill-Ticks teilen den Kamera-Warp-Floor. 7×11 px sonst 77 trotz Floor.
    static func displayTickWarpShare(floor: CGFloat, frameDt: TimeInterval, period: TimeInterval) -> CGFloat {
        let n = CGFloat(frameDt / max(0.008, period))
        return max(2, floor / max(1, n))
    }

    /// Dieser Screen hat keine eigene Homographie — Laptop-Map nicht schleppen.
    /// Legacy ohne Screen-ID ist kein Miss: Load hat destBounds schon geprüft.
    static func mapMissingOnScreen(loadedScreenID: String?, currentScreenID: String?) -> Bool {
        guard let current = currentScreenID, !current.isEmpty else { return false }
        guard let loaded = loadedScreenID, !loaded.isEmpty else { return false }
        return loaded != current
    }

    static func mapMissingChip(_ missing: Bool) -> String? { missing ? "KALIB HIER" : nil }

    /// Relativ-Warp nur mit Map auf dem neuen Screen. Sonst Snap — Laptop-Homographie nicht schleppen.
    static func mapWarmupUsesRelative(hasMap: Bool, screenChanged: Bool) -> Bool {
        hasMap && screenChanged
    }

    /// Farbenblind: MAGNET/BUTTON/WEG nicht nur Farbe.
    static func overlayDash(kind: HoverRingKind) -> [NSNumber]? {
        switch kind {
        case .magnet: return [2, 2]
        case .button: return [10, 3]
        case .travel: return [1.5, 5]
        case .hover: return [6, 4]
        case .none: return nil
        }
    }

    static func overlayDashAlways(kind: HoverRingKind, ghost: Bool, hovering: Bool, flinging: Bool) -> [NSNumber]? {
        if let dash = overlayDash(kind: kind) { return dash }
        if ghost || hovering || flinging { return [6, 4] }
        return nil
    }

    /// Per-App Gain. Safari-Tabs enger, Spiele langsamer, Finder weicher.
    static func appGain(bundle: String?) -> CGFloat {
        guard let b = bundle, !b.isEmpty else { return 1 }
        switch b {
        case "com.apple.Safari", "com.google.Chrome", "org.mozilla.firefox",
             "com.apple.SafariTechnologyPreview":
            return 0.82
        case "com.apple.finder":
            return 0.90
        case "com.apple.dt.Xcode":
            return 0.88
        case "com.apple.TextEdit", "com.microsoft.Word", "com.microsoft.Excel":
            return 0.92
        default:
            let low = b.lowercased()
            if low.contains("game") || low.contains("steam") { return 0.55 }
            return 1
        }
    }

    /// Dock / Mitteilungszentrale immer Click-Lock — kein Fenster-Drag.
    static func clickLockAlways(bundle: String?, extra: Set<String> = []) -> Bool {
        guard let bundle, !bundle.isEmpty else { return false }
        if extra.contains(bundle) { return true }
        switch bundle {
        case "com.apple.dock", "com.apple.notificationcenterui", "com.apple.controlcenter":
            return true
        default:
            return false
        }
    }

    /// click-lock.txt / game-lock.txt: eine Bundle-ID je Zeile, # Kommentar.
    static func prefsBundleList(_ text: String) -> Set<String> {
        Set(
            text.split(whereSeparator: { $0.isNewline || $0 == "," }).map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }.filter { !$0.isEmpty && !$0.hasPrefix("#") }
        )
    }

    /// Klappe + Built-in: tot. Clamshell (Continuity/USB + extra Display): Arbeitsplatz.
    static func lidBlocksArm(
        lidClosed: Bool,
        cameraFallback: Bool = false,
        extraScreens: Bool = false
    ) -> Bool {
        guard lidClosed else { return false }
        if extraScreens && cameraFallback { return false }
        return true
    }

    /// Klappe oder Game: kein Faust-Scharf im selben Tick. Phase blockte nur Klicks.
    static func phaseBlocksArm(
        lidClosed: Bool,
        gamePaused: Bool,
        cameraFallback: Bool = false,
        extraScreens: Bool = false
    ) -> Bool {
        lidBlocksArm(lidClosed: lidClosed, cameraFallback: cameraFallback, extraScreens: extraScreens) || gamePaused
    }

    /// Laptop-Map nicht auf den Externen. Legacy ohne screenID nur bei dest-Overlap.
    static func mapFitsScreen(
        mapScreenID: String?,
        screenID: String?,
        dest: CGRect? = nil,
        screen: CGRect? = nil
    ) -> Bool {
        guard let want = screenID, !want.isEmpty else { return true }
        if let have = mapScreenID, !have.isEmpty {
            return have == want
        }
        guard let dest, let screen, screen.width > 1, screen.height > 1, dest.width > 1, dest.height > 1 else {
            return false
        }
        let inter = dest.intersection(screen)
        guard !inter.isNull, !inter.isInfinite else { return false }
        let area = dest.width * dest.height
        return area > 1 && (inter.width * inter.height) / area >= 0.80
    }

    /// Homographie bleibt auf dem kalibrierten Screen. clampQuartz-Union war der Sprung.
    static func destClamp(_ p: CGPoint, bounds: CGRect?) -> CGPoint {
        guard let b = bounds, b.width > 1, b.height > 1 else { return p }
        return CGPoint(
            x: min(max(p.x, b.minX + 1), b.maxX - 1),
            y: min(max(p.y, b.minY + 1), b.maxY - 1)
        )
    }

    /// Relativ ohne destBounds: Screen unter dem Cursor, nicht die Union.
    /// Lücke/Bezel: nächster Screen, nie nil — sonst clampQuartz = Union = Sprung.
    /// Freeze: letzten Screen merken, nicht mid-Steal nearest auf den Externen.
    /// Naht: 24 px Hysterese, sonst Fill wechselt Screen am Pixel.
    static let screenSeamPad: CGFloat = 24

    static func screenSeamHolds(point: CGPoint, last: CGRect?, pad: CGFloat = screenSeamPad, screens: [CGRect] = []) -> Bool {
        guard let last, last.width > 1, last.height > 1 else { return false }
        if !last.insetBy(dx: -pad, dy: -pad).contains(point) { return false }
        if screens.count >= 2, let hit = destEdgeNearest(point, screens: screens)?.screen {
            if abs(hit.minX - last.minX) > 1
                || abs(hit.minY - last.minY) > 1
                || abs(hit.width - last.width) > 1
                || abs(hit.height - last.height) > 1 {
                return false
            }
        }
        return true
    }

    static func destClampSameScreen(_ a: CGRect, _ b: CGRect) -> Bool {
        abs(a.minX - b.minX) < 1
            && abs(a.minY - b.minY) < 1
            && abs(a.width - b.width) < 1
            && abs(a.height - b.height) < 1
    }

    static func destClampScreen(
        point: CGPoint,
        mapBounds: CGRect?,
        screens: [CGRect],
        freeze: Bool = false,
        lastScreen: CGRect? = nil,
        mapScreenID: String? = nil,
        currentScreenID: String? = nil
    ) -> CGRect? {
        if freeze, let last = lastScreen, last.width > 1, last.height > 1 { return last }
        if destClampMapHolds(
            mapScreenID: mapScreenID,
            currentScreenID: currentScreenID,
            dest: mapBounds,
            screenCount: screens.count
        ), let mapBounds {
            if let hit = destEdgeNearest(point, screens: screens),
               !destClampSameScreen(hit.screen, mapBounds) {
                // Punkt schon auf dem Nachbarschirm: Map nicht als Mauer.
            } else {
                return mapBounds
            }
        }
        if screenSeamHolds(point: point, last: lastScreen, screens: screens) { return lastScreen }
        if let hit = destEdgeNearest(point, screens: screens) {
            return hit.screen
        }
        return screens.min { a, b in
            hypot(a.midX - point.x, a.midY - point.y) < hypot(b.midX - point.x, b.midY - point.y)
        }
    }

    /// destBounds ohne screenID nach Monitor-Wake: Laptop-Map auf den Externen. Latch: ohne ID nur 1 Screen.
    static func destClampMapHolds(
        mapScreenID: String?,
        currentScreenID: String?,
        dest: CGRect?,
        screenCount: Int = 1
    ) -> Bool {
        guard let dest, dest.width > 1, dest.height > 1 else { return false }
        if let have = mapScreenID, !have.isEmpty {
            if let current = currentScreenID, !current.isEmpty { return have == current }
            return screenCount <= 1
        }
        return screenCount <= 1
    }

    /// 40 px vor dem Rand Gain 0,35 — Fill schießt sonst auf den Nachbarschirm.
    static let destEdgePad: CGFloat = 40
    static let destEdgeFloor: CGFloat = 0.35

    /// 5K 2560 pt × 0,025 = 64. 13″ 1440 bleibt Floor 40. Hart 40 fliegt auf den Nachbarschirm.
    static func destEdgePadOf(width: CGFloat, floor: CGFloat = destEdgePad, ratio: CGFloat = 0.025) -> CGFloat {
        guard width > 1 else { return floor }
        return max(floor, width * ratio)
    }

    /// Fill nach Kamera-Tick. Continuity ≥ 8 fps: destEdgeVel schon auf palmVelScreen.
    /// Tot nach destEdgeFill Passthrough (1.5.89) — Konstante bleibt für Tests/Doku.
    static let destEdgeFillSkip: TimeInterval = 0.08

    static func destEdgeMulOf(dist: CGFloat, pad: CGFloat = destEdgePad, dt: TimeInterval = 0.016) -> CGFloat {
        // Spatial. dt-Scale × dt/0,016 machte 8 fps Gain 1 — destEdge tot, Nachbarschirm.
        _ = dt
        if dist >= pad { return 1 }
        if dist <= 0 { return destEdgeFloor }
        return destEdgeFloor + (1 - destEdgeFloor) * (dist / pad)
    }

    static func destEdgeMul(point: CGPoint, screen: CGRect?, pad: CGFloat = destEdgePad, dt: TimeInterval = 0.016) -> CGFloat {
        let used: CGFloat
        if let s = screen, s.width > 1 {
            used = destEdgePadOf(width: s.width, floor: pad)
        } else {
            used = pad
        }
        guard let d = destEdgeDist(point: point, screen: screen, pad: used) else { return 1 }
        return destEdgeMulOf(dist: d, pad: used, dt: dt)
    }

    /// Entlang der Bezel: nur die Rand-Achse, sonst Y tot beim X-Rand.
    /// toward: Kante in Bewegungsrichtung. min(left,right) dämpfte Inbound — 5K-Landung kroch.
    static func destEdgeMulX(point: CGPoint, screen: CGRect?, pad: CGFloat = destEdgePad, dt: TimeInterval = 0.016, toward: CGFloat = 0) -> CGFloat {
        guard let s = screen, s.width > 8, s.height > 8 else { return 1 }
        let used = destEdgePadOf(width: s.width, floor: pad)
        let dir = destEdgeTowardOf(toward)
        let dist: CGFloat
        if dir > 1e-9 {
            dist = s.maxX - point.x
        } else if dir < -1e-9 {
            dist = point.x - s.minX
        } else {
            dist = min(point.x - s.minX, s.maxX - point.x)
        }
        return destEdgeMulOf(dist: dist, pad: used, dt: dt)
    }

    static func destEdgeMulY(point: CGPoint, screen: CGRect?, pad: CGFloat = destEdgePad, dt: TimeInterval = 0.016, toward: CGFloat = 0) -> CGFloat {
        guard let s = screen, s.width > 8, s.height > 8 else { return 1 }
        let used = destEdgePadOf(width: s.height, floor: pad)
        let dir = destEdgeTowardOf(toward)
        let dist: CGFloat
        if dir > 1e-9 {
            dist = s.maxY - point.y
        } else if dir < -1e-9 {
            dist = point.y - s.minY
        } else {
            dist = min(point.y - s.minY, s.maxY - point.y)
        }
        return destEdgeMulOf(dist: dist, pad: used, dt: dt)
    }

    /// toward-Noise 1–3 px wählt die falsche Kante (gestapelte Monitore, 8 fps Jitter).
    static let destEdgeTowardDead: CGFloat = 4

    static func destEdgeTowardOf(_ toward: CGFloat, dead: CGFloat = destEdgeTowardDead) -> CGFloat {
        abs(toward) <= dead ? 0 : toward
    }

    /// Pinch/Drag/Click-Lock: Fenster und AXButton müssen den Rand erreichen.
    static func destEdgeApplies(dragging: Bool, pinchHeld: Bool, clickLocked: Bool = false) -> Bool {
        !dragging && !pinchHeld && !clickLocked
    }

    /// Ecke: hypot(dx,dy), nicht min — sonst doppelt tot.
    static func destEdgeDist(point: CGPoint, screen: CGRect?, pad: CGFloat = destEdgePad) -> CGFloat? {
        guard let s = screen, s.width > 8, s.height > 8 else { return nil }
        let used = destEdgePadOf(width: s.width, floor: pad)
        let dx = min(point.x - s.minX, s.maxX - point.x)
        let dy = min(point.y - s.minY, s.maxY - point.y)
        if dx < used && dy < used {
            return hypot(max(0, dx), max(0, dy))
        }
        return min(dx, dy)
    }

    static func destEdgeVel(_ vel: CGPoint, point: CGPoint, screen: CGRect?, pad: CGFloat = destEdgePad, screens: [CGRect] = []) -> CGPoint {
        let mx = destEdgeNeighborMul(
            destEdgeMulX(point: point, screen: screen, pad: pad, toward: vel.x),
            destEdgeHasNeighbor(point: point, toward: vel.x, screens: screens, axisX: true)
        )
        let my = destEdgeNeighborMul(
            destEdgeMulY(point: point, screen: screen, pad: pad, toward: vel.y),
            destEdgeHasNeighbor(point: point, toward: vel.y, screens: screens, axisX: false)
        )
        return CGPoint(x: vel.x * mx, y: vel.y * my)
    }

    /// Kamera-Tick. Fill allein dämpft zu spät — 8 fps hat den Nachbarschirm schon.
    /// 8 fps: Gain × dt/0,016, sonst ein Tick 35 % von 125 ms = tot.
    /// pad = destEdgePadNow, sonst Slider tot und 5K Floor 40.
    /// screens: Seam-Outbound Gain 1 — Lead und Pad entkoppelt.
    static func destEdgeStep(from: CGPoint, to: CGPoint, screen: CGRect?, dt: TimeInterval = 0.016, pad: CGFloat = destEdgePad, screens: [CGRect] = []) -> CGPoint {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let mx = destEdgeNeighborMul(
            destEdgeMulX(point: from, screen: screen, pad: pad, dt: dt, toward: dx),
            destEdgeHasNeighbor(point: from, toward: dx, screens: screens, axisX: true)
        )
        let my = destEdgeNeighborMul(
            destEdgeMulY(point: from, screen: screen, pad: pad, dt: dt, toward: dy),
            destEdgeHasNeighbor(point: from, toward: dy, screens: screens, axisX: false)
        )
        return CGPoint(x: from.x + dx * mx, y: from.y + dy * my)
    }

    /// Fill am aktuellen Cursor, nicht am Kamera-Tick. Passthrough schoss X auf den Nachbarschirm.
    /// Y entlang der Bezel bleibt frei (destEdgeMulY). palmVelScreen roh — Fill nicht 0,35².
    static func destEdgeFill(_ vel: CGPoint, point: CGPoint, screen: CGRect?, frameDt: TimeInterval, pad: CGFloat = destEdgePad, screens: [CGRect] = []) -> CGPoint {
        _ = frameDt
        return destEdgeVel(vel, point: point, screen: screen, pad: pad, screens: screens)
    }

    /// Fill-Passthrough ließ X am Bezel auf den Nachbarschirm. Nur X dämpfen, Y entlang der Kante frei.
    /// toward + screens: Inbound frei, Seam Gain 1, Void dämpft. Ohne toward min(left,right) am x=8.
    /// pad = destEdgePadNow — hart 40 ignoriert den 5K-Slider.
    static func destEdgeFillAxis(
        _ vel: CGPoint,
        point: CGPoint,
        screen: CGRect?,
        frameDt: TimeInterval,
        pad: CGFloat = destEdgePad,
        screens: [CGRect] = []
    ) -> CGPoint {
        _ = frameDt
        let mx = destEdgeNeighborMul(
            destEdgeMulX(point: point, screen: screen, pad: pad, toward: vel.x),
            destEdgeHasNeighbor(point: point, toward: vel.x, screens: screens, axisX: true)
        )
        return CGPoint(x: vel.x * mx, y: vel.y)
    }

    /// Fill-Dest: stealScreen, nicht destBounds/Main. Sonst Rand-Gain auf dem falschen Schirm.
    static func destEdgeScreen(steal: CGRect?, map: CGRect?, main: CGRect?) -> CGRect? {
        if let steal, steal.width > 1, steal.height > 1 { return steal }
        if let map, map.width > 1, map.height > 1 { return map }
        if let main, main.width > 1, main.height > 1 { return main }
        return nil
    }

    static func destEdgeChip(mul: CGFloat, dist: CGFloat? = nil) -> String? {
        guard mul < 0.6 else { return nil }
        if let dist {
            return "EDGE \(Int(max(0, dist).rounded()))"
        }
        return "EDGE"
    }

    /// HUD je Achse. destEdgeMul hypot zeigte EDGE obwohl Y frei war.
    /// Seam-Nachbar nur an der näheren Kante: OR beider Richtungen blendete Void-EDGE
    /// (Laptop-Links trotz 5K rechts). Gain 1 am Seam, Chip sonst Mauer.
    static func destEdgeChipOf(point: CGPoint, screen: CGRect?, pad: CGFloat = destEdgePad, screens: [CGRect] = []) -> String? {
        guard let s = screen, s.width > 8, s.height > 8 else { return nil }
        let dx = min(point.x - s.minX, s.maxX - point.x)
        let dy = min(point.y - s.minY, s.maxY - point.y)
        let towardX: CGFloat = (s.maxX - point.x) <= (point.x - s.minX) ? 1 : -1
        let towardY: CGFloat = (s.maxY - point.y) <= (point.y - s.minY) ? 1 : -1
        let mx = destEdgeNeighborMul(
            destEdgeMulX(point: point, screen: screen, pad: pad, toward: towardX),
            destEdgeHasNeighbor(point: point, toward: towardX, screens: screens, axisX: true)
        )
        let my = destEdgeNeighborMul(
            destEdgeMulY(point: point, screen: screen, pad: pad, toward: towardY),
            destEdgeHasNeighbor(point: point, toward: towardY, screens: screens, axisX: false)
        )
        var parts: [String] = []
        if mx < 0.6 { parts.append("X \(Int(max(0, dx).rounded()))") }
        if my < 0.6 { parts.append("Y \(Int(max(0, dy).rounded()))") }
        guard !parts.isEmpty else { return nil }
        return "EDGE " + parts.joined(separator: " · ")
    }

    /// Relock auf anderem Schirm. destEdgeChipOf sieht nur steal ?? map — MAP≠STEAL unsichtbar.
    static func destMapStealChip(steal: CGRect?, map: CGRect?) -> String? {
        guard let steal, let map, steal.width > 1, map.width > 1 else { return nil }
        if abs(steal.minX - map.minX) > 8
            || abs(steal.minY - map.minY) > 8
            || abs(steal.width - map.width) > 8
            || abs(steal.height - map.height) > 8
        {
            return "MAP≠STEAL"
        }
        return nil
    }

    /// Relock vor Warp vor Bezel. destEdgeChipOf allein lässt WARP unsichtbar.
    static func destHudChip(steal: String?, warp: String?, edge: String?) -> String? {
        steal ?? warp ?? edge
    }

    /// Display-Link: Zielen 12 px, Flick 28 px. Fester Deckel 28 lässt beide haken.
    static func displayLinkCap(speed: CGFloat, rest: CGFloat = 12, flick: CGFloat = 28) -> CGFloat {
        let u = min(1, max(0, (speed - 80) / 400))
        return rest + (flick - rest) * u
    }

    /// Continuity: iPhone-Stabilizer warpt Joints, Pinch tanzt. macOS hat kein preferredVideoStabilizationMode.
    static func videoStabilizationOff(_ continuity: Bool) -> Bool { continuity }

    /// Inverse — Built-in darf, Continuity nicht.
    static func videoStabilizationApplies(continuity: Bool) -> Bool { !videoStabilizationOff(continuity) }

    /// Lid-Open: Format oft bei 8. reselectFormat, Center Stage nochmal aus.
    static func clamshellWakeReselects(wasClosed: Bool, nowClosed: Bool) -> Bool {
        wasClosed && !nowClosed
    }

    /// USB/Wi-Fi Continuity: erste 400 ms bei 8 fps nicht Format-hoppen.
    static func continuityUsbHold(dt: TimeInterval, hold: TimeInterval, need: TimeInterval = 0.40) -> Bool {
        dt >= 0.08 && hold < need
    }

    static func formatHopHold(last: TimeInterval, now: TimeInterval, need: TimeInterval = 0.40) -> Bool {
        last > 0 && now - last < need
    }

    /// Pinch-Klick 180 ms nach Zwei-Finger-Rad / Scale. cooldown 0,45 s Wischen reicht nicht für Scale 0,50.
    static let pinchAfterScrollLock: TimeInterval = 0.18

    static func pinchClickBlocksAfterScroll(lastScroll: TimeInterval, now: TimeInterval) -> Bool {
        lastScroll > 0 && now - lastScroll < pinchAfterScrollLock
    }

    /// Coast-Return 180 ms: Dropout-Klick sonst. 80 ms tot bei Continuity 8 fps (nächster Tick 125 ms).
    static let pinchAfterCoastLock: TimeInterval = 0.18

    static func pinchClickBlocksAfterCoast(lastCoastEnd: TimeInterval, now: TimeInterval) -> Bool {
        lastCoastEnd > 0 && now - lastCoastEnd < pinchAfterCoastLock
    }

    /// Reduce Motion: Predict aus, Overlay nicht vor der Hand.
    static func pointerPredictApplies(reduceMotion: Bool) -> Bool { !reduceMotion }

    /// Continuity-Reconnect schaltet Center Stage wieder an. Lid-Open analog.
    static func reconnectCenterStageOff(continuity: Bool, enabled: Bool) -> Bool {
        continuity && centerStageNeedsReassert(enabled: enabled)
    }

    /// GPUFrameRing Slot −1 reicht den Kamera-Buffer. Vision liest, AVFoundation überschreibt.
    static func ringSlotStealDrops(_ slot: Int) -> Bool { slot < 0 }

    /// Enhance darf 420f/420v halten. BGRA-Pingpong tötet den nativen Ring indoor.
    static func enhanceDestFormat(osType: UInt32) -> UInt32 {
        visionTakesNative(osType: osType) ? osType : formatFourCCBGRA
    }

    /// 8 fps Overlay Ghost-Knochen ein Frame. Zwei Frames peak-hold analog WARP.
    static func overlayGhostPeakHold(current: Bool, remaining: Int, need: Int = 2) -> (ghost: Bool, remaining: Int) {
        if current { return (true, need) }
        if remaining > 0 { return (true, remaining - 1) }
        return (false, 0)
    }

    /// Lid-Open: AX-Cache nach Sleep tot. TypeID-Check reicht nicht, Probe neu.
    static func axProbeWakeInvalidates(wasClosed: Bool, nowClosed: Bool) -> Bool {
        clamshellWakeReselects(wasClosed: wasClosed, nowClosed: nowClosed)
    }

    /// GPUFrameRing Slot −1: HUD `STEAL n`. Decay sonst Blindflug Indoor.
    static func ringSlotStealCount(prev: Int, dropped: Bool, cap: Int = 24) -> Int {
        if dropped { return min(cap, prev + 1) }
        return max(0, prev - 1)
    }

    static func ringSlotStealChip(_ drops: Int) -> String? {
        drops > 0 ? "STEAL \(drops)" : nil
    }

    /// Format-Chip plus Steal. `420f 15–24 · STEAL 3`.
    static func formatStealChip(band: String, drops: Int) -> String {
        guard let steal = ringSlotStealChip(drops) else { return band }
        if band.isEmpty { return steal }
        return "\(band) · \(steal)"
    }

    /// 8 fps zwei Hände halten S1-ROI. HUD sonst tot warum Kill-Hand fehlt.
    static func palmROILatchChip(secondHand: Bool, dt: TimeInterval) -> String? {
        secondHand && !palmROISecondNils(dt: dt) ? "ROI S1" : nil
    }

    /// Actor-Wechsel: Slow-State der anderen Hand würde den Cursor reißen.
    /// Ghost (actor nil) hält S1-Slow — sonst Continuity-Dropout = Sprung.
    static func palmHighpassResets(actor: String?, prev: String?) -> Bool {
        guard let actor else { return false }
        return actor != prev
    }

    /// Neue Hand: Slow = dx, erster fast 0. Gespeicherte Slow der Slot-Hand bleibt.
    /// stale (fresh=false): Dropout > TTL, alter Atem wäre Bias.
    static func palmHighpassLoad(savedX: CGFloat?, savedY: CGFloat?, dx: CGFloat, dy: CGFloat, fresh: Bool = true) -> (x: CGFloat, y: CGFloat) {
        if fresh, let x = savedX, let y = savedY { return (x, y) }
        return (dx, dy)
    }

    /// Gespeicherte Slow nach 2 s Dropout ist tot. Restore würde S1-Atem von vor 10 s als S2-Bias.
    static func palmHighpassFresh(savedAt: TimeInterval?, now: TimeInterval, ttl: TimeInterval = 2) -> Bool {
        guard let savedAt else { return false }
        return now - savedAt <= ttl
    }

    /// HUD `α 0,15 S1`. Slider ohne Chip = Blindflug.
    static func palmHighpassChip(actor: String?, alpha: CGFloat) -> String? {
        guard let actor, !actor.isEmpty else { return nil }
        return String(format: "α %.2f %@", Double(alpha), actor)
    }

    /// Predict > 8 px: HUD `PREDICT 12`. Sonst Overlay vor der Hand ohne Grund.
    static func pointerPredictChip(dx: CGFloat, dy: CGFloat, floor: CGFloat = 8) -> String? {
        let d = hypot(dx, dy)
        return d >= floor ? String(format: "PREDICT %.0f", Double(d)) : nil
    }

    /// Actor-Switch: Screen-Vel der anderen Hand. Fill coaster sonst S1 auf S2.
    static func palmVelScreenResets(actor: String?, prev: String?) -> Bool {
        palmHighpassResets(actor: actor, prev: prev)
    }

    /// Nach Reset: Vel 0, nicht Keep. mad 0 hält sonst S1-Vel.
    static func palmVelScreenAfterActor(resets: Bool, vel: CGPoint) -> CGPoint {
        resets ? .zero : vel
    }

    /// lastMapped der anderen Hand = Teleport-Vel (S2−S1)/dt.
    static func palmMappedClears(resets: Bool) -> Bool { resets }

    /// HUD `VEL 0` ein Frame nach Switch. `JUMP` nach Dropout-Teleport. `MUTE` Fill tot.
    static func palmVelChip(zeroed: Bool, teleport: Bool = false, muted: Bool = false) -> String? {
        if teleport && muted { return "JUMP · MUTE" }
        if muted { return "MUTE" }
        if teleport { return "JUMP" }
        return zeroed ? "VEL 0" : nil
    }

    /// Fill-Vel nach Dropout. Ghost hält Vel (1.5.98) — 8 s Coast ohne TTL.
    static let palmVelScreenTTL: TimeInterval = 0.40

    static func palmVelScreenFresh(savedAt: TimeInterval?, now: TimeInterval, ttl: TimeInterval = palmVelScreenTTL) -> Bool {
        guard let savedAt, savedAt > 0 else { return false }
        return now - savedAt <= ttl
    }

    /// lastMapped nach Ghost-Restore. 4× Pad: Flick 72 px bleibt, 400 px tot.
    static func palmVelScreenTeleport(from: CGPoint, to: CGPoint, cap: CGFloat = destEdgePad, mul: CGFloat = 4) -> Bool {
        cursorWarpIsTeleport(from: from, to: to, cap: cap, mul: mul)
    }

    /// X-Teleport allein. Hypot 400 px setzte Y-Coast 0 — Fill tot auf der freien Achse.
    static func palmVelScreenTeleportX(from: CGPoint, to: CGPoint, cap: CGFloat = destEdgePad, mul: CGFloat = 4) -> Bool {
        abs(to.x - from.x) > cap * mul
    }

    static func palmVelScreenTeleportY(from: CGPoint, to: CGPoint, cap: CGFloat = destEdgePad, mul: CGFloat = 4) -> Bool {
        abs(to.y - from.y) > cap * mul
    }

    static func palmVelScreenOf(raw: CGPoint, teleport: Bool) -> CGPoint {
        teleport ? .zero : raw
    }

    static func palmVelScreenOf(raw: CGPoint, teleportX: Bool, teleportY: Bool) -> CGPoint {
        CGPoint(x: teleportX ? 0 : raw.x, y: teleportY ? 0 : raw.y)
    }

    /// 8 fps Palm-Vel ist ein 125-ms-Sprung. EMA vor destEdgeStep, nicht nach JUMP.
    static func palmVelScreenEMA(
        prev: CGPoint,
        raw: CGPoint,
        dt: TimeInterval,
        alphaFast: CGFloat = 0.55
    ) -> CGPoint {
        let a: CGFloat = dt >= 0.08 ? 0.45 : alphaFast
        let u = min(max(a, 0.12), 0.90)
        return CGPoint(x: prev.x * (1 - u) + raw.x * u, y: prev.y * (1 - u) + raw.y * u)
    }

    /// JUMP: lastMapped2 = current, sonst Fill (c−prev)/dt.
    static func palmMappedPair(current: CGPoint, prev: CGPoint?, teleport: Bool) -> (mapped: CGPoint, mapped2: CGPoint) {
        if teleport { return (current, current) }
        return (current, prev ?? current)
    }

    /// Zwei-Hand-Scale endet: eine Pinzette bleibt → sonst Klick/Drag.
    static func scaleAbortClick(hadSpan: Bool, closedCount: Int) -> Bool {
        hadSpan && closedCount < 2
    }

    /// Pref 24–160. 5K Default destEdgePadOf, nicht hart 40.
    static func destEdgePadPref(_ pref: CGFloat) -> CGFloat {
        min(160, max(24, pref))
    }

    /// Slider-Floor vs live Pad. 5K Pref 24 bleibt 64.
    static func destEdgePadLive(width: CGFloat, pref: CGFloat) -> CGFloat {
        destEdgePadOf(width: width, floor: destEdgePadPref(pref))
    }

    static func destEdgePadLiveChip(width: CGFloat, pref: CGFloat) -> String {
        String(format: "PAD %.0f", Double(destEdgePadLive(width: width, pref: pref)))
    }

    /// NSScreen.main neben 5K: Laptop-Pad. Max-Breite = härtester Floor.
    /// Leer: 5K 2560, nicht 13″ — Clamshell + Studio sonst Pad 36.
    static func destEdgePadWidthOf(_ widths: [CGFloat]) -> CGFloat {
        widths.filter { $0 > 1 }.max() ?? 2560
    }

    static func destEdgePadNow(screen: CGRect?, pref: CGFloat, fallback: CGFloat = 2560) -> CGFloat {
        destEdgePadLive(width: screen?.width ?? fallback, pref: pref)
    }

    /// Fill nach JUMP unabhängig von lastMapped2. Timer .common während pair-Write.
    /// Warp-Hold: mute bleibt bis Release — 90 Hz unmutet sonst nach 11 ms.
    static func displayTickMutesJump(_ jumped: Bool, held: Bool = false) -> Bool { jumped || held }

    /// Hold: MUTE-Flag nicht wischen. Ohne Hold 1 Fill-Tick.
    static func displayTickClearsJumpMute(held: Bool) -> Bool { !held }

    /// Sentinel 0 war tot. nil = keine Vel.
    static func palmVelAtOf(now: TimeInterval, teleport: Bool, reset: Bool = false) -> TimeInterval? {
        if teleport || reset { return nil }
        return now
    }

    /// Restore-Teleport auf der Homographie: Snap auf q. Hold friert from (1.5.101 MUTE ewig).
    /// Relativ: Snap nur nach Dropout > 0,80 s — sonst Hold (Zielen).
    static let cursorWarpRelDropout: TimeInterval = 0.80

    static func cursorWarpSnapsRestore(teleport: Bool, mapped: Bool, dropout: TimeInterval = 0) -> Bool {
        if !teleport { return false }
        if mapped { return true }
        return dropout > cursorWarpRelDropout
    }

    static func cursorWarpRestoreOf(from: CGPoint, to: CGPoint, snap: Bool) -> CGPoint {
        snap ? to : from
    }

    /// JUMP/Hold: Slow=dx, sonst Atem-DC reißt den Cursor nach Restore.
    static func palmHighpassMutesJump(_ jumped: Bool) -> Bool { jumped }

    /// Vision-Flip 1 Tick: Lock halten. otherClaimed 3 Ticks löst.
    static let palmLateralityNeed = 3

    static func palmLateralityDebounce(otherClaimed: Bool, ticks: Int, need: Int = palmLateralityNeed) -> Bool {
        otherClaimed && ticks >= need
    }

    /// 0 unknown, 1 left, 2 right. Vision-Chirality-Flip sonst S1↔S2.
    /// claimedTicks Default = Need: alte Tests (otherClaimed sofort).
    static func palmLateralityLock(prev: Int, live: Int, otherClaimed: Bool, claimedTicks: Int = palmLateralityNeed) -> Int {
        if (prev == 1 || prev == 2), live != prev {
            if !palmLateralityDebounce(otherClaimed: otherClaimed, ticks: claimedTicks) { return prev }
        }
        return live
    }

    static func palmLateralityCode(_ left: Bool, right: Bool) -> Int {
        if left { return 1 }
        if right { return 2 }
        return 0
    }

    /// Warp-Hold freeze: Fill sonst (edged−held)/dt nach Release.
    static func palmWarpHoldJumps(_ held: Bool) -> Bool { held }

    /// Hold-Release: 40–64 px Catch-up bei 8 fps = 500 px/s Coast. Ein JUMP.
    static func palmWarpHoldReleaseJumps(wasHeld: Bool, nowHeld: Bool) -> Bool {
        wasHeld && !nowHeld
    }

    /// Vision-Flip gehalten: HUD `L` / `R`.
    static func palmLateralityChip(locked: Int, live: Int) -> String? {
        guard locked == 1 || locked == 2, locked != live else { return nil }
        return locked == 1 ? "← L" : "R →"
    }

    /// claimed.contains(.left) vor Bind macht aus der zweiten .left eine .right.
    static func palmLateralityClaimFlips(_ claimedContains: Bool) -> Bool {
        _ = claimedContains
        return false
    }

    /// Zweite Hand stiehlt die gelockte Seite nicht. Unknown, nicht Flip.
    static func palmLateralityTakes(locked: Int, claimedSame: Bool) -> Int {
        if claimedSame, locked == 1 || locked == 2 { return 0 }
        return locked
    }

    /// S1 Laterality nach Bind. Gitarre als S2 darf S1-Seite nicht klauen.
    static func palmLateralityBlocksS2(s1Locked: Int, live: Int, slotID: Int) -> Bool {
        slotID != 1 && (s1Locked == 1 || s1Locked == 2) && live == s1Locked
    }

    /// AXPosition ist Quartz. Cocoa-Cursor minus Quartz-Pos invertiert Y — Maske ≠ Fenster.
    static func axGrabOffset(cursorQuartz: CGPoint, axPosition: CGPoint) -> CGPoint {
        CGPoint(x: cursorQuartz.x - axPosition.x, y: cursorQuartz.y - axPosition.y)
    }

    static func axGrabDest(cursorQuartz: CGPoint, offset: CGPoint) -> CGPoint {
        CGPoint(x: cursorQuartz.x - offset.x, y: cursorQuartz.y - offset.y)
    }

    /// displayTick ohne Live-Frames coaster den Cursor in fremde Fenster.
    static func displayTickNeedsCamera(_ running: Bool, frameAge: TimeInterval = 0) -> Bool {
        running && frameAge >= 0 && frameAge < 0.10
    }

    /// visibleFrame ist Cocoa. AXPosition will Quartz — sonst Maske ≠ Fenster nach Snap.
    static func axSnapQuartz(visibleCocoa: CGRect, primaryMaxY: CGFloat) -> CGRect {
        CoordMath.quartzRect(fromCocoa: visibleCocoa, primaryMaxY: primaryMaxY)
    }

    /// Timeout ≠ Nachbarfenster greifen.
    static func axDragRebindsNeighbor() -> Bool { false }

    /// Raw Floor 0,10 flackert. EMA hält den Landmark.
    static func jointConfEMA(prev: Float, live: Float, alpha: Float = 0.35) -> Float {
        let a = min(0.80, max(0.15, alpha))
        if prev <= 0 { return live }
        return prev + a * (live - prev)
    }

    static func jointConfHolds(_ ema: Float, floor: Float = 0.10) -> Bool {
        ema + 1e-5 >= floor
    }

    /// EMA hält Palm-Knochen. Tips restored = Phantom-Pinch nach Occlusion.
    static func jointConfIsTip(_ name: String) -> Bool {
        name.lowercased().hasSuffix("tip")
    }

    static func jointConfRestores(holds: Bool, isTip: Bool) -> Bool {
        holds && !isTip
    }

    /// 0° Capture: Pixel stehen. height>width nicht .right — sonst 90° Palm nach Format-Hop.
    static func visionBufferOrientation(width: Int, height: Int, rotationApplied: Bool = false) -> UInt32 {
        if !rotationApplied, !physicalCaptureRotation() { return 1 }
        return previewOrientationRaw(width: width, height: height)
    }

    /// 8 fps AX 2 Frames. 180 ms war 1,4 Ticks — MAGNET/BUTTON flackert.
    static func axHitCacheNeed(dt: TimeInterval) -> Int { dt >= 0.08 ? 2 : 1 }

    /// 8 fps Cursor > 2,5 px/Tick. Cache 16 px sonst jeder Tick AX.
    static func axHitCacheDist(dt: TimeInterval) -> CGFloat {
        dt >= 0.08 ? 16 : 2.5
    }

    static func axHitCacheDistTTL(_ ttl: TimeInterval) -> CGFloat {
        ttl >= 0.20 ? 16 : 2.5
    }

    /// Swift 6: AX-Ref nach Sleep tot. TypeID vor Use.
    static func axTypeIDHolds(_ matches: Bool) -> Bool { matches }

    /// Ring wächst nicht unbegrenzt. 12 Slots, dann Steal-Drop.
    static func ringSlotCap(_ count: Int, cap: Int = 12) -> Bool { count < cap }

    /// Geometry-Hop neu. slots.count < 4 bei gleichem Format = Alloc-Sturm.
    static func ringRebuilds(count: Int, width: Int, height: Int, format: UInt32, wantW: Int, wantH: Int, wantFmt: UInt32) -> Bool {
        count == 0 || width != wantW || height != wantH || format != wantFmt
    }

    /// Slot-Dist + Laterality. Mismatch +0,10 — zwei .left-Obs sonst S1↔S2 nach Palm-Nähe.
    static func slotLateralityDist(palmDist: CGFloat, slotCode: Int, liveCode: Int, penalty: CGFloat = 0.10) -> CGFloat {
        if slotCode == 0 || liveCode == 0 || slotCode == liveCode { return palmDist }
        return palmDist + penalty
    }

    /// Matching-Slot in Reichweite: Mismatch nicht nehmen, Penalty 0,10 sonst zu schwach.
    static func slotLateralityMatches(slotCode: Int, liveCode: Int) -> Bool {
        slotCode != 0 && liveCode != 0 && slotCode == liveCode
    }

    static func slotLateralityPrefers(slotCode: Int, liveCode: Int, haveMatch: Bool) -> Bool {
        if !haveMatch { return true }
        return slotLateralityMatches(slotCode: slotCode, liveCode: liveCode)
    }

    /// Screen unter dem Punkt. inset −8 überlappte die Seam 16 px — Laptop first stahl den 5K.
    /// Mehrere contains: innerster, nicht screens.first. destEdgeHasNeighbor home sonst Laptop.
    static func destEdgeNearest(_ point: CGPoint, screens: [CGRect]) -> (screen: CGRect, dist: CGFloat)? {
        let valid = screens.filter { $0.width > 1 && $0.height > 1 }
        let containing = valid.filter { $0.contains(point) }
        if containing.count == 1 { return (containing[0], 0) }
        if containing.count > 1 {
            let interiors = containing.map { destEdgeInterior(point, in: $0) }
            let gap = max(destEdgeGap, destEdgeOverlapGap(screens: valid))
            // Seam-Band: min Interior < Gap, nicht nur alle. 40 px Cocoa-Overlap:
            // 4 px auf dem 5K / 36 px Laptop → max-Interior war Laptop-Pad.
            if interiors.contains(where: { $0 < gap }) {
                return (destEdgeLargerScreen(containing), 0)
            }
            var best = containing[0]
            var bestIn = destEdgeInterior(point, in: best)
            var bestArea = best.width * best.height
            for s in containing.dropFirst() {
                let inn = destEdgeInterior(point, in: s)
                let area = s.width * s.height
                if inn > bestIn + 1e-6 || (abs(inn - bestIn) <= 1e-6 && area > bestArea) {
                    best = s
                    bestIn = inn
                    bestArea = area
                }
            }
            return (best, 0)
        }
        var best: CGRect?
        var bestD = CGFloat.infinity
        for s in valid {
            let dx = max(0, max(s.minX - point.x, point.x - s.maxX))
            let dy = max(0, max(s.minY - point.y, point.y - s.maxY))
            let d = hypot(dx, dy)
            if d < bestD {
                bestD = d
                best = s
            }
        }
        if let best { return (best, bestD) }
        return nil
    }

    /// min Distanz zum Rand. Überlapp: der Schirm, in dem der Punkt tiefer sitzt.
    static func destEdgeInterior(_ point: CGPoint, in screen: CGRect) -> CGFloat {
        min(
            point.x - screen.minX,
            screen.maxX - point.x,
            point.y - screen.minY,
            screen.maxY - point.y
        )
    }

    static func destEdgeLargerScreen(_ screens: [CGRect]) -> CGRect {
        var best = screens[0]
        var bestArea = best.width * best.height
        for s in screens.dropFirst() {
            let area = s.width * s.height
            if area > bestArea {
                best = s
                bestArea = area
            }
        }
        return best
    }

    /// Nach Cross 160 ms Zielschirm halten. displayTick 90 Hz sonst Laptop-Pad im Rest-Overlap.
    static func destEdgeScreenHolds(holding: Bool, hold: CGRect?) -> CGRect? {
        guard holding, let hold, hold.width > 1, hold.height > 1 else { return nil }
        return hold
    }

    static func destEdgeScreenAt(
        point: CGPoint,
        screens: [CGRect],
        steal: CGRect?,
        map: CGRect?,
        main: CGRect?,
        hold: CGRect? = nil,
        holding: Bool = false
    ) -> CGRect? {
        if let held = destEdgeScreenHolds(holding: holding, hold: hold) {
            return held
        }
        if let hit = destEdgeNearest(point, screens: screens) {
            return hit.screen
        }
        return destEdgeScreen(steal: steal, map: map, main: main)
    }

    /// Seam-Lücke, nicht Void. to außerhalb ohne Nachbar = destEdge soll dämpfen.
    static let destEdgeGap: CGFloat = 32

    /// Seam: `from` Laptop, `to` 5K. destEdgeStep dämpft sonst mit Laptop-Pad — Cursor kriecht.
    /// first-contains = screens.first: 16 px Überlapp → Laptop stiehlt den 5K (destEdgeNearest 1.5.113).
    /// Enthalten: innerster. Lücke: nearest other ≤ gap. Void bleibt false.
    static func destEdgeScreenContaining(_ point: CGPoint, screens: [CGRect]) -> CGRect? {
        let hit = screens.filter { $0.width > 1 && $0.height > 1 && $0.contains(point) }
        guard !hit.isEmpty else { return nil }
        return destEdgeNearest(point, screens: hit)?.screen
    }

    static func destEdgeCrosses(from: CGPoint, to: CGPoint, screens: [CGRect], gap: CGFloat = destEdgeGap) -> Bool {
        let valid = screens.filter { $0.width > 1 && $0.height > 1 }
        let a = destEdgeScreenContaining(from, screens: valid)
        let b = destEdgeScreenContaining(to, screens: valid)
        if let a, let b {
            return abs(a.minX - b.minX) > 1
                || abs(a.minY - b.minY) > 1
                || abs(a.width - b.width) > 1
                || abs(a.height - b.height) > 1
        }
        if let a, b == nil {
            let others = valid.filter {
                abs($0.minX - a.minX) > 1
                    || abs($0.minY - a.minY) > 1
                    || abs($0.width - a.width) > 1
                    || abs($0.height - a.height) > 1
            }
            if let n = destEdgeNearest(to, screens: others), n.dist <= gap { return true }
        }
        return false
    }

    static func destEdgeSkipsCross(_ crosses: Bool) -> Bool { crosses }

    /// 1 px Jitter an der Seam: Cross an/aus jedes Frame → destEdge dämpft, Cursor stottert.
    /// 80 ms Hold stirbt vor dem nächsten Continuity-Tick (8 fps = 125 ms).
    static let destEdgeCrossHoldSec: TimeInterval = 0.16

    static func destEdgeSkipHold(
        pref: TimeInterval = destEdgeCrossHoldSec,
        frameDt: TimeInterval = 0
    ) -> TimeInterval {
        let p = destEdgeSkipPref(pref)
        if frameDt <= 0 { return p }
        return max(p, min(0.24, frameDt * 1.25))
    }

    /// Pref 40–240 ms. 80 ms stirbt vor Continuity 8 fps.
    static func destEdgeSkipPref(_ pref: TimeInterval) -> TimeInterval {
        min(0.24, max(0.04, pref))
    }

    static func destEdgeSkipNow(
        crosses: Bool,
        now: TimeInterval,
        lastAt: TimeInterval?,
        hold: TimeInterval = destEdgeCrossHoldSec
    ) -> (skip: Bool, lastAt: TimeInterval?) {
        if crosses { return (true, now) }
        if let lastAt, now - lastAt <= hold { return (true, lastAt) }
        return (false, lastAt)
    }

    /// 5K Pad 64, Lead 48: Fill 50 px vor der Seam dämpft den Rückweg.
    static func destEdgeFillLead(pad: CGFloat, extra: CGFloat = 16, floor: CGFloat = 48) -> CGFloat {
        max(floor, pad + extra)
    }

    /// Fill 90 Hz am Laptop-Rand Richtung 5K. destEdgeFill sonst Gain 0,35 — Kriechen.
    static func destEdgeFillToward(from: CGPoint, vel: CGPoint, screens: [CGRect], lead: CGFloat = 48) -> Bool {
        let n = hypot(vel.x, vel.y)
        guard n > 1 else { return false }
        let to = CGPoint(x: from.x + vel.x / n * lead, y: from.y + vel.y / n * lead)
        return destEdgeCrosses(from: from, to: to, screens: screens)
    }

    /// Seam in Bewegungsrichtung. destEdgeStep dämpfte 20 px vor der Naht — `to` bleibt auf dem Laptop.
    /// FillToward braucht Lead pad+16. HasNeighbor sitzt an der Kante, Pad und Lead entkoppelt.
    /// toward≈0: nächste Kante (ChipOf analog). Seam still Gain 1, Void dämpft.
    static func destEdgeHasNeighbor(
        point: CGPoint,
        toward: CGFloat,
        screens: [CGRect],
        axisX: Bool,
        gap: CGFloat = destEdgeGap
    ) -> Bool {
        let valid = screens.filter { $0.width > 1 && $0.height > 1 }
        guard valid.count >= 2 else { return false }
        guard let home = destEdgeNearest(point, screens: valid)?.screen else { return false }
        var dir = destEdgeTowardOf(toward)
        if abs(dir) <= 1e-9 {
            if axisX {
                dir = (home.maxX - point.x) <= (point.x - home.minX) ? 1 : -1
            } else {
                dir = (home.maxY - point.y) <= (point.y - home.minY) ? 1 : -1
            }
        }
        let out: CGFloat = dir > 0 ? 1 : -1
        let probe: CGPoint
        if axisX {
            let edge = dir > 0 ? home.maxX : home.minX
            let y = min(home.maxY - 1, max(home.minY + 1, point.y))
            probe = CGPoint(x: edge + out * min(gap, 8), y: y)
        } else {
            let edge = dir > 0 ? home.maxY : home.minY
            let x = min(home.maxX - 1, max(home.minX + 1, point.x))
            probe = CGPoint(x: x, y: edge + out * min(gap, 8))
        }
        let others = valid.filter {
            abs($0.minX - home.minX) > 1
                || abs($0.minY - home.minY) > 1
                || abs($0.width - home.width) > 1
                || abs($0.height - home.height) > 1
        }
        guard let n = destEdgeNearest(probe, screens: others) else { return false }
        return n.dist <= gap
    }

    /// Seam-Outbound Gain 1. Void behält destEdgeMul.
    static func destEdgeNeighborMul(_ mul: CGFloat, _ hasNeighbor: Bool) -> CGFloat {
        hasNeighbor ? 1 : mul
    }

    /// Pad des Schirms unter dem Cursor, nicht NSScreen.main / max / steal / screens.first.
    static func destEdgePadAt(
        point: CGPoint,
        screens: [CGRect],
        pref: CGFloat,
        steal: CGRect? = nil,
        map: CGRect? = nil,
        main: CGRect? = nil,
        hold: CGRect? = nil,
        holding: Bool = false
    ) -> CGFloat {
        destEdgePadNow(
            screen: destEdgeScreenAt(
                point: point,
                screens: screens,
                steal: steal,
                map: map,
                main: main,
                hold: hold,
                holding: holding
            ),
            pref: pref
        )
    }

    /// HUD-Stack. HP/VEL/JUMP/MUTE/LAT/OCC/PREDICT sonst > 6 und deckt den Cursor.
    /// prefix ohne Prio droppt JUMP. Duplikate crashen ForEach id:\.self.
    static func overlayChipKeep(_ chip: String) -> Int {
        let t = overlayChipTone(chip)
        if t == 1 { return 0 }
        if t == 2 { return 1 }
        return 2
    }

    static func overlayChipCap(_ chips: [String], cap: Int = 6) -> [String] {
        var seen = Set<String>()
        var unique: [String] = []
        for c in chips where !c.isEmpty {
            if seen.insert(c).inserted { unique.append(c) }
        }
        let n = max(0, cap)
        if unique.count <= n { return unique }
        let ranked = unique.enumerated().sorted { a, b in
            let pa = overlayChipKeep(a.element)
            let pb = overlayChipKeep(b.element)
            if pa != pb { return pa < pb }
            return a.offset < b.offset
        }
        let keep = Set(ranked.prefix(n).map(\.element))
        return unique.filter { keep.contains($0) }
    }

    /// 0 Amber, 1 Danger, 2 Cyan. Cap-ForEach sonst alles Amber.
    static func overlayChipTone(_ chip: String) -> Int {
        let u = chip.uppercased()
        if u.hasPrefix("VEL") || u.hasPrefix("JUMP") || u.hasPrefix("MUTE") || u.hasPrefix("OCC") { return 1 }
        if u.hasPrefix("PREDICT") || u.hasPrefix("ROI") || u.hasPrefix("LATCH") || u.hasPrefix("FILL") { return 2 }
        return 0
    }
}


/// 1-Euro auf einem Skalar. Relativzeiger, nicht Homographie.
struct PointerEuro {
    var minCutoff: CGFloat = 1.4
    var beta: CGFloat = 0.018
    var dCutoff: CGFloat = 1.0
    private var xHat: CGFloat?
    private var dxHat: CGFloat = 0
    private var tPrev: TimeInterval = 0

    init(minCutoff: CGFloat = 1.4, beta: CGFloat = 0.018, dCutoff: CGFloat = 1.0) {
        self.minCutoff = minCutoff
        self.beta = beta
        self.dCutoff = dCutoff
    }

    mutating func filter(_ value: CGFloat, now: TimeInterval) -> CGFloat {
        guard let prev = xHat else {
            xHat = value
            tPrev = now
            return value
        }
        let dt = CGFloat(max(1e-3, now - tPrev))
        tPrev = now
        let dx = (value - prev) / dt
        let ad = alpha(dCutoff, dt: dt)
        dxHat = ad * dx + (1 - ad) * dxHat
        let cutoff = GestureMath.oneEuroCutoff(base: minCutoff, dt: dt) + beta * abs(dxHat)
        let a = alpha(cutoff, dt: dt)
        let hat = a * value + (1 - a) * prev
        xHat = hat
        return hat
    }

    mutating func reset() {
        xHat = nil
        dxHat = 0
        tPrev = 0
    }

    private func alpha(_ cutoff: CGFloat, dt: CGFloat) -> CGFloat {
        let tau = 1 / (2 * .pi * max(1e-4, cutoff))
        return 1 / (1 + tau / dt)
    }
}

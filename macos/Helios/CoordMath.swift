import CoreGraphics
import Foundation

/// Reine Cocoa↔Quartz-Rechnung. Quartz-Ursprung = oben links am **Hauptbildschirm**.
enum CoordMath {
    /// Traffic-Lights / Titelleiste. Pinch darunter ist Text, kein Fenstergriff.
    static let titleBarHeight: CGFloat = 36
    /// Erstes Post-Clutch-Frame: Sprünge darüber sind Warp, kein echter Palm-Delta.
    static let warpGuardPx: CGFloat = 80
    /// Nach Zwei-Finger-Lift noch so lange ausrollen, analog Trackpad.
    static let scrollCoast: Double = 0.18
    /// AX-Hit-Test nicht jeden Frame systemweit.
    static let magnetCache: Double = 0.03
    static let textSelectHandwidths: CGFloat = 0.08
    /// Pinch auf Magnet-Ziele: unter so vielen Handbreiten klebt der Magnet, kein Zitter-Drag.
    static let clickLockHandwidths: CGFloat = 0.30
    static let peaceCooldownOk: Double = 4
    static let peaceCooldownFail: Double = 0.80
    /// Peace-als-Scroll: unter so vielen Handbreiten ist es Hold (Aufnahme), kein Tick.
    static let peaceScrollDeadzone: CGFloat = 0.12
    /// Traffic-Lights, Toggles, Slider, Tabs — Pinch-Zitter darf kein Fenster-Drag werden.
    static let clickLockRoles: Set<String> = [
        "AXSlider", "AXIncrementor", "AXCheckBox", "AXRadioButton",
        "AXCloseButton", "AXMinimizeButton", "AXZoomButton",
        "AXTab", "AXMenuItem", "AXButton", "AXPopUpButton", "AXDisclosureTriangle"
    ]
    /// HID-Pixel trifft Traffic-Lights oft 2–4 px daneben. AXPress trifft den Knopf.
    static let axPressRoles: Set<String> = [
        "AXCloseButton", "AXMinimizeButton", "AXZoomButton",
        "AXButton", "AXCheckBox", "AXRadioButton", "AXPopUpButton",
        "AXDisclosureTriangle", "AXTab", "AXMenuItem"
    ]
    static let textRoles: Set<String> = [
        "AXTextArea", "AXTextField", "AXTextView", "AXWebArea", "AXStaticText"
    ]
    static let textAbortRoles: Set<String> = [
        "AXButton", "AXToolbar", "AXTab", "AXMenuBar", "AXMenuItem",
        "AXCloseButton", "AXMinimizeButton", "AXZoomButton", "AXRadioButton"
    ]

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

    /// AXPosition ist Cocoa (unten links). Titelleiste = oberer Streifen.
    static func titleBar(windowPos: CGPoint, windowSize: CGSize, height: CGFloat = titleBarHeight) -> CGRect {
        CGRect(
            x: windowPos.x,
            y: windowPos.y + windowSize.height - height,
            width: windowSize.width,
            height: height
        )
    }

    static func cocoaInTitleBar(
        point: CGPoint,
        windowPos: CGPoint,
        windowSize: CGSize,
        height: CGFloat = titleBarHeight
    ) -> Bool {
        titleBar(windowPos: windowPos, windowSize: windowSize, height: height).contains(point)
    }

    /// Micro-Dwell-Magnet: sitzt `from` in `radius` von `toward`, rastet ein.
    static func magnetSnap(from: CGPoint, toward: CGPoint, radius: CGFloat = 4) -> CGPoint? {
        let d = hypot(from.x - toward.x, from.y - toward.y)
        guard d > 0.5, d <= radius else { return nil }
        return toward
    }

    /// Clutch-Nachlauf: Injektion bleibt tot, bis `endedAt + grace`.
    static func clutchInjects(now: Double, clutchEndedAt: Double, grace: Double = 0.15) -> Bool {
        now >= clutchEndedAt + grace
    }

    /// HUD-Chip. `remain` ist 0…1 der jeweiligen Phase — Nachlauf war vorher „TASTATUR“.
    static func clutchChip(reason: String, remain: CGFloat) -> (label: String, ms: CGFloat) {
        switch reason {
        case "Maus": return ("MAUS", remain * 850)
        case "Tastatur": return ("TASTATUR", remain * 400)
        case "Nachlauf": return ("NACHLAUF", remain * 150)
        default: return (reason.uppercased(), remain * 150)
        }
    }

    /// Erstes Post-Clutch-Frame: Δ > 80 px verwerfen, Hardware-Cursor bleibt.
    static func warpGuarded(from: CGPoint, to: CGPoint, limit: CGFloat = warpGuardPx) -> CGPoint {
        hypot(to.x - from.x, to.y - from.y) > limit ? from : to
    }

    /// Peace-Hold. `nil` = gerade am Scrollen, Aufnahme tot. Nach Scroll 1,2 s, sonst 0,9 s.
    static func peaceHoldSeconds(sinceScroll: Double) -> Double? {
        if sinceScroll < 0.40 { return nil }
        if sinceScroll < 1.20 { return 1.20 }
        return 0.90
    }

    /// HUD: Peace ist Pose, aber Aufnahme ist tot weil gerade gescrollt.
    static func peaceHoldDark(sinceScroll: Double) -> Bool {
        peaceHoldSeconds(sinceScroll: sinceScroll) == nil
    }

    /// Peace-Hand stillhalten ist Aufnahme, kein Zwei-Finger-Scroll.
    static func peaceScrollMoves(moved: CGFloat, deadzone: CGFloat = peaceScrollDeadzone) -> Bool {
        moved >= deadzone
    }

    /// Trackpad-Nachlauf: Ticks klingen in `window` s linear ab.
    static func scrollCoastTicks(last: Int32, elapsed: Double, window: Double = scrollCoast) -> Int32 {
        guard last != 0, elapsed >= 0, elapsed < window else { return 0 }
        let decay = 1 - elapsed / window
        let t = Int32((Double(last) * decay).rounded())
        if t != 0 { return t }
        return last > 0 ? 1 : -1
    }

    /// Magnet-Cache: gleicher Treffer, solange Cursor < 8 px und < 30 ms.
    static func magnetCacheHit(
        cachedAt: Double,
        cachedAtPoint: CGPoint,
        now: Double,
        point: CGPoint,
        ttl: Double = magnetCache,
        radius: CGFloat = 8
    ) -> Bool {
        now - cachedAt < ttl && hypot(point.x - cachedAtPoint.x, point.y - cachedAtPoint.y) < radius
    }

    /// Nach fehlgeschlagenem Screenshot nicht 4 s tot — nur 0,8 s, sonst wirkt die App tot.
    static func peaceCooldown(succeeded: Bool) -> Double {
        succeeded ? peaceCooldownOk : peaceCooldownFail
    }

    /// Slider/Stepper/Traffic-Lights/Toggles: kleine Palm-Zitter sind kein Drag.
    static func clickLockHolds(moved: CGFloat, role: String?) -> Bool {
        guard let role, clickLockRoles.contains(role) else { return false }
        return moved < clickLockHandwidths
    }

    /// HUD-Chip für den AX-Magnet. Nicht das generische „Magnet“.
    static func magnetLabel(_ role: String?) -> String {
        switch role {
        case "AXCloseButton": return "Schließen"
        case "AXMinimizeButton": return "Mini"
        case "AXZoomButton": return "Zoom"
        case "AXSlider", "AXIncrementor": return "Slider"
        case "AXCheckBox": return "Checkbox"
        case "AXRadioButton": return "Radio"
        case "AXTab": return "Tab"
        case "AXMenuItem": return "Menü"
        case "AXButton", "AXPopUpButton": return "Knopf"
        case "AXDisclosureTriangle": return "Dreieck"
        default: return "Magnet"
        }
    }

    /// Text-Drag bleibt in Text/Web. Chrome daneben bricht ab.
    static func stillInText(role: String?) -> Bool {
        guard let role else { return true }
        if textRoles.contains(role) { return true }
        if textAbortRoles.contains(role) { return false }
        return true
    }

    /// Dominant-Achse. Klar waagerecht → horizontal (Browser Shift-Wheel), sonst vertikal.
    static func scrollDelta(dx: CGFloat, dy: CGFloat) -> (horizontal: CGFloat, vertical: CGFloat) {
        if abs(dx) > abs(dy) * 1.25, abs(dx) > 0.10 {
            return (dx, 0)
        }
        return (0, dy)
    }

    /// macOS Natural-Scroll (Finger hoch = Inhalt runter). Default an.
    static func naturalScrollEnabled(_ object: Any?) -> Bool {
        if let b = object as? Bool { return b }
        if let n = object as? NSNumber { return n.boolValue }
        return true
    }

    /// Profil-Invert gilt für Natural-an. Natural-aus dreht nochmal, sonst doppelt falsch.
    /// Horizontal (wheel2) nimmt den vertikalen Profil-XOR nicht — sonst geht Safari-Zurück vorwärts.
    /// `invertHorizontal` ist der eigene Toggle (Terminal braucht ihn, Safari nicht).
    static func signedScrollTicks(
        _ ticks: Int32,
        profileInverts: Bool,
        natural: Bool,
        horizontal: Bool = false,
        invertHorizontal: Bool = false
    ) -> Int32 {
        var t = ticks
        if horizontal {
            if invertHorizontal { t = -t }
        } else if profileInverts {
            t = -t
        }
        if !natural { t = -t }
        return t
    }

    static let keyClutch: Double = 0.40
    static let keyRepeatClutch: Double = 0.55
    /// Shift/Ctrl/Opt/Cmd — CapsLock zählt nicht, sonst klebt der Clutch.
    static let modifierBlockMask: UInt = (1 << 17) | (1 << 18) | (1 << 19) | (1 << 20)

    static func modifiersBlockInjection(_ raw: UInt) -> Bool {
        (raw & modifierBlockMask) != 0
    }

    static func keyClutchSeconds(isRepeat: Bool, modifiersDown: Bool) -> Double {
        (isRepeat || modifiersDown) ? keyRepeatClutch : keyClutch
    }

    /// 80 ms nach Pinch-Start, sonst Ghost-Doppelklick in Textfeldern.
    static let textSelectDwell: Double = 0.08
    static let peaceRegionWidth: CGFloat = 720
    static let peaceRegionHeight: CGFloat = 450

    static func textSelectReady(held: Double, dwell: Double = textSelectDwell) -> Bool {
        held >= dwell
    }

    /// AX-Text unter dem Cursor → HUD als I-Beam, nicht als Pfeil.
    static func ibeamRole(_ role: String?) -> Bool {
        guard let role else { return false }
        return textRoles.contains(role)
    }

    /// Faust der zweiten Hand während Pinch = Shift+Klick.
    static func shiftClick(otherFist: Bool) -> Bool {
        otherFist
    }

    /// Zweite Hand: Faust = Shift, Peace = Cmd, Point = Opt. Faust gewinnt bei Kollision.
    static func clickFlags(otherFist: Bool, otherPeace: Bool, otherPoint: Bool) -> (shift: Bool, command: Bool, option: Bool) {
        if otherFist { return (true, false, false) }
        if otherPeace { return (false, true, false) }
        if otherPoint { return (false, false, true) }
        return (false, false, false)
    }

    static func clickName(shift: Bool, command: Bool, option: Bool) -> String {
        if command { return "Cmd-Klick" }
        if option { return "Opt-Klick" }
        if shift { return "Shift-Klick" }
        return "Klick"
    }

    /// HUD-Chip bevor der Pinch aufgeht. nil = keine zweite Hand.
    static func chordLabel(shift: Bool, command: Bool, option: Bool) -> String? {
        if command { return "CMD" }
        if option { return "OPT" }
        if shift { return "SHIFT" }
        return nil
    }

    static func axPresses(_ role: String?) -> Bool {
        guard let role else { return false }
        return axPressRoles.contains(role)
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

    /// Fenster unter dem Cursor, sonst 16:9-Region. Nicht das Vordergrund-Fenster.
    static func peaceCaptureBounds(window: CGRect?, cursor: CGPoint, screen: CGRect) -> CGRect {
        if let window, window.width > 8, window.height > 8 { return window }
        return peaceRegion(around: cursor, screen: screen)
    }

    /// Peace-Fallback: Region um den Cursor, nicht der ganze Schirm.
    static func peaceRegion(
        around quartz: CGPoint,
        screen: CGRect,
        width: CGFloat = peaceRegionWidth,
        height: CGFloat = peaceRegionHeight
    ) -> CGRect {
        let w = min(max(120, width), max(120, screen.width))
        let h = min(max(80, height), max(80, screen.height))
        var x = quartz.x - w / 2
        var y = quartz.y - h / 2
        if screen.width > 0 {
            x = min(max(x, screen.minX), screen.maxX - w)
        }
        if screen.height > 0 {
            y = min(max(y, screen.minY), screen.maxY - h)
        }
        return CGRect(x: x, y: y, width: w, height: h)
    }

    /// 0…1 der aktuellen Peace-Pause. Fail 0,8 s darf nicht durch 4 geteilt werden.
    static func peaceCooldownFraction(leftover: Double, span: Double) -> CGFloat {
        guard span > 0, leftover > 0 else { return 0 }
        return CGFloat(min(1, max(0, leftover / span)))
    }

    /// HUD-Sekunden: Restzeit, nicht remain×4.
    static func peaceCooldownSeconds(leftover: Double) -> Double {
        max(0, leftover)
    }
}

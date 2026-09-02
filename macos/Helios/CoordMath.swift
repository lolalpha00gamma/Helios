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
    /// Pinch auf Slider: unter so vielen Handbreiten klebt der Magnet, kein Zitter-Drag.
    static let clickLockHandwidths: CGFloat = 0.30
    static let peaceCooldownOk: Double = 4
    static let peaceCooldownFail: Double = 0.80
    static let clickLockRoles: Set<String> = ["AXSlider", "AXIncrementor"]
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

    /// Slider/Stepper: kleine Palm-Zitter sind kein Drag.
    static func clickLockHolds(moved: CGFloat, role: String?) -> Bool {
        guard let role, clickLockRoles.contains(role) else { return false }
        return moved < clickLockHandwidths
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
    static func signedScrollTicks(_ ticks: Int32, profileInverts: Bool, natural: Bool) -> Int32 {
        var t = ticks
        if profileInverts { t = -t }
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
}

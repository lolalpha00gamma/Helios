import AppKit
import CoreGraphics
import Foundation
import QuartzCore
import Vision

enum EngineMode: String {
    case idle
    case armed

    var labelDE: String {
        switch self {
        case .idle: return "BEREIT"
        case .armed: return "SCHARF"
        }
    }
}

enum GrabPhase: String {
    case none, follow, hold, grab

    var labelDE: String {
        switch self {
        case .none: return "KEINE HAND"
        case .follow: return "HIER"
        case .hold: return "HALTEN"
        case .grab: return "GREIFT"
        }
    }
}

enum GestureAction: String, CaseIterable, Codable, Hashable {
    case click, scroll, swipe, fling, grab, scale, peace, thumbs, dwell, rightClick

    var titleDE: String {
        switch self {
        case .click: return "Klick"
        case .scroll: return "Scroll"
        case .swipe: return "Wischen"
        case .fling: return "Werfen"
        case .grab: return "Greifen"
        case .scale: return "Skalieren"
        case .peace: return "Aufnahme"
        case .thumbs: return "Hervorholen"
        case .dwell: return "Dwell-Klick"
        case .rightClick: return "Rechtsklick"
        }
    }

    static func from(name: String) -> GestureAction? {
        switch name {
        case "Klick", "Shift-Klick", "Cmd-Klick", "Opt-Klick": return .click
        case "Scroll": return .scroll
        case "Nächste App", "Vorherige App": return .swipe
        case "Wegwerfen", "Minimieren", "Links andocken", "Rechts andocken": return .fling
        case "Greifen", "Heranziehen": return .grab
        case "Skalieren": return .scale
        case "Aufnahme": return .peace
        case "Hervorholen": return .thumbs
        case "Dwell-Klick": return .dwell
        case "Rechtsklick": return .rightClick
        default: return nil
        }
    }
}

/// Low-Light: Scroll bleibt, Klick/Greifen nicht. 0,20–0,28 nur Klick dämpfen.
enum LowLightGate {
    static func allows(_ action: GestureAction, luma: CGFloat) -> (ok: Bool, reason: String?) {
        if luma < 0.20 {
            switch action {
            case .scroll, .swipe:
                return (true, nil)
            default:
                return (false, "zu dunkel")
            }
        }
        if luma < 0.28, action == .click {
            return (false, "gedämpft")
        }
        return (true, nil)
    }
}

struct ProfileSpec: Codable, Equatable {
    var name: String
    var bundles: [String]
    var allowed: [String]?
    var invertScroll: Bool?
    var invertHorizontal: Bool?
}

struct ProfileOverride: Codable, Equatable {
    var extra: [String] = []
    var blocked: [String] = []
    var invertScroll: Bool?
    var invertHorizontal: Bool?
}

struct AppGestureProfile: Equatable {
    var name: String
    var allowed: Set<GestureAction>?
    var bundleId: String = ""
    var invertScroll = false
    var invertHorizontal = false

    static let standard = AppGestureProfile(name: "Standard", allowed: nil)

    static let bundledJSON = """
    [
      {
        "name": "Browser",
        "bundles": [
          "com.apple.Safari",
          "com.google.Chrome",
          "com.google.Chrome.canary",
          "org.mozilla.firefox",
          "company.thebrowser.Browser",
          "com.apple.Safari.WebApp"
        ],
        "allowed": ["click", "scroll", "swipe", "rightClick", "dwell", "peace"],
        "invertScroll": true,
        "invertHorizontal": false
      },
      {
        "name": "Finder",
        "bundles": ["com.apple.finder"],
        "allowed": ["click", "scroll", "grab", "fling", "rightClick", "dwell", "peace", "thumbs"],
        "invertScroll": false,
        "invertHorizontal": false
      },
      {
        "name": "Xcode",
        "bundles": ["com.apple.dt.Xcode"],
        "allowed": ["click", "scroll", "rightClick", "dwell"],
        "invertScroll": false,
        "invertHorizontal": false
      },
      {
        "name": "Terminal",
        "bundles": [
          "com.apple.Terminal",
          "com.googlecode.iterm2",
          "net.kovidgoyal.kitty",
          "com.github.wez.wezterm"
        ],
        "allowed": ["click", "scroll", "rightClick", "dwell", "peace"],
        "invertScroll": false,
        "invertHorizontal": true
      }
    ]
    """

    private static func catalog() -> [(ids: [String], name: String, allowed: Set<GestureAction>, invertScroll: Bool, invertHorizontal: Bool)] {
        let specs: [ProfileSpec]
        if let data = UserDefaults.standard.data(forKey: "helios.profiles.json"),
           let decoded = try? JSONDecoder().decode([ProfileSpec].self, from: data),
           !decoded.isEmpty
        {
            specs = decoded
        } else {
            specs = (try? JSONDecoder().decode([ProfileSpec].self, from: Data(bundledJSON.utf8))) ?? []
        }
        return specs.map { spec in
            let set = Set((spec.allowed ?? []).compactMap(GestureAction.init(rawValue:)))
            return (spec.bundles, spec.name, set, spec.invertScroll ?? false, spec.invertHorizontal ?? false)
        }
    }

    static func forBundle(_ id: String) -> AppGestureProfile {
        var base = Self.standard
        base.bundleId = id
        for row in catalog() where row.ids.contains(id) {
            base = AppGestureProfile(
                name: row.name,
                allowed: row.allowed.isEmpty ? nil : row.allowed,
                bundleId: id,
                invertScroll: row.invertScroll,
                invertHorizontal: row.invertHorizontal
            )
            break
        }
        let pack = loadOverrides()[id] ?? ProfileOverride()
        if pack.extra.isEmpty, pack.blocked.isEmpty, pack.invertScroll == nil, pack.invertHorizontal == nil { return base }
        var set = base.allowed ?? Set(GestureAction.allCases)
        for raw in pack.extra {
            if let a = GestureAction(rawValue: raw) { set.insert(a) }
        }
        for raw in pack.blocked {
            if let a = GestureAction(rawValue: raw) { set.remove(a) }
        }
        let tagged = pack.extra.isEmpty && pack.blocked.isEmpty ? base.name : "\(base.name)*"
        return AppGestureProfile(
            name: tagged,
            allowed: set,
            bundleId: id,
            invertScroll: pack.invertScroll ?? base.invertScroll,
            invertHorizontal: pack.invertHorizontal ?? base.invertHorizontal
        )
    }

    func allows(_ action: GestureAction) -> Bool {
        allowed?.contains(action) ?? true
    }

    static func setAction(_ action: GestureAction, bundle: String, on: Bool) {
        guard !bundle.isEmpty else { return }
        var all = loadOverrides()
        var pack = all[bundle] ?? ProfileOverride()
        let raw = action.rawValue
        if on {
            pack.blocked.removeAll { $0 == raw }
            if !pack.extra.contains(raw) { pack.extra.append(raw) }
        } else {
            pack.extra.removeAll { $0 == raw }
            if !pack.blocked.contains(raw) { pack.blocked.append(raw) }
        }
        all[bundle] = pack
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: "helios.profileOverrides")
        }
    }

    static func setInvertScroll(bundle: String, on: Bool) {
        guard !bundle.isEmpty else { return }
        var all = loadOverrides()
        var pack = all[bundle] ?? ProfileOverride()
        pack.invertScroll = on
        all[bundle] = pack
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: "helios.profileOverrides")
        }
    }

    static func setInvertHorizontal(bundle: String, on: Bool) {
        guard !bundle.isEmpty else { return }
        var all = loadOverrides()
        var pack = all[bundle] ?? ProfileOverride()
        pack.invertHorizontal = on
        all[bundle] = pack
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: "helios.profileOverrides")
        }
    }

    private static func loadOverrides() -> [String: ProfileOverride] {
        guard let data = UserDefaults.standard.data(forKey: "helios.profileOverrides"),
              let pack = try? JSONDecoder().decode([String: ProfileOverride].self, from: data)
        else { return [:] }
        return pack
    }
}

@MainActor
final class GestureEngine {
    var mode: EngineMode = .idle
    var lastAction = "—"
    var cursor: CGPoint?
    var twoHandSpan: CGFloat?
    var testMode = false
    var protocolMode = true
    var leftHanded = false
    var pointerGain: CGFloat = 1.6
    var spaceMap: SpaceMap?
    var calibration: CalibrationSession?
    var trashHot = false
    var killFlash = false
    var dragging = false
    var grabPhase: GrabPhase = .none
    var grabTargetName = ""
    var cursorHand: String = "—"
    var mousePaused = false
    var dwellEnabled = false
    var profile = AppGestureProfile.standard
    var fusionTemperature: Double = 0.75
    var luma: CGFloat = 1
    var peaceProgress: CGFloat = 0
    var clutchReason: String?
    var clutchRemain: CGFloat = 0
    var peaceCooldownRemain: CGFloat = 0
    var cursorIBeam = false
    var chordPreview: String?
    var peaceHoldDark = false
    var clapWake = false

    private var fistSince: TimeInterval?
    private var fistLostAt: TimeInterval?
    private var lastHandSeen: TimeInterval = 0
    private var palmSince: TimeInterval?
    private var lastPalmSeen: TimeInterval = 0
    private var thumbsSince: TimeInterval?
    private var peaceSince: TimeInterval?
    private var pinchHeld = false
    private var pinchBecameDrag = false
    private var pinchBeganAt: TimeInterval = 0
    private var pinchTrail: [(t: TimeInterval, x: CGFloat, y: CGFloat)] = []
    private var pinchSpan0: CGFloat?
    private var grabLogged = false
    private var lastGrabTry: TimeInterval = 0
    private var twoPinchSince: TimeInterval?
    private var swipeTrail: [(t: TimeInterval, x: CGFloat, y: CGFloat)] = []
    private var swipeHandID: String?
    private var cooldownUntil: TimeInterval = 0
    private var peaceCooldownUntil: TimeInterval = 0
    private var lastArmToggle: TimeInterval = 0
    private var lastLoggedPose: String = ""
    private var lastPoseLog: TimeInterval = 0
    private var killLatched = false
    private var mustRearm = false
    private var armLockUntil: TimeInterval = 0
    private var pointerOrigin: CGPoint?
    private var cursorSmooth: CGPoint?
    private var lastPalm: CGPoint?
    private var pointerHandID: String?
    private var swipeGraceUntil: TimeInterval = 0
    private var armedQuietUntil: TimeInterval = 0
    private var cursorDidMove = false
    private var lastPalmWidth: CGFloat = 0.12
    private var scrollAnchor: (t: TimeInterval, x: CGFloat, y: CGFloat)?
    private var ringPinchSince: TimeInterval?
    private var dwellSince: TimeInterval?
    private var dwellPalm: CGPoint?
    private var killSample: (t: TimeInterval, y: CGFloat)?
    private var dominantLockID: String?
    private var dominantLockSince: TimeInterval?
    private var dominantLostAt: TimeInterval?
    private var lastPreferred: TrackedHand?
    private var twoPinchLeftX: CGFloat?
    private var twoPinchRightX: CGFloat?
    private var palmRestSince: TimeInterval?
    /// Nach Clutch: Pinch nicht als Klick werten, bis die Finger wieder offen sind.
    private var pinchArmedAfterClutch = true
    /// Hover-Intent: Pinch muss 200 ms auf der Titelleiste sitzen, bevor AX greift.
    private var titleBarSince: TimeInterval?
    /// Nach Clutch: erstes Palm-Integral verwerfen, sonst Warp.
    private var warpGuardFrames = 0
    private var wasClutch = false
    /// Zwei-Finger-Scroll-Nachlauf.
    private var lastScrollAt: TimeInterval = 0
    private var lastScrollTicks: Int32 = 0
    private var lastScrollHorizontal: Int32 = 0
    private var pinchStartQuartz: CGPoint?
    private var clapClosed = false
    private var clapSpan: (t: TimeInterval, span: CGFloat)?
    private var firstClapAt: TimeInterval = 0
    private var lastClapFire: TimeInterval = 0
    private var lastTwoHands: TimeInterval = 0
    private let system = SystemControl()
    var onLog: ((String, ProtocolKind, Int?) -> Void)?
    var focused: FocusedTarget?

    private var space: AspectSpace { GestureClassifier.space }

    func reset() {
        mode = .idle
        fistSince = nil
        fistLostAt = nil
        lastHandSeen = 0
        palmSince = nil
        lastPalmSeen = 0
        thumbsSince = nil
        peaceSince = nil
        pinchHeld = false
        pinchBecameDrag = false
        pinchBeganAt = 0
        pinchTrail.removeAll()
        pinchSpan0 = nil
        grabLogged = false
        lastGrabTry = 0
        twoPinchSince = nil
        swipeTrail.removeAll()
        swipeHandID = nil
        cooldownUntil = 0
        peaceCooldownUntil = 0
        lastArmToggle = 0
        lastLoggedPose = ""
        lastPoseLog = 0
        killLatched = false
        mustRearm = false
        armLockUntil = 0
        pointerOrigin = nil
        cursorSmooth = nil
        lastPalm = nil
        pointerHandID = nil
        swipeGraceUntil = 0
        armedQuietUntil = 0
        cursorDidMove = false
        mousePaused = false
        killFlash = false
        scrollAnchor = nil
        ringPinchSince = nil
        dwellSince = nil
        dwellPalm = nil
        killSample = nil
        dominantLockID = nil
        dominantLockSince = nil
        dominantLostAt = nil
        lastPreferred = nil
        twoPinchLeftX = nil
        twoPinchRightX = nil
        palmRestSince = nil
        pinchArmedAfterClutch = true
        titleBarSince = nil
        warpGuardFrames = 0
        wasClutch = false
        lastScrollAt = 0
        lastScrollTicks = 0
        lastScrollHorizontal = 0
        pinchStartQuartz = nil
        clapClosed = false
        clapSpan = nil
        firstClapAt = 0
        lastClapFire = 0
        lastTwoHands = 0
        clapWake = false
        chordPreview = nil
        peaceHoldDark = false
        peaceProgress = 0
        clutchReason = nil
        clutchRemain = 0
        peaceCooldownRemain = 0
        cursorIBeam = false
        system.endWindowDrag()
        system.endTextDrag()
        cursor = nil
        twoHandSpan = nil
        trashHot = false
        dragging = false
        grabPhase = .none
        grabTargetName = ""
        lastAction = "Reset"
    }

    func tick(hands incoming: [TrackedHand], now: TimeInterval) {
        let hands = incoming.filter { $0.joints.count >= 8 && $0.meanConfidence >= 0.18 }
        refreshHudTimes(now: now)
        if hands.isEmpty {
            peaceProgress = 0
            if lastHandSeen > 0, now - lastHandSeen < 0.18, pinchHeld {
                dragging = pinchHeld
                return
            }
            coastScroll(now: now)
            releasePointer()
            fistSince = nil
            fistLostAt = nil
            palmSince = nil
            killLatched = false
            lastPalmSeen = 0
            pinchTrail.removeAll()
            swipeTrail.removeAll()
            swipeHandID = nil
            if system.isDragging { system.endWindowDrag() }
            if system.isTextDragging { system.endTextDrag() }
            pinchHeld = false
            pinchBecameDrag = false
            pinchStartQuartz = nil
            twoPinchSince = nil
            scrollAnchor = nil
            ringPinchSince = nil
            dwellSince = nil
            dwellPalm = nil
            palmRestSince = nil
            peaceProgress = 0
            trashHot = false
            dragging = false
            grabPhase = .none
            grabTargetName = ""
            if mustRearm {
                mode = .idle
                lastAction = "Not-Aus"
            }
            return
        }
        lastHandSeen = now
        lastPalmWidth = hands.map(\.palmWidth).max() ?? lastPalmWidth
        mousePaused = !system.allowsInjection && !system.fromInstallMedia
        peaceProgress = 0
        peaceHoldDark = false
        chordPreview = nil

        if system.fromInstallMedia {
            lastAction = "Cursor frei — Helios nach Programme ziehen"
            mode = .idle
            if let cal = calibration, cal.active { cal.cancel() }
            releasePointer()
            if system.isDragging { system.endWindowDrag() }
            return
        }

        if mousePaused {
            wasClutch = true
            lastAction = system.clutchReason == "Tastatur"
                ? "Tastatur hat Vorrang"
                : (system.clutchReason == "Nachlauf" ? "Nachlauf 150 ms" : "Maus hat Vorrang")
            swallowPinchFromClutch()
            let actor = preferred(hands, now: now)
            resyncPointer(actor)
            cursorHand = actor.sideDE
            dragging = false
            grabPhase = .follow
            grabTargetName = focused?.appName ?? ""
            return
        }
        if wasClutch {
            wasClutch = false
            warpGuardFrames = 2
        }

        if let cal = calibration, cal.active {
            let actor = preferred(hands, now: now)
            let confirm = actor.pinchClosed || actor.pose == .pinch
            if let done = cal.feed(palm: actor.palm, now: now, confirm: confirm) {
                spaceMap = done
                lastAction = "Kalibrierung fertig"
                let n = done.palms.count
                onLog?(n >= 9 ? "Kalibrierung · 9 Punkte" : "Kalibrierung · \(n) Punkte", .executed, 100)
                pinchHeld = false
                pinchBecameDrag = false
                cooldownUntil = now + 1.1
            } else {
                lastAction = cal.hint
            }
            cursor = SpaceMap.linear(actor.palm)
            cursorHand = actor.sideDE
            return
        }

        let primary = preferred(hands, now: now)
        let live = mode == .armed || testMode

        if protocolMode, now - lastPoseLog > 0.28 {
            let key = hands.map { "\($0.sideDE):\($0.pose.rawValue)" }.joined(separator: ",")
            if key != lastLoggedPose {
                lastLoggedPose = key
                lastPoseLog = now
                let text = hands.map {
                    String(format: "%@ %@ %.0f%%", $0.sideDE, $0.pose.labelDE, $0.poseProb * 100)
                }.joined(separator: " · ")
                let conf = Int((hands.map(\.poseProb).max() ?? 0) * 100)
                onLog?("Geste \(text)", .recognized, conf)
            }
        }

        if handleKillSwitch(hands: hands, now: now) {
            placeCursor(primary)
            if !testMode, cursorDidMove, let p = cursor {
                system.moveCursor(to: p)
            }
            return
        }
        _ = driveClap(hands: hands, now: now)
        handleArming(hands: hands, now: now)

        if system.isDragging, !profile.allows(.grab), !testMode {
            system.endWindowDrag()
            pinchBecameDrag = false
            lastAction = "Greifen — \(profile.name) blockt"
            onLog?("Greifen — Profil \(profile.name) bricht Drag ab", .blocked, nil)
        }

        if !live {
            placeCursor(primary)
            grabPhase = (primary.pose == .pinch || primary.pose == .fist) ? .hold : .follow
            grabTargetName = focused?.appName ?? ""
            if hands.contains(where: { $0.pose == .pinch || $0.pose == .fist }) {
                lastAction = mustRearm ? "Nach Not-Aus: Faust halten oder 2× klatschen" : "Faust halten oder 2× klatschen → Scharf"
            }
            dragging = false
            return
        }
        if now < cooldownUntil || now < armedQuietUntil {
            // Peace/Kill-Cooldown darf den Cursor nicht einfrieren — nur Aktionen.
            placeCursor(primary)
            if !testMode, !system.isDragging, cursorDidMove, primary.pose != .fist, let p = cursor {
                system.moveCursor(to: p)
            }
            if now < peaceCooldownUntil {
                lastAction = String(format: "Aufnahme-Pause %.0fs", ceil(peaceCooldownUntil - now))
            }
            updateTrashHot()
            dragging = pinchHeld
            return
        }

        let scaling = handleTwoPinchScale(hands: hands, now: now)
        let actor = pinchActor(hands, primary: primary)
        // Dominante Hand behält den Zeiger. Die zweite Hand darf greifen/peace,
        // stiehlt den Cursor aber nicht — vor 1.6.8 hat placeCursor(actor) das
        // Dominant-Lock unterlaufen.
        let freezePointer = pinchHeld && !pinchBecameDrag && actor.id == primary.id
        if !freezePointer {
            placeCursor(primary)
            if !testMode, !system.isDragging, cursorDidMove, primary.pose != .fist, let p = cursor {
                system.moveCursor(to: p)
            }
        }
        updateTrashHot()
        if scaling {
            dragging = pinchHeld
            return
        }
        let right = driveRightClick(actor, now: now)
        if !right {
            driveGrab(actor, hands: hands, now: now)
        }
        driveSwipe(hands: hands, now: now)
        driveScroll(hands: hands, now: now)
        drivePeace(actor, now: now)
        driveThumbs(actor, now: now)
        driveDwell(actor, now: now)
        drivePalmRest(actor, now: now)
        refreshChord(hands: hands, actor: actor)
        refreshCursorChrome()
        dragging = pinchHeld
        if system.isDragging {
            grabPhase = .grab
            grabTargetName = focused?.appName ?? grabTargetName
        } else if pinchHeld {
            grabPhase = .hold
            grabTargetName = focused?.appName ?? ""
        } else {
            grabPhase = .follow
            grabTargetName = focused?.appName ?? ""
        }
    }

    func forceIdle() {
        mode = .idle
        mustRearm = true
        system.endWindowDrag()
        system.endTextDrag()
        lastAction = "Idle"
        onLog?(testMode ? "Idle (Test)" : "Manuell Idle", .info, nil)
    }

    func forceArm() {
        mode = .armed
        mustRearm = false
        lastAction = "Scharf"
        onLog?(testMode ? "Scharf (Test)" : "Manuell Scharf", .info, nil)
    }

    func startInputClutch() {
        system.startClutch()
    }

    func recenterPointer() {
        lastPalm = nil
        pointerHandID = nil
        cursorSmooth = nil
    }

    private func releasePointer() {
        cursor = nil
        lastPalm = nil
        pointerHandID = nil
        cursorSmooth = nil
        pointerOrigin = nil
        cursorDidMove = false
        cursorIBeam = false
    }

    /// Clutch hat den Pinch unterbrochen — Loslassen danach ist kein Klick.
    private func swallowPinchFromClutch() {
        if pinchHeld || pinchBecameDrag || system.isDragging {
            pinchHeld = false
            pinchBecameDrag = false
            pinchTrail.removeAll()
            pinchSpan0 = nil
            grabLogged = false
            trashHot = false
            titleBarSince = nil
            pinchStartQuartz = nil
            system.endWindowDrag()
            system.endTextDrag()
        }
        pinchArmedAfterClutch = false
    }


    @discardableResult
    private func perform(
        _ name: String,
        need: PermissionNeed = .ax,
        confidence: Float = 1,
        systemAction: Bool = true,
        _ body: () -> ActionResult
    ) -> Bool {
        if systemAction, let kind = GestureAction.from(name: name), !profile.allows(kind), !testMode {
            lastAction = "\(name) — \(profile.name) blockt"
            onLog?("\(name) — Profil \(profile.name)", .blocked, Int(confidence * 100))
            return false
        }
        if systemAction, !testMode {
            if let kind = GestureAction.from(name: name) {
                let gate = LowLightGate.allows(kind, luma: luma)
                if !gate.ok {
                    lastAction = "\(name) — \(gate.reason ?? "zu dunkel")"
                    onLog?(
                        "\(name) — luma \(String(format: "%.2f", Double(luma))) \(gate.reason ?? "dunkel")",
                        .blocked,
                        Int(confidence * 100)
                    )
                    return false
                }
            } else if luma < 0.20 {
                lastAction = "\(name) — zu dunkel"
                onLog?("\(name) — luma \(String(format: "%.2f", Double(luma))) < 0,20", .blocked, Int(confidence * 100))
                return false
            }
        }
        if systemAction, confidence < 0.62, !testMode {
            lastAction = "\(name) — unsicher"
            onLog?("\(name) — Pose < 62 %", .blocked, Int(confidence * 100))
            return false
        }
        let conf = Int(confidence * 100)
        if testMode {
            lastAction = "Test: \(name)"
            onLog?("\(name) — Testmodus, System unberührt", .blocked, conf)
            return false
        }
        let r = body()
        if r.ok {
            lastAction = name
            onLog?("\(name) · \(r.detail)", .executed, conf)
            return true
        }
        lastAction = "\(name) fehlgeschlagen"
        onLog?("\(name) — NICHT AUSGEFÜHRT: \(r.detail)", .failed, conf)
        if need == .ax, r.detail.localizedCaseInsensitiveContains("Bedienung") {
            Permissions.demand(.accessibility)
        } else if need == .input {
            Permissions.demand(.inputMonitoring)
        }
        return false
    }

    /// Zwei Hände, sichtbarer Schlag zusammen — kein Mikrofon.
    @discardableResult
    private func driveClap(hands: [TrackedHand], now: TimeInterval) -> Bool {
        guard !pinchHeld, twoPinchSince == nil else { return false }
        if now - lastClapFire < 1.15 {
            return false
        }
        if mode == .idle, now < armLockUntil, (armLockUntil - now) > 1.20 {
            return false
        }
        guard hands.count >= 2 else {
            if lastTwoHands > 0, now - lastTwoHands > 0.22 {
                clapClosed = false
                clapSpan = nil
                firstClapAt = 0
            }
            return false
        }
        lastTwoHands = now
        let a = hands[0]
        let b = hands[1]
        if a.openScore == 0, b.openScore == 0 { return false }
        let unit = max(0.04, (a.palmWidth + b.palmWidth) / 2)
        let span = space.dist(a.palm, b.palm) / unit
        defer { clapSpan = (now, span) }
        if clapClosed {
            if span > CoordMath.clapOpen {
                clapClosed = false
            }
            return false
        }
        guard let prev = clapSpan else { return false }
        guard CoordMath.isClapPulse(prevSpan: prev.span, prevT: prev.t, span: span, now: now) else {
            if firstClapAt > 0, now - firstClapAt > CoordMath.clapMaxGap {
                firstClapAt = 0
            }
            return false
        }
        clapClosed = true
        if firstClapAt > 0, CoordMath.isDoubleClap(first: firstClapAt, second: now) {
            firstClapAt = 0
            lastClapFire = now
            clapWake = true
            palmSince = nil
            killLatched = false
            mustRearm = false
            fistSince = nil
            if mode != .armed {
                mode = .armed
                lastArmToggle = now
                cooldownUntil = now + 0.4
                armedQuietUntil = now + 0.70
                lastAction = testMode ? "Test: Doppelklatschen" : "Doppelklatschen → Scharf"
                onLog?(
                    testMode
                        ? "Doppelklatschen — Testmodus, System unberührt"
                        : "Doppelklatschen (Kamera) → Scharf",
                    testMode ? .blocked : .executed,
                    Int((hands.map(\.poseProb).max() ?? 0) * 100)
                )
            } else {
                lastAction = "Doppelklatschen"
                onLog?("Doppelklatschen — HUD nach vorn", .info, Int((hands.map(\.poseProb).max() ?? 0) * 100))
            }
            return true
        }
        firstClapAt = now
        lastAction = "Klatschen …"
        onLog?("Klatschen erkannt", .recognized, Int((hands.map(\.poseProb).max() ?? 0) * 100))
        return false
    }

    private func refreshChord(hands: [TrackedHand], actor: TrackedHand) {
        let other = hands.filter { $0.id != actor.id }
        let mods = CoordMath.clickFlags(
            otherFist: other.contains { $0.pose == .fist },
            otherPeace: other.contains { $0.pose == .peace },
            otherPoint: other.contains { $0.pose == .point }
        )
        chordPreview = CoordMath.chordLabel(shift: mods.shift, command: mods.command, option: mods.option)
    }

    @discardableResult
    private func handleKillSwitch(hands: [TrackedHand], now: TimeInterval) -> Bool {
        if firstClapAt > 0, now - firstClapAt < CoordMath.clapMaxGap {
            palmSince = nil
            return false
        }
        let open = hands.filter { $0.openScore >= 4 }
        let fists = hands.filter {
            $0.pose == .fist || ($0.openScore == 0 && $0.pinchRatio > 0.5 && $0.meanConfidence > 0.35)
        }
        // Faust + eine offene Hand bricht den 0,8-s-Hold ab, ohne Idle zu erzwingen.
        if palmSince != nil, !killLatched, fists.count >= 1, open.count == 1 {
            palmSince = nil
            killSample = nil
            lastAction = "Not-Aus abgebrochen"
            onLog?("Faust + offen → Not-Aus-Hold verworfen.", .info, nil)
            return false
        }
        if open.count >= 2 {
            let unit = max(0.04, (open[0].palmWidth + open[1].palmWidth) / 2)
            let span = space.dist(open[0].palm, open[1].palm) / unit
            if span < CoordMath.clapOpen {
                palmSince = nil
                if !killLatched { return false }
            }
            if killLatched {
                lastAction = "Not-Aus"
                mode = .idle
                return true
            }
            let y = open.map(\.palm.y).reduce(0, +) / CGFloat(open.count)
            var moving = false
            if let prev = killSample {
                let dt = max(0.001, now - prev.t)
                let speed = abs(y - prev.y) / unit / CGFloat(dt)
                if dt >= 0.016, speed > 0.7 { moving = true }
            }
            killSample = (now, y)
            // Vertikal unterwegs = Scroll, kein Not-Aus. Sonst frisst Kill jeden Zwei-Hand-Scroll.
            if moving {
                palmSince = nil
                return false
            }
            if palmSince == nil { palmSince = now }
            lastPalmSeen = now
            let held = now - (palmSince ?? now)
            if held >= 0.80 {
                mode = .idle
                mustRearm = true
                killLatched = true
                armLockUntil = now + 1.6
                pinchHeld = false
                pinchBecameDrag = false
                fistSince = nil
                system.endWindowDrag()
                lastAction = "Not-Aus"
                onLog?("Beide Hände offen → Not-Aus. Bleibt Idle, bis Faust hält oder 2× klatschen.", .info, nil)
                killFlash = true
                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    await MainActor.run { self?.killFlash = false }
                }
                cooldownUntil = now + 0.8
                return true
            }
            if held >= 0.35 {
                lastAction = "Not-Aus halten"
                return true
            }
            return false
        }
        killSample = nil
        if now - lastPalmSeen < 0.18, palmSince != nil {
            return true
        }
        palmSince = nil
        killLatched = false
        return false
    }

    private func handleArming(hands: [TrackedHand], now: TimeInterval) {
        if now < armLockUntil {
            if mode == .idle { lastAction = "Not-Aus — Faust oder 2× Klatschen" }
            return
        }
        if mode == .armed { return }

        let fisting = hands.contains {
            $0.pose == .fist || ($0.openScore == 0 && $0.pinchRatio > 0.5 && $0.meanConfidence > 0.35)
        }
        if fisting {
            fistLostAt = nil
            if fistSince == nil { fistSince = now }
            let need: TimeInterval = mustRearm ? 0.85 : 0.55
            let held = now - (fistSince ?? now)
            if held >= need, now - lastArmToggle > 0.6 {
                lastArmToggle = now
                fistSince = nil
                mustRearm = false
                mode = .armed
                lastAction = "Scharf"
                cooldownUntil = now + 0.4
                armedQuietUntil = now + 0.70
                onLog?("Faust → Scharf", .executed, Int((hands.map(\.poseProb).max() ?? 0) * 100))
            } else if held >= 0.08 {
                lastAction = "Faust …"
            }
        } else if fistSince != nil {
            if fistLostAt == nil { fistLostAt = now }
            if now - (fistLostAt ?? now) > 0.22 {
                fistSince = nil
                fistLostAt = nil
            }
        }
    }

    private func preferred(_ hands: [TrackedHand], now: TimeInterval) -> TrackedHand {
        // Lock-Timer darf nicht pro Frame zurückgesetzt werden — sonst greift der Lock nie.
        // 200 ms Hysterese: die zweite Hand kriegt den Cursor nicht in dem Frame, in dem
        // die dominante das Bild verlässt.
        if let id = dominantLockID {
            if let locked = hands.first(where: { $0.id == id }) {
                dominantLostAt = nil
                lastPreferred = locked
                if now - (dominantLockSince ?? now) >= 1.2 {
                    return locked
                }
            } else if now - (dominantLockSince ?? now) >= 1.2 {
                if dominantLostAt == nil { dominantLostAt = now }
                if now - (dominantLostAt ?? now) < 0.20, let kept = lastPreferred {
                    return kept
                }
                dominantLockID = nil
                dominantLockSince = nil
                dominantLostAt = nil
            }
        }
        let pick: TrackedHand = {
            if leftHanded, let left = hands.first(where: { $0.chirality == .left }) {
                return left
            }
            if !leftHanded, let right = hands.first(where: { $0.chirality == .right }) {
                return right
            }
            return hands.max { a, b in
                (a.joints.values.map(\.confidence).max() ?? 0) < (b.joints.values.map(\.confidence).max() ?? 0)
            } ?? hands[0]
        }()
        if dominantLockID != pick.id {
            dominantLockID = pick.id
            dominantLockSince = now
        }
        lastPreferred = pick
        return pick
    }

    private func refreshHudTimes(now: TimeInterval) {
        clutchReason = system.clutchReason
        clutchRemain = system.clutchRemain
        let leftover = peaceCooldownUntil > now ? peaceCooldownUntil - now : 0
        peaceCooldownRemain = leftover > 0 ? CGFloat(CoordMath.peaceCooldownSeconds(leftover: leftover)) : 0
    }

    private func refreshCursorChrome() {
        guard let p = cursor, !testMode else {
            cursorIBeam = false
            return
        }
        cursorIBeam = CoordMath.ibeamRole(system.cachedRole(at: p))
    }

    private func mappedPoint(_ hand: TrackedHand) -> CGPoint {
        adoptMapForCursor()
        if let map = spaceMap, map.isReady {
            return map.apply(hand.palm)
        }
        return SpaceMap.linear(hand.palm)
    }

    /// Ziehen folgt der Aktor-Hand. Nur die dominante Hand benutzt den geglätteten Cursor.
    private func dragPoint(_ hand: TrackedHand) -> CGPoint {
        if pointerHandID == hand.id, let c = cursor { return c }
        return mappedPoint(hand)
    }

    private func pinchActor(_ hands: [TrackedHand], primary: TrackedHand) -> TrackedHand {
        // Dominante Hand behält den Cursor. Zweite Hand pincht nicht den Zeiger weg.
        if pinchHeld, hands.contains(where: { $0.id == primary.id }) {
            return hands.first(where: { $0.id == primary.id }) ?? primary
        }
        if primary.pose == .pinch || primary.pinchClosedness > 0.55 || primary.pose == .fist {
            return primary
        }
        if pinchHeld {
            return hands.min { a, b in a.pinchRatio < b.pinchRatio } ?? primary
        }
        if let pinching = hands.filter({ $0.pose == .pinch || $0.pinchClosedness > 0.55 }).min(by: { $0.pinchRatio < $1.pinchRatio }) {
            return pinching
        }
        if let fist = hands.first(where: { $0.pose == .fist }) {
            return fist
        }
        return primary
    }

    private func actorMapped(_ hand: TrackedHand) -> CGPoint {
        adoptMapForCursor()
        if let map = spaceMap, map.isReady {
            cursorDidMove = true
            let qAbs = map.apply(hand.palm)
            let edge = map.edgeWeight(hand.palm)
            if pointerHandID != hand.id {
                pointerHandID = hand.id
                lastPalm = hand.palm
                cursorSmooth = qAbs
                return qAbs
            }
            let prevPalm = lastPalm ?? hand.palm
            lastPalm = hand.palm
            var dx = hand.palm.x - prevPalm.x
            var dy = hand.palm.y - prevPalm.y
            // Nah an der Kamera ist palmWidth groß — gleiche Pixel-Zitter
            // werden sonst zu großen Palm-Deltas. unit 0,12 → 0,003 wie bisher.
            let dead: CGFloat = 0.025 * max(0.04, hand.palmWidth)
            if abs(dx) < dead { dx = 0 }
            if abs(dy) < dead { dy = 0 }
            let from = cursorSmooth ?? qAbs
            let stepped = ScreenGeometry.stepCursor(from: from, dPalm: CGPoint(x: dx, y: dy), gain: pointerGain)
            // Äußere 15 %: Homographie. Innen: Trackpad-Relativ. Blend dazwischen.
            let mixed = CGPoint(
                x: edge * qAbs.x + (1 - edge) * stepped.x,
                y: edge * qAbs.y + (1 - edge) * stepped.y
            )
            let a: CGFloat = 0.86
            let s = CGPoint(x: a * mixed.x + (1 - a) * from.x, y: a * mixed.y + (1 - a) * from.y)
            let out = applyWarpGuard(from: from, to: s)
            cursorSmooth = out
            return out
        }
        cursorDidMove = false
        let palm = hand.palm
        if pointerHandID != hand.id {
            pointerHandID = hand.id
            lastPalm = palm
            let start = ScreenGeometry.clampQuartz(NSEvent.mouseLocation.screenFlipped)
            cursorSmooth = start
            return start
        }
        let prevPalm = lastPalm ?? palm
        lastPalm = palm
        var dx = palm.x - prevPalm.x
        var dy = palm.y - prevPalm.y
        let dead: CGFloat = 0.025 * max(0.04, hand.palmWidth)
        if abs(dx) < dead { dx = 0 }
        if abs(dy) < dead { dy = 0 }
        if dx == 0 && dy == 0 {
            return cursorSmooth ?? ScreenGeometry.clampQuartz(NSEvent.mouseLocation.screenFlipped)
        }
        cursorDidMove = true
        let from = cursorSmooth ?? ScreenGeometry.clampQuartz(NSEvent.mouseLocation.screenFlipped)
        let stepped = ScreenGeometry.stepCursor(from: from, dPalm: CGPoint(x: dx, y: dy), gain: pointerGain)
        let a: CGFloat = 0.8
        let s = CGPoint(x: a * stepped.x + (1 - a) * from.x, y: a * stepped.y + (1 - a) * from.y)
        let out = applyWarpGuard(from: from, to: s)
        cursorSmooth = out
        return out
    }

    /// Erstes Post-Clutch-Frame: Δ > 80 px ist Warp, Hardware-Cursor bleibt.
    private func applyWarpGuard(from: CGPoint, to: CGPoint) -> CGPoint {
        guard warpGuardFrames > 0 else { return to }
        warpGuardFrames -= 1
        return CoordMath.warpGuarded(from: from, to: to)
    }

    private func placeCursor(_ hand: TrackedHand) {
        cursor = actorMapped(hand)
        cursorHand = hand.sideDE
    }

    /// Während Clutch/Nachlauf nicht integrieren. lastPalm/cursorSmooth würden
    /// sonst nach der Pause den Hardware-Zeiger um die Palm-Deltas der Pause warpen.
    private func resyncPointer(_ hand: TrackedHand) {
        lastPalm = hand.palm
        pointerHandID = hand.id
        let hw = ScreenGeometry.clampQuartz(NSEvent.mouseLocation.screenFlipped)
        cursorSmooth = hw
        cursor = hw
        cursorDidMove = false
        cursorHand = hand.sideDE
    }

    private func adoptMapForCursor() {
        let loc = cursor ?? ScreenGeometry.quartz(fromCocoa: NSEvent.mouseLocation)
        guard let screen = ScreenGeometry.screenContaining(quartz: loc) else { return }
        let id = ScreenGeometry.displayID(of: screen)
        if spaceMap?.displayID == id { return }
        if let other = SpaceMap.load(displayID: id), other.isReady {
            spaceMap = other
        }
    }

    @discardableResult
    private func handleTwoPinchScale(hands: [TrackedHand], now: TimeInterval) -> Bool {
        let pinches = hands.filter { $0.pose == .pinch }
        guard pinches.count >= 2 else {
            twoHandSpan = nil
            twoPinchSince = nil
            twoPinchLeftX = nil
            twoPinchRightX = nil
            return false
        }
        // Gegenüberliegende Bildhälften, nicht zwei Pinzetten an einer Palme.
        let xs = pinches.map(\.palm.x).sorted()
        guard let lo = xs.first, let hi = xs.last, hi - lo >= 0.22 else {
            twoHandSpan = nil
            twoPinchSince = nil
            twoPinchLeftX = nil
            twoPinchRightX = nil
            return false
        }
        if twoPinchSince == nil { twoPinchSince = now }
        // Während der Bestätigung den Tick belegen, sonst feuern Klick/Wischen.
        guard now - (twoPinchSince ?? now) >= 0.35 else { return true }
        let left = pinches.min(by: { $0.palm.x < $1.palm.x })!
        let right = pinches.max(by: { $0.palm.x < $1.palm.x })!
        let unit = max(0.04, (left.palmWidth + right.palmWidth) / 2)
        let span = space.dist(left.palm, right.palm) / unit
        if twoPinchLeftX == nil {
            twoPinchLeftX = left.palm.x
            twoPinchRightX = right.palm.x
            twoHandSpan = span
            return true
        }
        let dLeft = (left.palm.x - (twoPinchLeftX ?? left.palm.x)) / unit
        let dRight = (right.palm.x - (twoPinchRightX ?? right.palm.x)) / unit
        twoPinchLeftX = left.palm.x
        twoPinchRightX = right.palm.x
        if (abs(dLeft) > 0.06 || abs(dRight) > 0.06), now >= cooldownUntil {
            let conf = Float(pinches.map(\.poseProb).min() ?? 0)
            let screenW = ScreenGeometry.cocoaUnion.width
            perform("Skalieren", confidence: conf) {
                system.nudgeWindow(dLeft: dLeft * screenW * 0.22, dRight: dRight * screenW * 0.22)
            }
            twoHandSpan = span
            cooldownUntil = now + 0.08
            return true
        }
        twoHandSpan = span
        return true
    }

    private func updateTrashHot() {
        guard pinchHeld, let cursor else {
            trashHot = false
            return
        }
        trashHot = NSScreen.screens.contains { screen in
            let local = ScreenGeometry.local(quartz: cursor, on: screen.frame)
            return ScreenGeometry.trashLocal(screen: screen).insetBy(dx: -20, dy: -20).contains(local)
        }
    }

    private func driveGrab(_ hand: TrackedHand, hands: [TrackedHand], now: TimeInterval) {
        if now < armedQuietUntil, !pinchHeld { return }
        let ratio = hand.pinchRatio
        let closed = hand.pinchClosed || hand.pinchClosedness > 0.55 || hand.pose == .pinch
        let fisting = hand.pose == .fist && mode == .armed
        let isGrab = pinchHeld
            ? (closed || (fisting && ratio < 0.55))
            : (closed || (fisting && ratio < 0.34))
        if !pinchArmedAfterClutch {
            if isGrab {
                lastAction = "Maus frei — Finger öffnen"
                return
            }
            pinchArmedAfterClutch = true
        }
        if isGrab && !pinchHeld {
            pinchHeld = true
            pinchBecameDrag = false
            pinchBeganAt = now
            pinchTrail = [(now, hand.palm.x, hand.palm.y)]
            pinchSpan0 = space.dist(hand.point(.middleTip) ?? hand.palm, hand.palm) / max(0.04, hand.palmWidth)
            grabLogged = false
            titleBarSince = nil
            pinchStartQuartz = dragPoint(hand)
            lastAction = testMode ? "Test: Halten" : "Halten"
            applyMagnet(at: dragPoint(hand))
        } else if isGrab && pinchHeld {
            pinchTrail.append((now, hand.palm.x, hand.palm.y))
            pinchTrail.removeAll { now - $0.t > 0.5 }
            var moved: CGFloat = 0
            if let first = pinchTrail.first {
                moved = space.dist(hand.palm, CGPoint(x: first.x, y: first.y)) / max(0.04, hand.palmWidth)
                if moved > 0.18, !CoordMath.clickLockHolds(moved: moved, role: system.lastMagnetRole) {
                    pinchBecameDrag = true
                }
            }
            let at = dragPoint(hand)
            if pinchStartQuartz == nil { pinchStartQuartz = at }
            // Textauswahl: Pinch über dem Textkörper, nicht der Titelleiste.
            if !testMode, !system.isDragging, !system.isTextDragging,
               let start = pinchStartQuartz,
               GestureClassifier.textSelectMoved(moved),
               CoordMath.textSelectReady(held: now - pinchBeganAt),
               !system.onTitleBar(at: start),
               now - lastGrabTry > 0.12
            {
                lastGrabTry = now
                perform("Klick", need: .input, confidence: Float(max(hand.poseProb, hand.pinchClosedness))) {
                    let began = system.beginTextDrag(at: start)
                    if began.ok { system.updateTextDrag(to: at) }
                    return began
                }
            }
            if !testMode, system.isTextDragging {
                system.updateTextDrag(to: at)
                lastAction = "Textauswahl"
            }
            if pinchBecameDrag, !system.isDragging, !system.isTextDragging, !testMode {
                if system.onTitleBar(at: at) {
                    if titleBarSince == nil { titleBarSince = now }
                    if now - (titleBarSince ?? now) >= 0.20, now - lastGrabTry > 0.35 {
                        lastGrabTry = now
                        perform("Greifen", confidence: Float(hand.poseProb)) {
                            system.beginWindowDrag(at: at)
                        }
                    } else if titleBarSince != nil, now - (titleBarSince ?? now) < 0.20 {
                        lastAction = "Titelleiste …"
                    }
                } else {
                    titleBarSince = nil
                    if !system.isTextDragging {
                        lastAction = GestureClassifier.textSelectMoved(moved)
                            ? "Textauswahl …"
                            : "Halten — Titelleiste für Fenster"
                    }
                }
            }
            // Drag muss jeden Frame folgen — nicht nur im Frame, der beginWindowDrag
            // aufruft. Vor 1.6.7 fehlte die schließende Klammer: update hing im
            // begin-if und das Fenster blieb stehen, sobald der Griff saß.
            if system.isDragging, !profile.allows(.grab), !testMode {
                system.endWindowDrag()
                lastAction = "Greifen — \(profile.name) blockt"
                onLog?("Greifen — Profil \(profile.name) bricht Drag ab", .blocked, Int(hand.poseProb * 100))
            } else if !testMode, system.isDragging {
                system.updateWindowDrag(to: dragPoint(hand))
                lastAction = trashHot ? "Papierkorb" : "Ziehen"
            } else if testMode, pinchBecameDrag {
                lastAction = trashHot ? "Test: Papierkorb" : "Test: Ziehen"
            } else if testMode, GestureClassifier.textSelectMoved(moved), !system.onTitleBar(at: at) {
                lastAction = "Test: Textauswahl"
            }
            if !pinchBecameDrag, !system.isDragging, !system.isTextDragging {
                applyMagnet(at: dragPoint(hand))
                if CoordMath.clickLockHolds(moved: moved, role: system.lastMagnetRole) {
                    lastAction = CoordMath.magnetLabel(system.lastMagnetRole)
                }
            }
            let span = space.dist(hand.point(.middleTip) ?? hand.palm, hand.palm) / max(0.04, hand.palmWidth)
            if let s0 = pinchSpan0, !system.isDragging, !system.isTextDragging, span > s0 + 1.4 {
                perform("Heranziehen", confidence: Float(hand.poseProb)) { system.snapFocused(.fill) }
                pinchSpan0 = span
                cooldownUntil = now + 0.5
            }
        } else if !isGrab && pinchHeld {
            let flung = resolveFling(now: now, confidence: Float(hand.poseProb), palmWidth: hand.palmWidth)
            let wasDrag = pinchBecameDrag
            let wasText = system.isTextDragging
            let held = now - pinchBeganAt
            pinchHeld = false
            pinchBecameDrag = false
            pinchTrail.removeAll()
            pinchSpan0 = nil
            grabLogged = false
            trashHot = false
            titleBarSince = nil
            pinchStartQuartz = nil
            if !testMode {
                if wasText {
                    system.endTextDrag()
                    lastAction = "Textauswahl"
                    onLog?("Textauswahl", .executed, Int(hand.poseProb * 100))
                    cooldownUntil = now + 0.12
                    return
                }
                system.endWindowDrag()
            }
            if flung {
                cooldownUntil = now + 0.4
                return
            }
            if wasDrag {
                lastAction = testMode ? "Test: Loslassen" : "Loslassen"
                onLog?("Loslassen", testMode ? .blocked : .executed, Int(hand.poseProb * 100))
            } else if held >= 0.07, held < 0.55 {
                let other = hands.filter { $0.id != hand.id }
                let mods = CoordMath.clickFlags(
                    otherFist: other.contains { $0.pose == .fist },
                    otherPeace: other.contains { $0.pose == .peace },
                    otherPoint: other.contains { $0.pose == .point }
                )
                let name = CoordMath.clickName(shift: mods.shift, command: mods.command, option: mods.option)
                perform(name, need: .input, confidence: Float(max(hand.poseProb, hand.pinchClosedness))) {
                    system.click(shift: mods.shift, command: mods.command, option: mods.option)
                }
            } else if held < 0.07 {
                lastAction = "zu kurz"
            }
            cooldownUntil = now + 0.12
        }
    }

    private func resolveFling(now: TimeInterval, confidence: Float, palmWidth: CGFloat) -> Bool {
        let unit = max(0.04, palmWidth)
        if trashHot {
            perform("Wegwerfen", confidence: confidence) { system.throwAway(finder: focused?.isFinder == true) }
            return true
        }
        guard let last = pinchTrail.last, let first = pinchTrail.first, last.t > first.t + 0.04 else {
            return false
        }
        let dt = max(0.04, last.t - first.t)
        let delta = space.vec(CGPoint(x: first.x, y: first.y), CGPoint(x: last.x, y: last.y))
        let dx = delta.x / unit
        let dy = delta.y / unit
        let vx = dx / dt
        let vy = dy / dt
        let speed = hypot(vx, vy)
        let dist = hypot(dx, dy)
        guard speed > 2.6 && dist > 0.55 else { return false }
        onLog?("Werfen erkannt", .recognized, Int(confidence * 100))
        if abs(dy) >= abs(dx) && dy > 0.55 {
            perform("Wegwerfen", confidence: confidence) { system.throwAway(finder: focused?.isFinder == true) }
            return true
        }
        if abs(dy) >= abs(dx) && dy < -0.35 {
            perform("Minimieren", confidence: confidence) { system.minimizeFocused() }
            return true
        }
        if dx < -0.50 {
            perform("Links andocken", confidence: confidence) { system.snapFocused(.left) }
            return true
        }
        if dx > 0.50 {
            perform("Rechts andocken", confidence: confidence) { system.snapFocused(.right) }
            return true
        }
        return false
    }

    private func driveSwipe(hands: [TrackedHand], now: TimeInterval) {
        guard !pinchHeld else {
            swipeTrail.removeAll()
            swipeHandID = nil
            return
        }
        let open = hands.filter { $0.pose == .openPalm || $0.openScore >= 2 }
        let hand = open.max { a, b in a.openScore < b.openScore }
            ?? (now < swipeGraceUntil ? hands.first : nil)
        guard let hand else {
            swipeTrail.removeAll()
            swipeHandID = nil
            return
        }
        if swipeHandID != hand.id {
            swipeTrail.removeAll()
            swipeHandID = hand.id
        }
        swipeGraceUntil = now + 0.32
        swipeTrail.append((now, hand.palm.x, hand.palm.y))
        swipeTrail.removeAll { now - $0.t > 0.40 }
        guard let first = swipeTrail.first, swipeTrail.count >= 2 else { return }
        let unit = max(0.04, hand.palmWidth)
        let delta = space.vec(CGPoint(x: first.x, y: first.y), hand.palm)
        let dx = delta.x / unit
        let dy = delta.y / unit
        let dt = now - first.t
        let speed = hypot(dx, dy) / max(dt, 0.001)
        // Flick: schnell, waagerecht, in Handbreiten — nicht dasselbe wie Cursor-Führen.
        guard dt >= 0.08, dt <= 0.40,
              abs(dx) > 0.85,
              abs(dx) > abs(dy) * 1.8,
              speed > 2.6 else { return }
        onLog?("Wischen erkannt", .recognized, Int(hand.poseProb * 100))
        let forward = dx < 0
        let name = forward ? "Nächste App" : "Vorherige App"
        perform(name, need: .none, confidence: Float(hand.poseProb)) { system.switchApp(forward: forward) }
        swipeTrail.removeAll()
        swipeHandID = nil
        cooldownUntil = now + 0.4
    }

    private func drivePeace(_ hand: TrackedHand, now: TimeInterval) {
        if hand.pose == .peace, hand.poseProb >= 0.50 {
            if CoordMath.peaceHoldDark(sinceScroll: now - lastScrollAt) {
                peaceSince = nil
                peaceProgress = 0
                peaceHoldDark = true
                lastAction = "Peace · Scroll-Pause"
                return
            }
            guard let need = CoordMath.peaceHoldSeconds(sinceScroll: now - lastScrollAt) else {
                peaceSince = nil
                peaceProgress = 0
                return
            }
            if peaceSince == nil { peaceSince = now }
            let held = now - (peaceSince ?? now)
            peaceProgress = CGFloat(min(1, max(0, held / need)))
            if held > need {
                let loc = cursor ?? ScreenGeometry.quartz(fromCocoa: NSEvent.mouseLocation)
                let under = TargetProbe.windowAt(quartz: loc, skipSelf: true)
                let ok = perform("Aufnahme", need: .capture, confidence: Float(hand.poseProb)) {
                    if let t = under, t.quartzBounds.width > 8 {
                        return system.screenshotFocused(windowID: t.windowID, bounds: t.quartzBounds)
                    }
                    let screen = ScreenGeometry.screenContaining(quartz: loc) ?? NSScreen.screens.first
                    let quartzScreen = screen.map { ScreenGeometry.quartzRect(fromCocoa: $0.frame) } ?? .zero
                    let region = CoordMath.peaceCaptureBounds(
                        window: nil,
                        cursor: loc,
                        screen: quartzScreen
                    )
                    return system.screenshotFocused(windowID: 0, bounds: region)
                }
                peaceSince = nil
                peaceProgress = 0
                let pause = CoordMath.peaceCooldown(succeeded: ok)
                peaceCooldownUntil = now + pause
                cooldownUntil = now + pause
            }
        } else {
            peaceSince = nil
            peaceProgress = 0
        }
    }

    private func driveThumbs(_ hand: TrackedHand, now: TimeInterval) {
        if hand.pose == .thumbsUp, hand.poseProb >= 0.50 {
            if thumbsSince == nil { thumbsSince = now }
            if now - (thumbsSince ?? now) > 0.5 {
                perform("Hervorholen", need: .none, confidence: Float(hand.poseProb)) { system.unhideFront() }
                thumbsSince = nil
                cooldownUntil = now + 3
            }
        } else {
            thumbsSince = nil
        }
    }

    /// Handrücken / Finger nach unten 0,6 s → Idle ohne Kill-Latch.
    private func drivePalmRest(_ hand: TrackedHand, now: TimeInterval) {
        guard mode == .armed, !pinchHeld, !system.isDragging else {
            palmRestSince = nil
            return
        }
        let wrist = hand.point(.wrist) ?? hand.palm
        let tip = hand.point(.middleTip) ?? hand.palm
        if GestureClassifier.palmDown(wrist: wrist, tip: tip, openScore: hand.openScore, pose: hand.pose),
           hand.poseProb >= 0.45
        {
            if palmRestSince == nil { palmRestSince = now }
            if now - (palmRestSince ?? now) >= 0.60 {
                mode = .idle
                mustRearm = false
                lastAction = "Ruhe"
                onLog?("Handrücken 0,6 s → Idle, kein Not-Aus", .info, Int(hand.poseProb * 100))
                palmRestSince = nil
                system.endWindowDrag()
                system.endTextDrag()
            } else {
                lastAction = "Ruhe …"
            }
        } else {
            palmRestSince = nil
        }
    }

    /// Zwei offene Hände vertikal — getrennt vom waagerechten Flick-Wischen.
    /// Ein-Hand-Zwei-Finger (Peace), wenn die andere Hand ruht oder fehlt.
    private func driveScroll(hands: [TrackedHand], now: TimeInterval) {
        guard !pinchHeld else {
            scrollAnchor = nil
            lastScrollTicks = 0
            lastScrollHorizontal = 0
            return
        }
        func isRest(_ h: TrackedHand) -> Bool {
            GestureClassifier.palmDown(
                wrist: h.point(.wrist) ?? h.palm,
                tip: h.point(.middleTip) ?? h.palm,
                openScore: h.openScore,
                pose: h.pose
            )
        }
        let rest = hands.filter(isRest)
        let open = hands.filter {
            $0.openScore >= 3 && !isRest($0)
        }
        let peace = hands.filter { $0.pose == .peace && $0.poseProb >= 0.45 }
        let actors: [TrackedHand]
        if open.count >= 2 {
            actors = open
        } else if GestureClassifier.twoFingerScroll(
            peace: peace.count,
            openPalms: open.count,
            resting: rest.count,
            hands: hands.count
        ) {
            actors = peace
        } else {
            coastScroll(now: now)
            scrollAnchor = nil
            return
        }
        let peaceOnly = open.count < 2 && !peace.isEmpty
        let y = actors.map(\.palm.y).reduce(0, +) / CGFloat(actors.count)
        let x = actors.map(\.palm.x).reduce(0, +) / CGFloat(actors.count)
        let unit = max(0.04, (actors[0].palmWidth + (actors.count > 1 ? actors[1].palmWidth : actors[0].palmWidth)) / 2)
        guard let a = scrollAnchor else {
            scrollAnchor = (now, x, y)
            return
        }
        let dy = (y - a.y) / unit
        let dx = (x - a.x) / unit
        let dt = now - a.t
        guard dt >= 0.05 else { return }
        // Peace stillhalten ist Aufnahme, kein Tick. Zwei offene Palmen bleiben frei.
        if peaceOnly, !CoordMath.peaceScrollMoves(moved: hypot(dx, dy)) {
            return
        }
        let axis = CoordMath.scrollDelta(dx: dx, dy: dy)
        let gain = 2.2 / max(0.06, unit)
        var vTicks = Int32(max(-24, min(24, -axis.vertical * gain)))
        var hTicks = Int32(max(-24, min(24, -axis.horizontal * gain)))
        let natural = CoordMath.naturalScrollEnabled(
            UserDefaults.standard.object(forKey: "com.apple.swipescrolldirection")
        )
        vTicks = CoordMath.signedScrollTicks(vTicks, profileInverts: profile.invertScroll, natural: natural)
        hTicks = CoordMath.signedScrollTicks(
            hTicks,
            profileInverts: profile.invertScroll,
            natural: natural,
            horizontal: true,
            invertHorizontal: profile.invertHorizontal
        )
        guard vTicks != 0 || hTicks != 0 else { return }
        let conf = Float(actors.map(\.poseProb).min() ?? 0)
        perform("Scroll", need: .input, confidence: conf) { system.scroll(ticks: vTicks, horizontal: hTicks) }
        scrollAnchor = (now, x, y)
        lastScrollAt = now
        lastScrollTicks = vTicks
        lastScrollHorizontal = hTicks
        peaceSince = nil
        peaceProgress = 0
    }

    /// Trackpad-Nachlauf 180 ms, sonst stirbt der Schwung hart am Lift.
    private func coastScroll(now: TimeInterval) {
        let v = CoordMath.scrollCoastTicks(last: lastScrollTicks, elapsed: now - lastScrollAt)
        let h = CoordMath.scrollCoastTicks(last: lastScrollHorizontal, elapsed: now - lastScrollAt)
        if v != 0 || h != 0 {
            perform("Scroll", need: .input, confidence: 0.70) { system.scroll(ticks: v, horizontal: h) }
        } else {
            lastScrollTicks = 0
            lastScrollHorizontal = 0
        }
    }

    /// Pinzette + Ringfinger, Mittel nicht gestreckt. Kurzer Halt → Rechtsklick statt Ziehen.
    @discardableResult
    private func driveRightClick(_ hand: TrackedHand, now: TimeInterval) -> Bool {
        let ringOut = hand.isExtended(.ring) && !hand.isExtended(.middle)
        let pinching = hand.pinchClosed || hand.pose == .pinch || hand.pinchClosedness > 0.55
        guard pinching, ringOut, !pinchHeld else {
            ringPinchSince = nil
            return false
        }
        if ringPinchSince == nil { ringPinchSince = now }
        let held = now - (ringPinchSince ?? now)
        if held >= 0.14 {
            perform("Rechtsklick", need: .input, confidence: Float(max(hand.poseProb, hand.pinchClosedness))) {
                system.rightClick()
            }
            ringPinchSince = nil
            cooldownUntil = now + 0.45
            // Loslassen danach ist kein Linksklick. Finger müssen erst wieder offen sein.
            pinchArmedAfterClutch = false
            pinchHeld = false
            pinchBecameDrag = false
            pinchTrail.removeAll()
            pinchStartQuartz = nil
            titleBarSince = nil
            return true
        }
        lastAction = "Rechtsklick …"
        return true
    }

    /// Offene Hand 1 s still. Aus by default — Accessibility, nicht Alltags-Klick.
    private func driveDwell(_ hand: TrackedHand, now: TimeInterval) {
        guard dwellEnabled, !pinchHeld, hand.openScore >= 3, hand.pose != .fist else {
            dwellSince = nil
            dwellPalm = nil
            return
        }
        if let prev = dwellPalm {
            let moved = space.dist(hand.palm, prev) / max(0.04, hand.palmWidth)
            if moved > 0.10 {
                dwellSince = now
                dwellPalm = hand.palm
                return
            }
        } else {
            dwellSince = now
            dwellPalm = hand.palm
            return
        }
        if now - (dwellSince ?? now) >= 1.0 {
            perform("Dwell-Klick", need: .input, confidence: Float(hand.poseProb)) { system.click() }
            dwellSince = nil
            dwellPalm = nil
            cooldownUntil = now + 0.8
        } else {
            lastAction = "Dwell …"
        }
    }

    /// 4 px AX-Magnet auf Schließen/Slider, solange Pinch stillhält.
    /// HUD *und* HID: sonst klickt `lastPosted` 4 px neben dem Magnet.
    private func applyMagnet(at quartz: CGPoint) {
        guard !testMode, let snapped = system.magnetQuartz(at: quartz) else { return }
        cursor = snapped
        cursorSmooth = snapped
        system.adoptPosted(snapped)
        system.moveCursor(to: snapped)
        lastAction = CoordMath.magnetLabel(system.lastMagnetRole)
    }
}

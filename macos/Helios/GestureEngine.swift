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
        case "Klick": return .click
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
}

struct ProfileOverride: Codable, Equatable {
    var extra: [String] = []
    var blocked: [String] = []
    var invertScroll: Bool?
}

struct AppGestureProfile: Equatable {
    var name: String
    var allowed: Set<GestureAction>?
    var bundleId: String = ""
    var invertScroll = false

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
        "invertScroll": true
      },
      {
        "name": "Finder",
        "bundles": ["com.apple.finder"],
        "allowed": ["click", "scroll", "grab", "fling", "rightClick", "dwell", "peace", "thumbs"],
        "invertScroll": false
      },
      {
        "name": "Xcode",
        "bundles": ["com.apple.dt.Xcode"],
        "allowed": ["click", "scroll", "rightClick", "dwell"],
        "invertScroll": false
      }
    ]
    """

    private static func catalog() -> [(ids: [String], name: String, allowed: Set<GestureAction>, invertScroll: Bool)] {
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
            return (spec.bundles, spec.name, set, spec.invertScroll ?? false)
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
                invertScroll: row.invertScroll
            )
            break
        }
        let pack = loadOverrides()[id] ?? ProfileOverride()
        if pack.extra.isEmpty, pack.blocked.isEmpty, pack.invertScroll == nil { return base }
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
            invertScroll: pack.invertScroll ?? base.invertScroll
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
    private var scrollAnchor: (t: TimeInterval, y: CGFloat)?
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
        peaceProgress = 0
        clutchReason = nil
        clutchRemain = 0
        peaceCooldownRemain = 0
        system.endWindowDrag()
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
            pinchHeld = false
            pinchBecameDrag = false
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

        if system.fromInstallMedia {
            lastAction = "Cursor frei — Helios nach Programme ziehen"
            mode = .idle
            if let cal = calibration, cal.active { cal.cancel() }
            releasePointer()
            if system.isDragging { system.endWindowDrag() }
            return
        }

        if mousePaused {
            lastAction = "Maus hat Vorrang"
        }

        if let cal = calibration, cal.active {
            let actor = preferred(hands, now: now)
            let confirm = actor.pinchClosed || actor.pose == .pinch
            if let done = cal.feed(palm: actor.palm, now: now, confirm: confirm) {
                spaceMap = done
                lastAction = "Kalibrierung fertig"
                onLog?("Kalibrierung · 4 Ecken", .executed, 100)
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
                lastAction = mustRearm ? "Nach Not-Aus: Faust halten" : "Faust halten → Scharf"
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
            driveGrab(actor, now: now)
        }
        driveSwipe(hands: hands, now: now)
        driveScroll(hands: hands, now: now)
        drivePeace(actor, now: now)
        driveThumbs(actor, now: now)
        driveDwell(actor, now: now)
        drivePalmRest(actor, now: now)
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
    }

    private func perform(
        _ name: String,
        need: PermissionNeed = .ax,
        confidence: Float = 1,
        systemAction: Bool = true,
        _ body: () -> ActionResult
    ) {
        if systemAction, let kind = GestureAction.from(name: name), !profile.allows(kind), !testMode {
            lastAction = "\(name) — \(profile.name) blockt"
            onLog?("\(name) — Profil \(profile.name)", .blocked, Int(confidence * 100))
            return
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
                    return
                }
            } else if luma < 0.20 {
                lastAction = "\(name) — zu dunkel"
                onLog?("\(name) — luma \(String(format: "%.2f", Double(luma))) < 0,20", .blocked, Int(confidence * 100))
                return
            }
        }
        if systemAction, confidence < 0.62, !testMode {
            lastAction = "\(name) — unsicher"
            onLog?("\(name) — Pose < 62 %", .blocked, Int(confidence * 100))
            return
        }
        let conf = Int(confidence * 100)
        if testMode {
            lastAction = "Test: \(name)"
            onLog?("\(name) — Testmodus, System unberührt", .blocked, conf)
            return
        }
        let r = body()
        if r.ok {
            lastAction = name
            onLog?("\(name) · \(r.detail)", .executed, conf)
            return
        }
        lastAction = "\(name) fehlgeschlagen"
        onLog?("\(name) — NICHT AUSGEFÜHRT: \(r.detail)", .failed, conf)
        if need == .ax, r.detail.localizedCaseInsensitiveContains("Bedienung") {
            Permissions.demand(.accessibility)
        } else if need == .input {
            Permissions.demand(.inputMonitoring)
        }
    }

    @discardableResult
    private func handleKillSwitch(hands: [TrackedHand], now: TimeInterval) -> Bool {
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
            if killLatched {
                lastAction = "Not-Aus"
                mode = .idle
                return true
            }
            let y = open.map(\.palm.y).reduce(0, +) / CGFloat(open.count)
            let unit = max(0.04, (open[0].palmWidth + open[1].palmWidth) / 2)
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
                onLog?("Beide Hände offen → Not-Aus. Bleibt Idle, bis Faust hält.", .info, nil)
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
            if mode == .idle { lastAction = "Not-Aus — Faust zum Scharf" }
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
        peaceCooldownRemain = peaceCooldownUntil > now
            ? CGFloat(min(1, max(0, (peaceCooldownUntil - now) / 4)))
            : 0
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
            cursorSmooth = s
            return s
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
        cursorSmooth = s
        return s
    }

    private func placeCursor(_ hand: TrackedHand) {
        cursor = actorMapped(hand)
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

    private func driveGrab(_ hand: TrackedHand, now: TimeInterval) {
        if now < armedQuietUntil, !pinchHeld { return }
        let ratio = hand.pinchRatio
        let closed = hand.pinchClosed || hand.pinchClosedness > 0.55 || hand.pose == .pinch
        let fisting = hand.pose == .fist && mode == .armed
        let isGrab = pinchHeld
            ? (closed || (fisting && ratio < 0.55))
            : (closed || (fisting && ratio < 0.34))
        if isGrab && !pinchHeld {
            pinchHeld = true
            pinchBecameDrag = false
            pinchBeganAt = now
            pinchTrail = [(now, hand.palm.x, hand.palm.y)]
            pinchSpan0 = space.dist(hand.point(.middleTip) ?? hand.palm, hand.palm) / max(0.04, hand.palmWidth)
            grabLogged = false
            lastAction = testMode ? "Test: Halten" : "Halten"
        } else if isGrab && pinchHeld {
            pinchTrail.append((now, hand.palm.x, hand.palm.y))
            pinchTrail.removeAll { now - $0.t > 0.5 }
            if let first = pinchTrail.first {
                let moved = space.dist(hand.palm, CGPoint(x: first.x, y: first.y)) / max(0.04, hand.palmWidth)
                // Bewegung ohne Profil-Greifen: trotzdem Drag-Intent, damit
                // Safari keinen Fehlklick feuert — beginWindowDrag läuft über perform().
                if moved > 0.18 { pinchBecameDrag = true }
            }
            if pinchBecameDrag, !system.isDragging, !testMode, now - lastGrabTry > 0.35 {
                lastGrabTry = now
                let at = dragPoint(hand)
                perform("Greifen", confidence: Float(hand.poseProb)) {
                    system.beginWindowDrag(at: at)
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
            }
            let span = space.dist(hand.point(.middleTip) ?? hand.palm, hand.palm) / max(0.04, hand.palmWidth)
            if let s0 = pinchSpan0, !system.isDragging, span > s0 + 1.4 {
                perform("Heranziehen", confidence: Float(hand.poseProb)) { system.snapFocused(.fill) }
                pinchSpan0 = span
                cooldownUntil = now + 0.5
            }
        } else if !isGrab && pinchHeld {
            let flung = resolveFling(now: now, confidence: Float(hand.poseProb), palmWidth: hand.palmWidth)
            let wasDrag = pinchBecameDrag
            let held = now - pinchBeganAt
            pinchHeld = false
            pinchBecameDrag = false
            pinchTrail.removeAll()
            pinchSpan0 = nil
            grabLogged = false
            trashHot = false
            if !testMode { system.endWindowDrag() }
            if flung {
                cooldownUntil = now + 0.4
                return
            }
            if wasDrag {
                lastAction = testMode ? "Test: Loslassen" : "Loslassen"
                onLog?("Loslassen", testMode ? .blocked : .executed, Int(hand.poseProb * 100))
            } else if held >= 0.07, held < 0.55 {
                perform("Klick", need: .input, confidence: Float(max(hand.poseProb, hand.pinchClosedness))) { system.click() }
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
            if peaceSince == nil { peaceSince = now }
            let held = now - (peaceSince ?? now)
            peaceProgress = CGFloat(min(1, max(0, held / 0.90)))
            if held > 0.90 {
                let target = focused
                perform("Aufnahme", need: .capture, confidence: Float(hand.poseProb)) {
                    if let t = target, t.quartzBounds.width > 8 {
                        return system.screenshotFocused(windowID: t.windowID, bounds: t.quartzBounds)
                    }
                    let b = NSScreen.main.map { ScreenGeometry.quartzRect(fromCocoa: $0.frame) } ?? .zero
                    return system.screenshotFocused(windowID: 0, bounds: b)
                }
                peaceSince = nil
                peaceProgress = 0
                peaceCooldownUntil = now + 4
                cooldownUntil = now + 4
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
        let pointingDown = tip.y + 0.06 < wrist.y
        let open = hand.openScore >= 3 && (hand.pose == .openPalm || hand.pose == .unknown)
        if open, pointingDown, hand.poseProb >= 0.45 {
            if palmRestSince == nil { palmRestSince = now }
            if now - (palmRestSince ?? now) >= 0.60 {
                mode = .idle
                mustRearm = false
                lastAction = "Ruhe"
                onLog?("Handrücken 0,6 s → Idle, kein Not-Aus", .info, Int(hand.poseProb * 100))
                palmRestSince = nil
                system.endWindowDrag()
            } else {
                lastAction = "Ruhe …"
            }
        } else {
            palmRestSince = nil
        }
    }

    /// Zwei offene Hände vertikal — getrennt vom waagerechten Flick-Wischen.
    private func driveScroll(hands: [TrackedHand], now: TimeInterval) {
        guard !pinchHeld else {
            scrollAnchor = nil
            return
        }
        let open = hands.filter { $0.openScore >= 3 }
        guard open.count >= 2 else {
            scrollAnchor = nil
            return
        }
        let y = open.map(\.palm.y).reduce(0, +) / CGFloat(open.count)
        let unit = max(0.04, (open[0].palmWidth + open[1].palmWidth) / 2)
        guard let a = scrollAnchor else {
            scrollAnchor = (now, y)
            return
        }
        let dy = (y - a.y) / unit
        let dt = now - a.t
        guard dt >= 0.05, abs(dy) > 0.10 else { return }
        // unit 0,12 → ~18 Ticks wie bisher; große Palme (nah) scrollt feiner.
        let gain = 2.2 / max(0.06, unit)
        var ticks = Int32(max(-24, min(24, -dy * gain)))
        if profile.invertScroll { ticks = -ticks }
        guard ticks != 0 else { return }
        let conf = Float(open.map(\.poseProb).min() ?? 0)
        perform("Scroll", need: .input, confidence: conf) { system.scroll(ticks: ticks) }
        scrollAnchor = (now, y)
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
}

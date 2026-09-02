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

struct HandCursor {
    var id: String
    var side: String
    var isLeft: Bool
    var point: CGPoint
    var actor: Bool
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
    var handCursors: [HandCursor] = []
    var mousePaused = false
    var dwellEnabled = false
    var chromeKnobs: [ChromeKnob] = []
    var chromeHot = ""
    var chromeDwell: CGFloat = 0
    var keyboardVisible = false
    var keyboardHits: [AirKeyHit] = []
    var keyboardHover = ""
    var keyboardDwell: CGFloat = 0
    var hideConsoleWhenArmed = false
    var clapWake = false
    var peaceProgress: CGFloat = 0

    private var fistSince: TimeInterval?
    private var fistLostAt: TimeInterval?
    private var lastHandSeen: TimeInterval = 0
    private var palmSince: TimeInterval?
    private var lastPalmSeen: TimeInterval = 0
    private var killPalms: [CGPoint]?
    private var thumbsSince: TimeInterval?
    private var peaceSince: TimeInterval?
    private var pinchHeld = false
    private var pinchBecameDrag = false
    private var pinchBeganAt: TimeInterval = 0
    private var pinchTrail: [(t: TimeInterval, x: CGFloat, y: CGFloat)] = []
    private var pinchSpan0: CGFloat?
    private var pinchHandID: String?
    private var pinchLastHand: TrackedHand?
    private var pinchOriginCursor: CGPoint?
    private var pinchPalmMoved: CGFloat = 0
    private var pinchMissSince: TimeInterval?
    private var grabLogged = false
    private var lastGrabTry: TimeInterval = 0
    private var twoPinchSince: TimeInterval?
    private var lastScaleSign: CGFloat = 0
    private var swipeTrail: [(t: TimeInterval, x: CGFloat, y: CGFloat)] = []
    private var swipeHandID: String?
    private var cooldownUntil: TimeInterval = 0
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
    private var pointerSourceID: String = ""
    private var palmSlow: CGPoint?
    private var cursorTracks: [String: CGPoint] = [:]
    private var swipeGraceUntil: TimeInterval = 0
    private var swipeMuteUntil: TimeInterval = 0
    private var lastSwipeDx: CGFloat = 0
    private var lastSwipeAt: TimeInterval = 0
    private var armedQuietUntil: TimeInterval = 0
    private var cursorDidMove = false
    private var lastPalmWidth: CGFloat = 0.12
    private var scrollAnchor: (t: TimeInterval, y: CGFloat)?
    private var ringPinchSince: TimeInterval?
    private var dwellSince: TimeInterval?
    private var dwellPalm: CGPoint?
    private var chromeDwellSince: TimeInterval?
    private var chromeDwellKind: ChromeKnob.Kind?
    private var pointSince: TimeInterval?
    private var kbDwellID: String?
    private var kbDwellAt: TimeInterval?
    private var shiftLatch = false
    private var cmdLatch = false
    private var fistHideSince: TimeInterval?
    private var clapClosed = false
    private var clapSpan: (t: TimeInterval, span: CGFloat)?
    private var firstClapAt: TimeInterval = 0
    private var lastTwoHands: TimeInterval = 0
    private var lastClapFire: TimeInterval = 0
    private var sampleDt: TimeInterval = 0.04
    private var lastTickNow: TimeInterval = 0
    private var lastFusionEntropy: Double = 0
    private var tableSince: TimeInterval?
    private var tablePalms: [CGPoint]?
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
        killPalms = nil
        thumbsSince = nil
        peaceSince = nil
        pinchHeld = false
        pinchBecameDrag = false
        pinchBeganAt = 0
        pinchTrail.removeAll()
        pinchSpan0 = nil
        pinchHandID = nil
        pinchLastHand = nil
        pinchOriginCursor = nil
        pinchPalmMoved = 0
        pinchMissSince = nil
        grabLogged = false
        lastGrabTry = 0
        twoPinchSince = nil
        lastScaleSign = 0
        swipeTrail.removeAll()
        swipeHandID = nil
        swipeMuteUntil = 0
        lastSwipeDx = 0
        lastSwipeAt = 0
        cooldownUntil = 0
        lastArmToggle = 0
        lastLoggedPose = ""
        lastPoseLog = 0
        killLatched = false
        mustRearm = false
        armLockUntil = 0
        pointerOrigin = nil
        cursorSmooth = nil
        cursorTracks.removeAll()
        handCursors = []
        lastPalm = nil
        pointerHandID = nil
        pointerSourceID = ""
        palmSlow = nil
        swipeGraceUntil = 0
        armedQuietUntil = 0
        cursorDidMove = false
        mousePaused = false
        killFlash = false
        scrollAnchor = nil
        ringPinchSince = nil
        dwellSince = nil
        dwellPalm = nil
        system.endWindowDrag()
        cursor = nil
        twoHandSpan = nil
        trashHot = false
        dragging = false
        grabPhase = .none
        grabTargetName = ""
        chromeKnobs = []
        chromeHot = ""
        chromeDwell = 0
        chromeDwellSince = nil
        chromeDwellKind = nil
        pointSince = nil
        kbDwellID = nil
        kbDwellAt = nil
        fistHideSince = nil
        keyboardVisible = false
        keyboardHits = []
        keyboardHover = ""
        keyboardDwell = 0
        clapWake = false
        clapClosed = false
        clapSpan = nil
        firstClapAt = 0
        lastTwoHands = 0
        lastClapFire = 0
        lastAction = "Reset"
        peaceProgress = 0
        sampleDt = 0.04
        lastTickNow = 0
        lastFusionEntropy = 0
        tableSince = nil
        tablePalms = nil
    }

    func tick(hands incoming: [TrackedHand], now: TimeInterval) {
        sampleDt = GestureMath.sampleDt(now: now, last: lastTickNow)
        lastTickNow = now
        let hands = incoming.filter { $0.joints.count >= 8 && $0.meanConfidence >= 0.18 }
        if hands.isEmpty {
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
            killPalms = nil
            pinchTrail.removeAll()
            swipeTrail.removeAll()
            swipeHandID = nil
            if system.isDragging { system.endWindowDrag() }
            if pinchHeld {
                swipeMuteUntil = now + GestureMath.swipeMuteAfterPinch
            }
            pinchHeld = false
            pinchBecameDrag = false
            pinchHandID = nil
            pinchLastHand = nil
            pinchOriginCursor = nil
            pinchPalmMoved = 0
            pinchMissSince = nil
            twoPinchSince = nil
            lastScaleSign = 0
            twoHandSpan = nil
            scrollAnchor = nil
            ringPinchSince = nil
            dwellSince = nil
            dwellPalm = nil
            clapClosed = false
            clapSpan = nil
            firstClapAt = 0
            trashHot = false
            dragging = false
            grabPhase = .none
            grabTargetName = ""
            chromeKnobs = []
            chromeHot = ""
            chromeDwell = 0
            peaceProgress = 0
            if mode == .armed, lastHandSeen > 0, now - lastHandSeen >= GestureMath.deadMan {
                mode = .idle
                mustRearm = true
                lastAction = "Keine Hand — Idle"
                onLog?("\(Int(GestureMath.deadMan)) s ohne Hand → Idle", .info, nil)
            } else if mustRearm {
                mode = .idle
            }
            return
        }
        lastHandSeen = now
        lastPalmWidth = hands.map(\.palmWidth).max() ?? lastPalmWidth
        mousePaused = !system.allowsInjection && !system.fromInstallMedia

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
            let actor = preferred(hands)
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

        let primary = preferred(hands)
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

        if driveClap(hands: hands, now: now) {
            placeCursors(hands, actor: primary)
            handleArming(hands: hands, now: now)
            return
        }
        if handleKillSwitch(hands: hands, now: now) {
            placeCursors(hands, actor: primary)
            if !testMode, cursorDidMove, let p = cursor {
                system.moveCursor(to: p)
            }
            return
        }
        if driveTableIdle(hands: hands, now: now) {
            placeCursors(hands, actor: primary)
            return
        }
        handleArming(hands: hands, now: now)

        if !live {
            placeCursors(hands, actor: primary)
            grabPhase = (primary.pose == .pinch || primary.pose == .fist) ? .hold : .follow
            grabTargetName = focused?.appName ?? ""
            if hands.contains(where: { $0.pose == .pinch || $0.pose == .fist }) {
                lastAction = mustRearm ? "Nach Not-Aus: Faust oder 2× Klatschen" : "Faust oder 2× Klatschen → Scharf"
            }
            dragging = false
            return
        }
        if now < cooldownUntil || now < armedQuietUntil {
            placeCursors(hands, actor: primary)
            if !testMode, !system.isDragging, cursorDidMove, primary.pose != .fist, let p = cursor {
                system.moveCursor(to: p)
            }
            updateTrashHot()
            dragging = pinchHeld
            return
        }

        let scaling = handleTwoPinchScale(hands: hands, now: now)
        let actor = pinchActor(hands, primary: primary)
        lastFusionEntropy = actor.fusion?.entropy ?? lastFusionEntropy
        let freezePointer = pinchHeld && !pinchBecameDrag
        if !freezePointer {
            placeCursors(hands, actor: actor)
            if !testMode, !system.isDragging, cursorDidMove, actor.pose != .fist, let p = cursor {
                system.moveCursor(to: p)
            }
        }
        magnetChrome(now: now)
        updateTrashHot()
        if scaling {
            dragging = pinchHeld
            return
        }
        let right = driveRightClick(actor, now: now)
        if !right {
            driveGrab(actor, now: now)
        }
        driveSwipe(hands: hands, preferred: primary, now: now)
        driveScroll(hands: hands, now: now)
        drivePeace(preferred: primary, hands: hands, now: now)
        driveThumbs(actor, now: now)
        driveKeyboard(hands: hands, actor: actor, now: now)
        driveDwell(actor, now: now)
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

    func stopInputClutch() {
        system.stopClutch()
    }

    func recenterPointer() {
        lastPalm = nil
        palmSlow = nil
        pointerHandID = nil
        pointerSourceID = ""
        cursorSmooth = nil
        cursorTracks.removeAll()
    }

    private func releasePointer() {
        cursor = nil
        lastPalm = nil
        palmSlow = nil
        pointerHandID = nil
        pointerSourceID = ""
        cursorSmooth = nil
        cursorTracks.removeAll()
        handCursors = []
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
        let profile = AppInjectProfile.of(bundleId: focused?.bundleId ?? "")
        if systemAction, !testMode, !profile.allows(name) {
            lastAction = "\(name) — \(profile.titleDE)"
            onLog?("\(name) — Profil \(profile.titleDE)", .blocked, Int(confidence * 100))
            return
        }
        let floor = Float(GestureMath.entropyActionFloor(entropy: lastFusionEntropy))
        if systemAction, confidence < floor, !testMode {
            lastAction = "\(name) — unsicher"
            onLog?(String(format: "%@ — Pose < %.0f %%", name, floor * 100), .blocked, Int(confidence * 100))
            return
        }
        let conf = Int(confidence * 100)
        if testMode {
            lastAction = "Test: \(name)"
            onLog?("\(name) — Testmodus, System unberührt", .blocked, conf)
            return
        }
        let r = body()
        if r.skipped {
            return
        }
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
            if span > GestureMath.clapOpen {
                clapClosed = false
            }
            return false
        }
        guard let prev = clapSpan else { return false }
        guard GestureMath.isClapPulse(prevSpan: prev.span, prevT: prev.t, span: span, now: now) else {
            if firstClapAt > 0, now - firstClapAt > GestureMath.clapMaxGap {
                firstClapAt = 0
            }
            return false
        }
        clapClosed = true
        if firstClapAt > 0, GestureMath.isDoubleClap(first: firstClapAt, second: now) {
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

    @discardableResult
    private func handleKillSwitch(hands: [TrackedHand], now: TimeInterval) -> Bool {
        if firstClapAt > 0, now - firstClapAt < GestureMath.clapMaxGap {
            palmSince = nil
            killPalms = nil
            return false
        }
        if pinchHeld || twoPinchSince != nil {
            palmSince = nil
            killPalms = nil
            if killLatched {
                lastAction = "Not-Aus"
                mode = .idle
                return true
            }
            return false
        }
        let open = hands.filter { $0.pose == .openPalm && $0.openScore >= 4 }
        if open.count >= 2 {
            let unit = max(0.04, (open[0].palmWidth + open[1].palmWidth) / 2)
            let span = space.dist(open[0].palm, open[1].palm) / unit
            if !GestureMath.killSwitchCandidate(
                openPalms: open.count,
                spanHW: span,
                pinchHeld: false,
                twoPinch: false
            ) {
                palmSince = nil
                killPalms = nil
                if !killLatched { return false }
            }
            if killLatched {
                lastAction = "Not-Aus"
                mode = .idle
                return true
            }
            if let prev = killPalms, prev.count >= 2 {
                let moved = max(
                    space.dist(open[0].palm, prev[0]) / unit,
                    space.dist(open[1].palm, prev[1]) / unit
                )
                if moved > GestureMath.killPalmStill {
                    palmSince = now
                }
            }
            killPalms = [open[0].palm, open[1].palm]
            if palmSince == nil { palmSince = now }
            lastPalmSeen = now
            let held = now - (palmSince ?? now)
            if held >= GestureMath.killHold {
                mode = .idle
                mustRearm = true
                killLatched = true
                armLockUntil = now + 1.6
                pinchHeld = false
                pinchBecameDrag = false
                fistSince = nil
                system.endWindowDrag()
                lastAction = "Not-Aus"
                onLog?("Beide Hände offen und still → Not-Aus. Bleibt Idle, bis Faust hält oder 2× klatschen.", .info, nil)
                killFlash = true
                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    await MainActor.run { self?.killFlash = false }
                }
                cooldownUntil = now + 0.8
                return true
            }
            lastAction = "Not-Aus halten"
            return false
        }
        if now - lastPalmSeen < GestureMath.killGrace, palmSince != nil {
            return false
        }
        palmSince = nil
        killPalms = nil
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

    @discardableResult
    private func driveTableIdle(hands: [TrackedHand], now: TimeInterval) -> Bool {
        guard mode == .armed, !testMode else {
            tableSince = nil
            tablePalms = nil
            return false
        }
        let palms = hands.map(\.palm)
        let still: CGFloat = {
            guard let prev = tablePalms, prev.count == palms.count, prev.count == hands.count else { return 0 }
            var m: CGFloat = 0
            for i in palms.indices {
                m = max(m, space.dist(palms[i], prev[i]) / max(0.04, hands[i].palmWidth))
            }
            return m
        }()
        tablePalms = palms
        if GestureMath.tableIdleCandidate(palmsY: palms.map(\.y), stillHW: still, pinchHeld: pinchHeld) {
            if tableSince == nil { tableSince = now }
            if now - (tableSince ?? now) >= GestureMath.tableIdleHold {
                tableSince = nil
                tablePalms = nil
                mode = .idle
                mustRearm = true
                lastAction = "Hände auf dem Tisch — Idle"
                onLog?("Hände unten still → Idle", .info, nil)
                if system.isDragging { system.endWindowDrag() }
                pinchHeld = false
                pinchBecameDrag = false
                pinchHandID = nil
                pinchLastHand = nil
                pinchOriginCursor = nil
                pinchPalmMoved = 0
                pinchMissSince = nil
                pinchTrail.removeAll()
                return true
            }
        } else {
            tableSince = nil
        }
        return false
    }

    private func preferred(_ hands: [TrackedHand]) -> TrackedHand {
        let left = hands.first(where: { $0.chirality == .left })
        let right = hands.first(where: { $0.chirality == .right })
        let id = GestureMath.preferredID(
            locked: pointerHandID,
            liveIDs: hands.map(\.id),
            leftID: left?.id,
            rightID: right?.id,
            leftHanded: leftHanded
        )
        if let id, let same = hands.first(where: { $0.id == id }) {
            return same
        }
        return hands.max { a, b in
            (a.joints.values.map(\.confidence).max() ?? 0) < (b.joints.values.map(\.confidence).max() ?? 0)
        } ?? hands[0]
    }

    private func pinchActor(_ hands: [TrackedHand], primary: TrackedHand) -> TrackedHand {
        if pinchHeld, let id = pinchHandID {
            if let same = hands.first(where: { $0.id == id }) {
                pinchMissSince = nil
                pinchLastHand = same
                return same
            }
            if pinchMissSince == nil { pinchMissSince = CACurrentMediaTime() }
            // Freeze. Nie die andere Hand — `primary` wäre der Steuerhand-Diebstahl.
            if let last = pinchLastHand { return last }
            return hands.first(where: { $0.id == id }) ?? primary
        }
        pinchLastHand = nil
        if let pinching = hands.filter({ $0.pose == .pinch || $0.pinchClosedness > 0.55 }).min(by: { $0.pinchRatio < $1.pinchRatio }) {
            return pinching
        }
        if let fist = hands.first(where: { $0.pose == .fist }) {
            return fist
        }
        return primary
    }

    private func mappedPoint(_ hand: TrackedHand, isActor: Bool) -> CGPoint {
        let palm = hand.palm
        let from = cursorTracks[hand.id]
        if let map = spaceMap, map.isReady {
            let q = map.apply(palm)
            let prev = from ?? q
            let dist = hypot(q.x - prev.x, q.y - prev.y)
            let a = min(0.93, 0.58 + dist / 55)
            let s = CGPoint(x: a * q.x + (1 - a) * prev.x, y: a * q.y + (1 - a) * prev.y)
            cursorTracks[hand.id] = s
            if isActor {
                cursorDidMove = dist > 1.4
                cursorSmooth = s
            }
            return s
        }

        if !isActor {
            let q = SpaceMap.linear(palm)
            let prev = from ?? q
            let a: CGFloat = 0.8
            let s = CGPoint(x: a * q.x + (1 - a) * prev.x, y: a * q.y + (1 - a) * prev.y)
            cursorTracks[hand.id] = s
            return s
        }

        let prevPalm = lastPalm ?? palm
        lastPalm = palm
        let dt = sampleDt
        let slowA = min(0.28, GestureMath.palmHighpassAlpha(dt: dt))
        let oldSlow = palmSlow ?? palm
        let newSlow = CGPoint(
            x: oldSlow.x + slowA * (palm.x - oldSlow.x),
            y: oldSlow.y + slowA * (palm.y - oldSlow.y)
        )
        if isActor { palmSlow = newSlow }
        var dx = (palm.x - newSlow.x) - (prevPalm.x - oldSlow.x)
        var dy = (palm.y - newSlow.y) - (prevPalm.y - oldSlow.y)
        let dead = GestureMath.palmDead * 0.55
        let step = GestureMath.deadzone2D(dx: dx, dy: dy, dead: dead)
        dx = step.x
        dy = step.y
        let seed = from ?? ScreenGeometry.clampQuartz(NSEvent.mouseLocation.screenFlipped)
        let stepped = ScreenGeometry.stepCursor(from: seed, dPalm: CGPoint(x: dx, y: dy), gain: pointerGain)
        let a: CGFloat = 0.86
        let s = CGPoint(x: a * stepped.x + (1 - a) * seed.x, y: a * stepped.y + (1 - a) * seed.y)
        cursorTracks[hand.id] = s
        if isActor {
            cursorDidMove = hypot(dx, dy) > dead
            cursorSmooth = s
        }
        return s
    }

    private func placeCursors(_ hands: [TrackedHand], actor: TrackedHand) {
        let live = Set(hands.map(\.id))
        cursorTracks = cursorTracks.filter { live.contains($0.key) }
        var out: [HandCursor] = []
        for h in hands {
            let p = mappedPoint(h, isActor: h.id == actor.id)
            out.append(HandCursor(
                id: h.id,
                side: h.sideDE,
                isLeft: h.chirality == .left,
                point: p,
                actor: h.id == actor.id
            ))
        }
        handCursors = out
        if let a = out.first(where: { $0.actor }) ?? out.first {
            cursor = a.point
            cursorHand = a.side
        }
        pointerHandID = actor.id
        if !actor.sourceID.isEmpty { pointerSourceID = actor.sourceID }
    }

    @discardableResult
    private func handleTwoPinchScale(hands: [TrackedHand], now: TimeInterval) -> Bool {
        let pinches = hands.filter {
            $0.pose == .pinch || $0.pinchClosed || $0.pinchClosedness > GestureMath.twoPinchClosed
        }
        guard pinches.count >= 2 else {
            if twoPinchSince != nil {
                swipeMuteUntil = now + GestureMath.swipeMuteAfterPinch
                cooldownUntil = max(cooldownUntil, now + 0.25)
            }
            twoHandSpan = nil
            twoPinchSince = nil
            lastScaleSign = 0
            return false
        }
        if twoPinchSince == nil { twoPinchSince = now }
        if pinchHeld {
            pinchHeld = false
            pinchBecameDrag = false
            pinchHandID = nil
            pinchLastHand = nil
            pinchOriginCursor = nil
            pinchPalmMoved = 0
            pinchTrail.removeAll()
            if system.isDragging { system.endWindowDrag() }
        }
        // Tick belegen, sonst stiehlt Greifen die erste Pinzette.
        guard now - (twoPinchSince ?? now) >= GestureMath.twoPinchConfirm else { return true }
        let unit = max(0.04, (pinches[0].palmWidth + pinches[1].palmWidth) / 2)
        let span = space.dist(pinches[0].palm, pinches[1].palm) / unit
        if let old = twoHandSpan, now >= cooldownUntil {
            let d = span - old
            let reversing = lastScaleSign != 0 && d * lastScaleSign < 0
            let need = GestureMath.twoPinchScaleNeed * (reversing ? GestureMath.twoPinchReverseMul : 1)
            if abs(d) > need {
                let conf = Float(pinches.map(\.poseProb).min() ?? 0)
                perform("Skalieren", confidence: conf) {
                    system.resizeFocused(scale: d > 0 ? 1.05 : 0.95)
                }
                lastScaleSign = d > 0 ? 1 : -1
                twoHandSpan = span
                cooldownUntil = now + 0.28
                return true
            }
        }
        if twoHandSpan == nil {
            twoHandSpan = span
        }
        return true
    }

    private func magnetChrome(now: TimeInterval) {
        guard !system.isDragging else {
            chromeKnobs = []
            chromeHot = ""
            chromeDwell = 0
            chromeDwellSince = nil
            return
        }
        guard let c = cursor else { return }
        if !pinchHeld {
            if let f = focused {
                let b = f.quartzBounds
                let band = CGRect(x: b.minX - 30, y: b.minY - 24, width: min(b.width, 430), height: 140)
                if !band.contains(c) {
                    if !chromeKnobs.isEmpty {
                        chromeKnobs = []
                        chromeHot = ""
                        chromeDwell = 0
                        chromeDwellSince = nil
                        chromeDwellKind = nil
                    }
                    return
                }
            }
        }
        let knobs = system.chromeKnobs(at: c)
        chromeKnobs = knobs
        guard !knobs.isEmpty else {
            chromeHot = ""
            chromeDwell = 0
            chromeDwellSince = nil
            chromeDwellKind = nil
            return
        }
        let near = knobs.contains {
            hypot(c.x - $0.center.x, c.y - $0.center.y) < GestureMath.chromeLoupe
        }
        guard near else {
            chromeHot = ""
            chromeDwell = 0
            chromeDwellSince = nil
            chromeDwellKind = nil
            return
        }
        guard let hot = knobs.min(by: {
            hypot($0.center.x - c.x, $0.center.y - c.y) < hypot($1.center.x - c.x, $1.center.y - c.y)
        }), hypot(hot.center.x - c.x, hot.center.y - c.y) < GestureMath.chromeMagnet else {
            chromeHot = ""
            chromeDwell = 0
            chromeDwellSince = nil
            chromeDwellKind = nil
            return
        }
        chromeHot = hot.labelDE
        if pinchHeld, !pinchBecameDrag {
            cursor = hot.center
            if !testMode { system.moveCursor(to: hot.center) }
        }
        if chromeDwellKind != hot.kind {
            chromeDwellKind = hot.kind
            chromeDwellSince = now
        }
        let held = now - (chromeDwellSince ?? now)
        chromeDwell = CGFloat(min(1, held / GestureMath.chromeDwellHold))
        if held >= GestureMath.chromeDwellHold {
            fireChrome(hot)
            chromeDwellSince = nil
            chromeDwellKind = nil
            chromeDwell = 0
            cooldownUntil = now + 0.75
        }
    }

    private func fireChrome(_ knob: ChromeKnob) {
        switch knob.kind {
        case .close:
            perform("Schließen", confidence: 0.9) { system.closeFocused() }
        case .min:
            perform("Minimieren", confidence: 0.9) { system.minimizeFocused() }
        case .zoom:
            perform("Vollbild", confidence: 0.9) { system.zoomFocused() }
        }
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
        if keyboardVisible, let c = cursor, AirLayout.hit(at: c, keys: keyboardHits) != nil {
            return
        }
        if now < armedQuietUntil, !pinchHeld { return }
        if pinchHeld, let id = pinchHandID, hand.id != id {
            // Andere Hand ist nicht die Pinzette — kein Klick/Loslassen.
            if pinchMissSince == nil { pinchMissSince = now }
            if now - (pinchMissSince ?? now) > GestureMath.pinchLockMiss {
                pinchHeld = false
                pinchBecameDrag = false
                pinchHandID = nil
                pinchLastHand = nil
                pinchOriginCursor = nil
                pinchPalmMoved = 0
                pinchMissSince = nil
                pinchTrail.removeAll()
                pinchSpan0 = nil
                grabLogged = false
                if !testMode { system.endWindowDrag() }
                swipeMuteUntil = now + GestureMath.swipeMuteAfterPinch
            }
            return
        }
        if pinchHeld, let miss = pinchMissSince, now - miss > GestureMath.pinchLockMiss {
            // Gesperrte Hand weg — nicht mit der anderen weitermachen.
            pinchHeld = false
            pinchBecameDrag = false
            pinchHandID = nil
            pinchLastHand = nil
            pinchOriginCursor = nil
            pinchPalmMoved = 0
            pinchMissSince = nil
            pinchTrail.removeAll()
            pinchSpan0 = nil
            grabLogged = false
            if !testMode { system.endWindowDrag() }
            swipeMuteUntil = now + GestureMath.swipeMuteAfterPinch
            return
        }
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
            pinchHandID = hand.id
            pinchLastHand = hand
            pinchOriginCursor = cursor
            pinchPalmMoved = 0
            pinchMissSince = nil
            pinchTrail = [(now, hand.palm.x, hand.palm.y)]
            pinchSpan0 = hand.palm.y
            grabLogged = false
            lastAction = testMode ? "Test: Halten" : "Halten"
        } else if isGrab && pinchHeld {
            pinchTrail.append((now, hand.palm.x, hand.palm.y))
            pinchTrail.removeAll { now - $0.t > 0.5 }
            if let first = pinchTrail.first {
                let moved = space.dist(hand.palm, CGPoint(x: first.x, y: first.y)) / max(0.04, hand.palmWidth)
                pinchPalmMoved = max(pinchPalmMoved, moved)
                let cursorPx: CGFloat = {
                    guard let a = pinchOriginCursor, let b = cursor else { return 0 }
                    return hypot(a.x - b.x, a.y - b.y)
                }()
                if GestureMath.isDrag(palmMovedHW: moved, cursorMovedPx: cursorPx) {
                    if chromeHot.isEmpty || cursorPx >= 52 {
                        pinchBecameDrag = true
                    }
                }
            }
            if pinchBecameDrag, !system.isDragging, !testMode, now - lastGrabTry > 0.35 {
                lastGrabTry = now
                let profile = AppInjectProfile.of(bundleId: focused?.bundleId ?? "")
                if !profile.allowsWindowDrag {
                    lastAction = "Greifen — \(profile.titleDE)"
                    onLog?("Greifen — Profil \(profile.titleDE)", .blocked, Int(hand.poseProb * 100))
                    grabLogged = true
                } else {
                    let at = cursor ?? SpaceMap.linear(hand.palm)
                    let r = system.beginWindowDrag(at: at)
                    if r.ok {
                        lastAction = "Greifen"
                        onLog?("Greifen · \(r.detail)", .executed, Int(hand.poseProb * 100))
                        grabLogged = true
                    } else if !grabLogged {
                        grabLogged = true
                        lastAction = "Greifen fehlgeschlagen"
                        onLog?("Greifen — NICHT AUSGEFÜHRT: \(r.detail)", .failed, Int(hand.poseProb * 100))
                        if r.detail.contains("Bedienung") || !AXIsProcessTrusted() {
                            Permissions.demand(.accessibility)
                        }
                    }
                }
            }
            if !testMode, system.isDragging {
                let at = cursor ?? SpaceMap.linear(hand.palm)
                system.updateWindowDrag(to: at)
                lastAction = trashHot ? "Papierkorb" : "Ziehen"
            } else if testMode, pinchBecameDrag {
                lastAction = trashHot ? "Test: Papierkorb" : "Test: Ziehen"
            }
            if let y0 = pinchSpan0, !system.isDragging, GestureMath.pullTowardSelf(startY: y0, nowY: hand.palm.y) {
                perform("Heranziehen", confidence: Float(hand.poseProb)) { system.snapFocused(.fill, at: cursor) }
                pinchSpan0 = hand.palm.y
                cooldownUntil = now + 0.5
            }
        } else if !isGrab && pinchHeld {
            let cursorPx: CGFloat = {
                guard let a = pinchOriginCursor, let b = cursor else { return 0 }
                return hypot(a.x - b.x, a.y - b.y)
            }()
            let wasDrag = pinchBecameDrag
            let flung = resolveFling(
                now: now,
                confidence: Float(hand.poseProb),
                palmWidth: hand.palmWidth,
                afterDrag: wasDrag
            )
            let held = now - pinchBeganAt
            let palmMoved = pinchPalmMoved
            pinchHeld = false
            pinchBecameDrag = false
            pinchHandID = nil
            pinchLastHand = nil
            pinchOriginCursor = nil
            pinchPalmMoved = 0
            pinchMissSince = nil
            pinchTrail.removeAll()
            pinchSpan0 = nil
            grabLogged = false
            trashHot = false
            let hotName = chromeHot
            let knobsNow = chromeKnobs
            if !testMode { system.endWindowDrag() }
            swipeMuteUntil = now + GestureMath.swipeMuteAfterPinch
            if flung {
                cooldownUntil = now + 0.4
                chromeKnobs = []
                chromeHot = ""
                return
            }
            if wasDrag {
                lastAction = testMode ? "Test: Loslassen" : "Loslassen"
                onLog?("Loslassen", testMode ? .blocked : .executed, Int(hand.poseProb * 100))
            } else if let knob = knobsNow.first(where: { $0.labelDE == hotName }) {
                fireChrome(knob)
            } else if GestureMath.isClick(held: held, palmMovedHW: palmMoved, cursorMovedPx: cursorPx) {
                perform("Klick", need: .input, confidence: Float(max(hand.poseProb, hand.pinchClosedness))) { system.click() }
            } else if held < GestureMath.pinchClickMinHold {
                lastAction = "zu kurz"
            } else {
                lastAction = "gehalten — kein Zug"
                onLog?("Pinzette gehalten, keine Aktion", .info, Int(hand.poseProb * 100))
            }
            cooldownUntil = now + 0.12
        }
    }

    private func resolveFling(
        now _: TimeInterval,
        confidence: Float,
        palmWidth: CGFloat,
        afterDrag: Bool
    ) -> Bool {
        if trashHot {
            perform("Wegwerfen", confidence: confidence) { system.throwAway(finder: focused?.isFinder == true) }
            return true
        }
        guard pinchTrail.count >= 2 else { return false }
        let screenUV: CGPoint? = {
            guard spaceMap?.isReady == true, let c = cursor else { return nil }
            return ScreenGeometry.unitInUnion(quartz: c)
        }()
        let kind = GestureMath.flingFromTrail(
            pinchTrail,
            palmWidth: palmWidth,
            aspect: space.aspect,
            afterDrag: afterDrag,
            screenUV: screenUV,
            windowSec: GestureMath.flingWindowLen(medianDt: sampleDt)
        )
        guard kind != .none else { return false }
        onLog?("Werfen erkannt", .recognized, Int(confidence * 100))
        switch kind {
        case .throwUp:
            perform("Wegwerfen", confidence: confidence) { system.throwAway(finder: focused?.isFinder == true) }
        case .minimize:
            perform("Minimieren", confidence: confidence) { system.minimizeFocused() }
        case .dockLeft:
            perform("Links andocken", confidence: confidence) { system.snapFocused(.left, at: cursor) }
        case .dockRight:
            perform("Rechts andocken", confidence: confidence) { system.snapFocused(.right, at: cursor) }
        case .none:
            return false
        }
        return true
    }

    private func driveSwipe(hands: [TrackedHand], preferred: TrackedHand, now: TimeInterval) {
        guard !pinchHeld, !keyboardVisible else {
            swipeTrail.removeAll()
            swipeHandID = nil
            return
        }
        if now < swipeMuteUntil {
            swipeTrail.removeAll()
            return
        }
        let open = hands.filter { $0.pose == .openPalm || $0.openScore >= GestureMath.swipeOpenNeed }
        let hand = open.first(where: { $0.id == preferred.id })
            ?? open.max(by: { $0.poseProb < $1.poseProb })
        guard let hand else {
            if now < swipeGraceUntil, let id = swipeHandID,
               let same = hands.first(where: { $0.id == id }),
               same.pose != .fist
            {
                return
            }
            swipeTrail.removeAll()
            swipeHandID = nil
            return
        }
        if swipeHandID != hand.id {
            swipeTrail.removeAll()
            swipeHandID = hand.id
        }
        swipeGraceUntil = now + 0.40
        swipeTrail.append((now, hand.palm.x, hand.palm.y))
        swipeTrail.removeAll { now - $0.t > 0.50 }
        guard let first = swipeTrail.first, swipeTrail.count >= 2 else { return }
        let unit = max(0.04, hand.palmWidth)
        let delta = space.vec(CGPoint(x: first.x, y: first.y), hand.palm)
        let dx = delta.x / unit
        let dy = delta.y / unit
        let dt = now - first.t
        let speed = hypot(dx, dy) / max(dt, 0.001)
        guard dt >= GestureMath.swipeMinDt, dt <= GestureMath.swipeMaxDt,
              abs(dx) > GestureMath.swipeMinDx,
              abs(dx) > abs(dy) * GestureMath.swipeAxis,
              speed > GestureMath.swipeMinSpeed else { return }
        if GestureMath.swipeBlocked(
            now: now,
            muteUntil: swipeMuteUntil,
            dx: dx,
            lastDx: lastSwipeDx,
            lastAt: lastSwipeAt
        ) {
            swipeTrail.removeAll()
            return
        }
        onLog?("Wischen erkannt", .recognized, Int(hand.poseProb * 100))
        let forward = dx < 0
        let name = forward ? "Nächste App" : "Vorherige App"
        perform(name, need: .none, confidence: Float(hand.poseProb)) { system.switchApp(forward: forward) }
        lastSwipeDx = dx
        lastSwipeAt = now
        swipeTrail.removeAll()
        swipeHandID = nil
        cooldownUntil = now + 0.40
    }

    private func drivePeace(preferred: TrackedHand, hands: [TrackedHand], now: TimeInterval) {
        let hand = preferred
        let otherOpen = hands.contains { $0.id != hand.id && $0.openScore >= 3 }
        // Öffnen geht durch Zwei-Finger. Peace nur allein, nicht beim Aufmachen.
        if otherOpen || hand.openScore >= 3 || hand.pose != .peace || hand.poseProb < 0.50 {
            peaceSince = nil
            peaceProgress = 0
            return
        }
        if peaceSince == nil { peaceSince = now }
        let held = now - (peaceSince ?? now)
        peaceProgress = CGFloat(min(1, held / GestureMath.peaceHold))
        if held > GestureMath.peaceHold {
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
            cooldownUntil = now + 4
        }
    }

    private func driveThumbs(_ hand: TrackedHand, now: TimeInterval) {
        if hand.pose == .thumbsUp, hand.poseProb >= 0.50 {
            if thumbsSince == nil { thumbsSince = now }
            if now - (thumbsSince ?? now) > GestureMath.thumbsHold {
                perform("Hervorholen", need: .none, confidence: Float(hand.poseProb)) { system.unhideFront() }
                thumbsSince = nil
                cooldownUntil = now + 3
            }
        } else {
            thumbsSince = nil
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
        let ticks = Int32(max(-24, min(24, -dy * 18)))
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

    func toggleKeyboard() {
        if keyboardVisible {
            hideKeyboard()
        } else {
            showKeyboard()
        }
    }

    private func showKeyboard() {
        keyboardVisible = true
        lastAction = "Tastatur in der Luft"
        onLog?("Luft-Tastatur an — Zeigen, Pinzette tippt. Faust schließt.", .info, nil)
    }

    private func hideKeyboard() {
        keyboardVisible = false
        keyboardHits = []
        keyboardHover = ""
        keyboardDwell = 0
        shiftLatch = false
        cmdLatch = false
        lastAction = "Tastatur aus"
        onLog?("Luft-Tastatur aus", .info, nil)
    }

    private func driveKeyboard(hands _: [TrackedHand], actor: TrackedHand, now: TimeInterval) {
        let pointing = actor.pose == .point && actor.poseProb >= 0.45
        if !keyboardVisible {
            let v = cursor.map { ScreenGeometry.unitInUnion(quartz: $0).y }
            if pointing, GestureMath.airKeyboardSummon(v: v ?? -1) {
                if pointSince == nil { pointSince = now }
                if now - (pointSince ?? now) >= GestureMath.airKeyboardPointHold {
                    showKeyboard()
                    pointSince = nil
                } else {
                    lastAction = "Tastatur …"
                }
            } else {
                pointSince = nil
            }
            return
        }
        let loc = cursor ?? actorMappedFallback
        let screen = ScreenGeometry.screenContaining(quartz: loc) ?? NSScreen.main
        let q = screen.map { ScreenGeometry.quartzRect(fromCocoa: $0.frame) } ?? .zero
        keyboardHits = AirLayout.hits(inQuartz: q)
        if actor.pose == .fist, actor.poseProb >= 0.50 {
            if fistHideSince == nil { fistHideSince = now }
            if now - (fistHideSince ?? now) >= 0.50 {
                hideKeyboard()
                fistHideSince = nil
                return
            }
        } else {
            fistHideSince = nil
        }
        guard let key = AirLayout.hit(at: loc, keys: keyboardHits) else {
            keyboardHover = ""
            keyboardDwell = 0
            kbDwellID = nil
            return
        }
        keyboardHover = key.id
        if kbDwellID != key.id {
            kbDwellID = key.id
            kbDwellAt = now
        }
        let held = now - (kbDwellAt ?? now)
        keyboardDwell = CGFloat(min(1, held / 0.32))
        let pinching = actor.pinchClosed || actor.pose == .pinch || actor.pinchClosedness > 0.52
        if pinching, held >= 0.05 {
            typeAir(key)
            kbDwellID = nil
            kbDwellAt = now + 8
            cooldownUntil = now + 0.16
        } else if !pinching, held >= 0.32 {
            typeAir(key)
            kbDwellAt = now
            cooldownUntil = now + 0.16
        }
    }

    private var actorMappedFallback: CGPoint {
        cursor ?? ScreenGeometry.clampQuartz(NSEvent.mouseLocation.screenFlipped)
    }

    private func typeAir(_ key: AirKeyHit) {
        switch key.kind {
        case .close:
            hideKeyboard()
        case .shift:
            shiftLatch.toggle()
            lastAction = shiftLatch ? "Umschalt an" : "Umschalt aus"
        case .cmd:
            cmdLatch.toggle()
            lastAction = cmdLatch ? "Befehl an" : "Befehl aus"
        case .delete:
            perform("Löschen", need: .input, confidence: 0.9) { system.typeKey(0x33) }
        case .space:
            perform("Leer", need: .input, confidence: 0.9) { system.typeKey(0x31) }
        case .enter:
            perform("Zeile", need: .input, confidence: 0.9) { system.typeKey(0x24) }
        case .char:
            var flags: CGEventFlags = []
            if shiftLatch { flags.insert(.maskShift) }
            if cmdLatch { flags.insert(.maskCommand) }
            perform("Taste \(key.label)", need: .input, confidence: 0.9) {
                system.typeKey(CGKeyCode(key.code), flags: flags)
            }
            shiftLatch = false
            cmdLatch = false
        }
        keyboardDwell = 0
    }
}

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

@MainActor
final class GestureEngine {
    var mode: EngineMode = .idle
    var lastAction = "—"
    var cursor: CGPoint?
    var twoHandSpan: CGFloat?
    var testMode = false
    var protocolMode = true
    var leftHanded = true
    var pointerGain: CGFloat = 1.6
    var trashHot = false
    var killFlash = false
    var dragging = false
    var cursorHand: String = "—"

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
    private var twoPinchSince: TimeInterval?
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
    private var swipeGraceUntil: TimeInterval = 0
    private var cursorDidMove = false
    private let system = SystemControl()
    var onLog: ((String, ProtocolKind, Int?) -> Void)?
    var focused: FocusedTarget?

    func reset() {
        mode = .idle
        fistSince = nil
        fistLostAt = nil
        palmSince = nil
        pinchHeld = false
        pinchBecameDrag = false
        twoPinchSince = nil
        swipeTrail.removeAll()
        swipeHandID = nil
        pinchTrail.removeAll()
        system.endWindowDrag()
        cursor = nil
        twoHandSpan = nil
        trashHot = false
        dragging = false
        mustRearm = false
        pointerOrigin = nil
        cursorSmooth = nil
        lastPalm = nil
        pointerHandID = nil
        lastAction = "Reset"
    }

    func tick(hands incoming: [TrackedHand], now: TimeInterval) {
        let hands = incoming.filter { $0.joints.count >= 8 && $0.meanConfidence >= 0.18 }
        if hands.isEmpty {
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
            trashHot = false
            dragging = false
            if mustRearm {
                mode = .idle
                lastAction = "Not-Aus"
            }
            return
        }
        lastHandSeen = now

        let primary = preferred(hands)
        let live = mode == .armed || testMode
        if !live {
            releasePointer()
        }

        if protocolMode, now - lastPoseLog > 0.28 {
            let key = hands.map { "\($0.sideDE):\($0.pose.rawValue)" }.joined(separator: ",")
            if key != lastLoggedPose {
                lastLoggedPose = key
                lastPoseLog = now
                let text = hands.map {
                    String(format: "%@ %@ %.0f%%", $0.sideDE, $0.pose.labelDE, $0.meanConfidence * 100)
                }.joined(separator: " · ")
                let conf = Int((hands.map(\.meanConfidence).max() ?? 0) * 100)
                onLog?("Geste \(text)", .recognized, conf)
            }
        }

        if handleKillSwitch(hands: hands, now: now) {
            return
        }
        handleArming(hands: hands, now: now)

        if !live {
            if hands.contains(where: { $0.pose == .pinch || $0.pose == .fist }) {
                lastAction = mustRearm ? "Nach Not-Aus: Faust halten" : "Faust halten → Scharf"
            }
            dragging = false
            return
        }
        if now < cooldownUntil { return }

        if handleTwoPinchScale(hands: hands, now: now) {
            return
        }

        let actor = pinchActor(hands, primary: primary)
        let freezePointer = pinchHeld && !pinchBecameDrag
        if !freezePointer {
            placeCursor(actor)
            if !testMode, cursorDidMove, actor.pose != .fist, let p = cursor {
                system.moveCursor(to: p)
            }
        }
        updateTrashHot()
        driveGrab(actor, now: now)
        driveSwipe(hands: hands, now: now)
        drivePeace(actor, now: now)
        driveThumbs(actor, now: now)
        dragging = pinchHeld
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
        _ body: () -> ActionResult
    ) {
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
        let open = hands.filter(\.isOpenEnough)
        if open.count >= 2 {
            if killLatched {
                lastAction = "Not-Aus"
                mode = .idle
                return true
            }
            if palmSince == nil { palmSince = now }
            lastPalmSeen = now
            let held = now - (palmSince ?? now)
            if held >= 0.22 {
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
            lastAction = "Not-Aus halten"
            return true
        }
        if now - lastPalmSeen < 0.28, palmSince != nil {
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
                onLog?("Faust → Scharf", .executed, Int((hands.map(\.meanConfidence).max() ?? 0) * 100))
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

    private func preferred(_ hands: [TrackedHand]) -> TrackedHand {
        if leftHanded, let left = hands.first(where: { $0.chirality == .left }) {
            return left
        }
        if !leftHanded, let right = hands.first(where: { $0.chirality == .right }) {
            return right
        }
        return hands.max { a, b in
            (a.joints.values.map(\.confidence).max() ?? 0) < (b.joints.values.map(\.confidence).max() ?? 0)
        } ?? hands[0]
    }

    private func pinchActor(_ hands: [TrackedHand], primary: TrackedHand) -> TrackedHand {
        if pinchHeld {
            return hands.min { a, b in a.pinchRatio < b.pinchRatio } ?? primary
        }
        if let pinching = hands.filter({ $0.pose == .pinch }).min(by: { $0.pinchRatio < $1.pinchRatio }) {
            return pinching
        }
        if let fist = hands.first(where: { $0.pose == .fist }) {
            return fist
        }
        return primary
    }

    private func actorMapped(_ hand: TrackedHand) -> CGPoint {
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
        let dead: CGFloat = 0.006
        if abs(dx) < dead { dx = 0 }
        if abs(dy) < dead { dy = 0 }
        if dx == 0 && dy == 0 {
            return cursorSmooth ?? ScreenGeometry.clampQuartz(NSEvent.mouseLocation.screenFlipped)
        }
        cursorDidMove = true
        let from = cursorSmooth ?? ScreenGeometry.clampQuartz(NSEvent.mouseLocation.screenFlipped)
        let stepped = ScreenGeometry.stepCursor(from: from, dPalm: CGPoint(x: dx, y: dy), gain: pointerGain)
        let a: CGFloat = 0.62
        let s = CGPoint(x: a * stepped.x + (1 - a) * from.x, y: a * stepped.y + (1 - a) * from.y)
        cursorSmooth = s
        return s
    }

    private func placeCursor(_ hand: TrackedHand) {
        cursor = actorMapped(hand)
        cursorHand = hand.sideDE
    }

    @discardableResult
    private func handleTwoPinchScale(hands: [TrackedHand], now: TimeInterval) -> Bool {
        let pinches = hands.filter { $0.pose == .pinch }
        guard pinches.count >= 2 else {
            twoHandSpan = nil
            twoPinchSince = nil
            return false
        }
        if twoPinchSince == nil { twoPinchSince = now }
        guard now - (twoPinchSince ?? now) >= 0.12 else { return false }
        let span = hypot(pinches[0].palm.x - pinches[1].palm.x, pinches[0].palm.y - pinches[1].palm.y)
        if let old = twoHandSpan, abs(span - old) > 0.010, now >= cooldownUntil {
            let conf = pinches.map(\.meanConfidence).min() ?? 0
            perform("Skalieren", confidence: conf) {
                system.resizeFocused(scale: span > old ? 1.05 : 0.95)
            }
            twoHandSpan = span
            cooldownUntil = now + 0.12
            return true
        }
        twoHandSpan = span
        return false
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
        let ratio = hand.pinchRatio
        let posing = hand.pose == .pinch
        let fisting = hand.pose == .fist && mode == .armed
        let isGrab = pinchHeld
            ? (posing || fisting || ratio < 0.58)
            : (posing || ratio < 0.38 || fisting)
        if isGrab && !pinchHeld {
            pinchHeld = true
            pinchBecameDrag = false
            pinchBeganAt = now
            pinchTrail = [(now, hand.palm.x, hand.palm.y)]
            pinchSpan0 = hypot(
                (hand.point(.middleTip) ?? hand.palm).x - hand.palm.x,
                (hand.point(.middleTip) ?? hand.palm).y - hand.palm.y
            )
            lastAction = testMode ? "Test: Halten" : "Halten"
        } else if isGrab && pinchHeld {
            pinchTrail.append((now, hand.palm.x, hand.palm.y))
            pinchTrail.removeAll { now - $0.t > 0.5 }
            if let first = pinchTrail.first {
                let moved = hypot(hand.palm.x - first.x, hand.palm.y - first.y)
                if moved > 0.025 { pinchBecameDrag = true }
            }
            if pinchBecameDrag, !system.isDragging, !testMode {
                let r = system.beginWindowDrag()
                if r.ok {
                    lastAction = "Greifen"
                    onLog?("Greifen · \(r.detail)", .executed, Int(hand.meanConfidence * 100))
                } else {
                    lastAction = "Greifen fehlgeschlagen"
                    onLog?("Greifen — NICHT AUSGEFÜHRT: \(r.detail)", .failed, Int(hand.meanConfidence * 100))
                    if r.detail.contains("Bedienung") || !AXIsProcessTrusted() {
                        Permissions.demand(.accessibility)
                    }
                }
            }
            if !testMode, system.isDragging {
                system.updateWindowDrag()
                lastAction = trashHot ? "Papierkorb" : "Ziehen"
            } else if testMode, pinchBecameDrag {
                lastAction = trashHot ? "Test: Papierkorb" : "Test: Ziehen"
            }
            let span = hypot(
                (hand.point(.middleTip) ?? hand.palm).x - hand.palm.x,
                (hand.point(.middleTip) ?? hand.palm).y - hand.palm.y
            )
            if let s0 = pinchSpan0, span > s0 + 0.09 {
                perform("Heranziehen", confidence: hand.meanConfidence) { system.snapFocused(.fill) }
                pinchSpan0 = span
                cooldownUntil = now + 0.5
            }
        } else if !isGrab && pinchHeld {
            let flung = resolveFling(now: now, confidence: hand.meanConfidence)
            let wasDrag = pinchBecameDrag
            let held = now - pinchBeganAt
            pinchHeld = false
            pinchBecameDrag = false
            pinchTrail.removeAll()
            pinchSpan0 = nil
            trashHot = false
            if !testMode { system.endWindowDrag() }
            if flung {
                cooldownUntil = now + 0.4
                return
            }
            if wasDrag {
                lastAction = testMode ? "Test: Loslassen" : "Loslassen"
                onLog?("Loslassen", testMode ? .blocked : .executed, Int(hand.meanConfidence * 100))
            } else if held >= 0.07, held < 0.55 {
                perform("Klick", need: .input, confidence: hand.meanConfidence) { system.click() }
            } else if held < 0.07 {
                lastAction = "zu kurz"
            }
            cooldownUntil = now + 0.12
        }
    }

    private func resolveFling(now: TimeInterval, confidence: Float) -> Bool {
        if trashHot {
            perform("Wegwerfen", confidence: confidence) { system.throwAway(finder: focused?.isFinder == true) }
            return true
        }
        guard let last = pinchTrail.last, let first = pinchTrail.first, last.t > first.t + 0.04 else {
            return false
        }
        let dt = max(0.04, last.t - first.t)
        let vx = (last.x - first.x) / dt
        let vy = (last.y - first.y) / dt
        let speed = hypot(vx, vy)
        let dx = last.x - first.x
        let dy = last.y - first.y
        let dist = hypot(dx, dy)
        guard speed > 0.38 && dist > 0.08 else { return false }
        onLog?("Werfen erkannt", .recognized, Int(confidence * 100))
        if abs(dy) >= abs(dx) && dy > 0.08 {
            perform("Wegwerfen", confidence: confidence) { system.throwAway(finder: focused?.isFinder == true) }
            return true
        }
        if abs(dy) >= abs(dx) && dy < -0.05 {
            perform("Minimieren", confidence: confidence) { system.minimizeFocused() }
            return true
        }
        if dx < -0.07 {
            perform("Links andocken", confidence: confidence) { system.snapFocused(.left) }
            return true
        }
        if dx > 0.07 {
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
        swipeTrail.removeAll { now - $0.t > 0.55 }
        guard let first = swipeTrail.first, swipeTrail.count >= 2 else { return }
        let dx = hand.palm.x - first.x
        let dy = hand.palm.y - first.y
        let dt = now - first.t
        guard dt > 0.12, abs(dx) > 0.12, abs(dx) > abs(dy) * 1.05 else { return }
        onLog?("Wischen erkannt", .recognized, Int(hand.meanConfidence * 100))
        let forward = dx < 0
        let name = forward ? "Nächste App" : "Vorherige App"
        perform(name, need: .none, confidence: hand.meanConfidence) { system.switchApp(forward: forward) }
        swipeTrail.removeAll()
        swipeHandID = nil
        cooldownUntil = now + 0.4
    }

    private func drivePeace(_ hand: TrackedHand, now: TimeInterval) {
        if hand.pose == .peace {
            if peaceSince == nil { peaceSince = now }
            if now - (peaceSince ?? now) > 0.55 {
                let target = focused
                perform("Aufnahme", need: .capture, confidence: hand.meanConfidence) {
                    if let t = target, t.quartzBounds.width > 8 {
                        return system.screenshotFocused(windowID: t.windowID, bounds: t.quartzBounds)
                    }
                    let b = NSScreen.main.map { ScreenGeometry.quartzRect(fromCocoa: $0.frame) } ?? .zero
                    return system.screenshotFocused(windowID: 0, bounds: b)
                }
                peaceSince = nil
                cooldownUntil = now + 4
            }
        } else {
            peaceSince = nil
        }
    }

    private func driveThumbs(_ hand: TrackedHand, now: TimeInterval) {
        if hand.pose == .thumbsUp {
            if thumbsSince == nil { thumbsSince = now }
            if now - (thumbsSince ?? now) > 0.5 {
                perform("Hervorholen", need: .none, confidence: hand.meanConfidence) { system.unhideFront() }
                thumbsSince = nil
                cooldownUntil = now + 3
            }
        } else {
            thumbsSince = nil
        }
    }
}

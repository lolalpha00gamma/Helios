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
    var testMode = true
    var trashHot = false
    var killFlash = false
    var dragging = false

    private var fistSince: TimeInterval?
    private var fistLostAt: TimeInterval?
    private var lastHandSeen: TimeInterval = 0
    private var palmSince: TimeInterval?
    private var lastPalmSeen: TimeInterval = 0
    private var pointHold: TimeInterval?
    private var palmMenuSince: TimeInterval?
    private var thumbsSince: TimeInterval?
    private var peaceSince: TimeInterval?
    private var pinchHeld = false
    private var pinchBecameDrag = false
    private var pinchTrail: [(t: TimeInterval, x: CGFloat, y: CGFloat)] = []
    private var pinchSpan0: CGFloat?
    private var twoPinchSince: TimeInterval?
    private var swipeTrail: [(t: TimeInterval, x: CGFloat, y: CGFloat)] = []
    private var cooldownUntil: TimeInterval = 0
    private var lastArmToggle: TimeInterval = 0
    private var lastLoggedPose: String = ""
    private var killLatched = false
    private let system = SystemControl()
    var onLog: ((String) -> Void)?
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
        pinchTrail.removeAll()
        system.endWindowDrag()
        cursor = nil
        twoHandSpan = nil
        trashHot = false
        dragging = false
        lastAction = "Reset"
    }

    func tick(hands: [TrackedHand], now: TimeInterval) {
        if hands.isEmpty {
            if pinchHeld, now - lastHandSeen < 0.18 {
                return
            }
            fistSince = nil
            fistLostAt = nil
            palmSince = nil
            killLatched = false
            lastPalmSeen = 0
            palmMenuSince = nil
            pinchTrail.removeAll()
            if system.isDragging { system.endWindowDrag() }
            pinchHeld = false
            pinchBecameDrag = false
            twoPinchSince = nil
            cursor = nil
            trashHot = false
            dragging = false
            return
        }
        lastHandSeen = now

        let primary = preferred(hands)
        if testMode {
            let key = hands.map { "\($0.sideDE):\($0.pose.rawValue)" }.joined(separator: ",")
            if key != lastLoggedPose, hands.contains(where: { $0.pose != .unknown }) {
                lastLoggedPose = key
                let text = hands.map { "\($0.sideDE) \($0.pose.labelDE)" }.joined(separator: " · ")
                onLog?("Erkannt: \(text)")
            }
        }

        if handleKillSwitch(hands: hands, now: now) {
            return
        }
        handleArming(hands: hands, now: now)

        let live = mode == .armed || testMode
        if !live {
            if hands.contains(where: { $0.pose == .pinch || $0.pinchRatio < 0.4 || $0.pose == .point }) {
                lastAction = "Faust halten → Scharf"
            }
            dragging = false
            return
        }
        if now < cooldownUntil { return }

        if handleTwoPinchScale(hands: hands, now: now) {
            return
        }

        let actor = pinchActor(hands, primary: primary)
        drivePointer(actor)
        updateTrashHot()
        drivePinch(actor, now: now)
        driveSwipe(hands: hands, now: now)
        drivePointHold(primary, now: now)
        drivePeace(primary, now: now)
        driveThumbs(primary, now: now)
        drivePalmMenu(hands: hands, primary: primary, now: now)
        dragging = pinchHeld
    }

    func forceIdle() {
        mode = .idle
        system.endWindowDrag()
        lastAction = testMode ? "Test: Idle" : "Idle"
        onLog?(testMode ? "Test · Idle" : "Manuell: Idle")
    }

    func forceArm() {
        mode = .armed
        lastAction = testMode ? "Test: Scharf" : "Scharf"
        onLog?(testMode ? "Test · Scharf" : "Manuell: Scharf")
    }

    private func perform(_ name: String, _ body: () -> Void) {
        lastAction = testMode ? "Test: \(name)" : name
        if testMode { return }
        body()
        onLog?(name)
    }

    /// Zwei offene Hände = Not-Aus. Läuft immer, auch im Idle, mit Hysterese gegen Flackern.
    @discardableResult
    private func handleKillSwitch(hands: [TrackedHand], now: TimeInterval) -> Bool {
        let open = hands.filter(\.isOpenEnough)
        if open.count >= 2 {
            if killLatched {
                lastAction = testMode ? "Test: Not-Aus" : "Not-Aus"
                return true
            }
            if palmSince == nil { palmSince = now }
            lastPalmSeen = now
            let held = now - (palmSince ?? now)
            if held >= 0.22 {
                mode = .idle
                killLatched = true
                pinchHeld = false
                pinchBecameDrag = false
                palmMenuSince = nil
                system.endWindowDrag()
                lastAction = testMode ? "Test: Not-Aus" : "Not-Aus"
                onLog?(testMode ? "Test · Beide Hände offen → Not-Aus" : "Beide Hände offen → Idle")
                killFlash = true
                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    await MainActor.run { self?.killFlash = false }
                }
                cooldownUntil = now + 0.7
                return true
            }
            lastAction = testMode ? "Test: Not-Aus halten" : "Not-Aus halten"
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
        let fisting = hands.contains { $0.pose == .fist || ($0.openScore == 0 && $0.pinchRatio > 0.5) }
        if fisting {
            fistLostAt = nil
            if fistSince == nil { fistSince = now }
            let held = now - (fistSince ?? now)
            if held >= 0.38, now - lastArmToggle > 0.65 {
                lastArmToggle = now
                fistSince = nil
                if mode == .idle {
                    mode = .armed
                    lastAction = testMode ? "Test: Scharf" : "Scharf"
                    onLog?(testMode ? "Test · Faust → Scharf" : "Faust → Scharf")
                } else {
                    mode = .idle
                    lastAction = testMode ? "Test: Idle" : "Idle"
                    onLog?(testMode ? "Test · Faust → Idle" : "Faust → Idle")
                    if !testMode { system.endWindowDrag() }
                    pinchHeld = false
                    pinchBecameDrag = false
                }
                cooldownUntil = now + 0.12
            } else if mode == .idle, held >= 0.08 {
                lastAction = testMode ? "Test: Faust …" : "Faust …"
            }
        } else if fistSince != nil {
            if fistLostAt == nil { fistLostAt = now }
            if now - (fistLostAt ?? now) > 0.22 {
                fistSince = nil
                fistLostAt = nil
            }
        }
    }

    private func pinchActor(_ hands: [TrackedHand], primary: TrackedHand) -> TrackedHand {
        if pinchHeld {
            return hands.min { a, b in a.pinchRatio < b.pinchRatio } ?? primary
        }
        if let pinching = hands.filter({ $0.pose == .pinch }).min(by: {
            $0.pinchRatio < $1.pinchRatio
        }) {
            return pinching
        }
        return primary
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
        guard now - (twoPinchSince ?? now) >= 0.16 else { return false }
        let span = hypot(pinches[0].palm.x - pinches[1].palm.x, pinches[0].palm.y - pinches[1].palm.y)
        if let old = twoHandSpan, abs(span - old) > 0.012 {
            perform("Skalieren") { system.resizeFocused(scale: span > old ? 1.04 : 0.96) }
        }
        twoHandSpan = span
        return true
    }

    private func drivePointer(_ hand: TrackedHand) {
        guard hand.pose == .point || hand.pose == .pinch || pinchHeld else { return }
        let tip = hand.point(.indexTip) ?? hand.palm
        let mapped = ScreenGeometry.mapNormalizedToQuartz(tip)
        cursor = mapped
        if !testMode { system.moveCursor(to: mapped) }
        if hand.pose == .point {
            lastAction = testMode ? "Test: Zeiger" : "Zeiger"
        }
    }

    private func updateTrashHot() {
        guard pinchHeld, let cursor else {
            trashHot = false
            return
        }
        trashHot = NSScreen.screens.contains { screen in
            let local = ScreenGeometry.local(quartz: cursor, on: screen.frame)
            return ScreenGeometry.trashLocal(screen: screen).insetBy(dx: -16, dy: -16).contains(local)
        }
    }

    private func drivePinch(_ hand: TrackedHand, now: TimeInterval) {
        let ratio = hand.pinchRatio
        let posing = hand.pose == .pinch
        let isPinch = pinchHeld
            ? (posing || ratio < 0.58)
            : (posing || ratio < 0.38)
        let span = hypot(
            (hand.point(.middleTip) ?? hand.palm).x - hand.palm.x,
            (hand.point(.middleTip) ?? hand.palm).y - hand.palm.y
        )
        if isPinch && !pinchHeld {
            pinchHeld = true
            pinchBecameDrag = false
            pinchTrail = [(now, hand.palm.x, hand.palm.y)]
            pinchSpan0 = span
            if !testMode { system.beginWindowDrag() }
            lastAction = testMode ? "Test: Greifen" : "Greifen"
            onLog?(testMode ? "Test · Pinzette" : "Pinzette — greifen")
        } else if isPinch && pinchHeld {
            pinchTrail.append((now, hand.palm.x, hand.palm.y))
            pinchTrail.removeAll { now - $0.t > 0.45 }
            if let first = pinchTrail.first {
                let moved = hypot(hand.palm.x - first.x, hand.palm.y - first.y)
                if moved > 0.028 { pinchBecameDrag = true }
            }
            if !testMode, system.isDragging {
                system.updateWindowDrag()
                pinchBecameDrag = true
                lastAction = trashHot ? "Papierkorb" : "Ziehen"
            } else if testMode {
                lastAction = trashHot ? "Test: Papierkorb" : "Test: Greifen"
            } else if !system.isDragging {
                lastAction = "Greifen"
            }
            if let s0 = pinchSpan0, span > s0 + 0.09 {
                perform("Heranziehen") { system.snapFocused(.fill) }
                pinchSpan0 = span
                cooldownUntil = now + 0.6
            }
        } else if !isPinch && pinchHeld {
            let flung = resolveFling(now: now)
            let wasDrag = pinchBecameDrag
            pinchHeld = false
            pinchBecameDrag = false
            pinchTrail.removeAll()
            pinchSpan0 = nil
            trashHot = false
            if !testMode { system.endWindowDrag() }
            if flung {
                cooldownUntil = now + 0.5
                return
            }
            if wasDrag {
                lastAction = testMode ? "Test: Loslassen" : "Loslassen"
            } else {
                if !testMode { system.click() }
                lastAction = testMode ? "Test: Klick" : "Klick"
                onLog?(testMode ? "Test · Klick" : "Klick")
            }
            cooldownUntil = now + 0.12
        }
    }

    private func resolveFling(now: TimeInterval) -> Bool {
        guard let last = pinchTrail.last, let first = pinchTrail.first, last.t > first.t + 0.05 else {
            if trashHot {
                perform("Wegwerfen") { system.throwAway(finder: focused?.isFinder == true) }
                onLog?(testMode ? "Test · Papierkorb" : "Wegwerfen")
                return true
            }
            return false
        }
        let dt = last.t - first.t
        let vx = (last.x - first.x) / dt
        let vy = (last.y - first.y) / dt
        let speed = hypot(vx, vy)
        if trashHot || (speed > 1.35 && vy < -0.7) {
            perform("Wegwerfen") { system.throwAway(finder: focused?.isFinder == true) }
            onLog?(testMode ? "Test · Wegwerfen" : "Wegwerfen")
            return true
        }
        if speed > 1.2 && vx < -0.85 {
            perform("Links andocken") { system.snapFocused(.left) }
            return true
        }
        if speed > 1.2 && vx > 0.85 {
            perform("Rechts andocken") { system.snapFocused(.right) }
            return true
        }
        if speed > 1.3 && vy > 0.85 {
            perform("Minimieren") { system.minimizeFocused() }
            return true
        }
        return false
    }

    private func driveSwipe(hands: [TrackedHand], now: TimeInterval) {
        guard !pinchHeld, hands.count == 1,
              let hand = hands.first(where: { $0.pose == .openPalm || $0.openScore >= 3 })
        else {
            swipeTrail.removeAll()
            return
        }
        swipeTrail.append((now, hand.palm.x, hand.palm.y))
        swipeTrail.removeAll { now - $0.t > 0.45 }
        guard let first = swipeTrail.first, swipeTrail.count >= 4 else { return }
        let dx = hand.palm.x - first.x
        let dy = hand.palm.y - first.y
        let dt = now - first.t
        guard dt > 0.07, abs(dx) > 0.18, abs(dx) > abs(dy) * 1.1 else { return }
        let name = dx < 0 ? "Nächste App" : "Vorherige App"
        perform(name) { system.switchApp(forward: dx < 0) }
        if testMode { onLog?("Test · \(name)") }
        swipeTrail.removeAll()
        palmMenuSince = nil
        cooldownUntil = now + 0.55
    }

    private func drivePointHold(_ hand: TrackedHand, now: TimeInterval) {
        guard hand.pose == .point, let tip = hand.point(.indexTip), let wrist = hand.point(.wrist) else {
            pointHold = nil
            return
        }
        let up = tip.y - wrist.y
        if up > 0.18 {
            if pointHold == nil { pointHold = now }
            if now - (pointHold ?? now) > 0.62 {
                perform("Zoom") { system.zoomFocused() }
                pointHold = nil
                cooldownUntil = now + 0.8
            }
        } else if up < -0.10 {
            if pointHold == nil { pointHold = now }
            if now - (pointHold ?? now) > 0.62 {
                perform("Minimieren") { system.minimizeFocused() }
                pointHold = nil
                cooldownUntil = now + 0.8
            }
        } else {
            pointHold = nil
        }
    }

    private func drivePeace(_ hand: TrackedHand, now: TimeInterval) {
        if hand.pose == .peace {
            if peaceSince == nil { peaceSince = now }
            if now - (peaceSince ?? now) > 0.45 {
                let target = focused
                perform("Aufnahme") {
                    if let t = target, t.quartzBounds.width > 8 {
                        system.screenshotFocused(windowID: t.windowID, bounds: t.quartzBounds)
                    }
                }
                onLog?(testMode ? "Test · Aufnahme" : "Fensteraufnahme")
                peaceSince = now + 10
                cooldownUntil = now + 1.0
            }
        } else {
            peaceSince = nil
        }
    }

    private func driveThumbs(_ hand: TrackedHand, now: TimeInterval) {
        if hand.pose == .thumbsUp {
            if thumbsSince == nil { thumbsSince = now }
            if now - (thumbsSince ?? now) > 0.4 {
                perform("Hervorholen") { system.unhideFront() }
                thumbsSince = now + 10
                cooldownUntil = now + 0.8
            }
        } else {
            thumbsSince = nil
        }
    }

    private func drivePalmMenu(hands: [TrackedHand], primary: TrackedHand, now: TimeInterval) {
        guard hands.count == 1, primary.isOpenEnough else {
            palmMenuSince = nil
            return
        }
        if let first = swipeTrail.first {
            let moved = hypot(primary.palm.x - first.x, primary.palm.y - first.y)
            if moved > 0.08 {
                palmMenuSince = nil
                return
            }
        }
        if palmMenuSince == nil { palmMenuSince = now }
        if now - (palmMenuSince ?? now) > 0.95 {
            perform("Mission Control") { system.missionControl() }
            palmMenuSince = now + 10
            cooldownUntil = now + 1.0
        }
    }

    private func preferred(_ hands: [TrackedHand]) -> TrackedHand {
        hands.max { a, b in
            let sa = a.joints.values.map(\.confidence).max() ?? 0
            let sb = b.joints.values.map(\.confidence).max() ?? 0
            return sa < sb
        } ?? hands[0]
    }
}

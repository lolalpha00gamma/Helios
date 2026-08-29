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

    private var fistSince: TimeInterval?
    private var palmSince: TimeInterval?
    private var pointHold: TimeInterval?
    private var pinchHeld = false
    private var pinchBecameDrag = false
    private var swipeTrail: [(t: TimeInterval, x: CGFloat)] = []
    private var cooldownUntil: TimeInterval = 0
    private var lastArmToggle: TimeInterval = 0
    private var lastLoggedPose: String = ""
    private let system = SystemControl()
    var onLog: ((String) -> Void)?

    func reset() {
        mode = .idle
        fistSince = nil
        palmSince = nil
        pinchHeld = false
        pinchBecameDrag = false
        swipeTrail.removeAll()
        system.endWindowDrag()
        cursor = nil
        twoHandSpan = nil
        lastAction = "Reset"
    }

    func tick(hands: [TrackedHand], now: TimeInterval) {
        if hands.isEmpty {
            fistSince = nil
            palmSince = nil
            if system.isDragging { system.endWindowDrag() }
            pinchHeld = false
            cursor = nil
            return
        }

        let primary = preferred(hands)
        if testMode {
            let key = hands.map { "\($0.sideDE):\($0.pose.rawValue)" }.joined(separator: ",")
            if key != lastLoggedPose, hands.contains(where: { $0.pose != .unknown }) {
                lastLoggedPose = key
                let text = hands.map { "\($0.sideDE) \($0.pose.labelDE)" }.joined(separator: " · ")
                onLog?("Erkannt: \(text)")
            }
        }
        handleArming(hands: hands, primary: primary, now: now)
        guard mode == .armed || testMode, now >= cooldownUntil else { return }

        if hands.count >= 2,
           hands.filter({ $0.pose == .openPalm || $0.pose == .pinch }).count == 2
        {
            let span = hypot(hands[0].palm.x - hands[1].palm.x, hands[0].palm.y - hands[1].palm.y)
            if let old = twoHandSpan, abs(span - old) > 0.012 {
                perform("Skalieren") { system.resizeFocused(scale: span > old ? 1.04 : 0.96) }
            }
            twoHandSpan = span
            return
        } else {
            twoHandSpan = nil
        }

        drivePointer(primary)
        drivePinch(primary, now: now)
        driveSwipe(primary, now: now)
        drivePointHold(primary, now: now)
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

    private func handleArming(hands: [TrackedHand], primary: TrackedHand, now: TimeInterval) {
        let palms = hands.filter { $0.pose == .openPalm }
        if palms.count >= 2 {
            if palmSince == nil { palmSince = now }
            if now - (palmSince ?? now) > 0.45, mode != .idle {
                mode = .idle
                perform("Not-Aus") { system.endWindowDrag() }
                if !testMode { onLog?("Beide Hände offen → Idle") }
                cooldownUntil = now + 0.6
            }
        } else {
            palmSince = nil
        }

        if primary.pose == .fist {
            if fistSince == nil { fistSince = now }
            if now - (fistSince ?? now) >= 0.75, now - lastArmToggle > 1.0 {
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
                }
                cooldownUntil = now + 0.4
            }
        } else {
            fistSince = nil
        }
    }

    private func drivePointer(_ hand: TrackedHand) {
        guard hand.pose == .point || hand.pose == .pinch || pinchHeld else { return }
        let tip = hand.point(.indexTip) ?? hand.palm
        let mapped = mapToQuartz(tip)
        cursor = mapped
        if !testMode { system.moveCursor(to: mapped) }
        if hand.pose == .point {
            lastAction = testMode ? "Test: Zeiger" : "Zeiger"
        }
    }

    private func drivePinch(_ hand: TrackedHand, now: TimeInterval) {
        let isPinch = hand.pose == .pinch
        if isPinch && !pinchHeld {
            pinchHeld = true
            pinchBecameDrag = false
            if !testMode { system.beginWindowDrag() }
            lastAction = testMode ? "Test: Greifen" : "Greifen"
            onLog?(testMode ? "Test · Pinzette" : "Pinzette — Fenster greifen")
        } else if isPinch && pinchHeld {
            if !testMode, system.isDragging {
                system.updateWindowDrag()
                pinchBecameDrag = true
                lastAction = "Ziehen"
            } else if testMode {
                lastAction = "Test: Greifen"
            }
        } else if !isPinch && pinchHeld {
            if !pinchBecameDrag {
                if !testMode {
                    system.endWindowDrag()
                    system.click()
                }
                lastAction = testMode ? "Test: Klick" : "Klick"
                onLog?(testMode ? "Test · Klick" : "Klick")
            } else {
                if !testMode { system.endWindowDrag() }
                lastAction = testMode ? "Test: Loslassen" : "Loslassen"
            }
            pinchHeld = false
            pinchBecameDrag = false
            cooldownUntil = now + 0.2
        }
    }

    private func driveSwipe(_ hand: TrackedHand, now: TimeInterval) {
        guard hand.pose == .point || hand.pose == .openPalm else {
            swipeTrail.removeAll()
            return
        }
        swipeTrail.append((now, hand.palm.x))
        swipeTrail.removeAll { now - $0.t > 0.38 }
        guard let first = swipeTrail.first, swipeTrail.count >= 4 else { return }
        let dx = hand.palm.x - first.x
        if abs(dx) > 0.22 {
            let name = dx < 0 ? "Nächste App" : "Vorherige App"
            perform(name) { system.switchApp(forward: dx < 0) }
            if testMode { onLog?("Test · \(name)") }
            swipeTrail.removeAll()
            cooldownUntil = now + 0.7
        }
    }

    private func drivePointHold(_ hand: TrackedHand, now: TimeInterval) {
        guard hand.pose == .point, let tip = hand.point(.indexTip), let wrist = hand.point(.wrist) else {
            pointHold = nil
            return
        }
        let up = tip.y - wrist.y
        if up > 0.16 {
            if pointHold == nil { pointHold = now }
            if now - (pointHold ?? now) > 0.55 {
                perform("Zoom") { system.zoomFocused() }
                if testMode { onLog?("Test · Zoom") }
                pointHold = nil
                cooldownUntil = now + 0.8
            }
        } else if up < -0.08 {
            if pointHold == nil { pointHold = now }
            if now - (pointHold ?? now) > 0.55 {
                perform("Minimieren") { system.minimizeFocused() }
                if testMode { onLog?("Test · Minimieren") }
                pointHold = nil
                cooldownUntil = now + 0.8
            }
        } else {
            pointHold = nil
        }
    }

    private func preferred(_ hands: [TrackedHand]) -> TrackedHand {
        hands.max { a, b in
            let sa = a.joints.values.map(\.confidence).max() ?? 0
            let sb = b.joints.values.map(\.confidence).max() ?? 0
            return sa < sb
        } ?? hands[0]
    }

    /// Vision (Ursprung unten links, X gespiegelt) → Quartz (Ursprung oben links).
    private func mapToQuartz(_ p: CGPoint) -> CGPoint {
        let screen = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let globalMaxY = NSScreen.screens.map(\.frame.maxY).max() ?? screen.maxY
        let cocoaX = screen.minX + p.x * screen.width
        let cocoaY = screen.minY + p.y * screen.height
        return CGPoint(x: cocoaX, y: globalMaxY - cocoaY)
    }
}

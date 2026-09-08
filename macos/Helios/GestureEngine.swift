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
    var lockFreeze = ""
    var qualityChip = ""
    var freezeLive = false
    var freezeEndedAt: TimeInterval?
    var freezeGhostDelta: CGPoint = .zero
    var freezeGhostDeltas: [String: CGPoint] = [:]
    private var freezePPos: CGFloat = 0.0004
    private var freezePVel: CGFloat = 0.008
    private var freezePByID: [String: (pPos: CGFloat, pVel: CGFloat)] = [:]

    private var fistSince: TimeInterval?
    private var fistLostAt: TimeInterval?
    private(set) var lastHandSeen: TimeInterval = 0
    private var palmSince: TimeInterval?
    private var lastPalmSeen: TimeInterval = 0
    private var killPalms: [CGPoint]?
    private var thumbsSince: TimeInterval?
    private var peaceSince: TimeInterval?
    private var pinchHeld = false
    private var pinchHoldPhase: GestureMath.PinchHoldPhase = .unseen
    private var pinchHoldFor: TimeInterval = 0
    private var pinchBecameDrag = false
    private var pinchBeganAt: TimeInterval = 0
    private var pinchTrail: [(t: TimeInterval, x: CGFloat, y: CGFloat)] = []
    private var pinchSpan0: CGFloat?
    private var pinchSpanW: CGFloat?
    private var pinchHandID: String?
    private var pinchLastHand: TrackedHand?
    private var pinchOriginCursor: CGPoint?
    private var pinchPeakClosed: Double = 0
    private var pinchPalmMoved: CGFloat = 0
    private var tipDwell: [String: (at: TimeInterval, key: String, pos: CGPoint)] = [:]
    var keyboardHots: Set<String> = []
    private var pinchMissSince: TimeInterval?
    private var pinchReleasedAt: TimeInterval?
    private var grabLogged = false
    private var lastGrabTry: TimeInterval = 0
    private var twoPinchSince: TimeInterval?
    private var twoPinchEndedAt: TimeInterval?
    private var lastScaleSign: CGFloat = 0
    private var lastScrollSign: Int32 = 0
    private var twoPinchEdgeStreak = 0
    private var twoPinchScaleStreak = 0
    private var twoPinchLockedAxis: TwoPinchAxis = .none
    private var twoPinchLastMapped: [CGPoint]?
    private var twoPinchLastTicks: Int32 = 0
    private var freezeGain: CGFloat = 1
    private var recoverUntil: TimeInterval = 0
    private var recoverSpan: TimeInterval = 0.08
    private var scrollCoast: (until: TimeInterval, vel: CGFloat)?
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
    private var lastPalmVel: CGPoint = .zero
    private var lastHandsFreeze: [(id: String, palm: CGPoint, vel: CGPoint)] = []
    private var lastHandsLive: [TrackedHand] = []
    private var pointerHandID: String?
    private var pointerSourceID: String = ""
    private var pointerLastHand: TrackedHand?
    private var pointerMissSince: TimeInterval?
    private var palmSlow: CGPoint?
    private var cursorTracks: [String: CGPoint] = [:]
    private var swipeGraceUntil: TimeInterval = 0
    private var swipeMuteUntil: TimeInterval = 0
    private var lastSwipeDx: CGFloat = 0
    private var lastSwipeAt: TimeInterval = 0
    private var armedQuietUntil: TimeInterval = 0
    private var cursorDidMove = false
    private var lastPalmWidth: CGFloat = 0.12
    private var palmJitter: [CGFloat] = []
    private var euroX: CGFloat = 0
    private var euroY: CGFloat = 0
    private var euroDx: CGFloat = 0
    private var euroDy: CGFloat = 0
    private var euroInited = false
    private var palmStillFor: TimeInterval = 0
    private var palmDeadman = false
    private var twoHandClutchOn = false
    private var scrollAnchor: (t: TimeInterval, y: CGFloat)?
    private var ringPinchSince: TimeInterval?
    private var dwellSince: TimeInterval?
    private var dwellPalm: CGPoint?
    private var chromeDwellSince: TimeInterval?
    private var chromeDwellKind: ChromeKnob.Kind?
    private var chromeDwellAt: CGPoint?
    private var pointSince: TimeInterval?
    private var kbDwellID: String?
    private var kbDwellAt: TimeInterval?
    private var kbCursorAt: CGPoint?
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
    private var tablePalms: [String: CGPoint] = [:]
    private let system = SystemControl()
    var onLog: ((String, ProtocolKind, Int?) -> Void)?

    func coastCursor(_ p: CGPoint) {
        guard !testMode else { return }
        system.moveCursor(to: p)
    }

    private func postSampleCursor(_ p: CGPoint, freeze: Bool = false) {
        guard !testMode else { return }
        let coast = GestureMath.hudLerpDrivesCursor()
            && GestureMath.hudCoastAllowed(
                reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
            )
        if GestureMath.sampleCursorYieldsToCoast(
            coastDrives: coast, dragging: system.isDragging, freeze: freeze
        ) { return }
        system.moveCursor(to: p)
    }
    var focused: FocusedTarget?

    private var space: AspectSpace { GestureClassifier.space }

    private var chromeScreenMin: CGFloat {
        NSScreen.screens.map { min($0.frame.width, $0.frame.height) }.max() ?? 1080
    }

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
        pinchHoldPhase = .unseen
        pinchHoldFor = 0
        pinchBecameDrag = false
        pinchTrail.removeAll()
        pinchSpan0 = nil
        pinchSpanW = nil
        pinchHandID = nil
        pinchLastHand = nil
        pinchOriginCursor = nil
        pinchPeakClosed = 0
        pinchPalmMoved = 0
        tipDwell.removeAll()
        keyboardHots = []
        pinchMissSince = nil
        pinchReleasedAt = nil
        grabLogged = false
        lastGrabTry = 0
        twoPinchSince = nil
        twoPinchEndedAt = nil
        lastScaleSign = 0
        lastScrollSign = 0
        twoPinchEdgeStreak = 0
        twoPinchScaleStreak = 0
        twoPinchLockedAxis = .none
        twoPinchLastMapped = nil
        twoPinchLastTicks = 0
        freezeGain = 1
        recoverUntil = 0
        recoverSpan = 0.08
        scrollCoast = nil
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
        lastPalmVel = .zero
        lastHandsFreeze = []
        lastHandsLive = []
        pointerHandID = nil
        pointerSourceID = ""
        pointerLastHand = nil
        pointerMissSince = nil
        palmSlow = nil
        palmJitter = []
        euroInited = false
        palmStillFor = 0
        palmDeadman = false
        twoHandClutchOn = false
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
        chromeDwellAt = nil
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
        lockFreeze = ""
        qualityChip = ""
        freezeLive = false
        freezeEndedAt = nil
        freezeGhostDelta = .zero
        freezeGhostDeltas = [:]
        freezePPos = 0.0004
        freezePVel = 0.008
        freezePByID = [:]
        sampleDt = 0.04
        lastTickNow = 0
        lastFusionEntropy = 0
        tableSince = nil
        tablePalms = [:]
    }

    private func dropPinchHold() {
        pinchHeld = false
        pinchHoldPhase = (pinchHoldPhase == .held || pinchHoldPhase == .tentative) ? .released : .unseen
        pinchHoldFor = 0
    }

    func tick(hands incoming: [TrackedHand], now: TimeInterval) {
        sampleDt = GestureMath.sampleDt(now: now, last: lastTickNow)
        lastTickNow = now
        system.sampleDt = sampleDt
        lockFreeze = ""
        qualityChip = ""
        let wasFrozen = freezeLive
        freezeLive = false
        freezeGhostDelta = .zero
        freezeGhostDeltas = [:]
        system.freezeLive = false
        let hands = incoming.filter { $0.joints.count >= 8 && $0.meanConfidence >= 0.18 }
        if hands.isEmpty {
            if lastHandSeen > 0, now - lastHandSeen < GestureMath.emptyHandsHold(dt: sampleDt) {
                freezeLive = true
                system.freezeLive = true
                if let p = lastPalm {
                    let pred = GestureMath.freezeKalmanPredict(
                        palm: p, vx: lastPalmVel.x, vy: lastPalmVel.y,
                        pPos: freezePPos, pVel: freezePVel, dt: sampleDt
                    )
                    freezeGhostDelta = CGPoint(x: pred.palm.x - p.x, y: pred.palm.y - p.y)
                    lastPalm = pred.palm
                    lastPalmVel = CGPoint(x: pred.vx, y: pred.vy)
                    freezePPos = pred.pPos
                    freezePVel = pred.pVel
                }
                let predHands = GestureMath.freezeKalmanPalms(
                    palms: lastHandsFreeze.map {
                        let p = freezePByID[$0.id] ?? (0.0004, 0.008)
                        return ($0.id, $0.palm, $0.vel.x, $0.vel.y, p.pPos, p.pVel)
                    },
                    dt: sampleDt
                )
                var deltas: [String: CGPoint] = [:]
                var nextP: [String: (pPos: CGFloat, pVel: CGFloat)] = [:]
                lastHandsFreeze = predHands.map { row in
                    let prev = lastHandsFreeze.first { $0.id == row.id }
                    let oldPalm = prev?.palm ?? row.palm
                    deltas[row.id] = CGPoint(x: row.palm.x - oldPalm.x, y: row.palm.y - oldPalm.y)
                    nextP[row.id] = (row.pPos, row.pVel)
                    return (row.id, row.palm, CGPoint(x: row.vx, y: row.vy))
                }
                freezePByID = nextP
                freezeGhostDeltas = deltas
                if let chip = GestureMath.freezeVelChip(dx: freezeGhostDelta.x, dy: freezeGhostDelta.y) {
                    lockFreeze = chip
                }
                if let id = pointerHandID, let label = GestureMath.lockFreezeLabel(locked: id, missHeld: true) {
                    lockFreeze = lockFreeze.isEmpty ? label : "\(label) \(lockFreeze)"
                } else if lockFreeze.isEmpty {
                    lockFreeze = "freeze"
                }
                if GestureMath.emptyHandsHoldReleaseAX(isDragging: system.isDragging) {
                    system.endWindowDrag()
                }
                if GestureMath.emptyHandsHoldDropsPinch() {
                    if pinchHeld {
                        swipeMuteUntil = now + GestureMath.swipeMuteAfterPinch
                        pinchReleasedAt = now
                        if let chip = GestureMath.emptyHandsHoldDropsPinchChip(dropped: true) {
                            lockFreeze = lockFreeze.isEmpty ? chip : "\(lockFreeze) \(chip)"
                        }
                    }
                    dropPinchHold()
                    pinchBecameDrag = false
                }
                if GestureMath.freezeDrivesCursor(hasHands: !lastHandsLive.isEmpty) {
                    lastHandsLive = lastHandsLive.map { h in
                        h.shifted(by: freezeGhostDeltas[h.id] ?? .zero)
                    }
                    let ghostPrimary = preferred(lastHandsLive)
                    let actor = pinchActor(lastHandsLive, primary: ghostPrimary)
                    placeCursors(lastHandsLive, actor: actor)
                    if let p = cursor {
                        postSampleCursor(p, freeze: true)
                    }
                }
                dragging = pinchHeld
                return
            }
            lastHandsLive = []
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
            twoPinchEdgeStreak = 0
            twoPinchScaleStreak = 0
            twoPinchLockedAxis = .none
            twoPinchLastMapped = nil
            freezeGain = 1
            if twoPinchSince != nil, let m = GestureMath.twoPinchScrollMomentum(ticks: twoPinchLastTicks, now: now) {
                scrollCoast = m
            } else {
                scrollCoast = nil
            }
            twoPinchLastTicks = 0
            if system.isDragging { system.endWindowDrag() }
            if pinchHeld {
                swipeMuteUntil = now + GestureMath.swipeMuteAfterPinch
                pinchReleasedAt = now
            }
            dropPinchHold()
            pinchBecameDrag = false
            pinchHandID = nil
            pinchLastHand = nil
            pinchOriginCursor = nil
            pinchPalmMoved = 0
            pinchMissSince = nil
            if twoPinchSince != nil { twoPinchEndedAt = now }
            twoPinchSince = nil
            lastScaleSign = 0
            lastScrollSign = 0
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
        if wasFrozen {
            freezeEndedAt = now
        }
        rememberHandsFreeze(hands)
        if lastHandSeen > 0, now - lastHandSeen > sampleDt * 1.6 {
            recoverSpan = GestureMath.emptyHandsRecoverSpan(dt: sampleDt)
            recoverUntil = now + recoverSpan
            if let pred = lastPalm, let meas = hands.first(where: { $0.id == pointerHandID })?.palm
                ?? hands.max(by: { $0.palmWidth < $1.palmWidth })?.palm {
                let u = GestureMath.freezeKalmanUpdate(pred: pred, meas: meas, pPos: freezePPos)
                lastPalm = u.palm
                freezePPos = u.pPos
                freezePVel = 0.008
            }
        } else {
            freezePPos = 0.0004
            freezePVel = 0.008
            freezePByID = [:]
        }
        let nextPalmW = hands.map(\.palmWidth).max() ?? lastPalmWidth
        let nextPalm = hands.first(where: { $0.id == pointerHandID })?.palm
            ?? hands.max(by: { $0.palmWidth < $1.palmWidth })?.palm
            ?? lastPalm
        if now < recoverUntil {
            let live = GestureMath.emptyHandsRecoverLive(
                now: now,
                until: recoverUntil,
                span: recoverSpan
            )
            var gain = live * GestureMath.emptyHandsRecoverPalmMul(prev: lastPalmWidth, next: nextPalmW)
            if let prev = lastPalm, let nxt = nextPalm {
                gain *= GestureMath.emptyHandsRecoverPalmJump(prev: prev, next: nxt, palmWidth: nextPalmW)
            }
            freezeGain = gain
            if let chip = GestureMath.emptyHandsRecoverChip(now: now, until: recoverUntil, span: recoverSpan) {
                lockFreeze = lockFreeze.isEmpty ? chip : "\(lockFreeze) \(chip)"
            }
        } else {
            freezeGain = 1
        }
        lastHandSeen = now
        lastPalmWidth = nextPalmW
        // lastPalm nur mappedPoint / freezePalmPredict. Hier schreiben = Highpass dx 0.
        mousePaused = !system.allowsInjection && !system.fromInstallMedia

        if system.fromInstallMedia, lastAction == "—" || lastAction.hasPrefix("Cursor frei") {
            lastAction = "Scharf — besser nach Programme ziehen"
        }

        if mousePaused {
            lastAction = "Maus hat Vorrang"
        }

        if let cal = calibration, cal.active {
            let actor = preferred(hands)
            placeCursors(hands, actor: actor)
            if let p = cursor { postSampleCursor(p) }
            if driveClap(hands: hands, now: now) {
                cal.cancel()
                mode = .armed
                mustRearm = false
                lastAction = "Kalibrierung abgebrochen — Scharf"
                onLog?("Kalibrierung — 2× Klatschen, Abbruch", .info, nil)
                return
            }
            let fisting = hands.contains {
                $0.pose == .fist || ($0.openScore == 0 && $0.pinchRatio > 0.5 && $0.meanConfidence > 0.35)
            }
            if fisting {
                if fistSince == nil { fistSince = now }
                if now - (fistSince ?? now) >= 0.55 {
                    cal.cancel()
                    fistSince = nil
                    mode = .armed
                    mustRearm = false
                    lastAction = "Kalibrierung abgebrochen — Scharf"
                    onLog?("Kalibrierung — Faust, Abbruch", .info, nil)
                    return
                }
            } else {
                fistSince = nil
            }
            let confirm = actor.pinchClosed && GestureMath.pinchLooksLikePinch(
                reach: actor.pinchReach,
                index: actor.indexScore,
                zSep: actor.pinchZSep,
                approach: actor.pinchZApproach,
                closedness: actor.pinchClosedness,
                residual: actor.liftResidual
            )
            if let done = cal.feed(palm: actor.palm, now: now, confirm: confirm, palmWidth: actor.palmWidth) {
                spaceMap = done
                lastAction = "Kalibrierung fertig — Scharf"
                onLog?("Kalibrierung · 4 Ecken", .executed, 100)
                dropPinchHold()
                pinchBecameDrag = false
                cooldownUntil = now + 0.4
                mode = .armed
                mustRearm = false
            } else {
                lastAction = cal.hint
            }
            return
        }

        let primary = preferred(hands)
        qualityChip = GestureMath.qualityChips(hands.map { ($0.id, $0.quality) })
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

        _ = driveClap(hands: hands, now: now)
        if now - lastClapFire > 2, handleKillSwitch(hands: hands, now: now) {
            placeCursors(hands, actor: primary)
            if let p = cursor { postSampleCursor(p) }
            return
        }
        if now - lastClapFire > 2, driveTableIdle(hands: hands, now: now) {
            placeCursors(hands, actor: primary)
            if let p = cursor { postSampleCursor(p) }
            return
        }
        handleArming(hands: hands, now: now)
        if mode != .armed, !testMode {
            let p = primary
            if GestureMath.pinchStartsGrab(
                gate: p.pinchClosed,
                closedness: p.pinchClosedness,
                reach: p.pinchReach,
                index: p.indexScore,
                zSep: p.pinchZSep,
                quality: p.quality,
                approach: p.pinchZApproach,
                residual: p.liftResidual,
                palmWidth: p.palmWidth
            ) {
                mode = .armed
                mustRearm = false
                lastAction = "Scharf"
            }
        }
        let armed = mode == .armed || testMode

        if !armed {
            placeCursors(hands, actor: primary)
            if let p = cursor { postSampleCursor(p) }
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
            if !system.isDragging, let p = cursor {
                postSampleCursor(p)
            }
            if pinchHeld {
                let actor = pinchActor(hands, primary: primary)
                driveGrab(actor, now: now, fire: false)
            }
            updateTrashHot()
            dragging = pinchHeld
            return
        }

        let scaling = handleTwoPinchScale(hands: hands, now: now)
        let actor = pinchActor(hands, primary: primary)
        lastFusionEntropy = actor.fusion?.entropy ?? lastFusionEntropy
        let freezePointer = (pinchHeld && !pinchBecameDrag)
            || !hands.contains(where: { $0.id == actor.id })
        placeCursors(hands, actor: actor)
        if !freezePointer, !system.isDragging, let p = cursor {
            postSampleCursor(p)
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
        driveScroll(hands: hands, preferred: primary, now: now)
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
        lastPalmVel = .zero
        lastHandsFreeze = []
        palmSlow = nil
        palmJitter = []
        euroInited = false
        palmStillFor = 0
        palmDeadman = false
        twoHandClutchOn = false
        pointerHandID = nil
        pointerSourceID = ""
        pointerLastHand = nil
        pointerMissSince = nil
        cursorSmooth = nil
        cursorTracks.removeAll()
    }

    private func releasePointer() {
        cursor = nil
        lastPalm = nil
        lastPalmVel = .zero
        lastHandsFreeze = []
        palmSlow = nil
        palmJitter = []
        euroInited = false
        palmStillFor = 0
        palmDeadman = false
        twoHandClutchOn = false
        pointerHandID = nil
        pointerSourceID = ""
        pointerLastHand = nil
        pointerMissSince = nil
        cursorSmooth = nil
        cursorTracks.removeAll()
        handCursors = []
        pointerOrigin = nil
        cursorDidMove = false
    }

    /// Zwei-Hand Freeze: Vel je Track, nicht nur Actor.
    private func rememberHandsFreeze(_ hands: [TrackedHand]) {
        lastHandsLive = hands
        lastHandsFreeze = hands.map { h in
            let prev = lastHandsFreeze.first { $0.id == h.id }
            let d = CGFloat(max(0.008, sampleDt))
            let vel: CGPoint
            if let p = prev {
                vel = CGPoint(x: (h.palm.x - p.palm.x) / d, y: (h.palm.y - p.palm.y) / d)
            } else if h.id == pointerHandID {
                vel = lastPalmVel
            } else {
                vel = .zero
            }
            return (h.id, h.palm, vel)
        }
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
                armedQuietUntil = now + 0.12
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
                dropPinchHold()
                pinchBecameDrag = false
                fistSince = nil
                pinchReleasedAt = now
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
                armedQuietUntil = now + 0.12
                onLog?("Faust → Scharf", .executed, Int((hands.map(\.poseProb).max() ?? 0) * 100))
            } else if held >= 0.08 {
                lastAction = "Faust …"
            }
        } else if fistSince != nil {
            if fistLostAt == nil { fistLostAt = now }
            if now - (fistLostAt ?? now) > GestureMath.fistScharfGrace(dt: sampleDt) {
                fistSince = nil
                fistLostAt = nil
            }
        }
    }

    @discardableResult
    private func driveTableIdle(hands: [TrackedHand], now: TimeInterval) -> Bool {
        guard mode == .armed, !testMode else {
            tableSince = nil
            tablePalms = [:]
            return false
        }
        let still: CGFloat = {
            guard !tablePalms.isEmpty else { return 0 }
            var m: CGFloat = 0
            var n = 0
            for h in hands {
                guard let prev = tablePalms[h.id] else { continue }
                m = max(m, space.dist(h.palm, prev) / max(0.04, h.palmWidth))
                n += 1
            }
            return n == 0 ? 0 : m
        }()
        tablePalms = Dictionary(uniqueKeysWithValues: hands.map { ($0.id, $0.palm) })
        if GestureMath.tableIdleCandidate(palmsY: hands.map(\.palm.y), stillHW: still, pinchHeld: pinchHeld) {
            if tableSince == nil { tableSince = now }
            if now - (tableSince ?? now) >= GestureMath.tableIdleHold {
                tableSince = nil
                tablePalms = [:]
                mode = .idle
                mustRearm = true
                lastAction = "Hände auf dem Tisch — Idle"
                onLog?("Hände unten still → Idle", .info, nil)
                if system.isDragging { system.endWindowDrag() }
                dropPinchHold()
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

    func mutexActorPalm() -> (x: CGFloat, y: CGFloat, w: CGFloat)? {
        mutexActorPalms().first
    }

    func mutexActorPalms() -> [(x: CGFloat, y: CGFloat, w: CGFloat)] {
        let live = lastHandsLive
        let actor = pointerLastHand.flatMap { h -> (x: CGFloat, y: CGFloat, w: CGFloat)? in
            guard live.contains(where: { $0.id == h.id }) else { return nil }
            return (h.palm.x, h.palm.y, max(0.04, h.palmWidth))
        }
        let others = live.map { ($0.palm.x, $0.palm.y, max(0.04, $0.palmWidth)) }
        return GestureMath.cameraMutexActorPalms(
            actor: GestureMath.cameraMutexActorPalm(
                actor: actor,
                fallback: live.first.map { ($0.palm.x, $0.palm.y, max(0.04, $0.palmWidth)) }
            ),
            others: others
        )
    }

    private func preferred(_ hands: [TrackedHand]) -> TrackedHand {
        let liveIDs = hands.map(\.id)
        let left = hands.first(where: { $0.chirality == .left })
        let right = hands.first(where: { $0.chirality == .right })
        let missHeld: Bool = {
            guard let locked = pointerHandID, !liveIDs.contains(locked) else {
                pointerMissSince = nil
                return false
            }
            if pointerMissSince == nil { pointerMissSince = lastTickNow }
            return GestureMath.missHeld(now: lastTickNow, since: pointerMissSince)
        }()
        if let label = GestureMath.lockFreezeLabel(locked: pointerHandID, missHeld: missHeld) {
            lockFreeze = label
        }
        let id = GestureMath.preferredHoldID(
            locked: pointerHandID,
            liveIDs: liveIDs,
            missHeld: missHeld,
            leftID: left?.id,
            rightID: right?.id,
            leftHanded: leftHanded
        )
        if let id, let same = hands.first(where: { $0.id == id }) {
            pointerLastHand = same
            return same
        }
        if missHeld, let last = pointerLastHand {
            return last
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
            if pinchMissSince == nil { pinchMissSince = lastTickNow }
            if let label = GestureMath.lockFreezeLabel(
                locked: id,
                missHeld: GestureMath.missHeld(now: lastTickNow, since: pinchMissSince)
            ) {
                lockFreeze = label
            }
            // Freeze. Nie die andere Hand — `primary` wäre der Steuerhand-Diebstahl.
            if let last = pinchLastHand { return last }
            return primary
        }
        pinchLastHand = nil
        if let pinching = hands.filter({
            ($0.pinchClosed || $0.pinchClosedness > GestureMath.pinchClosednessNeed(quality: $0.quality, start: true, palmWidth: $0.palmWidth))
                && GestureMath.pinchLooksLikePinch(
                    reach: $0.pinchReach,
                    index: $0.indexScore,
                    zSep: $0.pinchZSep,
                    approach: $0.pinchZApproach,
                    closedness: $0.pinchClosedness,
                    residual: $0.liftResidual
                )
        }).min(by: { $0.pinchRatio < $1.pinchRatio }) {
            pinchLastHand = pinching
            return pinching
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
            let a = min(0.93, 0.58 + dist / 55) * freezeGain
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
        let velDt = CGFloat(max(0.008, sampleDt))
        lastPalmVel = CGPoint(x: (palm.x - prevPalm.x) / velDt, y: (palm.y - prevPalm.y) / velDt)
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
        let seed = from ?? ScreenGeometry.clampQuartz(NSEvent.mouseLocation.screenFlipped)
        let scale = ScreenGeometry.backingScale(quartz: seed)
        let dead = GestureMath.deadzoneScaled(dead: GestureMath.palmDead * 0.55, scale: scale)
        let step = GestureMath.deadzone2D(dx: dx, dy: dy, dead: dead)
        dx = step.x
        dy = step.y
        if isActor {
            palmJitter.append(hypot(dx, dy))
            if palmJitter.count > 8 { palmJitter.removeFirst() }
        }
        let rms = GestureMath.jitterRms(palmJitter)
        if isActor {
            if GestureMath.palmDeadmanStill(delta: hypot(dx, dy), dead: dead) {
                palmStillFor += sampleDt
            } else {
                palmStillFor = 0
            }
            palmDeadman = GestureMath.palmDeadmanClutch(stillFor: palmStillFor)
            _ = palmDeadman
        }
        let adapt = GestureMath.pointerGainAdaptive(
            gain: pointerGain * freezeGain * GestureMath.pointerGainDt(dt: sampleDt),
            jitterRms: rms
        )
        var stepped = ScreenGeometry.stepCursor(
            from: seed,
            dPalm: CGPoint(x: dx, y: dy),
            gain: GestureMath.pointerGainScaled(
                gain: adapt,
                scale: scale
            )
        )
        if isActor {
            let minC = GestureMath.oneEuroMinCutoff(jitterRms: rms)
            if !euroInited {
                euroX = stepped.x
                euroY = stepped.y
                euroDx = 0
                euroDy = 0
                euroInited = true
            }
            let fx = GestureMath.oneEuroFilter(
                prev: euroX, sample: stepped.x, dt: sampleDt, minCutoff: minC, dPrev: euroDx
            )
            let fy = GestureMath.oneEuroFilter(
                prev: euroY, sample: stepped.y, dt: sampleDt, minCutoff: minC, dPrev: euroDy
            )
            euroX = fx.value
            euroDx = fx.deriv
            euroY = fy.value
            euroDy = fy.deriv
            let clutchPredict = !GestureMath.pointerPredictArmed(
                deadman: palmDeadman, clutch: twoHandClutchOn
            )
            if clutchPredict {
                euroDx = 0
                euroDy = 0
                stepped = CGPoint(x: fx.value, y: fy.value)
            } else {
                stepped = GestureMath.pointerPredictPoint(
                    sample: CGPoint(x: fx.value, y: fy.value),
                    vel: CGPoint(x: fx.deriv, y: fy.deriv),
                    dt: sampleDt,
                    cap: GestureMath.pointerPredictCap(false)
                )
            }
        }
        let a: CGFloat = freezeGain < 0.99 ? 1 : 0.48
        let s = CGPoint(x: a * stepped.x + (1 - a) * seed.x, y: a * stepped.y + (1 - a) * seed.y)
        cursorTracks[hand.id] = s
        if isActor {
            cursorDidMove = hypot(dx, dy) > dead
            cursorSmooth = s
        }
        return s
    }

    private func placeCursors(_ hands: [TrackedHand], actor: TrackedHand) {
        twoHandClutchOn = GestureMath.twoHandClutch(
            livePalms: hands.count, twoPinch: twoPinchSince != nil
        )
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
        if hands.contains(where: { $0.id == actor.id }) {
            pointerHandID = actor.id
            if !actor.sourceID.isEmpty { pointerSourceID = actor.sourceID }
        }
    }

    @discardableResult
    private func handleTwoPinchScale(hands: [TrackedHand], now: TimeInterval) -> Bool {
        let pinches = hands.filter {
            ($0.pinchClosed || $0.pinchClosedness > GestureMath.twoPinchClosed)
                && GestureMath.pinchLooksLikePinch(
                    reach: $0.pinchReach,
                    index: $0.indexScore,
                    zSep: $0.pinchZSep,
                    approach: $0.pinchZApproach,
                    closedness: $0.pinchClosedness,
                    residual: $0.liftResidual
                )
        }.sorted { $0.id < $1.id }
        guard pinches.count >= 2 else {
            if twoPinchSince != nil {
                swipeMuteUntil = now + GestureMath.swipeMuteAfterPinch
                cooldownUntil = max(cooldownUntil, now + 0.25)
                pinchTrail.removeAll()
                twoPinchEndedAt = now
                if let m = GestureMath.twoPinchScrollMomentum(ticks: twoPinchLastTicks, now: now) {
                    scrollCoast = m
                }
            }
            twoHandSpan = nil
            twoPinchSince = nil
            lastScaleSign = 0
            lastScrollSign = 0
            twoPinchEdgeStreak = 0
            twoPinchScaleStreak = 0
            twoPinchLockedAxis = .none
            twoPinchLastMapped = nil
            twoPinchLastTicks = 0
            return false
        }
        if twoPinchSince == nil { twoPinchSince = now }
        if pinchHeld {
            dropPinchHold()
            pinchBecameDrag = false
            pinchHandID = nil
            pinchLastHand = nil
            pinchOriginCursor = nil
            pinchPalmMoved = 0
            pinchTrail.removeAll()
            if system.isDragging { system.endWindowDrag() }
        }
        // Tick belegen, sonst stiehlt Greifen die erste Pinzette.
        guard now - (twoPinchSince ?? now) >= GestureMath.twoPinchConfirmNeed(dt: sampleDt) else { return true }
        let mapped: [CGPoint] = pinches.map { hand in
            if let p = cursorTracks[hand.id] { return p }
            if let map = spaceMap, map.isReady { return map.apply(hand.palm) }
            return SpaceMap.linear(hand.palm)
        }
        if let bounds = focused?.quartzBounds, mapped.count >= 2 {
            let axis = GestureMath.twoPinchAxis(mapped[0], mapped[1], window: bounds)
            let dx = abs(mapped[0].x - mapped[1].x) / max(40, bounds.width)
            let dy = abs(mapped[0].y - mapped[1].y) / max(40, bounds.height)
            twoPinchLockedAxis = GestureMath.twoPinchAxisHysteresis(
                locked: twoPinchLockedAxis, next: axis, dx: dx, dy: dy
            )
            let holds = twoPinchLockedAxis != .none
            if holds, let chip = GestureMath.twoPinchAxisChip(twoPinchLockedAxis) {
                lockFreeze = lockFreeze.isEmpty ? chip : "\(lockFreeze) \(chip)"
            }
            let frames = GestureMath.twoPinchConfirmFrames(dt: sampleDt)
            twoPinchEdgeStreak = GestureMath.twoPinchEdgeHold(
                ok: holds,
                streak: twoPinchEdgeStreak,
                need: frames
            )
            if !GestureMath.twoPinchEdgeReady(streak: twoPinchEdgeStreak, need: frames) {
                twoPinchLastMapped = mapped
                return true
            }
        }
        let unit = max(0.04, (pinches[0].palmWidth + pinches[1].palmWidth) / 2)
        let span: CGFloat = {
            if mapped.count >= 2, let bounds = focused?.quartzBounds, bounds.width > 40 {
                return hypot(mapped[0].x - mapped[1].x, mapped[0].y - mapped[1].y)
                    / max(40, min(bounds.width, bounds.height))
            }
            return space.dist(pinches[0].palm, pinches[1].palm) / unit
        }()
        if let old = twoHandSpan, now >= cooldownUntil {
            let d = span - old
            if GestureMath.twoPinchPrefersScroll(spanDelta: d),
               twoPinchLockedAxis != .none,
               let prev = twoPinchLastMapped, prev.count >= 2, mapped.count >= 2
            {
                let mid = CGPoint(
                    x: (mapped[0].x + mapped[1].x) / 2,
                    y: (mapped[0].y + mapped[1].y) / 2
                )
                let ticks = GestureMath.twoPinchScrollTicks(
                    axis: twoPinchLockedAxis,
                    a: mapped[0], b: mapped[1],
                    prevA: prev[0], prevB: prev[1],
                    scale: ScreenGeometry.backingScale(quartz: mid),
                    gain: GestureMath.scrollGainFor(bundleId: focused?.bundleId ?? "")
                )
                if ticks != 0 {
                    let holds = GestureMath.twoPinchScrollHolds(ticks: ticks, lastSign: lastScrollSign)
                    if !holds {
                        lastScrollSign = 0
                    } else {
                        if lastScrollSign == 0 { lastScrollSign = ticks > 0 ? 1 : -1 }
                        twoPinchLastTicks = ticks
                        let conf = Float(pinches.map(\.poseProb).min() ?? 0)
                        perform("Scroll", need: .input, confidence: conf) { system.scroll(ticks: ticks) }
                    }
                }
                twoPinchLastMapped = mapped
                return true
            }
            let reversing = lastScaleSign != 0 && d * lastScaleSign < 0
            let need = GestureMath.twoPinchScaleNeed * (reversing ? GestureMath.twoPinchReverseMul : 1)
            if abs(d) > need {
                let frames = GestureMath.twoPinchConfirmFrames(dt: sampleDt)
                let holds = GestureMath.twoPinchZoomHolds(delta: d, lastSign: lastScaleSign)
                twoPinchScaleStreak = GestureMath.twoPinchEdgeHold(
                    ok: holds,
                    streak: twoPinchScaleStreak,
                    need: frames
                )
                if !holds { lastScaleSign = 0 }
                else if lastScaleSign == 0 { lastScaleSign = d > 0 ? 1 : -1 }
                guard GestureMath.twoPinchEdgeReady(streak: twoPinchScaleStreak, need: frames) else {
                    twoPinchLastMapped = mapped
                    return true
                }
                let conf = Float(pinches.map(\.poseProb).min() ?? 0)
                perform("Skalieren", confidence: conf) {
                    system.resizeFocused(scale: d > 0 ? 1.05 : 0.95)
                }
                lastScaleSign = d > 0 ? 1 : -1
                twoHandSpan = span
                twoPinchScaleStreak = 0
                twoPinchLastMapped = mapped
                cooldownUntil = now + 0.28
                return true
            }
            twoPinchScaleStreak = 0
        }
        if twoHandSpan == nil {
            twoHandSpan = span
        }
        twoPinchLastMapped = mapped
        return true
    }

    private func magnetChrome(now: TimeInterval) {
        guard !system.isDragging else {
            chromeKnobs = []
            chromeHot = ""
            chromeDwell = 0
            chromeDwellSince = nil
            chromeDwellKind = nil
            chromeDwellAt = nil
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
                        chromeDwellAt = nil
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
            chromeDwellAt = nil
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
            chromeDwellAt = nil
            return
        }
        guard let hot = knobs.min(by: {
            hypot($0.center.x - c.x, $0.center.y - c.y) < hypot($1.center.x - c.x, $1.center.y - c.y)
        }), hypot(hot.center.x - c.x, hot.center.y - c.y) < GestureMath.chromeMagnet else {
            chromeHot = ""
            chromeDwell = 0
            chromeDwellSince = nil
            chromeDwellKind = nil
            chromeDwellAt = nil
            return
        }
        // Nur Anzeige. Aktion nur bei Pinzette-Loslassen direkt auf der Ampel.
        guard pinchHeld, !pinchBecameDrag else {
            chromeHot = ""
            chromeDwell = 0
            chromeDwellSince = nil
            chromeDwellKind = nil
            chromeDwellAt = nil
            return
        }
        chromeHot = hot.labelDE
        if chromeDwellKind != hot.kind {
            chromeDwellKind = hot.kind
            chromeDwellSince = now
            chromeDwellAt = c
        } else if let origin = chromeDwellAt, GestureMath.chromeDwellMoved(
            from: origin,
            to: c,
            need: GestureMath.chromeDwellStillNeed(dt: sampleDt, screenMin: chromeScreenMin)
        ) {
            chromeDwellSince = now
            chromeDwellAt = c
            chromeDwell = 0
            return
        }
        let held = now - (chromeDwellSince ?? now)
        let dwellNeed = GestureMath.chromeDwellNeed(dt: sampleDt)
        chromeDwell = CGFloat(min(1, held / dwellNeed))
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

    private func driveGrab(_ hand: TrackedHand, now: TimeInterval, fire: Bool = true) {
        if keyboardVisible, let c = cursor, AirLayout.hit(at: c, keys: keyboardHits) != nil {
            return
        }
        if now < armedQuietUntil, !pinchHeld { return }
        if pinchHeld, let id = pinchHandID, hand.id != id {
            // Andere Hand ist nicht die Pinzette — kein Klick/Loslassen.
            if pinchMissSince == nil { pinchMissSince = now }
            if !GestureMath.missHeld(now: now, since: pinchMissSince) {
                dropPinchHold()
                pinchBecameDrag = false
                pinchHandID = nil
                pinchLastHand = nil
                pinchOriginCursor = nil
                pinchPalmMoved = 0
                pinchMissSince = nil
                pinchReleasedAt = now
                pinchTrail.removeAll()
                pinchSpan0 = nil
                pinchSpanW = nil
                grabLogged = false
                if !testMode { system.endWindowDrag() }
                swipeMuteUntil = now + GestureMath.swipeMuteAfterPinch
            }
            return
        }
        if pinchHeld, let miss = pinchMissSince, !GestureMath.missHeld(now: now, since: miss) {
            // Gesperrte Hand weg — nicht mit der anderen weitermachen.
            dropPinchHold()
            pinchBecameDrag = false
            pinchHandID = nil
            pinchLastHand = nil
            pinchOriginCursor = nil
            pinchPalmMoved = 0
            pinchMissSince = nil
            pinchReleasedAt = now
            pinchTrail.removeAll()
            pinchSpan0 = nil
            pinchSpanW = nil
            grabLogged = false
            if !testMode { system.endWindowDrag() }
            swipeMuteUntil = now + GestureMath.swipeMuteAfterPinch
            return
        }
        let analogClosed = GestureMath.pinchAnalogClosed(
            GestureMath.pinchAnalog(closedness: hand.pinchClosedness, zSep: hand.pinchZSep)
        )
        let closedWanted = (pinchHoldPhase == .held || pinchHoldPhase == .tentative)
            ? (analogClosed || GestureMath.pinchHoldsGrab(
                gate: hand.pinchClosed,
                closedness: hand.pinchClosedness,
                reach: hand.pinchReach,
                index: hand.indexScore,
                allowFist: pinchBecameDrag,
                zSep: hand.pinchZSep,
                quality: hand.quality,
                approach: hand.pinchZApproach,
                residual: hand.liftResidual,
                palmWidth: hand.palmWidth
            ))
            : (fire && GestureMath.pinchStartsGrab(
                gate: hand.pinchClosed,
                closedness: hand.pinchClosedness,
                reach: hand.pinchReach,
                index: hand.indexScore,
                zSep: hand.pinchZSep,
                quality: hand.quality,
                approach: hand.pinchZApproach,
                residual: hand.liftResidual,
                palmWidth: hand.palmWidth
            ))
        let advanced = GestureMath.pinchHoldAdvance(
            phase: pinchHoldPhase,
            closed: closedWanted,
            heldFor: pinchHoldFor,
            dt: sampleDt
        )
        pinchHoldPhase = advanced.phase
        pinchHoldFor = advanced.heldFor
        let isGrab = GestureMath.pinchHoldFire(pinchHoldPhase)
        if isGrab && !pinchHeld {
            if GestureMath.pinchReleaseBlocks(now: now, releasedAt: pinchReleasedAt, dt: sampleDt) {
                return
            }
            pinchHeld = true
            pinchBecameDrag = false
            pinchBeganAt = now
            pinchHandID = hand.id
            pinchLastHand = hand
            pinchOriginCursor = cursor
            pinchPeakClosed = hand.pinchClosedness
            pinchPalmMoved = 0
            pinchMissSince = nil
            pinchTrail = [(now, hand.palm.x, hand.palm.y)]
            pinchSpan0 = hand.palm.y
            pinchSpanW = hand.palmWidth
            grabLogged = false
            lastAction = testMode ? "Test: Halten" : "Halten"
        } else if isGrab && pinchHeld {
            pinchPeakClosed = max(pinchPeakClosed, hand.pinchClosedness)
            pinchTrail.append((now, hand.palm.x, hand.palm.y))
            pinchTrail.removeAll { now - $0.t > 0.5 }
            if let first = pinchTrail.first {
                let moved = space.dist(hand.palm, CGPoint(x: first.x, y: first.y)) / max(0.04, hand.palmWidth)
                pinchPalmMoved = max(pinchPalmMoved, moved)
                let cursorPx: CGFloat = {
                    guard let a = pinchOriginCursor, let b = cursor else { return 0 }
                    return hypot(a.x - b.x, a.y - b.y)
                }()
                let vel: CGFloat = {
                    guard pinchTrail.count >= 2 else { return 0 }
                    let a = pinchTrail[pinchTrail.count - 2]
                    let b = pinchTrail[pinchTrail.count - 1]
                    let d = space.dist(CGPoint(x: b.x, y: b.y), CGPoint(x: a.x, y: a.y)) / max(0.04, hand.palmWidth)
                    return GestureMath.pinchPalmVel(movedHW: d, dt: max(0.008, b.t - a.t))
                }()
                if GestureMath.isDrag(palmMovedHW: moved, cursorMovedPx: cursorPx, dt: sampleDt, palmVelHW: vel) {
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
            if pinchBecameDrag,
               now - pinchBeganAt > 0.35,
               let y0 = pinchSpan0,
               !system.isDragging,
               (GestureMath.pullTowardSelf(startY: y0, nowY: hand.palm.y)
                || GestureMath.pullTowardPalmGrow(startW: pinchSpanW ?? hand.palmWidth, nowW: hand.palmWidth))
            {
                perform("Heranziehen", confidence: Float(hand.poseProb)) { system.snapFocused(.fill, at: cursor) }
                pinchSpan0 = hand.palm.y
                pinchSpanW = hand.palmWidth
                cooldownUntil = now + 0.5
            }
        } else if !isGrab && pinchHeld {
            let cursorPx: CGFloat = {
                guard let a = pinchOriginCursor, let b = cursor else { return 0 }
                return hypot(a.x - b.x, a.y - b.y)
            }()
            let wasDrag = pinchBecameDrag
            let held = now - pinchBeganAt
            let palmMoved = pinchPalmMoved
            let peakClosed = max(pinchPeakClosed, hand.pinchClosedness)
            let origin = pinchOriginCursor
            dropPinchHold()
            pinchBecameDrag = false
            pinchHandID = nil
            pinchLastHand = nil
            pinchOriginCursor = nil
            pinchPeakClosed = 0
            pinchPalmMoved = 0
            pinchMissSince = nil
            pinchReleasedAt = now
            let trail = pinchTrail
            pinchTrail.removeAll()
            pinchSpan0 = nil
            pinchSpanW = nil
            grabLogged = false
            trashHot = false
            let hotName = chromeHot
            let knobsNow = chromeKnobs
            if !testMode { system.endWindowDrag() }
            swipeMuteUntil = now + GestureMath.swipeMuteAfterPinch
            if !fire {
                lastAction = "Loslassen"
                return
            }
            let wantsClick = !wasDrag && GestureMath.isClick(
                held: held, palmMovedHW: palmMoved, cursorMovedPx: cursorPx,
                dt: sampleDt, closedness: peakClosed
            )
            let knobHit: ChromeKnob? = {
                guard !wasDrag, !wantsClick, let name = Optional(hotName), !name.isEmpty else { return nil }
                guard let knob = knobsNow.first(where: { $0.labelDE == name }) else { return nil }
                let at = origin ?? cursor ?? knob.center
                guard hypot(at.x - knob.center.x, at.y - knob.center.y) < 26 else { return nil }
                return knob
            }()
            if wantsClick || (!wasDrag && peakClosed >= 0.50 && held >= 0.04 && held <= 1.2 && palmMoved < 0.80) {
                let at = cursor
                perform("Klick", need: .input, confidence: 1) {
                    if let point = at { system.moveCursor(to: point) }
                    return system.click()
                }
            } else if wasDrag {
                pinchTrail = trail
                let flung = resolveFling(
                    now: now,
                    confidence: Float(hand.poseProb),
                    palmWidth: hand.palmWidth,
                    afterDrag: true
                )
                pinchTrail.removeAll()
                if flung {
                    cooldownUntil = now + 0.4
                    chromeKnobs = []
                    chromeHot = ""
                    return
                }
                lastAction = testMode ? "Test: Loslassen" : "Loslassen"
                onLog?("Loslassen", testMode ? .blocked : .executed, Int(hand.poseProb * 100))
            } else if let knob = knobHit {
                fireChrome(knob)
            } else if held < GestureMath.pinchClickMinNeed(dt: sampleDt) {
                lastAction = "zu kurz"
            } else {
                lastAction = "gehalten — kein Zug"
                onLog?("Pinzette gehalten, keine Aktion", .info, Int(hand.poseProb * 100))
            }
            cooldownUntil = now + GestureMath.pinchReleaseNeed(dt: sampleDt)
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
        let kind = GestureMath.flingVelFromTail(
            pinchTrail,
            palmWidth: palmWidth,
            aspect: space.aspect,
            afterDrag: afterDrag,
            screenUV: screenUV,
            windowSec: GestureMath.flingWindowLen(medianDt: sampleDt),
            screenHeight: ScreenGeometry.screenContaining(quartz: cursor ?? .zero)?.frame.height ?? 0
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
        let name = forward ? "Nächster Schreibtisch" : "Vorheriger Schreibtisch"
        perform(name, need: .input, confidence: Float(hand.poseProb)) { system.switchDesktop(forward: forward) }
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

    /// Eine offene Steuerhand vertikal. Zwei offene Palmen gehören dem Not-Aus.
    private func driveScroll(hands: [TrackedHand], preferred: TrackedHand, now: TimeInterval) {
        let open = hands.filter { $0.openScore >= 3 }
        if !GestureMath.scrollAllowed(
            openPalms: open.count,
            pinchHeld: pinchHeld,
            twoPinch: twoPinchSince != nil
        ) || GestureMath.scrollMuteAfterTwoPinch(now: now, endedAt: twoPinchEndedAt) {
            if GestureMath.scrollCoastBreaks(pinchHeld: pinchHeld, twoPinch: twoPinchSince != nil) {
                scrollCoast = nil
                scrollAnchor = nil
                return
            }
            if let coast = scrollCoast, now < coast.until {
                let ticks = GestureMath.scrollCoastTicks(velHW: coast.vel, remain: coast.until - now)
                if ticks != 0 {
                    perform("Scroll", need: .input, confidence: 0.55) { system.scroll(ticks: ticks) }
                }
            } else {
                scrollCoast = nil
            }
            scrollAnchor = nil
            return
        }
        let hand = open.first(where: { $0.id == preferred.id }) ?? open[0]
        let y = hand.palm.y
        let unit = max(0.04, hand.palmWidth)
        guard let a = scrollAnchor else {
            scrollAnchor = (now, y)
            return
        }
        let dy = (y - a.y) / unit
        let dt = now - a.t
        guard dt >= 0.05, abs(dy) > GestureMath.scrollDeadHW else { return }
        let ticks = Int32(max(-24, min(24, -dy * 18)))
        guard ticks != 0 else { return }
        perform("Scroll", need: .input, confidence: Float(hand.poseProb)) { system.scroll(ticks: ticks) }
        scrollAnchor = (now, y)
        scrollCoast = (now + GestureMath.scrollInertia, dy / CGFloat(max(0.05, dt)))
    }

    /// Pinzette + Ringfinger, Mittel nicht gestreckt. Kurzer Halt → Rechtsklick statt Ziehen.
    @discardableResult
    private func driveRightClick(_ hand: TrackedHand, now: TimeInterval) -> Bool {
        let ringOut = hand.isExtended(.ring) && !hand.isExtended(.middle)
        let pinching = hand.pinchClosed || hand.pinchClosedness > 0.55
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
        onLog?("Luft-Tastatur: zehn Fingerkuppen, kurz halten tippt. Faust schließt.", .info, nil)
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

    private static let airTips: [VNHumanHandPoseObservation.JointName] = [
        .thumbTip, .indexTip, .middleTip, .ringTip, .littleTip
    ]

    private func mapTip(_ uv: CGPoint) -> CGPoint {
        if let map = spaceMap, map.isReady { return map.apply(uv) }
        return SpaceMap.linear(uv)
    }

    private func driveKeyboard(hands: [TrackedHand], actor: TrackedHand, now: TimeInterval) {
        let pointing = actor.pose == .point && actor.poseProb >= 0.45
        if !keyboardVisible {
            keyboardHots = []
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
        var hots: Set<String> = []
        var bestHold: CGFloat = 0
        var liveIDs: Set<String> = []
        let dwellNeed = min(0.14, GestureMath.keyboardDwellNeed(dt: sampleDt) * 0.65)
        for hand in hands {
            for tip in Self.airTips {
                guard let uv = hand.point(tip) else { continue }
                let id = "\(hand.id).\(tip.rawValue)"
                liveIDs.insert(id)
                let at = mapTip(uv)
                guard let key = AirLayout.hit(at: at, keys: keyboardHits) else {
                    tipDwell[id] = nil
                    continue
                }
                hots.insert(key.id)
                var slot = tipDwell[id]
                if slot?.key != key.id {
                    slot = (now, key.id, at)
                    tipDwell[id] = slot
                }
                let moved = hypot(at.x - (slot?.pos.x ?? at.x), at.y - (slot?.pos.y ?? at.y))
                if moved > 28 {
                    tipDwell[id] = (now, key.id, at)
                    continue
                }
                let held = now - (slot?.at ?? now)
                bestHold = max(bestHold, CGFloat(min(1, held / dwellNeed)))
                if now < cooldownUntil { continue }
                if held >= dwellNeed {
                    typeAir(key)
                    tipDwell[id] = (now + 0.12, key.id, at)
                    cooldownUntil = now + 0.08
                }
            }
        }
        for k in tipDwell.keys where !liveIDs.contains(k) {
            tipDwell[k] = nil
        }
        keyboardHots = hots
        keyboardHover = hots.sorted().first ?? ""
        keyboardDwell = bestHold
        if hots.isEmpty {
            lastAction = "Tastatur — Finger auf Tasten"
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

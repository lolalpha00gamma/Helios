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
    var palmHighpassPref: CGFloat = GestureMath.palmHighpassAlphaDefault
    var destEdgePadPref: CGFloat = GestureMath.destEdgePad
    var destEdgeSkipPref: TimeInterval = GestureMath.destEdgeCrossHoldSec
    var deadManFistPref: TimeInterval = GestureMath.deadManFist
    var flingWindowPref: TimeInterval = GestureMath.flingWindow
    var fillCapLaptop: CGFloat = 12
    var fillCapStudio: CGFloat = 28
    var fillCapMap: [String: CGFloat] = [:]
    var fillGapMul: Double = 2.4
    var swipeOpenOnly = false
    private var fistClickFrames = 0
    private var lastActorOpenScore = 4
    private var lastActorCurl: [CGFloat] = [0, 0, 0, 0, 0]
    var spaceMap: SpaceMap?
    var calibration: CalibrationSession?
    var trashHot = false
    var killFlash = false
    var dragging = false
    var grabPhase: GrabPhase = .none
    var grabTargetName = ""
    var cursorHand: String = "—"
    var mousePaused = false
    /// Eine Phase für HUD und Gatter, nicht vier Bools.
    var phase: GestureMath.EnginePhase = .idle
    /// Vollbild-Spiel: Idle, Cursor frei.
    var gamePaused = false
    /// Clamshell: Idle unabhängig von Gaze.
    var lidClosed = false
    /// Continuity/Desk-View/USB — nicht Built-in. Clamshell darf leben.
    var cameraFallback = false
    /// click-lock.txt Bundle-IDs.
    var clickLockExtra: Set<String> = []
    /// game-lock.txt — Vollbild dieser Apps pausiert trotz Exempt.
    var gameLockExtra: Set<String> = []
    /// Zweite Hand: ⌘ ⌥ ⇧.
    var modKind: GestureMath.ModKind = .none
    var awaitingRearm: Bool { mustRearm }
    var mapDrifted = false
    var actorHandID: String? {
        if pointerStealLatched { return pointerHandID }
        return pinchActorID ?? pointerHandID
    }
    /// Continuity: 0,12. Built-in: 0,18. AppState setzt das.
    var confidenceFloor: Float = GestureMath.builtInConfidence
    /// Display-ID der letzten Homographie. AppState lädt die Map je Screen.
    private(set) var lastScreenID: String?
    /// fps < 6 für 5 s — Gain halbieren.
    var cameraSlow = false
    /// Median-dt (gedeckelt) für Need.
    var medianFrameDt: TimeInterval { clickNeedDt }
    /// Ungedeckelt — Continuity-Lock ist 500 ms+.
    private(set) var rawFrameDt: TimeInterval = 0.016
    /// HUD-Ring 0…1 während pinchClickMin. nil = kein Settle.
    var clickSettle: CGFloat? {
        guard pinchHeld, !pinchBecameDrag else { return nil }
        return GestureMath.clickSettleProgress(
            held: CACurrentMediaTime() - pinchBeganAt,
            need: GestureMath.pinchClickNeed(dt: clickNeedDt, speed: trailSpeed())
        )
    }
    /// Vor Gate: Pinzette nähert sich. Overlay-Ring füllt gestrichelt.
    var hoverProgress: CGFloat?
    /// Button unter dem Zeiger — HUD „BUTTON“, kein Fenster-Drag.
    var clickLocked: Bool { pressLocksClick }
    /// AX-Miss während Lock. 1 Frame halten.
    private var clickLockMisses = 0
    /// Still-Clutch: Cursor eingefroren. HUD „CLUTCH“, sonst wirkt Helios tot.
    var pointerClutch: Bool { palmFrozen }
    private var lastWarpChip: String?
    private var warpChipHold = 0
    var destEdgeChip: String? {
        let pt = cursorSmooth ?? cursor ?? .zero
        let screens = ScreenGeometry.quartzScreens
        let holding = GestureMath.destEdgeSkipNow(
            crosses: false,
            now: CACurrentMediaTime(),
            lastAt: lastDestCrossAt,
            hold: GestureMath.destEdgeSkipHold(pref: destEdgeSkipPref, frameDt: rawFrameDt)
        ).skip
        let dest = GestureMath.destEdgeScreenAt(
            point: pt,
            screens: screens,
            steal: stealScreen,
            map: spaceMap?.destBounds,
            main: NSScreen.main.map { ScreenGeometry.quartzBounds(of: $0) },
            hold: stealScreen,
            holding: holding
        )
        return GestureMath.destHudChip(
            steal: GestureMath.destMapStealChip(steal: stealScreen, map: spaceMap?.destBounds),
            warp: lastWarpChip,
            edge: GestureMath.destEdgeChipOf(
                point: pt,
                screen: dest,
                pad: GestureMath.destEdgePadNow(screen: dest, pref: destEdgePadPref),
                screens: screens
            )
        )
    }
    var palmHighpassChip: String? {
        GestureMath.palmHighpassChip(actor: pointerHandID, alpha: palmHighpassPref)
    }
    var palmVelChip: String? { lastVelChip }
    var palmLateralityChip: String? { lastLateralityChip }
    var pointerPredictChip: String? { lastPredictChip }
    var fillGapChip: String? { lastFillGapChip }
    var reanchorChip: String? { lastReanchorChip }
    var occlusionChip: String? { lastOcclusionChip }
    var warpWriterChip: String? {
        GestureMath.warpWriterChip(linkArmed: GestureMath.displayLinkPulseAlive(
            lastPulse: lastDisplayTick,
            now: CACurrentMediaTime()
        ))
    }
    /// Traffic-Lights in Magnet-Reichweite. Overlay „MAGNET“.
    var trafficMagnet = false
    /// Quartz-Mitte der drei Lights — Overlay-Ringe.
    var trafficLights: [CGPoint] = []
    /// Während Drag: FLING-Pfeil bevor Loslassen wirft.
    var flingGhostKind: FlingKind = .none
    /// Overlay WEG n% während Settle.
    var travelProgress: CGFloat?

    var hoverKind: GestureMath.HoverRingKind {
        GestureMath.hoverRingKind(
            magnet: trafficMagnet,
            locked: pressLocksClick,
            travel: travelProgress,
            hover: hoverProgress
        )
    }

    var latchChip: String? {
        GestureMath.escapeLatchHUD(now: CACurrentMediaTime(), until: escapeLatchUntil)
    }

    var deadManChip: String? {
        if let fist = GestureMath.deadManFistChip(
            lastFist: lastFistAt,
            lastHand: lastHandSeen,
            now: CACurrentMediaTime(),
            need: deadManFistPref
        ) {
            return fist
        }
        return GestureMath.deadManLabel(
            GestureMath.deadManProgress(lastInterior: lastInteriorSeen, now: CACurrentMediaTime())
        )
    }

    var fistArmChip: String? {
        guard let fistSince else { return nil }
        let need: TimeInterval = mustRearm ? GestureMath.rearmHold : GestureMath.armHold
        return GestureMath.fistArmLabel(
            GestureMath.fistArmProgress(held: CACurrentMediaTime() - fistSince, need: need)
        )
    }

    var modifierChip: String? { GestureMath.modifierChip(modKind) }
    var phaseChip: String { GestureMath.enginePhaseChip(phase) }
    var gameChip: String? { GestureMath.gameModeChip(gamePaused) }
    var slotChip: String? {
        GestureMath.slotChip(id: pointerHandID ?? lastPoolIDs.first)
    }

    var stealChip: String? {
        guard pointerStealLatched else { return nil }
        if let relock = GestureMath.pointerStealRelockHUD(
            held: stealRelockSince.map { CACurrentMediaTime() - $0 }
        ) {
            return relock
        }
        return GestureMath.pointerStealHUD(
            locked: pointerSideLock,
            emptySince: stealSince,
            now: CACurrentMediaTime(),
            dragging: pinchHeld || system.isDragging
        )
    }
    var mapMissingChip: String? {
        GestureMath.mapMissingChip(mapMissingHere)
    }

    var mapMissingHere: Bool {
        GestureMath.mapMissingOnScreen(loadedScreenID: spaceMap?.screenID, currentScreenID: lastScreenID)
    }

    /// Extra-Hold ohne Click-Lock → HUD „RECHTS“.
    var rightHeld: Bool {
        guard pinchHeld, !pinchBecameDrag, !pressLocksClick else { return false }
        return GestureMath.rightClickHold(held: CACurrentMediaTime() - pinchBeganAt, need: clickNeedDt)
    }

    private var fistSince: TimeInterval?
    private var fistLostAt: TimeInterval?
    private var lastFistAt: TimeInterval = 0
    private var lastHandSeen: TimeInterval = 0
    private var lastScrollAt: TimeInterval = 0
    private var lastCoastEnd: TimeInterval = 0
    private var lastCoasting = false
    private var palmSince: TimeInterval?
    private var lastPalmSeen: TimeInterval = 0
    private var thumbsSince: TimeInterval?
    private var peaceSince: TimeInterval?
    private var pinchHeld = false
    private var pinchBecameDrag = false
    private var pinchBeganAt: TimeInterval = 0
    private var pinchTrail: [(t: TimeInterval, x: CGFloat, y: CGFloat)] = []
    private var pinchPalmY0: CGFloat?
    private var grabLogged = false
    private var lastGrabTry: TimeInterval = 0
    private var pressLocksClick = false
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
    private var lastPalm2: CGPoint?
    private var palmDeltas: [CGFloat] = []
    private var palmDeltasX: [CGFloat] = []
    private var palmDeltasY: [CGFloat] = []
    private var lastPalmConf: CGFloat = 1
    private var lastTipHeld = false
    private var palmHoldFill = false
    private var lastLuma: CGFloat = 1
    private var lumaPrev: CGFloat = 1
    private var armedAt: TimeInterval?
    private var lastMapped: CGPoint?
    private var lastMapped2: CGPoint?
    private var lastFlingAt: TimeInterval = 0
    private var pointerHandID: String?
    private var pinchActorID: String?
    private var pinchCursor0: CGPoint?
    private var swipeGraceUntil: TimeInterval = 0
    private var cursorDidMove = false
    private var ignoreGrabUntilOpen = false
    private var palmStillSince: TimeInterval?
    private var palmFrozen = false
    private var warpCapHeld: CGFloat?
    private var warpCapHoldFrames = 0
    private var residualHighSince: TimeInterval?
    private var palmEuroX = PointerEuro()
    private var palmEuroY = PointerEuro()
    private var palmVel = CGPoint.zero
    /// lastMapped-Delta in Quartz-px/s. Fill nicht Palm-Norm × Screen-Breite (Y wäre Aspect-falsch).
    private var palmVelScreen = CGPoint.zero
    private var palmSlowX: CGFloat = 0
    private var palmSlowY: CGFloat = 0
    private var palmSlowActor: String?
    private var palmSlowByActor: [String: (x: CGFloat, y: CGFloat, at: TimeInterval)] = [:]
    private var palmVelActor: String?
    private var lastVelChip: String?
    private var velChipHold = 0
    private var lastVelZeroed = false
    private var lastVelJump = false
    private var jumpMuteFill = false
    private var warpHeldJump = false
    /// destEdgeCross Hold. 1 px Seam-Jitter sonst jedes Frame dämpfen.
    private var lastDestCrossAt: TimeInterval?
    private var lastLateralityChip: String?
    private var lastOcclusionChip: String?
    private var palmVelAt: TimeInterval?
    private var lastPredictChip: String?
    private var lastFillGapChip: String?
    private var lastReanchorChip: String?
    private var lastFillSeen: TimeInterval = 0
    private var fillGapLatched = false
    private var palmKalmanPX: CGFloat = 0
    private var palmKalmanPY: CGFloat = 0
    private var cursorSteps: [CGFloat] = []
    private var handsLostAt: TimeInterval?
    private var actorRebindUntil: TimeInterval = 0
    /// Nach abortGrab den Cursor nicht auf `primary` teleportieren.
    private var pointerFrozenUntil: TimeInterval = 0
    /// Faust-Scharf: Hand muss vorher wirklich offen gewesen sein, sonst zittert eine halboffene Faust.
    private var sawOpen = false
    private var lastPointerT: TimeInterval = 0
    /// Tick-Takt für Need/TTL/Continuity. lastPointerT stampft nur bei Palm-Bewegung.
    private var lastTickT: TimeInterval = 0
    private var lastDisplayTick: TimeInterval = 0
    private var lastCursorMoveAt: TimeInterval = 0
    /// Nach Freeze ersten Sample als Rebase, nicht als Sprung.
    private var pointerNeedsRebase = false
    /// Palm nach pinchClickMin — Zielen in den ersten 120 ms ist kein Drag.
    private var pinchSettlePalm: CGPoint?
    /// Nach Klick: Still-Clutch erst nach clutchGraceHold.
    private var clutchGraceUntil: TimeInterval = 0
    /// Frame-dt vor placeCursor. driveGrab darf lastPointerT nicht als Takt lesen.
    private var frameDt: TimeInterval = 0.016
    /// Median der letzten 8 Sample-dts — Spike darf Need nicht kippen.
    private var sampleDts: [TimeInterval] = []
    private var clickNeedDt: TimeInterval = 0.016
    /// Vorheriger Tick war skipAX — erster frischer Tick kein Down.
    private var prevSkipAX = false
    /// Escape/⌘. Latch: nächster Pinch kein sofortiger Klick.
    private var escapeLatchUntil: TimeInterval = 0
    /// Letzte Hand im Innenraum — Gaze-Idle, Rand-Knie zählt nicht.
    private var lastInteriorSeen: TimeInterval = 0
    /// Letzter Pinch-Klick — Double-Pinch 0,32 s.
    private var lastClickAt: TimeInterval = 0
    /// Letzter Klick wanderte — nächster Pinch kein Doppel.
    private var lastClickTravelled = false
    /// Continuity in der Tasche: Ghost darf Dead-Man nicht halten.
    private var pointerSideLock: GestureMath.PointerSide = .any
    /// Freeze wegen Steal — HUD LOCK, driveGrab tot.
    private var pointerStealLatched = false
    /// Pool leer — Cursor still. Freeze bei Lock-Hand da: Cursor folgt der Lock-Hand.
    private var pointerStealCursor = false
    /// Pool leer seit — Timeout 1,2 s → Idle.
    private var stealSince: TimeInterval?
    /// Faust der anderen Hand seit — Relock erst nach 0,35 s.
    private var stealRelockSince: TimeInterval?
    /// Freeze: Screen unter dem Cursor, nicht nearest mid-Steal.
    private var stealScreen: CGRect?
    /// Reconnect-Pool — actorMapped und pinchActor müssen denselben Slot sehen.
    private var lastPoolIDs: [String] = []
    /// Zweite offene Palme — Gain 0,4.
    private var clutchOtherOpen = false
    private var lastPinchPID: pid_t?
    private var lastFaceSeen: TimeInterval = 0
    /// Screen-Blend 120 ms beim Monitorwechsel.
    private var blendFrom: CGPoint?
    private var blendStarted: TimeInterval = 0
    /// Erster Continuity-Tick nach Lock.
    private var continuityFirstAfterLock = false
    private let system = SystemControl()
    var onLog: ((String, ProtocolKind, Int?) -> Void)?
    var focused: FocusedTarget?
    var pointerMoved: Bool { cursorDidMove }

    func grabOutlineQuartz() -> CGRect? {
        system.dragQuartzFrame(cursor: cursor)
    }

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
        grabPhase = .none
        grabTargetName = ""
        mustRearm = false
        ignoreGrabUntilOpen = false
        pointerOrigin = nil
        cursorSmooth = nil
        lastPalm = nil
        lastPalm2 = nil
        palmDeltas.removeAll()
        palmDeltasX.removeAll()
        palmDeltasY.removeAll()
        lastPalmConf = 1
        lastTipHeld = false
        palmHoldFill = false
        lastMapped = nil
        lastMapped2 = nil
        lastFlingAt = 0
        lastFistAt = 0
        lastScrollAt = 0
        lastCoastEnd = 0
        lastCoasting = false
        modKind = .none
        pointerHandID = nil
        pinchActorID = nil
        pinchCursor0 = nil
        pinchPalmY0 = nil
        pointerStealLatched = false
        pointerStealCursor = false
        stealSince = nil
        stealRelockSince = nil
        stealScreen = nil
        warpCapHeld = nil
        warpCapHoldFrames = 0
        lastPoolIDs = []
        clutchOtherOpen = false
        lastAction = "Reset"
        cooldownUntil = 0
        lastActorOpenScore = 4
        killLatched = false
        armLockUntil = 0
        peaceSince = nil
        thumbsSince = nil
        mousePaused = false
        palmStillSince = nil
        palmFrozen = false
        mapDrifted = false
        residualHighSince = nil
        palmEuroX.reset()
        palmEuroY.reset()
        palmVel = .zero
        palmVelScreen = .zero
        palmSlowX = 0
        palmSlowY = 0
        palmSlowActor = nil
        palmVelActor = nil
        lastVelChip = nil
        velChipHold = 0
        lastVelZeroed = false
        lastVelJump = false
        jumpMuteFill = false
        warpHeldJump = false
        lastDestCrossAt = nil
        lastLateralityChip = nil
        lastOcclusionChip = nil
        palmVelAt = nil
        palmSlowByActor.removeAll()
        lastPredictChip = nil
        lastFillGapChip = nil
        fillGapLatched = false
        palmKalmanPX = 0
        palmKalmanPY = 0
        cursorSteps.removeAll()
        handsLostAt = nil
        actorRebindUntil = 0
        pointerFrozenUntil = 0
        sawOpen = false
        lastPointerT = 0
        lastTickT = 0
        lastDisplayTick = 0
        lastCursorMoveAt = 0
        pointerNeedsRebase = false
        cameraSlow = false
        pinchSettlePalm = nil
        pressLocksClick = false
        clickLockMisses = 0
        clutchGraceUntil = 0
        frameDt = 0.016
        sampleDts = []
        clickNeedDt = 0.016
        rawFrameDt = 0.016
        flingGhostKind = .none
        hoverProgress = nil
        trafficMagnet = false
        trafficLights = []
        travelProgress = nil
        prevSkipAX = false
        escapeLatchUntil = 0
        lastInteriorSeen = 0
        lastFaceSeen = 0
        lastClickAt = 0
        lastClickTravelled = false
        lidClosed = false
        blendFrom = nil
        blendStarted = 0
        lastScreenID = nil
        continuityFirstAfterLock = false
        pointerSideLock = .any
        lastPinchPID = nil
        phase = .idle
        gamePaused = false
        system.cancelPress()
        system.invalidateProbe()
        system.onEscape = nil
    }

    /// Session tot / Kamera-Stopp: Fill nicht in fremde Fenster coasten.
    func muteDisplayFill() {
        lastMapped = nil
        lastMapped2 = nil
        cursorSmooth = nil
        cursor = nil
        palmVel = .zero
        palmVelScreen = .zero
        palmVelAt = nil
        system.endWindowDrag()
        system.cancelPress()
    }

    func tick(hands incoming: [TrackedHand], now: TimeInterval, skipAX: Bool = false, faces: Int = 0, luma: CGFloat = 1) {
        system.skipProbe = skipAX
        lidClosed = Permissions.clamshellClosed()
        system.palmSpeed = trailSpeed()
        lumaPrev = lastLuma
        lastLuma = luma
        if mode == .armed {
            if armedAt == nil { armedAt = now }
        } else {
            armedAt = nil
        }
        defer {
            prevSkipAX = skipAX
            lastTickT = now
            phase = livePhase()
        }
        let hands = incoming.filter {
            GestureMath.tickKeepsGhost(
                isGhost: $0.isGhost,
                joints: $0.joints.count,
                confidence: $0.meanConfidence,
                floor: confidenceFloor
            )
        }
        if hands.isEmpty {
            lastMapped = nil
            lastMapped2 = nil
            palmVelScreen = .zero
            if lastHandSeen > 0, now - lastHandSeen > GestureMath.openMemory {
                sawOpen = false
            }
            if pinchHeld || system.isDragging || system.isMousePressed {
                if handsLostAt == nil { handsLostAt = now }
                if now - (handsLostAt ?? now) < GestureMath.grabAbortHold {
                    if testMode { lastAction = "Hand unsicher" }
                    return
                }
                abortGrab(reason: "Hand verloren — Loslassen", now: now)
            }
            handsLostAt = nil
            let emptyFor = lastHandSeen > 0 ? now - lastHandSeen : GestureMath.slotLatch
            if !GestureMath.slotLatchEmptyKeepsPointer(emptyFor: emptyFor) {
                releasePointer()
                lastPalmSeen = 0
                palmEuroX.reset()
                palmEuroY.reset()
                palmVel = .zero
                palmVelScreen = .zero
                palmSlowX = 0
                palmSlowY = 0
                palmSlowActor = nil
                palmVelActor = nil
                lastVelChip = nil
                velChipHold = 0
                lastVelZeroed = false
                lastVelJump = false
                jumpMuteFill = false
                warpHeldJump = false
                lastDestCrossAt = nil
                lastLateralityChip = nil
                lastOcclusionChip = nil
                palmVelAt = nil
                palmSlowByActor.removeAll()
                lastPredictChip = nil
                lastFillGapChip = nil
                fillGapLatched = false
                palmKalmanPX = 0
                palmKalmanPY = 0
                cursorSteps.removeAll()
            }
            fistSince = nil
            fistLostAt = nil
            palmSince = nil
            peaceSince = nil
            thumbsSince = nil
            killLatched = false
            pinchTrail.removeAll()
            swipeTrail.removeAll()
            swipeHandID = nil
            pinchActorID = nil
            pinchCursor0 = nil
            pinchPalmY0 = nil
            if system.isDragging { system.endWindowDrag() }
            system.cancelPress()
            pinchHeld = false
            pinchBecameDrag = false
            twoPinchSince = nil
            hoverProgress = nil
            trafficMagnet = false
            trafficLights = []
            travelProgress = nil
            flingGhostKind = .none
            trashHot = false
            dragging = false
            grabPhase = .none
            grabTargetName = ""
            palmStillSince = nil
            palmFrozen = false
            residualHighSince = nil
            if GestureMath.deadManFistIdle(lastFist: lastFistAt, lastHand: lastHandSeen, now: now, need: deadManFistPref), mode == .armed {
                mode = .idle
                mustRearm = false
                lastHandSeen = 0
                lastFillSeen = 0
                lastFistAt = 0
                pointerSideLock = .any
                lastAction = "Dead-Man Faust"
                onLog?("Faust weg \(String(format: "%.1f", GestureMath.deadManFistPref(deadManFistPref))) s → Idle", .info, nil)
            } else if lastHandSeen > 0, now - lastHandSeen > GestureMath.deadMan, mode == .armed {
                mode = .idle
                mustRearm = false
                lastHandSeen = 0
                lastFillSeen = 0
                lastFistAt = 0
                pointerSideLock = .any
                lastAction = "Dead-Man Idle"
                onLog?("Keine Hand \(Int(GestureMath.deadMan)) s → Idle", .info, nil)
            } else if !GestureMath.stealHoldsPocket(steal: pointerStealLatched), GestureMath.pocketIdle(
                cameraFallback: cameraFallback,
                lastInterior: lastInteriorSeen,
                now: now
            ), mode == .armed {
                abortGrab(reason: "Tasche", now: now)
                mode = .idle
                mustRearm = false
                pointerSideLock = .any
                lastAction = "Tasche"
                onLog?("Continuity ohne Innenraum → Idle", .info, nil)
            } else if mustRearm {
                mode = .idle
                lastAction = "Not-Aus"
            }
            return
        }
        if hands.contains(where: { GestureMath.obsFillSeesHand(ghost: $0.isGhost) }) {
            lastFillSeen = now
        }
        if hands.contains(where: { GestureMath.liveHandRefreshesDeadMan(ghost: $0.isGhost) }) {
            lastHandSeen = now
        }
        handsLostAt = nil
        let interiorNow = hands.contains {
            !$0.isGhost && GestureMath.armOpenCounts(x: $0.palm.x, y: $0.palm.y)
        }
        if interiorNow { lastInteriorSeen = now }
        let actorID = pinchActorID ?? pointerHandID
        if let other = hands.first(where: { !$0.isGhost && $0.id != actorID }) {
            modKind = GestureMath.modifierKind(
                peace: other.pose == .peace,
                point: other.pose == .point,
                fist: other.pose == .fist
            )
        } else {
            modKind = .none
        }
        if GestureMath.flingUndo(
            now: now,
            lastFling: lastFlingAt,
            peace: hands.contains { !$0.isGhost && $0.pose == .peace },
            pinch: hands.contains { !$0.isGhost && $0.pinchClosed }
        ) {
            lastAction = "Fling-Undo"
            lastFlingAt = 0
            onLog?("Fling-Undo", .executed, nil)
        }
        if faces > 0 { lastFaceSeen = now }
        let extraScreens = NSScreen.screens.count > 1
        if GestureMath.armedIdle(
            faces: faces,
            lastFace: lastFaceSeen,
            lastInterior: lastInteriorSeen,
            now: now,
            lidClosed: lidClosed,
            cameraFallback: cameraFallback,
            extraScreens: extraScreens
        ), mode == .armed, !GestureMath.stealHoldsPocket(steal: pointerStealLatched)
        {
            abortGrab(reason: "Gaze-Idle", now: now)
            mode = .idle
            mustRearm = false
            pointerSideLock = .any
            lastAction = GestureMath.lidBlocksArm(
                lidClosed: lidClosed, cameraFallback: cameraFallback, extraScreens: extraScreens
            )
                ? "Klappe zu"
                : (faces == 0 && lastFaceSeen > 0 ? "Kein Gesicht" : "Gaze-Idle")
            onLog?("Kein Innenraum/Gesicht \(String(format: "%.1f", GestureMath.gazeIdleNeed)) s → Idle", .info, nil)
        }
        if let f = focused {
            let screens = ScreenGeometry.quartzScreens
            let full = screens.contains { GestureMath.gameModeFullscreen(window: f.quartzBounds, screen: $0) }
            gamePaused = GestureMath.gameModePause(
                fullscreen: full, bundle: f.bundleId, extraLock: gameLockExtra
            )
            if gamePaused, mode == .armed {
                abortGrab(reason: "Game-Mode", now: now)
                mode = .idle
                pointerSideLock = .any
                lastAction = "Game-Mode"
                onLog?("Vollbild → Idle", .info, nil)
            }
        } else {
            gamePaused = false
        }
        rawFrameDt = GestureMath.rawFrameDt(now: now, last: lastTickT)
        if rawFrameDt > 0.40 { continuityFirstAfterLock = true }
        let dt = GestureMath.sampleDt(now: now, last: lastTickT)
        frameDt = dt
        sampleDts.append(dt)
        if sampleDts.count > 8 { sampleDts.removeFirst(sampleDts.count - 8) }
        clickNeedDt = GestureMath.medianSampleDt(sampleDts, fallback: dt)
        system.probeTTL = GestureMath.axProbeTTL(dt: dt)
        if skipAX {
            system.invalidateProbe()
            if pinchHeld {
                pinchBeganAt = GestureMath.pinchClockAdvance(beganAt: pinchBeganAt, skipAX: true, dt: dt)
            }
        }
        let blockPress = GestureMath.pressBlockedBySkipAX(skipAX: skipAX, latched: prevSkipAX)
        if hands.contains(where: {
            $0.openScore >= GestureMath.openBeforeArm && GestureMath.armOpenCounts(x: $0.palm.x, y: $0.palm.y)
        }) {
            sawOpen = true
        }
        mousePaused = !system.allowsInjection && !system.fromInstallMedia

        if system.fromInstallMedia {
            lastAction = "Cursor frei — Helios nach Programme ziehen"
            mode = .idle
            if let cal = calibration, cal.active { cal.cancel() }
            releasePointer()
            if system.isDragging { system.endWindowDrag() }
            system.cancelPress()
            pinchHeld = false
            pinchBecameDrag = false
            pinchTrail.removeAll()
            pinchActorID = nil
            pinchCursor0 = nil
            pinchPalmY0 = nil
            peaceSince = nil
            thumbsSince = nil
            return
        }

        // Ghost: letzte Pose halten. Kein Peace/Daumen/Wisch/Scharf/Not-Aus.
        let liveHands = hands.filter { !$0.isGhost }
        if lastCoasting, liveHands.contains(where: { $0.id == "S1" }) {
            lastCoastEnd = now
        }
        lastCoasting = hands.contains { $0.id == "S1" && $0.isGhost }
        if liveHands.isEmpty {
            if !GestureMath.ghostKeepsPool(ghosting: !hands.isEmpty) {
                lastPoolIDs = []
            }
            clutchOtherOpen = false
            if pointerSideLock != .any {
                pointerStealLatched = true
                pointerStealCursor = true
                if pinchHeld || system.isDragging {
                    stealSince = now
                } else if stealSince == nil {
                    stealSince = now
                }
                lastAction = GestureMath.pointerStealHUD(
                    locked: pointerSideLock,
                    emptySince: stealSince,
                    now: now,
                    dragging: pinchHeld || system.isDragging
                )
                if GestureMath.pointerStealTimesOut(
                    emptySince: stealSince,
                    now: now,
                    poolEmpty: true,
                    dragging: pinchHeld || system.isDragging,
                    ghosting: !hands.isEmpty
                ) {
                    stealGoIdle(now: now)
                    return
                }
            } else {
                pointerStealLatched = false
                pointerStealCursor = false
            }
            holdGhost(hands, now: now)
            return
        }

        if let cal = calibration, cal.active {
            let actor = preferred(liveHands)
            let confirm = actor.pinchClosed || actor.pose == .pinch
            if let done = cal.feed(palm: actor.palm, now: now, confirm: confirm) {
                spaceMap = done
                mapDrifted = false
                residualHighSince = nil
                lastAction = "Kalibrierung fertig"
                onLog?("Kalibrierung · 4 Ecken", .executed, 100)
                pinchHeld = false
                pinchBecameDrag = false
                cooldownUntil = now + 1.1
            } else {
                lastAction = cal.hint
            }
            cursor = SpaceMap.linear(actor.palm, in: cal.visQuartz)
            cursorHand = actor.sideDE
            return
        }

        let primary = preferred(liveHands)
        let live = mode == .armed || testMode

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

        if handleKillSwitch(hands: liveHands, now: now) {
            return
        }

        if mousePaused {
            lastAction = "Maus hat Vorrang"
            placeCursor(primary, now: now)
            grabPhase = .follow
            grabTargetName = focused?.appName ?? ""
            dragging = false
            hoverProgress = nil
            if system.isDragging { system.endWindowDrag() }
            system.cancelPress()
            pinchHeld = false
            pinchBecameDrag = false
            return
        }

        handleArming(hands: liveHands, now: now)


        if !live {
            injectCursor(primary, now: now)
            grabPhase = (primary.pose == .pinch || primary.pose == .fist) ? .hold : .follow
            grabTargetName = focused?.appName ?? ""
            if liveHands.contains(where: { $0.pose == .pinch || $0.pose == .fist }) {
                lastAction = mustRearm ? "Nach Not-Aus: Faust \(String(format: "%.2f", GestureMath.rearmHold)) s" : "Faust halten → Scharf"
            }
            dragging = false
            return
        }

        let poolIDs = GestureMath.pointerPoolReconnect(
            locked: pointerSideLock,
            candidates: liveHands.map { ($0.id, pointerSide(of: $0), $0.palm.x, $0.palm.y) },
            keepID: pointerHandID ?? pinchActorID,
            lastX: lastPalm?.x,
            lastY: lastPalm?.y,
            last2X: lastPalm2?.x,
            last2Y: lastPalm2?.y,
            dt: rawFrameDt
        )
        lastPoolIDs = poolIDs
        clutchOtherOpen = liveHands.contains {
            $0.id != (pointerHandID ?? pinchActorID ?? primary.id)
                && $0.isOpenEnough
                && !$0.pinchClosed
        }
        if let kept = GestureMath.pointerKeepPerHand(
            keepIDs: [pointerHandID, pinchActorID].compactMap { $0 },
            poolIDs: poolIDs
        ) {
            pointerHandID = kept
        }
        let actor = pinchActor(liveHands, primary: primary, now: now)
        if GestureMath.fistCancelsHold(
            pinchHeld: pinchHeld,
            otherFist: liveHands.contains { $0.id != actor.id && $0.pose == .fist }
        ) {
            cancelHold(now: now)
            lastAction = "Faust bricht Pinch"
            return
        }
        let stealFreeze = GestureMath.pointerFreezesSteal(
            locked: pointerSideLock,
            candidate: pointerSide(of: actor),
            sameSlot: GestureMath.pointerSameSlot(
                keepID: pointerHandID,
                actorID: actor.id,
                poolIDs: poolIDs
            )
        )
        pointerStealLatched = GestureMath.pointerStealBlocksActor(
            poolEmpty: poolIDs.isEmpty,
            freeze: stealFreeze
        )
        pointerStealCursor = poolIDs.isEmpty
        if pointerStealLatched {
            if pinchHeld || system.isDragging {
                stealSince = now
            } else if poolIDs.isEmpty {
                if stealSince == nil { stealSince = now }
            } else {
                stealSince = nil
            }
            lastAction = GestureMath.pointerStealHUD(
                locked: pointerSideLock,
                emptySince: poolIDs.isEmpty ? stealSince : nil,
                now: now,
                dragging: pinchHeld || system.isDragging
            )
            if GestureMath.pointerStealTimesOut(
                emptySince: stealSince,
                now: now,
                poolEmpty: poolIDs.isEmpty,
                dragging: pinchHeld || system.isDragging
            ) {
                stealGoIdle(now: now)
                return
            }
        } else {
            stealSince = nil
            stealRelockSince = nil
        }
        let cursorHandLive: TrackedHand = {
            if stealFreeze, !poolIDs.isEmpty { return preferred(liveHands) }
            return actor
        }()
        let freezePointer = GestureMath.pointerFrozenWhile(
            abortHold: now < pointerFrozenUntil,
            mouseDown: system.isMousePressed,
            clickLocked: pressLocksClick,
            becameDrag: pinchBecameDrag,
            pinchHeld: pinchHeld
        ) || GestureMath.pointerStealBlocksCursor(steal: poolIDs.isEmpty)
        if freezePointer {
            // Pool leer: lastPalm nicht von der anderen Hand — sonst Reconnect an sie.
            if !GestureMath.stealHoldsPalm(poolEmpty: poolIDs.isEmpty) {
                rememberPalm(cursorHandLive.palm)
            }
            lastPointerT = now
        } else {
            injectCursor(cursorHandLive, now: now)
        }
        if !testMode, system.isMousePressed, !system.isDragging, !poolIDs.isEmpty, let p = cursor {
            system.moveCursor(to: p)
        }
        updateTrashHot()

        let gated = now < cooldownUntil
        let scaling = handleTwoPinchScale(hands: liveHands, now: now, gated: gated)
        if scaling {
            lastAction = GestureMath.scaleStealHUD()
        }
        if !scaling, !pointerStealLatched {
            driveGrab(actor, hands: liveHands, now: now, blockPress: blockPress)
            if !gated {
                driveSwipe(hands: liveHands, actor: actor, now: now)
                drivePeace(actor, hands: liveHands, now: now)
                driveThumbs(actor, hands: liveHands, now: now)
            }
        } else if !scaling {
            system.cancelPress()
        }
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
        if pinchHeld {
            hoverProgress = nil
            trafficLights = system.trafficLightPoints(at: cursor)
            trafficMagnet = pressLocksClick && system.trafficMagnet(at: cursor, palmScale: actor.palmScale)
        } else {
            hoverProgress = GestureMath.pinchHoverProgress(
                ratio: actor.pinchRatio,
                closed: actor.pinchClosed
            )
            trafficLights = system.trafficLightPoints(at: cursor)
            trafficMagnet = system.trafficMagnet(at: cursor, palmScale: actor.palmScale)
        }
        if palmFrozen, grabPhase == .follow, let clutch = GestureMath.clutchHUD(frozen: true) {
            lastAction = clutch
        }
        if let latch = GestureMath.escapeLatchHUD(now: now, until: escapeLatchUntil) {
            lastAction = latch
        }
    }

    func forceIdle() {
        abortGrab(reason: testMode ? "Idle (Test)" : "Manuell Idle")
        mode = .idle
        mustRearm = true
        twoPinchSince = nil
        twoHandSpan = nil
        fistSince = nil
        fistLostAt = nil
        peaceSince = nil
        thumbsSince = nil
        armLockUntil = 0
        lastAction = "Idle"
        onLog?(testMode ? "Idle (Test)" : "Manuell Idle", .info, nil)
    }

    func forceArm() {
        mode = .armed
        mustRearm = false
        ignoreGrabUntilOpen = true
        lastAction = "Scharf"
        onLog?(testMode ? "Scharf (Test)" : "Manuell Scharf", .info, nil)
    }

    func startInputClutch() {
        system.onEscape = { [weak self] in self?.cancelHold() }
        system.startClutch()
    }

    /// Escape vor Down: Pinch tot, kein Klick.
    func cancelHold(now: TimeInterval = CACurrentMediaTime()) {
        guard pinchHeld || system.isMousePressed || system.isDragging else { return }
        pinchHeld = false
        pinchBecameDrag = false
        pinchTrail.removeAll()
        pinchPalmY0 = nil
        pinchSettlePalm = nil
        pinchActorID = nil
        pinchCursor0 = nil
        grabLogged = false
        trashHot = false
        pressLocksClick = false
        clickLockMisses = 0
        hoverProgress = nil
        trafficMagnet = false
        trafficLights = []
        travelProgress = nil
        clutchGraceUntil = now + GestureMath.clutchGraceHold
        escapeLatchUntil = now + GestureMath.escapeLatchHold
        system.endWindowDrag()
        system.cancelPress()
        lastAction = "Escape"
        cooldownUntil = now + GestureMath.clickCooldown
        dragging = false
        grabPhase = .follow
    }

    func recenterPointer() {
        lastPalm = nil
        lastPalm2 = nil
        palmDeltas.removeAll()
        palmDeltasX.removeAll()
        palmDeltasY.removeAll()
        lastPalmConf = 1
        lastTipHeld = false
        palmHoldFill = false
        lastMapped = nil
        lastMapped2 = nil
        pointerHandID = nil
        cursorSmooth = nil
        palmEuroX.reset()
        palmEuroY.reset()
        palmVel = .zero
        palmVelScreen = .zero
        palmSlowX = 0
        palmSlowY = 0
        palmSlowActor = nil
        palmVelActor = nil
        lastVelChip = nil
        velChipHold = 0
        lastVelZeroed = false
        lastVelJump = false
        jumpMuteFill = false
        warpHeldJump = false
        lastDestCrossAt = nil
        lastLateralityChip = nil
        lastOcclusionChip = nil
        palmVelAt = nil
        palmSlowByActor.removeAll()
        lastPredictChip = nil
        lastFillGapChip = nil
        fillGapLatched = false
        palmKalmanPX = 0
        palmKalmanPY = 0
        cursorSteps.removeAll()
        lastPointerT = 0
        lastTickT = 0
        lastDisplayTick = 0
        lastCursorMoveAt = 0
        pointerNeedsRebase = true
        residualHighSince = nil
        sampleDts = []
        clickNeedDt = 0.016
        rawFrameDt = 0.016
        frameDt = 0.016
    }

    func noteScreenChange() {
        let cam = spaceMap?.cameraID
        if let sid = lastScreenID,
           let loaded = SpaceMap.load(cameraID: cam, screenID: sid),
           loaded.isUsable
        {
            spaceMap = loaded
        }
        if spaceMap?.isReady == true {
            mapDrifted = true
        }
        recenterPointer()
        system.invalidateProbe()
        lastAction = "Monitor-Wechsel"
    }

    func invalidateAXProbe() {
        system.invalidateProbe()
    }

    /// Dunkel ≠ Hand weg. Grab bleibt. Dead-Man zählt weiter. AX nicht auf totem Cursor.
    /// Continuity in der Tasche: Vision aus, Tick kommt nicht — pocketIdle hier, sonst 8 s Scharf.
    func noteDarkFrame(now: TimeInterval) {
        pointerNeedsRebase = true
        actorRebindUntil = max(actorRebindUntil, GestureMath.darkHoldsRebind(now: now))
        system.skipProbe = GestureMath.axProbeSkip(visionRan: false)
        if GestureMath.pocketIdle(
            cameraFallback: cameraFallback,
            lastInterior: lastInteriorSeen,
            now: now
        ), mode == .armed, !GestureMath.stealHoldsPocket(steal: pointerStealLatched) {
            abortGrab(reason: "Tasche", now: now)
            mode = .idle
            mustRearm = false
            pointerSideLock = .any
            lastAction = "Tasche"
            onLog?("Continuity dunkel ohne Innenraum → Idle", .info, nil)
            return
        }
        if GestureMath.deadManFistIdle(lastFist: lastFistAt, lastHand: lastHandSeen, now: now, need: deadManFistPref), mode == .armed {
            mode = .idle
            mustRearm = false
            lastHandSeen = 0
            lastFillSeen = 0
            lastFistAt = 0
            pointerSideLock = .any
            abortGrab(reason: "Dead-Man Faust", now: now)
            onLog?("Faust weg \(String(format: "%.1f", GestureMath.deadManFistPref(deadManFistPref))) s → Idle", .info, nil)
        } else if lastHandSeen > 0, now - lastHandSeen > GestureMath.deadMan, mode == .armed {
            mode = .idle
            mustRearm = false
            lastHandSeen = 0
            lastFillSeen = 0
            lastFistAt = 0
            pointerSideLock = .any
            abortGrab(reason: "Dead-Man Idle", now: now)
            onLog?("Keine Hand \(Int(GestureMath.deadMan)) s → Idle", .info, nil)
        }
    }

    private func rememberPalm(_ p: CGPoint) {
        lastPalm2 = lastPalm
        lastPalm = p
    }

    private func notePalmDelta(_ d: CGFloat) {
        palmDeltas.append(d)
        if palmDeltas.count > 12 { palmDeltas.removeFirst(palmDeltas.count - 12) }
    }

    private func notePalmAxis(dx: CGFloat, dy: CGFloat) {
        notePalmDelta(hypot(dx, dy))
        palmDeltasX.append(abs(dx))
        palmDeltasY.append(abs(dy))
        if palmDeltasX.count > 12 { palmDeltasX.removeFirst(palmDeltasX.count - 12) }
        if palmDeltasY.count > 12 { palmDeltasY.removeFirst(palmDeltasY.count - 12) }
    }

    private func deadNow() -> CGFloat {
        GestureMath.palmDeadAdaptive(
            palmDeltas,
            window: GestureMath.palmDeadWindow(dt: rawFrameDt)
        )
    }

    private func madNowX() -> CGFloat {
        GestureMath.palmMad(palmDeltasX, window: GestureMath.palmDeadWindow(dt: rawFrameDt))
    }

    private func madNowY() -> CGFloat {
        GestureMath.palmMad(palmDeltasY, window: GestureMath.palmDeadWindow(dt: rawFrameDt))
    }

    private func deadNowX() -> CGFloat {
        GestureMath.palmDeadOf(mad: madNowX())
    }

    private func deadNowY() -> CGFloat {
        GestureMath.palmDeadOf(mad: madNowY())
    }

    private func warpCap() -> CGFloat {
        let base = GestureMath.cursorWarpCap(
            medianStep: GestureMath.medianCursorStep(cursorSteps),
            floor: GestureMath.cursorWarpFloor(
                dt: rawFrameDt,
                continuity: cameraFallback,
                lumaWarp: GestureMath.palmHolds(
                    armedAt: armedAt, now: CACurrentMediaTime(), luma: lastLuma, prevLuma: lumaPrev,
                    conf: lastPalmConf, continuity: cameraFallback, tipHeld: lastTipHeld
                )
            )
        )
        let live = GestureMath.cursorWarpCapScreenOf(steal: stealScreen, map: spaceMap?.destBounds)
        let held = GestureMath.cursorWarpCapHold(prev: warpCapHeld, live: live, frames: warpCapHoldFrames)
        noteWarpCap(live)
        return max(base, held)
    }

    private func warpCapAxes() -> (x: CGFloat, y: CGFloat) {
        let iso = warpCap()
        let axis = GestureMath.cursorWarpCapAxis(steal: stealScreen, map: spaceMap?.destBounds)
        return (max(iso, axis.x), max(iso, axis.y))
    }

    private func noteWarpCap(_ live: CGFloat) {
        if stealRelockSince != nil {
            warpCapHeld = max(warpCapHeld ?? live, live)
            warpCapHoldFrames = 1
        } else if warpCapHoldFrames > 0 {
            warpCapHoldFrames += 1
            if warpCapHoldFrames > 3 {
                warpCapHoldFrames = 0
                warpCapHeld = live
            } else {
                warpCapHeld = max(warpCapHeld ?? live, live)
            }
        } else {
            warpCapHeld = live
        }
    }

    private func noteCursorStep(from: CGPoint, to: CGPoint) {
        cursorSteps.append(hypot(to.x - from.x, to.y - from.y))
        if cursorSteps.count > 8 { cursorSteps.removeFirst(cursorSteps.count - 8) }
    }

    private func releasePointer() {
        cursor = nil
        lastPalm = nil
        lastPalm2 = nil
        palmDeltas.removeAll()
        palmDeltasX.removeAll()
        palmDeltasY.removeAll()
        lastPalmConf = 1
        lastTipHeld = false
        palmHoldFill = false
        lastMapped = nil
        lastMapped2 = nil
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
        let open = hands.filter {
            $0.isOpenEnough && GestureMath.killCounts(x: $0.palm.x, y: $0.palm.y)
        }
        let liveHandsReach = hands.contains {
            GestureMath.palmReachKills(
                palmScale: $0.palmScale,
                openScore: $0.openScore,
                dt: rawFrameDt,
                side: pointerSide(of: $0),
                locked: pointerSideLock
            )
        }
        if open.count >= 2 || liveHandsReach {
            let panic = GestureMath.panicKill(openScores: open.map(\.openScore)) || liveHandsReach
            if killLatched {
                lastAction = "Not-Aus"
                mode = .idle
                pointerSideLock = .any
                return true
            }
            if palmSince == nil { palmSince = now }
            lastPalmSeen = now
            let held = now - (palmSince ?? now)
            if panic || held >= GestureMath.killHold {
                abortGrab(reason: "Not-Aus", now: now)
                mode = .idle
                mustRearm = true
                killLatched = true
                pointerSideLock = .any
                armLockUntil = now + 1.6
                fistSince = nil
                ignoreGrabUntilOpen = false
                lastAction = "Not-Aus"
                onLog?(
                    liveHandsReach
                        ? "Palm-Reach → Not-Aus. Bleibt Idle, bis Faust hält."
                        : "Beide Hände offen → Not-Aus. Bleibt Idle, bis Faust hält.",
                    .info,
                    nil
                )
                killFlash = true
                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    await MainActor.run { self?.killFlash = false }
                }
                cooldownUntil = now + GestureMath.killCooldown
                return true
            }
            lastAction = String(format: "Not-Aus halten · %.0f %%", min(100, held / GestureMath.killHold * 100))
            if pinchHeld || system.isDragging {
                pinchHeld = false
                pinchBecameDrag = false
                system.endWindowDrag()
                system.cancelPress()
            }
            if GestureMath.killKeepsCursor() {
                injectCursor(preferred(hands), now: now)
            }
            return true
        }
        if now - lastPalmSeen < GestureMath.killGrace, palmSince != nil {
            if GestureMath.killKeepsCursor() {
                injectCursor(preferred(hands), now: now)
            } else {
                placeCursor(preferred(hands), now: now)
            }
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
        if GestureMath.calibBlocksArm(active: calibration?.active == true, testMode: testMode) {
            lastAction = calibration?.hint ?? "Erst kalibrieren"
            return
        }
        if GestureMath.phaseBlocksArm(
            lidClosed: lidClosed,
            gamePaused: gamePaused,
            cameraFallback: cameraFallback,
            extraScreens: NSScreen.screens.count > 1
        ) {
            let lid = GestureMath.lidBlocksArm(
                lidClosed: lidClosed,
                cameraFallback: cameraFallback,
                extraScreens: NSScreen.screens.count > 1
            )
            let actor = preferred(hands)
            let fisting = actor.pose == .fist || (actor.openScore == 0 && actor.pinchRatio > 0.5 && actor.meanConfidence > 0.35)
            if fisting {
                if fistSince == nil { fistSince = now }; lastFistAt = now
                let need: TimeInterval = mustRearm ? GestureMath.rearmHold : GestureMath.armHold
                let held = now - (fistSince ?? now)
                let prog = GestureMath.fistArmLabel(GestureMath.fistArmProgress(held: held, need: need))
                lastAction = (lid ? "Klappe zu" : "Game-Mode") + (prog.map { " · \($0)" } ?? "")
            } else {
                fistSince = nil
                lastAction = lid ? "Klappe zu" : "Game-Mode"
            }
            return
        }
        if mode == .armed {
            let actor = preferred(hands)
            let freeze = GestureMath.pointerFreezesSteal(
                locked: pointerSideLock,
                candidate: pointerSide(of: actor),
                sameSlot: GestureMath.pointerSameSlot(
                    keepID: pointerHandID,
                    actorID: actor.id,
                    poolIDs: GestureMath.pointerPoolReconnect(
                        locked: pointerSideLock,
                        candidates: hands.map { ($0.id, pointerSide(of: $0), $0.palm.x, $0.palm.y) },
                        keepID: pointerHandID ?? pinchActorID,
                        lastX: lastPalm?.x,
                        lastY: lastPalm?.y,
                        last2X: lastPalm2?.x,
                        last2Y: lastPalm2?.y,
                        dt: rawFrameDt
                    )
                )
            )
            let fisting = actor.pose == .fist || (actor.openScore == 0 && actor.pinchRatio > 0.5 && actor.meanConfidence > 0.35)
            if freeze && fisting {
                if stealRelockSince == nil { stealRelockSince = now }
                let held = now - (stealRelockSince ?? now)
                let skip = NSEvent.modifierFlags.contains(.option)
                if GestureMath.pointerStealRelock(freeze: freeze, otherFist: fisting, held: held, modifierSkip: skip) {
                    pointerSideLock = .any
                    pointerHandID = actor.id
                    pointerStealLatched = false
                    pointerStealCursor = false
                    stealSince = nil
                    stealRelockSince = nil
                    lastAction = "Scharf \(actor.sideDE)"
                    onLog?("Faust → Lock \(actor.sideDE)", .executed, Int(actor.meanConfidence * 100))
                } else {
                    lastAction = GestureMath.pointerStealRelockHUD(held: held)
                        ?? GestureMath.pointerStealHUD(locked: pointerSideLock)
                }
            } else {
                stealRelockSince = nil
            }
            return
        }

        let actor = preferred(hands)
        let fisting = actor.pose == .fist || (actor.openScore == 0 && actor.pinchRatio > 0.5 && actor.meanConfidence > 0.35)
        if mustRearm, !fisting {
            lastAction = "Nach Not-Aus: Faust halten"
            return
        }
        if fistSince == nil { fistSince = now }
        lastFistAt = now
        let need: TimeInterval = mustRearm ? GestureMath.rearmHold : GestureMath.armHold
        let held = now - (fistSince ?? now)
        if held >= need, now - lastArmToggle > GestureMath.armCooldown {
            lastArmToggle = now
            fistSince = nil
            mustRearm = false
            ignoreGrabUntilOpen = true
            mode = .armed
            pointerSideLock = .any
            lastAction = "Scharf"
            cooldownUntil = now + GestureMath.armCooldown
            onLog?("Hand → Scharf", .executed, Int((hands.map(\.meanConfidence).max() ?? 0) * 100))
        } else if held >= 0.08 {
            lastAction = GestureMath.fistArmLabel(
                GestureMath.fistArmProgress(held: held, need: need)
            ) ?? "Scharf …"
        }
    }

    private func pointerSide(of hand: TrackedHand) -> GestureMath.PointerSide {
        switch hand.chirality {
        case .left: return .left
        case .right: return .right
        default: return .any
        }
    }

    private func preferred(_ hands: [TrackedHand]) -> TrackedHand {
        let keep = pointerHandID ?? pinchActorID
        let ids = GestureMath.pointerPoolReconnect(
            locked: pointerSideLock,
            candidates: hands.map { ($0.id, pointerSide(of: $0), $0.palm.x, $0.palm.y) },
            keepID: keep,
            lastX: lastPalm?.x,
            lastY: lastPalm?.y,
            last2X: lastPalm2?.x,
            last2Y: lastPalm2?.y,
            dt: rawFrameDt
        )
        let pool = ids.compactMap { id in hands.first(where: { $0.id == id }) }
        if !GestureMath.preferredKeepsPool(poolEmpty: pool.isEmpty) {
            if let id = keep, let same = hands.first(where: { $0.id == id }) {
                return same
            }
            if let nearest = GestureMath.preferredNearest(
                keepID: keep,
                poolEmpty: true,
                hands: hands.map { (id: $0.id, x: $0.palm.x, y: $0.palm.y) },
                lastX: lastPalm?.x,
                lastY: lastPalm?.y
            ), let hand = hands.first(where: { $0.id == nearest }) {
                return hand
            }
            return hands.first(where: { $0.id == "S1" }) ?? hands[0]
        }
        let use = pool
        if use.count == 1 { return use[0] }
        // Slot vor Chirality — sonst teleportiert der Zeiger nach L↔R / Abort.
        if let id = keep, let same = use.first(where: { $0.id == id }) {
            return same
        }
        if leftHanded, let left = use.first(where: { $0.chirality == .left }) {
            return left
        }
        if !leftHanded, let right = use.first(where: { $0.chirality == .right }) {
            return right
        }
        return use.max { a, b in
            (a.joints.values.map(\.confidence).max() ?? 0) < (b.joints.values.map(\.confidence).max() ?? 0)
        } ?? use[0]
    }

    private func pinchActor(_ hands: [TrackedHand], primary: TrackedHand, now: TimeInterval) -> TrackedHand {
        let pool = lastPoolIDs.compactMap { id in hands.first(where: { $0.id == id }) }
        if pinchHeld, let id = pinchActorID {
            if GestureMath.pinchActorKeeps(id: id, poolIDs: lastPoolIDs),
               let same = hands.first(where: { $0.id == id })
            {
                return same
            }
            // Nur Lock-Pool. last-3 analog pointerPoolReconnect, nicht nur pinchTrail.last.
            let last2 = pinchTrail.count >= 2 ? pinchTrail[pinchTrail.count - 2] : nil
            if let rebound = GestureMath.actorRebindRing(
                lostID: id,
                candidates: pool.map { (id: $0.id, x: $0.palm.x, y: $0.palm.y) },
                lastX: pinchTrail.last?.x ?? lastPalm?.x,
                lastY: pinchTrail.last?.y ?? lastPalm?.y,
                last2X: last2?.x ?? lastPalm2?.x,
                last2Y: last2?.y ?? lastPalm2?.y,
                dt: rawFrameDt
            ),
               let hand = hands.first(where: { $0.id == rebound })
            {
                pinchActorID = hand.id
                actorRebindUntil = now + GestureMath.grabAbortHold
                return hand
            }
            abortGrab(reason: "Hand verloren — Loslassen", now: now)
            pointerFrozenUntil = now + GestureMath.grabAbortHold
            pointerNeedsRebase = true
            return primary
        }
        guard GestureMath.pinchActorScanPool(poolIDs: lastPoolIDs), !pool.isEmpty else {
            return primary
        }
        if let pinching = pool.filter({ $0.pinchClosed || $0.pose == .pinch }).min(by: { $0.pinchRatio < $1.pinchRatio }) {
            pinchActorID = pinching.id
            return pinching
        }
        if let fist = pool.first(where: { $0.pose == .fist }) {
            return fist
        }
        return primary
    }

    private func abortGrab(reason: String, now: TimeInterval = CACurrentMediaTime()) {
        if system.isDragging { system.endWindowDrag() }
        pinchHeld = false
        pinchBecameDrag = false
        pinchTrail.removeAll()
        pinchPalmY0 = nil
        pinchSettlePalm = nil
        pinchActorID = nil
        pinchCursor0 = nil
        grabLogged = false
        trashHot = false
        dragging = false
        ignoreGrabUntilOpen = true
        pressLocksClick = false
        clickLockMisses = 0
        flingGhostKind = .none
        hoverProgress = nil
        trafficMagnet = false
        trafficLights = []
        travelProgress = nil
        cooldownUntil = max(cooldownUntil, now + GestureMath.grabAbortHold)
        actorRebindUntil = 0
        pointerFrozenUntil = max(pointerFrozenUntil, now + GestureMath.grabAbortHold)
        pointerNeedsRebase = true
        system.cancelPress()
        clutchGraceUntil = now + GestureMath.clutchGraceHold
        lastAction = reason
    }

    private func actorMapped(_ hand: TrackedHand, now: TimeInterval) -> CGPoint {
        let palm = hand.palm
        if GestureMath.pointerFreezesSteal(
            locked: pointerSideLock,
            candidate: pointerSide(of: hand),
            sameSlot: GestureMath.pointerSameSlot(
                keepID: pointerHandID,
                actorID: hand.id,
                poolIDs: lastPoolIDs
            )
        ) {
            cursorDidMove = false
            return cursorSmooth ?? snapPalm(palm)
        }
        if now < pointerFrozenUntil {
            return cursorSmooth ?? snapPalm(palm)
        }
        pointerNeedsRebase = false
        pointerHandID = hand.id
        rememberPalm(palm)
        palmVel = .zero
        palmVelScreen = .zero
        lastVelJump = false
        lastVelZeroed = true
        jumpMuteFill = true
        warpHeldJump = false
        palmHoldFill = false
        palmFrozen = false
        cursorDidMove = true
        lastPointerT = now
        lastDisplayTick = now
        let q = snapPalm(palm)
        cursorSmooth = q
        lastMapped = q
        lastMapped2 = q
        seedLastScreen(point: q)
        return q
    }

    /// Palme im Bild = Cursor auf dem Schirm. Keine Homographie: alte Kalib war Cursor-Ecke, nicht Reichweite.
    private func snapPalm(_ palm: CGPoint) -> CGPoint {
        clampMapped(SpaceMap.linear(palm), freeze: pointerStealLatched || pointerStealCursor)
    }

    /// Relativ-Pfad und displayTick: Screen unter dem Cursor, Freeze hält lastScreen.
    private func clampMapped(_ p: CGPoint, freeze: Bool) -> CGPoint {
        let screens = ScreenGeometry.quartzScreens
        let bounds = GestureMath.destClampScreen(
            point: p,
            mapBounds: spaceMap?.destBounds,
            screens: screens,
            freeze: freeze,
            lastScreen: stealScreen,
            mapScreenID: spaceMap?.screenID,
            currentScreenID: lastScreenID
        )
        if !freeze {
            stealScreen = bounds
            seedLastScreen(point: p)
        }
        return ScreenGeometry.clampQuartz(GestureMath.destClamp(p, bounds: bounds))
    }

    private func quartzScreenRows() -> [(id: String, bounds: CGRect)] {
        NSScreen.screens.map { scr in
            (id: "\(ScreenGeometry.displayID(of: scr))", bounds: ScreenGeometry.quartzBounds(of: scr))
        }
    }

    /// Relativ-Pfad sonst lastScreenID=nil für immer. destClampMap Latch tot, SpaceMap.load falsch.
    private func seedLastScreen(point: CGPoint) {
        lastScreenID = GestureMath.screenKeySeed(point: point, screens: quartzScreenRows(), current: lastScreenID)
    }

    /// Atem raus, Flick bleibt. Slow je Hand — S1-Tremor nicht auf S2.
    /// Ghost hält S1-Slow. Neue Hand seedet Slow=dx (erster fast 0).
    /// Nach TTL 2 s: gespeicherte Slow tot, sonst Dropout-Restore = Sprung.
    /// JUMP/Hold: Slow=dx, sonst Atem-DC reißt nach Restore.
    private func applyPalmHighpass(dx: inout CGFloat, dy: inout CGFloat, now: TimeInterval) {
        let actor = pointerHandID
        if GestureMath.palmHighpassMutesJump(jumpMuteFill || lastVelJump || warpHeldJump) {
            let loaded = GestureMath.palmHighpassLoad(savedX: nil, savedY: nil, dx: dx, dy: dy, fresh: false)
            palmSlowX = loaded.x
            palmSlowY = loaded.y
        } else if GestureMath.palmHighpassResets(actor: actor, prev: palmSlowActor) {
            let saved = actor.flatMap { palmSlowByActor[$0] }
            let fresh = GestureMath.palmHighpassFresh(savedAt: saved?.at, now: now)
            let loaded = GestureMath.palmHighpassLoad(
                savedX: saved?.x,
                savedY: saved?.y,
                dx: dx,
                dy: dy,
                fresh: fresh
            )
            palmSlowX = loaded.x
            palmSlowY = loaded.y
            palmSlowActor = actor
        }
        let hx = GestureMath.palmHighpass(
            dx: dx,
            slow: palmSlowX,
            alpha: GestureMath.palmHighpassAlpha(palmHighpassPref)
        )
        let hy = GestureMath.palmHighpass(
            dx: dy,
            slow: palmSlowY,
            alpha: GestureMath.palmHighpassAlpha(palmHighpassPref)
        )
        palmSlowX = hx.slow
        palmSlowY = hy.slow
        if let actor {
            palmSlowByActor[actor] = (palmSlowX, palmSlowY, now)
            if palmSlowByActor.count > 4 {
                palmSlowByActor = [actor: (palmSlowX, palmSlowY, now)]
            }
        }
        dx = hx.fast
        dy = hy.fast
    }

    /// Atem/Schulter unter palmStill → nach palmStillHold kein Cursor. Aufwachen über palmUnstillOf.
    /// Während Pinch/Down nicht: die Hand ist still, Clutch nach Klick tötet den Zeiger.
    /// Nach Klick clutchGraceHold: Loslassen ist still, der nächste Weg darf.
    private func freezeIfStill(dx: CGFloat, dy: CGFloat, now: TimeInterval) -> Bool {
        palmFrozen = false
        palmStillSince = nil
        return false
    }

    /// Warp-Hold freeze: Fill und lastMapped sonst schießen nach Release.
    private func applyWarpHold(_ held: CGPoint) -> CGPoint {
        cursorDidMove = false
        cursorSmooth = held
        lastMapped = held
        lastMapped2 = held
        if GestureMath.palmWarpHoldJumps(true) {
            warpHeldJump = true
            jumpMuteFill = true
            lastVelJump = true
            lastVelZeroed = true
            palmVelScreen = .zero
            palmVelAt = nil
        }
        return held
    }

    private func placeCursor(_ hand: TrackedHand, now: TimeInterval) {
        cursor = actorMapped(hand, now: now)
        cursorHand = hand.sideDE
    }

    /// destEdgeCross + Hold ≥ 1,25 Continuity-Ticks. 80 ms stirbt vor dem 8-fps-Frame.
    private func destEdgeSkips(_ crosses: Bool, now: TimeInterval) -> Bool {
        let next = GestureMath.destEdgeSkipNow(
            crosses: crosses,
            now: now,
            lastAt: lastDestCrossAt,
            hold: GestureMath.destEdgeSkipHold(pref: destEdgeSkipPref, frameDt: rawFrameDt)
        )
        lastDestCrossAt = next.lastAt
        return next.skip
    }

    /// 8 fps HUD: WARP 1 Frame halten.
    private func rememberWarpChip(_ live: String?) -> String? {
        let next = GestureMath.hudChipPeakHold(
            current: live,
            held: lastWarpChip,
            remaining: warpChipHold,
            need: 1
        )
        warpChipHold = next.remaining
        return next.chip
    }

    /// Reduce Motion: Predict aus. Nach destEdgeCross tot — sonst Overshoot über die Seam.
    private func predictPointer(from edged: CGPoint, vel: CGPoint, mute: Bool = false) -> CGPoint {
        if GestureMath.pointerPredictSkipsCross(mute) {
            lastPredictChip = nil
            return edged
        }
        guard GestureMath.pointerPredictApplies(
            reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        ) else {
            lastPredictChip = nil
            return edged
        }
        let pred = GestureMath.pointerPredict(from: edged, vel: vel, dt: min(rawFrameDt, 0.04))
        lastPredictChip = GestureMath.pointerPredictChip(dx: pred.x - edged.x, dy: pred.y - edged.y)
        return pred
    }

    func displayTick(now: TimeInterval) {
        lastDisplayTick = now
    }

    /// Jeder Vision-Tick warpt. displayTick coastet nicht. Idle folgt trotzdem.
    private func injectCursor(_ hand: TrackedHand, now: TimeInterval) {
        placeCursor(hand, now: now)
        if !testMode, let p = cursor {
            system.moveCursor(to: p)
            lastCursorMoveAt = now
        }
    }

    @discardableResult
    private func handleTwoPinchScale(hands: [TrackedHand], now: TimeInterval, gated: Bool) -> Bool {
        let pinches = hands.filter(\.pinchClosed).sorted { $0.id < $1.id }
        let closedCount = GestureMath.scaleHandCount(closed: hands.map(\.pinchClosed))
        guard GestureMath.scaleBlocksGrab(pinchHeld: pinchHeld, closedCount: closedCount), pinches.count >= 2 else {
            if GestureMath.scaleAbortClick(hadSpan: twoHandSpan != nil, closedCount: closedCount) {
                lastScrollAt = now
            }
            twoHandSpan = nil
            twoPinchSince = nil
            return false
        }
        if pinchHeld || system.isDragging || system.isMousePressed {
            pinchHeld = false
            pinchBecameDrag = false
            pressLocksClick = false
            system.endWindowDrag()
            system.cancelPress()
        }
        if twoPinchSince == nil { twoPinchSince = now }
        let span = hypot(pinches[0].palm.x - pinches[1].palm.x, pinches[0].palm.y - pinches[1].palm.y)
        guard now - (twoPinchSince ?? now) >= GestureMath.scaleSettleNeed(dt: clickNeedDt) else {
            twoHandSpan = span
            lastAction = testMode ? "Test: Skalieren" : "Skalieren …"
            return true
        }
        if let old = twoHandSpan, GestureMath.scaleMoved(old: old, span: span, dt: rawFrameDt) {
            if !gated {
                let conf = pinches.map(\.meanConfidence).min() ?? 0
                perform("Skalieren", confidence: conf) {
                    system.resizeFocused(scale: span > old ? 1.08 : 0.93, anchor: cursor)
                }
                twoHandSpan = GestureMath.scaleKeepsSpan(old: old, span: span, gated: false)
                cooldownUntil = now + GestureMath.scaleCooldown
                lastScrollAt = now
            }
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

    private func driveGrab(_ hand: TrackedHand, hands: [TrackedHand], now: TimeInterval, blockPress: Bool = false) {
        travelProgress = nil
        let overlapMute = GestureMath.palmPinchMuteOverlap(
            palm: hand.palm,
            others: hands.filter { $0.id != hand.id && !$0.isGhost }.map(\.palm)
        )
        let preArm = GestureMath.fistFormingPreArmAny(
            prevOpen: lastActorOpenScore,
            liveOpen: hand.openScore,
            prevCurl: lastActorCurl,
            liveCurl: hand.fingerCurl
        )
        lastActorOpenScore = hand.openScore
        lastActorCurl = hand.fingerCurl
        if GestureMath.focusStealLatches(
            prevPID: lastPinchPID.map { Int32($0) },
            nextPID: focused.map { Int32($0.pid) },
            pinchHeld: pinchHeld
        ) {
            lastPinchPID = focused?.pid
            escapeLatchUntil = now + GestureMath.escapeLatchHold
            system.cancelPress()
            pressLocksClick = false
            lastAction = GestureMath.escapeLatchHUD(now: now, until: escapeLatchUntil) ?? "LATCH"
        } else if pinchHeld {
            lastPinchPID = focused?.pid
        } else {
            lastPinchPID = nil
        }
        if ignoreGrabUntilOpen {
            if hand.pose == .openPalm || hand.pose == .point || hand.openScore >= 2 {
                ignoreGrabUntilOpen = false
            } else {
                return
            }
        }
        let ratio = hand.pinchRatio
        let closed = hand.pinchClosed || hand.pose == .pinch
        let fisting = (hand.pose == .fist || preArm) && mode == .armed
        if fisting { fistClickFrames += 1 } else { fistClickFrames = 0 }
        let fistOk = !fisting || GestureMath.fistClickDebounce(frames: fistClickFrames)
        let rebind = now < actorRebindUntil
        let isGrab = GestureMath.pinchKeepsGrabTipZ(
            held: pinchHeld,
            closed: closed,
            ratio: ratio,
            fisting: fisting && fistOk,
            rebind: rebind,
            palmScale: hand.palmScale,
            tipZ: hand.tipZ,
            revision2: true
        )
        let wristAbort = GestureMath.pinchHoldAborts(mad: max(madNowX(), madNowY()), rest: GestureMath.palmStill)
        let keepGrab = isGrab && !wristAbort
        if keepGrab && !pinchHeld {
            pinchHeld = true
            pinchBecameDrag = false
            pinchBeganAt = now
            pinchActorID = hand.id
            pinchCursor0 = cursor
            pinchTrail = [(now, hand.palm.x, hand.palm.y)]
            pinchPalmY0 = hand.palm.y
            pinchSettlePalm = nil
            grabLogged = false
            palmFrozen = false
            palmStillSince = nil
            let latchPress = blockPress || GestureMath.escapeLatches(now: now, until: escapeLatchUntil)
            if !latchPress {
                let hoverOk = GestureMath.clickLockNeedsHover(hoverProgress, closed: closed)
                let always = GestureMath.clickLockAlways(bundle: focused?.bundleId, extra: clickLockExtra)
                pressLocksClick = always || (hoverOk && system.hitLocksClick(
                    at: system.aimPoint(from: cursor, palmScale: hand.palmScale),
                    palmScale: hand.palmScale
                ))
                clickLockMisses = 0
            }
            lastAction = testMode
                ? GestureMath.testGrabHUD(becameDrag: false)
                : (latchPress
                    ? (GestureMath.escapeLatchHUD(now: now, until: escapeLatchUntil) ?? "LATCH")
                    : GestureMath.clickLockLabel(locks: pressLocksClick, magnet: system.trafficMagnet(at: cursor, palmScale: hand.palmScale)))
        } else if keepGrab && pinchHeld {
            pinchTrail.append((now, hand.palm.x, hand.palm.y))
            pinchTrail.removeAll { now - $0.t > 0.5 }
            let held = now - pinchBeganAt
            let clickNeed = GestureMath.pinchClickNeed(dt: clickNeedDt, speed: trailSpeed())
            if !blockPress, GestureMath.pinchSettled(held: held, need: clickNeed) {
                let nowLocked = system.hitLocksClick(
                    at: system.aimPoint(from: cursor, palmScale: hand.palmScale),
                    palmScale: hand.palmScale
                )
                let refreshed = GestureMath.clickLockRefresh(
                    settled: true,
                    wasLocked: pressLocksClick,
                    nowLocked: nowLocked
                )
                let heldLock = GestureMath.clickLockMissHold(
                    wasLocked: pressLocksClick,
                    nowLocked: refreshed,
                    misses: clickLockMisses
                )
                pressLocksClick = heldLock.locked
                clickLockMisses = heldLock.misses
                if pinchSettlePalm == nil {
                    pinchSettlePalm = hand.palm
                    pinchCursor0 = GestureMath.cursorTravelOrigin(
                        start: pinchCursor0,
                        gate: cursor,
                        settled: true
                    )
                }
                if let origin = pinchSettlePalm {
                    let palmMoved = hypot(hand.palm.x - origin.x, hand.palm.y - origin.y)
                    let span = (NSScreen.main?.frame.width ?? 1440)
                    let movedPx = palmMoved * span
                    if let kind = GestureMath.pinchClickVsDrag(moved: movedPx, clickMax: 22, dragMin: 48) {
                        if kind == "drag" {
                            if pressLocksClick {
                                lastAction = testMode ? "Test: BUTTON" : "BUTTON"
                            } else {
                                pinchBecameDrag = true
                            }
                        }
                    }
                }
            }
            if pinchBecameDrag, !system.isDragging, !testMode, !blockPress, now - lastGrabTry > 0.35 {
                lastGrabTry = now
                system.cancelPress()
                let at = cursor ?? SpaceMap.linear(hand.palm)
                let r = system.beginWindowDrag(at: at)
                if r.ok {
                    lastAction = r.detail
                    onLog?("Greifen · \(r.detail)", .executed, Int(hand.meanConfidence * 100))
                    grabLogged = true
                } else if !grabLogged {
                    grabLogged = true
                    lastAction = "Greifen fehlgeschlagen"
                    onLog?("Greifen — NICHT AUSGEFÜHRT: \(r.detail)", .failed, Int(hand.meanConfidence * 100))
                    if r.detail.contains("Bedienung") || !AXIsProcessTrusted() {
                        Permissions.demand(.accessibility)
                    }
                }
            } else if !pinchBecameDrag, !testMode, !system.isDragging, !blockPress {
                let cursorTravel: CGFloat = {
                    guard let a = pinchCursor0, let b = cursor else { return 0 }
                    return hypot(a.x - b.x, a.y - b.y)
                }()
                let travelPx = GestureMath.pinchClickTravelPx(
                    dt: clickNeedDt,
                    mapped: spaceMap?.isUsable == true,
                    palmScale: hand.palmScale
                )
                if let weg = GestureMath.travelHUDLabel(GestureMath.travelHUD(travel: cursorTravel, limit: travelPx)),
                   !pressLocksClick
                {
                    travelProgress = GestureMath.travelHUD(travel: cursorTravel, limit: travelPx)
                    lastAction = weg
                }
                if GestureMath.rightClickHold(held: now - pinchBeganAt, need: clickNeed), !pressLocksClick {
                    lastAction = GestureMath.rightClickChipLabel(right: true) ?? "RECHTS"
                }
                if now - pinchBeganAt >= clickNeed,
                   cursorTravel < travelPx,
                   !system.isMousePressed,
                   !GestureMath.escapeLatches(now: now, until: escapeLatchUntil),
                   GestureMath.pressDuringHold(locksClick: pressLocksClick)
                {
                    let speedNow = trailSpeed()
                    if GestureMath.pinchDownBlocked(speed: speedNow) {
                        if testMode { lastAction = "kein Klick — Hand zu schnell" }
                    } else if !GestureMath.pinchClickNeedsStill(speed: speedNow, frozen: palmFrozen) {
                        if testMode { lastAction = "kein Klick — Hand zittert" }
                    } else if GestureMath.phaseBlocksClick(livePhase()) {
                        if testMode { lastAction = "kein Klick — Phase" }
                    } else {
                        let aim = system.aimPoint(from: cursor, palmScale: hand.palmScale)
                        pressLocksClick = system.hitLocksClick(at: aim, palmScale: hand.palmScale)
                        if GestureMath.pressDuringHold(locksClick: pressLocksClick) {
                            let flags = CGEventFlags(rawValue: GestureMath.modifierFlagBits(modKind))
                            let r = system.pressMouse(at: aim, flags: flags)
                            if r.ok {
                                lastAction = testMode
                                    ? "Test: Klick bereit"
                                    : GestureMath.clickLockLabel(
                                        locks: pressLocksClick,
                                        magnet: system.trafficMagnet(at: aim, palmScale: hand.palmScale)
                                    )
                                pointerNeedsRebase = true
                                rememberPalm(hand.palm)
                                lastPointerT = now
                            }
                        }
                    }
                }
            }
            if !testMode, system.isDragging {
                let at = cursor ?? SpaceMap.linear(hand.palm)
                system.updateWindowDrag(to: at)
                let motion = GestureMath.trailMotion(pinchTrail)
                let kind = flingOf(motion)
                flingGhostKind = GestureMath.flingGhost(kind: kind, dragging: true) ? kind : .none
                if trashHot {
                    lastAction = "Papierkorb"
                } else if let ghost = GestureMath.flingGhostLabel(flingGhostKind) {
                    lastAction = ghost
                } else {
                    lastAction = "Ziehen"
                }
            } else if testMode, pinchBecameDrag {
                let motion = GestureMath.trailMotion(pinchTrail)
                let kind = flingOf(motion)
                flingGhostKind = GestureMath.flingGhost(kind: kind, dragging: true) ? kind : .none
                if trashHot {
                    lastAction = "Test: Papierkorb"
                } else if let ghost = GestureMath.flingGhostLabel(flingGhostKind) {
                    lastAction = "Test: \(ghost)"
                } else {
                    lastAction = GestureMath.testGrabHUD(becameDrag: true)
                }
            }
            // Pinzette + zu sich: Vision-Y fällt (Hand zur Brust / Kamera).
            // Nur nach Drag-Intent und außerhalb des Klick-Fensters — sonst füllt
            // ein leichtes Öffnen / Atmen das Fenster.
            if pinchBecameDrag,
               !system.isDragging,
               !blockPress,
               now - pinchBeganAt > GestureMath.pinchClickMax,
               let y0 = pinchPalmY0,
               (y0 - hand.palm.y) > GestureMath.pullToward
            {
                perform("Heranziehen", confidence: hand.meanConfidence) { system.snapFocused(.fill) }
                pinchPalmY0 = hand.palm.y
                cooldownUntil = now + 0.5
            }
        } else if pinchHeld {
            if wristAbort || GestureMath.releaseBlockedBySkipAX(blockPress: blockPress) {
                pinchHeld = false
                pinchBecameDrag = false
                pinchTrail.removeAll()
                pinchPalmY0 = nil
                pinchSettlePalm = nil
                pinchActorID = nil
                pinchCursor0 = nil
                grabLogged = false
                trashHot = false
                pressLocksClick = false
                clickLockMisses = 0
                flingGhostKind = .none
                clutchGraceUntil = now + GestureMath.clutchGraceHold
                if !testMode { system.endWindowDrag() }
                system.cancelPress()
                lastAction = wristAbort ? "kein Klick — Wrist" : "kein Klick — Skip-AX"
                cooldownUntil = now + GestureMath.clickCooldown
                return
            }
            let flung = resolveFling(now: now, confidence: hand.meanConfidence)
            let wasDrag = pinchBecameDrag
            let held = now - pinchBeganAt
            let cursorTravel: CGFloat = {
                guard let a = pinchCursor0, let b = cursor else { return 0 }
                return hypot(a.x - b.x, a.y - b.y)
            }()
            let travelPx = GestureMath.pinchClickTravelPx(
                dt: clickNeedDt,
                mapped: spaceMap?.isUsable == true,
                palmScale: hand.palmScale
            )
            let releaseSpeed = trailSpeed()
            let wasPressed = system.isMousePressed
            let clickNeed = GestureMath.pinchClickNeed(dt: clickNeedDt, speed: trailSpeed())
            let blockByPhase = GestureMath.phaseBlocksClick(livePhase())
            pinchHeld = false
            pinchBecameDrag = false
            pinchTrail.removeAll()
            pinchPalmY0 = nil
            pinchSettlePalm = nil
            pinchActorID = nil
            pinchCursor0 = nil
            grabLogged = false
            trashHot = false
            pressLocksClick = false
            clickLockMisses = 0
            flingGhostKind = .none
            clutchGraceUntil = now + GestureMath.clutchGraceHold
            if !testMode { system.endWindowDrag() }
            if flung {
                lastFlingAt = now
                system.cancelPress()
                cooldownUntil = now + 0.4
                return
            }
            if wasDrag {
                system.cancelPress()
                lastAction = testMode ? "Test: Loslassen" : "Loslassen"
                onLog?("Loslassen", testMode ? .blocked : .executed, Int(hand.meanConfidence * 100))
            } else if cursorTravel >= travelPx {
                system.cancelPress()
                lastAction = "kein Klick — Cursor wanderte"
            } else if GestureMath.nearFlingClick(speed: releaseSpeed) {
                system.cancelPress()
                lastAction = "kein Klick — fast Wurf"
            } else if blockByPhase {
                system.cancelPress()
                lastAction = "kein Klick — Phase"
            } else if wasPressed {
                perform("Klick", need: .input, confidence: hand.meanConfidence) { system.releaseMouse() }
                lastClickAt = now
                lastClickTravelled = GestureMath.doublePinchBlocksTravel(travel: cursorTravel, limit: travelPx)
            } else if GestureMath.rightClickHold(held: held, need: clickNeed) {
                perform("Rechtsklick", need: .input, confidence: hand.meanConfidence) {
                    system.rightClick(at: system.aimPoint(from: cursor, palmScale: hand.palmScale))
                }
                lastClickAt = 0
                lastClickTravelled = false
            } else if GestureMath.pinchClickAbortsOcc(hand.tipHeld) {
                system.cancelPress()
                lastAction = "kein Klick — OCC"
            } else if overlapMute {
                system.cancelPress()
                lastAction = "kein Klick — S1∩S2"
            } else if held >= clickNeed, held < GestureMath.pinchClickMax {
                if GestureMath.pinchDownBlocked(speed: releaseSpeed) {
                    system.cancelPress()
                    lastAction = "kein Klick — Hand zu schnell"
                } else if GestureMath.pinchClickBlocksAfterScroll(lastScroll: lastScrollAt, now: now) {
                    system.cancelPress()
                    lastAction = "kein Klick — nach Scroll"
                } else if GestureMath.pinchClickBlocksAfterCoast(lastCoastEnd: lastCoastEnd, now: now) {
                    system.cancelPress()
                    lastAction = "kein Klick — nach Coast"
                } else if GestureMath.doublePinch(now: now, lastClick: lastClickAt),
                          !lastClickTravelled,
                          !GestureMath.doublePinchBlocksTravel(travel: cursorTravel, limit: travelPx)
                {
                    perform("Doppelklick", need: .input, confidence: hand.meanConfidence) {
                        system.doubleClick(at: system.aimPoint(from: cursor, palmScale: hand.palmScale))
                    }
                    lastClickAt = now
                    lastClickTravelled = false
                } else {
                    perform("Klick", need: .input, confidence: hand.meanConfidence) {
                        let flags = CGEventFlags(rawValue: GestureMath.modifierFlagBits(modKind))
                        return system.click(at: system.aimPoint(from: cursor, palmScale: hand.palmScale), flags: flags)
                    }
                    lastClickAt = now
                    lastClickTravelled = GestureMath.doublePinchBlocksTravel(travel: cursorTravel, limit: travelPx)
                }
            } else if held < clickNeed {
                system.cancelPress()
                lastAction = "zu kurz"
            } else {
                system.cancelPress()
            }
            cooldownUntil = now + GestureMath.clickCooldown
        }
    }

    private func livePhase() -> GestureMath.EnginePhase {
        GestureMath.enginePhase(
            modeArmed: mode == .armed && !gamePaused && !GestureMath.lidBlocksArm(
                lidClosed: lidClosed,
                cameraFallback: cameraFallback,
                extraScreens: NSScreen.screens.count > 1
            ),
            pinchHeld: pinchHeld,
            dragging: system.isDragging || dragging,
            scaleActive: twoHandSpan != nil,
            kill: killLatched
        )
    }

    private func trailSpeed() -> CGFloat {
        GestureMath.trailMotion(pinchTrail).speed
    }

    private func flingOf(_ motion: (dx: CGFloat, dy: CGFloat, speed: CGFloat, dist: CGFloat)) -> FlingKind {
        let h = spaceMap?.destBounds?.height ?? NSScreen.main?.frame.height ?? 900
        return GestureMath.fling(
            dx: motion.dx,
            dy: motion.dy,
            speed: motion.speed,
            dist: motion.dist,
            speedPx: motion.speed * h,
            minPx: GestureMath.flingMinSpeedPx(screenHeight: h)
        )
    }

    private func resolveFling(now _: TimeInterval, confidence: Float) -> Bool {
        if trashHot {
            perform("Wegwerfen", confidence: confidence) { system.throwAway(finder: focused?.isFinder == true) }
            return true
        }
        let h = spaceMap?.destBounds?.height ?? NSScreen.main?.frame.height ?? 900
        let kind = GestureMath.flingFromTrail(pinchTrail, screenHeight: h, window: flingWindowPref)
        guard kind != .none else { return false }
        onLog?("Werfen erkannt", .recognized, Int(confidence * 100))
        switch kind {
        case .throwUp:
            perform("Wegwerfen", confidence: confidence) { system.throwAway(finder: focused?.isFinder == true) }
        case .minimize:
            perform("Minimieren", confidence: confidence) { system.minimizeFocused() }
        case .dockLeft:
            perform("Links andocken", confidence: confidence) { system.snapFocused(.left) }
        case .dockRight:
            perform("Rechts andocken", confidence: confidence) { system.snapFocused(.right) }
        case .none:
            return false
        }
        return true
    }

    private func driveSwipe(hands: [TrackedHand], actor: TrackedHand, now: TimeInterval) {
        guard !pinchHeld else {
            swipeTrail.removeAll()
            swipeHandID = nil
            return
        }
        let open = hands.filter {
            GestureMath.swipeEligible(
                isOpenPalm: $0.pose == .openPalm,
                isPeace: $0.pose == .peace,
                openScore: $0.openScore,
                openOnly: swipeOpenOnly
            )
        }
        let openBest = open.max { a, b in a.openScore < b.openScore }
        let graceID = GestureMath.swipeGraceID(
            openID: openBest?.id,
            lastID: swipeHandID,
            lastStillPresent: swipeHandID.map { id in hands.contains { $0.id == id } } ?? false
        )
        let hand: TrackedHand? = {
            if let h = openBest { return h }
            if now < swipeGraceUntil, let id = graceID {
                return hands.first { $0.id == id }
            }
            return nil
        }()
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
        let trailWin = GestureMath.adaptiveSwipeTrail(swipeTrail)
        swipeTrail.removeAll { now - $0.t > trailWin }
        guard let first = swipeTrail.first, swipeTrail.count >= 2 else { return }
        let dx = hand.palm.x - first.x
        let dy = hand.palm.y - first.y
        let dt = now - first.t
        let medianDt = GestureMath.medianDt(swipeTrail)
        guard GestureMath.isHorizontalSwipe(dx: dx, dy: dy, dt: dt, medianDt: medianDt) else { return }
        if hand.id == actor.id, GestureMath.swipeBlockedByPointer(dx: dx, pointerMoving: cursorDidMove && !palmFrozen) {
            return
        }
        onLog?("Wischen erkannt", .recognized, Int(hand.meanConfidence * 100))
        let forward = dx < 0
        let name = forward ? "Nächste App" : "Vorherige App"
        perform(name, need: .none, confidence: hand.meanConfidence) { system.switchApp(forward: forward) }
        swipeTrail.removeAll()
        swipeHandID = nil
        cooldownUntil = now + GestureMath.swipeCooldown
        lastScrollAt = now
    }

    private func otherHandPinching(_ hand: TrackedHand, hands: [TrackedHand]) -> Bool {
        hands.contains { $0.id != hand.id && ($0.pinchClosed || $0.pose == .pinch) }
    }

    private func drivePeace(_ hand: TrackedHand, hands: [TrackedHand], now: TimeInterval) {
        if otherHandPinching(hand, hands: hands) {
            peaceSince = nil
            return
        }
        let edge = GestureMath.peaceEdge
        if hand.palm.x < edge || hand.palm.x > 1 - edge || hand.palm.y < edge || hand.palm.y > 1 - edge {
            peaceSince = nil
            return
        }
        if hand.pose == .peace {
            if peaceSince == nil { peaceSince = now }
            if now - (peaceSince ?? now) > GestureMath.peaceHold {
                let target = focused
                perform("Aufnahme", need: .capture, confidence: hand.meanConfidence) {
                    if let t = target, t.quartzBounds.width > 8 {
                        return system.screenshotFocused(windowID: t.windowID, bounds: t.quartzBounds)
                    }
                    let b = NSScreen.main.map { ScreenGeometry.quartzBounds(of: $0) } ?? .zero
                    return system.screenshotFocused(windowID: 0, bounds: b)
                }
                peaceSince = nil
                cooldownUntil = now + 4
            }
        } else {
            peaceSince = nil
        }
    }

    private func driveThumbs(_ hand: TrackedHand, hands: [TrackedHand], now: TimeInterval) {
        if otherHandPinching(hand, hands: hands) {
            thumbsSince = nil
            return
        }
        if hand.pose == .thumbsUp {
            if thumbsSince == nil { thumbsSince = now }
            if now - (thumbsSince ?? now) > GestureMath.thumbsHold {
                perform("Hervorholen", need: .none, confidence: hand.meanConfidence) { system.unhideFront() }
                thumbsSince = nil
                cooldownUntil = now + 3
            }
        } else {
            thumbsSince = nil
        }
    }

    /// Vision-Dropout: Grab/Cursor halten, keine One-Shots.
    /// Rebase bleibt stehen — placeCursor darf ihn nicht verbrauchen, sonst
    /// ist der erste Live-Frame ein Teleport um den Dropout-Delta.
    private func holdGhost(_ hands: [TrackedHand], now: TimeInterval) {
        peaceSince = nil
        thumbsSince = nil
        if GestureMath.pocketIdle(
            cameraFallback: cameraFallback,
            lastInterior: lastInteriorSeen,
            now: now
        ), mode == .armed, !GestureMath.stealHoldsPocket(steal: pointerStealLatched) {
            abortGrab(reason: "Tasche", now: now)
            mode = .idle
            mustRearm = false
            pointerSideLock = .any
            lastAction = "Tasche"
            onLog?("Continuity Ghost ohne Innenraum → Idle", .info, nil)
            return
        }
        let g = hands.max { $0.ghostRemaining < $1.ghostRemaining } ?? hands[0]
        lastAction = GestureMath.ghostHUD(id: actorHandID ?? g.id, remaining: g.ghostRemaining)
        if pinchHeld || system.isDragging {
            if system.isDragging, let p = cursor {
                system.updateWindowDrag(to: p)
                grabPhase = .grab
            } else {
                grabPhase = .hold
            }
            dragging = pinchHeld
            grabTargetName = focused?.appName ?? grabTargetName
            pointerNeedsRebase = true
            return
        }
        if GestureMath.pointerStealBlocksCursor(steal: pointerStealLatched) {
            pointerNeedsRebase = GestureMath.ghostLeavesRebase()
            grabPhase = .follow
            dragging = false
            grabTargetName = focused?.appName ?? ""
            return
        }
        placeCursor(preferred(hands), now: now)
        pointerNeedsRebase = GestureMath.ghostLeavesRebase()
        grabPhase = .follow
        dragging = false
        grabTargetName = focused?.appName ?? ""
    }

    private func stealGoIdle(now: TimeInterval) {
        abortGrab(reason: "LOCK tot", now: now)
        mode = .idle
        mustRearm = false
        pointerSideLock = .any
        pointerStealLatched = false
        pointerStealCursor = false
        stealSince = nil
        stealRelockSince = nil
        stealScreen = nil
        warpCapHeld = nil
        warpCapHoldFrames = 0
        lastPoolIDs = []
        pointerHandID = nil
        lastAction = "LOCK tot → Idle"
        onLog?("Steal-Timeout 1,2 s → Idle. Faust zum Scharf.", .info, nil)
    }
}

import AppKit
import Combine
import CoreMedia
import CoreVideo
import Foundation
import QuartzCore
import SwiftUI
import ImageIO
import Vision

/// vsync Fill. Timer.common coalesced gegen ProMotion — Cursor stottert an der Seam.
private final class DisplayPulse: NSObject {
    var link: CADisplayLink?
    var onTick: () -> Void = {}

    func arm(preferred: Float = 120) {
        stop()
        let l = CADisplayLink(target: self, selector: #selector(step))
        l.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: preferred, preferred: preferred)
        l.add(to: .main, forMode: .common)
        link = l
    }

    func stop() {
        link?.invalidate()
        link = nil
    }

    @objc func step() { onTick() }
}

@MainActor
final class AppState: ObservableObject {
    let camera = CameraSession()
    let engine = GestureEngine()
    let log = AuditLog()
    let recorder = SessionRecorder()
    private let overlay = OverlayController()
    private var permTimer: Timer?
    private var displayTimer: Timer?
    private var displayPulse: DisplayPulse?
    private var displayTimerPeriod: TimeInterval = GestureMath.displayLinkTimerPeriod()
    private var frames: Int = 0
    private var fpsStamp: TimeInterval = CACurrentMediaTime()
    private var fpsSamples: [Double] = []
    private let tracker = HandTracker()

    @Published var hands: [TrackedHand] = []
    @Published var mode: EngineMode = .idle
    @Published var lastAction = "—"
    @Published var fps: Double = 0
    @Published var fpsSpark = ""
    @Published var latencyMs: Double = 0
    @Published var cameraOK = false
    @Published var accessOK = false
    @Published var cameraRunning = false
    @Published var cameraError: String?
    @Published var preview: NSImage?
    @Published var deviceName = "—"
    @Published var engineCursor: CGPoint?
    @Published var hudVisible = true
    @Published var showReticle = true
    @Published var showPreviewChip = true
    @Published var showCheats = true
    @Published var testMode = false
    @Published var protocolMode = true
    @Published var leftHanded = false
    @Published var showJointLabels = true
    @Published var showOutline = true
    @Published var showTrashZone = true
    @Published var luma: CGFloat = 1
    @Published var focused: FocusedTarget?
    @Published var trashHot = false
    @Published var killFlash = false
    @Published var screenCount = 1
    @Published var inputOK = false
    @Published var fromDiskImage = false
    @Published var installPath = "—"
    @Published var cursorHand = "—"
    @Published var pointerGain: Double = 1.6
    @Published var calibActive = false
    @Published var calibCorner = ""
    @Published var calibHold: CGFloat = 0
    @Published var calibCursorGap: CGFloat = 0
    @Published var mapReady = false
    @Published var mousePaused = false
    @Published var awaitingRearm = false
    @Published var grabPhase: GrabPhase = .none
    @Published var grabTargetName = ""
    @Published var mapDrifted = false
    @Published var cameraFallback = false
    @Published var actorHandID: String?
    @Published var lumaLow = false
    @Published var cameraSlow = false
    @Published var dualCamAvailable = false
    @Published var cameraChoice: CameraChoice = .auto
    @Published var accessDropped = false
    @Published var hudDim = false
    @Published var visionMs: Double = 0
    @Published var holdRing = false
    @Published var formatChip = ""
    @Published var roiLatchChip = ""

    let calibSession = CalibrationSession()
    private var lastPanel: TimeInterval = 0
    private var didStart = false
    private let visionInbox = VisionInbox()
    private var lastScreenHash = ""
    private var overlayDarkSince: TimeInterval?
    private var slowSince: TimeInterval?
    private var sawAccessOK = false
    private var lastCameraID = ""
    private var formatStuckSince: TimeInterval?
    private var lastFormatReselect: TimeInterval = 0
    private var lumaDarkStreak = 0
    private var idleSince: TimeInterval?
    private var lastFrameAt: TimeInterval = 0
    private var lastLidClosed = false
    private var axSkipLatched = false
    private var axCheapStreak = 0
    private var lastOverlayCursor: CGPoint?
    private var overlayGhostHold = 0
    @Published var palmHighpass: Double = 0.15
    @Published var destEdgePad: Double = 40
    @Published var destEdgeSkip: Double = 0.16
    @Published var palmCoastNeed: Double = 2
    @Published var deadManFist: Double = 1.6
    @Published var flingWindow: Double = 0.12
    @Published var swipeOpenOnly = false
    @Published var fillCapLaptop: Double = 12
    @Published var fillCapStudio: Double = 28
    private var destEdgePadMap: [String: CGFloat] = [:]
    private var fillCapMap: [String: CGFloat] = [:]
    private var displayPulseHz: Float = 120
    private var screenObs: NSObjectProtocol?
    private var overlayHandsFrom: [TrackedHand] = []
    private var overlayHandsTo: [TrackedHand] = []
    private var overlayLerpAt: TimeInterval = 0
    private var overlayLerpDt: TimeInterval = 0.12

    private var cancellables: Set<AnyCancellable> = []
    private var focusTick = 0

    func start() {
        if didStart { return }
        didStart = true
        overlay.attach(state: self)
        engine.startInputClutch()
        engine.calibration = calibSession
        engine.spaceMap = SpaceMap.load(cameraID: camera.uniqueID, screenID: engine.lastScreenID)
        mapReady = engine.spaceMap?.isUsable == true
        engine.onLog = { [weak self] text, kind, conf in
            self?.log.record(text, kind: kind, confidence: conf)
            self?.objectWillChange.send()
        }
        loadPrefs()
        log.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
        $hudVisible.sink { Prefs.hudVisible = $0 }.store(in: &cancellables)
        $showReticle.sink { Prefs.showReticle = $0 }.store(in: &cancellables)
        $showJointLabels.sink { Prefs.showJointLabels = $0 }.store(in: &cancellables)
        $showCheats.sink { Prefs.showCheats = $0 }.store(in: &cancellables)
        $showOutline.sink { Prefs.showOutline = $0 }.store(in: &cancellables)
        $showTrashZone.sink { Prefs.showTrashZone = $0 }.store(in: &cancellables)
        $showPreviewChip.sink { Prefs.showPreviewChip = $0 }.store(in: &cancellables)
        camera.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.deviceName = self.camera.deviceName
                let running = self.camera.isRunning
                if self.cameraRunning, !running {
                    self.engine.muteDisplayFill()
                }
                self.cameraRunning = running
                self.cameraError = self.camera.errorMessage
                self.cameraFallback = self.camera.usingFallback
                self.dualCamAvailable = self.camera.dualCamAvailable
                self.formatChip = self.camera.formatChip
                let camID = self.camera.uniqueID
                if camID != self.lastCameraID {
                    self.lastCameraID = camID
                    self.calibSession.cameraID = camID
                    self.engine.spaceMap = SpaceMap.load(cameraID: camID, screenID: self.engine.lastScreenID)
                    self.mapReady = self.engine.spaceMap?.isUsable == true
                    self.engine.recenterPointer()
                }
            }
            .store(in: &cancellables)

        $hudVisible
            .sink { [weak self] v in self?.overlay.setVisible(v) }
            .store(in: &cancellables)

        refreshPermissions()
        pollFocus()
        permTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollFocus()
                self?.watchFrameSilence()
                self?.watchClamshellWake()
                self?.focusTick += 1
                if (self?.focusTick ?? 0) % 5 == 0 {
                    self?.refreshPermissions()
                }
            }
        }
        displayTimerPeriod = GestureMath.displayLinkTimerPeriod()
        armDisplayTimer(period: displayTimerPeriod)
        if screenObs == nil {
            screenObs = NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.pollFocus()
                }
            }
        }
        log.record(leftHanded ? "Helios bereit. Linkshänder." : "Helios bereit. Rechtshänder.")
        Task {
            await Permissions.bootstrap()
            refreshPermissions()
            await startCamera()
        }
    }

    private func armDisplayTimer(period: TimeInterval) {
        displayTimer?.invalidate()
        displayTimer = nil
        if GestureMath.displayLinkUsesCA() {
            let hz = GestureMath.displayLinkHzOf(fps: NSScreen.main?.maximumFramesPerSecond ?? 120)
            displayTimerPeriod = 1.0 / hz
            displayPulseHz = Float(hz)
            if displayPulse == nil {
                let pulse = DisplayPulse()
                pulse.onTick = { [weak self] in
                    MainActor.assumeIsolated {
                        self?.fireDisplayTick()
                    }
                }
                displayPulse = pulse
            }
            displayPulse?.arm(preferred: displayPulseHz)
            return
        }
        displayPulse?.stop()
        displayTimerPeriod = period
        let t = Timer(timeInterval: period, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.fireDisplayTick()
            }
        }
        t.tolerance = min(0.004, period * 0.15)
        RunLoop.main.add(t, forMode: GestureMath.displayLinkTimerCommonMode() ? .common : .default)
        displayTimer = t
    }

    private func fireDisplayTick() {
        let now = CACurrentMediaTime()
        let age = lastFrameAt > 0 ? now - lastFrameAt : 99
        guard GestureMath.displayTickNeedsCamera(cameraRunning, frameAge: age) else { return }
        engine.displayTick(now: now)
        lerpPublishedHands(now: now)
        if engine.rawFrameDt >= 0.08, let c = engine.cursor {
            engineCursor = c
            overlay.mark(
                cursor: GestureMath.overlayShowsCursor(mousePaused: engine.mousePaused) ? c : nil,
                phase: engine.grabPhase,
                hand: engine.cursorHand,
                target: engine.grabTargetName,
                window: engine.grabOutlineQuartz() ?? focused?.quartzBounds,
                ghost: false,
                settle: engine.clickSettle,
                hover: engine.hoverProgress,
                magnet: engine.trafficMagnet,
                lights: engine.trafficLights,
                fling: GestureMath.flingGhostLabel(engine.flingGhostKind),
                kind: engine.hoverKind
            )
        }
    }

    private func lerpPublishedHands(now: TimeInterval) {
        guard GestureMath.overlayLerpShould(dt: overlayLerpDt), !overlayHandsTo.isEmpty else { return }
        let t = GestureMath.overlayLerpT(elapsed: now - overlayLerpAt, frameDt: overlayLerpDt)
        self.hands = overlayLerpHands(from: overlayHandsFrom, to: overlayHandsTo, t: t)
    }

    private func overlayLerpHands(from: [TrackedHand], to: [TrackedHand], t: CGFloat) -> [TrackedHand] {
        to.map { next in
            guard let prev = from.first(where: { $0.id == next.id }) else { return next }
            return overlayLerpHand(from: prev, to: next, t: t)
        }
    }

    private func overlayLerpHand(from: TrackedHand, to: TrackedHand, t: CGFloat) -> TrackedHand {
        var h = to
        let palmVel = GestureMath.overlayVel(from: from.palm, to: to.palm)
        h.palm = GestureMath.overlayBezier(prev: from.palm, next: to.palm, t: t, vel: palmVel)
        h.joints = overlayLerpJoints(from.joints, to.joints, t: t)
        let fromDisp = from.displayJoints.isEmpty ? from.joints : from.displayJoints
        let toDisp = to.displayJoints.isEmpty ? to.joints : to.displayJoints
        h.displayJoints = overlayLerpJoints(fromDisp, toDisp, t: t)
        return h
    }

    private func overlayLerpJoints(
        _ a: [VNHumanHandPoseObservation.JointName: TrackedJoint],
        _ b: [VNHumanHandPoseObservation.JointName: TrackedJoint],
        t: CGFloat
    ) -> [VNHumanHandPoseObservation.JointName: TrackedJoint] {
        var out = b
        for (name, next) in b {
            guard let prev = a[name] else { continue }
            var j = next
            let vel = GestureMath.overlayVel(from: prev.point, to: next.point)
            j.point = GestureMath.overlayBezier(prev: prev.point, next: next.point, t: t, vel: vel)
            out[name] = j
        }
        return out
    }

    func refreshPermissions() {
        cameraOK = Permissions.cameraGranted()
        let ax = Permissions.accessibilityGranted()
        if sawAccessOK, !ax {
            if !accessDropped {
                accessDropped = true
                log.record("Bedienungshilfen aus — Schalter in Datenschutz neu setzen.", kind: .failed)
            }
        }
        if ax {
            accessDropped = false
            sawAccessOK = true
        }
        accessOK = ax
        inputOK = Permissions.inputMonitoringGranted()
        fromDiskImage = AppInstall.needsCopy
        installPath = AppInstall.locationHint
        screenCount = NSScreen.screens.count
    }

    func pollFocus() {
        trashHot = engine.trashHot
        killFlash = engine.killFlash
        let hash = GestureMath.screenArrangementHash(NSScreen.screens.map {
            (id: String(ScreenGeometry.displayID(of: $0)), bounds: ScreenGeometry.quartzBounds(of: $0))
        })
        if GestureMath.screenArrangementChanged(prev: lastScreenHash, next: hash) {
            engine.noteScreenChange()
            overlay.rebuild()
            applyDestEdgePadForScreen()
            applyFillCapForScreen()
            armDisplayTimer(period: displayTimerPeriod)
        }
        lastScreenHash = hash
        if !cameraRunning {
            focused = nil
            engine.focused = nil
            return
        }
        if let grab = engine.grabOutlineQuartz() {
            if var f = focused {
                f.quartzBounds = grab
                focused = f
                engine.focused = f
            }
            return
        }
        if GestureMath.pollFocusHolds(
            moved: engine.pointerMoved,
            dragging: false,
            hadFocus: focused != nil
        ) {
            return
        }
        focused = engine.cursor.flatMap { TargetProbe.windowAt(quartz: $0, skipSelf: false) }
        engine.focused = focused
    }

    private func watchFrameSilence() {
        guard cameraRunning, lastFrameAt > 0 else { return }
        let now = CACurrentMediaTime()
        let age = now - lastFrameAt
        guard GestureMath.frameSilenceRetry(age: age), now - lastFormatReselect >= 2.0 else { return }
        lastFormatReselect = now
        camera.reselectFormat()
        log.record("Kamera stumm \(Int(age)) s — Format neu", kind: .info)
    }

    /// Lid-Open: Continuity oft bei 8, Center Stage wieder an.
    private func watchClamshellWake() {
        let closed = Permissions.clamshellClosed()
        if GestureMath.clamshellWakeReselects(wasClosed: lastLidClosed, nowClosed: closed) {
            camera.reselectFormat()
            if GestureMath.axProbeWakeInvalidates(wasClosed: lastLidClosed, nowClosed: closed) {
                engine.invalidateAXProbe()
            }
            log.record("Klappe auf — Format neu", kind: .info)
        }
        lastLidClosed = closed
    }

    func startCamera() async {
        let ok = await Permissions.requestCamera()
        cameraOK = ok
        guard ok else {
            log.record("Kamera verweigert.")
            Permissions.openPrivacyPane(.camera)
            return
        }
        if !accessOK {
            Permissions.promptAccessibility()
        }
        if !Permissions.inputMonitoringGranted() {
            Permissions.requestInputMonitoring()
        }
        let tracker = self.tracker
        let cam = self.camera
        var lumaEnterStreak = 0
        camera.onFrame = { [weak self] vision, _, luma, arrived in
            let t0 = CACurrentMediaTime()
            DispatchQueue.main.async { self?.lastFrameAt = t0 }
            let dark = luma < GestureMath.lumaSkip
            let enter = GestureMath.lumaSkipEnter(dark: dark, streak: lumaEnterStreak)
            lumaEnterStreak = enter.streak
            if enter.skip {
                // Dunkel: Vision aus, aber Hands/Grab/Dead-Man nicht als „keine Hand“ zählen.
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.visionInbox.reset()
                    self.luma = luma
                    let hold = GestureMath.lumaSkipHold(
                        dark: true,
                        skip: self.lumaLow,
                        brightStreak: self.lumaDarkStreak
                    )
                    self.lumaDarkStreak = hold.streak
                    self.lumaLow = hold.skip
                    let t = CACurrentMediaTime()
                    // Ring sofort weg — nicht 0,4 s am letzten Cursor kleben.
                    self.overlay.mark(
                        cursor: nil,
                        phase: .none,
                        hand: "—",
                        target: "",
                        window: nil
                    )
                    if self.overlayDarkSince == nil { self.overlayDarkSince = t }
                    if t - (self.overlayDarkSince ?? t) >= GestureMath.overlayDarkHold {
                        self.hands = []
                        self.overlayHandsFrom = []
                        self.overlayHandsTo = []
                        self.overlayLerpAt = 0
                    }
                    self.engine.cameraFallback = self.cameraFallback
                    self.engine.noteDarkFrame(now: t)
                    self.mode = self.engine.mode
                    self.lastAction = self.engine.lastAction
                    self.grabPhase = self.engine.grabPhase
                }
                return
            }
            let fallback = cam.usingFallback
            tracker.minObservationConfidence = fallback ? GestureMath.continuityConfidence : 0.22
            let hands = tracker.analyze(
                pixelBuffer: vision,
                now: t0,
                mirrored: cam.isMirrored,
                orientation: cam.visionOrientation
            )
            let visMs = (CACurrentMediaTime() - t0) * 1000
            let endToEnd = (CACurrentMediaTime() - arrived) * 1000
            let latency = max(visMs, endToEnd)
            self?.visionInbox.push(hands: hands, latency: latency, luma: luma, visMs: visMs) {
                self?.drainVision()
            }
        }
        camera.setPreviewSink { [weak self] img in
            self?.preview = img
        }
        camera.start()
        log.record("Kamera gestartet.")
    }

    func stopCamera() {
        camera.onFrame = nil
        camera.stop()
        tracker.reset()
        engine.reset()
        engine.muteDisplayFill()
        axSkipLatched = false
        axCheapStreak = 0
        cameraRunning = false
        hands = []
        focused = nil
        engine.focused = nil
        engineCursor = nil
        overlayHandsFrom = []
        overlayHandsTo = []
        overlayLerpAt = 0
        overlay.mark(
            cursor: nil,
            phase: .none,
            hand: "",
            target: "",
            window: nil
        )
        visionInbox.reset()
        log.record("Kamera gestoppt.")
    }

    func setTestMode(_ on: Bool) {
        testMode = on
        engine.testMode = on
        Prefs.testMode = on
        if on {
            engine.forceIdle()
            log.record("Testmodus an — nur Erkennung, keine Aktionen.", kind: .blocked)
        } else {
            log.record("Testmodus aus — Gesten steuern das System.", kind: .info)
        }
    }

    func setProtocolMode(_ on: Bool) {
        protocolMode = on
        engine.protocolMode = on
        Prefs.protocolMode = on
        log.record(on ? "Protokoll an" : "Protokoll aus", kind: .info)
    }

    func setLeftHanded(_ on: Bool) {
        leftHanded = on
        engine.leftHanded = on
        Prefs.leftHanded = on
        log.record(on ? "Linkshänder" : "Rechtshänder", kind: .info)
    }

    func setPointerGain(_ g: Double) {
        pointerGain = g
        engine.pointerGain = CGFloat(g)
        engine.recenterPointer()
        Prefs.pointerGain = g
    }

    func setPalmHighpass(_ a: Double) {
        palmHighpass = a
        engine.palmHighpassPref = GestureMath.palmHighpassAlpha(CGFloat(a))
        Prefs.palmHighpass = a
    }

    func setDestEdgePad(_ p: Double) {
        destEdgePad = Double(GestureMath.destEdgePadPref(CGFloat(p)))
        engine.destEdgePadPref = GestureMath.destEdgePadPref(CGFloat(destEdgePad))
        Prefs.destEdgePad = destEdgePad
        if let id = engine.lastScreenID, !id.isEmpty {
            destEdgePadMap = GestureMath.destEdgePadMapPut(id: id, pad: CGFloat(destEdgePad), onto: destEdgePadMap)
            Prefs.destEdgePadMap = destEdgePadMap
        }
    }

    private func applyDestEdgePadForScreen() {
        guard let id = engine.lastScreenID, !id.isEmpty else { return }
        let screens = ScreenGeometry.quartzScreens
        let pt = ScreenGeometry.quartz(fromCocoa: NSEvent.mouseLocation)
        let width = GestureMath.destEdgeNearest(pt, screens: screens)?.screen.width
            ?? NSScreen.main?.frame.width ?? 1440
        let pad = GestureMath.destEdgePadByUUID(
            id: id,
            width: width,
            stored: destEdgePadMap,
            floor: CGFloat(destEdgePad)
        )
        destEdgePad = Double(pad)
        engine.destEdgePadPref = pad
    }

    var destEdgePadScreenLabel: String {
        let names = NSScreen.screens.map {
            (id: "\(ScreenGeometry.displayID(of: $0))", name: $0.localizedName)
        }
        return GestureMath.destEdgePadScreenName(id: engine.lastScreenID ?? "", names: names)
    }

    func setDestEdgeSkip(_ s: Double) {
        destEdgeSkip = GestureMath.destEdgeSkipPref(s)
        engine.destEdgeSkipPref = GestureMath.destEdgeSkipPref(s)
        Prefs.destEdgeSkip = destEdgeSkip
    }

    func setPalmCoastNeed(_ n: Double) {
        palmCoastNeed = Double(GestureMath.palmCoastNeedPref(Int(n.rounded())))
        tracker.palmCoastNeed = GestureMath.palmCoastNeedPref(Int(palmCoastNeed))
        Prefs.palmCoastNeed = palmCoastNeed
    }

    func setFillCapLaptop(_ v: Double) {
        fillCapLaptop = Double(GestureMath.fillCapLaptopPref(CGFloat(v)))
        engine.fillCapLaptop = GestureMath.fillCapLaptopPref(CGFloat(fillCapLaptop))
        Prefs.fillCapLaptop = fillCapLaptop
        putFillCapForScreen(fillCapLaptop)
    }

    func setFillCapStudio(_ v: Double) {
        fillCapStudio = Double(GestureMath.fillCapStudioPref(CGFloat(v)))
        engine.fillCapStudio = GestureMath.fillCapStudioPref(CGFloat(fillCapStudio))
        Prefs.fillCapStudio = fillCapStudio
        putFillCapForScreen(fillCapStudio)
    }

    private func putFillCapForScreen(_ cap: Double) {
        guard let id = engine.lastScreenID, !id.isEmpty else { return }
        let screens = ScreenGeometry.quartzScreens
        let pt = ScreenGeometry.quartz(fromCocoa: NSEvent.mouseLocation)
        let width = GestureMath.destEdgeNearest(pt, screens: screens)?.screen.width
            ?? NSScreen.main?.frame.width ?? 1440
        fillCapMap = GestureMath.fillCapMapPut(id: id, cap: CGFloat(cap), width: width, onto: fillCapMap)
        engine.fillCapMap = fillCapMap
        Prefs.fillCapMap = fillCapMap
    }

    private func applyFillCapForScreen() {
        engine.fillCapMap = fillCapMap
        engine.fillCapLaptop = GestureMath.fillCapLaptopPref(CGFloat(fillCapLaptop))
        engine.fillCapStudio = GestureMath.fillCapStudioPref(CGFloat(fillCapStudio))
    }

    func setDeadManFist(_ s: Double) {
        deadManFist = GestureMath.deadManFistPref(s)
        engine.deadManFistPref = GestureMath.deadManFistPref(s)
        Prefs.deadManFist = deadManFist
    }

    func setFlingWindow(_ s: Double) {
        flingWindow = GestureMath.flingWindowPref(s)
        engine.flingWindowPref = GestureMath.flingWindowPref(s)
        Prefs.flingWindow = flingWindow
    }

    func setSwipeOpenOnly(_ v: Bool) {
        swipeOpenOnly = v
        engine.swipeOpenOnly = v
        Prefs.swipeOpenOnly = v
    }

    func setCameraChoice(_ choice: CameraChoice) {
        cameraChoice = choice
        camera.choice = choice
        Prefs.cameraChoice = choice
        tracker.reset()
        engine.recenterPointer()
        calibSession.cameraID = camera.uniqueID
        if cameraRunning {
            stopCamera()
            Task { await startCamera() }
        }
        log.record("Kamera: \(choice.titleDE)", kind: .info)
    }

    private func loadPrefs() {
        leftHanded = Prefs.leftHanded
        pointerGain = Prefs.pointerGain
        palmHighpass = Prefs.palmHighpass
        destEdgePad = Prefs.destEdgePad
        destEdgePadMap = Prefs.destEdgePadMap
        destEdgeSkip = Prefs.destEdgeSkip
        palmCoastNeed = Prefs.palmCoastNeed
        deadManFist = Prefs.deadManFist
        flingWindow = Prefs.flingWindow
        swipeOpenOnly = Prefs.swipeOpenOnly
        fillCapLaptop = Prefs.fillCapLaptop
        fillCapStudio = Prefs.fillCapStudio
        fillCapMap = Prefs.fillCapMap
        protocolMode = Prefs.protocolMode
        testMode = Prefs.testMode
        hudVisible = Prefs.hudVisible
        showReticle = Prefs.showReticle
        showJointLabels = Prefs.showJointLabels
        showCheats = Prefs.showCheats
        showOutline = Prefs.showOutline
        showTrashZone = Prefs.showTrashZone
        showPreviewChip = Prefs.showPreviewChip
        cameraChoice = Prefs.cameraChoice
        camera.choice = cameraChoice
        engine.leftHanded = leftHanded
        engine.pointerGain = CGFloat(pointerGain)
        engine.palmHighpassPref = GestureMath.palmHighpassAlpha(CGFloat(palmHighpass))
        engine.destEdgePadPref = GestureMath.destEdgePadPref(CGFloat(destEdgePad))
        engine.destEdgeSkipPref = GestureMath.destEdgeSkipPref(destEdgeSkip)
        tracker.palmCoastNeed = GestureMath.palmCoastNeedPref(Int(palmCoastNeed))
        engine.deadManFistPref = GestureMath.deadManFistPref(deadManFist)
        engine.flingWindowPref = GestureMath.flingWindowPref(flingWindow)
        engine.fillCapLaptop = GestureMath.fillCapLaptopPref(CGFloat(fillCapLaptop))
        engine.fillCapStudio = GestureMath.fillCapStudioPref(CGFloat(fillCapStudio))
        engine.fillCapMap = fillCapMap
        engine.swipeOpenOnly = swipeOpenOnly
        engine.protocolMode = protocolMode
        engine.testMode = testMode
        engine.clickLockExtra = Prefs.clickLockExtra
        engine.gameLockExtra = Prefs.gameLockExtra
    }

    func startCalibration() {
        hudVisible = true
        overlayVisible()
        calibSession.cameraID = camera.uniqueID
        calibSession.start()
        engine.calibration = calibSession
        log.record("Kalibrierung: Ecke oben links", kind: .info)
    }

    func cancelCalibration() {
        calibSession.cancel()
        log.record("Kalibrierung abgebrochen", kind: .info)
    }

    func clearCalibration() {
        SpaceMap.clear(cameraID: camera.uniqueID, screenID: engine.lastScreenID)
        SpaceMap.clear(cameraID: camera.uniqueID)
        engine.spaceMap = nil
        mapReady = false
        mapDrifted = false
        engine.recenterPointer()
        log.record("Kalibrierung gelöscht — Relativ-Zeiger", kind: .info)
    }

    private func overlayVisible() {
        hudVisible = true
    }

    func exportSession() {
        recorder.export(log: log)
        log.record("Sitzung exportiert", kind: .info)
    }

    func copyProtocol() {
        recorder.copyProtocol(log)
        log.record("Protokoll in die Zwischenablage", kind: .info)
    }

    func copyFilmstrip() {
        recorder.copyFilmstrip()
        log.record("Gesten-Filmstreifen in die Zwischenablage", kind: .info)
    }

    private func drainVision() {
        while let next = visionInbox.take() {
            apply(
                hands: next.hands,
                latency: next.latency,
                now: CACurrentMediaTime(),
                preview: self.preview,
                luma: next.luma,
                visMs: next.visMs
            )
        }
    }

    fileprivate func apply(
        hands: [TrackedHand],
        latency: Double,
        now: TimeInterval,
        preview: NSImage?,
        luma: CGFloat,
        visMs: Double = 0
    ) {
        engine.confidenceFloor = GestureMath.confidenceFloor(fallback: cameraFallback)
        engine.cameraFallback = cameraFallback
        engine.clickLockExtra = Prefs.clickLockExtra
        engine.gameLockExtra = Prefs.gameLockExtra
        engine.cameraSlow = cameraSlow
        if luma >= GestureMath.lumaSkip {
            overlayDarkSince = nil
            let hold = GestureMath.lumaSkipHold(
                dark: false,
                skip: lumaLow,
                brightStreak: lumaDarkStreak
            )
            lumaDarkStreak = hold.streak
            lumaLow = hold.skip
        } else {
            let hold = GestureMath.lumaSkipHold(
                dark: true,
                skip: lumaLow,
                brightStreak: lumaDarkStreak
            )
            lumaDarkStreak = hold.streak
            lumaLow = hold.skip
        }
        let expensive = lumaLow || GestureMath.axBudgetSkip(visionMs: visMs, dt: engine.rawFrameDt)
        let latch = GestureMath.skipAXLatch(
            expensive: expensive,
            skip: axSkipLatched,
            cheapStreak: axCheapStreak
        )
        axSkipLatched = latch.skip
        axCheapStreak = latch.streak
        let snap = tracker.snapshotFaces()
        let wasArmed = engine.mode == .armed
        engine.tick(
            hands: hands,
            now: now,
            skipAX: latch.skip,
            faces: GestureMath.faceCountFresh(count: snap.count, lastSeen: snap.lastSeen, now: now),
            luma: luma
        )
        if engine.mode == .armed, !wasArmed,
           GestureMath.fistAELockApplies(continuity: engine.cameraFallback) {
            camera.lockExposure(seconds: GestureMath.fistAELock)
        }
        visionMs = visMs
        holdRing = GestureMath.darkRingHolds(darkStreak: lumaDarkStreak)
        let liveGhost = hands.contains { $0.id == engine.actorHandID && $0.isGhost }
        let ghostHold = GestureMath.overlayGhostPeakHold(current: liveGhost, remaining: overlayGhostHold)
        overlayGhostHold = ghostHold.remaining
        let ghost = ghostHold.ghost
        let liveCursor = GestureMath.overlayShowsCursor(mousePaused: engine.mousePaused) ? engine.cursor : nil
        let ringCursor = holdRing ? lastOverlayCursor : liveCursor
        if !holdRing { lastOverlayCursor = liveCursor }
        overlay.mark(
            cursor: ringCursor,
            phase: engine.grabPhase,
            hand: engine.cursorHand,
            target: engine.grabTargetName,
            window: engine.grabOutlineQuartz() ?? focused?.quartzBounds,
            ghost: ghost,
            settle: engine.clickSettle,
            hover: engine.hoverProgress,
            magnet: engine.trafficMagnet,
            lights: engine.trafficLights,
            fling: GestureMath.flingGhostLabel(engine.flingGhostKind),
            kind: engine.hoverKind
        )
        if GestureMath.overlayLerpShould(dt: engine.rawFrameDt) {
            overlayHandsFrom = overlayHandsTo.isEmpty ? hands : overlayHandsTo
            overlayHandsTo = hands
            overlayLerpAt = now
            overlayLerpDt = max(0.05, engine.rawFrameDt)
            self.hands = overlayLerpHands(from: overlayHandsFrom, to: overlayHandsTo, t: 0)
        } else {
            overlayHandsFrom = []
            overlayHandsTo = []
            self.hands = hands
        }
        roiLatchChip = GestureMath.palmROILatchChip(
            secondHand: hands.filter { !$0.isGhost }.count >= 2,
            dt: engine.rawFrameDt
        ) ?? ""
        engineCursor = engine.cursor
        cursorHand = engine.cursorHand
        grabPhase = engine.grabPhase
        grabTargetName = engine.grabTargetName
        actorHandID = engine.actorHandID
        mode = engine.mode
        lastAction = engine.lastAction
        frames += 1
        let raw = engine.rawFrameDt
        if cameraFallback, raw > 0.20 {
            if formatStuckSince == nil { formatStuckSince = now }
            let hold = now - (formatStuckSince ?? now)
            let lock = GestureMath.continuityLockRetry(dt: raw, hold: hold)
            let stuck = GestureMath.continuityStuck(dt: raw, hold: hold)
            let cool: TimeInterval = lock ? 2.0 : GestureMath.continuityReselectCooldown()
            if (lock || stuck), now - lastFormatReselect >= cool,
               !GestureMath.thermalHoldsFormat(medianFps: fps, slowFor: hold),
               !GestureMath.continuityUsbHold(dt: raw, hold: hold),
               !GestureMath.formatHopHold(last: lastFormatReselect, now: now)
            {
                lastFormatReselect = now
                formatStuckSince = now
                camera.reselectFormat()
                log.record("Continuity-Format neu — Takt \(String(format: "%.0f", 1.0 / max(0.008, raw))) fps", kind: .info)
            }
        } else if !cameraFallback || raw <= 0.20 {
            formatStuckSince = nil
        }
        if now - fpsStamp >= 0.5 {
            fps = Double(frames) / (now - fpsStamp)
            frames = 0
            fpsStamp = now
            fpsSamples.append(fps)
            if fpsSamples.count > 8 { fpsSamples.removeFirst(fpsSamples.count - 8) }
            fpsSpark = GestureMath.fpsSpark(fpsSamples)
            let med = GestureMath.medianFps(fpsSamples)
            if let dt = med > 0.5 ? 1.0 / med : nil,
               displayPulse?.link == nil,
               let want = GestureMath.displayLinkTimerRetarget(current: displayTimerPeriod, frameDt: dt)
            {
                armDisplayTimer(period: want)
            }
            if GestureMath.cameraSlowNow(medianFps: med) {
                if slowSince == nil { slowSince = now }
                if now - (slowSince ?? now) >= GestureMath.watchdogHold {
                    cameraSlow = true
                }
            } else {
                slowSince = nil
                if med >= GestureMath.watchdogFps + 2 {
                    cameraSlow = false
                }
            }
        }
        if hands.isEmpty {
            if idleSince == nil { idleSince = now }
            hudDim = GestureMath.hudDims(idleFor: now - (idleSince ?? now), armed: engine.mode == .armed)
        } else {
            idleSince = nil
            hudDim = false
        }
        if protocolMode {
            recorder.push(
                hands: hands,
                preview: preview,
                luma: luma,
                mode: engine.mode,
                action: engine.lastAction,
                now: now
            )
        }
        guard now - lastPanel >= 0.09 else { return }
        lastPanel = now
        self.luma = luma
        latencyMs = latency
        trashHot = engine.trashHot
        killFlash = engine.killFlash
        calibActive = calibSession.active
        calibCorner = calibSession.corner.titleDE
        calibHold = calibSession.progress
        calibCursorGap = calibSession.cursorGap
        mapReady = engine.spaceMap?.isUsable == true
        mapDrifted = engine.mapDrifted
        mousePaused = engine.mousePaused
        awaitingRearm = engine.awaitingRearm
    }
}

enum Prefs {
    static var leftHanded: Bool {
        get { UserDefaults.standard.object(forKey: "helios.leftHanded") as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: "helios.leftHanded") }
    }
    static var pointerGain: Double {
        get {
            let v = UserDefaults.standard.double(forKey: "helios.pointerGain")
            return v == 0 ? 1.6 : min(3.2, max(0.6, v))
        }
        set { UserDefaults.standard.set(newValue, forKey: "helios.pointerGain") }
    }
    static var palmHighpass: Double {
        get {
            if UserDefaults.standard.object(forKey: "helios.palmHighpass") == nil {
                return Double(GestureMath.palmHighpassAlphaDefault)
            }
            return Double(GestureMath.palmHighpassAlpha(
                CGFloat(UserDefaults.standard.double(forKey: "helios.palmHighpass"))
            ))
        }
        set { UserDefaults.standard.set(newValue, forKey: "helios.palmHighpass") }
    }
    static var destEdgePad: Double {
        get {
            if UserDefaults.standard.object(forKey: "helios.destEdgePad") == nil {
                return Double(GestureMath.destEdgePad)
            }
            return Double(GestureMath.destEdgePadPref(
                CGFloat(UserDefaults.standard.double(forKey: "helios.destEdgePad"))
            ))
        }
        set { UserDefaults.standard.set(newValue, forKey: "helios.destEdgePad") }
    }
    static var destEdgePadMap: [String: CGFloat] {
        get {
            (UserDefaults.standard.dictionary(forKey: "helios.destEdgePadMap") as? [String: Double])?
                .mapValues { CGFloat($0) } ?? [:]
        }
        set {
            UserDefaults.standard.set(
                Dictionary(uniqueKeysWithValues: newValue.map { ($0.key, Double($0.value)) }),
                forKey: "helios.destEdgePadMap"
            )
        }
    }
    static var destEdgeSkip: Double {
        get {
            if UserDefaults.standard.object(forKey: "helios.destEdgeSkip") == nil {
                return GestureMath.destEdgeCrossHoldSec
            }
            return GestureMath.destEdgeSkipPref(UserDefaults.standard.double(forKey: "helios.destEdgeSkip"))
        }
        set { UserDefaults.standard.set(newValue, forKey: "helios.destEdgeSkip") }
    }
    static var palmCoastNeed: Double {
        get {
            if UserDefaults.standard.object(forKey: "helios.palmCoastNeed") == nil {
                return 2
            }
            return Double(GestureMath.palmCoastNeedPref(Int(UserDefaults.standard.double(forKey: "helios.palmCoastNeed").rounded())))
        }
        set { UserDefaults.standard.set(newValue, forKey: "helios.palmCoastNeed") }
    }
    static var fillCapLaptop: Double {
        get {
            if UserDefaults.standard.object(forKey: "helios.fillCapLaptop") == nil {
                return 12
            }
            return Double(GestureMath.fillCapLaptopPref(
                CGFloat(UserDefaults.standard.double(forKey: "helios.fillCapLaptop"))
            ))
        }
        set { UserDefaults.standard.set(newValue, forKey: "helios.fillCapLaptop") }
    }
    static var fillCapStudio: Double {
        get {
            if UserDefaults.standard.object(forKey: "helios.fillCapStudio") == nil {
                return 28
            }
            return Double(GestureMath.fillCapStudioPref(
                CGFloat(UserDefaults.standard.double(forKey: "helios.fillCapStudio"))
            ))
        }
        set { UserDefaults.standard.set(newValue, forKey: "helios.fillCapStudio") }
    }
    static var fillCapMap: [String: CGFloat] {
        get {
            (UserDefaults.standard.dictionary(forKey: "helios.fillCapMap") as? [String: Double])?
                .mapValues { CGFloat($0) } ?? [:]
        }
        set {
            UserDefaults.standard.set(
                Dictionary(uniqueKeysWithValues: newValue.map { ($0.key, Double($0.value)) }),
                forKey: "helios.fillCapMap"
            )
        }
    }
    static var deadManFist: Double {
        get {
            if UserDefaults.standard.object(forKey: "helios.deadManFist") == nil {
                return GestureMath.deadManFist
            }
            return GestureMath.deadManFistPref(UserDefaults.standard.double(forKey: "helios.deadManFist"))
        }
        set { UserDefaults.standard.set(newValue, forKey: "helios.deadManFist") }
    }
    static var flingWindow: Double {
        get {
            if UserDefaults.standard.object(forKey: "helios.flingWindow") == nil {
                return GestureMath.flingWindow
            }
            return GestureMath.flingWindowPref(UserDefaults.standard.double(forKey: "helios.flingWindow"))
        }
        set { UserDefaults.standard.set(newValue, forKey: "helios.flingWindow") }
    }
    static var swipeOpenOnly: Bool {
        get { UserDefaults.standard.bool(forKey: "helios.swipeOpenOnly") }
        set { UserDefaults.standard.set(newValue, forKey: "helios.swipeOpenOnly") }
    }
    static var protocolMode: Bool {
        get { UserDefaults.standard.object(forKey: "helios.protocolMode") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "helios.protocolMode") }
    }
    static var testMode: Bool {
        get { UserDefaults.standard.bool(forKey: "helios.testMode") }
        set { UserDefaults.standard.set(newValue, forKey: "helios.testMode") }
    }
    static var hudVisible: Bool {
        get { UserDefaults.standard.object(forKey: "helios.hud") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "helios.hud") }
    }
    static var showReticle: Bool {
        get { UserDefaults.standard.object(forKey: "helios.reticle") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "helios.reticle") }
    }
    static var showJointLabels: Bool {
        get { UserDefaults.standard.object(forKey: "helios.joints") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "helios.joints") }
    }
    static var showCheats: Bool {
        get { UserDefaults.standard.object(forKey: "helios.cheats") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "helios.cheats") }
    }
    static var showOutline: Bool {
        get { UserDefaults.standard.object(forKey: "helios.outline") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "helios.outline") }
    }
    static var showTrashZone: Bool {
        get { UserDefaults.standard.object(forKey: "helios.trash") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "helios.trash") }
    }
    static var showPreviewChip: Bool {
        get { UserDefaults.standard.object(forKey: "helios.preview") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "helios.preview") }
    }
    static var cameraChoice: CameraChoice {
        get {
            let raw = UserDefaults.standard.string(forKey: "helios.cameraChoice") ?? CameraChoice.auto.rawValue
            return CameraChoice(rawValue: raw) ?? .auto
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "helios.cameraChoice") }
    }

    static func supportDir() -> URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Helios", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func bundleList(_ name: String) -> Set<String> {
        let url = supportDir().appendingPathComponent(name)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return GestureMath.prefsBundleList(text)
    }

    /// ~/Library/Application Support/Helios/click-lock.txt
    static var clickLockExtra: Set<String> { bundleList("click-lock.txt") }
    /// ~/Library/Application Support/Helios/game-lock.txt — Vollbild dieser Apps = GAME.
    static var gameLockExtra: Set<String> { bundleList("game-lock.txt") }
}

/// Vision-Queue schreibt, Main drain t. Zwischenframes fallen — der letzte bleibt.
private final class VisionInbox: @unchecked Sendable {
    private let lock = NSLock()
    private var latest: (hands: [TrackedHand], latency: Double, luma: CGFloat, visMs: Double)?
    private var scheduled = false

    func push(
        hands: [TrackedHand],
        latency: Double,
        luma: CGFloat,
        visMs: Double = 0,
        onMain: @escaping () -> Void
    ) {
        lock.lock()
        latest = (hands, latency, luma, visMs)
        let need = !scheduled
        if need { scheduled = true }
        lock.unlock()
        if need {
            DispatchQueue.main.async(qos: .userInteractive, execute: onMain)
        }
    }

    func take() -> (hands: [TrackedHand], latency: Double, luma: CGFloat, visMs: Double)? {
        lock.lock()
        defer { lock.unlock() }
        let v = latest
        latest = nil
        if v == nil { scheduled = false }
        return v
    }

    func reset() {
        lock.lock()
        latest = nil
        scheduled = false
        lock.unlock()
    }
}

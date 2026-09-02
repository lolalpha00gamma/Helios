import AppKit
import Combine
import CoreMedia
import CoreVideo
import Foundation
import QuartzCore
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    let camera = CameraSession()
    let engine = GestureEngine()
    let log = AuditLog()
    let recorder = SessionRecorder()
    private let overlay = OverlayController()
    private var permTimer: Timer?
    private var frames: Int = 0
    private var fpsStamp: TimeInterval = CACurrentMediaTime()
    private let tracker = HandTracker()

    @Published var hands: [TrackedHand] = []
    @Published var mode: EngineMode = .idle
    @Published var lastAction = "—"
    @Published var fps: Double = 0
    @Published var latencyMs: Double = 0
    @Published var latencyHistory: [Double] = []
    @Published var dwellEnabled = false
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
    @Published var grabPhase: GrabPhase = .none
    @Published var grabTargetName = ""
    @Published var fusion: FusionDebug?
    @Published var hasDepth = false
    @Published var fusionTemperature: Double = 0.75
    @Published var profileName = "Standard"
    @Published var mapRMSE: CGFloat?
    let calibSession = CalibrationSession()
    private var lastPanel: TimeInterval = 0
    private var didStart = false

    private var cancellables: Set<AnyCancellable> = []
    private var focusTick = 0

    func start() {
        if didStart { return }
        didStart = true
        overlay.attach(state: self)
        engine.startInputClutch()
        engine.calibration = calibSession
        engine.spaceMap = SpaceMap.load()
        mapReady = engine.spaceMap?.isReady == true
        mapRMSE = engine.spaceMap?.rmse()
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
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reloadSpaceMap() }
            .store(in: &cancellables)
        camera.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.deviceName = self.camera.deviceName
                self.cameraRunning = self.camera.isRunning
                self.cameraError = self.camera.errorMessage
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
                self?.focusTick += 1
                if (self?.focusTick ?? 0) % 5 == 0 {
                    self?.refreshPermissions()
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

    func refreshPermissions() {
        cameraOK = Permissions.cameraGranted()
        accessOK = Permissions.accessibilityGranted()
        inputOK = Permissions.inputMonitoringGranted()
        fromDiskImage = AppInstall.needsCopy
        installPath = AppInstall.locationHint
        screenCount = NSScreen.screens.count
    }

    func pollFocus() {
        focused = engine.cursor.flatMap { TargetProbe.windowAt(quartz: $0) } ?? FocusTracker.poll()
        engine.focused = focused
        let nextProfile = AppGestureProfile.forBundle(focused?.bundleId ?? "")
        if engine.profile != nextProfile {
            engine.profile = nextProfile
            profileName = nextProfile.name
        }
        trashHot = engine.trashHot
        killFlash = engine.killFlash
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
        camera.onFrame = { [weak self] vision, _, luma, arrived in
            let t0 = CACurrentMediaTime()
            let hands = tracker.analyze(
                pixelBuffer: vision,
                now: t0,
                mirrored: cam.isMirrored,
                depth: cam.latestDepth,
                orientation: cam.frameOrientation
            )
            let visMs = (CACurrentMediaTime() - t0) * 1000
            let endToEnd = (CACurrentMediaTime() - arrived) * 1000
            DispatchQueue.main.async(qos: .userInteractive) {
                self?.apply(
                    hands: hands,
                    latency: max(visMs, endToEnd),
                    now: CACurrentMediaTime(),
                    preview: nil,
                    luma: luma
                )
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
        cameraRunning = false
        hands = []
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

    func setDwellEnabled(_ on: Bool) {
        dwellEnabled = on
        engine.dwellEnabled = on
        Prefs.dwellEnabled = on
        log.record(on ? "Dwell-Klick an" : "Dwell-Klick aus", kind: .info)
    }

    private func loadPrefs() {
        leftHanded = Prefs.leftHanded
        pointerGain = Prefs.pointerGain
        protocolMode = Prefs.protocolMode
        testMode = Prefs.testMode
        hudVisible = Prefs.hudVisible
        showReticle = Prefs.showReticle
        showJointLabels = Prefs.showJointLabels
        showCheats = Prefs.showCheats
        showOutline = Prefs.showOutline
        showTrashZone = Prefs.showTrashZone
        showPreviewChip = Prefs.showPreviewChip
        dwellEnabled = Prefs.dwellEnabled
        fusionTemperature = Prefs.fusionTemperature
        engine.leftHanded = leftHanded
        engine.pointerGain = CGFloat(pointerGain)
        engine.protocolMode = protocolMode
        engine.testMode = testMode
        engine.dwellEnabled = dwellEnabled
        engine.fusionTemperature = fusionTemperature
        tracker.fusionTemperature = fusionTemperature
    }

    func setFusionTemperature(_ t: Double) {
        fusionTemperature = t
        engine.fusionTemperature = t
        tracker.fusionTemperature = t
        Prefs.fusionTemperature = t
    }

    func startCalibration(ninePoint: Bool = true) {
        hudVisible = true
        overlayVisible()
        let id = NSScreen.main.map { ScreenGeometry.displayID(of: $0) }
        calibSession.start(ninePoint: ninePoint, displayID: id)
        engine.calibration = calibSession
        log.record(ninePoint ? "Kalibrierung: 9-Punkt-Gitter" : "Kalibrierung: vier Ecken", kind: .info)
    }

    func setProfileAction(_ action: GestureAction, on: Bool) {
        guard let id = focused?.bundleId, !id.isEmpty else { return }
        AppGestureProfile.setAction(action, bundle: id, on: on)
        engine.profile = AppGestureProfile.forBundle(id)
        profileName = engine.profile.name
        log.record("Profil \(profileName): \(action.titleDE) \(on ? "an" : "aus")", kind: .info)
    }

    func setInvertScroll(_ on: Bool) {
        guard let id = focused?.bundleId, !id.isEmpty else { return }
        AppGestureProfile.setInvertScroll(bundle: id, on: on)
        engine.profile = AppGestureProfile.forBundle(id)
        profileName = engine.profile.name
        log.record("Profil \(profileName): Scroll \(on ? "invertiert" : "normal")", kind: .info)
    }

    func reloadSpaceMap() {
        screenCount = NSScreen.screens.count
        let loc = engine.cursor ?? ScreenGeometry.quartz(fromCocoa: NSEvent.mouseLocation)
        let screen = ScreenGeometry.screenContaining(quartz: loc) ?? NSScreen.main
        let id = screen.map { ScreenGeometry.displayID(of: $0) }
        if let map = SpaceMap.load(displayID: id), map.isReady {
            engine.spaceMap = map
            mapReady = true
            mapRMSE = map.rmse()
            log.record("Schirme \(screenCount) — Karte für Display \(id ?? 0) geladen", kind: .info)
        } else {
            engine.spaceMap = nil
            mapReady = false
            mapRMSE = nil
            log.record("Schirme \(screenCount) — keine Karte für diesen Display", kind: .info)
        }
    }

    func cancelCalibration() {
        calibSession.cancel()
        log.record("Kalibrierung abgebrochen", kind: .info)
    }

    func clearCalibration() {
        SpaceMap.clear()
        engine.spaceMap = nil
        mapReady = false
        mapRMSE = nil
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

    fileprivate func apply(
        hands: [TrackedHand],
        latency: Double,
        now: TimeInterval,
        preview: NSImage?,
        luma: CGFloat
    ) {
        engine.tick(hands: hands, now: now)
        overlay.mark(
            cursor: engine.cursor,
            phase: engine.grabPhase,
            hand: engine.cursorHand,
            target: engine.grabTargetName,
            window: focused?.quartzBounds
        )
        frames += 1
        if now - fpsStamp >= 0.5 {
            fps = Double(frames) / (now - fpsStamp)
            frames = 0
            fpsStamp = now
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
        var hist = latencyHistory
        hist.append(latency)
        if hist.count > 30 { hist.removeFirst(hist.count - 30) }
        latencyHistory = hist
        mode = engine.mode
        lastAction = engine.lastAction
        engineCursor = engine.cursor
        cursorHand = engine.cursorHand
        trashHot = engine.trashHot
        killFlash = engine.killFlash
        calibActive = calibSession.active
        calibCorner = calibSession.spot.titleDE
        calibHold = calibSession.progress
        calibCursorGap = calibSession.cursorGap
        mapReady = engine.spaceMap?.isReady == true
        mapRMSE = engine.spaceMap?.rmse()
        mousePaused = engine.mousePaused
        grabPhase = engine.grabPhase
        grabTargetName = engine.grabTargetName
        self.hands = hands
        fusion = hands.first?.fusion ?? tracker.lastFusion
        hasDepth = camera.hasDepth
        camera.setHandsPresent(!hands.isEmpty)
        profileName = engine.profile.name
    }
}

enum Prefs {
    static var leftHanded: Bool {
        get { UserDefaults.standard.object(forKey: "helios.leftHanded") as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: "helios.leftHanded") }
    }
    static var dwellEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "helios.dwell") }
        set { UserDefaults.standard.set(newValue, forKey: "helios.dwell") }
    }
    static var pointerGain: Double {
        get {
            let v = UserDefaults.standard.double(forKey: "helios.pointerGain")
            return v == 0 ? 1.6 : min(3.2, max(0.6, v))
        }
        set { UserDefaults.standard.set(newValue, forKey: "helios.pointerGain") }
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
    static var fusionTemperature: Double {
        get {
            let v = UserDefaults.standard.double(forKey: "helios.fusionT")
            return v == 0 ? 0.75 : min(1.4, max(0.35, v))
        }
        set { UserDefaults.standard.set(newValue, forKey: "helios.fusionT") }
    }
}

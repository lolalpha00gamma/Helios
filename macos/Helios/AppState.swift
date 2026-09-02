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
    @Published var leftHanded = true
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
    @Published var chromeKnobs: [ChromeKnob] = []
    @Published var chromeHot = ""
    @Published var hideConsoleWhenArmed = true
    @Published var cameraDevices: [CameraChoice] = []
    @Published var selectedCameraID = ""
    @Published var fusion: FusionDebug?
    @Published var hasDepth = false
    @Published var permissionBanner = ""
    let calibSession = CalibrationSession()
    private var lastPanel: TimeInterval = 0
    private var didStart = false
    private let applySlot = ApplySlot()

    private var lastArmedConsole: EngineMode = .idle
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
        Permissions.onDemand = { [weak self] kind in
            self?.permissionBanner = "Rechte: \(kind.title) — Systemeinstellungen"
            self?.log.record("Rechte fehlen: \(kind.title)", kind: .blocked)
        }
        engine.onLog = { [weak self] text, kind, conf in
            self?.log.record(text, kind: kind, confidence: conf)
            self?.objectWillChange.send()
        }
        loadPrefs()
        log.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
        $hudVisible.sink { Prefs.hudVisible = $0 }.store(in: &cancellables)
        $showReticle.sink { [weak self] v in
            Prefs.showReticle = v
            guard let self else { return }
            self.overlay.mark(
                cursor: self.engine.cursor,
                phase: self.engine.grabPhase,
                hand: self.engine.cursorHand,
                target: self.engine.grabTargetName,
                window: self.focused?.quartzBounds,
                showReticle: v
            )
        }.store(in: &cancellables)
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
                self.cameraRunning = self.camera.isRunning
                self.cameraError = self.camera.errorMessage
                self.cameraDevices = self.camera.devices
                self.selectedCameraID = self.camera.selectedID
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
        permTimer?.tolerance = 0.05
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
        if cameraOK, accessOK, inputOK {
            permissionBanner = ""
        }
    }

    func pollFocus() {
        focused = engine.cursor.flatMap { TargetProbe.windowAt(quartz: $0) } ?? FocusTracker.poll()
        engine.focused = focused
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
        let slot = self.applySlot
        camera.onFrame = { [weak self] vision, _, luma, arrived in
            let t0 = CACurrentMediaTime()
            let hands = tracker.analyze(
                pixelBuffer: vision,
                now: t0,
                mirrored: cam.isMirrored,
                depth: cam.latestDepth,
                orientation: cam.visionOrientation
            )
            let visMs = (CACurrentMediaTime() - t0) * 1000
            let endToEnd = (CACurrentMediaTime() - arrived) * 1000
            slot.push(
                hands: hands,
                latency: max(visMs, endToEnd),
                now: t0,
                luma: luma
            ) {
                DispatchQueue.main.async { self?.drainApply() }
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

    func shutdown() {
        permTimer?.invalidate()
        permTimer = nil
        engine.stopInputClutch()
        overlay.detach()
        stopCamera()
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
        hideConsoleWhenArmed = Prefs.hideConsoleWhenArmed
        engine.leftHanded = leftHanded
        engine.pointerGain = CGFloat(pointerGain)
        engine.protocolMode = protocolMode
        engine.testMode = testMode
        engine.dwellEnabled = dwellEnabled
        engine.hideConsoleWhenArmed = hideConsoleWhenArmed
        cameraDevices = CameraSession.discover()
        selectedCameraID = UserDefaults.standard.string(forKey: "helios.cameraID")
            ?? cameraDevices.first?.id ?? ""
        if !selectedCameraID.isEmpty, !cameraDevices.contains(where: { $0.id == selectedCameraID }) {
            selectedCameraID = cameraDevices.first?.id ?? ""
        }
    }

    func setHideConsoleWhenArmed(_ on: Bool) {
        hideConsoleWhenArmed = on
        engine.hideConsoleWhenArmed = on
        Prefs.hideConsoleWhenArmed = on
        if !on {
            ConsolePolicy.show()
        }
        log.record(on ? "Konsole bei Scharf aus" : "Konsole bleibt sichtbar", kind: .info)
    }

    func selectCamera(_ id: String) {
        selectedCameraID = id
        camera.selectDevice(id)
        log.record("Kamera: \(cameraDevices.first(where: { $0.id == id })?.name ?? id)", kind: .info)
    }

    func startCalibration() {
        hudVisible = true
        overlayVisible()
        calibSession.start()
        engine.calibration = calibSession
        log.record("Kalibrierung: Ecke oben links", kind: .info)
    }

    func cancelCalibration() {
        calibSession.cancel()
        log.record("Kalibrierung abgebrochen", kind: .info)
    }

    func clearCalibration() {
        SpaceMap.clear()
        engine.spaceMap = nil
        mapReady = false
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
            window: focused?.quartzBounds,
            showReticle: showReticle
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
        if engine.chromeKnobs != chromeKnobs || engine.chromeHot != chromeHot {
            chromeKnobs = engine.chromeKnobs
            chromeHot = engine.chromeHot
        }
        if hideConsoleWhenArmed, engine.mode == .armed, lastArmedConsole != .armed, !testMode {
            ConsolePolicy.hide()
        }
        lastArmedConsole = engine.mode
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
        calibCorner = calibSession.corner.titleDE
        calibHold = calibSession.progress
        calibCursorGap = calibSession.cursorGap
        mapReady = engine.spaceMap?.isReady == true
        mousePaused = engine.mousePaused
        grabPhase = engine.grabPhase
        grabTargetName = engine.grabTargetName
        self.hands = hands
        fusion = hands.first?.fusion ?? tracker.lastFusion
        hasDepth = camera.hasDepth
        cameraDevices = camera.devices
        selectedCameraID = camera.selectedID
    }

    private func drainApply() {
        guard let item = applySlot.take() else { return }
        apply(hands: item.hands, latency: item.latency, now: item.now, preview: nil, luma: item.luma)
    }
}

/// Nur den neuesten Stand nach main — analog FramePump.
private final class ApplySlot: @unchecked Sendable {
    private let lock = NSLock()
    private var pending: (hands: [TrackedHand], latency: Double, now: TimeInterval, luma: CGFloat)?
    private var queued = false

    func push(
        hands: [TrackedHand],
        latency: Double,
        now: TimeInterval,
        luma: CGFloat,
        schedule: () -> Void
    ) {
        lock.lock()
        pending = (hands, latency, now, luma)
        let need = !queued
        if need { queued = true }
        lock.unlock()
        if need { schedule() }
    }

    func take() -> (hands: [TrackedHand], latency: Double, now: TimeInterval, luma: CGFloat)? {
        lock.lock()
        let item = pending
        pending = nil
        queued = false
        lock.unlock()
        return item
    }
}

enum Prefs {
    static var leftHanded: Bool {
        get { UserDefaults.standard.object(forKey: "helios.leftHanded") as? Bool ?? true }
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
    static var hideConsoleWhenArmed: Bool {
        get { UserDefaults.standard.object(forKey: "helios.hideConsole") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "helios.hideConsole") }
    }
}

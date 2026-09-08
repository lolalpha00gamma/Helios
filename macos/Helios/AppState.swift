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
    let drill = ActionDrill()
    private let overlay = OverlayController()
    private var permTimer: Timer?
    private var frames: Int = 0
    private var fpsStamp: TimeInterval = CACurrentMediaTime()
    private var fpsSpark: [(t: TimeInterval, fps: Double)] = []
    private let tracker = HandTracker()
    private let coverTracker = HandTracker()
    private let coverSlot = CoverSlot()
    private var usingCover = false

    @Published var hands: [TrackedHand] = []
    @Published var mode: EngineMode = .idle
    @Published var lastAction = "—"
    @Published var fps: Double = 0
    @Published var fpsAmber = false
    @Published var fpsSparkBars: [CGFloat] = []
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
    @Published var showOutline = false
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
    @Published var chromeDwell: CGFloat = 0
    @Published var keyboardVisible = false
    @Published var keyboardHits: [AirKeyHit] = []
    @Published var keyboardHover = ""
    @Published var keyboardDwell: CGFloat = 0
    @Published var hideConsoleWhenArmed = false
    @Published var cameraDevices: [CameraChoice] = []
    @Published var selectedCameraID = ""
    @Published var cameraPair: CameraPair = .single
    @Published var coverName = "—"
    @Published var coverRunning = false
    @Published var coverError: String?
    @Published var coverPreview: NSImage?
    @Published var coverHands: [TrackedHand] = []
    @Published var coverID = ""
    @Published var coverMapReady = false
    @Published var actorSource = ""
    @Published var fusion: FusionDebug?
    @Published var hasDepth = false
    @Published var permissionBanner = ""
    @Published var fusionTemperature: Double = 0.75
    @Published var peaceProgress: CGFloat = 0
    @Published var lockFreeze = ""
    @Published var qualityChip = ""
    let calibSession = CalibrationSession()
    private var lastPanel: TimeInterval = 0
    private var didStart = false
    private let applySlot = ApplySlot()

    private var lastArmedConsole: EngineMode = .idle
    private var lastAppliedCameraID = ""
    private var lastAppliedCameraName = ""
    private var lastAppliedCameraRole = ""
    private var mapMemo: [String: SpaceMap] = [:]
    private var cancellables: Set<AnyCancellable> = []
    private var didShutdown = false
    private var focusTick = 0
    private var focusHoldID: CGWindowID = 0
    private var focusHoldCount = 0

    func start() {
        if didStart { return }
        didStart = true
        HeliosAppDelegate.state = self
        overlay.attach(state: self)
        overlay.onCoastCursor = { [weak self] p in
            self?.engine.coastCursor(p)
        }
        engine.startInputClutch()
        engine.calibration = calibSession
        engine.spaceMap = SpaceMap.load(displayID: ScreenGeometry.mainDisplayID)
        mapReady = engine.spaceMap?.isReady == true
        ConsolePolicy.installGuard()
        Permissions.onDemand = { [weak self] kind in
            self?.permissionBanner = "Rechte: \(kind.title) — Systemeinstellungen"
            self?.log.record("Rechte fehlen: \(kind.title)", kind: .blocked)
        }
        engine.onLog = { [weak self] text, kind, conf in
            self?.log.record(text, kind: kind, confidence: conf)
        }
        loadPrefs()
        log.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
        drill.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
        $hudVisible.sink { Prefs.hudVisible = $0 }.store(in: &cancellables)
        $showReticle.sink { [weak self] v in
            Prefs.showReticle = v
            guard let self else { return }
            self.overlay.mark(
                cursors: self.engine.handCursors,
                phase: self.engine.grabPhase,
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
                self.coverName = self.camera.coverName
                self.coverRunning = self.camera.coverRunning
                self.coverError = self.camera.coverError
                self.coverID = self.camera.coverID
                self.cameraPair = self.camera.pair
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
        let sticky = engine.grabPhase == .grab || engine.grabPhase == .hold
        let raw: FocusedTarget?
        if let c = engine.cursor {
            raw = TargetProbe.windowAt(quartz: c)
        } else if sticky, let prev = focused {
            raw = TargetProbe.window(id: prev.windowID) ?? prev
        } else {
            raw = nil
        }
        let next: FocusedTarget?
        if sticky {
            next = quietBounds(raw ?? focused)
            focusHoldCount = 2
            focusHoldID = next?.windowID ?? 0
        } else if let raw {
            if raw.windowID == focused?.windowID {
                focusHoldID = raw.windowID
                focusHoldCount = 2
                next = quietBounds(raw)
            } else if raw.windowID == focusHoldID {
                focusHoldCount += 1
                next = focusHoldCount >= 2 ? raw : focused
            } else {
                focusHoldID = raw.windowID
                focusHoldCount = 1
                next = focused
            }
        } else {
            focusHoldCount = 0
            focusHoldID = 0
            next = nil
        }
        if focused != next {
            focused = next
        }
        engine.focused = focused
        trashHot = engine.trashHot
        killFlash = engine.killFlash
    }

    /// Subpixel-/Shadow-Sprünge der CGWindowList nicht in die HUD-Höhe durchreichen.
    private func quietBounds(_ incoming: FocusedTarget?) -> FocusedTarget? {
        guard let incoming, let old = focused, old.windowID == incoming.windowID else {
            return incoming
        }
        let a = old.quartzBounds
        let b = incoming.quartzBounds
        if abs(a.minX - b.minX) < 4, abs(a.minY - b.minY) < 4,
           abs(a.width - b.width) < 4, abs(a.height - b.height) < 4
        {
            return old
        }
        return incoming
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
        let coverTracker = self.coverTracker
        let cam = self.camera
        let slot = self.applySlot
        camera.onFrame = { [weak self] vision, _, luma, arrived in
            let t0 = CACurrentMediaTime()
            var hands = tracker.analyze(
                pixelBuffer: vision,
                now: arrived,
                mirrored: cam.isMirrored,
                depth: cam.latestDepth,
                orientation: cam.visionOrientation
            )
            let leadID = cam.selectedID
            for i in hands.indices {
                hands[i].sourceID = leadID
                hands[i].id = "L." + hands[i].id
            }
            let visMs = (CACurrentMediaTime() - t0) * 1000
            let endToEnd = max(0, (t0 - arrived) * 1000)
            slot.push(
                hands: hands,
                latency: max(visMs, endToEnd > 5000 ? visMs : endToEnd),
                now: arrived,
                luma: luma
            ) {
                Task { @MainActor in self?.drainApply() }
            }
        }
        camera.coverPipe.onBuffer = { [weak self] pb, arrived, mirrored, orient in
            var hands = coverTracker.analyze(
                pixelBuffer: pb,
                now: arrived,
                mirrored: mirrored,
                depth: nil,
                orientation: orient
            )
            let cid = cam.coverID
            for i in hands.indices {
                hands[i].sourceID = cid
                hands[i].id = "C." + hands[i].id
            }
            self?.coverSlot.push(hands)
        }
        camera.coverPipe.onPreview = { [weak self] img in
            Task { @MainActor in self?.coverPreview = img }
        }
        camera.setPreviewSink { [weak self] img in
            self?.preview = img
        }
        camera.start()
        let names = cameraDevices.map { "\($0.name) [\($0.role.rawValue)]" }.joined(separator: ", ")
        log.record(names.isEmpty ? "Kamera gestartet." : "Kamera gestartet · \(names)", kind: .info)
    }

    func stopCamera() {
        camera.onFrame = nil
        camera.coverPipe.onBuffer = nil
        camera.coverPipe.onPreview = nil
        camera.stop()
        tracker.reset()
        coverTracker.reset()
        cameraRunning = false
        coverRunning = false
        hands = []
        coverSlot.push([])
        log.record("Kamera gestoppt.")
    }

    func shutdown() {
        if didShutdown { return }
        didShutdown = true
        permTimer?.invalidate()
        permTimer = nil
        engine.stopInputClutch()
        overlay.detach()
        stopCamera()
        ConsolePolicy.uninstall()
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

    func setFusionTemperature(_ t: Double) {
        fusionTemperature = min(1.4, max(0.35, t))
        tracker.fusionTemperature = fusionTemperature
        coverTracker.fusionTemperature = fusionTemperature
        Prefs.fusionTemperature = fusionTemperature
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
        fusionTemperature = Prefs.fusionTemperature
        engine.leftHanded = leftHanded
        engine.pointerGain = CGFloat(pointerGain)
        engine.protocolMode = protocolMode
        engine.testMode = testMode
        engine.dwellEnabled = dwellEnabled
        engine.hideConsoleWhenArmed = hideConsoleWhenArmed
        tracker.fusionTemperature = fusionTemperature
        coverTracker.fusionTemperature = fusionTemperature
        cameraDevices = CameraSession.discover()
        if let raw = UserDefaults.standard.string(forKey: "helios.cameraPair"),
           let p = CameraPair(rawValue: raw)
        {
            cameraPair = p
            camera.preparePair(p, devices: cameraDevices)
        }
        selectedCameraID = UserDefaults.standard.string(forKey: "helios.cameraID")
            ?? cameraDevices.first?.id ?? ""
        coverID = UserDefaults.standard.string(forKey: "helios.coverID") ?? ""
        if !selectedCameraID.isEmpty, !cameraDevices.contains(where: { $0.id == selectedCameraID }) {
            selectedCameraID = cameraDevices.first?.id ?? ""
        }
        engine.spaceMap = SpaceMap.load(cameraID: selectedCameraID, displayID: ScreenGeometry.mainDisplayID)
            ?? SpaceMap.load(displayID: ScreenGeometry.mainDisplayID)
        mapReady = engine.spaceMap?.isReady == true
        coverMapReady = coverCalibrated(UserDefaults.standard.string(forKey: "helios.coverID") ?? "")
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
        cameraPair = .single
        UserDefaults.standard.set(CameraPair.single.rawValue, forKey: "helios.cameraPair")
        selectedCameraID = id
        camera.selectDevice(id)
        engine.spaceMap = SpaceMap.load(cameraID: id, displayID: ScreenGeometry.mainDisplayID)
        mapReady = engine.spaceMap?.isReady == true
        log.record("Kamera: \(cameraDevices.first(where: { $0.id == id })?.name ?? id)", kind: .info)
    }

    func selectPair(_ pair: CameraPair) {
        cameraPair = pair
        camera.selectPair(pair, devices: cameraDevices, fallbackLead: selectedCameraID)
        if pair == .single {
            engine.spaceMap = SpaceMap.load(cameraID: selectedCameraID, displayID: ScreenGeometry.mainDisplayID)
            log.record("Eine Kamera", kind: .info)
            return
        }
        let mac = CameraSession.pick(cameraDevices, role: .mac)?.name
        let phone = CameraSession.pick(cameraDevices, role: .phone)?.name
        let osmo = CameraSession.pick(cameraDevices, role: .osmo)?.name
        log.record("Paar \(pair.titleDE) · Mac \(mac ?? "—") · iPhone \(phone ?? "—") · Osmo \(osmo ?? "—")", kind: .info)
        if CameraRig.resolve(
            pair: pair,
            mac: CameraSession.pick(cameraDevices, role: .mac)?.id,
            phone: CameraSession.pick(cameraDevices, role: .phone)?.id,
            osmo: CameraSession.pick(cameraDevices, role: .osmo)?.id
        ) == nil {
            log.record("Paar unvollständig — zweite Kamera fehlt. Osmo: am Gerät Webcam-Modus, USB-C. Dann Quelle unten wählen.", kind: .blocked)
        }
    }

    func rescanCameras() {
        cameraDevices = CameraSession.discover()
        let names = cameraDevices.map { "\($0.name) [\($0.role.rawValue)]" }.joined(separator: ", ")
        log.record(names.isEmpty ? "Keine Kamera gefunden." : "Quellen: \(names)", kind: .info)
        if cameraPair != .single {
            camera.selectPair(cameraPair, devices: cameraDevices, fallbackLead: selectedCameraID)
        }
    }

    func selectLead(_ id: String) {
        selectedCameraID = id
        let cover = coverID == id ? "" : coverID
        camera.assign(lead: id, cover: cover)
        engine.spaceMap = SpaceMap.load(cameraID: id, displayID: ScreenGeometry.mainDisplayID)
        mapReady = engine.spaceMap?.isReady == true
        log.record("Lead: \(cameraDevices.first(where: { $0.id == id })?.name ?? id)", kind: .info)
    }

    func selectCover(_ id: String) {
        if id == selectedCameraID {
            log.record("Cover muss eine andere Kamera sein als Lead.", kind: .blocked)
            return
        }
        coverID = id
        camera.assign(lead: selectedCameraID, cover: id)
        coverMapReady = coverCalibrated(id)
        log.record("Cover/Osmo: \(cameraDevices.first(where: { $0.id == id })?.name ?? id)", kind: .info)
    }

    func startCalibration() {
        hudVisible = true
        overlayVisible()
        let coverID = camera.coverID
        let leadID = camera.selectedID
        let disp = ScreenGeometry.mainDisplayID
        let leadReady = SpaceMap.load(cameraID: leadID, displayID: disp)?.isReady == true
        if cameraPair != .single, !coverID.isEmpty, leadReady,
           SpaceMap.load(cameraID: coverID, displayID: disp)?.isReady != true
        {
            calibSession.start(cameraID: coverID, label: camera.coverName)
            log.record("Kalibrierung zweiter Winkel: \(camera.coverName)", kind: .info)
        } else {
            let label = camera.deviceName
            calibSession.start(cameraID: leadID, label: label)
            log.record("Kalibrierung: \(label) · Ecke oben links", kind: .info)
        }
        engine.calibration = calibSession
    }

    func cancelCalibration() {
        calibSession.cancel()
        log.record("Kalibrierung abgebrochen", kind: .info)
    }

    func clearCalibration() {
        SpaceMap.clear()
        invalidateMaps()
        engine.spaceMap = nil
        mapReady = false
        coverMapReady = false
        log.record("Kalibrierung gelöscht — Relativ-Zeiger", kind: .info)
    }

    func reloadSpaceMap() {
        invalidateMaps()
        let id = usingCover ? camera.coverID : camera.selectedID
        let cursor = engine.cursor ?? .zero
        let screens = NSScreen.screens.map {
            (id: ScreenGeometry.displayID(of: $0), quartz: ScreenGeometry.quartzRect(fromCocoa: $0.frame))
        }
        let did = GestureMath.spaceMapDisplayID(
            cursor: cursor, screens: screens, fallback: ScreenGeometry.mainDisplayID
        )
        engine.spaceMap = SpaceMap.load(cameraID: id, displayID: did)
            ?? SpaceMap.load(cameraID: id, displayID: ScreenGeometry.mainDisplayID)
            ?? SpaceMap.load(displayID: did)
            ?? SpaceMap.load(displayID: ScreenGeometry.mainDisplayID)
        if let map = engine.spaceMap, map.displayID != 0 {
            let live = GestureMath.spaceMapRotation(displayID: map.displayID)
            if GestureMath.spaceMapNeedsRecalib(stored: map.rotation, live: live) {
                engine.spaceMap = nil
                log.record("Display gedreht — Homographie tot, neu kalibrieren", kind: .info)
            }
        }
        mapReady = engine.spaceMap?.isReady == true
        coverMapReady = coverCalibrated(camera.coverID)
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

    private var drillSavedTest: Bool?

    func startDrill() {
        drillSavedTest = testMode
        setTestMode(true)
        engine.forceArm()
        overlayVisible()
        drill.start()
        log.record("Aktionskalibrierung — 12 Gesten × 3, Timer, kein Systemeingriff.", kind: .info)
    }

    func cancelDrill() {
        drill.cancel()
        if let saved = drillSavedTest {
            setTestMode(saved)
            drillSavedTest = nil
        }
        log.record("Aktionskalibrierung abgebrochen", kind: .info)
    }

    func copyDrillForGrok() {
        drill.copyForGrok()
        log.record("Aktionskalibrierung in die Zwischenablage — in Grok einfügen.", kind: .info)
    }

    func exportDrill() {
        drill.exportFiles()
        log.record("Aktionskalibrierung exportiert", kind: .info)
    }

    fileprivate func apply(
        hands: [TrackedHand],
        latency: Double,
        now: TimeInterval,
        preview: NSImage?,
        luma: CGFloat
    ) {
        let camID = camera.selectedID
        let camName = camera.deviceName
        let camRole = cameraDevices.first { $0.id == camID }?.role.rawValue ?? lastAppliedCameraRole
        if GestureMath.cameraIDHomographyResets(
            prev: lastAppliedCameraID,
            next: camID,
            prevName: lastAppliedCameraName,
            nextName: camName,
            prevRole: lastAppliedCameraRole,
            nextRole: camRole
        ) {
            engine.recenterPointer()
            engine.spaceMap = SpaceMap.load(cameraID: camID, displayID: ScreenGeometry.mainDisplayID)
                ?? SpaceMap.load(displayID: ScreenGeometry.mainDisplayID)
            mapReady = engine.spaceMap?.isReady == true
            log.record("Kamerawechsel — Zeiger neu, Homographie geladen.", kind: .info)
        } else if lastAppliedCameraID != camID, !lastAppliedCameraID.isEmpty, !camID.isEmpty {
            SpaceMap.retarget(
                from: lastAppliedCameraID,
                to: camID,
                displayID: ScreenGeometry.mainDisplayID
            )
            engine.spaceMap = SpaceMap.load(cameraID: camID, displayID: ScreenGeometry.mainDisplayID)
                ?? engine.spaceMap
            mapReady = engine.spaceMap?.isReady == true
        }
        lastAppliedCameraID = camID
        lastAppliedCameraName = camName
        lastAppliedCameraRole = camRole
        engine.tick(hands: hands, now: now)
        if drill.running || drill.phase == .countdown || drill.phase == .capture || drill.phase == .rest {
            drill.tick(hands: hands, now: now)
        }
        if drill.phase == .done, let saved = drillSavedTest {
            setTestMode(saved)
            drillSavedTest = nil
        }
        if let done = calibSession.consumeFinished() {
            invalidateMaps()
            let name = cameraDevices.first(where: { $0.id == done })?.name ?? (done.isEmpty ? deviceName : done)
            log.record("Kalibrierung \(name) — Homographie nimmt Blickwinkel, Weitwinkel und Spiegelung auf.", kind: .info)
            if cameraPair != .single, !camera.coverID.isEmpty, done == camera.selectedID,
               SpaceMap.load(cameraID: camera.coverID, displayID: ScreenGeometry.mainDisplayID)?.isReady != true
            {
                calibSession.start(cameraID: camera.coverID, label: camera.coverName)
                engine.calibration = calibSession
                log.record("Zweiter Winkel: \(camera.coverName). Dieselben 4 Bildschirmecken aus dieser Sicht.", kind: .info)
            }
        }
        if engine.clapWake {
            engine.clapWake = false
            hudVisible = true
            overlay.setVisible(true)
        }
        overlay.mark(
            cursors: engine.handCursors,
            phase: engine.grabPhase,
            target: engine.grabTargetName,
            window: focused?.quartzBounds,
            showReticle: showReticle,
            freeze: engine.freezeLive
        )
        frames += 1
        let wall = CACurrentMediaTime()
        if wall - fpsStamp >= 0.5 {
            fps = Double(frames) / (wall - fpsStamp)
            frames = 0
            fpsStamp = wall
            fpsSpark.append((wall, fps))
            fpsSpark.removeAll { wall - $0.t > GestureMath.fpsSparkSec }
            fpsAmber = GestureMath.fpsAmber(fps) || GestureMath.fpsSparkAmber(fpsSpark, now: wall)
            fpsSparkBars = GestureMath.fpsSparkBars(fpsSpark, now: wall)
            camera.renegotiateIfSlow(measuredFps: fps)
        }
        if protocolMode {
            recorder.push(
                hands: hands,
                preview: preview ?? self.preview,
                luma: luma,
                mode: engine.mode,
                action: engine.lastAction,
                now: now
            )
        }
        if engine.chromeKnobs != chromeKnobs || engine.chromeHot != chromeHot || engine.chromeDwell != chromeDwell {
            chromeKnobs = engine.chromeKnobs
            chromeHot = engine.chromeHot
            chromeDwell = engine.chromeDwell
        }
        if engine.keyboardVisible != keyboardVisible
            || engine.keyboardHover != keyboardHover
            || engine.keyboardDwell != keyboardDwell
            || engine.keyboardHits != keyboardHits
        {
            keyboardVisible = engine.keyboardVisible
            keyboardHits = engine.keyboardHits
            keyboardHover = engine.keyboardHover
            keyboardDwell = engine.keyboardDwell
        }
        if hideConsoleWhenArmed, engine.mode == .armed, !testMode {
            if lastArmedConsole != .armed {
                ConsolePolicy.hide()
            } else {
                ConsolePolicy.enforce()
            }
        }
        lastArmedConsole = engine.mode
        let stickyGrab = engine.grabPhase == .grab || engine.grabPhase == .hold
        if stickyGrab || now - lastPanel >= 0.09 {
            pollFocus()
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
        calibCorner = calibSession.corner.titleDE
        calibHold = calibSession.progress
        calibCursorGap = calibSession.cursorGap
        mapReady = engine.spaceMap?.isReady == true
        mousePaused = engine.mousePaused
        grabPhase = engine.grabPhase
        grabTargetName = engine.grabTargetName
        peaceProgress = engine.peaceProgress
        lockFreeze = engine.lockFreeze
        qualityChip = engine.qualityChip
        if engine.freezeLive, hands.isEmpty, !self.hands.isEmpty {
            self.hands = self.hands.map { h in
                let d = engine.freezeGhostDeltas[h.id] ?? engine.freezeGhostDelta
                return (d.x != 0 || d.y != 0) ? h.shifted(by: d) : h
            }
        } else {
            self.hands = hands
        }
        fusion = hands.first?.fusion ?? tracker.lastFusion
        hasDepth = camera.hasDepth
        cameraDevices = camera.devices
        selectedCameraID = camera.selectedID
        coverName = camera.coverName
        coverRunning = camera.coverRunning
        coverError = camera.coverError
        coverID = camera.coverID
        cameraPair = camera.pair
        coverMapReady = coverCalibrated(camera.coverID)
        actorSource = usingCover ? "cover" : "lead"
    }

    private func drainApply() {
        guard let item = applySlot.take() else { return }
        GestureClassifier.space = tracker.lastSpace
        let fused = fuseHands(lead: item.hands)
        apply(hands: fused, latency: item.latency, now: item.now, preview: preview, luma: item.luma)
    }

    private func cachedMap(cameraID: String, displayID: CGDirectDisplayID = 0, fallback: Bool = false) -> SpaceMap? {
        let disp = displayID == 0 ? ScreenGeometry.mainDisplayID : displayID
        let key = "\(cameraID)#\(disp)#\(fallback ? "f" : "x")"
        if let m = mapMemo[key] { return m }
        if let m = SpaceMap.load(cameraID: cameraID, displayID: disp) {
            mapMemo[key] = m
            return m
        }
        if fallback, !cameraID.isEmpty, let m = SpaceMap.load(displayID: disp) {
            mapMemo[key] = m
            return m
        }
        return nil
    }

    private func coverCalibrated(_ id: String) -> Bool {
        !id.isEmpty && SpaceMap.load(cameraID: id, displayID: ScreenGeometry.mainDisplayID)?.isReady == true
    }

    private func invalidateMaps() {
        mapMemo.removeAll()
    }

    private func fuseHands(lead: [TrackedHand]) -> [TrackedHand] {
        let cover = coverSlot.take()
        coverHands = cover
        let leadID = camera.selectedID
        let coverID = camera.coverID
        let disp = ScreenGeometry.mainDisplayID
        let leadMap = cachedMap(cameraID: leadID, displayID: disp, fallback: true)
        let coverMap = coverID.isEmpty ? nil : cachedMap(cameraID: coverID, displayID: disp)

        if calibSession.active {
            if !calibSession.cameraID.isEmpty, calibSession.cameraID == coverID {
                engine.spaceMap = coverMap
                usingCover = false
                return coverForCalib(cover, lead: lead)
            }
            engine.spaceMap = leadMap
            usingCover = false
            return lead
        }

        usingCover = false
        engine.spaceMap = leadMap
        if lead.isEmpty || cover.isEmpty { return lead }
        return refineLeadWithCover(lead: lead, cover: cover, leadMap: leadMap, coverMap: coverMap)
    }

    /// Cover-Kalibrierung: Palme aus Osmo, Pinzette nur wenn die Lead-Kamera mitmacht.
    private func coverForCalib(_ cover: [TrackedHand], lead: [TrackedHand]) -> [TrackedHand] {
        guard !lead.isEmpty else { return [] }
        let leadPinch = lead.contains { $0.pinchClosed || $0.pinchClosedness > 0.52 || $0.pose == .pinch }
        guard leadPinch else {
            return cover.map {
                var h = $0
                h.pinchClosed = false
                h.pinchClosedness = min(h.pinchClosedness, 0.30)
                return h
            }
        }
        return cover
    }

    private func refineLeadWithCover(
        lead: [TrackedHand],
        cover: [TrackedHand],
        leadMap: SpaceMap?,
        coverMap: SpaceMap?
    ) -> [TrackedHand] {
        var out = lead
        let canMap = leadMap?.isReady == true && coverMap?.isReady == true
        for i in out.indices {
            guard let c = matchCover(out[i], cover, leadMap: leadMap, coverMap: coverMap) else { continue }
            let pinch = CameraRig.pinchAssist(lead: out[i].pinchClosedness, cover: c.pinchClosedness)
            out[i].pinchClosedness = pinch
            out[i].quality = min(1, out[i].quality + 0.10 * c.quality)
            if canMap, let lm = leadMap, let cm = coverMap {
                let a = lm.apply(out[i].palm)
                let b = cm.apply(c.palm)
                if let blended = CameraRig.blendScreen(a, b), let back = lm.invert(blended) {
                    out[i].palm = CGPoint(
                        x: min(max(back.x, 0), 1),
                        y: min(max(back.y, 0), 1)
                    )
                }
            }
        }
        return out
    }

    private func matchCover(
        _ lead: TrackedHand,
        _ cover: [TrackedHand],
        leadMap: SpaceMap?,
        coverMap: SpaceMap?
    ) -> TrackedHand? {
        if lead.chirality != .unknown {
            let same = cover.filter { $0.chirality == lead.chirality }
            if same.count == 1 { return same[0] }
            if same.count > 1, let lm = leadMap, lm.isReady, let cm = coverMap, cm.isReady {
                let lp = lm.apply(lead.palm)
                return same.min {
                    let da = hypot(cm.apply($0.palm).x - lp.x, cm.apply($0.palm).y - lp.y)
                    let db = hypot(cm.apply($1.palm).x - lp.x, cm.apply($1.palm).y - lp.y)
                    return da < db
                }
            }
            return same.first
        }
        if cover.count == 1, lead.chirality == .unknown { return cover[0] }
        return nil
    }
}

/// Cover-Vision schreibt hier, Lead-Tick liest — analog ApplySlot.
private final class CoverSlot: @unchecked Sendable {
    private let lock = NSLock()
    private var hands: [TrackedHand] = []

    func push(_ h: [TrackedHand]) {
        lock.lock()
        hands = h
        lock.unlock()
    }

    func take() -> [TrackedHand] {
        lock.lock()
        let h = hands
        lock.unlock()
        return h
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
        get {
            if !UserDefaults.standard.bool(forKey: "helios.outline.offByDefault") {
                UserDefaults.standard.set(true, forKey: "helios.outline.offByDefault")
                UserDefaults.standard.set(false, forKey: "helios.outline")
                return false
            }
            return UserDefaults.standard.object(forKey: "helios.outline") as? Bool ?? false
        }
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
        get {
            if UserDefaults.standard.object(forKey: "helios.hideConsole.stay") != nil {
                return UserDefaults.standard.bool(forKey: "helios.hideConsole.stay")
            }
            return false
        }
        set { UserDefaults.standard.set(newValue, forKey: "helios.hideConsole.stay") }
    }
    static var fusionTemperature: Double {
        get {
            let v = UserDefaults.standard.double(forKey: "helios.fusionTemp")
            return v == 0 ? 0.75 : min(1.4, max(0.35, v))
        }
        set { UserDefaults.standard.set(newValue, forKey: "helios.fusionTemp") }
    }
}

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
    @Published var displayHands: [TrackedHand] = []
    @Published var mode: EngineMode = .idle
    @Published var lastAction = "—"
    @Published var fps: Double = 0
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

    private var cancellables: Set<AnyCancellable> = []
    private var focusTick = 0

    func start() {
        overlay.attach(state: self)
        engine.onLog = { [weak self] text, kind, conf in
            self?.log.record(text, kind: kind, confidence: conf)
            self?.objectWillChange.send()
        }
        engine.testMode = false
        engine.protocolMode = true
        engine.leftHanded = true
        engine.pointerGain = 1.6
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
        log.record("Helios bereit. Linkshänder. Aktionen gehen an das System.")
        engine.testMode = false
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
        fromDiskImage = AppInstall.isFromDiskImage || !AppInstall.isInApplications
        installPath = AppInstall.locationHint
        screenCount = NSScreen.screens.count
    }

    func pollFocus() {
        focused = FocusTracker.poll()
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
        camera.onFrame = { [weak self] vision, preview, luma, arrived in
            let t0 = CACurrentMediaTime()
            let hands = tracker.analyze(pixelBuffer: vision, now: t0, mirrored: true)
            let visMs = (CACurrentMediaTime() - t0) * 1000
            let endToEnd = (CACurrentMediaTime() - arrived) * 1000
            DispatchQueue.main.async {
                self?.apply(
                    hands: hands,
                    latency: max(visMs, endToEnd),
                    now: CACurrentMediaTime(),
                    preview: preview,
                    luma: luma
                )
            }
        }
        camera.start()
        log.record("Kamera gestartet.")
    }

    func stopCamera() {
        camera.onFrame = nil
        camera.stop()
        cameraRunning = false
        hands = []
        displayHands = []
        log.record("Kamera gestoppt.")
    }

    func setTestMode(_ on: Bool) {
        testMode = on
        engine.testMode = on
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
        log.record(on ? "Protokoll an" : "Protokoll aus", kind: .info)
    }

    func setLeftHanded(_ on: Bool) {
        leftHanded = on
        engine.leftHanded = on
        log.record(on ? "Linkshänder" : "Rechtshänder", kind: .info)
    }

    func setPointerGain(_ g: Double) {
        pointerGain = g
        engine.pointerGain = CGFloat(g)
        engine.recenterPointer()
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
        self.hands = hands
        self.displayHands = hands
        self.luma = luma
        latencyMs = latency
        frames += 1
        if now - fpsStamp >= 0.5 {
            fps = Double(frames) / (now - fpsStamp)
            frames = 0
            fpsStamp = now
        }
        if let preview {
            self.preview = preview
        }
        engine.tick(hands: hands, now: now)
        mode = engine.mode
        lastAction = engine.lastAction
        engineCursor = engine.cursor
        cursorHand = engine.cursorHand
        trashHot = engine.trashHot
        killFlash = engine.killFlash
        recorder.push(
            hands: hands,
            preview: preview,
            luma: luma,
            mode: engine.mode,
            action: engine.lastAction,
            now: now
        )
    }
}

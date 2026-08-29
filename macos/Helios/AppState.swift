import AppKit
import Combine
import CoreMedia
import Foundation
import QuartzCore
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    let camera = CameraSession()
    let engine = GestureEngine()
    let log = AuditLog()
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

    private var cancellables: Set<AnyCancellable> = []

    func start() {
        overlay.attach(state: self)
        engine.onLog = { [weak self] text in
            self?.log.record(text)
        }
        camera.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.preview = self.camera.preview
                self.deviceName = self.camera.deviceName
                self.cameraRunning = self.camera.isRunning
                self.cameraError = self.camera.errorMessage
            }
            .store(in: &cancellables)

        $hudVisible
            .sink { [weak self] v in self?.overlay.setVisible(v) }
            .store(in: &cancellables)

        refreshPermissions()
        permTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshPermissions() }
        }
        log.record("Helios bereit.")
        Task { await startCamera() }
    }

    func refreshPermissions() {
        cameraOK = Permissions.cameraGranted()
        accessOK = Permissions.accessibilityGranted()
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
        let tracker = self.tracker
        camera.onBuffer = { [weak self] buffer in
            let t0 = CACurrentMediaTime()
            guard let hands = tracker.analyze(sampleBuffer: buffer) else { return }
            let dt = (CACurrentMediaTime() - t0) * 1000
            Task { @MainActor in
                self?.apply(hands: hands, latency: dt, now: CACurrentMediaTime())
            }
        }
        camera.start()
        log.record("Kamera gestartet.")
    }

    func stopCamera() {
        camera.onBuffer = nil
        camera.stop()
        cameraRunning = false
        hands = []
        log.record("Kamera gestoppt.")
    }

    fileprivate func apply(hands: [TrackedHand], latency: Double, now: TimeInterval) {
        self.hands = hands
        latencyMs = latency
        frames += 1
        if now - fpsStamp >= 0.5 {
            fps = Double(frames) / (now - fpsStamp)
            frames = 0
            fpsStamp = now
        }
        engine.tick(hands: hands, now: now)
        mode = engine.mode
        lastAction = engine.lastAction
        engineCursor = engine.cursor
        objectWillChange.send()
    }
}

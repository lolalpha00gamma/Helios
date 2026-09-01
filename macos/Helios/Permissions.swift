import ApplicationServices
import AVFoundation
import AppKit
import CoreGraphics

enum PermissionKind: String, CaseIterable, Identifiable {
    case camera
    case accessibility
    case inputMonitoring

    var id: String { rawValue }

    var title: String {
        switch self {
        case .camera: return "Kamera"
        case .accessibility: return "Bedienungshilfen"
        case .inputMonitoring: return "Eingabeüberwachung"
        }
    }

    var hint: String {
        switch self {
        case .camera:
            return "Livestream der Hände."
        case .accessibility:
            return "Fenster verschieben, zoomen, schließen."
        case .inputMonitoring:
            return "Cursor und Klicks setzen."
        }
    }
}

enum PermissionNeed {
    case none
    case ax
    case input
    case capture
}

enum Permissions {
    private final class Gate: @unchecked Sendable {
        var lastDemand: TimeInterval = 0
    }
    private static let gate = Gate()

    static func cameraGranted() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    static func accessibilityGranted() -> Bool {
        AXIsProcessTrusted()
    }

    static func inputMonitoringGranted() -> Bool {
        CGPreflightPostEventAccess() || CGPreflightListenEventAccess()
    }

    static func requestInputMonitoring() {
        _ = CGRequestPostEventAccess()
        _ = CGRequestListenEventAccess()
    }

    static func promptAccessibility() {
        let opts = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }

    static func requestScreenCapture() {
        _ = CGRequestScreenCaptureAccess()
    }

    @MainActor
    static func bootstrap() async {
        _ = await requestCamera()
        AppInstall.settleIfNeeded()
        if !accessibilityGranted() {
            promptAccessibility()
        }
        if !inputMonitoringGranted() {
            requestInputMonitoring()
        }
        requestScreenCapture()
    }

    /// Systemdialog + Einstellungen. Nicht öfter als alle 6 s.
    @MainActor
    static func demand(_ kind: PermissionKind) {
        let now = CACurrentMediaTime()
        if now - gate.lastDemand < 6 { return }
        gate.lastDemand = now
        switch kind {
        case .camera:
            Task { _ = await requestCamera() }
        case .accessibility:
            promptAccessibility()
        case .inputMonitoring:
            requestInputMonitoring()
        }
        showAlert(missing: [kind])
    }

    @MainActor
    private static func showAlert(missing: [PermissionKind]) {
        let names = missing.map(\.title).joined(separator: ", ")
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Helios braucht Rechte"
        alert.informativeText = """
        macOS blockiert die Steuerung ohne diese Freigaben: \(names).

        1. Auf „Erlauben“ tippen — der Systemdialog erscheint.
        2. Helios in der Liste einschalten.
        3. Die App danach neu starten (bei Bedienungshilfen nötig).

        Die App muss in Programme liegen, nicht nur im geöffneten DMG.
        """
        alert.addButton(withTitle: "Systemeinstellungen öffnen")
        alert.addButton(withTitle: "Später")
        NSApp.activate()
        let result = alert.runModal()
        if result == .alertFirstButtonReturn {
            for k in missing {
                openPrivacyPane(k)
            }
        }
    }

    static func openPrivacyPane(_ kind: PermissionKind) {
        let urls: [String] = {
            switch kind {
            case .camera:
                return [
                    "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Camera",
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
                ]
            case .accessibility:
                promptAccessibility()
                return [
                    "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
                ]
            case .inputMonitoring:
                requestInputMonitoring()
                return [
                    "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ListenEvent",
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
                ]
            }
        }()
        for s in urls {
            if let url = URL(string: s), NSWorkspace.shared.open(url) { break }
        }
    }

    static func requestCamera() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            await MainActor.run { openPrivacyPane(.camera) }
            return false
        }
    }
}

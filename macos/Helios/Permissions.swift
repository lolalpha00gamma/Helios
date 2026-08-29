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
            return "Fenster verschieben, zoomen, App wechseln."
        case .inputMonitoring:
            return "Cursor und Klicks setzen."
        }
    }
}

enum Permissions {
    static func cameraGranted() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    static func accessibilityGranted() -> Bool {
        AXIsProcessTrusted()
    }

    static func promptAccessibility() {
        let opts = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }

    static func openPrivacyPane(_ kind: PermissionKind) {
        let url: URL? = {
            switch kind {
            case .camera:
                return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")
            case .accessibility:
                return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
            case .inputMonitoring:
                return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
            }
        }()
        if let url {
            NSWorkspace.shared.open(url)
        }
    }

    static func requestCamera() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }
}

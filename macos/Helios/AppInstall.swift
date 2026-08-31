import AppKit
import Foundation
import QuartzCore

enum AppInstall {
    private final class Gate: @unchecked Sendable {
        var lastOffer: TimeInterval = 0
    }
    private static let gate = Gate()

    static var bundlePath: String { Bundle.main.bundlePath }

    static var isInApplications: Bool {
        bundlePath.hasPrefix("/Applications/")
    }

    static var isFromDiskImage: Bool {
        bundlePath.contains("AppTranslocation")
            || bundlePath.hasPrefix("/Volumes/")
            || bundlePath.contains("/.Trash/")
    }

    static var locationHint: String {
        if isInApplications { return "Programme" }
        if isFromDiskImage { return "DMG — Rechte greifen hier nicht" }
        return bundlePath
    }

    @MainActor
    static func installAndRelaunch() {
        let now = CACurrentMediaTime()
        if now - gate.lastOffer < 20 { return }
        gate.lastOffer = now
        let dest = URL(fileURLWithPath: "/Applications/Helios.app")
        let src = Bundle.main.bundleURL
        let alert = NSAlert()
        alert.messageText = "Nach Programme kopieren"
        alert.informativeText = """
        macOS bindet Bedienungshilfen an den Dateipfad. Läuft Helios aus dem DMG, bleiben die Schalter in den Systemeinstellungen wirkungslos.

        Helios wird nach /Applications kopiert und neu gestartet. Danach Bedienungshilfen und Eingabeüberwachung einmal aus- und wieder einschalten.
        """
        alert.addButton(withTitle: "Kopieren und neu starten")
        alert.addButton(withTitle: "Abbrechen")
        NSApp.activate()
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        do {
            let fm = FileManager.default
            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
            }
            try fm.copyItem(at: src, to: dest)
            let cfg = NSWorkspace.OpenConfiguration()
            cfg.activates = true
            NSWorkspace.shared.openApplication(at: dest, configuration: cfg) { _, err in
                DispatchQueue.main.async {
                    if let err {
                        let a = NSAlert(error: err)
                        a.runModal()
                    }
                    NSApp.terminate(nil)
                }
            }
        } catch {
            let a = NSAlert(error: error)
            a.messageText = "Kopieren fehlgeschlagen — App manuell nach Programme ziehen."
            a.runModal()
        }
    }
}

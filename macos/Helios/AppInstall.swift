import AppKit
import Darwin
import Foundation
import QuartzCore

enum AppInstall {
    private final class Gate: @unchecked Sendable {
        var lastOffer: TimeInterval = 0
    }
    private static let gate = Gate()

    static var bundleURL: URL {
        Bundle.main.bundleURL.resolvingSymlinksInPath()
    }

    static var bundlePath: String { bundleURL.path }

    static var installedURL: URL {
        URL(fileURLWithPath: "/Applications/Helios.app")
    }

    static var installedExists: Bool {
        FileManager.default.fileExists(atPath: installedURL.path)
    }

    /// Läuft wirklich aus /Applications oder ~/Applications, nicht transloziert.
    static var isInstalledCopy: Bool {
        let p = bundlePath
        if p.contains("AppTranslocation") { return false }
        if p.hasPrefix("/Volumes/") || p.contains("/.Trash/") { return false }
        return p.hasPrefix("/Applications/") || p.contains("/Applications/Helios.app")
    }

    static var isTranslocated: Bool {
        bundlePath.contains("AppTranslocation")
    }

    static var isFromDiskImage: Bool {
        bundlePath.hasPrefix("/Volumes/") || bundlePath.contains("/.Trash/")
    }

    /// Dialog/Kopieren nur, wenn es noch keine echte Kopie in Programme gibt.
    static var needsCopy: Bool {
        if isInstalledCopy { return false }
        if isTranslocated && installedExists { return false }
        return isFromDiskImage || !isInstalledCopy
    }

    /// Quarantäne-Kopie, Original liegt schon in Programme.
    static var shouldOpenInstalled: Bool {
        !isInstalledCopy && installedExists && (isTranslocated || isFromDiskImage)
    }

    static var locationHint: String {
        if isInstalledCopy { return "Programme (\(bundlePath))" }
        if isTranslocated && installedExists {
            return "Quarantäne-Kopie — Original in Programme"
        }
        if isFromDiskImage { return "DMG — Rechte greifen hier nicht" }
        return bundlePath
    }

    @MainActor
    static func installAndRelaunch() {
        let now = CACurrentMediaTime()
        if now - gate.lastOffer < 8 { return }
        gate.lastOffer = now

        if isInstalledCopy {
            return
        }

        if shouldOpenInstalled {
            openInstalled(reason: """
            Helios liegt schon in Programme. macOS hat eine Quarantäne-Kopie gestartet — die Rechte gelten nur für die Datei in Programme.

            Ich öffne /Applications/Helios.app und beende diese Kopie.
            """)
            return
        }

        let alert = NSAlert()
        alert.messageText = "Nach Programme kopieren"
        alert.informativeText = """
        Diese Sitzung läuft nicht aus Programme (\(bundlePath)).

        Helios wird nach /Applications kopiert. Danach Bedienungshilfen und Eingabeüberwachung einmal aus- und wieder einschalten.
        """
        alert.addButton(withTitle: "Kopieren und öffnen")
        alert.addButton(withTitle: "Abbrechen")
        NSApp.activate()
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        do {
            try copyToApplications()
            openInstalled(reason: nil)
        } catch {
            let a = NSAlert()
            a.alertStyle = .warning
            a.messageText = "Kopieren nicht möglich"
            a.informativeText = """
            \(error.localizedDescription)

            Wenn Helios schon unter Programme liegt: diese Meldung ignorieren und /Applications/Helios.app per Doppelklick starten (nicht die Datei aus dem DMG).

            Sonst Helios.app selbst nach Programme ziehen.
            """
            a.addButton(withTitle: "Programme öffnen")
            a.addButton(withTitle: "OK")
            NSApp.activate()
            if a.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications"))
            }
        }
    }

    @MainActor
    private static func openInstalled(reason: String?) {
        if let reason {
            let a = NSAlert()
            a.messageText = "Installierte Kopie öffnen"
            a.informativeText = reason
            a.addButton(withTitle: "Öffnen")
            NSApp.activate()
            _ = a.runModal()
        }
        stripQuarantine(installedURL)
        let cfg = NSWorkspace.OpenConfiguration()
        cfg.activates = true
        NSWorkspace.shared.openApplication(at: installedURL, configuration: cfg) { _, err in
            DispatchQueue.main.async {
                if err != nil {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications"))
                }
                NSApp.terminate(nil)
            }
        }
    }

    private static func copyToApplications() throws {
        let fm = FileManager.default
        let dest = installedURL
        let src = bundleURL
        let staging = fm.temporaryDirectory.appendingPathComponent("Helios-\(UUID().uuidString).app")
        try fm.copyItem(at: src, to: staging)
        stripQuarantine(staging)
        if fm.fileExists(atPath: dest.path) {
            try fm.trashItem(at: dest, resultingItemURL: nil)
        }
        try fm.moveItem(at: staging, to: dest)
        stripQuarantine(dest)
    }

    private static func stripQuarantine(_ url: URL) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        proc.arguments = ["-dr", "com.apple.quarantine", url.path]
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        do {
            try proc.run()
            proc.waitUntilExit()
        } catch {}
        url.withUnsafeFileSystemRepresentation { path in
            guard let path else { return }
            _ = removexattr(path, "com.apple.quarantine", 0)
        }
    }
}

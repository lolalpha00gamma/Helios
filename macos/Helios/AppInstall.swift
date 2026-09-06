import AppKit
import Darwin
import Foundation

enum AppInstall {
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

    static var originalURL: URL {
        translocatedOriginal(of: Bundle.main.bundleURL) ?? bundleURL
    }

    static var isTranslocated: Bool {
        secIsTranslocated(Bundle.main.bundleURL) || bundlePath.contains("AppTranslocation")
    }

    static var isFromDiskImage: Bool {
        let p = originalURL.path
        return p.hasPrefix("/Volumes/") || p.contains("/.Trash/")
    }

    static var isInstalledCopy: Bool {
        if isTranslocated { return false }
        let p = bundlePath
        if p.hasPrefix("/Volumes/") || p.contains("/.Trash/") { return false }
        return p.hasPrefix("/Applications/") || p.contains("/Applications/Helios.app")
    }

    static var originalIsInApplications: Bool {
        let p = originalURL.path
        return p.hasPrefix("/Applications/") || p.contains("/Applications/Helios.app")
    }

    /// Nur echtes DMG/Papierkorb — nicht Quarantäne einer schon installierten App.
    static var needsCopy: Bool {
        isFromDiskImage && !originalIsInApplications
    }

    static var shouldOpenInstalled: Bool { false }

    static var locationHint: String {
        if isTranslocated {
            return "Quarantäne → \(originalURL.path)"
        }
        if isFromDiskImage { return "DMG \(originalURL.path)" }
        if isInstalledCopy { return "Programme" }
        return bundlePath
    }

    /// Kein Dialog. Quarantäne runter, bei Translokation einmal die Originaldatei öffnen.
    @MainActor
    static func settleIfNeeded() {
        stripQuarantine(bundleURL)
        stripQuarantine(originalURL)
        if installedExists { stripQuarantine(installedURL) }

        if !isTranslocated {
            UserDefaults.standard.set(false, forKey: "helios.didRelaunchUnquarantine")
            return
        }
        guard originalIsInApplications || installedExists else { return }
        let dest = originalIsInApplications ? originalURL : installedURL
        let key = "helios.didRelaunchUnquarantine"
        if UserDefaults.standard.bool(forKey: key) { return }
        UserDefaults.standard.set(true, forKey: key)
        let cfg = NSWorkspace.OpenConfiguration()
        cfg.activates = true
        NSWorkspace.shared.openApplication(at: dest, configuration: cfg) { app, err in
            DispatchQueue.main.async {
                if app != nil, err == nil {
                    NSApp.terminate(nil)
                } else {
                    UserDefaults.standard.set(false, forKey: key)
                }
            }
        }
    }

    @MainActor
    static func installAndRelaunch() {
        if !needsCopy {
            settleIfNeeded()
            return
        }
        let alert = NSAlert()
        alert.messageText = "Nach Programme kopieren"
        alert.informativeText = "Diese Sitzung läuft aus \(originalURL.path). Helios wird nach /Applications kopiert."
        alert.addButton(withTitle: "Kopieren und öffnen")
        alert.addButton(withTitle: "Abbrechen")
        NSApp.activate()
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        do {
            try copyToApplications()
            UserDefaults.standard.set(false, forKey: "helios.didRelaunchUnquarantine")
            let cfg = NSWorkspace.OpenConfiguration()
            cfg.activates = true
            NSWorkspace.shared.openApplication(at: installedURL, configuration: cfg) { app, err in
                DispatchQueue.main.async {
                    if app != nil, err == nil {
                        NSApp.terminate(nil)
                    }
                }
            }
        } catch {
            let a = NSAlert()
            a.alertStyle = .warning
            a.messageText = "Kopieren nicht möglich"
            a.informativeText = """
            Helios nicht überschreiben, wenn es schon in Programme liegt.

            Im Terminal:
            xattr -dr com.apple.quarantine /Applications/Helios.app

            Danach nur Programme → Helios starten.
            """
            a.addButton(withTitle: "OK")
            NSApp.activate()
            a.runModal()
        }
    }

    private static func copyToApplications() throws {
        let fm = FileManager.default
        let dest = installedURL
        let staging = fm.temporaryDirectory.appendingPathComponent("Helios-\(UUID().uuidString).app")
        try fm.copyItem(at: originalURL, to: staging)
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
        proc.arguments = ["-cr", url.path]
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

    private static func secHandle() -> UnsafeMutableRawPointer? {
        dlopen("/System/Library/Frameworks/Security.framework/Security", RTLD_NOW)
    }

    private static func secIsTranslocated(_ url: URL) -> Bool {
        guard let handle = secHandle(),
              let raw = dlsym(handle, "SecTranslocateIsTranslocatedURL")
        else { return url.path.contains("AppTranslocation") }
        typealias Fn = @convention(c) (
            CFURL,
            UnsafeMutablePointer<Bool>?,
            UnsafeMutablePointer<Unmanaged<CFError>?>?
        ) -> DarwinBoolean
        let fn = unsafeBitCast(raw, to: Fn.self)
        var flag = false
        _ = fn(url as CFURL, &flag, nil)
        return flag
    }

    private static func translocatedOriginal(of url: URL) -> URL? {
        guard let handle = secHandle(),
              let raw = dlsym(handle, "SecTranslocateCreateOriginalPathForURL")
        else { return nil }
        typealias Fn = @convention(c) (CFURL, UnsafeMutablePointer<Unmanaged<CFError>?>?) -> Unmanaged<CFURL>?
        let fn = unsafeBitCast(raw, to: Fn.self)
        var err: Unmanaged<CFError>?
        guard let result = fn(url as CFURL, &err) else { return nil }
        return result.takeRetainedValue() as URL
    }
}

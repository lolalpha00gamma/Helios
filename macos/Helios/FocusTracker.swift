import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

struct FocusedTarget: Equatable {
    var appName: String
    var bundleId: String
    var pid: pid_t
    var title: String
    var quartzBounds: CGRect
    var windowID: CGWindowID
    var isFinder: Bool
}

enum TargetProbe {
    static var selfPID: pid_t { ProcessInfo.processInfo.processIdentifier }

    /// Maus in CGWindowList-Koordinaten (Ursprung oben links am Hauptbildschirm).
    static func cursorInWindowList() -> CGPoint {
        let cocoa = NSEvent.mouseLocation
        let originH = NSScreen.screens.first {
            abs($0.frame.minX) < 0.5 && abs($0.frame.minY) < 0.5
        }?.frame.maxY ?? NSScreen.main?.frame.maxY ?? 0
        return CGPoint(x: cocoa.x, y: originH - cocoa.y)
    }

    static func windowUnderCursor(skipSelf: Bool = true) -> FocusedTarget? {
        let p = cursorInWindowList()
        guard let list = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else { return nil }

        for item in list {
            let pid = (item[kCGWindowOwnerPID as String] as? pid_t) ?? 0
            if skipSelf, pid == selfPID { continue }
            if pid == 0 { continue }
            let layer = item[kCGWindowLayer as String] as? Int ?? 0
            guard layer == 0 else { continue }
            guard let dict = item[kCGWindowBounds as String] as? [String: CGFloat] else { continue }
            let r = CGRect(
                x: dict["X"] ?? 0,
                y: dict["Y"] ?? 0,
                width: dict["Width"] ?? 0,
                height: dict["Height"] ?? 0
            )
            guard r.width > 80, r.height > 40 else { continue }
            guard r.insetBy(dx: -4, dy: -4).contains(p) else { continue }
            return makeTarget(pid: pid, item: item, bounds: r)
        }
        return nil
    }

    private static func makeTarget(pid: pid_t, item: [String: Any], bounds: CGRect) -> FocusedTarget {
        let app = NSRunningApplication(processIdentifier: pid)
        let id = CGWindowID((item[kCGWindowNumber as String] as? NSNumber)?.uint32Value ?? 0)
        let title = item[kCGWindowName as String] as? String ?? ""
        return FocusedTarget(
            appName: app?.localizedName ?? (item[kCGWindowOwnerName as String] as? String) ?? "App",
            bundleId: app?.bundleIdentifier ?? "",
            pid: pid,
            title: title,
            quartzBounds: ScreenGeometry.fromWindowList(bounds),
            windowID: id,
            isFinder: app?.bundleIdentifier == "com.apple.finder"
        )
    }
}

enum FocusTracker {
    static func poll() -> FocusedTarget? {
        TargetProbe.windowUnderCursor(skipSelf: true)
    }
}

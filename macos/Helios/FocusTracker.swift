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
        ScreenGeometry.quartz(fromCocoa: NSEvent.mouseLocation)
    }

    static func frontmost(skipSelf: Bool = true) -> FocusedTarget? {
        guard let list = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else { return nil }
        for item in list {
            let pid = (item[kCGWindowOwnerPID as String] as? pid_t) ?? 0
            let layer = item[kCGWindowLayer as String] as? Int ?? 0
            guard GestureMath.cgWindowIsGrabTarget(pid: pid, layer: layer, skipSelf: skipSelf, selfPID: selfPID) else { continue }
            guard let r = GestureMath.windowListRect(item[kCGWindowBounds as String]) else { continue }
            guard r.width > 80, r.height > 40 else { continue }
            let app = NSRunningApplication(processIdentifier: pid)
            guard app?.activationPolicy == .regular else { continue }
            return makeTarget(pid: pid, item: item, bounds: r)
        }
        return nil
    }

    static func windowUnderCursor(skipSelf: Bool = true) -> FocusedTarget? {
        windowAt(quartz: cursorInWindowList(), skipSelf: skipSelf)
    }

    static func windowAt(quartz: CGPoint, skipSelf: Bool = true) -> FocusedTarget? {
        let p = quartz
        guard let list = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else { return nil }

        for item in list {
            let pid = (item[kCGWindowOwnerPID as String] as? pid_t) ?? 0
            let layer = item[kCGWindowLayer as String] as? Int ?? 0
            guard GestureMath.cgWindowIsGrabTarget(pid: pid, layer: layer, skipSelf: skipSelf, selfPID: selfPID) else { continue }
            guard let r = GestureMath.windowListRect(item[kCGWindowBounds as String]) else { continue }
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

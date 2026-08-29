import AppKit
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

enum FocusTracker {
    static func poll() -> FocusedTarget? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let pid = app.processIdentifier
        let win = largestWindow(pid: pid)
        return FocusedTarget(
            appName: app.localizedName ?? "App",
            bundleId: app.bundleIdentifier ?? "",
            pid: pid,
            title: win?.title ?? "",
            quartzBounds: win?.bounds ?? .zero,
            windowID: win?.id ?? 0,
            isFinder: app.bundleIdentifier == "com.apple.finder"
        )
    }

    private static func largestWindow(pid: pid_t) -> (id: CGWindowID, bounds: CGRect, title: String)? {
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        var best: (id: CGWindowID, bounds: CGRect, title: String)?
        var bestArea: CGFloat = 0
        for item in list {
            guard let owner = item[kCGWindowOwnerPID as String] as? pid_t, owner == pid else { continue }
            let layer = item[kCGWindowLayer as String] as? Int ?? 0
            guard layer == 0 else { continue }
            guard let dict = item[kCGWindowBounds as String] as? [String: CGFloat] else { continue }
            let r = CGRect(
                x: dict["X"] ?? 0,
                y: dict["Y"] ?? 0,
                width: dict["Width"] ?? 0,
                height: dict["Height"] ?? 0
            )
            let area = r.width * r.height
            guard area > bestArea, r.width > 80, r.height > 40 else { continue }
            bestArea = area
            let id = CGWindowID((item[kCGWindowNumber as String] as? NSNumber)?.uint32Value ?? 0)
            let title = item[kCGWindowName as String] as? String ?? ""
            best = (id, r, title)
        }
        return best
    }
}

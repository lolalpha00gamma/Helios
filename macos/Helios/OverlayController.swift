import AppKit
import SwiftUI

private struct HUDRoot: View {
    @ObservedObject var state: AppState
    var body: some View {
        HUDView()
            .environmentObject(state)
            .ignoresSafeArea()
    }
}

@MainActor
final class OverlayController {
    private var panel: NSPanel?
    private var hosting: NSHostingView<HUDRoot>?

    func attach(state: AppState) {
        guard panel == nil, let screen = NSScreen.main else { return }
        let view = NSHostingView(rootView: HUDRoot(state: state))
        view.frame = screen.frame
        let panel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.assistiveTechHighWindow)))
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.contentView = view
        panel.setFrame(screen.frame, display: true)
        panel.orderFrontRegardless()
        self.panel = panel
        self.hosting = view
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.syncFrame()
            }
        }
    }

    func syncFrame() {
        guard let screen = NSScreen.main else { return }
        panel?.setFrame(screen.frame, display: true)
        hosting?.frame = screen.frame
    }

    func setVisible(_ visible: Bool) {
        if visible {
            panel?.orderFrontRegardless()
        } else {
            panel?.orderOut(nil)
        }
    }
}

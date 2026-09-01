import AppKit
import SwiftUI

private struct HUDRoot: View {
    @ObservedObject var state: AppState
    var screenFrame: CGRect
    var isPrimary: Bool

    var body: some View {
        HUDView(screenFrame: screenFrame, isPrimary: isPrimary)
            .environmentObject(state)
            .ignoresSafeArea()
    }
}

@MainActor
final class OverlayController {
    private var panels: [CGDirectDisplayID: NSPanel] = [:]
    private var hostings: [CGDirectDisplayID: NSHostingView<HUDRoot>] = [:]
    private var markers: [CGDirectDisplayID: HandMarkerView] = [:]
    private weak var state: AppState?
    private var screenObs: NSObjectProtocol?
    private var attached = false

    func attach(state: AppState) {
        self.state = state
        rebuild()
        guard !attached else { return }
        attached = true
        screenObs = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.rebuild()
            }
        }
    }

    func rebuild() {
        guard let state else { return }
        let screens = NSScreen.screens
        let live = Set(screens.map { ScreenGeometry.displayID(of: $0) })
        for (id, panel) in panels where !live.contains(id) {
            panel.orderOut(nil)
            panel.close()
            panels[id] = nil
            hostings[id] = nil
            markers[id] = nil
        }
        let mainID = NSScreen.main.map { ScreenGeometry.displayID(of: $0) }
        for screen in screens {
            let id = ScreenGeometry.displayID(of: screen)
            let root = HUDRoot(state: state, screenFrame: screen.frame, isPrimary: id == mainID)
            if let existing = panels[id], let hosting = hostings[id] {
                hosting.rootView = root
                existing.setFrame(screen.frame, display: true)
                hosting.frame = CGRect(origin: .zero, size: screen.frame.size)
                markers[id]?.frame = CGRect(origin: .zero, size: screen.frame.size)
                markers[id]?.screenFrame = screen.frame
                existing.orderFrontRegardless()
                continue
            }
            let hosting = NSHostingView(rootView: root)
            hosting.frame = CGRect(origin: .zero, size: screen.frame.size)
            let marker = HandMarkerView(frame: CGRect(origin: .zero, size: screen.frame.size))
            marker.screenFrame = screen.frame
            let wrap = NSView(frame: CGRect(origin: .zero, size: screen.frame.size))
            wrap.wantsLayer = true
            wrap.addSubview(hosting)
            wrap.addSubview(marker)
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
            panel.contentView = wrap
            panel.setFrame(screen.frame, display: true)
            panel.orderFrontRegardless()
            panels[id] = panel
            hostings[id] = hosting
            markers[id] = marker
        }
    }

    func mark(
        cursor: CGPoint?,
        phase: GrabPhase,
        hand: String,
        target: String,
        window: CGRect?
    ) {
        for (id, view) in markers {
            guard let panel = panels[id] else { continue }
            view.screenFrame = panel.frame
            view.apply(cursor: cursor, phase: phase, hand: hand, target: target, window: window)
        }
    }

    func setVisible(_ visible: Bool) {
        for panel in panels.values {
            if visible {
                panel.orderFrontRegardless()
            } else {
                panel.orderOut(nil)
            }
        }
    }
}

final class HandMarkerView: NSView {
    var screenFrame: CGRect = .zero
    private var cursor: CGPoint?
    private var phase: GrabPhase = .none
    private var hand = ""
    private var target = ""
    private var windowRect: CGRect?

    override var isFlipped: Bool { true }
    override var isOpaque: Bool { false }

    func apply(
        cursor: CGPoint?,
        phase: GrabPhase,
        hand: String,
        target: String,
        window: CGRect?
    ) {
        self.cursor = cursor
        self.phase = phase
        self.hand = hand
        self.target = target
        self.windowRect = window
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let q = cursor, ScreenGeometry.contains(quartz: q, screen: screenFrame, pad: 80) else { return }
        let local = ScreenGeometry.local(quartz: q, on: screenFrame)
        let grab = phase == .grab
        let hold = phase == .hold
        let col: NSColor = {
            switch phase {
            case .grab, .hold: return NSColor(red: 1, green: 0.72, blue: 0.15, alpha: 1)
            case .follow: return NSColor(red: 0.25, green: 0.9, blue: 1, alpha: 1)
            case .none: return NSColor(white: 0.6, alpha: 0.5)
            }
        }()
        if grab, let wr = windowRect, ScreenGeometry.intersects(quartz: wr, screen: screenFrame) {
            let r = ScreenGeometry.localRect(quartz: wr, on: screenFrame)
            let path = NSBezierPath()
            path.move(to: local)
            path.line(to: CGPoint(x: r.midX, y: r.midY))
            col.setStroke()
            path.lineWidth = 2.5
            path.setLineDash([7, 5], count: 2, phase: 0)
            path.stroke()
        }
        let outer: CGFloat = grab ? 58 : 46
        let ring = NSBezierPath(ovalIn: CGRect(x: local.x - outer, y: local.y - outer, width: outer * 2, height: outer * 2))
        col.withAlphaComponent(0.35).setStroke()
        ring.lineWidth = 2
        ring.stroke()
        let inner = NSBezierPath(ovalIn: CGRect(x: local.x - 28, y: local.y - 28, width: 56, height: 56))
        col.setStroke()
        inner.lineWidth = grab ? 4 : 2.5
        inner.stroke()
        let core = NSBezierPath(ovalIn: CGRect(x: local.x - 6, y: local.y - 6, width: 12, height: 12))
        col.setFill()
        core.fill()
        let text = "\(phase.labelDE)  \(hand.uppercased())" + (grab && !target.isEmpty ? "  \(target.uppercased())" : "")
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 15, weight: .bold),
            .foregroundColor: col,
            .backgroundColor: NSColor.black.withAlphaComponent(0.72)
        ]
        (text as NSString).draw(at: CGPoint(x: local.x + 36, y: local.y - 10), withAttributes: attrs)
        let xy = String(format: "%.0f  %.0f", local.x, local.y) as NSString
        xy.draw(
            at: CGPoint(x: local.x + 36, y: local.y + 10),
            withAttributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .medium),
                .foregroundColor: col.withAlphaComponent(0.85)
            ]
        )
    }
}

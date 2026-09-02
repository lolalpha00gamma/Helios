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

/// Overlay darf nie Key-Window werden — sonst liegt Helios über der Ziel-App.
final class HUDPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class OverlayController {
    private var panels: [CGDirectDisplayID: HUDPanel] = [:]
    private var hostings: [CGDirectDisplayID: NSHostingView<HUDRoot>] = [:]
    private var markers: [CGDirectDisplayID: (left: HandMarkerView, right: HandMarkerView)] = [:]
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
                self?.state?.reloadSpaceMap()
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
                let box = CGRect(origin: .zero, size: screen.frame.size)
                markers[id]?.left.frame = box
                markers[id]?.right.frame = box
                markers[id]?.left.screenFrame = screen.frame
                markers[id]?.right.screenFrame = screen.frame
                existing.orderFrontRegardless()
                continue
            }
            let hosting = NSHostingView(rootView: root)
            hosting.frame = CGRect(origin: .zero, size: screen.frame.size)
            let box = CGRect(origin: .zero, size: screen.frame.size)
            let leftM = HandMarkerView(frame: box)
            leftM.screenFrame = screen.frame
            let rightM = HandMarkerView(frame: box)
            rightM.screenFrame = screen.frame
            let wrap = NSView(frame: box)
            wrap.wantsLayer = true
            wrap.addSubview(hosting)
            wrap.addSubview(leftM)
            wrap.addSubview(rightM)
            let panel = HUDPanel(
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
            panel.becomesKeyOnlyIfNeeded = true
            panel.contentView = wrap
            panel.setFrame(screen.frame, display: true)
            panel.orderFrontRegardless()
            panels[id] = panel
            hostings[id] = hosting
            markers[id] = (leftM, rightM)
        }
    }

    func detach() {
        if let screenObs {
            NotificationCenter.default.removeObserver(screenObs)
            self.screenObs = nil
        }
        attached = false
        for panel in panels.values {
            panel.orderOut(nil)
            panel.close()
        }
        panels.removeAll()
        hostings.removeAll()
        markers.removeAll()
    }

    func mark(
        cursors: [HandCursor],
        phase: GrabPhase,
        target: String,
        window: CGRect?,
        showReticle: Bool = true
    ) {
        for (id, pair) in markers {
            guard let panel = panels[id] else { continue }
            _ = panel
            if !showReticle {
                pair.left.isHidden = true
                pair.right.isHidden = true
                continue
            }
            pair.left.screenFrame = panel.frame
            pair.right.screenFrame = panel.frame
            let left = cursors.first(where: { $0.isLeft }) ?? cursors.first(where: { $0.side == "Links" })
            let right = cursors.first(where: { !$0.isLeft && $0.side != "Links" })
            pair.left.apply(
                cursor: left?.point,
                phase: left?.actor == true ? phase : (left == nil ? .none : .follow),
                hand: left?.side ?? "Links",
                target: left?.actor == true ? target : "",
                window: left?.actor == true ? window : nil,
                isLeft: true,
                showBeam: left?.actor == true
            )
            pair.right.apply(
                cursor: right?.point,
                phase: right?.actor == true ? phase : (right == nil ? .none : .follow),
                hand: right?.side ?? "Rechts",
                target: right?.actor == true ? target : "",
                window: right?.actor == true ? window : nil,
                isLeft: false,
                showBeam: right?.actor == true
            )
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
    private let ring = CAShapeLayer()
    private let core = CAShapeLayer()
    private let label = CATextLayer()
    private let beam = CAShapeLayer()
    private var lastLocal: CGPoint = CGPoint(x: -999, y: -999)

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layerContentsRedrawPolicy = .never
        layer?.backgroundColor = .clear
        beam.fillColor = nil
        beam.lineWidth = 2
        beam.lineDashPattern = nil
        ring.fillColor = nil
        ring.lineWidth = 3
        ring.bounds = CGRect(x: 0, y: 0, width: 92, height: 92)
        ring.path = CGPath(ellipseIn: CGRect(x: 2, y: 2, width: 88, height: 88), transform: nil)
        ring.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        core.bounds = CGRect(x: 0, y: 0, width: 14, height: 14)
        core.path = CGPath(ellipseIn: CGRect(x: 0, y: 0, width: 14, height: 14), transform: nil)
        core.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        label.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .bold)
        label.fontSize = 14
        label.alignmentMode = .left
        label.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
        label.bounds = CGRect(x: 0, y: 0, width: 280, height: 36)
        label.anchorPoint = CGPoint(x: 0, y: 0.5)
        let host = layer ?? CALayer()
        host.addSublayer(beam)
        host.addSublayer(ring)
        host.addSublayer(core)
        host.addSublayer(label)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isFlipped: Bool { true }
    override var isOpaque: Bool { false }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    func apply(
        cursor: CGPoint?,
        phase: GrabPhase,
        hand: String,
        target: String,
        window: CGRect?,
        isLeft: Bool = false,
        showBeam: Bool = true
    ) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }
        guard let q = cursor, ScreenGeometry.contains(quartz: q, screen: screenFrame, pad: 80) else {
            isHidden = true
            return
        }
        isHidden = false
        let local = ScreenGeometry.local(quartz: q, on: screenFrame)
        lastLocal = local
        let grab = phase == .grab
        let hold = phase == .hold
        let col: CGColor = {
            if grab || hold { return CGColor(red: 1, green: 0.72, blue: 0.15, alpha: 1) }
            if isLeft { return CGColor(red: 1, green: 0.72, blue: 0.22, alpha: 1) }
            return CGColor(red: 0.25, green: 0.9, blue: 1, alpha: 1)
        }()
        ring.strokeColor = col
        ring.position = local
        core.fillColor = col
        core.position = local
        label.foregroundColor = col
        label.string = "\(phase.labelDE)  \(hand.uppercased())" + (grab && !target.isEmpty ? "  \(target.uppercased())" : "")
        label.position = CGPoint(x: local.x + 52, y: local.y)
        if showBeam, grab, let wr = window, ScreenGeometry.intersects(quartz: wr, screen: screenFrame) {
            let r = ScreenGeometry.localRect(quartz: wr, on: screenFrame)
            let path = CGMutablePath()
            path.move(to: local)
            path.addLine(to: CGPoint(x: r.midX, y: r.midY))
            beam.path = path
            beam.strokeColor = col
            beam.isHidden = false
        } else {
            beam.isHidden = true
        }
        ring.lineWidth = grab || hold ? 4 : 2.5
    }
}

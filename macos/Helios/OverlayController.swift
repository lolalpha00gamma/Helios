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
    /// HUD-Chrome auf Konsole/Kalibrier-Schirm, nicht hart NSScreen.main.
    private var preferredPrimaryID: CGDirectDisplayID?

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

    func setPrimaryDisplay(_ id: CGDirectDisplayID?) {
        if preferredPrimaryID == id { return }
        preferredPrimaryID = id
        if state != nil { rebuild() }
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
        let mainID = preferredPrimaryID ?? NSScreen.main.map { ScreenGeometry.displayID(of: $0) }
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
        window: CGRect?,
        peace: CGFloat = 0,
        clutch: CGFloat = 0,
        ibeam: Bool = false
    ) {
        for (id, view) in markers {
            guard let panel = panels[id] else { continue }
            view.screenFrame = panel.frame
            view.apply(
                cursor: cursor,
                phase: phase,
                hand: hand,
                target: target,
                window: window,
                peace: peace,
                clutch: clutch,
                ibeam: ibeam
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
    private let peaceRing = CAShapeLayer()
    private let clutchRing = CAShapeLayer()
    private var lastLocal: CGPoint = CGPoint(x: -999, y: -999)

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layerContentsRedrawPolicy = .never
        layer?.backgroundColor = .clear
        beam.fillColor = nil
        beam.lineWidth = 2.5
        beam.lineDashPattern = [7, 5]
        ring.fillColor = nil
        ring.lineWidth = 3
        ring.bounds = CGRect(x: 0, y: 0, width: 92, height: 92)
        ring.path = CGPath(ellipseIn: CGRect(x: 2, y: 2, width: 88, height: 88), transform: nil)
        ring.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        peaceRing.fillColor = nil
        peaceRing.lineWidth = 5
        peaceRing.lineCap = .round
        peaceRing.strokeStart = 0
        peaceRing.strokeEnd = 0
        peaceRing.bounds = CGRect(x: 0, y: 0, width: 118, height: 118)
        peaceRing.path = CGPath(ellipseIn: CGRect(x: 4, y: 4, width: 110, height: 110), transform: nil)
        peaceRing.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        peaceRing.strokeColor = CGColor(red: 1, green: 0.72, blue: 0.15, alpha: 1)
        clutchRing.fillColor = nil
        clutchRing.lineWidth = 4
        clutchRing.lineCap = .round
        clutchRing.strokeStart = 0
        clutchRing.strokeEnd = 0
        clutchRing.bounds = CGRect(x: 0, y: 0, width: 142, height: 142)
        clutchRing.path = CGPath(ellipseIn: CGRect(x: 4, y: 4, width: 134, height: 134), transform: nil)
        clutchRing.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        clutchRing.strokeColor = CGColor(red: 1, green: 0.72, blue: 0.15, alpha: 0.95)
        clutchRing.isHidden = true
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
        host.addSublayer(clutchRing)
        host.addSublayer(peaceRing)
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
        peace: CGFloat = 0,
        clutch: CGFloat = 0,
        ibeam: Bool = false
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
        let ghost = clutch > 0.02
        let col: CGColor = {
            if ghost { return CGColor(red: 1, green: 0.72, blue: 0.15, alpha: 0.45) }
            if ibeam { return CGColor(red: 0.85, green: 0.95, blue: 1, alpha: 1) }
            switch phase {
            case .grab, .hold: return CGColor(red: 1, green: 0.72, blue: 0.15, alpha: 1)
            case .follow: return CGColor(red: 0.25, green: 0.9, blue: 1, alpha: 1)
            case .none: return CGColor(gray: 0.55, alpha: 0.5)
            }
        }()
        if ibeam {
            let path = CGMutablePath()
            path.addRect(CGRect(x: 0, y: 0, width: 16, height: 3))
            path.addRect(CGRect(x: 6, y: 0, width: 4, height: 28))
            path.addRect(CGRect(x: 0, y: 25, width: 16, height: 3))
            core.path = path
            core.bounds = CGRect(x: 0, y: 0, width: 16, height: 28)
        } else {
            core.path = CGPath(ellipseIn: CGRect(x: 0, y: 0, width: 14, height: 14), transform: nil)
            core.bounds = CGRect(x: 0, y: 0, width: 14, height: 14)
        }
        ring.strokeColor = col
        ring.lineDashPattern = ghost ? [6, 5] : nil
        ring.opacity = ghost ? 0.55 : 1
        ring.position = local
        core.fillColor = col
        core.opacity = ghost ? 0.35 : 1
        core.position = local
        label.foregroundColor = col
        if ghost {
            label.string = "GEIST  \(hand.uppercased())"
        } else if ibeam {
            label.string = "TEXT  \(hand.uppercased())"
        } else {
            label.string = "\(phase.labelDE)  \(hand.uppercased())" + (grab && !target.isEmpty ? "  \(target.uppercased())" : "")
        }
        label.position = CGPoint(x: local.x + 52, y: local.y)
        if grab, let wr = window, ScreenGeometry.intersects(quartz: wr, screen: screenFrame) {
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
        peaceRing.position = local
        if peace > 0.02 {
            peaceRing.isHidden = false
            peaceRing.strokeEnd = peace
        } else {
            peaceRing.isHidden = true
            peaceRing.strokeEnd = 0
        }
        clutchRing.position = local
        if clutch > 0.02 {
            clutchRing.isHidden = false
            clutchRing.strokeEnd = clutch
        } else {
            clutchRing.isHidden = true
            clutchRing.strokeEnd = 0
        }
    }
}

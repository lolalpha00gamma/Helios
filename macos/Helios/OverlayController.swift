import AppKit
import QuartzCore
import SwiftUI

private struct HUDRoot: View {
    @ObservedObject var state: AppState
    var screenFrame: CGRect
    var isPrimary: Bool
    var layer: HUDLayer

    var body: some View {
        HUDView(screenFrame: screenFrame, isPrimary: isPrimary, layer: layer)
            .environmentObject(state)
            .ignoresSafeArea()
            .containerBackground(.clear, for: .window)
    }
}

/// Overlay darf nie Key-Window werden — sonst liegt Helios über der Ziel-App.
final class HUDPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private struct HUDPoseSample {
    var at: TimeInterval
    var cursors: [HandCursor]
    var phase: GrabPhase
    var target: String
    var window: CGRect?
    var showReticle: Bool
    var freeze: Bool
}

private final class HUDLinkDriver: NSObject {
    var onFire: (() -> Void)?
    @objc func fire(_ link: CADisplayLink) {
        onFire?()
    }
}

@MainActor
final class OverlayController {
    private var panels: [CGDirectDisplayID: HUDPanel] = [:]
    private var chromeHostings: [CGDirectDisplayID: NSHostingView<HUDRoot>] = [:]
    private var dockHostings: [CGDirectDisplayID: NSHostingView<HUDRoot>] = [:]
    private var fillHostings: [CGDirectDisplayID: NSHostingView<HUDRoot>] = [:]
    private var markers: [CGDirectDisplayID: (left: HandMarkerView, right: HandMarkerView)] = [:]
    private var loupes: [CGDirectDisplayID: CursorLoupeView] = [:]
    private weak var state: AppState?
    private var screenObs: NSObjectProtocol?
    private var attached = false
    private var displayLink: CADisplayLink?
    private let linkDriver = HUDLinkDriver()
    private var posePrev: HUDPoseSample?
    private var poseNow: HUDPoseSample?
    var onCoastCursor: ((CGPoint) -> Void)?

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
            chromeHostings[id] = nil
            dockHostings[id] = nil
            fillHostings[id] = nil
            markers[id] = nil
            loupes[id] = nil
        }
        let mainID = NSScreen.main.map { ScreenGeometry.displayID(of: $0) }
        for screen in screens {
            let id = ScreenGeometry.displayID(of: screen)
            let box = CGRect(origin: .zero, size: screen.frame.size)
            let chromeRoot = HUDRoot(state: state, screenFrame: screen.frame, isPrimary: id == mainID, layer: .chrome)
            let dockRoot = HUDRoot(state: state, screenFrame: screen.frame, isPrimary: id == mainID, layer: .dock)
            let fillRoot = HUDRoot(state: state, screenFrame: screen.frame, isPrimary: id == mainID, layer: .fill)
            if let existing = panels[id], let chrome = chromeHostings[id], let dock = dockHostings[id], let fill = fillHostings[id] {
                chrome.rootView = chromeRoot
                dock.rootView = dockRoot
                fill.rootView = fillRoot
                existing.setFrame(screen.frame, display: true)
                layoutChrome(chrome, box: box)
                layoutDock(dock, box: box)
                fill.frame = box
                markers[id]?.left.frame = box
                markers[id]?.right.frame = box
                markers[id]?.left.screenFrame = screen.frame
                markers[id]?.right.screenFrame = screen.frame
                polish(chrome, wrap: existing.contentView, panel: existing)
                polish(dock, wrap: existing.contentView, panel: existing)
                polish(fill, wrap: existing.contentView, panel: existing)
                fill.isHidden = true
                if loupes[id] == nil, let wrap = existing.contentView {
                    let loupe = CursorLoupeView(frame: CGRect(x: 0, y: 0, width: 180, height: 180))
                    wrap.addSubview(loupe)
                    loupes[id] = loupe
                }
                if !existing.isVisible {
                    existing.orderFrontRegardless()
                }
                continue
            }
            let chrome = NSHostingView(rootView: chromeRoot)
            let dock = NSHostingView(rootView: dockRoot)
            let fill = NSHostingView(rootView: fillRoot)
            layoutChrome(chrome, box: box)
            layoutDock(dock, box: box)
            fill.frame = box
            fill.isHidden = true
            let leftM = HandMarkerView(frame: box)
            leftM.screenFrame = screen.frame
            let rightM = HandMarkerView(frame: box)
            rightM.screenFrame = screen.frame
            let wrap = NSView(frame: box)
            wrap.wantsLayer = true
            wrap.layer?.isOpaque = false
            wrap.layer?.backgroundColor = NSColor.clear.cgColor
            wrap.addSubview(fill)
            wrap.addSubview(chrome)
            wrap.addSubview(dock)
            wrap.addSubview(leftM)
            wrap.addSubview(rightM)
            let loupe = CursorLoupeView(frame: CGRect(x: 0, y: 0, width: 180, height: 180))
            wrap.addSubview(loupe)
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
            if GestureMath.hudSharingExcluded() {
                panel.sharingType = .none
            }
            panel.isReleasedWhenClosed = false
            panel.hidesOnDeactivate = false
            panel.becomesKeyOnlyIfNeeded = true
            panel.contentView = wrap
            polish(chrome, wrap: wrap, panel: panel)
            polish(dock, wrap: wrap, panel: panel)
            polish(fill, wrap: wrap, panel: panel)
            panel.setFrame(screen.frame, display: true)
            panel.orderFrontRegardless()
            panels[id] = panel
            chromeHostings[id] = chrome
            dockHostings[id] = dock
            fillHostings[id] = fill
            markers[id] = (leftM, rightM)
            loupes[id] = loupe
        }
        restartDisplayLink()
    }

    func detach() {
        displayLink?.invalidate()
        displayLink = nil
        linkDriver.onFire = nil
        posePrev = nil
        poseNow = nil
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
        chromeHostings.removeAll()
        dockHostings.removeAll()
        fillHostings.removeAll()
        markers.removeAll()
        loupes.removeAll()
    }

    func mark(
        cursors: [HandCursor],
        phase: GrabPhase,
        target: String,
        window: CGRect?,
        showReticle: Bool = true,
        freeze: Bool = false
    ) {
        posePrev = poseNow
        poseNow = HUDPoseSample(
            at: CACurrentMediaTime(),
            cursors: cursors,
            phase: phase,
            target: target,
            window: window,
            showReticle: showReticle,
            freeze: freeze
        )
        ensureDisplayLink()
        let fillOn = (state?.calibActive == true)
            || (state?.keyboardVisible == true)
            || (state.map { $0.drill.phase != .idle } ?? false)
            || !(state?.folderOrbs.isEmpty ?? true)
        let clickable = state?.calibActive == true
        for (id, h) in fillHostings {
            h.isHidden = !fillOn
            if !fillOn, let panel = panels[id] {
                polish(h, wrap: panel.contentView, panel: panel)
            }
        }
        for panel in panels.values {
            panel.ignoresMouseEvents = !clickable
            if !fillOn {
                panel.isOpaque = false
                panel.backgroundColor = .clear
            }
        }
        if posePrev == nil || freeze {
            paint(
                cursors: cursors,
                phase: phase,
                target: target,
                window: window,
                showReticle: showReticle,
                freeze: freeze
            )
        }
    }

    private func restartDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
        ensureDisplayLink()
    }

    private func ensureDisplayLink() {
        guard displayLink == nil else { return }
        guard let view = panels.values.first?.contentView else { return }
        linkDriver.onFire = { [weak self] in
            Task { @MainActor in self?.displayTick() }
        }
        let link = view.displayLink(target: linkDriver, selector: #selector(HUDLinkDriver.fire(_:)))
        if #available(macOS 14.0, *) {
            link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 120, preferred: 90)
        }
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func displayTick() {
        guard let next = poseNow else { return }
        guard let prev = posePrev, prev.at < next.at else {
            paint(
                cursors: next.cursors,
                phase: next.phase,
                target: next.target,
                window: next.window,
                showReticle: next.showReticle,
                freeze: next.freeze
            )
            return
        }
        let now = CACurrentMediaTime()
        var cursors = next.cursors
        let t = GestureMath.hudLerpT(prevAt: prev.at, nextAt: next.at, now: now, freeze: next.freeze)
        let snap = next.freeze || !GestureMath.hudCoastAllowed(
            reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        )
        let span = next.at - prev.at
        for i in cursors.indices {
            let id = cursors[i].id
            if let old = prev.cursors.first(where: { $0.id == id }) {
                var p = GestureMath.hudLerpPoint(
                    prev: old.point,
                    next: cursors[i].point,
                    t: snap ? 1 : t
                )
                if !snap, t >= 1, span > 1e-6 {
                    let extra = now - next.at - span
                    if extra > 0 {
                        let vel = GestureMath.hudCoastVel(prev: old.point, next: cursors[i].point, dt: span)
                        let cap = GestureMath.hudCoastCapScaled(
                            scale: ScreenGeometry.backingScale(quartz: p)
                        )
                        p = GestureMath.hudCoastPoint(sample: p, vel: vel, elapsed: extra, cap: cap)
                    }
                }
                cursors[i].point = p
            }
        }
        paint(
            cursors: cursors,
            phase: next.phase,
            target: next.target,
            window: next.window,
            showReticle: next.showReticle,
            freeze: next.freeze
        )
        if GestureMath.hudLerpDrivesCursor(),
           GestureMath.hudCoastAllowed(reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion),
           !next.freeze,
           let actor = cursors.first(where: { $0.actor }) ?? cursors.first
        {
            onCoastCursor?(actor.point)
        }
    }

    private func paint(
        cursors: [HandCursor],
        phase: GrabPhase,
        target: String,
        window: CGRect?,
        showReticle: Bool,
        freeze: Bool
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
                showBeam: left?.actor == true,
                dim: GestureMath.skeletonFreezeDim(freeze)
            )
            pair.right.apply(
                cursor: right?.point,
                phase: right?.actor == true ? phase : (right == nil ? .none : .follow),
                hand: right?.side ?? "Rechts",
                target: right?.actor == true ? target : "",
                window: right?.actor == true ? window : nil,
                isLeft: false,
                showBeam: right?.actor == true,
                dim: GestureMath.skeletonFreezeDim(freeze)
            )
            let actorPt = (left?.actor == true ? left?.point : nil) ?? (right?.actor == true ? right?.point : nil) ?? left?.point ?? right?.point
            loupes[id]?.apply(
                quartz: actorPt,
                screen: panel.frame,
                windowID: CGWindowID(panel.windowNumber),
                show: showReticle && (state?.showLoupe ?? true)
            )
        }
    }

    func setVisible(_ visible: Bool) {
        for (id, panel) in panels {
            if visible {
                if let chrome = chromeHostings[id] { polish(chrome, wrap: panel.contentView, panel: panel) }
                if let dock = dockHostings[id] { polish(dock, wrap: panel.contentView, panel: panel) }
                if let fill = fillHostings[id] {
                    polish(fill, wrap: panel.contentView, panel: panel)
                    let fillOn = (state?.calibActive == true)
                        || (state?.keyboardVisible == true)
                        || (state.map { $0.drill.phase != .idle } ?? false)
                    fill.isHidden = !fillOn
                }
                panel.isOpaque = false
                panel.backgroundColor = .clear
                if !panel.isVisible {
                    panel.orderFrontRegardless()
                }
            } else {
                panel.orderOut(nil)
            }
        }
    }

    private func layoutChrome(_ hosting: NSHostingView<HUDRoot>, box: CGRect) {
        hosting.frame = CGRect(x: 0, y: box.height - 48, width: box.width, height: 48)
    }

    private func layoutDock(_ hosting: NSHostingView<HUDRoot>, box: CGRect) {
        hosting.frame = CGRect(x: max(0, box.width - 420), y: 8, width: min(420, box.width), height: 228)
    }

    /// NSHostingView.drawsBackground default true — Dark Mode = Vollbild schwarz nach orderFront.
    private func polish(_ hosting: NSHostingView<HUDRoot>, wrap: NSView?, panel: HUDPanel) {
        if hosting.responds(to: Selector(("setDrawsBackground:"))) {
            hosting.setValue(false, forKey: "drawsBackground")
        }
        hosting.wantsLayer = true
        hosting.layer?.isOpaque = false
        hosting.layer?.backgroundColor = NSColor.clear.cgColor
        wrap?.wantsLayer = true
        wrap?.layer?.isOpaque = false
        wrap?.layer?.backgroundColor = NSColor.clear.cgColor
        panel.isOpaque = false
        panel.backgroundColor = .clear
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
        label.contentsScale = ScreenGeometry.backingScale(
            quartz: ScreenGeometry.clampQuartz(NSEvent.mouseLocation.screenFlipped)
        )
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
        showBeam: Bool = true,
        dim: CGFloat = 1
    ) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }
        guard let q = cursor else {
            isHidden = true
            return
        }
        if !ScreenGeometry.contains(quartz: q, screen: screenFrame, pad: 280) {
            isHidden = true
            return
        }
        isHidden = false
        var local = ScreenGeometry.local(quartz: q, on: screenFrame)
        local.x = min(max(local.x, 12), max(12, screenFrame.width - 12))
        local.y = min(max(local.y, 12), max(12, screenFrame.height - 12))
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
        let a = Float(max(0.2, min(1, dim)))
        ring.opacity = a
        core.opacity = a
        label.opacity = a
        beam.opacity = a
    }
}

/// Großer Zielkreis am Zeiger. Ohne ScreenCapture (sonst Blackscreen-Rechte).
final class CursorLoupeView: NSView {
    private let glass = CAShapeLayer()
    private let rim = CAShapeLayer()
    private let hair = CAShapeLayer()
    private let side: CGFloat = 180

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = .clear
        isHidden = true
        let inner = CGRect(x: 8, y: 8, width: side - 16, height: side - 16)
        glass.frame = CGRect(origin: .zero, size: CGSize(width: side, height: side))
        glass.path = CGPath(ellipseIn: inner, transform: nil)
        glass.fillColor = NSColor.black.withAlphaComponent(0.10).cgColor
        glass.strokeColor = nil
        rim.frame = glass.frame
        rim.path = CGPath(ellipseIn: CGRect(x: 2, y: 2, width: side - 4, height: side - 4), transform: nil)
        rim.fillColor = nil
        rim.strokeColor = CGColor(red: 0.25, green: 0.9, blue: 1, alpha: 0.95)
        rim.lineWidth = 2.5
        let mid = side / 2
        let p = CGMutablePath()
        p.move(to: CGPoint(x: mid - 14, y: mid))
        p.addLine(to: CGPoint(x: mid + 14, y: mid))
        p.move(to: CGPoint(x: mid, y: mid - 14))
        p.addLine(to: CGPoint(x: mid, y: mid + 14))
        p.addEllipse(in: CGRect(x: mid - 5, y: mid - 5, width: 10, height: 10))
        hair.path = p
        hair.strokeColor = CGColor(red: 1, green: 0.72, blue: 0.22, alpha: 0.95)
        hair.lineWidth = 1.4
        hair.fillColor = nil
        let host = layer ?? CALayer()
        host.addSublayer(glass)
        host.addSublayer(rim)
        host.addSublayer(hair)
        self.frame.size = CGSize(width: side, height: side)
    }

    required init?(coder: NSCoder) { fatalError() }
    override var isFlipped: Bool { true }
    override var isOpaque: Bool { false }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    func apply(quartz: CGPoint?, screen: CGRect, windowID: CGWindowID, show: Bool) {
        _ = windowID
        guard show, let q = quartz, ScreenGeometry.contains(quartz: q, screen: screen, pad: 12) else {
            isHidden = true
            return
        }
        isHidden = false
        var local = ScreenGeometry.local(quartz: q, on: screen)
        local.x -= side / 2
        local.y -= side / 2
        local.x = min(max(8, local.x), max(8, screen.width - side - 8))
        local.y = min(max(8, local.y), max(8, screen.height - side - 8))
        setFrameOrigin(local)
    }
}
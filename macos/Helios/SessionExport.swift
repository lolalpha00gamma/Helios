import AppKit
import Foundation
import QuartzCore
import UniformTypeIdentifiers
import Vision

struct JointSnap: Codable {
    var x: Double
    var y: Double
    var z: Double?
    var c: Double
}

struct HandSnap: Codable {
    var id: String?
    var side: String
    var pose: String
    var label: String?
    var confidence: Double
    var poseProb: Double?
    var quality: Double?
    var openScore: Int
    var pinchRatio: Double
    var pinchClosed: Bool
    var pinchClosedness: Double?
    var palmX: Double
    var palmY: Double
    var palmWidth: Double?
    var joints: [String: JointSnap]
}

struct GestureFrame: Codable {
    var t: Double
    var iso: String
    var luma: Double
    var mode: String
    var action: String
    var hands: [HandSnap]
}

@MainActor
final class SessionRecorder {
    private var frames: [GestureFrame] = []
    private var thumbs: [(hands: [HandSnap], t: Double)] = []
    private var lastFrameAt: TimeInterval = 0
    private var lastThumbAt: TimeInterval = 0
    private let t0 = CACurrentMediaTime()
    private let maxFrames = 2400
    private let maxThumbs = 16
    private let iso = ISO8601DateFormatter()

    var frameCount: Int { frames.count }

    func push(
        hands: [TrackedHand],
        preview: NSImage?,
        luma: CGFloat,
        mode: EngineMode,
        action: String,
        now: TimeInterval
    ) {
        if now - lastFrameAt < 0.12 { return }
        lastFrameAt = now
        let snaps = hands.map(Self.snap)
        let frame = GestureFrame(
            t: now - t0,
            iso: iso.string(from: Date()),
            luma: Double(luma),
            mode: mode.labelDE,
            action: action,
            hands: snaps
        )
        frames.append(frame)
        if frames.count > maxFrames {
            frames.removeFirst(frames.count - maxFrames)
        }
        if now - lastThumbAt >= 0.40, !snaps.isEmpty {
            lastThumbAt = now
            thumbs.append((snaps, now - t0))
            if thumbs.count > maxThumbs {
                thumbs.removeFirst(thumbs.count - maxThumbs)
            }
        }
    }

    func copyProtocol(_ log: AuditLog) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(log.plainText(), forType: .string)
    }

    func copyFilmstrip() {
        let img = filmstrip()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([img])
    }

    func export(log: AuditLog) {
        let stamp = Self.stamp()
        let panel = NSSavePanel()
        panel.title = "Helios-Sitzung exportieren"
        panel.nameFieldStringValue = "Helios-Sitzung-\(stamp)"
        panel.canCreateDirectories = true
        panel.prompt = "Exportieren"
        panel.message = "Ordner mit Protokoll (JSON+TXT), Gesten (JSONL) und einem Filmstreifen (PNG)."
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try write(to: url, log: log)
            NSWorkspace.shared.open(url)
        } catch {
            let a = NSAlert(error: error)
            a.messageText = "Export fehlgeschlagen"
            a.runModal()
        }
    }

    private func write(to url: URL, log: AuditLog) throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: url.path) {
            try fm.removeItem(at: url)
        }
        try fm.createDirectory(at: url, withIntermediateDirectories: true)
        try log.plainText().write(to: url.appendingPathComponent("protokoll.txt"), atomically: true, encoding: .utf8)
        try log.jsonData().write(to: url.appendingPathComponent("protokoll.json"))
        let jsonl = frames.map { Self.line($0) }.joined(separator: "\n") + "\n"
        try jsonl.write(to: url.appendingPathComponent("gesten.jsonl"), atomically: true, encoding: .utf8)
        if let tiff = filmstrip().tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:])
        {
            try png.write(to: url.appendingPathComponent("gesten.png"))
        }
        let readme = """
        Helios-Sitzung

        protokoll.txt   lesbares Protokoll (Erkannt / Ausgeführt / Fehler)
        protokoll.json  dasselbe strukturiert
        gesten.jsonl    eine Zeile pro Frame: Pose, label (Create ML), Gelenke x/y/z/Konfidenz
        gesten.png      Filmstreifen der letzten Gesten (Kamera + Skelett)

        Gelenke: x/y normiert 0…1 (Kamera), y nach oben. z relativ zum Handgelenk, isotrope Skala.
        label: englischer Pose-Name (fist, openPalm, pinch, point, thumbsUp, peace, unknown).
        Training: Create ML Tabular/Time-Series auf 12 Frames × 8 Merkmale, Ausgabe HeliosTemporal.mlmodel.
        """
        try readme.write(to: url.appendingPathComponent("README.txt"), atomically: true, encoding: .utf8)
    }

    func filmstrip() -> NSImage {
        let src: [(hands: [HandSnap], t: Double)] = {
            if !thumbs.isEmpty { return thumbs }
            let picked = frames.filter { !$0.hands.isEmpty }
            guard !picked.isEmpty else { return [] }
            let step = max(1, picked.count / maxThumbs)
            return picked.enumerated().compactMap { i, f in
                i % step == 0 ? (f.hands, f.t) : nil
            }.suffix(maxThumbs).map { $0 }
        }()
        let cols = 4
        let rows = max(1, (max(src.count, 1) + cols - 1) / cols)
        let cell = CGSize(width: 320, height: 180)
        let size = CGSize(width: cell.width * CGFloat(cols), height: cell.height * CGFloat(rows))
        return NSImage(size: size, flipped: false) { rect in
            NSColor(white: 0.05, alpha: 1).setFill()
            rect.fill()
            if src.isEmpty {
                let p = NSString(string: "Noch keine Geste — Kamera laufen lassen, dann erneut exportieren.")
                p.draw(
                    at: CGPoint(x: 24, y: size.height / 2),
                    withAttributes: [
                        .foregroundColor: NSColor.secondaryLabelColor,
                        .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
                    ]
                )
                return true
            }
            for (i, thumb) in src.enumerated() {
                let c = i % cols
                let r = i / cols
                let box = CGRect(
                    x: CGFloat(c) * cell.width,
                    y: size.height - CGFloat(r + 1) * cell.height,
                    width: cell.width,
                    height: cell.height
                )
                GestureDraw.composite(image: nil, hands: thumb.hands, in: box)
                let label = String(format: "%.1fs  %@", thumb.t, thumb.hands.map(\.pose).joined(separator: " · "))
                (label as NSString).draw(
                    at: CGPoint(x: box.minX + 6, y: box.minY + 4),
                    withAttributes: [
                        .foregroundColor: NSColor.cyan,
                        .font: NSFont.monospacedSystemFont(ofSize: 9, weight: .medium),
                        .backgroundColor: NSColor.black.withAlphaComponent(0.45)
                    ]
                )
            }
            return true
        }
    }

    private static func snap(_ hand: TrackedHand) -> HandSnap {
        var joints: [String: JointSnap] = [:]
        for (name, j) in hand.overlayJoints {
            joints[Self.key(name)] = JointSnap(
                x: Double(j.point.x),
                y: Double(j.point.y),
                z: Double(j.z),
                c: Double(j.confidence)
            )
        }
        return HandSnap(
            id: hand.id,
            side: hand.sideDE,
            pose: hand.pose.labelDE,
            label: hand.pose.rawValue,
            confidence: Double(hand.meanConfidence),
            poseProb: hand.poseProb,
            quality: hand.quality,
            openScore: hand.openScore,
            pinchRatio: Double(hand.pinchRatio),
            pinchClosed: hand.pinchClosed,
            pinchClosedness: hand.pinchClosedness,
            palmX: Double(hand.palm.x),
            palmY: Double(hand.palm.y),
            palmWidth: Double(hand.palmWidth),
            joints: joints
        )
    }

    private static func key(_ n: VNHumanHandPoseObservation.JointName) -> String {
        switch n {
        case .wrist: return "wrist"
        case .thumbCMC: return "thumbCMC"
        case .thumbMP: return "thumbMP"
        case .thumbIP: return "thumbIP"
        case .thumbTip: return "thumbTip"
        case .indexMCP: return "indexMCP"
        case .indexPIP: return "indexPIP"
        case .indexDIP: return "indexDIP"
        case .indexTip: return "indexTip"
        case .middleMCP: return "middleMCP"
        case .middlePIP: return "middlePIP"
        case .middleDIP: return "middleDIP"
        case .middleTip: return "middleTip"
        case .ringMCP: return "ringMCP"
        case .ringPIP: return "ringPIP"
        case .ringDIP: return "ringDIP"
        case .ringTip: return "ringTip"
        case .littleMCP: return "littleMCP"
        case .littlePIP: return "littlePIP"
        case .littleDIP: return "littleDIP"
        case .littleTip: return "littleTip"
        default: return String(describing: n)
        }
    }

    private static func line(_ f: GestureFrame) -> String {
        let data = try? JSONEncoder().encode(f)
        return data.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    }

    private static func stamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HHmmss"
        return f.string(from: Date())
    }
}

enum GestureDraw {
    private static let chains: [[String]] = [
        ["wrist", "thumbCMC", "thumbMP", "thumbIP", "thumbTip"],
        ["wrist", "indexMCP", "indexPIP", "indexDIP", "indexTip"],
        ["wrist", "middleMCP", "middlePIP", "middleDIP", "middleTip"],
        ["wrist", "ringMCP", "ringPIP", "ringDIP", "ringTip"],
        ["wrist", "littleMCP", "littlePIP", "littleDIP", "littleTip"]
    ]

    static func composite(image: NSImage?, hands: [HandSnap], in box: CGRect) {
        if let image {
            let fitted = fit(image.size, in: box)
            image.draw(in: fitted, from: .zero, operation: .copy, fraction: 1)
        } else {
            NSColor(white: 0.08, alpha: 1).setFill()
            box.fill()
        }
        NSColor.black.withAlphaComponent(0.15).setFill()
        box.fill()
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()
        ctx.setLineWidth(3.2)
        ctx.setLineJoin(.round)
        ctx.setLineCap(.round)
        for hand in hands {
            let col = hand.side == "Links"
                ? CGColor(red: 1, green: 0.75, blue: 0.2, alpha: 0.95)
                : CGColor(red: 0.3, green: 0.9, blue: 1, alpha: 0.95)
            ctx.setStrokeColor(col)
            ctx.setFillColor(col)
            let fitted = box
            for chain in chains {
                var started = false
                let path = CGMutablePath()
                for name in chain {
                    guard let j = joint(hand, name), j.c > 0.18 else { continue }
                    let p = vis(j, fitted)
                    if started { path.addLine(to: p) } else { path.move(to: p); started = true }
                }
                ctx.addPath(path)
                ctx.strokePath()
            }
            for (_, j) in hand.joints where j.c > 0.18 {
                let p = vis(j, fitted)
                ctx.fillEllipse(in: CGRect(x: p.x - 3.2, y: p.y - 3.2, width: 6.4, height: 6.4))
            }
        }
        ctx.restoreGState()
    }

    private static func joint(_ hand: HandSnap, _ name: String) -> JointSnap? {
        if let j = hand.joints[name] { return j }
        return hand.joints.first { $0.key.lowercased().contains(name.lowercased()) }?.value
    }

    private static func vis(_ j: JointSnap, _ box: CGRect) -> CGPoint {
        CGPoint(x: box.minX + CGFloat(j.x) * box.width, y: box.minY + CGFloat(j.y) * box.height)
    }

    private static func fit(_ image: CGSize, in box: CGRect) -> CGRect {
        guard image.width > 0, image.height > 0 else { return box }
        let s = min(box.width / image.width, box.height / image.height)
        let w = image.width * s
        let h = image.height * s
        return CGRect(x: box.midX - w / 2, y: box.midY - h / 2, width: w, height: h)
    }
}

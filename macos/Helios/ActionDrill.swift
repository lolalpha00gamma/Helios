import AppKit
import Foundation
import QuartzCore
import Vision

struct DrillAction: Equatable, Identifiable {
    var id: String
    var titleDE: String
    var hint: String
}

struct DrillSample: Codable {
    var t: Double
    var side: String
    var pose: String
    var poseProb: Double
    var pinch: Double
    var palmX: Double
    var palmY: Double
    var open: Int
}

struct DrillTrial: Codable {
    var action: String
    var titleDE: String
    var repeatIndex: Int
    var iso: String
    var durationMs: Int
    var detected: Bool
    var evidence: String
    var samples: [DrillSample]
}

enum DrillPhase: String {
    case idle, countdown, capture, rest, done
}

@MainActor
final class ActionDrill: ObservableObject {
    static let repeats = 3
    static let countdownSec = 3.0
    static let captureSec = 2.0
    static let restSec = 0.7

    static let catalog: [DrillAction] = [
        DrillAction(id: "openRight", titleDE: "Rechte Hand offen", hint: "Rechte Handfläche zur Kamera, still halten."),
        DrillAction(id: "openLeft", titleDE: "Linke Hand offen", hint: "Linke Handfläche zur Kamera, still halten."),
        DrillAction(id: "pinch", titleDE: "Pinzette", hint: "Daumen und Zeigefinger zusammen, kurz halten."),
        DrillAction(id: "drag", titleDE: "Ziehen", hint: "Pinzette zu, dann Hand nach rechts oder links ziehen."),
        DrillAction(id: "throwUp", titleDE: "Werfen hoch", hint: "Pinzette, dann schnell nach oben werfen."),
        DrillAction(id: "throwDown", titleDE: "Werfen runter", hint: "Pinzette, dann schnell nach unten werfen."),
        DrillAction(id: "swipeLeft", titleDE: "Wischen links", hint: "Offene Hand schnell nach links wischen."),
        DrillAction(id: "swipeRight", titleDE: "Wischen rechts", hint: "Offene Hand schnell nach rechts wischen."),
        DrillAction(id: "fist", titleDE: "Faust", hint: "Faust zur Kamera, eine Sekunde halten."),
        DrillAction(id: "point", titleDE: "Zeigen", hint: "Zeigefinger ausstrecken, Rest zu."),
        DrillAction(id: "peace", titleDE: "Zwei Finger", hint: "Zeige- und Mittelfinger, Rest zu."),
        DrillAction(id: "clap", titleDE: "Klatschen", hint: "Zwei offene Hände, einmal sichtbar zusammenschlagen.")
    ]

    @Published var running = false
    @Published var phase: DrillPhase = .idle
    @Published var actionIndex = 0
    @Published var repeatIndex = 0
    @Published var countdown = 3
    @Published var captureLeft: Double = 0
    @Published var trials: [DrillTrial] = []
    @Published var lastEvidence = ""
    @Published var status = "Bereit — 12 Gesten × 3."

    private var phaseBegan: TimeInterval = 0
    private var buffer: [DrillSample] = []
    private let isoFmt: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    var current: DrillAction { Self.catalog[min(actionIndex, Self.catalog.count - 1)] }
    var stepLabel: String { "\(actionIndex + 1)/\(Self.catalog.count)" }
    var progress: Double {
        let total = Double(Self.catalog.count * Self.repeats)
        guard total > 0 else { return 0 }
        let done = Double(actionIndex * Self.repeats + repeatIndex)
        return min(1, done / total)
    }

    func start() {
        running = true
        phase = .countdown
        actionIndex = 0
        repeatIndex = 0
        trials = []
        buffer = []
        lastEvidence = ""
        countdown = 3
        phaseBegan = CACurrentMediaTime()
        status = "Countdown"
    }

    func cancel() {
        running = false
        phase = .idle
        status = "Abgebrochen"
        buffer = []
    }

    func tick(hands: [TrackedHand], now: TimeInterval) {
        guard running, phase != .done, phase != .idle else { return }
        let elapsed = now - phaseBegan
        switch phase {
        case .countdown:
            let left = max(0, Self.countdownSec - elapsed)
            countdown = Int(ceil(left))
            status = "\(current.titleDE)  ·  Wiederholung \(repeatIndex + 1)/\(Self.repeats)"
            if elapsed >= Self.countdownSec {
                phase = .capture
                phaseBegan = now
                buffer = []
                captureLeft = Self.captureSec
            }
        case .capture:
            captureLeft = max(0, Self.captureSec - elapsed)
            status = "AUFNAHME  \(current.titleDE)"
            append(hands: hands, t: elapsed)
            if elapsed >= Self.captureSec {
                commitTrial()
                phase = .rest
                phaseBegan = now
            }
        case .rest:
            status = lastEvidence
            if elapsed >= Self.restSec {
                advance()
            }
        default:
            break
        }
    }

    func markdown() -> String {
        var lines: [String] = [
            "# Helios Aktionskalibrierung",
            "",
            "Version 1.6.20 · \(Self.repeats)× je Geste · \(isoFmt.string(from: Date()))",
            "",
            "Protokoll für Grok: so wirft, zieht, wischt und tippt diese Person. Jede Geste einzeln, Timer, drei Wiederholungen.",
            ""
        ]
        for action in Self.catalog {
            let mine = trials.filter { $0.action == action.id }.sorted { $0.repeatIndex < $1.repeatIndex }
            lines.append("## \(action.titleDE)")
            lines.append("")
            lines.append(action.hint)
            lines.append("")
            if mine.isEmpty {
                lines.append("_keine Aufnahme_")
                lines.append("")
                continue
            }
            for t in mine {
                let mark = t.detected ? "erkannt" : "schwach / anders"
                lines.append("### Wiederholung \(t.repeatIndex) · \(mark)")
                lines.append("- Dauer: \(t.durationMs) ms")
                lines.append("- Evidenz: \(t.evidence)")
                let poses = t.samples.map(\.pose)
                let compact = poseRun(poses)
                if !compact.isEmpty {
                    lines.append("- Pose-Folge: \(compact)")
                }
                lines.append("")
            }
        }
        let ok = trials.filter(\.detected).count
        lines.append("## Summe")
        lines.append("")
        lines.append("\(ok)/\(trials.count) Wiederholungen vom Klassifikator bestätigt. Die Spuren zählen trotzdem — so sieht der Wurf aus.")
        lines.append("")
        return lines.joined(separator: "\n")
    }

    func jsonData() throws -> Data {
        let payload: [String: Any] = [
            "helios": "1.6.20",
            "protocol": "action-calib-v1",
            "repeats": Self.repeats,
            "recordedAt": isoFmt.string(from: Date()),
            "trials": trials.map { trialDict($0) }
        ]
        return try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
    }

    func copyForGrok() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(markdown(), forType: .string)
    }

    func exportFiles() {
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let panel = NSSavePanel()
        panel.title = "Aktionskalibrierung für Grok"
        panel.nameFieldStringValue = "Helios-Aktionskalibrierung-\(stamp)"
        panel.canCreateDirectories = true
        panel.prompt = "Exportieren"
        panel.message = "Ordner: Markdown zum Einfügen in Grok + JSON der Spuren."
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            try markdown().write(to: url.appendingPathComponent("protokoll.md"), atomically: true, encoding: .utf8)
            try jsonData().write(to: url.appendingPathComponent("spuren.json"))
            NSWorkspace.shared.open(url)
        } catch {
            let a = NSAlert(error: error)
            a.messageText = "Export fehlgeschlagen"
            a.runModal()
        }
    }

    private func append(hands: [TrackedHand], t: TimeInterval) {
        for h in hands {
            buffer.append(DrillSample(
                t: (t * 1000).rounded() / 1000,
                side: h.sideDE,
                pose: h.pose.rawValue,
                poseProb: h.poseProb,
                pinch: h.pinchClosedness,
                palmX: Double(h.palm.x),
                palmY: Double(h.palm.y),
                open: h.openScore
            ))
        }
    }

    private func commitTrial() {
        let action = current
        let evid = Self.score(action: action.id, samples: buffer)
        let trial = DrillTrial(
            action: action.id,
            titleDE: action.titleDE,
            repeatIndex: repeatIndex + 1,
            iso: isoFmt.string(from: Date()),
            durationMs: Int(Self.captureSec * 1000),
            detected: evid.ok,
            evidence: evid.text,
            samples: downsample(buffer, max: 48)
        )
        trials.append(trial)
        lastEvidence = evid.ok ? "✓ \(action.titleDE) · \(evid.text)" : "○ \(action.titleDE) · \(evid.text)"
        buffer = []
    }

    static func score(action: String, samples: [DrillSample]) -> (ok: Bool, text: String) {
        let poses = samples.map(\.pose)
        let sides = samples.map(\.side)
        let pinchMax = samples.map(\.pinch).max() ?? 0
        let openMax = samples.map(\.open).max() ?? 0
        let two = Set(samples.map(\.side)).count >= 2
        let d = GestureMath.trailDelta(
            xs: samples.map(\.palmX),
            ys: samples.map(\.palmY),
            dt: max(0.05, (samples.last?.t ?? 0) - (samples.first?.t ?? 0))
        )
        return GestureMath.drillMatch(
            action: action,
            poses: poses,
            sides: sides,
            pinchMax: pinchMax,
            dx: d.dx,
            dy: d.dy,
            openMax: openMax,
            twoHands: two
        )
    }

    private func advance() {
        if repeatIndex + 1 < Self.repeats {
            repeatIndex += 1
            phase = .countdown
            phaseBegan = CACurrentMediaTime()
            countdown = 3
            return
        }
        if actionIndex + 1 < Self.catalog.count {
            actionIndex += 1
            repeatIndex = 0
            phase = .countdown
            phaseBegan = CACurrentMediaTime()
            countdown = 3
            return
        }
        phase = .done
        running = false
        status = "Fertig — \(trials.filter(\.detected).count)/\(trials.count) erkannt. Für Grok kopieren."
    }

    private func downsample(_ src: [DrillSample], max: Int) -> [DrillSample] {
        guard src.count > max, max > 1 else { return src }
        let step = Double(src.count - 1) / Double(max - 1)
        return (0..<max).map { src[min(src.count - 1, Int((Double($0) * step).rounded()))] }
    }

    private func poseRun(_ poses: [String]) -> String {
        var out: [String] = []
        var last = ""
        var n = 0
        for p in poses {
            if p == last { n += 1; continue }
            if !last.isEmpty { out.append("\(last)×\(n)") }
            last = p
            n = 1
        }
        if !last.isEmpty { out.append("\(last)×\(n)") }
        return out.joined(separator: " → ")
    }

    private func trialDict(_ t: DrillTrial) -> [String: Any] {
        [
            "action": t.action,
            "titleDE": t.titleDE,
            "repeat": t.repeatIndex,
            "iso": t.iso,
            "durationMs": t.durationMs,
            "detected": t.detected,
            "evidence": t.evidence,
            "samples": t.samples.map {
                [
                    "t": $0.t,
                    "side": $0.side,
                    "pose": $0.pose,
                    "poseProb": $0.poseProb,
                    "pinch": $0.pinch,
                    "palmX": $0.palmX,
                    "palmY": $0.palmY,
                    "open": $0.open
                ] as [String: Any]
            }
        ]
    }
}

import Foundation

enum ProtocolKind: String {
    case recognized
    case executed
    case failed
    case blocked
    case info

    var labelDE: String {
        switch self {
        case .recognized: return "ERKANNT"
        case .executed: return "AUSGEFÜHRT"
        case .failed: return "NICHT AUSGEFÜHRT"
        case .blocked: return "BLOCKIERT"
        case .info: return "INFO"
        }
    }
}

struct AuditEntry: Identifiable {
    let id = UUID()
    let at: Date
    let kind: ProtocolKind
    let text: String
    let confidence: Int?
}

@MainActor
final class AuditLog: ObservableObject {
    @Published private(set) var entries: [AuditEntry] = []
    private let limit = 2500

    func record(_ text: String, kind: ProtocolKind = .info, confidence: Int? = nil) {
        entries.append(AuditEntry(at: Date(), kind: kind, text: text, confidence: confidence))
        if entries.count > limit {
            entries.removeFirst(entries.count - limit)
        }
    }

    func clear() { entries.removeAll() }

    func plainText() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        var lines: [String] = [
            "Helios Protokoll  \(ISO8601DateFormatter().string(from: Date()))",
            String(repeating: "-", count: 72)
        ]
        for e in entries {
            let conf = e.confidence.map { "  \($0)%" } ?? ""
            let kind = e.kind.labelDE.padding(toLength: 16, withPad: " ", startingAt: 0)
            lines.append("\(f.string(from: e.at))  \(kind)  \(e.text)\(conf)")
        }
        return lines.joined(separator: "\n") + "\n"
    }

    func jsonData() throws -> Data {
        let f = ISO8601DateFormatter()
        let rows: [[String: Any]] = entries.map { e in
            var row: [String: Any] = [
                "at": f.string(from: e.at),
                "kind": e.kind.rawValue,
                "kindDE": e.kind.labelDE,
                "text": e.text
            ]
            if let c = e.confidence { row["confidence"] = c }
            return row
        }
        return try JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys])
    }
}

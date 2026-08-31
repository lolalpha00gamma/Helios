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
final class AuditLog {
    private(set) var entries: [AuditEntry] = []
    private let limit = 200

    func record(_ text: String, kind: ProtocolKind = .info, confidence: Int? = nil) {
        entries.insert(AuditEntry(at: Date(), kind: kind, text: text, confidence: confidence), at: 0)
        if entries.count > limit {
            entries.removeLast(entries.count - limit)
        }
    }

    func clear() { entries.removeAll() }
}

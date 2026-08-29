import Foundation

struct AuditEntry: Identifiable {
    let id = UUID()
    let at: Date
    let text: String
}

@MainActor
final class AuditLog {
    private(set) var entries: [AuditEntry] = []
    private let limit = 80

    func record(_ text: String) {
        entries.insert(AuditEntry(at: Date(), text: text), at: 0)
        if entries.count > limit {
            entries.removeLast(entries.count - limit)
        }
    }
}

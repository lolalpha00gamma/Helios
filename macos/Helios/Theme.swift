import SwiftUI

enum HeliosTheme {
    static let cyan = Color(red: 0.31, green: 0.90, blue: 1.00)
    static let amber = Color(red: 1.00, green: 0.72, blue: 0.22)
    static let void = Color(red: 0.02, green: 0.05, blue: 0.09)
    static let panel = Color(red: 0.04, green: 0.08, blue: 0.14).opacity(0.82)
    static let danger = Color(red: 1.00, green: 0.32, blue: 0.28)
    static let ok = Color(red: 0.35, green: 0.95, blue: 0.55)

    static let mono: Font = .system(size: 11, weight: .medium, design: .monospaced)
    static let title: Font = .system(size: 13, weight: .semibold, design: .default)
}

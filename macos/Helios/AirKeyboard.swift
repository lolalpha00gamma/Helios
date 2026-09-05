import AppKit
import CoreGraphics
import Foundation

struct AirKeyHit: Equatable, Identifiable {
    var id: String
    var label: String
    var code: UInt16
    var kind: Kind
    var frame: CGRect

    enum Kind: String {
        case char, shift, delete, space, enter, close, cmd
    }
}

enum AirLayout {
    nonisolated(unsafe) private static var cache: (rect: CGRect, hits: [AirKeyHit])?
    static let rows: [[(id: String, label: String, code: UInt16, kind: AirKeyHit.Kind)]] = [
        [
            ("1", "1", 0x12, .char), ("2", "2", 0x13, .char), ("3", "3", 0x14, .char),
            ("4", "4", 0x15, .char), ("5", "5", 0x17, .char), ("6", "6", 0x16, .char),
            ("7", "7", 0x1A, .char), ("8", "8", 0x1C, .char), ("9", "9", 0x19, .char),
            ("0", "0", 0x1D, .char), ("ss", "ß", 0x1B, .char), ("del", "⌫", 0x33, .delete)
        ],
        [
            ("q", "Q", 0x0C, .char), ("w", "W", 0x0D, .char), ("e", "E", 0x0E, .char),
            ("r", "R", 0x0F, .char), ("t", "T", 0x11, .char), ("z", "Z", 0x06, .char),
            ("u", "U", 0x20, .char), ("i", "I", 0x22, .char), ("o", "O", 0x1F, .char),
            ("p", "P", 0x23, .char), ("ue", "Ü", 0x21, .char)
        ],
        [
            ("a", "A", 0x00, .char), ("s", "S", 0x01, .char), ("d", "D", 0x02, .char),
            ("f", "F", 0x03, .char), ("g", "G", 0x05, .char), ("h", "H", 0x04, .char),
            ("j", "J", 0x26, .char), ("k", "K", 0x28, .char), ("l", "L", 0x25, .char),
            ("oe", "Ö", 0x29, .char), ("ae", "Ä", 0x27, .char), ("ret", "⏎", 0x24, .enter)
        ],
        [
            ("shift", "⇧", 0x38, .shift), ("y", "Y", 0x10, .char), ("x", "X", 0x07, .char),
            ("c", "C", 0x08, .char), ("v", "V", 0x09, .char), ("b", "B", 0x0B, .char),
            ("n", "N", 0x2D, .char), ("m", "M", 0x2E, .char), ("kom", ",", 0x2B, .char),
            ("dot", ".", 0x2F, .char), ("cls", "✕", 0x35, .close)
        ],
        [
            ("cmd", "⌘", 0x37, .cmd), ("spc", "Leer", 0x31, .space)
        ]
    ]

    static func hits(inQuartz screen: CGRect) -> [AirKeyHit] {
        if let c = cache, c.rect == screen { return c.hits }
        let margin: CGFloat = 48
        let boardW = min(screen.width - margin * 2, 1280)
        let boardH: CGFloat = 340
        let origin = CGPoint(
            x: screen.minX + (screen.width - boardW) / 2,
            y: screen.maxY - boardH - 48
        )
        let board = CGRect(x: origin.x, y: origin.y, width: boardW, height: boardH)
        var out: [AirKeyHit] = []
        let rowH = (board.height - 18) / CGFloat(rows.count)
        let gap: CGFloat = 10
        for (ri, row) in rows.enumerated() {
            let weights: [CGFloat] = row.map { $0.kind == .space ? 5 : ($0.kind == .shift || $0.kind == .enter || $0.kind == .delete ? 1.45 : 1) }
            let sum = weights.reduce(0, +)
            var x = board.minX + 10
            let y = board.minY + 8 + CGFloat(ri) * rowH
            let inner = board.width - 20 - gap * CGFloat(max(0, row.count - 1))
            for (i, spec) in row.enumerated() {
                let w = inner * (weights[i] / sum)
                let frame = CGRect(x: x, y: y, width: w, height: rowH - gap)
                out.append(AirKeyHit(
                    id: spec.id,
                    label: spec.label,
                    code: spec.code,
                    kind: spec.kind,
                    frame: frame
                ))
                x += w + gap
            }
        }
        cache = (screen, out)
        return out
    }

    static func hit(at p: CGPoint, keys: [AirKeyHit]) -> AirKeyHit? {
        keys.first { $0.frame.insetBy(dx: -4, dy: -4).contains(p) }
    }
}

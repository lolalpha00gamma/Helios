import AppKit
import CoreGraphics
import Foundation

struct XY: Codable, Equatable {
    var x: CGFloat
    var y: CGFloat
    var point: CGPoint { CGPoint(x: x, y: y) }
    init(_ p: CGPoint) { x = p.x; y = p.y }
    init(x: CGFloat, y: CGFloat) { self.x = x; self.y = y }
}

enum CalibCorner: Int, CaseIterable, Codable {
    case topLeft, topRight, bottomRight, bottomLeft

    var titleDE: String {
        switch self {
        case .topLeft: return "oben links"
        case .topRight: return "oben rechts"
        case .bottomRight: return "unten rechts"
        case .bottomLeft: return "unten links"
        }
    }

    var hintDE: String {
        "Halte die Hand ruhig dort, wo für dich die Ecke \(titleDE) ist. Pinch bestätigt."
    }
}

/// Homographie Kamera-Handfläche → Bildschirm (Quartz). Nur Mapping, keine Erkennung.
struct SpaceMap: Codable {
    var palms: [XY]

    var isReady: Bool { palms.count == 4 }

    static func screenCorners() -> [CGPoint] {
        let q = ScreenGeometry.quartzRect(fromCocoa: ScreenGeometry.cocoaUnion)
        return [
            CGPoint(x: q.minX + 8, y: q.minY + 8),
            CGPoint(x: q.maxX - 8, y: q.minY + 8),
            CGPoint(x: q.maxX - 8, y: q.maxY - 8),
            CGPoint(x: q.minX + 8, y: q.maxY - 8)
        ]
    }

    static func linear(_ palm: CGPoint) -> CGPoint {
        let q = ScreenGeometry.quartzRect(fromCocoa: ScreenGeometry.cocoaUnion)
        let u = min(max((palm.x - 0.10) / 0.80, 0), 1)
        let v = min(max((palm.y - 0.10) / 0.80, 0), 1)
        return CGPoint(x: q.minX + u * q.width, y: q.minY + (1 - v) * q.height)
    }

    func apply(_ palm: CGPoint) -> CGPoint {
        guard isReady, let H = homography() else { return Self.linear(palm) }
        let w = H[6] * palm.x + H[7] * palm.y + H[8]
        guard abs(w) > 1e-8 else { return Self.linear(palm) }
        let p = CGPoint(
            x: (H[0] * palm.x + H[1] * palm.y + H[2]) / w,
            y: (H[3] * palm.x + H[4] * palm.y + H[5]) / w
        )
        return ScreenGeometry.clampQuartz(p)
    }

    func homography() -> [CGFloat]? {
        guard palms.count == 4 else { return nil }
        return SpaceMap.homography(from: palms.map(\.point), to: Self.screenCorners())
    }

    /// 4 Punktpaare, h22 = 1, 8×8 Gauss.
    static func homography(from src: [CGPoint], to dst: [CGPoint]) -> [CGFloat]? {
        guard src.count == 4, dst.count == 4 else { return nil }
        var A = Array(repeating: Array(repeating: 0.0 as CGFloat, count: 8), count: 8)
        var b = Array(repeating: 0.0 as CGFloat, count: 8)
        for i in 0..<4 {
            let x = src[i].x, y = src[i].y
            let u = dst[i].x, v = dst[i].y
            let r = i * 2
            A[r] = [x, y, 1, 0, 0, 0, -u * x, -u * y]
            b[r] = u
            A[r + 1] = [0, 0, 0, x, y, 1, -v * x, -v * y]
            b[r + 1] = v
        }
        guard var h8 = gauss(A, b) else { return nil }
        h8.append(1)
        return h8
    }

    static func gauss(_ aIn: [[CGFloat]], _ bIn: [CGFloat]) -> [CGFloat]? {
        let n = bIn.count
        var a = aIn
        var b = bIn
        for i in 0..<n {
            var piv = i
            var best = abs(a[i][i])
            for r in (i + 1)..<n where abs(a[r][i]) > best {
                best = abs(a[r][i])
                piv = r
            }
            if best < 1e-12 { return nil }
            if piv != i {
                a.swapAt(i, piv)
                b.swapAt(i, piv)
            }
            let diag = a[i][i]
            for c in i..<n { a[i][c] /= diag }
            b[i] /= diag
            for r in 0..<n where r != i {
                let f = a[r][i]
                if f == 0 { continue }
                for c in i..<n { a[r][c] -= f * a[i][c] }
                b[r] -= f * b[i]
            }
        }
        return b
    }

    static func load() -> SpaceMap? {
        guard let data = UserDefaults.standard.data(forKey: "helios.spaceMap") else { return nil }
        return try? JSONDecoder().decode(SpaceMap.self, from: data)
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "helios.spaceMap")
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: "helios.spaceMap")
    }
}

@MainActor
final class CalibrationSession {
    private(set) var active = false
    private(set) var corner: CalibCorner = .topLeft
    private(set) var hold: CGFloat = 0
    private(set) var cursorGap: CGFloat = 0
    private(set) var samples: [CalibCorner: CGPoint] = [:]
    private var lastPalm: CGPoint?
    private var lastT: TimeInterval = 0

    var progress: CGFloat { hold / 0.7 }
    var remaining: Int { 4 - samples.count }

    func start() {
        active = true
        corner = .topLeft
        hold = 0
        samples.removeAll()
        lastPalm = nil
    }

    func cancel() {
        active = false
        hold = 0
    }

    func targetQuartz() -> CGPoint {
        SpaceMap.screenCorners()[corner.rawValue]
    }

    /// Gibt die fertige Karte zurück, sobald 4 Ecken liegen.
    func feed(palm: CGPoint, now: TimeInterval, confirm: Bool) -> SpaceMap? {
        guard active else { return nil }
        let dt = lastT == 0 ? 0 : min(now - lastT, 0.08)
        lastT = now
        let moved = lastPalm.map { hypot(palm.x - $0.x, palm.y - $0.y) } ?? 1
        lastPalm = palm
        let target = targetQuartz()
        let cursor = ScreenGeometry.quartz(fromCocoa: NSEvent.mouseLocation)
        cursorGap = hypot(cursor.x - target.x, cursor.y - target.y)
        if moved < 0.014 {
            hold += CGFloat(dt)
        } else {
            hold = 0
        }
        if (confirm && hold >= 0.2) || hold >= 0.7 {
            samples[corner] = palm
            hold = 0
            lastPalm = nil
            if let next = CalibCorner(rawValue: corner.rawValue + 1) {
                corner = next
            } else {
                let ordered: [CalibCorner] = [.topLeft, .topRight, .bottomRight, .bottomLeft]
                let palms = ordered.compactMap { samples[$0] }.map(XY.init)
                guard palms.count == 4 else { return nil }
                let map = SpaceMap(palms: palms)
                map.save()
                active = false
                return map
            }
        }
        return nil
    }
}

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

enum CalibSpot: String, CaseIterable, Codable {
    case topLeft, topRight, bottomRight, bottomLeft
    case topMid, midRight, bottomMid, midLeft, center

    static let four: [CalibSpot] = [.topLeft, .topRight, .bottomRight, .bottomLeft]
    static let nine: [CalibSpot] = four + [.topMid, .midRight, .bottomMid, .midLeft, .center]

    var titleDE: String {
        switch self {
        case .topLeft: return "oben links"
        case .topRight: return "oben rechts"
        case .bottomRight: return "unten rechts"
        case .bottomLeft: return "unten links"
        case .topMid: return "oben Mitte"
        case .midRight: return "rechts Mitte"
        case .bottomMid: return "unten Mitte"
        case .midLeft: return "links Mitte"
        case .center: return "Mitte"
        }
    }

    /// Index ins 3×3-Gitter (Zeile von oben, Quartz: y oben klein).
    var gridIndex: Int {
        switch self {
        case .topLeft: return 0
        case .topMid: return 1
        case .topRight: return 2
        case .midLeft: return 3
        case .center: return 4
        case .midRight: return 5
        case .bottomLeft: return 6
        case .bottomMid: return 7
        case .bottomRight: return 8
        }
    }

    var hintDE: String {
        "Halte die Hand ruhig dort, wo für dich \(titleDE) ist. Pinch bestätigt."
    }
}

enum CalibCorner: Int, CaseIterable, Codable {
    case topLeft, topRight, bottomRight, bottomLeft

    var titleDE: String { CalibSpot.four[rawValue].titleDE }
    var hintDE: String { CalibSpot.four[rawValue].hintDE }
    var spot: CalibSpot { CalibSpot.four[rawValue] }
}

/// Homographie Kamera-Handfläche → Bildschirm (Quartz). Nur Mapping, keine Erkennung.
struct SpaceMap: Codable {
    var palms: [XY]
    var displayID: UInt32?
    /// Index ins 3×3-Gitter, parallel zu `palms`. Nil = alte Karten (4 Ecken oder 9 in Reihenfolge).
    var gridIndices: [Int]?

    var isReady: Bool { palms.count >= 4 }
    var isNinePoint: Bool { palms.count >= 9 }

    static func screen(of id: UInt32?) -> NSScreen? {
        guard let id else { return NSScreen.main }
        return NSScreen.screens.first { ScreenGeometry.displayID(of: $0) == id } ?? NSScreen.main
    }

    static func quartzField(of id: UInt32?) -> CGRect {
        if let screen = screen(of: id) {
            return ScreenGeometry.quartzRect(fromCocoa: screen.frame)
        }
        return ScreenGeometry.quartzRect(fromCocoa: ScreenGeometry.cocoaUnion)
    }

    static func screenCorners(displayID: UInt32? = nil) -> [CGPoint] {
        let q = quartzField(of: displayID)
        return [
            CGPoint(x: q.minX + 8, y: q.minY + 8),
            CGPoint(x: q.maxX - 8, y: q.minY + 8),
            CGPoint(x: q.maxX - 8, y: q.maxY - 8),
            CGPoint(x: q.minX + 8, y: q.maxY - 8)
        ]
    }

    /// 3×3-Gitter, Zeile oben → unten, links → rechts. Quartz-Ursprung unten-links.
    static func screenGrid(displayID: UInt32? = nil) -> [CGPoint] {
        let q = quartzField(of: displayID)
        let xs: [CGFloat] = [q.minX + 8, q.midX, q.maxX - 8]
        let ys: [CGFloat] = [q.minY + 8, q.midY, q.maxY - 8]
        var pts: [CGPoint] = []
        pts.reserveCapacity(9)
        for row in 0..<3 {
            for col in 0..<3 {
                pts.append(CGPoint(x: xs[col], y: ys[row]))
            }
        }
        return pts
    }

    static func linear(_ palm: CGPoint) -> CGPoint {
        let q = ScreenGeometry.quartzRect(fromCocoa: ScreenGeometry.cocoaUnion)
        let u = min(max((palm.x - 0.10) / 0.80, 0), 1)
        let v = min(max((palm.y - 0.10) / 0.80, 0), 1)
        return CGPoint(x: q.minX + u * q.width, y: q.minY + (1 - v) * q.height)
    }

    func destinations() -> [CGPoint] {
        let grid = Self.screenGrid(displayID: displayID)
        if let idx = gridIndices, idx.count == palms.count, !idx.isEmpty {
            return idx.map { grid[min(max(0, $0), 8)] }
        }
        if palms.count >= 9 {
            return Self.screenGrid(displayID: displayID)
        }
        return Self.screenCorners(displayID: displayID)
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

    /// Ungeklammertes Projekt — für RMSE, nicht für den Cursor.
    static func project(_ H: [CGFloat], _ palm: CGPoint) -> CGPoint {
        let w = H[6] * palm.x + H[7] * palm.y + H[8]
        guard abs(w) > 1e-8 else { return palm }
        return CGPoint(
            x: (H[0] * palm.x + H[1] * palm.y + H[2]) / w,
            y: (H[3] * palm.x + H[4] * palm.y + H[5]) / w
        )
    }

    /// Reprojektionsfehler in Pixeln. > 12 px: Mitte nochmal.
    func rmse() -> CGFloat? {
        guard let H = homography() else { return nil }
        let src = palms.map(\.point)
        let dst = destinations()
        let n = min(src.count, dst.count)
        guard n >= 4 else { return nil }
        var acc: CGFloat = 0
        for i in 0..<n {
            let p = Self.project(H, src[i])
            let e = hypot(p.x - dst[i].x, p.y - dst[i].y)
            acc += e * e
        }
        return sqrt(acc / CGFloat(n))
    }

    /// 0 innen (relativ), 1 in den äußeren 15 % der Kalibrier-Quad (absolut).
    func edgeWeight(_ palm: CGPoint) -> CGFloat {
        guard palms.count >= 4 else { return 1 }
        let xs = palms.map(\.x)
        let ys = palms.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max() else { return 1 }
        let w = max(1e-4, maxX - minX)
        let h = max(1e-4, maxY - minY)
        let u = (palm.x - minX) / w
        let v = (palm.y - minY) / h
        let m = min(u, v, 1 - u, 1 - v)
        if m >= 0.15 { return 0 }
        if m <= 0 { return 1 }
        return 1 - m / 0.15
    }

    func homography() -> [CGFloat]? {
        guard palms.count >= 4 else { return nil }
        let src = palms.map(\.point)
        let dst = destinations()
        let n = min(src.count, dst.count)
        return SpaceMap.homography(from: Array(src.prefix(n)), to: Array(dst.prefix(n)))
    }

    /// 4 Punktpaare: h22 = 1, 8×8 Gauss. ≥5 Punkte: DLT least squares (AtA).
    static func homography(from src: [CGPoint], to dst: [CGPoint]) -> [CGFloat]? {
        let n = min(src.count, dst.count)
        guard n >= 4 else { return nil }
        if n == 4 {
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
        return homographyLeastSquares(from: Array(src.prefix(n)), to: Array(dst.prefix(n)))
    }

    static func homographyLeastSquares(from src: [CGPoint], to dst: [CGPoint]) -> [CGFloat]? {
        let n = min(src.count, dst.count)
        guard n >= 4 else { return nil }
        let rows = 2 * n
        var A = Array(repeating: Array(repeating: 0.0 as CGFloat, count: 8), count: rows)
        var b = Array(repeating: 0.0 as CGFloat, count: rows)
        for i in 0..<n {
            let x = src[i].x, y = src[i].y
            let u = dst[i].x, v = dst[i].y
            let r = i * 2
            A[r] = [x, y, 1, 0, 0, 0, -u * x, -u * y]
            b[r] = u
            A[r + 1] = [0, 0, 0, x, y, 1, -v * x, -v * y]
            b[r + 1] = v
        }
        var AtA = Array(repeating: Array(repeating: 0.0 as CGFloat, count: 8), count: 8)
        var Atb = Array(repeating: 0.0 as CGFloat, count: 8)
        for i in 0..<8 {
            for j in 0..<8 {
                var s: CGFloat = 0
                for r in 0..<rows { s += A[r][i] * A[r][j] }
                AtA[i][j] = s
            }
            var s: CGFloat = 0
            for r in 0..<rows { s += A[r][i] * b[r] }
            Atb[i] = s
        }
        guard var h8 = gauss(AtA, Atb) else { return nil }
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

    static func storageKey(displayID: UInt32?) -> String {
        let id = displayID ?? NSScreen.main.map { ScreenGeometry.displayID(of: $0) } ?? 0
        return "helios.spaceMap.\(id)"
    }

    static func load(displayID: UInt32? = nil) -> SpaceMap? {
        let id = displayID ?? NSScreen.main.map { ScreenGeometry.displayID(of: $0) }
        if let id,
           let data = UserDefaults.standard.data(forKey: storageKey(displayID: id)),
           let map = try? JSONDecoder().decode(SpaceMap.self, from: data)
        {
            return map
        }
        // Alte 1.6.3-Maps ohne Display-Key.
        if let data = UserDefaults.standard.data(forKey: "helios.spaceMap"),
           let map = try? JSONDecoder().decode(SpaceMap.self, from: data)
        {
            return map
        }
        return nil
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey(displayID: displayID))
        if displayID == nil || displayID == NSScreen.main.map({ ScreenGeometry.displayID(of: $0) }) {
            UserDefaults.standard.set(data, forKey: "helios.spaceMap")
        }
    }

    static func clear(displayID: UInt32? = nil) {
        UserDefaults.standard.removeObject(forKey: storageKey(displayID: displayID))
        if displayID == nil {
            UserDefaults.standard.removeObject(forKey: "helios.spaceMap")
            for screen in NSScreen.screens {
                UserDefaults.standard.removeObject(forKey: storageKey(displayID: ScreenGeometry.displayID(of: screen)))
            }
        }
    }

    static func isCalibrated(displayID: UInt32) -> Bool {
        load(displayID: displayID)?.isReady == true
    }

    static func calibratedIDs() -> [UInt32] {
        NSScreen.screens.compactMap { screen in
            let id = ScreenGeometry.displayID(of: screen)
            return isCalibrated(displayID: id) ? id : nil
        }
    }
}

@MainActor
final class CalibrationSession {
    private(set) var active = false
    private(set) var spot: CalibSpot = .topLeft
    private(set) var hold: CGFloat = 0
    private(set) var cursorGap: CGFloat = 0
    private(set) var samples: [CalibSpot: CGPoint] = [:]
    private(set) var ninePoint = true
    private(set) var displayID: UInt32?
    private var sequence: [CalibSpot] = CalibSpot.nine
    private var seqIndex = 0
    private var lastPalm: CGPoint?
    private var lastT: TimeInterval = 0
    private var lastCapture: TimeInterval = 0
    private var needRelease = false
    private var needMove = false
    private(set) var hint = "Pinzette an der Ecke halten"
    private(set) var rejected = false
    private(set) var skipped: Set<CalibSpot> = []

    var progress: CGFloat { min(1, hold / 0.9) }
    var remaining: Int { max(0, sequence.count - samples.count - skipped.count) }
    var totalSpots: Int { sequence.count }
    var corner: CalibCorner {
        switch spot {
        case .topLeft: return .topLeft
        case .topRight: return .topRight
        case .bottomRight: return .bottomRight
        default: return .bottomLeft
        }
    }

    func start(ninePoint: Bool = true, displayID: UInt32? = nil) {
        active = true
        self.ninePoint = ninePoint
        self.displayID = displayID ?? NSScreen.main.map { ScreenGeometry.displayID(of: $0) }
        sequence = ninePoint ? CalibSpot.nine : CalibSpot.four
        seqIndex = 0
        spot = sequence[0]
        hold = 0
        samples.removeAll()
        skipped.removeAll()
        lastPalm = nil
        lastCapture = 0
        needRelease = false
        needMove = false
        rejected = false
        lastT = 0
        hint = "Punkt \(spot.titleDE): Hand hin, Pinzette 1 s halten"
    }

    func cancel() {
        active = false
        hold = 0
    }

    /// Punkt hinter dem Deckel / außerhalb der Kamera: überspringen, Homographie aus dem Rest.
    func skip() {
        guard active else { return }
        skipped.insert(spot)
        hold = 0
        lastPalm = nil
        needRelease = false
        needMove = false
        rejected = false
        hint = "Übersprungen: \(spot.titleDE)"
        _ = advanceOrFinish()
    }

    func liveRMSE() -> CGFloat? {
        guard samples.count >= 4 else { return nil }
        var src: [CGPoint] = []
        var dst: [CGPoint] = []
        let grid = SpaceMap.screenGrid(displayID: displayID)
        let corners = SpaceMap.screenCorners(displayID: displayID)
        for (spot, palm) in samples {
            src.append(palm)
            if ninePoint {
                dst.append(grid[min(max(0, spot.gridIndex), 8)])
            } else {
                switch spot {
                case .topLeft: dst.append(corners[0])
                case .topRight: dst.append(corners[1])
                case .bottomRight: dst.append(corners[2])
                default: dst.append(corners[3])
                }
            }
        }
        guard let H = SpaceMap.homography(from: src, to: dst) else { return nil }
        var acc: CGFloat = 0
        for i in src.indices {
            let p = SpaceMap.project(H, src[i])
            let e = hypot(p.x - dst[i].x, p.y - dst[i].y)
            acc += e * e
        }
        return sqrt(acc / CGFloat(src.count))
    }

    func targetQuartz() -> CGPoint {
        if ninePoint {
            let grid = SpaceMap.screenGrid(displayID: displayID)
            return grid[spot.gridIndex]
        }
        let corners = SpaceMap.screenCorners(displayID: displayID)
        switch spot {
        case .topLeft: return corners[0]
        case .topRight: return corners[1]
        case .bottomRight: return corners[2]
        default: return corners[3]
        }
    }

    /// Nur Pinzette. Nach jedem Treffer: Hand öffnen und zum nächsten Punkt gehen.
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

        if needRelease {
            hold = 0
            hint = "Hand öffnen, dann nach \(spot.titleDE)"
            if !confirm {
                needRelease = false
                needMove = true
            }
            return nil
        }
        if needMove {
            if let last = lastSample(), hypot(palm.x - last.x, palm.y - last.y) < 0.16 {
                hold = 0
                hint = "Noch zu nah — weiter nach \(spot.titleDE)"
                return nil
            }
            needMove = false
        }
        let minSep: CGFloat = ninePoint ? 0.10 : 0.18
        if samples.values.contains(where: { hypot(palm.x - $0.x, palm.y - $0.y) < minSep }) {
            hold = 0
            hint = "Zu nah an einem fertigen Punkt — weiter nach außen"
            rejected = true
            return nil
        }
        if !confirm {
            hint = "Pinzette an \(spot.titleDE) halten (\(remaining) offen)"
            return nil
        }
        if hold < 0.9 {
            hint = "Pinzette halten … \(Int(min(100, hold / 0.9 * 100))) %"
            return nil
        }
        if lastCapture > 0, now - lastCapture < 1.8 {
            hint = "Kurz warten …"
            return nil
        }

        rejected = false
        samples[spot] = palm
        hold = 0
        lastPalm = nil
        lastCapture = now
        needRelease = true
        return advanceOrFinish()
    }

    @discardableResult
    private func advanceOrFinish() -> SpaceMap? {
        if seqIndex + 1 < sequence.count {
            seqIndex += 1
            spot = sequence[seqIndex]
            while skipped.contains(spot), seqIndex + 1 < sequence.count {
                seqIndex += 1
                spot = sequence[seqIndex]
            }
            if skipped.contains(spot) {
                return finishMap()
            }
            hint = samples.isEmpty
                ? "Punkt \(spot.titleDE): Hand hin, Pinzette 1 s halten"
                : "OK. Öffnen und nach \(spot.titleDE)"
            if let err = liveRMSE() {
                hint += String(format: " · live RMSE %.0f px", err)
            }
            return nil
        }
        return finishMap()
    }

    private func finishMap() -> SpaceMap? {
        let ordered = (ninePoint ? CalibSpot.allCases : CalibSpot.four)
            .sorted { $0.gridIndex < $1.gridIndex }
        var pts: [XY] = []
        var idx: [Int] = []
        for s in ordered {
            if let p = samples[s] {
                pts.append(XY(p))
                idx.append(s.gridIndex)
            }
        }
        if pts.count < 4 {
            hint = "Mindestens 4 Punkte, \(pts.count) da. Ecke nachholen."
            rejected = true
            active = true
            return nil
        }
        if ninePoint, pts.count >= 4 {
            let corners = [CalibSpot.topLeft, .topRight, .bottomRight, .bottomLeft]
            let areaPts = corners.compactMap { samples[$0] }
            if areaPts.count == 4, Self.quadArea(areaPts) < 0.035 {
                samples[.center] = nil
                seqIndex = sequence.count - 1
                spot = .center
                hint = "Gitter zu klein. Mitte weiter, dann Pinzette."
                rejected = true
                return nil
            }
        } else if !ninePoint {
            let corners = CalibSpot.four.compactMap { samples[$0] }
            if corners.count == 4, Self.quadArea(corners) < 0.035 {
                samples[.bottomLeft] = nil
                seqIndex = sequence.count - 1
                spot = .bottomLeft
                hint = "Ecken zu nah. Unten links weiter außen, dann Pinzette."
                rejected = true
                return nil
            }
        }
        let map = SpaceMap(palms: pts, displayID: displayID, gridIndices: idx)
        map.save()
        active = false
        if let err = map.rmse(), err > 12 {
            hint = String(format: "Fertig · RMSE %.0f px — Mitte nochmal, Cursor springt", err)
            rejected = true
        } else if let err = map.rmse() {
            let skipNote = skipped.isEmpty ? "" : " · \(skipped.count) übersprungen"
            hint = String(format: "Fertig · RMSE %.0f px%@", err, skipNote)
        } else {
            hint = "Fertig"
        }
        return map
    }

    private func lastSample() -> CGPoint? {
        var i = seqIndex
        while i > 0 {
            i -= 1
            if let p = samples[sequence[i]] { return p }
        }
        return nil
    }

    private static func quadArea(_ p: [CGPoint]) -> CGFloat {
        guard p.count == 4 else { return 0 }
        var a: CGFloat = 0
        for i in 0..<4 {
            let j = (i + 1) % 4
            a += p[i].x * p[j].y - p[j].x * p[i].y
        }
        return abs(a) / 2
    }
}

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
        "So weit nach \(titleDE) wie die Hand im Kamerabild bleibt. Pinzette speichert diese Reichweite als Bildschirmecke."
    }
}

/// Homographie Kamera-Handfläche → Bildschirm (Quartz). Nur Mapping, keine Erkennung.
struct SpaceMap: Codable {
    var palms: [XY]
    var cameraID: String? = nil
    /// Quartz-Ecken zum Kalib-Zeitpunkt. Ohne das mappt homography() auf den Hauptbildschirm.
    var dest: [XY]? = nil
    /// CGDirectDisplayID als String. Laptop und Extern teilen sich sonst destBounds.
    var screenID: String? = nil

    var isReady: Bool { palms.count == 4 }
    /// Vier Punkte reichen nicht: singuläre Homographie fällt auf Relativzeiger.
    var isUsable: Bool { isReady && homography() != nil }

    /// Bounding-Box der Kalib-Ecken. Residual gegen linear(in:) sonst auf Primary.
    var destBounds: CGRect? {
        guard let dest, dest.count == 4 else { return nil }
        let xs = dest.map(\.x)
        let ys = dest.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() else {
            return nil
        }
        let w = maxX - minX
        let h = maxY - minY
        guard w > 1, h > 1 else { return nil }
        return CGRect(x: minX, y: minY, width: w, height: h)
    }


    static func screenCorners() -> [CGPoint] {
        if let s = NSScreen.main {
            return screenCorners(of: ScreenGeometry.visQuartz(of: s))
        }
        return screenCorners(of: ScreenGeometry.quartzRect(fromCocoa: ScreenGeometry.cocoaUnion))
    }

    static func screenCorners(of q: CGRect, inset: CGFloat = 8) -> [CGPoint] {
        GestureMath.screenAwareCorners(of: q, inset: inset)
    }

    static func linear(_ palm: CGPoint, in q: CGRect? = nil) -> CGPoint {
        let rect = q ?? NSScreen.main.map { ScreenGeometry.visQuartz(of: $0) }
            ?? ScreenGeometry.quartzRect(fromCocoa: ScreenGeometry.cocoaUnion)
        let u = min(max((palm.x - 0.10) / 0.80, 0), 1)
        let v = min(max((palm.y - 0.10) / 0.80, 0), 1)
        return CGPoint(x: rect.minX + u * rect.width, y: rect.minY + (1 - v) * rect.height)
    }

    func apply(_ palm: CGPoint) -> CGPoint {
        guard isReady, let H = homography() else { return Self.linear(palm) }
        let w = H[6] * palm.x + H[7] * palm.y + H[8]
        guard abs(w) > 1e-8 else { return Self.linear(palm) }
        let p = CGPoint(
            x: (H[0] * palm.x + H[1] * palm.y + H[2]) / w,
            y: (H[3] * palm.x + H[4] * palm.y + H[5]) / w
        )
        if destBounds != nil {
            return GestureMath.destClamp(p, bounds: destBounds)
        }
        return ScreenGeometry.clampQuartz(p)
    }

    func homography() -> [CGFloat]? {
        guard palms.count == 4 else { return nil }
        let dst: [CGPoint]
        if let dest, dest.count == 4 {
            dst = dest.map(\.point)
        } else {
            dst = Self.screenCorners()
        }
        return SpaceMap.homography(from: palms.map(\.point), to: dst)
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

    static func storageKey(_ cameraID: String?, screenID: String? = nil) -> String {
        GestureMath.spaceMapKey(cameraID, screenID: screenID)
    }

    static func load(cameraID: String? = nil, screenID: String? = nil) -> SpaceMap? {
        var keys: [String] = []
        if let screenID, !screenID.isEmpty {
            keys.append(storageKey(cameraID, screenID: screenID))
            keys.append(storageKey(cameraID))
        } else {
            keys.append(storageKey(cameraID))
            if cameraID == nil || cameraID?.isEmpty == true {
                keys.append("helios.spaceMap")
            }
        }
        let screenQuartz: CGRect? = {
            if let screenID, !screenID.isEmpty {
                for s in NSScreen.screens where "\(ScreenGeometry.displayID(of: s))" == screenID {
                    return ScreenGeometry.quartzBounds(of: s)
                }
            }
            return NSScreen.main.map { ScreenGeometry.quartzBounds(of: $0) }
        }()
        var seen = Set<String>()
        for key in keys where seen.insert(key).inserted {
            if let data = UserDefaults.standard.data(forKey: key),
               let map = try? JSONDecoder().decode(SpaceMap.self, from: data),
               GestureMath.mapFitsScreen(
                mapScreenID: map.screenID,
                screenID: screenID,
                dest: map.destBounds,
                screen: screenQuartz
               )
            {
                return map
            }
        }
        return nil
    }

    func save(cameraID: String? = nil, screenID: String? = nil) {
        let id = cameraID ?? self.cameraID
        let sid = screenID ?? self.screenID
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey(id, screenID: sid))
        }
    }

    static func clear(cameraID: String? = nil, screenID: String? = nil) {
        UserDefaults.standard.removeObject(forKey: storageKey(cameraID, screenID: screenID))
        if screenID == nil || screenID?.isEmpty == true {
            UserDefaults.standard.removeObject(forKey: storageKey(cameraID))
            if cameraID == nil || cameraID?.isEmpty == true {
                UserDefaults.standard.removeObject(forKey: "helios.spaceMap")
            }
        }
    }
}

@MainActor
final class CalibrationSession {
    var cameraID: String?
    private(set) var active = false
    private(set) var corner: CalibCorner = .topLeft
    private(set) var hold: CGFloat = 0
    private(set) var cursorGap: CGFloat = 0
    private(set) var samples: [CalibCorner: CGPoint] = [:]
    private var cornerGaps: [CalibCorner: CGFloat] = [:]
    private var lastPalm: CGPoint?
    private var lastMapped: CGPoint?
    private var lastT: TimeInterval = 0
    private var lastCapture: TimeInterval = 0
    private var needRelease = false
    private var needMove = false
    private(set) var hint = "Pinzette an der Ecke halten"
    private(set) var rejected = false

    var progress: CGFloat { min(1, hold / 0.9) }
    var remaining: Int { 4 - samples.count }
    /// Live-RMS der schon genommenen Ecken plus aktuelle Lücke.
    var liveRMS: CGFloat? {
        var g = CalibCorner.allCases.compactMap { cornerGaps[$0] }
        if samples[corner] == nil, cursorGap > 0 { g.append(cursorGap) }
        guard !g.isEmpty else { return nil }
        return GestureMath.mapRMS(g)
    }
    var visQuartz: CGRect {
        let q = lastMapped ?? ScreenGeometry.quartz(fromCocoa: NSEvent.mouseLocation)
        let screen = ScreenGeometry.screenContaining(quartz: q) ?? NSScreen.main
        if let screen { return ScreenGeometry.visQuartz(of: screen) }
        return ScreenGeometry.quartzRect(fromCocoa: ScreenGeometry.cocoaUnion)
    }

    func start() {
        active = true
        corner = .topLeft
        hold = 0
        samples.removeAll()
        cornerGaps.removeAll()
        lastPalm = nil
        lastMapped = nil
        lastCapture = 0
        needRelease = false
        needMove = false
        rejected = false
        lastT = 0
        hint = "Ecke oben links: so weit nach oben links wie im Bild, dann Pinzette"
    }

    func cancel() {
        active = false
        hold = 0
        lastMapped = nil
    }

    func targetQuartz() -> CGPoint {
        let visQ = visQuartz
        let corners = SpaceMap.screenCorners(of: visQ)
        return corners[min(corner.rawValue, corners.count - 1)]
    }

    /// Nur Pinzette. Nach jedem Treffer: Hand öffnen und zur nächsten Ecke gehen.
    func feed(palm: CGPoint, now: TimeInterval, confirm: Bool) -> SpaceMap? {
        guard active else { return nil }
        let dt = lastT == 0 ? 0 : min(now - lastT, GestureMath.sampleDtCap)
        lastT = now
        let moved = lastPalm.map { hypot(palm.x - $0.x, palm.y - $0.y) } ?? 1
        lastPalm = palm
        let visQ = visQuartz
        let mapped = SpaceMap.linear(palm, in: visQ)
        lastMapped = mapped
        let target = targetQuartz()
        cursorGap = hypot(mapped.x - target.x, mapped.y - target.y)
        if moved < 0.014 {
            hold += CGFloat(dt)
        } else {
            hold = 0
        }

        if needRelease {
            hold = 0
            hint = "Hand öffnen, dann nach \(corner.titleDE)"
            if !confirm {
                needRelease = false
                needMove = true
            }
            return nil
        }
        if needMove {
            if let last = lastSample(), hypot(palm.x - last.x, palm.y - last.y) < GestureMath.calibSampleSep {
                hold = 0
                hint = "Noch zu nah — weiter nach \(corner.titleDE)"
                return nil
            }
            needMove = false
        }
        if samples.values.contains(where: { hypot(palm.x - $0.x, palm.y - $0.y) < GestureMath.calibSampleSep }) {
            hold = 0
            hint = "Zu nah an einer fertigen Ecke — weiter nach außen"
            rejected = true
            return nil
        }
        if !confirm {
            hint = "So weit nach \(corner.titleDE) wie im Bild, dann Pinzette (\(remaining) offen)"
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
        samples[corner] = palm
        cornerGaps[corner] = cursorGap
        hold = 0
        lastPalm = nil
        lastCapture = now
        needRelease = true
        if let next = CalibCorner(rawValue: corner.rawValue + 1) {
            corner = next
            hint = "OK. Öffnen und nach \(next.titleDE)"
            return nil
        }
        let ordered: [CalibCorner] = [.topLeft, .topRight, .bottomRight, .bottomLeft]
        let pts = ordered.compactMap { samples[$0] }
        guard pts.count == 4, Self.quadArea(pts) >= GestureMath.calibQuadMin else {
            samples[.bottomLeft] = nil
            cornerGaps[.bottomLeft] = nil
            corner = .bottomLeft
            hint = "Ecken zu nah. Unten links weiter außen, dann Pinzette."
            rejected = true
            return nil
        }
        let dest = SpaceMap.screenCorners(of: visQ).map(XY.init)
        let sid: String?
        if let scr = ScreenGeometry.screenContaining(quartz: CGPoint(x: visQ.midX, y: visQ.midY)) {
            let n = ScreenGeometry.displayID(of: scr)
            sid = n == 0 ? nil : "\(n)"
        } else {
            sid = nil
        }
        var map = SpaceMap(palms: pts.map(XY.init), cameraID: cameraID, dest: dest, screenID: sid)
        map.save(cameraID: cameraID, screenID: sid)
        active = false
        hint = "Fertig"
        return map
    }

    private func lastSample() -> CGPoint? {
        let prev = CalibCorner(rawValue: max(0, corner.rawValue - 1)) ?? .topLeft
        return samples[prev]
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

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
        "Dein Anschlag \(titleDE) — so weit du kommst, ohne das Bild zu verlassen. Pinch bestätigt."
    }
}

/// Homographie Kamera-Handfläche → Bildschirm (Quartz). Nur Mapping, keine Erkennung.
struct SpaceMap: Codable {
    var palms: [XY]
    var displayID: UInt32 = 0
    var cameraID: String = ""

    var isReady: Bool { palms.count == 4 }

    enum CodingKeys: String, CodingKey {
        case palms, displayID, cameraID
    }

    init(palms: [XY], displayID: UInt32 = 0, cameraID: String = "") {
        self.palms = palms
        self.displayID = displayID
        self.cameraID = cameraID
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        palms = try c.decode([XY].self, forKey: .palms)
        displayID = try c.decodeIfPresent(UInt32.self, forKey: .displayID) ?? 0
        cameraID = try c.decodeIfPresent(String.self, forKey: .cameraID) ?? ""
    }

    static func screenCorners(displayID: CGDirectDisplayID = 0) -> [CGPoint] {
        let frame: CGRect
        if displayID != 0,
           let screen = NSScreen.screens.first(where: { ScreenGeometry.displayID(of: $0) == displayID })
        {
            frame = screen.frame
        } else {
            frame = ScreenGeometry.cocoaUnion
        }
        let q = ScreenGeometry.quartzRect(fromCocoa: frame)
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
        guard isReady, let H = cachedHomography() else { return Self.linear(palm) }
        let w = H[6] * palm.x + H[7] * palm.y + H[8]
        guard abs(w) > 1e-8 else { return Self.linear(palm) }
        let p = CGPoint(
            x: (H[0] * palm.x + H[1] * palm.y + H[2]) / w,
            y: (H[3] * palm.x + H[4] * palm.y + H[5]) / w
        )
        return ScreenGeometry.clampQuartz(p)
    }

    /// Bildschirm → Kamera-Handfläche. Cover-Lage in Lead-Raum.
    func invert(_ screen: CGPoint) -> CGPoint? {
        guard isReady, let H = cachedHomography(), let inv = CoordMath.invert3x3(H) else { return nil }
        return CoordMath.apply3x3(inv, screen)
    }

    /// Außen absolut (Homographie), innen Relativ-Schritt. `relative` ist schon in Quartz.
    func hybrid(palm: CGPoint, relative: CGPoint, band: CGFloat = GestureMath.hybridBand) -> CGPoint {
        let absP = apply(palm)
        let uv = ScreenGeometry.unitInUnion(quartz: absP)
        let w = CoordMath.edgeAbsoluteWeight(u: uv.x, v: uv.y, band: band)
        let p = CGPoint(
            x: w * absP.x + (1 - w) * relative.x,
            y: w * absP.y + (1 - w) * relative.y
        )
        return ScreenGeometry.clampQuartz(p)
    }

    func homography() -> [CGFloat]? {
        cachedHomography()
    }

    private func cachedHomography() -> [CGFloat]? {
        HomographyStore.get(palms, displayID: displayID, cameraID: cameraID)
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

    static func storageKey(displayID: CGDirectDisplayID) -> String {
        displayID == 0 ? "helios.spaceMap" : "helios.spaceMap.\(displayID)"
    }

    static func camKey(cameraID: String, displayID: CGDirectDisplayID) -> String {
        if cameraID.isEmpty { return storageKey(displayID: displayID) }
        return displayID == 0
            ? "helios.spaceMap.cam.\(cameraID)"
            : "helios.spaceMap.cam.\(cameraID).\(displayID)"
    }

    static func load(cameraID: String = "", displayID: CGDirectDisplayID = 0) -> SpaceMap? {
        if !cameraID.isEmpty {
            if let data = UserDefaults.standard.data(forKey: camKey(cameraID: cameraID, displayID: displayID)),
               let map = try? JSONDecoder().decode(SpaceMap.self, from: data)
            {
                return map
            }
            if displayID != 0,
               let data = UserDefaults.standard.data(forKey: camKey(cameraID: cameraID, displayID: 0)),
               let map = try? JSONDecoder().decode(SpaceMap.self, from: data)
            {
                return map
            }
            // Cover/Lead-cam keys are exact. Global helios.spaceMap is lead-only fallback
            // (empty cameraID). 1.6.27 wrote cover into global — inheriting it here
            // marked Cover as calibrated without a Cover-Kamera.
            return nil
        }
        if displayID != 0,
           let data = UserDefaults.standard.data(forKey: storageKey(displayID: displayID)),
           let map = try? JSONDecoder().decode(SpaceMap.self, from: data)
        {
            return map
        }
        guard let data = UserDefaults.standard.data(forKey: "helios.spaceMap") else { return nil }
        return try? JSONDecoder().decode(SpaceMap.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        // Cover-Kalibrierung darf die globale Fallback-Homographie des Lead nicht überschreiben.
        if cameraID.isEmpty {
            UserDefaults.standard.set(data, forKey: "helios.spaceMap")
        }
        if displayID != 0, cameraID.isEmpty {
            UserDefaults.standard.set(data, forKey: Self.storageKey(displayID: displayID))
        }
        if !cameraID.isEmpty {
            UserDefaults.standard.set(data, forKey: Self.camKey(cameraID: cameraID, displayID: displayID))
            var ids = UserDefaults.standard.stringArray(forKey: "helios.spaceMap.cameras") ?? []
            if !ids.contains(cameraID) {
                ids.append(cameraID)
                UserDefaults.standard.set(ids, forKey: "helios.spaceMap.cameras")
            }
        }
        HomographyStore.clear()
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: "helios.spaceMap")
        for screen in NSScreen.screens {
            UserDefaults.standard.removeObject(forKey: storageKey(displayID: ScreenGeometry.displayID(of: screen)))
        }
        let ids = UserDefaults.standard.stringArray(forKey: "helios.spaceMap.cameras") ?? []
        for id in ids {
            UserDefaults.standard.removeObject(forKey: camKey(cameraID: id, displayID: 0))
            for screen in NSScreen.screens {
                UserDefaults.standard.removeObject(
                    forKey: camKey(cameraID: id, displayID: ScreenGeometry.displayID(of: screen))
                )
            }
        }
        UserDefaults.standard.removeObject(forKey: "helios.spaceMap.cameras")
        HomographyStore.clear()
    }
}

private enum HomographyStore {
    private struct Slot {
        var palms: [XY]
        var displayID: UInt32
        var cameraID: String
        var H: [CGFloat]?
    }

    private static let lock = NSLock()
    private static let cap = 4
    nonisolated(unsafe) private static var slots: [Slot] = []

    static func get(_ src: [XY], displayID: UInt32, cameraID: String = "") -> [CGFloat]? {
        lock.lock()
        defer { lock.unlock() }
        if let i = slots.firstIndex(where: {
            $0.cameraID == cameraID && $0.displayID == displayID && $0.palms == src
        }) {
            let hit = slots.remove(at: i)
            slots.append(hit)
            return hit.H
        }
        guard src.count == 4 else {
            upsert(Slot(palms: src, displayID: displayID, cameraID: cameraID, H: nil))
            return nil
        }
        let H = SpaceMap.homography(from: src.map(\.point), to: SpaceMap.screenCorners(displayID: displayID))
        upsert(Slot(palms: src, displayID: displayID, cameraID: cameraID, H: H))
        return H
    }

    private static func upsert(_ slot: Slot) {
        slots.removeAll { $0.cameraID == slot.cameraID && $0.displayID == slot.displayID }
        slots.append(slot)
        if slots.count > cap { slots.removeFirst(slots.count - cap) }
    }

    static func clear() {
        lock.lock()
        slots = []
        lock.unlock()
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
    private var lastCapture: TimeInterval = 0
    private var needRelease = false
    private var needMove = false
    private(set) var hint = "Pinzette an der Ecke halten"
    private(set) var rejected = false
    private var targetDisplay: CGDirectDisplayID = 0
    private(set) var cameraID = ""
    private(set) var cameraLabel = ""
    private var finishedID: String?

    var progress: CGFloat { min(1, hold / 0.9) }
    var remaining: Int { 4 - samples.count }

    func start(cameraID: String = "", label: String = "") {
        active = true
        corner = .topLeft
        hold = 0
        samples.removeAll()
        lastPalm = nil
        lastCapture = 0
        needRelease = false
        needMove = false
        rejected = false
        lastT = 0
        targetDisplay = ScreenGeometry.mainDisplayID
        self.cameraID = cameraID
        cameraLabel = label
        finishedID = nil
        if label.isEmpty {
            hint = "Ecke oben links: dein Anschlag, nicht der Kamerarand. Pinzette 1 s."
        } else {
            hint = "\(label): Ecke oben links — Blickwinkel dieser Quelle. Anschlag, nicht Kamerarand."
        }
    }

    func consumeFinished() -> String? {
        let v = finishedID
        finishedID = nil
        return v
    }

    func cancel() {
        active = false
        hold = 0
    }

    func targetQuartz() -> CGPoint {
        SpaceMap.screenCorners(displayID: targetDisplay)[corner.rawValue]
    }

    /// Nur Pinzette. Nach jedem Treffer: Hand öffnen und zur nächsten Ecke gehen.
    func feed(palm: CGPoint, now: TimeInterval, confirm: Bool) -> SpaceMap? {
        guard active else { return nil }
        let dt = lastT == 0 ? 0 : min(now - lastT, GestureMath.sampleDtCap)
        lastT = now
        let moved = lastPalm.map { hypot(palm.x - $0.x, palm.y - $0.y) } ?? 1
        lastPalm = palm
        let target = targetQuartz()
        let cursor = ScreenGeometry.quartz(fromCocoa: NSEvent.mouseLocation)
        cursorGap = hypot(cursor.x - target.x, cursor.y - target.y)

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
            if let last = lastSample(), hypot(palm.x - last.x, palm.y - last.y) < GestureMath.calibCornerSep {
                hold = 0
                hint = "Etwas weiter nach \(corner.titleDE) — nur so weit, wie die Hand im Bild bleibt"
                return nil
            }
            needMove = false
        }
        if samples.values.contains(where: { hypot(palm.x - $0.x, palm.y - $0.y) < GestureMath.calibCornerSep }) {
            hold = 0
            hint = "Zu nah an einer fertigen Ecke — dein nächster Anschlag, ohne das Bild zu verlassen"
            rejected = true
            return nil
        }
        if !confirm {
            hold = 0
            hint = "Pinzette an Ecke \(corner.titleDE) halten (\(remaining) offen)"
            return nil
        }
        if moved < 0.014 {
            hold += CGFloat(dt)
        } else {
            hold = 0
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
        hold = 0
        lastPalm = nil
        lastCapture = now
        needRelease = true
        if let next = CalibCorner(rawValue: corner.rawValue + 1) {
            corner = next
            hint = "OK. Öffnen und nach \(next.titleDE) — Anschlag, nicht Kamerarand"
            return nil
        }
        let ordered: [CalibCorner] = [.topLeft, .topRight, .bottomRight, .bottomLeft]
        let pts = ordered.compactMap { samples[$0] }
        guard pts.count == 4, Self.quadArea(pts) >= GestureMath.calibMinArea else {
            samples[.bottomLeft] = nil
            corner = .bottomLeft
            hint = "Ecken zu nah. Unten links so weit du kommst, ohne das Bild zu verlassen."
            rejected = true
            return nil
        }
        let map = SpaceMap(palms: pts.map(XY.init), displayID: targetDisplay, cameraID: cameraID)
        map.save()
        active = false
        finishedID = cameraID
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

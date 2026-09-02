import CoreGraphics
import Foundation

struct AspectSpace: Equatable {
    var width: CGFloat
    var height: CGFloat
    static let hd720 = AspectSpace(width: 1280, height: 720)
    var aspect: CGFloat { width / max(1, height) }
    func iso(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * aspect, y: p.y) }
    func fromIso(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x / max(0.01, aspect), y: p.y) }
    func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let p = iso(a); let q = iso(b)
        return hypot(p.x - q.x, p.y - q.y)
    }
    func vec(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        let p = iso(a); let q = iso(b)
        return CGPoint(x: q.x - p.x, y: q.y - p.y)
    }
}

enum JointGeom {
    static func angle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, space: AspectSpace) -> CGFloat {
        let ba = space.vec(b, a)
        let bc = space.vec(b, c)
        let na = hypot(ba.x, ba.y)
        let nc = hypot(bc.x, bc.y)
        guard na > 1e-6, nc > 1e-6 else { return .pi }
        let cosv = max(-1, min(1, (ba.x * bc.x + ba.y * bc.y) / (na * nc)))
        return acos(cosv)
    }
    static func extensionScore(angleRadians: CGFloat) -> CGFloat {
        let t = (angleRadians - 1.15) / max(0.05, 3.141592653589793 - 1.15)
        return max(0, min(1, t))
    }
    static func softmax(_ logits: [Double], temperature: Double = 0.85) -> [Double] {
        let t = max(0.15, temperature)
        let shifted = logits.map { $0 / t }
        let m = shifted.max() ?? 0
        let exps = shifted.map { exp($0 - m) }
        let s = exps.reduce(0, +)
        guard s > 0 else { return Array(repeating: 1 / Double(max(1, logits.count)), count: logits.count) }
        return exps.map { $0 / s }
    }
    static func median(_ xs: [CGFloat]) -> CGFloat {
        guard !xs.isEmpty else { return 0 }
        let s = xs.sorted()
        let n = s.count
        if n % 2 == 1 { return s[n / 2] }
        return (s[n / 2 - 1] + s[n / 2]) / 2
    }
}

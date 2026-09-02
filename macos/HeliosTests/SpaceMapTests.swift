import CoreGraphics
import Foundation

@main
enum SpaceMapTests {
    static func main() {
        let src = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 1, y: 0),
            CGPoint(x: 1, y: 1),
            CGPoint(x: 0, y: 1)
        ]
        guard let ident = SpaceMap.homography(from: src, to: src) else {
            fputs("FAIL identity homography nil\n", stderr)
            exit(1)
        }
        let p = apply(ident, CGPoint(x: 0.25, y: 0.8))
        if abs(p.x - 0.25) > 0.002 || abs(p.y - 0.8) > 0.002 {
            fputs("FAIL identity \(p)\n", stderr)
            exit(1)
        }
        let dst = src.map { CGPoint(x: 100 + $0.x * 800, y: 50 + $0.y * 600) }
        guard let H = SpaceMap.homography(from: src, to: dst) else {
            fputs("FAIL scale homography nil\n", stderr)
            exit(1)
        }
        let q = apply(H, CGPoint(x: 0.5, y: 0.5))
        if abs(q.x - 500) > 0.5 || abs(q.y - 350) > 0.5 {
            fputs("FAIL scale \(q)\n", stderr)
            exit(1)
        }
        let palms = [XY(x: 0.2, y: 0.2), XY(x: 0.8, y: 0.2), XY(x: 0.8, y: 0.8), XY(x: 0.2, y: 0.8)]
        let smap = SpaceMap(palms: palms)
        if smap.edgeWeight(CGPoint(x: 0.5, y: 0.5)) >= 0.05 {
            fputs("FAIL SpaceMap innen relativ\n", stderr)
            exit(1)
        }
        if smap.edgeWeight(CGPoint(x: 0.21, y: 0.5)) <= 0.8 {
            fputs("FAIL SpaceMap Rand absolut\n", stderr)
            exit(1)
        }

        // 9-Punkt-DLT: Identität über ein 3×3-Gitter.
        var src9: [CGPoint] = []
        var dst9: [CGPoint] = []
        for r in 0..<3 {
            for c in 0..<3 {
                src9.append(CGPoint(x: CGFloat(c) * 0.5, y: CGFloat(r) * 0.5))
                dst9.append(CGPoint(x: 100 + CGFloat(c) * 400, y: 50 + CGFloat(r) * 300))
            }
        }
        guard let H9 = SpaceMap.homography(from: src9, to: dst9) else {
            fputs("FAIL 9-point homography nil\n", stderr)
            exit(1)
        }
        let q9 = apply(H9, CGPoint(x: 0.5, y: 0.5))
        if abs(q9.x - 500) > 1.0 || abs(q9.y - 350) > 1.0 {
            fputs("FAIL 9-point \(q9)\n", stderr)
            exit(1)
        }
        guard let H9fit = SpaceMap.homography(from: src9, to: dst9) else {
            fputs("FAIL 9-point RMSE homography nil\n", stderr)
            exit(1)
        }
        var acc: CGFloat = 0
        for i in 0..<9 {
            let p = SpaceMap.project(H9fit, src9[i])
            let e = hypot(p.x - dst9[i].x, p.y - dst9[i].y)
            acc += e * e
        }
        let rmse = sqrt(acc / 9)
        if rmse > 0.5 {
            fputs("FAIL 9-point RMSE \(rmse)\n", stderr)
            exit(1)
        }
        var map9 = SpaceMap(palms: src9.map(XY.init), displayID: nil)
        if !map9.isReady || !map9.isNinePoint {
            fputs("FAIL 9-point isReady\n", stderr)
            exit(1)
        }
        // 4-Punkt bleibt gültig.
        if !smap.isReady {
            fputs("FAIL 4-point isReady\n", stderr)
            exit(1)
        }
        print("SpaceMapTests OK")
    }

    static func apply(_ H: [CGFloat], _ p: CGPoint) -> CGPoint {
        let w = H[6] * p.x + H[7] * p.y + H[8]
        return CGPoint(
            x: (H[0] * p.x + H[1] * p.y + H[2]) / w,
            y: (H[3] * p.x + H[4] * p.y + H[5]) / w
        )
    }
}

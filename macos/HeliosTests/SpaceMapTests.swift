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

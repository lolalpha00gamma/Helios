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
        let collapsed = SpaceMap(palms: [
            XY(x: 0.5, y: 0.5), XY(x: 0.5, y: 0.5),
            XY(x: 0.5, y: 0.5), XY(x: 0.5, y: 0.5)
        ])
        if !collapsed.isReady {
            fputs("FAIL collapsed isReady\n", stderr)
            exit(1)
        }
        if collapsed.isUsable {
            fputs("FAIL singuläre Homographie zählt als usable\n", stderr)
            exit(1)
        }
        let open = SpaceMap(palms: [
            XY(x: 0.15, y: 0.85), XY(x: 0.85, y: 0.85),
            XY(x: 0.85, y: 0.15), XY(x: 0.15, y: 0.15)
        ])
        if !open.isUsable {
            fputs("FAIL offenes Quad nicht usable\n", stderr)
            exit(1)
        }
        if GestureMath.spaceMapKey("built-in") == GestureMath.spaceMapKey("continuity") {
            fputs("FAIL Kamera-Keys gleich\n", stderr)
            exit(1)
        }
        if SpaceMap.storageKey("a") != "helios.spaceMap.a" {
            fputs("FAIL storageKey\n", stderr)
            exit(1)
        }
        if SpaceMap.storageKey("a", screenID: "9") == SpaceMap.storageKey("a") {
            fputs("FAIL storageKey screen == camera\n", stderr)
            exit(1)
        }
        if SpaceMap.storageKey("a", screenID: "9") == SpaceMap.storageKey("a", screenID: "8") {
            fputs("FAIL storageKey screens gleich\n", stderr)
            exit(1)
        }
        let vis = CGRect(x: 100, y: 50, width: 1280, height: 800)
        let corners = SpaceMap.screenCorners(of: vis)
        if corners.count != 4 {
            fputs("FAIL screenCorners count\n", stderr)
            exit(1)
        }
        if abs(corners[0].x - 108) > 0.5 || abs(corners[0].y - 58) > 0.5 {
            fputs("FAIL screenCorners TL \(corners[0])\n", stderr)
            exit(1)
        }
        if abs(corners[2].x - 1372) > 0.5 || abs(corners[2].y - 842) > 0.5 {
            fputs("FAIL screenCorners BR \(corners[2])\n", stderr)
            exit(1)
        }
        let mapped = SpaceMap.linear(CGPoint(x: 0.10, y: 0.90), in: vis)
        if abs(mapped.x - 100) > 0.5 || abs(mapped.y - 50) > 0.5 {
            fputs("FAIL linear in vis TL \(mapped)\n", stderr)
            exit(1)
        }
        let mappedBR = SpaceMap.linear(CGPoint(x: 0.90, y: 0.10), in: vis)
        if abs(mappedBR.x - 1380) > 0.5 || abs(mappedBR.y - 850) > 0.5 {
            fputs("FAIL linear in vis BR \(mappedBR)\n", stderr)
            exit(1)
        }
        let destMap = SpaceMap(
            palms: [XY(x: 0, y: 0), XY(x: 1, y: 0), XY(x: 1, y: 1), XY(x: 0, y: 1)],
            dest: [XY(x: 100, y: 50), XY(x: 900, y: 50), XY(x: 900, y: 650), XY(x: 100, y: 650)]
        )
        guard let Hd = destMap.homography() else {
            fputs("FAIL dest homography nil\n", stderr)
            exit(1)
        }
        let mid = apply(Hd, CGPoint(x: 0.5, y: 0.5))
        if abs(mid.x - 500) > 0.5 || abs(mid.y - 350) > 0.5 {
            fputs("FAIL dest mid \(mid)\n", stderr)
            exit(1)
        }
        guard let db = destMap.destBounds else {
            fputs("FAIL destBounds nil\n", stderr)
            exit(1)
        }
        if abs(db.minX - 100) > 0.5 || abs(db.minY - 50) > 0.5 || abs(db.width - 800) > 0.5 || abs(db.height - 600) > 0.5 {
            fputs("FAIL destBounds \(db)\n", stderr)
            exit(1)
        }
        let collapsedDest = SpaceMap(
            palms: [XY(x: 0, y: 0), XY(x: 1, y: 0), XY(x: 1, y: 1), XY(x: 0, y: 1)]
        )
        if collapsedDest.destBounds != nil {
            fputs("FAIL destBounds ohne dest\n", stderr)
            exit(1)
        }
        if !GestureMath.mapRMSReady(GestureMath.mapRMS([12, 8, 20, 16])) {
            fputs("FAIL kleine RMS nicht ready\n", stderr)
            exit(1)
        }
        if GestureMath.mapRMSReady(70) {
            fputs("FAIL 70 px RMS ready\n", stderr)
            exit(1)
        }
        let b = CGRect(x: 100, y: 50, width: 800, height: 600)
        let c = GestureMath.destClamp(CGPoint(x: 5000, y: -20), bounds: b)
        if c.x > b.maxX - 0.5 || c.y < b.minY + 0.5 {
            fputs("FAIL destClamp \(c)\n", stderr)
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

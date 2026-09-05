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

        let globalKey = "helios.spaceMap"
        let prevGlobal = UserDefaults.standard.data(forKey: globalKey)
        let sample = SpaceMap(
            palms: [XY(x: 0, y: 0), XY(x: 1, y: 0), XY(x: 1, y: 1), XY(x: 0, y: 1)],
            cameraID: ""
        )
        guard let blob = try? JSONEncoder().encode(sample) else {
            fputs("FAIL encode SpaceMap\n", stderr)
            exit(1)
        }
        UserDefaults.standard.set(blob, forKey: globalKey)
        if SpaceMap.load(cameraID: "cover-test-cam") != nil {
            fputs("FAIL Cover erbt globale Homographie\n", stderr)
            exit(1)
        }
        if SpaceMap.load() == nil {
            fputs("FAIL globale Map ohne cameraID lesbar\n", stderr)
            exit(1)
        }
        let coverBlob = SpaceMap(
            palms: [XY(x: 0, y: 0), XY(x: 1, y: 0), XY(x: 1, y: 1), XY(x: 0, y: 1)],
            cameraID: "cover-poison"
        )
        guard let coverData = try? JSONEncoder().encode(coverBlob) else {
            fputs("FAIL encode Cover-Map\n", stderr)
            exit(1)
        }
        UserDefaults.standard.set(coverData, forKey: globalKey)
        if SpaceMap.load() != nil {
            fputs("FAIL globale Cover-Map darf Lead nicht vergiften\n", stderr)
            exit(1)
        }

        let cam = "helios-test-mismatch"
        let disp: UInt32 = 99
        let perCam = SpaceMap(
            palms: [XY(x: 0, y: 0), XY(x: 1, y: 0), XY(x: 1, y: 1), XY(x: 0, y: 1)],
            displayID: disp,
            cameraID: cam
        )
        perCam.save()
        if SpaceMap.load(cameraID: cam)?.isReady != true {
            fputs("FAIL load ohne displayID findet cam.<id>.<display> nicht\n", stderr)
            exit(1)
        }
        if SpaceMap.load(cameraID: cam, displayID: disp)?.cameraID != cam {
            fputs("FAIL load mit displayID verfehlt den Key\n", stderr)
            exit(1)
        }
        UserDefaults.standard.removeObject(forKey: SpaceMap.camKey(cameraID: cam, displayID: disp))
        UserDefaults.standard.removeObject(forKey: SpaceMap.camKey(cameraID: cam, displayID: 0))
        let main = ScreenGeometry.mainDisplayID
        if main != 0 {
            let cam2 = "helios-test-screenloop"
            SpaceMap(
                palms: [XY(x: 0, y: 0), XY(x: 1, y: 0), XY(x: 1, y: 1), XY(x: 0, y: 1)],
                displayID: main,
                cameraID: cam2
            ).save()
            UserDefaults.standard.removeObject(forKey: SpaceMap.camKey(cameraID: cam2, displayID: 0))
            if SpaceMap.load(cameraID: cam2)?.isReady != true {
                fputs("FAIL load ohne displayID findet bestehenden Display-Key nicht\n", stderr)
                exit(1)
            }
            UserDefaults.standard.removeObject(forKey: SpaceMap.camKey(cameraID: cam2, displayID: main))
            UserDefaults.standard.removeObject(forKey: SpaceMap.camKey(cameraID: cam2, displayID: 0))
            if let ids = UserDefaults.standard.stringArray(forKey: "helios.spaceMap.cameras") {
                UserDefaults.standard.set(ids.filter { $0 != cam && $0 != cam2 }, forKey: "helios.spaceMap.cameras")
            }
        } else if let ids = UserDefaults.standard.stringArray(forKey: "helios.spaceMap.cameras") {
            UserDefaults.standard.set(ids.filter { $0 != cam }, forKey: "helios.spaceMap.cameras")
        }
        if let prevGlobal {
            UserDefaults.standard.set(prevGlobal, forKey: globalKey)
        } else {
            UserDefaults.standard.removeObject(forKey: globalKey)
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

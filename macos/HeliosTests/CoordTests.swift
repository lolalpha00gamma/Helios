import CoreGraphics
import Foundation

/// `swiftc macos/Helios/CoordMath.swift macos/HeliosTests/CoordTests.swift -o /tmp/coordtests && /tmp/coordtests`

@main
enum CoordTests {
    static var fails = 0

    static func eq(_ a: CGFloat, _ b: CGFloat, _ msg: String) {
        if abs(a - b) > 0.001 {
            fputs("FAIL \(msg): \(a) != \(b)\n", stderr)
            fails += 1
        }
    }

    static func ok(_ cond: Bool, _ msg: String) {
        if !cond {
            fputs("FAIL \(msg)\n", stderr)
            fails += 1
        }
    }

    static func pointEq(_ a: CGPoint, _ b: CGPoint, _ msg: String) {
        eq(a.x, b.x, msg + " x")
        eq(a.y, b.y, msg + " y")
    }

    static func main() {
        let primaryH: CGFloat = 1080
        pointEq(
            CoordMath.quartz(fromCocoa: CGPoint(x: 10, y: 1080), primaryMaxY: primaryH),
            CGPoint(x: 10, y: 0),
            "oben Hauptbildschirm"
        )
        pointEq(
            CoordMath.quartz(fromCocoa: CGPoint(x: 10, y: 0), primaryMaxY: primaryH),
            CGPoint(x: 10, y: 1080),
            "unten Hauptbildschirm"
        )
        pointEq(
            CoordMath.quartz(fromCocoa: CGPoint(x: 100, y: 1080 + 400), primaryMaxY: primaryH),
            CGPoint(x: 100, y: -400),
            "Schirm oben"
        )
        let p = CGPoint(x: -200, y: 500)
        let q = CoordMath.quartz(fromCocoa: p, primaryMaxY: primaryH)
        pointEq(CoordMath.cocoa(fromQuartz: q, primaryMaxY: primaryH), p, "Roundtrip Punkt")

        let cocoaWin = CGRect(x: 100, y: 200, width: 800, height: 600)
        let quartzWin = CoordMath.quartzRect(fromCocoa: cocoaWin, primaryMaxY: primaryH)
        eq(quartzWin.origin.x, 100, "rect x")
        eq(quartzWin.origin.y, primaryH - 200 - 600, "rect y top-left quartz")
        eq(quartzWin.height, 600, "rect h")
        let back = CoordMath.cocoaRect(fromQuartz: quartzWin, primaryMaxY: primaryH)
        eq(back.origin.x, cocoaWin.origin.x, "rect roundtrip x")
        eq(back.origin.y, cocoaWin.origin.y, "rect roundtrip y")
        eq(back.width, cocoaWin.width, "rect roundtrip w")
        eq(back.height, cocoaWin.height, "rect roundtrip h")

        let cgWindow = CGRect(x: 50, y: 80, width: 400, height: 300)
        let ax = CoordMath.cocoaRect(fromQuartz: cgWindow, primaryMaxY: primaryH)
        eq(ax.minX, 50, "AX x")
        eq(ax.height, 300, "AX h")
        eq(ax.maxY, primaryH - 80, "AX top in cocoa")

        let qWin = CGRect(x: 50, y: 80, width: 400, height: 300)
        pointEq(CoordMath.quartzTopLeft(qWin), CGPoint(x: 50, y: 80), "Quartz oben links = minY")
        ok(CoordMath.quartzTopLeft(qWin).y != qWin.maxY, "maxY ist die Unterkante, nicht Titelbalken")
        let nsBounds: [String: Any] = [
            "X": NSNumber(value: 50.0),
            "Y": NSNumber(value: 80.0),
            "Width": NSNumber(value: 400.0),
            "Height": NSNumber(value: 300.0)
        ]
        let parsed = GestureMath.windowListRect(nsBounds)
        ok(parsed != nil, "NSNumber-Bounds nicht nil")
        eq(parsed?.origin.x ?? -1, 50, "NSNumber X")
        eq(parsed?.origin.y ?? -1, 80, "NSNumber Y")
        eq(parsed?.width ?? -1, 400, "NSNumber W")
        eq(parsed?.height ?? -1, 300, "NSNumber H")
        let dblBounds: [String: Any] = ["X": 10.0, "Y": 20.0, "Width": 100.0, "Height": 50.0]
        let parsedD = GestureMath.windowListRect(dblBounds)
        ok(parsedD?.width == 100 && parsedD?.height == 50, "Double-Bounds")
        ok(GestureMath.windowListRect(nil) == nil, "nil Bounds")
        ok(GestureMath.windowListRect(["X": 1, "Y": 2] as [String: Any]) == nil, "unvollständig")
        ok(GestureMath.windowListRect(["X": 0, "Y": 0, "Width": 0, "Height": 10] as [String: Any]) == nil, "breite 0")
        ok(GestureMath.axWriteTook(want: CGPoint(x: 100, y: 200), got: CGPoint(x: 108, y: 204)), "AX 8 px Slop OK")
        ok(!GestureMath.axWriteTook(want: CGPoint(x: 100, y: 200), got: CGPoint(x: 140, y: 200)), "AX 40 px tot")
        ok(GestureMath.axWriteTook(want: CGSize(width: 800, height: 600), got: CGSize(width: 800, height: 605)), "AX Size Slop")
        ok(!GestureMath.axWriteTook(want: CGSize(width: 800, height: 600), got: CGSize(width: 800, height: 640)), "AX Size tot")
        ok(!GestureMath.skipProbeStoresEmpty(), "Skip-AX speichert keine leere Probe")
        ok(GestureMath.releaseBlockedBySkipAX(blockPress: true), "Release nach Skip blockt Klick")
        ok(!GestureMath.releaseBlockedBySkipAX(blockPress: false), "frisches AX darf Release")

        ok(GestureMath.cgWindowIsGrabTarget(pid: 42, layer: 0, skipSelf: true, selfPID: 7), "fremde App")
        ok(!GestureMath.cgWindowIsGrabTarget(pid: 7, layer: 0, skipSelf: true, selfPID: 7), "skipSelf überspringt Helios")
        ok(GestureMath.cgWindowIsGrabTarget(pid: 7, layer: 0, skipSelf: false, selfPID: 7), "ControlPanel greifbar")
        ok(!GestureMath.cgWindowIsGrabTarget(pid: 7, layer: 25, skipSelf: false, selfPID: 7), "HUD-Overlay nie")
        ok(!GestureMath.cgWindowIsGrabTarget(pid: 0, layer: 0, skipSelf: false, selfPID: 7), "pid 0 nie")
        ok(GestureMath.scaleBlocksGrab(pinchHeld: true, closedCount: 2), "Scale trotz Grab")
        ok(GestureMath.scaleKeepsSpan(old: 0.3, span: 0.5, gated: true) == 0.3, "gated Span alt")
        ok(GestureMath.scaleKeepsSpan(old: 0.3, span: 0.5, gated: false) == 0.5, "frei Span neu")

        if fails > 0 {
            fputs("\(fails) Tests fehlgeschlagen\n", stderr)
            exit(1)
        }
        print("CoordTests OK")
    }
}

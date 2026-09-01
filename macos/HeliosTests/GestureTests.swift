import CoreGraphics
import Foundation
import Vision

/// `swiftc -framework Vision macos/Helios/GestureClassifier.swift macos/HeliosTests/GestureTests.swift -o /tmp/g && /tmp/g`

@main
enum GestureTests {
    static var fails = 0

    static func ok(_ cond: Bool, _ msg: String) {
        if !cond {
            fputs("FAIL \(msg)\n", stderr)
            fails += 1
        }
    }

    static func hand(
        wrist: CGPoint = CGPoint(x: 0.50, y: 0.20),
        tipsY: CGFloat,
        thumbUp: Bool = false
    ) -> [VNHumanHandPoseObservation.JointName: CGPoint] {
        let mcpY = wrist.y + 0.14
        let pipY = wrist.y + (tipsY + 0.14) * 0.5
        return [
            .wrist: wrist,
            .indexMCP: CGPoint(x: 0.46, y: mcpY),
            .indexPIP: CGPoint(x: 0.45, y: pipY),
            .indexTip: CGPoint(x: 0.44, y: tipsY),
            .middleMCP: CGPoint(x: 0.50, y: mcpY),
            .middlePIP: CGPoint(x: 0.50, y: pipY),
            .middleTip: CGPoint(x: 0.50, y: tipsY),
            .ringMCP: CGPoint(x: 0.54, y: mcpY),
            .ringPIP: CGPoint(x: 0.55, y: pipY),
            .ringTip: CGPoint(x: 0.56, y: tipsY),
            .littleMCP: CGPoint(x: 0.58, y: mcpY),
            .littlePIP: CGPoint(x: 0.59, y: pipY),
            .littleTip: CGPoint(x: 0.60, y: tipsY),
            .thumbMP: CGPoint(x: 0.44, y: mcpY),
            .thumbIP: CGPoint(x: 0.45, y: mcpY + 0.01),
            .thumbTip: CGPoint(x: 0.46, y: thumbUp ? wrist.y + 0.40 : mcpY - 0.02)
        ]
    }

    static func main() {
        let open = hand(tipsY: 0.72)
        ok(GestureClassifier.classify(joints: open, pinch: 0.22) == .openPalm, "offene Hand")
        ok(GestureClassifier.openScore(joints: open) >= 3, "openScore")

        let fist = hand(tipsY: 0.32)
        ok(GestureClassifier.classify(joints: fist, pinch: 0.10) == .fist, "Faust")

        var pinchJ = hand(tipsY: 0.32)
        pinchJ[.indexTip] = CGPoint(x: 0.40, y: 0.62)
        pinchJ[.indexPIP] = CGPoint(x: 0.42, y: 0.48)
        pinchJ[.indexMCP] = CGPoint(x: 0.46, y: 0.34)
        pinchJ[.thumbTip] = CGPoint(x: 0.41, y: 0.61)
        let pinchDist = hypot(0.40 - 0.41, 0.62 - 0.61)
        ok(GestureClassifier.classify(joints: pinchJ, pinch: pinchDist) == .pinch, "Pinzette")

        if fails > 0 {
            fputs("\(fails) GestureTests fehlgeschlagen\n", stderr)
            exit(1)
        }
        print("GestureTests OK")
    }
}

import CoreGraphics
import Foundation
import Vision

/// `swiftc -framework Vision macos/Helios/*.swift macos/HeliosTests/GestureTests.swift` is not used;
/// compile the classifier files listed in README.

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
        GestureClassifier.space = AspectSpace(width: 1280, height: 720)

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
        let pinchDist = AspectSpace.hd720.dist(CGPoint(x: 0.40, y: 0.62), CGPoint(x: 0.41, y: 0.61))
        ok(GestureClassifier.classify(joints: pinchJ, pinch: pinchDist) == .pinch, "Pinzette")

        var gate = PinchGate()
        gate.setSpace(.hd720)
        var t: TimeInterval = 1
        func step(_ joints: [VNHumanHandPoseObservation.JointName: CGPoint], n: Int) -> Bool {
            var c: [VNHumanHandPoseObservation.JointName: Float] = [:]
            for k in joints.keys { c[k] = 0.9 }
            var closed = false
            for _ in 0..<n {
                t += 0.016
                closed = gate.update(raw: joints, conf: c, now: t).closed
            }
            return closed
        }
        ok(!step(open, n: 4), "Gate offen bleibt offen")
        ok(step(pinchJ, n: 6), "Gate schließt bei Pinzette")
        var gone = pinchJ
        gone.removeValue(forKey: .thumbTip)
        gone.removeValue(forKey: .indexTip)
        ok(step(gone, n: 4), "Gate bleibt zu wenn Spitzen fehlen")
        ok(!step(open, n: 10), "Gate öffnet wieder")

        let isoX = AspectSpace.hd720.dist(CGPoint(x: 0, y: 0), CGPoint(x: 100 / 1280, y: 0))
        let isoY = AspectSpace.hd720.dist(CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 100 / 720))
        ok(abs(isoX - isoY) < 0.002, "isotrop: 100 px in x entspricht 100 px in y")

        let fusion = EstimateFusion()
        var p2: [HandPose: Double] = [:]
        var p3: [HandPose: Double] = [:]
        for k in HandPose.allCases { p2[k] = 0.02; p3[k] = 0.02 }
        p2[.openPalm] = 0.8
        p3[.fist] = 0.7
        let e2 = HandEstimate(source: .geometry2D, probabilities: p2, pinchClosedness: 0.1, palm: CGPoint(x: 0.4, y: 0.4), palmVariance: 0.002, quality: 0.9, available: true, palmWidth: 0.12)
        let e3 = HandEstimate(source: .lift3D, probabilities: p3, pinchClosedness: 0.1, palm: CGPoint(x: 0.41, y: 0.4), palmVariance: 0.002, quality: 0.9, available: true, palmWidth: 0.12)
        let (fused, _) = fusion.fuse([e2, e3], dt: 0.016)
        ok(fused.available, "Fusion liefert Schätzung")
        ok((fused.probabilities[.openPalm] ?? 0) > 0.45, "2D-Stimme bleibt führend")

        var copy3 = p2
        let eCopy = HandEstimate(source: .lift3D, probabilities: copy3, pinchClosedness: 0.1, palm: CGPoint(x: 0.4, y: 0.4), palmVariance: 0.002, quality: 0.9, available: true, palmWidth: 0.12)
        let eT = HandEstimate(source: .temporal, probabilities: copy3, pinchClosedness: 0.1, palm: CGPoint(x: 0.4, y: 0.4), palmVariance: 0.006, quality: 0.42, available: true, palmWidth: 0.12)
        let (peaked, dbgPeak) = fusion.fuse([e2, eCopy, eT], dt: 0.016)
        ok((peaked.probabilities[.openPalm] ?? 0) > 0.70, "korrelierte Lift/Zeit flatten die Pose nicht")
        ok(!dbgPeak.collapsed.isEmpty, "korrelierte Quellen werden markiert")

        var pD: [HandPose: Double] = [:]
        for k in HandPose.allCases { pD[k] = 0.02 }
        pD[.openPalm] = 0.75
        let eD = HandEstimate(source: .depth, probabilities: pD, pinchClosedness: 0.1, palm: CGPoint(x: 0.4, y: 0.4), palmVariance: 0.001, quality: 0.9, available: true, palmWidth: 0.12)
        let (_, dbg) = fusion.fuse([e2, e3, eD], dt: 0.016)
        ok((dbg.weights["lift3D"] ?? 1) < (dbg.weights["depth"] ?? 0) + 0.05, "Lift-Gewicht fällt wenn Tiefe da ist")
        ok(dbg.usedDepth, "Fusion markiert echte Tiefe")

        var hmm = PoseHMM()
        var pose = HandPose.unknown
        for i in 0..<12 {
            var em: [HandPose: Double] = [:]
            for k in HandPose.allCases { em[k] = 0.05 }
            em[.fist] = 0.7
            let r = hmm.step(emission: em, pinchClosedness: 0.1, now: Double(i) * 0.016, dt: 0.016)
            pose = r.pose
        }
        ok(pose == .fist, "HMM geht auf Faust")

        let short = hand(tipsY: 0.38)
        let ang = GestureClassifier.fingerExtension(short, .index, space: .hd720, conf: [:]).score
        ok(ang >= 0, "Winkel-Streckung definiert bei verkürzter Hand")

        let sameSideA = CGPoint(x: 0.22, y: 0.4)
        let sameSideB = CGPoint(x: 0.28, y: 0.42)
        ok(AspectSpace.hd720.dist(sameSideA, sameSideB) < 0.15, "zwei Hände links bleiben trennbar")

        if fails > 0 {
            fputs("\(fails) GestureTests fehlgeschlagen\n", stderr)
            exit(1)
        }
        print("GestureTests OK")
    }
}

import CoreGraphics
import Foundation
import Vision

/// `swiftc -framework Vision macos/Helios/GestureClassifier.swift macos/Helios/CoordMath.swift macos/HeliosTests/GestureTests.swift -o /tmp/g && /tmp/g`

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

        // Peace vor Pinzette: Daumen klebt am Zeigefinger, Ring/Klein sind zu.
        var peace = hand(tipsY: 0.72)
        peace[.ringTip] = CGPoint(x: 0.55, y: 0.32)
        peace[.ringPIP] = CGPoint(x: 0.54, y: 0.33)
        peace[.littleTip] = CGPoint(x: 0.59, y: 0.32)
        peace[.littlePIP] = CGPoint(x: 0.58, y: 0.33)
        peace[.thumbTip] = CGPoint(x: 0.43, y: 0.70)
        let peacePinch = hypot(0.44 - 0.43, 0.72 - 0.70)
        ok(GestureClassifier.classify(joints: peace, pinch: peacePinch) == .peace, "Peace vor Pinzette")

        var point = hand(tipsY: 0.32)
        point[.indexTip] = CGPoint(x: 0.44, y: 0.72)
        point[.indexPIP] = CGPoint(x: 0.45, y: 0.50)
        ok(GestureClassifier.classify(joints: point, pinch: 0.22) == .point, "Zeigen vor Pinzette")

        var gate = PinchGate()
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
        ok(step(pinchJ, n: 4), "Gate schließt bei Pinzette")
        var gone = pinchJ
        gone.removeValue(forKey: .thumbTip)
        gone.removeValue(forKey: .indexTip)
        ok(step(gone, n: 3), "Gate bleibt zu wenn Spitzen fehlen")
        ok(!step(gone, n: 24), "Gate öffnet nach fehlenden Spitzen (nicht ewig zu)")
        ok(!step(open, n: 6), "Gate öffnet wieder")

        ok(GestureMath.isHorizontalSwipe(dx: 0.20, dy: 0.04, dt: 0.22), "Wischen horizontal")
        ok(!GestureMath.isHorizontalSwipe(dx: 0.20, dy: 0.18, dt: 0.22), "Wischen zu diagonal")
        ok(!GestureMath.isHorizontalSwipe(dx: 0.20, dy: 0.02, dt: 0.08), "Wischen zu kurz")

        ok(GestureMath.fling(dx: 0.02, dy: 0.20, speed: 1.2, dist: 0.20) == .throwUp, "Werfen oben")
        ok(GestureMath.fling(dx: 0.02, dy: -0.20, speed: 1.2, dist: 0.20) == .minimize, "Werfen unten")
        ok(GestureMath.fling(dx: -0.20, dy: 0.02, speed: 1.2, dist: 0.20) == .dockLeft, "Werfen links")
        ok(GestureMath.fling(dx: 0.20, dy: 0.02, speed: 1.2, dist: 0.20) == .dockRight, "Werfen rechts")
        ok(GestureMath.fling(dx: 0.12, dy: 0.12, speed: 1.2, dist: 0.17) == .none, "Werfen diagonal tot")
        ok(GestureMath.fling(dx: 0.20, dy: 0.0, speed: 0.1, dist: 0.20) == .none, "Werfen zu langsam")
        ok(GestureMath.killHold >= 0.5, "Not-Aus nicht unter 0.5 s")
        ok(GestureMath.pinchClickMin >= 0.12, "Klick-Fenster nicht zu kurz")
        ok(GestureMath.pinchDragPalm >= 0.05, "Drag-Schwelle")
        ok(GestureMath.missingTipsOpen >= 0.25 && GestureMath.missingTipsOpen < 0.6, "fehlende Spitzen Timeout")
        ok(GestureMath.rearmHold > GestureMath.armHold, "Not-Aus-Scharf länger als normales Scharf")
        ok(GestureMath.swipeTrail < 0.4, "Wisch-Trail kurz genug gegen Cursor")
        ok(GestureMath.palmDead >= 0.012, "palmDead schluckt Atem-Jitter")
        ok(GestureMath.deadMan >= 6, "Dead-Man Idle")
        ok(GestureMath.clickCooldown >= 0.12, "Klick-Cooldown")
        ok(GestureMath.swipeCooldown >= 0.35, "Wisch-Cooldown")
        ok(GestureMath.peaceHold >= 0.5, "Peace-Hold")
        ok(GestureMath.thumbsHold >= 0.5, "Daumen-Hold")
        ok(GestureMath.flingCenter >= 0.12, "Fling-Mitte tot")
        ok(GestureMath.palmStillHold >= 0.15, "Stillstand-Halt")
        ok(GestureMath.mapSmooth > 0.4 && GestureMath.mapSmooth < 0.7, "Homographie-Glättung 0,55")
        ok(GestureMath.pinchClickMaxPx >= 10, "Klick nur bei stiller Pinzette")
        ok(abs(GestureMath.pinchClickTravelPx(dt: 0.016, mapped: true) - 12) < 0.5, "24 fps Map 12 px")
        ok(abs(GestureMath.pinchClickTravelPx(dt: 0.125, mapped: true) - 20) < 0.5, "8 fps Map 20 px")
        ok(abs(GestureMath.pinchClickTravelPx(dt: 0.125, mapped: false) - 28) < 0.5, "8 fps Relativ 28 px")
        ok(abs(GestureMath.pinchClickTravelPx(dt: 0.125, mapped: false, palmScale: 0.06) - 34) < 0.5, "ferne Hand 34 px")
        ok(GestureMath.pinchClickTravelPx(dt: 0.20, mapped: false, palmScale: 0.05) <= 36, "Cap 36 px")
        ok(!GestureMath.axBudgetSkip(visionMs: 10), "Vision 10 ms AX frei")
        ok(GestureMath.axBudgetSkip(visionMs: 19), "24 fps Vision 19 ms Probe skip")
        ok(!GestureMath.axBudgetSkip(visionMs: 19, dt: 0.125), "8 fps AX bleibt — MAGNET")
        ok(abs(GestureMath.pinchCloseRatio(scale: 0.12) - 0.33) < 0.001, "nahe Hand Close 0,33")
        ok(abs(GestureMath.pinchCloseRatio(scale: 0.06) - 0.40) < 0.001, "ferne Hand Close 0,40")
        ok(abs(GestureMath.pinchKeepRatioFor(scale: 0.06) - 0.56) < 0.001, "ferne Hand Keep 0,56")
        ok(
            GestureMath.pinchKeepsGrab(held: true, closed: false, ratio: 0.50, fisting: false, rebind: false, palmScale: 0.06),
            "ferne Hand Atmen 0,50 hält Grab"
        )
        ok(
            !GestureMath.pinchKeepsGrab(held: true, closed: false, ratio: 0.50, fisting: false, rebind: false, palmScale: 0.12),
            "nahe Hand 0,50 lässt Grab"
        )
        let pred = GestureMath.predictPalm(
            current: CGPoint(x: 0.50, y: 0.50),
            prev: CGPoint(x: 0.40, y: 0.50),
            dt: 0.125
        )
        ok(abs(pred.x - 0.57) < 0.001, "Predictor 0,7 Frame voraus (ist \(pred.x))")
        ok(GestureMath.predictPalm(current: CGPoint(x: 0.5, y: 0.5), prev: nil, dt: 0.125).x == 0.5, "ohne prev kein Predict")
        ok(GestureMath.swipeBlockedByPointer(dx: 0.16, pointerMoving: true), "Wischen vs Cursor blockiert")
        ok(!GestureMath.swipeBlockedByPointer(dx: 0.40, pointerMoving: true), "klarer Flick darf wischen")
        ok(!GestureMath.swipeBlockedByPointer(dx: 0.16, pointerMoving: false), "still: Wischen frei")
        ok(GestureMath.unknownPalmBind >= 0.18, "Unbekannt-Bindung über Palm")
        ok(GestureMath.scalePalmDead >= 0.03, "Scale-Palmen-Totzone")
        ok(GestureMath.scaleMoved(old: 0.40, span: 0.50), "Scale Rel 0,08 plus Totzone")
        ok(!GestureMath.scaleMoved(old: 0.40, span: 0.42), "Scale-Jitter unter Deadband")
        ok(GestureMath.nearFlingClick(speed: 0.30), "fast Wurf kein Klick")
        ok(!GestureMath.nearFlingClick(speed: 0.10), "langsam darf klicken")
        ok(!GestureMath.nearFlingClick(speed: 0.50), "über flingMinSpeed ist Fling, nicht Guard")
        ok(GestureMath.pinchDownSpeed >= 0.15 && GestureMath.pinchDownSpeed < GestureMath.flingMinSpeed, "Down-Speed unter Fling")
        ok(GestureMath.pinchDownBlocked(speed: 0.35), "Palm-Speed 0,35 blockt Down")
        ok(!GestureMath.pinchDownBlocked(speed: 0.05), "still darf Down")
        ok(!GestureMath.pinchDownBlocked(speed: GestureMath.pinchDownSpeed), "an der Schwelle darf Down")
        ok(GestureMath.mapDriftResidual >= 400, "Residual-Banner Schwelle")
        ok(GestureMath.mapDriftHold >= 1.5, "Residual 2 s halten")
        ok(GestureMath.flingClickGuard >= 0.6 && GestureMath.flingClickGuard < 1, "Fling-Klick-Guard")
        ok(GestureMath.flingWindow >= 0.08 && GestureMath.flingWindow <= 0.18, "Fling-Fenster ~120 ms")
        ok(GestureMath.pullToward >= 0.08, "Heranziehen Palm-Y")
        ok(GestureMath.lumaSkip > 0 && GestureMath.lumaSkip <= 0.10, "Luma-Gate")
        ok(GestureMath.killGrace >= 0.10 && GestureMath.killGrace < 0.22, "Not-Aus-Grace unter 0,22 s")
        ok(GestureMath.grabAbortHold >= 0.16 && GestureMath.grabAbortHold <= 0.35, "Grab-Abort nicht erben")
        ok(GestureMath.peaceEdge >= 0.06 && GestureMath.peaceEdge <= 0.12, "Peace-Rand")
        ok(GestureMath.overlayDarkHold >= 0.30 && GestureMath.overlayDarkHold <= 0.60, "Overlay-Dunkel 0,4 s")
        ok(abs(GestureMath.mapGain(residual: 0) - 1) < 0.01, "Residual 0 → Gain 1")
        ok(abs(GestureMath.mapGain(residual: 240) - 1) < 0.01, "Residual 240 → Gain 1")
        ok(abs(GestureMath.mapGain(residual: 480) - GestureMath.mapGainFloor) < 0.01, "Residual 480 → Floor")
        ok(GestureMath.mapGain(residual: 360) < 0.85 && GestureMath.mapGain(residual: 360) > 0.40, "Residual 360 dämpft")
        ok(GestureMath.mapGainFloor >= 0.25 && GestureMath.mapGainFloor <= 0.50, "mapGainFloor")
        ok(GestureMath.flingWindowMul >= 2 && GestureMath.flingWindowMul <= 3, "Fling 2,5× dt")

        let holdThenFlick: [(t: TimeInterval, x: CGFloat, y: CGFloat)] = [
            (0.00, 0.40, 0.40),
            (0.20, 0.40, 0.40),
            (0.40, 0.40, 0.40),
            (0.48, 0.40, 0.52),
            (0.52, 0.40, 0.62)
        ]
        let flick = GestureMath.trailMotion(holdThenFlick)
        ok(flick.speed > GestureMath.flingMinSpeed, "120-ms-Flick über MinSpeed (ist \(flick.speed))")
        ok(flick.dy > 0.08, "Flick-dy aus dem Fenster, nicht 0,5 s Hold")
        let whole = GestureMath.fling(dx: 0.00, dy: 0.22, speed: 0.30, dist: 0.22)
        ok(whole == .none, "0,5-s-Mittel wäre zu langsam für denselben Wurf")
        let empty = GestureMath.trailMotion([])
        ok(empty.speed == 0 && empty.dist == 0, "leerer Trail")
        let sparse: [(t: TimeInterval, x: CGFloat, y: CGFloat)] = [
            (0.00, 0.40, 0.40),
            (0.12, 0.40, 0.52),
            (0.25, 0.40, 0.68)
        ]
        let slow = GestureMath.trailMotion(sparse)
        ok(slow.speed > GestureMath.flingMinSpeed, "8-fps-Flick über MinSpeed (ist \(slow.speed))")
        ok(slow.dy > 0.08, "8-fps-Flick dy aus den letzten Samples")
        let slowHold: [(t: TimeInterval, x: CGFloat, y: CGFloat)] = [
            (0.00, 0.40, 0.40),
            (0.13, 0.40, 0.40),
            (0.26, 0.40, 0.40),
            (0.39, 0.40, 0.52),
            (0.52, 0.40, 0.68)
        ]
        let adaptWin = GestureMath.adaptiveFlingWindow(slowHold)
        ok(adaptWin >= 0.25, "adaptives Fenster ≥ 2,5 × 0,13 s (ist \(adaptWin))")
        let adapt = GestureMath.trailMotion(slowHold)
        ok(adapt.speed > GestureMath.flingMinSpeed, "adaptiver 8-fps-Flick (ist \(adapt.speed))")
        ok(adapt.dy > 0.10, "adaptiver Flick nutzt nicht den 0,5-s-Hold")

        ok(
            GestureMath.actorRebind(
                lostID: "R",
                candidates: [(id: "L", x: 0.41, y: 0.50)],
                lastX: 0.40,
                lastY: 0.51
            ) == "L",
            "Chirality-Flip gleiche Palm rebindet"
        )
        ok(
            GestureMath.actorRebind(
                lostID: "R",
                candidates: [(id: "L", x: 0.90, y: 0.90)],
                lastX: 0.10,
                lastY: 0.10
            ) == nil,
            "fremde Hand erbt den Grab nicht"
        )
        ok(
            GestureMath.actorRebind(
                lostID: "R",
                candidates: [(id: "L", x: 0.12, y: 0.80), (id: "U-0", x: 0.41, y: 0.49)],
                lastX: 0.40,
                lastY: 0.50
            ) == "U-0",
            "nächste Palm, nicht primary"
        )
        ok(abs(GestureMath.oneEuroCutoff(base: 1.4, dt: 0.04) - 1.4) < 0.01, "24 fps Pointer-Cutoff")
        ok(GestureMath.oneEuroCutoff(base: 1.4, dt: 0.125) > 2.0, "8 fps Pointer-Cutoff höher")

        ok(GestureMath.pinchCloseVel(dt: 0.016) < -1.8 && GestureMath.pinchCloseVel(dt: 0.016) > -2.2, "24 fps Close-Vel −2")
        ok(GestureMath.pinchCloseVel(dt: 0.125) > -0.50 && GestureMath.pinchCloseVel(dt: 0.125) < -0.20, "8 fps Close-Vel weicher")
        ok(GestureMath.palmBind(scale: 0.05) <= 0.10, "ferne Hand enger Slot")
        ok(GestureMath.palmBind(scale: 0.16) >= 0.20, "nahe Hand volle Bindung")
        ok(GestureMath.palmBind(scale: 1.0) <= GestureMath.unknownPalmBind, "Bind-Deckel")
        let swipe8: [(t: TimeInterval, x: CGFloat, y: CGFloat)] = [
            (0.00, 0.60, 0.50),
            (0.13, 0.48, 0.50),
            (0.26, 0.34, 0.51)
        ]
        ok(GestureMath.adaptiveSwipeTrail(swipe8) >= 0.35, "8 fps Wisch-Fenster ≥ 3,2 × dt")
        ok(
            GestureMath.isHorizontalSwipe(dx: 0.20, dy: 0.04, dt: 0.13, medianDt: 0.125),
            "8 fps Wischen mit 2 Samples"
        )
        ok(
            !GestureMath.isHorizontalSwipe(dx: 0.20, dy: 0.02, dt: 0.08, medianDt: 0.016),
            "24 fps Wischen zu kurz bleibt tot"
        )
        ok(GestureMath.swipeMinDt(medianDt: 0.125) <= 0.13, "8 fps minDt ≤ 125 ms")
        ok(GestureMath.swipeTrailMul >= 3 && GestureMath.swipeTrailMul <= 4, "Wisch 3,2× dt")
        ok(GestureMath.sampleDtCap >= 0.18 && GestureMath.sampleDtCap <= 0.25, "Sample-dt-Deckel lässt 8 fps durch")
        ok(abs(GestureMath.medianDt(swipe8) - 0.13) < 0.01, "8 fps medianDt")
        ok(abs(GestureMath.sampleDt(now: 1.125, last: 1.0) - 0.125) < 0.001, "sampleDt 8 fps ungekappt")
        ok(GestureMath.sampleDt(now: 1.5, last: 1.0) <= GestureMath.sampleDtCap, "sampleDt Deckel")

        ok(GestureMath.pinchOpenVel(dt: 0.016) > 0.35 && GestureMath.pinchOpenVel(dt: 0.016) < 0.45, "24 fps Open-Vel 0,40")
        ok(GestureMath.pinchOpenVel(dt: 0.125) > 0.04 && GestureMath.pinchOpenVel(dt: 0.125) < 0.08, "8 fps Open-Vel weicher")
        ok(GestureMath.slotHold >= 0.50 && GestureMath.slotHold <= 0.80, "Slot-TTL 0,60 s")
        ok(GestureMath.slotHold > GestureMath.grabAbortHold, "Slot überlebt Abort-Hold")
        ok(GestureMath.confidenceFloor(fallback: true) == GestureMath.continuityConfidence, "Continuity-Floor")
        ok(GestureMath.confidenceFloor(fallback: false) == GestureMath.builtInConfidence, "Built-in-Floor")
        ok(GestureMath.pointerGainMul(dt: 0.04) == 1, "24 fps Gain voll")
        ok(GestureMath.pointerGainMul(dt: 0.125) == GestureMath.continuityGainMul, "8 fps Gain dämpft")
        ok(GestureMath.openBeforeArm >= 2, "Faust-Scharf braucht vorher offene Hand")
        ok(GestureMath.openMemory >= 1.5 && GestureMath.openMemory <= 3.0, "sawOpen 2 s Memory")
        ok(GestureMath.pinchOpenNeed(dt: 0.016) == 3, "24 fps Open-Streak 3")
        ok(GestureMath.pinchOpenNeed(dt: 0.125) == 1, "8 fps Open-Streak 1")
        ok(GestureMath.pinchCloseNeed(dt: 0.016) == 2, "Close-Streak 2")
        ok(GestureMath.pinchCloseNeed(dt: 0.125) == 1, "8 fps Close 1")
        ok(GestureMath.pinchCloseNeed(dt: 0.067) == 1, "15 fps Close wie 8")
        ok(GestureMath.pinchPoseHoldNeed(dt: 0.016) == 2, "24 fps Pinch-Hold 2")
        ok(GestureMath.pinchPoseHoldNeed(dt: 0.125) == 1, "8 fps Pinch-Hold 1")
        ok(GestureMath.pinchPoseHoldNeed(dt: 0.067) == 1, "15 fps Pinch-Hold wie 8")
        ok(GestureMath.poseHoldNeed(dt: 0.016) == 4, "24 fps Pose-Hold 4")
        ok(GestureMath.poseHoldNeed(dt: 0.125) == 2, "8 fps Pose-Hold 2")
        ok(GestureMath.poseHoldNeed(dt: 0.067) == 2, "15 fps Pose-Hold wie 8")
        ok(GestureMath.ghostHands(emptyFor: 0.05), "ein Continuity-Frame Ghost")
        ok(!GestureMath.ghostHands(emptyFor: 0.50), "0,50 s kein Ghost")
        ok(!GestureMath.ghostHands(emptyFor: 0.61), "0,61 s kein Latch-Ghost")
        ok(!GestureMath.ghostHands(emptyFor: 2.0), "2 s kein Ghost")
        ok(!GestureMath.ghostHands(emptyFor: 4.1), "nach Latch kein Ghost")
        ok(!GestureMath.ghostHands(emptyFor: -0.01), "negativ kein Ghost")
        ok(!GestureMath.ghostHands(emptyFor: 0.61, hold: GestureMath.slotHold), "HUD-Hold 0,60 tot")
        ok(GestureMath.ghostHUD(id: "S1", remaining: 0.4) == "S1 Ghost 0.4 s", "Ghost-HUD Slot")
        ok(GestureMath.ghostHUD(id: nil, remaining: 0.2) == "Ghost 0.2 s", "Ghost-HUD ohne Slot")
        let winPos = CGPoint(x: 100, y: 200)
        let winSize = CGSize(width: 400, height: 300)
        let center = CGPoint(x: 300, y: 350)
        let aroundCenter = GestureMath.resizeOrigin(pos: winPos, size: winSize, scale: 1.10, anchor: center)
        ok(abs(aroundCenter.x - (100 - 20)) < 0.5, "Scale um Mitte = alte Formel x")
        ok(abs(aroundCenter.y - (200 - 15)) < 0.5, "Scale um Mitte = alte Formel y")
        let corner = CGPoint(x: 100, y: 200)
        let aroundCorner = GestureMath.resizeOrigin(pos: winPos, size: winSize, scale: 1.10, anchor: corner)
        ok(abs(aroundCorner.x - 100) < 0.01, "Scale am Cursor-Ecke hält x")
        ok(abs(aroundCorner.y - 200) < 0.01, "Scale am Cursor-Ecke hält y")
        ok(GestureMath.watchdogGainMul(slow: true) == GestureMath.watchdogGain, "Watchdog Gain halb")
        ok(GestureMath.watchdogGainMul(slow: false) == 1, "Watchdog aus voll")
        ok(GestureMath.mapSmoothAlpha(dt: 0.04) == GestureMath.mapSmooth, "24 fps mapSmooth")
        ok(GestureMath.mapSmoothAlpha(dt: 0.125) == GestureMath.mapSmoothContinuity, "8 fps mapSmooth höher")
        ok(GestureMath.lockFrameRate(60) == 60, "60 fps Format bleibt 60")
        ok(GestureMath.lockFrameRate(24) == 24, "24 fps bleibt 24")
        ok(GestureMath.lockFrameRate(8) == 8, "Continuity 8 bleibt 8")
        ok(!GestureMath.captureForcesLandscapeRight(), "Mac-Cam kein iOS-landscapeRight")
        ok(!GestureMath.physicalCaptureRotation(), "kein physisches Drehen (Latenz/Cursor)")
        ok(GestureMath.videoRotationAngleFallback() == 0, "Fallback 0° aufrecht")
        ok(GestureMath.previewOrientationRaw(width: 1280, height: 720) == 1, "Landscape Vision up")
        ok(GestureMath.previewOrientationRaw(width: 720, height: 1280) == 6, "Portrait Vision right")
        ok(GestureMath.orientedPixelSize(width: 720, height: 1280, orientationRaw: 6).width == 1280, "90° tauscht Breite")
        ok(GestureMath.orientedPixelSize(width: 1280, height: 720, orientationRaw: 1).width == 1280, "up behält Größe")
        ok(GestureMath.videoRotationAngleFallback() == 0, "Fallback 0° aufrecht")
        ok(GestureMath.visionOrientationRaw(physicalRotationApplied: true, angle: 90) == 1, "physisch 90° → Vision up")
        ok(GestureMath.visionOrientationRaw(physicalRotationApplied: true, angle: 180) == 1, "physisch 180° → Vision up")
        ok(GestureMath.visionOrientationRaw(physicalRotationApplied: false, angle: 0) == 1, "Tag 0° → up")
        ok(GestureMath.visionOrientationRaw(physicalRotationApplied: false, angle: 90) == 6, "Tag 90° → right")
        ok(GestureMath.visionOrientationRaw(physicalRotationApplied: false, angle: 180) == 3, "Tag 180° → down")
        ok(GestureMath.visionOrientationRaw(physicalRotationApplied: false, angle: 270) == 8, "Tag 270° → left")

        let s720_24 = GestureMath.formatScore(width: 1280, height: 720, fps: 24)
        let s720_60 = GestureMath.formatScore(width: 1280, height: 720, fps: 60)
        let s360_60 = GestureMath.formatScore(width: 640, height: 360, fps: 60)
        let s540_15 = GestureMath.formatScore(width: 960, height: 540, fps: 15)
        let s800_8 = GestureMath.formatScore(width: 1280, height: 800, fps: 8)
        ok(s720_24 > s360_60, "720p@24 schlägt 360p@60")
        ok(s720_60 > s720_24, "720p@60 schlägt 720p@24")
        ok(s540_15 > s800_8, "540p@15 schlägt 800p@8")
        ok(GestureMath.formatScore(width: 320, height: 240, fps: 30) < 0, "zu klein unbrauchbar")
        ok(s720_24 > 0 && s540_15 > 0, "brauchbare Formate positiv")

        var gate8 = PinchGate()
        var t8: TimeInterval = 2
        func step8(_ joints: [VNHumanHandPoseObservation.JointName: CGPoint], n: Int) -> Bool {
            var c: [VNHumanHandPoseObservation.JointName: Float] = [:]
            for k in joints.keys { c[k] = 0.9 }
            var closed = false
            for _ in 0..<n {
                t8 += 0.125
                closed = gate8.update(raw: joints, conf: c, now: t8).closed
            }
            return closed
        }
        ok(step8(pinchJ, n: 3), "8 fps PinchGate schließt in 3 Frames (dt=0,125)")
        ok(!step8(open, n: 3), "8 fps PinchGate öffnet in 2 Frames")

        let near = CGPoint(x: 0.40, y: 0.50)
        let far = CGPoint(x: 0.90, y: 0.90)
        ok(hypot(near.x - 0.41, near.y - 0.51) < GestureMath.palmBind(scale: 0.12), "Palm-Slot gleiche Hand")
        ok(hypot(far.x - 0.10, far.y - 0.10) > GestureMath.palmBind(scale: 0.12), "Palm-Slot fremde Hand")

        // Geschlossene Spitzen ohne Reach: Pinch, nicht Faust (sonst Scharf während Pinzette).
        var closedFist = hand(tipsY: 0.32)
        closedFist[.thumbTip] = CGPoint(x: 0.46, y: 0.32)
        closedFist[.indexTip] = CGPoint(x: 0.47, y: 0.33)
        let closedDist = hypot(0.46 - 0.47, 0.32 - 0.33)
        ok(GestureClassifier.classify(joints: closedFist, pinch: closedDist) == .pinch, "enge Spitzen = Pinzette, nicht Faust")

        var euro = PointerEuro(minCutoff: 1.0, beta: 0.0, dCutoff: 1.0)
        let first = euro.filter(10, now: 0)
        ok(abs(first - 10) < 0.01, "PointerEuro erster Sample")
        let second = euro.filter(20, now: 0.1)
        ok(second > 10 && second < 20, "PointerEuro folgt ohne vollen Sprung")
        euro.reset()
        ok(abs(euro.filter(99, now: 5) - 99) < 0.01, "PointerEuro reset")

        ok(GestureMath.swipeEligible(isOpenPalm: true, isPeace: false, openScore: 4), "offene Hand wischt")
        ok(!GestureMath.swipeEligible(isOpenPalm: false, isPeace: true, openScore: 2), "Peace wischt nicht")
        ok(!GestureMath.swipeEligible(isOpenPalm: false, isPeace: true, openScore: 3), "Peace auch mit 3 Fingern nicht")
        ok(GestureMath.swipeEligible(isOpenPalm: false, isPeace: false, openScore: 3), "3 Finger ohne Peace wischt")
        ok(!GestureMath.swipeEligible(isOpenPalm: false, isPeace: false, openScore: 1), "Zeigen wischt nicht")
        ok(GestureMath.pinchSettled(held: 0.12), "Settle an pinchClickMin")
        ok(!GestureMath.pinchSettled(held: 0.08), "vor Settle kein Drag")
        let settle0 = CGPoint(x: 0.40, y: 0.50)
        ok(!GestureMath.pinchDragMoved(from: settle0, to: CGPoint(x: 0.43, y: 0.51)), "Zielen 0,03 kein Drag")
        ok(GestureMath.pinchDragMoved(from: settle0, to: CGPoint(x: 0.50, y: 0.50)), "0,10 nach Settle ist Drag")
        ok(GestureMath.scaleHandCount(closed: [true, false]) == 1, "Scale zählt nur PinchGate")
        ok(GestureMath.scaleHandCount(closed: [true, true]) == 2, "zwei Gates = Scale")
        ok(GestureMath.scaleBlocksGrab(pinchHeld: true, closedCount: 2), "zwei Gates gewinnen gegen Grab")
        ok(GestureMath.scaleBlocksGrab(pinchHeld: false, closedCount: 2), "zwei Gates ohne Grab = Scale")
        ok(!GestureMath.scaleBlocksGrab(pinchHeld: false, closedCount: 1), "eine Pinzette kein Scale")
        ok(GestureMath.scaleKeepsSpan(old: 0.40, span: 0.55, gated: true) == 0.40, "Cooldown hält Span")
        ok(GestureMath.scaleKeepsSpan(old: 0.40, span: 0.55, gated: false) == 0.55, "nach Gate neuer Span")
        ok(GestureMath.swipeGraceID(openID: "S1", lastID: "S2", lastStillPresent: true) == "S1", "offene Hand vor Grace")
        ok(GestureMath.swipeGraceID(openID: nil, lastID: "S1", lastStillPresent: true) == "S1", "Grace hält dieselbe Hand")
        ok(GestureMath.swipeGraceID(openID: nil, lastID: "S1", lastStillPresent: false) == nil, "fremde/weg keine Grace")
        ok(GestureMath.ghostLeavesRebase(), "Ghost lässt Rebase für den ersten Live-Frame")
        ok(GestureMath.killCounts(x: 0.50, y: 0.50), "Mitte zählt für Not-Aus")
        ok(!GestureMath.killCounts(x: 0.02, y: 0.50), "Rand-x (Schulter) kein Not-Aus")
        ok(!GestureMath.killCounts(x: 0.50, y: 0.97), "Rand-y (Knie) kein Not-Aus")
        ok(!GestureMath.killCounts(x: 0.99, y: 0.50), "rechter Rand kein Not-Aus")
        ok(GestureMath.killCounts(x: 0.20, y: 0.20), "innen zählt")
        ok(GestureMath.killKeepsCursor(), "Not-Aus-Windup injiziert den Cursor")
        ok(GestureMath.killEdge == GestureMath.peaceEdge, "Kill-Rand = Peace-Rand")
        let down = CGPoint(x: 120, y: 80)
        let jitter = CGPoint(x: 128, y: 86)
        ok(GestureMath.clickReleasePoint(down: down, current: jitter, wasDrag: false) == down, "Klick-Up am Down")
        ok(GestureMath.clickReleasePoint(down: down, current: jitter, wasDrag: true) == jitter, "Drag-Up bleibt current")
        ok(GestureMath.clickSettleProgress(held: 0) == 0, "Settle 0 am Gate")
        ok(abs(GestureMath.clickSettleProgress(held: 0.06) - 0.5) < 0.001, "Settle halb bei 60 ms")
        ok(GestureMath.clickSettleProgress(held: 0.12) == 1, "Settle voll an pinchClickMin")
        ok(GestureMath.clickSettleProgress(held: 0.50) == 1, "Settle klemmt bei 1")
        ok(GestureMath.clickSettleStrokeEnd(nil) == 1, "ohne Settle voller Ring")
        ok(GestureMath.clickSettleStrokeEnd(0) == 0.04, "Settle 0 zeigt 4 % Ring")
        ok(GestureMath.clickSettleStrokeEnd(1) == 1, "Settle 1 voller Ring")
        ok(GestureMath.pinchKeepsGrab(held: true, closed: false, ratio: 0.40, fisting: false, rebind: false), "Atmen 0,40 hält Grab")
        ok(GestureMath.pinchKeepsGrab(held: true, closed: false, ratio: 0.47, fisting: false, rebind: false), "0,47 unter Keep")
        ok(!GestureMath.pinchKeepsGrab(held: true, closed: false, ratio: 0.60, fisting: false, rebind: false), "0,60 öffnet")
        ok(GestureMath.pinchKeepsGrab(held: false, closed: true, ratio: 0.30, fisting: false, rebind: false), "Gate-Schluss startet Grab")
        ok(!GestureMath.pinchKeepsGrab(held: false, closed: false, ratio: 0.40, fisting: false, rebind: false), "ohne Gate kein Start bei 0,40")
        ok(GestureMath.pinchKeepsGrab(held: true, closed: false, ratio: 0.70, fisting: false, rebind: true), "Rebind hält")
        ok(GestureMath.axLocksClick("AXButton"), "Button lockt Klick")
        ok(GestureMath.axLocksClick("AXLink"), "Link lockt Klick")
        ok(GestureMath.axLocksClick("AXTextField"), "Textfeld lockt Klick")
        ok(GestureMath.axLocksClick("AXCheckBox"), "Checkbox lockt Klick")
        ok(!GestureMath.axLocksClick("AXWindow"), "Fenster darf Drag")
        ok(!GestureMath.axLocksClick("AXGroup"), "Group darf Drag")
        ok(!GestureMath.axLocksClick(nil), "ohne Rolle kein Lock")
        ok(GestureMath.axLocksClick("AXCloseButton"), "Close-Button enthält Button")
        ok(abs(GestureMath.pointerAccel(0)) < 1e-6, "Accel 0")
        ok(abs(GestureMath.pointerAccel(0.02)) < 0.02, "kleine Wege gedämpft")
        ok(abs(GestureMath.pointerAccel(0.10)) > abs(GestureMath.pointerAccel(0.02)) * 3, "große Wege flickig")
        ok(GestureMath.pointerAccel(-0.10) < 0, "Accel Vorzeichen")
        ok(abs(GestureMath.depthGain(palmScale: 0.12) - 1) < 0.01, "nahe Palme Gain 1")
        ok(GestureMath.depthGain(palmScale: 0.05) > 1.5, "ferne Palme mehr Gain")
        ok(GestureMath.depthGain(palmScale: 0.01) <= 2.4, "Depth klemmt 2,4")
        ok(GestureMath.calibBlocksArm(active: true, testMode: false), "Kalib blockt Scharf")
        ok(!GestureMath.calibBlocksArm(active: true, testMode: true), "Testmodus darf")
        ok(!GestureMath.calibBlocksArm(active: false, testMode: false), "ohne Kalib frei")
        ok(GestureMath.killRingOnAllDisplays(), "Kill-Ring jedes Display")
        let btn = CGRect(x: 100, y: 80, width: 40, height: 20)
        ok(GestureMath.pressTarget(cursor: CGPoint(x: 102, y: 81), frame: btn) == CGPoint(x: 120, y: 90), "AX-Mitte statt Rand")
        ok(GestureMath.pressTarget(cursor: CGPoint(x: 400, y: 400), frame: btn) == CGPoint(x: 400, y: 400), "außerhalb kein Warp")
        ok(GestureMath.pressTarget(cursor: CGPoint(x: 10, y: 10), frame: nil) == CGPoint(x: 10, y: 10), "ohne Frame Cursor")
        let win = CGRect(x: 0, y: 0, width: 800, height: 600)
        ok(GestureMath.pressTarget(cursor: CGPoint(x: 102, y: 81), frame: win) == CGPoint(x: 102, y: 81), "Fenster nicht zur Mitte")
        ok(!GestureMath.overlayShowsCursor(mousePaused: true), "Maus-Vorrang Overlay aus")
        ok(GestureMath.overlayShowsCursor(mousePaused: false), "ohne Pause Overlay an")
        let lights = [CGPoint(x: 20, y: 20), CGPoint(x: 44, y: 20), CGPoint(x: 68, y: 20)]
        ok(GestureMath.trafficSnap(cursor: CGPoint(x: 22, y: 24), lights: lights, maxDist: 36) == CGPoint(x: 20, y: 20), "Close-Magnet")
        ok(GestureMath.trafficSnap(cursor: CGPoint(x: 200, y: 200), lights: lights, maxDist: 36) == nil, "weit kein Magnet")
        ok(GestureMath.trafficMaxDist(palmScale: 0.12) >= 36, "Magnet mindestens 36 px")
        ok(GestureMath.clickLockLabel(locks: true) == "BUTTON", "Lock-HUD BUTTON")
        ok(GestureMath.clickLockLabel(locks: false) == "Halten", "ohne Lock Halten")
        ok(GestureMath.axSubroleLocksClick("AXCloseButton"), "Close-Subrole lockt")
        ok(!GestureMath.axSubroleLocksClick("AXStandardWindow"), "Window-Subrole kein Lock")
        ok(GestureMath.pinchHoverProgress(ratio: 0.70, closed: false) == nil, "offen kein Hover")
        ok(GestureMath.pinchHoverProgress(ratio: 0.40, closed: true) == nil, "Gate kein Hover")
        let hover = GestureMath.pinchHoverProgress(ratio: 0.40, closed: false)
        ok(hover != nil && hover! > 0 && hover! < 1, "Hover 0,40 zwischen")
        ok(GestureMath.pinchHoverProgress(ratio: 0.28, closed: false) == 1, "Hover voll an Shut")
        ok(GestureMath.fpsSpark([8, 8, 8, 8]) == "▂▂▂▂", "8 fps Spark niedrig")
        ok(GestureMath.fpsSpark([24, 24, 24, 24]).contains("▆") || GestureMath.fpsSpark([24, 24, 24, 24]).contains("▇") || GestureMath.fpsSpark([24, 24, 24, 24]).contains("█"), "24 fps Spark hoch")
        ok(GestureMath.fpsSpark([]) == "", "ohne Samples leer")
        ok(GestureMath.clutchWhilePinch(pinchHeld: false, mouseDown: false), "ohne Pinch darf Clutch")
        ok(!GestureMath.clutchWhilePinch(pinchHeld: true, mouseDown: false), "Pinch kein Clutch")
        ok(!GestureMath.clutchWhilePinch(pinchHeld: false, mouseDown: true), "Down kein Clutch")
        ok(GestureMath.hitLocksAtGate(startLocked: false, gateLocked: true, settled: true), "Gate-Schluss Button lockt")
        ok(!GestureMath.hitLocksAtGate(startLocked: false, gateLocked: true, settled: false), "vor Gate Start-Rolle")
        ok(GestureMath.hitLocksAtGate(startLocked: true, gateLocked: false, settled: false), "vor Gate Start bleibt")
        ok(!GestureMath.hitLocksAtGate(startLocked: true, gateLocked: false, settled: true), "nach Gate Fenster, nicht Start-Button")
        ok(abs(GestureMath.mapFollowMul(0)) < 1e-6, "mapFollow 0")
        ok(GestureMath.mapFollowMul(0.02) < 0.55, "kleine Homographie-Wege gedämpft")
        ok(GestureMath.mapFollowMul(0.10) > GestureMath.mapFollowMul(0.02) * 1.5, "große Homographie-Wege")
        ok(!GestureMath.pointerFrozenWhile(abortHold: false, mouseDown: false, clickLocked: false, becameDrag: false), "Settle zielt")
        ok(!GestureMath.pointerFrozenWhile(abortHold: false, mouseDown: false, clickLocked: true, becameDrag: false), "Hold vor Down zielt")
        ok(GestureMath.pointerFrozenWhile(abortHold: false, mouseDown: true, clickLocked: true, becameDrag: false), "Down auf Button friert")
        ok(!GestureMath.pointerFrozenWhile(abortHold: false, mouseDown: true, clickLocked: false, becameDrag: false), "Down auf Fenster folgt")
        ok(!GestureMath.pointerFrozenWhile(abortHold: false, mouseDown: true, clickLocked: true, becameDrag: true), "Drag folgt")
        ok(GestureMath.pointerFrozenWhile(abortHold: true, mouseDown: false, clickLocked: false, becameDrag: false), "Abort friert")
        let start = CGPoint(x: 10, y: 10)
        let gatePt = CGPoint(x: 40, y: 18)
        ok(GestureMath.cursorTravelOrigin(start: start, gate: gatePt, settled: false) == start, "vor Gate Start")
        ok(GestureMath.cursorTravelOrigin(start: start, gate: gatePt, settled: true) == gatePt, "nach Gate Zielen")
        ok(GestureMath.clutchInGrace(now: 1.0, until: 1.2), "Grace aktiv")
        ok(!GestureMath.clutchInGrace(now: 1.4, until: 1.2), "Grace vorbei")
        ok(!GestureMath.clutchInGrace(now: 1.0, until: 0), "ohne Grace")
        ok(GestureMath.clutchHUD(frozen: true) == "CLUTCH", "Clutch-HUD")
        ok(GestureMath.clutchHUD(frozen: false) == nil, "ohne Freeze kein Clutch")
        ok(GestureMath.axLocksClick("AXDockItem"), "Dock lockt Klick")
        ok(GestureMath.axLocksClick("AXMenuBarItem"), "Menüleiste lockt Klick")
        ok(GestureMath.axLocksClick("AXMenuBar"), "MenuBar lockt")
        ok(GestureMath.axChromeSkipsTraffic("AXDockItem"), "Dock kein Traffic-Walk")
        ok(GestureMath.axChromeSkipsTraffic("AXMenuBarItem"), "Menü kein Traffic-Walk")
        ok(!GestureMath.axChromeSkipsTraffic("AXButton"), "Button darf Traffic")
        ok(!GestureMath.pressDuringHold(locksClick: false), "Fenster kein Down während Hold")
        ok(GestureMath.pressDuringHold(locksClick: true), "Button Down während Hold")
        ok(GestureMath.clickLockLabel(locks: true, magnet: true) == "MAGNET", "Traffic-HUD MAGNET")
        ok(GestureMath.clickLockLabel(locks: true, magnet: false) == "BUTTON", "ohne Magnet BUTTON")
        let vis = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let snapped = GestureMath.edgeMagnet(
            origin: CGPoint(x: 8, y: 40),
            size: CGSize(width: 400, height: 300),
            vis: vis
        )
        ok(snapped.x == 0, "linker Rand magnetisiert")
        let farEdge = GestureMath.edgeMagnet(
            origin: CGPoint(x: 200, y: 200),
            size: CGSize(width: 400, height: 300),
            vis: vis
        )
        ok(farEdge.x == 200 && farEdge.y == 200, "Mitte kein Magnet")
        let right = GestureMath.edgeMagnet(
            origin: CGPoint(x: 1035, y: 10),
            size: CGSize(width: 400, height: 300),
            vis: vis
        )
        ok(abs(right.x - 1040) < 0.5, "rechter Rand magnetisiert")
        ok(abs(right.y - 0) < 0.5, "unterer Rand magnetisiert")
        ok(abs(GestureMath.axProbeTTL(dt: 0.016) - 0.09) < 0.001, "24 fps Probe 90 ms")
        ok(abs(GestureMath.axProbeTTL(dt: 0.125) - 0.26) < 0.001, "8 fps Probe 2 Frames")
        ok(GestureMath.fistCancelsHold(pinchHeld: true, otherFist: true), "zweite Faust bricht Pinch")
        ok(!GestureMath.fistCancelsHold(pinchHeld: true, otherFist: false), "ohne Faust kein Abbruch")
        ok(!GestureMath.fistCancelsHold(pinchHeld: false, otherFist: true), "ohne Pinch keine Faust-Cancel")
        ok(GestureMath.cmdPeriodCancels(keyCode: 47, command: true), "Cmd-Punkt")
        ok(!GestureMath.cmdPeriodCancels(keyCode: 47, command: false), "Punkt ohne Cmd")
        ok(!GestureMath.cmdPeriodCancels(keyCode: 53, command: true), "Escape ist nicht Cmd-Punkt")
        ok(GestureMath.clickLockRefresh(settled: true, wasLocked: false, nowLocked: true), "nach Gate Button lockt")
        ok(!GestureMath.clickLockRefresh(settled: true, wasLocked: true, nowLocked: false), "nach Gate Fenster löst")
        ok(GestureMath.clickLockRefresh(settled: false, wasLocked: true, nowLocked: false), "vor Gate Start bleibt")
        ok(GestureMath.samePressElement(downRole: "AXButton", downSub: "AXCloseButton", nowRole: "AXButton", nowSub: "AXCloseButton"), "Close bleibt Close")
        ok(!GestureMath.samePressElement(downRole: "AXButton", downSub: "AXCloseButton", nowRole: "AXButton", nowSub: "AXMinimizeButton"), "Close nicht Mini")
        ok(GestureMath.samePressElement(downRole: "AXWindow", downSub: nil, nowRole: "AXButton", nowSub: "AXCloseButton"), "Fenster-Down darf woanders Up")
        let rings = GestureMath.trafficLightRings(lights: lights, magnet: true)
        ok(rings.count == 3, "drei MAGNET-Ringe")
        ok(rings[0].1 == GestureMath.trafficRingRadius, "Ring-Radius")
        ok(GestureMath.trafficLightRings(lights: lights, magnet: false).isEmpty, "ohne Magnet keine Ringe")
        ok(GestureMath.trafficMaxDist(palmScale: 0.08) == 36, "kleine Palme Magnet 36, nicht 52")
        ok(GestureMath.trafficMaxDist(palmScale: 0.12) > 36, "mittlere Palme Magnet > 36")
        ok(abs(GestureMath.pinchClickNeed(dt: 0.125) - 0.18) < 0.001, "8 fps Klick 180 ms")
        ok(abs(GestureMath.pinchClickNeed(dt: 0.016) - 0.09) < 0.001, "24 fps Klick 90 ms")
        ok(!GestureMath.pinchSettled(held: 0.12, need: 0.18), "8 fps 120 ms noch Settle")
        ok(GestureMath.pinchSettled(held: 0.18, need: 0.18), "8 fps 180 ms Down")
        ok(GestureMath.pinchSettled(held: 0.09, need: 0.09), "24 fps 90 ms Down")
        ok(abs(GestureMath.clickSettleProgress(held: 0.09, need: 0.18) - 0.5) < 0.01, "8 fps HUD halb")
        ok(GestureMath.clickSettleProgress(held: 0.18, need: 0.18) == 1, "8 fps HUD voll")
        ok(GestureMath.axProbeSkip(visionRan: false), "Luma-Skip kein AX")
        ok(!GestureMath.axProbeSkip(visionRan: true), "Vision darf AX")
        ok(!GestureMath.continuityStuck(dt: 0.125, hold: 5), "8 fps nicht stuck")
        ok(GestureMath.continuityStuck(dt: 0.25, hold: 4), "4 fps 4 s stuck")
        ok(!GestureMath.continuityStuck(dt: 0.25, hold: 2), "2 s noch nicht")
        ok(GestureMath.spaceMapKey(nil) == "helios.spaceMap", "Legacy-Key")
        ok(GestureMath.spaceMapKey("") == "helios.spaceMap", "leere ID Legacy")
        ok(GestureMath.spaceMapKey("cam-a") == "helios.spaceMap.cam-a", "Kamera-Key")
        ok(GestureMath.spaceMapKey("cam-a") != GestureMath.spaceMapKey("cam-b"), "Continuity ≠ Built-in")
        ok(GestureMath.spaceMapKey("cam-a", screenID: "1") != GestureMath.spaceMapKey("cam-a", screenID: "2"), "Laptop ≠ Extern")
        ok(GestureMath.spaceMapKey("cam-a", screenID: "1") != GestureMath.spaceMapKey("cam-a"), "Screen-Key ≠ Kamera-Key")
        ok(GestureMath.spaceMapKey(nil, screenID: "1") == "helios.spaceMap.screen.1", "Screen ohne Kamera")
        let miss0 = GestureMath.clickLockMissHold(wasLocked: true, nowLocked: false, misses: 0)
        ok(miss0.locked && miss0.misses == 1, "AX-Flicker 1. Frame hält BUTTON")
        let miss1 = GestureMath.clickLockMissHold(wasLocked: true, nowLocked: false, misses: 1)
        ok(miss1.locked && miss1.misses == 2, "2. Miss hält noch")
        let miss2 = GestureMath.clickLockMissHold(wasLocked: true, nowLocked: false, misses: 2)
        ok(!miss2.locked && miss2.misses == 0, "3. Miss droppt")
        let missHit = GestureMath.clickLockMissHold(wasLocked: true, nowLocked: true, misses: 1)
        ok(missHit.locked && missHit.misses == 0, "Treffer setzt Miss zurück")
        ok(GestureMath.axProbeSkip(visionRan: false) && !GestureMath.axProbeSkip(visionRan: true), "Skip nur ohne Vision")

        let dark = GestureMath.lumaSkipHold(dark: true, skip: false, brightStreak: 3)
        ok(dark.skip && dark.streak == 0, "Dunkel skip, Streak 0")
        let b1 = GestureMath.lumaSkipHold(dark: false, skip: true, brightStreak: 0)
        ok(b1.skip && b1.streak == 1, "1. hell hält AX-Skip")
        let b2 = GestureMath.lumaSkipHold(dark: false, skip: true, brightStreak: 1)
        ok(!b2.skip && b2.streak == 0, "2. hell AX wieder")
        let already = GestureMath.lumaSkipHold(dark: false, skip: false, brightStreak: 1)
        ok(!already.skip && already.streak == 0, "schon hell bleibt AX")
        ok(GestureMath.formatPrefers(score: 100, minFps: 24, otherScore: 100, otherMinFps: 1), "Tie: höheres minFps")
        ok(!GestureMath.formatPrefers(score: 100, minFps: 1, otherScore: 100, otherMinFps: 24), "Tie: niedrigeres minFps verliert")
        ok(GestureMath.formatPrefers(score: 110, minFps: 1, otherScore: 100, otherMinFps: 24), "Score sticht minFps")
        ok(!GestureMath.formatPrefers(score: 100, minFps: 30, otherScore: 110, otherMinFps: 1), "Score verliert trotz minFps")
        ok(abs(GestureMath.medianFps([24, 24, 24, 8, 24, 24, 24, 24]) - 24) < 0.01, "Median nicht letztes Fenster")
        ok(abs(GestureMath.medianFps([4, 4, 4, 24]) - 4) < 0.01, "Median 4 fps")
        ok(GestureMath.cameraSlowNow(medianFps: 4), "4 fps slow")
        ok(!GestureMath.cameraSlowNow(medianFps: 8), "8 fps Continuity nicht slow")
        ok(!GestureMath.cameraSlowNow(medianFps: 0), "kein Sample nicht slow")
        ok(GestureMath.hudDims(idleFor: 8, armed: false), "8 s Idle dim")
        ok(!GestureMath.hudDims(idleFor: 7.9, armed: false), "unter 8 s voll")
        ok(!GestureMath.hudDims(idleFor: 20, armed: true), "scharf kein Dim")
        ok(abs(GestureMath.darkHoldsRebind(now: 10) - 10.22) < 0.001, "Dark hält Rebind grabAbort")
        ok(abs(GestureMath.hudDimOpacity - 0.40) < 0.001, "Dim 40 %")
        ok(GestureMath.lumaSkipNeed == 2, "Luma 2 helle Frames")
        let enter0 = GestureMath.lumaSkipEnter(dark: true, streak: 0)
        ok(!enter0.skip && enter0.streak == 1, "1. dunkel Vision bleibt")
        let enter1 = GestureMath.lumaSkipEnter(dark: true, streak: 1)
        ok(enter1.skip && enter1.streak == 0, "2. dunkel Vision skip")
        let enterFlash = GestureMath.lumaSkipEnter(dark: false, streak: 1)
        ok(!enterFlash.skip && enterFlash.streak == 0, "heller Blitz reset Enter")
        ok(GestureMath.rawFrameDt(now: 1.5, last: 1.0) > 0.40, "Lock-dt ungedeckelt 500 ms")
        ok(GestureMath.sampleDt(now: 1.5, last: 1.0) <= GestureMath.sampleDtCap, "Need-dt bleibt gedeckelt")
        ok(GestureMath.continuityLockRetry(dt: GestureMath.rawFrameDt(now: 1.5, last: 1.0), hold: 2.0), "Lock aus Roh-dt")
        ok(!GestureMath.continuityLockRetry(dt: GestureMath.sampleDt(now: 1.5, last: 1.0), hold: 2.0), "Cap 200 ms feuert Lock nicht")
        ok(GestureMath.continuityLockRetry(dt: 0.50, hold: 2.0), "Lock 2 s")
        ok(!GestureMath.continuityLockRetry(dt: 0.50, hold: 1.0), "Lock 1 s noch nicht")
        ok(!GestureMath.continuityLockRetry(dt: 0.125, hold: 5.0), "8 fps kein Lock-Retry")
        let visCal = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let corners = GestureMath.screenAwareCorners(of: visCal)
        ok(corners.count == 4, "4 Kalib-Ecken")
        ok(corners[0].x == 8 && corners[0].y == 8, "oben links inset")
        ok(abs(corners[1].x - 1432) < 0.5 && corners[1].y == 8, "oben rechts inset")
        ok(abs(GestureMath.calibCornerDrift(mapped: CGPoint(x: 0, y: 0), target: CGPoint(x: 80, y: 0)) - 80) < 0.01, "Drift 80")
        ok(GestureMath.calibAborts(drift: 81), "Ecke > 80 px Abbruch")
        ok(!GestureMath.calibAborts(drift: 40), "40 px bleibt")

        let spike = [0.016, 0.016, 0.016, 0.016, 0.016, 0.016, 0.016, 0.20]
        ok(abs(GestureMath.medianSampleDt(spike) - 0.016) < 0.001, "Spike 200 ms kippt Median nicht")
        ok(abs(GestureMath.pinchClickNeed(dt: GestureMath.medianSampleDt(spike)) - 0.09) < 0.001, "24 fps Need trotz Spike 90 ms")
        ok(abs(GestureMath.pinchClickNeed(dt: 0.20) - 0.20) < 0.001, "Roh-Spike Open-Floor 200 ms")
        let cont8 = [0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125, 0.125]
        ok(abs(GestureMath.pinchClickNeed(dt: GestureMath.medianSampleDt(cont8)) - 0.18) < 0.001, "8 fps Median Need 180")
        ok(abs(GestureMath.medianSampleDt([], fallback: 0.04) - 0.04) < 0.001, "leerer Median Fallback")
        ok(GestureMath.flingGhost(kind: .throwUp, dragging: true), "Drag + Wurf = Ghost")
        ok(!GestureMath.flingGhost(kind: .throwUp, dragging: false), "ohne Drag kein Ghost")
        ok(!GestureMath.flingGhost(kind: .none, dragging: true), "Ziehen ohne Speed kein Ghost")
        ok(GestureMath.flingGhostLabel(.throwUp) == "FLING ↑", "Ghost oben")
        ok(GestureMath.flingGhostLabel(.minimize) == "FLING ↓", "Ghost unten")
        ok(GestureMath.flingGhostLabel(.dockLeft) == "FLING ←", "Ghost links")
        ok(GestureMath.flingGhostLabel(.dockRight) == "FLING →", "Ghost rechts")
        ok(GestureMath.flingGhostLabel(.none) == nil, "kein Ghost")
        ok(abs(GestureMath.scaleSettleNeed(dt: 0.125) - 0.35) < 0.001, "8 fps Scale 350 ms")
        ok(abs(GestureMath.scaleSettleNeed(dt: 0.016) - 0.18) < 0.001, "24 fps Scale 180 ms")
        ok(GestureMath.scaleSettleNeed(dt: 0.125) > 0.125, "Continuity erstes Tick skaliert nicht")
        ok(GestureMath.pinchTipConfidenceOk(thumb: 0.9, index: 0.9), "beide Spitzen ok")
        ok(!GestureMath.pinchTipConfidenceOk(thumb: 0.9, index: 0.05), "tote Index-Spitze")
        ok(!GestureMath.pinchTipConfidenceOk(thumb: 0.05, index: 0.9), "toter Daumen")
        ok(!GestureMath.pinchTipConfidenceOk(thumb: nil, index: 0.9), "Spitze fehlt")
        ok(abs(Double(GestureMath.pinchTipFloor) - 0.18) < 0.001, "Floor 0,18")
        ok(GestureMath.cgWindowIsGrabTarget(pid: 99, layer: 0, skipSelf: true, selfPID: 1), "fremde App greifbar")
        ok(!GestureMath.cgWindowIsGrabTarget(pid: 1, layer: 0, skipSelf: true, selfPID: 1), "skipSelf Helios raus")
        ok(GestureMath.cgWindowIsGrabTarget(pid: 1, layer: 0, skipSelf: false, selfPID: 1), "Helios ControlPanel rein")
        ok(!GestureMath.cgWindowIsGrabTarget(pid: 1, layer: 20, skipSelf: false, selfPID: 1), "HUD layer nie")

        let t0: TimeInterval = 10
        ok(abs(GestureMath.pinchClockAdvance(beganAt: t0, skipAX: true, dt: 0.50) - 10.50) < 0.001, "Skip schiebt Need-Uhr")
        ok(abs(GestureMath.pinchClockAdvance(beganAt: t0, skipAX: false, dt: 0.50) - 10) < 0.001, "ohne Skip Uhr steht")
        ok(GestureMath.pressBlockedBySkipAX(skipAX: true, latched: false), "Skip blockt Down")
        ok(GestureMath.pressBlockedBySkipAX(skipAX: false, latched: true), "erster Tick nach Skip blockt Down")
        ok(!GestureMath.pressBlockedBySkipAX(skipAX: false, latched: false), "frisches AX darf Down")
        ok(GestureMath.frameSilenceRetry(age: 2.0), "2 s ohne Frame")
        ok(!GestureMath.frameSilenceRetry(age: 1.9), "unter 2 s kein Retry")
        ok(GestureMath.testGrabHUD(becameDrag: false) == "Test: Halten", "Test Hold")
        ok(GestureMath.testGrabHUD(becameDrag: true) == "GREIFT · KEINE AKTION", "Test Drag ohne AX")
        let winLocal = CGRect(x: 100, y: 80, width: 800, height: 600)
        let beam = GestureMath.beamAim(windowLocal: winLocal)
        ok(abs(beam.x - 500) < 0.5, "Beam X Mitte")
        ok(abs(beam.y - 94) < 0.5, "Beam Y Titelbalken nicht Mitte")
        ok(abs(GestureMath.beamAim(windowLocal: winLocal).y - winLocal.midY) > 200, "nicht Fenstermitte")
        ok(!GestureMath.skipProbeStoresEmpty(), "leere Skip-Probe nicht cachen")
        ok(GestureMath.releaseBlockedBySkipAX(blockPress: true), "Release wie Down nach Skip")
        ok(!GestureMath.releaseBlockedBySkipAX(blockPress: false), "ohne Skip Release frei")
        ok(GestureMath.axWriteTook(want: CGPoint(x: 10, y: 10), got: CGPoint(x: 10, y: 21)), "AX 11 px unter Slop")
        ok(GestureMath.axWriteTook(want: CGPoint(x: 0, y: 0), got: CGPoint(x: 12, y: 0)), "AX genau 12 px")
        ok(!GestureMath.axWriteTook(want: CGPoint(x: 0, y: 0), got: CGPoint(x: 13, y: 0)), "AX 13 px Fail")
        ok(GestureMath.sampleDt(now: 1.200, last: 1.184) < 0.03, "Tick-Takt 16 ms")
        ok(abs(GestureMath.sampleDt(now: 1.200, last: 1.000) - GestureMath.sampleDtCap) < 0.002, "Pointer-Still 200 ms würde Need kippen")
        ok(GestureMath.rawFrameDt(now: 1.200, last: 1.184) < 0.03, "Tick-Rohdt 16 ms")
        ok(GestureMath.rawFrameDt(now: 1.200, last: 1.000) > 0.19, "Pointer-Still Rohdt 200 ms feuert Lock")
        ok(abs(CoordMath.quartzTopLeft(CGRect(x: 100, y: 80, width: 400, height: 300)).y - 80) < 0.001, "localRect minY")
        let ns: [String: Any] = [
            "X": NSNumber(value: 12.0),
            "Y": NSNumber(value: 34.0),
            "Width": NSNumber(value: 640.0),
            "Height": NSNumber(value: 480.0)
        ]
        let wr = GestureMath.windowListRect(ns)
        ok(wr?.origin.x == 12 && wr?.width == 640, "WindowList NSNumber")
        ok(!GestureMath.mirrorAsFront(positionFront: false, unspecified: true, deskView: true), "Desk-View nicht spiegeln")
        ok(GestureMath.mirrorAsFront(positionFront: true, unspecified: false, deskView: false), "FaceTime Front spiegeln")
        ok(GestureMath.mirrorAsFront(positionFront: false, unspecified: true, deskView: false), "Built-in unspecified Front")
        ok(!GestureMath.mirrorAsFront(positionFront: false, unspecified: false, deskView: false), "Back-Cam tot")
        let farVel = GestureMath.pinchCloseVel(dt: 0.016, palmScale: 0.05)
        let nearVel = GestureMath.pinchCloseVel(dt: 0.016, palmScale: 0.12)
        ok(farVel > nearVel, "ferne Hand Close-Vel weicher (weniger negativ)")
        ok(GestureMath.clickLockNeedsHover(0.80, closed: false), "Hover 80 % lockt")
        ok(!GestureMath.clickLockNeedsHover(0.40, closed: false), "Hover 40 % kein Lock")
        ok(GestureMath.clickLockNeedsHover(nil, closed: true), "zu = Lock")
        ok(!GestureMath.clickLockNeedsHover(nil, closed: false), "ohne Hover kein Lock")
        ok(GestureMath.panicKill(openScores: [4, 4]), "zwei volle Palmen Panic")
        ok(!GestureMath.panicKill(openScores: [3, 3]), "openScore 3 hält 0,55 s")
        ok(!GestureMath.panicKill(openScores: [4]), "eine Hand kein Panic")
        ok(GestureMath.armOpenCounts(x: 0.5, y: 0.5), "Mitte zählt für Scharf")
        ok(!GestureMath.armOpenCounts(x: 0.02, y: 0.5), "Rand-Knie kein Scharf")
        ok(GestureMath.escapeLatches(now: 1.10, until: 1.20), "Escape-Latch 200 ms")
        ok(!GestureMath.escapeLatches(now: 1.21, until: 1.20), "Latch vorbei")
        let skipSpike = GestureMath.skipAXLatch(expensive: true, skip: false, cheapStreak: 0)
        ok(skipSpike.skip && skipSpike.streak == 0, "teurer Tick skippt")
        let skipC1 = GestureMath.skipAXLatch(expensive: false, skip: true, cheapStreak: 0)
        ok(skipC1.skip && skipC1.streak == 1, "1. billig noch Skip")
        let skipC2 = GestureMath.skipAXLatch(expensive: false, skip: true, cheapStreak: 1)
        ok(!skipC2.skip, "2. billig Probe")
        ok(GestureMath.travelHUD(travel: 18, limit: 24)! > 0.7, "WEG 75 %")
        ok(GestureMath.travelHUD(travel: 0, limit: 24) == nil, "still kein WEG")
        ok(GestureMath.travelHUDLabel(0.5) == "WEG 50%", "WEG-Label")
        ok(GestureMath.gazeIdle(lastInterior: 1.0, now: 2.3), "1,2 s Gaze-Idle")
        ok(!GestureMath.gazeIdle(lastInterior: 0, now: 10), "nie Innenraum kein Idle")
        ok(!GestureMath.gazeIdle(lastInterior: 2.0, now: 2.5), "unter 1,2 s")
        ok(GestureMath.relativePredicts(dt: 0.125), "8 fps Relativ predict")
        ok(!GestureMath.relativePredicts(dt: 0.016), "24 fps kein Relativ-Predict")
        ok(GestureMath.hoverRingKind(magnet: true, locked: true, travel: 0.5, hover: 0.8) == .magnet, "MAGNET vor BUTTON")
        ok(GestureMath.hoverRingKind(magnet: false, locked: true, travel: 0.5, hover: 0.8) == .travel, "WEG vor BUTTON")
        ok(GestureMath.hoverRingKind(magnet: false, locked: true, travel: nil, hover: 0.8) == .button, "BUTTON")
        ok(GestureMath.hoverRingKind(magnet: false, locked: false, travel: nil, hover: 0.4) == .hover, "HOVER")
        ok(GestureMath.hoverRingKind(magnet: false, locked: false, travel: nil, hover: nil) == .none, "kein Ring")
        ok(GestureMath.hoverRingLabel(.magnet) == "MAGNET", "MAGNET-Label")
        ok(GestureMath.hoverRingLabel(.button) == "BUTTON", "BUTTON-Label")
        ok(GestureMath.hoverRingLabel(.hover) == nil, "Hover ohne Extra-Chip")
        ok(GestureMath.escapeLatchHUD(now: 1.10, until: 1.20) == "LATCH", "LATCH-Chip")
        ok(GestureMath.escapeLatchHUD(now: 1.21, until: 1.20) == nil, "Latch tot")
        ok(GestureMath.visionMsSpark(10) == "10 ms", "visMs unter Budget")
        ok(GestureMath.visionMsSpark(22).contains("!"), "visMs über Budget")
        ok(GestureMath.trafficCacheFresh(now: 1.20, cachedAt: 1.00), "Traffic 200 ms frisch")
        ok(!GestureMath.trafficCacheFresh(now: 1.50, cachedAt: 1.00), "Traffic 500 ms tot")
        ok(!GestureMath.trafficCacheFresh(now: 1.00, cachedAt: 0), "nie cached")
        ok(GestureMath.axProbeCoalesced(), "ein Probe / Tick")
        ok(abs(GestureMath.flingSpeedPx(dx: 100, dy: 0, dt: 0.10) - 1000) < 0.5, "1000 px/s")
        ok(GestureMath.flingMinSpeedPx(screenHeight: 900) >= 280, "Fling min px")
        ok(GestureMath.fling(dx: 0.20, dy: 0, speed: 0.20, dist: 0.20, speedPx: 900, minPx: 280) == .dockRight, "px-Speed wirft")
        ok(GestureMath.fling(dx: 0.20, dy: 0, speed: 0.20, dist: 0.20, speedPx: 100, minPx: 280) == .none, "px zu langsam")
        ok(GestureMath.darkRingHolds(darkStreak: 1), "1. Frame nach Dunkel hält Ring")
        ok(!GestureMath.darkRingHolds(darkStreak: 0), "ohne Dunkel")
        ok(!GestureMath.darkRingHolds(darkStreak: 2), "2 Frames vorbei")
        ok(GestureMath.deadManProgress(lastInterior: 1.0, now: 1.5) != nil, "Dead-Man Fenster")
        ok(GestureMath.deadManProgress(lastInterior: 1.0, now: 1.02) == nil, "frisch kein Ring")
        ok(GestureMath.deadManLabel(0.5) == "IDLE 50%", "Idle-Label")
        ok(abs((GestureMath.fistArmProgress(held: 0.275, need: 0.55) ?? 0) - 0.5) < 0.01, "SCHARF 50 %")
        ok(GestureMath.fistArmProgress(held: 0.55, need: 0.55) == nil, "fertig kein Ring")
        ok(GestureMath.fistArmLabel(0.5) == "SCHARF 50%", "SCHARF-Label")
        let mid = GestureMath.palmInterp(prev: CGPoint(x: 0, y: 0), curr: CGPoint(x: 1, y: 0), t: 0.5)
        ok(abs(mid.x - 0.5) < 0.01, "smoothstep Mitte")
        ok(!GestureMath.faceCountIdle(faces: 1, lastSeen: 1, now: 10), "Gesicht da")
        ok(GestureMath.faceCountIdle(faces: 0, lastSeen: 1, now: 2.3), "kein Gesicht 1,2 s")
        ok(!GestureMath.faceCountIdle(faces: 0, lastSeen: 0, now: 10), "nie gesehen")
        ok(abs(GestureMath.predictLead(0.2) - 0.3) < 0.001, "Lead Floor 0,3")
        ok(abs(GestureMath.predictLead(2) - 1.0) < 0.001, "Lead Cap 1,0")
        ok(abs(GestureMath.predictPalm(current: CGPoint(x: 0.50, y: 0.50), prev: CGPoint(x: 0.40, y: 0.50), dt: 0.125, lead: 1.0).x - 0.60) < 0.001, "Lead 1,0")
        ok(abs(GestureMath.predictLeadDt(0.125) - 0.7) < 0.001, "8 fps lead 0,7")
        ok(abs(GestureMath.predictLeadDt(0.016) - 0.35) < 0.001, "24 fps lead 0,35")
        let pred24 = GestureMath.predictPalm(
            current: CGPoint(x: 0.50, y: 0.50),
            prev: CGPoint(x: 0.40, y: 0.50),
            dt: 0.016,
            lead: GestureMath.predictLeadDt(0.016)
        )
        ok(abs(pred24.x - 0.535) < 0.001, "24 fps Predictor 0,35 (ist \(pred24.x))")
        ok(GestureMath.rightClickHold(held: 0.55, need: 0.12), "0,55 s Extra-Hold Rechts")
        ok(!GestureMath.rightClickHold(held: 0.40, need: 0.12), "unter 0,55 kein Rechts")
        ok(!GestureMath.rightClickHold(held: 0.55, need: 0.60), "Need noch nicht")
        ok(GestureMath.doublePinch(now: 1.20, lastClick: 1.00), "0,20 s Doppel")
        ok(!GestureMath.doublePinch(now: 1.50, lastClick: 1.00), "0,50 s kein Doppel")
        ok(!GestureMath.doublePinch(now: 1.00, lastClick: 0), "ohne last kein Doppel")
        ok(GestureMath.rightClickChipLabel(right: true) == "RECHTS", "RECHTS-Chip")
        ok(GestureMath.doublePinchBlocksTravel(travel: 12, limit: 24), "Travel 50 % blockt Doppel")
        ok(!GestureMath.doublePinchBlocksTravel(travel: 4, limit: 24), "Travel 16 % Doppel frei")
        ok(!GestureMath.doublePinchBlocksTravel(travel: 20, limit: 0), "ohne Limit kein Block")
        ok(GestureMath.faceScanDue(tick: 0), "erster Tick Face")
        ok(!GestureMath.faceScanDue(tick: 1), "Tick 1 kein Face")
        ok(GestureMath.faceScanDue(tick: 4), "Tick 4 Face")
        let cont = GestureMath.continuityPalm(prev: CGPoint(x: 0, y: 0), current: CGPoint(x: 1, y: 0), dt: 0.125)
        ok(cont.x > 0.4 && cont.x < 0.8, "8 fps Palm interpoliert")
        ok(GestureMath.continuityPalm(prev: CGPoint(x: 0, y: 0), current: CGPoint(x: 1, y: 0), dt: 0.016).x == 1, "24 fps roh")

        ok(abs(GestureMath.pinchClickNeed(dt: 0.016) - 0.09) < 0.001, "24 fps still 90 ms")
        ok(GestureMath.pinchClickNeed(dt: 0.016, speed: 0.25) > 0.15, "Flick streckt Need")
        ok(abs(GestureMath.pinchClickNeed(dt: 0.016, speed: 0) - 0.09) < 0.001, "Zielen bleibt 90")
        ok(!GestureMath.armedIdle(faces: 1, lastFace: 1, lastInterior: 0.1, now: 3), "Gesicht hält Scharf am Rand")
        ok(GestureMath.armedIdle(faces: 0, lastFace: 1, lastInterior: 1, now: 2.3), "kein Gesicht 1,2 s Idle")
        ok(GestureMath.armedIdle(faces: 1, lastFace: 1, lastInterior: 1, now: 3, lidClosed: true), "Klappe Idle")
        ok(!GestureMath.lidClosedIdle(false), "Klappe offen")
        ok(GestureMath.lidClosedIdle(true), "Klappe zu")
        let rmsOk = GestureMath.mapRMS([10, 12, 8, 14])
        ok(GestureMath.mapRMSReady(rmsOk), "RMS unter 40")
        ok(!GestureMath.mapRMSReady(GestureMath.mapRMS([70, 70, 70, 70])), "70 px × 4 nicht fertig")
        ok(GestureMath.mapRMSLabel(70)?.contains("!") == true, "RMS-Warnung")
        ok(GestureMath.modifierKind(peace: true, point: false, fist: false) == .command, "Peace = ⌘")
        ok(GestureMath.modifierKind(peace: false, point: true, fist: false) == .option, "Point = ⌥")
        ok(GestureMath.modifierKind(peace: false, point: false, fist: true) == .shift, "Faust = ⇧")
        ok(GestureMath.modifierChip(.command) == "⌘", "⌘-Chip")
        ok(GestureMath.modifierFlagBits(.command) == 0x100000, "⌘-Bits")
        ok(GestureMath.axProbeTimesOut(ms: 12), "AX > 8 ms tot")
        ok(!GestureMath.axProbeTimesOut(ms: 4), "AX 4 ms ok")
        ok(GestureMath.flingUndo(now: 1.30, lastFling: 1.00, peace: true, pinch: true), "Undo 0,3 s")
        ok(!GestureMath.flingUndo(now: 1.50, lastFling: 1.00, peace: true, pinch: true), "Undo tot")
        ok(!GestureMath.flingUndo(now: 1.10, lastFling: 0, peace: true, pinch: true), "ohne Wurf kein Undo")
        ok(GestureMath.dwellClick(held: 0.70, dock: true, enabled: true), "Dwell Dock")
        ok(!GestureMath.dwellClick(held: 0.70, dock: false, enabled: true), "Dwell nicht Dock")
        let cub0 = CGPoint(x: 0, y: 0)
        let cub1 = CGPoint(x: 1, y: 0)
        let cubMid = GestureMath.palmInterpCubic(p0: cub0, p1: cub0, p2: cub1, p3: cub1, t: 0.5)
        ok(cubMid.x > 0.3 && cubMid.x < 0.7, "cubic Mitte")
        let cub = GestureMath.continuityPalmCubic(older: cub0, prev: CGPoint(x: 0.4, y: 0), current: CGPoint(x: 0.8, y: 0), dt: 0.125)
        ok(cub.x > 0.4 && cub.x < 1.0, "8 fps cubic")
        ok(GestureMath.continuityPalmCubic(older: nil, prev: nil, current: cub1, dt: 0.125).x == 1, "ohne History roh")
        ok(GestureMath.trackpadClutch(mouseDelta: 10, palmSpeed: 0.005), "ruhige Palm + 10 px = Clutch")
        ok(!GestureMath.trackpadClutch(mouseDelta: 10, palmSpeed: 0.20), "bewegte Palm kein Diebstahl")
        ok(GestureMath.trackpadClutch(mouseDelta: 32, palmSpeed: 0.20), "große Maus trotz Palm")
        ok(GestureMath.trackpadClutch(mouseDelta: 5, palmSpeed: 0, dragged: true), "Drag 5 px Clutch")
        ok(!GestureMath.trackpadClutch(mouseDelta: 5, palmSpeed: 0), "Move 5 px kein Clutch")
        ok(GestureMath.clamshellIdle(true), "Klappe Idle")
        ok(!GestureMath.clamshellIdle(false), "Klappe offen")
        ok(GestureMath.enginePhase(modeArmed: false, pinchHeld: true, dragging: false, scaleActive: false) == .idle, "Idle schlägt Pinch")
        ok(GestureMath.enginePhase(modeArmed: true, pinchHeld: false, dragging: false, scaleActive: false) == .armed, "Scharf")
        ok(GestureMath.enginePhase(modeArmed: true, pinchHeld: true, dragging: false, scaleActive: false) == .pinch, "Pinch")
        ok(GestureMath.enginePhase(modeArmed: true, pinchHeld: true, dragging: true, scaleActive: false) == .drag, "Ziehen vor Pinch")
        ok(GestureMath.enginePhase(modeArmed: true, pinchHeld: true, dragging: true, scaleActive: true) == .scale, "Scale vor Drag")
        ok(GestureMath.enginePhaseChip(.drag) == "ZIEHEN", "Phase-Chip")
        ok(GestureMath.enginePhase(modeArmed: true, pinchHeld: true, dragging: false, scaleActive: false, kill: true) == .kill, "Kill vor Pinch")
        ok(GestureMath.enginePhaseChip(.kill) == "KILL", "KILL-Chip")
        ok(GestureMath.phaseBlocksClick(.idle), "Idle kein Klick")
        ok(GestureMath.phaseBlocksClick(.kill), "Kill kein Klick")
        ok(!GestureMath.phaseBlocksClick(.pinch), "Pinch darf klicken")
        ok(!GestureMath.phaseBlocksClick(.armed), "Scharf darf klicken")
        ok(GestureMath.clickHapticKind(ok: true) == .generic, "Klick-Haptik")
        ok(GestureMath.clickHapticKind(ok: false) == .none, "kein Klick keine Haptik")
        ok(GestureMath.clickHapticKind(ok: true, alignment: true) == .alignment, "Fling-Haptik")
        ok(abs(GestureMath.tickClock(now: 1.10, lastTick: 1.00) - 0.10) < 0.001, "Tick-Clock")
        ok(abs(GestureMath.screenBlendT(elapsed: 0.06) - 0.5) < 0.02, "Blend 60 ms")
        let b = GestureMath.screenBlend(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 10, y: 0), t: 0.5)
        ok(b.x > 3 && b.x < 7, "Blend Mitte")
        ok(GestureMath.screenChanged(prevID: "a", nextID: "b"), "Screen-Wechsel")
        ok(!GestureMath.screenChanged(prevID: "a", nextID: "a"), "gleicher Screen")
        let key = GestureMath.screenKey(
            point: CGPoint(x: 50, y: 50),
            screens: [("left", CGRect(x: 0, y: 0, width: 100, height: 100)), ("right", CGRect(x: 100, y: 0, width: 100, height: 100))]
        )
        ok(key == "left", "Screen-Key")
        ok(GestureMath.gameModeFullscreen(window: CGRect(x: 0, y: 0, width: 1920, height: 1080), screen: CGRect(x: 0, y: 0, width: 1920, height: 1080)), "Vollbild")
        ok(!GestureMath.gameModeFullscreen(window: CGRect(x: 100, y: 100, width: 400, height: 300), screen: CGRect(x: 0, y: 0, width: 1920, height: 1080)), "Fenster")
        ok(GestureMath.gameModePause(fullscreen: true), "Game-Pause")
        ok(!GestureMath.gameModePause(fullscreen: true, enabled: false), "Game aus")
        ok(GestureMath.gameModeChip(true) == "GAME", "GAME-Chip")
        ok(GestureMath.continuityReconnectHolds(firstAfterLock: true, hasHistory: true), "Reconnect hält")
        ok(!GestureMath.continuityReconnectHolds(firstAfterLock: true, hasHistory: false), "ohne History roh")
        let held = GestureMath.continuityReconnectPalm(prev: CGPoint(x: 0.2, y: 0.2), current: CGPoint(x: 0.9, y: 0.9), firstAfterLock: true)
        ok(abs(held.x - 0.2) < 0.001, "erster Frame nach Lock kein Sprung")
        ok(GestureMath.pinchTipZClosed(tipZ: 0.08), "Tip-Z zu")
        ok(!GestureMath.pinchTipZClosed(tipZ: 0.01), "Tip-Z offen")
        ok(GestureMath.pinchUsesTipZ(revision2: true, tipZ: 0.08), "Revision 2")
        ok(!GestureMath.pinchUsesTipZ(revision2: false, tipZ: 0.08), "ohne Rev2 2D")
        let tipFwd = GestureMath.pinchTipZ(thumbZ: 0.20, indexZ: 0.18, wristZ: 0.12)
        ok(abs((tipFwd ?? -1) - 0.07) < 0.001, "Tip-Z vor Wrist")
        ok(GestureMath.pinchTipZ(thumbZ: nil, indexZ: 0.2, wristZ: 0.1) == nil, "ohne Thumb kein Z")
        ok(GestureMath.pinchKeepsGrabTipZ(held: true, closed: false, ratio: 0.60, fisting: false, rebind: false, palmScale: 0.12, tipZ: 0.08, revision2: true), "Tip-Z hält Grab trotz Ratio 0,60")
        ok(!GestureMath.pinchKeepsGrabTipZ(held: true, closed: false, ratio: 0.60, fisting: false, rebind: false, palmScale: 0.12, tipZ: 0.08, revision2: false), "ohne Rev2 Ratio öffnet")
        ok(!GestureMath.pinchKeepsGrabTipZ(held: true, closed: false, ratio: 0.60, fisting: false, rebind: false, palmScale: 0.12, tipZ: 0.01, revision2: true), "Tip-Z offen Ratio öffnet")
        ok(GestureMath.displayLinkFires(frameDt: 0.125, elapsed: 0.042), "8 fps Display-Link")
        ok(!GestureMath.displayLinkFires(frameDt: 0.016, elapsed: 0.042), "24 fps kein Fill")
        ok(!GestureMath.displayLinkFires(frameDt: 0.125, elapsed: 0.010), "zu früh")
        ok(!GestureMath.displayLinkFires(frameDt: 0.125, elapsed: 0.120), "nächster Kamera-Tick")
        let tLink = GestureMath.displayLinkCubicT(elapsed: 0.125, frameDt: 0.125)
        ok(abs(tLink - 1.0) < 0.02, "t am Frame-Ende 1")
        let tMid = GestureMath.displayLinkCubicT(elapsed: 0, frameDt: 0.125)
        ok(abs(tMid - 0.62) < 0.02, "t am Tick 0,62")
        let vel = GestureMath.displayLinkVelocity(prev: CGPoint(x: 0, y: 0), current: CGPoint(x: 40, y: 0), frameDt: 0.125)
        ok(abs(vel.x - 320) < 1, "Velocity px/s")
        let stepped = GestureMath.displayLinkCursor(from: CGPoint(x: 10, y: 10), velocity: CGPoint(x: 200, y: 0), elapsed: 0.04)
        ok(abs(stepped.x - 18) < 0.2, "8 px in 40 ms")
        let cap = GestureMath.displayLinkCursor(from: .zero, velocity: CGPoint(x: 2000, y: 0), elapsed: 0.04, maxStep: 28)
        ok(abs(cap.x - 28) < 0.2, "Cap 28 px")
        ok(GestureMath.mapMissingOnScreen(loadedScreenID: "1", currentScreenID: "2"), "anderes Display")
        ok(!GestureMath.mapMissingOnScreen(loadedScreenID: "1", currentScreenID: "1"), "gleiche Map")
        ok(!GestureMath.mapMissingOnScreen(loadedScreenID: nil, currentScreenID: "2"), "Fallback ohne Screen")
        ok(!GestureMath.mapMissingOnScreen(loadedScreenID: nil, currentScreenID: nil), "ohne Cursor")
        ok(GestureMath.mapMissingChip(true) == "KALIB HIER", "KALIB HIER")
        ok(GestureMath.mapMissingChip(false) == nil, "kein Chip")
        ok(GestureMath.mapWarmupUsesRelative(hasMap: true, screenChanged: true), "Map da: Relativ-Warp")
        ok(!GestureMath.mapWarmupUsesRelative(hasMap: false, screenChanged: true), "ohne Map kein Warp")
        ok(!GestureMath.mapWarmupUsesRelative(hasMap: true, screenChanged: false), "gleicher Screen kein Warmup")
        ok(GestureMath.overlayDash(kind: .magnet)?.map(\.doubleValue) == [2.0, 2.0], "MAGNET dicht")
        ok(GestureMath.overlayDash(kind: .button)?.map(\.doubleValue) == [10.0, 3.0], "BUTTON lang")
        ok(GestureMath.overlayDash(kind: .travel) != nil, "WEG Punkte")
        ok(GestureMath.overlayDash(kind: .none) == nil, "ohne Kind")
        ok(GestureMath.overlayDashAlways(kind: .none, ghost: true, hovering: false, flinging: false)?.map(\.doubleValue) == [6.0, 4.0], "Ghost Dash")
        ok(GestureMath.appGain(bundle: "com.apple.Safari") < 1, "Safari langsamer")
        ok(GestureMath.appGain(bundle: nil) == 1, "ohne Bundle")
        ok(GestureMath.appGain(bundle: "com.example.Notes") == 1, "neutral")
        ok(GestureMath.appGain(bundle: "com.valve.steam") < 0.7, "Steam gedämpft")
        ok(GestureMath.clickLockAlways(bundle: "com.apple.dock"), "Dock Lock")
        ok(!GestureMath.clickLockAlways(bundle: "com.apple.Safari"), "Safari kein Always")
        ok(GestureMath.phaseBlocksArm(lidClosed: true, gamePaused: false), "Klappe blockt Scharf")
        ok(GestureMath.phaseBlocksArm(lidClosed: false, gamePaused: true), "Game blockt Scharf")
        ok(!GestureMath.phaseBlocksArm(lidClosed: false, gamePaused: false), "offen darf Scharf")
        ok(GestureMath.lidBlocksArm(lidClosed: true), "Built-in Klappe tot")
        ok(GestureMath.lidBlocksArm(lidClosed: true, cameraFallback: false, extraScreens: true), "Klappe Built-in + Extern tot")
        ok(!GestureMath.lidBlocksArm(lidClosed: true, cameraFallback: true, extraScreens: true), "Clamshell Continuity lebt")
        ok(GestureMath.lidBlocksArm(lidClosed: true, cameraFallback: true, extraScreens: false), "Klappe ohne Extern tot")
        ok(!GestureMath.lidBlocksArm(lidClosed: false, cameraFallback: true, extraScreens: true), "offen nie tot")
        ok(!GestureMath.phaseBlocksArm(lidClosed: true, gamePaused: false, cameraFallback: true, extraScreens: true), "Clamshell darf Scharf")
        ok(GestureMath.mapFitsScreen(mapScreenID: "1", screenID: "1"), "Map passt")
        ok(!GestureMath.mapFitsScreen(mapScreenID: "1", screenID: "2"), "Laptop-Map nicht Extern")
        ok(!GestureMath.mapFitsScreen(mapScreenID: nil, screenID: "2"), "Legacy ohne dest nicht auf Extern")
        ok(GestureMath.mapFitsScreen(mapScreenID: "1", screenID: nil), "ohne Ziel ok")
        let destHere = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let destThere = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        ok(GestureMath.mapFitsScreen(mapScreenID: nil, screenID: "2", dest: destHere, screen: destHere), "Legacy dest passt")
        ok(!GestureMath.mapFitsScreen(mapScreenID: nil, screenID: "2", dest: destThere, screen: destHere), "Legacy dest fremd")
        ok(!GestureMath.mapMissingOnScreen(loadedScreenID: nil, currentScreenID: "2"), "Legacy nicht KALIB HIER")
        ok(GestureMath.mapMissingOnScreen(loadedScreenID: "1", currentScreenID: "2"), "fremde Map KALIB HIER")
        let clamped = GestureMath.destClamp(CGPoint(x: 5000, y: 20), bounds: destHere)
        ok(clamped.x <= destHere.maxX - 1 && clamped.x >= destHere.minX + 1, "destClamp X im Screen")
        ok(abs(GestureMath.displayLinkCap(speed: 0) - 12) < 0.2, "Zielen 12 px")
        ok(abs(GestureMath.displayLinkCap(speed: 80) - 12) < 0.2, "80 px/s Rest")
        ok(abs(GestureMath.displayLinkCap(speed: 480) - 28) < 0.2, "Flick 28 px")
        ok(GestureMath.displayLinkCap(speed: 200) > 12 && GestureMath.displayLinkCap(speed: 200) < 28, "Mitte zwischen Rest und Flick")
        ok(GestureMath.gameModeExempt(bundle: "com.apple.Safari"), "Safari kein Game")
        ok(GestureMath.gameModeExempt(bundle: "com.google.Chrome"), "Chrome kein Game")
        ok(!GestureMath.gameModeExempt(bundle: "com.valve.steam"), "Steam ist Game")
        ok(!GestureMath.gameModePause(fullscreen: true, bundle: "com.apple.Safari"), "Safari FS kein Pause")
        ok(GestureMath.gameModePause(fullscreen: true, bundle: "com.valve.steam"), "Steam FS Pause")
        ok(GestureMath.gameModePause(fullscreen: true, bundle: "com.apple.Safari", extraLock: ["com.apple.Safari"]), "Prefs Lock schlägt Exempt")
        ok(!GestureMath.gameModePause(fullscreen: false, bundle: "com.valve.steam"), "Fenster kein Pause")
        ok(GestureMath.clickLockAlways(bundle: "com.example.game", extra: ["com.example.game"]), "Prefs Click-Lock")
        ok(!GestureMath.clickLockAlways(bundle: "com.apple.Safari", extra: []), "Safari kein Always")
        ok(GestureMath.prefsBundleList("# c\ncom.a\n com.b , com.c").contains("com.a"), "prefsBundleList")
        ok(!GestureMath.prefsBundleList("# nur kommentar").contains("# nur kommentar"), "Kommentar raus")
        ok(abs(GestureMath.pinchOpenRatio(scale: 0.12) - 0.58) < 0.001, "nahe Open 0,58")
        ok(abs(GestureMath.pinchOpenRatio(scale: 0.06) - 0.64) < 0.001, "ferne Open 0,64")
        ok(!GestureMath.pinchWantOpen(ratio: 0.59, proxRatio: 0.59, vel: 0, dt: 0.125, scale: 0.12), "8 fps 0,59 ohne Vel bleibt")
        ok(GestureMath.pinchWantOpen(ratio: 0.65, proxRatio: 0.65, vel: 0, dt: 0.125, scale: 0.12), "8 fps 0,65 ohne Vel öffnet")
        ok(GestureMath.pinchWantOpen(ratio: 0.59, proxRatio: 0.59, vel: 0.2, dt: 0.125, scale: 0.12), "8 fps Vel öffnet")
        ok(!GestureMath.pinchWantOpen(ratio: 0.50, proxRatio: 0.50, vel: 0, dt: 0.125, scale: 0.12), "0,50 bleibt zu")
        ok(GestureMath.faceCountFresh(count: 1, lastSeen: 1, now: 2.4) == 0, "stale Face 0")
        ok(GestureMath.faceCountFresh(count: 1, lastSeen: 1, now: 1.5) == 1, "frisches Face")
        ok(GestureMath.faceCountFresh(count: 0, lastSeen: 1, now: 1.1) == 0, "kein Face")
        ok(GestureMath.pocketIdle(cameraFallback: true, lastInterior: 1, now: 2.3), "Tasche Idle")
        ok(!GestureMath.pocketIdle(cameraFallback: false, lastInterior: 1, now: 2.3), "Built-in kein Tasche")
        ok(!GestureMath.pocketIdle(cameraFallback: true, lastInterior: 1, now: 1.5), "frisch kein Tasche")
        ok(GestureMath.liveHandRefreshesDeadMan(ghost: false), "Live hält Dead-Man")
        ok(!GestureMath.liveHandRefreshesDeadMan(ghost: true), "Ghost hält Dead-Man nicht")
        ok(GestureMath.pointerStaysSide(locked: .right, candidate: .right), "gleiche Seite")
        ok(!GestureMath.pointerStaysSide(locked: .right, candidate: .left), "andere Seite tot")
        ok(!GestureMath.pointerStaysSide(locked: .right, candidate: .any), "unknown nicht die Lock-Seite")
        ok(GestureMath.pointerStaysSide(locked: .any, candidate: .left), "ohne Lock frei")
        ok(GestureMath.pointerFreezesSteal(locked: .right, candidate: .left, sameSlot: false), "Steal friert")
        ok(!GestureMath.pointerFreezesSteal(locked: .right, candidate: .left, sameSlot: true), "gleicher Slot folgt")
        ok(!GestureMath.pointerFreezesSteal(locked: .any, candidate: .left, sameSlot: false), "ohne Lock kein Freeze")
        let poolRight = GestureMath.pointerPool(
            locked: .right,
            candidates: [("L", .left), ("R", .right)],
            keepID: "L"
        )
        ok(poolRight == ["R"], "Lock-Seite vor Keep-ID")
        let poolKeep = GestureMath.pointerPool(
            locked: .right,
            candidates: [("L", .left), ("U", .any)],
            keepID: "U"
        )
        ok(poolKeep == ["U"], "ohne Lock-Seite nur Slot-ID")
        let poolAny = GestureMath.pointerPool(
            locked: .any,
            candidates: [("L", .left), ("R", .right)],
            keepID: "R"
        )
        ok(poolAny == ["L", "R"], "ohne Lock alle")
        let poolEmpty = GestureMath.pointerPool(
            locked: .right,
            candidates: [("L", .left)],
            keepID: "R"
        )
        ok(poolEmpty.isEmpty, "Lock-Hand weg: Pool leer, nicht die andere")
        ok(GestureMath.focusStealLatches(prevPID: 10, nextPID: 20, pinchHeld: true), "Focus-Steal")
        ok(!GestureMath.focusStealLatches(prevPID: 10, nextPID: 10, pinchHeld: true), "gleicher PID")
        ok(!GestureMath.focusStealLatches(prevPID: 10, nextPID: 20, pinchHeld: false), "ohne Pinch kein Latch")
        ok(GestureMath.gameModeExempt(bundle: "com.microsoft.edgemac"), "Edge kein Game")
        ok(GestureMath.gameModeExempt(bundle: "com.brave.Browser"), "Brave kein Game")
        let laptop = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let ext = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let uni = CGRect(x: 0, y: 0, width: 3360, height: 1080)
        let span = GestureMath.relativeStepSpan(cursor: CGPoint(x: 200, y: 200), screens: [laptop, ext], union: uni)
        ok(abs(span.width - 1440) < 1, "Relativ-Span Laptop nicht Union")
        let spanExt = GestureMath.relativeStepSpan(cursor: CGPoint(x: 2000, y: 200), screens: [laptop, ext], union: uni)
        ok(abs(spanExt.width - 1920) < 1, "Relativ-Span Extern")
        ok(GestureMath.armedIdle(faces: 1, lastFace: 1, lastInterior: 1, now: 2.5, cameraFallback: true), "Continuity Tasche trotz Face-Count")
        ok(!GestureMath.armedIdle(faces: 1, lastFace: 1, lastInterior: 1, now: 2.5, cameraFallback: false), "Built-in Gesicht hält")
        let relScr = GestureMath.destClampScreen(
            point: CGPoint(x: 200, y: 200),
            mapBounds: nil,
            screens: [laptop, ext]
        )
        ok(relScr == laptop, "Relativ-Fill auf Laptop")
        let mapScr = GestureMath.destClampScreen(
            point: CGPoint(x: 200, y: 200),
            mapBounds: laptop,
            screens: [laptop, ext]
        )
        ok(mapScr == laptop, "Map-Bounds vor Screen")
        let over = GestureMath.destClamp(CGPoint(x: 2000, y: 200), bounds: relScr)
        ok(over.x <= laptop.maxX - 1, "Relativ-Fill nicht auf den Externen")
        let gap = GestureMath.destClampScreen(
            point: CGPoint(x: 1435, y: -20),
            mapBounds: nil,
            screens: [laptop, ext]
        )
        ok(gap == laptop || gap == ext, "Bezel/Lücke: nächster Screen, nie nil")
        ok(GestureMath.pointerStealHUD(locked: .right) == "LOCK R", "HUD LOCK R")
        ok(GestureMath.pointerStealHUD(locked: .left) == "LOCK L", "HUD LOCK L")
        ok(GestureMath.pointerStealBlocksActor(poolEmpty: true, freeze: false), "Pool leer blockt Actor")
        ok(GestureMath.pointerStealBlocksActor(poolEmpty: false, freeze: true), "Freeze blockt Actor")
        ok(!GestureMath.pointerStealBlocksActor(poolEmpty: false, freeze: false), "Lock-Hand da: Actor lebt")
        ok(GestureMath.pointerStealRelock(freeze: true, otherFist: true), "Faust legt Lock um")
        ok(!GestureMath.pointerStealRelock(freeze: true, otherFist: false), "ohne Faust kein Relock")
        ok(!GestureMath.pointerStealRelock(freeze: false, otherFist: true), "ohne Freeze kein Relock")
        ok(!GestureMath.pointerStealRelock(freeze: true, otherFist: true, held: 0.10), "1 Frame Faust kein Relock")
        ok(GestureMath.pointerStealRelock(freeze: true, otherFist: true, held: 0.35), "0,35 s Relock")
        ok(GestureMath.pointerStealTimesOut(emptySince: 0, now: 1.2, poolEmpty: true), "1,2 s → Idle")
        ok(!GestureMath.pointerStealTimesOut(emptySince: 0, now: 0.4, poolEmpty: true), "0,4 s hält LOCK")
        ok(!GestureMath.pointerStealTimesOut(emptySince: 0, now: 2, poolEmpty: false), "Lock-Hand da: kein Timeout")
        ok(!GestureMath.pointerStealTimesOut(emptySince: nil, now: 2, poolEmpty: true), "ohne Since kein Timeout")
        ok(!GestureMath.pointerStealTimesOut(emptySince: 0, now: 2, poolEmpty: true, ghosting: true), "Ghost: kein LOCK tot")
        ok(GestureMath.pointerStealBlocksCursor(steal: true), "Freeze: kein placeCursor")
        ok(!GestureMath.pointerStealBlocksCursor(steal: false), "Lock-Hand da: Cursor lebt")
        ok(GestureMath.displayTickBlocksSteal(steal: true, frameDt: 0.125, poolEmpty: true), "8 fps Pool leer: kein Tick")
        ok(!GestureMath.displayTickBlocksSteal(steal: true, frameDt: 0.125, poolEmpty: false), "8 fps Lock-Hand: interpolieren")
        ok(!GestureMath.displayTickBlocksSteal(steal: true, frameDt: 0.016), "24 fps Freeze: Kamera treibt")
        ok(!GestureMath.displayTickBlocksSteal(steal: false, frameDt: 0.125), "ohne Freeze Tick")
        ok(GestureMath.scaleAllowsSteal(), "Scale trotz Steal")
        ok(!GestureMath.palmReachKills(palmScale: 0.32, openScore: 3), "3 Finger kein Reach")
        ok(GestureMath.palmReachKills(palmScale: 0.32, openScore: 4), "Palm-Reach Not-Aus")
        ok(!GestureMath.palmReachKills(palmScale: 0.10, openScore: 4), "ferne Palm kein Kill")
        ok(!GestureMath.palmReachKills(palmScale: 0.40, openScore: 1), "Faust-Reach kein Kill")
        ok(!GestureMath.palmReachKills(palmScale: 0.32, openScore: 3, dt: 0.125), "8 fps 3 Finger kein Kill")
        ok(GestureMath.palmReachKills(palmScale: 0.32, openScore: 4, dt: 0.125), "8 fps Palm 4 Kill")
        ok(!GestureMath.palmReachKills(palmScale: 0.40, openScore: 4, side: .right, locked: .right), "Lock-Hand nah kein Kill")
        ok(GestureMath.palmReachKills(palmScale: 0.40, openScore: 4, side: .left, locked: .right), "andere Hand Reach Kill")
        ok(!GestureMath.pointerStealTimesOut(emptySince: 0, now: 2, poolEmpty: true, dragging: true), "Drag: kein LOCK tot")
        ok(GestureMath.pointerStealTimesOut(emptySince: 0, now: 1.2, poolEmpty: true, dragging: false), "ohne Drag Timeout")
        ok(GestureMath.pointerStealRelock(freeze: true, otherFist: true, held: 0.05, modifierSkip: true), "⌥-Faust Relock sofort")
        ok(!GestureMath.pointerStealRelock(freeze: true, otherFist: true, held: 0.05, modifierSkip: false), "ohne ⌥ 0,05 s tot")
        ok(GestureMath.pointerStealHUD(locked: .right, emptySince: 0, now: 0.4) == "IDLE in 0,8 s", "HUD IDLE Countdown")
        ok(GestureMath.pointerStealHUD(locked: .right, emptySince: 0, now: 0.4, dragging: true) == "LOCK R · DRAG", "Drag: LOCK · DRAG")
        ok(GestureMath.pointerStealRelockHUD(held: 0.245) == "LOCK … 70%", "Relock 70%")
        ok(GestureMath.pointerStealRelockHUD(held: 0.35) == nil, "Relock fertig kein Chip")
        ok(GestureMath.scaleStealHUD() == "SCALE", "Scale-HUD")
        ok(!GestureMath.displayTickBlocksSteal(steal: true, frameDt: 0.125, poolEmpty: false), "Latch 8 fps interpoliert")
        ok(GestureMath.displayTickBlocksSteal(steal: true, frameDt: 0.016, poolEmpty: true), "24 fps Pool leer: kein Tick")
        ok(!GestureMath.displayTickBlocksSteal(steal: true, frameDt: 0.016, poolEmpty: false), "24 fps Lock-Hand: Kamera treibt")
        ok(GestureMath.stealHoldsPocket(steal: true), "Steal hält Tasche")
        ok(!GestureMath.stealHoldsPocket(steal: false), "ohne Steal Tasche lebt")
        let recon = GestureMath.pointerPoolReconnect(
            locked: .right,
            candidates: [("new", .any, 0.51, 0.20)],
            keepID: "old",
            lastX: 0.50,
            lastY: 0.20
        )
        ok(recon == ["new"], "Reconnect Palm trotz neuer ID")
        let reconFar = GestureMath.pointerPoolReconnect(
            locked: .right,
            candidates: [("far", .any, 0.90, 0.90)],
            keepID: "old",
            lastX: 0.10,
            lastY: 0.10
        )
        ok(reconFar.isEmpty, "Reconnect weit kein Slot")
        ok(GestureMath.pointerSameSlot(keepID: "old", actorID: "new", poolIDs: ["new"]), "Reconnect sameSlot")
        ok(!GestureMath.pointerSameSlot(keepID: "old", actorID: "other", poolIDs: ["new"]), "andere Hand nicht sameSlot")
        ok(abs(GestureMath.displayTickCapSteal(base: 12, relock: true) - 6) < 0.01, "Relock Cap halb")
        ok(abs(GestureMath.displayTickCapSteal(base: 12, relock: false) - 12) < 0.01, "ohne Relock Cap")
        let freezeScr = GestureMath.destClampScreen(
            point: CGPoint(x: 2000, y: 200),
            mapBounds: nil,
            screens: [laptop, ext],
            freeze: true,
            lastScreen: laptop
        )
        ok(freezeScr == laptop, "Freeze: letzter Screen, nicht Extern")
        let liveScr = GestureMath.destClampScreen(
            point: CGPoint(x: 2000, y: 200),
            mapBounds: nil,
            screens: [laptop, ext],
            freeze: false,
            lastScreen: laptop
        )
        ok(liveScr == ext, "ohne Freeze: Screen unter Cursor")
        ok(abs(GestureMath.reconnectBind(dt: 0.016) - 0.22) < 0.001, "24 fps Bind 0,22")
        ok(GestureMath.reconnectBind(dt: 0.125) > 0.38, "8 fps Bind weiter")
        let reconJump = GestureMath.pointerPoolReconnect(
            locked: .right,
            candidates: [("new", .any, 0.82, 0.20)],
            keepID: "old",
            lastX: 0.50,
            lastY: 0.20,
            dt: 0.125
        )
        ok(reconJump == ["new"], "8 fps Bind 0,32 noch Slot")
        let reconLast2 = GestureMath.pointerPoolReconnect(
            locked: .right,
            candidates: [("new", .any, 0.70, 0.20)],
            keepID: "old",
            lastX: 0.20,
            lastY: 0.80,
            last2X: 0.68,
            last2Y: 0.20,
            dt: 0.125
        )
        ok(reconLast2 == ["new"], "last-3 Palm-Ring nach Sprung")
        ok(GestureMath.pinchActorKeeps(id: "S1", poolIDs: ["S1"]), "pinchActor im Pool")
        ok(!GestureMath.pinchActorKeeps(id: "S2", poolIDs: ["S1"]), "andere Hand nicht Actor")
        ok(!GestureMath.pinchActorScanPool(poolIDs: []), "leerer Pool: kein Scan aller Hände")
        ok(GestureMath.pinchActorScanPool(poolIDs: ["S1"]), "Pool da: Scan")
        ok(GestureMath.pinchGateUsesSmoothed(closed: true), "Pinch zu: Open geglättet")
        ok(!GestureMath.pinchGateUsesSmoothed(closed: false), "Pinch auf: Close roh")
        ok(GestureMath.slotChip(id: "S1") == "S1", "Slot S1")
        ok(GestureMath.slotChip(id: "S2") == "S2", "Slot S2")
        ok(GestureMath.slotChip(id: nil) == nil, "ohne ID kein Chip")
        ok(GestureMath.slotChip(id: "ghost") == nil, "kein S-Prefix")
        ok(GestureMath.pointerKeepInPool(keepID: "S1", poolIDs: ["S2", "S1"]) == "S1", "Keep im Pool bleibt")
        ok(GestureMath.pointerKeepInPool(keepID: "S1", poolIDs: ["S2"]) == "S2", "Keep tot: first")
        ok(GestureMath.pointerKeepInPool(keepID: nil, poolIDs: ["S1"]) == "S1", "ohne Keep first")
        ok(GestureMath.pointerKeepInPool(keepID: "S1", poolIDs: []) == nil, "leerer Pool kein Keep")
        ok(GestureMath.preferredKeepsPool(poolEmpty: false), "Pool da: preferred scannt Pool")
        ok(!GestureMath.preferredKeepsPool(poolEmpty: true), "leerer Pool: preferred nicht alle Hände")
        ok(GestureMath.stealHoldsPalm(poolEmpty: true), "Freeze hält lastPalm")
        ok(!GestureMath.stealHoldsPalm(poolEmpty: false), "Lock-Hand da: Palm folgt")
        ok(GestureMath.slotBind(dt: 0.016, scale: 0.12) < 0.23, "24 fps Slot-Bind eng")
        ok(GestureMath.slotBind(dt: 0.125, scale: 0.12) > 0.35, "8 fps Slot-Bind weiter")
        let ringNear = GestureMath.actorRebindRing(
            lostID: "old",
            candidates: [("new", 0.52, 0.20)],
            lastX: 0.50,
            lastY: 0.20,
            dt: 0.016
        )
        ok(ringNear == "new", "Rebind nah")
        let ringFar = GestureMath.actorRebindRing(
            lostID: "old",
            candidates: [("new", 0.90, 0.80)],
            lastX: 0.10,
            lastY: 0.10,
            dt: 0.016
        )
        ok(ringFar == nil, "Rebind weit tot")
        let ringLast2 = GestureMath.actorRebindRing(
            lostID: "old",
            candidates: [("new", 0.70, 0.20)],
            lastX: 0.10,
            lastY: 0.80,
            last2X: 0.68,
            last2Y: 0.20,
            dt: 0.125
        )
        ok(ringLast2 == "new", "pinchActor last-3 nach Sprung")
        ok(GestureMath.slotHue("S1") == "cyan", "S1 cyan")
        ok(GestureMath.slotHue("S2") == "amber", "S2 amber")
        ok(GestureMath.slotHue("ghost") == nil, "ohne Slot kein Hue")
        ok(GestureMath.slotKeepsID(emptyFor: 2.0), "2 s Pause hält S1")
        ok(!GestureMath.slotKeepsID(emptyFor: 4.1), "nach Latch S1 tot")
        ok(GestureMath.slotLatchBind(dt: 0.125, scale: 0.12) > GestureMath.slotBind(dt: 0.125, scale: 0.12), "Latch weiter als Bind")
        ok(GestureMath.slotReusesUnclaimed(unclaimed: 1, nearest: 0.50, bind: 0.22, latch: 0.72), "ein Unclaimed im Latch = S1")
        ok(!GestureMath.slotReusesUnclaimed(unclaimed: 1, nearest: 0.90, bind: 0.22, latch: 0.72), "zu weit mintet neu")
        ok(GestureMath.slotReusesUnclaimed(unclaimed: 2, nearest: 0.18, bind: 0.22, latch: 0.72), "nah Bind gewinnt")
        let nearPalm = GestureMath.preferredNearest(
            keepID: "S1",
            poolEmpty: true,
            hands: [("S2", 0.80, 0.80), ("S3", 0.52, 0.21)],
            lastX: 0.50,
            lastY: 0.20
        )
        ok(nearPalm == "S3", "Keep tot: nächste Palme, nicht first")
        ok(GestureMath.preferredNearest(keepID: "S1", poolEmpty: false, hands: [("S1", 0, 0)], lastX: nil, lastY: nil) == "S1", "Pool da: Keep")
        let warpHeld = GestureMath.cursorWarpReject(from: .zero, to: CGPoint(x: 200, y: 0))
        ok(warpHeld == .zero, "Warp > 80 px halten")
        let okStep = GestureMath.cursorWarpReject(from: .zero, to: CGPoint(x: 40, y: 0))
        ok(okStep.x == 40, "Warp < 80 px folgen")
        ok(GestureMath.cursorWarpHeld(from: .zero, to: CGPoint(x: 81, y: 0)), "81 px Warp")
        ok(!GestureMath.cursorWarpHeld(from: .zero, to: CGPoint(x: 40, y: 0)), "40 px kein Warp")
        ok(GestureMath.fingerOcclusionHoldsDIP(tipConf: nil, hasDIP: true), "Tip fehlt, DIP da")
        ok(GestureMath.fingerOcclusionHoldsDIP(tipConf: 0.05, hasDIP: true), "Tip tot, DIP da")
        ok(GestureMath.fingerOcclusionHoldsDIP(tipConf: 0.22, hasDIP: true), "Phantom-Tip 0,22 → DIP")
        ok(!GestureMath.fingerOcclusionHoldsDIP(tipConf: 0.9, hasDIP: true), "Tip ok")
        ok(!GestureMath.fingerOcclusionHoldsDIP(tipConf: nil, hasDIP: false), "ohne DIP kein Hold")
        ok(GestureMath.fingerOcclusionUsesLastTip(lastTip: CGPoint(x: 0.44, y: 0.80)), "letzter Tip vor DIP")
        ok(!GestureMath.fingerOcclusionUsesLastTip(lastTip: nil), "ohne Tip DIP")
        let lastTip = GestureMath.fingerOcclusionTip(
            lastTip: CGPoint(x: 0.44, y: 0.80),
            dip: CGPoint(x: 0.44, y: 0.62)
        )
        ok(lastTip == CGPoint(x: 0.44, y: 0.80), "Occlusion: letzter Tip, nicht DIP")
        ok(
            GestureMath.fingerOcclusionTip(lastTip: nil, dip: CGPoint(x: 0.44, y: 0.62)) == nil,
            "DIP kein Pinch-Tip"
        )
        ok(GestureMath.fingerOcclusionFresh(savedAt: 1, now: 1.3), "Tip 0,3 s frisch")
        ok(!GestureMath.fingerOcclusionFresh(savedAt: 1, now: 1.5), "Tip 0,5 s tot")
        ok(!GestureMath.fingerOcclusionFresh(savedAt: nil, now: 1), "ohne Tip tot")
        ok(!GestureMath.fingerOcclusionConfirm(ticks: 1), "1 Tick kein OCC")
        ok(GestureMath.fingerOcclusionConfirm(ticks: 2), "2 Ticks OCC")
        ok(GestureMath.fingerOcclusionChip(held: true) == "OCC", "HUD OCC")
        ok(GestureMath.fingerOcclusionChip(held: false) == nil, "ohne Hold kein OCC")
        let heldSmooth = GestureMath.cursorWarpHoldsSmooth(from: .zero, to: CGPoint(x: 200, y: 0))
        ok(heldSmooth == .zero, "Warp schreibt Smooth")
        ok(GestureMath.cursorWarpHoldsSmooth(from: .zero, to: CGPoint(x: 40, y: 0)) == nil, "kein Warp nil")
        ok(GestureMath.slotLatchEmptyKeepsPointer(emptyFor: 0.12), "ein Dropout hält Pointer")
        ok(!GestureMath.slotLatchEmptyKeepsPointer(emptyFor: 2.0), "2 s Pointer tot")
        ok(GestureMath.slotLatchEmptyKeepsPointer(emptyFor: 0), "erster leerer Tick hält")
        ok(!GestureMath.slotLatchEmptyKeepsPointer(emptyFor: 4.1), "nach Latch Pointer tot")
        ok(!GestureMath.slotLatchEmptyKeepsPointer(emptyFor: -0.01), "negativ kein Pointer-Latch")
        ok(GestureMath.trackerEmptyKeepsGhost(kept: 0), "Low-Conf = Ghost")
        ok(!GestureMath.trackerEmptyKeepsGhost(kept: 1), "eine Hand kein Ghost-Empty")
        ok(GestureMath.fingerSparseKeepsPalm(rawCount: 3, hasWrist: true, mcpCount: 0), "Wrist-only Palm")
        ok(GestureMath.fingerSparseKeepsPalm(rawCount: 4, hasWrist: false, mcpCount: 2), "MCP-Palm ohne Wrist")
        ok(!GestureMath.fingerSparseKeepsPalm(rawCount: 3, hasWrist: false, mcpCount: 1), "ein MCP tot")
        ok(!GestureMath.fingerSparseKeepsPalm(rawCount: 12, hasWrist: true, mcpCount: 4), "voll nicht sparse")
        ok(GestureMath.palmCenterFallsBackToWrist(mcpCount: 0, hasWrist: true), "MCP tot → Wrist")
        ok(GestureMath.palmCenterFallsBackToMCP(mcpCount: 3, hasWrist: false), "Wrist tot → MCP")
        ok(!GestureMath.palmCenterFallsBackToWrist(mcpCount: 3, hasWrist: true), "MCP da kein Wrist-Fallback")
        let wristOnly = GestureClassifier.palmCenter([.wrist: CGPoint(x: 0.40, y: 0.22)])
        ok(wristOnly == CGPoint(x: 0.40, y: 0.22), "palmCenter Wrist")
        let mcpPalm = GestureClassifier.palmCenter([
            .indexMCP: CGPoint(x: 0.44, y: 0.34),
            .littleMCP: CGPoint(x: 0.56, y: 0.34)
        ])
        ok(abs(mcpPalm.x - 0.50) < 0.001, "palmCenter MCP-Mittel")
        ok(GestureMath.medianCursorStep([8, 10, 40, 12, 9]) == 10, "Median-Schritt")
        ok(GestureMath.medianCursorStep([]) == 24, "ohne Schritte Fallback")
        ok(GestureMath.cursorWarpCap(medianStep: 10) == 48, "Still: Floor 48")
        ok(GestureMath.cursorWarpCap(medianStep: 50) == 150, "Flick 50 → Cap 150")
        ok(!GestureMath.cursorWarpHeld(from: .zero, to: CGPoint(x: 120, y: 0), cap: 150), "Flick 120 unter 150")
        ok(GestureMath.cursorWarpHeld(from: .zero, to: CGPoint(x: 120, y: 0), cap: 48), "Still 120 über 48")
        ok(GestureMath.centerStageOff, "Center Stage aus")
        ok(GestureMath.centerStageDisabled(false), "Center Stage disabled")
        ok(!GestureMath.centerStageDisabled(true), "wenn an, nicht disabled")
        ok(GestureMath.centerStageNeedsAppControl(currentModeRaw: 0), "user-Mode muss .app nehmen")
        ok(!GestureMath.centerStageNeedsAppControl(currentModeRaw: 1), "schon .app")
        ok(GestureMath.centerStageNeedsAppControl(currentModeRaw: 2), "cooperative auch .app")
        let k24 = GestureMath.palmKalman(prev: .zero, meas: CGPoint(x: 0.4, y: 0), vel: .zero, dt: 0.016)
        ok(k24.pos.x > 0.15 && k24.pos.x < 0.40, "24 fps Kalman folgt, nicht skip")
        let k8 = GestureMath.palmKalman(
            prev: CGPoint(x: 0.20, y: 0.20),
            meas: CGPoint(x: 0.80, y: 0.20),
            vel: .zero,
            dt: 0.125
        )
        ok(k8.pos.x > 0.20 && k8.pos.x < 0.80, "8 fps Kalman dämpft Sprung")
        ok(k8.pos.x < 0.70, "8 fps Kalman kein Cubic-Overshoot")
        ok(GestureMath.tickKeepsGhost(isGhost: true, joints: 3, confidence: 0.05, floor: 0.18), "Ghost trotz Floor")
        ok(!GestureMath.tickKeepsGhost(isGhost: false, joints: 3, confidence: 0.9, floor: 0.18), "Live unter 8 tot")
        ok(GestureMath.tickKeepsGhost(isGhost: false, joints: 12, confidence: 0.4, floor: 0.18), "Live ok")
        ok(GestureMath.ghostKeepsPool(ghosting: true), "Ghost hält Pool")
        ok(!GestureMath.ghostKeepsPool(ghosting: false), "ohne Ghost Pool-Wipe erlaubt")
        ok(GestureMath.sparseMergeKeeps(isPalmBone: true), "Wrist/MCP mergen")
        ok(!GestureMath.sparseMergeKeeps(isPalmBone: false), "Tip nicht mergen")
        ok(abs(GestureMath.jointGain(count: 6) - 0.45) < 0.001, "6 Joints Gain 0,45")
        ok(abs(GestureMath.jointGain(count: 21) - 1) < 0.001, "21 Joints Gain 1")
        ok(abs(GestureMath.twoHandClutchGain(secondOpen: true) - 0.4) < 0.001, "Clutch 0,4")
        ok(GestureMath.twoHandClutchGain(secondOpen: false) == 1, "ohne zweite Palme 1")
        ok(GestureMath.pinchPoseHoldNeed(dt: 0.125, gateClosed: true) == 0, "8 fps Gate zu: kein Extra-Hold")
        ok(GestureMath.pinchPoseHoldNeed(dt: 0.125, gateClosed: false) == 1, "8 fps Gate auf: 1 Frame")
        ok(GestureMath.pinchPoseHoldNeed(dt: 0.016, gateClosed: true) == 2, "24 fps Hold bleibt 2")
        ok(!GestureMath.slotMintsNew(existing: 2, latching: true), "Latch: kein S3")
        ok(GestureMath.slotMintsNew(existing: 1, latching: true), "ein Slot darf S2")
        ok(GestureMath.slotMintsNew(existing: 2, latching: false), "ohne Latch S3 ok")
        ok(GestureMath.slotAllocCap(latching: true) == 2, "Latch-Cap 2")
        ok(GestureMath.slotAllocCap(latching: false) == nil, "ohne Latch kein Cap")
        ok(GestureMath.palmROIAllows(secondHand: false), "eine Hand ROI")
        ok(!GestureMath.palmROIAllows(secondHand: true), "Kill-Hand kein ROI")
        let roi = GestureMath.palmVisionROI(palm: CGPoint(x: 0.5, y: 0.5), scale: 0.12, secondHand: false)
        ok(roi != nil && (roi?.width ?? 0) > 0.2, "ROI um Palme")
        ok(GestureMath.palmVisionROI(palm: CGPoint(x: 0.5, y: 0.5), scale: 0.12, secondHand: true) == nil, "zwei Hände volles Bild")
        ok(abs(GestureMath.oneEuroLandmarkCutoff(base: 6.2, dt: 0.125) - 14) < 0.001, "8 fps Landmark 14")
        ok(abs(GestureMath.oneEuroLandmarkCutoff(base: 6.2, dt: 0.04) - 10) < 0.001, "24 fps Landmark 10")
        ok(GestureMath.cursorWarpFloor(dt: 0.125) == 64, "8 fps Warp-Floor 64")
        ok(GestureMath.cursorWarpFloor(dt: 0.016) == 48, "24 fps Warp-Floor 48")
        ok(GestureMath.cursorWarpFloor(dt: 0.016, continuity: true) == 64, "Continuity Floor 64")
        ok(GestureMath.cursorWarpCap(medianStep: 10, floor: 64) == 64, "Still Continuity 64")
        ok(GestureMath.centerStageNeedsReassert(enabled: true), "Center Stage nach Sleep wieder an")
        ok(!GestureMath.centerStageNeedsReassert(enabled: false), "bleibt aus")
        ok(GestureMath.fpsLatchChip(fps: 8, ghosting: true) == "8 Hz · LATCH", "Ghost-HUD Latch")
        ok(GestureMath.fpsLatchChip(fps: 8, ghosting: false) == "8 Hz", "8 fps Hz")
        ok(GestureMath.fpsLatchChip(fps: 24, ghosting: false) == "24 fps", "24 fps Label")
        let frozen = GestureMath.displayLinkVelocity(
            prev: CGPoint(x: 100, y: 100),
            current: CGPoint(x: 100, y: 100),
            frameDt: 0.125,
            palmVel: CGPoint(x: 0.4, y: 0),
            mappedScale: 1440
        )
        ok(frozen.x > 100, "Warp-Freeze: Palm-Vel füllt Tick")
        let closeMid = GestureMath.pinchCloseRatio(scale: 0.09)
        ok(closeMid > 0.33 && closeMid < 0.40, "Close-Ratio stetig")
        let keepMid = GestureMath.pinchKeepRatioFor(scale: 0.09)
        ok(keepMid > 0.48 && keepMid < 0.56, "Keep-Ratio stetig")
        ok(GestureMath.palmROIMissRetries(hadROI: true, empty: true), "ROI-Miss retry")
        ok(!GestureMath.palmROIMissRetries(hadROI: false, empty: true), "ohne ROI kein retry")
        ok(!GestureMath.palmROIMissGoesFull(dt: 0.125), "8 fps ROI nicht Full")
        ok(GestureMath.palmROIMissAllowsFull(dt: 0.016), "24 fps Full-Pass ok")
        ok(!GestureMath.palmROIMissAllowsFull(dt: 0.125), "8 fps kein Full-Pass")
        let roi0 = GestureMath.palmVisionROI(palm: CGPoint(x: 0.5, y: 0.5), scale: 0.12, secondHand: false)!
        let roi1 = GestureMath.palmROIExpand(roi0)
        ok(roi1.width > roi0.width, "ROI 1,8×")
        ok(GestureMath.palmROIFull().width == 1, "ROI voll")
        ok(GestureMath.tipOccluded(tip: CGPoint(x: 0.50, y: 0.50), palm: CGPoint(x: 0.50, y: 0.50), scale: 0.20, extended: false), "Tip in Palme")
        ok(!GestureMath.tipOccluded(tip: CGPoint(x: 0.80, y: 0.50), palm: CGPoint(x: 0.50, y: 0.50), scale: 0.20, extended: false), "Tip draußen")
        ok(!GestureMath.tipOccluded(tip: CGPoint(x: 0.50, y: 0.50), palm: CGPoint(x: 0.50, y: 0.50), scale: 0.20, extended: true), "extended kein Occlude")
        ok(GestureMath.lumaWarp(prev: 0.50, next: 0.20), "Luma-Sprung")
        ok(!GestureMath.lumaWarp(prev: 0.50, next: 0.48), "Luma ruhig")
        ok(GestureMath.fistAELockActive(armedAt: 1.0, now: 1.4), "AE 1,2 s innen")
        ok(GestureMath.fistAELockActive(armedAt: 1.0, now: 2.0), "AE 1,0 s noch an")
        ok(!GestureMath.fistAELockActive(armedAt: 1.0, now: 2.3), "AE vorbei")
        ok(!GestureMath.fistAELockActive(armedAt: nil, now: 1.0), "ohne Faust kein AE")
        ok(GestureMath.palmKalmanFreeze(armedAt: 1.0, now: 1.4, luma: 0.20, prevLuma: 0.55), "AE+Warp freeze")
        ok(!GestureMath.palmKalmanFreeze(armedAt: nil, now: 1.4, luma: 0.20, prevLuma: 0.55), "ohne AE kein freeze")
        ok(!GestureMath.palmKalmanFreeze(armedAt: 1.0, now: 1.4, luma: 0.50, prevLuma: 0.48), "ohne Warp kein freeze")
        ok(abs(GestureMath.palmKalmanQ(luma: 0.70) - 0.055) < 0.001, "hell weniger Q")
        ok(abs(GestureMath.palmKalmanQ(luma: 0.20) - 0.10) < 0.001, "dunkel Q 0,10")
        let freeze = GestureMath.palmKalman(
            prev: CGPoint(x: 0.40, y: 0.40),
            meas: CGPoint(x: 0.80, y: 0.40),
            vel: .zero,
            dt: 0.125,
            luma: 0.20,
            freeze: true
        )
        ok(abs(freeze.pos.x - 0.40) < 0.001, "Luma-Warp freeze Palm")
        let noFreeze = GestureMath.palmKalman(
            prev: CGPoint(x: 0.40, y: 0.40),
            meas: CGPoint(x: 0.80, y: 0.40),
            vel: .zero,
            dt: 0.125,
            luma: 0.20,
            freeze: false
        )
        ok(abs(noFreeze.pos.x - 0.40) > 0.05, "ohne AE-Fenster Kalman folgt")
        ok(GestureMath.pinchOpenNeed(dt: 0.125, ratioOnly: true) == 2, "8 fps ratio-only 2")
        ok(GestureMath.pinchOpenNeed(dt: 0.125, ratioOnly: false) == 1, "8 fps Vel 1")
        ok(abs(GestureMath.palmKalmanR(tipConf: 1) - 0.045) < 0.001, "sicher R 0,045")
        ok(GestureMath.palmKalmanR(tipConf: 0.30) > GestureMath.palmKalmanR(tipConf: 1), "unsicher mehr R")
        let loConf = GestureMath.palmKalman(
            prev: CGPoint(x: 0.40, y: 0.40),
            meas: CGPoint(x: 0.80, y: 0.40),
            vel: .zero,
            dt: 0.125,
            tipConf: 0.25
        )
        let hiConf = GestureMath.palmKalman(
            prev: CGPoint(x: 0.40, y: 0.40),
            meas: CGPoint(x: 0.80, y: 0.40),
            vel: .zero,
            dt: 0.125,
            tipConf: 1
        )
        ok(abs(loConf.pos.x - 0.40) < abs(hiConf.pos.x - 0.40), "unsicherer Tip weniger Warp")
        ok(GestureMath.fistAELockApplies(continuity: true), "Continuity AE")
        ok(!GestureMath.fistAELockApplies(continuity: false), "Built-in kein AE")
        ok(GestureMath.cursorWarpFloor(dt: 0.125, lumaWarp: true) == 96, "AE-Warp Floor 96")
        ok(GestureMath.cursorWarpFloor(dt: 0.125) == 64, "8 fps Floor 64 bleibt")
        let slotS2 = GestureMath.palmROISlotPalm(hands: [
            (id: "S2", palm: CGPoint(x: 0.80, y: 0.50), scale: 0.10),
            (id: "S1", palm: CGPoint(x: 0.20, y: 0.50), scale: 0.12)
        ])
        ok(slotS2?.palm.x == 0.20, "ROI an S1 nicht first")
        let onlyS2 = GestureMath.palmROISlotPalm(hands: [
            (id: "S2", palm: CGPoint(x: 0.80, y: 0.50), scale: 0.10)
        ])
        ok(onlyS2?.palm.x == 0.80, "nur S2 folgt S2")
        let keepS1 = GestureMath.palmROISlotPalm(
            hands: [(id: "S2", palm: CGPoint(x: 0.80, y: 0.50), scale: 0.10)],
            keepPalm: CGPoint(x: 0.20, y: 0.50),
            keepScale: 0.12
        )
        ok(keepS1?.palm.x == 0.20, "S1 fehlt: Crop bleibt an last S1")
        let guitar = GestureMath.palmROISlotPalm(hands: [
            (id: "S1", palm: CGPoint(x: 0.50, y: 0.50), scale: 0.42),
            (id: "S2", palm: CGPoint(x: 0.82, y: 0.20), scale: 0.11)
        ])
        ok(guitar?.palm.x == 0.82, "Gitarre S1: Crop an echte Hand S2")
        let guitarOnly = GestureMath.palmROISlotPalm(hands: [
            (id: "S1", palm: CGPoint(x: 0.50, y: 0.50), scale: 0.42)
        ])
        ok(guitarOnly == nil, "nur Prop Full")
        ok(GestureMath.palmScaleIsHand(0.12), "Hand-Scale")
        ok(!GestureMath.palmScaleIsHand(0.42), "Prop-Scale")
        ok(GestureMath.palmLowConfFreeze(conf: 0.25), "Occlusion freeze")
        ok(!GestureMath.palmLowConfFreeze(conf: 0.80), "sicher kein freeze")
        ok(GestureMath.palmHolds(armedAt: nil, now: 1, luma: 0.5, prevLuma: 0.5, conf: 0.22), "Low-Conf hält")
        ok(!GestureMath.palmHolds(armedAt: nil, now: 1, luma: 0.5, prevLuma: 0.5, conf: 0.90), "sicher kein Hold")
        let kept = GestureMath.palmKalmanKeepsState(CGPoint(x: 0.41, y: 0.40))
        ok(abs(kept.x - 0.41) < 0.001, "Kalman-State zurück")
        let spikeKalman = GestureMath.palmKalman(
            prev: CGPoint(x: 0.40, y: 0.40),
            meas: CGPoint(x: 0.80, y: 0.40),
            vel: .zero,
            dt: 0.125,
            tipConf: 0.25
        )
        let recoverState = GestureMath.palmKalman(
            prev: GestureMath.palmKalmanKeepsState(spikeKalman.pos),
            meas: CGPoint(x: 0.42, y: 0.40),
            vel: spikeKalman.vel,
            dt: 0.125,
            tipConf: 1
        )
        let recoverRaw = GestureMath.palmKalman(
            prev: CGPoint(x: 0.80, y: 0.40),
            meas: CGPoint(x: 0.42, y: 0.40),
            vel: .zero,
            dt: 0.125,
            tipConf: 1
        )
        ok(abs(recoverState.pos.x - 0.42) < abs(recoverRaw.pos.x - 0.42), "State erholt nach Spike")
        ok(GestureMath.palmDeadAdaptive(Array(repeating: 0.002, count: 12)) <= 0.010, "still Dead klein")
        ok(GestureMath.palmDeadAdaptive(Array(repeating: 0.05, count: 12)) <= 0.010, "Flick kein extra Dead")
        let shaky: [CGFloat] = [0.002, 0.018, 0.003, 0.016, 0.001, 0.019, 0.002, 0.017, 0.004, 0.015, 0.002, 0.018]
        ok(
            GestureMath.palmDeadAdaptive(shaky) > GestureMath.palmDeadAdaptive(Array(repeating: 0.002, count: 12)),
            "zittrig größer"
        )
        ok(abs(GestureMath.displayLinkStepMul() - 0.4) < 0.03, "60 Hz Step 0,4")
        ok(GestureMath.displayLinkPeriod < 0.02, "Display-Link 60 Hz")
        let freezeLo = GestureMath.palmKalman(
            prev: CGPoint(x: 0.40, y: 0.40),
            meas: CGPoint(x: 0.80, y: 0.40),
            vel: .zero,
            dt: 0.125,
            tipConf: 0.25,
            freeze: GestureMath.palmLowConfFreeze(conf: 0.25)
        )
        ok(abs(freezeLo.pos.x - 0.40) < 0.001, "Low-Conf freeze Palm")
        ok(abs(GestureMath.palmLowConfFloor(continuity: true) - 0.10) < 0.001, "Continuity Floor 0,10")
        ok(abs(GestureMath.palmLowConfFloor(continuity: false) - 0.30) < 0.001, "Built-in Floor 0,30")
        ok(!GestureMath.palmLowConfFreeze(conf: 0.15, floor: GestureMath.palmLowConfFloor(continuity: true)), "Continuity 0,15 live")
        ok(
            !GestureMath.palmLowConfFreeze(
                conf: 0.15,
                floor: GestureMath.palmLowConfFloor(continuity: true),
                tipHeld: true
            ),
            "DIP-Fake kein Freeze"
        )
        ok(
            !GestureMath.palmHolds(
                armedAt: nil, now: 1, luma: 0.5, prevLuma: 0.5, conf: 0.15, continuity: true
            ),
            "Continuity mean 0,15 kein Freeze"
        )
        ok(
            !GestureMath.palmHolds(
                armedAt: nil, now: 1, luma: 0.5, prevLuma: 0.5, conf: 0.80, continuity: true, tipHeld: true
            ),
            "tipHeld kein Freeze bei sicherer Conf"
        )
        ok(abs(GestureMath.palmTipConf(tip: 0.55, mean: 0.18) - 0.55) < 0.001, "Tip vor Mean")
        ok(abs(GestureMath.palmTipConf(tip: 0, mean: 0.18) - 0.18) < 0.001, "ohne Tip Mean")
        ok(GestureMath.palmKalmanUses(dt: 0.016), "24 fps Kalman")
        ok(!GestureMath.palmKalmanUses(dt: 0.004), "Sub-Frame kein Kalman")
        let k24Blend = GestureMath.palmKalman(
            prev: CGPoint(x: 0.40, y: 0.40),
            meas: CGPoint(x: 0.42, y: 0.40),
            vel: CGPoint(x: 0.10, y: 0),
            dt: 0.016
        )
        ok(abs(k24Blend.pos.x - 0.42) > 0.001 && abs(k24Blend.pos.x - 0.40) > 0.001, "24 fps blendet")
        ok(hypot(k24Blend.vel.x, k24Blend.vel.y) > 0.01, "24 fps vel bleibt")
        ok(GestureMath.predictLeadAfterKalman(0.125) < GestureMath.predictLeadDt(0.125), "kein Doppel-Lead")
        ok(GestureMath.predictLeadAfterKalman(0.016) < GestureMath.predictLeadDt(0.016), "24 fps Lead klein")
        ok(GestureMath.palmDeadWindow(dt: 0.125) == 6, "8 fps Dead 6")
        ok(GestureMath.palmDeadWindow(dt: 0.016) == 12, "24 fps Dead 12")
        let mixed: [CGFloat] = [0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.002, 0.002, 0.002, 0.002, 0.002, 0.002]
        ok(
            GestureMath.palmDeadAdaptive(mixed, window: 6)
                < GestureMath.palmDeadAdaptive(mixed, window: 12) + 0.001,
            "6 Samples erholen nach Flick"
        )
        let late = GestureMath.displayLinkElapsed(now: 1.050, last: 1.000)
        ok(late <= GestureMath.displayLinkPeriod * 1.5 + 0.001, "Display-dt Cap 1,5×")
        ok(late >= GestureMath.displayLinkPeriod * 0.5 - 0.001, "Display-dt Floor 0,5×")
        let firstFill = GestureMath.displayLinkElapsed(now: 1.0, last: 0)
        ok(abs(firstFill - GestureMath.displayLinkPeriod) < 0.001, "erster Fill = Period")

        let fzVel = GestureMath.palmKalman(
            prev: CGPoint(x: 0.40, y: 0.40),
            meas: CGPoint(x: 0.55, y: 0.40),
            vel: CGPoint(x: 0.40, y: 0),
            dt: 0.125,
            freeze: true
        )
        ok(abs(fzVel.vel.x) < 0.001 && abs(fzVel.vel.y) < 0.001, "Freeze vel 0")
        ok(
            abs(GestureMath.palmKalmanFreezeVel(CGPoint(x: 0.4, y: 0), freeze: true).x) < 0.001,
            "FreezeVel Helper 0"
        )
        ok(
            abs(GestureMath.palmKalmanFreezeVel(CGPoint(x: 0.4, y: 0), freeze: false).x - 0.4) < 0.001,
            "ohne Freeze Vel bleibt"
        )
        ok(GestureMath.displayTickBlocksHold(freeze: true), "Fill tot bei Hold")
        ok(!GestureMath.displayTickBlocksHold(freeze: false), "ohne Hold Fill")
        let cam0 = CGPoint(x: 0, y: 0)
        let cam1 = CGPoint(x: 80, y: 0)
        let cursorMoved = CGPoint(x: 96.7, y: 0)
        let velCam = GestureMath.displayLinkVelocity(prev: cam0, current: cam1, frameDt: 0.125)
        let velCompound = GestureMath.displayLinkVelocity(prev: cam0, current: cursorMoved, frameDt: 0.125)
        ok(velCam.x + 1 < velCompound.x, "Kamera-Vel nicht Compound")
        ok(
            abs(GestureMath.displayLinkVelCamera(from: cursorMoved, camera: cam1).x - 80) < 0.01,
            "Fill aus lastMapped"
        )
        ok(GestureMath.displayLinkRebase() == 0, "Kamera rebased lastDisplay")
        ok(
            abs(GestureMath.displayLinkElapsed(now: 1, last: GestureMath.displayLinkRebase())
                - GestureMath.displayLinkPeriod) < 0.001,
            "erster Fill nach Kamera = Period"
        )
        let afterFlick: [CGFloat] = [0.15, 0.002, 0.002, 0.002, 0.002, 0.002]
        ok(GestureMath.palmDeadAdaptive(afterFlick, window: 6) <= 0.010, "MAD nach Flick Rest")
        ok(GestureMath.displayTickBlocksStill(frozen: true), "Fill tot bei Still")
        ok(!GestureMath.displayTickBlocksStill(frozen: false), "ohne Still Fill")
        let stillVel = GestureMath.displayLinkVelocity(
            prev: CGPoint(x: 100, y: 100),
            current: CGPoint(x: 100, y: 100),
            frameDt: 0.125,
            palmVel: CGPoint(x: 0.4, y: 0),
            mappedScale: 1440,
            still: true
        )
        ok(abs(stillVel.x) < 0.001 && abs(stillVel.y) < 0.001, "Still: Fill vel 0")
        let wideY = GestureMath.displayLinkVelocity(
            prev: CGPoint(x: 100, y: 100),
            current: CGPoint(x: 100, y: 100),
            frameDt: 0.125,
            palmVel: CGPoint(x: 0, y: 0.4),
            mappedScale: 2560,
            mappedScaleY: 1440
        )
        ok(abs(wideY.y - 576) < 0.5, "Y-Vel × Höhe, nicht Breite")
        ok(abs(wideY.x) < 0.001, "X tot bei reiner Y-Vel")
        let screenFill = GestureMath.displayLinkVelocity(
            prev: CGPoint(x: 100, y: 100),
            current: CGPoint(x: 100, y: 100),
            frameDt: 0.125,
            palmVel: CGPoint(x: 0.4, y: 0),
            mappedScale: 2560,
            palmVelScreen: CGPoint(x: 320, y: 0)
        )
        ok(abs(screenFill.x - 320) < 0.01, "Fill aus Screen-px, nicht Palm×Breite")
        let qStill = GestureMath.palmKalmanQ(luma: 0.50, mad: 0.003)
        let qShaky = GestureMath.palmKalmanQ(luma: 0.50, mad: 0.018)
        ok(qShaky > qStill, "Kalman-Q aus MAD")
        let scale = GestureMath.displayLinkMappedScale(bounds: CGRect(x: 0, y: 0, width: 2560, height: 1440))
        ok(abs(scale.x - 2560) < 0.001 && abs(scale.y - 1440) < 0.001, "Scale X/Y getrennt")
        ok(GestureMath.palmVelScreenStale(moved: false, mad: 0.003), "Rest-MAD tot")
        ok(!GestureMath.palmVelScreenStale(moved: true, mad: 0.003), "Bewegung hält Vel")
        ok(!GestureMath.palmVelScreenStale(moved: false, mad: 0), "mad 0 kein Stale")
        let restVel = GestureMath.palmVelScreenKeep(moved: false, mad: 0.003, vel: CGPoint(x: 400, y: 0))
        ok(abs(restVel.x) < 0.001, "Rest-MAD Screen-Vel 0")
        let holdZ = GestureMath.palmVelScreenKeep(moved: true, mad: 0.018, vel: CGPoint(x: 400, y: 0), hold: true)
        ok(abs(holdZ.x) < 0.001, "Hold Screen-Vel 0")
        let coast0 = GestureMath.displayLinkCoast(CGPoint(x: 400, y: 0), elapsed: 0)
        ok(abs(coast0.x - 400) < 1, "Coast t=0 voll")
        let coast1 = GestureMath.displayLinkCoast(CGPoint(x: 400, y: 0), elapsed: 0.08)
        ok(coast1.x < 200 && coast1.x > 40, "Coast 80 ms halbiert+")
        let restFill = GestureMath.displayLinkVelocity(
            prev: CGPoint(x: 100, y: 100),
            current: CGPoint(x: 100, y: 100),
            frameDt: 0.125,
            palmVel: CGPoint(x: 0.4, y: 0),
            mappedScale: 2560,
            palmVelScreen: CGPoint(x: 400, y: 0),
            mad: 0.003
        )
        ok(abs(restFill.x) < 0.001 && abs(restFill.y) < 0.001, "Rest-MAD Fill tot")
        let step = GestureMath.palmKalmanStep(p: 0, q: 0.10, r: 0.045)
        ok(abs(step.k - (0.10 / 0.145)) < 0.001, "P=0 k = q/(q+r)")
        ok(step.p > 0 && step.p < 0.10, "P schrumpft")
        ok(GestureMath.palmKalmanResidualMul(residual: 0.0005) < 0.5, "Tiny Residual k runter")
        ok(GestureMath.palmKalmanResidualMul(residual: 0.08) > 0.95, "Flick Residual k voll")
        let pKalman = GestureMath.palmKalman(
            prev: CGPoint(x: 0.40, y: 0.40),
            meas: CGPoint(x: 0.41, y: 0.55),
            vel: .zero,
            dt: 0.125,
            pX: 0.02,
            pY: 0.08
        )
        ok(pKalman.pX != pKalman.pY, "2×2 P je Achse")
        let laptopSeam = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let extSeam = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        ok(GestureMath.screenSeamHolds(point: CGPoint(x: 1455, y: 200), last: laptopSeam), "Naht 15 px hält ohne screens")
        ok(!GestureMath.screenSeamHolds(point: CGPoint(x: 2000, y: 200), last: laptopSeam), "weit kein Hold")
        ok(
            !GestureMath.screenSeamHolds(
                point: CGPoint(x: 1455, y: 200),
                last: laptopSeam,
                screens: [laptopSeam, extSeam]
            ),
            "Naht 15 px auf 5K kein Wall"
        )
        let seamScr = GestureMath.destClampScreen(
            point: CGPoint(x: 1455, y: 200),
            mapBounds: nil,
            screens: [laptopSeam, extSeam],
            lastScreen: laptopSeam
        )
        ok(seamScr == extSeam, "Hysterese gibt Seam an 5K ab")
        ok(GestureMath.stillChip(frozen: true) == "HOLD", "HOLD-Chip")
        ok(GestureMath.stillChip(frozen: false) == nil, "ohne Freeze kein HOLD")
        ok(GestureMath.fpsLatchChip(fps: 8, ghosting: false, frozen: true) == "8 Hz · HOLD", "fps HOLD")
        ok(abs(GestureMath.displayLinkPeriodAdaptive(frameDt: 0.125) - 1.0 / 90.0) < 0.001, "8 fps Fill 90 Hz")
        ok(abs(GestureMath.displayLinkPeriodAdaptive(frameDt: 0.016) - 1.0 / 30.0) < 0.001, "24 fps Fill 30 Hz")
        let breath: [CGFloat] = [0.001, 0.012, 0.001, 0.011, 0.002, 0.013]
        ok(GestureMath.palmMad(breath) > 0.004, "Y-Atem MAD")
        ok(GestureMath.palmMad([CGFloat](repeating: 0.001, count: 4)) < 0.001, "still MAD 0")
        let qY = GestureMath.palmKalmanQ(luma: 0.50, mad: 0.012)
        let qX = GestureMath.palmKalmanQ(luma: 0.50, mad: 0.001)
        ok(qY > qX, "Y-Atem mehr Q als X-Still")
        let axisK = GestureMath.palmKalman(
            prev: CGPoint(x: 0.40, y: 0.40),
            meas: CGPoint(x: 0.401, y: 0.45),
            vel: .zero,
            dt: 0.125,
            madX: 0.001,
            madY: 0.018,
            pX: 0.04,
            pY: 0.04
        )
        ok(abs(axisK.pos.x - 0.40) < abs(axisK.pos.y - 0.40), "Atem-Q folgt Y, X klebt")
        let laptopEdge = CGRect(x: 0, y: 0, width: 1440, height: 900)
        ok(abs(GestureMath.destEdgeMul(point: CGPoint(x: 720, y: 450), screen: laptopEdge) - 1) < 0.001, "Mitte Gain 1")
        ok(GestureMath.destEdgeMul(point: CGPoint(x: 10, y: 450), screen: laptopEdge) < 0.55, "Rand Gain runter")
        let edgeV = GestureMath.destEdgeVel(CGPoint(x: -400, y: 0), point: CGPoint(x: 8, y: 400), screen: laptopEdge)
        ok(edgeV.x > -400 && edgeV.x < -100, "Outbound Fill am Rand gedämpft")
        let cap13 = GestureMath.cursorWarpCapScreen(screen: CGRect(x: 0, y: 0, width: 1440, height: 900))
        let cap5k = GestureMath.cursorWarpCapScreen(screen: CGRect(x: 0, y: 0, width: 5120, height: 2880))
        ok(cap5k > cap13, "Warp-Cap folgt Diagonale")
        ok(GestureMath.cursorWarpCapScreen(screen: nil) == 48, "ohne Screen Floor 48")
        let breathMad = GestureMath.palmMad(breath)
        let stillMad = GestureMath.palmMad([CGFloat](repeating: 0.001, count: 6))
        ok(GestureMath.palmDeadOf(mad: breathMad) > GestureMath.palmDeadOf(mad: stillMad), "Y-Atem Dead > X-Still")
        ok(GestureMath.palmDeadOf(mad: stillMad) < 0.012, "X-Still Dead lässt Flick 0,015")
        ok(GestureMath.palmDeadOf(mad: 0.012) <= GestureMath.palmDeadTense, "Dead Cap Tense")
        let laptopEdge2 = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let stepIn = GestureMath.destEdgeStep(
            from: CGPoint(x: 8, y: 400),
            to: CGPoint(x: -40, y: 400),
            screen: laptopEdge2
        )
        ok(stepIn.x > -40, "Kamera-Tick am Rand gedämpft")
        ok(stepIn.x < 8, "Trotzdem nach außen")
        let midStep = GestureMath.destEdgeStep(
            from: CGPoint(x: 720, y: 450),
            to: CGPoint(x: 800, y: 450),
            screen: laptopEdge2
        )
        ok(abs(midStep.x - 800) < 0.001, "Mitte Kamera-Tick voll")
        let extEdge = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let fillDest = GestureMath.destEdgeScreen(steal: extEdge, map: laptopEdge2, main: laptopEdge2)
        ok(fillDest == extEdge, "Fill-Dest = stealScreen")
        ok(GestureMath.destEdgeScreen(steal: nil, map: laptopEdge2, main: extEdge) == laptopEdge2, "ohne steal Map")
        ok(GestureMath.destEdgeChip(mul: 0.40) == "EDGE", "HUD EDGE")
        ok(GestureMath.destEdgeChip(mul: 1) == nil, "Mitte kein EDGE")
        ok(GestureMath.destEdgeChip(mul: 0.40, dist: 12) == "EDGE 12", "HUD EDGE px")
        let capRelock = GestureMath.cursorWarpCapScreenOf(steal: nil, map: CGRect(x: 0, y: 0, width: 5120, height: 2880))
        ok(capRelock > 48, "Relock Map-Diagonale, nicht Floor 48")
        ok(GestureMath.cursorWarpCapScreenOf(steal: nil, map: nil) == 48, "ohne steal/map Floor")
        ok(GestureMath.fpsLatchChip(fps: 8, ghosting: false, edge: true) == "8 Hz · EDGE", "fps EDGE")
        ok(GestureMath.pinchCloseNeed(dt: 0.25, justOpened: true) == 1, "Dropout Open kein Need 2")
        ok(GestureMath.pinchCloseNeed(dt: 0.125, justOpened: true) == 2, "8 fps Open-Hysterese")
        ok(GestureMath.pinchCloseNeed(dt: 0.125, justOpened: false) == 1, "8 fps Close 1")
        let share8 = GestureMath.displayTickWarpShare(floor: 64, frameDt: 0.125, period: 1.0 / 90.0)
        ok(share8 < 12 && share8 >= 2, "Fill-Share unter Floor")
        ok(GestureMath.displayTickCoalesced(now: 1.004, lastMove: 1.0), "Fill coalesced 4 ms")
        ok(!GestureMath.displayTickCoalesced(now: 1.02, lastMove: 1.0), "Fill nach 20 ms")
        let laptopMap = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let extMap = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        ok(
            !GestureMath.destClampMapHolds(mapScreenID: nil, currentScreenID: "2", dest: laptopMap, screenCount: 2),
            "destBounds ohne screenID bei 2 Screens tot"
        )
        let race = GestureMath.destClampScreen(
            point: CGPoint(x: 2000, y: 200),
            mapBounds: laptopMap,
            screens: [laptopMap, extMap],
            lastScreen: nil,
            mapScreenID: nil,
            currentScreenID: "2"
        )
        ok(race == extMap, "Wake ohne screenID: Screen unter Cursor")
        ok(GestureMath.palmUnstillOf(dx: 0.015, dy: 0.012), "X-Flick weckt HOLD")
        ok(!GestureMath.palmUnstillOf(dx: 0.001, dy: 0.001), "beide tot kein Wake")
        ok(GestureMath.palmStillOf(dx: 0.001, dy: 0.001), "beide tot Still")
        ok(!GestureMath.palmStillOf(dx: 0.015, dy: 0.001), "X-Flick kein Still")
        let bezel = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let cornerMin = GestureMath.destEdgeMul(point: CGPoint(x: 8, y: 400), screen: bezel)
        let cornerHyp = GestureMath.destEdgeMul(point: CGPoint(x: 8, y: 8), screen: bezel)
        ok(cornerHyp > cornerMin, "Ecke radial nicht doppelt tot")
        let edge8 = GestureMath.destEdgeMul(point: CGPoint(x: 8, y: 400), screen: bezel, dt: 0.125)
        let edge24 = GestureMath.destEdgeMul(point: CGPoint(x: 8, y: 400), screen: bezel, dt: 0.016)
        ok(abs(edge8 - edge24) < 0.001, "destEdge räumlich, nicht × dt")
        let tau13 = GestureMath.displayLinkCoastTau(screen: CGRect(x: 0, y: 0, width: 1440, height: 900))
        let tau5k = GestureMath.displayLinkCoastTau(screen: CGRect(x: 0, y: 0, width: 5120, height: 2880))
        ok(tau5k > tau13, "Coast τ folgt Diagonale")
        ok(abs(GestureMath.displayLinkCoastTau(screen: nil) - 0.055) < 0.001, "ohne Screen τ 55")
        ok(GestureMath.cursorWarpCapHold(prev: 180, live: 48, frames: 2) == 180, "Relock Map-Cap 3 Frames")
        ok(GestureMath.cursorWarpCapHold(prev: 180, live: 48, frames: 0) == 48, "ohne Hold live")
        ok(GestureMath.cursorWarpCapHold(prev: 180, live: 48, frames: 4) == 48, "nach 3 Frames live")
        let dist12 = GestureMath.destEdgeDist(point: CGPoint(x: 12, y: 450), screen: bezel)
        ok(abs((dist12 ?? -1) - 12) < 0.001, "Rand-Dist 12")
        ok(abs(GestureMath.destEdgeMulY(point: CGPoint(x: 8, y: 400), screen: bezel) - 1) < 0.001, "Bezel Y frei")
        ok(GestureMath.destEdgeMulX(point: CGPoint(x: 8, y: 400), screen: bezel) < 0.55, "Bezel X tot")
        let along = GestureMath.destEdgeVel(CGPoint(x: 0, y: 400), point: CGPoint(x: 8, y: 400), screen: bezel)
        ok(abs(along.y - 400) < 0.001, "Fill Y entlang Bezel ungedämpft")
        ok(abs(along.x) < 0.001, "Fill X 0 bleibt 0")
        ok(!GestureMath.destEdgeApplies(dragging: true, pinchHeld: false), "Drag kein destEdge")
        ok(!GestureMath.destEdgeApplies(dragging: false, pinchHeld: true), "Pinch kein destEdge")
        ok(GestureMath.destEdgeApplies(dragging: false, pinchHeld: false), "Pointer destEdge")
        ok(!GestureMath.destEdgeApplies(dragging: false, pinchHeld: false, clickLocked: true), "Click-Lock kein destEdge")
        let fill8 = GestureMath.destEdgeFill(CGPoint(x: 400, y: 0), point: CGPoint(x: 8, y: 400), screen: bezel, frameDt: 0.125)
        ok(abs(fill8.x - 400) < 0.5, "Inbound Fill X frei")
        ok(abs(fill8.y) < 0.001, "Fill Y 0 bleibt 0")
        let fill24 = GestureMath.destEdgeFill(CGPoint(x: 400, y: 80), point: CGPoint(x: 8, y: 400), screen: bezel, frameDt: 0.016)
        ok(abs(fill24.x - 400) < 0.5, "24 fps Inbound Fill X frei")
        ok(abs(fill24.y - 80) < 0.001, "Fill Y entlang Bezel frei")
        let fillOut = GestureMath.destEdgeFill(CGPoint(x: -400, y: 0), point: CGPoint(x: 8, y: 400), screen: bezel, frameDt: 0.016)
        ok(abs(fillOut.x + 192) < 0.5, "Outbound Fill X gedämpft")
        let fillMid = GestureMath.destEdgeFill(CGPoint(x: 400, y: 0), point: CGPoint(x: 720, y: 450), screen: bezel, frameDt: 0.016)
        ok(abs(fillMid.x - 400) < 0.001, "Mitte Fill ungedämpft")
        let alongStep = GestureMath.destEdgeStep(
            from: CGPoint(x: 8, y: 400),
            to: CGPoint(x: 8, y: 520),
            screen: bezel
        )
        ok(abs(alongStep.y - 520) < 0.001, "Kamera-Tick Y entlang Bezel voll")
        ok(GestureMath.destEdgeChipOf(point: CGPoint(x: 8, y: 400), screen: bezel) == "EDGE X 8", "HUD EDGE X")
        ok(GestureMath.destEdgeChipOf(point: CGPoint(x: 720, y: 450), screen: bezel) == nil, "Mitte kein EDGE-Chip")
        ok(
            GestureMath.destEdgeChipOf(point: CGPoint(x: 8, y: 8), screen: bezel) == "EDGE X 8 · Y 8",
            "Ecke EDGE X und Y"
        )
        ok(GestureMath.lockFrameRate(15) == 15, "Continuity 15 bleibt 15")
        ok(GestureMath.lockFrameRate(18) == 18, "18 fps nicht auf 8")
        ok(GestureMath.formatPixelBonus(osType: GestureMath.formatFourCC420f, fps: 24) > 0, "420f @ 24 Bonus")
        ok(GestureMath.formatPixelBonus(osType: GestureMath.formatFourCCBGRA, fps: 8) < 0, "BGRA @ 8 Strafe")
        ok(GestureMath.formatPrefers420(osType: GestureMath.formatFourCC420f, fps: 15), "420f @ 15 nativ")
        ok(!GestureMath.formatPrefers420(osType: GestureMath.formatFourCCBGRA, fps: 15), "BGRA nicht 420")
        let s720_15 = GestureMath.formatScore(width: 1280, height: 720, fps: 15)
            + GestureMath.formatPixelBonus(osType: GestureMath.formatFourCC420f, fps: 15)
        let s720_8bgra = GestureMath.formatScore(width: 1280, height: 720, fps: 8)
            + GestureMath.formatPixelBonus(osType: GestureMath.formatFourCCBGRA, fps: 8)
        ok(s720_15 > s720_8bgra, "720p 420f@15 vor BGRA@8")
        ok(abs(GestureMath.displayLinkTimerPeriod() - 1.0 / 90.0) < 0.001, "Timer 90 Hz bei 8 fps")
        ok(abs(GestureMath.displayLinkTimerPeriod(frameDt: 0.016) - 1.0 / 60.0) < 0.001, "24 fps Timer 60")
        ok(abs(GestureMath.palmROIMinFrac - 0.10) < 0.001, "ROI min 0,10")
        let roiEdge = GestureMath.palmVisionROI(palm: CGPoint(x: 0.98, y: 0.50), scale: 0.12, secondHand: false)
        ok(roiEdge != nil && (roiEdge?.width ?? 0) >= 0.10, "Kanten-Hand ROI nicht tot")
        let axisY = GestureMath.cursorWarpAxis(from: CGPoint(x: 8, y: 400), to: CGPoint(x: 8, y: 520), cap: 48)
        ok(abs(axisY.x - 8) < 0.001, "Warp-Axis X frei")
        ok(abs(axisY.y - 448) < 0.001, "Warp-Axis Y 48 px")
        ok(
            !GestureMath.cursorWarpIsTeleport(from: CGPoint(x: 8, y: 400), to: CGPoint(x: 8, y: 520), cap: 48),
            "Y-Flick 120 kein Teleport"
        )
        ok(
            GestureMath.cursorWarpIsTeleport(from: .zero, to: CGPoint(x: 400, y: 0), cap: 48),
            "400 px Reconnect Teleport"
        )
        let axisX = GestureMath.cursorWarpAxis(from: .zero, to: CGPoint(x: 200, y: 30), cap: 80)
        ok(abs(axisX.x - 80) < 0.001, "X geklemmt")
        ok(abs(axisX.y - 30) < 0.001, "Y-Flick am X-Warp frei")
        ok(abs(GestureMath.lockFrameLo(30, rangeMin: 1) - 15) < 1e-9, "Continuity 1–30 Floor 15")
        ok(abs(GestureMath.lockFrameLo(60, rangeMin: 1) - 30) < 1e-9, "Built-in 60 Floor 30")
        ok(abs(GestureMath.lockFrameLo(30, rangeMin: 24) - 24) < 1e-9, "Built-in 24–30 bleibt 24")
        ok(abs(GestureMath.lockFrameLo(8, rangeMin: 1) - 8) < 1e-9, "8 fps kein 15-Floor")
        ok(abs(GestureMath.lockFrameLo(15, rangeMin: 1) - 15) < 1e-9, "15 bleibt 15")
        ok(abs(GestureMath.pinchClickNeed(dt: 0.067) - 0.1332) < 0.01, "15 fps Need interpoliert")
        ok(abs(Double(GestureMath.pinchTipFloorOf(dt: 0.125)) - 0.10) < 0.001, "8 fps Tip-Floor 0,10")
        ok(abs(Double(GestureMath.pinchTipFloorOf(dt: 0.016)) - 0.18) < 0.001, "24 fps Tip-Floor 0,18")
        ok(abs(Double(GestureMath.pinchTipFloorOf(dt: 0.016, continuity: true)) - 0.10) < 0.001, "Continuity Tip 0,10")
        ok(abs(GestureMath.fistAELock - 1.2) < 0.001, "AE 1,2 s")
        ok(GestureMath.formatBandChip(osType: GestureMath.formatFourCC420f, lo: 15, hi: 24) == "420f 15–24", "Format-Chip 420f")
        ok(GestureMath.formatBandChip(osType: GestureMath.formatFourCCBGRA, lo: 8, hi: 8, fps: 8) == "BGRA 8", "Format-Chip BGRA 8")
        ok(abs(GestureMath.cursorWarpCapX() - GestureMath.destEdgePad) < 0.001, "Warp-X = destEdgePad")
        let ptrPred = GestureMath.pointerPredict(from: .zero, vel: CGPoint(x: 100, y: 0), dt: 0.04)
        ok(abs(ptrPred.x - 4) < 0.001, "Predict 1 Frame 4 px")
        ok(GestureMath.displayLinkTimerRetarget(current: 1.0 / 90.0, frameDt: 0.016) != nil, "Timer 8→24 retarget")
        ok(GestureMath.displayLinkTimerRetarget(current: 1.0 / 90.0, frameDt: 0.125) == nil, "Timer 8 bleibt 90")
        ok(GestureMath.thermalHoldsFormat(medianFps: 10, slowFor: 2.0), "Thermal hält Format")
        ok(!GestureMath.thermalHoldsFormat(medianFps: 24, slowFor: 2.0), "24 fps kein Thermal")
        ok(GestureMath.sessionPresetClampsContinuity(true), "Continuity Preset aus")
        ok(!GestureMath.sessionPresetClampsContinuity(false), "Built-in Preset 720p")
        ok(GestureMath.lockFrameRate(30, continuity: true) == 30, "Continuity 30")
        ok(GestureMath.lockFrameRate(60) == 60, "Built-in 60 bleibt 60")
        ok(abs(GestureMath.formatPixelBonus(osType: GestureMath.formatFourCC420f, fps: 24) - 32) < 0.001, "420f @ 24 extra")
        let laptopWarp = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let capAxes = GestureMath.cursorWarpCapAxis(steal: laptopWarp, map: laptopWarp)
        ok(capAxes.x > capAxes.y - 1, "Laptop Warp-Cap X ≥ Y")
        let warpFrom = CGPoint(x: 8, y: 400)
        let warpFlickY = CGPoint(x: 200, y: 480)
        let heldY = GestureMath.cursorWarpHoldsSmoothOf(from: warpFrom, to: warpFlickY, capX: 80, capY: 96)
        ok(heldY != nil, "X-Warp hält Smooth")
        let heldYOk = heldY ?? .zero
        ok(abs(heldYOk.x - 8) < 0.001, "X-Teleport freeze")
        ok(abs(heldYOk.y - 480) < 0.001, "Y-Flick am X-Warp frei")
        let hypotHeld = GestureMath.cursorWarpHoldsSmooth(from: .zero, to: CGPoint(x: 200, y: 30), cap: 80)
        ok(hypotHeld != nil && abs((hypotHeld?.y ?? -1) - 30) < 0.001, "Hypot-Warp friert nicht Y")
        let fillFrom = CGPoint.zero
        let fillStep = GestureMath.displayLinkCursorOf(
            from: fillFrom,
            velocity: CGPoint(x: 2000, y: 400),
            elapsed: 0.04,
            capX: 28,
            capY: 48
        )
        ok(abs(fillStep.x - 28) < 0.2, "Fill X Cap")
        ok(abs(fillStep.y - 16) < 0.2, "Fill Y nicht hypot-skaliert")
        let mapLap = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let mapExt = CGRect(x: 1440, y: 0, width: 2560, height: 1440)
        ok(GestureMath.destMapStealChip(steal: mapExt, map: mapLap) == "MAP≠STEAL", "HUD MAP≠STEAL")
        ok(GestureMath.destMapStealChip(steal: mapLap, map: mapLap) == nil, "gleicher Schirm kein Chip")
        ok(!GestureMath.pinchWantOpen(ratio: 0.59, proxRatio: 0.59, vel: 0, dt: 0.067, scale: 0.12), "15 fps 0,59 ohne Vel bleibt")
        ok(GestureMath.pinchWantOpen(ratio: 0.59, proxRatio: 0.59, vel: 0, dt: 0.016, scale: 0.12), "24 fps 0,59 öffnet")
        ok(GestureMath.pinchOpenNeed(dt: 0.067, ratioOnly: true) == 2, "15 fps ratio-only 2")
        ok(GestureMath.pinchOpenNeed(dt: 0.067, ratioOnly: false) == 2, "15 fps Vel 2")
        ok(GestureMath.formatScore(width: 1440, height: 1080, fps: 15) > 0, "Desk-View 4:3 1440×1080")
        ok(GestureMath.formatScore(width: 1920, height: 1440, fps: 15) > 0, "Desk-View 4:3 1920×1440")
        ok(GestureMath.formatScore(width: 1080, height: 1440, fps: 15) > 0, "Portrait Desk-View")
        ok(abs(GestureMath.luma420Lift(osType: GestureMath.formatFourCC420v, luma: 16.0 / 255.0)) < 0.02, "420v Offset 16 → 0")
        ok(abs(GestureMath.luma420Lift(osType: GestureMath.formatFourCC420f, luma: 0.50) - 0.50) < 0.001, "420f ohne Lift")
        ok(GestureMath.enhanceSkipsCopy(copyMs: 12), "Copy 12 ms skip Enhance")
        ok(!GestureMath.enhanceSkipsCopy(copyMs: 3), "Copy 3 ms Enhance")
        ok(GestureMath.pinchClickNeedsStill(speed: 0.08) == false, "Wrist 0,08 zittert")
        ok(GestureMath.pinchClickNeedsStill(speed: 0.005), "still reicht")
        ok(GestureMath.pinchClickFires(held: 0.20, need: 0.09, speed: 0.005), "Need+still Down")
        ok(!GestureMath.pinchClickFires(held: 0.20, need: 0.09, speed: 0.08), "Need ohne still kein Down")
        let warpY = GestureMath.cursorWarpChip(from: .zero, to: CGPoint(x: 10, y: 80), capX: 40, capY: 40)
        ok(warpY == "WARP Y 80", "WARP Y Chip")
        ok(GestureMath.destHudChip(steal: "MAP≠STEAL", warp: "WARP Y 80", edge: "EDGE X 8") == "MAP≠STEAL", "HUD Steal vor Warp")
        ok(GestureMath.destHudChip(steal: nil, warp: "WARP Y 80", edge: "EDGE X 8") == "WARP Y 80", "HUD Warp vor Edge")
        ok(GestureMath.formatCopyChip(band: "420f 15–24", copyMs: 12) == "420f 15–24 · COPY 12", "COPY Chip")
        ok(GestureMath.formatCopyChip(band: "420f 15–24", copyMs: 3) == "420f 15–24", "Copy 3 ms kein COPY")
        ok(GestureMath.videoStabilizationOff(true), "Continuity Stab aus")
        ok(!GestureMath.videoStabilizationOff(false), "Built-in Stab egal")
        ok(GestureMath.continuityUsbHold(dt: 0.125, hold: 0.20), "USB 8 fps < 400 ms halten")
        ok(!GestureMath.continuityUsbHold(dt: 0.125, hold: 0.50), "USB nach 400 ms frei")
        ok(!GestureMath.continuityUsbHold(dt: 0.016, hold: 0.10), "24 fps kein USB-Hold")
        ok(GestureMath.formatHopHold(last: 1.0, now: 1.2), "Hop 200 ms block")
        ok(!GestureMath.formatHopHold(last: 1.0, now: 1.5), "Hop nach 400 ms")
        ok(GestureMath.pinchClickBlocksAfterScroll(lastScroll: 1.0, now: 1.10), "Klick 100 ms nach Scroll tot")
        ok(!GestureMath.pinchClickBlocksAfterScroll(lastScroll: 1.0, now: 1.25), "Klick nach 180 ms")
        ok(GestureMath.deadManFistIdle(lastFist: 1.0, lastHand: 1.0, now: 2.7), "Faust-Idle 1,6 s")
        ok(!GestureMath.deadManFistIdle(lastFist: 1.0, lastHand: 1.0, now: 2.0), "Faust frisch kein Idle")
        ok(!GestureMath.deadManFistIdle(lastFist: 0, lastHand: 1.0, now: 3.0), "ohne Faust kein 1,6")
        let hp = GestureMath.palmHighpass(dx: 0.20, slow: 0)
        ok(abs(hp.fast - 0.17) < 0.001, "Hochpass Flick")
        ok(abs(hp.slow - 0.03) < 0.001, "Hochpass Slow")
        ok(abs(GestureMath.deadManFist - 1.6) < 0.001, "Dead-Man Faust 1,6")
        ok(abs(GestureMath.palmHighpassAlpha(0.04) - 0.08) < 0.001, "Hochpass Pref Floor 0,08")
        ok(abs(GestureMath.palmHighpassAlpha(0.40) - 0.25) < 0.001, "Hochpass Pref Cap 0,25")
        ok(abs(GestureMath.palmHighpassAlpha(0.15) - 0.15) < 0.001, "Hochpass Pref 0,15")
        let click15 = GestureMath.pinchClickNeed(dt: 0.055)
        let open15 = TimeInterval(GestureMath.pinchOpenNeed(dt: 0.055)) * 0.055
        ok(click15 + 1e-9 >= open15, "15 fps Click ≥ Open × dt")
        ok(abs(GestureMath.pinchClickNeed(dt: 0.016) - 0.09) < 0.001, "24 fps Click 90 ms")
        ok(GestureMath.deadManFistChip(lastFist: 1.0, lastHand: 1.0, now: 1.4) == "IDLE 1,2", "Faust-HUD 1,2")
        ok(GestureMath.deadManFistChip(lastFist: 1.0, lastHand: 1.0, now: 2.7) == nil, "Faust-HUD nach Idle leer")
        ok(GestureMath.deadManFistChip(lastFist: 0, lastHand: 1.0, now: 1.4) == nil, "ohne Faust kein IDLE-Chip")
        let hold0 = GestureMath.hudChipPeakHold(current: "WARP Y 80", held: nil, remaining: 0, need: 1)
        ok(hold0.chip == "WARP Y 80" && hold0.remaining == 1, "WARP peak setzt Hold")
        let hold1 = GestureMath.hudChipPeakHold(current: nil, held: hold0.chip, remaining: hold0.remaining, need: 1)
        ok(hold1.chip == "WARP Y 80" && hold1.remaining == 0, "WARP 1 Frame halten")
        let hold2 = GestureMath.hudChipPeakHold(current: nil, held: hold1.chip, remaining: hold1.remaining, need: 1)
        ok(hold2.chip == nil, "WARP nach Hold weg")
        let bezelCoast = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let tauBase = GestureMath.displayLinkCoastTau(screen: bezelCoast)
        let tauX = GestureMath.displayLinkCoastTauAxis(
            base: tauBase,
            mul: GestureMath.destEdgeMulX(point: CGPoint(x: 8, y: 400), screen: bezelCoast)
        )
        let tauY = GestureMath.displayLinkCoastTauAxis(
            base: tauBase,
            mul: GestureMath.destEdgeMulY(point: CGPoint(x: 8, y: 400), screen: bezelCoast)
        )
        ok(tauX < tauY - 0.005, "Coast τ X am Rand kürzer")
        ok(abs(tauY - tauBase) < 0.001, "Coast τ Y entlang Bezel frei")
        let coasted = GestureMath.displayLinkCoast(
            CGPoint(x: 400, y: 200),
            elapsed: 0.011,
            tauX: tauX,
            tauY: tauY
        )
        ok(abs(coasted.x) < abs(coasted.y) * 2, "Coast X am Rand stirbt schneller")
        ok(!GestureMath.pointerPredictApplies(reduceMotion: true), "Reduce Motion Predict aus")
        ok(GestureMath.pointerPredictApplies(reduceMotion: false), "Predict an")
        ok(GestureMath.reconnectCenterStageOff(continuity: true, enabled: true), "Continuity CS Reconnect aus")
        ok(!GestureMath.reconnectCenterStageOff(continuity: false, enabled: true), "Built-in CS egal")
        ok(GestureMath.visionTakesNative(osType: GestureMath.formatFourCC420f), "Vision 420f nativ")
        ok(GestureMath.visionTakesNative(osType: GestureMath.formatFourCC420v), "Vision 420v nativ")
        ok(!GestureMath.visionTakesNative(osType: GestureMath.formatFourCCBGRA), "BGRA wandelt")
        ok(!GestureMath.ringCopyConverts(osType: GestureMath.formatFourCC420f), "420f kein Convert")
        ok(GestureMath.ringCopyConverts(osType: GestureMath.formatFourCCBGRA), "BGRA Convert")
        ok(!GestureMath.enhanceSkipsCopy(copyMs: 12, converts: false), "Native Blit kein Enhance-Skip")
        ok(GestureMath.formatCopyChip(band: "420f 15–24", copyMs: 12, converts: false) == "420f 15–24", "Native kein COPY")
        let openSec15 = GestureMath.pinchOpenNeedSec(dt: 0.067)
        let clickSec15 = GestureMath.pinchClickNeed(dt: 0.067)
        ok(openSec15 <= clickSec15 + 0.02, "15 fps Open-Need ≤ Click-Need")
        ok(abs(GestureMath.pinchOpenNeedSec(dt: 0.067, ratioOnly: true) - 0.134) < 0.01, "15 fps Open 2 Frames")
        ok(GestureMath.clamshellWakeReselects(wasClosed: true, nowClosed: false), "Klappe auf reselect")
        ok(!GestureMath.clamshellWakeReselects(wasClosed: false, nowClosed: false), "offen bleibt")
        ok(!GestureMath.videoStabilizationApplies(continuity: true), "Continuity Stabilizer aus")
        ok(GestureMath.videoStabilizationApplies(continuity: false), "Built-in Stabilizer darf")
        let bezelAxis = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let fillAxis = GestureMath.destEdgeFillAxis(
            CGPoint(x: 400, y: 400),
            point: CGPoint(x: 8, y: 400),
            screen: bezelAxis,
            frameDt: 0.016
        )
        ok(abs(fillAxis.x - 400) < 0.5, "Fill-Axis Inbound X frei")
        ok(abs(fillAxis.y - 400) < 0.001, "Fill-Axis Y frei")
        let fillAxisOut = GestureMath.destEdgeFillAxis(
            CGPoint(x: -400, y: 400),
            point: CGPoint(x: 8, y: 400),
            screen: bezelAxis,
            frameDt: 0.016
        )
        ok(fillAxisOut.x > -400 && fillAxisOut.x < -100, "Fill-Axis Outbound Void dämpft")
        let nowFling: TimeInterval = 100

        let flickTrail: [(t: TimeInterval, x: CGFloat, y: CGFloat)] = [
            (nowFling, 0.50, 0.40),
            (nowFling + 0.04, 0.50, 0.55),
            (nowFling + 0.08, 0.50, 0.78)
        ]
        ok(GestureMath.flingFromTrail(flickTrail) == .throwUp, "Fling-Fenster wirft hoch")
        let dragTrail: [(t: TimeInterval, x: CGFloat, y: CGFloat)] = [
            (nowFling, 0.50, 0.50),
            (nowFling + 0.40, 0.52, 0.53)
        ]
        ok(GestureMath.flingFromTrail(dragTrail) == .none, "Ziehen kein Werfen")
        let startCenter: [(t: TimeInterval, x: CGFloat, y: CGFloat)] = [
            (nowFling, 0.50, 0.50),
            (nowFling + 0.04, 0.50, 0.62),
            (nowFling + 0.08, 0.50, 0.80)
        ]
        ok(GestureMath.flingFromTrail(startCenter) == .throwUp, "Pinch-Mitte Flick-außen wirft")
        ok(GestureMath.ringSlotStealDrops(-1), "Slot −1 drop")
        ok(!GestureMath.ringSlotStealDrops(0), "Slot 0 hält")
        ok(GestureMath.enhanceDestFormat(osType: GestureMath.formatFourCC420f) == GestureMath.formatFourCC420f, "Enhance 420f")
        ok(GestureMath.enhanceDestFormat(osType: GestureMath.formatFourCC420v) == GestureMath.formatFourCC420v, "Enhance 420v")
        ok(GestureMath.enhanceDestFormat(osType: GestureMath.formatFourCCBGRA) == GestureMath.formatFourCCBGRA, "Enhance BGRA")
        ok(GestureMath.pinchOpenHolds(frames: 1, dt: 0.125), "8 fps 1 Frame Open")
        ok(!GestureMath.pinchOpenHolds(frames: 1, dt: 0.016), "24 fps 1 Frame kein Open")
        ok(GestureMath.pinchOpenHolds(frames: 3, dt: 0.016), "24 fps 3 Frames Open")
        ok(GestureMath.pinchOpenHolds(frames: 2, dt: 0.067), "15 fps 2 Frames Open")
        ok(!GestureMath.pinchOpenHolds(frames: 1, dt: 0.067), "15 fps 1 Frame kein Open")
        ok(GestureMath.palmROISecondNils(dt: 0.125), "8 fps zweite Hand Full")
        ok(GestureMath.palmROISecondNils(dt: 0.016), "24 fps zweite Hand Full")
        ok(GestureMath.palmROISecondHands(handSized: 2), "zwei echte Hände Full")
        ok(!GestureMath.palmROISecondHands(handSized: 1), "eine Hand Crop")
        ok(GestureMath.palmVisionROI(palm: CGPoint(x: 0.5, y: 0.5), scale: 0.12, secondHand: true, dt: 0.125) == nil, "8 fps zwei Hände Full")
        ok(GestureMath.palmVisionROI(palm: CGPoint(x: 0.5, y: 0.5), scale: 0.12, secondHand: true, dt: 0.016) == nil, "24 fps zwei Hände Full")
        let ghostOn = GestureMath.overlayGhostPeakHold(current: true, remaining: 0, need: 2)
        ok(ghostOn.ghost && ghostOn.remaining == 2, "Ghost peak setzt 2")
        let ghost1 = GestureMath.overlayGhostPeakHold(current: false, remaining: ghostOn.remaining, need: 2)
        ok(ghost1.ghost && ghost1.remaining == 1, "Ghost Frame 1 halten")
        let ghost2 = GestureMath.overlayGhostPeakHold(current: false, remaining: ghost1.remaining, need: 2)
        ok(ghost2.ghost && ghost2.remaining == 0, "Ghost Frame 2 halten")
        ok(!GestureMath.overlayGhostPeakHold(current: false, remaining: 0, need: 2).ghost, "Ghost nach Hold weg")
        ok(GestureMath.axProbeWakeInvalidates(wasClosed: true, nowClosed: false), "Klappe AX neu")
        ok(!GestureMath.axProbeWakeInvalidates(wasClosed: false, nowClosed: false), "offen kein AX-Invalidate")
        ok(abs(GestureMath.palmHighpassAlpha(0.12) - 0.12) < 0.001, "Hochpass Pref 0,12")
        ok(GestureMath.ringSlotStealCount(prev: 0, dropped: true) == 1, "Steal +1")
        ok(GestureMath.ringSlotStealCount(prev: 3, dropped: false) == 2, "Steal Decay")
        ok(GestureMath.ringSlotStealChip(3) == "STEAL 3", "HUD STEAL")
        ok(GestureMath.ringSlotStealChip(0) == nil, "kein STEAL")
        ok(GestureMath.formatStealChip(band: "420f 15–24", drops: 2) == "420f 15–24 · STEAL 2", "Format+STEAL")
        ok(GestureMath.formatStealChip(band: "", drops: 2) == "STEAL 2", "STEAL allein")
        ok(GestureMath.palmROILatchChip(secondHand: true, dt: 0.125) == "ROI S1", "8 fps Latch HUD")
        ok(GestureMath.palmROILatchChip(secondHand: true, dt: 0.016) == nil, "24 fps Full kein Latch")
        ok(GestureMath.palmROILatchChip(secondHand: false, dt: 0.125) == nil, "eine Hand kein Latch")
        ok(GestureMath.palmHighpassResets(actor: "S2", prev: "S1"), "Hochpass Actor-Wechsel")
        ok(!GestureMath.palmHighpassResets(actor: "S1", prev: "S1"), "gleiche Hand hält Slow")
        ok(!GestureMath.palmHighpassResets(actor: nil, prev: "S1"), "Ghost hält Slow")
        ok(GestureMath.palmHighpassResets(actor: "S1", prev: nil), "erste Hand seed")
        let seeded = GestureMath.palmHighpassLoad(savedX: nil, savedY: nil, dx: 0.10, dy: 0.08)
        ok(abs(seeded.x - 0.10) < 0.001 && abs(seeded.y - 0.08) < 0.001, "neue Hand Slow=dx")
        let heldSlow = GestureMath.palmHighpassLoad(savedX: 0.02, savedY: 0.01, dx: 0.10, dy: 0.08)
        ok(abs(heldSlow.x - 0.02) < 0.001 && abs(heldSlow.y - 0.01) < 0.001, "S1 Slow hält")
        ok(GestureMath.palmHighpassChip(actor: "S1", alpha: 0.15) == "α 0.15 S1", "HUD α S1")
        ok(GestureMath.palmHighpassChip(actor: nil, alpha: 0.15) == nil, "ohne Actor kein Chip")
        ok(GestureMath.pointerPredictChip(dx: 12, dy: 0) == "PREDICT 12", "PREDICT HUD")
        ok(GestureMath.pointerPredictChip(dx: 3, dy: 4) == nil, "Predict unter 8 tot")
        ok(GestureMath.visionBufferOrientation(width: 720, height: 1280) == 1, "0° Portrait up")
        ok(GestureMath.visionBufferOrientation(width: 1280, height: 720) == 1, "0° Landscape up")
        ok(GestureMath.visionBufferOrientation(width: 720, height: 1280, rotationApplied: true) == 6, "gedreht Portrait right")
        ok(GestureMath.axHitCacheNeed(dt: 0.125) == 2, "8 fps AX 2 Frames")
        ok(GestureMath.axHitCacheNeed(dt: 0.016) == 1, "24 fps AX 1 Frame")
        ok(abs(GestureMath.axHitCacheDist(dt: 0.125) - 16) < 0.001, "8 fps AX 16 px")
        ok(abs(GestureMath.axHitCacheDist(dt: 0.016) - 2.5) < 0.001, "24 fps AX 2,5 px")
        ok(abs(GestureMath.axHitCacheDistTTL(0.26) - 16) < 0.001, "TTL 260 ms 16 px")
        ok(GestureMath.axTypeIDHolds(true), "TypeID ok")
        ok(!GestureMath.axTypeIDHolds(false), "TypeID tot")
        ok(GestureMath.ringSlotCap(8), "Ring 8 wächst")
        ok(!GestureMath.ringSlotCap(12), "Ring 12 Cap")
        ok(!GestureMath.ringRebuilds(count: 8, width: 1280, height: 720, format: 1, wantW: 1280, wantH: 720, wantFmt: 1), "Ring gleiche Geometrie hält")
        ok(GestureMath.ringRebuilds(count: 0, width: 0, height: 0, format: 0, wantW: 1280, wantH: 720, wantFmt: 1), "Ring leer neu")
        ok(GestureMath.ringRebuilds(count: 3, width: 800, height: 600, format: 1, wantW: 1280, wantH: 720, wantFmt: 1), "Ring Format-Hop neu")
        ok(!GestureMath.ringRebuilds(count: 3, width: 1280, height: 720, format: 1, wantW: 1280, wantH: 720, wantFmt: 1), "Ring 3 Slots kein Sturm")
        ok(GestureMath.enhanceDownscales(luma: 0.18), "Nacht Enhance")
        ok(!GestureMath.enhanceDownscales(luma: 0.50), "Tag kein Downscale")
        ok(GestureMath.displayLinkTimerCommonMode(), "Timer .common")
        ok(abs(GestureMath.destEdgePadOf(width: 1440) - 40) < 0.001, "13″ Pad 40")
        ok(abs(GestureMath.destEdgePadOf(width: 2560) - 64) < 0.001, "5K Pad 64")
        ok(!GestureMath.scaleMoved(old: 0.40, span: 0.45, dt: 0.125), "8 fps Scale-Jitter tot")
        ok(GestureMath.scaleMoved(old: 0.40, span: 0.55, dt: 0.125), "8 fps Scale echt")
        ok(GestureMath.pinchHoldAborts(mad: 0.040, rest: 0.012), "Wrist-MAD > Rest abort")
        ok(!GestureMath.pinchHoldAborts(mad: 0.010, rest: 0.012), "still kein abort")
        ok(!GestureMath.pinchHoldAborts(mad: 0.018, rest: 0.012), "Atem kein abort")
        ok(abs(GestureMath.cursorWarpCapX(width: 2560) - 64) < 0.001, "Warp-X 5K 64")
        ok(abs(GestureMath.cursorWarpCapX() - GestureMath.destEdgePad) < 0.001, "Warp-X Floor 40")
        let fiveKEdge = CGRect(x: 0, y: 0, width: 2560, height: 1440)
        ok(GestureMath.destEdgeMulX(point: CGPoint(x: 50, y: 720), screen: fiveKEdge) < 1, "5K Pad 64 bei 50 px")
        ok(abs(GestureMath.destEdgeMulX(point: CGPoint(x: 80, y: 720), screen: fiveKEdge) - 1) < 0.001, "5K 80 außerhalb Pad")
        ok(GestureMath.palmHighpassFresh(savedAt: 1, now: 2.5), "Slow 1,5 s frisch")
        ok(!GestureMath.palmHighpassFresh(savedAt: 1, now: 4), "Slow 3 s tot")
        ok(!GestureMath.palmHighpassFresh(savedAt: nil, now: 1), "ohne at tot")
        let staleLoad = GestureMath.palmHighpassLoad(savedX: 0.02, savedY: 0.01, dx: 0.10, dy: 0.08, fresh: false)
        ok(abs(staleLoad.x - 0.10) < 0.001 && abs(staleLoad.y - 0.08) < 0.001, "stale Slow = dx")
        let freshLoad = GestureMath.palmHighpassLoad(savedX: 0.02, savedY: 0.01, dx: 0.10, dy: 0.08, fresh: true)
        ok(abs(freshLoad.x - 0.02) < 0.001, "frisch Slow hält")
        ok(GestureMath.palmVelScreenResets(actor: "S2", prev: "S1"), "Vel Actor-Wechsel")
        ok(!GestureMath.palmVelScreenResets(actor: "S1", prev: "S1"), "gleiche Hand hält Vel")
        ok(!GestureMath.palmVelScreenResets(actor: nil, prev: "S1"), "Ghost hält Vel")
        let velKept = GestureMath.palmVelScreenAfterActor(resets: false, vel: CGPoint(x: 400, y: 0))
        ok(abs(velKept.x - 400) < 0.001, "ohne Reset Vel hält")
        let velZero = GestureMath.palmVelScreenAfterActor(resets: true, vel: CGPoint(x: 400, y: 0))
        ok(abs(velZero.x) < 0.001 && abs(velZero.y) < 0.001, "Actor-Switch Vel 0")
        ok(GestureMath.palmMappedClears(resets: true), "lastMapped tot nach Switch")
        ok(!GestureMath.palmMappedClears(resets: false), "lastMapped hält")
        ok(GestureMath.palmVelChip(zeroed: true) == "VEL 0", "HUD VEL 0")
        ok(GestureMath.palmVelChip(zeroed: false) == nil, "ohne Zero kein Chip")
        ok(GestureMath.scaleAbortClick(hadSpan: true, closedCount: 1), "Scale 2→1 abort")
        ok(!GestureMath.scaleAbortClick(hadSpan: true, closedCount: 2), "zwei Hände Scale hält")
        ok(!GestureMath.scaleAbortClick(hadSpan: false, closedCount: 1), "ohne Span kein abort")
        ok(abs(GestureMath.destEdgePadPref(12) - 24) < 0.001, "Pad Pref Floor 24")
        ok(abs(GestureMath.destEdgePadPref(200) - 160) < 0.001, "Pad Pref Cap 160")
        ok(abs(GestureMath.destEdgePadPref(64) - 64) < 0.001, "Pad Pref 64")
        ok(GestureMath.palmVelScreenFresh(savedAt: 1, now: 1.3), "Vel 0,3 s frisch")
        ok(!GestureMath.palmVelScreenFresh(savedAt: 1, now: 1.5), "Vel 0,5 s tot")
        ok(!GestureMath.palmVelScreenFresh(savedAt: nil, now: 1), "Vel ohne at tot")
        ok(GestureMath.palmVelScreenTeleport(from: .zero, to: CGPoint(x: 400, y: 0)), "400 px Teleport")
        ok(!GestureMath.palmVelScreenTeleport(from: .zero, to: CGPoint(x: 72, y: 0)), "Flick 72 px kein Teleport")
        ok(GestureMath.palmVelScreenOf(raw: CGPoint(x: 800, y: 0), teleport: true) == .zero, "Teleport Vel 0")
        ok(GestureMath.palmVelChip(zeroed: true, teleport: true) == "JUMP", "HUD JUMP")
        ok(GestureMath.palmVelChip(zeroed: true) == "VEL 0", "HUD VEL 0 bleibt")
        let staleCoast = GestureMath.palmVelScreenKeep(moved: true, mad: 0.018, vel: CGPoint(x: 800, y: 0), fresh: false)
        ok(staleCoast == .zero, "stale Coast tot")
        let jumpPair = GestureMath.palmMappedPair(current: CGPoint(x: 400, y: 0), prev: .zero, teleport: true)
        ok(jumpPair.mapped.x == 400 && jumpPair.mapped2.x == 400, "JUMP lastMapped2 = current")
        let keepPair = GestureMath.palmMappedPair(current: CGPoint(x: 80, y: 0), prev: .zero, teleport: false)
        ok(keepPair.mapped.x == 80 && abs(keepPair.mapped2.x) < 0.001, "Flick lastMapped2 hält")
        let jumpFill = GestureMath.displayLinkVelocity(
            prev: jumpPair.mapped2,
            current: jumpPair.mapped,
            frameDt: 0.125,
            palmVelScreen: .zero
        )
        ok(hypot(jumpFill.x, jumpFill.y) < 8, "Fill nach JUMP 0")
        let staleFill = GestureMath.displayLinkVelocity(
            prev: CGPoint(x: 100, y: 100),
            current: CGPoint(x: 100, y: 100),
            frameDt: 0.125,
            palmVelScreen: CGPoint(x: 800, y: 0),
            fresh: false
        )
        ok(abs(staleFill.x) < 0.001 && abs(staleFill.y) < 0.001, "Fill stale tot")
        ok(!GestureMath.palmVelScreenFresh(savedAt: 0, now: 1), "Vel at 0 tot")
        ok(GestureMath.displayTickMutesJump(true), "JUMP Fill mute")
        ok(!GestureMath.displayTickMutesJump(false), "ohne JUMP Fill")
        ok(GestureMath.displayTickMutesJump(false, held: true), "Hold Fill mute")
        ok(!GestureMath.displayTickClearsJumpMute(held: true), "Hold MUTE bleibt")
        ok(GestureMath.displayTickClearsJumpMute(held: false), "ohne Hold MUTE 1 Tick")
        ok(GestureMath.palmVelAtOf(now: 1, teleport: true) == nil, "JUMP at nil")
        ok(GestureMath.palmVelAtOf(now: 1, teleport: false) == 1, "Vel at now")
        ok(GestureMath.palmVelAtOf(now: 1, teleport: false, reset: true) == nil, "Reset at nil")
        ok(GestureMath.palmLateralityLock(prev: 1, live: 2, otherClaimed: false) == 1, "Links bleibt Links")
        ok(GestureMath.palmLateralityLock(prev: 1, live: 2, otherClaimed: true) == 2, "andere Hand nimmt Links")
        ok(GestureMath.palmLateralityLock(prev: 0, live: 2, otherClaimed: false) == 2, "unbekannt nimmt Live")
        ok(GestureMath.palmLateralityLock(prev: 1, live: 2, otherClaimed: true, claimedTicks: 1) == 1, "1 Tick Flip hält")
        ok(GestureMath.palmLateralityLock(prev: 1, live: 2, otherClaimed: true, claimedTicks: 3) == 2, "3 Ticks Flip löst")
        ok(!GestureMath.palmLateralityDebounce(otherClaimed: true, ticks: 2), "2 Ticks kein Debounce")
        ok(GestureMath.palmLateralityDebounce(otherClaimed: true, ticks: 3), "3 Ticks Debounce")
        ok(GestureMath.palmHighpassMutesJump(true), "JUMP mute Slow")
        ok(!GestureMath.palmHighpassMutesJump(false), "ohne JUMP Slow hält")
        ok(GestureMath.palmLateralityCode(true, right: false) == 1, "Code Links")
        ok(GestureMath.palmLateralityCode(false, right: true) == 2, "Code Rechts")
        ok(GestureMath.jointConfHolds(GestureMath.jointConfEMA(prev: 0.40, live: 0.05)), "EMA hält Flicker")
        ok(!GestureMath.jointConfHolds(0.05), "raw 0,05 tot")
        ok(GestureMath.continuityTransportChip(continuity: true, usb: true) == "USB", "USB Chip")
        ok(GestureMath.continuityTransportChip(continuity: true, usb: false) == "WIFI", "WIFI Chip")
        ok(GestureMath.continuityTransportChip(continuity: false, usb: true) == nil, "Built-in kein Transport")
        ok(GestureMath.continuityIsUSB("USB-123"), "uniqueID USB")
        ok(!GestureMath.continuityIsUSB("ContinuityCamera"), "Continuity Wi-Fi")
        ok(GestureMath.formatTransportChip(band: "420f 15–24", continuity: true, usb: true) == "420f 15–24 · USB", "Format USB")
        ok(GestureMath.formatTransportChip(band: "420f 15–24", continuity: false, usb: true) == "420f 15–24", "Built-in Band")
        ok(abs(GestureMath.destEdgePadOf(width: 2560, floor: GestureMath.destEdgePadPref(80)) - 80) < 0.001, "Pref 80 5K")
        ok(abs(GestureMath.destEdgePadOf(width: 2560, floor: GestureMath.destEdgePadPref(24)) - 64) < 0.001, "Pref 24 5K bleibt 64")
        ok(GestureMath.palmWarpHoldJumps(true), "Warp-Hold = JUMP")
        ok(!GestureMath.palmWarpHoldJumps(false), "ohne Hold kein JUMP")
        ok(GestureMath.palmWarpHoldReleaseJumps(wasHeld: true, nowHeld: false), "Hold-Release JUMP")
        ok(!GestureMath.palmWarpHoldReleaseJumps(wasHeld: true, nowHeld: true), "Hold hält kein Release")
        ok(!GestureMath.palmWarpHoldReleaseJumps(wasHeld: false, nowHeld: false), "ohne Hold kein Release")
        ok(GestureMath.palmVelChip(zeroed: true, teleport: true, muted: true) == "JUMP · MUTE", "HUD JUMP MUTE")
        ok(GestureMath.palmVelChip(zeroed: true, muted: true) == "MUTE", "HUD MUTE")
        ok(GestureMath.palmLateralityChip(locked: 1, live: 2) == "← L", "HUD ← L")
        ok(GestureMath.palmLateralityChip(locked: 2, live: 1) == "R →", "HUD R →")
        ok(GestureMath.palmLateralityChip(locked: 1, live: 1) == nil, "ohne Flip kein Chip")
        ok(GestureMath.continuityIsUSB("ContinuityCamera", modelID: "UVC", localizedName: "iPhone"), "modelID UVC = USB")
        ok(!GestureMath.continuityIsUSB("ContinuityCamera", modelID: "iPhone", localizedName: "iPhone"), "Continuity Wi-Fi ohne UVC")
        ok(GestureMath.continuityIsUSB("abc", transportUSB: true), "transportUSB")
        ok(GestureMath.continuityTransportIsUSB(0x75736220), "FourCC usb")
        ok(GestureMath.continuityTransportIsUSB(0x75766320), "FourCC uvc")
        ok(!GestureMath.continuityTransportIsUSB(0x77726C73), "FourCC wrls")
        let holdRelease = GestureMath.palmMappedPair(current: CGPoint(x: 64, y: 0), prev: .zero, teleport: GestureMath.palmWarpHoldReleaseJumps(wasHeld: true, nowHeld: false))
        ok(holdRelease.mapped.x == 64 && holdRelease.mapped2.x == 64, "Release lastMapped2 = current")
        let holdFill = GestureMath.displayLinkVelocity(
            prev: holdRelease.mapped2,
            current: holdRelease.mapped,
            frameDt: 0.125,
            palmVelScreen: .zero
        )
        ok(hypot(holdFill.x, holdFill.y) < 8, "Fill nach Hold-Release 0")
        ok(GestureMath.cursorWarpSnapsRestore(teleport: true, mapped: true), "Map-Teleport Snap")
        ok(!GestureMath.cursorWarpSnapsRestore(teleport: true, mapped: false), "Relativ kein Snap")
        ok(!GestureMath.cursorWarpSnapsRestore(teleport: false, mapped: true), "ohne Teleport kein Snap")
        ok(GestureMath.cursorWarpSnapsRestore(teleport: true, mapped: false, dropout: 1.0), "Relativ Snap nach Dropout")
        ok(!GestureMath.cursorWarpSnapsRestore(teleport: true, mapped: false, dropout: 0.4), "Relativ frisch kein Snap")
        let snapQ = GestureMath.cursorWarpRestoreOf(from: .zero, to: CGPoint(x: 400, y: 0), snap: true)
        ok(snapQ.x == 400, "Snap auf q")
        let heldRestore = GestureMath.cursorWarpRestoreOf(from: .zero, to: CGPoint(x: 400, y: 0), snap: false)
        ok(abs(heldRestore.x) < 0.001, "ohne Snap from")
        let snapFill = GestureMath.displayLinkVelocity(
            prev: CGPoint(x: 400, y: 0),
            current: CGPoint(x: 400, y: 0),
            frameDt: 0.125,
            palmVelScreen: .zero
        )
        ok(hypot(snapFill.x, snapFill.y) < 8, "Fill nach Snap 0")
        ok(GestureMath.displayTickClearsJumpMute(held: false), "Snap MUTE 1 Tick")
        ok(GestureMath.jointConfIsTip("indexTip"), "indexTip ist Tip")
        ok(!GestureMath.jointConfIsTip("wrist"), "wrist kein Tip")
        ok(!GestureMath.jointConfRestores(holds: true, isTip: true), "Tip nicht restore")
        ok(GestureMath.jointConfRestores(holds: true, isTip: false), "Palm restore")
        ok(!GestureMath.jointConfRestores(holds: false, isTip: false), "ohne Hold kein Restore")
        ok(!GestureMath.continuityIsUSB("USB-WiFi-Bridge", localizedName: "Wi-Fi"), "Wi-Fi schlägt USB-String")
        ok(GestureMath.continuityIsUSB("USB-WiFi-Bridge", transportUSB: true, localizedName: "Wi-Fi"), "transportUSB schlägt Wi-Fi")
        ok(abs(GestureMath.destEdgePadLive(width: 2560, pref: 24) - 64) < 0.001, "Live Pad 5K 64")
        ok(GestureMath.destEdgePadLiveChip(width: 2560, pref: 24) == "PAD 64", "PAD Chip")
        ok(GestureMath.destEdgePadLiveChip(width: 1440, pref: 24) == "PAD 36", "Laptop Pref 24 live 36")
        ok(!GestureMath.palmLateralityClaimFlips(true), "claimed vor Bind kein Flip")
        ok(GestureMath.palmLateralityTakes(locked: 1, claimedSame: true) == 0, "zweite Links tot")
        ok(GestureMath.palmLateralityTakes(locked: 2, claimedSame: false) == 2, "freie Seite hält")
        let occFollow = GestureMath.fingerOcclusionFollows(
            lastTip: CGPoint(x: 0.40, y: 0.60),
            lastPalm: CGPoint(x: 0.50, y: 0.20),
            palm: CGPoint(x: 0.55, y: 0.20)
        )
        ok(abs(occFollow.x - 0.45) < 0.001, "OCC Tip folgt Palm-X")
        ok(abs(occFollow.y - 0.60) < 0.001, "OCC Tip Y hält")
        ok(GestureMath.pinchClickAbortsOcc(true), "OCC kein Klick")
        ok(!GestureMath.pinchClickAbortsOcc(false), "ohne OCC Klick ok")
        ok(!GestureMath.pinchClickFires(held: 0.20, need: 0.09, speed: 0.005, occ: true), "OCC sperrt Down")
        ok(abs(GestureMath.destEdgePadWidthOf([1440, 2560]) - 2560) < 0.001, "Pad-Breite 5K")
        ok(abs(GestureMath.destEdgePadWidthOf([]) - 2560) < 0.001, "Pad-Breite Fallback")
        let padNow = GestureMath.destEdgePadNow(screen: CGRect(x: 0, y: 0, width: 2560, height: 1440), pref: 24)
        ok(abs(padNow - 64) < 0.001, "PadNow 5K 64")
        ok(abs(GestureMath.destEdgePadNow(screen: nil, pref: 24) - 64) < 0.001, "PadNow nil Fallback 2560 → 64")
        ok(abs(GestureMath.slotLateralityDist(palmDist: 0.04, slotCode: 1, liveCode: 1) - 0.04) < 0.001, "Laterality Match Dist")
        ok(abs(GestureMath.slotLateralityDist(palmDist: 0.04, slotCode: 1, liveCode: 2) - 0.14) < 0.001, "Laterality Mismatch +0,10")
        ok(abs(GestureMath.slotLateralityDist(palmDist: 0.04, slotCode: 0, liveCode: 1) - 0.04) < 0.001, "Slot unknown kein Penalty")
        let padLaptop = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let studio = CGRect(x: 1440, y: 0, width: 2560, height: 1440)
        let onStudio = GestureMath.destEdgeScreenAt(
            point: CGPoint(x: 2000, y: 200),
            screens: [padLaptop, studio],
            steal: laptop,
            map: laptop.union(studio),
            main: laptop
        )
        ok(onStudio == studio, "Pad-Screen 5K unter Cursor, nicht steal Laptop")
        let onLaptop = GestureMath.destEdgeScreenAt(
            point: CGPoint(x: 100, y: 100),
            screens: [laptop, studio],
            steal: studio,
            map: nil,
            main: laptop
        )
        ok(onLaptop == laptop, "Pad-Screen Laptop unter Cursor")
        ok(abs(GestureMath.destEdgePadAt(point: CGPoint(x: 2000, y: 200), screens: [laptop, studio], pref: 24) - 64) < 0.001, "5K Pad 64")
        ok(abs(GestureMath.destEdgePadAt(point: CGPoint(x: 100, y: 100), screens: [laptop, studio], pref: 24) - 36) < 0.001, "Laptop Pad 36")
        ok(GestureMath.overlayChipCap(["HP", "VEL", "JUMP", "MUTE", "LAT", "OCC", "PREDICT"]).count == 6, "Chip-Stack Cap 6")
        ok(GestureMath.overlayChipCap(["", "OCC", ""]).count == 1, "leere Chips raus")
        ok(GestureMath.overlayChipCap([]).isEmpty, "leer bleibt leer")
        ok(GestureMath.overlayChipTone("OCC") == 1, "OCC Danger")
        ok(GestureMath.overlayChipTone("JUMP · MUTE") == 1, "JUMP MUTE Danger")
        ok(GestureMath.overlayChipTone("PREDICT 12") == 2, "PREDICT Cyan")
        ok(GestureMath.overlayChipTone("ROI S1") == 2, "ROI Cyan")
        ok(GestureMath.overlayChipTone("α 0.15 S1") == 0, "HP Amber")
        let seam5k = GestureMath.destEdgeScreenAt(
            point: CGPoint(x: 1444, y: 200),
            screens: [laptop, studio],
            steal: laptop,
            map: laptop.union(studio),
            main: laptop
        )
        ok(seam5k == studio, "Seam 4px auf 5K nicht Laptop")
        let seamPad = GestureMath.destEdgePadAt(
            point: CGPoint(x: 1444, y: 200),
            screens: [laptop, studio],
            pref: 24,
            steal: laptop,
            map: laptop.union(studio),
            main: laptop
        )
        ok(abs(seamPad - 64) < 0.001, "Seam 5K Pad 64")
        let gapHit = GestureMath.destEdgeScreenAt(
            point: CGPoint(x: 1438, y: 200),
            screens: [laptop, studio],
            steal: studio,
            map: nil,
            main: laptop
        )
        ok(gapHit == laptop, "Seam Laptop-Seite hält Laptop")
        ok(GestureMath.slotLateralityMatches(slotCode: 1, liveCode: 1), "Laterality Match")
        ok(!GestureMath.slotLateralityMatches(slotCode: 1, liveCode: 2), "Laterality Mismatch")
        ok(!GestureMath.slotLateralityPrefers(slotCode: 2, liveCode: 1, haveMatch: true), "Match-Slot sperrt Mismatch")
        ok(GestureMath.slotLateralityPrefers(slotCode: 2, liveCode: 1, haveMatch: false), "ohne Match Dist bleibt")
        ok(GestureMath.overlayChipCap(["HP", "VEL", "JUMP", "MUTE", "LAT", "OCC", "PREDICT", "PREDICT"]).count == 6, "Chip unique Cap")
        let chipKept = GestureMath.overlayChipCap(["HP", "LAT", "α 0.15", "PREDICT", "ROI S1", "X", "JUMP · MUTE", "OCC"])
        ok(chipKept.contains("JUMP · MUTE") && chipKept.contains("OCC"), "Danger überlebt Cap")
        let stepPad = GestureMath.destEdgeStep(
            from: CGPoint(x: 8, y: 400),
            to: CGPoint(x: -40, y: 400),
            screen: laptop,
            pad: 80
        )
        let stepFloor = GestureMath.destEdgeStep(
            from: CGPoint(x: 8, y: 400),
            to: CGPoint(x: -40, y: 400),
            screen: laptop,
            pad: 40
        )
        ok(stepPad.x > stepFloor.x, "destEdgeStep pad dämpft Kamera-Tick")
        ok(
            GestureMath.destEdgeCrosses(
                from: CGPoint(x: 1430, y: 200),
                to: CGPoint(x: 1500, y: 200),
                screens: [laptop, studio]
            ),
            "Laptop→5K Cross"
        )
        ok(
            !GestureMath.destEdgeCrosses(
                from: CGPoint(x: 100, y: 100),
                to: CGPoint(x: 200, y: 100),
                screens: [laptop, studio]
            ),
            "Laptop intern kein Cross"
        )
        ok(GestureMath.destEdgeSkipsCross(true), "Cross skippt destEdge")
        ok(!GestureMath.destEdgeSkipsCross(false), "ohne Cross Step")
        ok(
            GestureMath.destEdgeFillToward(
                from: CGPoint(x: 1430, y: 200),
                vel: CGPoint(x: 400, y: 0),
                screens: [laptop, studio]
            ),
            "Fill Richtung 5K skippt"
        )
        ok(
            !GestureMath.destEdgeFillToward(
                from: CGPoint(x: 720, y: 450),
                vel: CGPoint(x: 40, y: 0),
                screens: [laptop, studio]
            ),
            "Fill Mitte kein Cross"
        )
        let inbound = GestureMath.destEdgeStep(
            from: CGPoint(x: 1448, y: 200),
            to: CGPoint(x: 1600, y: 200),
            screen: studio,
            pad: 64
        )
        ok(abs(inbound.x - 1600) < 1, "Inbound 5K kein Dämpfer")
        let outVoid = GestureMath.destEdgeStep(
            from: CGPoint(x: 8, y: 200),
            to: CGPoint(x: -40, y: 200),
            screen: laptop,
            pad: 40
        )
        ok(outVoid.x > -40, "Outbound Void dämpft")
        ok(GestureMath.destEdgeFillLead(pad: 64) >= 80, "Fill-Lead ≥ Pad+16")
        ok(GestureMath.destEdgeFillLead(pad: 24) == 48, "Fill-Lead Floor 48")
        let gapScreens = [laptop, CGRect(x: 1472, y: 0, width: 2560, height: 1440)]
        ok(
            GestureMath.destEdgeCrosses(
                from: CGPoint(x: 1430, y: 200),
                to: CGPoint(x: 1455, y: 200),
                screens: gapScreens
            ),
            "Seam-Lücke 32 px = Cross"
        )
        ok(
            !GestureMath.destEdgeCrosses(
                from: CGPoint(x: 8, y: 200),
                to: CGPoint(x: -400, y: 200),
                screens: [laptop, studio]
            ),
            "Void kein Cross"
        )
        let order = GestureMath.overlayChipCap(["HP", "LAT", "JUMP · MUTE", "OCC", "PREDICT", "ROI S1", "X", "Y"])
        ok(order.first == "HP", "Chip-Cap Original-Reihenfolge")
        ok(order.contains("JUMP · MUTE") && order.contains("OCC"), "Danger bleibt in Original-Lage")

        ok(GestureMath.palmVelScreenTeleportX(from: .zero, to: CGPoint(x: 400, y: 10), cap: 40), "X-Teleport 400")
        ok(!GestureMath.palmVelScreenTeleportY(from: .zero, to: CGPoint(x: 400, y: 10), cap: 40), "Y 10 kein Teleport")
        let axisVel = GestureMath.palmVelScreenOf(raw: CGPoint(x: 100, y: 50), teleportX: true, teleportY: false)
        ok(abs(axisVel.x) < 0.001 && abs(axisVel.y - 50) < 0.001, "X-Teleport Y-Coast hält")
        ok(
            GestureMath.destEdgeHasNeighbor(
                point: CGPoint(x: 1435, y: 200),
                toward: 1,
                screens: [laptop, studio],
                axisX: true
            ),
            "Seam Laptop→5K HasNeighbor"
        )
        ok(
            !GestureMath.destEdgeHasNeighbor(
                point: CGPoint(x: 8, y: 200),
                toward: -1,
                screens: [laptop, studio],
                axisX: true
            ),
            "Void kein Neighbor"
        )
        ok(
            GestureMath.destEdgeHasNeighbor(
                point: CGPoint(x: 1448, y: 200),
                toward: -1,
                screens: [laptop, studio],
                axisX: true
            ),
            "Rückweg 5K→Laptop HasNeighbor"
        )
        ok(
            !GestureMath.destEdgeHasNeighbor(
                point: CGPoint(x: 1435, y: 200),
                toward: 1,
                screens: [laptop],
                axisX: true
            ),
            "ein Schirm kein Neighbor"
        )
        let preSeam = GestureMath.destEdgeStep(
            from: CGPoint(x: 1435, y: 200),
            to: CGPoint(x: 1500, y: 200),
            screen: laptop,
            pad: 40,
            screens: [laptop, studio]
        )
        ok(abs(preSeam.x - 1500) < 1, "20px vor Seam Gain 1")
        let preSeamDamp = GestureMath.destEdgeStep(
            from: CGPoint(x: 1435, y: 200),
            to: CGPoint(x: 1500, y: 200),
            screen: laptop,
            pad: 40
        )
        ok(preSeamDamp.x < 1480, "ohne screens 20px vor Seam dämpft")
        let voidStepScr = GestureMath.destEdgeStep(
            from: CGPoint(x: 8, y: 200),
            to: CGPoint(x: -40, y: 200),
            screen: laptop,
            pad: 40,
            screens: [laptop, studio]
        )
        ok(voidStepScr.x > -40, "Void mit screens dämpft")
        ok(
            abs(
                GestureMath.destEdgeNeighborMul(
                    GestureMath.destEdgeMulX(point: CGPoint(x: 1435, y: 200), screen: laptop, pad: 40, toward: 1),
                    true
                ) - 1
            ) < 0.001,
            "NeighborMul Seam 1"
        )
        let voidMul = GestureMath.destEdgeNeighborMul(
            GestureMath.destEdgeMulX(point: CGPoint(x: 8, y: 200), screen: laptop, pad: 40, toward: -1),
            GestureMath.destEdgeHasNeighbor(
                point: CGPoint(x: 8, y: 200),
                toward: -1,
                screens: [laptop, studio],
                axisX: true
            )
        )
        ok(voidMul < 0.6, "Coast Mul Void dämpft")
        let seamMul = GestureMath.destEdgeNeighborMul(
            GestureMath.destEdgeMulX(point: CGPoint(x: 1435, y: 200), screen: laptop, pad: 40, toward: 1),
            GestureMath.destEdgeHasNeighbor(
                point: CGPoint(x: 1435, y: 200),
                toward: 1,
                screens: [laptop, studio],
                axisX: true
            )
        )
        ok(abs(seamMul - 1) < 0.001, "Coast Mul Rückweg/Seam 1")
        ok(
            GestureMath.destEdgeChipOf(
                point: CGPoint(x: 1435, y: 200),
                screen: laptop,
                pad: 40,
                screens: [laptop, studio]
            ) == nil,
            "Seam kein EDGE-Chip"
        )
        ok(
            GestureMath.destEdgeChipOf(
                point: CGPoint(x: 8, y: 200),
                screen: laptop,
                pad: 40,
                screens: [laptop, studio]
            ) == "EDGE X 8",
            "Void EDGE trotz Seam-Nachbar"
        )
        let gapNeighbor = [laptop, CGRect(x: 1472, y: 0, width: 2560, height: 1440)]
        ok(
            GestureMath.destEdgeHasNeighbor(
                point: CGPoint(x: 1435, y: 200),
                toward: 1,
                screens: gapNeighbor,
                axisX: true
            ),
            "Gap 32 px HasNeighbor"
        )
        let farGap = [laptop, CGRect(x: 1520, y: 0, width: 2560, height: 1440)]
        ok(
            !GestureMath.destEdgeHasNeighbor(
                point: CGPoint(x: 1435, y: 200),
                toward: 1,
                screens: farGap,
                axisX: true
            ),
            "Gap 80 px kein Neighbor"
        )

        // PIP-Biegung: 40° zählt nicht als offen — sonst Not-Aus an der Kralle.
        let mcp = CGPoint(x: 0.50, y: 0.34)
        let pip = CGPoint(x: 0.50, y: 0.50)
        let rad40 = 40 * CGFloat.pi / 180
        let tip40 = CGPoint(x: pip.x + sin(rad40) * 0.16, y: pip.y + cos(rad40) * 0.16)
        var claw = hand(tipsY: 0.72)
        claw[.indexMCP] = mcp
        claw[.indexPIP] = pip
        claw[.indexTip] = tip40
        claw[.middleMCP] = mcp
        claw[.middlePIP] = pip
        claw[.middleTip] = tip40
        claw[.ringMCP] = mcp
        claw[.ringPIP] = pip
        claw[.ringTip] = tip40
        claw[.littleMCP] = mcp
        claw[.littlePIP] = pip
        claw[.littleTip] = tip40
        let bend40 = GestureClassifier.pipBendDegrees(claw, tip: .indexTip, pip: .indexPIP, mcp: .indexMCP) ?? -1
        ok(bend40 > 35 && bend40 < 45, "40°-Kralle gemessen")
        ok(!GestureClassifier.isExtended(claw, tip: .indexTip, pip: .indexPIP, mcp: .indexMCP), "40° nicht extended")
        ok(GestureClassifier.openScore(joints: claw) == 0, "Kralle openScore 0")
        ok(!GestureMath.palmReachKills(palmScale: 0.40, openScore: GestureClassifier.openScore(joints: claw)), "Kralle kein Not-Aus")
        ok(GestureClassifier.isExtended(open, tip: .indexTip, pip: .indexPIP, mcp: .indexMCP), "gerade Finger extended")
        ok(GestureMath.displayTickCoasts(80), "Coast über Floor")
        ok(!GestureMath.displayTickCoasts(8), "Jitter kein Coast")
        ok(GestureMath.pollFocusHolds(moved: false, dragging: false, hadFocus: true), "Focus hält ohne Bewegung")
        ok(!GestureMath.pollFocusHolds(moved: true, dragging: false, hadFocus: true), "Focus folgt Bewegung")
        ok(GestureMath.pollFocusHolds(moved: true, dragging: true, hadFocus: true), "Grab hält Focus")
        ok(!GestureMath.pollFocusHolds(moved: false, dragging: false, hadFocus: false), "ohne Focus darf setzen")
        let rad12 = 12 * CGFloat.pi / 180
        var mild = hand(tipsY: 0.72)
        mild[.indexMCP] = CGPoint(x: 0.50, y: 0.34)
        mild[.indexPIP] = CGPoint(x: 0.50, y: 0.50)
        mild[.indexTip] = CGPoint(x: 0.50 + sin(rad12) * 0.16, y: 0.50 + cos(rad12) * 0.16)
        ok(GestureClassifier.isExtended(mild, tip: .indexTip, pip: .indexPIP, mcp: .indexMCP), "12° noch extended")
        var dipClaw = hand(tipsY: 0.72)
        dipClaw[.indexMCP] = CGPoint(x: 0.50, y: 0.34)
        dipClaw[.indexPIP] = CGPoint(x: 0.50, y: 0.52)
        dipClaw[.indexDIP] = CGPoint(x: 0.50, y: 0.68)
        let radDip = 40 * CGFloat.pi / 180
        dipClaw[.indexTip] = CGPoint(x: 0.50 + sin(radDip) * 0.12, y: 0.68 + cos(radDip) * 0.12)
        ok(!GestureClassifier.isExtended(dipClaw, tip: .indexTip, pip: .indexPIP, mcp: .indexMCP), "DIP 40° nicht extended")
        var faceClaw = hand(tipsY: 0.72)
        faceClaw[.indexMCP] = CGPoint(x: 0.50, y: 0.34)
        faceClaw[.indexPIP] = CGPoint(x: 0.50, y: 0.40)
        faceClaw[.indexTip] = CGPoint(x: 0.50, y: 0.44)
        ok(!GestureClassifier.isExtended(faceClaw, tip: .indexTip, pip: .indexPIP, mcp: .indexMCP), "Kralle zur Kamera nicht extended")
        ok(GestureMath.displayTickNeedsCamera(true), "Kamera live Fill")
        ok(!GestureMath.displayTickNeedsCamera(false), "Kamera tot kein Fill")
        ok(!GestureMath.displayTickNeedsCamera(true, frameAge: 1), "stille Kamera kein Fill")
        ok(GestureMath.displayTickNeedsCamera(true, frameAge: 0.05), "frisches Frame Fill")
        ok(!GestureMath.axDragRebindsNeighbor(), "AX-Timeout greift kein Nachbarfenster")
        let visQ = GestureMath.axSnapQuartz(
            visibleCocoa: CGRect(x: 0, y: 0, width: 1440, height: 900),
            primaryMaxY: 900
        )
        ok(abs(visQ.minY) < 0.001 && abs(visQ.height - 900) < 0.001, "Snap visibleFrame Quartz")
        let grabOff = GestureMath.axGrabOffset(cursorQuartz: CGPoint(x: 100, y: 40), axPosition: CGPoint(x: 80, y: 20))
        ok(abs(grabOff.x - 20) < 0.001 && abs(grabOff.y - 20) < 0.001, "AX-Offset Quartz, nicht Cocoa-Flip")
        let grabDest = GestureMath.axGrabDest(cursorQuartz: CGPoint(x: 140, y: 80), offset: grabOff)
        ok(abs(grabDest.x - 120) < 0.001 && abs(grabDest.y - 60) < 0.001, "AX-Dest Quartz")
        ok(
            GestureMath.destEdgeHasNeighbor(
                point: CGPoint(x: 1448, y: 200),
                toward: 0,
                screens: [laptop, studio],
                axisX: true
            ),
            "Seam still HasNeighbor"
        )
        ok(
            !GestureMath.destEdgeHasNeighbor(
                point: CGPoint(x: 8, y: 200),
                toward: 0,
                screens: [laptop, studio],
                axisX: true
            ),
            "Void still kein Neighbor"
        )
        let overlap = GestureMath.destEdgeNearest(
            CGPoint(x: 1436, y: 200),
            screens: [laptop, CGRect(x: 1420, y: 0, width: 2560, height: 1440)]
        )?.screen
        ok(overlap != nil && overlap!.width > 2000, "Überlapp innerster/größerer Schirm")
        let stillMul = GestureMath.destEdgeNeighborMul(
            GestureMath.destEdgeMulX(point: CGPoint(x: 1448, y: 200), screen: studio, pad: 64, toward: 0),
            GestureMath.destEdgeHasNeighbor(
                point: CGPoint(x: 1448, y: 200),
                toward: 0,
                screens: [laptop, studio],
                axisX: true
            )
        )
        ok(abs(stillMul - 1) < 0.001, "Seam still Gain 1")
        let overlapStudio = CGRect(x: 1424, y: 0, width: 2560, height: 1440)
        ok(
            (GestureMath.destEdgeNearest(CGPoint(x: 1436, y: 200), screens: [laptop, overlapStudio])?.screen.width ?? 0) > 2000,
            "Überlapp 1436 innerster 5K"
        )
        ok(
            !GestureMath.destEdgeCrosses(
                from: CGPoint(x: 1436, y: 200),
                to: CGPoint(x: 1438, y: 200),
                screens: [laptop, overlapStudio]
            ),
            "Überlapp bleibt 5K — first-contains wäre Laptop tot"
        )
        ok(
            GestureMath.destEdgeCrosses(
                from: CGPoint(x: 1436, y: 200),
                to: CGPoint(x: 720, y: 200),
                screens: [laptop, overlapStudio]
            ),
            "Überlapp 5K → Laptop-Mitte = Cross"
        )
        let holdOn = GestureMath.destEdgeSkipNow(crosses: true, now: 10, lastAt: nil)
        ok(holdOn.skip && abs((holdOn.lastAt ?? 0) - 10) < 0.001, "Cross setzt Hold")
        ok(GestureMath.destEdgeSkipNow(crosses: false, now: 10.10, lastAt: holdOn.lastAt).skip, "160 ms Hold hält")
        ok(!GestureMath.destEdgeSkipNow(crosses: false, now: 10.20, lastAt: holdOn.lastAt).skip, "Hold abgelaufen")
        ok(GestureMath.destEdgeSkipNow(crosses: false, now: 10.05, lastAt: holdOn.lastAt, hold: 0.08).skip, "Pref 80 ms hält")
        ok(!GestureMath.destEdgeSkipNow(crosses: false, now: 10.12, lastAt: holdOn.lastAt, hold: 0.08).skip, "Pref 80 ms tot")
        ok(GestureMath.destEdgeSkipHold(pref: 0.08, frameDt: 0.125) >= 0.15, "8 fps Hold ≥ 1,25 Tick")
        ok(abs(GestureMath.destEdgeSkipHold() - 0.16) < 0.001, "Default 160 ms")
        ok(GestureMath.screenBlendSkipsCross(true), "Cross kein Blend")
        ok(!GestureMath.screenBlendSkipsCross(false), "ohne Cross Blend")
        ok(GestureMath.pointerPredictSkipsCross(true), "Cross kein Predict")
        ok(GestureMath.destEdgeTowardOf(2) == 0, "toward 2 px tot")
        ok(GestureMath.destEdgeTowardOf(4) == 0, "toward Dead 4 px tot")
        ok(GestureMath.destEdgeTowardOf(5) == 5, "toward 5 px live")
        ok(GestureMath.destEdgeTowardOf(1) == 0, "ChipOf toward ±1 nearer-edge")
        ok(GestureMath.destEdgeTowardOf(40) == 40, "toward 40 px live")
        ok(GestureMath.destEdgeSkipHold(pref: 0.08, frameDt: 0.20) <= 0.24, "Hold Cap 240 ms")
        let ema = GestureMath.palmVelScreenEMA(prev: .zero, raw: CGPoint(x: 100, y: 0), dt: 0.125)
        ok(ema.x > 40 && ema.x < 55, "8 fps EMA α 0,45")
        let keyScreens: [(id: String, bounds: CGRect)] = [
            ("laptop", laptop),
            ("studio", overlapStudio)
        ]
        ok(GestureMath.screenKey(point: CGPoint(x: 1436, y: 200), screens: keyScreens) == "studio", "screenKey innerster 5K")
        let axisPad = GestureMath.destEdgeFillAxis(
            CGPoint(x: -400, y: 0),
            point: CGPoint(x: 8, y: 400),
            screen: laptop,
            frameDt: 0.016,
            pad: 80
        )
        let axisFloor = GestureMath.destEdgeFillAxis(
            CGPoint(x: -400, y: 0),
            point: CGPoint(x: 8, y: 400),
            screen: laptop,
            frameDt: 0.016,
            pad: 40
        )
        ok(axisPad.x > axisFloor.x, "FillAxis pad dämpft Void")
        let cropROI = CGRect(x: 0.50, y: 0.05, width: 0.45, height: 0.50)
        let cropWrist = CGPoint(x: 0.08, y: 0.12)
        let cropTip = CGPoint(x: 0.55, y: 0.92)
        let cropThumb = CGPoint(x: 0.78, y: 0.48)
        ok(GestureMath.visionROIMap(roi: cropROI, sample: [cropWrist, cropTip, cropThumb]) != nil, "Crop-Punkte mappen")
        let mappedWrist = GestureMath.visionPointFromROI(cropWrist, roi: cropROI)
        ok(abs(mappedWrist.x - 0.536) < 0.001 && abs(mappedWrist.y - 0.110) < 0.001, "Wrist ROI → unten rechts")
        let mappedTip = GestureMath.visionPointFromROI(cropTip, roi: cropROI)
        ok(mappedTip.x > 0.70 && mappedTip.x < 0.80 && mappedTip.y > 0.45 && mappedTip.y < 0.55, "Tip bleibt in der ROI")
        let imgPts = [CGPoint(x: 0.52, y: 0.10), CGPoint(x: 0.88, y: 0.48)]
        ok(GestureMath.visionROIMap(roi: cropROI, sample: imgPts) == nil, "Bild-Punkte nicht doppelt mappen")
        ok(GestureMath.visionPointFromROI(cropWrist, roi: GestureMath.palmROIFull()) == cropWrist, "Full-ROI Identität")
        ok(!GestureMath.visionROIIsFull(cropROI), "Crop ist nicht Full")
        ok(GestureMath.visionROIIsFull(GestureMath.palmROIFull()), "palmROIFull ist Full")
        ok(!GestureMath.palmVisionUsesROI(), "ROI aus — Vollbild wie 1.5.66/1.6")
        ok(
            GestureMath.visionROIPointsNeedMap(minX: 0.08, maxX: 0.78, minY: 0.12, maxY: 0.92, roi: cropROI),
            "gestrecktes Overlay braucht Map"
        )
        ok(
            !GestureMath.visionROIPointsNeedMap(minX: 0.52, maxX: 0.88, minY: 0.10, maxY: 0.48, roi: cropROI),
            "Hand in der ROI schon Bild"
        )
        let guitar = [
            CGPoint(x: 0.06, y: 0.08), CGPoint(x: 0.94, y: 0.12),
            CGPoint(x: 0.10, y: 0.88), CGPoint(x: 0.90, y: 0.86),
            CGPoint(x: 0.48, y: 0.50)
        ]
        let guitarSpan = GestureMath.obsJointSpan(guitar)
        ok(guitarSpan.w > 0.80 && guitarSpan.h > 0.70, "Gitarre spannt Preview")
        ok(
            !GestureMath.obsLooksLikeHand(spanW: guitarSpan.w, spanH: guitarSpan.h, palmScale: 0.52, jointCount: 21),
            "Gitarre keine Hand"
        )
        let palmSpan = GestureMath.obsJointSpan([
            CGPoint(x: 0.62, y: 0.10), CGPoint(x: 0.70, y: 0.12),
            CGPoint(x: 0.78, y: 0.18), CGPoint(x: 0.68, y: 0.28),
            CGPoint(x: 0.64, y: 0.22)
        ])
        ok(
            GestureMath.obsLooksLikeHand(spanW: palmSpan.w, spanH: palmSpan.h, palmScale: 0.14, jointCount: 16),
            "echte Hand kompakt"
        )
        ok(
            !GestureMath.obsLooksLikeHand(
                spanW: 0.55, spanH: 0.50, palmScale: 0.18, jointCount: 16, chainOk: false
            ),
            "großer Blob ohne Kette tot"
        )
        ok(
            !GestureMath.obsLooksLikeHand(spanW: 0.30, spanH: 0.30, palmScale: 0.29, jointCount: 16),
            "Gitarre 0,29 keep tot"
        )
        ok(
            GestureMath.obsLooksLikeHand(spanW: 0.30, spanH: 0.30, palmScale: 0.29, jointCount: 16, keep: true),
            "Keep 0,29 Hand"
        )
        ok(
            GestureMath.obsLooksLikeHand(spanW: 0.20, spanH: 0.20, palmScale: 0.14, jointCount: 5, sparse: true),
            "Sparse 8 fps Hand"
        )
        ok(
            !GestureMath.obsLooksLikeHand(spanW: 0.20, spanH: 0.20, palmScale: 0.14, jointCount: 4),
            "4 Gelenke tot"
        )
        ok(
            GestureMath.obsSmoothResets(
                prevPalm: CGPoint(x: 0.48, y: 0.50),
                nextPalm: CGPoint(x: 0.68, y: 0.18),
                hadPrev: true
            ),
            "Sprung Gitarre→Hand setzt Smoother zurück"
        )
        ok(
            !GestureMath.obsSmoothResets(
                prevPalm: CGPoint(x: 0.48, y: 0.50),
                nextPalm: CGPoint(x: 0.64, y: 0.34),
                hadPrev: true
            ),
            "Flick 0,22 setzt Smoother nicht"
        )
        ok(GestureMath.obsHandCountCap() == 4, "HandCount 4")
        ok(GestureMath.obsHandCountCap(2) == 2, "HandCount Floor 2")
        ok(GestureMath.obsHandCountCap(9) == 8, "HandCount Cap 8")
        ok(
            GestureMath.obsLooksLikeHand(
                spanW: 0.16, spanH: 0.18, palmScale: 0.14, jointCount: 16, chainOk: false
            ),
            "Faust ohne Fingerkette hält"
        )
        ok(
            GestureMath.obsLooksLikeHand(
                spanW: 0.16, spanH: 0.18, palmScale: 0.14, jointCount: 5, sparse: true, chainOk: false
            ),
            "Sparse ohne Kette hält"
        )
        let chainWrist = CGPoint(x: 0.50, y: 0.20)
        ok(
            GestureMath.obsFingerChainOk(
                wrist: chainWrist,
                mcps: [
                    CGPoint(x: 0.46, y: 0.34),
                    CGPoint(x: 0.50, y: 0.34),
                    CGPoint(x: 0.54, y: 0.34),
                    CGPoint(x: 0.58, y: 0.34)
                ],
                tips: [
                    CGPoint(x: 0.44, y: 0.52),
                    CGPoint(x: 0.50, y: 0.54),
                    CGPoint(x: 0.56, y: 0.52),
                    CGPoint(x: 0.60, y: 0.50)
                ]
            ),
            "Hand Fingerkette"
        )
        ok(
            !GestureMath.obsFingerChainOk(
                wrist: chainWrist,
                mcps: [
                    CGPoint(x: 0.20, y: 0.50),
                    CGPoint(x: 0.50, y: 0.80),
                    CGPoint(x: 0.80, y: 0.50)
                ],
                tips: [
                    CGPoint(x: 0.22, y: 0.48),
                    CGPoint(x: 0.50, y: 0.70),
                    CGPoint(x: 0.78, y: 0.48)
                ]
            ),
            "Gitarre keine Fingerkette"
        )
        ok(GestureMath.obsScaleMarksProp(0.14) > GestureMath.palmHandScaleMax, "Prop-Scale > 0,28")
        let overlapLap = CGRect(x: 0, y: 0, width: 1456, height: 900)
        let overlapStudio = CGRect(x: 1440, y: 0, width: 2560, height: 1440)
        let overlapHit = GestureMath.destEdgeNearest(CGPoint(x: 1448, y: 200), screens: [overlapLap, overlapStudio])
        ok(overlapHit?.screen == overlapStudio, "16 px Overlap: 5K nicht Laptop")
        ok(
            abs(GestureMath.destEdgePadAt(
                point: CGPoint(x: 1448, y: 200),
                screens: [overlapLap, overlapStudio],
                pref: 24
            ) - 64) < 0.001,
            "Overlap Pad 5K 64"
        )
        let voidHold = GestureMath.screenSeamHolds(
            point: CGPoint(x: -10, y: 200),
            last: overlapLap,
            screens: [overlapLap]
        )
        ok(voidHold, "Void-Naht hält Laptop")
        let fatLap = CGRect(x: 0, y: 0, width: 1480, height: 900)
        let fatStudio = CGRect(x: 1440, y: 0, width: 2560, height: 1440)
        let fatHit = GestureMath.destEdgeNearest(CGPoint(x: 1444, y: 200), screens: [fatLap, fatStudio])
        ok(fatHit?.screen == fatStudio, "40 px Overlap: 4 px auf 5K nicht Laptop-Pad")
        ok(
            abs(GestureMath.destEdgePadAt(
                point: CGPoint(x: 1444, y: 200),
                screens: [fatLap, fatStudio],
                pref: 24
            ) - 64) < 0.001,
            "40 px Overlap Pad 5K 64"
        )
        ok(GestureMath.slotAllocMinID(0.12) == 1, "Hand mintet S1")
        ok(GestureMath.slotAllocMinID(0.42) == 2, "Prop mintet S2")
        ok(GestureMath.slotBindSkipsProp(slotID: 1, scale: 0.42), "Prop stiehlt S1 nicht")
        ok(!GestureMath.slotBindSkipsProp(slotID: 1, scale: 0.12), "Hand darf S1")
        ok(!GestureMath.slotBindSkipsProp(slotID: 2, scale: 0.42), "Prop darf S2")
        ok(GestureMath.pointerKeepPrefersHand(["S2", "S1"]) == "S1", "Pool S1 vor Observation-first")
        ok(GestureMath.pointerKeepInPool(keepID: nil, poolIDs: ["S2", "S1"]) == "S1", "ohne Keep S1")
        ok(GestureMath.pointerKeepInPool(keepID: "S2", poolIDs: ["S2", "S1"]) == "S2", "Keep bleibt")
        let holdScr = GestureMath.destEdgeScreenHolds(holding: true, hold: fatStudio)
        ok(holdScr == fatStudio, "Cross-Hold hält 5K")
        ok(GestureMath.destEdgeScreenHolds(holding: false, hold: fatStudio) == nil, "ohne Hold nearest")
        ok(
            GestureMath.destEdgeScreenAt(
                point: CGPoint(x: 720, y: 200),
                screens: [fatLap, fatStudio],
                steal: nil,
                map: nil,
                main: nil,
                hold: fatStudio,
                holding: true
            ) == fatStudio,
            "ScreenAt Hold nach Cross 5K"
        )
        ok(!GestureMath.palmScaleIsHand(0.29), "0,29 hart Prop")
        ok(GestureMath.palmScaleIsHand(0.29, keep: true), "0,29 Keep Hand")
        ok(!GestureMath.palmScaleIsHand(0.32, keep: true), "0,32 Keep tot")
        ok(GestureMath.slotAllocMinID(0.29) == 2, "neu 0,29 Prop S2")
        ok(GestureMath.slotAllocMinID(0.29, keep: true) == 1, "Keep 0,29 mintet S1")
        ok(GestureMath.slotAllocMinID(0.42) == 2, "0,42 Prop bleibt S2")
        ok(!GestureMath.slotBindSkipsProp(slotID: 1, scale: 0.29), "Keep-Hand darf S1")
        ok(abs(GestureMath.destEdgeSkipPref(0.02) - 0.04) < 0.001, "Skip Pref Floor 40 ms")
        ok(abs(GestureMath.destEdgeSkipPref(0.40) - 0.24) < 0.001, "Skip Pref Cap 240 ms")
        let seedScreens = [(id: "1", bounds: laptopSeam), (id: "2", bounds: extSeam)]
        ok(GestureMath.screenKeySeed(point: CGPoint(x: 2000, y: 200), screens: seedScreens, current: nil) == "2", "Seed Relativ 5K")
        ok(GestureMath.screenKeySeed(point: CGPoint(x: 2000, y: 200), screens: seedScreens, current: "1") == "2", "Seed folgt 5K")
        ok(GestureMath.screenKeySeed(point: CGPoint(x: 200, y: 200), screens: seedScreens, current: "2") == "1", "Seed folgt Laptop")
        ok(GestureMath.screenKeySeed(point: CGPoint(x: 200, y: 200), screens: seedScreens, current: nil) == "1", "Seed Relativ Laptop")
        let seamPt = CGPoint(x: 1448, y: 200)
        ok(GestureMath.screenKeySeed(point: seamPt, screens: seedScreens, current: "1") == "1", "Seam hält current")
        let overlapScreens = [(id: "1", bounds: overlapLap), (id: "2", bounds: CGRect(x: 1440, y: 0, width: 2560, height: 1440))]
        ok(abs(GestureMath.destEdgeOverlapGap(screens: overlapScreens.map(\.bounds)) - 16) < 1, "Overlap auto 16 px")
        ok(GestureMath.fistClickDebounce(frames: 1) == false, "Faust 1 Frame tot")
        ok(GestureMath.fistClickDebounce(frames: 2), "Faust 2 Frames Klick")
        let warp = CGPoint(x: 100, y: 100)
        let truth = CGPoint(x: 120, y: 100)
        ok(GestureMath.pointerReanchor(warped: warp, truth: truth, rms: 8) == truth, "Reanchor RMS > 8")
        ok(GestureMath.pointerReanchor(warped: warp, truth: CGPoint(x: 104, y: 100), rms: 8) == nil, "Reanchor unter RMS tot")
        ok(abs(GestureMath.deadManFistPref(1.0) - 1.6) < 0.001, "Dead-Man Floor 1,6")
        ok(abs(GestureMath.deadManFistPref(9) - 8) < 0.001, "Dead-Man Cap 8")
        ok(GestureMath.deadManFistIdle(lastFist: 1, lastHand: 1, now: 4, need: 2.5), "Dead-Man Pref 2,5")
        ok(!GestureMath.deadManFistIdle(lastFist: 1, lastHand: 1, now: 3, need: 2.5), "Dead-Man Pref frisch")
        ok(abs(GestureMath.flingWindowPref(0.05) - GestureMath.flingWindow) < 0.001, "Fling Floor")
        ok(abs(GestureMath.flingWindowPref(0.80) - 0.55) < 0.001, "Fling Cap 0,55")
        ok(GestureMath.swipeEligible(isOpenPalm: false, isPeace: false, openScore: 3), "3 Finger ohne Pref wischt")
        ok(!GestureMath.swipeEligible(isOpenPalm: false, isPeace: false, openScore: 3, openOnly: true), "openOnly tot ohne Palma")
        ok(GestureMath.swipeEligible(isOpenPalm: true, isPeace: false, openScore: 4, openOnly: true), "openOnly Palma wischt")
        ok(
            !GestureMath.destClampMapHolds(mapScreenID: "1", currentScreenID: nil, dest: overlapLap, screenCount: 2),
            "leeres currentScreenID bei 2 Screens tot"
        )
        ok(
            GestureMath.destClampMapHolds(mapScreenID: "1", currentScreenID: nil, dest: overlapLap, screenCount: 1),
            "leeres currentScreenID bei 1 Screen hält"
        )
        let staleMap = GestureMath.destClampScreen(
            point: CGPoint(x: 2000, y: 200),
            mapBounds: laptopSeam,
            screens: [laptopSeam, extSeam],
            mapScreenID: "1",
            currentScreenID: nil
        )
        ok(staleMap == extSeam, "leeres currentScreenID: 5K nicht Laptop-Map")
        let matchCross = GestureMath.destClampScreen(
            point: CGPoint(x: 2000, y: 200),
            mapBounds: laptopSeam,
            screens: [laptopSeam, extSeam],
            mapScreenID: "1",
            currentScreenID: "1"
        )
        ok(matchCross == extSeam, "Map-ID match aber Punkt auf 5K")
        let matchStay = GestureMath.destClampScreen(
            point: CGPoint(x: 200, y: 200),
            mapBounds: laptopSeam,
            screens: [laptopSeam, extSeam],
            mapScreenID: "1",
            currentScreenID: "1"
        )
        ok(matchStay == laptopSeam, "Map-ID match + Punkt auf Map")
        let seamWall = GestureMath.destClampScreen(
            point: CGPoint(x: 2000, y: 200),
            mapBounds: laptopSeam,
            screens: [laptopSeam, extSeam],
            lastScreen: laptopSeam,
            mapScreenID: "1",
            currentScreenID: "1"
        )
        ok(seamWall == extSeam, "Map+Seam keine Laptop-Mauer")
        ok(GestureMath.displayLinkUsesCA(), "CADisplayLink")
        ok(abs(GestureMath.displayLinkPreferredHz() - 120) < 0.1, "Fill 120 Hz")
        let k0 = GestureMath.palmScaleKalman(prev: 0.27, live: 0.31)
        ok(k0 < 0.31 && k0 > 0.27, "Kalman 0,31 bleibt unter Prop")
        ok(GestureMath.palmScaleIsHand(k0, keep: true), "Kalman Keep Hand")
        let kProp = GestureMath.palmScaleKalman(prev: 0.30, live: 0.42)
        ok(kProp > 0.30 && kProp < 0.42, "Kalman Gitarre kriecht")
        ok(GestureMath.pointerKeepPerHand(keepIDs: ["S1", "S2"], poolIDs: ["S2", "S1"]) == "S1", "Keep S1 vor S2")
        ok(GestureMath.pointerKeepPerHand(keepIDs: ["S2"], poolIDs: ["S2", "S3"]) == "S2", "Keep S2 bleibt")
        ok(GestureMath.pointerKeepPerHand(keepIDs: ["S9"], poolIDs: ["S1", "S2"]) == "S1", "tote Keep → Hand")
        let lerped = GestureMath.overlayPalmLerp(prev: .zero, next: CGPoint(x: 10, y: 0), t: 0.5)
        ok(abs(lerped.x - 5) < 0.01, "Overlay Lerp 0,5")
        ok(abs(GestureMath.overlayLerpT(elapsed: 0.06, frameDt: 0.12) - 0.5) < 0.01, "LerpT 8 fps")
        ok(GestureMath.pinchClickVsDrag(moved: 3) == "click", "Pinch still Click")
        ok(GestureMath.pinchClickVsDrag(moved: 20) == "drag", "Pinch 20 px Drag")
        ok(GestureMath.pinchClickVsDrag(moved: 9) == nil, "Pinch Band tot")
        ok(abs(GestureMath.fillCapPref(width: 1440) - 12) < 0.1, "Fill-Cap Laptop 12")
        ok(abs(GestureMath.fillCapPref(width: 5120) - 28) < 0.1, "Fill-Cap 5K 28")
        let padMap = GestureMath.destEdgePadMapPut(id: "5k", pad: 64, onto: [:])
        ok(abs(GestureMath.destEdgePadByUUID(id: "5k", width: 1440, stored: padMap, floor: 24) - 64) < 0.1, "Pad UUID 5K")
        ok(abs(GestureMath.destEdgePadByUUID(id: "lap", width: 1440, stored: padMap, floor: 24) - GestureMath.destEdgePadLive(width: 1440, pref: 24)) < 0.1, "Pad UUID miss → width")
        let arrA = GestureMath.screenArrangementHash([(id: "1", bounds: laptopSeam), (id: "2", bounds: extSeam)])
        let arrB = GestureMath.screenArrangementHash([(id: "1", bounds: laptopSeam)])
        ok(GestureMath.screenArrangementChanged(prev: arrA, next: arrB), "Arrangement Clamshell")
        ok(!GestureMath.screenArrangementChanged(prev: "", next: arrA), "erster Hash kein Change")
        ok(!GestureMath.screenArrangementChanged(prev: arrA, next: arrA), "Arrangement gleich tot")
        ok(!GestureMath.slotKeepBit(id: 1, scale: 0.29), "Keep-Bit neu Prop")
        ok(GestureMath.slotKeepBit(id: 1, scale: 0.29, prev: [1: true]), "Keep-Bit Hyst 0,29")
        ok(GestureMath.slotKeepBit(id: 1, scale: 0.12), "Keep-Bit Hand")
        ok(!GestureMath.slotKeepBit(id: 1, scale: 0.42), "Keep-Bit Gitarre")
        ok(GestureMath.slotBindSkipsProp(slotID: 1, scale: 0.29, prev: [1: false]), "Gitarre 0,29 stiehlt S1 nicht")
        ok(!GestureMath.slotBindSkipsProp(slotID: 1, scale: 0.29, prev: [1: true]), "Keep 0,29 bleibt S1")
        ok(!GestureMath.slotBindSkipsProp(slotID: 1, scale: 0.12, prev: [1: false]), "Hand 0,12 darf S1")
        ok(abs(GestureMath.fillCapLaptopPref(4) - 8) < 0.01, "Fill Laptop Floor 8")
        ok(abs(GestureMath.fillCapLaptopPref(40) - 24) < 0.01, "Fill Laptop Cap 24")
        ok(abs(GestureMath.fillCapStudioPref(8) - 12) < 0.01, "Fill Studio Floor 12")
        ok(abs(GestureMath.fillCapStudioPref(80) - 48) < 0.01, "Fill Studio Cap 48")
        ok(abs(GestureMath.fillCapPrefOf(width: 1440, laptop: 16, studio: 40) - 16) < 0.1, "Fill Pref Laptop")
        ok(abs(GestureMath.fillCapPrefOf(width: 5120, laptop: 16, studio: 40) - 40) < 0.1, "Fill Pref 5K")
        ok(abs(GestureMath.fillCapPrefOf(width: 1440, laptop: 4, studio: 8) - 8) < 0.1, "Fill Pref Floor Laptop")
        ok(abs(GestureMath.fillCapPrefOf(width: 5120, laptop: 4, studio: 8) - 12) < 0.1, "Fill Pref Floor 5K")
        ok(GestureMath.slotScaleJumpVeto(prev: 0.12, live: 0.29), "Jump 0,12→0,29")
        ok(!GestureMath.slotScaleJumpVeto(prev: 0.12, live: 0.14), "Jump 0,02 tot")
        ok(!GestureMath.slotKeepBit(id: 1, scale: 0.29, prev: [1: true], prevScale: [1: 0.12]), "Jump Veto kein Keep")
        ok(GestureMath.slotBindSkipsProp(slotID: 1, scale: 0.29, prev: [1: true], prevScale: [1: 0.12]), "Jump Veto Gitarre stiehlt S1 nicht")
        let capMap = GestureMath.fillCapMapPut(id: "lap", cap: 16, width: 1440, onto: [:])
        ok(abs(GestureMath.fillCapByUUID(id: "lap", width: 1440, stored: capMap, laptop: 12, studio: 28) - 16) < 0.1, "Fill UUID Laptop")
        ok(abs(GestureMath.fillCapByUUID(id: "5k", width: 5120, stored: capMap, laptop: 12, studio: 28) - 28) < 0.1, "Fill UUID miss → Studio")
        let capStudio = GestureMath.fillCapMapPut(id: "5k", cap: 40, width: 5120, onto: capMap)
        ok(abs(GestureMath.fillCapByUUID(id: "5k", width: 5120, stored: capStudio, laptop: 12, studio: 28) - 40) < 0.1, "Fill UUID 5K")
        ok(GestureMath.destEdgePadScreenName(id: "1", names: [(id: "1", name: "Built-in")]) == "Built-in", "Pad Name UUID")
        ok(GestureMath.destEdgePadScreenName(id: "", names: []) == "—", "Pad Name leer")
        ok(abs(GestureMath.displayLinkHzOf(fps: 60) - 60) < 0.1, "Fill Studio 60")
        ok(abs(GestureMath.displayLinkHzOf(fps: 24) - 30) < 0.1, "Fill Floor 30")
        ok(abs(GestureMath.displayLinkPreferredHz(144) - 120) < 0.1, "Fill Cap 120")
        ok(GestureMath.palmCoastAdvance(prev: 0, hit: true) == 0, "Coast Hit reset")
        ok(GestureMath.palmCoastAdvance(prev: 0, hit: false) == 1, "Coast Miss +1")
        ok(GestureMath.palmCoastKeepsS1(miss: 1), "Coast Tick 1")
        ok(GestureMath.palmCoastKeepsS1(miss: 2), "Coast Tick 2")
        ok(!GestureMath.palmCoastKeepsS1(miss: 0), "Coast Hit tot")
        ok(!GestureMath.palmCoastKeepsS1(miss: 3), "Coast Tick 3 tot")
        ok(GestureMath.palmCoastNeedPref(0) == 1, "Coast Pref Floor 1")
        ok(GestureMath.palmCoastNeedPref(9) == 4, "Coast Pref Cap 4")
        ok(GestureMath.palmCoastKeepsS1(miss: 3, need: 3), "Coast Pref 3 hält")
        ok(!GestureMath.palmCoastKeepsS1(miss: 4, need: 3), "Coast Pref 3 Tick 4 tot")
        let coastP = GestureMath.palmCoastPredict(palm: CGPoint(x: 0.40, y: 0.50), vel: CGPoint(x: 0.04, y: -0.02))
        ok(abs(coastP.x - 0.44) < 0.001, "Coast Predict X")
        ok(abs(coastP.y - 0.48) < 0.001, "Coast Predict Y")
        let coastCap = GestureMath.palmCoastPredict(palm: CGPoint(x: 0.50, y: 0.50), vel: CGPoint(x: 0.40, y: 0))
        ok(abs(coastCap.x - 0.58) < 0.001, "Coast Predict Cap")
        ok(GestureMath.warpWriterVisionSkips(linkArmed: true), "Warp Vision skip Link")
        ok(!GestureMath.warpWriterVisionSkips(linkArmed: false), "Warp Vision ohne Link")
        ok(GestureMath.warpWriterPressSkips(linkArmed: true), "Warp Press skip Link")
        ok(!GestureMath.warpWriterPressSkips(linkArmed: false), "Warp Press ohne Link")
        ok(GestureMath.displayTickFillsPress(pressed: true, dragging: false), "Fill Press")
        ok(GestureMath.displayTickFillsPress(pressed: false, dragging: false), "Fill Idle")
        ok(!GestureMath.displayTickFillsPress(pressed: true, dragging: true), "Fill Drag tot")
        ok(GestureMath.warpWriterChip(linkArmed: true) == "FILL", "Warp Chip FILL")
        ok(GestureMath.warpWriterChip(linkArmed: false) == "VISION", "Warp Chip VISION")
        ok(abs(GestureMath.overlayGhostAlpha(coast: true) - 0.50) < 0.001, "Ghost Coast 50")
        ok(abs(GestureMath.overlayGhostAlpha(coast: false) - 0.35) < 0.001, "Ghost Latch 35")
        ok(GestureMath.overlayGhostIsCoast(remaining: 0), "Ghost Coast remaining 0")
        ok(!GestureMath.overlayGhostIsCoast(remaining: 0.12), "Ghost Latch remaining")
        ok(GestureMath.warpWriterInjectSkips(linkArmed: true), "Warp Inject skip Link")
        ok(!GestureMath.warpWriterInjectSkips(linkArmed: false), "Warp Inject ohne Link")
        let coastHit = GestureMath.palmCoastVelOnHit(
            live: CGPoint(x: 0.50, y: 0.50),
            stored: CGPoint(x: 0.20, y: 0.20),
            wasCoast: true,
            lastVel: CGPoint(x: 0.04, y: 0)
        )
        ok(abs(coastHit.x - 0.04) < 0.001, "Coast Vel Return hält")
        let coastLive = GestureMath.palmCoastVelOnHit(
            live: CGPoint(x: 0.50, y: 0.50),
            stored: CGPoint(x: 0.40, y: 0.50),
            wasCoast: false,
            lastVel: CGPoint(x: 0.04, y: 0)
        )
        ok(abs(coastLive.x - 0.10) < 0.001, "Coast Vel Live delta")
        let coastD = GestureMath.palmCoastDelta(from: CGPoint(x: 0.40, y: 0.50), to: CGPoint(x: 0.44, y: 0.48))
        ok(abs(coastD.x - 0.04) < 0.001, "Coast Delta X")
        let coastS = GestureMath.palmCoastShift(CGPoint(x: 0.10, y: 0.20), delta: CGPoint(x: 0.04, y: -0.02))
        ok(abs(coastS.x - 0.14) < 0.001 && abs(coastS.y - 0.18) < 0.001, "Coast Joint Shift")
        ok(GestureMath.palmCoastNeedAuto(dt: 0.25, pref: 2) == 3, "Coast Need Auto 4 fps")
        ok(GestureMath.palmCoastNeedAuto(dt: 0.12, pref: 2) == 2, "Coast Need Auto 8 fps Pref")
        ok(GestureMath.palmCoastNeedAuto(dt: 0.25, pref: 4) == 4, "Coast Need Auto Pref Cap")
        let decay0 = GestureMath.palmCoastVelDecay(vel: CGPoint(x: 0.10, y: 0), miss: 1)
        ok(abs(decay0.x - 0.10) < 0.001, "Coast Vel Miss 1 voll")
        let decay2 = GestureMath.palmCoastVelDecay(vel: CGPoint(x: 0.10, y: 0), miss: 2)
        ok(abs(decay2.x - 0.082) < 0.001, "Coast Vel Decay 0,82")
        let retCap = GestureMath.palmCoastReturnVel(
            live: CGPoint(x: 0.50, y: 0.50),
            stored: CGPoint(x: 0.20, y: 0.20),
            wasCoast: true,
            lastVel: CGPoint(x: 0.40, y: 0)
        )
        ok(abs(retCap.x - 0.08) < 0.001, "Coast Return Cap 0,08")
        ok(GestureMath.warpWriter(linkArmed: true) == .fill, "WarpWriter FILL")
        ok(GestureMath.warpWriter(linkArmed: false) == .vision, "WarpWriter VISION")
        ok(GestureMath.warpWriterSkips(.fill), "WarpWriter skip FILL")
        ok(!GestureMath.warpWriterSkips(.vision), "WarpWriter VISION warpt")
        ok(GestureMath.warpWriterChip(linkArmed: true) == GestureMath.WarpWriter.fill.rawValue, "Chip Token FILL")
        ok(GestureMath.palmROIFreeze(keepHand: true, coast: false), "ROI Freeze Keep")
        ok(GestureMath.palmROIFreeze(keepHand: false, coast: true), "ROI Freeze Coast")
        ok(!GestureMath.palmROIFreeze(keepHand: true, coast: true, secondHand: true), "ROI Freeze Second tot")
        let frozen = CGRect(x: 0.20, y: 0.20, width: 0.30, height: 0.30)
        let walked = CGRect(x: 0.60, y: 0.10, width: 0.30, height: 0.30)
        let held = GestureMath.palmROILocked(live: walked, frozen: frozen, freeze: true)
        ok(held == frozen, "ROI Locked Freeze")
        ok(GestureMath.palmROILocked(live: walked, frozen: frozen, freeze: false) == walked, "ROI Locked Live")
        ok(GestureMath.palmCoastEmptyKeeps(miss: 1, need: 2), "Empty Coast Tick 1")
        ok(!GestureMath.palmCoastEmptyKeeps(miss: 0, need: 2), "Empty Coast Hit tot")
        ok(!GestureMath.palmCoastEmptyKeeps(miss: 3, need: 2), "Empty Coast Tick 3 tot")
        ok(!GestureMath.palmROIMissFullNext(dt: 0.04, expanded: true), "ROI FullNext 24 fps tot")
        ok(GestureMath.palmROIMissFullNext(dt: 0.12, expanded: true), "ROI FullNext 8 fps")
        ok(!GestureMath.palmROIMissFullNext(dt: 0.12, expanded: false), "ROI FullNext ohne Expand tot")
        ok(!GestureMath.displayLinkPulseAlive(lastPulse: 0, now: 1), "Pulse 0 tot")
        ok(GestureMath.displayLinkPulseAlive(lastPulse: 1.00, now: 1.04), "Pulse 40 ms lebt")
        ok(!GestureMath.displayLinkPulseAlive(lastPulse: 1.00, now: 1.12), "Pulse 120 ms tot")
        ok(GestureMath.displayLinkPulseStale(false), "Pulse Stale")
        let kHand = GestureMath.palmScaleKalman(prev: 0.27, live: 0.40)
        ok(kHand < GestureMath.palmHandScaleMax, "Kalman Hand nicht Prop")
        ok(GestureMath.palmScaleIsHand(kHand, keep: false), "Kalman Clamp unter 0,28")
        ok(GestureMath.warpWriter(linkArmed: GestureMath.displayLinkPulseAlive(lastPulse: 0, now: 1)) == .vision, "Pulse tot VISION")
        ok(GestureMath.warpWriter(linkArmed: GestureMath.displayLinkPulseAlive(lastPulse: 1, now: 1.02)) == .fill, "Pulse lebt FILL")
        ok(GestureMath.palmROIThawHit(didFull: true, hit: true), "Thaw Full Hit")
        ok(!GestureMath.palmROIThawHit(didFull: true, hit: false), "Thaw Full Miss tot")
        ok(!GestureMath.palmROIThawHit(didFull: false, hit: true), "Thaw ohne Full tot")
        ok(GestureMath.palmROIThawHit(didFull: false, hit: true, sameTickFull: true), "Thaw Same-Tick Full")
        ok(GestureMath.palmROIThawHit(didFull: false, hit: true, expandHit: true), "Thaw Expand Hit")
        ok(GestureMath.palmROIMissFullAfter(expandMiss: 2, dt: 0.04), "FullAfter 24 fps 2 Expand")
        ok(!GestureMath.palmROIMissFullAfter(expandMiss: 1, dt: 0.04), "FullAfter 1 tot")
        ok(GestureMath.palmROIMissExpandAdvance(prev: 1, expandedEmpty: true) == 2, "Expand Advance")
        ok(GestureMath.palmROIMissExpandAdvance(prev: 3, expandedEmpty: false) == 0, "Expand Hit reset")
        ok(GestureMath.palmROIIsFull(GestureMath.palmROIFull()), "ROI Full rect")
        let bindOrd = GestureMath.palmBindHandsFirst(scales: [0.42, 0.12, 0.29])
        ok(bindOrd.first == 1, "Bind Hands First S1")
        ok(bindOrd.last == 0, "Bind Prop last")
        ok(GestureMath.palmROICoastFollows(true, usesROI: true), "Coast ROI Follow Crop")
        ok(!GestureMath.palmROICoastFollows(true), "Coast ROI Follow tot — ROI aus")
        ok(!GestureMath.palmROICoastFollows(false), "Coast ROI Follow tot")
        let followed = GestureMath.palmROIFollow(palm: CGPoint(x: 0.40, y: 0.50), scale: 0.12)
        ok(followed != nil && followed!.contains(CGPoint(x: 0.40, y: 0.50)), "Coast ROI Follow rect")
        ok(!GestureMath.overlayLerpShould(dt: 0.12), "Lerp 8 fps tot")
        ok(!GestureMath.overlayLerpShould(dt: 0.04), "Lerp 24 fps tot")
        ok(!GestureMath.overlayLerpShould(dt: 0.008), "Lerp 120 fps tot")
        ok(abs(GestureMath.overlayBezierEase(0.5) - 0.5) < 0.01, "Bezier mid")
        ok(GestureMath.overlayBezierEase(0.25) > 0.10 && GestureMath.overlayBezierEase(0.25) < 0.25, "Bezier ease in")
        let bez = GestureMath.overlayBezier(prev: .zero, next: CGPoint(x: 10, y: 0), t: 0.5)
        ok(abs(bez.x - 5) < 0.01, "Bezier 0,5")
        let ovFrom = [(id: "S1", palm: CGPoint(x: 0.20, y: 0.40))]
        let ovTo = [(id: "S1", palm: CGPoint(x: 0.40, y: 0.40))]
        let ovMid = GestureMath.overlayLerpHands(from: ovFrom, to: ovTo, t: 0.5)
        ok(ovMid.count == 1 && abs(ovMid[0].palm.x - 0.30) < 0.01, "Overlay Hands Lerp")
        let ovSnap = GestureMath.overlayLerpHands(from: ovFrom, to: ovTo, t: 0)
        ok(abs(ovSnap[0].palm.x - 0.20) < 0.01, "Overlay Hands t=0")
        let wrist = CGPoint(x: 0.50, y: 0.20)
        let mcpMed = GestureMath.palmScaleWristMCP(
            wrist: wrist,
            mcps: [
                CGPoint(x: 0.46, y: 0.34),
                CGPoint(x: 0.50, y: 0.34),
                CGPoint(x: 0.54, y: 0.34),
                CGPoint(x: 0.58, y: 0.34)
            ]
        )
        ok(mcpMed != nil && mcpMed! > 0.13 && mcpMed! < 0.17, "Wrist-MCP Median")
        ok(GestureMath.palmScaleWristMCP(wrist: nil, mcps: []) == nil, "Wrist-MCP leer")
        ok(GestureMath.palmScaleSpanVeto(wristMCP: 0.40, span: 0.12), "Span Veto Gitarre")
        ok(!GestureMath.palmScaleSpanVeto(wristMCP: 0.14, span: 0.12), "Span Veto Hand tot")
        ok(GestureMath.palmScaleSpanVeto(wristMCP: 0.10, span: 0.20), "Span Veto 2×")
        let med8 = GestureMath.palmScaleMedian([0.12, 0.13, 0.14, 0.40, 0.12, 0.13, 0.14, 0.15, 0.99])
        ok(med8 != nil && med8! < 0.20, "Scale Median 8 Cap")
        ok(GestureMath.palmScaleMedian([]) == nil, "Scale Median leer")
        let pose = GestureClassifier.palmScale([
            .wrist: wrist,
            .indexMCP: CGPoint(x: 0.46, y: 0.34),
            .middleMCP: CGPoint(x: 0.50, y: 0.34),
            .ringMCP: CGPoint(x: 0.54, y: 0.34),
            .littleMCP: CGPoint(x: 0.58, y: 0.34)
        ])
        ok(pose > 0.13 && pose < 0.17, "Classifier Wrist-MCP Median")
        let guitar = GestureClassifier.palmScale([
            .wrist: wrist,
            .indexMCP: CGPoint(x: 0.10, y: 0.20),
            .middleMCP: CGPoint(x: 0.50, y: 0.70),
            .ringMCP: CGPoint(x: 0.90, y: 0.20),
            .littleMCP: CGPoint(x: 0.95, y: 0.20)
        ])
        ok(guitar > GestureMath.palmHandScaleMax, "Classifier Gitarre Wrist-MCP Prop")
        ok(GestureMath.palmROIThawMiss(frozenMiss: 2), "Thaw 2 Frozen-Miss")
        ok(!GestureMath.palmROIThawMiss(frozenMiss: 1), "Thaw 1 Frozen-Miss tot")
        ok(GestureMath.palmScaleMedianKeeps(s1Live: true), "Scale Ring S1")
        ok(!GestureMath.palmScaleMedianKeeps(s1Live: false), "Scale Ring S2 tot")
        let ovVel = GestureMath.overlayVel(from: CGPoint(x: 0.20, y: 0.40), to: CGPoint(x: 0.40, y: 0.40))
        ok(abs(ovVel.x - 0.20) < 0.001, "Overlay Vel X")
        let ovEx = GestureMath.overlayExtrapolate(
            prev: CGPoint(x: 0.40, y: 0.40),
            vel: CGPoint(x: 0.20, y: 0),
            extra: 0.5
        )
        ok(abs(ovEx.x - 0.50) < 0.01, "Overlay Extrapolate 0,5")
        let ovCap = GestureMath.overlayExtrapolate(
            prev: CGPoint(x: 0.40, y: 0.40),
            vel: CGPoint(x: 0.40, y: 0),
            extra: 1
        )
        ok(abs(ovCap.x - 0.48) < 0.01, "Overlay Extrapolate Cap 0,08")
        let ovPast = GestureMath.overlayBezier(
            prev: CGPoint(x: 0.20, y: 0.40),
            next: CGPoint(x: 0.40, y: 0.40),
            t: 1.5,
            vel: CGPoint(x: 0.20, y: 0)
        )
        ok(abs(ovPast.x - 0.40) < 0.01, "Overlay Bezier t>1 snap")
        let ovT = GestureMath.overlayLerpT(elapsed: 0.18, frameDt: 0.12)
        ok(abs(ovT - 1) < 0.01, "LerpT clamp 1")
        let ovCoast = GestureMath.overlayLerpHands(from: ovFrom, to: ovTo, t: 1.5)
        ok(ovCoast.count == 1 && abs(ovCoast[0].palm.x - 0.40) < 0.01, "Overlay Hands kein Extrapolate")
        ok(GestureMath.palmROIThawProp(frozen: true, hit: true, handHit: false, usesROI: true), "Thaw Prop Gitarre")
        ok(!GestureMath.palmROIThawProp(frozen: true, hit: true, handHit: true, usesROI: true), "Thaw Prop Hand tot")
        ok(!GestureMath.palmROIThawProp(frozen: false, hit: true, handHit: false, usesROI: true), "Thaw Prop ohne Freeze tot")
        ok(!GestureMath.palmROIThawProp(frozen: true, hit: true, handHit: false), "Thaw Prop ROI aus tot")
        ok(GestureMath.palmROIFreezeTTL(frozenAt: 1.00, now: 1.40), "ROI Freeze TTL 400 ms")
        ok(!GestureMath.palmROIFreezeTTL(frozenAt: 1.00, now: 1.20), "ROI Freeze TTL 200 ms tot")
        ok(!GestureMath.palmROIFreezeTTL(frozenAt: 0, now: 2), "ROI Freeze TTL 0 tot")
        ok(abs(GestureMath.palmROIFreezeClock(frozen: false, prev: 1.0, now: 2.0)) < 1e-12, "Freeze Clock unfrozen 0")
        ok(abs(GestureMath.palmROIFreezeClock(frozen: true, prev: 0, now: 1.5) - 1.5) < 1e-12, "Freeze Clock stamp")
        ok(abs(GestureMath.palmROIFreezeClock(frozen: true, prev: 1.0, now: 1.5) - 1.0) < 1e-12, "Freeze Clock hält")
        let nearPalm = CGPoint(x: 0.40, y: 0.50)
        let farPalm = CGPoint(x: 0.10, y: 0.20)
        let bindLast = GestureMath.palmBindHandsFirst(
            scales: [0.25, 0.27],
            palms: [farPalm, nearPalm],
            last: nearPalm
        )
        ok(bindLast.first == 1, "Bind lastS1 nearer")
        ok(GestureMath.palmBindHandsFirst(scales: [0.42, 0.12, 0.29]).first == 1, "Bind Hands First Scale")
        let bindDense = GestureMath.palmBindHandsFirst(
            scales: [0.25, 0.27],
            palms: [farPalm, nearPalm],
            counts: [4, 16]
        )
        ok(bindDense.first == 1, "Bind denser Hand vor Gitarre")
        ok(GestureMath.palmBindHandsFirst(scales: [0.25, 0.27], counts: [4, 16]).first == 1, "Bind counts ohne last")
        ok(GestureMath.palmLateralityBlocksS2(s1Locked: 1, live: 1, slotID: 2), "S2 stiehlt S1 L")
        ok(!GestureMath.palmLateralityBlocksS2(s1Locked: 1, live: 2, slotID: 2), "S2 R frei")
        ok(!GestureMath.palmLateralityBlocksS2(s1Locked: 1, live: 1, slotID: 1), "S1 selbst tot")
        ok(GestureMath.pinchClickBlocksAfterCoast(lastCoastEnd: 1.00, now: 1.05), "Coast Click 50 ms tot")
        ok(GestureMath.pinchClickBlocksAfterCoast(lastCoastEnd: 1.00, now: 1.12), "Coast Click 120 ms tot")
        ok(!GestureMath.pinchClickBlocksAfterCoast(lastCoastEnd: 1.00, now: 1.25), "Coast Click 250 ms")
        ok(!GestureMath.pinchClickBlocksAfterCoast(lastCoastEnd: 0, now: 1), "Coast Click 0 tot")
        let vetoHand = GestureClassifier.palmScale([
            .wrist: CGPoint(x: 0.50, y: 0.20),
            .indexMCP: CGPoint(x: 0.36, y: 0.34),
            .middleMCP: CGPoint(x: 0.50, y: 0.34),
            .ringMCP: CGPoint(x: 0.54, y: 0.34),
            .littleMCP: CGPoint(x: 0.76, y: 0.34)
        ])
        ok(vetoHand > GestureMath.palmHandScaleMax, "Classifier Span-Veto markiert Prop")
        ok(
            !GestureMath.obsFingerChainOk(
                wrist: nil,
                mcps: [CGPoint(x: 0.20, y: 0.50), CGPoint(x: 0.80, y: 0.50)],
                tips: [CGPoint(x: 0.22, y: 0.48), CGPoint(x: 0.78, y: 0.48)]
            ),
            "ohne Wrist keine Kette"
        )
        ok(
            !GestureMath.obsFingerChainOk(
                wrist: CGPoint(x: 0.50, y: 0.20),
                mcps: [
                    CGPoint(x: 0.46, y: 0.34),
                    CGPoint(x: 0.50, y: 0.34),
                    CGPoint(x: 0.54, y: 0.34)
                ],
                tips: [CGPoint(x: 0.44, y: 0.52)]
            ),
            "ein Tip keine Kette"
        )
        ok(GestureMath.obsJointConfOk(wrist: 0.72, mcps: [0.68, 0.70, 0.66]), "Hand Conf")
        ok(GestureMath.obsJointConfOk(wrist: 0.28, mcps: [0.22, 0.24, 0.20]), "Faust Conf hält")
        ok(!GestureMath.obsJointConfOk(wrist: 0.10, mcps: [0.08, 0.09, 0.07]), "Blur Conf tot")
        ok(GestureMath.obsJointConfOk(wrist: 0.28, mcps: [0.22], sparse: true), "Sparse Conf 0,22")
        ok(!GestureMath.obsJointConfOk(wrist: 0.10, mcps: [0.12], sparse: true), "Sparse Conf tot")
        ok(
            GestureMath.obsJointConfOk(
                wrist: 0.80, mcps: [0.70, 0.68, 0.66], tips: [0.10, 0.12, 0.08]
            ),
            "Faust Tips optional"
        )
        ok(
            GestureMath.obsJointConfOk(
                wrist: 0.72, mcps: [0.68, 0.70], tips: [0.60, 0.62, 0.58]
            ),
            "Hand Tips halten"
        )
        ok(GestureMath.obsSmoothChiralityHolds(prev: 1, live: 1), "L hält")
        ok(!GestureMath.obsSmoothChiralityHolds(prev: 1, live: 2), "L→R tot")
        ok(GestureMath.obsSmoothChiralityHolds(prev: 1, live: 0), "Unknown hält")
        ok(
            !GestureMath.obsSmoothResets(
                prevPalm: CGPoint(x: 0.48, y: 0.50),
                nextPalm: CGPoint(x: 0.88, y: 0.10),
                hadPrev: true,
                chiralityHolds: false
            ),
            "Chirality-Flip setzt Smoother nicht"
        )
        ok(
            !GestureMath.obsFingerChainPairs(
                wrist: CGPoint(x: 0.50, y: 0.20),
                mcps: [
                    CGPoint(x: 0.46, y: 0.34),
                    CGPoint(x: 0.50, y: 0.34),
                    CGPoint(x: 0.54, y: 0.34),
                    nil
                ],
                tips: [
                    CGPoint(x: 0.44, y: 0.52),
                    nil,
                    nil,
                    CGPoint(x: 0.60, y: 0.50)
                ]
            ),
            "Paare ohne Little-MCP — compactMap-Zip tot"
        )
        ok(
            GestureMath.obsFingerChainPairs(
                wrist: CGPoint(x: 0.50, y: 0.20),
                mcps: [
                    CGPoint(x: 0.46, y: 0.34),
                    CGPoint(x: 0.50, y: 0.34),
                    CGPoint(x: 0.54, y: 0.34),
                    nil
                ],
                tips: [
                    CGPoint(x: 0.44, y: 0.52),
                    CGPoint(x: 0.50, y: 0.54),
                    CGPoint(x: 0.56, y: 0.52),
                    CGPoint(x: 0.60, y: 0.50)
                ]
            ),
            "Paare halten ohne Little-MCP"
        )
        ok(!GestureMath.palmROIFrozenWrite(true), "Frozen Write ROI aus tot")
        ok(GestureMath.palmROIFrozenWrite(true, usesROI: true), "Frozen Write ROI an")
        ok(!GestureMath.palmROIFrozenWrite(false, usesROI: true), "Frozen Write ohne Freeze tot")
        ok(GestureMath.obsSmoothJumpOf(dt: 0.125) > 0.34, "Smooth 8 fps 0,35")
        ok(GestureMath.obsSmoothJumpOf(dt: 0.042) < 0.13, "Smooth 24 fps enger")
        ok(
            GestureMath.obsSmoothResets(
                prevPalm: CGPoint(x: 0.48, y: 0.50),
                nextPalm: CGPoint(x: 0.60, y: 0.42),
                hadPrev: true,
                dt: 0.042
            ),
            "24 fps 0,14 setzt"
        )
        ok(
            !GestureMath.obsSmoothResets(
                prevPalm: CGPoint(x: 0.48, y: 0.50),
                nextPalm: CGPoint(x: 0.60, y: 0.42),
                hadPrev: true,
                dt: 0.125
            ),
            "8 fps 0,14 hält One-Euro"
        )
        let spanAll = GestureMath.palmScaleSpanOf([
            CGPoint(x: 0.20, y: 0.34),
            CGPoint(x: 0.50, y: 0.34),
            CGPoint(x: 0.80, y: 0.34)
        ])
        ok(spanAll > 0.55, "Span max-Paar nicht nur Index-Klein")
        ok(abs(GestureMath.displayLinkHzOf(fpsList: [60, 120]) - 120) < 0.001, "DisplayLink max 120")
        ok(abs(GestureMath.displayLinkHzOf(fpsList: [60]) - 60) < 0.001, "DisplayLink Studio 60")
        ok(abs(GestureMath.displayLinkHzOf(fpsList: []) - 120) < 0.001, "DisplayLink leer 120")
        ok(GestureMath.displayLinkDebounce(last: 0, now: 0.005), "Debounce 5 ms feuert")
        ok(!GestureMath.displayLinkDebounce(last: 0, now: 0.002), "Debounce 2 ms tot")
        let laptop = CGRect(x: 0, y: 0, width: 1512, height: 982)
        let studio = CGRect(x: 1512, y: -800, width: 5120, height: 2880)
        ok(GestureMath.displayLinkScreenIndex(cursor: CGPoint(x: 200, y: 100), screens: [laptop, studio]) == 0, "Pulse Laptop")
        ok(GestureMath.displayLinkScreenIndex(cursor: CGPoint(x: 3000, y: -100), screens: [laptop, studio]) == 1, "Pulse Studio")
        ok(GestureMath.displayLinkIsDest(screenIndex: 1, cursor: CGPoint(x: 3000, y: -100), screens: [laptop, studio]), "Dest Studio")
        ok(!GestureMath.displayLinkIsDest(screenIndex: 0, cursor: CGPoint(x: 3000, y: -100), screens: [laptop, studio]), "Laptop-Pulse kein Studio-Warp")
        ok(GestureMath.displayLinkIsDest(screenIndex: nil, cursor: CGPoint(x: 200, y: 100), screens: [laptop, studio]), "ohne Index Dest")
        ok(
            GestureMath.displayLinkLayoutToken([(id: 2, hz: 60), (id: 1, hz: 120)])
                == GestureMath.displayLinkLayoutToken([(id: 1, hz: 120), (id: 2, hz: 60)]),
            "Layout Token sort"
        )
        ok(GestureMath.displayLinkLayoutChanged(prev: "1:120", next: "1:120|2:60"), "Layout 5K")
        ok(!GestureMath.displayLinkLayoutChanged(prev: "1:120", next: "1:120"), "Layout gleich tot")
        ok(GestureMath.visionRotationApplied(90) == false, "Rotation applied tot ohne physical")
        ok(GestureMath.visionOrientationLive(angle: 0, applied: false) == 1, "Live 0 up")
        ok(GestureMath.visionOrientationLive(angle: 90, applied: true) == 1, "Live applied up")
        ok(GestureMath.visionOrientationLive(angle: 90, applied: false) == 6, "Live 90 right")
        ok(GestureMath.visionOrientationLive(angle: 180, applied: false) == 3, "Live 180 down")
        ok(GestureMath.visionOrientationLive(angle: 270, applied: false) == 8, "Live 270 left")
        let wrist = CGPoint(x: 0.40, y: 0.20)
        let fanHand = GestureMath.palmMCPFanDeg(wrist: wrist, mcps: [
            CGPoint(x: 0.36, y: 0.34),
            CGPoint(x: 0.42, y: 0.36),
            CGPoint(x: 0.48, y: 0.35),
            CGPoint(x: 0.54, y: 0.32)
        ])
        ok(fanHand > 18, "Hand-Fächer > 18°")
        let fanGuitar = GestureMath.palmMCPFanDeg(wrist: wrist, mcps: [
            CGPoint(x: 0.42, y: 0.30),
            CGPoint(x: 0.44, y: 0.40),
            CGPoint(x: 0.46, y: 0.50),
            CGPoint(x: 0.48, y: 0.60)
        ])
        ok(fanGuitar < 18, "Gitarre-Hals < 18°")
        ok(GestureMath.palmMCPCollinearVeto(fan: fanGuitar), "Gitarre kollinear")
        ok(!GestureMath.palmMCPCollinearVeto(fan: fanHand), "Hand nicht kollinear")
        ok(
            GestureMath.obsLooksLikeHand(
                spanW: 0.20, spanH: 0.40, palmScale: 0.14, jointCount: 16, fanOk: false
            ),
            "Kante fanOk tot hält"
        )
        ok(
            GestureMath.obsLooksLikeHand(
                spanW: 0.20, spanH: 0.20, palmScale: 0.14, jointCount: 16, fanOk: true
            ),
            "fanOk Hand"
        )
        let ema = GestureMath.palmBindScaleOf(live: 0.29, last: 0.14, ticks: 8)
        ok(ema < 0.22 && ema > 0.14, "Bind-EMA dämpft Gitarre-Flicker")
        ok(GestureMath.palmBindScaleOf(live: 0.29, last: 0.14, ticks: 1) == 0.29, "Bind-EMA vor 3 Ticks tot")
        let lockLine = GestureMath.cameraMutexLine(owner: "helios", pid: 12, now: 1_000)
        ok(GestureMath.cameraMutexParse(lockLine, now: 1_001) == "helios", "Mutex Helios")
        ok(GestureMath.cameraMutexParse(lockLine, now: 1_010, stale: 3) == nil, "Mutex stale 3")
        ok(GestureMath.cameraMutexParse(lockLine, now: 1_011) == "helios", "Mutex 12 s hält")
        ok(GestureMath.cameraMutexParse(lockLine, now: 1_020) == nil, "Mutex stale 12")
        ok(GestureMath.cameraMutexYieldsContinuity(holder: "helios", owner: "aegis"), "Aegis weicht Helios")
        ok(!GestureMath.cameraMutexYieldsContinuity(holder: "aegis", owner: "helios"), "Helios weicht nicht")
        ok(GestureMath.cameraMutexPid(lockLine) == 12, "Mutex PID")
        ok(lockLine.contains("1000.000"), "Mutex Stamp ms")
        ok(GestureMath.cameraMutexParse(lockLine, now: 1_001, pidLive: false) == nil, "Mutex tot PID")
        ok(GestureMath.cameraMutexParse(lockLine, now: 1_001, pidLive: true) == "helios", "Mutex live PID")
        ok(GestureMath.cameraMutexPidDead(0), "PID 0 tot")
        ok(!GestureMath.cameraMutexPidDead(12), "PID 12 lebend")
        ok(GestureMath.cameraMutexClaimWrites(holder: "aegis", owner: "helios"), "Helios überschreibt Aegis")
        ok(!GestureMath.cameraMutexClaimWrites(holder: "helios", owner: "aegis"), "Aegis schreibt nicht über Helios")
        ok(GestureMath.cameraMutexClaimWrites(holder: nil, owner: "aegis"), "Aegis frei")
        ok(GestureMath.cameraMutexClaimWrites(holder: "aegis", owner: "aegis"), "Aegis Heartbeat selbst")
        ok(GestureMath.cameraMutexYieldsNow(holder: "helios", owner: "aegis", wasYielded: false), "Yield live")
        ok(GestureMath.cameraMutexYieldsNow(holder: nil, owner: "aegis", wasYielded: true), "Yield hält")
        ok(!GestureMath.cameraMutexYieldsNow(holder: nil, owner: "aegis", wasYielded: false), "Yield tot")
        ok(abs(GestureMath.cameraMutexHeartbeatSec() - 2) < 0.01, "Heartbeat 2 s")

        if fails > 0 {
            fputs("\(fails) GestureTests fehlgeschlagen\n", stderr)
            exit(1)
        }
        print("GestureTests OK")
    }
}

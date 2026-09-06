import CoreMedia
import CoreML
import CoreVideo
import Foundation
import ImageIO
import Vision

struct TrackedJoint {
    var point: CGPoint
    var confidence: Float
}

struct TrackedHand: Identifiable {
    var id: String
    var chirality: VNChirality
    var joints: [VNHumanHandPoseObservation.JointName: TrackedJoint]
    var displayJoints: [VNHumanHandPoseObservation.JointName: TrackedJoint]
    var pose: HandPose
    var pinchDistance: CGFloat
    var pinchRatio: CGFloat
    var pinchClosed: Bool
    var palm: CGPoint
    var openScore: Int
    var extended: Set<String>
    /// Leere Vision: letzte Pose, keine One-Shots.
    var isGhost: Bool = false
    var ghostRemaining: TimeInterval = 0
    /// Vision-3D: Spitzen minus Wrist, +Z zur Kamera. nil = 2D-PinchGate.
    var tipZ: Float? = nil
    /// DIP als Fake-Tip: Kalman freeze, nicht meanConfidence.
    var tipHeld: Bool = false
    /// Vision-Chirality vor Lock. HUD `L`/`R` wenn Lock hält.
    var lateralityLive: Int = 0

    func point(_ name: VNHumanHandPoseObservation.JointName) -> CGPoint? {
        guard let j = joints[name], j.confidence > 0.22 else { return nil }
        return j.point
    }

    func overlayPoint(_ name: VNHumanHandPoseObservation.JointName) -> CGPoint? {
        let src = displayJoints.isEmpty ? joints : displayJoints
        guard let j = src[name], j.confidence > 0.18 else { return nil }
        return j.point
    }

    var overlayJoints: [VNHumanHandPoseObservation.JointName: TrackedJoint] {
        displayJoints.isEmpty ? joints : displayJoints
    }

    var meanConfidence: Float {
        let src = joints.isEmpty ? overlayJoints : joints
        guard !src.isEmpty else { return 0 }
        return src.values.map(\.confidence).reduce(0, +) / Float(src.count)
    }

    var sideDE: String {
        switch chirality {
        case .left: return "Links"
        case .right: return "Rechts"
        default: return "Unbekannt"
        }
    }

    var isOpenEnough: Bool { openScore >= 3 }

    var palmScale: CGFloat {
        GestureClassifier.palmScale(joints.mapValues(\.point))
    }

    func isExtended(_ finger: FingerKind) -> Bool {
        extended.contains(finger.rawValue)
    }

    func confidence(_ name: VNHumanHandPoseObservation.JointName) -> Float {
        (displayJoints[name] ?? joints[name])?.confidence ?? 0
    }
}

final class HandTracker: @unchecked Sendable {
    private let request: VNDetectHumanHandPoseRequest = {
        let r = VNDetectHumanHandPoseRequest()
        r.maximumHandCount = GestureMath.obsHandCountCap()
        MetalHub.bindVision(r)
        return r
    }()

    private let faceRequest: VNDetectFaceRectanglesRequest = {
        let r = VNDetectFaceRectanglesRequest()
        MetalHub.bindVision(r)
        return r
    }()

    /// PinchGate + Smoother über Palm-Nähe, nicht L/R. Chirality ist nur Label.
    private struct PalmSlot {
        var smooth = LandmarkSmoothing()
        var pinch = PinchGate()
        var palm = CGPoint.zero
        var lastSeen: TimeInterval = 0
        /// Occlusion: Index-Tip fehlt, DIP bleibt.
        var lastIndexDIP: CGPoint?
        /// Letzter echter Index-Tip. DIP als Fake-Tip drückt Pinch-Ratio.
        var lastIndexTip: CGPoint?
        var lastIndexTipAt: TimeInterval = 0
        /// Occlusion: Daumen-Tip fehlt, IP bleibt — Pinch braucht beide Spitzen.
        var lastThumbIP: CGPoint?
        var lastThumbTip: CGPoint?
        var lastThumbTipAt: TimeInterval = 0
        var occlusionTicks: Int = 0
        /// 0 unknown, 1 left, 2 right. Vision-Flip sonst S1↔S2.
        var laterality: Int = 0
        var lateralityClaimedTicks: Int = 0
        var confEMA: [VNHumanHandPoseObservation.JointName: Float] = [:]
        /// Keep-Bit je Slot. Ohne Scale bleibt bindSlot keep:true — Gitarre 0,29 stiehlt S1.
        var scale: CGFloat = 0.12
    }

    private var slots: [Int: PalmSlot] = [:]
    private var nextSlotID = 0
    private var poseHold: [Int: (pose: HandPose, n: Int, pending: HandPose?, pendingN: Int)] = [:]
    private var emptySince: TimeInterval?
    private var lastHands: [TrackedHand] = []
    private var lastS1Palm: CGPoint?
    private var lastS1Scale: CGFloat = 0.12
    private var lastS1ScaleRing: [CGFloat] = []
    private var lastS1Vel: CGPoint = .zero
    private var s1MissTicks: Int = 0
    private var lastFrozenROI: CGRect?
    private var lastFrozenAt: TimeInterval = 0
    private var roiMissFullNext = false
    private var frozenMissTicks = 0
    private var expandMissTicks = 0
    private var lastObsDt: TimeInterval = 0.016
    private var lastObsAt: TimeInterval = 0
    private var faceScanTick = 0
    private var faceCount = 0
    private var lastFaceAt: TimeInterval = 0
    private let lock = NSLock()
    /// Continuity oft 0,12–0,18. Default Built-in 0,22 Observation / Engine 0,18.
    var minObservationConfidence: Float = 0.22
    /// Indoor 4 fps braucht 3. Pref 1–4, Default 2.
    var palmCoastNeed: Int = 2

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        slots.removeAll()
        nextSlotID = 0
        poseHold.removeAll()
        emptySince = nil
        lastHands = []
        lastS1Palm = nil
        lastS1Scale = 0.12
        lastS1ScaleRing = []
        lastS1Vel = .zero
        s1MissTicks = 0
        lastFrozenROI = nil
        lastFrozenAt = 0
        roiMissFullNext = false
        frozenMissTicks = 0
        expandMissTicks = 0
        lastObsDt = 0.016
        lastObsAt = 0
        faceScanTick = 0
        faceCount = 0
        lastFaceAt = 0
    }

    func snapshotFaces() -> (count: Int, lastSeen: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        return (faceCount, lastFaceAt)
    }

    func analyze(
        pixelBuffer: CVPixelBuffer,
        now: TimeInterval,
        mirrored: Bool = true,
        orientation: CGImagePropertyOrientation = .up
    ) -> [TrackedHand] {
        lock.lock()
        let minConf = minObservationConfidence
        let roiPick = GestureMath.palmROISlotPalm(
            hands: lastHands.map { (id: $0.id, palm: $0.palm, scale: $0.palmScale) },
            keepPalm: lastS1Palm,
            keepScale: lastS1Scale
        )
        let handSized = lastHands.filter { !$0.isGhost && GestureMath.palmScaleIsHand($0.palmScale) }.count
        let roiSecond = GestureMath.palmROISecondHands(handSized: handSized)
        let roiPalm = roiPick?.palm
        let roiScale = roiPick?.scale ?? lastS1Scale
        let roiDt = lastObsDt
        let coastNeed = GestureMath.palmCoastNeedAuto(dt: lastObsDt, pref: palmCoastNeed)
        let keepHand = lastS1Palm != nil && GestureMath.palmScaleIsHand(lastS1Scale, keep: true)
        let coastNow = GestureMath.palmCoastKeepsS1(miss: s1MissTicks, need: coastNeed)
        let frozenROI = lastFrozenROI
        let takeFull = roiMissFullNext
        let expandPrev = expandMissTicks
        if takeFull { roiMissFullNext = false }
        lock.unlock()
        var activeROI: CGRect?
        if takeFull {
            request.regionOfInterest = GestureMath.palmROIFull()
        } else if GestureMath.palmVisionUsesROI(),
           let roi = GestureMath.palmVisionROI(palm: roiPalm, scale: roiScale, secondHand: roiSecond, dt: roiDt) {
            let freeze = GestureMath.palmROIFreeze(keepHand: keepHand, coast: coastNow, secondHand: roiSecond)
            activeROI = GestureMath.palmROILocked(live: roi, frozen: frozenROI, freeze: freeze)
            if let activeROI {
                request.regionOfInterest = activeROI
            } else {
                request.regionOfInterest = GestureMath.palmROIFull()
            }
        } else {
            request.regionOfInterest = GestureMath.palmROIFull()
        }
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: orientation,
            options: [.ciContext: MetalHub.ci]
        )
        var performFailed = false
        var missFullNext = false
        var sameTickFull = false
        var expandHit = false
        var expandNext = 0
        do {
            try handler.perform([request])
        } catch {
            performFailed = true
        }
        // Crop-Miss: 8 fps direkt volles Bild, sonst 1,4× dann voll.
        if !performFailed, (request.results ?? []).isEmpty, let roi = activeROI,
           GestureMath.palmROIMissRetries(hadROI: true, empty: true) {
            if GestureMath.palmROIMissAllowsFull(dt: roiDt), GestureMath.palmROIMissGoesFull(dt: roiDt) {
                request.regionOfInterest = GestureMath.palmROIFull()
                do {
                    try handler.perform([request])
                } catch {
                    performFailed = true
                }
            } else {
                request.regionOfInterest = GestureMath.palmROIExpand(roi)
                do {
                    try handler.perform([request])
                } catch {
                    performFailed = true
                }
                if !performFailed, (request.results ?? []).isEmpty, GestureMath.palmROIMissAllowsFull(dt: roiDt) {
                    request.regionOfInterest = GestureMath.palmROIFull()
                    sameTickFull = true
                    do {
                        try handler.perform([request])
                    } catch {
                        performFailed = true
                    }
                } else if !performFailed, (request.results ?? []).isEmpty {
                    expandNext = GestureMath.palmROIMissExpandAdvance(prev: expandPrev, expandedEmpty: true)
                    missFullNext = GestureMath.palmROIMissFullNext(dt: roiDt, expanded: true)
                        || GestureMath.palmROIMissFullAfter(expandMiss: expandNext, dt: roiDt)
                } else if !performFailed {
                    expandHit = true
                    expandNext = 0
                }
            }
        } else if !performFailed, !(request.results ?? []).isEmpty {
            expandNext = 0
        }
        var pose3DZ: [VNChirality: Float] = [:]
        // macOS Vision hat keine VNDetectHumanHandPose3DRequest (iOS/visionOS).
        // PinchGate fällt auf 2D-Ratio zurück, tipZ bleibt nil.
        var facesN: Int?
        if !performFailed {
            lock.lock()
            let due = GestureMath.faceScanDue(tick: faceScanTick)
            faceScanTick += 1
            lock.unlock()
            if due {
                try? handler.perform([faceRequest])
                facesN = (faceRequest.results ?? []).filter { $0.confidence >= 0.35 }.count
            }
        }
        lock.lock()
        defer { lock.unlock() }
        if missFullNext { roiMissFullNext = true }
        expandMissTicks = expandNext
        if let facesN {
            faceCount = facesN
            if facesN > 0 { lastFaceAt = now }
        }
        if performFailed {
            if lastObsAt > 0 {
                lastObsDt = GestureMath.sampleDt(now: now, last: lastObsAt)
            }
            lastObsAt = now
            return emitEmpty(now: now)
        }
        let observations = request.results ?? []
        if lastObsAt > 0 {
            lastObsDt = GestureMath.sampleDt(now: now, last: lastObsAt)
        }
        lastObsAt = now
        if observations.isEmpty {
            let freezeEmpty = GestureMath.palmROIFreeze(keepHand: keepHand, coast: coastNow, secondHand: roiSecond)
            if takeFull || freezeEmpty {
                frozenMissTicks += 1
                if GestureMath.palmROIThawMiss(frozenMiss: frozenMissTicks)
                    || GestureMath.palmROIFreezeTTL(frozenAt: lastFrozenAt, now: now)
                {
                    lastFrozenROI = nil
                    lastFrozenAt = 0
                    roiMissFullNext = true
                    frozenMissTicks = 0
                }
            }
            return emitEmpty(now: now)
        }
        frozenMissTicks = 0
        expandMissTicks = 0

        let freezeROI = GestureMath.palmROIFreeze(keepHand: keepHand, coast: coastNow, secondHand: roiSecond)
        if GestureMath.palmROIThawHit(
            didFull: takeFull,
            hit: true,
            sameTickFull: sameTickFull && GestureMath.palmROIIsFull(request.regionOfInterest),
            expandHit: expandHit
        ) {
            lastFrozenROI = nil
            lastFrozenAt = 0
        } else if !GestureMath.palmROIFrozenWrite(freezeROI) {
            lastFrozenROI = nil
            lastFrozenAt = 0
        } else {
            if lastFrozenROI == nil {
                lastFrozenROI = activeROI
            }
            lastFrozenAt = GestureMath.palmROIFreezeClock(frozen: true, prev: lastFrozenAt, now: now)
        }

        let usedROI = request.regionOfInterest
        var hands: [TrackedHand] = []
        hands.reserveCapacity(observations.count)
        var claimed: Set<VNChirality> = []
        var claimedSlots: Set<Int> = []
        var bindScales = Array(repeating: CGFloat(1), count: observations.count)
        var bindPalms = Array(repeating: CGPoint.zero, count: observations.count)
        var bindCounts = Array(repeating: 0, count: observations.count)
        let keepBind = lastS1Palm != nil && GestureMath.palmScaleIsHand(lastS1Scale, keep: true)
        for (i, obs) in observations.enumerated() {
            guard let pts = try? obs.recognizedPoints(.all) else { continue }
            var raw: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
            var wristC: Float?
            var mcpCs: [Float] = []
            var tipCs: [Float] = []
            for (name, p) in pts where p.confidence > 0.10 {
                raw[name] = CGPoint(x: p.location.x, y: p.location.y)
                if name == .wrist { wristC = p.confidence }
                if name == .indexMCP || name == .middleMCP || name == .ringMCP || name == .littleMCP {
                    mcpCs.append(p.confidence)
                }
                if name == .indexTip || name == .middleTip || name == .ringTip || name == .littleTip {
                    tipCs.append(p.confidence)
                }
            }
            if let mapROI = GestureMath.visionROIMap(roi: usedROI, sample: Array(raw.values)) {
                for (name, p) in raw {
                    raw[name] = GestureMath.visionPointFromROI(p, roi: mapROI)
                }
            }
            let scLive = GestureClassifier.palmScale(raw)
            let sc = GestureMath.palmBindScaleOf(live: scLive, last: lastS1Scale, ticks: lastS1ScaleRing.count)
            let span = GestureMath.obsJointSpan(Array(raw.values))
            let mcpPts = [raw[.indexMCP], raw[.middleMCP], raw[.ringMCP], raw[.littleMCP]].compactMap { $0 }
            let mcpN = mcpPts.count
            let sparse = GestureMath.fingerSparseKeepsPalm(
                rawCount: raw.count,
                hasWrist: raw[.wrist] != nil,
                mcpCount: mcpN
            )
            let chainOk = GestureMath.obsFingerChainPairs(
                wrist: raw[.wrist],
                mcps: [raw[.indexMCP], raw[.middleMCP], raw[.ringMCP], raw[.littleMCP]],
                tips: [raw[.indexTip], raw[.middleTip], raw[.ringTip], raw[.littleTip]]
            )
            let fan = GestureMath.palmMCPFanDeg(wrist: raw[.wrist], mcps: mcpPts)
            let fanOk = sparse || !GestureMath.palmMCPCollinearVeto(fan: fan)
            let confOk = GestureMath.obsJointConfOk(wrist: wristC, mcps: mcpCs, tips: tipCs, sparse: sparse)
            if GestureMath.obsLooksLikeHand(
                spanW: span.w,
                spanH: span.h,
                palmScale: sc,
                jointCount: raw.count,
                keep: keepBind,
                sparse: sparse,
                chainOk: chainOk,
                fanOk: fanOk
            ), confOk {
                bindScales[i] = sc
            } else {
                bindScales[i] = 1
            }
            bindPalms[i] = GestureClassifier.palmCenter(raw)
            bindCounts[i] = raw.count
        }
        let handHit = bindScales.contains { GestureMath.palmScaleIsHand($0) }
        let thawProp = GestureMath.palmROIThawProp(frozen: lastFrozenROI != nil, hit: true, handHit: handHit)
        if thawProp || GestureMath.palmROIFreezeTTL(frozenAt: lastFrozenAt, now: now) {
            lastFrozenROI = nil
            lastFrozenAt = 0
            roiMissFullNext = true
        }
        if thawProp {
            return emitEmpty(now: now)
        }
        var s1Locked = slots[1]?.laterality ?? 0
        for idx in GestureMath.palmBindHandsFirst(
            scales: bindScales, palms: bindPalms, last: lastS1Palm, counts: bindCounts
        ) {
            let obs = observations[idx]
            guard let pts = try? obs.recognizedPoints(.all) else { continue }
            if obs.confidence < minConf { continue }
            var raw: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
            var conf: [VNHumanHandPoseObservation.JointName: Float] = [:]
            var wristC: Float?
            var mcpCs: [Float] = []
            var tipCs: [Float] = []
            for (name, p) in pts where p.confidence > 0.10 {
                raw[name] = CGPoint(x: p.location.x, y: p.location.y)
                conf[name] = p.confidence
                if name == .wrist { wristC = p.confidence }
                if name == .indexMCP || name == .middleMCP || name == .ringMCP || name == .littleMCP {
                    mcpCs.append(p.confidence)
                }
                if name == .indexTip || name == .middleTip || name == .ringTip || name == .littleTip {
                    tipCs.append(p.confidence)
                }
            }
            if let mapROI = GestureMath.visionROIMap(roi: usedROI, sample: Array(raw.values)) {
                for (name, p) in raw {
                    raw[name] = GestureMath.visionPointFromROI(p, roi: mapROI)
                }
            }
            let spanLive = GestureMath.obsJointSpan(Array(raw.values))
            let scaleLive = GestureMath.palmBindScaleOf(
                live: GestureClassifier.palmScale(raw),
                last: lastS1Scale,
                ticks: lastS1ScaleRing.count
            )
            let mcpPts = [raw[.indexMCP], raw[.middleMCP], raw[.ringMCP], raw[.littleMCP]].compactMap { $0 }
            let mcpN = mcpPts.count
            let sparse = GestureMath.fingerSparseKeepsPalm(
                rawCount: raw.count,
                hasWrist: raw[.wrist] != nil,
                mcpCount: mcpN
            )
            let chainLive = GestureMath.obsFingerChainPairs(
                wrist: raw[.wrist],
                mcps: [raw[.indexMCP], raw[.middleMCP], raw[.ringMCP], raw[.littleMCP]],
                tips: [raw[.indexTip], raw[.middleTip], raw[.ringTip], raw[.littleTip]]
            )
            let fanLive = GestureMath.palmMCPFanDeg(wrist: raw[.wrist], mcps: mcpPts)
            let fanOk = sparse || !GestureMath.palmMCPCollinearVeto(fan: fanLive)
            if !GestureMath.obsLooksLikeHand(
                spanW: spanLive.w,
                spanH: spanLive.h,
                palmScale: scaleLive,
                jointCount: raw.count,
                keep: keepBind,
                sparse: sparse,
                chainOk: chainLive,
                fanOk: fanOk
            ) {
                continue
            }
            if !GestureMath.obsJointConfOk(wrist: wristC, mcps: mcpCs, tips: tipCs, sparse: sparse) {
                continue
            }
            if raw.count < 5, !sparse { continue }

            var chirality = obs.chirality
            if chirality == .unknown {
                let wx = raw[.wrist]?.x ?? 0.5
                chirality = wx < 0.5 ? .left : .right
            }
            if mirrored {
                if chirality == .left { chirality = .right }
                else if chirality == .right { chirality = .left }
            }
            if GestureMath.palmLateralityClaimFlips(claimed.contains(chirality)) {
                let other: VNChirality = chirality == .left ? .right : .left
                chirality = claimed.contains(other) ? .unknown : other
            }

            let palmGuess = GestureClassifier.palmCenter(raw)
            let scale = GestureClassifier.palmScale(raw)
            let tipZ = pose3DZ[chirality] ?? pose3DZ[.unknown]
            if raw.count < 8 {
                let prev = lastHands.min {
                    hypot($0.palm.x - palmGuess.x, $0.palm.y - palmGuess.y)
                        < hypot($1.palm.x - palmGuess.x, $1.palm.y - palmGuess.y)
                }
                if let prev {
                    let palmBones: Set<VNHumanHandPoseObservation.JointName> = [
                        .wrist, .indexMCP, .middleMCP, .ringMCP, .littleMCP, .thumbMP
                    ]
                    for (name, joint) in prev.joints where raw[name] == nil {
                        guard GestureMath.sparseMergeKeeps(isPalmBone: palmBones.contains(name)) else { continue }
                        raw[name] = joint.point
                        conf[name] = min(joint.confidence, 0.35)
                    }
                }
                if raw.count < 8 { continue }
            }
            let liveCodeEarly = GestureMath.palmLateralityCode(chirality == .left, right: chirality == .right)
            let slotID = bindSlot(palm: palmGuess, scale: scale, claimed: &claimedSlots, now: now, liveCode: liveCodeEarly)
            var slot = slots[slotID] ?? PalmSlot(palm: palmGuess, lastSeen: now)
            var liveCode = liveCodeEarly
            if GestureMath.palmLateralityBlocksS2(s1Locked: s1Locked, live: liveCode, slotID: slotID) {
                liveCode = 0
                chirality = .unknown
            }
            let prevWanted: VNChirality = slot.laterality == 1 ? .left : slot.laterality == 2 ? .right : .unknown
            let otherClaimed = prevWanted != .unknown && claimed.contains(prevWanted)
            if otherClaimed { slot.lateralityClaimedTicks += 1 } else { slot.lateralityClaimedTicks = 0 }
            let locked = GestureMath.palmLateralityLock(
                prev: slot.laterality,
                live: liveCode,
                otherClaimed: otherClaimed,
                claimedTicks: slot.lateralityClaimedTicks
            )
            let claimedSame = (locked == 1 && claimed.contains(.left)) || (locked == 2 && claimed.contains(.right))
            let takes = GestureMath.palmLateralityTakes(locked: locked, claimedSame: claimedSame)
            if takes == 1 { chirality = .left }
            else if takes == 2 { chirality = .right }
            else if takes == 0 { chirality = .unknown }
            if slotID == 1, takes == 1 || takes == 2 {
                s1Locked = takes
            }
            if chirality == .left || chirality == .right {
                claimed.insert(chirality)
            }
            slot.laterality = takes
            let lateralityLiveCode = liveCode
            for name in Set(conf.keys).union(slot.confEMA.keys) {
                let live = conf[name] ?? 0
                let ema = GestureMath.jointConfEMA(prev: slot.confEMA[name] ?? 0, live: live)
                slot.confEMA[name] = ema
                let holds = GestureMath.jointConfHolds(ema)
                if holds {
                    conf[name] = ema
                }
                let isTip = name == .indexTip || name == .thumbTip || name == .middleTip || name == .ringTip || name == .littleTip
                if GestureMath.jointConfRestores(holds: holds, isTip: isTip), raw[name] == nil, let prev = lastHands.first(where: { $0.id == "S\(slotID)" })?.joints[name] {
                    raw[name] = prev.point
                }
            }
            if let tip = raw[.indexTip], (conf[.indexTip] ?? 0) >= GestureMath.pinchOcclusionFloor {
                slot.lastIndexTip = tip
                slot.lastIndexTipAt = now
            }
            if let tip = raw[.thumbTip], (conf[.thumbTip] ?? 0) >= GestureMath.pinchOcclusionFloor {
                slot.lastThumbTip = tip
                slot.lastThumbTipAt = now
            }
            var tipHeld = false
            let indexFresh = GestureMath.fingerOcclusionFresh(savedAt: slot.lastIndexTipAt > 0 ? slot.lastIndexTipAt : nil, now: now)
            let thumbFresh = GestureMath.fingerOcclusionFresh(savedAt: slot.lastThumbTipAt > 0 ? slot.lastThumbTipAt : nil, now: now)
            let wantsIndex = GestureMath.fingerOcclusionHoldsDIP(
                tipConf: conf[.indexTip],
                hasDIP: raw[.indexDIP] != nil
                    || GestureMath.fingerOcclusionUsesLastTip(lastTip: indexFresh ? slot.lastIndexTip : nil)
            )
            let wantsThumb = GestureMath.fingerOcclusionHoldsDIP(
                tipConf: conf[.thumbTip],
                hasDIP: raw[.thumbIP] != nil
                    || GestureMath.fingerOcclusionUsesLastTip(lastTip: thumbFresh ? slot.lastThumbTip : nil)
            )
            if wantsIndex || wantsThumb {
                slot.occlusionTicks += 1
            } else {
                slot.occlusionTicks = 0
            }
            let occOk = GestureMath.fingerOcclusionConfirm(ticks: slot.occlusionTicks)
            if occOk, wantsIndex, let tip = GestureMath.fingerOcclusionTip(
                lastTip: slot.lastIndexTip,
                dip: raw[.indexDIP] ?? slot.lastIndexDIP,
                lastTipFresh: indexFresh
            ) {
                let followed = GestureMath.fingerOcclusionFollows(lastTip: tip, lastPalm: slot.palm, palm: palmGuess)
                raw[.indexTip] = followed
                slot.lastIndexTip = followed
                conf[.indexTip] = max(conf[.indexDIP] ?? 0.25, 0.25)
                tipHeld = true
            }
            if occOk, wantsThumb, let tip = GestureMath.fingerOcclusionTip(
                lastTip: slot.lastThumbTip,
                dip: raw[.thumbIP] ?? slot.lastThumbIP,
                lastTipFresh: thumbFresh
            ) {
                let followed = GestureMath.fingerOcclusionFollows(lastTip: tip, lastPalm: slot.palm, palm: palmGuess)
                raw[.thumbTip] = followed
                slot.lastThumbTip = followed
                conf[.thumbTip] = max(conf[.thumbIP] ?? 0.25, 0.25)
                tipHeld = true
            }
            if occOk, wantsIndex || wantsThumb { tipHeld = true }
            if let dip = raw[.indexDIP] { slot.lastIndexDIP = dip }
            if let ip = raw[.thumbIP] { slot.lastThumbIP = ip }
            if GestureMath.obsSmoothResets(
                prevPalm: slot.palm,
                nextPalm: palmGuess,
                hadPrev: slot.lastSeen > 0 && slot.palm != .zero,
                chiralityHolds: GestureMath.obsSmoothChiralityHolds(prev: slot.laterality, live: liveCode),
                dt: lastObsDt
            ) {
                slot.smooth.reset()
            }
            let smoothed = slot.smooth.apply(raw, now: now)
            let gateJoints = GestureMath.pinchGateUsesSmoothed(closed: slot.pinch.closed) ? smoothed : raw
            let pinchState = slot.pinch.update(raw: gateJoints, conf: conf, now: now, tipZ: tipZ, dt: lastObsDt)
            slot.palm = palmGuess
            slot.lastSeen = now
            slot.scale = GestureMath.palmScaleKalman(prev: slot.scale, live: scale)
            slots[slotID] = slot

            var joints: [VNHumanHandPoseObservation.JointName: TrackedJoint] = [:]
            var display: [VNHumanHandPoseObservation.JointName: TrackedJoint] = [:]
            for (name, point) in smoothed {
                joints[name] = TrackedJoint(point: point, confidence: conf[name] ?? 0)
            }
            for (name, point) in raw {
                display[name] = TrackedJoint(point: point, confidence: conf[name] ?? 0)
            }

            let pinch = pinchState.distance
            let palm = GestureClassifier.palmCenter(smoothed)
            var pose = GestureClassifier.classify(joints: smoothed, pinch: pinch)
            if pinchState.closed, pose == .unknown || pose == .point || pose == .fist {
                pose = .pinch
            }
            pose = stabilize(pose, slot: slotID, dt: lastObsDt, gateClosed: pinchState.closed)
            if pinchState.closed, pose == .unknown || pose == .point || pose == .fist {
                pose = .pinch
            }
            let openScore = GestureClassifier.openScore(joints: smoothed)
            let ratio = pinchState.ratio
            var ext: Set<String> = []
            for f in FingerKind.allCases {
                if GestureClassifier.isExtended(smoothed, tip: f.tip, pip: f.pip, mcp: f.mcp) {
                    ext.insert(f.rawValue)
                }
            }
            hands.append(
                TrackedHand(
                    id: "S\(slotID)",
                    chirality: chirality,
                    joints: joints,
                    displayJoints: display,
                    pose: pose,
                    pinchDistance: pinch,
                    pinchRatio: ratio,
                    pinchClosed: pinchState.closed,
                    palm: palm,
                    openScore: openScore,
                    extended: ext,
                    tipZ: tipZ,
                    tipHeld: tipHeld,
                    lateralityLive: lateralityLiveCode
                )
            )
        }
        expireSlots(claimed: claimedSlots, now: now)
        if GestureMath.trackerEmptyKeepsGhost(kept: hands.count) {
            return emitEmpty(now: now)
        }
        emptySince = nil
        let s1Live = hands.contains { $0.id == "S1" && !$0.isGhost }
        let wasCoast = lastHands.contains { $0.id == "S1" && $0.isGhost }
        let coastNeedLive = GestureMath.palmCoastNeedAuto(dt: lastObsDt, pref: palmCoastNeed)
        s1MissTicks = GestureMath.palmCoastAdvance(prev: s1MissTicks, hit: s1Live)
        if !s1Live, GestureMath.palmCoastKeepsS1(miss: s1MissTicks, need: coastNeedLive),
           let prev = lastHands.first(where: { $0.id == "S1" })
        {
            let rest = hands.filter { $0.id != "S1" }
            hands = applyCoastGhost(prev: prev, onto: rest)
        }
        lastHands = hands
        let keepLast = GestureMath.palmScaleIsHand(lastS1Scale, keep: true)
        if GestureMath.palmScaleMedianKeeps(s1Live: s1Live),
           let s1 = hands.first(where: { $0.id == "S1" && !$0.isGhost }),
           GestureMath.palmScaleIsHand(s1.palmScale, keep: keepLast) {
            if let prev = lastS1Palm {
                lastS1Vel = GestureMath.palmCoastReturnVel(
                    live: s1.palm, stored: prev, wasCoast: wasCoast, lastVel: lastS1Vel
                )
            }
            lastS1Palm = s1.palm
            lastS1ScaleRing = Array(lastS1ScaleRing.suffix(GestureMath.palmScaleMedianCap - 1)) + [s1.palmScale]
            lastS1Scale = GestureMath.palmScaleKalman(
                prev: lastS1Scale,
                live: GestureMath.palmScaleMedian(lastS1ScaleRing) ?? s1.palmScale
            )
        }
        return hands
    }

    /// Observation leer oder alles unter Floor: Ghost statt lastHands = [].
    /// Coast zuerst — sonst lastS1/ROI tot nach einem Continuity-Dropout.
    private func emitEmpty(now: TimeInterval) -> [TrackedHand] {
        let coastNeed = GestureMath.palmCoastNeedAuto(dt: lastObsDt, pref: palmCoastNeed)
        s1MissTicks = GestureMath.palmCoastAdvance(prev: s1MissTicks, hit: false)
        if GestureMath.palmCoastEmptyKeeps(miss: s1MissTicks, need: coastNeed),
           let prev = lastHands.first(where: { $0.id == "S1" })
        {
            emptySince = nil
            lastHands = applyCoastGhost(prev: prev, onto: lastHands.filter { $0.id != "S1" })
            return lastHands
        }
        if emptySince == nil { emptySince = now }
        let emptyFor = now - (emptySince ?? now)
        if GestureMath.slotKeepsID(emptyFor: emptyFor) {
            if GestureMath.ghostHands(emptyFor: emptyFor), !lastHands.isEmpty {
                let remaining = max(0, GestureMath.slotLatch - emptyFor)
                return lastHands.map { h in
                    var copy = h
                    copy.isGhost = true
                    copy.ghostRemaining = remaining
                    return copy
                }
            }
            lastHands = []
            lastS1Palm = nil
            lastS1Scale = 0.12
            lastS1ScaleRing = []
            lastS1Vel = .zero
            s1MissTicks = 0
            lastFrozenROI = nil
            lastFrozenAt = 0
            roiMissFullNext = false
            frozenMissTicks = 0
            expandMissTicks = 0
            return []
        }
        emptySince = nil
        slots.removeAll()
        poseHold.removeAll()
        lastHands = []
        lastS1Palm = nil
        lastS1Scale = 0.12
        lastS1ScaleRing = []
        lastS1Vel = .zero
        s1MissTicks = 0
        lastFrozenROI = nil
        lastFrozenAt = 0
        roiMissFullNext = false
        frozenMissTicks = 0
        expandMissTicks = 0
        return []
    }

    private func applyCoastGhost(prev: TrackedHand, onto rest: [TrackedHand]) -> [TrackedHand] {
        var ghost = prev
        ghost.isGhost = true
        ghost.ghostRemaining = 0
        lastS1Vel = GestureMath.palmCoastVelDecay(vel: lastS1Vel, miss: s1MissTicks)
        let predicted = GestureMath.palmCoastPredict(palm: prev.palm, vel: lastS1Vel)
        let delta = GestureMath.palmCoastDelta(from: prev.palm, to: predicted)
        ghost.palm = predicted
        ghost.joints = ghost.joints.mapValues { j in
            var copy = j
            copy.point = GestureMath.palmCoastShift(j.point, delta: delta)
            return copy
        }
        ghost.displayJoints = ghost.displayJoints.mapValues { j in
            var copy = j
            copy.point = GestureMath.palmCoastShift(j.point, delta: delta)
            return copy
        }
        lastS1Palm = predicted
        if GestureMath.palmROICoastFollows(true) {
            lastFrozenROI = GestureMath.palmROIFollow(palm: predicted, scale: lastS1Scale, dt: lastObsDt)
            if lastFrozenAt <= 0 { lastFrozenAt = lastObsAt }
        }
        let ghosts = rest.map { h -> TrackedHand in
            var copy = h
            copy.isGhost = true
            copy.ghostRemaining = 0
            return copy
        }
        return [ghost] + ghosts
    }

    /// Observation-Index und Chirality springen. Dieselbe Hand über Palm-Nähe halten.
    private func bindSlot(palm: CGPoint, scale: CGFloat, claimed: inout Set<Int>, now: TimeInterval, liveCode: Int = 0) -> Int {
        let bind = GestureMath.slotBind(dt: lastObsDt, scale: scale)
        let latch = GestureMath.slotLatchBind(dt: lastObsDt, scale: scale)
        var bestK: Int?
        var bestD = latch
        var unclaimed = 0
        let haveMatch = slots.contains { k, s in
            !claimed.contains(k) && GestureMath.slotLateralityMatches(slotCode: s.laterality, liveCode: liveCode)
        }
        let keepPrev = Dictionary(uniqueKeysWithValues: slots.map { k, s in
            (k, GestureMath.slotKeepBit(id: k, scale: s.scale, prev: [k: true], prevScale: [k: s.scale]))
        })
        let scalePrev = Dictionary(uniqueKeysWithValues: slots.map { ($0.key, $0.value.scale) })
        for (k, s) in slots where !claimed.contains(k) {
            unclaimed += 1
            if !GestureMath.slotLateralityPrefers(slotCode: s.laterality, liveCode: liveCode, haveMatch: haveMatch) {
                continue
            }
            if GestureMath.slotBindSkipsProp(slotID: k, scale: scale, prev: keepPrev, prevScale: scalePrev) {
                continue
            }
            let d = GestureMath.slotLateralityDist(
                palmDist: hypot(s.palm.x - palm.x, s.palm.y - palm.y),
                slotCode: s.laterality,
                liveCode: liveCode
            )
            if d < bestD {
                bestD = d
                bestK = k
            }
        }
        if let k = bestK,
           GestureMath.slotReusesUnclaimed(unclaimed: unclaimed, nearest: bestD, bind: bind, latch: latch)
        {
            claimed.insert(k)
            return k
        }
        let k = allocSlot(palm: palm, scale: scale, now: now, claimed: claimed)
        claimed.insert(k)
        return k
    }

    /// Abgelaufene IDs wiederverwenden, sonst S47 nach einer Stunde.
    private func allocSlot(palm: CGPoint, scale: CGFloat, now: TimeInterval, claimed: Set<Int>) -> Int {
        let used = Set(slots.keys)
        let latching = slots.contains { now - $0.value.lastSeen < GestureMath.slotLatch }
        let cap = GestureMath.slotAllocCap(latching: latching)
        let searchTo = cap ?? max(2, nextSlotID)
        let searchFrom = GestureMath.slotAllocMinID(scale: scale)
        if let free = (searchFrom...max(searchFrom, searchTo)).first(where: { !used.contains($0) && !claimed.contains($0) }) {
            slots[free] = PalmSlot(palm: palm, lastSeen: now, scale: scale)
            nextSlotID = max(nextSlotID, free)
            return free
        }
        if !GestureMath.slotMintsNew(existing: used.count, latching: latching), let cap {
            var bestK: Int?
            var bestD = CGFloat.infinity
            for (k, s) in slots where k <= cap && !claimed.contains(k) {
                let d = hypot(s.palm.x - palm.x, s.palm.y - palm.y)
                if d < bestD {
                    bestD = d
                    bestK = k
                }
            }
            if let k = bestK {
                slots[k] = PalmSlot(palm: palm, lastSeen: now, scale: scale)
                return k
            }
        }
        nextSlotID += 1
        let k = nextSlotID
        slots[k] = PalmSlot(palm: palm, lastSeen: now, scale: scale)
        return k
    }

    private func expireSlots(claimed: Set<Int>, now: TimeInterval) {
        slots = slots.filter { key, slot in
            if claimed.contains(key) { return true }
            return now - slot.lastSeen < GestureMath.slotLatch
        }
        poseHold = poseHold.filter { slots[$0.key] != nil }
    }

    private func holdNeed(_ pose: HandPose, dt: TimeInterval, gateClosed: Bool) -> Int {
        pose == .pinch ? GestureMath.pinchPoseHoldNeed(dt: dt, gateClosed: gateClosed) : GestureMath.poseHoldNeed(dt: dt)
    }

    /// Pinch 2 Frames (Latenz). Peace/Daumen brauchen Bestätigung, sonst 1-Frame-Fehlschuss.
    /// Faust/Offen dürfen im ersten Frame stehen — Arming/Cursor brauchen das.
    /// 8 fps: Gate schon zu → kein Extra-Hold.
    private func stabilize(_ pose: HandPose, slot: Int, dt: TimeInterval, gateClosed: Bool = false) -> HandPose {
        let k = slot
        let need = holdNeed(pose, dt: dt, gateClosed: gateClosed)
        if pose == .unknown, let old = poseHold[k] { return old.pose }
        if var h = poseHold[k] {
            if h.pose == pose {
                h.n = min(8, h.n + 1)
                h.pending = nil
                h.pendingN = 0
                poseHold[k] = h
                return pose
            }
            if h.pending == pose {
                h.pendingN += 1
            } else {
                h.pending = pose
                h.pendingN = 1
            }
            if h.pendingN >= need {
                poseHold[k] = (pose, need, nil, 0)
                return pose
            }
            poseHold[k] = h
            return h.pose
        }
        if pose == .peace || pose == .thumbsUp {
            poseHold[k] = (.unknown, 0, pose, 1)
            return .unknown
        }
        poseHold[k] = (pose, 1, nil, 0)
        return pose
    }
}


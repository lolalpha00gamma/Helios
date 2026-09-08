import CoreMedia
import CoreVideo
import Foundation
import ImageIO
import Vision

struct TrackedJoint {
    var point: CGPoint
    var confidence: Float
    var z: CGFloat = 0
}

struct TrackedHand: Identifiable {
    var id: String
    var chirality: VNChirality
    var joints: [VNHumanHandPoseObservation.JointName: TrackedJoint]
    var displayJoints: [VNHumanHandPoseObservation.JointName: TrackedJoint]
    var pose: HandPose
    var poseProb: Double
    var pinchDistance: CGFloat
    var pinchRatio: CGFloat
    var pinchClosed: Bool
    var pinchClosedness: Double
    var palm: CGPoint
    var palmWidth: CGFloat
    var openScore: Int
    var extended: Set<String>
    var fusion: FusionDebug?
    var quality: Double
    var sourceID: String = ""
    /// 0…1 vom Classifier, nicht das 0,52-Set.
    var indexScore: Double = 0.15
    var liftResidual: CGFloat = 0

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
        let src = overlayJoints
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

    func isExtended(_ finger: FingerKind) -> Bool {
        extended.contains(finger.rawValue)
    }

    /// Freeze-Predict: Gelenke + Palme um Δ. Geisterhand sonst steht.
    func shifted(by d: CGPoint) -> TrackedHand {
        guard d.x != 0 || d.y != 0 else { return self }
        var h = self
        h.palm = CGPoint(x: palm.x + d.x, y: palm.y + d.y)
        func move(_ src: [VNHumanHandPoseObservation.JointName: TrackedJoint]) -> [VNHumanHandPoseObservation.JointName: TrackedJoint] {
            var out = src
            for (k, j) in src {
                var jj = j
                jj.point = CGPoint(x: j.point.x + d.x, y: j.point.y + d.y)
                out[k] = jj
            }
            return out
        }
        h.joints = move(h.joints)
        if !h.displayJoints.isEmpty { h.displayJoints = move(h.displayJoints) }
        return h
    }

    /// Wrist → Daumen/Zeigefinger. Faust bleibt unter pinchReachNeed.
    var pinchReach: CGFloat {
        guard let w = point(.wrist), let t = point(.thumbTip), let i = point(.indexTip) else {
            return isExtended(.index) ? 1.2 : 0.3
        }
        return GestureMath.pinchReach(wrist: w, thumb: t, index: i, scale: palmWidth)
    }

    /// |z_Daumen − z_Zeigefinger| in Palmenbreiten. Faust-in-Kamera hat 2D-Reach, 3D-Sep groß.
    var pinchZSep: CGFloat {
        guard let t = joints[.thumbTip], let i = joints[.indexTip],
              t.confidence > 0.22, i.confidence > 0.22 else { return 0 }
        return GestureMath.pinch3DSep(thumbZ: t.z, indexZ: i.z, palmWidth: palmWidth)
    }

    /// Beide Spitzen auf die Kamera. Sep tot wenn Daumen und Zeigefinger gleich tief.
    var pinchZApproach: CGFloat {
        guard let t = joints[.thumbTip], let i = joints[.indexTip],
              t.confidence > 0.22, i.confidence > 0.22 else { return 0 }
        return GestureMath.pinch3DApproach(thumbZ: t.z, indexZ: i.z, palmWidth: palmWidth)
    }

    func confidence(_ name: VNHumanHandPoseObservation.JointName) -> Float {
        (displayJoints[name] ?? joints[name])?.confidence ?? 0
    }
}

private struct RawObs {
    var raw: [VNHumanHandPoseObservation.JointName: CGPoint]
    var conf: [VNHumanHandPoseObservation.JointName: Float]
    var chirality: VNChirality
    var palm: CGPoint
}

private struct TrackSlot {
    var id: String
    var chirality: VNChirality
    var smoother = LandmarkSmoothing()
    var pinch = PinchGate()
    var hmm = PoseHMM()
    var fusion = EstimateFusion()
    var temporal = TemporalNet()
    var lastPalm: CGPoint = .zero
    var lastSeen: TimeInterval = 0
    var lastZ: [VNHumanHandPoseObservation.JointName: CGFloat] = [:]
    var lastNow: TimeInterval = 0
    var palmWidthEma: CGFloat = 0
}

final class HandTracker: @unchecked Sendable {
    private let request: VNDetectHumanHandPoseRequest = {
        let r = VNDetectHumanHandPoseRequest()
        r.maximumHandCount = 2
        r.revision = VNDetectHumanHandPoseRequestRevision1
        MetalHub.bindVision(r)
        return r
    }()

    private let bodyRequest: VNDetectHumanBodyPoseRequest = {
        let r = VNDetectHumanBodyPoseRequest()
        r.revision = VNDetectHumanBodyPoseRequestRevision1
        MetalHub.bindVision(r)
        return r
    }()

    private var tracks: [TrackSlot] = []
    private var nextID = 1
    private let lock = NSLock()
    var lastFusion: FusionDebug?
    var depthAvailable = false
    var fusionTemperature: Double = 0.75
    private(set) var lastSpace = AspectSpace.hd720
    private var lastHands: [TrackedHand] = []
    private var lastHandsAt: TimeInterval = 0
    private var bodyTick = 0
    private var lastBodyPts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint] = [:]

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        tracks.removeAll()
        lastFusion = nil
        lastHands = []
        lastHandsAt = 0
        lastBodyPts = [:]
        bodyTick = 0
    }

    func analyze(
        pixelBuffer: CVPixelBuffer,
        now: TimeInterval,
        mirrored: Bool = true,
        depth: DepthSample? = nil,
        orientation: CGImagePropertyOrientation = .up
    ) -> [TrackedHand] {
        lock.lock()
        defer { lock.unlock() }
        let w = CVPixelBufferGetWidth(pixelBuffer)
        let h = CVPixelBufferGetHeight(pixelBuffer)
        let space = AspectSpace(width: CGFloat(max(1, w)), height: CGFloat(max(1, h)))
        lastSpace = space

        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: orientation,
            options: [.ciContext: MetalHub.ci]
        )
        do {
            bodyTick += 1
            if bodyTick % 4 == 1 {
                try handler.perform([request, bodyRequest])
                lastBodyPts = (try? bodyRequest.results?.first?.recognizedPoints(.all)) ?? lastBodyPts
            } else {
                try handler.perform([request])
            }
        } catch {
            // Drop the frame. A second VNImageRequestHandler on the same buffer
            // almost never recovers and burns the rest of the tick.
        }
        let observations = request.results ?? []
        if observations.isEmpty {
            tracks.removeAll { now - $0.lastSeen > 0.12 }
            if !lastHands.isEmpty, now - lastHandsAt < 0.09 {
                return lastHands
            }
            lastHands = []
            lastFusion = nil
            return []
        }

        let bodyPts = lastBodyPts
        depthAvailable = depth != nil

        var obsList: [RawObs] = []
        for obs in observations {
            guard let pts = try? obs.recognizedPoints(.all) else { continue }
            if obs.confidence < 0.22 { continue }
            var raw: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
            var conf: [VNHumanHandPoseObservation.JointName: Float] = [:]
            for (name, p) in pts where p.confidence > 0.18 {
                raw[name] = CGPoint(x: p.location.x, y: p.location.y)
                conf[name] = p.confidence
            }
            guard raw.count >= 8 else { continue }
            var chirality = obs.chirality
            if mirrored {
                if chirality == .left { chirality = .right }
                else if chirality == .right { chirality = .left }
            }
            let palm = GestureClassifier.palmCenter(raw)
            if let voted = bodyChirality(palm: palm, body: bodyPts, vision: chirality) {
                chirality = voted
            } else if chirality == .unknown {
                let wx = raw[.wrist]?.x ?? 0.5
                if mirrored {
                    chirality = wx < 0.5 ? .left : .right
                } else {
                    chirality = wx < 0.5 ? .right : .left
                }
            }
            obsList.append(RawObs(raw: raw, conf: conf, chirality: chirality, palm: palm))
        }

        let assigned = assign(obsList, space: space, now: now)
        var hands: [TrackedHand] = []
        for (idx, obs) in obsList.enumerated() {
            var slot: TrackSlot
            if let ti = assigned[idx], ti < tracks.count {
                slot = tracks[ti]
            } else {
                slot = TrackSlot(id: "T\(nextID)", chirality: obs.chirality)
                nextID += 1
            }
            slot.smoother.space = space
            slot.pinch.setSpace(space)
            let dt = slot.lastNow == 0 ? 0.016 : GestureMath.sampleDt(now: now, last: slot.lastNow)
            if slot.lastSeen > 0, now - slot.lastSeen > 0.35 {
                slot.hmm.reset()
                slot.fusion.reset()
                slot.temporal.reset()
            }

            let smoothed = slot.smoother.apply(obs.raw, now: now)
            let lifted = Lift3D.lift(joints: smoothed, conf: obs.conf, space: space, previous: slot.lastZ)
            if !GestureMath.liftSignKeepsPrevious(residual: lifted.residual) {
                slot.lastZ = Dictionary(uniqueKeysWithValues: lifted.pts.map { ($0.key, $0.value.z) })
            }
            let zSep: CGFloat = {
                guard let t = lifted.pts[.thumbTip], let i = lifted.pts[.indexTip],
                      t.c > 0.22, i.c > 0.22 else { return 0 }
                return GestureMath.pinch3DSep(thumbZ: t.z, indexZ: i.z, palmWidth: lifted.palmWidth)
            }()
            let approach: CGFloat = {
                guard let t = lifted.pts[.thumbTip], let i = lifted.pts[.indexTip],
                      t.c > 0.22, i.c > 0.22 else { return 0 }
                return GestureMath.pinch3DApproach(thumbZ: t.z, indexZ: i.z, palmWidth: lifted.palmWidth)
            }()
            let pinchState = slot.pinch.update(
                raw: smoothed,
                conf: obs.conf,
                now: now,
                zSep: zSep,
                approach: approach,
                residual: lifted.residual
            )
            let feat2D = GestureClassifier.features(
                joints: smoothed,
                pinch: pinchState.distance,
                conf: obs.conf,
                space: space
            )
            var q2 = feat2D.quality
            q2 *= forearmGate(palm: feat2D.palm, wrist: smoothed[.wrist], chirality: obs.chirality, body: bodyPts, space: space)

            let e2 = HandEstimate(
                source: .geometry2D,
                probabilities: feat2D.probs,
                pinchClosedness: pinchState.closedness,
                palm: feat2D.palm,
                palmVariance: 0.0018 / max(0.2, feat2D.quality),
                quality: q2,
                available: true,
                palmWidth: feat2D.palmWidth
            )

            let liftedPts = lifted.pts
            var e3 = Lift3D.estimate(pts: liftedPts, residual: lifted.residual, palmWidth: lifted.palmWidth)
            e3.palm = feat2D.palm

            var eDepth = HandEstimate.empty(.depth)
            if let depth {
                eDepth = depth.estimate(joints: smoothed, conf: obs.conf, space: space, palmWidth: feat2D.palmWidth)
            }

            let extArr: [CGFloat] = ["thumb", "index", "middle", "ring", "little"].map { feat2D.extensions[$0] ?? 0 }
            let vel = space.dist(slot.lastPalm, feat2D.palm) / CGFloat(dt)
            let tFeat = TemporalNet.features(
                ext: extArr,
                pinchRatio: feat2D.pinchRatio,
                thumbUp: feat2D.extensions["thumb"] ?? 0,
                palmVel: vel
            )
            var eT = slot.temporal.push(features: tFeat, now: now)
            eT.palm = feat2D.palm
            eT.palmWidth = feat2D.palmWidth
            eT.palmVariance = 0.006

            slot.fusion.temperature = fusionTemperature
            let (fused, dbg) = slot.fusion.fuse([e2, e3, eDepth, eT], dt: dt)
            let hmmOut = slot.hmm.step(
                emission: fused.probabilities,
                pinchClosedness: fused.pinchClosedness,
                now: now,
                dt: dt,
                quality: fused.quality
            )
            lastFusion = dbg

            var joints: [VNHumanHandPoseObservation.JointName: TrackedJoint] = [:]
            var display: [VNHumanHandPoseObservation.JointName: TrackedJoint] = [:]
            for (name, point) in smoothed {
                joints[name] = TrackedJoint(point: point, confidence: obs.conf[name] ?? 0, z: lifted.pts[name]?.z ?? 0)
            }
            for (name, point) in obs.raw {
                display[name] = TrackedJoint(point: point, confidence: obs.conf[name] ?? 0)
            }
            var ext: Set<String> = []
            for f in FingerKind.allCases {
                if (feat2D.extensions[f.rawValue] ?? 0) > 0.52 { ext.insert(f.rawValue) }
            }

            slot.chirality = obs.chirality
            slot.lastPalm = fused.palm
            let dt = slot.lastNow > 0 ? now - slot.lastNow : 0.04
            slot.lastSeen = now
            slot.lastNow = now
            slot.palmWidthEma = GestureMath.palmWidthEMA(prev: slot.palmWidthEma, next: fused.palmWidth, dt: dt)
            if let ti = assigned[idx], ti < tracks.count {
                tracks[ti] = slot
            } else {
                tracks.append(slot)
            }

            hands.append(
                TrackedHand(
                    id: slot.id,
                    chirality: obs.chirality,
                    joints: joints,
                    displayJoints: display,
                    pose: hmmOut.pose,
                    poseProb: hmmOut.prob,
                    pinchDistance: pinchState.distance,
                    pinchRatio: feat2D.pinchRatio,
                    pinchClosed: pinchState.closed,
                    pinchClosedness: pinchState.closedness,
                    palm: fused.palm,
                    palmWidth: slot.palmWidthEma,
                    openScore: feat2D.openScore,
                    extended: ext,
                    fusion: dbg,
                    quality: fused.quality,
                    sourceID: "",
                    indexScore: Double(feat2D.extensions["index"] ?? 0),
                    liftResidual: lifted.residual
                )
            )
        }
        tracks.removeAll { now - $0.lastSeen > 0.18 }
        for i in tracks.indices where now - tracks[i].lastSeen > 0.12 {
            tracks[i].pinch.reset()
        }
        lastHands = hands
        lastHandsAt = now
        return hands
    }

    private func assign(_ obs: [RawObs], space: AspectSpace, now: TimeInterval) -> [Int: Int] {
        var result: [Int: Int] = [:]
        let live = tracks.enumerated().filter { now - $0.element.lastSeen < 0.35 }
        if live.isEmpty || obs.isEmpty { return [:] }
        var usedT: Set<Int> = []
        var usedO: Set<Int> = []
        var pairs: [(o: Int, t: Int, d: CGFloat)] = []
        for (oi, o) in obs.enumerated() {
            for (ti, tr) in live {
                var d = space.dist(o.palm, tr.lastPalm)
                if o.chirality == tr.chirality { d -= 0.04 }
                pairs.append((oi, ti, d))
            }
        }
        for p in pairs.sorted(by: { $0.d < $1.d }) {
            if usedO.contains(p.o) || usedT.contains(p.t) { continue }
            if p.d > 0.42 { continue }
            result[p.o] = p.t
            usedO.insert(p.o)
            usedT.insert(p.t)
        }
        return result
    }

    private func forearmGate(
        palm: CGPoint,
        wrist: CGPoint?,
        chirality: VNChirality,
        body: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint],
        space: AspectSpace
    ) -> Double {
        guard let wrist else { return 1 }
        let elbowName: VNHumanBodyPoseObservation.JointName = chirality == .left ? .leftElbow : .rightElbow
        let wristName: VNHumanBodyPoseObservation.JointName = chirality == .left ? .leftWrist : .rightWrist
        guard let el = body[elbowName], el.confidence > 0.15,
              let bw = body[wristName], bw.confidence > 0.15
        else { return 1 }
        let e = CGPoint(x: el.location.x, y: el.location.y)
        let ww = CGPoint(x: bw.location.x, y: bw.location.y)
        let forearm = space.vec(e, ww)
        let handAx = space.vec(wrist, palm)
        let nf = hypot(forearm.x, forearm.y)
        let nh = hypot(handAx.x, handAx.y)
        guard nf > 1e-5, nh > 1e-5 else { return 1 }
        let cosv = (forearm.x * handAx.x + forearm.y * handAx.y) / (nf * nh)
        let ang = acos(max(-1, min(1, Double(cosv))))
        if ang > 1.05 { return 0.35 }
        if ang > 0.7 { return 0.7 }
        return 1
    }

    /// Körperpose stimmt L/R nur ab, wenn Vision unbekannt ist oder der Vote klar gewinnt.
    /// Sonst kippt ein schwacher Wrist-Treffer die Steuerhand und der Cursor springt.
    private func bodyChirality(
        palm: CGPoint,
        body: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint],
        vision: VNChirality
    ) -> VNChirality? {
        func pt(_ name: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
            guard let p = body[name], p.confidence > 0.20 else { return nil }
            return CGPoint(x: p.location.x, y: p.location.y)
        }
        guard let left = pt(.leftWrist), let right = pt(.rightWrist) else { return nil }
        let dl = hypot(palm.x - left.x, palm.y - left.y)
        let dr = hypot(palm.x - right.x, palm.y - right.y)
        let nearest = min(dl, dr)
        let farthest = max(dl, dr)
        guard farthest > 1e-4 else { return nil }
        let ratio = Double(nearest / farthest)
        let voted: VNChirality = dl < dr ? .left : .right
        let disagree = vision != .unknown && vision != voted
        guard GestureMath.bodyOverridesVision(
            visionUnknown: vision == .unknown,
            ratio: ratio,
            disagree: disagree
        ) else { return nil }
        return voted
    }
}

struct DepthSample {
    var map: CVPixelBuffer

    func estimate(
        joints: [VNHumanHandPoseObservation.JointName: CGPoint],
        conf: [VNHumanHandPoseObservation.JointName: Float],
        space: AspectSpace,
        palmWidth: CGFloat
    ) -> HandEstimate {
        var pts: [VNHumanHandPoseObservation.JointName: Joint3] = [:]
        var depths: [CGFloat] = []
        CVPixelBufferLockBaseAddress(map, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(map, .readOnly) }
        let mw = CVPixelBufferGetWidth(map)
        let mh = CVPixelBufferGetHeight(map)
        let bpr = CVPixelBufferGetBytesPerRow(map)
        guard let base = CVPixelBufferGetBaseAddress(map) else { return .empty(.depth) }
        let fmt = CVPixelBufferGetPixelFormatType(map)
        for (name, p) in joints {
            let px = min(mw - 1, max(0, Int(p.x * CGFloat(mw))))
            let py = min(mh - 1, max(0, Int((1 - p.y) * CGFloat(mh))))
            var z: Float = 0
            if fmt == kCVPixelFormatType_DepthFloat32 || fmt == kCVPixelFormatType_DisparityFloat32 {
                let row = base.advanced(by: py * bpr).assumingMemoryBound(to: Float.self)
                z = row[px]
            }
            if z.isFinite, z != 0 { depths.append(CGFloat(z)) }
            let iso = space.iso(p)
            pts[name] = Joint3(x: iso.x, y: iso.y, z: CGFloat(z), c: conf[name] ?? 0)
        }
        guard depths.count >= 4 else { return .empty(.depth) }
        let z0 = JointGeom.median(depths)
        for k in pts.keys { pts[k]?.z -= z0 }
        let lifted = Lift3D.estimate(pts: pts, residual: 0.12, palmWidth: palmWidth)
        return HandEstimate(
            source: .depth,
            probabilities: lifted.probabilities,
            pinchClosedness: lifted.pinchClosedness,
            palm: GestureClassifier.palmCenter(joints),
            palmVariance: 0.0009,
            quality: 0.85,
            available: true,
            palmWidth: palmWidth
        )
    }
}

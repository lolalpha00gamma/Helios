import CoreMedia
import CoreML
import CoreVideo
import Foundation
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

    func confidence(_ name: VNHumanHandPoseObservation.JointName) -> Float {
        (displayJoints[name] ?? joints[name])?.confidence ?? 0
    }
}

final class HandTracker: @unchecked Sendable {
    private let request: VNDetectHumanHandPoseRequest = {
        let r = VNDetectHumanHandPoseRequest()
        r.maximumHandCount = 2
        r.usesCPUOnly = false
        MetalHub.bindVision(r)
        return r
    }()

    private var leftSmooth = LandmarkSmoothing()
    private var rightSmooth = LandmarkSmoothing()
    private var leftPinch = PinchGate()
    private var rightPinch = PinchGate()
    private var poseHold: [Int: (pose: HandPose, n: Int)] = [:]
    private let lock = NSLock()

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        leftSmooth.reset()
        rightSmooth.reset()
        leftPinch.reset()
        rightPinch.reset()
        poseHold.removeAll()
    }

    func analyze(pixelBuffer: CVPixelBuffer, now: TimeInterval, mirrored: Bool = true) -> [TrackedHand] {
        lock.lock()
        defer { lock.unlock() }
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .up,
            options: [.ciContext: MetalHub.ci]
        )
        do {
            try handler.perform([request])
        } catch {
            return []
        }
        let observations = request.results ?? []
        if observations.isEmpty {
            leftSmooth.reset()
            rightSmooth.reset()
            return []
        }

        var hands: [TrackedHand] = []
        hands.reserveCapacity(observations.count)
        var claimed: Set<VNChirality> = []
        for (idx, obs) in observations.enumerated() {
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
            if chirality == .unknown {
                let wx = raw[.wrist]?.x ?? 0.5
                chirality = wx < 0.5 ? .left : .right
            }
            if mirrored {
                if chirality == .left { chirality = .right }
                else if chirality == .right { chirality = .left }
            }
            // Zwei Beobachtungen dürfen sich nicht denselben Smoother teilen.
            if chirality != .unknown, claimed.contains(chirality) {
                if chirality == .left, !claimed.contains(.right) {
                    chirality = .right
                } else if chirality == .right, !claimed.contains(.left) {
                    chirality = .left
                } else {
                    chirality = .unknown
                }
            }
            if chirality != .unknown {
                claimed.insert(chirality)
            }
            let useLeft = chirality == .left
            let useRight = chirality == .right
            var smoother = useLeft ? leftSmooth : (useRight ? rightSmooth : LandmarkSmoothing())
            let smoothed = smoother.apply(raw, now: now)
            if useLeft { leftSmooth = smoother }
            else if useRight { rightSmooth = smoother }

            var joints: [VNHumanHandPoseObservation.JointName: TrackedJoint] = [:]
            var display: [VNHumanHandPoseObservation.JointName: TrackedJoint] = [:]
            for (name, point) in smoothed {
                joints[name] = TrackedJoint(point: point, confidence: conf[name] ?? 0)
            }
            for (name, point) in raw {
                display[name] = TrackedJoint(point: point, confidence: conf[name] ?? 0)
            }
            var pinchGate = useLeft ? leftPinch : (useRight ? rightPinch : PinchGate())
            let pinchState = pinchGate.update(raw: raw, conf: conf, now: now)
            if useLeft { leftPinch = pinchGate }
            else if useRight { rightPinch = pinchGate }

            let pinch = pinchState.distance
            let palm = GestureClassifier.palmCenter(smoothed)
            var pose = GestureClassifier.classify(joints: smoothed, pinch: pinch)
            if pinchState.closed, pose != .openPalm, pose != .peace {
                pose = .pinch
            }
            pose = stabilize(pose, chirality: chirality)
            if pinchState.closed, pose == .fist || pose == .unknown || pose == .point {
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
                    id: chirality == .left ? "L" : (chirality == .right ? "R" : "U-\(idx)"),
                    chirality: chirality,
                    joints: joints,
                    displayJoints: display,
                    pose: pose,
                    pinchDistance: pinch,
                    pinchRatio: ratio,
                    pinchClosed: pinchState.closed,
                    palm: palm,
                    openScore: openScore,
                    extended: ext
                )
            )
        }
        if !hands.contains(where: { $0.chirality == .left }) {
            leftSmooth.reset()
            leftPinch.reset()
            poseHold[VNChirality.left.rawValue] = nil
        }
        if !hands.contains(where: { $0.chirality == .right }) {
            rightSmooth.reset()
            rightPinch.reset()
            poseHold[VNChirality.right.rawValue] = nil
        }
        return hands
    }

    /// Pose muss 2 Frames halten, sonst flackert Faust/Pinzette/Offen.
    private func stabilize(_ pose: HandPose, chirality: VNChirality) -> HandPose {
        let k = chirality.rawValue
        if pose == .unknown, let old = poseHold[k] { return old.pose }
        if var h = poseHold[k] {
            if h.pose == pose {
                h.n = min(8, h.n + 1)
                poseHold[k] = h
                return pose
            }
            h.n -= 1
            if h.n <= 0 {
                poseHold[k] = (pose, 2)
                return pose
            }
            poseHold[k] = h
            return h.pose
        }
        poseHold[k] = (pose, 2)
        return pose
    }
}

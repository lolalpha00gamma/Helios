import CoreMedia
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
    var palm: CGPoint
    var openScore: Int

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
        let map = Dictionary(uniqueKeysWithValues: joints.map { ($0.key, $0.value.point) })
        return GestureClassifier.isExtended(map, tip: finger.tip, pip: finger.pip, mcp: finger.mcp)
    }

    func confidence(_ name: VNHumanHandPoseObservation.JointName) -> Float {
        (displayJoints[name] ?? joints[name])?.confidence ?? 0
    }
}

final class HandTracker: @unchecked Sendable {
    private let request: VNDetectHumanHandPoseRequest = {
        let r = VNDetectHumanHandPoseRequest()
        r.maximumHandCount = 2
        return r
    }()

    private var leftSmooth = LandmarkSmoothing()
    private var rightSmooth = LandmarkSmoothing()

    func reset() {
        leftSmooth.reset()
        rightSmooth.reset()
    }

    func analyze(pixelBuffer: CVPixelBuffer, now: TimeInterval) -> [TrackedHand] {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
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
        for (idx, obs) in observations.enumerated() {
            guard let pts = try? obs.recognizedPoints(.all) else { continue }
            var raw: [VNHumanHandPoseObservation.JointName: CGPoint] = [:]
            var conf: [VNHumanHandPoseObservation.JointName: Float] = [:]
            for (name, p) in pts where p.confidence > 0.12 {
                raw[name] = CGPoint(x: p.location.x, y: p.location.y)
                conf[name] = p.confidence
            }
            guard raw.count >= 6 else { continue }

            var chirality = obs.chirality
            if chirality == .unknown {
                let wx = raw[.wrist]?.x ?? 0.5
                chirality = wx < 0.5 ? .left : .right
            }
            var smoother = chirality == .left ? leftSmooth : rightSmooth
            let smoothed = smoother.apply(raw, now: now)
            if chirality == .left { leftSmooth = smoother } else { rightSmooth = smoother }

            var joints: [VNHumanHandPoseObservation.JointName: TrackedJoint] = [:]
            var display: [VNHumanHandPoseObservation.JointName: TrackedJoint] = [:]
            for (name, point) in smoothed {
                joints[name] = TrackedJoint(point: point, confidence: conf[name] ?? 0)
            }
            for (name, point) in raw {
                display[name] = TrackedJoint(point: point, confidence: conf[name] ?? 0)
            }
            let pinchRaw = Self.distance(raw[.thumbTip], raw[.indexTip])
            let pinchSm = Self.distance(smoothed[.thumbTip], smoothed[.indexTip])
            let pinch = min(pinchRaw, pinchSm)
            let palm = smoothed[.wrist] ?? smoothed[.indexMCP] ?? raw[.wrist] ?? .zero
            let pose = GestureClassifier.classify(joints: smoothed, pinch: pinch)
            let openScore = GestureClassifier.openScore(joints: smoothed)
            let ratio = GestureClassifier.pinchRatio(joints: smoothed, pinch: pinch)
            hands.append(
                TrackedHand(
                    id: "\(chirality.rawValue)-\(idx)",
                    chirality: chirality,
                    joints: joints,
                    displayJoints: display,
                    pose: pose,
                    pinchDistance: pinch,
                    pinchRatio: ratio,
                    palm: palm,
                    openScore: openScore
                )
            )
        }
        if !hands.contains(where: { $0.chirality == .left }) { leftSmooth.reset() }
        if !hands.contains(where: { $0.chirality == .right }) { rightSmooth.reset() }
        return hands
    }

    private static func distance(_ a: CGPoint?, _ b: CGPoint?) -> CGFloat {
        guard let a, let b else { return 1 }
        let dx = a.x - b.x
        let dy = a.y - b.y
        return sqrt(dx * dx + dy * dy)
    }
}

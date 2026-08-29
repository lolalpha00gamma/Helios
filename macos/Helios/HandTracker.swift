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
    var pose: HandPose
    var pinchDistance: CGFloat
    var palm: CGPoint

    func point(_ name: VNHumanHandPoseObservation.JointName) -> CGPoint? {
        guard let j = joints[name], j.confidence > 0.35 else { return nil }
        return j.point
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
    private var busy = false
    private let lock = NSLock()

    func reset() {
        leftSmooth.reset()
        rightSmooth.reset()
    }

    func analyze(sampleBuffer: CMSampleBuffer) -> [TrackedHand]? {
        lock.lock()
        if busy {
            lock.unlock()
            return nil
        }
        busy = true
        lock.unlock()
        defer {
            lock.lock()
            busy = false
            lock.unlock()
        }

        guard let pb = CMSampleBufferGetImageBuffer(sampleBuffer) else { return [] }
        let handler = VNImageRequestHandler(cvPixelBuffer: pb, orientation: .up, options: [:])
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
            for (name, p) in pts where p.confidence > 0.25 {
                raw[name] = CGPoint(x: p.location.x, y: p.location.y)
                conf[name] = p.confidence
            }
            let chirality = obs.chirality
            var smoother = chirality == .left ? leftSmooth : rightSmooth
            let smoothed = smoother.apply(raw)
            if chirality == .left { leftSmooth = smoother } else { rightSmooth = smoother }

            var joints: [VNHumanHandPoseObservation.JointName: TrackedJoint] = [:]
            for (name, point) in smoothed {
                joints[name] = TrackedJoint(point: point, confidence: conf[name] ?? 0)
            }
            let pinch = Self.distance(smoothed[.thumbTip], smoothed[.indexTip])
            let palm = smoothed[.wrist] ?? smoothed[.indexMCP] ?? .zero
            let pose = GestureClassifier.classify(joints: smoothed, pinch: pinch)
            hands.append(
                TrackedHand(
                    id: "\(chirality.rawValue)-\(idx)",
                    chirality: chirality,
                    joints: joints,
                    pose: pose,
                    pinchDistance: pinch,
                    palm: palm
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

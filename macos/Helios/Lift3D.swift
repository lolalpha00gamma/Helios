import CoreGraphics
import Foundation
import Vision

/// Monokulares Lifting über feste Knochenlängen (MediaPipe/MANO-Verhältnisse).
/// z relativ zum Handgelenk, gleiche Skala wie isotrope x.
enum Lift3D {
    static let bones: [(VNHumanHandPoseObservation.JointName, VNHumanHandPoseObservation.JointName, CGFloat)] = [
        (.wrist, .indexMCP, 0.74),
        (.wrist, .middleMCP, 1.00),
        (.wrist, .ringMCP, 0.70),
        (.wrist, .littleMCP, 0.64),
        (.wrist, .thumbCMC, 0.38),
        (.thumbCMC, .thumbMP, 0.42),
        (.thumbMP, .thumbIP, 0.32),
        (.thumbIP, .thumbTip, 0.28),
        (.indexMCP, .indexPIP, 0.48),
        (.indexPIP, .indexDIP, 0.28),
        (.indexDIP, .indexTip, 0.22),
        (.middleMCP, .middlePIP, 0.53),
        (.middlePIP, .middleDIP, 0.31),
        (.middleDIP, .middleTip, 0.24),
        (.ringMCP, .ringPIP, 0.48),
        (.ringPIP, .ringDIP, 0.29),
        (.ringDIP, .ringTip, 0.22),
        (.littleMCP, .littlePIP, 0.38),
        (.littlePIP, .littleDIP, 0.23),
        (.littleDIP, .littleTip, 0.20)
    ]

    static func lift(
        joints: [VNHumanHandPoseObservation.JointName: CGPoint],
        conf: [VNHumanHandPoseObservation.JointName: Float],
        space: AspectSpace,
        previous: [VNHumanHandPoseObservation.JointName: CGFloat]
    ) -> (pts: [VNHumanHandPoseObservation.JointName: Joint3], residual: CGFloat, palmWidth: CGFloat) {
        let scale = GestureClassifier.palmScale(joints, space: space)
        var z: [VNHumanHandPoseObservation.JointName: CGFloat] = [.wrist: 0]
        var residual: CGFloat = 0
        var nRes = 0

        func signPrefer(
            parent: VNHumanHandPoseObservation.JointName,
            child: VNHumanHandPoseObservation.JointName,
            mag: CGFloat
        ) -> CGFloat {
            if let pz = previous[child], let pp = previous[parent] {
                let pred = pz - pp
                return pred >= 0 ? mag : -mag
            }
            let curlIn: Set<VNHumanHandPoseObservation.JointName> = [
                .indexPIP, .indexDIP, .indexTip,
                .middlePIP, .middleDIP, .middleTip,
                .ringPIP, .ringDIP, .ringTip,
                .littlePIP, .littleDIP, .littleTip
            ]
            return curlIn.contains(child) ? mag : -mag
        }

        for (parent, child, L0) in bones {
            guard let p = joints[parent], let c = joints[child] else { continue }
            let d = space.dist(p, c) / max(0.02, scale)
            let L = L0
            let mag = sqrt(max(0, L * L - d * d))
            let dz = signPrefer(parent: parent, child: child, mag: mag)
            let zp = z[parent] ?? 0
            z[child] = zp + dz
            let recon = hypot(d, dz)
            residual += abs(recon - L)
            nRes += 1
        }

        var out: [VNHumanHandPoseObservation.JointName: Joint3] = [:]
        for (name, p) in joints {
            let iso = space.iso(p)
            out[name] = Joint3(
                x: iso.x,
                y: iso.y,
                z: (z[name] ?? 0) * scale,
                c: conf[name] ?? 0
            )
        }
        let meanRes = nRes == 0 ? 1 : residual / CGFloat(nRes)
        return (out, meanRes, scale)
    }

    static func estimate(
        pts: [VNHumanHandPoseObservation.JointName: Joint3],
        residual: CGFloat,
        palmWidth: CGFloat
    ) -> HandEstimate {
        guard pts.count >= 8 else { return .empty(.lift3D) }
        let feats = GestureClassifier.features3D(pts, palmWidth: palmWidth)
        let quality = max(0.05, min(1, 1 - Double(residual) / 0.55)) * feats.quality
        return HandEstimate(
            source: .lift3D,
            probabilities: feats.probs,
            pinchClosedness: feats.pinchClosedness,
            palm: feats.palm,
            palmVariance: max(0.0006, palmWidth * palmWidth * 0.08 + CGFloat(residual) * 0.01),
            quality: quality,
            available: true,
            palmWidth: palmWidth
        )
    }
}

import CoreGraphics
import Foundation
import Vision

struct HandEstimate {
    var source: EstimateSource
    var probabilities: [HandPose: Double]
    var pinchClosedness: Double
    var palm: CGPoint
    var palmVariance: CGFloat
    var quality: Double
    var available: Bool
    var palmWidth: CGFloat

    static func empty(_ source: EstimateSource) -> HandEstimate {
        HandEstimate(
            source: source,
            probabilities: Dictionary(uniqueKeysWithValues: HandPose.allCases.map { ($0, 0) }),
            pinchClosedness: 0,
            palm: .zero,
            palmVariance: 1,
            quality: 0,
            available: false,
            palmWidth: 0.12
        )
    }

    var argmax: HandPose {
        probabilities.max(by: { $0.value < $1.value })?.key ?? .unknown
    }
}

enum EstimateSource: String, CaseIterable {
    case geometry2D
    case lift3D
    case temporal
    case depth

    var labelDE: String {
        switch self {
        case .geometry2D: return "2D"
        case .lift3D: return "3D-Lift"
        case .temporal: return "Zeit/KI"
        case .depth: return "Tiefe"
        }
    }
}

struct FusionDebug: Equatable {
    var weights: [String: Double]
    var quality: [String: Double]
    var deviation: [String: Double]
    var poseProb: Double
    var pinchClosedness: Double
    var usedDepth: Bool
    var collapsed: [String] = []
}

struct Joint3: Equatable {
    var x: CGFloat
    var y: CGFloat
    var z: CGFloat
    var c: Float

    var xy: CGPoint { CGPoint(x: x, y: y) }
}

import CoreGraphics
import Foundation

final class EstimateFusion {
    var base: [EstimateSource: Double] = [.geometry2D: 0.40, .lift3D: 0.28, .depth: 0.22, .temporal: 0.25]
    private var reliability: [EstimateSource: Double] = [.geometry2D: 1, .lift3D: 1, .depth: 1, .temporal: 1]
    private var errEMA: [EstimateSource: Double] = [:]
    private let minW: Double = 0.10
    func reset() {
        for s in EstimateSource.allCases { reliability[s] = 1; errEMA[s] = 0 }
    }
    func fuse(_ estimates: [HandEstimate], dt: TimeInterval) -> (HandEstimate, FusionDebug) {
        let live = estimates.filter(\.available)
        if live.isEmpty {
            return (.empty(.geometry2D), FusionDebug(weights: [:], quality: [:], deviation: [:], poseProb: 0, pinchClosedness: 0, usedDepth: false))
        }
        var rawW: [EstimateSource: Double] = [:]
        var qmap: [String: Double] = [:]
        for e in live {
            let b: Double = {
                if e.source == .lift3D, estimates.contains(where: { $0.source == .depth && $0.available }) { return 0.12 }
                return base[e.source] ?? 0.25
            }()
            rawW[e.source] = max(minW, b * (reliability[e.source] ?? 1) * max(0.02, e.quality))
            qmap[e.source.rawValue] = e.quality
        }
        let sumW = rawW.values.reduce(0, +)
        var w: [EstimateSource: Double] = [:]
        for (s, v) in rawW { w[s] = v / max(1e-9, sumW) }
        var logp: [HandPose: Double] = [:]
        for pose in HandPose.allCases {
            var acc = 0.0
            for e in live {
                let p = max(1e-6, min(1 - 1e-6, e.probabilities[pose] ?? 1e-6))
                acc += (w[e.source] ?? 0) * log(p)
            }
            logp[pose] = acc
        }
        let keys = HandPose.allCases
        let sm = JointGeom.softmax(keys.map { logp[$0] ?? -20 }, temperature: 1)
        var probs: [HandPose: Double] = [:]
        for (i, k) in keys.enumerated() { probs[k] = sm[i] }
        func scalar(_ pick: (HandEstimate) -> Double, _ varPick: (HandEstimate) -> Double) -> Double {
            var num = 0.0, den = 0.0
            for e in live {
                let v = max(1e-8, varPick(e))
                num += pick(e) / v
                den += 1 / v
            }
            return den > 0 ? num / den : 0
        }
        let pinch = scalar(\.pinchClosedness, { max(0.02, 1 - $0.quality) })
        let palmX = scalar({ Double($0.palm.x) }, { Double(max(0.0004, $0.palmVariance)) })
        let palmY = scalar({ Double($0.palm.y) }, { Double(max(0.0004, $0.palmVariance)) })
        let palmW = scalar({ Double($0.palmWidth) }, { Double(max(0.0004, $0.palmVariance)) })
        let restVar = 1 / live.map { 1 / max(0.0004, Double($0.palmVariance)) }.reduce(0, +)
        let fused = HandEstimate(source: .geometry2D, probabilities: probs, pinchClosedness: max(0, min(1, pinch)), palm: CGPoint(x: palmX, y: palmY), palmVariance: CGFloat(restVar), quality: live.map(\.quality).reduce(0, +) / Double(live.count), available: true, palmWidth: CGFloat(max(0.02, palmW)))
        var dev: [String: Double] = [:]
        let winner = fused.argmax
        let alpha = 1 - exp(-dt / 5.0)
        for e in live {
            let d = 1 - (e.probabilities[winner] ?? 0)
            dev[e.source.rawValue] = d
            let ema = (errEMA[e.source] ?? d) * (1 - alpha) + d * alpha
            errEMA[e.source] = ema
            reliability[e.source] = max(minW, min(1.4, 1.0 / max(0.25, 0.35 + ema)))
        }
        let dbg = FusionDebug(weights: Dictionary(uniqueKeysWithValues: w.map { ($0.key.rawValue, $0.value) }), quality: qmap, deviation: dev, poseProb: probs[winner] ?? 0, pinchClosedness: fused.pinchClosedness, usedDepth: live.contains { $0.source == .depth })
        return (fused, dbg)
    }
}

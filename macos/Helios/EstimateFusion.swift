import CoreGraphics
import Foundation

/// Gewichtetes log-Meinungspooling für Klassen, inverse Varianz für Skalare.
/// Adaptive Gewichte aus gleitender Abweichung vom Fusionsergebnis.
/// Korrelierte Quellen (Lift/Zeit kopieren 2D) werden kollabiert, sonst
/// flacht Softmax ab und das 62-%-Aktions-Tor blockt jede Geste.
final class EstimateFusion {
    var base: [EstimateSource: Double] = [
        .geometry2D: 0.62,
        .lift3D: 0.14,
        .depth: 0.32,
        .temporal: 0.16
    ]
    private var reliability: [EstimateSource: Double] = [
        .geometry2D: 1, .lift3D: 1, .depth: 1, .temporal: 1
    ]
    private var errEMA: [EstimateSource: Double] = [:]
    private let minW: Double = 0.02
    var temperature: Double = 0.75

    func reset() {
        for s in EstimateSource.allCases {
            reliability[s] = 1
            errEMA[s] = 0
        }
    }

    func fuse(_ estimates: [HandEstimate], dt: TimeInterval) -> (HandEstimate, FusionDebug) {
        let live = estimates.filter(\.available)
        if live.isEmpty {
            return (
                .empty(.geometry2D),
                FusionDebug(weights: [:], quality: [:], deviation: [:], poseProb: 0, pinchClosedness: 0, usedDepth: false, collapsed: [])
            )
        }

        let e2 = live.first { $0.source == .geometry2D }
        let hasDepth = estimates.contains { $0.source == .depth && $0.available }
        var collapsed: [String] = []
        var rawW: [EstimateSource: Double] = [:]
        var qmap: [String: Double] = [:]
        for e in live {
            let b: Double = {
                switch e.source {
                case .lift3D: return hasDepth ? 0.06 : (base[.lift3D] ?? 0.14)
                default: return base[e.source] ?? 0.20
                }
            }()
            var corr = 1.0
            if (e.source == .lift3D || e.source == .temporal), let e2 {
                if overlap(e, e2) > 0.80 {
                    corr = 0.22
                    collapsed.append(e.source.rawValue)
                }
            }
            let r = reliability[e.source] ?? 1
            rawW[e.source] = max(minW, b * r * max(0.02, e.quality) * corr)
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
        let logits = keys.map { logp[$0] ?? -20 }
        let sm = JointGeom.softmax(logits, temperature: max(0.35, min(1.4, temperature)))
        var probs: [HandPose: Double] = [:]
        for (i, k) in keys.enumerated() { probs[k] = sm[i] }

        func scalar(_ pick: (HandEstimate) -> Double, _ varPick: (HandEstimate) -> Double) -> Double {
            var num = 0.0
            var den = 0.0
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

        var qFused = 0.0
        var qDen = 0.0
        for e in live {
            let ww = w[e.source] ?? 0
            qFused += e.quality * ww
            qDen += ww
        }

        let fused = HandEstimate(
            source: .geometry2D,
            probabilities: probs,
            pinchClosedness: max(0, min(1, pinch)),
            palm: CGPoint(x: palmX, y: palmY),
            palmVariance: CGFloat(restVar),
            quality: qDen > 0 ? qFused / qDen : live.map(\.quality).reduce(0, +) / Double(live.count),
            available: true,
            palmWidth: CGFloat(max(0.02, palmW))
        )

        var dev: [String: Double] = [:]
        let winner = fused.argmax
        let alpha = 1 - exp(-dt / 5.0)
        for e in live {
            let d = 1 - (e.probabilities[winner] ?? 0)
            dev[e.source.rawValue] = d
            let prev = errEMA[e.source] ?? d
            let ema = prev * (1 - alpha) + d * alpha
            errEMA[e.source] = ema
            let rel = max(minW, min(1.4, 1.0 / max(0.25, 0.35 + ema)))
            reliability[e.source] = rel
        }

        let dbg = FusionDebug(
            weights: Dictionary(uniqueKeysWithValues: w.map { ($0.key.rawValue, $0.value) }),
            quality: qmap,
            deviation: dev,
            poseProb: probs[winner] ?? 0,
            pinchClosedness: fused.pinchClosedness,
            usedDepth: hasDepth,
            collapsed: collapsed
        )
        return (fused, dbg)
    }

    private func overlap(_ a: HandEstimate, _ b: HandEstimate) -> Double {
        var acc = 0.0
        for pose in HandPose.allCases {
            acc += min(a.probabilities[pose] ?? 0, b.probabilities[pose] ?? 0)
        }
        return acc
    }
}

import Foundation

/// Vorwärtsfilter über 7 Posen. Zeitkonstanten in Sekunden, nicht Frames.
struct PoseHMM {
    private var logP: [HandPose: Double]
    private var holdSince: TimeInterval?
    private var current: HandPose = .unknown
    private var pinch: Double = 0
    private var lastRealProb: Double = 0

    init() {
        let n = Double(HandPose.allCases.count)
        logP = Dictionary(uniqueKeysWithValues: HandPose.allCases.map { ($0, log(1 / n)) })
    }

    mutating func reset() {
        let n = Double(HandPose.allCases.count)
        logP = Dictionary(uniqueKeysWithValues: HandPose.allCases.map { ($0, log(1 / n)) })
        holdSince = nil
        current = .unknown
        pinch = 0
        lastRealProb = 0
    }

    mutating func step(
        emission: [HandPose: Double],
        pinchClosedness: Double,
        now: TimeInterval,
        dt: TimeInterval
    ) -> (pose: HandPose, prob: Double, pinch: Double) {
        let tauStay: Double = 0.11
        let pStay = exp(-dt / tauStay)
        let pLeave = 1 - pStay
        var next: [HandPose: Double] = [:]
        for j in HandPose.allCases {
            var acc = -1e9
            for i in HandPose.allCases {
                let trans = i == j ? log(max(1e-9, pStay + pLeave * 0.15)) : log(max(1e-9, pLeave * affinity(i, j)))
                acc = logSumExp(acc, (logP[i] ?? -20) + trans)
            }
            let e = max(1e-6, emission[j] ?? 1e-6)
            next[j] = acc + log(e)
        }
        let m = next.values.max() ?? 0
        var norm = 0.0
        for k in next.keys {
            next[k] = exp((next[k] ?? -20) - m)
            norm += next[k] ?? 0
        }
        for k in next.keys { next[k] = (next[k] ?? 0) / max(1e-12, norm) }
        logP = Dictionary(uniqueKeysWithValues: next.map { ($0.key, log(max(1e-12, $0.value))) })

        let best = next.max(by: { $0.value < $1.value }) ?? (.unknown, 0)
        let pinchTau = 0.07
        let a = 1 - exp(-dt / pinchTau)
        pinch = pinch * (1 - a) + pinchClosedness * a

        // Unknown darf eine echte Pose nicht unter das Aktions-Tor drücken.
        // next[current] ist verdünnt — perform() blockte sonst bei gehaltenem unknown.
        if best.key == .unknown, current != .unknown {
            holdSince = nil
            let held = lastRealProb > 0.40 ? lastRealProb : max(next[current] ?? 0, 0.62)
            return (current, held, pinch)
        }

        if best.key != current {
            if holdSince == nil { holdSince = now }
            if now - (holdSince ?? now) >= 0.05, best.value >= 0.48 {
                current = best.key
                holdSince = nil
            }
        } else {
            holdSince = nil
            if best.value >= 0.50 { current = best.key }
        }
        let pCur = next[current] ?? best.value
        if current != .unknown {
            lastRealProb = pCur
        }
        return (current, pCur, pinch)
    }

    private func affinity(_ a: HandPose, _ b: HandPose) -> Double {
        if a == b { return 1 }
        if b == .unknown { return 0.05 }
        if a == .unknown { return 0.22 }
        let close: Set<[HandPose]> = [
            [.pinch, .fist], [.fist, .pinch],
            [.pinch, .point], [.point, .pinch],
            [.point, .peace], [.peace, .point],
            [.openPalm, .peace], [.peace, .openPalm],
            [.fist, .thumbsUp], [.thumbsUp, .fist]
        ]
        if close.contains([a, b]) { return 0.28 }
        return 0.08
    }

    private func logSumExp(_ a: Double, _ b: Double) -> Double {
        let m = max(a, b)
        if m < -1e8 { return -1e9 }
        return m + log(exp(a - m) + exp(b - m))
    }
}

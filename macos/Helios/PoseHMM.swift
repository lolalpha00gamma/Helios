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

    /// 24 fps bleibt 50 ms (~3 Frames). 8 fps: 2 Frames, sonst Flicker jeden Tick.
    static func switchHold(dt: TimeInterval) -> TimeInterval {
        max(0.05, min(0.22, max(0.008, dt) * 0.95))
    }

    /// Pinch-EMA. 45 ms bei 60 fps, ~90 ms bei 8 fps — sonst ist α ≈ 0,94 (kein Glätten).
    static func pinchTau(dt: TimeInterval) -> TimeInterval {
        max(0.045, min(0.12, max(0.008, dt) * 0.70))
    }

    mutating func step(
        emission: [HandPose: Double],
        pinchClosedness: Double,
        now: TimeInterval,
        dt: TimeInterval,
        quality: Double = 1,
        pinchHeld: Bool = false
    ) -> (pose: HandPose, prob: Double, pinch: Double) {
        var emission = Self.qualityScale(emission, quality: quality)
        if pinchHeld {
            emission = Self.pinchHoldBoost(emission)
        }
        let tauStay: Double = pinchHeld ? 0.11 : 0.07
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
        let pinchTau = Self.pinchTau(dt: dt)
        let a = 1 - exp(-dt / pinchTau)
        pinch = pinch * (1 - a) + pinchClosedness * a

        if pinchHeld, current == .pinch || best.key == .pinch {
            current = .pinch
            holdSince = nil
            lastRealProb = max(lastRealProb, next[.pinch] ?? 0.62)
            return (.pinch, max(0.62, next[.pinch] ?? lastRealProb), pinch)
        }

        if best.key == .unknown, current != .unknown {
            if current == .pinch, pinch < 0.40 {
                holdSince = nil
            } else {
                holdSince = nil
                let held = max(0.62, lastRealProb > 0.40 ? lastRealProb : (next[current] ?? 0.62))
                return (current, held, pinch)
            }
        }

        let holdNeed = Self.switchHold(dt: dt)
        if best.key != current {
            if holdSince == nil { holdSince = now }
            if now - (holdSince ?? now) >= holdNeed, best.value >= 0.48 {
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

    static func pinchHoldBoost(_ emission: [HandPose: Double]) -> [HandPose: Double] {
        var out = emission
        let pinch = max(emission[.pinch] ?? 0, 0.55)
        out[.pinch] = pinch
        var sum = 0.0
        for p in HandPose.allCases {
            if p != .pinch { out[p] = (out[p] ?? 0) * 0.55 }
            sum += out[p] ?? 0
        }
        guard sum > 1e-12 else { return emission }
        for k in out.keys { out[k] = (out[k] ?? 0) / sum }
        return out
    }

    static func qualityScale(_ emission: [HandPose: Double], quality: Double) -> [HandPose: Double] {
        let q = max(0, min(1, quality))
        if q >= 0.55 { return emission }
        let n = Double(max(1, HandPose.allCases.count))
        let uni = 1 / n
        let w = q / 0.55
        var out: [HandPose: Double] = [:]
        var sum = 0.0
        for p in HandPose.allCases {
            let v = (emission[p] ?? uni) * w + uni * (1 - w)
            out[p] = v
            sum += v
        }
        guard sum > 1e-12 else { return emission }
        for k in out.keys { out[k] = (out[k] ?? 0) / sum }
        return out
    }

    private func affinity(_ a: HandPose, _ b: HandPose) -> Double {
        if a == b { return 1 }
        if b == .unknown { return 0.05 }
        if a == .unknown { return 0.22 }
        switch (a, b) {
        case (.pinch, .fist), (.fist, .pinch),
             (.pinch, .point), (.point, .pinch),
             (.point, .peace), (.peace, .point),
             (.openPalm, .peace), (.peace, .openPalm),
             (.fist, .thumbsUp), (.thumbsUp, .fist):
            return 0.28
        default:
            return 0.08
        }
    }

    private func logSumExp(_ a: Double, _ b: Double) -> Double {
        let m = max(a, b)
        if m < -1e8 { return -1e9 }
        return m + log(exp(a - m) + exp(b - m))
    }
}

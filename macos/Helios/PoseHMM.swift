import Foundation

/// Vorwärtsfilter über 7 Posen. Zeitkonstanten in Sekunden, nicht Frames.
/// Übergänge sind normiert (Summe 1). Schnelle Palme dämpft Pinch —
/// eine Wischbewegung ist keine Pinzette.
struct PoseHMM {
    private var logP: [HandPose: Double]
    private var holdSince: TimeInterval?
    private var current: HandPose = .unknown
    private var pinch: Double = 0

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
    }

    mutating func step(
        emission rawEmission: [HandPose: Double],
        pinchClosedness: Double,
        now: TimeInterval,
        dt: TimeInterval,
        palmSpeed: Double = 0
    ) -> (pose: HandPose, prob: Double, pinch: Double) {
        var emission = rawEmission
        // Velocity-Prior: schnelle Faust/Wisch ist kein Pinch.
        if palmSpeed > 2.2 {
            let p = emission[.pinch] ?? 0
            emission[.pinch] = p * 0.32
            emission[.openPalm] = (emission[.openPalm] ?? 0) + p * 0.28
            emission[.point] = (emission[.point] ?? 0) + p * 0.12
        }

        let tauStay: Double = 0.11
        let pStay = exp(-dt / tauStay)
        let pLeave = 1 - pStay
        var next: [HandPose: Double] = [:]
        for j in HandPose.allCases {
            var acc = -1e9
            for i in HandPose.allCases {
                let trans = log(max(1e-9, transition(from: i, to: j, pStay: pStay, pLeave: pLeave)))
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
        let pinchTau = pinchClosedness > 0.7 || pinchClosedness < 0.25 ? 0.04 : 0.07
        let a = 1 - exp(-dt / pinchTau)
        pinch = pinch * (1 - a) + pinchClosedness * a

        if best.key != current {
            if holdSince == nil { holdSince = now }
            let instant = best.value >= 0.72 && (
                best.key == .pinch || best.key == .fist || best.key == .openPalm
            )
            let need: TimeInterval = instant ? 0.018 : 0.038
            if now - (holdSince ?? now) >= need, best.value >= 0.44 {
                current = best.key
                holdSince = nil
            }
        } else {
            holdSince = nil
            if best.value >= 0.46 { current = best.key }
        }
        // Gate bekommt max(committed, best): sonst blockt perform() bei 62 %,
        // während der HMM noch die sterbende Vor-Pose hält.
        let pCur = next[current] ?? best.value
        let pGate = max(pCur, best.value)
        return (current, pGate, pinch)
    }

    private func transition(from i: HandPose, to j: HandPose, pStay: Double, pLeave: Double) -> Double {
        if i == j { return pStay }
        var mass = 0.0
        for k in HandPose.allCases where k != i {
            mass += affinity(i, k)
        }
        let w = affinity(i, j) / max(1e-9, mass)
        return pLeave * w
    }

    private func affinity(_ a: HandPose, _ b: HandPose) -> Double {
        if a == b { return 1 }
        if a == .unknown || b == .unknown { return 0.28 }
        let pairs: Set<String> = [
            "pinch|fist", "fist|pinch",
            "pinch|point", "point|pinch",
            "point|peace", "peace|point",
            "openPalm|peace", "peace|openPalm",
            "fist|thumbsUp", "thumbsUp|fist"
        ]
        if pairs.contains("\(a.rawValue)|\(b.rawValue)") { return 0.28 }
        return 0.08
    }

    private func logSumExp(_ a: Double, _ b: Double) -> Double {
        let m = max(a, b)
        if m < -1e8 { return -1e9 }
        return m + log(exp(a - m) + exp(b - m))
    }
}

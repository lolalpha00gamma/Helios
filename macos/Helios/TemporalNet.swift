import CoreGraphics
import CoreML
import Foundation
import Vision

final class TemporalNet {
    private var history: [[Double]] = []
    private let window = 12
    private var model: MLModel?
    private var skip = 0
    private var last: HandEstimate = .empty(.temporal)
    init() {
        if let url = Bundle.main.url(forResource: "HeliosTemporal", withExtension: "mlmodelc") ?? Bundle.main.url(forResource: "HeliosTemporal", withExtension: "mlmodel") {
            let cfg = MLModelConfiguration(); cfg.computeUnits = .all
            model = try? MLModel(contentsOf: url, configuration: cfg)
        }
    }
    func reset() { history.removeAll(); last = .empty(.temporal); skip = 0 }
    func push(features: [Double], now _: TimeInterval) -> HandEstimate {
        history.append(features)
        if history.count > window { history.removeFirst(history.count - window) }
        guard history.count >= 6 else { last = .empty(.temporal); return last }
        skip += 1
        if skip % 2 == 0, last.available { return last }
        if let model, let fromML = inferML(model) { last = fromML; return last }
        last = inferHeuristic()
        return last
    }
    private func inferHeuristic() -> HandEstimate {
        let lastF = history.last ?? []
        let first = history[max(0, history.count - 6)]
        func at(_ i: Int, _ arr: [Double]) -> Double { i < arr.count ? arr[i] : 0 }
        let ext = (0..<5).map { at($0, lastF) }
        let pinch = at(5, lastF)
        let thumbY = at(6, lastF)
        let hold = zip(ext, (0..<5).map { at($0, first) }).map { abs($0 - $1) }.reduce(0, +) < 0.45 && abs(pinch - at(5, first)) < 0.18
        var logits: [HandPose: Double] = [
            .fist: (1 - ext.dropFirst().reduce(0, +) / 4) * 3.2 + (1 - pinch) * 0.4,
            .openPalm: ext.dropFirst().reduce(0, +) * 1.4,
            .pinch: (1 - pinch) * 4.2 + ext[1] * 0.6 - ext[2] * 0.8,
            .point: ext[1] * 3.2 - ext[2] * 2.4 - ext[3] * 1.6,
            .peace: ext[1] * 2.2 + ext[2] * 2.2 - ext[3] * 2.4 - ext[4] * 2.0,
            .thumbsUp: ext[0] * 2.8 + thumbY * 2.4 - ext.dropFirst().reduce(0, +),
            .unknown: 0.15
        ]
        if hold { for k in logits.keys { logits[k, default: 0] *= 1.15 } }
        let keys = HandPose.allCases
        let sm = JointGeom.softmax(keys.map { logits[$0] ?? 0 }, temperature: 0.7)
        var probs: [HandPose: Double] = [:]
        for (i, k) in keys.enumerated() { probs[k] = sm[i] }
        return HandEstimate(source: .temporal, probabilities: probs, pinchClosedness: max(0, min(1, 1 - pinch)), palm: .zero, palmVariance: 0.008, quality: hold ? 0.62 : 0.42, available: true, palmWidth: 0.12)
    }
    private func inferML(_ model: MLModel) -> HandEstimate? {
        let feat = history.flatMap { $0 }
        guard let arr = try? MLMultiArray(shape: [1, NSNumber(value: feat.count)], dataType: .double) else { return nil }
        for (i, v) in feat.enumerated() { arr[i] = NSNumber(value: v) }
        guard let out = try? model.prediction(from: MLDictionaryFeatureProvider(dictionary: ["input": arr])), let scores = out.featureValue(for: "output")?.multiArrayValue else { return nil }
        var logits: [Double] = []
        let n = min(HandPose.allCases.count, scores.count)
        for i in 0..<n { logits.append(scores[i].doubleValue) }
        while logits.count < HandPose.allCases.count { logits.append(0) }
        let sm = JointGeom.softmax(logits, temperature: 1)
        var probs: [HandPose: Double] = [:]
        for (i, k) in HandPose.allCases.enumerated() { probs[k] = sm[i] }
        return HandEstimate(source: .temporal, probabilities: probs, pinchClosedness: probs[.pinch] ?? 0, palm: .zero, palmVariance: 0.006, quality: Double(sm.max() ?? 0), available: true, palmWidth: 0.12)
    }
    static func features(ext: [CGFloat], pinchRatio: CGFloat, thumbUp: CGFloat, palmVel: CGFloat) -> [Double] {
        var f = ext.prefix(5).map { Double($0) }
        while f.count < 5 { f.append(0) }
        f.append(Double(pinchRatio)); f.append(Double(thumbUp)); f.append(Double(palmVel))
        return f
    }
}

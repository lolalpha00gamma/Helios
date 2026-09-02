import SwiftUI

struct FusionStrip: View {
    var fusion: FusionDebug?
    var hasDepth: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("FUSION")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(HeliosTheme.cyan)
                Spacer()
                Text(hasDepth ? "Tiefe an" : "nur Lift")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(hasDepth ? HeliosTheme.ok : .secondary)
            }
            if let fusion {
                Text(String(format: "Pose %.0f %%  ·  Pinzette %.0f %%  ·  H %.2f  ·  Tor %.0f %%", fusion.poseProb * 100, fusion.pinchClosedness * 100, fusion.entropy, GestureMath.entropyActionFloor(entropy: fusion.entropy) * 100))
                    .font(.system(size: 11, design: .monospaced))
                if !fusion.collapsed.isEmpty {
                    Text("kollabiert: " + fusion.collapsed.joined(separator: ", "))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(HeliosTheme.amber)
                }
                ForEach(fusion.weights.keys.sorted(), id: \.self) { k in
                    HStack(spacing: 8) {
                        Text(k)
                            .font(.system(size: 10, design: .monospaced))
                            .frame(width: 72, alignment: .leading)
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Rectangle().fill(Color.white.opacity(0.08))
                                Rectangle()
                                    .fill(HeliosTheme.cyan.opacity(0.85))
                                    .frame(width: g.size.width * CGFloat(fusion.weights[k] ?? 0))
                            }
                        }
                        .frame(height: 5)
                        Text(String(format: "%.0f", (fusion.weights[k] ?? 0) * 100))
                            .font(.system(size: 10, design: .monospaced))
                            .frame(width: 28, alignment: .trailing)
                    }
                }
            } else {
                Text("Keine Schätzung")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.04))
        .overlay(Rectangle().stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

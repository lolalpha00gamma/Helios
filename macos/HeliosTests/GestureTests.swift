import CoreGraphics
import Foundation

/// Standalone: `swift macos/HeliosTests/GestureTests.swift`
/// Spiegelt GestureClassifier-Schwellen: Faust vs. offen vs. Pinzette.

func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
    hypot(a.x - b.x, a.y - b.y)
}

func isExtended(tip: CGPoint, pip: CGPoint, mcp: CGPoint, wrist: CGPoint, slack: CGFloat = 0.008) -> Bool {
    let tipD = dist(tip, wrist)
    let pipD = dist(pip, wrist)
    let mcpD = dist(mcp, wrist)
    return tipD > pipD + slack && pipD > mcpD * 0.86
}

var fails = 0
func ok(_ cond: Bool, _ msg: String) {
    if !cond {
        fputs("FAIL \(msg)\n", stderr)
        fails += 1
    }
}

let wrist = CGPoint(x: 0.5, y: 0.2)
let mcp = CGPoint(x: 0.5, y: 0.35)

// Faust: Spitzen nah am MCP
let fistTip = CGPoint(x: 0.5, y: 0.33)
ok(!isExtended(tip: fistTip, pip: CGPoint(x: 0.5, y: 0.36), mcp: mcp, wrist: wrist), "Faust nicht gestreckt")

// Offen: Spitze weit vom Handgelenk
let openTip = CGPoint(x: 0.5, y: 0.72)
let openPip = CGPoint(x: 0.5, y: 0.55)
ok(isExtended(tip: openTip, pip: openPip, mcp: mcp, wrist: wrist), "offener Finger gestreckt")

// Pinzetten-Abstand relativ zur Handfläche
let scale = dist(wrist, mcp)
ok(scale > 0.04, "Handflächen-Maß")
let pinch = dist(CGPoint(x: 0.48, y: 0.50), CGPoint(x: 0.50, y: 0.50))
ok(pinch / scale < 0.45, "Pinzette nah")

if fails > 0 {
    fputs("\(fails) GestureTests fehlgeschlagen\n", stderr)
    exit(1)
}
print("GestureTests OK")

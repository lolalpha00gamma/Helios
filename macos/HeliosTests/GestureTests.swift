import CoreGraphics
import Foundation
import Vision

// Wird gegen die echte Quelle gebaut:
//   cat macos/Helios/GestureClassifier.swift macos/HeliosTests/GestureTests.swift > g.swift && swift g.swift
// GestureClassifier darf hier NICHT nachgebaut werden.

typealias JN = VNHumanHandPoseObservation.JointName

var fails = 0

func ok(_ cond: Bool, _ msg: String) {
    if !cond {
        fputs("FAIL \(msg)\n", stderr)
        fails += 1
    }
}

let wrist = CGPoint(x: 0.5, y: 0.20)

/// Vier Finger nebeneinander; gestreckt zeigen sie nach oben (Vision-y wächst nach oben),
/// gekrümmt liegen die Spitzen wieder nahe am Handgelenk.
func finger(_ x: CGFloat, extended: Bool) -> (mcp: CGPoint, pip: CGPoint, dip: CGPoint, tip: CGPoint) {
    let mcp = CGPoint(x: x, y: 0.35)
    if extended {
        return (mcp, CGPoint(x: x, y: 0.50), CGPoint(x: x, y: 0.60), CGPoint(x: x, y: 0.68))
    }
    return (mcp, CGPoint(x: x, y: 0.40), CGPoint(x: x, y: 0.36), CGPoint(x: x, y: 0.30))
}

func makeHand(
    index: Bool,
    middle: Bool,
    ring: Bool,
    little: Bool,
    thumbTip: CGPoint
) -> [JN: CGPoint] {
    let i = finger(0.44, extended: index)
    let m = finger(0.50, extended: middle)
    let r = finger(0.56, extended: ring)
    let l = finger(0.62, extended: little)
    return [
        .wrist: wrist,
        .thumbCMC: CGPoint(x: 0.44, y: 0.24),
        .thumbMP: CGPoint(x: 0.42, y: 0.27),
        .thumbIP: CGPoint(x: 0.43, y: 0.30),
        .thumbTip: thumbTip,
        .indexMCP: i.mcp, .indexPIP: i.pip, .indexDIP: i.dip, .indexTip: i.tip,
        .middleMCP: m.mcp, .middlePIP: m.pip, .middleDIP: m.dip, .middleTip: m.tip,
        .ringMCP: r.mcp, .ringPIP: r.pip, .ringDIP: r.dip, .ringTip: r.tip,
        .littleMCP: l.mcp, .littlePIP: l.pip, .littleDIP: l.dip, .littleTip: l.tip
    ]
}

func pinchDistance(_ j: [JN: CGPoint]) -> CGFloat {
    guard let t = j[.thumbTip], let i = j[.indexTip] else { return 1 }
    return hypot(t.x - i.x, t.y - i.y)
}

func classify(_ j: [JN: CGPoint]) -> HandPose {
    GestureClassifier.classify(joints: j, pinch: pinchDistance(j))
}

// --- isExtended: die Grundlage aller Posen
let curled = finger(0.44, extended: false)
ok(
    !GestureClassifier.isExtended(
        [.wrist: wrist, .indexTip: curled.tip, .indexPIP: curled.pip, .indexMCP: curled.mcp],
        tip: .indexTip, pip: .indexPIP, mcp: .indexMCP
    ),
    "gekrümmter Finger gilt nicht als gestreckt"
)
let straight = finger(0.44, extended: true)
ok(
    GestureClassifier.isExtended(
        [.wrist: wrist, .indexTip: straight.tip, .indexPIP: straight.pip, .indexMCP: straight.mcp],
        tip: .indexTip, pip: .indexPIP, mcp: .indexMCP
    ),
    "gestreckter Finger gilt als gestreckt"
)
// Fehlende Gelenke dürfen niemals "gestreckt" ergeben.
ok(
    !GestureClassifier.isExtended(
        [.wrist: wrist], tip: .indexTip, pip: .indexPIP, mcp: .indexMCP
    ),
    "fehlende Gelenke sind nicht gestreckt"
)

// --- Handflächenmaß und Pinzettenverhältnis
let openHand = makeHand(index: true, middle: true, ring: true, little: true,
                        thumbTip: CGPoint(x: 0.32, y: 0.34))
ok(abs(GestureClassifier.palmScale(openHand) - 0.15) < 0.001, "Handflächenmaß Wurzel→MittelMCP")
ok(GestureClassifier.openScore(joints: openHand) == 4, "offene Hand zählt 4 Finger")

// --- Posen
ok(classify(openHand) == .openPalm, "offene Hand → Offene Hand")

let fist = makeHand(index: false, middle: false, ring: false, little: false,
                    thumbTip: CGPoint(x: 0.45, y: 0.30))
ok(GestureClassifier.openScore(joints: fist) == 0, "Faust zählt 0 Finger")
ok(classify(fist) == .fist, "Faust → Faust")

let pinch = makeHand(index: true, middle: false, ring: false, little: false,
                     thumbTip: CGPoint(x: 0.46, y: 0.66))
ok(classify(pinch) == .pinch, "Daumen an Zeigespitze → Pinzette")
ok(
    GestureClassifier.pinchRatio(joints: pinch, pinch: pinchDistance(pinch)) < 0.45,
    "Pinzettenverhältnis unter der Schwelle"
)

let peace = makeHand(index: true, middle: true, ring: false, little: false,
                     thumbTip: CGPoint(x: 0.32, y: 0.34))
ok(classify(peace) == .peace, "Zeige + Mittel → Zwei Finger")

let point = makeHand(index: true, middle: false, ring: false, little: false,
                     thumbTip: CGPoint(x: 0.32, y: 0.34))
ok(classify(point) == .point, "nur Zeigefinger → Zeigen")

// Eine Faust darf nicht als Pinzette durchgehen — sonst klickt sie.
ok(classify(fist) != .pinch, "Faust ist keine Pinzette")

// --- Handflächenmittelpunkt liegt zwischen den MCPs
let palm = GestureClassifier.palmCenter(openHand)
ok(abs(palm.y - 0.35) < 0.001, "Handflächenmitte auf MCP-Höhe")
ok(palm.x > 0.44 && palm.x < 0.62, "Handflächenmitte zwischen den MCPs")

if fails > 0 {
    fputs("\(fails) GestureTests fehlgeschlagen\n", stderr)
    exit(1)
}
print("GestureTests OK")

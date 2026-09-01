import CoreGraphics
import Foundation

// Wird gegen die echte Quelle gebaut:
//   cat macos/Helios/CoordMath.swift macos/HeliosTests/CoordTests.swift > coord.swift && swift coord.swift
// CoordMath darf hier NICHT noch einmal definiert werden — eine Kopie würde
// nur sich selbst prüfen und könnte eine Regression im App-Code nie sehen.

var fails = 0

func eq(_ a: CGFloat, _ b: CGFloat, _ msg: String) {
    if abs(a - b) > 0.001 {
        fputs("FAIL \(msg): \(a) != \(b)\n", stderr)
        fails += 1
    }
}

func pointEq(_ a: CGPoint, _ b: CGPoint, _ msg: String) {
    eq(a.x, b.x, msg + " x")
    eq(a.y, b.y, msg + " y")
}

let primaryH: CGFloat = 1080

// Cocoa-Ursprung unten links am Hauptbildschirm → Quartz oben links.
pointEq(
    CoordMath.quartz(fromCocoa: CGPoint(x: 10, y: 1080), primaryMaxY: primaryH),
    CGPoint(x: 10, y: 0),
    "oben Hauptbildschirm"
)
pointEq(
    CoordMath.quartz(fromCocoa: CGPoint(x: 10, y: 0), primaryMaxY: primaryH),
    CGPoint(x: 10, y: 1080),
    "unten Hauptbildschirm"
)

// Monitor über dem Hauptschirm: Cocoa-y > primaryH → Quartz-y negativ.
// Genau hier lag der Fehler, als die Union statt des Hauptbildschirms zählte.
pointEq(
    CoordMath.quartz(fromCocoa: CGPoint(x: 100, y: 1080 + 400), primaryMaxY: primaryH),
    CGPoint(x: 100, y: -400),
    "Schirm oben"
)

// Monitor links vom Hauptschirm: x bleibt negativ, y unberührt.
pointEq(
    CoordMath.quartz(fromCocoa: CGPoint(x: -1920, y: 1080), primaryMaxY: primaryH),
    CGPoint(x: -1920, y: 0),
    "Schirm links"
)

// Roundtrip Punkt.
let p = CGPoint(x: -200, y: 500)
let q = CoordMath.quartz(fromCocoa: p, primaryMaxY: primaryH)
pointEq(CoordMath.cocoa(fromQuartz: q, primaryMaxY: primaryH), p, "Roundtrip Punkt")

// Rechteck: Quartz-y misst die Oberkante von oben.
let cocoaWin = CGRect(x: 100, y: 200, width: 800, height: 600)
let quartzWin = CoordMath.quartzRect(fromCocoa: cocoaWin, primaryMaxY: primaryH)
eq(quartzWin.origin.x, 100, "rect x")
eq(quartzWin.origin.y, primaryH - 200 - 600, "rect y oben links")
eq(quartzWin.height, 600, "rect h")

let back = CoordMath.cocoaRect(fromQuartz: quartzWin, primaryMaxY: primaryH)
eq(back.origin.x, cocoaWin.origin.x, "rect roundtrip x")
eq(back.origin.y, cocoaWin.origin.y, "rect roundtrip y")
eq(back.width, cocoaWin.width, "rect roundtrip w")
eq(back.height, cocoaWin.height, "rect roundtrip h")

// cocoaRect ist eine Involution — zweimal angewandt kommt das Original zurück.
let twice = CoordMath.cocoaRect(
    fromQuartz: CoordMath.cocoaRect(fromQuartz: cocoaWin, primaryMaxY: primaryH),
    primaryMaxY: primaryH
)
eq(twice.origin.y, cocoaWin.origin.y, "Involution y")

// Ein Fenster, das oben am Hauptbildschirm klebt, hat Quartz-y 0.
let topWindow = CGRect(x: 0, y: primaryH - 300, width: 500, height: 300)
eq(
    CoordMath.quartzRect(fromCocoa: topWindow, primaryMaxY: primaryH).origin.y,
    0,
    "Fenster oben bündig"
)

if fails > 0 {
    fputs("\(fails) CoordTests fehlgeschlagen\n", stderr)
    exit(1)
}
print("CoordTests OK")

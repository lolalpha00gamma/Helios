# Helios Review 1.5.124 — 2026-09-06

Stand: **1.5.123 Build 143**. Kein Merge von `bugfix` (1.5.8). Nur `main`.

## Warum Overlay und Cursor schlecht sitzen

Helios ist ein Zeiger aus drei Uhren und zwei Geometrien:

- Continuity oft 8 fps (125 ms).
- displayTick ~90 Hz Fill.
- Vision Observation-first (groesster Blob = S1).
- SpaceMap Homographie vs destEdge aus CGDisplayBounds.
- Cocoa-frame vs Quartz, 16–40 px Overlap Laptop+5K.

Seit 1.5.100 ist fast jeder Patch ein neuer Schalter gegen denselben Riss: Prop wird S1, Crop frisst die echte Hand, destEdgeNearest nimmt den Laptop im Overlap, Hold stirbt vor dem naechsten Kamera-Frame, Predict/Blend ziehen nach dem Cross zurueck.

1.5.123 hat die akuten Hebel (Prop nie S1, Pool Hand zuerst, min-Interior zu groesserem Schirm, destEdgeScreenHolds 160 ms, visQuartz). Das heilt nicht:

1. Observation-order von Vision bleibt. Scale-Gate 0,28 zittert bei 8 fps um die Schwelle.
2. Timer.common statt CADisplayLink. Fill driftet gegen ProMotion.
3. Eine Homographie fuer Laptop+5K. Kissen + Seam = RMS.
4. CGWarp ohne NSEvent.mouseLocation-Reanchor. Drift waechst.
5. GestureTests > 180 kB, CoordMath ~168 kB. Kein Split, kein Latency-HUD.
6. Zweite App Aegis oeffnet eine zweite Kamera-Session, zweite TCC, zweiter Buffer.

## Logik / Ineffizienz (offen)

- palmScale hart 0,035…0,28 statt Filter. Continuity um 0,28 flippt Prop/Hand jedes zweite Frame.
- destEdgeSkipHold an frameDt gekoppelt, kein Pref im Panel.
- Pad nicht per Display-UUID persistiert. Clamshell vs Studio wechselt den Dämpfer.
- Predict und 1-Euro parallel. Nach Cross tot, sonst Overshoot.
- Overlay an Kamera-Rate. 8 fps Skelett, 90 Hz Cursor — Overlay luegt.
- AX-Fokus per Poll statt kAXFocusedUIElementChanged.

Bugfix-Skill: drei volle saubere Paesse ueber CoordMath+GestureEngine+HandTracker ohne macOS-Build waeren geratene Flags. Das war 1.5.100–1.5.123. Naechster Schritt ist Struktur, nicht 1.5.124-Schalter ohne XCTest auf der Maschine.

## Erweiterung (neu oben auf der Liste)

- CADisplayLink / CVDisplayLink, Target 120 Hz.
- Shared XPC `helios.aegis.camera` — eine TCC, ein Buffer, 0-Grad-Geometrie mit Aegis.
- VNDetectHumanBodyPose als Prop-Veto, palmScale Kalman.
- destEdgeSkip Pref 40–240 ms, destEdgePad Pref je Display-UUID.
- Fill-Cap Laptop vs 5K getrennt von Warp-Cap.
- Kalman-Zeiger 2D statt 1-Euro + Predict.
- NSEvent.mouseLocation Ground-Truth 4 Hz, RMS > 8 px Reanchor.
- Overlay CAMetalLayer unabhaengig von der Kamera.
- SpaceMap Auto-Recalib RMS > 24 px / 2 s, eine Karte je Display-UUID.
- Two-mode Pointer: Desk absolut, 0,8 s Dwell relativ.
- 6-Punkt-Kalib gegen Kissen.
- Dead-Man: Touch/Optic ID, Leertaste 0,4 s, Faust-Timeout Pref 2–8 s (aus bugfix 1.5.8, nicht mergen).
- Fling-Fenster Pref und Wischen-nur-offen Pref aus bugfix 1.5.8.
- maximumHandCount 2 + Joint-Group statt Observation-first.
- Latency-HUD Tick zu AX-move, ueber 40 ms Gain halb.
- Tests splitten (GestureTests).
- AX kAXFocusedUIElementChanged statt Poll.
- IOHID Event-Tap statt CGEvent-Post.
- Low-Power: Vision 12 fps Cap.

Shared XPC mit Aegis bleibt der groesste einzelne Effizienzgewinn.

Nur main.

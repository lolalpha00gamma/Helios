# Helios Vorschläge — 2026-09-09 (Pass 36, 1.6.87)

Stand 1.6.87. analogClosed ist Gate, nicht Hold. Faust analog ≥ 0,58 gibt Zug frei.

## Gelandet in 1.6.87

- pinchHoldOk: analogClosed ignoriert, Hold oder Schnabel
- driveGrab Hold = pinchHoldOk (analogClosed bleibt Gate in pinchStartsGrab/pinchHoldsGrab)

## Erweiterung (neu)

507. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
508. **HeliosAegisKit** SPM, Mutex einmal.
509. **VNTrackObjectRequest.** P1.
510. **VNImageRequestHandler(cvPixelBuffer:).**
511. **Per-Finger-Kontakt** statt Skalar.
512. **analogClosed Start härter.** analog 0,58 + pinchLooksLikePinch startet ohne Vision-Gate.
513. **Ampel-Ring Overlay** vor fireChrome.
514. **Rechtsklick-HUD** 0,32 s.
515. **Tap-Cancel** offene Palme 200 ms.
516. **Click-Ring Overlay** 80 ms vor Fire.
517. **Hand-ID über uniqueID-Flicker.**
518. **CGEventSource-State** Steal.
519. **Desk-View Crop-Kompensation.**
520. **IOHIDEventSystemClient** Pointer.
521. **Watch Double-Tap.**
522. **MediaPipe Hands Fallback.**
523. **Overlay CAMetalLayer.**
524. **LiDAR DepthCapture.**
525. **Continuity 15-fps Probe.**
526. **Mission-Control Spread.**
527. **Aegis-Gaze Pinch-Confirm.**
528. **Palm-UV Highpass** vor Gain.
529. **HUD-Coast** bei Sample-Dropout.
530. **flingFromTrail** statt nur Vel-Tail.
531. **ChiralityLock** bei ID-Flicker.
532. **Gesture-Macro** 2-Schritt.
533. **Chrome-Dwell nur focused AX.**
534. **SpaceMap nur als Start, nicht als Delta-Quelle.**
535. **CGEvent tapHold** statt move+click.
536. **emptyHandsRecover** nach Dropout.
537. **pinch3DVeto** Depth vor 2D.
538. **axHitCacheFresh** AX nicht jedes Tick.

P0: CameraBroker. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.

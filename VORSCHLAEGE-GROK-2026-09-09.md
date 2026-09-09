# Helios Vorschläge — 2026-09-09 (Pass 35, 1.6.86)

Stand 1.6.86. Relativer Zeiger, One-Euro, pinchTap, Achse/Follow, 2HAND-Clutch, Freeze-Hitch.

## Gelandet in 1.6.86

- Relativer Zeiger Gain × Dt × Adaptive, Recenter-Clutch
- One-Euro + Totzone + Ecken-Rest + Deadman STILL
- pinchTapWouldClick neben isClick
- twoPinchAxisHolds + pinchFollowID
- twoHandClutchOn blockt Delta (HUD 2HAND)
- clickHitchFromFreeze in fireTapClick + driveRightClick

## Erweiterung (neu)

471. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
472. **HeliosAegisKit** SPM, Mutex einmal.
473. **VNTrackObjectRequest.** P1.
474. **VNImageRequestHandler(cvPixelBuffer:).**
475. **Per-Finger-Kontakt** statt Skalar.
476. **Ampel-Ring Overlay** vor fireChrome.
477. **Rechtsklick-HUD** 0,32 s.
478. **Tap-Cancel** offene Palme 200 ms.
479. **Click-Ring Overlay** 80 ms vor Fire.
480. **Hand-ID über uniqueID-Flicker.**
481. **CGEventSource-State** Steal.
482. **Desk-View Crop-Kompensation.**
483. **IOHIDEventSystemClient** Pointer.
484. **Watch Double-Tap.**
485. **MediaPipe Hands Fallback.**
486. **Overlay CAMetalLayer.**
487. **LiDAR DepthCapture.**
488. **Continuity 15-fps Probe.**
489. **Mission-Control Spread.**
490. **Aegis-Gaze Pinch-Confirm.**
491. **Per-Display pointerGain.**
492. **Bezel Homographie Blend 200 ms.**
493. **Gesture-Macro** 2-Schritt.
494. **Chrome-Dwell nur focused AX.**
495. **Palm-UV Highpass** vor Gain.
496. **HUD-Coast** bei Sample-Dropout.
497. **flingFromTrail** statt nur Vel-Tail.
498. **ChiralityLock** bei ID-Flicker.
499. **bezelHopRecalib** Chip live.
500. **pointerGain Continuity vs Built-in.**
501. **CGEvent tapHold** statt move+click.
502. **emptyHandsRecover** nach Dropout.
503. **stageManagerClamp** vor CGEvent.
504. **clutchIgnores** Retina-Echo.
505. **pinch3DVeto** Depth vor 2D.
506. **axHitCacheFresh** AX nicht jedes Tick.

P0: CameraBroker. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.

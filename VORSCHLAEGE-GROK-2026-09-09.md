# Helios Vorschläge — 2026-09-09 (Pass 37, 1.6.88)

Stand 1.6.88. palmHighpass / HUD-Coast / flingFromTrail / chiralityLock live.

## Gelandet in 1.6.88

- palmHighpassAlpha vor Gain (palmSlow LP der Screen-Deltas)
- hudCoastPoint nach t=1 (Cap scaled)
- flingFromTrail Fallback nach Vel-Tail
- chiralityLock am TrackSlot bei Dropout

## Erweiterung (neu)

539. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
540. **HeliosAegisKit** SPM, Mutex einmal.
541. **VNTrackObjectRequest.** P1.
542. **VNImageRequestHandler(cvPixelBuffer:).**
543. **Per-Finger-Kontakt** statt Skalar.
544. **analogClosed Start härter.** analog 0,58 + pinchLooksLikePinch.
545. **Ampel-Ring Overlay** vor fireChrome.
546. **Rechtsklick-HUD** 0,32 s.
547. **Tap-Cancel** offene Palme 200 ms.
548. **Click-Ring Overlay** 80 ms vor Fire.
549. **CGEventSource-State** Steal.
550. **Desk-View Crop-Kompensation.**
551. **IOHIDEventSystemClient** Pointer.
552. **Watch Double-Tap.**
553. **MediaPipe Hands Fallback.**
554. **Overlay CAMetalLayer.**
555. **LiDAR DepthCapture.**
556. **Continuity 15-fps Probe.**
557. **Mission-Control Spread.**
558. **Aegis-Gaze Pinch-Confirm.**
559. **Gesture-Macro** 2-Schritt.
560. **Chrome-Dwell nur focused AX.**
561. **SpaceMap nur als Start.**
562. **CGEvent tapHold** statt move+click.
563. **axHitCacheFresh** AX nicht jedes Tick.
564. **emptyHandsRecover** extra Cap.
565. **HUD-Coast Vel EMA.**
566. **ChiralityLock + Palm-UV** bei doppeltem Flicker.
567. **Bezel-Hop Homographie Blend** 200 ms.
568. **Per-Display pointerGain Pref.**

P0: CameraBroker. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.

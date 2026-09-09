# Helios Vorschläge — 2026-09-09 (Pass 38, 1.6.89)

Stand 1.6.89. Highpass nach Clutch. HUD-Coast am Sample-Dropout.

## Gelandet in 1.6.89

- palmHighpassDelta nach Clutch (DC trainiert LP nicht während STILL)
- HUD-Coast wenn now > next.at vom Sample
- Tests + MARKETING 1.6.89 (Build 122)

## Erweiterung (neu)

574. **CameraBroker XPC + IOSurface** mit Aegis. P0.
575. **HeliosAegisKit.**
576. **VNTrackObjectRequest.** P1.
577. **VNImageRequestHandler(cvPixelBuffer:).**
578. **Per-Finger-Kontakt.**
579. **analogClosed Start härter.**
580. **HUD-Lerp zwischen Samples.**
581. **palmHighpass auf UV-Position.**
582. **Ampel-Ring Overlay.**
583. **Rechtsklick-HUD.**
584. **Tap-Cancel.**
585. **Click-Ring Overlay.**
586. **Hand-ID uniqueID-Flicker.**
587. **CGEventSource-State.**
588. **Desk-View Crop.**
589. **IOHIDEventSystemClient.**
590. **Watch Double-Tap.**
591. **MediaPipe Hands.**
592. **Overlay CAMetalLayer.**
593. **LiDAR.**
594. **Continuity 15-fps Probe.**
595. **Mission-Control Spread.**
596. **Two-pointer origin lock.**
597. **Pinch-Hysterese palmWidth.**
598. **Gesture-Macro.**
599. **SpaceMap nur als Start.**
600. **CGEvent tapHold.**
601. **pinch3DVeto.**
602. **axHitCacheFresh.**
603. **Per-Display pointerGain.**
604. **Bezel-Hop Blend.**

P0: CameraBroker. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.

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

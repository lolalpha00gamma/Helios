# Helios Vorschläge — 2026-09-09 (Pass 33, 1.6.84)

Stand 1.6.84. pinchStartsGrab live, Idle-Arm, Stamp-TTL 250 ms, Interrupt-Beat tot.

## Gelandet in 1.6.84

- driveGrab Start = pinchStartsGrab (Reach/Index oder Schnabel)
- Hold = pinchHoldsGrab, Faust nur Zug
- Idle-Arm nicht mehr Meter 0,24
- cameraMutexStampFresh 250 ms
- cameraMutexBeatAllowed: Interrupt schreibt keinen Stamp/Claim

## Erweiterung (neu)

425. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
426. **HeliosAegisKit** SPM, Mutex einmal.
427. **VNTrackObjectRequest.** P1.
428. **VNImageRequestHandler(cvPixelBuffer:).**
429. **Per-Finger-Kontakt** statt Skalar.
430. **Tap-Cancel** offene Palme 200 ms.
431. **Click-Ring Overlay** 80 ms vor Fire.
432. **Hand-ID über uniqueID-Flicker.**
433. **CGEventSource-State** Steal.
434. **Desk-View Crop-Kompensation.**
435. **IOHIDEventSystemClient** Pointer.
436. **Watch Double-Tap.**
437. **MediaPipe Hands Fallback.**
438. **Overlay CAMetalLayer.**
439. **LiDAR DepthCapture.**
440. **Continuity 15-fps Probe.**
441. **Mission-Control Spread.**
442. **Aegis-Gaze Pinch-Confirm.**
443. **Per-Display pointerGain.**
444. **Bezel Homographie Blend 200 ms.**
445. **Gesture-Macro** 2-Schritt.

P0: CameraBroker. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.

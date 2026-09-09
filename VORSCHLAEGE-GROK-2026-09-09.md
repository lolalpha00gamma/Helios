# Helios Vorschläge — 2026-09-09 (Pass 34, 1.6.85)

Stand 1.6.85. isClick live, Ampel fireChrome, Rechtsklick vor Grab, Scroll-Coast nach Streak.

## Gelandet in 1.6.85

- isClick vor fireTapClick (Halt/Palm/Cursor/Energy)
- chromeHotKnob + chromeDwellFires → fireChrome, kein Desktop-Durchklick
- driveRightClick vor driveGrab, Zählfenster return true
- twoPinchScrollCoastTicks vor Streak-Reset

## Erweiterung (neu)

446. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
447. **HeliosAegisKit** SPM, Mutex einmal.
448. **VNTrackObjectRequest.** P1.
449. **VNImageRequestHandler(cvPixelBuffer:).**
450. **Per-Finger-Kontakt** statt Skalar.
451. **pinchTapWouldClick live** zweite Sequenz-Gate.
452. **Ampel-Ring Overlay** vor fireChrome.
453. **Rechtsklick-HUD** 0,32 s.
454. **Tap-Cancel** offene Palme 200 ms.
455. **Click-Ring Overlay** 80 ms vor Fire.
456. **Hand-ID über uniqueID-Flicker.**
457. **CGEventSource-State** Steal.
458. **Desk-View Crop-Kompensation.**
459. **IOHIDEventSystemClient** Pointer.
460. **Watch Double-Tap.**
461. **MediaPipe Hands Fallback.**
462. **Overlay CAMetalLayer.**
463. **LiDAR DepthCapture.**
464. **Continuity 15-fps Probe.**
465. **Mission-Control Spread.**
466. **Aegis-Gaze Pinch-Confirm.**
467. **Per-Display pointerGain.**
468. **Bezel Homographie Blend 200 ms.**
469. **Gesture-Macro** 2-Schritt.
470. **Chrome-Dwell nur focused AX.**

P0: CameraBroker. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.

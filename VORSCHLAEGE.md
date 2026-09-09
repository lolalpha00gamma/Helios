# Helios — Vorschlagsliste

Stand: **1.6.88**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes. Nur `main`. `bugfix` ist Altlast — nicht anlegen, nicht mergen.

## In 1.6.88 erledigt

1.6.87 pinchHoldOk. palmHighpass / hudCoast / flingFromTrail / chiralityLock tot trotz Tests. palmSlow nie gelesen.

1. **palmHighpassAlpha vor Gain.** palmSlow = LP der Screen-Deltas.
2. **hudCoastPoint** nach HUD t=1. Cap scaled.
3. **flingFromTrail Fallback** nach Vel-Tail.
4. **chiralityLock** am TrackSlot bei Dropout.
5. Tests + MARKETING_VERSION 1.6.88 (Build 121).

## Erweiterung (neu, 1.6.88)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
2. **HeliosAegisKit** SPM: Mutex-Protokoll einmal.
3. **VNTrackObjectRequest** echte Hand-Observation statt IoU-Box.
4. **VNImageRequestHandler(cvPixelBuffer:)** — 420f nicht über CGImage.
5. **Per-Finger-Kontakt** statt Skalar-Closedness.
6. **analogClosed Start härter.** analog 0,58 + pinchLooksLikePinch startet ohne Vision-Gate.
7. **Ampel-Ring Overlay** 80 ms vor fireChrome.
8. **Rechtsklick-HUD** während 0,32 s Ring-Halt.
9. **Tap-Cancel** offene Palme 200 ms bricht pending Hold.
10. **Click-Ring Overlay** 80 ms vor Fire.
11. **CGEventSource-State** OS-Maus-Steal schneller als Clutch-Radius.
12. **Continuity Desk-View Crop-Kompensation.**
13. **IOHIDEventSystemClient** Pointer statt CGEvent.
14. **Watch Double-Tap** destruktive Klicks.
15. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
16. **Overlay CAMetalLayer.**
17. **DepthCapture an Continuity-LiDAR.**
18. **Continuity 15-fps Probe** gemessen.
19. **Mission-Control Zwei-Palm-Spread.**
20. **Aegis-Gaze Pinch-Confirm.**
21. **Per-Display pointerGain Pref.**
22. **Bezel-Hop Homographie Blend** 200 ms.
23. **Gesture-Macro** 2-Schritt.
24. **Chrome-Dwell nur auf focused AX.**
25. **SpaceMap nur als Start, nicht als Delta-Quelle.**
26. **CGEvent tapHold** statt move+click.
27. **axHitCacheFresh** AX nicht jedes Tick.
28. **emptyHandsRecover** als extra Cap neben recoverLive.
29. **HUD-Coast Vel EMA** statt raw prev→next.
30. **ChiralityLock + Palm-UV** wenn uniqueID und Chirality gleichzeitig kippen.

P0: CameraBroker. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.

# Helios — Vorschlagsliste

Stand: **1.6.87**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes. Nur `main`. `bugfix` ist Altlast — nicht anlegen, nicht mergen.

## In 1.6.87 erledigt

1.6.86 relativer Zeiger/One-Euro/pinchTap. Faust analog ≥ 0,58 hielt Zug: `holdOk || analogClosed`.

1. **pinchHoldOk.** analogClosed ist Gate, nicht Hold.
2. **driveGrab Hold = pinchHoldOk.** Faust ohne Reach/allowFist gibt frei.
3. Tests + MARKETING_VERSION 1.6.87 (Build 120).

## Erweiterung (neu, 1.6.87)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
2. **HeliosAegisKit** SPM: Mutex-Protokoll einmal.
3. **VNTrackObjectRequest** echte Hand-Observation statt IoU-Box.
4. **VNImageRequestHandler(cvPixelBuffer:)** — 420f nicht über CGImage.
5. **Per-Finger-Kontakt** statt Skalar-Closedness.
6. **analogClosed Start härter.** analog 0,58 + pinchLooksLikePinch startet ohne Vision-Gate — Reach/Index optional härter.
7. **Ampel-Ring Overlay** 80 ms vor fireChrome.
8. **Rechtsklick-HUD** während 0,32 s Ring-Halt.
9. **Tap-Cancel** offene Palme 200 ms bricht pending Hold.
10. **Click-Ring Overlay** 80 ms vor Fire.
11. **Hand-ID über uniqueID-Flicker** Chirality + Palm-UV, nicht Slot.
12. **CGEventSource-State** OS-Maus-Steal schneller als Clutch-Radius.
13. **Continuity Desk-View Crop-Kompensation.**
14. **IOHIDEventSystemClient** Pointer statt CGEvent.
15. **Watch Double-Tap** destruktive Klicks.
16. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
17. **Overlay CAMetalLayer.**
18. **DepthCapture an Continuity-LiDAR.**
19. **Continuity 15-fps Probe** gemessen.
20. **Mission-Control Zwei-Palm-Spread.**
21. **Aegis-Gaze Pinch-Confirm.**
22. **Per-Display pointerGain Pref.**
23. **Bezel-Hop Homographie Blend** 200 ms.
24. **Palm-UV Highpass** vor Gain, 8-Hz-Bias tot.
25. **HUD-Coast** wenn Sample ausfällt statt Freeze-Kalman.
26. **flingFromTrail** statt nur Vel-Tail.
27. **ChiralityLock** bei ID-Flicker.
28. **Gesture-Macro** 2-Schritt.
29. **Chrome-Dwell nur auf focused AX.**
30. **SpaceMap nur als Start, nicht als Delta-Quelle.**

P0: CameraBroker. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.

# Helios — Vorschlagsliste

Stand: **1.6.86**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes. Nur `main`. `bugfix` ist Altlast — nicht anlegen, nicht mergen.

## In 1.6.86 erledigt

1.6.85 isClick/Ampel/Rechtsklick/Coast. Gain/One-Euro/Deadman/pinchTap tot in mappedPoint. twoHandClutchOn Flag ohne Delta. Freeze-Hitch tot hinter force:true.

1. **Relativer Zeiger** Gain × Dt × Adaptive. Recenter = Clutch.
2. **One-Euro + Totzone + Ecken-Rest + Deadman STILL.**
3. **pinchTapWouldClick** Sequenz neben isClick.
4. **twoPinchAxisHolds + pinchFollowID.**
5. **twoHandClutchOn blockt Delta** (2HAND).
6. **clickHitchFromFreeze** in fireTapClick + driveRightClick.
7. Tests + MARKETING_VERSION 1.6.86 (Build 119).

## Erweiterung (neu, 1.6.86)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
2. **HeliosAegisKit** SPM: Mutex-Protokoll einmal.
3. **VNTrackObjectRequest** echte Hand-Observation statt IoU-Box.
4. **VNImageRequestHandler(cvPixelBuffer:)** — 420f nicht über CGImage.
5. **Per-Finger-Kontakt** statt Skalar-Closedness.
6. **Ampel-Ring Overlay** 80 ms vor fireChrome.
7. **Rechtsklick-HUD** während 0,32 s Ring-Halt.
8. **Tap-Cancel** offene Palme 200 ms bricht pending Hold.
9. **Click-Ring Overlay** 80 ms vor Fire.
10. **Hand-ID über uniqueID-Flicker** Chirality + Palm-UV, nicht Slot.
11. **CGEventSource-State** OS-Maus-Steal schneller als Clutch-Radius.
12. **Continuity Desk-View Crop-Kompensation.**
13. **IOHIDEventSystemClient** Pointer statt CGEvent.
14. **Watch Double-Tap** destruktive Klicks.
15. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
16. **Overlay CAMetalLayer.**
17. **DepthCapture an Continuity-LiDAR.**
18. **Continuity 15-fps Probe** gemessen.
19. **Mission-Control Zwei-Palm-Spread.**
20. **Aegis-Gaze Pinch-Confirm.**
21. **Per-Display pointerGain Pref.**
22. **Bezel-Hop Homographie Blend** 200 ms.
23. **FramePump Vision-Cancel Token.**
24. **Air-Keyboard Shortcut-Overlay.**
25. **JSONL Palm-Vel** für späteres Predict (bleibt 0 bis gemessen).
26. **iPhone Ultraweit FOV.**
27. **Gesture-Macro** 2-Schritt.
28. **Scroll-Coast Sign-Hold** nach Achsenwechsel kein Rest-Momentum.
29. **Chrome-Dwell nur auf focused AX.**
30. **SpaceMap nur als Start, nicht als Delta-Quelle** — Kalibrierung als Bias.
31. **Palm-UV Highpass** (`palmHighpassAlpha`) vor Gain, 8-Hz-Bias tot.
32. **HUD-Coast** `hudCoastPoint` wenn Sample ausfällt statt Freeze-Kalman.
33. **Fling-Trail** `flingFromTrail` statt nur Vel-Tail — Wurf aus 8 Hz zu kurz.
34. **ChiralityLock** bei uniqueID-Flicker, nicht nur pinchFollowID.
35. **Bezel-Hop Recalib-Chip** live nach 20 Hops (`bezelHopRecalib`).
36. **pointerGain je Continuity vs Built-in** — 8 Hz Default höher.
37. **CGEvent tapHold** statt move+click Races mit System-Maus.
38. **emptyHandsRecover** Gain nach Dropout statt Sprung.
39. **stageManagerClamp** live vor CGEvent, nicht nur Tests.
40. **clutchIgnores** Echo der eigenen CGEvents auf Retina.
41. **pinch3DVeto** Depth-Sep vor 2D-Closedness.
42. **axHitCacheFresh** AX-Hit nicht jedes 8-Hz-Tick.

P0: CameraBroker. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.

# Helios — Vorschlagsliste

Stand: **1.6.85**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes. Nur `main`. `bugfix` ist Altlast — nicht anlegen, nicht mergen.

## In 1.6.85 erledigt

1.6.84 pinchStartsGrab. isClick tot, Ampel tot, Rechtsklick tot, Scroll-Coast nach Jitter.

1. **isClick vor fireTapClick.**
2. **Ampel chromeHotKnob + chromeDwellFires → fireChrome.**
3. **driveRightClick vor driveGrab**, Zählfenster blockt Grab.
4. **twoPinchScrollCoastTicks** vor Streak-Reset.
5. Tests + MARKETING_VERSION 1.6.85 (Build 118).

## Erweiterung (neu, 1.6.85)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
2. **HeliosAegisKit** SPM: Mutex-Protokoll einmal, nicht Copy-Paste CoordMath/MatchMath.
3. **VNTrackObjectRequest** echte Hand-Observation statt IoU-Box zwischen 8-Hz-Detect.
4. **VNImageRequestHandler(cvPixelBuffer:)** — 420f nicht über CGImage.
5. **Per-Finger-Kontakt** statt Skalar-Closedness (Daumen-Index Distanz + Finger-Curl).
6. **pinchTapWouldClick live** als zweite Sequenz-Gate neben isClick (zu→auf über 2 Frames).
7. **Ampel-Ring Overlay** 80 ms vor fireChrome, gleicher Click-Ring wie Tap.
8. **Rechtsklick-HUD** während 0,32 s Ring-Halt (Chip „R-Klick …“).
9. **Tap-Cancel** offene Palme 200 ms bricht pending Hold vor Fire.
10. **Click-Ring Overlay** 80 ms vor Fire, damit man den Tap sieht.
11. **Hand-ID über uniqueID-Flicker** Chirality + Palm-UV, nicht Slot.
12. **CGEventSource-State** OS-Maus-Steal schneller als Clutch-Radius.
13. **Continuity Desk-View Crop-Kompensation** (zweite Cam, andere Homographie).
14. **IOHIDEventSystemClient** Pointer statt CGEvent (weniger Hitch).
15. **Watch Double-Tap** destruktive Klicks.
16. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
17. **Overlay CAMetalLayer.**
18. **DepthCapture an Continuity-LiDAR.**
19. **Continuity 15-fps Probe** gemessen.
20. **Mission-Control Zwei-Palm-Spread.**
21. **Aegis-Gaze Pinch-Confirm.**
22. **Per-Display pointerGain Pref.**
23. **Bezel-Hop Homographie Blend** 200 ms.
24. **FramePump Vision-Cancel Token.**
25. **Air-Keyboard Shortcut-Overlay.**
26. **JSONL Palm-Vel** für späteres Predict (bleibt 0 bis gemessen).
27. **iPhone Ultraweit FOV.**
28. **Gesture-Macro** 2-Schritt (Pinzette halten + Wisch = App-Switch).
29. **Scroll-Coast Sign-Hold** nach Achsenwechsel kein Rest-Momentum.
30. **Chrome-Dwell nur auf focused AX** — fremde Ampel hinter Vollbild tot.

P0: CameraBroker. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.

# Helios — Vorschlagsliste

Stand: **1.6.84**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes. Nur `main`. `bugfix` ist Altlast — nicht anlegen, nicht mergen.

## In 1.6.84 erledigt

1.6.83 Schnabel/OK. `pinchStartsGrab` tot in driveGrab. Meter 0,24 = Jitter-Klick. Stamp ohne TTL. Interrupt-Release, Beat 80 ms reclaimte.

1. **driveGrab Start/Hold verdrahtet** (`pinchStartsGrab` / `pinchHoldsGrab`).
2. **Idle-Arm echte Pinzette.**
3. **Stamp-TTL 250 ms** (`cameraMutexStampFresh`).
4. **Interrupt-Beat tot** (`cameraMutexBeatAllowed`). Palmen leer nach Release.
5. Tests + MARKETING_VERSION 1.6.84 (Build 117).

## Erweiterung (neu, 1.6.84)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
2. **HeliosAegisKit** SPM: Mutex-Protokoll einmal, nicht Copy-Paste CoordMath/MatchMath.
3. **VNTrackObjectRequest** echte Hand-Observation statt IoU-Box zwischen 8-Hz-Detect.
4. **VNImageRequestHandler(cvPixelBuffer:)** — 420f nicht über CGImage.
5. **Per-Finger-Kontakt** statt Skalar-Closedness (Daumen-Index Distanz + Finger-Curl).
6. **Tap-Cancel** offene Palme 200 ms bricht pending Hold vor Fire.
7. **Click-Ring Overlay** 80 ms vor Fire, damit man den Tap sieht.
8. **Hand-ID über uniqueID-Flicker** Chirality + Palm-UV, nicht Slot.
9. **CGEventSource-State** OS-Maus-Steal schneller als Clutch-Radius.
10. **Continuity Desk-View Crop-Kompensation** (zweite Cam, andere Homographie).
11. **IOHIDEventSystemClient** Pointer statt CGEvent (weniger Hitch).
12. **Watch Double-Tap** destruktive Klicks.
13. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
14. **Overlay CAMetalLayer.**
15. **DepthCapture an Continuity-LiDAR.**
16. **Continuity 15-fps Probe** gemessen.
17. **Mission-Control Zwei-Palm-Spread.**
18. **Aegis-Gaze Pinch-Confirm.**
19. **Per-Display pointerGain Pref.**
20. **Bezel-Hop Homographie Blend** 200 ms.
21. **FramePump Vision-Cancel Token.**
22. **Air-Keyboard Shortcut-Overlay.**
23. **JSONL Palm-Vel** für späteres Predict (bleibt 0 bis gemessen).
24. **iPhone Ultraweit FOV.**
25. **Gesture-Macro** 2-Schritt (Pinzette halten + Wisch = App-Switch).

P0: CameraBroker. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.

# Helios — Vorschlagsliste

Stand: **1.6.75**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes. Nur `main`. `bugfix` ist Altlast — nicht anlegen, nicht mergen.


## In 1.6.75 erledigt

1.6.74 Stamp lock-free, erster Hop, Scroll-Streak. Load einmal. PTS = Date() ohne Sample. Beat hart 0,08. Stamp ohne fsync.

1. **SpaceMap je Hop** (`bezelHopLoadStep`).
2. **PTS last-sample** 0,25 s.
3. **Beat-Helper + Stamp fsync.**
4. **Scroll-Streak Reset** Pause/Zoom.
5. Tests + MARKETING_VERSION 1.6.75 (Build 108).

## Erweiterung (neu, 1.6.75)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
2. **HeliosAegisKit** gemeinsamer Broker + Mutex-PTS.
3. **VNTrackObjectRequest** echte Observation, nicht nur IoU-Box.
4. **Watch Double-Tap** Click-Confirm + Haptic.
5. **JSONL Session-Replay** ohne Vision, Palm-Vel für Predict-Tuning.
6. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
7. **Click-Tick Sound** (optional, Accessibility).
8. **iPhone Ultraweit** FOV-Fallback statt Center-Stage-Crop.
9. **Per-Display pointerGain** UserDefaults.
10. **Aegis-Gaze Pinch-Confirm.**
11. **Overlay CAMetalLayer.**
12. **DepthCapture an Continuity-LiDAR.**
13. **Homographie Recalib-Tap** nach RECAL-Chip.
14. **Mission-Control Zwei-Palm-Spread.**
15. **Continuity 15-fps Probe** gemessen, nicht claimed.
16. **Deadman-Ring Overlay.**
17. **Air-Keyboard Shortcut-Overlay.**
18. **Stereo Mac+iPhone Disparität.**
19. **Pointer-Gain × Continuity-FOV.**
20. **drei Palmen** nur wenn Helios drei Hände trackt.
21. **Watch-IMU** Confirm für destruktive Klicks.
22. **FramePump Vision-Cancel Token** statt 400 ms Drop.
23. **Per-App Scroll-Gain Pref.**
24. **SpaceMap JSONL Replay** der Hop-Welle.
25. **Bezel-Hop Homographie Blend** 200 ms.

P0 CameraBroker. Kein neues *Need(dt). Predict nicht wieder an.

# Helios — Vorschlagsliste

Stand: **1.6.73**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes. Nur `main`. `bugfix` ist Altlast — nicht anlegen, nicht mergen.

## In 1.6.73 erledigt

1.6.70 Mutex-Write, Actor-Palm, Zoom-Sign. Eine Palme. Beat nur am Frame. Interrupt ließ den Claim stehen. Scroll ohne Vorzeichen.

1. **Zwei Palmen** Actor+Clutch in der Lock-Zeile.
2. **Mutex-Release** bei sessionWasInterrupted.
3. **Heartbeat 80 ms** ohne Frame.
4. **twoPinchScrollHolds** analog Zoom.
5. Tests + MARKETING_VERSION 1.6.73 (Build 106).

## Erweiterung (neu, 1.6.73)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
2. **HeliosAegisKit** gemeinsamer Broker + Mutex-PTS.
3. **VNTrackObjectRequest** echte Observation, nicht nur IoU-Box.
4. **Mutex flock timeout / lock-free stamp.** EX|NB während Aegis LOCK_SH.
5. **SpaceMap load per Bezel-Hop**, nicht erst 20.
6. **Watch Double-Tap** Click-Confirm + Haptic.
7. **JSONL Session-Replay** ohne Vision.
8. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
9. **Click-Tick Sound** (optional, Accessibility).
10. **iPhone Ultraweit** FOV-Fallback.
11. **Per-Display pointerGain** UserDefaults.
12. **Aegis-Gaze Pinch-Confirm.**
13. **Overlay CAMetalLayer.**
14. **DepthCapture an Continuity-LiDAR.**
15. **Homographie Recalib-Tap** nach RECAL-Chip.
16. **Mission-Control Zwei-Palm-Spread.**
17. **Continuity 15-fps Probe** gemessen.
18. **Deadman-Ring Overlay.**
19. **Air-Keyboard Shortcut-Overlay.**
20. **Scroll-Streak analog Zoom-EdgeHold.**

P0 CameraBroker. Kein neues *Need(dt).

# Helios — Vorschlagsliste

Stand: **1.6.63**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes. Nur `main`. `bugfix` ist Altlast — nicht anlegen, nicht mergen.

## In 1.6.63 erledigt

1.6.62 Mutex-Claim, Pinch×Palme, Size-Key, Watchdog, Predict×Höhe. PTS war Media. Predict-Cap `NSScreen.main`. Zoom-Streak `ok: true` bei Vorzeichenwechsel. Bezel-Hop ohne Recalib.

1. **Mutex PTS Wall** Unix, nicht CMSampleBuffer.
2. **Mutex Palm UV** für Aegis skipPrint.
3. **Predict-Cap × aktueller Schirm.**
4. **Zwei-Pinch Zoom-Vorzeichen** gleichsinnig.
5. **Bezel 20 hops → RECAL.**
6. Tests + MARKETING_VERSION 1.6.63 (Build 96).

## Erweiterung (neu, 1.6.63)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
2. **HeliosAegisKit** gemeinsamer Broker + Mutex-PTS.
3. **VNTrackObjectRequest** echte Observation, nicht nur IoU-Box.
4. **Mutex-PTS pro Frame** (Heartbeat 2 s > Fill-Skew 220 ms).
5. **Pair-Stereo-Tiefe** Mac+iPhone statt DepthCapture-Stub.
6. **Watch Double-Tap** Click-Confirm + Haptic.
7. **JSONL Session-Replay** ohne Vision.
8. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
9. **Click-Tick Sound** (optional, Accessibility).
10. **iPhone Ultraweit** FOV-Fallback.
11. **Per-Display pointerGain** UserDefaults.
12. **Aegis-Gaze Pinch-Confirm.**
13. **Overlay CAMetalLayer.**
14. **DepthCapture an Continuity-LiDAR.**
15. **Bezel-Hop Count decay.**
16. **Homographie Recalib-Tap** nach RECAL-Chip.
17. **Mission-Control Zwei-Palm-Spread.**
18. **Continuity 15-fps Probe** gemessen.
19. **Deadman-Ring Overlay.**
20. **Air-Keyboard Shortcut-Overlay.**

P0 CameraBroker. Kein neues *Need(dt).

# Helios — Vorschlagsliste

Stand: **1.6.59**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes. Nur `main`. `bugfix` ist Altlast — nicht anlegen, nicht mergen.

## In 1.6.59 erledigt

1.6.58 Predict-Clutch, USB-Promote, Fling-Cap, Scroll-Gain. Track-TTL 0,18 remintete den Slot. Pinch-Reset 0,12. Osmo = Phone. Promote ohne Rolle.

1. **Track-TTL trackDropoutNeed** statt hart 0,18.
2. **Pinch-Reset emptyHandsHold** statt hart 0,12.
3. **Osmo kein Phone-Bias** im Cold-Start.
4. **USB-Promote rollen-gated** Phone bleibt 24.
5. Tests + MARKETING_VERSION 1.6.59 (Build 92).

## Erweiterung (neu, 1.6.59)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
2. **HeliosAegisKit** gemeinsamer Broker + Mutex-PTS.
3. **VNTrackObjectRequest** echte Observation, nicht nur IoU-Box.
4. **Pair-Stereo-Tiefe** Mac+iPhone statt DepthCapture-Stub.
5. **Watch Double-Tap** Click-Confirm + Haptic.
6. **JSONL Session-Replay** ohne Vision.
7. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
8. **Click-Tick Sound** (optional, Accessibility).
9. **iPhone Ultraweit** FOV-Fallback.
10. **Per-Display pointerGain** UserDefaults.
11. **Aegis-Gaze Pinch-Confirm.**
12. **Continuity Center Stage off.** Cropt Palmen am FOV-Rand.
13. **Vision ROI aus letzter Palm-Box** (2× Crop).
14. **Chirality-Lock** nach Dropout.
15. **Continuity AE/WB-Lock.** Gegenlicht tötet Pinch.
16. **Fling-Achsen-Deadzone × palmWidth.**
17. **Display-Reconfig SpaceMap-Nudge.**
18. **Pinch-Hysterese × palmWidth.**
19. **AVCapture Mutex-File** ohne XPC.
20. **Mission-Control Zwei-Palm-Spread.**
21. **Session-Watchdog** 8 s leer.
22. **Overlay CAMetalLayer.**
23. **DepthCapture an Continuity-LiDAR.**
24. **Palm-Vel JSONL.**

P0 CameraBroker. Kein neues *Need(dt).

# Helios — Vorschlagsliste

Stand: **1.6.58**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes. Nur `main`. `bugfix` ist Altlast — nicht anlegen, nicht mergen.

## In 1.6.58 erledigt

1.6.57 Predict, Zwei-Hand-Clutch, Stage, Hand-Box. Clutch coastete Predict. Osmo 30 ohne Messung. Dropout-Fling. Scroll global.

1. **Predict-Clutch** Deadman/Zwei-Hand Cap 0.
2. **USB-C 30 fps Promote** gemessen ≥ 22.
3. **Fling-Cap × Screen-Höhe** 42 %.
4. **Per-App Scroll-Gain** Safari 1,35 / Xcode 0,55.
5. Tests + MARKETING_VERSION 1.6.58 (Build 91).

## Erweiterung (neu, 1.6.58)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
2. **HeliosAegisKit** gemeinsamer Broker + Mutex-PTS.
3. **VNTrackObjectRequest** echte Hand-Observation, nicht nur IoU-Box.
4. **Pair-Stereo-Tiefe** Mac+iPhone statt DepthCapture-Stub.
5. **Watch Double-Tap** Click-Confirm + Haptic.
6. **App-Grammar** Safari-Scroll vs Finder-Drag vs Xcode-Caret (Profile wirklich an).
7. **JSONL Session-Replay** ohne Vision.
8. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
9. **Click-Tick Sound** (optional, Accessibility).
10. **iPhone Ultraweit** als FOV-Fallback wenn Hands am Bildrand sterben.
11. **Per-Display pointerGain** UserDefaults.
12. **Aegis-Gaze Pinch-Confirm** wenn Face frontal und Blick auf HUD.
13. **Continuity HDR Tone-Map** bevor Vision 8-Bit sieht.
14. **Miss-Click Heatmap** JSONL.
15. **Accessibility Dwell-Click** unabhängig von Pinch.
16. **IOHID Force-Click vs Pinch.**
17. **mmap leftover-Boxen** Helios↔Aegis Palm-Occlusion.
18. **DepthCapture an Continuity-LiDAR.**
19. **Overlay CAMetalLayer.**
20. **Session-Watchdog** Idle = fps>0 UND keine Aegis-Face UND 8 s leer.
21. **Palm-Vel JSONL** für Predict-Tuning ohne Kamera.
22. **Predict-Cap × Screen-Höhe** analog Fling (48 pt auf 5K zu klein).
23. **Cover-Pipe 30-Promote** analog Lead.
24. **Air-Keyboard Shortcut-Overlay** ⌘C/V/Z.

P0 CameraBroker. Kein neues *Need(dt).

# Helios — Vorschlagsliste

Stand: **1.6.57**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes. Nur `main`. `bugfix` ist Altlast — nicht anlegen, nicht mergen.

## In 1.6.57 erledigt

1.6.56 One-Euro, 24-fps Kaltstart, Bezel, Deadman. Sample laggte 1 Frame. Zweite Palme klickte. Stage-Strip fraß den Cursor. Hand-Slot sprang.

1. **Pointer 1-Frame Predict** One-Euro-Vel × dt, Cap 48.
2. **Two-Hand Clutch** zweite Palme ohne Zwei-Pinch.
3. **Stage-Manager Space-Clamp** visibleFrame.
4. **Hand-Box IoU persist** Slot-ID zwischen Detect.
5. Tests + MARKETING_VERSION 1.6.57 (Build 90).

## Erweiterung (neu, 1.6.57)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
2. **HeliosAegisKit** gemeinsamer Broker + Mutex-PTS.
3. **USB-C Wired Continuity 30 fps** nur nach gemessenen ≥ 22 fps (Osmo 30 → 8).
4. **Pair-Stereo-Tiefe** Mac+iPhone statt DepthCapture-Stub.
5. **Watch Double-Tap** Click-Confirm + Haptic.
6. **App-Grammar** Safari-Scroll vs Finder-Drag vs Xcode-Caret.
7. **JSONL Session-Replay** ohne Vision.
8. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
9. **Click-Tick Sound** (optional, Accessibility).
10. **iPhone Ultraweit** als FOV-Fallback wenn Hands am Bildrand sterben.
11. **Per-Display pointerGain** UserDefaults.
12. **Aegis-Gaze Pinch-Confirm** wenn Face frontal und Blick auf HUD.
13. **Continuity HDR Tone-Map** bevor Vision 8-Bit sieht.
14. **Miss-Click Heatmap** JSONL.
15. **Accessibility Dwell-Click** unabhängig von Pinch.
16. **IOHID Force-Click vs Pinch.**
17. **mmap leftover-Boxen** Helios↔Aegis Palm-Occlusion.
18. **DepthCapture an Continuity-LiDAR.**
19. **Overlay CAMetalLayer.**
20. **Per-App Scroll-Gain.**
21. **Fling-Cap × Screen-Höhe.**
22. **VNTrackObjectRequest** echte Observation, nicht nur IoU-Box.
23. **Air-Keyboard Shortcut-Overlay** ⌘C/V/Z.
24. **Session-Watchdog** Idle = fps>0 UND keine Aegis-Face UND 8 s leer.
25. **Palm-Vel JSONL** für Predict-Tuning ohne Kamera.

P0 CameraBroker. Kein neues *Need(dt).

# Helios — Vorschlagsliste

Stand: **1.6.56**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes. Nur `main`. `bugfix` ist Altlast — nicht anlegen, nicht mergen.

## In 1.6.56 erledigt

1.6.55 Adaptive Gain, HUD-Sharing, Edge, Gap. Continuity-Kaltstart blieb 1080@8. Cover Max-FPS. Bezel ohne Hysterese. Drift-Klick.

1. **One-Euro Filter** min-cutoff × Jitter.
2. **Continuity 24-fps Kaltstart** + Cover `cameraLockDuration`.
3. **Bezel-Hop Hysterese** 80 pt.
4. **Palm-Deadman 2 s** → Clutch.
5. Tests + MARKETING_VERSION 1.6.56 (Build 89).

## Erweiterung (neu, 1.6.56)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
2. **HeliosAegisKit** gemeinsamer Broker + Mutex-PTS.
3. **VNTrack Hand-Box persist** bei Continuity 8 Hz.
4. **Pair-Stereo-Tiefe** Mac+iPhone statt DepthCapture-Stub.
5. **Watch Double-Tap** Click-Confirm + Haptic.
6. **App-Grammar** Safari-Scroll vs Finder-Drag vs Xcode-Caret.
7. **JSONL Session-Replay** ohne Vision.
8. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
9. **Stage-Manager Space-Clamp** — Cursor nicht in unsichtbare Spaces.
10. **Click-Tick Sound** (optional, Accessibility).
11. **iPhone Ultraweit** als FOV-Fallback wenn Hands am Bildrand sterben.
12. **Per-Display pointerGain** UserDefaults.
13. **Aegis-Gaze Pinch-Confirm** wenn Face frontal und Blick auf HUD.
14. **Continuity HDR Tone-Map** bevor Vision 8-Bit sieht.
15. **Pointer 1-Frame Predict** bei 8 Hz (Palm-Vel × dt).
16. **Two-Hand Clutch** — zweite Palme friert die erste.
17. **USB-C Wired Continuity** statt Wi-Fi 8 fps.
18. **Miss-Click Heatmap** JSONL.
19. **Accessibility Dwell-Click** unabhängig von Pinch.
20. **IOHID Force-Click vs Pinch.**
21. **mmap leftover-Boxen** Helios↔Aegis Palm-Occlusion.
22. **DepthCapture an Continuity-LiDAR.**
23. **Overlay CAMetalLayer.**
24. **Per-App Scroll-Gain.**
25. **Freeze-Kalman über uniqueID.**
26. **Air-Keyboard Shortcut-Overlay** ⌘C/V/Z.

P0 CameraBroker. Kein neues *Need(dt).

# Helios — Vorschlagsliste

Stand: **1.6.55**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes. Nur `main`. `bugfix` ist Altlast — nicht anlegen, nicht mergen.

## In 1.6.55 erledigt

1.6.54 Scale/Deadzone/Momentum/Homographie/Click-Energy. Continuity-Jitter teleportierte. HUD in Screenshots. Bezel verschluckte den Cursor.

1. **Adaptive Gain aus Jitter-RMS.**
2. **HUD sharingType .none.**
3. **Window-Edge Resistance.**
4. **Multi-Display Warp** über die Lücke.
5. Tests + MARKETING_VERSION 1.6.55 (Build 88).

## Erweiterung (neu, 1.6.55)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
2. **HeliosAegisKit** gemeinsamer Broker + Mutex-PTS.
3. **Pair-Stereo-Tiefe** Mac+iPhone statt DepthCapture-Stub.
4. **Watch Double-Tap** Click-Confirm + Haptic.
5. **App-Grammar** Safari-Scroll vs Finder-Drag vs Xcode-Caret.
6. **JSONL Session-Replay** ohne Vision.
7. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
8. **Slot-ID persist** über uniqueID-Flicker.
9. **IOHID Force-Click vs Pinch.**
10. **mmap leftover-Boxen** Helios↔Aegis Palm-Occlusion.
11. **DepthCapture an Continuity-LiDAR.**
12. **Overlay CAMetalLayer.**
13. **Per-App Scroll-Gain.**
14. **Pinch-Hold analog × Kalman-Q.**
15. **VNTrack Hand-Box persist** bei Continuity 8 Hz.
16. **Fling-Cap × Screen-Höhe.**
17. **Session-Watchdog** Idle = fps>0 UND keine Aegis-Face UND 8 s leer.
18. **Air-Keyboard Dwell × Scale.**
19. **Per-Display pointerGain** UserDefaults, nicht nur Scale.
20. **Aegis-Gaze Pinch-Confirm** wenn Face frontal und Blick auf HUD.
21. **Continuity HDR Tone-Map** bevor Vision 8-Bit sieht.
22. **Air-Keyboard Shortcut-Overlay** ⌘C/V/Z ohne Maus.
23. **Freeze-Kalman über uniqueID** — Palm-Vel überlebt Reconnect.
24. **One-Euro Filter** auf Cursor (min-cutoff × Jitter, nicht nur Highpass).
25. **Continuity 24-fps Format-Leiter** bevor 8 Hz akzeptiert wird.
26. **Bezel-Hop Hysterese** 80 pt extra, nicht nur Gap-Clamp.
27. **Stage-Manager Space-Clamp** — Cursor nicht in unsichtbare Spaces.
28. **Click-Tick Sound** (optional, Accessibility).
29. **Palm-Deadman 2 s** ohne Intent → Clutch, nicht Kill.
30. **iPhone Ultraweit** als FOV-Fallback wenn Hands am Bildrand sterben.

P0 CameraBroker. Kein neues *Need(dt).

# Helios — Vorschlagsliste

Stand: **1.6.54**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes. Nur `main`. `bugfix` ist Altlast — nicht anlegen, nicht mergen.

## In 1.6.54 erledigt

1.6.53 Pointer×Scale immer Main. Deadzone UV. Zwei-Pinzette tot nach Loslassen. Nudge wischte H-Store. Klick nur Dauer.

1. **Per-Display backingScaleFactor.** Cursor-Schirm, nicht `NSScreen.main`.
2. **Deadzone × Scale.**
3. **Two-pinch Scroll-Momentum** nach Loslassen.
4. **Homographie-Cache keyed by rotation.** Nudge ohne Wipe.
5. **Click-Energy** (Closedness × Still × Hold).
6. Tests + MARKETING_VERSION 1.6.54 (Build 87).

## Erweiterung (neu, 1.6.54)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
2. **HeliosAegisKit** gemeinsamer Broker + Mutex-PTS.
3. **Pair-Stereo-Tiefe** Mac+iPhone statt DepthCapture-Stub.
4. **Watch Double-Tap** Click-Confirm + Haptic.
5. **App-Grammar** Safari-Scroll vs Finder-Drag vs Xcode-Caret.
6. **JSONL Session-Replay** ohne Vision.
7. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
8. **Slot-ID persist** über uniqueID-Flicker.
9. **IOHID Force-Click vs Pinch.**
10. **mmap leftover-Boxen** Helios↔Aegis Palm-Occlusion.
11. **DepthCapture an Continuity-LiDAR.**
12. **Overlay CAMetalLayer.**
13. **Per-App Scroll-Gain.**
14. **Pinch-Hold analog × Kalman-Q.**
15. **VNTrack Hand-Box persist** bei Continuity 8 Hz.
16. **Fling-Cap × Screen-Höhe.**
17. **Session-Watchdog** Idle = fps>0 UND keine Aegis-Face UND 8 s leer.
18. **Air-Keyboard Dwell × Scale.**
19. **Adaptive Gain aus Jitter-RMS** 8 Hz vs 24 Hz, nicht nur dt.
20. **HUD aus Screen-Capture ausschließen** (SCContentFilter).
21. **Multi-Display Warp über die Lücke** — Cursor stirbt zwischen 5K und Sidecar.
22. **Aegis-Gaze Pinch-Confirm** wenn Face frontal und Blick auf HUD.
23. **Per-Display pointerGain** UserDefaults, nicht nur Scale.
24. **Window-Edge Resistance** statt hartem Clamp.
25. **Continuity HDR Tone-Map** bevor Vision 8-Bit sieht.
26. **Air-Keyboard Shortcut-Overlay** ⌘C/V/Z ohne Maus.
27. **Freeze-Kalman über uniqueID** — Palm-Vel überlebt Reconnect.

P0 CameraBroker. Kein neues *Need(dt).

# Helios — Vorschlagsliste

Stand: **1.6.53**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes. Nur `main`. `bugfix` ist Altlast — nicht anlegen, nicht mergen.

## In 1.6.53 erledigt

1.6.52 Two-pinch Hysterese, Rotation-Recalib, CGEvent 90 Hz. Pointer teleportiert auf Retina. Scroll-Ticks 1×. 90° Wipe. Hitch = Double-Click.

1. **Pointer-Accel × backingScaleFactor.** `pointerGainScaled` UV bleibt, Gain / scale.
2. **Two-pinch Scroll-Ticks × backingScale.**
3. **SpaceMap Rotation-Nudge** 90/180/270 — Palmen halten, H neu. Wipe nur schräg.
4. **Click-Hitch Debounce.** Continuity-Miss ≠ Double-Click. `clickHitchNeed` ≥ 0,22 s.
5. Tests + MARKETING_VERSION 1.6.53 (Build 86).

## Erweiterung (neu, 1.6.53)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
2. **HeliosAegisKit** gemeinsamer Broker + Mutex-PTS.
3. **Pair-Stereo-Tiefe** Mac+iPhone statt DepthCapture-Stub.
4. **Watch Double-Tap** Click-Confirm.
5. **App-Grammar** Safari-Scroll vs Finder-Drag vs Xcode-Caret.
6. **JSONL Session-Replay** ohne Vision.
7. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
8. **Slot-ID persist** über uniqueID-Flicker.
9. **IOHID Force-Click vs Pinch.**
10. **mmap leftover-Boxen** Helios↔Aegis Palm-Occlusion.
11. **DepthCapture an Continuity-LiDAR.**
12. **Overlay CAMetalLayer.**
13. **Per-App Scroll-Gain.**
14. **Pinch-Hold analog × Kalman-Q.**
15. **VNTrack Hand-Box persist** bei Continuity 8 Hz.
16. **Fling-Cap × Screen-Höhe.**
17. **Per-Display backingScaleFactor** (Cursor auf 5K vs 1× Sidecar).
18. **Two-pinch Scroll-Momentum** nach Loslassen coasten.
19. **Homographie-Cache keyed by rotation** — Nudge ohne Store-Wipe.
20. **Deadzone × Scale** analog Jiggle.
21. **Session-Watchdog** Idle = fps>0 UND keine Aegis-Face UND 8 s leer.
22. **Air-Keyboard Dwell × Scale.**
23. **Click-Energy** (nicht nur Dauer) gegen Hitch-Klicks.

P0 CameraBroker. Kein neues *Need(dt).

# Helios — Vorschlagsliste

Stand: **1.6.52**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes. Nur `main`. `bugfix` ist Altlast — nicht anlegen, nicht mergen.

## In 1.6.52 erledigt

1.6.51 Two-pinch vs Scroll, Coast-Cap×Scale, Jiggle×Scale. Achse kippte. Display-Drehung tot. Sample vs Coast.

1. **Two-pinch vs Scroll-Hysterese.** Achse hält, kleine Span = Ticks.
2. **SpaceMap Re-Calib** nach Display-Drehung.
3. **CGEvent coalescing 90 Hz.**
4. **Sample-Cursor weicht Coast.**
5. Tests + MARKETING_VERSION 1.6.52 (Build 85).

## Erweiterung (neu, 1.6.52)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
2. **HeliosAegisKit** gemeinsamer Broker + Mutex-PTS.
3. **Pair-Stereo-Tiefe** Mac+iPhone statt DepthCapture-Stub.
4. **Watch Double-Tap** Click-Confirm.
5. **App-Grammar** Safari-Scroll vs Finder-Drag vs Xcode-Caret.
6. **JSONL Session-Replay** ohne Vision.
7. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
8. **Slot-ID persist** über uniqueID-Flicker.
9. **IOHID Force-Click vs Pinch.**
10. **mmap leftover-Boxen** Helios↔Aegis Palm-Occlusion.
11. **DepthCapture an Continuity-LiDAR.**
12. **Overlay CAMetalLayer.**
13. **Per-App Scroll-Gain.**
14. **Pinch-Hold analog × Kalman-Q.**
15. **Pointer-Accel × backingScaleFactor.**
16. **VNTrack Hand-Box persist** bei Continuity 8 Hz.
17. **Two-pinch Scroll-Ticks × backingScale.**
18. **SpaceMap Rotation-Nudge** statt Wipe.
19. **Click-Hitch Debounce** Continuity-Miss ≠ Double-Click.

P0 CameraBroker. Kein neues *Need(dt).

# Helios — Vorschlagsliste

Stand: **1.6.51**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes. Nur `main`. `bugfix` ist Altlast — nicht anlegen, nicht mergen.

## In 1.6.51 erledigt

1.6.50 Clutch×Scale, AX-Window, reduced-motion, Vision-Stale, Pinch analog. Zoom = Scroll. Coast 80 pt. Jiggle 1,2.

1. **Two-pinch vs Scroll-Hysterese.** `scrollAllowed` + Mute 0,28 s.
2. **HUD-Coast-Cap × backingScaleFactor.**
3. **Clutch-Jiggle × Scale.**
4. Tests + MARKETING_VERSION 1.6.51 (Build 84).

## Erweiterung (neu, 1.6.51)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
2. **HeliosAegisKit** gemeinsamer Broker + Mutex-PTS.
3. **Pair-Stereo-Tiefe** Mac+iPhone statt DepthCapture-Stub.
4. **Watch Double-Tap** Click-Confirm.
5. **App-Grammar** Safari-Scroll vs Finder-Drag vs Xcode-Caret.
6. **JSONL Session-Replay** ohne Vision.
7. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
8. **Slot-ID persist** über uniqueID-Flicker.
9. **IOHID Force-Click vs Pinch.**
10. **mmap leftover-Boxen** Helios↔Aegis Palm-Occlusion.
11. **DepthCapture an Continuity-LiDAR.**
12. **Overlay CAMetalLayer.**
13. **SpaceMap Re-Calib** nach Display-Drehung.
14. **Watch-IMU Pinch-Confirm.**
15. **Session-Watchdog** Idle = fps>0 UND keine Aegis-Face UND 8 s leer.
16. **CGEvent-Tap coalescing 90 Hz.**
17. **Pointer-Accel × backingScaleFactor** (UV bleibt, Gain in pt).
18. **Fling-Cap × Screen-Höhe** analog Coast-Cap.
19. **Air-Keyboard Dwell × Scale.**
20. **Kill-Switch Chip** ohne neues *Need(dt).

P0 CameraBroker. Kein neues *Need(dt).

# Helios — Vorschlagsliste

Stand: **1.6.50**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes. Nur `main`. `bugfix` ist Altlast — nicht anlegen, nicht mergen.

## In 1.6.50 erledigt

1.6.49 720-Lock, 24 fps, Click-Vel, HUD-Coast. Retina-Clutch 48 pt. Coast AX 90 Hz. Reduce-Motion Coast. Vision stale. Pinch-Bool.

1. **Clutch-Radius × backingScaleFactor.**
2. **AX-Fenster-ID Cache** während Coast.
3. **HUD reduced-motion** ohne Coast.
4. **FramePump Vision-Timeout 400 ms.**
5. **Pinch analog** Closedness×zSep.
6. Tests + MARKETING_VERSION 1.6.50 (Build 83).

## Erweiterung (neu, 1.6.50)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
2. **HeliosAegisKit** gemeinsamer Broker + Mutex-PTS.
3. **Pair-Stereo-Tiefe** Mac+iPhone statt DepthCapture-Stub.
4. **Watch Double-Tap** Click-Confirm.
5. **App-Grammar** Safari-Scroll vs Finder-Drag vs Xcode-Caret.
6. **Two-pinch vs scroll hysteresis.**
7. **JSONL Session-Replay** ohne Vision.
8. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
9. **Slot-ID persist** über uniqueID-Flicker.
10. **IOHID Force-Click vs Pinch.**
11. **mmap leftover-Boxen** Helios↔Aegis Palm-Occlusion.
12. **DepthCapture an Continuity-LiDAR.**
13. **Overlay CAMetalLayer.**
14. **SpaceMap Re-Calib** nach Display-Drehung.
15. **Watch-IMU Pinch-Confirm.**
16. **Session-Watchdog** Idle = fps>0 UND keine Aegis-Face UND 8 s leer.
17. **CGEvent-Tap coalescing 90 Hz.**

P0 CameraBroker. Kein neues *Need(dt).

# Helios — Vorschlagsliste

Stand: **1.6.49**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes. Nur `main`. `bugfix` ist Altlast — nicht anlegen, nicht mergen.

## In 1.6.49 erledigt

1.6.48 inputPriority, Native 420, Freeze-Cursor. Continuity Kaltstart 1080@8. Drift=Zug. HUD 1 Frame tot. Homographie Main. Body fraß 8 fps.

1. **720p-Lock persist** UserDefaults. Mac nicht auf Phone-720.
2. **cameraLockFps 24** statt 30-Request.
3. **Click-vs-Drag Palm-Vel.**
4. **HUD-Coast + OS-Cursor 90 Hz.** Clutch Radius.
5. **Per-Display SpaceMap.**
6. **visionSkipsBody** bei 8 fps.
7. Tests + MARKETING_VERSION 1.6.49 (Build 82).

## Erweiterung (neu, 1.6.49)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
2. **HeliosAegisKit** gemeinsamer Broker + Mutex-PTS.
3. **Pair-Stereo-Tiefe** Mac+iPhone statt DepthCapture-Stub.
4. **Watch Double-Tap** Click-Confirm.
5. **App-Grammar** Safari-Scroll vs Finder-Drag vs Xcode-Caret.
6. **HUD reduced-motion** ohne 90 Hz Coast.
7. **Two-pinch vs scroll hysteresis.**
8. **Clutch-Radius × backingScaleFactor.**
9. **AX-Hit-Cache × Fenster-ID** während Freeze.
10. **JSONL Session-Replay** ohne Vision.
11. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
12. **Slot-ID persist** über uniqueID-Flicker.
13. **IOHID Force-Click vs Pinch.**
14. **Pinch analog** Closedness×zSep Mix.
15. **mmap leftover-Boxen** Helios↔Aegis Palm-Occlusion.
16. **DepthCapture an Continuity-LiDAR.**
17. **Overlay CAMetalLayer.**
18. **SpaceMap Re-Calib** nach Display-Drehung.
19. **Watch-IMU Pinch-Confirm.**
20. **Session-Watchdog** Idle = fps>0 UND keine Aegis-Face UND 8 s leer.

P0 CameraBroker. Kein neues *Need(dt).

# Helios — Vorschlagsliste

Stand: **1.6.48**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes. Nur `main`. `bugfix` ist Altlast — nicht anlegen, nicht mergen.

## In 1.6.48 erledigt

1.6.47 start() Leiter, sticky Höhe, Mac nie. 1080p-Preset klemmt Continuity. Freeze tot. Pinch/AX drop.

1. **sessionPreset inputPriority / 720p.** Nie 1080 zuerst.
2. **Native 420 vor BGRA.**
3. **freezeDrivesCursor** + lastHandsLive.
4. **emptyHandsHoldDropsPinch / ReleaseAX(beyondHold).**
5. **didWake Session-Recovery.**
6. Tests + MARKETING_VERSION 1.6.48 (Build 81).

## Erweiterung (neu, 1.6.48)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC, eine Session. P0.
2. **HeliosAegisKit** gemeinsamer Broker + Mutex-PTS.
3. **Click-vs-Drag Classifier** aus Palm-Velocity-Histogramm, nicht nur Distanz.
4. **Per-Display SpaceMap** wenn der Cursor den Screen wechselt.
5. **720p-Lock persist** lastFormatHeight in UserDefaults über Launches.
6. **Pair-Stereo-Tiefe** Mac+iPhone statt DepthCapture-Stub.
7. **Watch Double-Tap** als Click-Confirm (neben IMU).
8. **App-Grammar** Safari-Scroll vs Finder-Drag vs Xcode-Caret.
9. **HUD reduced-motion** ohne 90 Hz Lerp.
10. **Vision-Cancel-Token** wenn FramePump droppt.
11. **Two-pinch vs scroll hysteresis.**
12. **Clutch-Radius × backingScaleFactor.**
13. **AX-Hit-Cache × Fenster-ID** während Freeze.
14. **JSONL Session-Replay** ohne Vision.
15. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
16. **CGEvent-Tap coalescing 90 Hz.**
17. **Slot-ID persist** über uniqueID-Flicker.
18. **IOHID Force-Click vs Pinch.**
19. **Pinch analog** Closedness×zSep Mix, nicht nur Hold-SM.
20. **mmap leftover-Boxen** Helios↔Aegis Palm-Occlusion.

P0 CameraBroker. Kein neues *Need(dt).

# Helios — Vorschlagsliste

Stand: **1.6.47**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes. Nur `main`. `bugfix` ist Altlast — nicht anlegen, nicht mergen.

## In 1.6.47 erledigt

1.6.46 uniqueID sticky Name, PTS-Wall, Kalman-Palme. start() dumpte Leiter. uniqueID-Wechsel dumpte Höhe. Mac-Name klebte.

1. **start() hält lastFormatHeight / uniqueID / Role.**
2. **lastFormatHeightResets via cameraIDSticky.** Mac nie, Osmo ja.
3. Tests + MARKETING_VERSION 1.6.47 (Build 80).

## Erweiterung (neu, 1.6.47)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC, eine Session. P0.
2. **HeliosAegisKit** gemeinsamer Broker + Mutex-PTS.
3. **Two-pinch vs scroll hysteresis.**
4. **Clutch-Radius × backingScaleFactor** je NSScreen.
5. **AX-Hit-Cache × Fenster-ID.**
6. **mmap leftover-Boxen** Helios↔Aegis.
7. **Aegis-Yaw als Click-Lock.**
8. **HUD Pose-Chips am DisplayLink.**
9. **Session-Watchdog** Idle = fps>0 UND keine Aegis-Face UND 8 s leer.
10. **Pointer-Accel × backingScaleFactor.**
11. **DepthCapture an Continuity LiDAR** (Datei ist Stub).
12. **JSONL Session-Replay** ohne Vision auf Linux.
13. **MediaPipe Hands Fallback.**
14. **SpaceMap Re-Calib** nach Bildschirm-Drehung.
15. **Watch-IMU Pinch-Confirm.**
16. **PinchHold analog** Closedness-Mix.
17. **Sleep/Wake Camera-Recovery** ohne Homographie-Reset.
18. **CGEvent-Tap coalescing 90 Hz.**
19. **Slot-ID persist** über uniqueID-Flicker.
20. **IOHID Force-Click vs Pinch.**

P0 CameraBroker. Kein 1.6.48-dt-Pflaster ohne Broker.

## In 1.6.46 erledigt

1.6.45 HMM pinchHeld, dtPalm, Format-Retry. Continuity uniqueID flackert Recenter. PTS = Dropout. Leiter alte Cam. Tracker Freeze stand.

1. **uniqueID sticky.** `cameraIDSticky` / HomographyResets / SpaceMap.retarget. ` · Tiefe` strip.
2. **PTS-Sprung = Freeze.** `ptsJumpIsFreeze` + `ptsWallStamp`.
3. **lastFormatHeightResets** + `cameraPreferredID` Name-Reconnect.
4. **Kalman-Palme im HandTracker** während Freeze (`lastVel`).
5. Tests + MARKETING_VERSION 1.6.46 (Build 79).

## Erweiterung (neu, 1.6.46)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC, eine Session. P0.
2. **HeliosAegisKit** gemeinsamer Broker + Mutex-PTS.
3. **Two-pinch vs scroll hysteresis** — offene Hand + Coast darf Pinch-Start nicht fressen.
4. **Clutch-Radius × backingScaleFactor** je NSScreen.
5. **AX-Hit-Cache × Fenster-ID** Resize während Freeze sonst tot.
6. **mmap leftover-Boxen** Helios↔Aegis, nicht Datei-Poll. Palm-Occlusion.
7. **Aegis-Yaw als Click-Lock** — Blick weg = kein Klick.
8. **HUD Pose-Chips am DisplayLink** unabhängig von `overlay.mark()`.
9. **Session-Watchdog** Idle nur fps>0 UND keine Aegis-Face UND 8 s leer.
10. **Pointer-Accel × backingScaleFactor** je NSScreen, nicht 48 px universal.
11. **DepthCapture an Continuity LiDAR** wirklich verdrahten (Datei ist Stub).
12. **JSONL Session-Replay** Gesten-Regression ohne Vision auf Linux.
13. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
14. **SpaceMap Re-Calib** nach Bildschirm-Drehung, nicht uniqueID-Flicker.
15. **Watch-IMU Pinch-Confirm.**
16. **PinchHold analog** Closedness als Emission-Mix, nicht nur Bool.
17. **Continuity 420v-Luma-Sprung = Freeze** (nicht nur PTS).
18. **Sleep/Wake Camera-Recovery** ohne Homographie-Reset.
19. **CGEvent-Tap coalescing 90 Hz**, nicht 8 Hz Vision.
20. **Slot-ID persist** über uniqueID-Flicker (Hand-ID nicht neu minten).
21. **IOHID Force-Click vs Pinch** disambiguieren.

P0 CameraBroker. Kein 1.6.47-dt-Pflaster ohne Broker.

## In 1.6.45 erledigt

## In 1.6.45 erledigt

1.6.44 DisplayLink HUD, PinchHoldPhase in driveGrab. HMM-Signatur da, Call-Site tot. `let dt` Shadow. Format-Retry hinter 8 s.

1. **HMM pinchHeld Call-Site.** `pinchState.closed` in `hmm.step`. Stay-Tau 110 ms.
2. **dtPalm = sampleDt.** Ungeklemmte zweite Uhr tot.
3. **cameraFormatRenegotiateRetry** verdrahtet (3 s Leiter-Schritt).
4. Tests + MARKETING_VERSION 1.6.45 (Build 78).

## Erweiterung (neu, 1.6.45)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC, eine Session. P0.
2. **HeliosAegisKit** gemeinsamer Broker + Mutex-PTS.
3. **Continuity uniqueID-Reconnect** — Slot stirbt, Pinch-Lock weg. Homographie nur wenn Cam wirklich wechselt. P0 klein.
4. **Continuity PTS-Sprung** als Freeze, nicht Dropout (Uhr reset ≠ Hand weg).
5. **Two-pinch vs scroll hysteresis** — offene Hand + Coast darf Pinch-Start nicht fressen.
6. **Clutch-Radius × backingScaleFactor** je NSScreen.
7. **AX-Hit-Cache × Fenster-ID** Resize während Freeze sonst tot.
8. **mmap leftover-Boxen** Helios↔Aegis, nicht Datei-Poll. Palm-Occlusion.
9. **Aegis-Yaw als Click-Lock** — Blick weg = kein Klick.
10. **HUD Pose-Chips am DisplayLink** unabhängig von `overlay.mark()`.
11. **Session-Watchdog** Idle nur fps>0 UND keine Aegis-Face UND 8 s leer.
12. **Pointer-Accel × backingScaleFactor** je NSScreen, nicht 48 px universal.
13. **DepthCapture an Continuity LiDAR** wirklich verdrahten (Datei ist Stub).
14. **JSONL Session-Replay** Gesten-Regression ohne Vision auf Linux.
15. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
16. **SpaceMap Re-Calib** nach Bildschirm-Drehung / uniqueID-Wechsel.
17. **Watch-IMU Pinch-Confirm.**
18. **Kalman-Palme während Freeze** in HandTracker, nicht nur Engine (Recover-Blend).
19. **Format-Leiter nach uniqueID-Wechsel** lastFormatHeight zurücksetzen.
20. **PinchHold analog** Closedness als Emission-Mix, nicht nur Bool.

P0 CameraBroker, dann uniqueID sticky. Kein 1.6.46-dt-Pflaster ohne eines davon.

## In 1.6.44 erledigt

1.6.43 Format-Leiter, PinchHoldPhase Math, fail-closed AX. HUD blieb 8 Hz. Engine las Bool.

1. **DisplayLink 90 Hz HUD.** `CADisplayLink` unabhängig von Detect. `hudLerpT` t=0 am Sample, t=1 nach Intervall. Freeze snap.
2. **PinchHoldPhase in GestureEngine.** `pinchHoldAdvance` in `driveGrab`. `dropPinchHold` statt nacktem Bool. Tentative überlebt einen Continuity-Tick.
3. Tests + MARKETING_VERSION 1.6.44 (Build 77).

## In 1.6.43 erledigt


1.6.42 Fusion Source-Tag / Reliability-Decay / freezeKalmanQ. Format-Retry denselben 1080p@8. Pinch weiter Bool+Uhren. AX-Drop warf Cursor trotzdem.

1. **cameraFormatLadder.** 1080p@8 → 720p@24 → 960p@15 → 640p@30. `cameraFormatLadderBias` in `bestFormat`.
2. **PinchHoldPhase** Unseen / Tentative / Held / Released. `pinchHoldAdvance` / `pinchHoldFire`.
3. **pointerWarpAllowed.** AX tot → kein CGEvent-Move (fail-closed).
4. Tests + MARKETING_VERSION 1.6.43 (Build 76).

## Erweiterung (neu, 1.6.43)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC, eine Session. P0.
2. **DisplayLink 90 Hz HUD**, Kamera 8–24 fps. Overlay-Lerp unabhängig. P1.
3. **PinchHoldPhase in GestureEngine verdrahten** — Math ist da, Gate/HMM lesen weiter Bool.
4. **HeliosAegisKit** gemeinsamer Broker + Mutex-PTS.
5. **Continuity uniqueID-Reconnect** — Slot stirbt, Pinch-Lock weg. Homographie nur wenn Cam wirklich wechselt.
6. **Two-pinch vs scroll hysteresis** — offene Hand + Coast darf Pinch-Start nicht fressen.
7. **mmap leftover-Boxen** Helios↔Aegis, nicht Datei-Poll. Palm-Occlusion.
8. **Aegis-Yaw als Click-Lock** — Blick weg = kein Klick.
9. **Per-Finger One-Euro**, nicht nur pinchRatio.
10. **VoiceOver-Rotor** Peace-Hold mappt Rotor, nicht System-Cmd.
11. **Cover-Lead Blend nur Quality-Gap.**
12. **Stereo Mac+Phone z aus Disparität**, Lift-Gewicht dann wirklich 0,06.
13. **On-Device Create ML** aus `gesten.jsonl` ohne Bundle-Modell.
14. **Tests ohne Vision.framework** Fusion/HMM auf Linux-CI (reine Double-Math) — CoordTests bleibt der Einstieg.
15. **Session-Watchdog** Idle nur fps>0 UND keine Aegis-Face UND 8 s leer.
16. **Pointer-Accel × backingScaleFactor** je NSScreen, nicht 48 px universal.
17. **HUD Pose-Chips am DisplayLink** auch wenn Detect 8 Hz friert.
18. **Palm-Silhouette Click-Lock** Aspect Kante-an = kein Klick.
19. **DepthCapture an Continuity LiDAR** wirklich verdrahten (Datei ist Stub).
20. **JSONL Session-Replay** Gesten-Regression.

P0 CameraBroker. P1 DisplayLink. P2 PinchHoldPhase in der Engine. Kein 1.6.44-dt-Pflaster ohne eines davon.

## In 1.6.42 erledigt

1.6.41 AX-TTL / Drag×dt / Format-Score. Fusion-Quelle immer 2D. Reliability fehlender Quellen 1. Kalman-Q fest 0,94.

1. **fused.source = argmax Gewicht.** HUD `führt`.
2. **reliabilityDecay** fehlende Quelle × 0,92.
3. **freezeKalmanQ(dt).**
4. Tests + MARKETING_VERSION 1.6.42 (Build 75).

## In 1.6.41 erledigt

1.6.40 Kalman / AX-Cache / EMA / Gain×dt / q-Chips / Format einmal. AX-TTL 40 ms < Continuity-Frame. Drag = ein 8-fps-Tick. Format-Nachzug gleicher Score. HMM-Reset 0,35 s.

1. **axHitCacheFresh(dt: sampleDt).**
2. **pinchDragNeedOf / pinchDragCursorNeed.**
3. **cameraFormatScoreMeasured** + Cooldown 8 s.
4. **trackDropoutNeed(dt).**
5. Tests + MARKETING_VERSION 1.6.41 (Build 74).

## In 1.6.40 erledigt

1.6.39 Approach+Reach / Finger-Kontakt / q-Gate / Tip. Freeze-Vel-Decay 0,82 tot nach 3 Ticks. AX jeden Tick. palmWidth α Frame. Pointer-Gain Teleport. q-Chip nur Actor. Format einmal.

1. **freezeKalmanPredict / Update / Palms.** Reibung 0,94, P wächst.
2. **axHitCacheFresh** 1 Frame.
3. **palmWidthEMA × dt.** 8 fps α 0,12.
4. **pointerGainDt.** 8 fps 0,32.
5. **qualityChips** je Hand.
6. **cameraFormatRenegotiate** fps < 12.
7. Tests + MARKETING_VERSION 1.6.40 (Build 73).

## Erweiterung (neu)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC, eine Session. P0.
2. **DisplayLink 90 Hz HUD**, Kamera 8–24 fps. Overlay-Lerp unabhängig.
3. **HeliosAegisKit** gemeinsamer Broker + Mutex-PTS.
4. **LiDAR-Pinch** (DepthCapture) statt nur Landmark-z. Residual-Gate 1.6.37 ist Lift3D.
5. **IOHID Event-Tap / AX SetPosition / Per-App Gain** (`bugfix`, opt-in).
6. **JSONL Session-Replay** Gesten-Regression.
7. **MediaPipe Hands Sidecar** — VNDetectHumanHandPose verliert Spitzen.
8. **Hand-ID über Continuity-Reconnect** — Slot stirbt, Pinch-Lock weg.
9. **Zwei-Pinzetten Freeze-Span** — Zoom-Anker nicht tot nach einem Miss.
10. **Helios liest Aegis leftover-Boxen** als Palm-Occlusion.
11. **Aegis-Yaw als Helios Click-Lock** — Blick weg = kein Klick.
12. **SpaceMap Re-Calib** wenn Palm-Aspect nach Drehung kippt.
13. **Two-pinch vs scroll hysteresis** — offene Hand + Coast darf Pinch-Start nicht fressen.
14. **Wrist-IMU via Watch** für Pinch-Confirm wenn Vision-Spitzen tot.
15. **Homographie Online-Nachzug** 4 Anschläge unsichtbar nach 20 s Pointer-Clutch.
16. **DepthCapture an Continuity LiDAR** wirklich verdrahten (Datei ist Stub).
17. **One-Euro auf Cursor-Output**, nicht nur Palm-Highpass — 8 fps sonst Nachschwingen.
18. **Pinch analog 0…1 als Scroll-Gain** statt Bool-Gate (Ultraleap-Stil).
19. **Per-Display Freeze-Clamp** — Geisterhand darf nicht den Nachbarschirm teleportieren.
20. **Vision-Revision-Fallback** wenn Continuity die gepinnte Revision droppt.
21. **Gesture-Macros** 2 s aufnehmen, Peace+Faust replay.
22. **ARKit Gaze Click-Lock** wenn Aegis-Yaw fehlt (Studio Display).
23. **AX-Hit-Cache × Fenster-ID** nicht nur Punkt — Resize während Freeze sonst tot.
24. **Pose als Hold-SM** Unseen / Tentative / Held / Released — statt 12 Bools.
25. **Format-Probe beim Start** vor dem ersten 8-fps-Sample, nicht erst Cooldown.
26. **Clutch-Radius × dt** — Jiggler 1,2 px bei 8 fps ein Tick.
27. **Pointer-SourceID sticky** — Continuity uniqueID-Wechsel ohne Homographie-Reset wenn dieselbe Cam.
28. **Scroll-Coast vs Kill** — zwei offene Hände nach Coast nicht Not-Aus.
29. **Per-Finger Kontakt-Hysterese** — pinchFingerContact je Tip, nicht nur q.
30. **Kalman-P HUD** — freezeVelChip um σ, nicht nur →/←.

## In 1.6.39 erledigt

1.6.38 Zwei-Hand-Freeze / Clutch / Vel / lastZ. Approach-Veto vor Reach. Gate Close 0,55 hart. Kein Finger-Kontakt. Occluded Tips → z. pinchRatio ohne q.

1. **pinch3DVeto** Reach skippt Approach.
2. **pinchFingerContact** + **pinchClosednessNeed** im Gate.
3. **pinchRatioSmooth × quality.**
4. **Tip-Konfidenz** vor zSep/Approach.
5. Tests + MARKETING_VERSION 1.6.39 (Build 72).

## In 1.6.38 erledigt

1.6.37 Format / Residual / Sign / q-Chip / One-Euro / Tastatur-Ring. Freeze nur Actor-Δ. Jiggler weckt Geist. Predict unsichtbar. lastZ bei Occlusion weitergeschrieben.

1. **freezePalmsPredict** + **freezeGhostDeltas** (Zwei-Hand).
2. **clutchIgnoresFreeze.** Jiggler seize tot während Freeze.
3. **freezeVelChip** →/←/↓/↑.
4. **liftSignKeepsPrevious** lastZ nicht bei Residual hoch.
5. Tests + MARKETING_VERSION 1.6.38 (Build 71).

## In 1.6.37 erledigt

1.6.36 Approach-Veto / Recover-Sprung / Faust-Grace. Format-Lock warf Continuity < 24 fps. PinchGate 2D. Lift-Sign kippte. Residual tot. HUD ohne q. Tastatur-Ring 3 px.

1. **cameraFormatScore** — 720p@24 vor 1080p@8.
2. **pinch3DTrusts** + residual in Looks/Starts/Holds/Gate.
3. **liftSignHolds** Optional — kleines pred → Anatomie.
4. **pinchRatioSmooth** One-Euro.
5. **qualityChip** HUD. **AirKeyboard** Ring × dt.
6. Tests + MARKETING_VERSION 1.6.37 (Build 70).

## In 1.6.36 erledigt

1.6.35 Closedness×q / Predict / Ring. Actor ohne z. Veto tötete echte Pinzette. Recover nur Breite. Heranziehen nur Y. Faust-Scharf 0,22 s.

1. **pinch3DApproach** + Veto nach Reach.
2. **pinchActor** zSep/Approach/Need.
3. **emptyHandsRecoverPalmJump.**
4. **pullTowardPalmGrow.** **fistScharfGrace(dt).**
5. Tests + MARKETING_VERSION 1.6.36 (Build 69).

## In 1.6.35 erledigt

1.6.34 Ampel × dt, 3D-Pinch, Freeze-HUD. Closedness ohne q. Freeze-Geist stand. Ring 6 px bei 8 fps.

1. **pinchClosednessNeed(quality, start).** q < 0,55 hebt Tor.
2. **pinchStartsGrab / pinchHoldsGrab** `quality`. Faust mit toten Spitzen kein Klick.
3. **freezePalmPredict** + **TrackedHand.shifted**. Recover ohne Teleport.
4. **chromeDwellRingWidth(dt).** 8 fps dicker.
5. Tests + MARKETING_VERSION 1.6.35 (Build 68).

## Erweiterung (neu)

1. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC, eine Session. P0.
2. **DisplayLink 90 Hz HUD**, Kamera 8–24 fps. Overlay-Lerp unabhängig.
3. **HeliosAegisKit** gemeinsamer Broker + Mutex-PTS.
4. **LiDAR-Pinch** (DepthCapture) statt nur Landmark-z. Residual-Gate 1.6.37 ist Lift3D.
5. **IOHID Event-Tap / AX SetPosition / Per-App Gain** (`bugfix`, opt-in).
6. **JSONL Session-Replay** Gesten-Regression.
7. **Kalman-Palme während Freeze** statt Vel-Decay (Predict 1.6.35/1.6.38).
8. **AX-Hit-Cache 1 Frame.** Continuity 8 fps sonst hitTest jeden Tick.
9. **MediaPipe Hands Sidecar** — VNDetectHumanHandPose verliert Spitzen.
10. **Palm-Scale EMA** — 8 fps palmWidth-Jitter skaliert Reach/Gate.
11. **Pointer-Gain × dt** — ein Continuity-Tick sonst Teleport trotz Freeze-Decay.
12. **Per-Hand q-Chip** — qualityChip 1.6.37 nur Actor/primary.
13. **Format nach Session neu verhandeln** wenn gemessene fps < 12 trotz Score.
14. **Hand-ID über Continuity-Reconnect** — Slot stirbt, Pinch-Lock weg.
15. **Zwei-Pinzetten Freeze-Span** — Zoom-Anker nicht tot nach einem Miss.
16. **Helios liest Aegis leftover-Boxen** als Palm-Occlusion.
17. **Aegis-Yaw als Helios Click-Lock** — Blick weg = kein Klick.
18. **pinchBecameDrag × dt** — Click-vs-Zug-Schwelle ein 8-fps-Tick.
19. **SpaceMap Re-Calib** wenn Palm-Aspect nach Drehung kippt.
20. **Two-pinch vs scroll hysteresis** — offene Hand + Coast darf Pinch-Start nicht fressen.
21. **Wrist-IMU via Watch** für Pinch-Confirm wenn Vision-Spitzen tot.
22. **Homographie Online-Nachzug** 4 Anschläge unsichtbar nach 20 s Pointer-Clutch.
23. **DepthCapture an Continuity LiDAR** wirklich verdrahten (Datei ist Stub).

## In 1.6.34 erledigt

1.6.33 Klick/Zwei-Pinzetten/Tastatur × dt. Ampel 0,55 s / 18 px. Faust-in-Kamera 2D-Pinzette. HMM 0,70 Faust bei q tot. Freeze-HUD leer.

1. **chromeDwellNeed(dt) / chromeDwellStillNeed.** 8 fps und 5K.
2. **pinch3DSep + pinch3DVeto** in pinchLooksLikePinch.
3. **PoseHMM.qualityScale** q < 0,55.
4. **freezeLive** dim + Geisterhand.
5. **fpsSparkBars** HUD. **twoPinchAxisChip** H/V.
6. Tests + MARKETING_VERSION 1.6.34 (Build 67).

## In 1.6.33 erledigt

1.6.32 Continuity-Uhr für HMM/Temporal/Release. Klick 50 ms, Zwei-Pinzetten 120 ms, Tastatur 120 ms = ein 8-fps-Tick.

1. **pinchClickMinNeed(dt).** 8 fps ≥ 150 ms.
2. **twoPinchConfirmNeed(dt).** 8 fps zwei Frames.
3. **keyboardDwellNeed(dt).** Vorbeifliegen tot.
4. **Klick-Cooldown** = pinchReleaseNeed(dt), nicht hart 120 ms.
5. Tests + MARKETING_VERSION 1.6.33 (Build 66).

## In 1.6.32 erledigt

1.6.31 Dropout-Klick tot, Recover sichtbar. Continuity 8 fps: HMM 50 ms, Temporal 12 Frames, Release 120 ms, Recover-Gain ignoriert Palm-Sprung.

1. **PoseHMM.switchHold(dt) / pinchTau(dt).** 8 fps zwei Frames, nicht jeder Tick.
2. **TemporalNet.maxAge 0,80 s.** Fenster in Sekunden. 8 fps 3 Frames reichen.
3. **pinchReleaseNeed(dt).** 8 fps ≥ 200 ms.
4. **emptyHandsRecoverPalmMul** + HUD `P drop`.
5. Tests + MARKETING_VERSION 1.6.32 (Build 65).

## In 1.6.31 erledigt

1.6.30 Cover-Maps / preparePair. Freeze trug pinchHeld. Recover unsichtbar.

1. **emptyHandsHoldDropsPinch.** Dropout droppt Gate, Mute wie Loslassen.
2. **emptyHandsRecoverChip** `R1`/`R2` während recoverUntil.
3. Tests + MARKETING_VERSION 1.6.31 (Build 64).

## In 1.6.27 erledigt

1.6.26 Gain nach Dropout einen Tick, AX-Zug blieb stehen, Coast über Pinch, Achse nur Bool, fps-Amber instant.

1. **Recover-Span 2 Frames.** `emptyHandsRecoverSpan` / `emptyHandsRecoverLive`.
2. **emptyHandsHold gibt AX frei** (`emptyHandsHoldReleaseAX`), Cursor freeze bleibt.
3. **Zwei-Pinzetten-Achse** `twoPinchAxis` + Lock. Jitter kippt nicht horizontal↔vertikal.
4. **`scrollCoastBreaks`** bei Pinch — Inertia tot vor Gate.
5. **fps-Spark 8 s.** Mittel < 10 → amber.
6. Tests: Recover-Live, AX-Release, Coast-Break, Achse, Spark.
7. MARKETING_VERSION 1.6.27 (Build 57).

## In 1.6.26 erledigt

1.6.25 freeze ohne Pinch — Palme teleportierte nach Dropout. Ein Tick Zoom. Fling erbte Zwei-Pinzetten-Trail. Scroll hart tot. fps 8 unsichtbar.

1. **Freeze-Decay.** `emptyHandsHoldGain` / `emptyHandsRecover` — erster Frame nach Miss nicht voller Gain.
2. **Zwei-Pinzetten Kanten 2–3 Frames** (`twoPinchConfirmFrames`). Trail leer beim Ausstieg.
3. **Scroll-Totzone 0,08** + **Inertia 200 ms**.
4. **HUD fps amber** unter 10.
5. Tests: Gain, Recover, Edge-Hold, Coast, fpsAmber.
6. MARKETING_VERSION 1.6.26 (Build 56).

## In 1.6.25 erledigt

1.6.24 hat Scroll/Miss/Release/HUD-Freeze — der Zeiger starb trotzdem ohne Pinzette (Continuity 8 fps). Local-Clutch sah eigene Events. PTS fehlte. uniqueID-Wechsel behielt die alte Homographie. Fling first→last verdünnte den Ruck. Zwei-Pinzetten am Palmenabstand.

1. **emptyHandsHold ohne Pinch.** Zeigen überlebt zwei Fehlframes. HUD `freeze`.
2. **Clutch nur global.** Jiggler < 1,2 px ignoriert.
3. **`presentationTimeStamp` als Engine-`now`.** FPS bleibt Wall-Clock.
4. **uniqueID-Wechsel** → `recenterPointer` + Homographie neu.
5. **Zwei-Pinzetten** an gegenüberliegenden Fensterhälften.
6. **`flingVelFromTail`** letzte 2–3 Samples.
7. MARKETING_VERSION 1.6.25 (Build 55).

## In 1.6.24 erledigt

1.6.23 hat Profile tot / Lock freeze / Zwei-Pinzetten sortiert — Scroll kollidierte mit Not-Aus (beide zwei offene Hände). `pinchActor` Miss auf Wanduhr. Folge-Klick aus dem Gate-Auf. HUD ohne Freeze-Chip.

1. **`scrollAllowed` genau 1 offene Hand.** Zwei offene = Kill, Scroll-Anker weg. Nur Steuerhand (bzw. die eine offene).
2. **`pinchActor` Miss = `lastTickNow`**, nicht `CACurrentMediaTime`. `missHeld(now:since:)` teilen Engine und Tests.
3. **`pinchReleaseDead` 0,12 s** nach Gate-Auf.
4. **HUD Lock-Chip** `lockFreezeLabel` → `T1 freeze`.
5. Tests: scrollAllowed, missHeld, pinchReleaseDead, lockFreezeLabel.
6. MARKETING_VERSION 1.6.24 (Build 54).

## In 1.6.23 erledigt

1.6.22 hat Reach/Ampel, aber Profile wieder an (Tests .full **und** .off), Lock-ID tot nach einem Frame, Zwei-Pinzetten unsortiert, empty-hold 0,18 s.

1. **AppInjectProfile.of = .full.** Xcode/Safari nicht mehr stumm. Widersprüchliche Tests raus.
2. **preferredHoldID** hält Lock `pinchLockMiss`.
3. **twoPinchSorted** nach Track-ID.
4. **emptyHandsHold(dt)** ≥ pinchLockMiss, 8 fps × 2,2.
5. MARKETING_VERSION 1.6.23 (Build 53).

## In 1.6.22 erledigt

1.6.21 hat Gate-statt-Pose — Faust schloss das Gate trotzdem (Spitzen nah = closedness), HMM-`max` hielt Pinch, Heranziehen im Klick-Fenster, Ampel während des Zielens, Profile tot, Tor 0,48.

1. **PinchGate + Greifen brauchen Reach** (`pinchReachNeed` 0,88) oder Zeigefinger. Faust-Spitzen an der Palme schließen nicht.
2. **`pinchClosedness` nur Gate**, nicht `max(HMM, Gate)`.
3. **`pinchActor` kein Faust-Fallback**, keine Pose-Pinzette ohne Reach.
4. **Heranziehen nur nach Drag** ≥ 0,35 s.
5. **Ampel-Verweilen nur still** (`chromeDwellStillPx` 18). `chromeHot` stirbt mit den Händen.
6. **App-Profile wieder an** (Xcode aus, Safari Klick/Scroll, Finder Werfen).
7. **Aktions-Tor 0,52–0,68.** Cover-Pinch nur 0,40–0,62.
8. **Gate öffnet bei Faust** (`!looksPinch`). Halten ohne Drag braucht Reach; Zug darf Faust tragen.
9. **`indexScore` Float** vom Classifier, nicht das 0,52-Set.
10. MARKETING_VERSION 1.6.22 (Build 52).

## In 1.6.21 erledigt


Erkennung: Faust startete Zug, HMM hielt Pinzette offen, Cooldown fror Drag, Cover überschrieb Gate, Not-Aus bei Scroll, Tastatur beim Zielen.

1. **pinchClosed = PinchGate**, nicht HMM-EMA.
2. **Greifen nur Gate/Closedness**, nicht `pose == .pinch` / Faust.
3. **HMM-Hold** lässt Pinzette fallen, wenn Closedness < 0,40.
4. **Cooldown** ruft `driveGrab(fire: false)` — Zug lebt, kein Extra-Klick.
5. **Cover** ändert `pinchClosed` nicht.
6. **killPalmStill 0,14** — Scroll setzt Not-Aus zurück.
7. **Tastatur still** (< 16 px) vor dem Tippen.
8. MARKETING_VERSION 1.6.21 (Build 51).

## In 1.6.19 erledigt

1.6.18 Ampel/Tastatur — Continuity 8 fps log, Steuerhand sprang, zweite Ampel-Annäherung tot, Mittelfinger zog Fenster, Tastatur feuerte beim Zielen.

1. **dt-Cap 0,20 s** in LandmarkSmoothing, PinchGate, HandTracker, SpaceMap, Engine. 125 ms nicht auf 80 ms.
2. **`preferredID` Lock zuerst**, dann L/R. Chirality-Flip teleportiert nicht.
3. **`pinchActor` friert** (`pinchLastHand`), nie `primary` der anderen Hand.
4. **`chromeDwellKind` reset** beim Verlassen und nach dem Feuern — zweite Annäherung zählt neu.
5. **Heranziehen = Palm-Y** (`pullToward` 0,11). Mittelfinger-Spannweite ist tot.
6. **`flingWindowLen(medianDt)`** — 8 fps ≥ 2 Frames.
7. **Luft-Tastatur 0,85 s unten** (`airKeyboardSummon`). 0,40 s irgendwo ist tot.
8. MARKETING_VERSION 1.6.19 (Build 49).

## In 1.6.18 erledigt

Ampel 118 px / 80 px, 0,55 s Verweilen. Luft-Tastatur QWERTZ. Totzone 2D (Schrägzug). Wischen weicher.

## In 1.6.14 erledigt

Warum 1.6.13 weiter falsch klickte und Gesten verschluckte: Pinzette-Lock fiel bei einem verlorenen Frame auf die **Steuerhand** (Kommentar sagte das Gegenteil). Fusion-Entropie fehlte — flaches Softmax blieb ≥ 0,62 und `perform()` feuerte Zufall. Continuity 8 fps nutzte denselben Hochpass wie 24 fps. HMM-Hold gab die verdünnte `next[current]` als Pose-Prob, also blockte das 62-%-Tor die gehaltene Faust.

1. **Pinzette friert.** Fehlende Lock-ID → letzte Hand, nie `primary`. Fehlklick der anderen Hand ist tot.
2. **Aktions-Tor an Entropie.** Spitz 0,55 / flach 0,72. HUD zeigt H und Tor.
3. **Hochpass × dt.** 8 fps Alpha hoch, Deadzone ×1,55. Ecken 2 % Ruhezone.
4. **Hände auf dem Tisch** 1,2 s unten still → Idle, kein Not-Aus.
5. **Per-App-Profil.** Xcode aus, Safari Klick/Scroll, Finder Werfen. HUD + Konsole.
6. **HMM-Hold behält lastRealProb** — unknown drückt die Pose nicht unter das Tor.
7. MARKETING_VERSION 1.6.14 (Build 44).

## In 1.6.13 / 1.6.12 erledigt

Konsole stiehlt den Vordergrund nicht mehr. Nur direkte Wahl (Fenster, ☀, Dock) holt sie nach vorn. Standard: sichtbar auch bei Scharf.

## In 1.6.11 erledigt

Konsole wirkte tot, Cmd+Q traf die App darunter, Osmo ohne Livestream.

- Beenden über Dock/Menü. Konsole bleibt bis man sie schließt.
- Osmo als zweites Bild, Cover wählbar.

## In 1.6.10 erledigt

Die Installations-DMG fehlte unter Releases (Tests rot). Faust mit eingerollten Fingern war Pinzette.

- Fling-Totzone nur Mini-Ruck in der *kalibrierten* Schirmmitte.
- Faust ≠ Pinzette: Pinzette braucht gestreckten Zeigefinger.
- HMM hält die letzte echte Pose; Track stirbt nach 0,18 s.
- Build: Tiefenkanal iOS-only.

## In 1.6.9 erledigt

- Zwei `AVCaptureSession`s: Mac+iPhone, Mac+Osmo, iPhone+Osmo ohne Mac.
- Kalibrierung **pro Kamera** (eigene Homographie = Blickwinkel/FOV/Spiegelung).
- Winkel-Unco: >140 px Abweichung → Lead, kein Blend.
- Cover nur wenn Lead die Hand verliert.

## In 1.6.8 erledigt

Warum 1.6.7 sich tot anfühlte, sobald die zweite Hand im Bild war: Not-Aus zählte 0,8 s jede zwei offenen Hände und **return true während des Zählens** — Klick, Wischen, Skalieren starben. Körperpose überschrieb Vision L/R schon bei Verhältnis 0,72 → Steuerhand-Tausch → Cursor-Teleport. Softmax/HMM hatten `.unknown` mit Logit 0,35, Pose fiel unter das 0,62-Tor.

- **Not-Aus nur nach 1,35 s** zwei `openPalm`, Abstand ≥ Klatschen-offen, still. Während des Haltens laufen andere Gesten weiter. Pinzette / Zwei-Pinzette überspringt. Grace blockt nicht.
- **Körper-Vote nur bei Vision-unbekannt oder Verhältnis < 0,50.** Schwacher Wrist-Treffer kippt die Steuerhand nicht mehr.
- **Cursor bleibt** beim Track-Wechsel: Palme neu verankern, `cursorSmooth` behalten.
- **unknown-Logit −1,8.** HMM hält die aktuelle Pose, wenn unknown schwach führt.
- **palmWidth-EMA** pro Track (0,22) — Fling/Wischen bei Webcam-Zoom stabil.

## In 1.6.7 erledigt

Warum es sich tot anfühlte: `leftHanded = true` (Prefs-Fallback auch), Vision L/R ohne Körper-Vote, kalibrierte Homographie 100 % absolut (Mitte zittert), Clutch hat eigene `mouseMoved` bei <12 fps als Hardware gewertet, linearer Gain, Fling-Totzone an der Kameramitte, Log „70 %“ bei Tor 62 %.

- Default **Rechtshänder**. Prefs-Fallback `false`.
- **Körperpose-Vote** für Chirality (`leftWrist`/`rightWrist`, Verhältnis < 0,72).
- **SpaceMap hybrid** äußere 15 % absolut / innen Relativ. **Per-Display-ID**.
- **Clutch:** 48 px + 120 ms um letzten eigenen CGEvent, Delta < 0,5 ignoriert.
- **Pointer-Accel** (quadratisch). Fling-Totzone am **Schirmmittelpunkt** wenn kalibriert.
- Fusion-Temperatur Slider. Peace-Ring, Clutch-LED. Log „Pose < 62 %“.

## In 1.6.6 erledigt

- 2× klatschen (sichtbar, Palmenabstand) weckt Scharf im Hintergrund. Kein Mikrofon.
- Not-Aus nur mit Händen auseinander — Kontakt ist Klatschen.
- Kamera-Keep-Alive, damit Idle/Accessory weiter Frames bekommt.

## In 1.6.5 erledigt

- App-Umriss ist kein Fenster: Standard aus, nur Greifen, kein Schreibtisch, keine Höhen-Animation.
- Konsole kommt nach Scharf nicht zurück (Key/Main-Wächter).
- Wischen landet nicht per ⌘⇥ im System-Umschalter.
- Zwei-Pinzetten-Skalieren ohne Höhen-Pumpe (0,55 + Gegenrichtungs-Sperre).
- Konsolen-Höhe nicht mehr vom Inhalt getrieben.

## In 1.6.4 erledigt (Sitzung 2026-09-02)

- Pinzette bleibt an der Hand, die das Gate geschlossen hat.
- Klick wenn still (< 0,45 Handbreiten / 14 px), Zug erst darüber.
- Fling nach echtem Fensterzug braucht 2,4× Schwelle — Ablegen ist kein Minimieren.
- Wischen: Mute 0,75 s nach Pinzette, Gegenrichtung 1,1 s, nur Steuerhand.
- Zwei-Pinzetten 80 ms / `pinchClosedness`.
- Peace 1,1 s, nur allein auf der Steuerhand.
- Konsole bei Scharf aus, HUD-Panel wird nie Key.
- Kalibrierung akzeptiert den persönlichen Anschlag.
- Chrom-Loupe + Magnet an Schließen/Mini/Zoom.
- Kamera-Picker (Mac / Kontinuität / Desk View / USB).

## In 1.6.3 erledigt (aus 1.5.8 `bugfix`, nicht nochmal mergen)

`bugfix` / PR #1 war 1.5.8 gegen 1.5.7. `main` ist 1.6.2 — Fusion, Handbreiten, Flick, Dropout. Roh mergen würde das zerlegen.

| 1.5.8 | 1.6.2 vorher | 1.6.3 |
|---|---|---|
| Fling-Fenster 120 ms | first→last über 0,5 s Trail (Bug) | Fenster, in **Handbreiten** |
| Totzone Bildmitte | fehlte | nur Mini-Zucken; Wurf aus der Mitte bleibt |
| Dead-Man 8 s | nur 180 ms Dropout | 8 s → Idle + Rearm |
| Palm-Hochpass + Dead 0,012 | Dead 0,003, kein Hochpass | Hochpass am Relativ-Zeiger, Totzone auch SpaceMap |
| Wischen `openScore ≥ 3` | `≥ 2` (Peace wischte) | ≥ 3, Flick-Zahlen aus 1.6.1 |
| Kill-Grace 0,14 s | 0,28 s hart | 0,14 s |
| `videoRotationAngle` | Vision immer `.up` | Winkel nach dem Format |
| HUD Kalibrierung fehlt | fehlte | Zeile in der Top-Bar, Relativ läuft |
| Peace 0,80 / Clutch 1,2 s | Peace 0,90 / Clutch 0,85 | **behalten** — 1.6.x ist hier besser |
| CI auf `bugfix` | — | **nicht** — nur `main` |

## In 1.6.2 erledigt

Koordinaten, AX, Threads, HUD — nicht die Erkennung (die war 1.6.0/1.6.1).

1. **localRect** nimmt Quartz-minY als Overlay-oben. Umriss, Greifstrahl, `intersects` lagen eine Fensterhöhe zu tief. Tests decken Haupt- und Zweitbildschirm ab.
2. **AX ohne Force-Cast.** `CFGetTypeID` vor jedem `AXUIElement`/`AXValue`.
3. **Main nicht blockieren.** `screencapture` und Finder-AppleScript vom Hauptthread, xattr beim Start auf Utility-Queue. Fensterzug koalesziert (letzter Punkt, Timeout auch am Drag-Element).
4. **dlopen einmal.** Installationsort/Translokation gecacht, nicht pro Cursor-Frame.
5. **PinchGate und HMM** resetten beim Handverlust. Kalibrier-Hold nur mit Pinzette.
6. **Export** löscht keinen bestehenden Ordner rekursiv.
7. **mirroredFlag** hinter demselben Lock wie der Frame-Handler. `apply()` koalesziert wie FramePump (letzter Stand, Vision-Zeitstempel).
8. **README** zeigt auf `lolalpha00gamma/Helios`. Homographie gecacht. Rechte-Demand ohne modalen Alert. Klick-Pause und Pinzette-ohne-Zug sind kein Fehler im Protokoll. `snapFocused` am Engine-Cursor. Wischen nimmt keine Faust. Vision-Revision gepinnt, `usesCPUOnly` weg. Luma über CIAreaAverage. Toter Code (HandBeacon, Reticle, missionControl) raus. Fadenkreuz steuert den Hand-Marker. permTimer und Clutch-Monitore werden beim Beenden abgemeldet. Maus-Clutch auch bei `mouseMoved`.

## In 1.6.1 erledigt


1. **Korrelierte Fusion.** Lift3D und Temporal-Heuristik sind dieselben 2D-Punkte (plus klebriges z-Vorzeichen). 1.6.0 hat sie als unabhängige Stimmen gepoolt → flaches Softmax → Pose < 70 % → `perform()` hat *jede* Systemaktion blockiert. Jetzt: 2D führt (0,62), Lift/Zeit kollabieren bei >80 % Überlappung, Softmax-Temperatur 0,75, Tor 62 %.
2. **Kein Chirality-Doppel-Flip.** Der Frontkamera-Buffer ist schon `isVideoMirrored`. Ein zweiter L/R-Tausch hat Linkshänder die rechte Hand als Steuerhand gegeben. Unbekannt fällt auf Bildposition, gespiegelt vs. ungespiegelt getrennt.
3. **Zwei-Pinzetten nach 0,35 s** belegen den Tick weiter — sonst feuern Klick und Wischen während des Skalierens.
4. **Track-Zuordnung 0,42** (war 0,22 iso) plus Chirality-Bonus. Flicks verlieren die ID nicht mehr.
5. **HMM** τ=0,11 s, Umschalten ab p≥0,48 / 50 ms. 0,62 + 180 ms hat Gestenwechsel verschluckt.
6. **PinchGate.** Occludierte Spitzen halten max. 0,32 s zu, nicht ewig.
7. **Dropout 180 ms.** Ein verlorener Vision-Frame beendet Drag nicht mit einem Fehlklick.
8. **Scroll / Rechtsklick / Dwell** wirklich verdrahtet (1.5.8 hatte sie nur in der README). Dwell aus by default.
9. **HUD:** Idle-Banner nach Not-Aus, Latenz-Sparkline (30 Frames), Fusion zeigt kollabierte Quellen.
10. **Not-Aus und Zwei-Pinzetten** bewegen den Cursor weiter.

## In 1.6.0 / 1.5.8 / 1.5.7 erledigt (nicht nochmal bauen)

Fusion 2D/3D/Tiefe/Zeit verdrahtet. AX in Cocoa. Flick-Wischen. Faust-Scharf ohne Folge-Klick. Cooldown friert den Cursor nicht ein. Not-Aus 0,8 s. Chirality teilt sich keinen Smoother. Maus-Clutch inkl. `mouseMoved`. Peace 0,9 s.

## Nächste Fixes (klein, hoher Nutzen)

- **chromeDwellHold × dt** — 1.6.34 `chromeDwellNeed` / `chromeDwellStillNeed`. Rest: Ampel-Ring sichtbar skalieren.
- **3D-Pinch** — 1.6.34 Landmark-z Veto. Rest: LiDAR/`DepthCapture`.
- **HMM-Emission × Landmark-Qualität** — 1.6.34 `qualityScale`. Rest: Temperature-Closedness.
- **Session-Replay** der Landmark-CSV direkt im HUD, Frame für Frame — ohne Xcode.
- **Kalibrier-Quad sichtbar** als dünnes Viereck der vier Anschläge, nicht nur Ecken-Marken.
- **Peace-Fortschritt auch in der Konsole**, nicht nur HUD-Ring.
- **Klick-Tick** optional (system sound), aus by default.
- **Profil-Override** in der Konsole (Safari voll, Xcode nur Scroll) — Defaults bleiben `.full` (1.6.25).
- **Fusion-Temperatur auto** aus Landmark-Qualität, Slider bleibt Override.
- **Dünne Tastatur-Leiste unten** auch wenn zu — Sichtbares Ziel statt „irgendwo zeigen“.
- **palmArea als z-Proxy** neben Palm-Y für Heranziehen (Hand kommt auf die Kamera zu).
- **Zwei-Pinzetten nach Reach sortieren**, nicht `pinchRatio` allein.
- **Ein Filter am Zeiger.** Palm-Hochpass plus cursorSmooth stapeln Latenz.
- **Kalibrier-Anschlag speichert Closedness** der Person — 0,55 ist Mittelwert.
- **SpaceMap bei Display-Reconfig** lädt schon (OverlayController) — HUD-Chip wenn Homographie nach Kabel-Plug tot ist.
- **Cover-PTS und Lead-PTS gleiche Epoche**, sonst Fusion-dt lügt.
- **Clutch-Radius in mm**, nicht 48 px auf 5K.
- **Not-Aus-Ring** im HUD analog Peace (1,35 s sichtbar).
- **Faust-Scharf-Grace 1 Frame** wenn HMM auf unknown kippt (Continuity 8 fps).
- **Kill-Alternative beide Fäuste 0,4 s** — Tisch-Pose, wenn offene Palmen unmöglich sind.
- **Skeleton dim / Geisterhand / Achse H/V / fps-Spark** — 1.6.34.
- **Per-App Scroll-Invert** (Safari natural, Xcode classic) ohne Rebuild.
- **Auto-Nachkalibrierung** nach 20 min Drift (Palm vs. Homographie-Residual > 80 px).
- **Fling-Bestätigungs-Tick** optional, aus by default.
- **CGWarp-ACK** nach Warp sofort NSEvent lesen, RMS > reanchor nicht 4 Hz warten.
- **Temperature-Closedness.** q < 0,55 hebt pinchClosedness-Tor.
- **Kalman auf freeze-Palme.** Geisterhand steht, Predict fehlt.

## Größere Erweiterungen

- **CameraBroker IOSurface.** Ein Capture, zwei Subscriber (Helios + Aegis). Continuity 8 fps sonst zweimal Vision. P0.
- **HeliosAegisKit.** Shared Package: dt-Uhren, CoordMath, CameraBroker. Zwei Apps, eine TCC.
- **DisplayLink 90 Hz Overlay** unabhängig von Continuity 8 fps. Lerp schon da, Clock ist Kamera.
- **Shared XPC `helios.aegis.camera`** mit Aegis — eine TCC, ein Buffer. Größter einzelner Effizienzgewinn. (`bugfix` hatte den Ansatz, 1.5.7-Tree nicht mergen.)
- **MediaPipe Hands Sidecar** für Continuity 8 fps — VNDetectHumanHandPose verliert Spitzen, Reach fällt, Faust wird Pinzette.
- **Developer ID + Notarisierung.** Ohne das muss TCC nach jedem Update neu an.
- **pinch3D Rest-Tiefe.** Landmark-z ist 1.6.34. LiDAR/`DepthCapture` sobald ein Mac es hat — Datei existiert, Session hängt am Format.
- **VNTrackObjectRequest** Hand-Box über Dropout, nicht nur Landmark-Miss → freeze.
- **Session-Replay JSONL** (Tick, Pose, Aktion, dt) ohne Xcode. Analog Aegis Match-Log.
- **Clutch-Radius in mm**, nicht 48 px auf 5K. palmWidth × FOV.
- **Cover-PTS und Lead-PTS gleiche Epoche**, sonst Fusion-dt lügt.
- **VoiceOver-Ansage** der letzten Aktion, ausgeschaltet by default.
- **Fenstertiling über Stage Manager** statt nur AX-Snap.
- **Swift Testing** in Xcode, Gesten-Zeitreihen als Fixtures.
- **Echtes Temporal-CoreML** (`HeliosTemporal.mlmodel`) statt Heuristik. Ohne Modell bleibt Zeit ein 2D-Echo.
- **Zoom/Trackpad-Magnify** als Geste (Pinzette + offene zweite Hand).
- **Mission Control / Schreibtisch.** Drei Finger hoch / runter, hinter Extra-Schalter.
- **Apple Watch als Not-Aus.** Krone oder Action-Taste tötet Injektion, wenn die Kamera die Hände nicht sieht.
- **Umgebungslicht → HUD.** Bei dunklem Schreibtisch Overlay dämpfen, nicht den Bildinhalt überstrahlen.
- **Hand-Velocity-Prior** im HMM (schnelle Faust ist kein Pinch).
- **Zwei-Personen-Szenen.** Wenn Körperpose zwei Torsi sieht, zweite Hand nie als Steuerhand.
- **Hover-Dwell nur über AX-Knöpfen**, nicht frei auf dem Schreibtisch.
- **Desk-View als zweite Karte**, nicht als Steuerkamera (Aufsicht für Kill/Klatschen).
- **Gesten-Lexikon.** Nutzer hält 1,5 s eine Pose, speichert sie als benannte Aktion (ohne CoreML-Training).
- **Watch-IMU Fusion.** Handgelenk-Beschleunigung als Clutch/Kill, wenn die Webcam die Hände verliert.
- **Overlay auf Stage-Manager-Spaces** — AX sieht oft nur das aktuelle Space.
- **Cursor-Gain pro Display-PPI**, nicht eine Zahl für Laptop+5K.
- **Kill-Geste ein Finger-Y** (beide Zeigefinger kreuzen) als Alternative zu zwei offenen Palmen.
- **Osmo IMU** wenn USB das liefert — Cover-Winkel ohne zweite Homographie grob schätzen.
- **App-Profil JSON** neben Defaults, damit der Nutzer Xcode doch Scroll erlauben kann ohne Rebuild.
- **Fling-Richtung an Stage-Manager** (links = recent, nicht nur AX-Snap).
- **Kalman auf Palme während freezeLive** — Geisterhand 1.6.34 steht, Predict fehlt.
- **Zwei-Pinzetten-Scale in mm**, nicht Pixel. 5K sonst Zoom aus Jitter.
- **AX-Hit-Cache 1 Frame.** Continuity 8 fps sonst hitTest jeden Tick.
- **Gesture-Fixture Replay** aus JSONL in CI, nicht nur Unit-Schwellen.
- **Per-Finger Kontakt** (Daumen–Index / palmWidth) statt nur Closedness-Skalar.
- **Temperature-Closedness.** q < 0,55 hebt pinchClosedness-Tor, analog HMM qualityScale.
- **VNDetectHumanBodyPose** als Prop-Veto (Gitarre, zweite Person).
- **Cursor-Magnetismus** 8 px an AX-Hit, optional, aus by default.
- **Match-Log JSONL** analog Aegis (Tick, Pose, Aktion, dt) für Sitzungs-Replay ohne Xcode.
- **Per-Display pointerGain** aus `CGDisplayPixelsWide` / mm, nicht ein Slider für Laptop+5K (steht oben, hier der Haken: SpaceMap ist schon per Display).
- **Zwei-Finger-Doppeltipp** (Index+Mittelfinger kurz) = Doppelklick, ohne zweite Pinzette.
- **Scroll an Handgelenk-Roll** (MCP-Linie) statt nur Palm-Y, weniger Konflikt mit Heranziehen.
- **HUD Latenz pro Kamera** (Mac vs Continuity), nicht eine Sparkline.
- **Kalibrier-Hold skaliert mit dt** schon 1.6.19 — visuelles Quad der vier Anschläge fehlt noch.
- **Reach-Meter im Debug-Chip** (0,3 Faust … 1,2 Pinzette), damit Faust-vs-Pinch ohne Konsole sichtbar ist.
- **Klick-Preview-Ring** 80 ms vor Gate-Schluss (Hover sitzt, bevor Down kommt).
- **AX-Drag coalescen** auf den letzten Punkt/Tick, nicht jeden 8-fps-Sprung als setPosition.
- **Dominant-Hand aus den ersten 30 Faust-Frames**, nicht nur Prefs-Toggle.
- **SpaceMap 1-Punkt-Nachkalibrierung** (nur Drift-Ecke) statt 4 Ecken neu.
- **Inspector: looksPinch + Reach** neben Closedness, damit Faust-vs-Pinch ohne CSV klar ist.
- **Klick/Drag-Schwelle als Slider** (Handbreiten), Default 0,45 bleibt.
- **Palm-mm aus palmWidth × FOV**, Clutch/Kill in physikalischen Einheiten.
- **AX-Drag Timeout < sampleDt** — 8 fps sonst ein Sprung pro Tick, Coalesce greift nie.
- **Space-Wechsel invalidiert focused Window** — Stage Manager lässt den Zug am Phantom.
- **Watch-IMU Pinch-Confirm** wenn Continuity die Spitzen verliert.

## Nicht tun

- Stimme / Diktat als Geste — kollidiert mit Kill und Peace.
- Mehr als zwei Hände. Vision max. 2 ist die ehrliche Grenze.
- Cursor während Pinch-Hold einfrieren (war Absicht für Klick-Zielen — bleibt).
- Fusion-Dateien wieder aus dem Target nehmen.
- Lift3D und Temporal wieder als unabhängige Voter mit Gewicht ≥ 0,25.
- Aktions-Tor wieder auf 70 % ohne die Fusion zu schärfen.
- `tick` bei Cooldown wieder komplett returnen — der Cursor muss laufen.
- Faust nachträglich zur Pinzette ummappen.
- PR #1 / Branch `bugfix` mergen — 1.6.3 hat die fehlenden Stücke, der Branch ist 1.5.7.
- Not-Aus wieder `return true` während des Zählens.
- Körperpose Vision L/R immer überschreiben.
- `.unknown` wieder mit positivem Softmax-Logit.
- Cursor bei Track-ID-Wechsel auf die neue Palme teleportieren.
- Pinzette-Lock auf `primary` fallen lassen, wenn die Hand einen Frame fehlt.
- Aktions-Tor wieder hart 0,62 ohne Entropie.
- HMM-Hold `next[current]` (verdünnt) als Pose-Prob zurückgeben.
- Hochpass 0,08 unabhängig von Frame-dt.
- Per-App-Profil wieder alle Aktionen in Xcode/Safari.
- dt wieder auf 80 ms kappen (Continuity-Vel lügt).
- `preferred()` nur L/R, Lock-ID ignorieren.
- `pinchActor` wieder `?? primary` der anderen Hand.
- `chromeDwellKind` nach Feuern/Verlassen stehen lassen.
- Heranziehen wieder über Mittelfinger-Spannweite.
- Fling-Fenster hart 120 ms bei 8 fps.
- Luft-Tastatur wieder 0,40 s Zeigen irgendwo.
- Branch `bugfix` anlegen oder mergen. Nur `main`.
- Faust-Spitzen (Reach < 0,88) als PinchGate-Close.
- `pinchClosedness = max(HMM, Gate)`.
- `pinchActor` Faust-Fallback oder `pose == .pinch` ohne Reach.
- Heranziehen im Klick-Fenster / vor Drag.
- Ampel-Dwell während der Cursor noch wandert.
- `AppInjectProfile.of` immer `.full`.
- Aktions-Tor wieder 0,48.
- Cover-`pinchAssist` unter Lead 0,40 (erfinden).
- PinchGate geschlossen lassen, wenn Reach/Index Faust sind.
- `pinchHoldsGrab` Faust vor Drag (Klick wird Zug).
- `indexScore` wieder 0,7/0,15 aus dem Extended-Set.
- Scroll wieder zwei offene Hände (Not-Aus-Kandidat).
- `pinchActor` Miss-Stempel `CACurrentMediaTime`.
- Gate-Auf ohne Release-Tot (Folge-Klick).
- Lock-Freeze ohne HUD-Chip.
- Freeze nach Dropout mit vollem Gain (Teleport).
- Zwei-Pinzetten-Zoom an einem Jitter-Tick.
- Pinch-Trail nach Zwei-Pinzetten stehen lassen.
- Scroll ohne Totzone / ohne Coast.
- fps unter 10 ohne HUD-Farbe.

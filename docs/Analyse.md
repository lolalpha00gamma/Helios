# Analyse, Fehlerbehebung, öffentlicher Abgleich

Stand: 2026-09-08. Helios **1.6.55** (Build 88). Nur `main`. `bugfix` ist 1.5.7 — nichts mergen.

## 0. 1.6.55 — Adaptive Gain, HUD-Sharing, Edge-Resistance, Display-Gap

1.6.54: Per-Display Scale, Deadzone×Scale, Momentum, Homographie-Rotation, Click-Energy. Danach zitterte der Zeiger bei Continuity 8 Hz (Gain unterschied Rauschen nicht von Intent). HUD landete in Screenshots. `stepCursor` nutzte die Union inkl. Bezel — Cursor starb zwischen 5K und Sidecar. Rand = hartes Clamp.

| # | Bug | Fix |
|---|---|---|
| 1 | 8 Hz Jitter = Teleport | `pointerGainAdaptive` × `jitterRms` |
| 2 | HUD in Screenshot | `sharingType = .none` |
| 3 | Rand clamp tot | `edgeResistance` 0,35 |
| 4 | Bezel-Lücke | `stepCursor` aktueller Schirm + `displayGapWarp` |

Nicht: CameraBroker, IOHID, Overlay-Metal, LiDAR-Pinch, MediaPipe.

# Analyse, Fehlerbehebung, öffentlicher Abgleich

Stand: 2026-09-08. Helios **1.6.54** (Build 87). Nur `main`. `bugfix` ist 1.5.7 — nichts mergen.

## 0. 1.6.54 — Per-Display Scale, Deadzone×Scale, Scroll-Momentum, Homographie-Rotation, Click-Energy

1.6.53: Pointer×Scale, Scroll-Ticks×Scale, Rotation-Nudge, Click-Hitch — immer `NSScreen.main`. Sidecar 1× erbte 5K-Gain. Deadzone UV unabhängig von Scale. Zwei-Pinzette starb beim Loslassen. Nudge wischte den ganzen Homographie-Store. Klick nur über Halt-Dauer.

| # | Bug | Fix |
|---|---|---|
| 1 | Scale immer Main | `ScreenGeometry.backingScale(quartz:)` |
| 2 | Deadzone 1× auf Retina | `deadzoneScaled` |
| 3 | Two-pinch ohne Coast | `twoPinchScrollMomentum` → scrollCoast |
| 4 | Nudge = Store-Wipe | Cache keyed by `spaceMapRotationKey` |
| 5 | Klick = nur Dauer | `clickEnergy` × Closedness × Still |

Nicht: CameraBroker, IOHID, Overlay-Metal, LiDAR-Pinch, MediaPipe.

# Analyse, Fehlerbehebung, öffentlicher Abgleich

Stand: 2026-09-08. Helios **1.6.53** (Build 86). Nur `main`. `bugfix` ist 1.5.7 — nichts mergen.

## 0. 1.6.53 — Pointer×Scale, Scroll-Ticks×Scale, Rotation-Nudge, Click-Hitch

1.6.52: Two-pinch Hysterese, Rotation-Wipe, CGEvent 90 Hz. Danach teleportierte der Zeiger auf 5K. Scroll-Ticks zu dünn auf Retina. 90°-Drehung wischte die Kalibrierung. Continuity-Miss = Doppelklick.

| # | Bug | Fix |
|---|---|---|
| 1 | Pointer-Gain unabhängig von Scale | `pointerGainScaled` / backingScaleFactor |
| 2 | Scroll-Ticks 1× auf 5K | `twoPinchScrollTicks(scale:)` |
| 3 | 90° Wipe | `spaceMapRotationNudge` + Palmen halten |
| 4 | Hitch = Double-Click | `clickHitchNeed` / `clickHitchFromFreeze` |

Nicht: CameraBroker, IOHID, Overlay-Metal, LiDAR-Pinch, MediaPipe.

# Analyse, Fehlerbehebung, öffentlicher Abgleich

Stand: 2026-09-08. Helios **1.6.52** (Build 85). Nur `main`. `bugfix` ist 1.5.7 — nichts mergen.

## 0. 1.6.52 — Two-pinch Hysterese, Rotation-Recalib, CGEvent 90 Hz

1.6.51: Two-pinch vs Scroll, Coast-Cap×Scale, Jiggle×Scale. Danach kippte Zwei-Pinzette zwischen Scroll und Scale (Achse `.none` nach einem Jitter). Display-Drehung ließ die Homographie stehen. Sample-Cursor (8 Hz) zog den Coast-Zeiger zurück.

| # | Bug | Fix |
|---|---|---|
| 1 | Two-pinch Achse `.none` nach 1 Frame | `twoPinchAxisHysteresis` + PrefersScroll |
| 2 | Display-Drehung tot | `spaceMapNeedsRecalib` + rotation stamp |
| 3 | Sample-Cursor vs Coast | `sampleCursorYieldsToCoast` |
| 4 | CGEvent Burst | `cgEventCoalesceDue` 90 Hz, Suppression 0 |

Nicht: CameraBroker, IOHID, Overlay-Metal, LiDAR-Pinch, MediaPipe.

# Analyse, Fehlerbehebung, öffentlicher Abgleich

Stand: 2026-09-08. Helios **1.6.51** (Build 84). Nur `main`. `bugfix` ist 1.5.7 — nichts mergen.

## 0. 1.6.51 — Two-pinch vs Scroll, Coast-Cap×Scale, Jiggle×Scale

1.6.50: Clutch×Scale, AX-Window, reduced-motion, Vision-Stale, Pinch analog. Danach Zoom während einer offenen Palme = Scroll. Coast 80 pt auf 5K zu kurz. Jiggle 1,2 pt lässt CGEvent-Echo durch.

| # | Bug | Fix |
|---|---|---|
| 1 | Two-pinch startet Scroll | `scrollAllowed` + Mute 0,28 s |
| 2 | Coast-Cap 80 pt Retina | `hudCoastCapScaled` |
| 3 | Jiggle 1,2 pt Retina | `clutchJiggleScaled` |

Nicht: CameraBroker, IOHID, Overlay-Metal, LiDAR-Pinch, MediaPipe.

# Analyse, Fehlerbehebung, öffentlicher Abgleich

Stand: 2026-09-08. Helios **1.6.50** (Build 83). Nur `main`. `bugfix` ist 1.5.7 — nichts mergen.

## 0. 1.6.50 — Clutch×Scale, AX-Window, reduced-motion, Vision-Stale, Pinch analog

1.6.49: 720-Lock persist, 24 fps, Click-Vel, HUD-Coast, Per-Display, Body-Skip. Danach seizes Retina-Maus den Zeiger (48 pt). Coast hitTestet 90 Hz das falsche Fenster. Reduce-Motion coastet trotzdem. Vision 500 ms füttert tot. Pinch-Bool droppt Hold.

| # | Bug | Fix |
|---|---|---|
| 1 | Retina-Clutch 48 pt | `clutchOwnRadiusScaled` × backingScaleFactor |
| 2 | Coast AX-Fenster wechselt | `axWindowCacheHolds` Bounds+Pad |
| 3 | Reduce-Motion Coast | `hudCoastAllowed` |
| 4 | Stale Vision | `visionStale` 400 ms drop |
| 5 | Pinch-Bool 8 fps | `pinchAnalog` Closedness×zSep |

Nicht: CameraBroker, IOHID, Overlay-Metal, LiDAR-Pinch, MediaPipe.

# Analyse, Fehlerbehebung, öffentlicher Abgleich

Stand: 2026-09-08. Helios **1.6.49** (Build 82). Nur `main`. `bugfix` ist 1.5.7 — nichts mergen.

## 0. 1.6.49 — 720-Lock persist, 24 fps, Click-Vel, HUD-Coast, Per-Display

1.6.48: inputPriority, Native 420, Freeze-Cursor, Pinch/AX, Wake. Danach startete Continuity weiter auf claimed 1080@30 (8 fps). Slow-Drift wurde Zug. HUD interpolierte ein Frame hinten. Homographie immer Main. Body-Pose fraß 8-fps-Ticks.

| # | Bug | Fix |
|---|---|---|
| 1 | Restart = 1080@8 | `helios.formatHeight` + prefers720 phone; Mac bleibt 1080 |
| 2 | 30 fps Request → 8 | `cameraLockFps` 24 |
| 3 | Drift = Drag | `isDrag` Palm-Vel Click/Need |
| 4 | HUD 1 Frame tot | `hudCoastPoint` + DisplayLink Cursor |
| 5 | Zweitmonitor tot | `spaceMapDisplayID` |
| 6 | Body bei 8 fps | `visionSkipsBody` |

Nicht: CameraBroker, IOHID, Overlay-Metal, LiDAR-Pinch, MediaPipe.

# Analyse, Fehlerbehebung, öffentlicher Abgleich

Stand: 2026-09-08. Helios **1.6.48** (Build 81). Nur `main`. `bugfix` ist 1.5.7 — nichts mergen.

## 0. 1.6.48 — inputPriority, Native 420, Freeze-Cursor, Pinch/AX, Wake

1.6.47: start() Leiter, sticky Höhe, Mac nie. Preset 1080p klemmt Continuity @ 8. Freeze return ohne Zeiger. Pinch+Fenster droppen beim Hitch.

| # | Bug | Fix |
|---|---|---|
| 1 | 1080p-Preset → 8 fps | inputPriority / 720p |
| 2 | BGRA-Convert | Native 420 |
| 3 | Freeze tot | freezeDrivesCursor + lastHandsLive |
| 4 | Hitch = Klick + Fenster-Drop | DropsPinch / ReleaseAX nur beyondHold |
| 5 | Sleep tötet Cam | didWake start() |

Nicht: CameraBroker, IOHID, Overlay-Metal, LiDAR-Pinch, MediaPipe.

# Analyse, Fehlerbehebung, öffentlicher Abgleich

Stand: 2026-09-08. Helios **1.6.47** (Build 80). Nur `main`. `bugfix` ist 1.5.7 — nichts mergen.

## 0. 1.6.47 — start() hält Leiter, lastFormatHeight sticky, Mac nie

1.6.46: uniqueID sticky Name, PTS-Wall, Kalman-Palme. `start()` wischte lastFormatHeight=1080 und lastDeviceUniqueID. uniqueID-Wechsel dumpte Leiter trotz gleichem iPhone. FaceTime-Name klebte.

| # | Bug | Fix |
|---|---|---|
| 1 | start() Leiter 1080p@8 | lastFormatHeight / uniqueID / Role überleben start() |
| 2 | uniqueID-Wechsel dumpte Höhe | lastFormatHeightResets via cameraIDSticky |
| 3 | Mac-Name sticky | cameraIDSticky Mac nie, Osmo ja |

Nicht: CameraBroker, IOHID, Overlay-Metal, LiDAR-Pinch, MediaPipe.



## 0. 1.6.46 — uniqueID sticky, PTS-Freeze, lastFormatHeight, Kalman-Palme

1.6.45: HMM Gate-Held, dtPalm, Format-Retry. Continuity uniqueID flackert Recenter+Homographie. PTS als Wall, Uhr-Sprung = Dropout. Leiter 1080p der alten Cam. preferredDevice Built-in. Freeze stand 90 ms.

| # | Bug | Fix |
|---|---|---|
| 1 | uniqueID-Flicker Recenter | cameraIDSticky + SpaceMap.retarget |
| 2 | PTS-Sprung Dropout | ptsJumpIsFreeze + ptsWallStamp |
| 3 | Leiter alte Cam | lastFormatHeightResets + cameraPreferredID |
| 4 | Freeze-Stand 90 ms | freezeKalmanPredict lastVel im Tracker |

Nicht: CameraBroker, IOHID, Overlay-Metal, LiDAR-Pinch, MediaPipe.

## 0. 1.6.45 — HMM Gate-Held, dtPalm, Format-Retry

1.6.44: DisplayLink 90 Hz HUD, PinchHoldPhase in driveGrab. PoseHMM `pinchHeld` Default false — Call-Site fehlte. Zweite `let dt` ungeklemmt. `cameraFormatRenegotiateRetry` nur Tests.

| # | Bug | Fix |
|---|---|---|
| 1 | HMM sieht PinchHold nicht | `hmm.step(..., pinchHeld: pinchState.closed)` |
| 2 | `let dt` Shadow ungeklemmt | `dtPalm = sampleDt` |
| 3 | Leiter hinter 8 s already | `cameraFormatRenegotiateRetry` ODER first |

Nicht: CameraBroker, IOHID, Overlay-Metal, LiDAR-Pinch, MediaPipe, uniqueID sticky.



## 0. 1.6.44 — DisplayLink HUD, PinchHoldPhase in der Engine

1.6.43: Format-Leiter, PinchHoldPhase Math, fail-closed AX. HUD und Detect teilten 8 Hz. Engine Bool.

| # | Bug | Fix |
|---|---|---|
| 1 | HUD 8 Hz | CADisplayLink ~90 Hz, hudLerpT / hudLerpPoint |
| 2 | Pinch Bool | pinchHoldAdvance in driveGrab, dropPinchHold |
| 3 | Freeze rastet | Freeze t=1, sonst 1 Frame Lag |

Nicht: CameraBroker, IOHID, Overlay-Metal, LiDAR-Pinch, MediaPipe.

## 0. 1.6.43 — Format-Leiter, PinchHoldPhase Math, fail-closed AX


1.6.41: AX-TTL sampleDt, Drag×dt, Format-Score gemessen. Fusion-Quelle immer 2D. Fehlende Tiefe Reliability 1. Kalman-Q fest 0,94.

| # | Bug | Fix |
|---|---|---|
| 1 | fused.source immer 2D | argmax Gewicht |
| 2 | Reliability fehlend = 1 | × 0,92 / Frame |
| 3 | Kalman-Q fest | freezeKalmanQ(dt) |

Nicht: CameraBroker, IOHID, Overlay-Metal, LiDAR-Pinch, MediaPipe, DisplayLink 90 Hz.

## 0. 1.6.41 — AX-TTL sampleDt, Drag×dt, Format-Score gemessen, Track-Dropout

1.6.40: Kalman, AX-Cache, EMA, Gain×dt, q-Chips, Format-Nachzug. Cache TTL hart 40 ms — 8 fps nie ein Treffer. pinchDragNeed 0,45 ein Continuity-Tick = Zug. renegotiateIfSlow einmal mit cameraFormatScore (1080p@30 gemeldet). HMM-Reset 0,35 s.

| # | Bug | Fix |
|---|---|---|
| 1 | AX-Cache 40 ms < 125 ms Frame | `axHitCacheFresh(dt: sampleDt)` |
| 2 | Klick = Zug ein Tick | `pinchDragNeedOf` 8 fps 0,61 HW / 40 px |
| 3 | Format-Nachzug gleicher Score | `cameraFormatScoreMeasured` + Cooldown 8 s |
| 4 | HMM-Reset während Freeze | `trackDropoutNeed(dt)` |

Nicht: CameraBroker, IOHID, Overlay-Metal, LiDAR-Pinch, MediaPipe, DisplayLink 90 Hz, Hand-ID Reconnect.

## 0. 1.6.40 — Kalman-Palme, AX-Cache, Palm-EMA × dt, Gain × dt

1.6.39: Approach+Reach, Finger-Kontakt, q-Gate, Tip. Freeze-Vel-Decay 0,82 tot nach 3 Continuity-Ticks. AX hitTest jeden Tick. palmWidth α 0,22 Frame. Pointer-Gain ein Tick = Teleport. q-Chip nur Actor. Format-Score einmal, 8 fps bleibt.

| # | Bug | Fix |
|---|---|---|
| 1 | Freeze-Geist tot nach 3 Ticks | `freezeKalmanPredict / Update / Palms` Reibung 0,94 |
| 2 | AX hitTest jeden Tick | `axHitCacheFresh` 1 Frame |
| 3 | palmWidth α Frame | `palmWidthEMA × dt` 8 fps 0,12 |
| 4 | Pointer-Gain Teleport | `pointerGainDt` 8 fps 0,32 |
| 5 | q-Chip nur Actor | `qualityChips` je Hand |
| 6 | Format einmal, 8 fps bleibt | `cameraFormatRenegotiate` fps < 12 |

Nicht: CameraBroker, IOHID, Overlay-Metal, LiDAR-Pinch, MediaPipe, DisplayLink 90 Hz.

## 0. 1.6.39 — Approach+Reach, Finger-Kontakt, q-Gate, Tip-Konfidenz

1.6.38: Zwei-Hand-Freeze, Clutch, Vel-Chip, lastZ. Approach-Veto vor Reach tötete echte Pinzette zur Kamera. Gate Close 0,55 hart. Occluded Tips fütterten z.

| # | Bug | Fix |
|---|---|---|
| 1 | Approach vetoed reach 1,1 | `pinch3DVeto` Reach skippt Approach |
| 2 | Gate Close 0,55 hart | `pinchClosednessNeed` im Gate |
| 3 | Closedness-Skalar jittert | `pinchFingerContact` nur q ≥ 0,55 |
| 4 | pinchRatio ohne q | `pinchRatioSmooth × quality` |
| 5 | Occluded Tips → z | Tip-Konfidenz > 0,22 |

Nicht: CameraBroker, IOHID, Overlay-Metal, LiDAR-Pinch, MediaPipe, AX-Hit-Cache, Kalman-Palme.

# Analyse, Fehlerbehebung, öffentlicher Abgleich

Stand: 2026-09-08. Helios **1.6.38** (Build 71). Nur `main`. `bugfix` ist 1.5.7 — nichts mergen.

## 0. 1.6.38 — Zwei-Hand-Freeze, Clutch, Vel-Chip, lastZ-Gate

1.6.37: Format, Residual, Sign, q-Chip, One-Euro, Tastatur-Ring. Freeze-Δ nur Actor auf beide Hände. Jiggler weckt Geist. Predict unsichtbar. lastZ bei Occlusion weitergeschrieben.

| # | Bug | Fix |
|---|---|---|
| 1 | Freeze-Δ nur Actor, zweite Hand teleportiert | `freezePalmsPredict` + `freezeGhostDeltas` |
| 2 | Jiggler seize während Freeze | `clutchIgnoresFreeze` |
| 3 | Predict unsichtbar | `freezeVelChip` |
| 4 | lastZ bei Residual hoch | `liftSignKeepsPrevious` |

Nicht: CameraBroker, IOHID, Overlay-Metal, LiDAR-Pinch, MediaPipe, AX-Hit-Cache, Kalman-Palme.

# Analyse, Fehlerbehebung, öffentlicher Abgleich

Stand: 2026-09-08. Helios **1.6.37** (Build 70). Nur `main`. `bugfix` ist 1.5.7 — nichts mergen.

## 0. 1.6.37 — Format, Residual-Gate, Sign-Hysterese, q-Chip

1.6.36: Approach-Veto, Recover-Sprung, Faust-Grace. Danach blieb Continuity auf 1080p@8 (`guard fps >= 24`). PinchGate ignorierte z. Lift3D-Sign kippte bei Occlusion. Residual-Veto ohne Trust. HUD ohne q. Tastatur-Ring 3 px.

| # | Bug | Fix |
|---|---|---|
| 1 | bestFormat wirft < 24 fps | `cameraFormatScore` 720p@24 vor 1080p@8 |
| 2 | PinchGate / Looks ohne Residual | `pinch3DTrusts` nullt z, Gate bekommt zSep |
| 3 | Lift-Sign previous[] kippt | `liftSignHolds` Optional, kleines pred → Anatomie |
| 4 | pinchRatio Jitter 8 fps | `pinchRatioSmooth` One-Euro |
| 5 | tot-Pinzette unsichtbar | HUD `qualityChip` |
| 6 | Tastatur-Ring 3 px | `chromeDwellRingWidth(dt)` |

Nicht: CameraBroker, IOHID, Overlay-Metal, LiDAR-Pinch, MediaPipe-Sidecar.

# Analyse, Fehlerbehebung, öffentlicher Abgleich

Stand: 2026-09-08. Helios **1.6.36** (Build 69). Nur `main`. `bugfix` ist 1.5.7 — nichts mergen.

## 0. 1.6.36 — Approach-Veto, Recover-Sprung, Faust-Grace

1.6.35: Closedness×q, Freeze-Predict, Ampel-Ring. pinchActor ignorierte z. pinch3DVeto tötete echte Pinzetten. Recover nur Breite. Heranziehen nur Y. Faust-Scharf 0,22 s.

| # | Bug | Fix |
|---|---|---|
| 1 | Faust-in-Kamera: Sep tot, 2D-Reach lügt | `pinch3DApproach` + Veto vor Reach-Skip |
| 2 | pinchActor ohne zSep/Approach | Actor + pinchLooksLikePinch reicht z durch |
| 3 | Veto auf \|Δz\| tötete echte Pinzette | Reach ≥ Need+0,15 skippt nur Sep |
| 4 | Recover-Teleport Palmenposition | `emptyHandsRecoverPalmJump` |
| 5 | Heranziehen nur Palm-Y | `pullTowardPalmGrow` |
| 6 | Faust-Scharf 0,22 s = 1 Continuity-Tick | `fistScharfGrace(dt)` |

Nicht: CameraBroker, IOHID, Overlay-Metal, LiDAR-Pinch, MediaPipe-Sidecar.

# Analyse, Fehlerbehebung, öffentlicher Abgleich

Stand: 2026-09-08. Helios **1.6.35** (Build 68). Nur `main`. `bugfix` ist 1.5.7 — nichts mergen.

## 0. 1.6.35 — Qualität-Closedness, Freeze-Predict, Ampel-Ring

1.6.34: Ampel × dt, 3D-Pinch, Freeze sichtbar. Danach klickte die Faust bei toten Landmarks, Freeze-Geist stand, Recover teleportierte, Ampel-Ring 4 Frames unsichtbar.

| # | Bug | Fix |
|---|---|---|
| 1 | pinchStartsGrab ignoriert q | `pinchClosednessNeed(quality, start)` |
| 2 | Freeze-Geist statisch | `freezePalmPredict` Vel × decay 0,82 |
| 3 | Recover-Teleport | `TrackedHand.shifted` + `freezeGhostDelta` |
| 4 | Ampel-Ring 6 px bei 8 fps | `chromeDwellRingWidth(dt)` |

Nicht: CameraBroker, IOHID, Overlay-Metal, LiDAR-Pinch.

# Analyse, Fehlerbehebung, öffentlicher Abgleich

Stand: 2026-09-07. Helios **1.6.34** (Build 67). Nur `main`. `bugfix` ist 1.5.7 — nichts mergen.

## 0. 1.6.34 — Ampel, 3D-Pinch, Freeze sichtbar

1.6.33: Klick/Zwei-Pinzetten/Tastatur × dt. Danach schloss die Ampel beim Zielen, Faust in die Kamera klickte, HMM log 0,70 Faust, Freeze-HUD leer.

| # | Bug | Fix |
|---|---|---|
| 1 | chromeDwellHold 0,55 s / Still 18 px | `chromeDwellNeed(dt)`, `chromeDwellStillNeed(dt, screenMin)` |
| 2 | 2D-Reach bei Faust-in-Kamera | `pinch3DSep` / `pinch3DVeto` in pinchLooksLikePinch |
| 3 | HMM Emission 0,70 bei q tot | `PoseHMM.qualityScale` q < 0,55 → Uniform |
| 4 | Freeze-HUD tot, Skeleton voll | `freezeLive` dim 0,38 + Geisterhand |
| 5 | fps-Spark ungenutzt, Achse unsichtbar | `fpsSparkBars`, `twoPinchAxisChip` H/V |

Nicht: CameraBroker, IOHID, Overlay-Metal, LiDAR-Pinch (Landmark-z ist da).

# Analyse, Fehlerbehebung, öffentlicher Abgleich

Stand: 2026-09-07. Helios **1.6.33** (Build 66). Nur `main`. `bugfix` ist 1.5.7 — nichts mergen.

## 0. 1.6.33 — Rest-Uhren unter einem Continuity-Frame

1.6.32: HMM/Temporal/Release. Danach klickte 1 Frame, Zoom startete 1 Frame, Tastatur feuerte am Vorbeiflug.

| # | Bug | Fix |
|---|---|---|
| 1 | pinchClickMinHold 50 ms < 125 ms | `pinchClickMinNeed(dt)` ≥ 150 ms bei 8 fps |
| 2 | twoPinchConfirm 120 ms = 1 Tick | `twoPinchConfirmNeed(dt)` zwei Frames |
| 3 | keyboardDwell 120 ms | `keyboardDwellNeed(dt)` |

Nicht: CameraBroker, IOHID, Overlay-Metal, 3D-Pinch (steht auf der Liste).

# Analyse, Fehlerbehebung, öffentlicher Abgleich

Stand: 2026-09-07. Helios **1.6.32** (Build 65). Nur `main`. `bugfix` ist 1.5.7 — nichts mergen.

## 0. 1.6.32 — Continuity-Uhr, nicht Schwellen

Warum 1.6.31 auf dem iPhone-Cam weiter riss:

| # | Bug | Fix |
|---|---|---|
| 1 | HMM-Hold 50 ms < 125 ms Frame | `switchHold(dt)` ≈ 1 Frame, 2. tick wechselt |
| 2 | pinch-EMA τ 45 ms, α ≈ 0,94 | `pinchTau(dt)` |
| 3 | TemporalNet 12 Frames = 1,5 s | `maxAge` 0,80 s, 8 fps 3 Frames |
| 4 | Release-Tot 120 ms = 1 Frame | `pinchReleaseNeed(dt)` ≥ 200 ms |
| 5 | Recover-Gain ignoriert Palm-Sprung | `emptyHandsRecoverPalmMul` |
| 6 | Pinch-Drop unsichtbar | HUD `P drop` |

Nicht: CameraBroker, IOHID, Overlay-Metal, 3D-Pinch (steht auf der Liste).

# Analyse, Fehlerbehebung, öffentlicher Abgleich

Stand: 2026-09-02. Helios 1.6.19. Erkennung (1.6.0/1.6.1) bleibt; 1.6.2
ist Koordinaten, AX, Threads, HUD. 1.6.14: Pinzette-Lock friert,
Entropie-Tor, dt-Hochpass, Tisch-Idle, App-Profil, HMM lastRealProb.
1.6.19: dt-Cap 0,20, preferred Lock-ID, chromeDwell reset, Palm-Y-Zug,
Fling×dt, Tastatur 0,85 s unten.

## 0. 1.6.19 — Continuity und Steuerhand

| # | Bug | Fix |
|---|---|---|
| 1 | dt auf 80 ms gekappt | `sampleDtCap` 0,20 |
| 2 | `preferred()` nur L/R | Lock-ID zuerst |
| 3 | `pinchActor ?? primary` | freeze `pinchLastHand` |
| 4 | `chromeDwellKind` undicht | reset leave + fire |
| 5 | Heranziehen Mittelfinger | Palm-Y `pullToward` |
| 6 | Fling-Fenster 120 ms leer bei 8 fps | `flingWindowLen` |
| 7 | Tastatur 0,40 s irgendwo | 0,85 s unten |

## 0. 1.6.14 — Rest-Logik nach 1.6.13

| # | Bug | Fix |
|---|---|---|
| 1 | `pinchActor` → `primary` bei fehlender Lock-ID | letzte Hand einfrieren, nie Steuerhand |
| 2 | Aktions-Tor hart 0,62 | Entropie 0,55–0,72 |
| 3 | Hochpass 0,08 bei 8 fps tot | `palmHighpassAlpha(dt)` |
| 4 | HMM-Hold `next[current]` verdünnt | `lastRealProb` |
| 5 | Ecken zittern am Anschlag | 2 % Ruhezone |
| 6 | Hände auf dem Tisch = Not-Aus-Nähe | 1,2 s Idle |
| 7 | Xcode/Safari gleiche Injektion | `AppInjectProfile` |

## 0. 1.6.8 — Rest-Logik, nicht Fusion

| # | Bug | Fix |
|---|---|---|
| 1 | Not-Aus `return true` ab Tick 1 | nur nach 1,35 s stiller offener Palmen |
| 2 | `openScore ≥ 4` reicht | `pose == .openPalm` und Abstand ≥ clapOpen |
| 3 | Kill während Pinzette | Skip wenn `pinchHeld` / Zwei-Pinzette |
| 4 | Körper-Vote Ratio 0,72 immer | Override nur unknown oder Ratio < 0,50 |
| 5 | Track-Wechsel teleportiert Cursor | `cursorSmooth` behalten, Palme re-anchorn |
| 6 | unknown-Logit 0,35 | −1,8; HMM hält aktuelle Pose |
| 7 | palmWidth roh pro Frame | EMA 0,22 pro Track |

## 0b. 1.6.2 — Plattform, nicht Erkennung

| # | Bug | Fix |
|---|---|---|
| 1 | Fensterumriss eine Höhe zu tief | `localRect` nutzt Quartz-minY |
| 2 | AX-Force-Casts | `CFGetTypeID` + bedingter Cast |
| 3 | Main blockiert (screencapture, AppleScript, xattr) | Hintergrund-Queues |
| 4 | dlopen pro Frame | Cache in `AppInstall` |
| 5 | Unbegrenzte AX-Zug-Schlange | letzter Punkt, Timeout am Drag-Element |
| 6 | PinchGate überlebt Handverlust | reset bei leeren Observations |
| 7 | Kalibrier-Hold ohne Pinzette | Hold nur bei `confirm` |
| 8 | Export `removeItem` auf Ordner | nur Helios-Dateien überschreiben |
| 9 | ForEach-IDs L/R | Track-IDs T1/T2 (seit 1.6.0) |
| 10 | `mirroredFlag` unsynchron | `handlerLock` |
| 11 | `apply()`-Stapel auf main | `ApplySlot` analog FramePump |
| 12 | README → falsches Repo | `lolalpha00gamma/Helios` |

Homographie gecacht, Rechte-Banner statt modalem Alert, Klick-Pause/Pinch-ohne-Zug nicht als Fehler, Snap am Engine-Cursor, Wischen ohne Faust, Vision-Revision gepinnt, Luma CIAreaAverage, Fadenkreuz verdrahtet, Clutch `mouseMoved`, Timer/Monitore beim Beenden frei.

## 1. Bestand vor der Umstellung (1.5.7)


Eine Quelle: `VNDetectHumanHandPoseRequest`, 21 Gelenke ohne z.
One-Euro, Radial-`isExtended`, binäre Posen, PinchGate und 2-Frame-Halter
alle an der Chiralität hängend. Das bricht bei:

- Verkürzung (Hand zur Kamera) — offene Hand wird Faust
- Kippung — `palmScale` schrumpft, Pinzette fällt raus
- zwei Hände auf derselben Bildseite — Zustand überschrieben
- 1280×720 — `hypot` mischt 128 px und 72 px (bis 78 % Diagonalefehler)
- 15 vs 60 fps — Streaks in Frames, nicht Sekunden
- grober Landmark-Sprung — Filter folgt ihm
- classify auf geglättet, PinchGate auf roh — drei Sonderfälle kitten das

1.5.7 hatte die **Aktionsseite** schon repariert (AX in Cocoa, Flick-Wischen,
Faust ohne Klick, Peace 0,9 s, Not-Aus 0,8 s). Die **Erkennung** blieb 2D.

## 2. Was jetzt läuft

```
Frame ─┬─► 2D   Gelenkwinkel, Softmax, isotropes palmScale
       ├─► 3D   Knochenlängen-Lift (jede Webcam)
       ├─► Tiefe  AVCaptureDepthDataOutput, sonst Gewicht 0
       └─► Zeit  12×8 Merkmale, optional HeliosTemporal.mlmodel
                 └─► log-Pooling + inverse Varianz + HMM (Sekunden)
```

Track-ID (gierig 2×2 auf Palm-Abstand) statt Links/Rechts als Schlüssel.
Chiralität bleibt Attribut. Ausreißer: 3,5·Median, One-Euro mit dt in
Sekunden. Wurf/Wischen/Skalieren in **Handbreiten**. Systemaktionen ab
Pose-p ≥ 0,62. 1.5.7-Sicherheit bleibt: Not-Aus 0,8 s und openScore ≥ 4,
Scharf-Ruhe 0,7 s, Peace 0,9 s, Cooldown bewegt den Cursor weiter.

Bekannte Restgrenze: ohne echte Tiefe ist 3D-Lift aus denselben 2D-Punkten
*nicht unabhängig*. Deshalb fällt sein Basisgewicht von 0,28 auf 0,12,
sobald `AVCaptureDepthDataOutput` liefert. Lift bleibt Backup.

## 3. Fehler, die die Umstellung schließt

| # | Bug | Fix |
|---|---|---|
| 1 | Perspektivische Verkürzung | 3D-Winkel + optionale Tiefe |
| 2 | palmScale-Kippung | Median aus vier Strecken + Achsenkorrektur |
| 3 | Chiralität als Schlüssel | ungarische Track-ID, Chiralität nur Label |
| 4 | anisotrope hypot | `AspectSpace` x′ = x·(w/h) |
| 5 | binäre Kanten Faust/offen | Softmax über 7 Klassen |
| 6 | Konfidenz nur Schwelle | Gewicht in Merkmal, quality, Fusion |
| 7 | Frame-Streaks | Sekunden (HMM 80 ms, PinchGate 32/55 ms) |
| 8 | zwei Wahrheiten classify/Pinch | beide auf geglätteten Punkten |
| 9 | Ausreißer | 3,5 · Median, extrapolieren statt folgen |
| 10 | absolute Bildschwellen | Handbreiten (Wisch 0,85, Wurf 2,6 hw/s) |

Zusätzlich in dieser Runde behoben:

- **Lift-Palm in Iso-Koordinaten** würde die Fusion verschieben → Palm bleibt
  Vision-[0,1], nur Winkel laufen in 3D.
- **Tiefen-Attach am Default-Format** fand kein Depth-Format, obwohl ein
  anderes Format welches hat → Output hängt, sobald *irgendein* Format Tiefe
  kann; `activeDepthDataFormat` nach `bestFormat`.
- **Isotropie-Test** verglich 0,1 in x mit 0,1 in y (das *ist* der Bug) →
  100 px gegen 100 px.
- **FusionStrip** war unverdrahtet.
- **pbxproj** kannte AspectSpace/Lift/Fusion nicht — Xcode hätte die neuen
  Dateien ignoriert.

## 4. Öffentliche Repos — Abgleich

Inspiriert von Tracker, Desktop-Control und 3D-Lift, inklusive Windows/Linux.

| Projekt | Plattform | Übernommen | Verworfen / warum nicht |
|---|---|---|---|
| [google-ai-edge/mediapipe Hands](https://github.com/google-ai-edge/mediapipe) | alle | 21 Landmarken; **x/y getrennt auf Breite/Höhe normiert** (genau unser Bug); z in x-Skala; Handedness als Attribut + Score; Tracking statt Re-Detect | Palm-Detector-CNN — Vision ersetzt ihn. World-Landmarks in Metern brauchen ihren Regressor. |
| [casiez/OneEuroFilter](https://github.com/casiez/OneEuroFilter) | C++/JS | minCutoff + β·\|dx\|, **dt in Sekunden** | — |
| [geaxgx/depthai_hand_tracker](https://github.com/geaxgx/depthai_hand_tracker) | Linux / OAK-D | Body-Pre-Focus: Unterarm-Achse als Qualitäts-Prior (`forearmGate`). Stereo-xyz wo Hardware es hat | Eigenes Palm-CNN; OAK-only Runtime |
| [CalciferZh/minimal-hand](https://github.com/CalciferZh/minimal-hand) | Python | IK/Knochenlängen für 2D→3D, Restfehler als quality | 100 fps GPU-IK-Netz, zu schwer fürs HUD |
| [kinivi/hand-gesture-recognition-mediapipe](https://github.com/kinivi/hand-gesture-recognition-mediapipe) | Python | Landmarken → kleines zeitliches Netz (12 Frames) | SVM/MLP von Grund auf — wir trainieren aus `gesten.jsonl` |
| [vladmandic/human](https://github.com/vladmandic/human) | Web | getrennte Body- und Hand-Modelle, Gesture als Verteilung nicht als argmax | TF.js-Bundle |
| [handtracking-io/yoha](https://github.com/handtracking-io/yoha) | Web | Track-Identität über Palm-Nähe | eigene Detektoren |
| [ultraleap/UnityPlugin](https://github.com/ultraleap/UnityPlugin) | Win/macOS | Pose-Stabilität, **Pinch als Analogwert 0…1** (kein Bool) | Stereo-IR-Hardware |
| [xinghaochen/awesome-hand-pose-estimation](https://github.com/xinghaochen/awesome-hand-pose-estimation) | Survey | MANO-Knochenverhältnisse fürs Lift | Mesh-Fit |
| [ahmetg0/AirTouch](https://github.com/ahmetg0/AirTouch) | macOS | One-Euro 1:1 (CHI 2012), Webcam-Desktop ohne Headset | bleibt 2D |
| [sunnycho100/HandCursor](https://github.com/sunnycho100/HandCursor) | iOS/macOS | Stabilisierungsschicht vor Gestenlogik | Ein-Hand, kein Fusion |
| [sayginsaman/hand-gesture-desktop-controller](https://github.com/sayginsaman/hand-gesture-desktop-controller) | Win/Linux Python | PyAutoGUI-Mapping Webcam → Desktop | MediaPipe-JS/Python, keine nativen AX-Rechte |
| [ThatsPelle/HandFlow](https://github.com/ThatsPelle/HandFlow) | Windows | nativer Cursor aus Webcam | Electron, kein macOS-AX |
| [vkDemon1/GestureApp](https://github.com/vkDemon1/GestureApp) | Windows | TFLite-Gesten + MediaPipe | PyQt6, keine Fusion |
| [Sarab-Rehman-1918/GestureDesk](https://github.com/Sarab-Rehman-1918/GestureDesk) | Win/Linux | Touchless Desktop, optionales Face-Lock | OpenCV+PyAutoGUI |

Was fast niemand von denen hat und Helios jetzt hat:

1. **Log-Meinungspooling** mehrerer Quellen (2D / Lift / Tiefe / Zeit) statt
   Winner-takes-all.
2. **Unabhängigkeit der Fehler** — Lift-Gewicht fällt, sobald echte Tiefe da
   ist. MediaPipe mischt z aus demselben 2D-Netz; wir tun das bewusst nicht
   als zweite Stimme, wenn ein Depth-Kanal existiert.
3. **Native macOS-AX** (Fenster greifen, Snap, Papierkorb) — die Python-Clones
   klicken nur die Maus.
4. **Schwellen in Handbreiten**, nicht Bildanteilen — Abstand zur Kamera ändert
   die Gesten nicht mehr.

MediaPipe selbst warnt: x und y sind *getrennt* normiert. Deren Landmark-Modell
gibt z bereits in x-Skala aus; Vision tut das nicht, deshalb Lift + optionale
Tiefe.

## 5. Was offen bleibt

- `HeliosTemporal.mlmodel` liegt nicht im Bundle. Heuristik übernimmt
  (quality ≤ 0,62). Training: Create ML auf exportiertem `gesten.jsonl`
  (Feld `label` + 12×8 Merkmale), Output als `macos/Helios/HeliosTemporal.mlmodel`.
- Echte Tiefe nur wenn irgendein Format `supportedDepthDataFormats` hat
  (Continuity Camera mit LiDAR / manche iPhone-Continuity, fast keine
  Built-in-Mac-Webcam).
- Kein On-Device-Training.
- 3D-Lift-Vorzeichen ist kinematisch (curl-in / zeitlich) — bei einer
  völlig neuen Pose ohne History kann z kippen, bis das HMM hält.
- Tests laufen nicht in dieser Linux-Sandbox (kein Vision.framework).
  Lokal: `swiftc macos/Helios/CoordMath.swift macos/HeliosTests/CoordTests.swift`
  plus GestureTests mit AspectSpace/HandEstimate/EstimateFusion/PoseHMM/
  GestureClassifier (siehe CI-Workflow).

## 6. Dateien

| Datei | Rolle |
|---|---|
| `AspectSpace.swift` | isotropes x′ = x·(w/h) |
| `HandEstimate.swift` | gemeinsame Schätz-Schnittstelle |
| `EstimateFusion.swift` | log-Pooling, inverse Varianz, adaptive Gewichte |
| `PoseHMM.swift` | Vorwärtsfilter, Umschalten ≥ 80 ms und p ≥ 0,62 |
| `Lift3D.swift` | z² = L² − (Δx²+Δy²) |
| `TemporalNet.swift` | Heuristik-GRU / optionales Core ML |
| `DepthCapture.swift` | echte Tiefe, sonst nil |
| `FusionStrip.swift` | Inspector: Gewichte, Pose-p, Tiefe an/nur Lift |
| `LandmarkSmoothing.swift` | One-Euro + 3,5·Median |
| `GestureClassifier.swift` | Winkel, Softmax, robustes palmScale |
| `HandTracker.swift` | Track-ID, Unterarm-Prior, Fusion |
| `GestureEngine.swift` | Handbreiten + 1.5.7-Sicherheit + p ≥ 0,62 |
| `CameraSession.swift` | Depth-Output, Format mit Depth-Bonus |
| `SessionExport.swift` | `z`, `label` für Create ML |

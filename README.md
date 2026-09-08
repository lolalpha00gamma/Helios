# Helios **1.6.61**


Native macOS-App: Gestensteuerung über den Kamera-Livestream, holografisches HUD, Fenster- und Cursorsteuerung.

Privates Repo. Keine Open-Source-Lizenzdatei.

Ziel: **macOS 26+** (Golden Gate / 27), **Apple Silicon**, **arm64**.

## Start

**Nur die DMG-Datei laden, nicht Source code (zip):**

[Helios.dmg](https://github.com/lolalpha00gamma/Helios/releases/latest/download/Helios.dmg)

1. `Helios.dmg` doppelklicken (kein Entpacken)
2. Helios nach **Programme** ziehen — nicht aus dem Image starten
3. Erster Start (nicht notarisierte Ad-hoc-Signatur): **Systemeinstellungen → Datenschutz & Sicherheit → Trotzdem öffnen**
4. Rechte: Kamera, Bedienungshilfen, Eingabeüberwachung. Nach jedem Update Schalter **aus und wieder an**.

Auf der Release-Seite stehen automatisch auch *Source code (zip)* / *tar.gz*. Das ist GitHub-Quelltext, **nicht** die App.

## Neu in 1.6.61

Warum der Cursor tot wirkte und Klicks fremd landeten: Continuity Center Stage croppt aufs Gesicht — die Palme fällt aus dem Frame, Vision sucht den ganzen 8-Hz-Frame, AE-Jagd kippt Homographie, Dropout dreht Links/Rechts.

- **Center Stage aus.** Wie Aegis: `.app`-Mode, `isCenterStageEnabled = false`. Palme bleibt im Bild.
- **AE/WB-Lock auf Phone.** Continuity nicht continuous. Mac bleibt Auto.
- **Chirality-Lock nach Dropout.** Vision-Flicker hält die letzte Seite.
- **Vision ROI 2× Palm-Box.** Miss → Full-Frame nächster Tick.
- **Pinch-Hysterese × palmWidth.** Kleine Palme höhere Closedness.
- **Fling-Achse × palmWidth.** Diagonale Dropout-Rucke docken nicht.
- Tests + MARKETING_VERSION 1.6.61 (Build 94).

# Helios **1.6.59**



Native macOS-App: Gestensteuerung über den Kamera-Livestream, holografisches HUD, Fenster- und Cursorsteuerung.

Privates Repo. Keine Open-Source-Lizenzdatei.

Ziel: **macOS 26+** (Golden Gate / 27), **Apple Silicon**, **arm64**.

## Start

**Nur die DMG-Datei laden, nicht Source code (zip):**

[Helios.dmg](https://github.com/lolalpha00gamma/Helios/releases/latest/download/Helios.dmg)

1. `Helios.dmg` doppelklicken (kein Entpacken)
2. Helios nach **Programme** ziehen — nicht aus dem Image starten
3. Erster Start (nicht notarisierte Ad-hoc-Signatur): **Systemeinstellungen → Datenschutz & Sicherheit → Trotzdem öffnen**
4. Rechte: Kamera, Bedienungshilfen, Eingabeüberwachung. Nach jedem Update Schalter **aus und wieder an**.

Auf der Release-Seite stehen automatisch auch *Source code (zip)* / *tar.gz*. Das ist GitHub-Quelltext, **nicht** die App.

## Neu in 1.6.59

1.6.58 Predict-Clutch, USB-C-Promote, Fling-Cap, Scroll-Gain. Track-TTL blieb hart 0,18 s — Slot tot vor dem 2. Continuity-Frame, Hand-Box-IoU wirkungslos. Pinch-Reset 0,12 s. Osmo im Cold-Start als Phone. Promote ohne Rolle: Continuity-Phone mit kurz 24 fps lockte 30 → 8 Hz.

- **Track-TTL = trackDropoutNeed.** 0,18 → ≥ 0,35 s. Slot überlebt 2 Misses.
- **Pinch-Reset emptyHandsHold.** 0,12 s resetete Closedness zwischen 8-Hz-Frames.
- **Osmo kein Phone-Bias.** Cold-Start 720@24 nur Continuity, nicht USB-C.
- **USB-Promote rollen-gated.** Phone bleibt 24. Osmo/USB gemessen ≥ 22 → 30.
- Tests + MARKETING_VERSION 1.6.59 (Build 92).

# Helios **1.6.58**


Native macOS-App: Gestensteuerung über den Kamera-Livestream, holografisches HUD, Fenster- und Cursorsteuerung.

Privates Repo. Keine Open-Source-Lizenzdatei.

Ziel: **macOS 26+** (Golden Gate / 27), **Apple Silicon**, **arm64**.

## Start

**Nur die DMG-Datei laden, nicht Source code (zip):**

[Helios.dmg](https://github.com/lolalpha00gamma/Helios/releases/latest/download/Helios.dmg)

1. `Helios.dmg` doppelklicken (kein Entpacken)
2. Helios nach **Programme** ziehen — nicht aus dem Image starten
3. Erster Start (nicht notarisierte Ad-hoc-Signatur): **Systemeinstellungen → Datenschutz & Sicherheit → Trotzdem öffnen**
4. Rechte: Kamera, Bedienungshilfen, Eingabeüberwachung. Nach jedem Update Schalter **aus und wieder an**.

Auf der Release-Seite stehen automatisch auch *Source code (zip)* / *tar.gz*. Das ist GitHub-Quelltext, **nicht** die App.

## Neu in 1.6.58

1.6.57 Predict, Zwei-Hand-Clutch, Stage-Clamp, Hand-Box. Clutch coastete den Zeiger. Osmo claimed 30 ohne Messung. Dropout war Dock. Scroll global.

- **Predict-Clutch.** Deadman/Zwei-Hand: Predict aus, Cap 0.
- **USB-C 30-fps Promote.** Nur nach gemessenen ≥ 22 fps, nicht claimed 30.
- **Fling-Cap × Screen-Höhe.** Dropout > 42 % Höhe ist kein Werfen.
- **Per-App Scroll-Gain.** Safari 1,35×, Xcode 0,55×.
- Tests + MARKETING_VERSION 1.6.58 (Build 91).

## Neu in 1.6.57


Native macOS-App: Gestensteuerung über den Kamera-Livestream, holografisches HUD, Fenster- und Cursorsteuerung.

Privates Repo. Keine Open-Source-Lizenzdatei.

Ziel: **macOS 26+** (Golden Gate / 27), **Apple Silicon**, **arm64**.

## Start

**Nur die DMG-Datei laden, nicht Source code (zip):**

[Helios.dmg](https://github.com/lolalpha00gamma/Helios/releases/latest/download/Helios.dmg)

1. `Helios.dmg` doppelklicken (kein Entpacken)
2. Helios nach **Programme** ziehen — nicht aus dem Image starten
3. Erster Start (nicht notarisierte Ad-hoc-Signatur): **Systemeinstellungen → Datenschutz & Sicherheit → Trotzdem öffnen**
4. Rechte: Kamera, Bedienungshilfen, Eingabeüberwachung. Nach jedem Update Schalter **aus und wieder an**.

Auf der Release-Seite stehen automatisch auch *Source code (zip)* / *tar.gz*. Das ist GitHub-Quelltext, **nicht** die App.

## Neu in 1.6.57

1.6.56 One-Euro, 24-fps Kaltstart, Bezel-Hop, Deadman. Cursor laggte 1 Continuity-Frame. Zweite Hand klickte. Stage-Strip verschluckte den Zeiger. Hand-Slot sprang bei 8 Hz.

- **Pointer 1-Frame Predict.** One-Euro-Vel × dt, Cap 48 pt.
- **Two-Hand Clutch.** Zweite Palme ohne Zwei-Pinch friert Actor und Klick.
- **Stage-Manager Space-Clamp.** `visibleFrame`, nicht der volle Screen-Frame.
- **Hand-Box IoU persist.** Slot-ID zwischen Detect, IoU 0,28.
- Tests + MARKETING_VERSION 1.6.57 (Build 90).

## Neu in 1.6.56


Native macOS-App: Gestensteuerung über den Kamera-Livestream, holografisches HUD, Fenster- und Cursorsteuerung.

Privates Repo. Keine Open-Source-Lizenzdatei.

Ziel: **macOS 26+** (Golden Gate / 27), **Apple Silicon**, **arm64**.

## Start

**Nur die DMG-Datei laden, nicht Source code (zip):**

[Helios.dmg](https://github.com/lolalpha00gamma/Helios/releases/latest/download/Helios.dmg)

1. `Helios.dmg` doppelklicken (kein Entpacken)
2. Helios nach **Programme** ziehen — nicht aus dem Image starten
3. Erster Start (nicht notarisierte Ad-hoc-Signatur): **Systemeinstellungen → Datenschutz & Sicherheit → Trotzdem öffnen**
4. Rechte: Kamera, Bedienungshilfen, Eingabeüberwachung. Nach jedem Update Schalter **aus und wieder an**.

Auf der Release-Seite stehen automatisch auch *Source code (zip)* / *tar.gz*. Das ist GitHub-Quelltext, **nicht** die App.

## Neu in 1.6.56

1.6.55 Adaptive Gain, HUD-Sharing, Edge-Resistance, Display-Gap. Continuity startete trotzdem claimed 1080@30 → 8 Hz. Cover-Session lockte Max-FPS. Bezel-Hop ohne Hysterese. Stillstand klickte.

- **One-Euro Filter.** min-cutoff × Jitter auf den Cursor, nicht nur Highpass.
- **Continuity 24-fps Kaltstart.** 720@24 schlägt claimed 1080@30. Cover nutzt `cameraLockDuration`.
- **Bezel-Hop Hysterese 80 pt.** Sidecar erst nach echtem Eindringen.
- **Palm-Deadman 2 s.** Stillstand = Clutch, kein Klick.
- Tests + MARKETING_VERSION 1.6.56 (Build 89).

## Neu in 1.6.55

1.6.54 Per-Display Scale, Deadzone×Scale, Momentum, Homographie-Rotation, Click-Energy. Cursor zitterte bei Continuity 8 Hz. HUD in Screenshots. Bezel-Lücke 5K↔Sidecar verschluckte den Zeiger. Rand = hartes Clamp.

- **Adaptive Gain aus Jitter-RMS.** Intent bleibt, 8-Hz-Rauschen dämpft.
- **HUD sharingType .none.** Nicht in Screenshot/Aufnahme.
- **Window-Edge Resistance.** Gain 0,35 am Rand.
- **Multi-Display Warp.** Schritt auf dem aktuellen Schirm, Lücke clamp, Hop nur auf echten Schirm.
- Tests + MARKETING_VERSION 1.6.55 (Build 88).

## Neu in 1.6.54

1.6.53 Pointer×Scale, Scroll-Ticks, Rotation-Nudge, Click-Hitch — immer Main-Display. Sidecar erbte 5K. Zwei-Pinzette tot nach Loslassen. Klick nur Dauer.

- **Per-Display Scale.** Cursor-Schirm, nicht `NSScreen.main`.
- **Deadzone × Scale.**
- **Two-pinch Momentum.** Loslassen coastet.
- **Homographie keyed by rotation.** Nudge ohne Store-Wipe.
- **Click-Energy.** Fest+still / Wackel blockt.
- Tests + MARKETING_VERSION 1.6.54 (Build 87).

## Neu in 1.6.53

1.6.52 Two-pinch Hysterese, Rotation-Recalib, CGEvent 90 Hz. Zeiger teleportierte auf Retina. 90° wischte die Map. Hitch = Doppelklick.

- **Pointer-Gain × Scale.** UV bleibt, Gain / backingScaleFactor.
- **Scroll-Ticks × Scale.** Two-pinch auf Retina.
- **Rotation-Nudge.** 90/180/270 Palmen halten. Wipe nur schräg.
- **Click-Hitch.** Continuity-Miss ≠ Double-Click.
- Tests + MARKETING_VERSION 1.6.53 (Build 86).

## Neu in 1.6.52

1.6.51 Two-pinch vs Scroll, Coast-Cap×Scale, Jiggle×Scale. Achse kippte bei Jitter. Display-Drehung tot. Sample-Cursor zog Coast zurück.

- **Two-pinch Hysterese.** Achse hält bei Jitter. Kleine Span-Δ = Scroll-Ticks.
- **SpaceMap Re-Calib** nach Display-Drehung (≥ 15°).
- **CGEvent 90 Hz.** Sample weicht Coast. SuppressionInterval 0.
- Tests + MARKETING_VERSION 1.6.52 (Build 85).

## Neu in 1.6.51

1.6.50 Clutch×Scale, AX-Window, reduced-motion, Vision-Stale, Pinch analog. Zoom startete Scroll. Coast 80 pt auf Retina zu kurz. Jiggle 1,2 pt ließ eigene CGEvents durch.

- **Two-pinch vs Scroll.** Zoom hält Wisch 0,28 s tot.
- **HUD-Coast-Cap × Scale.** 2× = 160 pt.
- **Clutch-Jiggle × Scale.** Echo ignoriert.
- Tests + MARKETING_VERSION 1.6.51 (Build 84).

## Neu in 1.6.50

1.6.49 720-Lock, 24 fps, Click-Vel, HUD-Coast, Per-Display. Retina-Maus seizes. Coast wechselte AX-Fenster. Reduce-Motion coastet. Vision stale. Pinch-Bool droppt.

- **Clutch × backingScaleFactor.** 2× = 96 pt.
- **AX-Fenster-ID Cache** während Coast.
- **reduced-motion HUD** ohne Coast.
- **Vision-Timeout 400 ms.** Stale Frame drop.
- **Pinch analog** Closedness×zSep.
- Tests + MARKETING_VERSION 1.6.50 (Build 83).

## Neu in 1.6.49

1.6.48 inputPriority, Native 420, Freeze-Cursor, Pinch/AX, Wake. Continuity startete trotzdem claimed 1080@30 → 8 fps. Slow-Drift wurde Fensterzug. HUD hing ein Frame hinter. Homographie nur Main.

- **720p-Lock persist.** Continuity Kaltstart 720. `helios.formatHeight`.
- **24 fps Lock.** Kein 30-Request der auf 8 fällt.
- **Click-vs-Drag Palm-Vel.** Drift bleibt Klick. Flick ist Zug.
- **HUD-Coast 90 Hz.** OS-Cursor folgt. Clutch über Radius.
- **Per-Display SpaceMap.**
- Tests + MARKETING_VERSION 1.6.49 (Build 82).

## Neu in 1.6.48

1.6.47 start() hielt Leiter, lastFormatHeight sticky, Mac nie. SessionPreset `.hd1920x1080` klemmte Continuity trotzdem auf 8 fps. Freeze ließ Cursor stehen und droppte Pinch/Fenster.

- **inputPriority statt 1080p.** Continuity darf 720p@24. Cover analog.
- **Native 420.** Kein BGRA-Convert pro Frame.
- **Freeze treibt Cursor.** Kalman-Palme bleibt der Zeiger.
- **Freeze hält Pinch + AX-Zug.** Nur echter Dropout droppt Gate.
- **Wake-Recovery.** Sleep tötet Continuity nicht dauerhaft.
- Tests + MARKETING_VERSION 1.6.48 (Build 81).

## Neu in 1.6.47

1.6.46 uniqueID sticky Name, PTS-Wall, Kalman-Palme. `start()` setzte lastFormatHeight=1080 und lastDeviceUniqueID="". uniqueID-Wechsel dumpte die Leiter trotz gleichem iPhone. Mac-Name klebte.

- **start() hält Leiter.** lastFormatHeight / lastDeviceUniqueID / Role überleben Reconnect.
- **lastFormatHeightResets sticky.** Gleicher Name+Role, Mac nie. Continuity-Reconnect bleibt 720p@24.
- Tests + MARKETING_VERSION 1.6.47 (Build 80).

## Neu in 1.6.46

1.6.45 HMM pinchHeld Call-Site, dtPalm, Format-Retry. Continuity uniqueID flackert → Homographie+Recenter. PTS als Wall → Uhr-Sprung = Dropout. Leiter 1080p der alten Cam. preferredDevice fällt auf Built-in. Freeze stand 90 ms.

- **uniqueID sticky.** Gleicher Gerätename (ohne ` · Tiefe`) hält Homographie. `SpaceMap.retarget` unter neue ID. Erster Frame kein Reset.
- **PTS-Sprung = Freeze.** `ptsWallStamp` — Continuity-Uhr-Reset ist nicht Hand-weg.
- **lastFormatHeight + preferredID.** Leiter neu nach Cam-Wechsel. Name-Reconnect statt Built-in.
- **Kalman-Palme im Tracker.** Leere Observations: `freezeKalmanPredict` mit lastVel.
- Tests + MARKETING_VERSION 1.6.46 (Build 79).

## Neu in 1.6.45

1.6.44 DisplayLink HUD, PinchHoldPhase in driveGrab. PoseHMM kannte pinchHeld, HandTracker reichte ihn nicht. Zweite `let dt` in analyze ungeklemmt. Format-Retry tot hinter 8 s already.

- **HMM Gate-Held.** `hmm.step(..., pinchHeld: pinchState.closed)`. Stay-Tau 110 ms, Boost gegen Faust-Tick bei 8 fps.
- **dtPalm = sampleDt.** Zweite Uhr `now - lastNow` war Dropout-Sprung in palmWidthEMA.
- **Format-Leiter Retry.** `cameraFormatRenegotiateRetry` nach 3 s, nicht erst nach 8 s Cooldown. 1080p@8 → 720p@24 → 960p@15.
- Tests + MARKETING_VERSION 1.6.45 (Build 78).

## Neu in 1.6.44

1.6.43 Format-Leiter, PinchHoldPhase Math, fail-closed AX. HUD am Detect-Takt 8 Hz. Engine las Bool.

- **DisplayLink 90 Hz HUD.** Overlay interpoliert per Track-ID, Freeze snap, 1 Frame Lag statt 8-Hz-Raster.
- **PinchHoldPhase verdrahtet.** `driveGrab` liest Unseen/Tentative/Held/Released. Ein Continuity-Miss ist kein Klick.
- Tests + MARKETING_VERSION 1.6.44 (Build 77).

## Neu in 1.6.43

1.6.42 Fusion Source-Tag, Reliability-Decay, freezeKalmanQ. Format-Retry denselben 1080p@8. Pinch Bool. AX-Drop warf Cursor.

- **Format-Leiter.** 1080p@8 → 720p@24 → 960p@15 → 640p@30, nicht denselben Retry.
- **PinchHoldPhase.** Unseen / Tentative / Held / Released — Math, Engine folgt.
- **Fail-closed AX.** Ohne Bedienungshilfen kein Cursor-Move.
- Tests + MARKETING_VERSION 1.6.43 (Build 76).

## Neu in 1.6.42


1.6.41 AX-TTL sampleDt, Drag×dt, Format-Score gemessen. Fusion stempelte immer `geometry2D`. Fehlende Quellen Reliability 1. Kalman-Q fest 0,94.

- **Fusion Source-Tag.** `fused.source` = argmax Gewicht, nicht immer 2D. HUD `führt`.
- **Reliability-Decay.** Fehlende Quelle × 0,92 / Frame, Floor 0,02. tot-Tiefe nicht mit vollem Gewicht.
- **freezeKalmanQ(dt).** 8 fps mehr Process-Noise, Reibung 0,90. 24 fps bleibt 0,94 / 0,0008.
- Tests + MARKETING_VERSION 1.6.42 (Build 75).

## Neu in 1.6.41

1.6.40 Kalman-Palme, AX-Cache, Palm-EMA, Gain×dt, q je Hand, Format-Nachzug. AX-Cache TTL hart 40 ms — bei Continuity 8 fps nie ein Treffer. pinchDragNeed 0,45 = ein Tick = Zug. Format-Nachzug einmal mit demselben Score → 1080p bleibt. HMM-Reset 0,35 s.

- **axHitCacheFresh(dt: sampleDt).** 8 fps 1 Frame, nicht 40 ms.
- **pinchDragNeedOf / pinchDragCursorNeed.** 8 fps 0,61 HW / 40 px — Klick bleibt Klick.
- **cameraFormatScoreMeasured + Cooldown 8 s.** Gemessen 8 fps → 720p, Retry wenn weiter langsam.
- **trackDropoutNeed(dt).** HMM überlebt Freeze+Recover.
- Tests + MARKETING_VERSION 1.6.41 (Build 74).

## Neu in 1.6.40

1.6.39 Approach+Reach, Finger-Kontakt, q-Gate, Tip-Konfidenz. Freeze-Geist Vel-Decay 0,82 tot nach 3 Continuity-Ticks. AX hitTest jeden Tick. palmWidth α 0,22 Frame. Pointer-Gain ein Tick = Teleport. q-Chip nur Actor. Format-Score einmal, 8 fps bleibt.

- **freezeKalmanPredict / Update / Palms.** Reibung 0,94, P wächst. Recover blendet Messung.
- **axHitCacheFresh** 1 Frame. Continuity sonst AX jeden Tick.
- **palmWidthEMA × dt.** 8 fps α 0,12 — Reach/Gate nicht mehr ein Jitter-Tick.
- **pointerGainDt.** 8 fps × 0,32, 24 fps = 1.
- **qualityChips** je Hand `T1 q tot · T2 q tot`.
- **cameraFormatRenegotiate** gemessene fps < 12, einmal pro Session.
- Tests + MARKETING_VERSION 1.6.40 (Build 73).

## Neu in 1.6.39

1.6.38 Zwei-Hand-Freeze, Clutch, Vel-Chip, lastZ. Approach-Veto tötete echte Pinzette zur Kamera (Reach 1,1). Gate Close 0,55 hart. Kein Finger-Kontakt. Occluded Tips fütterten z. q tot dämpfte pinchRatio nicht.

- **pinch3DVeto** Reach skippt Approach. Echte Pinzette (Reach ≥ Need+0,15) bleibt. Faust-in-Kamera tot.
- **pinchFingerContact** + Gate Close über `pinchClosednessNeed`. Contact nur q ≥ 0,55.
- **pinchRatioSmooth × quality.** q tot dämpft cutoff.
- **HandTracker** zSep/Approach nur bei Tip-Konfidenz > 0,22.
- Tests + MARKETING_VERSION 1.6.39 (Build 72).

## Neu in 1.6.38

1.6.37 Format, Residual, Sign, q-Chip, One-Euro, Tastatur-Ring. Freeze-Δ nur Actor. Jiggler weckt Geist. Predict unsichtbar. lastZ bei Occlusion weitergeschrieben.

- **freezePalmsPredict** + **freezeGhostDeltas.** Zweite Hand nicht mehr Actor-Δ.
- **clutchIgnoresFreeze.** Jiggler seize tot während Freeze.
- **freezeVelChip** →/←/↓/↑ am Lock-Chip.
- **liftSignKeepsPrevious.** Occlusion hält lastZ.
- Tests + MARKETING_VERSION 1.6.38 (Build 71).

## Neu in 1.6.37

1.6.36 Approach-Veto, Recover-Sprung, Faust-Grace. Continuity wählte 1080p@8 weil `bestFormat` fps < 24 warf. PinchGate nur 2D. Lift3D-Sign kippte bei Occlusion. Residual-Veto tötete echte Pinzette oder ließ Faust durch. HUD ohne q-Chip. Tastatur-Ring 3 px bei 8 fps unsichtbar.

- **cameraFormatScore.** 720p@24 vor 1080p@8. Unter 24 fps nicht verwerfen.
- **pinch3DTrusts + residual** in pinchLooksLikePinch / Starts / Holds / Gate. z tot wenn Lift-Residual hoch.
- **liftSignHolds.** Kleines previous[] fällt auf Anatomie, Occlusion kippt nicht.
- **pinchRatioSmooth** One-Euro. Gate-Jitter bei 8 fps kein Klick.
- **qualityChip** HUD `q tot` bei Landmark < 0,55.
- **AirKeyboard-Ring** `chromeDwellRingWidth(dt)`.
- Tests + MARKETING_VERSION 1.6.37 (Build 70).

## Neu in 1.6.36

1.6.35 Closedness×q, Freeze-Predict, Ampel-Ring. pinchActor ohne z. pinch3DVeto tötete echte Pinzetten (Lift3D-z-Rauschen). Recover dämpfte nur Breite. Heranziehen nur Palm-Y. Faust-Scharf 0,22 s = ein Continuity-Tick.

- **pinch3DApproach + pinch3DVeto(approach, reach).** Faust-in-Kamera = Approach. Echte Pinzette mit z-Rauschen bleibt (Reach ≥ Need+0,15 skippt nur Sep).
- **pinchActor** zSep + Approach + Closedness-Need. 1.6.34-Veto war tot am Actor.
- **emptyHandsRecoverPalmJump.** Palmensprung nach Dropout, nicht nur Breite.
- **pullTowardPalmGrow.** Hand auf die Kamera = Palme wächst.
- **fistScharfGrace(dt).** 8 fps ≥ 0,27 s unknown.
- Tests + MARKETING_VERSION 1.6.36 (Build 69).

## Neu in 1.6.35

1.6.34 Ampel × dt, 3D-Pinch, Freeze-HUD. Closedness-Tor ignorierte Landmark-Qualität — Faust-Klick bei q tot. Freeze-Geist stand, Recover teleportierte. Ampel-Ring 6 px, bei 8 fps 4 Frames unsichtbar.

- **pinchClosednessNeed(quality, start).** q < 0,55 hebt das Tor. Faust mit toten Spitzen kein Klick.
- **pinchStartsGrab / pinchHoldsGrab** nehmen `quality`. GestureEngine reicht `hand.quality`.
- **freezePalmPredict.** Geisterhand folgt letzter Vel × decay 0,82. Recover ohne Teleport.
- **TrackedHand.shifted(by:)** + AppState wendet `freezeGhostDelta` an.
- **chromeDwellRingWidth(dt).** 8 fps dicker, 24 fps bleibt 6 px.
- Tests + MARKETING_VERSION 1.6.35 (Build 68).

## Neu in 1.6.34

1.6.33 hat Klick/Zwei-Pinzetten/Tastatur auf Continuity-Zeit. Ampel blieb 0,55 s / 18 px — ein 8-fps-Tick plus Gain setzt das Still-Tor jedes Frame zurück. Faust in die Kamera sieht in 2D wie Pinzette aus. HMM gibt 0,70 Faust bei toten Spitzen. Freeze-HUD leer, fps-Sparkline ungenutzt, Zwei-Pinzetten-Achse unsichtbar.

- **chromeDwellNeed(dt).** 24 fps bleibt 0,55 s. 8 fps ≥ 0,65 s — Zielen schließt die Ampel nicht.
- **chromeDwellStillNeed(dt, screenMin).** 18 px bei 24 fps. Continuity 8 fps und 5K sonst tot.
- **pinch3DSep / pinch3DVeto.** |z_Daumen − z_Zeigefinger| in Palmenbreiten. Faust-in-Kamera kein Klick.
- **PoseHMM.qualityScale.** q < 0,55 mischt Emission gegen Uniform — unknown führt, nicht 0,70 Faust.
- **freezeLive.** Overlay dimmt, letzte Palme bleibt (Geisterhand), Skeleton 0,38.
- **fpsSparkBars + HUD-Spark.** 8 s, nicht nur amber-Bool.
- **twoPinchAxisChip** `H`/`V` am Lock.
- Tests + MARKETING_VERSION 1.6.34 (Build 67).

## Neu in 1.6.33

1.6.32 hat HMM/Temporal/Release auf Continuity-Zeit. Klick-Min blieb 50 ms, Zwei-Pinzetten-Confirm 120 ms, Tastatur 120 ms — ein 8-fps-Tick.

- **pinchClickMinNeed(dt).** 24 fps 50 ms. 8 fps ≥ 150 ms — Jitter ist kein Klick.
- **twoPinchConfirmNeed(dt).** 8 fps zwei Frames, sonst Zoom aus einem Tick.
- **keyboardDwellNeed(dt).** Vorbeifliegen tippt nicht.
- **Klick-Cooldown** = `pinchReleaseNeed(dt)`, nicht hart 120 ms.
- Tests + MARKETING_VERSION 1.6.33 (Build 66).

## Neu in 1.6.32

1.6.31 droppt Pinch bei Dropout, aber Continuity 8 fps blieb zäh: HMM-Hold war 50 ms (ein Frame schaltet immer), TemporalNet dachte in 12 Frames (= 1,5 s tot), Recover teleportierte bei Palm-Sprung, Release-Tot war 120 ms (= 1 Frame), HUD zeigte den Pinch-Drop nicht.

- **HMM `switchHold(dt)`.** 24 fps bleibt 50 ms. 8 fps zwei Frames, sonst Faust↔Pinzette jeden Tick.
- **HMM `pinchTau(dt)`.** EMA glättet bei 8 fps nicht mehr mit α ≈ 0,94.
- **TemporalNet in Sekunden.** `maxAge` 0,80 s, 8 fps braucht 3 Frames, Skip nur unter 12 ms.
- **pinchReleaseNeed(dt).** 8 fps ≥ 200 ms — kein Folge-Klick nach Freeze.
- **emptyHandsRecoverPalmMul.** Palme näher nach Dropout → Gain klein.
- **HUD `P drop`** wenn Freeze den Pinch killt. R1/R2 bleiben.
- Tests + MARKETING_VERSION 1.6.32 (Build 65).

## Neu in 1.6.31

1.6.30 hat Cover-Maps und preparePair. Dropout gab AX frei, ließ pinchHeld aber stehen — die Hand kommt zurück, Gate öffnet, Klick. Recover war unsichtbar.

- **emptyHandsHoldDropsPinch.** Freeze droppt Pinch + Drag-Flag. Mute wie echtes Loslassen. Kein Dropout-Klick.
- **emptyHandsRecoverChip** `R1`/`R2` im HUD während recoverUntil. Freeze-Chip bleibt für Miss.
- Tests + MARKETING_VERSION 1.6.31 (Build 64).

## Neu in 1.6.30

1.6.29 hat Cover-Maps unter `cam.<id>.<display>` gespeichert und ohne Display-ID gelesen — Konsole blieb bei „4 Ecken fehlen“. `preparePair` schrieb die Kamera-IDs asynchron, `loadPrefs` las sie sofort.

- **load(cameraID:)** ohne Display findet den Display-Key (Screens + Alias-Key 0). `coverCalibrated` / Start-Kalibrierung übergeben `mainDisplayID`.
- **preparePair** schreibt UserDefaults auf dem Caller. Nur `preferredID` geht auf die Kamera-Queue.
- **ScreenGeometry** behält den Observer-Token.

## Neu in 1.6.29

1.6.28 hat den Ring nach einem Auflösungswechsel nicht wieder aufgebaut, Cover als kalibriert gemeldet ohne Cover-Kamera, und chromeKnobs vor dem Cache AX gerufen.

- **Ring.** `pendingW/H` — One-off nur solange alte Slots busy sind. `release` baut um, sobald der Ring frei ist.
- **chromeKnobs** prüft den Cache zuerst. Ohne Fenster wird die Leere 260 ms gehalten.
- **Cover-Map** nur aus cam-spezifischem Key. Globales `helios.spaceMap` ist Lead-Fallback, nicht Cover. Eine Map mit `cameraID` im globalen Slot gilt nicht als Lead.
- **ScreenGeometry** invalidiert über `didChangeScreenParameters`. `swiftc` braucht `CGRect.null`, nicht `.null`.
- **preparePair** `async` auf der Kamera-Queue, kein `sync` auf dem Main-Thread.
- **Observer** nur auf dem Center, das sie registriert hat.

## Neu in 1.6.28

1.6.22–1.6.27 bauten nicht: `flingVelFromTail` war zweimal deklariert, CoordTests widersprachen sich (Floor ≤ 0,62 und ≥ 0,66). Latest-Download blieb v1.6.21.

- **Build.** Eine `flingVelFromTail`. Aktions-Tor-Tests folgen 0,52–0,68. `win` in CoordTests nur einmal. Screen- und Tastatur-Cache `nonisolated(unsafe)`; Filmstreifen-Typ trägt `image`.
- **AX ist Quartz.** Fensterzug, Andocken und Elementtreffer nicht mehr über Cocoa-Y — vertikal gegen die Hand ist tot.
- **Konsole bei Scharf aus.** `hide()` hebt den Launch-Pin. Observer werden beim Beenden entfernt.
- **Uhren.** Drill und Filmstreifen laufen auf der Kamera-PTS, nicht `CACurrentMediaTime`.
- **Cover-Kalibrierung** schreibt nicht mehr die globale Homographie. Homographie-Cache hält Lead und Cover.
- **Ring / Preview.** Auflösungswechsel clobbert keine In-Flight-Slots. Preview liest den Buffer vor `release`.
- **Stillstand** vergleicht Palmen per Hand-ID, nicht Array-Index.

## Neu in 1.6.27

1.6.26 Freeze-Decay galt **einen Tick** — danach voller Gain, Palme springt. Dropout ließ den AX-Zug stehen (Fenster in der Luft). Scroll-Inertia überdeckte den Pinch-Start. Zwei-Pinzetten kannten nur „gegenüber“, nicht links/rechts vs. oben/unten. fps-Amber war der letzte 0,5-s-Wert.

- **Recover über 2 Frames.** `emptyHandsRecoverLive` 0,25 → 1 über `dt × 2,2`.
- **Dropout gibt AX frei.** Cursor bleibt freeze, Fenster klebt nicht.
- **Zwei-Pinzetten-Achse** merkt horizontal/vertikal. Jitter dreht nicht um.
- **Coast bricht bei Pinch.** Inertia startet keinen Klick.
- **fps-Spark 8 s.** Mittel unter 10 bleibt amber, nicht nur der letzte Sample.

## Neu in 1.6.26

1.6.25 hat Zeiger-Freeze ohne Pinch — nach dem Dropout teleportierte die Palme, ein Jitter-Tick skalierte das Fenster, Werfen erbte den Zoom-Trail, Scroll starb hart, fps unter 10 war unsichtbar.

- **Freeze-Decay.** Nach Fehlframes startet der Zeiger mit reduziertem Gain, kein Sprung.
- **Zwei-Pinzetten 2–3 Frames** an den Kanten, bevor Zoom feuert. Trail leer beim Ausstieg.
- **Scroll-Totzone 0,08** plus **200 ms Inertia** nach Loslassen.
- **HUD fps amber** unter 10.

## Neu in 1.6.25

1.6.24 hat Scroll vs Kill und Freeze-Chip — Continuity tötete den Zeiger trotzdem, sobald keine Pinzette da war. Die Maus-Pause sah eigene Cursor-Events. Kamerawechsel behielt die alte Homographie.

- **Zeiger hält** zwei Fehlframes, auch ohne Pinzette.
- **Clutch nur echte Hardware.** Kein Local-Monitor, Mini-Zucken unter 1,2 px zählt nicht.
- **Kamera-Zeitstempel** steuert Filter und Gesten. uniqueID-Wechsel setzt Zeiger und Homographie neu.
- **Zwei-Pinzetten** an gegenüberliegenden Fensterhälften. Werfen aus den letzten 2–3 Samples.

## Neu in 1.6.24

1.6.23 hat Profile tot und Lock freeze — Scroll brauchte **zwei offene Hände** und war derselbe Kandidat wie Not-Aus. Ein Palm-Zucken hat gescrollt, während Kill 1,35 s zählte. `pinchActor` stempelte den Fehlframe auf die Wanduhr (testMode / Continuity lügen). Gate-Auf feuerte Folge-Klick.

- **Scroll nur Steuerhand.** Genau eine offene Hand. Zwei offene = Not-Aus, Scroll-Anker weg.
- **Pinch-Miss auf Tick-Takt** (`lastTickNow`), nicht `CACurrentMediaTime`.
- **Release 120 ms tot** nach Gate-Auf — Öffnen ist kein zweiter Klick.
- **HUD `T1 freeze`** wenn Lock-ID einen Fehlframe hält.

## Neu in 1.6.23

1.6.22 hat Faust/Ampel — CoordTests widersprechen sich (Xcode voll **und** aus), Continuity tötet den Zug nach 180 ms, Steuerhand teleportiert, Zwei-Pinzetten springen.

- **Profile wieder tot** (wie 1.6.17). Xcode/Safari/Finder voll. 1.6.22 hat die App in Xcode stumm geschaltet und die Tests zerlegt.
- **Steuerhand friert** einen Fehlframe (`preferredHoldID`), statt auf L/R zu springen.
- **Zwei-Pinzetten** sortiert nach Track-ID.
- **Continuity-Hold** `emptyHandsHold(dt)` ≥ 0,22 s (zwei 8-fps-Fehlframes).

## Neu in 1.6.22

Warum Klick und Zug weiter zufällig kamen: das Pinch-Gate schloss bei jeder nahen Daumen/Zeigefinger-Spitze — **Faust war Pinzette**. HMM-Closedness hielt den Wert hoch. Heranziehen feuerte im Klick-Fenster. Ampel-Verweilen zählte während du über Schließen zielst.

- **Faust ≠ Pinzette.** Gate und Greifen brauchen Reach (Spitzen weg vom Handgelenk) oder gestreckten Zeigefinger. Faust-Spitzen an der Palme starten keinen Klick/Zug. Gate **öffnet**, sobald es keine Pinzette mehr ist — Faust hält keinen Klick.
- **Closedness nur vom Gate**, nicht `max(HMM, Gate)`. HMM-Hold täuscht keine Pinzette mehr vor.
- **Halten ohne Drag braucht Reach.** Faust nach dem Klick startet keinen Zug; erst ein echter Drag darf Faust tragen.
- **Heranziehen nur nach echtem Drag** (≥ 0,35 s). Atmen maximiert das Fenster nicht.
- **Ampel nur still.** 18 px Bewegung setzt das 0,55-s-Verweilen zurück — Schließen beim Zielen ist tot.
- **App-Profile wieder an.** Xcode aus, Safari Klick/Scroll, Finder Werfen.
- **Aktions-Tor 0,52–0,68.** Flaches Softmax feuert nicht mehr bei 48 %.
- Cover bestätigt Pinch nur im Band 0,40–0,62, erfindet ihn nicht.
- **Zeigefinger-Score** ist der Classifier-Wert, nicht nur „über 0,52“.

## Neu in 1.6.21


Erkennung: weniger Fehlklicks.

- **Pinzette** kommt vom Gate, nicht von Faust-Pose oder HMM-Hold.
- **Cooldown** lässt ein laufendes Ziehen weiterlaufen.
- **Not-Aus** bricht bei leichter Bewegung ab — Zwei-Hand-Scroll tötet nicht.
- **Tastatur** tippt nur, wenn der Zeiger stillsteht.

## Neu in 1.6.20

Schneller tippen, L/R am Spiegel, Aktionskalibrierung für Grok.

- **Tippen:** Taste 0,12 s halten reicht. Keine Pinzette.
- **Links/Rechts:** Frontkamera-Spiegel dreht Vision um — deine rechte Hand ist wieder rechts.
- **Aktionskalibrierung:** 12 Gesten × 3, Countdown + 2 s Aufnahme. Testmodus, kein Fensterzugriff. „Für Grok kopieren“ legt Markdown in die Zwischenablage.

## Neu in 1.6.19

1.6.18 hat Ampel und Luft-Tastatur — Continuity blieb tot, die Steuerhand sprang, die Tastatur feuerte beim Zielen.

- **dt-Cap 200 ms.** Filter, Pinch-Vel und Kalibrier-Hold kappen 125-ms-Frames nicht mehr auf 80 ms.
- **Steuerhand bleibt Lock-ID.** L/R-Flip teleportiert den Cursor nicht. Pinzette friert, fällt nie auf die andere Hand.
- **Ampel-Verweilen startet neu**, wenn du weggehst oder nach dem Auslösen wieder kommst.
- **Heranziehen = Palm-Y** (Hand zu sich), nicht Mittelfinger-Spannweite.
- **Fling-Fenster × Frame-dt.** 8 fps hat sonst nur ein Sample im 120-ms-Fenster.
- **Luft-Tastatur:** Zeigen 0,85 s **unten** öffnet. Tippen per Verweilen.

## Neu in 1.6.18

Schließen/Vollbild per Verweilen, große getrennte Ampel-Knöpfe, Luft-Tastatur, Schrägzug, Wischen.

- **Ampel.** Schließen, Minimieren, Vollbild liegen 118 px auseinander, 80 px groß. 0,55 s Verweilen löst aus — kein Pinzetten-Zielen auf 12-px-Punkte.
- **Luft-Tastatur.** Zeigen 0,4 s öffnet QWERTZ. Pinzette tippt, Faust schließt. Menü ☀ oder Umschalt-⌘K.
- **Schrägzug.** Totzone gilt der Strecke, nicht je Achse. Seitwärts und gleichzeitig hoch/runter geht. Diagonales Loslassen dockt nicht mehr falsch.
- **Wischen.** Offene Hand, weichere Schwelle, kürzere Mute nach Pinzette.

## Neu in 1.6.17

Erkennung war rucklig und hinterher: doppeltes Glätten, Body-Pose in jedem Frame, HMM-Reset bei einem Fehlframe, Safari/Xcode-Profile haben Aktionen geschluckt.

- **Zeiger folgt der Hand.** Kalibriert ohne Hochpass-Kleber. Ein leichtes Follow, kein 0,55-Nachziehen.
- **Zwei Ringe.** Links gelb, rechts cyan. Die Systemmaus folgt der aktiven Hand.
- **Weniger Latenz.** Body-Pose nur jedes 4. Frame. Luma nicht jeden Tick. Fehlframe friert 90 ms, statt Pose zu löschen.
- **Gelbe gestrichelte Linie** war der Kasten um die linke Hand im Kamerabild — weg. Beim Greifen ist die Linie zum Fenster jetzt durchgezogen.
- Aktions-Tor wieder um 0,48–0,60. App-Profile greifen nicht mehr.

## Neu in 1.6.16

Osmo/Cover hat allein Aktionen ausgelöst (schräger Blickwinkel, falsche Pinzette) — Kalibrierung rutschte weg, ohne dass du etwas getan hast.

- **Mac führt.** Cover ist nur Ergänzung für Finger- und Handlage. Keine eigenen Klicks, Züge, Würfe.
- Ohne Hand in der Mac-Kamera passiert nichts, auch wenn Osmo etwas sieht.
- Cover darf Pinch nur **bestätigen**, nicht erfinden. Lage wird gemischt, wenn beide Homographien einig sind; sonst Mac.
- Cover-Kalibrierung: Pinzette zählt nur, wenn die Mac-Kamera sie auch sieht.

## Neu in 1.6.15

Kein Zurückspringen. 1.6.13 hat beim Klick auf die Konsole den Fokus an die App darunter zurückgegeben. Helios aktiviert keine andere App mehr. Die Konsole bleibt, wenn du sie anwählst; SwiftUI holt sie nicht über andere Fenster und schubst dich nicht weg.

## Neu in 1.6.14

Klick und Gesten wirkten weiter zufällig: die Pinzette sprang auf die **andere Hand**, sobald Vision einen Frame verlor (Kommentar: „nicht springen“ — Code sprang). Flaches Softmax blieb über 62 %, Continuity 8 fps war tot, HMM-Hold drückte die Pose-Prob unter das Tor.

- **Pinzette bleibt an der Lock-Hand.** Fehlender Frame friert, klickt nicht mit der Steuerhand.
- **Aktions-Tor folgt der Fusion-Entropie** (spitz 55 %, flach 72 %). HUD zeigt H und Tor.
- **Hochpass an Frame-dt.** 8 fps nicht mehr wie 24 fps. Ecken 2 % Ruhezone.
- **Hände auf dem Tisch** 1,2 s → Idle.
- **Per-App-Profil:** Xcode aus, Safari nur Klick/Scroll, Finder Werfen.
- HMM-Hold behält die letzte echte Pose-Prob.

## Neu in 1.6.13

Nach vorn nur, wenn du die Konsole **selbst** anwählst (Fenster klicken, Menüleiste ☀ → Konsole, Dock). Gesten-Klicks, Klicks in anderen Apps und Kamera-Ticks holen sie nicht.

## Neu in 1.6.12

Die Konsole ist wieder da — und bleibt stehen. Sie springt nicht mehr bei jedem Kamera-Frame über die App, die du steuerst.

- **UI bleibt.** Standard: Konsole sichtbar, auch bei Scharf. Der Schalter „Konsole bei Scharf ausblenden“ ist aus.
- **Kein Vordergrund-Diebstahl.** SwiftUI hat das Fenster bei jedem Tick key gemacht. Jetzt: nur nach vorn, wenn du Konsole, Dock oder das Fenster selbst klickst. Sonst gibt Helios den Fokus sofort zurück, das Fenster bleibt wo es war (`stationary`, `hidesOnDeactivate = false`).
- Beenden und Osmo-Livestream aus 1.6.11 unverändert.

## Neu in 1.6.11

Die Konsole wirkte abgestürzt und Helios ließ sich nicht beenden: nach **Scharf** wurde die App zum Accessory ohne Dock — das SwiftUI-Fenster war weg, Cmd+Q traf die App darunter. Osmo lief intern, ohne Livestream in der Konsole.

- **Beenden geht wieder.** Dock bleibt. Menüleiste ☀ → **Helios beenden**, oder Helios im Dock → Cmd+Q. Das rote Fenster-X schließt nur die Konsole, nicht die App.
- **Konsole zurück:** Menüleiste ☀ → Konsole, oder Helios im Dock klicken. Sie bleibt offen, bis du sie schließt — Scharf holt sie nicht mehr sofort weg.
- **Osmo als Livestream.** Bei Mac+Osmo / iPhone+Osmo zwei Bilder: Lead oben, Cover/Osmo darunter, plus zweiter Chip im HUD. Cover-Kamera ist wählbar, nicht nur Auto-Paar. Osmo/DJI am Namen erkannt. 1080p-Webcam erlaubt.

## Neu in 1.6.10

Die Installations-DMG fehlte unter Releases: die Tests vor dem Paket sind seit 1.6.0 rot gelaufen, deshalb wurde nie `Helios.dmg` hochgeladen. Latest blieb **v1.5.7**.

- **Fling-Totzone:** Mini-Ruck tot in der *kalibrierten* Schirmmitte. Echter Wurf am Rand bleibt Werfen — der Test hat einen vollen Wurf in der Mitte erwartet und CI blockiert.
- **Faust ≠ Pinzette.** Eingeringelte Finger mit Daumen neben dem Zeigefinger waren Pinzette (Klick). Pinzette braucht einen gestreckten Zeigefinger.
- **HMM hält die letzte echte Pose.** `unknown` ersetzt keine offene Hand/Faust mehr; der Track stirbt nach 0,18 s ohne Beobachtung.
- **Build auf dem Mac:** Tiefenkanal ist iOS-only — Fusion läuft ohne z, 2D/3D-Lift bleiben.

## Neu in 1.6.9

Multi-Kamera war nur ein Picker für **eine** Quelle. Jetzt echte Paare, jede Quelle mit eigener Homographie.

- **Mac + iPhone**, **Mac + Osmo**, **iPhone + Osmo (ohne Mac)**. Lead macht Gesten, Cover ist der zweite Blickwinkel.
- **Kalibrierung pro Kamera:** 4 Bildschirmecken in DIESER Sicht. Homographie schluckt Winkel, Weitwinkel, Spiegelung. Danach automatisch die zweite Quelle.
- **Winkel-Unco:** weichen die gemappten Zeiger > 140 px ab, gewinnt Lead — kein Mittelwert aus zwei falschen Winkeln.
- Cover nur wenn Lead die Hand verliert (Hysterese). Continuity ist oft exklusiv zur Mac-Kamera — Osmo per USB ist die robuste zweite Quelle.

## Neu in 1.6.8

Die zweite Hand im Bild hat 1.6.7 praktisch ausgeschaltet: Not-Aus zählte 0,8 s und **blockte jede andere Geste schon während des Haltens**. Ein unsicherer Körper-Vote hat L/R getauscht, der Cursor sprang. `.unknown` im Softmax hat klare Posen unter 62 % gedrückt.

- **Not-Aus 1,35 s**, nur zwei echte offene Hände, weit auseinander, still. Klick/Wischen/Skalieren laufen während des Zählens. Pinzette ist kein Kill.
- **Vision L/R bleibt**, außer der Körper ist sich sehr sicher (Abstand-Verhältnis < 0,50) oder Vision sagt unbekannt.
- **Kein Cursor-Sprung** wenn die Track-ID wechselt — Palme neu verankern, Zeiger bleibt.
- **unknown-Logit −1,8**, HMM hält die letzte echte Pose.
- **palmWidth geglättet** pro Hand, Fling/Wischen bei Zoom der Webcam ruhiger.

## Neu in 1.6.7

Die rechte Hand war die Steuerhand — im Code stand trotzdem `leftHanded = true`. Vision hat L/R oft getauscht, die Kalibrierung hat in der Bildschirmmitte gezittert, und bei wenigen fps hat Helios die eigene Mausbewegung als „Maus hat Vorrang“ gewertet.

- **Rechtshänder default.** Neue Installationen und leeres Pref: rechte Hand steuert. Linkshänder-Schalter bleibt.
- **Körperpose stimmt L/R ab.** `VNDetectHumanBodyPose` votiert über die Handgelenke, wenn Vision die Hände vertauscht. `forearmGate` dämpft weiter die Qualität.
- **SpaceMap hybrid.** Nur die äußeren 15 % absolut (Ecken erreichbar), innen Trackpad-Relativ — kein Homographie-Zittern in der Mitte. Kalibrierung merkt die Display-ID.
- **Maus-Clutch ignoriert eigene Events.** 48 px / 120 ms um den letzten `CGEvent`. Delta ≈ 0 zählt nicht als Hardware.
- **Pointer-Beschleunigung** (quadratisch): Feinzielen bleibt langsam, Schwung wird schneller.
- **Fling-Totzone am Schirmmittelpunkt**, sobald kalibriert — nicht mehr Kamerabild-Mitte.
- **Aktions-Log 62 %** (war Text „70 %“ bei Tor 0,62). Fusion-Temperatur als Inspector-Slider. Peace-Ring + Clutch-LED im HUD.

## Neu in 1.6.6

**2× klatschen weckt Helios**, auch wenn die Konsole weg ist und nur die Kamera im Hintergrund läuft. Rein visuell: zwei Hände, Palmenabstand fällt schnell unter Kontakt und wieder auf — **kein Mikrofon**. Faust bleibt der andere Weg zu Scharf. Not-Aus (beide Hände offen, Abstand) zählt nicht als Klatschen. Die Kamera bleibt aktiv, damit das im Hintergrund ankommt.

## Neu in 1.6.5

Der cyanfarbene Rahmen war **kein eigenes Fenster** — er markierte das Fenster unter der Hand. Standard an, plus Schreibtisch-Hintergrund = Umriss über den ganzen Monitor, SwiftUI interpolierte die Höhe, Wischen ohne zweite App schickte ⌘⇥. Die Konsole (selbst mit Cyan-Rahmen um die Kamera) kam nach SwiftUI-Updates wieder nach vorn. Zwei Pinzetten haben bei 0,28 Handbreiten Zittern die Fensterhöhe gepumpt.

- **App-Umriss aus.** Einmalig zurückgesetzt. Nur noch beim Greifen/Halten, wenn du ihn einschaltest. Schreibtisch/Wallpaper wird nie umrandet. Keine Animation zwischen Fenstern.
- **Konsole bleibt weg.** Nach Scharf: `orderOut` plus Wächter gegen `didBecomeKey` / `didBecomeMain`. SwiftUI darf sie nicht zurückholen. Menüleiste → Konsole.
- **Keine ⌘⇥-Krücke** mehr, wenn nur eine App offen ist — das war der System-Umschalter.
- **Skalieren** braucht 0,55 Handbreiten, Gegenrichtung 1,8× — Höhe pumpt nicht mehr.
- Konsole: linke Spalte scrollt, Fenster wächst nicht mit dem Inhalt.

## Neu in 1.6.4

Sitzung 2026-09-02: Pinzette wurde zum Greifen, Öffnen zum App-Wechsel, Zug nach unten zum Minimieren, die Konsole lag über den Apps, zwei Hände stahlen sich Pinzette und Cursor.

- **Pinzette kurz und still = Klick.** Zug erst ab 0,45 Handbreiten oder 28 px — 0,18 war Palm-Zittern. Die Hand, die das Gate schließt, bleibt der Actor.
- **Ziehen hält.** Loslassen nach echtem Fensterzug dockt/minimiert nicht, außer der Ruck ist klar (2,4× Werfen-Schwelle). Vertikal ablegen geht.
- **Kein Hin-und-her-Wischen.** 0,75 s Mute nach Pinzette, Gegenrichtung 1,1 s gesperrt, nur die Steuerhand wischt.
- **Zwei Pinzetten** ab `pinchClosedness > 0,42`, Bestätigung 80 ms — Skalieren stiehlt nicht mehr der erste Klick.
- **Peace** nur allein auf der Steuerhand, 1,1 s, nicht während die andere Hand offen ist (Öffnen ≠ Aufnahme).
- **Konsole aus bei Scharf.** HUD bleibt Overlay, wird nie Key-Window. Menüleiste → Konsole.
- **Kalibrierung = Anschlag**, nicht Kamerarand. Kleineres Viereck gilt.
- **Loupe + Magnet** an Schließen / Minimieren / Vollbild, wenn die Pinzette in der Titelleiste zielt.
- **Kamera-Picker:** Mac, iPhone-Kontinuität, Desk View, USB (Osmo Action 3 im Webcam-Modus). LiDAR/TrueDepth nur wenn das Format Tiefe liefert.

## Neu in 1.6.3

PR `bugfix` (1.5.8 Fling-Fenster / Dead-Man / Palm-Hochpass) war nie in `main`. 1.6.0–1.6.2 haben Fusion und AX, aber Werfen mittelte weiter den ganzen Pinch-Trail.

- **Werfen aus 120 ms.** Ziehen + Ruck zählt, nicht der Mittelwert über das Halten. Mini-Zucken in der Bildmitte dockt nicht — ein echter Wurf aus der Mitte schon. Schwellen bleiben Handbreiten.
- **Dead-Man 8 s.** Keine Hand → Idle, Faust muss neu scharf schalten. Der 180-ms-Dropout bleibt für kurze Verluste.
- **Palm-Hochpass + Totzone 0,012.** Relativ-Zeiger folgt der Geste, nicht dem Atem. SpaceMap teilt die Totzone, glättet weicher (0,55).
- **Wischen nur offene Hand** (`openScore ≥ 3`) — Peace wechselt keine Apps. Flick-Schwellen aus 1.6.1 bleiben.
- **Kill-Grace 0,14 s.** Zweite Hand am Bildrand ist kein Not-Aus.
- **Kamera-Winkel** über `videoRotationAngle`. HUD: „Relativ — kalibrieren für absolut“, ohne den Zeiger zu blocken.

## Neu in 1.6.2

Koordinaten, AX, Threads und HUD — die Erkennung aus 1.6.1 bleibt.

- **Fensterumriss sitzt.** Overlay rechnet mit Quartz-minY (obere Kante), nicht maxY. Umriss, Greifstrahl und Schirmwahl lagen eine Fensterhöhe zu tief.
- **AX crasht nicht** mehr, wenn eine App ein unerwartetes Attribut liefert (CFGetTypeID statt Force-Cast).
- **Hauptthread bleibt frei.** Peace-Aufnahme, Finder-Papierkorb und Quarantäne-xattr laufen nicht mehr synchron auf main. Fensterzug hält nur den letzten Zielpunkt, solange AX beschäftigt ist.
- **Maus hat Vorrang** auch ohne gedrückte Taste. Clutch-Monitore und der Rechte-Timer werden beim Beenden abgemeldet.
- **Kalibrierung** zählt die Haltezeit nur mit geschlossener Pinzette. Export überschreibt nur Helios-Dateien, löscht keinen Ordner.
- **Fadenkreuz-Schalter** blendet den Hand-Marker wirklich aus. Fehlende Rechte erscheinen als HUD-Zeile, nicht als modaler Alert in der Gestenschleife. Pinzette gehalten ohne Zug → Protokoll „kein Zug“, nicht „fehlgeschlagen“. Klick-Pause ebenfalls nicht als Fehler.
- Homographie einmal cachen, Vision-Revision pinnen, Helligkeit über CIAreaAverage statt GPU-Buffer-Lock.

Details: [docs/Erkennung.md](./docs/Erkennung.md), [VORSCHLAEGE.md](./VORSCHLAEGE.md).

## Neu in 1.6.1


1.6.0 hat vier Quellen fusioniert, aber drei davon waren dasselbe 2D-Signal. Die Pose kam selten über 70 %, also hat das Aktions-Tor fast alles geschluckt. 1.5.8 hat Scroll/Rechtsklick/Dwell in der README behauptet — der Code war leer.

- **Fusion entkoppelt.** 2D führt. Lift und Zeit-Heuristik kollabieren, wenn sie die 2D-Verteilung nur kopieren. Aktions-Tor 62 %.
- **Kein L/R-Doppel-Flip** auf der schon gespiegelten Frontkamera.
- **Zwei-Pinzetten** belegen den Tick auch nach der 0,35 s-Bestätigung.
- **Tracks** überleben Flicks (0,42 iso). HMM schaltet schneller.
- **Scroll** (zwei offene Hände vertikal), **Rechtsklick** (Pinzette + Ring), **Dwell-Klick** (optional, 1 s still).
- Dropout 180 ms, Pinch-Timeout 0,32 s, Latenz-Sparkline, Idle-Banner nach Not-Aus.

Details: [docs/Erkennung.md](./docs/Erkennung.md), [VORSCHLAEGE.md](./VORSCHLAEGE.md).

## Neu in 1.6.0

Erkennung ist nicht mehr nur 2D. Vier Quellen laufen parallel und werden fusioniert.

- **Isotroper Raum.** Vision-x/y sind unabhängig [0,1] — Abstände laufen in x′ = x·(w/h).
- **Track-ID statt Chiralität.** Zwei Hände auf derselben Bildseite überschreiben sich nicht mehr.
- **Gelenkwinkel + Softmax** statt Radialabstand und binärer Kanten.
- **3D-Lift** über MANO-Knochenlängen plus echte Tiefe, wo das Format sie hat.
- **Zeitnetz** 12 Frames, optional `HeliosTemporal.mlmodel`.
- 1.5.7-Sicherheit bleibt: Not-Aus 0,8 s, Scharf-Ruhe 0,7 s, Peace 0,9 s, Flick-Wischen.

## Gesten

| Geste | Wirkung |
|---|---|
| Faust halten | Scharf schalten |
| **2× klatschen** (Kamera, kein Ton) | Scharf, auch im Hintergrund |
| Offene Hand bewegen | Cursor (Trackpad: heben = neu ansetzen) |
| Pinzette kurz | Klick (still, nicht ziehen) |
| Pinzette + Ringfinger kurz | Rechtsklick |
| Pinzette oder Faust + ziehen | Fenster verschieben; Loslassen = ablegen |
| In die Papierkorb-Ecke ziehen und loslassen | Fenster zu / Finder-Auswahl in den Papierkorb |
| Werfen nach oben (Ruck, nicht das Ziehen) | Wegwerfen |
| Werfen nach unten | Minimieren |
| Werfen nach links/rechts | Andocken |
| Pinzette + zu sich ziehen | Fenster füllen |
| Zwei Pinzetten | Skalieren |
| Offene Hand **schnell** waagerecht wischen | App wechseln |
| Zwei offene Hände vertikal | Scroll |
| Offene Hand 1 s still (optional) | Dwell-Klick |
| Peace allein halten (~1,1 s) | Fensteraufnahme auf den Schreibtisch |
| Daumen hoch | App hervorholen |
| Beide Handflächen (~0,8 s, nicht zusammen) | Not-Aus → Idle (Faust **oder** 2× klatschen macht wieder scharf) |

**Testmodus** (⌘T): Erkennung anzeigen, keine Systemaktionen.

Aktive App bekommt nur beim Greifen einen Umriss, und nur wenn der Schalter an ist (Standard aus). HUD liegt auf jedem Monitor. Keine Stimme.

Bei Scharf blendet Helios die Konsole aus (Menüleiste holt sie zurück), damit die anderen Apps sichtbar bleiben.

## Kameras

Paar in der Konsole, oder eine Quelle.

| Paar / Quelle | Rolle |
|---|---|
| Eine Kamera | Nur die gewählte Quelle |
| Mac + iPhone | Mac führt (vorn), iPhone Kontinuität oder Desk View als zweiter Winkel |
| Mac + Osmo | Mac führt, Osmo Action 3 USB-Webcam (seitlich/weit) |
| iPhone + Osmo | **Kein Mac.** iPhone führt, Osmo deckt den toten Winkel |
| LiDAR | Nur wenn Kontinuität ein Tiefenformat liefert |

Kalibrierung: erst Lead 4 Ecken, dann Cover dieselben Bildschirmecken aus dem anderen Winkel. Jede Homographie gehört zu genau dieser Kamera (Blickwinkel, Weitwinkel, Spiegelung).

Continuity blockt oft die Mac-Kamera — dann bleibt Lead allein. Osmo per USB ist die robuste zweite Quelle. Cover-Vision läuft gedrosselt (~20 fps).

## Bau

Xcode 26/27, macOS 26 SDK:

```
xcodebuild -project macos/Helios.xcodeproj -scheme Helios -configuration Release ARCHS=arm64
swiftc macos/Helios/CoordMath.swift macos/HeliosTests/CoordTests.swift -o /tmp/coordtests && /tmp/coordtests
```

GitHub Actions legt bei jedem Push auf `main` eine `Helios.dmg` als Release ab.

Ad-hoc-Signatur. Developer ID + Notarisierung braucht ein Apple-Zertifikat — ohne das muss der Nutzer nach jedem Update die TCC-Schalter neu setzen.

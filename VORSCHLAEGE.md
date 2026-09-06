# Helios — Vorschlagsliste

Stand **1.5.144** (2026-09-06). Aktueller Nachtrag: [VORSCHLAEGE-NEU.md](VORSCHLAEGE-NEU.md). Analyse: [ANALYSE.md](ANALYSE.md). Nur `main`. `bugfix` ist Altlast — nicht fortsetzen.

Neu in 1.5.144: HandCount 4, Fingerkette, Span-Veto Prop, Smooth 0,35.

## In 1.5.79 wirklich im Code

1.5.78 HOLD je Achse, destEdge radial, 8 fps Gain, Coast τ, Warp Relock 3 Frames. destEdgeVel skalar. destEdgeStep während Pinch. Fill destEdge nochmal.

- **`destEdgeMulX` / `destEdgeMulY` / `destEdgeMulOf`.** Vel/Step je Achse. Entlang Bezel Y frei.
- **`destEdgeApplies(dragging:pinchHeld:)`.** Engine Pinch/Drag voll zum Rand.
- **`destEdgeFill`.** 8 fps skip zweites destEdge.
- Tests + MARKETING_VERSION 1.5.79 (Build 99).

## In 1.5.78 wirklich im Code

1.5.77 Open-Hysterese, Fill coalesced, destBounds-Latch, Fill-Share. HOLD Hypot. destEdge min Ecke tot. 8 fps Rand träge. Coast fest. Relock Cap weg.

- **`palmStillOf` / `palmUnstillOf`.** Engine freezeIfStill(dx:dy:).
- **`destEdgeDist` / `destEdgeMul(dt:)`.**
- **`displayLinkCoastTau` / `cursorWarpCapHold`.**
- **`destEdgeChip` EDGE 12.**
- Tests + MARKETING_VERSION 1.5.78 (Build 98).

## In 1.5.77 wirklich im Code

1.5.76 Totzone je Achse, destEdge Kamera-Tick, Warp Relock Map, EDGE. Pinch Need 1 nach Open. Fill+Kamera vsync. destBounds ohne ID. Fill-Cap je Tick.

- **`pinchCloseNeed(justOpened:)`.** Dropout dt ≥ 0,20.
- **`displayTickCoalesced` / PeriodAdaptive / `assumeIsolated`.**
- **`destClampMapHolds`.**
- **`displayTickWarpShare`.**
- Tests + MARKETING_VERSION 1.5.77 (Build 97).

## In 1.5.76 wirklich im Code

1.5.75: Kalman-Q je Achse, Warp-Cap Diagonale, Fill-Rand. Hypot-Dead schluckte X. destEdge nur Fill. Relock Warp 48.

- **`palmDeadOf(mad:)`.** Engine deadNowX/Y.
- **`destEdgeStep` / `destEdgeScreen`.**
- **`cursorWarpCapScreenOf(steal:map:)`.**
- **`destEdgeChip`.**
- Tests + MARKETING_VERSION 1.5.76 (Build 96).

## In 1.5.75 wirklich im Code

1.5.74: Fill-Coast, Rest-MAD, 2×2 P, Residual-Mul, Naht 24 px, HOLD. Hypot-MAD hob Q auf X und Y. Warp fest. Fill volle Vel am Bezel.

- **`palmMad` / `palmKalman(madX:madY:)`.**
- **`cursorWarpCapScreen`.**
- **`destEdgeMul` / `destEdgeVel`.**
- Tests + MARKETING_VERSION 1.5.75 (Build 95).

## In 1.5.74 wirklich im Code

1.5.73: Fill tot bei Still, Y × Höhe, Screen-px Vel, Kalman-Q aus MAD. Fill ohne Reibung. Flick-Vel stale. Skalar-k. Naht ohne Pad.

- **`displayLinkCoast`.**
- **`palmVelScreenKeep` / `palmVelScreenStale`.**
- **`palmKalmanStep` + 2×2 P + `palmKalmanResidualMul`.**
- **`screenSeamHolds`.**
- **`fpsLatchChip(frozen:)`.**
- Tests + MARKETING_VERSION 1.5.74 (Build 94).

## In 1.5.73 wirklich im Code

1.5.72: Display-Link Vel aus Kamera, Freeze vel 0, Fill tot bei Hold, Totzone MAD, Display rebase. Still-Clutch füllte. Y × Breite. Warp ohne Screen-px.

- **`displayTickBlocksStill`.**
- **`displayLinkMappedScale` / `mappedScaleY`.**
- **`palmVelScreen`.**
- **`palmKalmanQ(mad:)`.**
- Tests + MARKETING_VERSION 1.5.73 (Build 93).

## In 1.5.72 wirklich im Code

1.5.71: Continuity-Floor, 24 fps Kalman, kleines Lead, echter Display-dt, Totzone 6. Fill compoundete. Freeze kroch. RMS nach Flick klebte.

- **`displayLinkVelCamera`.**
- **`palmKalmanFreezeVel`.**
- **`displayTickBlocksHold`.**
- **`palmDeadAdaptive` MAD.**
- **`displayLinkRebase`.**
- Tests + MARKETING_VERSION 1.5.72 (Build 92).

## In 1.5.71 wirklich im Code

1.5.70: Kalman-State, Dead adaptiv, Freeze auf Mean, 60 Hz Period, ROI keep-S1. Continuity tot. 24 fps roh. Lead×Kalman. Timer-Burst.

- **`palmLowConfFloor(continuity)` / `palmTipConf` / `tipHeld`.**
- **`palmKalmanUses`.**
- **`predictLeadAfterKalman`.**
- **`displayLinkElapsed`.**
- **`palmDeadWindow(dt)`.**
- Tests + MARKETING_VERSION 1.5.71 (Build 91).

## In 1.5.70 wirklich im Code

1.5.69: Kalman-R, Pinch ratio-only, ROI-S1-Helfer. State weggeworfen. Dead fest. 24 Hz. Crop an S2.

- **`palmKalmanKeepsState`.**
- **`palmDeadAdaptive`.**
- **`palmLowConfFreeze` / `palmHolds`.**
- **`displayLinkPeriod` 60 Hz + `displayLinkStepMul`.**
- **`palmROISlotPalm(keepPalm:)`.**
- Tests + MARKETING_VERSION 1.5.70 (Build 90).

## In 1.5.69 wirklich im Code

1.5.68: ROI-Miss, Pinch-Margin, Faust-AE, luma-Q. R fest 0,045. Ein Sample öffnet. Crop an first. Built-in AE. Floor 64 während Faust.

- **`palmKalmanR(tipConf)`.**
- **`pinchOpenNeed(ratioOnly:)`.**
- **`palmROISlotPalm`.**
- **`fistAELockApplies(continuity)`.**
- **`cursorWarpFloor(lumaWarp:)`.**
- Tests + MARKETING_VERSION 1.5.69 (Build 89).

## In 1.5.68 wirklich im Code

1.5.67: ROI, Latch-Cap, Palm-Vel. Crop-Miss Ghost. 0,59 ohne Vel = Klick. Faust ohne AE = Warp.

- **`palmROIMissRetries` / `palmROIMissGoesFull`.** 24 fps 1,4× dann voll. 8 fps direkt voll.
- **`pinchWantOpen` 8 fps +0,06** ohne Vel.
- **`fistAELock` 0,8 s.** **`palmKalmanFreeze` nur im AE-Fenster.** **`palmKalmanQ(luma)`.**
- **`tipOccluded`.** Overlay ohne Tips in der Palme.
- Tests + MARKETING_VERSION 1.5.68 (Build 88).

## In 1.5.67 wirklich im Code


1.5.66: Ghosts, Pool, Sparse. Doppelte Pinch-Hysterese 250 ms. S3 am Latch. Warp-Freeze vel=0. Vision volles Bild. Center Stage nach Sleep.

- **`pinchPoseHoldNeed(gateClosed)`.** 8 fps Gate zu = 0.
- **`slotMintsNew` / `slotAllocCap`.** Latch max 2.
- **`palmVisionROI`.** lastPalm ± 1,8; Kill volles Bild.
- **`displayLinkVelocity(palmVel)`.** Freeze füllt aus Palm.
- **`oneEuroLandmarkCutoff` 3,2.** **`cursorWarpFloor` 64.** **`fpsLatchChip`.** **`centerStageNeedsReassert`.** Close/Keep stetig.
- Tests + MARKETING_VERSION 1.5.67 (Build 87).

## In 1.5.66 wirklich im Code

1.5.65: Tracker-Ghost. Engine-Filter warf sie weg. lastPoolIDs = [] am Ghost. Sparse kopierte Tips. pinchCloseNeed immer 2.

- **`tickKeepsGhost`.** isGhost trotz Floor.
- **`ghostKeepsPool`.** lastPoolIDs am Ghost.
- **`sparseMergeKeeps`.** nur Wrist/MCP.
- **`pinchCloseNeed(dt)` 8 fps = 1.** **`jointGain`.** **`twoHandClutchGain` 0,4.**
- Tests + MARKETING_VERSION 1.5.66 (Build 86).

## In 1.5.65 wirklich im Code

1.5.64: Warp Smooth, lastTip, Engine-Latch. Observation unter Floor wischte lastHands. Warp 80 px klebte. Cubic overshootete.

- **`trackerEmptyKeepsGhost` / `emitEmpty`.** kept 0 → Ghost.
- **`fingerSparseKeepsPalm`.** Wrist-only / 2 MCP mergen.
- **`cursorWarpCap` 3× Median, Floor 48.**
- **`palmKalman` 8 fps.** **`centerStageOff`.**
- Tests + MARKETING_VERSION 1.5.65 (Build 85).

## In 1.5.64 wirklich im Code

1.5.63: Warp ohne Smooth-Write. DIP als Fake-Tip. Confidence-Floor → releasePointer.

- **`cursorWarpHoldsSmooth`.** Smooth + lastMapped freeze.
- **`fingerOcclusionTip` / `lastIndexTip` / `lastThumbTip`.**
- **`slotLatchEmptyKeepsPointer`.**
- Tests + MARKETING_VERSION 1.5.64 (Build 84).

## In 1.5.54 wirklich im Code

1.5.53: Freeze hielt Cursor, driveGrab klickte mit der anderen Hand. Faust der anderen Hand tat nichts. Bezel-Lücke = Union. Faust-Countdown bei Klappe unsichtbar.

- **`pointerStealBlocksActor`.** Pool leer / Freeze: kein driveGrab, kein Wisch.
- **`pointerStealHUD` + `stealChip`.** LOCK L/R.
- **`pointerStealRelock`.** Faust der anderen Hand legt Lock um.
- **`destClampScreen` nächster Screen.** Bezel nie nil.
- **fistArmChip während phaseBlocksArm.**
- Tests + MARKETING_VERSION 1.5.54 (Build 74).

## In 1.5.53 wirklich im Code


1.5.52: Lock-Hand weg → Pool alle → zweite Hand stiehlt. Relativ-Fill ohne destBounds = Union. Pinch-Open 2 Frames / 8 fps.

- **`pointerPool` leer** wenn Lock-Hand weg.
- **`pointerFreezesSteal`.** actorMapped hält cursorSmooth.
- **`destClampScreen`.** Relativ-Fill auf dem Laptop.
- **`pinchOpenNeed` 8 fps = 1.**
- Tests + MARKETING_VERSION 1.5.53 (Build 73).

## In 1.5.52 wirklich im Code

1.5.51: Klappe/Legacy/destClamp/Game-Exempt. Pinzette klebte zu (0,54∧0,62). Ghost hielt Dead-Man. Face-Count aus der Tasche. Display-Link Union-Snap. Relativ auf Union. Zweite Hand stahl Pointer. Dark-Pfad ohne pocketIdle. Unknown-Chirality stahl den Lock.

- **`pinchWantOpen` / `pinchOpenRatio`.** 0,58 nahe / 0,64 fern. PinchGate, nicht Hardcode.
- **`liveHandRefreshesDeadMan`.** Ghost hält lastHandSeen nicht.
- **`pocketIdle`.** Continuity ohne Innenraum 1,2 s → Idle. Auch `noteDarkFrame` (Tasche = Vision aus).
- **Dark-Pfad `cameraFallback`.** Continuity bleibt Continuity, auch ohne hellen Tick.
- **`faceCountFresh`.** Stale VNFace-Count = 0.
- **`displayTick` destClamp.** Fill bleibt auf der Map.
- **`relativeStepSpan`.** Gain vom Screen unter dem Cursor.
- **`pointerStaysSide` + `pointerPool`.** Unknown ist nicht die Lock-Seite. Fehlt die Seite: nur Slot-ID.
- **`focusStealLatches`.** AX-PID-Wechsel während Pinch = Latch.
- Edge/Brave/Discord/Notion Exempt.
- Tests + MARKETING_VERSION 1.5.52 (Build 72).

## In 1.5.51 wirklich im Code


1.5.50: Klappe blockte Scharf immer — Clamshell tot. Legacy-Map ohne screenID lud nicht. apply() klemmte an die Union. Safari-FS = GAME.

- **`lidBlocksArm`.** Built-in + Klappe tot. Continuity/USB + extra Screen = Clamshell, Scharf bleibt.
- **Legacy-Load.** Camera-Key nur bei dest-Overlap ≥ 80 %. Fremde Laptop-Map bleibt tot.
- **`destClamp`.** Homographie bleibt in destBounds.
- **`gameModeExempt`.** Browser/Keynote/Finder kein Pause. `game-lock.txt` schlägt Exempt.
- **`click-lock.txt`.** Bundle-IDs unter Application Support.
- **Skelett-Dash** je Finger, nicht nur Hue.
- Tests + MARKETING_VERSION 1.5.51 (Build 71).

## In 1.5.50 wirklich im Code


1.5.49 Tip-Z, Display-Link, KALIB HIER, Warmup. Game/Klappe setzten Idle, `handleArming` schaltete im selben Tick scharf. Load fiel auf die Laptop-Map. Display-Link-Cap fest 28 px.

- **`phaseBlocksArm`.** Klappe und Game: kein Faust-Scharf. `livePhase` kennt `lidClosed`.
- **`mapFitsScreen`.** Load ohne Legacy auf fremden Screen. `apply()` skippt fremde Homographie.
- **`displayLinkCap`.** Velocity: ruhig 12 px, Flick 28 px.
- Tests + MARKETING_VERSION 1.5.50 (Build 70).

## Nächste (offen)

- Frame-Pump mit Aegis, eine TCC. Gemeinsamer CVPixelBuffer, eine Kamera-Session.
- ~~Click-Lock-Liste in Prefs~~ — 1.5.51 `click-lock.txt`.
- ~~Preview-Skelett farbenblind~~ — 1.5.51 Dash je Finger.
- Zwei-Kamera-Fusion Continuity+Built-in: Built-in Tiefe, Continuity Weitwinkel.
- Haptik-Stärke nach App (Safari leicht, Finder fest, Spiel aus).
- Latency-HUD: Kamera-Tick → AX-move in ms. Über 40 ms → Gain halbieren.
- 6-Punkt-Kalib statt 4 Ecken (Mitte + Kanten) gegen Kissenverzerrung.
- Stage-Manager / Space-ID in SpaceMap-Key — Homographie je Space.
- Watch als Pinch-Confirm (zweite Haptik, kein Klick ohne Watch-Tap in Prefs).
- VoiceOver: Cursor-Ansage „Safari, Link, 40 %“.
- Continuity LiDAR-Tiefe (iPhone Pro) als Palm-Z statt nur Vision-3D.
- Menu-Bar Extra: letzte 8 Gesten, ein Tap = Undo.
- Per-Display Pointer-Acceleration (Laptop 1,0, 4K-Extern 1,4).
- ~~Keyboard-Focus-Steal~~ — 1.5.52 `focusStealLatches`.
- ~~Game-Mode Whitelist~~ — 1.5.51 Exempt + `game-lock.txt`.
- ~~Zwei-Hand-Dominanz-Lock~~ — 1.5.52 `pointerStaysSide` + `pointerPool`.
- AX `kAXFocusedUIElementChanged` statt Poll.
- Dwell-Klick Dock (Hover 0,45 s ohne Pinch).
- Wrist-Roll Scroll, Zwei-Hand-Rotate.
- Palm zur Kamera = Pause / Datenschutz (2D-Reach, macOS hat kein HandPose3D).
- Low-Power auf Akku: Vision 12 fps Cap.
- ~~Dead-Man vs Continuity~~ — 1.5.52 `pocketIdle` in Tick, Ghost und `noteDarkFrame`.
- Homographie-RMS live im Kalib-Wizard, Abbruch > 40 px.
- Click-Lock als Prefs-Text, nicht nur Hardcode — Steam/Games Default-Lock.
- ~~Pinch-Hysterese asymmetrisch verdrahten~~ — 1.5.52 `pinchWantOpen` 0,58/0,64.
- Pinch-Index = Klick, Pinch-Mittel = Rechtsklick (Finger statt Hold-Zeit).
- AX-Hit-Magnet 12 px: Cursor rastet auf Button, nicht daneben.
- Continuity-FPS im HUD-Chip (8 vs 24), Gain-Warnung über 40 ms.
- Offene Hand + Modifier vertikal = Scroll, nicht nur Wisch.
- Caps-Lock-LED als Scharf-Anzeige.
- iPhone Action Button über Continuity als Not-Aus.
- SpaceMap bilinear/Homographie-Blend nach RMS.
- HUD HOLD X/Y — welche Achse tot ist.
- destEdgeFloor Pref 0,25 / 0,35 / 0,50. 8 fps Cap 4 statt 8.
- palmStillHold Pref 0,15 / 0,22 / 0,35.
- warpCapHold Frames Pref 1 / 3 / 5.
- HUD `MAP≠STEAL` wenn stealScreen ≠ destBounds.
- Two-hand HOLD nur Pointer-Hand.
- palmUnstillAxis Pref 0,010 / 0,014 / 0,018.
- Coast-τ Override Auto / Laptop / 5K.

## In 1.5.49 wirklich im Code


1.5.48 Phase-Gatter, Homographie je Screen, Haptik. Tip-Z-Math unverdrahtet. Continuity 8 fps ohne Fill. Laptop-Map auf dem Externen still. Overlay nur Farbe. Eine Gain-Kurve. Erster Tick warpte relativ.

- **Vision Revision 2 + Tip-Z.** 3D-Request, Z aus 4×4 (`columns.3`), 3D nur bei 2D-Treffer. `pinchKeepsGrabTipZ`. 2D-Fallback.
- **Display-Link 24 Hz.** `displayTick` zwischen Continuity-Frames, Cap 28 px.
- **`KALIB HIER`.** Screen ohne eigene Map. Banner + Chip.
- **Homographie-Warmup.** Relativ-Warp nur mit Map auf dem neuen Screen.
- **Farbenblind Overlay-Dash.** MAGNET/BUTTON/WEG.
- **Per-App Gain + Dock-Lock.**
- Tests + MARKETING_VERSION 1.5.49 (Build 69).

## Nächste (offen)

- Frame-Pump mit Aegis, eine TCC. Gemeinsamer CVPixelBuffer, eine Kamera-Session.
- Click-Lock-Liste in Prefs (Bundle-IDs), nicht nur Dock/Control-Center.
- Preview-Skelett farbenblind (nicht nur HUD-Ring) — Fingerglieder als Strichmuster.
- Zwei-Kamera-Fusion Continuity+Built-in: Built-in Tiefe, Continuity Weitwinkel.
- Haptik-Stärke nach App (Safari leicht, Finder fest, Spiel aus).
- Display-Link Cap aus Palm-Velocity (ruhig 12 px, Flick 28 px).
- Latency-HUD: Kamera-Tick → AX-move in ms. Über 40 ms → Gain halbieren.
- 6-Punkt-Kalib statt 4 Ecken (Mitte + Kanten) gegen Kissenverzerrung.
- Stage-Manager / Space-ID in SpaceMap-Key — Homographie je Space.
- Watch als Pinch-Confirm (zweite Haptik, kein Klick ohne Watch-Tap in Prefs).
- VoiceOver: Cursor-Ansage „Safari, Link, 40 %“.
- Continuity LiDAR-Tiefe (iPhone Pro) als Palm-Z statt nur Vision-3D.
- Menu-Bar Extra: letzte 8 Gesten, ein Tap = Undo.
- Per-Display Pointer-Acceleration (Laptop 1,0, 4K-Extern 1,4).
- Keyboard-Focus-Steal: wenn AX-Fenster wechselt während Pinch, Latch wie Escape.
- Game-Mode Whitelist in Prefs, nicht nur 92 %-Vollbild.
- Zwei-Hand-Dominanz-Lock: zweite Hand nur Modifier, nie Pointer-Diebstahl.

## In 1.5.48 wirklich im Code

1.5.47 Phase-Chip, Screen-Blend, Game-Mode, Continuity-Reconnect. Phase war Ableitung — Idle/Kill klickten weiter. Eine Homographie für Laptop und Extern. Klick ohne Haptik wirkt tot.

- **`phaseBlocksClick`.** Idle und Kill klicken nicht. `livePhase()` vor Down und Release. HUD `KILL`.
- **SpaceMap je Display.** `spaceMapKey(camera, screen)`. Kalib speichert `screenID`. Monitorwechsel lädt die Map, schleppt destBounds nicht mit.
- **`tapHaptic`.** Generic bei Klick/Down/Up/Doppel, Alignment bei Rechtsklick. Trackpad klickt mit.
- Tests + MARKETING_VERSION 1.5.48 (Build 68).

## Nächste (offen, 1.5.47 — erledigt in 1.5.48)

Phase-Gatter, Homographie je Screen, Klick-Haptik sitzen in 1.5.48. Tip-Z-Draht, DisplayLink, Frame-Pump mit Aegis bleiben.

## In 1.5.47 wirklich im Code

1.5.46 Clamshell/Trackpad. Der Tick hatte weiter vier Uhren und keine Phase. Monitorwechsel snapte. Continuity-Lock warf den Zeiger. Vollbild-Spiel klickte mit.

- **`EnginePhase`.** idle / armed / pinch / drag / scale. HUD-Chip. `tick` setzt `phase` im `defer`.
- **`screenBlend` 120 ms** Smoothstep. Screen-Key = `CGDirectDisplayID`, nicht Array-Index.
- **`gameModeFullscreen` 92 %.** Vollbild → Idle, Chip `GAME`.
- **`continuityReconnectPalm`.** `rawFrameDt > 0,40` hält letzte Palm, Cubic kein Sprung.
- **`pinchTipZClosed` / `pinchUsesTipZ`.** Math; Revision-2-Draht nächste.
- Tests + MARKETING_VERSION 1.5.47 (Build 67).

## Nächste (offen, 1.5.46 — erledigt in 1.5.47)

Phase-Chip, Screen-Blend, Game-Mode, Continuity-Reconnect, Tip-Z-Math sitzen in 1.5.47. Phase treibt die Gatter noch nicht. SpaceMap bleibt eine Homographie.

## In 1.5.46 wirklich im Code

1.5.45 `lidClosed` nie gesetzt — Math ohne IOKit. Trackpad 6 px stahl den Zeiger während Palm-Gain.

- **`Permissions.clamshellClosed`.** IOPMrootDomain `AppleClamshellState`. Tick → `lidClosed`. HUD „Klappe zu“.
- **`trackpadClutch(mouseDelta:palmSpeed:)`.** Ruhig 8 px, bewegt 28 px. Drag 4/16. `system.palmSpeed`.
- Tests + MARKETING_VERSION 1.5.46 (Build 66).

## Nächste (offen, 1.5.45 — erledigt in 1.5.46)

Clamshell-IOKit und Trackpad-Diebstahl sitzen in 1.5.46.

## In 1.5.45 wirklich im Code

1.5.44 VNFace / Continuity-Interp — Knie am Rand warf Scharf trotz Gesicht. Flick und Zielen hatten dieselbe Klick-Need. Kalib „fertig“ bei 70 px × 4 Ecken. Zweite Hand ohne ⌘⌥⇧. 8 fps smoothstep overshoot.

- **`armedIdle`.** Gesicht da → Gaze-Idle tot. Klappe (`lidClosed`) immer Idle. HUD „Kein Gesicht“ / „Klappe zu“.
- **`pinchClickNeed(dt:speed:)`.** Flick ≥ 0,20 streckt Need +120 ms. Zielen bleibt 90/180.
- **`mapRMS` / `mapRMSReady` 40 px.** Kalib bricht die letzte Ecke ab. HUD `RMS n`.
- **`continuityPalmCubic`.** Catmull-Rom 8 fps, 24 fps roh. `lastPalm2`.
- **`modifierKind`.** Peace = ⌘, Point = ⌥, Faust = ⇧. `click`/`pressMouse` Flags. HUD-Chip.
- **`axProbeTimesOut` 8 ms.** Math; Probe-Budget sichtbar.
- **`flingUndo` 0,40 s** Peace+Pinch nach Wurf.
- Tests + MARKETING_VERSION 1.5.45 (Build 65).

## Nächste (offen, 1.5.44 — erledigt in 1.5.45)

Edge-Idle vs Face-Idle, Pinch-Need aus Palm-Speed, Kalib-RMS 40 px, Cubic-Interp, zweite-Hand-Modifier sitzen in 1.5.45.

## In 1.5.44 wirklich im Code

1.5.43 Doppel nach Flick. AX-Toolbar 1 Frame. Continuity-Warp. Kein VNFace.

- **`doublePinchBlocksTravel` 45 %.** Letzter und aktueller Travel.
- **`clickLockMissFrames` 2.**
- **`continuityPalm`** 8 fps interp 0,62 vor Predict.
- **VNFace alle 4 Frames** + `faceCountIdle`. HUD „Kein Gesicht“.
- Tests + MARKETING_VERSION 1.5.44 (Build 64).

## Nächste (offen, 1.5.43 — erledigt in 1.5.44)

Doppel-Totzone, Click-Lock 2 Frames, Continuity-Interp, VNFace sitzen in 1.5.44.

## In 1.5.43 wirklich im Code

1.5.42 Clamp 0,4 über 24-fps-Lead. Extra-Hold stilles Abbrechen. Kein Doppel.

- **`predictLeadDt`** 0,7 / 0,35. Floor 0,3.
- **`rightClickHold` 0,55 s** + `SystemControl.rightClick`. HUD `RECHTS`.
- **`doublePinchWindow` 0,32 s** + `doubleClick` clickState 2.
- Tests + MARKETING_VERSION 1.5.43 (Build 63).

## Nächste (offen, 1.5.42 — erledigt in 1.5.43)

Lead nach dt, Rechtsklick Extra-Hold, Doppel-Pinch sitzen in 1.5.43.

## In 1.5.42 wirklich im Code

1.5.41 Relativ-Predict — `predictPalm` versehentlich gelöscht, App kompiliert nicht. Traffic-Walk jeden Tick. Fling nur Palm-Norm. Escape/Dead-Man/Faust-Scharf ohne HUD. Overlay nach Dunkel warp.

- **`predictPalm` restauriert** + `predictLead` 0,4–1,0.
- **`hoverRingKind` / Label** MAGNET vor BUTTON vor WEG.
- **`escapeLatchHUD` LATCH.**
- **`visionMsSpark`** visMs neben fps.
- **`trafficCacheFresh` 400 ms.**
- **`axProbeCoalesced`.**
- **`fling(speedPx:minPx:)`** Dual-Monitor.
- **`darkRingHolds` 2 Frames.**
- **`deadManProgress` / `fistArmLabel`.**
- **`palmInterp` / `faceCountIdle`** (Math; VNFace-Zählung nächste).
- Tests + MARKETING_VERSION 1.5.42 (Build 62).

## Nächste (offen, 1.5.41 — erledigt in 1.5.42)

predictPalm-Restore, MAGNET/BUTTON/WEG, LATCH-HUD, visMs-Spark, Traffic-Cache 400 ms, Fling-px, Dark-Ring, Dead-Man-Ring, Faust-Scharf-Countdown sitzen in 1.5.42.

## In 1.5.41 wirklich im Code

1.5.40 Continuity-Klick — Desk-View gespiegelt, Relativzeiger 1 Frame tot, ferne Close-Vel, Lock vor Hover, Rand-Knie Scharf, Escape sofort Klick, AX jeder Spike, Panic 0,55 s.

- **`mirrorAsFront`.** Desk-View nie. Built-in unspecified Front.
- **`relativePredicts` / `predictPalm`** auf dem Relativpfad.
- **`pinchCloseVel(dt:palmScale:)`.**
- **`clickLockNeedsHover` 0,70.**
- **`panicKill` openScore 4.**
- **`armOpenCounts` + `gazeIdle` 1,2 s.**
- **`escapeLatch` 200 ms.**
- **`skipAXLatch`.** 1 teuer, 2 billig.
- **`travelHUD` WEG n%.**
- Tests + MARKETING_VERSION 1.5.41 (Build 61).

## Nächste (offen, 1.5.40 — erledigt in 1.5.41)

Desk-View-Spiegel, Relativ-Predict, Close-Vel×Scale, Hover-Lock, Panic, Gaze-Idle, Escape-Latch, Skip-AX-Latch, Travel-HUD sitzen in 1.5.41.

## In 1.5.40 wirklich im Code

1.5.39 RotationCoordinator — Klick tot bei Continuity: 12 px Travel, AX nach 20 ms Vision, ferne Pinch-Ratio, Homographie ein Frame hinterher. Lock während Vision.perform.

- **`pinchClickTravelPx`.** dt / Map / palmScale. 12 / 20 / 28 / 34, Cap 36.
- **`axBudgetSkip` 18 ms.** visMs, nicht End-to-End. 8 fps nie skip (MAGNET).
- **`predictPalm` 0,7.** Continuity-Lag auf der Map.
- **`pinchCloseRatio` / Keep** ferne Hand.
- **meanConfidence** smoothed. Vision-Lock nur um Slots.
- Tests + MARKETING_VERSION 1.5.40 (Build 60).

## Nächste (offen, 1.5.39 — erledigt in 1.5.40)

Klick-Travel, AX-Budget, Palm-Predictor, Pinch aus palmScale sitzen in 1.5.40.

## In 1.5.39 wirklich im Code

Mac-FaceTime lag auf der Seite: `videoOrientation = landscapeRight` rotiert VideoDataOutput physisch (iOS-Mapping 180°/90°). Preview und Vision sahen den gedrehten Puffer.

- **`AVCaptureDevice.RotationCoordinator`.** `videoRotationAngleForHorizonLevelCapture`, nicht landscapeRight.
- **`visionOrientationRaw`.** Physische Rotation → Vision `.up`.
- **`captureForcesLandscapeRight` = false.** Fallback-Winkel 0°.
- MARKETING_VERSION 1.5.39 (Build 59).

## In 1.5.38 wirklich im Code

Zweiter vollständiger Bugfix-Pass nach 1.5.37. Kamera-Restart tot (reset vor cancel). Window-List-Cast. Overlay Y. Tick vs Pointer-Uhr. Skip-AX Release. AX hinter Helios.

- **FramePump.reset** auf `cameraQueue` in `configureAndRun`. Stop löscht `uniqueID` nicht. `isRunning` nur nach Start-OK. Input/Output `canAdd` bricht ab. `HeliosCatch` um `beginConfiguration`.
- **`windowListRect`.** NSNumber-Bounds. FocusTracker frontmost/windowAt.
- **`quartzTopLeft`.** `localRect` minY. HUD-Umriss und Beam sitzen auf dem Titelbalken.
- **`lastTickT`.** Need/TTL/Continuity-Lock. `recenterPointer` leert Median-dts (24→8 fps).
- **forceIdle / empty / ghost** nil `peaceSince`/`thumbsSince`/`fistSince`.
- **`skipProbeStoresEmpty`.** Leere Probe nicht cachen. **`releaseBlockedBySkipAX`** vor `releaseMouse`/`click`.
- **beginWindowDrag** `TargetProbe` self zuerst. AX-Write Read-back 12 px. resize OR wie Snap. `dragGen`. `.privateState`. Dump-Up `clamp: false`.
- **`SpaceMap.destBounds`.** Residual gegen Kalib-Rect. Kalib-HUD `linear(in: visQuartz)`.
- Dunkel: `visionInbox.reset()` vor `noteDarkFrame`. Filmstrip `self.preview`. `stopCamera` → `engine.reset()`. Footer Linke/Rechte. Relaunch nur bei Open-OK.
- Tests: windowListRect, quartzTopLeft, axWriteTook, skipProbeStoresEmpty, releaseBlocked, destBounds, Tick vs Pointer.
- MARKETING_VERSION 1.5.38 (Build 58).

## In 1.5.37 wirklich im Code

Vollständiger bugfix-Pass. Helios-Fenster: AXPosition/AXSize tot → Drag/Snap/Mini über NSWindow. Kalib 1.5.35: `cursorGap` aus Hardware-Maus, jeder Sample > 80 px tot. Snap loggte OK ohne Write. Down blieb nach leerer Vision. Skip-AX ließ Need weiterlaufen — Down nach Dunkel. Homographie-Ziel immer Primary. Probe-Cache nach Monitor-Wechsel. Kamera ohne Frames: kein Format-Retry.

- **`dragOwnWindow` / `beginOwnWindowDrag`.**
- **Kalib mapped Palm**, nicht Maus. **`SpaceMap.dest`** speichert die Quartz-Ecken.
- **snapFocused** Fail wenn beide AX-Writes tot.
- cancelPress leer / DMG / Idle. forceIdle über abortGrab.
- **`pinchClockAdvance`.** Skip-AX schiebt `pinchBeganAt` um dt. **`pressBlockedBySkipAX`:** Skip plus erster frischer Tick kein Down. Probe wird geleert.
- **`invalidateProbe`** bei Monitor-Wechsel.
- **`frameSilenceRetry`.** permTimer, 2 s ohne onFrame → reselectFormat.
- Beam **`beamAim`** Titelbalken. Test-HUD **GREIFT · KEINE AKTION**. Greifen-Log `r.detail` (Helios).
- Tests: Clock, Skip-Latch, Silence, Beam, dest-Homographie, linear-in-rect.
- MARKETING_VERSION 1.5.37 (Build 57).

## In 1.5.36 wirklich im Code

1.5.35 Continuity-Lock — Zoom tot: erste Pinzette setzte Grab, zweite Gate zählte nicht. Cooldown fraß den Span. AXSize an der SwiftUI-Konsole oft `.cannotSetValue`.

- **`scaleBlocksGrab`.** `closedCount >= 2` unabhängig von pinchHeld. Engine bricht Grab ab.
- **`scaleKeepsSpan`.** Gated → alter Span.
- **`resizeOwnWindow`.** `NSWindow.setFrame` für Helios.
- HUD „Skalieren …“ im Settle.
- Tests: zwei Gates vs Grab, Span.
- MARKETING_VERSION 1.5.36 (Build 56).

## Nächste (offen)

- **SpaceMap pro Monitor** mit 4 Ecken je Screen + RMS unter 40 px vor „fertig“. Dest sitzt in 1.5.37, Blend beim Screen-Wechsel fehlt.
- **Rechtsklick Ringfinger-Pinzette** (Extra-Hold 0,55 s sitzt in 1.5.43). Index vs Ring aus Vision 21 Joints.
- **Cmd/Opt/Shift über zweite Hand:** Peace = Cmd, Point = Opt, Faust = Shift. Overlay-Chips.
- **Gemeinsame Kamera-Session mit Aegis.** Eine TCC, ein Frame-Pump.
- **Dwell-Klick** 0,70 s Hover ohne Pinch, Prefs aus. Nur Dock.
- **Mission Control:** drei offene Finger nach oben, Totzone gegen Wisch.
- **Window-Snap Ghost-Rechteck** (Magnet ist 1.5.29, Vorschau fehlt).
- **Double-Pinch Totzone gegen Drag.** **→ 1.5.44 doublePinchBlocksTravel**
- **Haptik** CoreHaptics bei Klick-Down und Fling-Lock.
- **Wrist-Roll Scroll:** Pitch der Palm-Normalen, Totzone gegen Cursor-Gain.
- **Blick weg / kein Gesicht → Auto-Idle.** **→ 1.5.44 VNFace + faceCountIdle.** Clamshell / Lid-closed fehlt.
- **Pinch-Need aus Palm-Speed-History**, nicht nur Median-dt — Flick vs Zielen in denselben 180 ms.
- **SpaceMap 1-Euro → Kalman** bei 8 fps.
- **Click-Lock Hysterese 2 Frames.** **→ 1.5.44 clickLockMissFrames = 2**
- **Zwei-Hand-Rotate** Yaw zwischen Palmen, Totzone gegen Scale.
- **Fling in Stage Manager.** Prefs.
- **HUD compact** 13"-Laptop: Cheat-Sheet weg, nur Chips.
- **Overlay farbenblind:** MAGNET nicht Orange-auf-Amber, Muster statt Hue.
- **Per-App Click-Lock-Liste** (Safari Toolbar vs Content).
- **Drag-Preview-Ghost** des Fensters bei 40 % Opacity während AX-Lag.
- **Kalib-RMS live** über alle 4 Ecken, Abbruch wenn RMS > 40 px vor „fertig“. 80-px-Ecke sitzt in 1.5.35.
- **Accel-Slider** 0 = linear, 1 = Trackpad.
- **Palm-Jitter-Meter** im Testmodus (px/s).
- **Linkshänder-Wisch** invertieren, Prefs.
- **Force-Click:** drei Finger Pinch = Rechtsklick analog Trackpad.
- **Volume:** Abstand zweier offener Palmen, Totzone gegen Scale.
- **Spotlight:** Faust dann Point, Cooldown gegen Scharf.
- **VoiceOver MAGNET/BUTTON** sobald Lock sitzt.
- **HUD-Scale nach Display-PPI** (1080p-TV vs Retina).
- **Gesture-Macro:** Peace dann Pinch = Screenshot in die Zwischenablage.
- **Safari-Tab Close** nur MAGNET auf AXTabButton, nie Fenster-Close.
- **Menüleisten-Extra** Helios nur als Status-Item, Panel optional.
- **Per-Display-Homographie-Blend** wenn der Cursor den Screen wechselt. **→ 1.5.47 screenBlend 120 ms**
- **Faust-Scharf Countdown-Ring** analog KLICK n %. **→ 1.5.42 fistArmLabel**
- **Trackpad-Clutch** Hardware-Maus > 8 px/Tick stiehlt nicht bei ruhiger Hand.
- **Palm-Z aus Vision** als Press-Force (leichter Pinch = Klick, tief = Drag).
- **AX Traffic-Light Cache 400 ms** am ancestorWindow, nicht jeden Tick Walk. **→ 1.5.42 trafficCacheFresh**
- **AX `kAXFocusedUIElementChanged`** statt Poll — App-Wechsel invalidiert Probe sofort.
- **Palm zur Kamera = Pause.** Datenschutz, Overlay „PAUSE“, Gesten tot, Cursor frei.
- **Per-App Gain-Profil.** Xcode 0,8 / Safari 1,2, Prefs.
- **Drei-Finger-Spread = Desktop zeigen.** Totzone gegen Scale.
- **Klick-Klick optional** NSSound, sonst wirkt tot ohne Haptik.
- **AX-Role Allowlist-Datei** `~/Library/Application Support/Helios/click-lock.txt`.
- **Zwei-Hand-Scroll:** eine Faust + eine offen, Palm-Y.
- **Pinch auf Helios-Toggle = Klick, Rest der Konsole = Fenster-Drag** (Click-Lock sitzt, Titelzeile/Preview ziehen).
- **Beam-Länge klemmen** wenn Ziel hinter HUD-Mitte liegt — keine Linie quer durch die Sidebar. Titelbalken-Ziel sitzt in 1.5.37.
- **HUD Format min–max fps** (24–30 vs 1–30) neben S1, nicht nur Ist-Takt.
- **Overlay-Ring nach Dunkel 2 Frames nicht rebase-warpen.** **→ 1.5.42 darkRingHolds**
- **Built-in nach Continuity-Disconnect:** Map laden ohne Drift-Banner wenn RMS < 40.
- **Dead-Man HUD-Ring** die letzten 3 s, bevor Idle. **→ 1.5.42 deadManProgress**
- **Continuity-Interpolator.** **→ 1.5.44 continuityPalm im Tick.** Display-Link 24 Hz zwischen Frames fehlt.
- **Radial-Picker.** Faust+Point = Fensterliste, Pinch wählt.
- **Gaze-Idle von Aegis.** **→ 1.5.44 VNFace.** Innenraum-Proxy 1.5.41 bleibt parallel.
- **Middle-Click.** Daumen+Mittelfinger, Totzone gegen Pinch.
- **Kalib-Wizard 4 Ecken mit Live-RMS und Abbruch > 40 px.** 80-px sitzt, Wizard-UI fehlt.
- **Pinch-Gate aus 3D-Handpose** (VNDetectHumanHandPoseRevision2) statt 2D-Spitzen, Continuity-Jitter runter.
- **Click-Lock nur wenn hoverProgress ≥ 0,7.** **→ 1.5.41 clickLockNeedsHover**
- **Fling-Speed in Quartz-px/s**, nicht nur Palm-Norm — Dual-Monitor 5k vs Laptop. **→ 1.5.42 fling(speedPx:)**
- **AX-Probe coalesced 1 / Tick unabhängig vom Budget** — Hit-Rolle vom letzten guten Probe, Traffic-Lights 400 ms. **→ 1.5.42 axProbeCoalesced + trafficCache**
- **Idle-Scharf nur nach offener Hand in der Bildmitte**, Rand-Knie kein Faust-Scharf. **→ 1.5.41 armOpenCounts**
- **Kamera-Watchdog: Format-Score live im HUD** min–max fps, Tie-Break sichtbar.
- **Escape-Latch 200 ms** nach Hardware-⌘. — nächster Pinch nicht sofort Klick. **→ 1.5.41 escapeLatch** · HUD **→ 1.5.42 escapeLatchHUD**
- **Two-hand Kill ohne Hold** wenn beide Palmen openScore 4 — 0,55 s war zu lang für Panic. **→ 1.5.41 panicKill**
- **Travel-HUD** analog Settle: Overlay `WEG n%`. **→ 1.5.41 travelHUD** · Ring-Farbe **→ 1.5.42 hoverRingKind**
- **PredictPalm lead Prefs** 0,4–1,0 neben Zeiger-Empfindlichkeit. Clamp sitzt 1.5.42, Slider fehlt.
- **PinchGate Close-Vel × palmScale.** **→ 1.5.41 pinchCloseVel(dt:palmScale:)**
- **Relativzeiger-Predict** wenn mapped=false und dt ≥ 0,08. **→ 1.5.41 relativePredicts**
- **Vision-ms Spark** im HUD neben fps, damit AX-Budget sichtbar ist. **→ 1.5.42 visionMsSpark**
- **Skip-AX Latch** analog lumaSkipHold. **→ 1.5.41 skipAXLatch**
- **Desk-View nicht spiegeln.** **→ 1.5.41 mirrorAsFront**
- **Echter VNDetectFaceRectangles-Count** alle 4 Frames. **→ 1.5.44**
- **Kalib 4-Ecken RMS-Wizard UI** mit Abbruch-Button.
- **Pinch-Right-Click HUD „RECHTS“** 0,55 s Extra-Hold ohne Bewegung. **→ 1.5.43**
- **Kalib-Hotkey ⌘K** startet 4-Ecken ohne ControlPanel.
- **Fling-Undo** Pinch+Peace 0,4 s nach Wurf = letztes Fenster zurück.
- **Low-Power auf Akku:** Vision 12 fps Cap, Gain bleibt.
- **SpaceMap JSON Export** zum Teilen der Kalib zwischen Macs.
- **Zweite Hand = Scroll** statt Scale wenn nur eine Pinzette.
- **Cursor-Warp-Log** im Testmodus: Map vs Relativ px-Fehler.
- **AX-Timeout 8 ms** hart auf loadProbe — sonst hängt der Zeiger hinter Safari.
- **Display-Link 24 Hz Interpolator** nutzt `palmInterp` zwischen Continuity-Frames. In-Tick 1.5.44.
- **Continuity 8→24 Hz Palm-Interpolator** (cubic), Need bleibt 180 ms. smoothstep 1.5.44.
- **Clamshell / Lid-closed → Idle** IOKit, unabhängig von Gaze.
- **AX hit-test coalesced** 1 Probe/Tick + Traffic-Cache 400 ms.
- **Fling px/s über Screen-PPI** statt Palm-Norm.
- **Hover-Ring Farbe** MAGNET vs BUTTON vs WEG, sonst drei Overlays unleserlich. **→ 1.5.42**
- **Escape-Latch Overlay** Chip 200 ms, sonst wirkt Pinch tot. **→ 1.5.42**
- **Edge-Idle vs Face-Idle trennen.** Knie am Rand darf Scharf halten wenn VNFace sitzt.
- **Pinch-Release-Sound** 8 ms Click, sonst wirkt tot ohne Haptik.
- **Hover-Dwell Dock only** 0,70 s, Prefs aus.
- **Zwei-Monitor Homographie-Blend** 120 ms Crossfade, nicht Snap. **→ 1.5.47 screenBlend**
- **Vision Revision 2** Handpose 3D, Pinch aus Tip-Z statt 2D-Ratio. Math **→ 1.5.47 pinchTipZClosed**. Draht fehlt.
- **Testmodus Gesture-Film** letzten 8 s als PNG-Streifen exportieren (SessionExport sitzt).
- **Panic-Hold Overlay** beide Palmen sofort, Chip KILL 140 ms.
- **Game-Mode Pause.** Vollbild-Spiel → Helios Idle, Cursor frei, nach Mission Control wieder scharf. **→ 1.5.47 gameModePause**
- **Palm-ROI Vision.** Continuity 8 fps nur Crop um letzte Palm, Full-Frame alle 4 Ticks.
- **Click-Lock lernend.** Letzte 50 AX-Subroles mit erfolgreichem Klick → Allowlist, Safari-Toolbar vs Content ohne Prefs-Datei.
- **Trackpad-Diebstahl.** Hardware-Maus > 8 px/Tick und ruhige Palm → Clutch, nicht Warp.
- **Menüleisten-Extra compact.** Nur Chips, Cheat-Sheet weg auf 13".
- **Session-Film 8 s PNG** aus SessionExport, Bug-Report ohne Screen-Capture-TCC.
- **Per-App Gain.** Xcode 0,8 / Safari 1,2, JSON in Application Support.
- **Stage-Manager Fling.** Prefs: Wurf nach außen = Set statt Dock.
- **Handpose Revision 2** Pinch aus Tip-Z, Continuity-Jitter runter.
- **Haptik** CoreHaptics Tick bei Down und Fling-Lock — ohne Sound-Prefs.
- **Siri/Shortcut „Helios scharf“** ohne Faust, Dead-Man bleibt.
- **Clamshell IOKit.** **→ 1.5.46 Permissions.clamshellClosed**
- **Trackpad-Diebstahl Palm-Still.** **→ 1.5.46 trackpadClutch**
- **Continuity Crop-ROI** um letzte Palm, Full-Frame alle 4 Ticks — 8 fps Vision-Budget runter.
- **AX `kAXFocusedUIElementChanged` Observer** statt Poll: App-Wechsel invalidiert Probe sofort.
- **SpaceMap-Blend 120 ms** beim Screen-Wechsel, nicht Snap. **→ 1.5.47 screenBlend + displayID**
- **Per-Ecke Kalib-Undo** ⌘Z, nicht ganze Session.
- **Continuity-Reconnect** hält cubic History, erster Frame nach Lock kein Sprung. **→ 1.5.47 continuityReconnectPalm**
- **Pointer-Kurve aus Systemeinstellungen** statt eigener Accel-Slider.
- **Hover-Intent Prior** letzte 50 AX-Subroles mit erfolgreichem Klick.
- **Zwei-Hand-Chord Overlay** wenn zweite Hand Continuity-off-frame.
- **Watch-IMU optional** Wrist-Roll als Scroll, Totzone gegen Gain.
- **Mission-Control drei Finger** mit Hysterese gegen App-Wisch.
- **Klick-Klick NSSound** 8 ms, Prefs aus, sonst tot ohne Haptik.
- **Game-Mode** NSWorkspace fullscreen → Idle, nach Mission Control wieder scharf. **→ 1.5.47 GAME-Chip**
- **Phase treibt Gatter.** HUD-Chip sitzt, Tick liest noch Bools — `enginePhase` als einziger Eingang. **→ 1.5.48 phaseBlocksClick + KILL**
- **SpaceMap Dictionary** `[CGDirectDisplayID: SpaceMap]`, Kalib 4 Ecken je Screen. **→ 1.5.48 spaceMapKey(camera, screen)**
- **DisplayLink 24 Hz** zwischen Continuity-Frames, `palmInterp` schon da.
- **VNHumanHandPose3DObservation** Pinch aus Tip-Z, Math sitzt.
- **Shared AVCapture** mit Aegis, eine TCC, ein RotationCoordinator.
- **CoreHaptics** Down + Fling-Lock, 8 ms NSSound optional. **→ 1.5.48 tapHaptic generic/alignment**
- **Farbenblind MAGNET** Muster statt Hue, VoiceOver Rolle.
- **Per-App Gain JSON** in Application Support, Xcode 0,8 / Safari 1,2.
- **kAXFocusedUIElementChanged** statt Probe-Poll.
- **Palm-zur-Kamera Pause.** Overlay PAUSE, Gesten tot, Cursor frei.
- **Low-Power 12 fps** auf Akku, Gain bleibt.
- **Kalib-Wizard UI** Live-RMS, Abbruch > 40 px, Undo je Ecke.
- **AX-Role Allowlist lernend** letzte 50 erfolgreichen Klicks.
- **Stage-Manager Fling** Prefs: Wurf nach außen = Set.
- **Siri/Shortcut „Helios scharf“** ohne Faust, Dead-Man bleibt.
- **HUD `KALIB HIER`** wenn dieser Screen keine Map hat — Relativzeiger ehrlich, nicht destBounds vom Laptop.
- **Haptic-Muster.** generic Klick, alignment Fling-Lock, error Kill. 1.5.48 hat generic/alignment.
- **Continuity LiDAR-Tiefe** als Pinch-Z (iPhone 12+), Fallback 2D-Ratio.
- **Warp-Audit.** clutch / gamePaused / kill nie `warpCursor`.
- **Palm-Still 400 ms** nach Game-Mode-Exit bevor der erste Klick zählt.
- **System-Pointer-Kurve** aus den Systemeinstellungen statt eigenem Accel-Slider (doppelt in 1.5.40-Ideen).
- **Zwei-Hand-Chord Overlay** wenn zweite Hand Continuity-off-frame.
- **Watch-IMU** Wrist-Roll als Scroll, Totzone gegen Gain.

## In 1.5.35 wirklich im Code

1.5.34 Luma-Hold / Format-Tie — Continuity-Lock hing 4 s + 8 s am 0,5 s-fps-Fenster. sampleDtCap 200 ms hätte Lock-Retry tot gemacht. Ein dunkler Frame skippte Vision. Kalib auf Cocoa-Union, Drift 80 px gespeichert.

- **`rawFrameDt` / `continuityLockRetry`.** Ungedeckelt, jeden Tick. dt > 400 ms für 2 s.
- **`lumaSkipEnter`.** 2 dunkle Frames bevor Vision tot.
- **`screenAwareCorners`.** visibleFrame, nicht Union.
- **`calibAborts`.** > 80 px neben der Ecke — Sample weg.
- Tests: Enter, Roh vs Cap, Lock, Ecken, Drift.
- MARKETING_VERSION 1.5.35 (Build 55).

## In 1.5.34 wirklich im Code

1.5.33 ControlPanel — Continuity blieb zäh: Format 720p@1–30 gleichauf mit 720p@24–30, Watchdog aus dem letzten 0,5 s-Fenster, ein heller Blitz nach Dunkel spammte AX (`apply` überschrieb `lumaLow` nach 90 ms), Dark-Frame ließ `actorRebindUntil` fallen, HUD blieb voll nach Idle.

- **`formatPrefers`.** Gleicher Score → höheres minFrameRate (24–30 vor 1–30).
- **`lumaSkipHold`.** Dunkel sofort Skip. Zwei helle Frames, dann AX. `tick(skipAX:)`. `apply` schreibt lumaLow nicht mehr nach dem Hold zurück.
- **`skipProbe` Cache.** Leere Probe wird gecacht, Flag bleibt bis Tick-Ende — nicht nur der erste `loadProbe`.
- **`medianFps` / `cameraSlowNow`.** Watchdog aus Median der 8 Fenster, nicht letztes 0,5 s.
- **`darkHoldsRebind`.** `noteDarkFrame` hält `actorRebindUntil` (Grab-Abort).
- **`hudDims`.** 8 s Idle, nicht scharf, 40 % Opacity, Chip DIM. Kill-Flash bleibt voll.
- Tests: Tie-Break, Luma-Hold, Median, Slow, Dim, Rebind.
- MARKETING_VERSION 1.5.34 (Build 54).

## In 1.5.33 wirklich im Code

1.5.32 Median-Need — Pinzette über der Konsole griff das Fenster *dahinter*. `skipSelf` warf die eigene PID weg. Overlay lag in AX `CopyElementAtPosition`.

- **`cgWindowIsGrabTarget`.** Layer 0 + skipSelf. Overlay nie.
- **`targetWindow`.** Self-AX → CGWindowList `skipSelf: false`.
- **`pollFocus`.** `windowAt(..., skipSelf: false)`.
- **HUD `accessibilityHidden`.** Marker kein AX-Element.
- Tests: fremde App, skipSelf, ControlPanel, HUD-Layer, pid 0.
- MARKETING_VERSION 1.5.33 (Build 53).

## Nächste (offen, 1.5.33 — erledigt in 1.5.34)

Die Punkte Luma-Hysterese, Format-Tie-Break, Median-Watchdog, Dark-Rebind, HUD-Dim sitzen in 1.5.34.

## In 1.5.32 wirklich im Code

1.5.31 Need aus Roh-dt — ein Dropout-Spike 200 ms kippte 24-fps-Need auf 180 ms (Hover klebt). Drag-HUD nur „Ziehen“, Wurf unsichtbar bis Loslassen. Scale hart 350 ms. Gate nahm Joint-Mittel statt Spitzen.

- **`medianSampleDt`.** 8 Samples. Spike 200 ms lässt Need bei 90 ms. Engine `clickNeedDt`.
- **FLING-Ghost.** `flingGhost` / `flingGhostLabel` während Drag. Overlay Dash + HUD-Pfeil.
- **`scaleSettleNeed`.** 8 fps 350 / 24 fps 180.
- **`pinchTipConfidenceOk`.** Thumb+Index ≥ 0,18.
- Tests: Median, Ghost, Scale, Spitzen.
- MARKETING_VERSION 1.5.32 (Build 52).

## Nächste (offen, 1.5.32 — erledigt in 1.5.33)

Helios-eigenes Fenster greifen sitzt in 1.5.33. Die übrigen Punkte stehen oben.

## In 1.5.31 wirklich im Code

1.5.30 MAGNET/AX-TTL — Continuity-Klick blieb tot: `pinchClickMin` 120 ms, Frame 125 ms, Down im ersten Tick, Zielen unmöglich. Built-in-Homographie auf Continuity = Zeiger im Void. `noteDarkFrame` ließ `loadProbe` auf dem letzten Cursor. fps-Watchdog halbierte Gain, Format blieb 4 fps. `frameDt` war deklariert, nie aus `sampleDt` geschrieben — Need blieb 90 ms. `skipProbe` blieb nach einem Dunkel-Frame für immer true. Down/Release nutzten weiter `pinchClickMin` 120 ms, Need nur den „zu kurz“-Zweig. Doppeltes `pinchClickMin` (TimeInterval + Kommentar-Stelle) hätte nicht kompiliert. AX-Flicker droppte BUTTON in einem Tick.

- **`pinchClickNeed(dt)`.** 8 fps 180 ms (zwei Frames), 24 fps 90 ms. `frameDt = sampleDt` vor placeCursor. Settle, HUD, Down, Release, zu-kurz folgen Need — nicht `pinchClickMin`.
- **`spaceMapKey` / `load(cameraID:)`.** Continuity und Built-in getrennte Homographien. Legacy-Key nur ohne ID.
- **`skipProbe`.** Luma-Skip: Cache oder leere Probe. `tick` setzt false, `loadProbe` verbraucht das Flag.
- **`continuityStuck`.** dt > 200 ms für 4 s, Cooldown 8 s → `reselectFormat`.
- **Kalib-dt** `sampleDtCap` 200 ms statt hart 80 — Continuity-Hold zählt voll.
- **`clickLockMissHold`.** 1 AX-Miss hält BUTTON, zweiter droppt.
- Tests: Need 90/180, Settle 120≠180, Skip, Stuck, Keys, Miss-Hold.
- MARKETING_VERSION 1.5.31 (Build 51).

## Nächste (offen, 1.5.31 — erledigt in 1.5.32)

Die Punkte Median-dt Need, Fling-Ghost, Scale-Settle, Pinch-Spitzen sitzen in 1.5.32.

## In 1.5.30 wirklich im Code

1.5.29 hat pressDuringHold und MAGNET-Text — Continuity blieb tot: AX-Cache 90 ms, Frame 125 ms, also jeder Tick ein Roundtrip. MAGNET nur Label, Lights unsichtbar. `hitLocksClick` hart palmScale 0,12 während `trafficMagnet` die echte Hand nutzte. Escape brach Pinch, zweite Faust und ⌘. nicht. Down auf Close, Up auf Mini = Klick. Click-Lock nach Gate starr auf dem Start-Control.

- **`axProbeTTL`.** 8 fps 180 ms, 24 fps 90 ms. Engine setzt `system.probeTTL` aus `sampleDt`.
- **MAGNET-Ringe.** `trafficLightRings` r=11, Overlay `lightsHost` um Close/Mini/Zoom.
- **palmScale durch `hitLocksClick`.** Magnet-Distanz folgt der Palme, kleine Hand 36 px.
- **Zweite Faust.** `fistCancelsHold` → `cancelHold`, kein Klick.
- **⌘.** `cmdPeriodCancels` keyCode 47 + Command, analog Escape.
- **`samePressElement`.** Anderes Control unter Up → `cancelPress`.
- **`clickLockRefresh`.** Nach Gate folgt Lock dem Control unter dem Zeiger.
- Tests: TTL 90/180, Faust, Cmd-Punkt, Close≠Mini, Ringe, palmScale 0,08.
- MARKETING_VERSION 1.5.30 (Build 50).

## Nächste (offen, 1.5.30 — erledigt in 1.5.31)

Die Punkte pinchClickNeed, AX-Skip, Kalib je Kamera, Continuity-Watchdog, skipProbe-Reset, frameDt, Click-Lock-Miss sitzen in 1.5.31.

## In 1.5.29 wirklich im Code

1.5.28 hat Clutch-Grace und Gate-Rolle — der Klick blieb trotzdem: `pressMouse` nach 120 ms auch auf der Fensterfläche. Bewegung → `pinchBecameDrag` → `cancelPress` postulierte Up am Cursor = Klick, danach erst Fenster-Drag. Dock und Menüleiste waren `AXWindow`-Drag. `hitRole`/`hitSubrole`/`hitFrame`/`trafficLightPoints` je ein `ElementAtPosition` (5 Roundtrips). Escape tat nichts. Traffic-Magnet nur intern.

- **`pressDuringHold`.** Down nur wenn AX-Rolle/Subrole/Traffic lockt. Fenster: Klick beim Loslassen oder Drag ohne Down.
- **`cancelPress` dump.** Up bei (−8000,−8000), Warp zurück. Kill/Escape/Drag-Start klicken nicht.
- **AX-Probe.** Ein Roundtrip, Cache 2,5 px / 90 ms. Lights vom ancestorWindow, Dock/Menü skip.
- **Dock/Menü lockt.** `AXDockItem`, `AXMenuBarItem`, `AXMenuBar`, `AXMenu`, `AXMenuExtra`.
- **Escape.** `cancelHold` vor Down.
- **`edgeMagnet` 12 px** am `visibleFrame` während Drag.
- **HUD/Overlay MAGNET.**
- Tests: pressDuringHold, Dock, edgeMagnet L/R, MAGNET-Label.
- MARKETING_VERSION 1.5.29 (Build 49).

## Nächste (offen, 1.5.29 — erledigt in 1.5.30)

Die Punkte Overlay-Ring, AX-TTL, zweite Faust, Cmd-Punkt, Down-Element, Click-Lock-refresh sitzen in 1.5.30.

## In 1.5.28 wirklich im Code

1.5.27 hat AX-Mitte, Traffic-Magnet, BUTTON, Hover — der Cursor starb trotzdem nach jedem Klick: `freezeIfStill` sah 0,22 s still während Pinch/Down und setzte `palmFrozen`. Nach Loslassen blieb der Zeiger tot bis `palmUnstill`. Homographie (der „gute“ Pfad nach Kalib) nutzte `pointerAccel` nie — kalibriert = linear-jitterig. `freezePointer` hielt den Cursor während pinchClickMin fest: Gate-Rolle = Start-Rolle, Zielen tot. `pinchClickMaxPx` vom Pinch-Start tötete das Zielen als „Cursor wanderte“.

- **`clutchWhilePinch`.** Pinch oder Down → kein Still-Clutch.
- **`clutchInGrace` 0,35 s.** Nach Loslassen kein Clutch — die Hand ruht kurz.
- **`pointerFrozenWhile`.** Settle zielt. Freeze nur Abort oder Down auf Button.
- **`hitLocksAtGate` + `cursorTravelOrigin`.** Rolle und Klick-Weg nach `pinchClickMin`.
- **`mapFollowMul`.** Homographie-Alpha × Palm-Delta-Kurve. Kleine Wege 0,45, Flick 1,0.
- **HUD CLUTCH.** `clutchHUD` + Chip wenn `palmFrozen` im Follow.
- Tests: clutchWhilePinch, hitLocksAtGate, mapFollowMul, pointerFrozenWhile, cursorTravelOrigin, clutchInGrace, clutchHUD.
- MARKETING_VERSION 1.5.28 (Build 48).

## In 1.5.27 wirklich im Code

1.5.26 hat Pinch-Hysterese und AX-Rolle — der Klick traf trotzdem den Rand: `pressMouse` auf dem HUD-Cursor, Button 4 px daneben, Up am Down-Punkt (Rand), nicht in der AX-Mitte. Pinch neben den Traffic-Lights (36 px) wurde Titelbalken-Drag, obwohl Close AXButton ist. HUD „Halten · Klick“ wirkte tot. Vor Gate kein Ring — die Pinzette schloss unsichtbar. `pressTarget` ohne Shift-Kappe hätte jeden Klick ins Fensterzentrum gewarpt (AXGroup 800×600). Overlay-Ring blieb über der Hardware-Maus.

- **AX-Mitte, mit Kappe.** `pressTarget` + `hitFrame`: Down/Up in `frame.mid` nur wenn der Weg ≤ 56 px (`pressMaxShift`). Große Gruppen bleiben am Cursor.
- **Traffic-Magnet.** `trafficSnap` / `trafficMaxDist` 36 px bzw. 0,30·palmScale. Close/Mini/Zoom der Fenstertitelzeile. `aimPoint` vor Down.
- **HUD BUTTON.** `clickLockLabel` — Control unter dem Zeiger, Cursor darf stillstehen.
- **Hover-Ring.** `pinchHoverProgress` ratio 0,55→0,28 vor Gate. Overlay gestrichelt `HOVER n %`.
- **Overlay aus bei Maus-Vorrang.** `overlayShowsCursor` — Ring nicht über der Hardware-Maus.
- **fps-Spark.** letzte 8 Samples neben `S1 · 8 fps`. Continuity-Drop ohne Konsole.
- Tests: pressTarget Mitte/Rand/nil/Fenster, trafficSnap, clickLockLabel, Subrole, Hover, Spark, Overlay-Pause.
- MARKETING_VERSION 1.5.27 (Build 47).

## In 1.5.26 wirklich im Code

1.5.25 hat Klick-Up am Down — der Klick starb trotzdem beim Atmen: `isGrab` fiel, sobald PinchGate bei ratio 0,40 öffnete und die Pose nicht `.pinch` war. Down auf einem Button wurde Fenster-Drag, sobald die Palme nach pinchClickMin 5 cm wanderte. Relativzeiger linear: nah zu träge, Continuity am Schreibtisch tot. Faust während 4-Ecken-Kalib schaltete scharf. Not-Aus-Fill auf Display 2 war ein Hauch.

- **Pinch-Hysterese.** `pinchKeepsGrab` hält bei ratio < 0,48 solange der Grab läuft. Atmen tötet Down nicht.
- **AX-Rolle lockt Klick.** `axLocksClick` + `hitLocksClick` am Gate-Schluss. Button/Link/Feld → kein `pinchBecameDrag`. HUD „Halten · Klick“.
- **Zeiger-Kurve.** `pointerAccel` dämpft kleine Wege (×0,55), flickig bei 0,10. `depthGain(palmScale)` hebt ferne Palmen bis ×2,4.
- **Kalib blockt Scharf.** `calibBlocksArm` außerhalb Testmodus. Faust zündet keine Ecken.
- **Kill-Ring jedes Display.** 16 px Stroke plus Fill, nicht nur Primary-Hauch.
- Tests: pinchKeepsGrab Atmen/Open/Rebind, axLocksClick Rollen, Accel, Depth, calibBlocksArm.
- MARKETING_VERSION 1.5.26 (Build 46).

## In 1.5.25 wirklich im Code

1.5.24 hat Kill-Rand und Cursor-Inject — der Klick traf trotzdem daneben: `releaseMouse` postulierte Up auf `lastPosted` nach 1-Euro-Jitter. Buttons und Fenster hinter dem Hover sahen den Up. Während `pinchClickMin` war der HUD-Ring tot (kein Fortschritt, Hover wirkte still).

- **Klick-Up am Down.** `pressPoint` + `clickReleasePoint`: ohne Drag immer der Down-Punkt, Warp dorthin. `cancelPress` / Fenster-Drag bleibt `current` (`snapToPress: false`).
- **Settle-Ring.** `clickSettleProgress` 0…1 während pinchClickMin. Overlay `strokeEnd`, HUD `KLICK n %`.
- Tests: clickReleasePoint Down vs Drag, clickSettle 0 / 0,5 / 1, strokeEnd nil/0/1.
- MARKETING_VERSION 1.5.25 (Build 45).

## In 1.5.24 wirklich im Code

1.5.23 hat Scale/Ghost/Wisch — der Cursor starb trotzdem 0,55 s, sobald eine zweite offene Hand im Bild war: `handleKillSwitch` return true vor `moveCursor`. `placeCursor` in der Grace setzte nur den HUD. Knie/Schulter am Bildrand (`openScore ≥ 3`) zählten als zweite Hand. Grab blieb während Windup kleben, weil `driveGrab` nicht lief.

- **Kill-Rand.** `killCounts` / `killEdge` 0,08 — Palmen am Frame-Rand zählen nicht. Peace-Rand dieselbe Zahl.
- **Cursor-Inject.** `injectCursor` = placeCursor + `moveCursor`. Windup und Grace. `killKeepsCursor`.
- **Grab tot im Windup.** Pinch/Drag enden sofort, nicht nach 0,55 s Kill.
- Tests: killCounts Mitte/Rand, killKeepsCursor, killEdge == peaceEdge.
- MARKETING_VERSION 1.5.24 (Build 44).

## In 1.5.23 wirklich im Code

1.5.22 hat Freeze-Rebase und Peace-nicht-wischen — Klick blieb tot, sobald eine zweite Hand lose zu war: Classifier mappt Faust auf `.pinch`, `handleTwoPinchScale` nahm `pose == .pinch || pinchClosed` und blockte `driveGrab` schon im 0,35-s-Windup. Ghost setzte `pointerNeedsRebase` und `placeCursor` verbrauchte ihn — erster Live-Frame nach Dropout = Teleport um den Dropout-Delta. Wisch-Grace nahm `hands.first` (Faust/Pinzette vollendet den Wisch). Not-Aus-Grace 0,14 s fror den Cursor.

- **Scale nur PinchGate.** `scaleHandCount` / `scaleBlocksGrab`: zwei `pinchClosed`, und nur wenn kein Einhand-Grab läuft. Faust-als-Pinch stiehlt den Klick nicht.
- **Ghost lässt Rebase.** `ghostLeavesRebase` — `placeCursor` im Ghost verbraucht ihn nicht. Erster Live-Frame rebase, kein Teleport.
- **Wisch-Grace dieselbe Hand.** `swipeGraceID` — nicht `hands.first`.
- **Not-Aus-Grace:** Cursor läuft weiter, Gesten bleiben tot.
- Tests: scaleHandCount, scaleBlocksGrab, swipeGraceID, ghostLeavesRebase.
- MARKETING_VERSION 1.5.23 (Build 43).

## In 1.5.22 wirklich im Code

1.5.21 hat Warp-vor-Down und Palm-Speed-Gate — der Klick blieb tot: Freeze hält den Cursor 120 ms, `lastPalm` altert mit, nach Down hebt Freeze (`isMousePressed`), der erste `leftMouseDragged` springt um den ganzen Palm-Delta. Buttons sehen einen Drag, nicht einen Klick. `pinchBecameDrag` maß vom Pinch-Start, also Zielen in den 120 ms → Fenster-Greifen statt Klick. Peace (`openScore ≥ 2`) zählte als Wischen: Screenshot-Haltung wechselte Apps. Luma-Skip und Ghost ließen `lastPalm` stehen → Sprung beim Wiedersehen.

- **Freeze zieht nur `lastPalm` nach**, Cursor bleibt. Nach `pressMouse` `pointerNeedsRebase`.
- **`pinchSettlePalm`:** Drag erst nach `pinchClickMin`, gemessen vom Settle-Palm, nicht vom Pinch-Start.
- **`swipeEligible`:** Peace und Zeigen wischen nicht. Nur offene Hand / `openScore ≥ 3`.
- **Ghost + Luma-Skip** setzen `pointerNeedsRebase` — kein Teleport nach Dropout/Dunkel.
- Tests: swipeEligible, pinchSettled, pinchDragMoved.
- MARKETING_VERSION 1.5.22 (Build 42).

## In 1.5.21 wirklich im Code

1.5.20 hat Ghost ohne One-Shots und Klick-Dragged — Down saß trotzdem auf `lastPosted` (nil nach Freeze/Erst-Pinch = Hardware-Maus). Cursor ist während pinchClickMin eingefroren, also `cursorTravel` immer 0: ein Flick in den ersten 120 ms klickte die Fläche unter dem Hover, bevor der Wurf kam. Abort-Hold schrieb „Hand unsicher“ ins Armed-HUD. Ghost nur 35 % im Preview-Chip, Overlay-Ring blieb solid.

- **`pressMouse(at:)` / `click(at:)`:** Warp `mouseMoved` auf HUD-Cursor, dann Down. Nicht lastPosted/Hardware.
- **`pinchDownBlocked`:** Palm-Speed > 0,20 während pinchClickMin → kein Down. Loslassen denselben Guard (sonst click()-Fallback).
- **„Hand unsicher“ nur Testmodus.** Armed hält lastAction während Abort-Hold.
- **Ghost-Ring gestrichelt** auf dem Overlay-Monitor (`GHOST`), Preview-Box immer Dash.
- Tests: pinchDownBlocked, pinchDownSpeed.
- MARKETING_VERSION 1.5.21 (Build 41).

## In 1.5.20 wirklich im Code

1.5.19 hat Ghost-Hände als echte Pose in die Engine geschoben — Peace hielt 0,55 s auf der gefrorenen Hand und machte Screenshots, Not-Aus zündete mit zwei Ghost-Palmen, Faust-Scharf aus einem Dropout. Klick-Down fror den Zeiger: Buttons unter einer leicht wandernden Pinzette sahen `mouseMoved` statt Druck. Zwei-Pinzetten-Scale wuchs um die Fenstermitte, nicht um den Cursor. Nach TCC-Reset blieb Helios „scharf“ ohne Banner.

- **Ghost ohne One-Shots:** `TrackedHand.isGhost`. Engine `holdGhost` — Grab/Cursor bleiben, Peace/Daumen/Wisch/Scharf/Not-Aus nicht. HUD `S1 Ghost 0,4 s`. Preview-Skelett 35 %.
- **Klick folgt:** nach `pressMouse` `leftMouseDragged` statt `mouseMoved`. Freeze nur bis Down, nicht danach.
- **Zoom am Cursor:** `resizeOrigin` + `resizeFocused(anchor:)`. Mitte bleibt Fallback.
- **AX-Banner:** `accessDropped` sobald Bedienungshilfen nach OK weg sind.
- Tests: ghostHUD, resizeOrigin um Mitte vs. Ecke.
- MARKETING_VERSION 1.5.20 (Build 40).

## In 1.5.19 wirklich im Code

1.5.18 hat Format-Score und Freeze-Rebase — Grab starb trotzdem: `HandTracker` lieferte bei leerer Vision `[]` (Slot-TTL hielt nur interne Slots). Engine abort nach 0,22 s. Pinch-Hold 2 Extra-Frames nach PinchGate = 500 ms bei 8 fps. Klick war Down+Up erst beim Loslassen — Buttons sahen keinen Hover-Druck. Dual-Cam-Banner ohne Picker.

- **Ghost-Hände:** leere Vision / Handler-Fehler < `slotHold` 0,60 s → letzte `TrackedHand`s, nicht `[]`. Grab/Pinch bleiben. Danach erst Abort.
- **`pinchPoseHoldNeed(dt)`:** 8 fps 1 Frame, 24 fps 2. Peace/Daumen `poseHoldNeed` 2 vs 4.
- **Klick Down/Up:** `pressMouse` nach `pinchClickMin` wenn Cursor still. `releaseMouse` beim Öffnen. Drag/Abort/`seize` macht `cancelPress`.
- **Kamera-Picker:** Auto / Built-in / Continuity. Prefs. Banner verweist aufs Panel.
- Tests: ghostHands, pinchPoseHoldNeed, poseHoldNeed.
- MARKETING_VERSION 1.5.19 (Build 39).

## In 1.5.18 wirklich im Code

1.5.17 hat Slot-TTL und Open-Vel — Formatwahl bevorzugte 360p@60 und 800p@8. PinchGate Open brauchte 3 Frames (375 ms bei Continuity). Nach Abort-Freeze war `lastPalm` 0,22 s alt → erster Tick Sprung. AX-Fail 2× ließ das tote Element fallen, ohne neu zu greifen. Slot-IDs liefen monoton. Homographie-Alpha 0,55 bei 8 fps zu träge. Unter 6 fps kein Banner. Continuity trotz Frontkamera still.

- **`formatScore`:** 720p@24 schlägt 360p@60; 540p@15 schlägt 800p@8. 1920×1080 erlaubt. `lockFrameRate` 24–30, Continuity bleibt beim Maximum.
- **`pinchOpenNeed(dt)`:** 8 fps 2 Frames, 24 fps 3. Open nicht mehr 375 ms klebrig.
- **`pointerNeedsRebase`:** erster Sample nach Freeze setzt `lastPalm`, kein dx.
- **AX-Fail 2×:** `targetWindow` neu, Offset neu. Nur wenn das fehlt, `endWindowDrag`.
- **Slot-Reuse:** kleinste freie ID, nicht S47.
- **`mapSmoothAlpha(dt)`:** 8 fps 0,67, sonst 0,55.
- **fps-Watchdog:** < 6 fps für 5 s → Banner + Gain ×0,5.
- **Dual-Cam-Banner** wenn Fallback und Built-in gleichzeitig da.
- **HUD** `S1 · 8 fps`.
- Tests: formatScore, lockFrameRate, Open-Need, Watchdog, mapSmooth, 8-fps Open in 2 Frames.
- MARKETING_VERSION 1.5.18 (Build 38).

## In 1.5.17 wirklich im Code

1.5.16 hat Slot vor Chirality und Close-Vel — der Rest blieb: Slot-TTL = Abort-Hold 0,22 s (ein Continuity-Frame tötet S1, zweite Hand erbt). PinchGate Open-Vel hart −0,5 (24 fps öffnet zu leicht, 8 fps bleibt zu). Faust-Scharf ohne vorher offene Hand. `bestFormat` verwarf alles unter 24 fps → Continuity blieb beim Default-8-fps-Format. Relativzeiger voller Gain bei dt 125 ms. AX `setPosition` jeden Tick, ohne Coalesce. Overlay-Ring erst nach 0,4 s Dunkel weg. `pointerHandID` während Freeze umgeschrieben.

- **`slotHold` 0,60 s:** Palm-Slot stirbt nicht mit Abort-Hold. `expireSlots` unabhängig.
- **`emptySince` wipe an `slotHold`:** 0,22 s hat S1 bei Continuity-Dropout gelöscht, obwohl expire 0,60 s sagte.
- **`pinchOpenVel(dt)`:** +0,40 bei 16 ms, weicher bei 8 fps. 24 fps muss wirklich öffnen.
- **Faust-Scharf nach `sawOpen`:** `openScore ≥ 2` vorher, sonst „Erst öffnen, dann Faust“.
- **`openMemory` 2 s:** ohne Hand `sawOpen` zurück, sonst gilt eine alte Öffnung ewig.
- **Continuity-Format:** `bestFormat` fällt auf ≥ 7 fps, nicht nil.
- **Confidence-Floor 0,12** bei Fallback-Cam (Engine + Vision-Observation).
- **Relativzeiger `pointerGainMul`:** dt ≥ 0,10 → ×0,72.
- **AX-Drag coalesced:** ein In-Flight, letzter Punkt, kein 8-fps-Stakkato.
- **Luma-Skip `mark` sofort** — Ring weg, Skelett nach 0,4 s.
- **Freeze hält `pointerHandID`** Homographie und Relativzeiger.
- **HUD Slot-ID** `S1`/`S2` (Pinch-Actor oder Pointer-Slot) neben der Aktion.
- Tests: pinchOpenVel, slotHold, openMemory, 8-fps-Gate 3 Frames, Palm-Slot Distanz, Gain-Mul.
- MARKETING_VERSION 1.5.17 (Build 37).

## In 1.5.16 wirklich im Code

1.5.15 hat Palm-Slot und Abort-Freeze — der Cursor sprang trotzdem: `preferred()` wählte nach L/R, `actorMapped` setzte `cursorSmooth = q` sobald die Hand-ID wechselte. PinchGate Close-Vel −2 war bei Continuity tot (`dt` auf 80 ms gekappt, ein Frame = 125 ms). Wischen: Trail 280 ms + `swipeMinDt` 160 ms, zwei 8-fps-Samples spannen 125 ms. Classifier lieferte `.fist` bei geschlossenen Spitzen ohne Reach — Faust schaltete scharf während der Pinzette. Overlay-Ring blieb nach Luma-Skip stehen, weil `mark` fehlte. Landmark-1-Euro kappte dt weiter auf 80 ms.

- **`preferred()` Slot vor Chirality:** `pointerHandID ?? pinchActorID`, nicht L/R. Nach Abort nicht `primary` (andere Hand).
- **Kein Homographie-Teleport:** Hand-ID-Wechsel hält `cursorSmooth`, Euro-Reset, `cursorDidMove = false`.
- **PinchGate Close-Vel `pinchCloseVel(dt)`:** −2 bei 16 ms, weicher bei 8 fps. `sampleDtCap` 0,20 s.
- **Wischen 8 fps:** `adaptiveSwipeTrail` 3,2 × medianDt, `swipeMinDt(medianDt)` statt hart 160 ms.
- **Geschlossene Spitzen = Pinzette:** `fingers == 0 && ratio < 0,38` → `.pinch`. HandTracker remappt auch `.fist`.
- **Palm-Bind skaliert:** ferne kleine Hände enger (`palmBind(scale)`), sonst kleben zwei auf einem Slot.
- **Luma-Skip:** `overlay.mark(cursor: nil)` — Ring weg, nicht eingefroren.
- **Landmark-Smoother** nutzt `sampleDtCap` 0,20 (war 0,08).
- Tests: pinchCloseVel, palmBind, adaptiveSwipe, 8-fps-Wisch, enge Spitzen, sampleDtCap.
- MARKETING_VERSION 1.5.16 (Build 36).

## In 1.5.15 wirklich im Code

1.5.14 hat Grab-Hold und Actor-Rebind — der Cursor sprang trotzdem: `pinchActor` gab nach `abortGrab` `primary` zurück, `placeCursor` teleportierte auf die andere Hand. PinchGate hing an L/R; der Transfer-Hack war die Brücke. Homographie im Void zog voll. Overlay-Skelett fror die letzte Pose ein. AX-Timeout wurde verschluckt. Wurf-Fenster fest 120 ms plus 4-Sample-Fallback.

- **Palm-Slot statt Chirality:** `HandTracker` bindet Smoother/PinchGate/Pose-Hold über Palm-Nähe. IDs `S1`/`S2`. L↔R-Transfer und L/R-Gates sind tot. Chirality bleibt Label für HUD/Linkshänder.
- **Kein Teleport nach Abort:** `pointerFrozenUntil` = `grabAbortHold`. `placeCursor` wartet, statt `primary` zu erben.
- **Fling-Fenster `max(120 ms, 2,5 × medianDt)`.** 8 fps ≈ 310 ms, nicht 120 ms + 4 Samples.
- **`mapGain(residual)`:** Homographie-Residual dämpft Follow (1 → 0,35), nicht nur Drift-Banner.
- **Overlay-Dunkel 0,4 s:** `overlayDarkHold` leert `hands`, Skelett friert nicht.
- **AX-Timeout:** zwei fehlgeschlagene `setPosition` → `endWindowDrag`. Pinch bleibt, Engine retried. Timeout ≠ Loslassen.
- Tests: mapGain, overlayDarkHold, adaptives Fling-Fenster.
- MARKETING_VERSION 1.5.15 (Build 35).

## In 1.5.14 wirklich im Code

1.5.13 hat Grab-Abbruch *behauptet*, sobald die Actor-ID fehlte — im selben Tick nahm `primary` den Drag, Vision-Flicker (1 leerer Frame) setzte PinchGate zurück, Chirality-Flip R→L tötete den Grab, Luma-Skip schob `hands: []` und zündete Dead-Man. Würfe bei Continuity 8 fps waren tot (120-ms-Fenster = 1 Sample).

- **`grabAbortHold` 0,22 s:** `abortGrab` setzt `ignoreGrabUntilOpen` + Cooldown. Leerer Tick hält den Grab, statt das Fenster fallen zu lassen.
- **Actor-Rebind über Palm** (`GestureMath.actorRebind`): dieselbe Hand nach L↔R, nicht `primary`.
- **PinchGate-Transfer:** fehlende Seite kopiert die geschlossene Pinzette, Donor wird geleert. Gate-Reset erst nach 0,22 s ohne diese Chirality.
- **Luma-Skip:** kein `hands: []`. `noteDarkFrame` nur Dead-Man nach 8 s.
- **`trailMotion`:** 8–12 fps fällt auf die letzten 4 Samples. Guard 20 ms.
- **Heranziehen** nur nach `pinchBecameDrag` und außerhalb `pinchClickMax`.
- **Peace** bricht bei Palm innerhalb `peaceEdge` 0,08 ab.
- **Zwei-Pinzetten** nach `id` sortiert (Span springt sonst).
- **PointerEuro** Cutoff ×1,7 bei dt ≥ 0,10 s.
- Tests: 8-fps-Flick, Actor-Rebind, Pointer-Cutoff.
- MARKETING_VERSION 1.5.14 (Build 34).

## In 1.5.13 wirklich im Code

1.5.12 hat den Pinch-Lock *behauptet*: `pinchActor` gab `primary` zurück, `pinchHeld` blieb true — `driveGrab` zog mit der anderen Hand weiter. Dazu drei Logikfehler, die sich wie „Helios spinnt“ anfühlen.

- **Grab-Abbruch:** Original-Hand weg → `abortGrab` (Drag Ende, `pinchHeld` false). Die andere Hand erbt den Grab nicht.
- **Wurf-Fenster 120 ms:** Speed/Richtung aus `GestureMath.trailMotion`, nicht first/last des 0,5-s-Trails. Ein Flick nach Halten lag unter `flingMinSpeed`.
- **Heranziehen:** Palm-Y fällt um `pullToward` 0,11. Mittelfinger-Spannweite hat beim Öffnen der Pinzette Fenster gefüllt.
- **Zwei-Pinzetten:** `pinchClosed` zählt, nicht nur `pose == .pinch`.
- **Luma-Gate 0,08:** kein Vision, Banner „ZU DUNKEL“, tote Frames.
- **Monitor-Hash:** Layout-Wechsel → Relativzeiger + Drift-Banner, Overlay neu.
- **Not-Aus-Grace 0,14 s** statt 0,28 s Totzeit nach einem Palm-Blitz.
- Tests: Flick über MinSpeed, 0,5-s-Mittel wäre `.none`.
- MARKETING_VERSION 1.5.13 (Build 33).

## In 1.5.12 wirklich im Code

- Build: doppeltes `swipeGraceUntil` weg.
- Peace/Daumen: andere Hand mit Pinzette → Screenshot/Unhide ignoriert.
- Fast-Wurf: `nearFlingClick`.
- Zwei-Pinzetten-Scale: Relativ 0,08 **und** Palmen-Totzone 0,04.
- SpaceMap `isUsable`: `isReady && homography() != nil`.
- Drift-Banner, Relativzeiger 1-Euro, Overlay Actor-Hand, Fallback-Cam, Pinzette vor Zeigen.

## Warum es sich schlecht anfühlte

- **Grab-Diebstahl:** Kommentar sagte „nicht erben“, Code erbte. Zweite Hand übernahm Fenster-Drag.
- **Grab-Flicker:** ein leerer Vision-Frame = PinchGate reset + Fenster fällt. Chirality-Flip dasselbe.
- **Cursor-Teleport (1.5.15):** Abort-Freeze hielt 0,22 s — danach `preferred()` über L/R, Homographie `cursorSmooth = q` auf die neue Hand. Der Zeiger sprang über den Tisch.
- **PinchGate tot bei 8 fps:** Close-Vel −2 bei dt 16 ms. Continuity-Frame 125 ms, dt gekappt auf 80 ms → vel nie unter −2. Pinzette schloss nicht.
- **Wischen tot bei 8 fps:** 2 Samples = 125 ms < `swipeMinDt` 160 ms. Trail 280 ms hält oft nur 2 Punkte.
- **Scharf während Pinzette:** Classifier `.fist` wenn Spitzen zu und Reach niedrig. HandTracker remappte nur unknown/point, nicht fist.
- **Overlay-Ring nach Dunkel:** Skelett leer, Marker nicht `mark` — Ring blieb am letzten Cursor.
- **Landmark-Jitter bei Continuity:** 1-Euro dt-Cap 80 ms, Velocity 125/80 zu groß, Hand zittert nach.
- **Würfe kamen nicht:** 0,5 s Stillstand + 120 ms Flick → Speed = Weg/0,5 < Schwelle. Bei 8 fps war das 120-ms-Fenster leer.
- **Fenster sprang auf Vollbild** sobald die Pinzette sich leicht öffnete (Mittelfinger) oder atmete.
- **Scale blieb tot**, wenn Vision `pinchClosed` aber Pose `fist` lieferte.
- Dunkelkammer: Vision auf Rauschen, Fake-Hände, Dead-Man zündete — oder nach dem Skip das Skelett ewig stehen blieb.
- Monitor umstecken: Homographie zeigte in den Void, kein Recenter, voller Gain.
- AX hängt: `setPosition` Timeout, Helios glaubt weiter zu ziehen.
- 1.5.11 kompiliert nicht (doppeltes `swipeGraceUntil`) — Fixes standen in der Liste, nicht im Binary.

## Aegis Scanner

Liegt unter [`lolalpha00gamma/aegis-scanner`](https://github.com/lolalpha00gamma/aegis-scanner). Fixes in **2.1.24**. Kein Code von dort hierher kopieren.

## Nächste Erweiterungen

- **Klick-Up am Down-Punkt.** **→ 1.5.25 clickReleasePoint**
- **Grab-Timeout Settle-Ring.** **→ 1.5.25 clickSettleProgress / strokeEnd**
- **Kill-Rand / Cursor-Inject / Grab im Windup.** **→ 1.5.24 killCounts injectCursor**
- **Zwei-Pinzetten-Scale braucht PinchGate, nicht Faust-als-Pinch.** **→ 1.5.23 scaleBlocksGrab**
- **Ghost-Rebase nicht verbrauchen.** **→ 1.5.23 ghostLeavesRebase**
- **Wisch-Grace dieselbe Slot-ID.** **→ 1.5.23 swipeGraceID**
- **Not-Aus-Grace Cursor nicht frieren.** **→ 1.5.23 HUD; 1.5.24 moveCursor**
- **Pinch-Hysterese:** leichtes Öffnen während Klick (ratio 0,34–0,42) nicht sofort `isGrab = false`. **→ 1.5.26 pinchKeepsGrab**
- **Kill-Ring auf jedem Display.** **→ 1.5.26 killRingOnAllDisplays**
- **Pointer-Clutch Prefs:** `palmStill` als Slider, HUD „CLUTCH“. **(HUD → 1.5.28 clutchHUD; Slider bleibt)**
- **Zeiger-Beschleunigung** (nicht linearer Gain). **→ 1.5.26 pointerAccel; Homographie → 1.5.28 mapFollowMul**
- **AX-Hit-Test für Klick-Up:** Down merkt das AX-Element, Up nur dort. **(Punkt → 1.5.25; Rolle lockt Drag → 1.5.26; Element-Mitte → 1.5.27 pressTarget)**
- **HUD „BUTTON“** wenn `pressLocksClick`. **→ 1.5.27 clickLockLabel**
- **AX-Element merken:** Down speichert das AXUIElement, Up warpt in dessen Mitte. **→ 1.5.27 pressFrame / pressMaxShift**
- **HUD fps-Spark:** letzte 8 fps-Samples. **→ 1.5.27 fpsSpark**
- **Klick-Magnet auf Traffic-Lights** bis 0,30 Handbreiten. **→ 1.5.27 trafficSnap**
- **Zwei-Stufen-Pinzette:** Hover-Ring 80–120 ms vor Gate. **→ 1.5.27 pinchHoverProgress**
- **Overlay aus bei Maus-Vorrang** — Ring bleibt sonst über der Hardware-Maus. **→ 1.5.27 overlayShowsCursor**
- **Rechtsklick:** Pinzette + 0,55 s Extra-Hold ohne Bewegung = `rightMouse` statt Left-Up.
- **Dwell-Klick:** 0,70 s Hover ohne Pinch für motorische Einschränkung, Prefs aus.
- **Fling-Inertia:** nach Loslassen 80 ms Cursor-Nachlauf in Wurf-Richtung, Totzone gegen Klick.
- **Per-App Zeiger-Gain** (Finder 1,2 / Safari 1,6 / Xcode 1,0).
- **Sleep-Rekalib:** Residual-Spike nach Display-Sleep → 1-Punkt-Nachkalib der driftenden Ecke.
- **Pinch-Right-Click HUD** „RECHTS“ analog BUTTON.
- **Window-Snap Ghost:** Rechteck-Vorschau am Rand während Drag. **Magnet 12 px → 1.5.29 edgeMagnet**
- **Clutch-Schwelle Prefs** (`palmStill` / `palmUnstill`) sichtbar neben Zeiger-Empfindlichkeit.
- **Clutch-Grace Prefs** (`clutchGraceHold` 0,35 s).
- **Homographie-Depth** nur wenn Residual klein — ferne Palme sonst extra Jitter.
- **RTL-Traffic-Lights** (Close rechts).
- **Pro-App-Profile** (Finder: Werfen = Datei; Safari: Werfen = Tab/Fenster).
- **Gemeinsame Kamera-Session mit Aegis** — eine TCC, zwei Consumer, kein Code-Duplikat.
- **Mission Control:** drei offene Finger nach oben, Totzone gegen Wisch. Edge-Dwell 0,6 s am Rand.
- **Cmd/Opt/Shift über zweite Hand:** Peace = Cmd, Point = Opt, Faust = Shift.
- **Fling-Pfeil-Ghost** während Pinch-Drag über `flingMinSpeed`.
- **SpaceMap pro Monitor** mit 4 Ecken je Screen + RMS unter 40 px vor „fertig“.
- **Wrist-Roll Scroll:** Pitch der Palm-Normalen, Totzone gegen Cursor-Gain.
- **Blick weg / kein Gesicht → Auto-Idle** (Vision face count, kein Aegis-Match).
- **Dominant-Hand** aus den ersten 30 Faust-Frames, Prefs-Toggle bleibt Override.
- **Accel-Slider** 0 = linear, 1 = Trackpad (intern 1.5.26/28 fest).
- **Depth-Gain Prefs** statt hart 0,12 / 2,4.
- **Palm-Velocity Scroll** (offene Hand + schnelles Y, Totzone gegen Wisch-X).
- **Haptik** CoreHaptics bei Klick-Down und Fling-Lock — ohne Ton.
- **Two-Finger Scroll:** offene Hand + Palm-Y, nicht Pinch — Pinch bleibt Klick.
- **Click-Lock während Hold auffrischen** wenn der Cursor auf ein anderes Control rutscht (Element, nicht nur Punkt).
- **AX-Hit Element merken:** Up nur auf dem Down-Element, sonst Buttons hinter dem Fenster.
- **Kalman nur Fling**, nicht Cursor.
- **SpaceMap 1-Punkt-Nachkalib** wenn Residual > 480 für 2 s.
- **Palm-Jitter-Meter** im Testmodus (px/s).
- **Testmodus Slot-TTL** `S1 0,4 s`.
- **Drei-Finger Spaces:** drei gestreckte Finger horizontal = Mission Control Spaces.
- **Cursor-Clutch Geste:** halboffene Faust friert den Zeiger ohne Idle.
- **Overlay-Skelett fade 0,4 s** statt hart leeren.
- **Continuity-Gain als Nutzer-Slider** (intern 0,72).
- **Right-Click:** Ringfinger-Pinzette oder zweite Faust.
- **Drag-Preview-Ghost** des Fensters bei 40 % Opacity während AX-Lag.
- **Per-App Click-Lock-Liste** (Safari Toolbar vs Content).
- **Double-Pinch = Double-Click** innerhalb 0,32 s, Totzone gegen Drag.
- **HUD-Skelett** nur Actor-Hand, 12 Gelenke, Overlay-Monitor.
- **Force-Touch analog:** Pinch-Ratio 0,12–0,20 = schneller Doppelklick.
- **Scroll-Inertia** nach Palm-Y Flick, klingt in 0,4 s aus.
- **Not-Aus nur über Brusthöhe** (Palm-Y > 0,35), Knie bleibt killEdge.
- **Kalib-RMS live** während der 4 Ecken, Abbruch wenn Ecke > 80 px Drift.

- Accessibility-Hold: nach TCC-Reset automatisch `AXIsProcessTrusted` pollen und Banner, nicht nur einmal. **→ 1.5.20 accessDropped**
- **Klick-Magnet auf Traffic-Lights** bis 0,30 Handbreiten — Pinch auf dem Punkt bleibt Klick. **→ 1.5.27 trafficSnap; HUD MAGNET → 1.5.29**
- **Fling-Pfeil-Ghost** während Pinch-Drag über `flingMinSpeed`.
- **SpaceMap pro Monitor** mit 4 Ecken je Screen.
- **Wrist-Roll Scroll:** Pitch der Palm-Normalen, Totzone gegen Cursor-Gain.
- **Zwei-Stufen-Pinzette:** Hover-Ring 80–120 ms vor Gate. **(Settle-Ring nach Gate → 1.5.25; vor Gate bleibt)**
- **Blick weg / kein Gesicht → Auto-Idle** (Vision face count, kein Aegis-Match).
- **Dominant-Hand** aus den ersten 30 Faust-Frames, Prefs-Toggle bleibt Override.
- **Accel-Slider** 0 = linear, 1 = Trackpad (intern 1.5.26 fest).
- **Depth-Gain Prefs** statt hart 0,12 / 2,4.
- **Palm-Velocity Scroll** (offene Hand + schnelles Y, Totzone gegen Wisch-X).
- **Fenster-Drag Magnet 12 px** am Screen-Rand, analog Andocken ohne Wurf. **→ 1.5.29 edgeMagnet**
- **Haptik** CoreHaptics bei Klick-Down und Fling-Lock — ohne Ton.
- **Gesture-Filmstreifen** nur Pose-Wechsel, nicht 30 fps ins Protokoll.
- **AX-Hit Cache:** ein ElementAtPosition pro Tick, Role/Subrole/Frame daraus — sonst 5 AX-Roundtrips pro Gate. **→ 1.5.29 HitProbe + ancestorWindow**
- **Click-Lock während Hold auffrischen** wenn der Cursor auf ein anderes Control rutscht.
- **Two-Finger Scroll:** offene Hand + Palm-Y, nicht Pinch — Pinch bleibt Klick.
- **Dock-Magnifier Skip:** AXDockItem Magnet 24 px, analog Traffic-Lights. **→ 1.5.29 AXDockItem lockt Klick**
- **Menu-Bar Extra** StatusItem-Klick ohne Fenster-Drag (AXMenuBarItem). **→ 1.5.29 AXMenuBarItem**
- **Escape = Pinch-Cancel** während Hold, bevor Down feuerte. **→ 1.5.29 cancelHold**
- **Kalman nur Fling**, nicht Cursor.
- **SpaceMap 1-Punkt-Nachkalib** wenn Residual > 480 für 2 s.
- **Peace+Palm-Y Scroll** ohne Screenshot (Peace-Hold bleibt 0,5 s extra).
- **Drei-Finger Spaces:** drei gestreckte Finger horizontal = Mission Control Spaces, nicht App-Wechsel.
- **Cursor-Clutch Geste:** halboffene Faust friert den Zeiger ohne Idle.
- **Overlay-Klick-Magnet sichtbar:** Ring um Traffic-Lights wenn die Palme in 0,30 Handbreiten ist. **→ 1.5.29 MAGNET-Text; 1.5.30 trafficLightRings**
- **Blick weg / kein Gesicht → Auto-Idle** (Vision face count, kein Aegis-Match).
- **Dominant-Hand** aus den ersten 30 Faust-Frames, Prefs-Toggle bleibt Override.
- **HUD-Skelett** nur Actor-Hand, 12 Gelenke, Overlay-Monitor.
- **Gesture-Filmstreifen** nur Pose-Wechsel, nicht 30 fps ins Protokoll.
- **Magnetischer Fensterrand** während Drag (12 px).
- **Continuity-Gain als Nutzer-Slider** (intern 0,72).
- **SpaceMap 1-Punkt-Nachkalib** wenn Residual > 480 für 2 s.
- **Peace+Palm-Y Scroll** ohne Screenshot (Peace-Hold bleibt 0,5 s extra).
- **SpaceMap RMS** nach Apply der Kalibrier-Ecken, unter 40 px = gut.
- **Kalman nur Fling**, nicht Cursor.
- **Palm-Jitter-Meter** im Testmodus (px/s).
- **Testmodus Slot-TTL** `S1 0,4 s`.
- **Haptik** über CoreHaptics bei Klick-Down und Fling-Lock — ohne Ton.
- Adaptive Pointer-Gain aus SpaceMap-Residual als Nutzer-Slider (mapGain ist intern).
- Handgelenk-Rollen als Scroll (Pitch der Palm-Normalen, Totzone gegen Cursor-Gain).
- Zwei-Stufen-Pinzette: Schweben vs. Klick (Hover-Ring 80–120 ms vor Gate). **(nach Gate → 1.5.25)**
- Blick weg / kein Gesicht → Auto-Idle nach 2 s (Vision face count, kein Aegis-Match).
- Dominant-Hand merken aus den ersten 30 Faust-Frames, nicht nur Prefs-Toggle.
- HUD-Skelett auf dem Overlay-Monitor, nicht nur im Preview-Chip (teuer — nur Actor-Hand, 12 Gelenke).
- Cursor-Clutch: Faust halb offen = Zeiger einfrieren ohne Idle.
- Pinch-Trail Kalman (2D) statt Roh-Palm für Fling-Richtung — weniger Diagonal-Fehlwürfe.
- SpaceMap pro Monitor: 4 Ecken je Screen, Homographie-Switch wenn Cursor den Screen wechselt.
- Gesture-Filmstreifen: nur Pose-Wechsel, nicht 30 fps ins Protokoll.
- **Klick-Hit-Test AX:** nach Down das AXUIElement unter dem Cursor merken, Up nur dort (sonst landet der Up auf dem Fenster dahinter). **Punkt → 1.5.25; Element bleibt**
- **Mission Control:** drei offene Finger nach oben, Totzone gegen Wisch.
- **Magnetischer Fensterrand** während Drag (12 px), analog Andocken ohne Wurf.
- **Zeiger-Beschleunigung** (nicht linearer Gain): kleine Palm-Wege dämpfen, große flickig — Trackpad-Kurve. **→ 1.5.26 pointerAccel; Homographie 1.5.28 mapFollowMul**
- **Edge-Dwell:** Palm 0,6 s am Bildrand = Mission Control / App-Exposé, nicht Wisch.
- **Haptik** über CoreHaptics (Trackpad) bei Klick-Down und Fling-Lock — ohne Ton.
- **Zweite Hand am Rand ignorieren** — oft ein Knie/Schulter-False-Positive für Not-Aus. **→ 1.5.24 killCounts**
- **Pinch-Up am selben AX-Element** wie Down, sonst Buttons hinter dem Fenster. **Punkt → 1.5.25**
- **Relativzeiger-Acceleration-Kurve** als Slider (0 = linear, 1 = Trackpad).
- **Grab-Timeout sichtbar:** HUD-Ring während pinchClickMin, damit der Hover sitzt. **→ 1.5.25 clickSettle**
- **Fling-Vorschau:** Pfeil-Ghost in Wurf-Richtung während Pinch-Drag über `flingMinSpeed`.
- Continuity-Gain als Nutzer-Slider (intern 0,72).
- Overlay-Skelett fade 0,4 s statt hart leeren — Grab-Hold bleibt, Pose wird transparent.
- SpaceMap-Rekalib 1-Punkt (nur Drift-Ecke) statt 4 Ecken neu.
- Zwei-Finger-Scroll: Peace + Palm-Y, ohne Screenshot (Peace-Hold bleibt 0,5 s extra).
- SpaceMap 4-Punkt-Qualität: RMS nach Apply der Kalibrier-Ecken, unter 40 px = gut.
- Gesture-Log JSONL nur Pose-Wechsel (Filmstreifen ist Clipboard).
- Kalman auf Pinch-Trail nur für Fling, nicht Cursor (sonst weich).
- Palm-Jitter-Meter im Testmodus (px/s), Kalibrierung der Totzone.

- Accessibility-Hold: nach TCC-Reset automatisch `AXIsProcessTrusted` pollen und Banner, nicht nur einmal. **→ 1.5.20 accessDropped**
- Zwei-Hände-Zoom an der Cursorposition, nicht am Fenstermittelpunkt. **→ 1.5.20 resizeOrigin**
- Fling-Vorschau: Pfeil-Ghost in Wurf-Richtung während Pinch-Drag über `flingMinSpeed`.
- `HandTracker` Confidence-Floor anpassen wenn Continuity-Fallback (0,12 statt 0,18). **→ 1.5.17**
- Fenster-Drag auf AXPosition-Main-Thread coalescen (axQ kann Frames hinterherhinken). **→ 1.5.17 coalesced**
- Slot-ID `S1` im Debug-Chip neben Links/Rechts — Chirality-Flip sichtbar machen. **→ 1.5.17 HUD**
- Relativzeiger: nach Abort `pointerHandID` nicht umschreiben, bis Freeze vorbei. **→ 1.5.17**
- Faust-Scharf nur wenn `openScore` vorher ≥ 2 war. **→ 1.5.17 sawOpen**
- Test: Palm-Slot-Bindung ohne Vision. **→ 1.5.17 Distanz-Fixtures**
- PinchGate **Open**-Vel dt-skalieren. **→ 1.5.17 pinchOpenVel**
- Slot stirbt nach 0,6 s. **→ 1.5.17 slotHold**
- Continuity Pointer-Gain-Dämpfer. **→ 1.5.17 pointerGainMul** (Slider bleibt)
- Test: 8-fps PinchGate `dt=0,125` in 3 Frames. **→ 1.5.17**
- AX-Drag coalescen. **→ 1.5.17**
- Luma-Skip `mark` sofort. **→ 1.5.17**
- Continuity-Format ≥ 7 fps. **→ 1.5.17 bestFormat**

- Continuity-Gain als Nutzer-Slider (intern 0,72).
- Overlay-Skelett fade 0,4 s statt hart leeren — Grab-Hold bleibt, Pose wird transparent.
- `beginWindowDrag` nach AX-Fail 2×: Ziel neu über CGWindowList, nicht dasselbe tote AXUIElement. **→ 1.5.18 reacquire**
- HUD „Hand unsicher“ nur wenn `handsLostAt` läuft, nicht als lastAction-Spam. **→ 1.5.21 testMode**
- SpaceMap-Rekalib 1-Punkt (nur Drift-Ecke) statt 4 Ecken neu.
- Zwei-Finger-Scroll: Peace + Palm-Y, ohne Screenshot (Peace-Hold bleibt 0,5 s extra).
- Overlay-fps neben Slot, damit 8 vs 24 ohne Konsole sichtbar ist. **→ 1.5.18 HUD S1 · fps**
- Klick-Preview: Ring 80 ms vor Gate-Schluss, damit der Hover sitzt bevor Down kommt. **(nach Gate → 1.5.25)**
- Slot-Reuse: abgelaufene IDs wiederverwenden, `nextSlotID` nicht monoton (S47 nach einer Stunde). **→ 1.5.18 allocSlot**
- `emptySince` Slot-Wipe an `slotHold` koppeln, nicht Abort-Hold — sonst S1 nach 0,22 s tot obwohl expire 0,60 s sagt. **→ 1.5.17**
- Pinch-Klick Down/Up split: CGEvent leftMouseDown bei Gate-Schluss, Up beim Öffnen (Buttons sehen Hover). **→ 1.5.19 pressMouse nach pinchClickMin**
- Homographie-dt in mapSmooth: 8 fps etwas höherer Alpha, sonst hängt der Zeiger. **→ 1.5.18 mapSmoothAlpha**
- Testmodus zeigt Slot-TTL: HUD „S1 0,4 s“ wenn Observation fehlt.
- Continuity: Frame-Rate-Range nicht auf minFrameDuration zwingen, wenn max < 24 — sonst 8 fps hart. **→ 1.5.18 lockFrameRate**
- Dual-Cam-Hinweis wenn Built-in und Continuity beide da: Picker, nicht still Fallback. **→ 1.5.18 Banner (Picker bleibt)**
- `sawOpen` nach 2 s Idle ohne Hand zurücksetzen — sonst gilt eine alte Öffnung ewig. **→ 1.5.17 openMemory**
- AX-Drag: nach Fail 2× `targetWindow(at:)` neu, nicht `endWindowDrag` allein. **→ 1.5.18**
- Kalman auf Pinch-Trail nur für Fling, nicht Cursor (sonst weich).
- Watchdog: wenn `fps < 6` fünf Sekunden, Banner „Kamera zu langsam“ + Gain-Mul 0,5. **→ 1.5.18**
- SpaceMap 4-Punkt-Qualität: RMS nach Apply der Kalibrier-Ecken, unter 40 px = gut.
- Gesture-Log JSONL nur Pose-Wechsel (Filmstreifen ist Clipboard).
- HUD Slot auch ohne Pinch (Pointer-Slot). **→ 1.5.17 pinchActorID ?? pointerHandID**
- PinchGate Open-Streak 8 fps: 2 Frames statt 1, sonst ein Rauschen öffnet. **→ 1.5.18 pinchOpenNeed**
- Relativzeiger nach Freeze: ersten Sample als Rebase, nicht als Sprung. **→ 1.5.18 pointerNeedsRebase**
- Continuity-Preset: 720p @ max fps des Formats, nicht 1280×800 @ 8 wenn 960×540 @ 15 da ist. **→ 1.5.18 formatScore**
- AX `setPosition` Fail-Streak zählt coalesced Writes, nicht Ticks.
- Palm-Jitter-Meter im Testmodus (px/s), Kalibrierung der Totzone.
- Zwei-Hände-Zoom an der Cursorposition, nicht am Fenstermittelpunkt (steht schon oben, bleibt der große).
- Pro-App-Profile bleiben der große Sprung (Finder-Wurf = Datei).
- Kamera-Picker im Control Panel (Built-in / Continuity), nicht nur Banner. **→ 1.5.19 CameraChoice**
- Pinch-Klick Down/Up split bleibt der größte Feel-Fix nach Rebase. **→ 1.5.19**
- SpaceMap RMS-Qualität vor „fertig“.
- Testmodus Slot-TTL.
- Hover-Ring 80 ms vor Gate. **(Down sitzt — Ring wäre nur Optik)**
- Kalman nur Fling.
- Peace+Palm-Y Scroll ohne Screenshot.
- Clutch: Faust halb offen = Zeiger freeze.
- Dominant-Hand aus den ersten 30 Faust-Frames.
- Blick weg / kein Gesicht → Auto-Idle (Vision face count).
- **Ghost-Hände statt `[]` während slotHold.** **→ 1.5.19** (One-Shots **→ 1.5.20**)
- **Pinch-Pose-Hold dt-skalieren.** **→ 1.5.19 pinchPoseHoldNeed**
- Zwei-Hände-Zoom am Cursor, nicht Fenstermittelpunkt (Resize-Anker `cursor`). **→ 1.5.20 resizeOrigin**
- Klick-Down bewegt sich mit: `pressMouse` folgt `moveCursor` solange gedrückt (Buttons unter dem Zeiger). **→ 1.5.20 dragged**
- Testmodus zeigt Ghost: HUD „S1 Ghost 0,4 s“ wenn Observation fehlt, Slot noch da. **→ 1.5.20**
- Accessibility-Poll nach TCC-Reset, Banner statt einmaliger Check. **→ 1.5.20 accessDropped**
- Continuity-Gain als sichtbarer Slider neben Zeiger-Empfindlichkeit.
- SpaceMap 1-Punkt-Nachkalib wenn Residual > 480 für 2 s — nur die driftende Ecke.
- Grab-Abort nach Ghost: Overlay-Text „Hand unsicher“ nur im Testmodus, Armed bleibt still. **→ 1.5.21**
- Fling-Kalman 2D nur auf pinchTrail, Cutoff 8 Hz — Diagonalfalschwürfe.
- App-Profile: Finder-Wurf = Datei, Safari-Wurf = Tab (AX-Rolle).
- Gemeinsame Capture-Session mit Aegis (eine TCC, zwei Consumer) — eigenes kleines Framework, kein Code-Kopieren.
- HUD-Skelett nur Actor-Hand, 12 Gelenke, Overlay-Monitor.
- Zwei-Stufen-Pinzette: 80 ms Hover-Ring bevor Down (Optik zu 1.5.19 Down). **(nach Gate → 1.5.25)**
- **Palm-Speed vor Down:** wenn `trailMotion` während pinchClickMin > 0,20, kein pressMouse (verhindert Down mitten im Flick). **→ 1.5.21 pinchDownBlocked**
- **Ghost-Ring gestrichelt** auf dem Overlay-Monitor, nicht nur Preview-Chip. **→ 1.5.21**
- **Klick-Warp auf HUD-Cursor** vor Down, nicht lastPosted. **→ 1.5.21 pressMouse(at:)**
- **Klick-Hit-Test AX:** nach Down das AXUIElement unter dem Cursor merken, Up nur dort (sonst landet der Up auf dem Fenster dahinter). **Punkt → 1.5.25; Element bleibt**
- **Mission Control:** drei offene Finger nach oben, Totzone gegen Wisch.
- **Magnetischer Fensterrand** während Drag (12 px), analog Andocken ohne Wurf.
- **Per-Monitor Homographie** (4 Ecken je Screen) — Relativzeiger nur als Fallback.
- **Clutch-Geste sichtbar:** halb offene Faust = Zeiger freeze, HUD „CLUTCH“.
- **Dominant-Hand aus den ersten 30 Faust-Frames**, Prefs-Toggle bleibt Override.
- **Blick weg / kein Gesicht → Auto-Idle** (Vision face count, kein Aegis-Match).
- **Fling-Kalman 2D** nur pinchTrail, Cutoff 8 Hz.
- **App-Profile:** Finder-Wurf = Datei, Safari-Wurf = Tab (AX-Rolle).
- Continuity-Gain als sichtbarer Slider neben Zeiger-Empfindlichkeit.
- SpaceMap 1-Punkt-Nachkalib wenn Residual > 480 für 2 s.
- Peace+Palm-Y Scroll ohne Screenshot.
- SpaceMap RMS vor „fertig“.
- Hover-Ring 80 ms vor Gate.
- Kalibrierung blockt Armed außerhalb Testmodus (Hinweis ist da).
- **AX-Up auf dasselbe Element wie Down** — sonst klickt der Up durch aufs Fenster dahinter, wenn der Ring während Hold wanderte.
- **Fling-Pfeil-Ghost** während Pinch-Drag über flingMinSpeed, damit der Wurf nicht überrascht.
- **Peace-Hold-Ring** analog Kill-Switch Prozent, nicht nur lastAction.
- **Zwei-Hände-Kill nur live**, Ghost-Palmen schon 1.5.20 — Test: zwei Ghost-Open dürfen nicht Not-Aus.
- **Cursor-Clutch Prefs:** Schwelle palmStill als Slider, nicht nur Konstante.
- **Not-Aus-Flash unabhängig vom Overlay-Monitor** — Kill auf Display 2 unsichtbar wenn isPrimary-only.
- **Klick-Magnet auf Traffic-Lights** (Schließen/Mini/Zoom) bis 0,30 Handbreiten — Pinch auf dem Punkt bleibt Klick, wird nicht zum Titelleisten-Drag.
- **Cmd/Opt-Klick über zweite Hand:** Peace = Cmd, Point = Opt, Faust = Shift (1.6-Pfad, hier noch nicht).
- **Fling-Richtung als HUD-Pfeil** in den letzten 80 ms vor Loslassen, nicht erst nach dem Wurf.
- **SpaceMap pro Monitor** mit 4 Ecken je Screen — Homographie-Switch wenn der Cursor den Screen wechselt.
- **Gemeinsame Kamera-Session mit Aegis** — eine TCC, zwei Consumer, Frame-Broker.
- **Hover-Ring 80 ms vor Gate-Schluss** (Optik; Down sitzt seit 1.5.19).
- **Testmodus Slot-TTL** `S1 0,4 s` wenn Observation fehlt.
- **Palm-Jitter-Meter** (px/s) im Testmodus, Totzone daraus kalibrieren.
- **Dominant-Hand aus den ersten 30 Faust-Frames**, Prefs-Toggle bleibt Override.

## Nicht tun

- Stimme / Diktat.
- Vollflächige Maus-Übernahme ohne Clutch.
- Mehr als zwei Hände.
- Aegis-Code in dieses Repo kopieren.
- `bugfix`-Branch. Nur `main`.
- VORSCHLAEGE schreiben, ohne den Diff im Target zu haben.
- Homographie als „fertig“ zählen, wenn Gauss nil liefert.
- Grab an `primary` weitergeben, wenn `pinchActorID` fehlt.
- Wurf-Speed über den ganzen Hold-Trail.
- Heranziehen über Mittelfinger-Spannweite.
- Vision auf Frames mit Luma < 0,08.
- PinchGate bei einem leeren Vision-Frame resetten.
- Luma-Skip als `hands: []` in die Engine schieben.
- Actor-ID nur über L/R, ohne Palm-Nähe.
- PinchGate wieder an Chirality hängen.
- Nach `abortGrab` sofort `placeCursor(primary)`.
- Fling-Fenster hart 120 ms bei 8 fps.
- Homographie-Residual nur Banner, voller Gain.
- Overlay-Skelett nach Dunkel unbegrenzt stehen lassen.
- AX-Timeout als Pinch-Loslassen.
- PinchGate Close-Vel hart −2 bei 8 fps.
- Wisch-`minDt` hart 160 ms.
- Nach `abortGrab` `preferred()` über L/R.
- Homographie `cursorSmooth = q` bei Hand-ID-Wechsel.
- Faust statt Pinch bei geschlossenen Spitzen (`ratio < 0,38`).
- Overlay.mark nach Luma-Skip weglassen.
- Landmark-1-Euro dt wieder auf 80 ms kappen.
- `bugfix`-Branch anlegen oder fortsetzen. Nur `main`.
- Slot-TTL wieder an `grabAbortHold` hängen.
- PinchGate Open-Vel hart −0,5.
- Faust-Scharf ohne `sawOpen`.
- `bestFormat` alles unter 24 fps verwerfen.
- Overlay.mark erst nach 0,4 s Dunkel.
- AX-Drag jeden Tick ohne Coalesce.
- `pointerHandID` während Freeze umschreiben.
- `emptySince` wieder an `grabAbortHold`.
- `sawOpen` ohne Timeout.
- `formatScore` wieder fps × 12 (360p@60 gewinnt).
- PinchGate Open wieder hart 3 Frames bei 8 fps.
- Nach Freeze `lastPalm` als dx weiterverwenden.
- AX-Fail 2× ohne `targetWindow` neu.
- Slot-IDs monoton ohne Reuse.
- mapSmooth hart 0,55 bei 8 fps.
- fps < 6 ohne Watchdog.
- Continuity trotz Frontkamera still, ohne Banner.
- 60 fps Format nicht auf 30 kappen (GPU).
- 1920×1080 wieder hart verwerfen.
- Leere Vision als `[]` während slotHold (Grab-Abort nach einem Dropout).
- Ghost-Hände als echte Pose: Peace/Not-Aus/Scharf aus Dropout.
- Pinch-Pose-Hold hart 2 Frames bei 8 fps.
- Klick Down+Up erst beim Loslassen, ohne pressMouse.
- `moveCursor` während Down als `mouseMoved` (Buttons verlieren den Druck).
- Zwei-Pinzetten-Scale um Fenstermitte statt Cursor.
- TCC-Verlust still, ohne Banner.
- Down ohne Warp auf lastPosted/Hardware-Maus.
- Palm-Speed ignorieren und mitten im Flick Down.
- „Hand unsicher“ im Armed-HUD.
- Ghost-Ring solid auf dem Overlay-Monitor.
- Nach Down `lastPalm` 120 ms alt lassen (erster Dragged teleportiert).
- `pinchBecameDrag` vom Pinch-Start messen (Zielen = Fenster-Greifen).
- Peace als Wischen (`openScore ≥ 2`).
- Ghost/Luma-Skip ohne `pointerNeedsRebase`.
- Not-Aus mit Palmen am Bildrand (Knie/Schulter).
- Kill-Windup ohne `moveCursor` (HUD-Cursor ≠ Hardware).
- Grab während Kill-Windup kleben lassen.
- `bugfix`-Branch anlegen oder fortsetzen. Nur `main`.
- Still-Clutch während Pinch/Down (Cursor tot nach Klick).
- Homographie ohne `mapFollowMul` (Kalib = linear-jitterig).
- Cursor während pinchClickMin frieren (Gate-Rolle = Start-Rolle, Zielen tot).
- `pinchClickMaxPx` vom Pinch-Start (Zielen = „Cursor wanderte“).
- Still-Clutch sofort nach Loslassen (Hand ruht 0,22 s → tot).
- Down auf Fensterfläche während Hold (`cancelPress` = Klick, dann Drag).
- 5× `ElementAtPosition` pro Tick.
- Dock/Menüleiste als Fenster-Drag.
- Escape ohne Pinch-Cancel.
- Fenster-Drag ohne Rand-Magnet.
- Traffic-Magnet unsichtbar.

# Helios

Native macOS-App: Gestensteuerung über den Kamera-Livestream, holografisches HUD, Fenster- und Cursorsteuerung.

Privates Repo. Copyright © 2026 Tony Rogers. Alle Rechte vorbehalten — siehe `LICENSE`. Keine Open-Source-Lizenz.

Ziel: **macOS 14+**, **Apple Silicon**, **arm64**. Aktuell **1.5.146**.

## Start

**Nur Helios.dmg** (macOS-Disk-Image). Nicht *Source code (zip)* / *tar.gz* — das ist Quelltext, räumt keine Rechte ein, ist nicht die App.

1. `Helios.dmg` laden. Rechtsklick → Öffnen (kein HTML, nicht entpacken)
2. Helios nach **Programme** ziehen — nicht aus dem Image starten
3. Erster Start: **Systemeinstellungen → Datenschutz & Sicherheit → Trotzdem öffnen**
4. Rechte: Kamera, Bedienungshilfen, Eingabeüberwachung. Nach jedem Update Schalter **aus und wieder an**

GitHub erzeugt automatisch *Source code (zip)* / *tar.gz*. Nicht laden.

## Gesten

| Geste | Wirkung |
|---|---|
| Faust halten | Scharf schalten (bevorzugte Hand) |
| Offene Hand bewegen | Cursor (Trackpad: heben = neu ansetzen) |
| Pinzette kurz | Klick (nur wenn der Cursor still blieb) |
| Pinzette 0,55 s halten | Rechtsklick (kein Button-Lock) |
| Zwei Pinzetten in 0,32 s | Doppelklick |
| Pinzette oder Faust + ziehen | Fenster verschieben |
| In die Papierkorb-Ecke ziehen und loslassen | Fenster zu / Finder-Auswahl in den Papierkorb |
| Werfen nach oben | Wegwerfen |
| Werfen nach unten | Minimieren |
| Werfen nach links/rechts | Andocken |
| Pinzette + zu sich ziehen | Fenster füllen |
| Zwei Pinzetten | Skalieren |
| Offene Hand waagerecht wischen | App wechseln (nicht während Cursor-Gain) |
| Peace halten | Fensteraufnahme auf den Schreibtisch |
| Daumen hoch | App hervorholen |
| Beide Handflächen | Not-Aus → Idle (erst Faust macht wieder scharf) |
| Eine offene Hand zur Kamera | Not-Aus (Palm-Reach, nicht die Lock-Hand) |
| Zweite Faust 0,35 s während LOCK | Lock umlegen |
| Zweite Faust oder ⌘. | Pinch abbrechen (kein Klick) |

**Testmodus** (⌘T): Erkennung anzeigen, keine Systemaktionen.

Aktive App bekommt einen Umriss. HUD liegt auf jedem Monitor. Keine Stimme.

## Bau

Xcode 26/27, macOS 26 SDK:

```
xcodebuild -project macos/Helios.xcodeproj -scheme Helios -configuration Release ARCHS=arm64
swift macos/HeliosTests/CoordTests.swift
```

GitHub Actions legt bei jedem Push auf `main` eine `Helios.dmg` als Release ab.

Ad-hoc-Signatur. Developer ID + Notarisierung braucht ein Apple-Zertifikat — ohne das muss der Nutzer nach jedem Update die TCC-Schalter neu setzen.

**1.5.146:** Finger-Paare. Tip-Conf. Frozen-Write tot. MARKETING_VERSION 1.5.146 (Build 165).

**1.5.145:** Fingerkette hart. Conf-Gate. Chirality hält One-Euro. ROI-Totpfad. MARKETING_VERSION 1.5.145 (Build 164).

**1.5.144:** Vision 4 Slots. Fingerkette. Span-Veto Prop. Smooth-Reset 0,35. MARKETING_VERSION 1.5.144 (Build 163).

**1.5.143:** Sparse/Close-Hand. Bind denser. Gitarre 0,29 tot. MARKETING_VERSION 1.5.143 (Build 162).

**1.5.142:** ROI tot. Gitarre-Span Filter. Overlay roh. Smoother-Reset 0,22. Builder macos-15. MARKETING_VERSION 1.5.142 (Build 161).

**1.5.141:** Bind lastS1 nearer unter 0,28. Freeze-Clock nur während Freeze. Scale-Pass mappt ROI. MARKETING_VERSION 1.5.141 (Build 160).

**1.5.140:** ROI Thaw Prop, Gitarre nicht S1. Freeze TTL 400 ms. S1 Laterality Lock. Coast Click 180 ms. MARKETING_VERSION 1.5.140 (Build 159).

**1.5.139:** ROI Thaw Same-Tick Full / Expand-Hit. FullAfter 24 fps nach 2 Expand. Bind Hands-First. MARKETING_VERSION 1.5.139 (Build 158).

**1.5.138:** Overlay t>1 Extrapolate lastVel. Lerp 24 fps. ROI Thaw 2 Frozen-Miss. Scale-Ring nur S1. MARKETING_VERSION 1.5.138 (Build 157).

**1.5.137:** Overlay-Skelett 90 Hz Bezier zwischen Vision-Poses. palmScale Wrist–MCP Median + Span-Veto. Scale Median 8 Ticks. MARKETING_VERSION 1.5.137 (Build 156).

**1.5.136:** ROI Thaw nach FullNext. Coast-ROI folgt Predict. FullNext unter Lock. MARKETING_VERSION 1.5.136 (Build 155).

**1.5.135:** ROI FullNext 8 fps. Empty-Coast hält lastS1. Kalman Clamp Hand nicht Prop. Pulse tot → Vision warpt. MARKETING_VERSION 1.5.135 (Build 154).

**1.5.134:** WarpWriter Token FILL/VISION, Chip Compile. Coast Need Auto, Vel-Decay, Return-Cap. ROI Freeze Lock/Coast. MARKETING_VERSION 1.5.134 (Build 153).

**1.5.133:** Coast-Return hält lastVel. lastS1Palm folgt Predict. Overlay-Knochen palmCoastShift. Not-Aus injectCursor skippt CGWarp. Ghost-Coast remaining ≤ 0. MARKETING_VERSION 1.5.133 (Build 152).

**1.5.132:** Press-Pfad skippt wie Follow. Fill während Klick. Coast-Ghost lastVel. Coast Pref 1–4. Ghost Alpha 50/35. Writer-Chip FILL/VISION. MARKETING_VERSION 1.5.132 (Build 151).

**1.5.131:** S1-Miss 2 Ticks Ghost, lastS1 nicht von S2. Ein Warp-Writer — Vision skippt CGWarp wenn CADisplayLink armed. MARKETING_VERSION 1.5.131 (Build 150).

**1.5.130:** Scale-Jump-Veto 0,12 — Gitarre stiehlt S1 nicht. Fill-Cap je Display-UUID. PalmSlot Kalman. DisplayLink je Screen-Hz. Pad-Slider zeigt Schirmname. MARKETING_VERSION 1.5.130 (Build 149).

**1.5.129:** Fill-Cap Slider Laptop/Studio. Pinch Click/Drag auf Cursor-px. Keep-Bit je Slot — Gitarre 0,29 stiehlt S1 nicht. MARKETING_VERSION 1.5.129 (Build 148).

**1.5.128:** CADisplayLink 120 Hz vsync. palmScale Kalman, Pad je Display-UUID, Keep je Hand, Pinch Click/Drag-Band, Fill-Cap Laptop/5K. MARKETING_VERSION 1.5.128 (Build 147).

**1.5.127:** Relativ-Pfad lastScreenID folgt dem Zielschirm. Overlap auto, Faust 2-Frame, Reanchor, Dead-Man/Fling/Wischen-Prefs aus bugfix. MARKETING_VERSION 1.5.127 (Build 146).

**1.5.126:** Relativ-Pfad schrieb lastScreenID nie — destClampMap Latch tot. slotAllocMinID(keep:true) mintete Gitarre 0,29 als S1. MARKETING_VERSION 1.5.126 (Build 145).

- **`screenKeySeed`.** Relativ lastScreenID aus destEdgeNearest.
- **`slotAllocMinID(keep: false)`.** Neu-Alloc 0,29 = Prop S2.

**1.5.125:** destClampMapHolds mit leerem currentScreenID klemmte den 5K auf die Laptop-Map. clampMapped las cursorSmooth. Hart 0,28 zitterte S1/S2. MARKETING_VERSION 1.5.125 (Build 144).

- **`destClampMapHolds` Latch.** 2 Screens ohne currentScreenID: Map tot. Punkt auf dem 5K: Map keine Mauer.
- **`clampMapped` Zielpunkt.** Nicht cursorSmooth.
- **`palmHandScaleHyst` 0,03.** Keep 0,29 S1.
- **`destEdgeSkipPref` 40–240 ms.** ControlPanel Naht-Hold.

**1.5.123:** Gitarre blieb S1 (Observation-first). 40 px Cocoa-Overlap max-Interior Laptop-Pad. SpaceMap destBounds fromCocoa, destEdge Hardware. MARKETING_VERSION 1.5.123 (Build 143).


- **`slotAllocMinID` / `slotBindSkipsProp`.** Prop nie S1.
- **`pointerKeepPrefersHand`.** Pool S1 vor Observation-first.
- **`destEdgeNearest` min Interior < Gap → größerer Schirm.**
- **`destEdgeScreenHolds`.** displayTick 160 ms Zielschirm.
- **`visQuartz` / SpaceMap.load `quartzBounds`.**

**1.5.122:** destClampScreen `screens.first` klemmte den Cursor auf den Laptop, 15 px auf dem 5K. Prop+Hand war immer Full (`liveCount >= 2`). MARKETING_VERSION 1.5.122 (Build 142).

- **`palmROISlotPalm` Prop → S2.** Nur Prop allein Full.
- **`palmROISecondHands`.** Full nur ≥2 echte Hände.
- **`destClampScreen` destEdgeNearest.** `screenSeamHolds` gibt die Seam ab.
- **`destEdgeNearest` Overlap:** größerer Schirm.

**1.5.121:** ROI-Crop um Gitarre/Rumpf (S1 scale ≥ 0,28) fraß die echte Hand. 8 fps hielt den Crop, zweite Hand blieb im S1-ROI. 1.5.119 Vollbild fraß den Tick. MARKETING_VERSION 1.5.121 (Build 141).

- **`palmScaleIsHand` 0,035…0,28.** Prop-S1: SlotPalm nil → Full.
- **`palmVisionUsesROI` true.** Crop nur um Hand.
- **`palmROISecondNils` immer true.** 8 fps zweite Hand Full.

**1.5.120:** destEdgeSkip 80 ms starb vor dem Continuity-Tick. screenBlend zog den Cross 120 ms zurück. Predict schoss über die Seam. screenKey first-contains stahl den 5K. toward-Noise wählte die falsche Kante. 8 fps palmVel roh. MARKETING_VERSION 1.5.120 (Build 140).

- **`destEdgeSkipHold`.** 160 ms, max(pref, 1,25·frameDt).
- **`screenBlendSkipsCross` / `pointerPredictSkipsCross`.** Cross = Snap.
- **`screenKey` innerster.** Analog destEdgeNearest.
- **`destEdgeTowardOf` 4 px. `palmVelScreenEMA`. `quartzBounds` = CGDisplayBounds roh.**

**1.5.119:** Overlay-Zeichnung nie kaputt — `vis()`/`fitted()` seit 1.5.40 gleich. ROI-Crop ab 1.5.67 sucht nur um S1. Continuity 8 fps hält den Crop (1.5.92). Gitarre/Raum wird S1, echte Hand liegt außerhalb. 1.5.117-Remap half nicht, wenn Punkte schon Bildraum waren. 1.6 und 1.5.66: Vollbild. MARKETING_VERSION 1.5.119 (Build 139).

- **`palmVisionUsesROI` false.** `regionOfInterest` immer 1×1.

**1.5.118:** LICENSE Alle Rechte vorbehalten. DMG ohne Ad-hoc auf dem Image, plus Helios.zip. MARKETING_VERSION 1.5.118 (Build 138).

**1.5.117:** Overlay-Skelett spannte das ganze Kamerabild, die echte Hand saß unten rechts. Vision-Punkte unter `regionOfInterest` blieben 0…1 der ROI, Overlay und SpaceMap lasen Vollbild. Palma sprang in die Bildmitte, Slot wurde S2, Pose Faust. MARKETING_VERSION 1.5.117 (Build 137).

- **`visionPointFromROI`.** Crop-Punkte → Bild, Full-ROI Identität.
- **`visionROIMap`.** Nur wenn die BBox aus der ROI ragt — Image-space nicht doppelt mappen.
- **HandTracker** mappt vor Slot, Smoother, Overlay.

**1.5.116:** Maske, Fensterwechsel und Not-Aus weiter in 1.5.114/115. HUD-Umriss kam von CGWindowList unter dem Cursor, nicht vom gezogenen Fenster. Fill coasterte unter 28 px/s. 3 Finger + 1,35× Palma zählte die 40°-Kralle. MARKETING_VERSION 1.5.116 (Build 136).

- **Grab-Maske = AX-Dest.** Outline nur Hold/Grab. Focus-PID hält ohne Bewegung.
- **displayTick** ohne Coast unter 28 px/s.
- **Not-Aus:** 4 Finger, PIP/DIP > 18°, Span < 1,52× Palma nicht extended.

**1.5.115:** destEdgeCrosses first-contains stahl den 5K analog destEdgeNearest vor 1.5.113. Seam-Jitter 1 px stotterte Fill. FillAxis ignorierte den Pad-Slider. MARKETING_VERSION 1.5.115 (Build 135).

- **`destEdgeCrosses` innerster.** Überlapp Laptop/5K kein first-contains.
- **`destEdgeSkipNow` 80 ms.** Engine Kamera, Relativ, Fill.
- **`destEdgeFillAxis(pad:)`.** 5K-Slider. displayTick bleibt destEdgeFill (X+Y).

**1.5.114:** 1.5.111–113 ließen Maske, Kamerastopp-Focus und Not-Aus. Snap schrieb Cocoa auf AX. Overlay pollte die Maus ohne Kamera. 2D-PIP sah die Kralle zur Kamera als gerade. MARKETING_VERSION 1.5.114 (Build 134).

- **`snapFocused` Quartz.** visibleFrame → AX ohne Y-Flip. Scale-Anker Quartz.
- **Kein Focus-Poll bei Kamera aus.** Fill nur Frame < 0,35 s. AX-Timeout greift keinen Nachbarn.
- **PIP/DIP > 22° oder Finger < 1,35× Palma** nicht extended.

**1.5.113:** destEdgeNearest first contains stahl den 5K. FillAxis ohne toward. HasNeighbor toward=0 tot. MARKETING_VERSION 1.5.113 (Build 133).

- **`destEdgeNearest` innerster.** Überlapp: tieferer/größerer Schirm, nicht screens.first.
- **`destEdgeFillAxis` toward + NeighborMul.** Inbound frei, Void dämpft.
- **HasNeighbor toward≈0 nearer-edge.** Seam still Gain 1.
- Tests + MARKETING_VERSION 1.5.113 (Build 133).

**1.5.112:** destEdgeStep dämpfte 20 px vor der Seam (Kamera-Tick, FillToward sitzt am Fill). Coast-τ ohne toward. hypot-Teleport 0-setzte Y. Pad-Fallback 1440. MARKETING_VERSION 1.5.112 (Build 132).

- **`destEdgeHasNeighbor` / `destEdgeNeighborMul`.** Seam Gain 1, Void dämpft. Pad ≠ Lead.
- **Coast toward + TeleportX/Y.** Inbound τ voll. X-JUMP lässt Y-Coast.
- **PadWidthOf [] = 2560.** Clamshell + 5K nicht Pad 36.
- **`destEdgeChipOf` nearer-edge + screens.** Seam kein EDGE, Void EDGE.
- Tests + MARKETING_VERSION 1.5.112 (Build 132).

**1.5.111:** Tests grün, xcodebuild tot: `palmLateralityCode` ohne `right:` in HandTracker/GestureEngine. MARKETING_VERSION 1.5.111 (Build 131).

**1.5.110:** PIP-Biegung war Innenwinkel (gerade = 180°), also jede offene Hand tot. destEdgeFill-Tests noch auf min(left,right)=192, 1.5.108 dämpft nur Outbound. MARKETING_VERSION 1.5.110 (Build 130).

- **PIP-Beugung = Streck-Deflexion.** Gerade 0°, 40°-Kralle nicht extended. Schwelle 32°.
- **Inbound Fill ungedämpft**, Outbound 0,48. Tests an `toward` angepasst.

**1.5.109:** Latest hing bei 1.5.99, weil GestureTests seit 1.5.100 nicht kompilierten. AX-Maske Y-invertiert. Display-Fill ohne Kamera. Not-Aus an 40°-Kralle. MARKETING_VERSION 1.5.109 (Build 129).

- **AXPosition ist Quartz.** Grab-Offset und Fenster-Match ohne Cocoa-Flip. HUD-Umriss = gezogenes Fenster.
- **displayTick** nur bei laufender Kamera. Session-Stopp löscht lastMapped — kein Coast in fremde Fenster.
- **PIP-Biegung > 28°** zählt nicht als offen. Not-Aus braucht gestreckte Finger, nicht die Kralle.
- Tests: `right:`-Label, keine Redeclaration `snapped`/`laptop`/`kept`.

**1.5.108:** destEdge min(left,right) dämpfte Inbound — Cursor kroch nach 5K-Landung. FillToward Lead 48 < Pad 64, Rückweg tot. Gap kein Cross. Chip-Cap reordert. MARKETING_VERSION 1.5.108 (Build 128).

- **`destEdgeMulX/Y(toward:)`.** Nur die Kante in Bewegungsrichtung. Inbound = 1.
- **`destEdgeFillLead` / `destEdgeNearest` / Gap-Cross.** 5K Lead 80. Lücke ≤ 32 px.
- **`overlayChipCap` Original-Lage.** HUD ForEach `id: \.offset`.
- Tests + MARKETING_VERSION 1.5.108 (Build 128).

**1.5.107:** destEdge inset −8 stahl 5K an der Seam. destEdgeStep ignorierte Slider. Cross dämpfte Laptop→5K. Laterality +0,10 zu schwach. Chip prefix droppt JUMP. MARKETING_VERSION 1.5.107 (Build 127).

- **`destEdgeScreenAt` exact + nearest.** **`destEdgeCrosses` / `destEdgeFillToward`.** Seam ohne Mauer.
- **`destEdgeStep(pad:)`** = destEdgePadNow. **`slotLateralityPrefers`.** Match-Slot sperrt Mismatch.
- **`overlayChipKeep`.** Danger zuerst, unique.
- Tests + MARKETING_VERSION 1.5.107 (Build 127).

**1.5.106:** destEdge steal=Laptop auf 5K. HUD-Stack > 6. bindSlot nur Palm-Dist. MARKETING_VERSION 1.5.106 (Build 126).

- **`destEdgeScreenAt` / `destEdgePadAt`.** Screen unter dem Cursor. Teleport-Cap und ControlPanel.
- **`overlayChipCap` 6 + `overlayChipTone`.**
- **`slotLateralityDist`.** Mismatch +0,10.
- Tests + MARKETING_VERSION 1.5.106 (Build 126).

**1.5.105:** claimed.contains vor Bind = S1↔S2. OCC lastTip freeze = Phantom-Klick. NSScreen.main Pad am 5K. MARKETING_VERSION 1.5.105 (Build 125).

- **`palmLateralityClaimFlips` / `palmLateralityTakes`.** Bind zuerst, zweite Hand Unknown.
- **`fingerOcclusionFollows` / `pinchClickAbortsOcc`.** Tip folgt Palm. HUD `kein Klick — OCC`.
- **`destEdgePadWidthOf` / `destEdgePadNow`.** Max-Screen, steal live.
- Tests + MARKETING_VERSION 1.5.105 (Build 125).

**1.5.104:** Occlusion lastTip/DIP ohne Gate = Phantom-Pinch. Relativ nach Dropout Hold. JUMP-Atem-DC. Vision-Flip 1 Tick. MARKETING_VERSION 1.5.104 (Build 124).

- **`fingerOcclusionFresh` / `Confirm`.** TTL 0,40 s, 2 Ticks, DIP kein Tip. HUD `OCC`.
- **`cursorWarpSnapsRestore` Relativ** nach Dropout > 0,80 s.
- **`palmHighpassMutesJump`.** Slow=dx.
- **`palmLateralityDebounce` 3 Ticks.**
- Tests + MARKETING_VERSION 1.5.104 (Build 124).

**1.5.103:** jointConfEMA restored Tips = Phantom-Pinch. Slider 24 vs live Pad 64 unsichtbar. USB-WiFi-String = USB. MARKETING_VERSION 1.5.103 (Build 123).

- **`jointConfRestores`.** Tips nicht restore.
- **`destEdgePadLiveChip`.** `24 px · PAD 64`.
- **`continuityIsUSB` Wi-Fi-Veto.**
- Tests + MARKETING_VERSION 1.5.103 (Build 123).

**1.5.102:** Warp-Hold Deadlock nach Restore. mapped Snap auf q. Relativ bleibt Hold. MARKETING_VERSION 1.5.102 (Build 122).

- **`cursorWarpSnapsRestore`.** mapped Teleport Snap auf q vor Hold.
- **`cursorWarpRestoreOf`.** lastMapped unangetastet. MUTE 1 Tick.
- Tests + MARKETING_VERSION 1.5.102 (Build 122).

**1.5.101:** Warp-Hold freeze ohne JUMP. Hold-Release 64 px Coast. USB nur uniqueID. MUTE 11 ms. L/R unsichtbar. MARKETING_VERSION 1.5.101 (Build 121).

- **`palmWarpHoldJumps` / `applyWarpHold`.** Freeze = JUMP, Fill mute.
- **`palmWarpHoldReleaseJumps`.** Hold-Release Teleport.
- **`displayTickMutesJump(held:)`.** MUTE bis Release.
- **`palmVelChip` `JUMP · MUTE`.** **`palmLateralityChip` `L`/`R`.**
- **`continuityIsUSB` modelID + UVC + `transportType` FourCC.**
- Tests + MARKETING_VERSION 1.5.101 (Build 121).

**1.5.100:** Fill nach JUMP denselben Tick. palmVelAt Sentinel 0. Vision L/R Flip S1↔S2. destEdgePad Pref ohne Slider. Joint-Conf raw Floor. Continuity USB unsichtbar. MARKETING_VERSION 1.5.100 (Build 120).

- **`displayTickMutesJump`.** Fill 1 Frame tot nach JUMP.
- **`palmVelAtOf` nil.** **`palmLateralityLock`.** destEdgePad Slider 24–160.
- **`jointConfEMA`.** HUD `USB` / `WIFI`.
- Tests + MARKETING_VERSION 1.5.100 (Build 120).

**1.5.99:** Ghost hielt Vel ohne TTL. Dropout-Restore Teleport. Fill lastMapped2 schoss trotz Vel 0. MARKETING_VERSION 1.5.99 (Build 119).

- **`palmVelScreenFresh` 0,40 s.** Keep stale → Vel 0.
- **`palmVelScreenTeleport` 4× Pad.** HUD `JUMP`.
- **`palmMappedPair`.** JUMP lastMapped2 = current. Fill-Delta 0.
- Tests + MARKETING_VERSION 1.5.99 (Build 119).

**1.5.98:** Actor-Switch hielt S1-Vel. lastMapped Teleport. Scale 2→1 Pinch-Klick. MARKETING_VERSION 1.5.98 (Build 118).

- **`palmVelScreenResets` / `palmMappedClears`.** HUD `VEL 0`.
- **`scaleAbortClick` lastScrollAt.** destEdgePadPref 24–160.
- Tests + MARKETING_VERSION 1.5.98 (Build 118).

**1.5.97:** Slow ohne TTL. Dropout Restore = S1-Atem als Bias. MARKETING_VERSION 1.5.97 (Build 117).

**1.5.96:** Center Stage: Control-Mode `.app` vor dem Setter, sonst NSException auf macOS 27 (`_setCenterStageEnabled`). HeliosCatch. MARKETING_VERSION 1.5.96 (Build 116).

**1.5.95:** CI GestureTests: `CACurrentMediaTime` ohne QuartzCore. MARKETING_VERSION 1.5.95 (Build 115).

**1.5.94:** Ghost wischte Hochpass. AX 2,5 px. Ring Alloc-Sturm. Enhance 1920→960 Tag. Timer .default. destEdge 40 auf 5K. Warp-X ≠ EDGE. PREDICT ohne HUD. Pinch-Hold bei Wrist-MAD.

- **`palmHighpassResets` Ghost hält. `palmHighpassLoad` je Actor.** HUD `α 0,15 S1`.
- **`axHitCacheDist` 16 px / `ringRebuilds` / `enhanceDownscales` / Timer `.common` / `destEdgePadOf` / `scaleMoved(dt:)`.**
- **`pointerPredictChip` HUD / `cursorWarpCapX(width:)` / `pinchHoldAborts`.**
- Tests + MARKETING_VERSION 1.5.94 (Build 114).

**1.5.93:** Slot −1 ohne HUD. Portrait-Buffer .right bei 0° Capture = 90° Palm. Hochpass eine Slow-State. AX 180 ms. Ring unbounded.

- **`ringSlotStealChip` / `formatStealChip`.** HUD `STEAL n`.
- **`visionBufferOrientation` / `palmHighpassResets` / `palmROILatchChip` / `ringSlotCap` 12 / AX TypeID.**
- Tests + MARKETING_VERSION 1.5.93 (Build 113).

**1.5.92:** Enhance wandelte 420f→BGRA. Slot −1 an Vision. Zwei-Hand-ROI tot bei 8 fps. Pinch-Open Frames. Ghost 1 Frame. Klappe AX tot. Hochpass ohne Slider.

- **`enhanceDestFormat` / `ringSlotStealDrops`.** Ping/Pong 420, Slot −1 drop.
- **`palmROISecondNils` / `pinchOpenHolds` / `overlayGhostPeakHold` / `invalidateAXProbe`.**
- **Atem-Hochpass-Slider 0,08–0,25.**
- Tests + MARKETING_VERSION 1.5.92 (Build 112).

**1.5.91:** Ring wandelte 420f→BGRA jede Frame. Werfen prüfte den Trail-Anfang. Klappe-auf ließ Continuity bei 8.


- **`visionTakesNative` / `ringCopyConverts`.** GPUFrameRing hält 420f/420v. COPY/Enhance-Skip nur Convert.
- **`flingFromTrail`.** Center-Dead am letzten Sample. `clamshellWakeReselects`. `pinchOpenNeedSec`.
- Tests + MARKETING_VERSION 1.5.91 (Build 111).

**1.5.90:** Fill-Coast ignorierte Bezel. Pinch 15 fps zwei Uhren. Dead-Man-HUD Gaze statt Faust. WARP 8 fps flackert. `bugfix` nicht mergen.

- **`displayLinkCoastTauAxis`.** Coast-τ × destEdge je Achse. X am Rand tot, Y frei.
- **`pinchClickNeed` ≥ Open × dt.** 15 fps 110 ms, nicht 90 ms vor Gate.
- **`deadManFistChip` `IDLE 1,2`.** `hudChipPeakHold` WARP 1 Frame. Hochpass-Pref. Reduce Motion. CS-Reconnect.
- Tests + MARKETING_VERSION 1.5.90 (Build 110).

**1.5.89:** Fill Passthrough schoss X auf den Nachbarschirm. Dead-Man 8 s nach Faust. USB-Hop. Atem. Klick nach Scroll. `bugfix` 1.5.8 Ideen auf main.

- **`destEdgeFillAxis`.** Fill-X am Rand, Y frei. palmVelScreen roh.
- **Dead-Man Faust 1,6 s.** Palm-Hochpass Engine. Close/Pose 15 fps wie 8.
- **USB-Hysterese 400 ms / Klick nach Scroll 180 ms.**
- Tests + MARKETING_VERSION 1.5.89 (Build 109).

**1.5.88:** Pinch-Ratio 15 fps wie 24. 420v Luma Nacht. Desk-View 4:3 Score −1. Enhance nach teurer Kopie. Down trotz zitterndem Wrist. WARP-Chip nur Math. Format-Chip ohne Copy.

- **`pinchWantOpen` Extra-Margin ab 15 fps.** `pinchOpenNeed` 15 fps = 2, nicht 3.
- **`luma420Lift` 420v Offset 16.** `enhanceSkipsCopy` > 8 ms.
- **`formatScore` 4:3** bis 1920×1440, Portrait Desk-View.
- **`pinchClickNeedsStill`.** Need allein reicht nicht.
- **`destHudChip` MAP≠STEAL → WARP → EDGE.** `formatCopyChip` `COPY` > 8 ms.
- Tests + MARKETING_VERSION 1.5.88 (Build 108).

**1.5.87:** 1.5.86 CI tot. `GestureTests.run()` redeclare `pred`. Swift-Overlay ohne `availableVideoCVPixelFormatTypes`.

- **`ptrPred`** statt zweitem `let pred`.
- **`availableVideoPixelFormatTypes`** ([OSType]), 420f → 420v → 422 → BGRA.
- Tests + MARKETING_VERSION 1.5.87 (Build 107).

**1.5.86:** Warp-Smooth hypot-fror Y mit X. Fill-Cap hypot-skalierte Y. HUD ohne MAP≠STEAL.

- **`cursorWarpHoldsSmoothOf` je Achse.** Y-Flick am X-Teleport bleibt.
- **`displayLinkCursorOf` Clamp je Achse.** Fill-Y nicht hypot.
- **`destMapStealChip` MAP≠STEAL.** Relock-HUD.
- Tests + MARKETING_VERSION 1.5.86 (Build 106).

**1.5.85:** Continuity Preset clampte auf 8. Timer immer 90 Hz. Pinch 15 fps wie 24. ROI-Miss Full-Frame. AE 0,8 s. Warp-X ≠ destEdge. Kein Format-Chip.

- **Continuity ohne sessionPreset.** Built-in 720p. `lockFrameRate` Continuity 24 statt 30.
- **Timer-Retarget 8↔24.** Thermal hält Format 2 s unter 12 fps.
- **pinchClickNeed 15 fps interpoliert.** Tip-Floor 0,10. Faust-AE 1,2 s.
- **ROI-Miss 1,8×**, 8 fps kein Full-Pass. Warp-X = destEdgePad. Predict 1 Frame.
- **Format-Chip HUD** `420f 15–24` / `BGRA 8`. CS-Off Format nochmal. 422 vor BGRA.
- Tests + MARKETING_VERSION 1.5.85 (Build 105).

**1.5.84:** Continuity lockte hart 30 fps (Drop auf 8). Center Stage nach der Formatwahl.

- **`lockFrameLo` 15–30.** Range 1–30 atmet, nicht min=max 1/30.
- **Center Stage vor `bestFormat`.** `reselectFormat` zuerst CS.
- Tests + MARKETING_VERSION 1.5.84 (Build 104).

**1.5.83:** Continuity blieb 8 fps trotz FormatScore 15. 32BGRA, Timer 60 Hz, ROI 0,22, Warp-Hypot. Swift 6 `as? AXUIElement` immer true.

- **Native 420f.** Continuity 15–30, BGRA@8 verliert. luma420-Fallback.
- **Fill-Timer 90 Hz.** displayLinkTimerPeriod verdrahtet.
- **palmROI 0,10.** Kanten-Hand nicht tot.
- **Warp je Achse.** Y-Flick am X-Rand. Teleport nur 3× Cap.
- **`axElement` / `axValue` TypeID.** CameraSession `self.applyCenterStage`.
- Tests + MARKETING_VERSION 1.5.83 (Build 103).

**1.5.82:** GestureTests „24 fps Kalman = meas“ — palmKalmanUses folgt seit ≥ 0,012, k≈0,55. Test war Skip-Rest.

- **24 fps Kalman folgt.** Nicht meas-passthrough.
- Tests + MARKETING_VERSION 1.5.82 (Build 102).

**1.5.81:** CI tot (`displayLinkPeriodAdaptive` ohne `frameDt:`, `palmMad([Double])`). destEdge-Fixes aus 1.5.80 kamen nicht an.

- **GestureTests `frameDt:`.** palmMad explizit `[CGFloat]`.
- Tests + MARKETING_VERSION 1.5.81 (Build 101).

**1.5.80:** CI tot (`jointGain` Int−CGFloat). destEdgeMulOf × dt machte 8 fps Gain 1. destEdgeFill 24 fps 0,35². HUD hypot. Click-Lock dämpft. `let stepped` doppelt.

- **`destEdgeMulOf` räumlich.** 8 fps nicht Gain 1.
- **`destEdgeFill` passthrough.** palmVelScreen hat destEdge schon.
- **`destEdgeChipOf`.** HUD `EDGE X 8`. **`destEdgeApplies clickLocked`.**
- Tests + MARKETING_VERSION 1.5.80 (Build 100).

**1.5.79:** destEdgeVel skalar tötete Y am X-Rand. destEdgeStep während Pinch. Fill destEdge 11× bei 8 fps.

- **`destEdgeMulX` / `destEdgeMulY` / `destEdgeMulOf`.** Vel/Step je Achse.
- **`destEdgeApplies`.** Pinch/Drag ohne Rand-Gain.
- **`destEdgeFill`.** 8 fps skip zweites destEdge.
- Tests + MARKETING_VERSION 1.5.79 (Build 99).

**1.5.78:** HOLD Hypot schluckte X-Flick. destEdge min Ecke tot. 8 fps Rand träge. Coast τ fest. Relock Cap weg.

- **`palmStillOf` / `palmUnstillOf`.** Engine `freezeIfStill(dx:dy:)`.
- **`destEdgeDist` radial.** **`destEdgeMul(dt:)`** 8 fps Gain. HUD `EDGE 12`.
- **`displayLinkCoastTau`.** **`cursorWarpCapHold`** Relock 3 Frames.
- Tests + MARKETING_VERSION 1.5.78 (Build 98).

**1.5.77:** Pinch Need 1 nach Open. Fill+Kamera vsync. destBounds ohne ID. Fill-Cap je Tick.

- **`pinchCloseNeed(justOpened:)`.** Dropout dt ≥ 0,20 → Need 1.
- **`displayTickCoalesced` + PeriodAdaptive + `assumeIsolated`.**
- **`destClampMapHolds`.** ohne screenID nur 1 Screen.
- **`displayTickWarpShare`.** Floor / n Fills.
- Tests + MARKETING_VERSION 1.5.77 (Build 97).

**1.5.76:** Totzone Hypot schluckte X-Flick während Y atmete. destEdge nur Fill. Relock Warp 48.

- **`palmDeadOf(mad:)`.** Engine `deadNowX/Y`. Atem-Dead nur Y.
- **`destEdgeStep` / `destEdgeScreen`.** Kamera-Tick und Fill-Dest = stealScreen.
- **`cursorWarpCapScreenOf`.** Relock Map-Diagonale. HUD `EDGE`.
- Tests + MARKETING_VERSION 1.5.76 (Build 96).

**1.5.75:** Hypot-MAD hob Kalman-Q auf X und Y. Warp fest 48/96. Fill volle Vel am Bezel.

- **`palmMad` / `palmKalman(madX:madY:)`.** Engine `palmDeltasX/Y`. Atem-Q nur Y.
- **`cursorWarpCapScreen`.** Diagonale × 0,035.
- **`destEdgeMul` / `destEdgeVel`.** 40 px Pad, Floor 0,35.
- Tests + MARKETING_VERSION 1.5.75 (Build 95).

**1.5.74:** Fill ohne Reibung. Flick-Vel stale. Skalar-Kalman. Naht ohne Pad. HUD ohne HOLD.

- **`displayLinkCoast`.** Fill-Vel × exp(−t/τ), τ 55 ms.
- **`palmVelScreenKeep` / `palmVelScreenStale`.** MAD Rest + tot → Vel 0.
- **`palmKalmanStep` + 2×2 P + `palmKalmanResidualMul`.**
- **`screenSeamHolds` 24 px.**
- **`fpsLatchChip(frozen:)` HOLD.**
- Tests + MARKETING_VERSION 1.5.74 (Build 94).

**1.5.73:** Still-Clutch füllte Rest-Vel. Y-Vel × Screen-Breite. Warp-Hold ohne Screen-px. Kalman-Q nur Luma.

- **`displayTickBlocksStill`.** Fill tot während Atem-Clutch.
- **`displayLinkMappedScale` / `mappedScaleY`.** X = Breite, Y = Höhe.
- **`palmVelScreen`.** Fill aus lastMapped-Delta in Quartz-px/s.
- **`palmKalmanQ(mad:)`.** Zittrig folgt, still klebt nicht.
- Tests + MARKETING_VERSION 1.5.73 (Build 93).

**1.5.72:** Display-Link-Vel aus cursorSmooth compoundete. Freeze hielt vel. Fill während Hold. RMS nach Flick klebte. Timer-Rest verdoppelte den ersten Schritt.

- **`displayLinkVelCamera`.** Velocity lastMapped, nicht cursorSmooth.
- **`palmKalmanFreezeVel`.** Freeze → vel 0.
- **`displayTickBlocksHold`.** Fill tot während Occlusion/AE.
- **`palmDeadAdaptive` MAD.** Flick kein Extra-Dead.
- **`displayLinkRebase`.** Kamera-Tick lastDisplay = 0.
- Tests + MARKETING_VERSION 1.5.72 (Build 92).

**1.5.71:** Continuity Freeze auf Mean = Cursor tot. Kalman 24 fps aus. Lead×Kalman. Timer-Period. Dead 12 Samples / 8 fps.

- **`palmLowConfFloor(continuity)` / `palmTipConf` / `tipHeld`.** Continuity 0,10. DIP freeze. Tip vor Mean.
- **`palmKalmanUses`.** 24 fps blendet, vel bleibt.
- **`predictLeadAfterKalman`.** 8 fps 0,22 / 24 fps 0,10.
- **`displayLinkElapsed`.** Echter dt, Cap 1,5× Period.
- **`palmDeadWindow(dt)`.** 8 fps 6 Samples.
- Tests + MARKETING_VERSION 1.5.71 (Build 91).

**1.5.70:** Kalman ohne State = Warp nach Spike. palmDead fest. Low-Conf kriecht. 24 Hz hakte. Crop an S2 wenn S1 ghosted.

- **`palmKalmanKeepsState`.** rememberPalm(kalman.pos).
- **`palmDeadAdaptive`.** Jitter um Median, 0,008…0,020.
- **`palmLowConfFreeze` / `palmHolds`.** conf < 0,30 hält.
- **`displayLinkPeriod` 60 Hz + `displayLinkStepMul` 0,4.**
- **`palmROISlotPalm(keepPalm:)`.** S1 fehlt: Crop bleibt.
- Tests + MARKETING_VERSION 1.5.70 (Build 90).

**1.5.69:** Kalman-R fest 0,045 = Warp bei Occlusion. 8 fps ein Sample öffnet ohne Vel. ROI = lastHands.first (S2). Built-in Faust-AE dumpf. Warp-Floor 64 während AE klebt.

- **`palmKalmanR(tipConf)`.** Unsicherer Landmark = mehr Measurement-Noise.
- **`pinchOpenNeed(ratioOnly:)`.** 8 fps Vel 1, ratio-only 2.
- **`palmROISlotPalm`.** S1 vor Observation-first.
- **`fistAELockApplies(continuity)`.** Nur Continuity.
- **`cursorWarpFloor(lumaWarp:)`.** AE-Fenster Floor 96.
- Tests + MARKETING_VERSION 1.5.69 (Build 89).

**1.5.68:** ROI-Crop leer = Ghost. 8 fps ratio 0,59 ohne Vel = Klick. Faust ohne AE-Lock = Luma-Warp. Overlay-Tips in der Palme. Freeze ohne AE-Fenster = Cursor tot bei Licht.

- **`palmROIMissRetries` / `palmROIMissGoesFull`.** 24 fps 1,4× dann voll. 8 fps direkt voll.
- **`pinchWantOpen` 8 fps Extra-Margin.** Vel öffnet, 0,59 ohne Vel bleibt.
- **`fistAELock` 0,8 s.** **`palmKalmanFreeze` nur im AE-Fenster.** **`palmKalmanQ`.** **`tipOccluded`.**
- Tests + MARKETING_VERSION 1.5.68 (Build 88).

**1.5.67:** Pinch-Hold nach Gate bei 8 fps extra 125 ms. S3 nach Latch. Warp-Freeze vel=0. Vision volles Bild = False-Empty. Center Stage nach Sleep. Landmark 6,2 hängt am Flick.

- **`pinchPoseHoldNeed(gateClosed)`.** 8 fps Gate zu = 0 Extra-Frames.
- **`slotMintsNew` / `slotAllocCap`.** Latch: max S1/S2, kein Hue-Sprung.
- **`palmVisionROI`.** lastPalm ± 1,8 Scale; zweite Hand volles Bild.
- **`displayLinkVelocity(palmVel)`.** Warp-Freeze füllt aus Palm-Vel.
- **`oneEuroLandmarkCutoff` 8 fps 3,2.** **`cursorWarpFloor` Continuity 64.** **`fpsLatchChip` `8 Hz · LATCH`.** **`centerStageNeedsReassert`.** Close/Keep stetig mit palmScale.
- Tests + MARKETING_VERSION 1.5.67 (Build 87).

**1.5.66:** Engine-Filter warf Tracker-Ghosts weg — Latch tot, Pinch abort. Ghost wischte lastPoolIDs. Sparse kopierte Tips = Phantom-Pinch. pinchCloseNeed 2 bei 8 fps = 250 ms.

- **`tickKeepsGhost`.** Ghost trotz Floor.
- **`ghostKeepsPool`.** lastPoolIDs am Dropout.
- **`sparseMergeKeeps`.** nur Wrist/MCP.
- **`pinchCloseNeed` 8 fps = 1.** **`jointGain`.** **`twoHandClutchGain` 0,4.**
- Tests + MARKETING_VERSION 1.5.66 (Build 86).

**1.5.65:** Observation unter minConf wischte lastHands — kein Ghost, Overlay tot, S3. Warp 80 px klebte 8 fps Flicks. Cubic overshootete. Center Stage wanderte.

- **`trackerEmptyKeepsGhost` / `emitEmpty`.** kept 0 → Ghost wie leer.
- **`fingerSparseKeepsPalm`.** Wrist-only / MCP-Palm.
- **`cursorWarpCap` 3× Median, Floor 48.** **`palmKalman`.** **`centerStageOff`.**
- Tests + MARKETING_VERSION 1.5.65 (Build 85).

**1.5.64:** Warp gab `from` ohne Smooth-Write — displayTick kroch zum Dropout. DIP als Fake-Tip = Phantom-Pinch. Confidence-Floor → `releasePointer`.

- **`cursorWarpHoldsSmooth`.** Smooth + lastMapped freeze.
- **`fingerOcclusionTip` / `lastIndexTip`.** Letzter echter Tip vor DIP. Daumen analog.
- **`slotLatchEmptyKeepsPointer`.** 4 s kein `releasePointer`.
- Tests + MARKETING_VERSION 1.5.64 (Build 84).

**1.5.63:** Ghost 0,60 gab `[]` während S1 noch 4 s lebte. `releasePointer` wischte lastPalm. Steal-Timeout 1,2 s auf Ghosts = Idle. DIP nur wenn Tip nil — Phantom 0,22 blieb, Daumen fehlte.

- **`ghostHands` Default `slotLatch` 4 s.** HUD bis Latch.
- **`pointerStealTimesOut(ghosting:)`.** Ghosts kein LOCK tot.
- **`pinchOcclusionFloor` 0,40.** Phantom-Tip → DIP. Daumen-IP analog.
- Tests + MARKETING_VERSION 1.5.63 (Build 83).

**1.5.62:** expire 0,60 s und `slots.removeAll` löschten S1 nach Continuity-Dunkel. bindSlot mintete S3. preferred() nahm `hands[0]`. Homographie folgte 200 px Dropout. Index-Tip tot = unknown.

- **`slotLatch` 4 s.** Ghost 0,6 s, ID bleibt. **`slotKeepsID`.**
- **`slotLatchBind` / `slotReusesUnclaimed`.** Unclaimed S1 im Latch, kein S3.
- **`preferredNearest`.** Keep tot: lastPalm, nicht Observation-first.
- **`cursorWarpReject` 80 px.** **`fingerOcclusionHoldsDIP`.**
- Tests + MARKETING_VERSION 1.5.62 (Build 82).

**1.5.61:** preferred() scannte bei leerem Pool alle Hände — Freeze merkte sich die andere Palme, Reconnect stahl. `pointerHandID = first` sprang bei L/R-Flip. bindSlot 0,22 verlor S1 bei 8 fps. pinchActor nur trail.last.

- **`preferredKeepsPool`.** Leerer Pool: Keep-ID, nicht die andere Hand.
- **`pointerKeepInPool`.** Keep im Pool bleibt, nicht Observation-first.
- **`stealHoldsPalm`.** Freeze schreibt lastPalm nicht von der anderen Hand.
- **`slotBind(dt:)`.** 8 fps Slot-Bind 0,40. **`actorRebindRing`** pinchActor last-3.
- **`slotHue` S1 cyan / S2 amber.** Overlay-Knochen je Slot.
- Tests + MARKETING_VERSION 1.5.61 (Build 81).

**1.5.60:** pinchActor scannte bei leerem Pool alle Hände — andere Pinzette stahl. Reconnect-Bind 0,22 verlor Continuity 8 fps. Gate roh, Overlay glatt. Slot unsichtbar.

- **`pinchActorKeeps` / `pinchActorScanPool`.** Nur Lock-Pool. Rebind nur im Slot. Pool leer: abort, nicht die andere Hand.
- **`reconnectBind(dt:)` + last-3.** 8 fps Bind 0,40. lastPalm2 zweiter Ring.
- **`pinchGateUsesSmoothed`.** Close roh, Open geglättet.
- **`slotChip` S1/S2.** Overlay + HUD.
- Tests + MARKETING_VERSION 1.5.60 (Build 80).

**1.5.59:** Continuity 8 fps blieb 8 Hz, weil displayTick bei steal+dt≥80 ms tot war — auch mit Lock-Hand. actorMapped prüfte nur die alte Vision-ID. pinchActor stahl. Lock-Hand nah = Not-Aus. Overlay roh.

- **`displayTickBlocksSteal` nur Pool leer.** Lock-Hand: interpolieren, destClamp hält den Screen.
- **`lastPoolIDs`.** Reconnect-Slot in actorMapped. pointerHandID = Pool first, vor pinchActor.
- **pinchActor nur Lock-Pool.** Andere Hand ist Modifier.
- **`palmReachKills(side:locked:)`.** Lock-Hand nah kein Kill. Overlay geglättet.
- Tests + MARKETING_VERSION 1.5.59 (Build 79).

**1.5.58:** Gesten tot nach 1.5.39: `RotationCoordinator` drehte jeden Frame physisch. Hohe Latenz, Cursor nicht an der Hand, Faust nicht erkannt — Palm-X/Y lagen 90° neben der Bewegung.

- Capture-Winkel **0°**. Kein Coordinator, kein landscapeRight.
- Portrait-Buffer: Preview und Vision dieselbe Software-Orientierung (`.right`).
- Mirror ohne `automaticallyAdjustsVideoMirroring = false`.
- MARKETING_VERSION 1.5.58 (Build 78).

**1.5.57:** Continuity-Reconnect verlor den Lock-Slot (Vision-ID tot, Chirality `.any`). displayTick interpolierte bei 24 fps obwohl die Kamera freeze. Relativ-Pfad sprang auf den Externen. HUD LOCK ohne DRAG. Tasche im ersten Ghost-Frame.

- **`pointerPoolReconnect` + `pointerSameSlot`.** Palm-Nähe nach ID-Tod. `.any` im Lock-Pool = sameSlot.
- **`displayTickBlocksSteal(poolEmpty:)`.** Pool leer: Tick tot auch bei 24 fps.
- **`clampMapped`.** Relativ und displayTick destClamp. stealScreen im Kamera-Tick.
- **`LOCK R · DRAG`.** stealSince nur Pool leer. **`stealHoldsPocket`.** Tasche nicht vor Timeout.
- Tests + MARKETING_VERSION 1.5.57 (Build 77).

**1.5.56:** Timeout während Pinch-Drag warf das Fenster. displayTick interpolierte bei Freeze mit Lock-Hand. destClamp sprang mid-Steal auf den Externen. Palm-Reach 3 bei 8 fps = Not-Aus. LOCK ohne Countdown.

- **`pointerStealTimesOut(dragging:)`.** Pinch/Drag: Fenster bleibt. Clock nach Up.
- **`displayTickBlocksSteal` Latch.** 8 fps Freeze auch mit Lock-Hand. Relock-Hold Cap × 0,5.
- **`destClampScreen(freeze:lastScreen:)`.** Freeze hält den Screen.
- **`palmReachKills(dt:)`.** 8 fps openScore 4. HUD `IDLE in 0,8 s`, `LOCK … 70%`, `SCALE`.
- **⌥-Faust Relock** sofort. Tests + MARKETING_VERSION 1.5.56 (Build 76).

**1.5.55:** Freeze hielt Klick, `placeCursor` lief vorher mit der anderen Hand. Relock in einem Frame. LOCK ewig. Continuity-Tick füllte auf den Externen. Ghost löschte den Latch.

- **`pointerStealBlocksCursor`.** Steal *vor* placeCursor/moveCursor. Overlay gestrichelt (actorHandID = Lock-Slot).
- **`pointerStealRelock` 0,35 s.** Kein Ein-Frame-Rauschen.
- **`pointerStealTimesOut` 1,2 s.** Pool leer → Idle.
- **`displayTickBlocksSteal`.** 8 fps Freeze kein Fill.
- **`palmReachKills`.** Offene Hand zur Kamera = Not-Aus. Scale trotz Steal.
- Tests + MARKETING_VERSION 1.5.55 (Build 75).

**1.5.54:** Freeze hielt den Cursor, driveGrab klickte mit der anderen Hand. Faust der anderen Hand tat nichts. Bezel-Lücke sprang auf den Externen. Faust-Countdown bei Klappe unsichtbar.

- **`pointerStealBlocksActor`.** Pool leer / Freeze: kein Klick, kein Wisch. Overlay darf die andere Hand zeigen.
- **`pointerStealHUD` + `stealChip`.** `LOCK L` / `LOCK R`.
- **`pointerStealRelock`.** Faust der anderen Hand legt den Lock um.
- **`destClampScreen` nächster Screen.** Bezel/Lücke nie nil.
- **fistArmChip während Klappe/Game.** Countdown sichtbar, Scharf bleibt tot.
- Tests + MARKETING_VERSION 1.5.54 (Build 74).

**1.5.53:** Lock-Hand weg → zweite Hand stahl den Zeiger. Relativ-Display-Link sprang auf den Externen. Pinch-Open 2 Frames bei 8 fps.

- **`pointerPool` leer.** Lock-Hand weg: nicht die andere.
- **`pointerFreezesSteal`.** actorMapped hält cursorSmooth, pointerHandID bleibt.
- **`destClampScreen`.** Relativ-Fill auf dem Screen unter dem Cursor.
- **`pinchOpenNeed` 8 fps = 1.**
- Tests + MARKETING_VERSION 1.5.53 (Build 73).

**1.5.52:** Pinzette blieb zu (0,54∧0,62, vel=0). Ghost hielt Dead-Man. Face-Count aus der Tasche. Display-Link sprang auf den Externen. Relativzeiger auf der Union. Zweite Hand stahl den Pointer. Tasche im Dunkeln blieb 8 s scharf. Unknown-Chirality stahl den Lock.

- **`pinchWantOpen`.** Zu 0,33/0,40, auf 0,58/0,64. 8 fps ohne Vel öffnet bei 0,59.
- **Ghost ≠ Dead-Man.** Nur Live-Hände stempeln lastHandSeen.
- **`pocketIdle` + `faceCountFresh`.** Continuity ohne Innenraum / stale Face → Idle. Auch `noteDarkFrame`.
- **Dark-Pfad `cameraFallback`.** Tasche ohne hellen Tick bleibt Continuity.
- **`displayTick` destClamp.** Fill bleibt auf der kalibrierten Map.
- **`relativeStepSpan`.** Laptop-Gain, nicht Screen-Union.
- **`pointerPool` + Focus-Steal.** Unknown nicht Lock. AX-PID-Wechsel = Latch.
- Tests + MARKETING_VERSION 1.5.52 (Build 72).

**1.5.51:** Klappe killte Clamshell. Legacy-Kalib ohne screenID lud nicht. Homographie sprang auf den Externen. Safari-Vollbild = GAME.

- **`lidBlocksArm`.** Continuity/USB + extra Display: Scharf bleibt. Built-in + Klappe tot.
- **Legacy-Load.** Camera-Key nur bei dest-Overlap. `destClamp` hält apply() auf dem kalibrierten Screen.
- **`gameModeExempt`.** Browser/Keynote kein Pause. `game-lock.txt` / `click-lock.txt`.
- **Skelett-Dash** je Finger.
- Tests + MARKETING_VERSION 1.5.51 (Build 71).

**1.5.50:** Game und Klappe setzten Idle, Faust schaltete im selben Tick scharf. Load zog die Laptop-Map auf den Externen. Display-Link-Cap fest 28 px.

- **`phaseBlocksArm`.** Klappe / Game: kein Faust-Scharf. `livePhase` kennt `lidClosed`.
- **`mapFitsScreen`.** Load ohne Legacy-Fallback. Homographie nur auf dem Screen, für den sie kalibriert ist.
- **`displayLinkCap`.** Zielen 12 px, Flick 28 px, dazwischen linear.
- Tests + MARKETING_VERSION 1.5.50 (Build 70).

**1.5.49:** Tip-Z-Math saß, PinchGate blieb 2D. Continuity 8 fps setzte den Zeiger nur am Kamera-Tick. Laptop-Map auf dem Externen ohne HUD. MAGNET/BUTTON/WEG nur Farbe. Eine Gain-Kurve für Safari und Steam. Erster Tick auf neuem Screen warpte relativ.

- **Vision Revision 2 + Tip-Z.** `VNDetectHumanHandPose3DRequest`. Z aus 4×4-Translation (`columns.3`). 3D nur bei 2D-Treffer. `pinchKeepsGrabTipZ` hält Grab wenn 2D atmet. Fallback 2D.
- **Display-Link 24 Hz.** Zwischen Continuity-Frames `displayTick` mit Velocity-Cap 28 px. 24 fps Built-in bleibt roh.
- **`KALIB HIER`.** Screen-ID ≠ Map-Screen. Banner + Chip. Laptop-Homographie nicht schleppen.
- **Homographie-Warmup.** Relativ-Warp nur mit Map auf dem neuen Screen.
- **Farbenblind Overlay.** MAGNET dicht, BUTTON lang, WEG Punkte — nicht nur Hue.
- **Per-App Gain + Click-Lock.** Safari 0,82, Steam 0,55, Dock immer Lock.
- Tests + MARKETING_VERSION 1.5.49 (Build 69).

**1.5.48:** Phase-Chip aus 1.5.47 klickte in Idle und Kill weiter. Eine Homographie für Laptop und Extern. Klick ohne Haptik.

- **`phaseBlocksClick`.** Idle / Kill kein Down, kein Release-Klick. HUD `KILL`.
- **SpaceMap je Display.** `spaceMapKey(camera, screen)`. Kalib schreibt `screenID`. Monitorwechsel lädt, schleppt destBounds nicht mit.
- **`tapHaptic`.** Generic Klick, Alignment Rechtsklick.
- Tests + MARKETING_VERSION 1.5.48 (Build 68).

**1.5.47:** Eine Phase statt vier Bools. Monitorwechsel snapte. Continuity-Lock warf den Zeiger. Vollbild-Spiel klickte mit.

- **`EnginePhase`.** HUD `IDLE` / `SCHARF` / `PINCH` / `ZIEHEN` / `SCALE`.
- **`screenBlend` 120 ms.** Display-ID, Smoothstep, kein Snap an der Naht.
- **Game-Mode.** Vollbild ≥ 92 % → Idle, Chip `GAME`.
- **Continuity-Reconnect.** Erster Frame nach Lock hält die Palm.
- Tests + MARKETING_VERSION 1.5.47 (Build 67).

**1.5.46:** 1.5.45 `lidClosed` blieb immer false — Math ohne IOKit. Trackpad 6 px stahl den Zeiger während Palm-Gain.

- **`Permissions.clamshellClosed`.** IOPMrootDomain `AppleClamshellState`. Tick setzt `lidClosed`.
- **`trackpadClutch`.** Ruhige Palm + 8 px Hardware = Clutch. Bewegte Palm erst ab 28 px. Drag 4/16.
- Tests + MARKETING_VERSION 1.5.46 (Build 66).

**1.5.45:** 1.5.44 Knie am Rand warf Scharf trotz VNFace. Flick und Zielen gleiche Klick-Need. Kalib 70 px × 4 „fertig“. Kein ⌘-Klick. 8 fps smoothstep Overshoot.

- **`armedIdle`.** Gesicht hält Scharf am Rand. Klappe → Idle.
- **`pinchClickNeed(dt:speed:)`.** Flick streckt, Zielen bleibt kurz.
- **Kalib-RMS 40 px** vor fertig. HUD `RMS n`.
- **`continuityPalmCubic`.** Catmull-Rom 8 fps.
- **Zweite Hand ⌘⌥⇧.** Peace / Point / Faust.
- Tests + MARKETING_VERSION 1.5.45 (Build 65).

**1.5.44:** 1.5.43 Doppelklick feuerte nach Flick. AX-Rolle auf Safari-Toolbar droppte BUTTON in einem Frame. Continuity-Zeiger warpte, weil `palmInterp` tot war. Blick weg hielt Scharf, weil kein VNFace.

- **`doublePinchBlocksTravel`.** Travel ≥ 45 % der Grenze = kein Doppel. Auch der vorherige Klick.
- **`clickLockMissFrames` 2.** Safari-Toolbar-Flackern hält BUTTON.
- **`continuityPalm`.** 8 fps smoothstep 0,62 vor Predict. 24 fps roh.
- **VNFace alle 4 Frames.** `faceCountIdle` 1,2 s → Idle. HUD „Kein Gesicht“.
- Tests + MARKETING_VERSION 1.5.44 (Build 64).

**1.5.43:** 1.5.42 stellte predictPalm wieder her, aber Lead-Clamp 0,4 blieb für 24 fps zu hoch. Extra-Hold ≥ 0,55 s war stilles cancelPress. Kein Doppelklick.

- **`predictLeadDt`.** 8 fps 0,7 / 24 fps 0,35. Clamp-Floor 0,3.
- **Rechtsklick** Extra-Hold 0,55 s ohne Click-Lock. HUD `RECHTS`.
- **Doppelklick** 0,32 s, `clickState` 2.
- Tests + MARKETING_VERSION 1.5.43 (Build 63).

**1.5.42:** `predictPalm` war in 1.5.41 gelöscht — Relativ-Predict und Tests kompilierten nicht. Traffic-Lights jeden Tick, Fling nur Palm-Norm (5k vs Laptop), Escape ohne HUD, Faust-Scharf ohne Countdown, Dead-Man unsichtbar, Overlay nach Dunkel rebase-Warp.

- **`predictPalm` wieder da** plus Lead-Clamp 0,4–1,0.
- **`hoverRingKind`** MAGNET / BUTTON / WEG — Overlay-Farbe und HUD-Chips.
- **`escapeLatchHUD` LATCH** 200 ms.
- **`visionMsSpark`** neben fps.
- **`trafficCacheFresh` 400 ms** — Lights nicht jeden Tick Walk.
- **`fling` Quartz-px/s** über destBounds.
- **`darkRingHolds`** 2 Frames nach Dunkel kein Warp.
- **`deadManProgress` / `fistArmLabel`** IDLE n% / SCHARF n%.
- Tests + MARKETING_VERSION 1.5.42 (Build 62).

**1.5.41:** Desk-View wurde als Front gespiegelt — Homographie im Void. Relativzeiger (ohne Kalib) hing ein Frame hinter Continuity. Ferne Pinch-Vel schloss das Gate. Click-Lock feuerte auf dem Weg zum Button. Knie am Bildrand hielten Scharf und Dead-Man. Escape → sofort Klick. AX-Skip bei jedem 19-ms-Spike. Panic-Not-Aus 0,55 s zu langsam.

- **`mirrorAsFront`.** Desk-View nie spiegeln. Built-in unspecified bleibt Front.
- **`relativePredicts` + `predictPalm`.** Relativzeiger bei dt ≥ 80 ms.
- **`pinchCloseVel(dt:palmScale:)`.** palmScale < 0,08 weicher.
- **`clickLockNeedsHover` 0,70.** Zu oder Hover, sonst kein Down-Lock.
- **`panicKill`.** Zwei openScore 4 sofort Idle.
- **`armOpenCounts` / `gazeIdle` 1,2 s.** Innenraum, nicht Rand-Knie.
- **`escapeLatch` 200 ms.**
- **`skipAXLatch`.** 1 teurer Tick, 2 billige, dann Probe.
- **`travelHUD` WEG n%.**
- Tests + MARKETING_VERSION 1.5.41 (Build 61).

**1.5.40:** Klicks starben an 12 px Jitter (Continuity / ohne Kalib). AX auf Main nach schwerem Vision-Tick ließ den Cursor hängen. Ferne Hände flackerten im Pinch. Homographie hing ein Frame hinter Continuity.

- **`pinchClickTravelPx`.** 24 fps Map 12 px, 8 fps 20, Relativ 28, ferne Hand 34, Cap 36. Down und Release dieselbe Distanz.
- **`axBudgetSkip`.** Vision > 18 ms **und** 24 fps → Probe skip, Cursor läuft. 8 fps nie — sonst MAGNET tot. visMs getrennt von End-to-End.
- **`predictPalm`.** 0,7 Frame voraus auf der Homographie.
- **`pinchCloseRatio` / `pinchKeepRatioFor`.** palmScale < 0,08 weicher (0,40 / 0,56).
- **meanConfidence** aus geglätteten Joints, nicht Roh-Overlay.
- **HandTracker** hält das Lock nicht mehr während `VNImageRequestHandler.perform`.
- Tests: Travel, Budget, Close/Keep, Predictor.
- MARKETING_VERSION 1.5.40 (Build 60).

**1.5.39:** Die Mac-Kamera lag in Helios auf der Seite. `videoOrientation = .landscapeRight` dreht auf macOS 26 die VideoDataOutput-Buffer physisch (iOS-Home-Button-Konvention). FaceTime ist schon aufrecht.

- **`RotationCoordinator`** Horizon-Level, `videoRotationAngle` statt landscapeRight.
- Vision `.up` sobald der Puffer physisch steht. Preview und Skelett dieselbe Geometrie.
- MARKETING_VERSION 1.5.39 (Build 59).

**1.5.38:** Zweiter Line-by-Line-Pass. Kamera stop→start ließ `FramePump.cancelled` stehen — jedes Frame fiel. CGWindowList-Bounds als NSNumber, der `[String: CGFloat]`-Cast war immer nil (kein Umriss, Helios-Hit tot). Overlay-Umriss/Beam eine Fensterhöhe zu tief (`localRect` nahm Quartz-maxY). Need/Watchdog lasen `lastPointerT` (nur bei Palm-Bewegung), Still/Clutch kippte Continuity auf 180 ms. Kamera-Wechsel ließ 16-ms-Median, erster Continuity-Pinch klickte. Idle/Ghost feuerte Peace. Skip-AX cachte eine leere Probe, Release klickte trotz Latch. Grab hinter Helios per AX-Hit-through.

- **FramePump.reset** auf der Kamera-Queue am Start von `configureAndRun`. `uniqueID` bleibt beim Stop. `isRunning` nur nach erfolgreichem `startRunning`. `canAddInput`/`canAddOutput` Abbruch.
- **`windowListRect`.** NSNumber/Double/Int. FocusTracker/outline/Helios-self.
- **`quartzTopLeft` / `localRect`.** Quartz minY = oben.
- **`lastTickT`.** Need/TTL/Lock jeden Tick. `recenterPointer` leert `sampleDts`.
- **`skipProbeStoresEmpty` / `releaseBlockedBySkipAX`.** Kein leerer Cache, kein Release-Klick nach Dunkel.
- **beginWindowDrag** CGWindowList-self zuerst. AX-Write mit Read-back (12 px). `dragGen` invalidiert In-Flight-Tasks. `CGEventSource.privateState`. Dump-Up ohne Clamp.
- **destBounds** Residual gegen Kalib-Rechteck. Kalib-Cursor `linear(in: visQuartz)`. Dunkel leert VisionInbox. Filmstrip bekommt Preview. Footer Linke/Rechte. Relaunch nur nach Open-OK.
- MARKETING_VERSION 1.5.38 (Build 58).

**1.5.37:** Vollständiger Bugfix-Pass. Helios-Drag ging weiter über AXPosition (SwiftUI setzt das oft nicht). Kalib 1.5.35 brach ab, weil der *Hardware-Mauszeiger* 80 px neben der Ecke lag, nicht die Hand. Snap meldete OK trotz AX-Fail. Leere Vision ließ Down stehen. Nach Dunkel wuchs pinchClickNeed mit — erster heller Tick klickte. Homographie-Ziel war immer der Hauptbildschirm. Probe-Cache überlebte Monitor-Wechsel. Ohne Frames blieb das Format tot.

- **`dragOwnWindow`.** Greifen/Ziehen/Snap/Mini/Close der Konsole über `NSWindow`.
- **Kalib `cursorGap`.** `SpaceMap.linear(palm)` gegen Ecke, nicht `NSEvent.mouseLocation`. Dest-Ecken in der Map.
- **`snapFocused`.** Fail wenn Position und Größe beide tot.
- **cancelPress** bei leerer Hand, DMG-Modus, Idle.
- **`pinchClockAdvance` / `pressBlockedBySkipAX`.** Need-Uhr steht bei Skip-AX, erster frischer Tick kein Down.
- **`invalidateProbe`.** Monitor-Wechsel und Skip leeren den AX-Cache.
- **`frameSilenceRetry`.** 2 s ohne Frame → Format neu.
- **Beam** an den Titelbalken. Testmodus „GREIFT · KEINE AKTION“.
- MARKETING_VERSION 1.5.37 (Build 57).

**1.5.36:** Zwei Pinzetten skalierten nicht: die erste Hand setzte `pinchHeld`, `scaleBlocksGrab` verwarf Scale. Cooldown schrieb den Span fort, die Bewegung war nach 0,5 s weg. Helios selbst: AXSize an SwiftUI-Fenstern oft tot.

- **`scaleBlocksGrab`.** Zwei PinchGates gewinnen immer, Grab wird abgebrochen.
- **`scaleKeepsSpan`.** Cooldown hält den alten Span.
- **`resizeOwnWindow`.** Eigenes ControlPanel über `NSWindow.setFrame`.
- **HUD** „Skalieren …“ während Settle.
- Tests: Gates gegen Grab, Span gated/frei.
- MARKETING_VERSION 1.5.36 (Build 56).

**1.5.35:** Continuity-Lock wartete 4 s + 8 s Cooldown im 0,5 s-fps-Fenster. `sampleDtCap` 200 ms hätte dt > 400 ms tot gemacht. Ein dunkler Frame skippte Vision. Kalib-Ecken lagen auf der Cocoa-Union (Menüleiste, zweiter Monitor), Drift > 80 px wurde trotzdem gespeichert.

- **`rawFrameDt` / `continuityLockRetry`.** Ungedeckelt, jeden Tick. dt > 400 ms für 2 s → Format neu.
- **`lumaSkipEnter`.** 2 dunkle Frames bevor Vision tot. AX-Hold (1.5.34) bleibt.
- **`screenAwareCorners`.** visibleFrame des Monitors unter dem Cursor.
- **`calibAborts`.** Pinzette > 80 px neben der Ecke — Sample weg.
- Tests: Enter 1/2, Roh vs Cap, Lock-Retry, Ecken, Drift 80 px.
- MARKETING_VERSION 1.5.35 (Build 55).

**1.5.34:** Format 720p@1–30 gleichauf mit 720p@24–30. Watchdog aus dem letzten 0,5 s-Fenster. Heller Blitz nach Dunkel spammte AX (`lumaLow` nach 90 ms überschrieben). Dark-Frame ließ Grab-Rebind fallen. HUD blieb voll nach Idle.

- **`formatPrefers`.** Tie-Break minFrameRate.
- **`lumaSkipHold` + `tick(skipAX:)`.** Zwei helle Frames, dann AX. skipProbe-Cache für den ganzen Tick.
- **`medianFps`.** Watchdog nicht aus einem Spike-Fenster.
- **`darkHoldsRebind` / `hudDims`.** Dark hält Actor, HUD 40 % nach 8 s Idle.
- Tests: Tie, Luma-Hold, Median, Dim, Rebind.
- MARKETING_VERSION 1.5.34 (Build 54).

**1.5.33:** Pinzette über Helios selbst griff das Fenster dahinter — `skipSelf` war hart an. HUD-Overlay lag in der AX-Hit-Test-Kette, die gelbe Linie zeigte zur Mitte eines anderen Fensters, Helios blieb stehen.

- **`cgWindowIsGrabTarget`.** HUD (layer ≠ 0) nie. Eigenes ControlPanel (layer 0) wenn `skipSelf: false`.
- **`targetWindow`.** Nach AX-Self (Overlay) CGWindowList inklusive Helios.
- **`pollFocus`.** Cursor über Helios → Umriss Helios, nicht das Fenster darunter.
- **HUD AX-hidden.** Overlay-Panels `accessibilityHidden`, Marker kein AX-Element — Hit-Test fällt durch aufs echte Fenster.
- Tests: skipSelf an/aus, Overlay-Layer, pid 0.
- MARKETING_VERSION 1.5.33 (Build 53).

**1.5.32:** Ein Spike-Frame (200 ms) kippte Click-Need auf 180 ms, obwohl der Takt 16 ms war. HUD zeigte nur „Ziehen“, obwohl der Wurf schon über `flingMinSpeed` war. Continuity-Scale am ersten Tick / 24 fps klebte 350 ms. `meanConfidence` ließ eine tote Daumen-/Index-Spitze als Pinzette durch.

- **`medianSampleDt`.** Letzte 8 dts. Need folgt Median, nicht dem Spike. `frameDt` bleibt für AX-TTL.
- **FLING-Ghost.** Overlay gestrichelt + HUD `FLING ↑↓←→` während Pinch-Drag.
- **`scaleSettleNeed`.** 8 fps 350 ms, 24 fps 180 ms.
- **`pinchTipConfidenceOk`.** Gate nur Thumb+Index ≥ 0,18, nicht Joint-Mittel.
- Tests: Median-Spike, Ghost-Labels, Scale-Settle, Spitzen-Confidence.
- MARKETING_VERSION 1.5.32 (Build 52).

**1.5.31:** Continuity-Klick war Down im ersten Frame (120 ms < 125 ms). Built-in und Continuity teilten eine Homographie. AX lief auf Luma-Skip. 4 fps blieb beim toten Format. `frameDt` wurde nie aus `sampleDt` geschrieben. `skipProbe` blieb nach Dunkel für immer true. Down/Release nutzten weiter 120 ms.

- **`pinchClickNeed(dt)`.** 8 fps 180 ms, 24 fps 90 ms. `frameDt` vor placeCursor. Settle, HUD, Down, Release folgen Need.
- **Kalib je `cameraUniqueID`.** Continuity erbt nicht die Built-in-Map.
- **`skipProbe`.** Dunkel: kein AX-Roundtrip. `tick` setzt zurück, `loadProbe` verbraucht.
- **Continuity-Watchdog.** dt > 200 ms für 4 s → Format neu.
- **Kalib-dt** 200 ms Deckel, nicht 80 — Hold zählt Continuity-Frames voll.
- **`clickLockMissHold`.** Ein AX-Miss hält BUTTON.
- Tests: Need 90/180, Settle, Skip, Stuck, Kamera-Keys, Miss-Hold.
- MARKETING_VERSION 1.5.31 (Build 51).

**1.5.30:** AX-Cache 90 ms starb bei Continuity 8 fps (125 ms). MAGNET nur Text. `hitLocksClick` hart palmScale 0,12. Zweite Faust / ⌘. tat nichts. Up auf Mini nach Down auf Close = Klick. Click-Lock nach Gate starr.

- **AX-Probe-TTL.** `axProbeTTL` 180 ms bei dt ≥ 80 ms, sonst 90. Engine setzt `probeTTL` pro Tick.
- **MAGNET-Ringe.** Overlay-Ellipsen r=11 um Close/Mini/Zoom, nicht nur Text.
- **palmScale durch hitLocksClick.** Magnet-Distanz folgt der Hand, nicht 0,12.
- **Zweite Faust** `fistCancelsHold` — Pinch tot, kein Klick.
- **⌘.** `cmdPeriodCancels` analog Escape.
- **Down-Element.** `samePressElement` — anderes Control → `cancelPress`.
- **Click-Lock-refresh** nach Gate folgt dem Control unter dem Zeiger.
- Tests: TTL, Faust, Cmd-Punkt, samePress, Ringe, palmScale 0,08 = 36 px.
- MARKETING_VERSION 1.5.30 (Build 50).

**1.5.29:** Down auf der Fensterfläche nach 120 ms plus `cancelPress`-Up war ein Klick, dann erst Drag. Dock/Menüleiste wurden gegriffen. 5 AX-Roundtrips pro Tick. Escape tat nichts. Traffic-Magnet unsichtbar.

- **Kein Down auf Fenster.** `pressDuringHold` — nur Button/Link/Feld/Dock/Menü während Hold. Fenster klickt beim Loslassen oder greift ohne vorherigen Down.
- **`cancelPress` ohne Klick.** Up bei (−8000,−8000), Cursor zurück.
- **AX-Probe einmal.** Rolle, Subrole, Frame, Traffic-Lights vom selben Element; Dock/Menü ohne Lights-Walk.
- **Dock/Menüleiste = Klick.** `AXDockItem`, `AXMenuBarItem`, `AXMenuBar`.
- **Escape bricht Pinch.** Vor Down kein Klick.
- **Fenster-Rand 12 px.** Drag bündig am `visibleFrame`.
- **HUD MAGNET** wenn Traffic-Lights in Reichweite.
- Tests: pressDuringHold, Dock-Lock, edgeMagnet, MAGNET-Label.
- MARKETING_VERSION 1.5.29 (Build 49).

**1.5.28:** Nach dem Klick starb der Cursor: Still-Clutch (0,22 s) lief während Pinch/Down, nach Loslassen blieb der Zeiger tot bis palmUnstill. Homographie ignorierte die Trackpad-Kurve — kalibriert = jitterig. Gate-Lock war tot, weil freezePointer den Cursor 120 ms festhielt (Rolle = Start). pinchClickMaxPx vom Start tötete Zielen als „Cursor wanderte“.

- **Clutch nicht während Pinch.** `clutchWhilePinch` — Hold/Down setzt palmFrozen zurück.
- **Clutch-Grace.** `clutchInGrace` 0,35 s nach Loslassen.
- **Settle zielt.** `pointerFrozenWhile` friert nur Abort oder Down auf Button.
- **AX-Rolle am Gate.** `hitLocksAtGate` + `cursorTravelOrigin` — Zielen lockt den Button, Weg zählt ab Gate.
- **Homographie-Kurve.** `mapFollowMul` dämpft kleine Palm-Wege.
- **HUD CLUTCH.** Chip wenn der Zeiger stillsteht, ohne tot zu wirken.
- MARKETING_VERSION 1.5.28 (Build 48).

**1.5.27:** Down/Up sitzen in der AX-Mitte kleiner Controls (max 56 px Shift) — große AX-Gruppen/Fenster bleiben am Cursor, sonst Teleport ins Fensterzentrum. Traffic-Lights magnetisieren bis 36 px / 0,30 Handbreiten. HUD „BUTTON“ sobald ein Control lockt. Hover-Ring gestrichelt bevor die Pinzette zu ist. Overlay-Ring aus sobald die Hardware-Maus Vorrang hat. fps-Spark neben `S1 · 8 fps`.

**1.5.26:** Pinch-Atmen (ratio 0,34–0,48) tötet den Klick nicht mehr. AX-Rolle Button/Link/Feld = immer Klick, nie Fenster-Drag. Relativzeiger Trackpad-Kurve plus Depth-Gain für ferne Palmen. Kalibrierung blockt Scharf. Not-Aus-Ring auf jedem Display.

**1.5.25:** Klick-Up sitzt am Down-Punkt (`pressPoint`), nicht auf `lastPosted` nach Jitter — Buttons hinter dem Fenster kriegen den Up nicht. Overlay-Ring füllt während pinchClickMin (`KLICK n %`), Hover ist sichtbar bevor Down kommt.

**1.5.24:** Not-Aus zählt nur Palmen im Innenraum — Knie/Schulter am Bildrand zünden nicht. Windup und Grace injizieren den Cursor (`injectCursor`), nicht nur HUD. Grab endet sofort im Windup, statt 0,55 s zu kleben.

**1.5.23:** Zwei-Pinzetten-Scale braucht PinchGate, nicht Faust-als-Pinch — Einhand-Klick stirbt nicht mehr, wenn die andere Hand lose zu ist. Ghost verbraucht Rebase nicht (kein Teleport nach Dropout). Wisch-Grace hält dieselbe Hand, nicht `hands.first`. Not-Aus-Grace lässt den Cursor laufen.

**1.5.22:** Freeze zieht `lastPalm` nach, Cursor nicht — nach Down Rebase statt Teleport-Dragged. Drag erst nach pinchClickMin vom Settle-Palm. Peace wischt nicht. Ghost/Dunkel rebase.

**1.5.21:** Klick-Down warpt zuerst auf den HUD-Cursor (sonst trifft Erst-Pinch/Freeze die Hardware-Maus). Palm-Speed > 0,20 während pinchClickMin → kein Down (Klick mitten im Flick). „Hand unsicher“ nur im Testmodus. Ghost-Ring gestrichelt auf dem Overlay-Monitor.

**1.5.20:** Ghost-Hände ohne One-Shots (kein Peace-Screenshot/Not-Aus aus gefrorener Pose). HUD `S1 Ghost 0,4 s`. Klick-Down folgt dem Zeiger (`leftMouseDragged`). Zwei-Pinzetten-Zoom am Cursor, nicht Fenstermitte. TCC-Banner wenn Bedienungshilfen nach Update weg sind.

**1.5.19:** Ghost-Hände 0,60 s (Vision-Dropout liefert letzte Pose, nicht `[]`). Pinch-Hold 8 fps 1 Frame. Klick: Down nach 120 ms, Up beim Öffnen. Kamera-Picker Built-in / Continuity. Tests: ghostHands, pinchPoseHoldNeed.

**1.5.18:** Format-Score (720p@15–30 schlägt 360p@60 und 800p@8). PinchGate Open 2 Frames bei 8 fps. Zeiger nach Freeze rebase, nicht Sprung. AX-Fail holt Fenster neu. Slot-IDs recyceln. Homographie-Alpha bei 8 fps höher. fps-Watchdog < 6 s + Gain 0,5. Dual-Cam-Banner wenn Continuity trotz Frontkamera. HUD `S1 · 8 fps`.

**1.5.17:** Slot-TTL 0,60 s (nicht Abort-Hold 0,22), auch `emptySince`. PinchGate Open-Vel folgt dt. Faust-Scharf nur nach offener Hand, `sawOpen` nach 2 s ohne Hand weg. Continuity-Format unter 24 fps. Relativzeiger 8 fps gedämpft. AX-Drag coalesced. Overlay-Ring bei Luma-Skip sofort weg. Slot-ID im HUD.

**1.5.16:** `preferred()` nimmt Slot (`pointerHandID` / Pinch-Actor) vor Links/Rechts — nach Abort kein Sprung auf die andere Hand. Homographie hält `cursorSmooth` beim Hand-Wechsel. PinchGate Close-Vel folgt dem Frame-dt (8 fps schließt wieder). Wischen: Trail 3,2 × medianDt, minDt nicht mehr hart 160 ms. Geschlossene Spitzen sind Pinzette, nicht Faust (kein Scharf mitten im Drag). Palm-Bind skaliert mit Handgröße. Overlay-Ring nach Luma-Skip weg. Landmark-1-Euro dt-Deckel 0,20 s.

**1.5.15:** PinchGate/Smoother über Palm-Slot (`S1`/`S2`), nicht L/R — Chirality-Flip hält den Grab ohne Transfer-Hack. Nach Abort bleibt der Cursor 0,22 s stehen, statt auf die andere Hand zu springen. Wurf-Fenster `max(120 ms, 2,5 × medianDt)` (8 fps). Homographie-Residual dämpft den Zeiger. Overlay-Skelett nach 0,4 s Dunkel weg. AX-Timeout: zwei Fehlschläge, dann Drag-Element weg, Pinch bleibt.

**1.5.14:** Original-Hand weg → `abortGrab` plus 0,22 s Hold, die andere Hand erbt nicht im selben Tick. Vision-Flicker und Chirality-Flip (R→L) halten den Grab an der Palm. Dunkle Frames zählen nicht als „keine Hand“ (kein Dead-Man, kein Loslassen), nach 8 s Dunkel trotzdem Idle. Wurf auch bei 8 fps (letzte 4 Samples). Heranziehen nur nach Drag, nicht im Klick-Fenster. Peace bricht am Bildrand ab. Relativzeiger 1-Euro bei 8 fps schneller. Zwei-Pinzetten nach Hand-ID sortiert.

**1.5.13:** Original-Hand weg → Grab tot, nicht an die andere Hand. Wurf-Speed aus 120 ms, nicht 0,5 s Halten. Heranziehen = Palm zu sich, nicht Mittelfinger. Zwei-Pinzetten auch `pinchClosed`. Luma < 0,08 kein Vision. Monitor-Wechsel setzt Relativzeiger + Drift-Banner. Not-Aus-Grace 0,14 s.

**1.5.12:** Duplicate `swipeGraceUntil` (Build-Bruch) weg. Pinch stiehlt nicht mehr, wenn die Original-Hand verschwindet. Peace/Daumen nur ohne fremde Pinzette. Fast-Wurf klickt nicht. Zwei-Pinzetten-Scale mit Palmen-Totzone. SpaceMap nur `isUsable` (singuläre Homographie → Relativzeiger + Banner). Residual > 480 px für 2 s → Drift-Banner. Relativzeiger 1-Euro statt EMA 0,8. Overlay hebt `pinchActorID` hervor. Continuity/Desk-View-Banner. **Pinzette vor Zeigen:** geschlossene Spitzen sind keine Point-Geste (CI „FAIL Pinzette“).

**1.5.11:** 1.5.10 stand nur in der Liste. Jetzt wirklich: SpaceMap-Totzone, Pinch bleibt an einer Hand, unbekannte Chirality über Palm, Main-Queue lässt Zwischenframes fallen. Dazu: Faust nur bevorzugte Hand, Wischen vs. Cursor, Klick nur bei stiller Pinzette, Homographie 0,55, Relativzeiger-Hinweis.

**1.5.8:** Cursor steht still, wenn die Hand atmet. Peace vor Pinzette. PinchGate und Pose-Hold setzen zurück, wenn die Hand verschwindet. Dead-Man Idle nach 8 s ohne Hand. Fling-Totzone in der Bildmitte. Faust nach Scharf greift nicht, bis die Hand wirklich offen war.

**1.5.7:** GestureMath ist wirklich die Engine (nicht nur Tests). Cooldown friert den Cursor nicht. Maus-Vorrang stoppt Gesten. Kamera-Orientierung nach dem Format. Pinzette öffnet nach fehlenden Spitzen. Not-Aus 0,55 s, Scharf danach 0,85 s.

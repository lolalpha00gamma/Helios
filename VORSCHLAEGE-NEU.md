# Helios Nachtrag 1.5.146 — 2026-09-06

Binary **1.5.146 Build 165**. Finger-Paare, Tip-Conf, Frozen-Write tot. Analyse in ANALYSE.md.

## In 1.5.146 gelandet

1. obsFingerChainPairs — Finger-Index, compactMap-Zip tot
2. obsJointConfOk tips — Gitarre tote Tips
3. palmROIFrozenWrite — ROI-aus kein lastFrozenROI
4. Tests + MARKETING_VERSION 1.5.146 (Build 165)

`bugfix` 1.5.8 gelesen, nicht gemergt. Dead-Man/Fling/Wischen sitzen seit 1.5.127.

## Nächste, zusätzlich

- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`. IOSurface zero-copy statt XPC-Copy.
- **Kamera-Mutex:** Helios+Aegis greifen Continuity gleichzeitig — 8 fps und TCC-Dialog. `helios.aegis.camera.lock` Datei oder XPC-Arbiter.
- **VNDetectHumanBodyPose als Prop-Veto.** Fingerkette dämpft, Body-Pose entscheidet Gitarre vs Hand.
- **Slot-ID Hungarian Palm-IoU** statt nearest lastS1. Slot-Steal nach Flick.
- **Kalman-Zeiger 2D** constant-velocity statt 1-Euro + Predict. Overlay-Extrapolate sitzt Bild 0…1, nicht Screen-px.
- **OneEuro minCutoff skaliert mit dt.** 8 fps 0,22 vs 24 fps 0,80 — ein Wert lügt.
- **OneEuro auf Palm im Bildraum** vor der Homographie. 8 fps Jitter sitzt an der Quelle, nicht am Seam.
- **DisplayPulse je NSScreen**, nicht NSScreen.main. Studio 60 + Laptop 120 zwei Links.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s, eine Karte je Display-UUID.
- **6-Punkt-Kalib RBF** gegen Kissen. Desk-View 45° kippt destBounds — CMAttitude Pitch-Gate < 12°.
- **Overlay CAMetalLayer 90 Hz** aus last-Palm. Lerp sitzt, Layer fehlt — SwiftUI Overlay 8 fps lügt.
- **Pointer-Gain-Kurve** statt linear. Klein = präzise, Flick = schnell.
- **Continuity IMU-Fusion** iPhone-Motion für 8-fps-Predict.
- **Pinch-Druck tip-Z / LiDAR** Click vs Drag.
- **IOHID Event-Tap** statt CGEvent-Post / CGWarp.
- **Vision requestRevision / joint-group.** HandCount 4 sitzt; Joint-Group fehlt.
- **Capture-Orientation live KVO** `videoRotationAngle` wenn MacBook klappt (`bugfix` 1.5.8).
- **HUD Chirality-Pfeil** L/R (`bugfix`).
- **Gesture-Log JSONL** neben Filmstreifen (`bugfix`).
- **AX SetPosition ein Call/Frame** (`bugfix`).
- **Continuity AE-Lock.** Belichtung springt Scale 0,12→0,20.
- **Desk-View Gravity Watchdog:** Pitch > 20° drei Ticks, Overlay-Chip „KIPP“, Warp-Gain 0,4.
- **Wrist-Roll Scroll** wenn Continuity 3D-Joints liefert.
- **Hover-to-Click Dwell 0,55 s** Accessibility, getrennt von Pinch.
- **Zwei-Hand: S1 Zeiger, S2 Scroll** ohne S1-Steal.
- **Per-App Gain aus AX bundle id.** Finder: Werfen = Datei; Safari: Tab (`bugfix`).
- **Fill-Cap RMS Auto** wenn Warp vs Overlay > 18 px / 1 s.
- **Mission Control Spaces** als dritter destBounds.
- **Stereo Continuity+Built-in** als grobe Tiefe.
- **Low-Power:** Vision 12 fps Cap.
- **Gaze-gated Click** VNFace-Yaw.
- **Zwei-Pinzetten proportional** zur Span-Änderung (`bugfix`).
- **Continuity Format-Lock 24 fps** request statt 8 fps Fallback.
- **Tests splitten** (GestureTests ~3200 Zeilen). CoordMath split: Overlay, Slot, Pointer. ROI-Totcode 1.5.67–141 kann raus.
- **obsJointConf geometrisches Mittel** Wrist×MCP×Tip statt AND-Floor — Gitarre Wrist 0,90 Tips 0,38 knapp unter Floor.
- **Center Stage Reassert** nach Continuity-Reconnect, nicht nur Start.
- **Palm-Scale EMA vor Bind** 3 Ticks, Gitarre-Flicker re-rankt sonst jeden Tick.
- **slotMintsNew cap 2** ist Absicht (HandCount 4 nur Vision-Results). Dokumentiert halten.

Die historische Liste bis 1.5.145: ANALYSE.md.

Nur main.

# Helios Nachtrag 1.5.145 — 2026-09-06

Binary **1.5.145 Build 164**. Fingerkette hart, Conf-Gate, Chirality hält One-Euro, ROI-Totpfad. Analyse in ANALYSE.md.

## In 1.5.145 gelandet

1. obsFingerChainOk ohne Wrist / n<2 tot
2. obsJointConfOk Wrist+MCP 0,40, Sparse 0,22
3. obsSmoothChiralityHolds — L/R-Flip kein Reset
4. palmROICoastFollows / palmROIThawProp Default ROI-aus
5. Tests + MARKETING_VERSION 1.5.145 (Build 164)

`bugfix` 1.5.8 gelesen, nicht gemergt. Dead-Man/Fling/Wischen sitzen seit 1.5.127. Capture-Orientation live KVO bleibt auf der Liste.

## Nächste, zusätzlich

- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`. IOSurface zero-copy statt XPC-Copy.
- **VNDetectHumanBodyPose als Prop-Veto.** Fingerkette dämpft, Body-Pose entscheidet Gitarre vs Hand.
- **Slot-ID Hungarian Palm-IoU** statt nearest lastS1. Slot-Steal nach Flick.
- **Kalman-Zeiger 2D** constant-velocity statt 1-Euro + Predict. Overlay-Extrapolate sitzt Bild 0…1, nicht Screen-px.
- **OneEuro auf Palm im Bildraum** vor der Homographie. 8 fps Jitter sitzt an der Quelle, nicht am Seam.
- **DisplayPulse je NSScreen**, nicht NSScreen.main. Studio 60 + Laptop 120 zwei Links.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s, eine Karte je Display-UUID.
- **6-Punkt-Kalib RBF** gegen Kissen. Desk-View 45° kippt destBounds — CMAttitude Pitch-Gate < 12°.
- **Overlay CAMetalLayer 90 Hz** aus last-Palm. Lerp sitzt, Layer fehlt — SwiftUI Overlay 8 fps lügt.
- **Pointer-Gain-Kurve** statt linear. Klein = präzise, Flick = schnell.
- **Continuity IMU-Fusion** iPhone-Motion für 8-fps-Predict.
- **Pinch-Druck tip-Z / LiDAR** Click vs Drag.
- **IOHID Event-Tap** statt CGEvent-Post / CGWarp.
- **Vision requestRevision / joint-group.** HandCount 4 sitzt; Joint-Group fehlt.
- **Capture-Orientation live KVO** `videoRotationAngle` wenn MacBook klappt (`bugfix` 1.5.8).
- **HUD Chirality-Pfeil** L/R (`bugfix`).
- **Gesture-Log JSONL** neben Filmstreifen (`bugfix`).
- **AX SetPosition ein Call/Frame** (`bugfix`).
- **Continuity AE-Lock.** Belichtung springt Scale 0,12→0,20.
- **Desk-View Gravity Watchdog:** Pitch > 20° drei Ticks, Overlay-Chip „KIPP“, Warp-Gain 0,4.
- **Wrist-Roll Scroll** wenn Continuity 3D-Joints liefert.
- **Hover-to-Click Dwell 0,55 s** Accessibility, getrennt von Pinch.
- **Zwei-Hand: S1 Zeiger, S2 Scroll** ohne S1-Steal.
- **Per-App Gain aus AX bundle id.** Finder: Werfen = Datei; Safari: Tab (`bugfix`).
- **Fill-Cap RMS Auto** wenn Warp vs Overlay > 18 px / 1 s.
- **Mission Control Spaces** als dritter destBounds.
- **Stereo Continuity+Built-in** als grobe Tiefe.
- **Low-Power:** Vision 12 fps Cap.
- **Gaze-gated Click** VNFace-Yaw.
- **Zwei-Pinzetten proportional** zur Span-Änderung (`bugfix`).
- **Continuity Format-Lock 24 fps** request statt 8 fps Fallback.
- **Tests splitten** (GestureTests ~3100 Zeilen). CoordMath split: Overlay, Slot, Pointer. ROI-Totcode 1.5.67–141 kann raus.
- **obsJointConf produkt** Wrist×MCP×Tip statt Mittel — Gitarre hohe Wrist-Conf, tote Tips.
- **Center Stage Reassert** nach Continuity-Reconnect, nicht nur Start.

Die historische Liste bis 1.5.144: ANALYSE.md.

Nur main.

# Helios Nachtrag 1.5.144 — 2026-09-06

Binary **1.5.144 Build 163**. HandCount 4, Fingerkette, Span-Veto Prop, Smooth 0,35. Analyse in ANALYSE.md.

## In 1.5.144 gelandet

1. obsHandCountCap 4 — Vision-Slots hinter Gitarre+Rumpf
2. obsFingerChainOk — Tip>MCP, Sparse ohne Kette hält
3. obsScaleMarksProp — Span-Veto markiert Prop > 0,28
4. obsSmoothJump 0,35 — Flick hält One-Euro
5. Tests + MARKETING_VERSION 1.5.144 (Build 163)

`bugfix` 1.5.8 gelesen, nicht gemergt. Dead-Man/Fling/Wischen sitzen seit 1.5.127. `bugfix` „max 2 Hände“ bewusst gebrochen — Gitarre frisst die zwei Slots.

## Nächste, zusätzlich

- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`. IOSurface zero-copy statt XPC-Copy.
- **Center Stage hart aus** sobald Zeiger live. Freeze/TTL/Thaw waren Pflaster; 1.5.142 ROI tot, Auto-Framing bleibt.
- **VNDetectHumanBodyPose als Prop-Veto.** Fingerkette dämpft, Body-Pose entscheidet Gitarre vs Hand.
- **Joint-confidence Gate.** Wrist+MCP conf < 0,40 tot — Gitarre halluziniert Kollinear mit hoher Conf.
- **Slot-ID Hungarian Palm-IoU** statt nearest lastS1. Slot-Steal nach Flick.
- **One-Euro nicht bei Chirality-Flip.** L/R-Label ist Vision-Rauschen, kein neuer Slot.
- **Kalman-Zeiger 2D** constant-velocity statt 1-Euro + Predict. Overlay-Extrapolate sitzt Bild 0…1, nicht Screen-px.
- **OneEuro auf Palm im Bildraum** vor der Homographie. 8 fps Jitter sitzt an der Quelle, nicht am Seam.
- **DisplayPulse je NSScreen**, nicht NSScreen.main. Studio 60 + Laptop 120 zwei Links.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s, eine Karte je Display-UUID.
- **6-Punkt-Kalib RBF** gegen Kissen. Desk-View 45° kippt destBounds — CMAttitude Pitch-Gate < 12°.
- **Overlay CAMetalLayer 90 Hz** aus last-Palm. Lerp+Extrapolate sitzen, Layer fehlt — SwiftUI Overlay 8 fps lügt.
- **Pointer-Gain-Kurve** statt linear. Klein = präzise, Flick = schnell. Continuity 8 fps sonst Overshoot.
- **Continuity IMU-Fusion** iPhone-Motion für 8-fps-Predict. Coast-Vel ist Bildraum.
- **Pinch-Druck tip-Z / LiDAR** Click vs Drag.
- **IOHID Event-Tap** statt CGEvent-Post / CGWarp.
- **Vision requestRevision / joint-group.** HandCount 4 sitzt; Joint-Group fehlt.
- **Capture-Orientation live KVO** `videoRotationAngle` wenn MacBook klappt (`bugfix` 1.5.8).
- **HUD Chirality-Pfeil** L/R, nicht nur Panel-Schalter (`bugfix`).
- **Gesture-Log JSONL** neben Filmstreifen, Fehlernachstellen (`bugfix`).
- **AX SetPosition ein Call/Frame**, nicht Queue-Stau (`bugfix`).
- **Continuity AE-Lock.** Belichtung springt Scale 0,12→0,20.
- **Desk-View Gravity Watchdog:** Pitch > 20° drei Ticks, Overlay-Chip „KIPP“, Warp-Gain 0,4.
- **Wrist-Roll Scroll** wenn Continuity 3D-Joints liefert.
- **Hover-to-Click Dwell 0,55 s** Accessibility, getrennt von Pinch.
- **Zwei-Hand: S1 Zeiger, S2 Scroll** ohne S1-Steal. 4 Slots machen S2 echt.
- **Per-App Gain aus AX bundle id.** Finder: Werfen = Datei; Safari: Tab (`bugfix`).
- **Fill-Cap RMS Auto** wenn Warp vs Overlay > 18 px / 1 s.
- **Mission Control Spaces** als dritter destBounds, Reanchor nach Space-Wechsel.
- **Stereo Continuity+Built-in** als grobe Tiefe, Prop-Veto ohne Body-Pose.
- **Low-Power:** Vision 12 fps Cap.
- **Gaze-gated Click** VNFace-Yaw.
- **Zwei-Pinzetten proportional** zur Span-Änderung, nicht ±5 % (`bugfix`).
- **Overlay roh 8 fps.** 1.5.142 Display=raw, Lerp sitzt auf Rohpunkten — Bezier 1.5.137 tot für Knochen. Lerp auf displayJoints.
- **ROI-Pfad tot verdrahten.** palmVisionUsesROI false, Freeze/Thaw/TTL tot-Code feuert noch lastFrozenROI=nil.
- **Continuity Format-Lock 24 fps** request statt 8 fps Fallback.
- **Tests splitten** (GestureTests ~3100 Zeilen). CoordMath split: Overlay, Slot, Pointer. ROI-Totcode 1.5.67–141 kann raus.

Die historische Liste bis 1.5.143: ANALYSE.md.

Nur main.

# Helios Nachtrag 1.5.143 — 2026-09-06

Binary **1.5.143 Build 162**. Sparse/Close-Hand, Bind denser, Gitarre 0,29 tot. Analyse in ANALYSE.md.

## In 1.5.143 gelandet

1. obsLooksLikeHand keep/sparse — 8 fps Sparse hält, Close-Hand groß, Gitarre 0,29 tot
2. palmBindHandsFirst counts — dichte Hand vor Gitarre
3. Tests + MARKETING_VERSION 1.5.143 (Build 162)

`bugfix` 1.5.8 gelesen, nicht gemergt. Dead-Man/Fling/Wischen-Prefs sitzen seit 1.5.127 auf `main`.

## Nächste, zusätzlich

- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`. IOSurface zero-copy statt XPC-Copy.
- **Center Stage hart aus** sobald Zeiger live. Freeze/TTL/ThawProp sind Pflaster gegen Auto-Framing.
- **VNDetectHumanBodyPose als Prop-Veto.** Span-Filter dämpft, Body-Pose entscheidet Gitarre vs Hand.
- **Kalman-Zeiger 2D** constant-velocity statt 1-Euro + Predict. Overlay-Extrapolate sitzt Bild 0…1, nicht Screen-px.
- **OneEuro auf Palm im Bildraum** vor der Homographie. 8 fps Jitter sitzt an der Quelle, nicht am Seam.
- **DisplayPulse je NSScreen**, nicht NSScreen.main. Studio 60 + Laptop 120 zwei Links.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s, eine Karte je Display-UUID.
- **6-Punkt-Kalib RBF** gegen Kissen. Desk-View 45° kippt destBounds — CMAttitude Pitch-Gate < 12°.
- **Overlay CAMetalLayer 90 Hz** aus last-Palm. Lerp+Extrapolate sitzen, Layer fehlt — SwiftUI Overlay 8 fps lügt.
- **Pointer-Gain-Kurve** statt linear. Klein = präzise, Flick = schnell. Continuity 8 fps sonst Overshoot.
- **Continuity IMU-Fusion** iPhone-Motion für 8-fps-Predict. Coast-Vel ist Bildraum.
- **Pinch-Druck tip-Z / LiDAR** Click vs Drag.
- **IOHID Event-Tap** statt CGEvent-Post / CGWarp.
- **Vision requestRevision Latest mit Span-Veto**, nicht hart Revision1 — Revision1 auf macOS 26 lügt Gelenke.
- **Continuity AE-Lock.** Belichtung springt Scale 0,12→0,20.
- **Desk-View Gravity Watchdog:** Pitch > 20° drei Ticks, Overlay-Chip „KIPP“, Warp-Gain 0,4.
- **Wrist-Roll Scroll** wenn Continuity 3D-Joints liefert.
- **Hover-to-Click Dwell 0,55 s** Accessibility, getrennt von Pinch.
- **Zwei-Hand: S1 Zeiger, S2 Scroll** ohne S1-Steal.
- **Per-App Gain aus AX bundle id.**
- **Fill-Cap RMS Auto** wenn Warp vs Overlay > 18 px / 1 s.
- **Mission Control Spaces** als dritter destBounds, Reanchor nach Space-Wechsel.
- **Stereo Continuity+Built-in** als grobe Tiefe, Prop-Veto ohne Body-Pose.
- **Low-Power:** Vision 12 fps Cap.
- **Gaze-gated Click** VNFace-Yaw.
- **Continuity Format-Lock 24 fps** request statt 8 fps Fallback.
- **palmScale Quality:** Wrist-MCP × Finger-Conf-Produkt, nicht nur Median.
- **obsSmoothResets 0,22 Flick.** 8 fps Swipe > 0,22 setzt Smoother zurück — Cap 0,35 oder dt-skaliert.
- **Overlay roh 8 fps.** 1.5.142 Display=raw, Lerp sitzt auf Rohpunkten — Bezier 1.5.137 tot für Knochen. Lerp auf displayJoints.
- **ROI-Pfad tot verdrahten.** palmVisionUsesROI false, Freeze/Thaw/TTL tot-Code feuert noch lastFrozenROI=nil. thawProp emitEmpty wenn lastFrozenROI Altlast.
- **Tests splitten** (GestureTests ~3000 Zeilen). CoordMath split: ROI, Overlay, Slot, Pointer.

Die historische Liste bis 1.5.142: ANALYSE.md.

Nur main.

# Helios Nachtrag 1.5.141 — 2026-09-06

Binary **1.5.141 Build 160**. Bind lastS1, Freeze-Clock nur Freeze, Scale-Pass ROI-Map. Analyse in ANALYSE.md.

## In 1.5.141 gelandet

1. palmBindHandsFirst palms+last — lastS1 vor kleiner Gitarre
2. palmROIFreezeClock — Unfrozen stampt TTL nicht
3. Scale-Pass visionROIMap — handHit in Bildraum
4. Tests + MARKETING_VERSION 1.5.141 (Build 160)

`bugfix` 1.5.8 gelesen, nicht gemergt. Dead-Man/Fling/Wischen-Prefs sitzen seit 1.5.127 auf `main`.

## Nächste, zusätzlich

- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`. IOSurface zero-copy statt XPC-Copy.
- **Center Stage hart aus** sobald Zeiger live. Freeze/TTL/ThawProp sind Pflaster gegen Auto-Framing.
- **VNDetectHumanBodyPose als Prop-Veto.** ThawProp dämpft, Body-Pose entscheidet Gitarre vs Hand.
- **Kalman-Zeiger 2D** constant-velocity statt 1-Euro + Predict. Overlay-Extrapolate sitzt Bild 0…1, nicht Screen-px.
- **OneEuro auf Palm im Bildraum** vor der Homographie. 8 fps Jitter sitzt an der Quelle, nicht am Seam.
- **DisplayPulse je NSScreen**, nicht NSScreen.main. Studio 60 + Laptop 120 zwei Links.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s, eine Karte je Display-UUID.
- **6-Punkt-Kalib RBF** gegen Kissen. Desk-View 45° kippt destBounds — CMAttitude Pitch-Gate < 12°.
- **Overlay CAMetalLayer 90 Hz** aus last-Palm. Lerp+Extrapolate sitzen, Layer fehlt — SwiftUI Overlay 8 fps lügt.
- **Pointer-Gain-Kurve** statt linear. Klein = präzise, Flick = schnell. Continuity 8 fps sonst Overshoot.
- **ROI Freeze expandiert** zur Full statt Binary-Thaw. TTL taut, Expand 1,4×/Tick wäre weicher.
- **Continuity IMU-Fusion** iPhone-Motion für 8-fps-Predict. Coast-Vel ist Bildraum.
- **Pinch-Druck tip-Z / LiDAR** Click vs Drag.
- **IOHID Event-Tap** statt CGEvent-Post / CGWarp.
- **Vision requestRevision / joint-group** statt Observation-first. maximumHandCount 2.
- **Continuity AE-Lock.** Belichtung springt Scale 0,12→0,20.
- **Desk-View Gravity Watchdog:** Pitch > 20° drei Ticks, Overlay-Chip „KIPP“, Warp-Gain 0,4.
- **Wrist-Roll Scroll** wenn Continuity 3D-Joints liefert.
- **Hover-to-Click Dwell 0,55 s** Accessibility, getrennt von Pinch.
- **Zwei-Hand: S1 Zeiger, S2 Scroll** ohne S1-Steal.
- **Per-App Gain aus AX bundle id.**
- **Fill-Cap RMS Auto** wenn Warp vs Overlay > 18 px / 1 s.
- **Mission Control Spaces** als dritter destBounds, Reanchor nach Space-Wechsel.
- **Stereo Continuity+Built-in** als grobe Tiefe, Prop-Veto ohne Body-Pose.
- **Low-Power:** Vision 12 fps Cap.
- **Gaze-gated Click** VNFace-Yaw.
- **palmROI Thaw nur um Hand-BBox**, nicht Full-Frame — Full frisst 125 ms.
- **Tests splitten** (GestureTests ~3000 Zeilen). CoordMath split: ROI, Overlay, Slot, Pointer.

Die historische Liste bis 1.5.140: ANALYSE.md.

Nur main.

# Helios Nachtrag 1.5.140 — 2026-09-06

Binary **1.5.140 Build 159**. ROI Thaw Prop (Gitarre nicht S1), Freeze TTL 400 ms, S1 Laterality Lock, Coast Click 180 ms. Analyse in ANALYSE.md.

## In 1.5.140 gelandet

1. palmROIThawProp — Frozen-Crop Gitarre taut, emitEmpty, nächster Tick Full
2. palmROIFreezeTTL 400 ms — Freeze stirbt auch ohne Empty-Miss
3. palmLateralityBlocksS2 — Gitarre als S2 klaut S1-Seite nicht
4. pinchClickBlocksAfterCoast 180 ms — Dropout-Klick tot auch 8 fps
5. Tests + MARKETING_VERSION 1.5.140 (Build 159)

`bugfix` 1.5.8 gelesen, nicht gemergt.

## Nächste, zusätzlich

- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`. IOSurface zero-copy statt XPC-Copy.
- **Center Stage hart aus** sobald Zeiger live. Freeze/TTL/ThawProp sind Pflaster gegen Auto-Framing.
- **VNDetectHumanBodyPose als Prop-Veto.** ThawProp dämpft, Body-Pose entscheidet Gitarre vs Hand.
- **Kalman-Zeiger 2D** constant-velocity statt 1-Euro + Predict. Overlay-Extrapolate sitzt Bild 0…1, nicht Screen-px.
- **DisplayPulse je NSScreen**, nicht NSScreen.main. Studio 60 + Laptop 120 zwei Links.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s, eine Karte je Display-UUID.
- **6-Punkt-Kalib RBF** gegen Kissen. Desk-View 45° kippt destBounds — CMAttitude Pitch-Gate < 12°.
- **Overlay CAMetalLayer 90 Hz** aus last-Palm. Lerp+Extrapolate sitzen, Layer fehlt — SwiftUI Overlay 8 fps lügt.
- **Continuity IMU-Fusion** iPhone-Motion für 8-fps-Predict. Coast-Vel ist Bildraum.
- **Pinch-Druck tip-Z / LiDAR** Click vs Drag.
- **IOHID Event-Tap** statt CGEvent-Post / CGWarp.
- **Vision requestRevision / joint-group** statt Observation-first. maximumHandCount 2.
- **Continuity AE-Lock.** Belichtung springt Scale 0,12→0,20.
- **Desk-View Gravity Watchdog:** Pitch > 20° drei Ticks, Overlay-Chip „KIPP“, Warp-Gain 0,4.
- **Tests splitten** (GestureTests ~3000 Zeilen). CoordMath split: ROI, Overlay, Slot, Pointer.
- **Hover-to-Click Dwell 0,55 s** Accessibility, getrennt von Pinch.
- **Zwei-Hand: S1 Zeiger, S2 Scroll** ohne S1-Steal.
- **Per-App Gain aus AX bundle id.**
- **Fill-Cap RMS Auto** wenn Warp vs Overlay > 18 px / 1 s.
- **Mission Control Spaces** als dritter destBounds, Reanchor nach Space-Wechsel.
- **Stereo Continuity+Built-in** als grobe Tiefe, Prop-Veto ohne Body-Pose.
- **Low-Power:** Vision 12 fps Cap.
- **Gaze-gated Click** VNFace-Yaw.
- **palmROI Thaw nur um Hand-BBox**, nicht Full-Frame — Full frisst 125 ms.
- **Coast Click vs Drag Band** nach Return, 180 ms tot sitzt — Drag nach Coast getrennt.

Die historische Liste bis 1.5.139: ANALYSE.md.

Nur main.

# Helios Nachtrag 1.5.139 — 2026-09-06

Binary **1.5.139 Build 158**. ROI Thaw Same-Tick/Expand, FullAfter 24 fps, Bind Hands-First. Analyse in ANALYSE.md.

## In 1.5.139 gelandet

1. palmROIThawHit sameTickFull + expandHit — 24 fps Full und Expand tauen Freeze
2. palmROIMissFullAfter / palmROIMissExpandAdvance — Full nach 2 Expand auch 24 fps
3. palmBindHandsFirst — HandTracker Observation-Loop Hands vor Prop
4. Tests + MARKETING_VERSION 1.5.139 (Build 158)

`bugfix` 1.5.8 gelesen, nicht gemergt.

## Nächste, zusätzlich

- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`. IOSurface zero-copy statt XPC-Copy.
- **Center Stage hart aus** sobald Zeiger live. Freeze/Follow sind Pflaster gegen Auto-Framing.
- **VNDetectHumanBodyPose als Prop-Veto.** Jump-Veto dämpft, Clamp hält Scale, Median 8 — Body-Pose entscheidet Gitarre vs Hand.
- **Kalman-Zeiger 2D** constant-velocity statt 1-Euro + Predict. Overlay-Extrapolate sitzt Bild 0…1, nicht Screen-px.
- **DisplayPulse je NSScreen**, nicht NSScreen.main. Studio 60 + Laptop 120 zwei Links.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s, eine Karte je Display-UUID.
- **6-Punkt-Kalib RBF** gegen Kissen. Desk-View 45° kippt destBounds — CMAttitude Pitch-Gate < 12°.
- **Overlay CAMetalLayer 90 Hz** aus last-Palm. Lerp+Extrapolate sitzen, Layer fehlt — SwiftUI Overlay 8 fps lügt.
- **Continuity IMU-Fusion** iPhone-Motion für 8-fps-Predict. Coast-Vel ist Bildraum.
- **Pinch-Druck tip-Z / LiDAR** Click vs Drag.
- **IOHID Event-Tap** statt CGEvent-Post / CGWarp.
- **Vision requestRevision / joint-group** statt Observation-first. maximumHandCount 2.
- **S1 Laterality Lock nach Bind:** Gitarre als S2 darf Laterality von S1 nicht klauen.
- **ROI Freeze TTL 400 ms:** Frozen-Crop stirbt auch ohne Thaw-Hit.
- **Desk-View Gravity Watchdog:** Pitch > 20° drei Ticks, Overlay-Chip „KIPP“, Warp-Gain 0,4.
- **Continuity AE-Lock.** Belichtung springt Scale 0,12→0,20.
- **Tests splitten** (GestureTests ~3000 Zeilen). CoordMath split: ROI, Overlay, Slot, Pointer.

Die historische Liste bis 1.5.138: ANALYSE.md.

Nur main.

# Helios Nachtrag 1.5.138 — 2026-09-06

Binary **1.5.138 Build 157**. Overlay Extrapolate t>1, Lerp 24 fps, ROI Thaw 2 Frozen-Miss, Scale-Ring nur S1. Analyse in ANALYSE.md.

## In 1.5.138 gelandet

1. overlayVel / overlayExtrapolate / overlayBezier t>1 — Coast-Ghost Overlay 90 Hz
2. overlayLerpShould 0,012 — 24 fps sub-frame Lerp
3. palmROIThawMiss 2 Frozen-Miss auch ohne FullNext
4. palmScaleMedianKeeps nur S1 — Gitarre nicht in den Ring
5. Tests + MARKETING_VERSION 1.5.138 (Build 157)

`bugfix` 1.5.8 gelesen, nicht gemergt. Dead-Man/Fling/Wischen-Prefs sitzen seit 1.5.127 auf `main`.

## Nächste, zusätzlich

- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`. IOSurface zero-copy statt XPC-Copy.
- **VNDetectHumanBodyPose als Prop-Veto.** Jump-Veto dämpft, Clamp hält Scale, Median 8 — Body-Pose entscheidet Gitarre vs Hand.
- **Kalman-Zeiger** 2D constant-velocity statt 1-Euro + Predict. Reanchor ist Pflaster. Overlay-Extrapolate sitzt Bild 0…1, nicht Screen-px.
- **DisplayPulse je NSScreen**, nicht NSScreen.main. Studio+Laptop zwei Links.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s, eine Karte je Display-UUID.
- **Two-mode Pointer:** Desk absolut, 0,8 s Dwell relativ.
- **6-Punkt-Kalib** gegen Kissen. RBF statt einer Homographie.
- **Overlay 90 Hz CAMetalLayer** aus last-Palm. Lerp+Extrapolate sitzt, Layer fehlt.
- **Continuity rotation lock.** Desk-View yaw kippt destBounds. CMMotionManager vor destBounds.
- **CGEventSource state matching** statt CGEvent-Post ohne Flags.
- **Vision joint-group / requestRevision** statt Observation-first.
- **Continuity IMU-Fusion** iPhone-Motion für 8-fps-Predict. Overlay-Vel ist Vision-Delta, nicht IMU.
- **Pinch-Druck über tip-Z** Click vs Drag — Pixel-Band sitzt, Druck fehlt. LiDAR-Tiefe wenn Continuity sie liefert.
- **CGEvent-Tap rebase** wenn Mission Control den Cursor wirft.
- **IOHID Event-Tap** statt CGEvent-Post / CGWarp.
- **Center Stage aus** sobald Zeiger live — sonst Gitarre wandert. ROI Freeze sitzt, Stage läuft weiter. Coast-Follow ist Pflaster.
- **Continuity Desk-View gravity** CMAttitude, destBounds nur bei Pitch < 12°.
- **SpaceMap per-UUID Fill-Cap UI** Liste statt nur lastScreen Write.
- **Tests splitten** (GestureTests ~3000 Zeilen).
- **AX kAXFocusedUIElementChanged** statt Poll.
- **Low-Power:** Vision 12 fps Cap.
- **Gaze-gated Click** VNFace-Yaw.
- **Per-App Gestenprofile UI.**
- **Faust = Maustaste Pref.**
- **Metal-Preview 420f** direkt.
- **CADisplayLink preferredFrameRateRange je sichtbarem Overlay-Screen.**
- **destBounds IMU-Pitch Gate** bevor Homographie. Desk-View 45° kippt Warp.
- **S1 Bind laterality+scale** statt Observation-first. Jump-Veto sitzt am Rebind. Ring-Steal tot, Bind bleibt Observation-first.
- **Fill-Cap RMS Auto** wenn Warp vs Overlay > 18 px / 1 s.
- **Click-Lockout 80 ms nach Coast-Return** — sonst Dropout-Klick.
- **Hover-to-Click Dwell 0,55 s** Accessibility, getrennt von Pinch.
- **Wrist-Flexion Click** neben Pinch, wenn Continuity 3D-Joints liefert.
- **Overlay-Knochen Breite aus Joint-Confidence.**
- **Zwei-Hand: S1 Zeiger, S2 Scroll** ohne S1-Steal.
- **Per-App Gain aus AX bundle id**, nicht nur Pref global.
- **Mission Control Spaces** als dritter destBounds, Reanchor nach Space-Wechsel.
- **VoiceOver Cursor-Ansage** 2 Hz, nur bei Move > 24 px.
- **Stereo Continuity+Built-in** als grobe Tiefe, Prop-Veto ohne Body-Pose.

Die historische Liste bis 1.5.137: ANALYSE.md.

Nur main.

# Helios Nachtrag 1.5.137 — 2026-09-06

Binary **1.5.137 Build 156**. Overlay 90 Hz Bezier, Wrist–MCP Median, Span-Veto, Scale Median 8. Analyse in ANALYSE.md.

## In 1.5.137 gelandet

1. overlayLerpShould / overlayBezier / overlayLerpHands — Continuity Overlay 90 Hz
2. AppState lerpPublishedHands — TrackingOverlay folgt Fill, nicht nur Vision
3. palmScaleWristMCP Median + palmScaleSpanVeto — Gitarre nicht Hand-Span
4. palmScaleMedian 8 Ticks vor Kalman
5. Tests + MARKETING_VERSION 1.5.137 (Build 156)

`bugfix` 1.5.8 gelesen, nicht gemergt. Dead-Man/Fling/Wischen-Prefs sitzen seit 1.5.127 auf `main`.

## Nächste, zusätzlich

- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`. IOSurface zero-copy statt XPC-Copy.
- **VNDetectHumanBodyPose als Prop-Veto.** Jump-Veto dämpft, Clamp hält Scale, Median 8 — Body-Pose entscheidet Gitarre vs Hand.
- **Kalman-Zeiger** 2D constant-velocity statt 1-Euro + Predict. Reanchor ist Pflaster. Coast-Predict sitzt Overlay+lastS1, nicht Screen-px.
- **DisplayPulse je NSScreen**, nicht NSScreen.main. Studio+Laptop zwei Links.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s, eine Karte je Display-UUID.
- **Two-mode Pointer:** Desk absolut, 0,8 s Dwell relativ.
- **6-Punkt-Kalib** gegen Kissen. RBF statt einer Homographie.
- **Overlay 90 Hz CAMetalLayer** aus last-Palm. Lerp sitzt, Layer fehlt.
- **Continuity rotation lock.** Desk-View yaw kippt destBounds. CMMotionManager vor destBounds.
- **CGEventSource state matching** statt CGEvent-Post ohne Flags.
- **Vision joint-group / requestRevision** statt Observation-first.
- **Continuity IMU-Fusion** iPhone-Motion für 8-fps-Predict.
- **Pinch-Druck über tip-Z** Click vs Drag — Pixel-Band sitzt, Druck fehlt. LiDAR-Tiefe wenn Continuity sie liefert.
- **CGEvent-Tap rebase** wenn Mission Control den Cursor wirft.
- **IOHID Event-Tap** statt CGEvent-Post / CGWarp.
- **Center Stage aus** sobald Zeiger live — sonst Gitarre wandert. ROI Freeze sitzt, Stage läuft weiter. Coast-Follow ist Pflaster.
- **Continuity Desk-View gravity** CMAttitude, destBounds nur bei Pitch < 12°.
- **SpaceMap per-UUID Fill-Cap UI** Liste statt nur lastScreen Write.
- **Tests splitten** (GestureTests ~2900 Zeilen).
- **AX kAXFocusedUIElementChanged** statt Poll.
- **Low-Power:** Vision 12 fps Cap.
- **Gaze-gated Click** VNFace-Yaw.
- **Per-App Gestenprofile UI.**
- **Faust = Maustaste Pref.**
- **Metal-Preview 420f** direkt.
- **palmROIMiss Full nach 2 Expand-Ticks** auch bei 24 fps, nicht nur Next.
- **CADisplayLink preferredFrameRateRange je sichtbarem Overlay-Screen.**
- **Coast-Ghost Overlay 90 Hz** aus lastVel, unabhängig vom Vision-Tick. Lerp sitzt zwischen Poses, Extrapolate fehlt.
- **palmROIThaw nach 2 Frozen-Miss** auch ohne FullNext, 24 fps Same-Tick Full leer.
- **destBounds IMU-Pitch Gate** bevor Homographie. Desk-View 45° kippt Warp.
- **S1 Bind laterality+scale** statt Observation-first. Jump-Veto sitzt am Rebind.
- **Fill-Cap RMS Auto** wenn Warp vs Overlay > 18 px / 1 s.
- **Overlay-Knochen Bezier mit lastS1Vel Control** statt Smoothstep-Lerp. Control = prev+vel.
- **palmScale Median Ring persist** über Coast-Ghost, nicht nur lastS1Scale.
- **DisplayTick Overlay auch 24 fps** wenn CADisplayLink 120 und Vision 24 — sub-frame Lerp.

Die historische Liste bis 1.5.136: ANALYSE.md.

Nur main.

# Helios Nachtrag 1.5.136 — 2026-09-06

Binary **1.5.136 Build 155**. ROI Thaw FullNext, Coast Follow Predict, FullNext Lock. Analyse in ANALYSE.md.

## In 1.5.136 gelandet

1. palmROIThawHit — FullNext Hit wischt Frozen-ROI
2. palmROICoastFollows / palmROIFollow — Coast folgt Predict, nicht Center Stage
3. roiMissFullNext unter erstem Lock
4. Tests + MARKETING_VERSION 1.5.136 (Build 155)

`bugfix` 1.5.8 gelesen, nicht gemergt. Dead-Man/Fling/Wischen-Prefs sitzen seit 1.5.127 auf `main`.

## Nächste, zusätzlich

- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`. IOSurface zero-copy statt XPC-Copy.
- **VNDetectHumanBodyPose als Prop-Veto.** Jump-Veto dämpft, Clamp hält Scale — Body-Pose entscheidet Gitarre vs Hand.
- **Kalman-Zeiger** 2D constant-velocity statt 1-Euro + Predict. Reanchor ist Pflaster. Coast-Predict sitzt Overlay+lastS1, nicht Screen-px.
- **DisplayPulse je NSScreen**, nicht NSScreen.main. Studio+Laptop zwei Links.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s, eine Karte je Display-UUID.
- **Two-mode Pointer:** Desk absolut, 0,8 s Dwell relativ.
- **6-Punkt-Kalib** gegen Kissen. RBF statt einer Homographie.
- **Overlay 90 Hz CAMetalLayer** aus last-Palm. Lerp sitzt, Layer fehlt.
- **Continuity rotation lock.** Desk-View yaw kippt destBounds. CMMotionManager vor destBounds.
- **CGEventSource state matching** statt CGEvent-Post ohne Flags.
- **Vision joint-group / requestRevision** statt Observation-first.
- **Continuity IMU-Fusion** iPhone-Motion für 8-fps-Predict.
- **Pinch-Druck über tip-Z** Click vs Drag — Pixel-Band sitzt, Druck fehlt. LiDAR-Tiefe wenn Continuity sie liefert.
- **Overlay-Skelett 90 Hz Bezier** zwischen zwei Vision-Poses.
- **CGEvent-Tap rebase** wenn Mission Control den Cursor wirft.
- **IOHID Event-Tap** statt CGEvent-Post / CGWarp.
- **Center Stage aus** sobald Zeiger live — sonst Gitarre wandert. ROI Freeze sitzt, Stage läuft weiter. Coast-Follow ist Pflaster.
- **Continuity Desk-View gravity** CMAttitude, destBounds nur bei Pitch < 12°.
- **SpaceMap per-UUID Fill-Cap UI** Liste statt nur lastScreen Write.
- **palmScale Wrist–MCP vs Finger-span Veto.** Quelle ist Wrist–MCP, Gitarre halluziniert denselben Span. Median 8 Ticks.
- **Tests splitten** (GestureTests ~2900 Zeilen).
- **AX kAXFocusedUIElementChanged** statt Poll.
- **Low-Power:** Vision 12 fps Cap.
- **Gaze-gated Click** VNFace-Yaw.
- **Per-App Gestenprofile UI.**
- **Faust = Maustaste Pref.**
- **Metal-Preview 420f** direkt.
- **palmROIMiss Full nach 2 Expand-Ticks** auch bei 24 fps, nicht nur Next.
- **CADisplayLink preferredFrameRateRange je sichtbarem Overlay-Screen.**
- **Coast-Ghost Overlay 90 Hz** aus lastVel, unabhängig vom Vision-Tick.
- **palmROIThaw nach 2 Frozen-Miss** auch ohne FullNext, 24 fps Same-Tick Full leer.
- **destBounds IMU-Pitch Gate** bevor Homographie. Desk-View 45° kippt Warp.
- **S1 Bind laterality+scale** statt Observation-first. Jump-Veto sitzt am Rebind.
- **Fill-Cap RMS Auto** wenn Warp vs Overlay > 18 px / 1 s.

Die historische Liste bis 1.5.135: ANALYSE.md.

Nur main.

# Helios Nachtrag 1.5.135 — 2026-09-06

Binary **1.5.135 Build 154**. ROI FullNext 8 fps, Empty-Coast, Kalman Clamp, Pulse-Alive Vision. Analyse in ANALYSE.md.

## In 1.5.135 gelandet

1. palmROIMissFullNext — Continuity Expand leer, nächster Tick Full
2. palmCoastEmptyKeeps — emitEmpty Coast statt lastS1-Wisch
3. palmScaleKalman Clamp — Hand nicht in Prop
4. displayLinkPulseAlive — Pulse tot → VISION warpt
5. Tests + MARKETING_VERSION 1.5.135 (Build 154)

`bugfix` 1.5.8 gelesen, nicht gemergt. Dead-Man/Fling/Wischen-Prefs sitzen seit 1.5.127 auf `main`.

## Nächste, zusätzlich

- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`. IOSurface zero-copy statt XPC-Copy.
- **VNDetectHumanBodyPose als Prop-Veto.** Jump-Veto dämpft, Clamp hält Scale — Body-Pose entscheidet Gitarre vs Hand.
- **Kalman-Zeiger** 2D constant-velocity statt 1-Euro + Predict. Reanchor ist Pflaster. Coast-Predict sitzt Overlay+lastS1, nicht Screen-px.
- **DisplayPulse je NSScreen**, nicht NSScreen.main. Studio+Laptop zwei Links.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s, eine Karte je Display-UUID.
- **Two-mode Pointer:** Desk absolut, 0,8 s Dwell relativ.
- **6-Punkt-Kalib** gegen Kissen. RBF statt einer Homographie.
- **Overlay 90 Hz CAMetalLayer** aus last-Palm. Lerp sitzt, Layer fehlt.
- **Continuity rotation lock.** Desk-View yaw kippt destBounds. CMMotionManager vor destBounds.
- **CGEventSource state matching** statt CGEvent-Post ohne Flags.
- **Vision joint-group / requestRevision** statt Observation-first.
- **Continuity IMU-Fusion** iPhone-Motion für 8-fps-Predict.
- **Pinch-Druck über tip-Z** Click vs Drag — Pixel-Band sitzt, Druck fehlt. LiDAR-Tiefe wenn Continuity sie liefert.
- **Overlay-Skelett 90 Hz Bezier** zwischen zwei Vision-Poses.
- **CGEvent-Tap rebase** wenn Mission Control den Cursor wirft.
- **IOHID Event-Tap** statt CGEvent-Post / CGWarp.
- **Center Stage aus** sobald Zeiger live — sonst Gitarre wandert. ROI Freeze sitzt, Stage läuft weiter.
- **Continuity Desk-View gravity** CMAttitude, destBounds nur bei Pitch < 12°.
- **SpaceMap per-UUID Fill-Cap UI** Liste statt nur lastScreen Write.
- **Hand-Scale aus Wrist–MCP** statt BBox. Slot-Kalman sitzt, Quelle bleibt BBox. Clamp 0,279 ist Pflaster.
- **Tests splitten** (GestureTests ~2900 Zeilen).
- **AX kAXFocusedUIElementChanged** statt Poll.
- **Low-Power:** Vision 12 fps Cap.
- **Gaze-gated Click** VNFace-Yaw.
- **Per-App Gestenprofile UI.**
- **Faust = Maustaste Pref.**
- **Metal-Preview 420f** direkt.
- **palmROIMiss Full nach 2 Expand-Ticks** auch bei 24 fps, nicht nur Next.
- **CADisplayLink preferredFrameRateRange je sichtbarem Overlay-Screen.**
- **Coast-Ghost Overlay 90 Hz** aus lastVel, unabhängig vom Vision-Tick.

Die historische Liste bis 1.5.134: ANALYSE.md.

Nur main.

# Helios Nachtrag 1.5.134 — 2026-09-06

Binary **1.5.134 Build 153**. WarpWriter Token, Need Auto, Vel-Decay, Return-Cap, ROI Freeze, Chip Compile. Analyse in ANALYSE.md.

## In 1.5.134 gelandet

1. WarpWriter FILL/VISION Token, warpWriterSkips, warpWriterChip (Compile-Loch 1.5.132)
2. palmCoastNeedAuto — 4 fps Need 3, 8 fps Pref 2
3. palmCoastVelDecay Miss 1 voll, α 0,82
4. palmCoastReturnVel Cap 0,08
5. palmROIFreeze / palmROILocked Lock/Coast
6. Tests + MARKETING_VERSION 1.5.134 (Build 153)

`bugfix` 1.5.8 gelesen, nicht gemergt. Dead-Man/Fling/Wischen-Prefs sitzen seit 1.5.127 auf `main`.

## Nächste, zusätzlich

- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`. IOSurface zero-copy statt XPC-Copy.
- **VNDetectHumanBodyPose als Prop-Veto.** Jump-Veto dämpft, Body-Pose entscheidet Gitarre vs Hand.
- **Kalman-Zeiger** 2D constant-velocity statt 1-Euro + Predict. Reanchor ist Pflaster. Coast-Predict sitzt Overlay+lastS1, nicht Screen-px.
- **palmCoastPredict in Screen-px** nach Homographie. Commit sitzt Bildraum.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s, eine Karte je Display-UUID.
- **Two-mode Pointer:** Desk absolut, 0,8 s Dwell relativ.
- **6-Punkt-Kalib** gegen Kissen. RBF statt einer Homographie.
- **Overlay 90 Hz CAMetalLayer** aus last-Palm. Lerp sitzt, Layer fehlt.
- **Per-Display CADisplayLink** zwei Links Laptop+5K, je Hz. Hz-Of sitzt, ein Link bleibt.
- **Continuity rotation lock.** Desk-View yaw kippt destBounds. CMMotionManager vor destBounds.
- **CGEventSource state matching** statt CGEvent-Post ohne Flags.
- **Vision joint-group / requestRevision** statt Observation-first.
- **Continuity IMU-Fusion** iPhone-Motion für 8-fps-Predict.
- **Pinch-Druck über tip-Z** Click vs Drag — Pixel-Band sitzt, Druck fehlt.
- **Hand-Scale aus Wrist–MCP** statt BBox. Slot-Kalman sitzt, Quelle bleibt BBox.
- **Continuity AE-Lock.** Belichtung springt Scale 0,12→0,20, Jump-Veto hält, AE ist die Ursache.
- **Center Stage aus** sobald Zeiger live — Freeze sitzt, Auto-Framing bleibt die Ursache.
- **IOHID Event-Tap** statt CGEvent-Post / CGWarp.
- **Latency-HUD** Tick zu AX-move, über 40 ms Gain halb.
- **Tests splitten** (GestureTests).
- **AX kAXFocusedUIElementChanged** statt Poll.
- **Low-Power:** Vision 12 fps Cap.
- **Continuity LiDAR depth** als Palm-Z für Pinch-Druck.
- **Adaptive Gain** RMS Reanchor > 8 px halbiert Predict.
- **Relativ-Inertia** nach Fling, analog Trackpad.
- **VNDetectTrajectoriesRequest** für Wurf-Geste.
- **Watch / UWB Pinch-Confirm.**
- **Gaze-gated Click** VNFace-Yaw.
- **iPhone Action Button = Not-Aus.**
- **Menu-Bar Extra:** letzte 8 Gesten.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **Triple-Pinch = Mission Control.**
- **Wrist-Roll = Scroll** pose3D.
- **Leertaste Dead-Man** 0,4 s.
- **Touch/Optic ID Dead-Man.**
- **HandTracker chirality** statt Laterality-Heuristik.
- **Metal-Preview 420f** direkt.
- **Accessibility Zoom folgt Palm.**
- **CGEvent-Tap rebase** wenn Mission Control den Cursor wirft.
- **Zwei-Finger-Scroll** Winkelgeschwindigkeit PIP.
- **Kalib-Heatmap** RMS je Quadrant.
- **Audio-Klick** Spatial-Pan = Screen-X.
- **HUD-Chips Magnet am Cursor.**
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick.**
- **Palm-Reach Not-Aus Pref-Winkel** 20–40°.
- **CADisplayLink(screen:)** je NSScreen statt main-Link.
- **Overlay-Skelett 90 Hz Bezier** zwischen zwei Vision-Poses.

Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

Nur main.

# Helios Nachtrag 1.5.133 — 2026-09-06

Binary **1.5.133 Build 152**. Coast-Vel Return, Joint-Shift, Inject-Skip, Ghost-Coast. Analyse in ANALYSE.md.

## In 1.5.133 gelandet

1. palmCoastVelOnHit — Coast-Return hält lastVel
2. lastS1Palm folgt Predict
3. palmCoastShift / palmCoastDelta — Overlay-Knochen mit
4. warpWriterInjectSkips — Not-Aus skippt CGWarp
5. overlayGhostIsCoast remaining ≤ 0
6. Tests + MARKETING_VERSION 1.5.133 (Build 152)

`bugfix` 1.5.8 gelesen, nicht gemergt. Dead-Man/Fling/Wischen-Prefs sitzen seit 1.5.127 auf `main`.

## Nächste, zusätzlich

- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **WarpWriter enum** statt drei Bool-Skips (Vision/Press/Inject). Ein Token, ein Writer.
- **palmCoastNeed auto aus fps.** 8 fps → 3, 24 fps → 1. Slider bleibt Override.
- **palmCoastVelDecay** µ 0,85 je Tick — 4-Tick-Coast fliegt sonst.
- **CADisplayLink(screen:)** je NSScreen statt main-Link. Hz-Of sitzt, ein Link bleibt.
- **Per-Display CADisplayLink** zwei Links Laptop+5K, je Hz.
- **Continuity AE-Lock.** Belichtung springt Scale 0,12→0,20, Jump-Veto hält, AE ist die Ursache.
- **VNDetectHumanBodyPose als Prop-Veto.** Jump-Veto dämpft, Body-Pose entscheidet Gitarre vs Hand.
- **Kalman-Zeiger** 2D constant-velocity statt 1-Euro + Predict. Reanchor ist Pflaster.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s, eine Karte je Display-UUID.
- **Two-mode Pointer:** Desk absolut, 0,8 s Dwell relativ.
- **6-Punkt-Kalib** gegen Kissen. RBF statt einer Homographie.
- **Overlay 90 Hz CAMetalLayer** aus last-Palm. Lerp sitzt, Layer fehlt.
- **Continuity rotation lock.** Desk-View yaw kippt destBounds. CMMotionManager vor destBounds.
- **CGEventSource state matching** statt CGEvent-Post ohne Flags.
- **Vision joint-group / requestRevision** statt Observation-first.
- **Continuity IMU-Fusion** iPhone-Motion für 8-fps-Predict.
- **Pinch-Druck über tip-Z** Click vs Drag — Pixel-Band sitzt, Druck fehlt.
- **Overlay-Skelett 90 Hz Bezier** zwischen zwei Vision-Poses.
- **CGEvent-Tap rebase** wenn Mission Control den Cursor wirft.
- **IOHID Event-Tap** statt CGEvent-Post / CGWarp.
- **Center Stage aus** sobald Zeiger live — sonst Gitarre wandert.
- **Continuity Desk-View gravity** CMAttitude, destBounds nur bei Pitch < 12°.
- **SpaceMap per-UUID Fill-Cap UI** Liste statt nur lastScreen Write.
- **Hand-Scale aus Wrist–MCP** statt BBox. Slot-Kalman sitzt, Quelle bleibt BBox.
- **Tests splitten** (GestureTests).
- **AX kAXFocusedUIElementChanged** statt Poll.
- **Low-Power:** Vision 12 fps Cap.
- **Gaze-gated Click** VNFace-Yaw.
- **Per-App Gestenprofile UI.**
- **Faust = Maustaste Pref.**
- **Metal-Preview 420f** direkt.
- **palmCoastPredict in Screen-px** nach Homographie bleibt offen — lastS1Palm folgt jetzt, Joints auch; Fill bleibt cursorSmooth.

Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

Nur main.

# Helios Nachtrag 1.5.132 — 2026-09-06

Binary **1.5.132 Build 151**. Press-Skip, Fill während Klick, Coast Predict, Coast Pref, Ghost Alpha, Writer-Chip. Analyse in ANALYSE.md.

## In 1.5.132 gelandet

1. warpWriterPressSkips — Press-Pfad skippt wie Follow wenn Link armed
2. displayTickFillsPress — Fill während mouseDown, nicht AX-Drag
3. palmCoastPredict — Ghost-Palm lastVel, Cap 0,08
4. palmCoastNeedPref 1–4 Slider
5. overlayGhostAlpha Coast 0,50 / Latch 0,35
6. warpWriterChip FILL/VISION
7. Tests + MARKETING_VERSION 1.5.132 (Build 151)

`bugfix` 1.5.8 gelesen, nicht gemergt. Dead-Man/Fling/Wischen-Prefs sitzen seit 1.5.127 auf `main`.

## Nächste, zusätzlich

- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **VNDetectHumanBodyPose als Prop-Veto.** Jump-Veto dämpft, Body-Pose entscheidet Gitarre vs Hand.
- **Kalman-Zeiger** 2D constant-velocity statt 1-Euro + Predict. Reanchor ist Pflaster. Coast-Predict sitzt nur Overlay.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s, eine Karte je Display-UUID.
- **Two-mode Pointer:** Desk absolut, 0,8 s Dwell relativ.
- **6-Punkt-Kalib** gegen Kissen. RBF statt einer Homographie.
- **Overlay 90 Hz CAMetalLayer** aus last-Palm. Lerp sitzt, Layer fehlt.
- **Continuity rotation lock.** Desk-View yaw kippt destBounds. CMMotionManager vor destBounds.
- **CGEventSource state matching** statt CGEvent-Post ohne Flags.
- **Vision joint-group / requestRevision** statt Observation-first.
- **Continuity IMU-Fusion** iPhone-Motion für 8-fps-Predict.
- **Pinch-Druck über tip-Z** Click vs Drag — Pixel-Band sitzt, Druck fehlt.
- **Overlay-Skelett 90 Hz Bezier** zwischen zwei Vision-Poses.
- **CGEvent-Tap rebase** wenn Mission Control den Cursor wirft.
- **Zwei-Finger-Scroll** Winkelgeschwindigkeit PIP.
- **Kalib-Heatmap** RMS je Quadrant.
- **Hand-Scale aus Wrist–MCP** statt BBox. Slot-Kalman sitzt, Quelle bleibt BBox.
- **Audio-Klick** Spatial-Pan = Screen-X.
- **Latency-HUD** Tick zu AX-move, über 40 ms Gain halb.
- **Tests splitten** (GestureTests).
- **AX kAXFocusedUIElementChanged** statt Poll.
- **IOHID Event-Tap** statt CGEvent-Post / CGWarp.
- **Low-Power:** Vision 12 fps Cap.
- **HUD-Chips Magnet am Cursor.**
- **Watch / UWB Pinch-Confirm.**
- **Gaze-gated Click** VNFace-Yaw.
- **iPhone Action Button = Not-Aus.**
- **Menu-Bar Extra:** letzte 8 Gesten.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **Triple-Pinch = Mission Control.**
- **Wrist-Roll = Scroll** pose3D.
- **Palm-Reach Not-Aus Pref-Winkel** 20–40°.
- **Metal-Preview 420f** direkt.
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick.**
- **Leertaste Dead-Man** 0,4 s.
- **Touch/Optic ID Dead-Man.**
- **HandTracker chirality** statt Laterality-Heuristik.
- **Center Stage aus** sobald Zeiger live — sonst Gitarre wandert.
- **pointerReanchor während Mission Control / Spaces.**
- **CADisplayLink(screen:)** je NSScreen statt main-Link. Hz-Of sitzt, ein Link bleibt.
- **Continuity AE-Lock.** Belichtung springt Scale 0,12→0,20, Jump-Veto hält, AE ist die Ursache.
- **SpaceMap per-UUID Fill-Cap UI** Liste statt nur lastScreen Write.
- **Relativ-Inertia** nach Fling, analog Trackpad.
- **VNDetectTrajectoriesRequest** für Wurf-Geste.
- **Accessibility Zoom folgt Palm** statt Cursor-Warp allein.
- **WarpWriter enum** statt zwei Bool-Skips. Ein Token, ein Writer.
- **palmCoastPredict in Screen-px** nach Homographie, nicht nur Overlay-Bildraum.
- **Center-Stage ROI freeze** sobald S1 lockt.
- **Continuity Desk-View gravity** CMAttitude, destBounds nur bei Pitch < 12°.
- **Per-Display CADisplayLink** zwei Links Laptop+5K, je Hz.

Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

Nur main.

# Helios Nachtrag 1.5.131 — 2026-09-06

Binary **1.5.131 Build 150**. Palm-Coast 2 Ticks, ein Warp-Writer. Analyse in ANALYSE.md.

## In 1.5.131 gelandet

1. palmCoastKeepsS1 / palmCoastAdvance — S1-Miss 2 Ticks, lastS1 nicht von S2
2. warpWriterVisionSkips — CADisplayLink armed, Vision skippt CGWarp
3. Tests + MARKETING_VERSION 1.5.131 (Build 150)

`bugfix` 1.5.8 gelesen, nicht gemergt. Dead-Man/Fling/Wischen-Prefs sitzen seit 1.5.127 auf `main`.

## Nächste, zusätzlich

- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **VNDetectHumanBodyPose als Prop-Veto.** Jump-Veto dämpft, Body-Pose entscheidet Gitarre vs Hand.
- **Kalman-Zeiger** 2D constant-velocity statt 1-Euro + Predict. Reanchor ist Pflaster.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s, eine Karte je Display-UUID.
- **Two-mode Pointer:** Desk absolut, 0,8 s Dwell relativ.
- **6-Punkt-Kalib** gegen Kissen. RBF statt einer Homographie.
- **Overlay 90 Hz CAMetalLayer** aus last-Palm. Lerp sitzt, Layer fehlt.
- **Continuity rotation lock.** Desk-View yaw kippt destBounds. CMMotionManager vor destBounds.
- **CGEventSource state matching** statt CGEvent-Post ohne Flags.
- **Vision joint-group / requestRevision** statt Observation-first.
- **Continuity IMU-Fusion** iPhone-Motion für 8-fps-Predict.
- **Pinch-Druck über tip-Z** Click vs Drag — Pixel-Band sitzt, Druck fehlt.
- **Overlay-Skelett 90 Hz Bezier** zwischen zwei Vision-Poses.
- **CGEvent-Tap rebase** wenn Mission Control den Cursor wirft.
- **Zwei-Finger-Scroll** Winkelgeschwindigkeit PIP.
- **Kalib-Heatmap** RMS je Quadrant.
- **Hand-Scale aus Wrist–MCP** statt BBox. Slot-Kalman sitzt, Quelle bleibt BBox.
- **Audio-Klick** Spatial-Pan = Screen-X.
- **Latency-HUD** Tick zu AX-move, über 40 ms Gain halb.
- **Tests splitten** (GestureTests).
- **AX kAXFocusedUIElementChanged** statt Poll.
- **IOHID Event-Tap** statt CGEvent-Post / CGWarp.
- **Low-Power:** Vision 12 fps Cap.
- **HUD-Chips Magnet am Cursor.**
- **Watch / UWB Pinch-Confirm.**
- **Gaze-gated Click** VNFace-Yaw.
- **iPhone Action Button = Not-Aus.**
- **Menu-Bar Extra:** letzte 8 Gesten.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **Triple-Pinch = Mission Control.**
- **Wrist-Roll = Scroll** pose3D.
- **Palm-Reach Not-Aus Pref-Winkel** 20–40°.
- **Metal-Preview 420f** direkt.
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick.**
- **Leertaste Dead-Man** 0,4 s.
- **Touch/Optic ID Dead-Man.**
- **HandTracker chirality** statt Laterality-Heuristik.
- **Center Stage aus** sobald Zeiger live — sonst Gitarre wandert.
- **pointerReanchor während Mission Control / Spaces.**
- **CADisplayLink(screen:)** je NSScreen statt main-Link. Hz-Of sitzt, ein Link bleibt.
- **Continuity AE-Lock.** Belichtung springt Scale 0,12→0,20, Jump-Veto hält, AE ist die Ursache.
- **SpaceMap per-UUID Fill-Cap UI** Liste statt nur lastScreen Write.
- **Relativ-Inertia** nach Fling, analog Trackpad.
- **VNDetectTrajectoriesRequest** für Wurf-Geste.
- **Accessibility Zoom folgt Palm** statt Cursor-Warp allein.
- **palmCoast Pref 1–4 Ticks** Slider. 2 sitzt, Indoor 4 fps braucht 3.
- **displayTick mouseDown Warp** während Drag — Vision skippt, Press-Pfad bleibt.
- **Slot-Ghost Overlay 50 % Alpha** während Coast, nicht voll S1.
- **Warp-Writer HUD** VISION vs FILL, Latency-Chip.
- **S1-Miss Coast + Predict** lastVel 2 Ticks statt Ghost-Pose still.

Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

Nur main.

# Helios Nachtrag 1.5.130 — 2026-09-06

Binary **1.5.130 Build 149**. Scale-Jump-Veto, Fill-Cap UUID, Slot-Kalman, DisplayLink je Screen-Hz, Pad-Name. Analyse in ANALYSE.md.

## In 1.5.130 gelandet

1. slotScaleJumpVeto 0,12 — Gitarre 0,29 stiehlt S1 nicht
2. PalmSlot.scale Kalman + bindSlot prevScale
3. fillCapByUUID / fillCapMap persist analog destEdgePadMap
4. displayLinkHzOf je NSScreen.maximumFramesPerSecond, Arrangement re-arm
5. destEdgePadScreenName ControlPanel
6. Tests + MARKETING_VERSION 1.5.130 (Build 149)

`bugfix` 1.5.8 gelesen, nicht gemergt. Dead-Man/Fling/Wischen-Prefs sitzen seit 1.5.127 auf `main`.

## Nächste, zusätzlich

- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **VNDetectHumanBodyPose als Prop-Veto.** Jump-Veto dämpft, Body-Pose entscheidet Gitarre vs Hand.
- **Kalman-Zeiger** 2D constant-velocity statt 1-Euro + Predict. Reanchor ist Pflaster.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s, eine Karte je Display-UUID.
- **Two-mode Pointer:** Desk absolut, 0,8 s Dwell relativ.
- **6-Punkt-Kalib** gegen Kissen. RBF statt einer Homographie.
- **Overlay 90 Hz CAMetalLayer** aus last-Palm. Lerp sitzt, Layer fehlt.
- **Continuity rotation lock.** Desk-View yaw kippt destBounds. CMMotionManager vor destBounds.
- **CGEventSource state matching** statt CGEvent-Post ohne Flags.
- **Vision joint-group / requestRevision** statt Observation-first.
- **Continuity IMU-Fusion** iPhone-Motion für 8-fps-Predict.
- **Pinch-Druck über tip-Z** Click vs Drag — Pixel-Band sitzt, Druck fehlt.
- **Overlay-Skelett 90 Hz Bezier** zwischen zwei Vision-Poses.
- **CGEvent-Tap rebase** wenn Mission Control den Cursor wirft.
- **Zwei-Finger-Scroll** Winkelgeschwindigkeit PIP.
- **Kalib-Heatmap** RMS je Quadrant.
- **Hand-Scale aus Wrist–MCP** statt BBox. Slot-Kalman sitzt, Quelle bleibt BBox.
- **Audio-Klick** Spatial-Pan = Screen-X.
- **Latency-HUD** Tick zu AX-move, über 40 ms Gain halb.
- **Tests splitten** (GestureTests).
- **AX kAXFocusedUIElementChanged** statt Poll.
- **IOHID Event-Tap** statt CGEvent-Post / CGWarp.
- **Low-Power:** Vision 12 fps Cap.
- **HUD-Chips Magnet am Cursor.**
- **Watch / UWB Pinch-Confirm.**
- **Gaze-gated Click** VNFace-Yaw.
- **iPhone Action Button = Not-Aus.**
- **Menu-Bar Extra:** letzte 8 Gesten.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **Triple-Pinch = Mission Control.**
- **Wrist-Roll = Scroll** pose3D.
- **Palm-Reach Not-Aus Pref-Winkel** 20–40°.
- **Metal-Preview 420f** direkt.
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick.**
- **Leertaste Dead-Man** 0,4 s.
- **Touch/Optic ID Dead-Man.**
- **HandTracker chirality** statt Laterality-Heuristik.
- **Center Stage aus** sobald Zeiger live — sonst Gitarre wandert.
- **pointerReanchor während Mission Control / Spaces.**
- **CADisplayLink(screen:)** je NSScreen statt main-Link. Hz-Of sitzt, ein Link bleibt.
- **Palm-coast 2 Ticks** wenn Vision droppt. 8 fps Miss → S1 tot, Cursor springt auf S2/Prop.
- **Ein Warp-Writer.** Vision-frame und displayTick dürfen nicht beide CGWarp — Double-Warp an der Seam.
- **Continuity AE-Lock.** Belichtung springt Scale 0,12→0,20, Jump-Veto hält, AE ist die Ursache.
- **Slot-Laterality Flip-Debounce** 3 Frames. L/R-Swap bei 8 fps stiehlt S1.
- **SpaceMap per-UUID Fill-Cap UI** Liste statt nur lastScreen Write.
- **Relativ-Inertia** nach Fling, analog Trackpad.
- **VNDetectTrajectoriesRequest** für Wurf-Geste.
- **Accessibility Zoom folgt Palm** statt Cursor-Warp allein.

Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

Nur main.

# Helios Nachtrag 1.5.129 — 2026-09-06

Binary **1.5.129 Build 148**. Fill-Cap Slider, Pinch Click/Drag Cursor-px, Keep-Bit je Slot. Analyse in ANALYSE.md.

## In 1.5.129 gelandet

1. fillCapPrefOf + fillCapLaptop/Studio Pref 8–24 / 12–48, ControlPanel, displayTick restCap
2. pinchClickVsDrag verdrahtet auf pinchCursor0 px — Palm 0,05 tot
3. slotKeepBit + PalmSlot.scale, bindSlot prev Keep — Gitarre 0,29 stiehlt S1 nicht
4. Tests + MARKETING_VERSION 1.5.129 (Build 148)

`bugfix` 1.5.8 gelesen, nicht gemergt. Dead-Man/Fling/Wischen-Prefs sitzen seit 1.5.127 auf `main`.

## Nächste, zusätzlich

- **CADisplayLink je Screen-Hz.** ProMotion 120 vs Studio 60. Ein Link für alle Displays ist Pflaster.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **VNDetectHumanBodyPose als Prop-Veto.** Kalman dämpft, Body-Pose entscheidet Gitarre vs Hand.
- **Kalman-Zeiger** 2D constant-velocity statt 1-Euro + Predict. Reanchor ist Pflaster.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s, eine Karte je Display-UUID.
- **Two-mode Pointer:** Desk absolut, 0,8 s Dwell relativ.
- **6-Punkt-Kalib** gegen Kissen.
- **Overlay 90 Hz CAMetalLayer** aus last-Palm, Lerp sitzt, Layer fehlt.
- **Continuity rotation lock.** Desk-View yaw kippt destBounds.
- **CGEventSource state matching** statt CGEvent-Post ohne Flags.
- **Vision joint-group / requestRevision** statt Observation-first. maximumHandCount 2 sitzt nicht.
- **destEdgePadMap UI** je Display-Name, nicht nur lastScreenID beim Slider.
- **fillCap je Display-UUID** analog destEdgePadMap — Clamshell sonst Studio-28 auf dem Laptop.
- **Continuity IMU-Fusion** iPhone-Motion für 8-fps-Predict.
- **Pinch-Druck über tip-Z** Click vs Drag — Pixel-Band sitzt, Druck fehlt.
- **Overlay-Skelett 90 Hz Bezier** zwischen zwei Vision-Poses.
- **CGEvent-Tap rebase** wenn Mission Control den Cursor wirft.
- **Zwei-Finger-Scroll** Winkelgeschwindigkeit PIP.
- **Kalib-Heatmap** RMS je Quadrant.
- **Hand-Scale aus Wrist–MCP** statt BBox. PalmSlot.scale Kalman nicht nur lastS1.
- **Audio-Klick** Spatial-Pan = Screen-X.
- **Latency-HUD** Tick zu AX-move, über 40 ms Gain halb.
- **Tests splitten** (GestureTests).
- **AX kAXFocusedUIElementChanged** statt Poll.
- **IOHID Event-Tap** statt CGEvent-Post.
- **Low-Power:** Vision 12 fps Cap.
- **HUD-Chips Magnet am Cursor.**
- **Watch / UWB Pinch-Confirm.**
- **Gaze-gated Click** VNFace-Yaw.
- **iPhone Action Button = Not-Aus.**
- **Menu-Bar Extra:** letzte 8 Gesten.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **Triple-Pinch = Mission Control.**
- **Wrist-Roll = Scroll** pose3D.
- **Palm-Reach Not-Aus Pref-Winkel** 20–40°.
- **Metal-Preview 420f** direkt.
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick.**
- **Leertaste Dead-Man** 0,4 s.
- **Touch/Optic ID Dead-Man.**
- **HandTracker chirality** statt Laterality-Heuristik.
- **Center Stage aus** sobald Zeiger live — sonst Gitarre wandert.
- **pointerReanchor während Mission Control / Spaces.**
- **DisplayLink preferredFrameRateRange je NSScreen.maximumFramesPerSecond.**
- **slotBind scale-Jump-Veto.** S1 0,12 → 0,29 ist kein Keep, sondern Objektwechsel.

Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

Nur main.

# Helios Nachtrag 1.5.128 — 2026-09-06

Binary **1.5.128 Build 147**. CADisplayLink 120, Kalman-Scale, Pad-UUID, Keep je Hand. Analyse in ANALYSE.md.

## In 1.5.128 gelandet

1. CADisplayLink 120 Hz DisplayPulse — Timer.common nur Fallback
2. palmScaleKalman q=0,18 lastS1Scale
3. destEdgePadMap je Display-UUID persist
4. pointerKeepPerHand S1 vor S2
5. pinchClickVsDrag Band 6–12 tot
6. fillCapPref Laptop 12 / 5K 28, overlayPalmLerp
7. screenArrangementHash → pollFocus
8. Tests + MARKETING_VERSION 1.5.128 (Build 147)

`bugfix` 1.5.8 gelesen, nicht gemergt. Dead-Man/Fling/Wischen-Prefs sitzen seit 1.5.127 auf `main`.

## Nächste, zusätzlich

- **CADisplayLink je Screen-Hz.** ProMotion 120 vs Studio 60. Ein Link für alle Displays ist Pflaster.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **VNDetectHumanBodyPose als Prop-Veto.** Kalman dämpft, Body-Pose entscheidet Gitarre vs Hand.
- **Kalman-Zeiger** 2D constant-velocity statt 1-Euro + Predict. Reanchor ist Pflaster.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s, eine Karte je Display-UUID.
- **Two-mode Pointer:** Desk absolut, 0,8 s Dwell relativ.
- **6-Punkt-Kalib** gegen Kissen.
- **Overlay 90 Hz CAMetalLayer** aus last-Palm, Lerp sitzt, Layer fehlt.
- **Continuity rotation lock.** Desk-View yaw kippt destBounds.
- **CGEventSource state matching** statt CGEvent-Post ohne Flags.
- **Vision joint-group / requestRevision** statt Observation-first. maximumHandCount 2 sitzt nicht.
- **Fill-Cap Slider** Laptop vs 5K, Pref sitzt hart 12/28.
- **destEdgePadMap UI** je Display-Name, nicht nur lastScreenID beim Slider.
- **Continuity IMU-Fusion** iPhone-Motion für 8-fps-Predict.
- **Pinch-Druck über tip-Z** Click vs Drag.
- **Overlay-Skelett 90 Hz Bezier** zwischen zwei Vision-Poses.
- **CGEvent-Tap rebase** wenn Mission Control den Cursor wirft.
- **Zwei-Finger-Scroll** Winkelgeschwindigkeit PIP.
- **Kalib-Heatmap** RMS je Quadrant.
- **Hand-Scale aus Wrist–MCP** statt BBox.
- **Audio-Klick** Spatial-Pan = Screen-X.
- **Latency-HUD** Tick zu AX-move, über 40 ms Gain halb.
- **Tests splitten** (GestureTests).
- **AX kAXFocusedUIElementChanged** statt Poll.
- **IOHID Event-Tap** statt CGEvent-Post.
- **Low-Power:** Vision 12 fps Cap.
- **HUD-Chips Magnet am Cursor.**
- **Watch / UWB Pinch-Confirm.**
- **Gaze-gated Click** VNFace-Yaw.
- **iPhone Action Button = Not-Aus.**
- **Menu-Bar Extra:** letzte 8 Gesten.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **Triple-Pinch = Mission Control.**
- **Wrist-Roll = Scroll** pose3D.
- **Palm-Reach Not-Aus Pref-Winkel** 20–40°.
- **Metal-Preview 420f** direkt.
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick.**
- **Leertaste Dead-Man** 0,4 s.
- **Touch/Optic ID Dead-Man.**
- **HandTracker chirality** statt Laterality-Heuristik.
- **Center Stage aus** sobald Zeiger live — sonst Gitarre wandert.
- **pointerReanchor während Mission Control / Spaces.**
- **DisplayLink preferredFrameRateRange je NSScreen.maximumFramesPerSecond.**

Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

Nur main.

# Helios Nachtrag 1.5.127 — 2026-09-06

Binary **1.5.127 Build 146**. lastScreenID folgt, Overlap auto, Faust 2-Frame, Reanchor, bugfix-Prefs. Analyse in ANALYSE.md.

## In 1.5.127 gelandet

1. screenKeySeed folgt Nachbarschirm — Seam hält
2. destEdgeOverlapGap aus CGDisplayBounds
3. fistClickDebounce 2 Frames
4. pointerReanchor NSEvent.mouseLocation RMS > 8
5. Dead-Man Pref 1,6–8 s, Fling-Fenster 120–550 ms, Wischen nur offene Hand (bugfix 1.5.8)
6. didChangeScreenParameters → pollFocus
7. Tests + MARKETING_VERSION 1.5.127 (Build 146)

`bugfix` 1.5.8 gelesen, nicht gemergt. Die drei Prefs sitzen jetzt auf `main`.

## Nächste, zusätzlich

- **CADisplayLink / CVDisplayLink** statt Timer .common. Target 120 Hz. Reanchor sitzt, vsync fehlt.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **VNDetectHumanBodyPose als Prop-Veto.** Scale-Gate 0,28 zittert weiter.
- **palmScale Kalman** 0,035…0,31 statt Keep-Hysterese allein.
- **destEdgePad Pref je Display-UUID** persist. Laptop 24, 5K 64.
- **Fill-Cap Pref** Laptop vs 5K, getrennt von Warp-Cap.
- **Kalman-Zeiger** 2D constant-velocity statt 1-Euro + Predict. Reanchor ist Pflaster.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s, eine Karte je Display-UUID.
- **Two-mode Pointer:** Desk absolut, 0,8 s Dwell relativ.
- **6-Punkt-Kalib** gegen Kissen.
- **Overlay 90 Hz CAMetalLayer** aus last-Palm, unabhängig von Continuity 8 fps.
- **Continuity rotation lock.** Desk-View yaw kippt destBounds.
- **CGEventSource state matching** statt CGEvent-Post ohne Flags.
- **Click/Drag Pinch-Hysterese getrennt.** Pinch-Drag stiehlt Click-Lock.
- **Vision joint-group / requestRevision** statt Observation-first. maximumHandCount 2 sitzt nicht.
- **Per-Hand Keep-Bit** statt nur lastS1.
- **Screen-Arrangement Snapshot** UUID + quartzBounds — Clamshell-Wake ohne Recalib.
- **Continuity IMU-Fusion** iPhone-Motion für 8-fps-Predict.
- **Pinch-Druck über tip-Z** Click vs Drag.
- **Overlay-Skelett 90 Hz Bezier** zwischen zwei Vision-Poses.
- **CGEvent-Tap rebase** wenn Mission Control den Cursor wirft.
- **Zwei-Finger-Scroll** Winkelgeschwindigkeit PIP.
- **Kalib-Heatmap** RMS je Quadrant.
- **Hand-Scale aus Wrist–MCP** statt BBox.
- **Audio-Klick** Spatial-Pan = Screen-X.
- **Latency-HUD** Tick zu AX-move, über 40 ms Gain halb.
- **Tests splitten** (GestureTests).
- **AX kAXFocusedUIElementChanged** statt Poll.
- **IOHID Event-Tap** statt CGEvent-Post.
- **Low-Power:** Vision 12 fps Cap.
- **HUD-Chips Magnet am Cursor.**
- **Watch / UWB Pinch-Confirm.**
- **Gaze-gated Click** VNFace-Yaw.
- **iPhone Action Button = Not-Aus.**
- **Menu-Bar Extra:** letzte 8 Gesten.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **Triple-Pinch = Mission Control.**
- **Wrist-Roll = Scroll** pose3D.
- **Palm-Reach Not-Aus Pref-Winkel** 20–40°.
- **Metal-Preview 420f** direkt.
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick.**
- **Leertaste Dead-Man** 0,4 s.
- **Touch/Optic ID Dead-Man.**

Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

Nur main.

# Helios Nachtrag 1.5.126 — 2026-09-06

Binary **1.5.126 Build 145**. lastScreenID Relativ-Seed, Prop-Alloc keep:false. Analyse in ANALYSE.md.

## In 1.5.126 gelandet

1. screenKeySeed — Relativ-Pfad lastScreenID aus destEdgeNearest
2. slotAllocMinID keep:false Default — neu 0,29 Prop S2
3. Tests + MARKETING_VERSION 1.5.126 (Build 145)

`bugfix` 1.5.8 gelesen, nicht gemergt. Fling-Fenster Pref, Dead-Man 2–8 s, Wischen nur offene Hand bleiben Prefs.

## Nächste, zusätzlich

- **NSApplication.didChangeScreenParameters** → SpaceMap + destEdge Pad neu. Clamshell/Studio sonst alte Homographie.
- **destEdge Overlap auto-measure** aus CGDisplayBounds-Intersection, nicht hart 16/40 px.
- **Seam dual-map lerp 80 ms** Laptop-Homographie → 5K-Homographie statt Snap oder Blend-zurück.
- **Fist-Click 2-Frame-Debounce.** 8 fps Faust-Zittern sonst Klick-Burst.
- **Vision joint-group / requestRevision** statt Observation-first. maximumHandCount 2 sitzt nicht.
- **Overlay 90 Hz CAMetalLayer** aus last-Palm, unabhängig von Continuity 8 fps.
- **Continuity rotation lock.** Desk-View yaw kippt destBounds.
- **CGEventSource state matching** statt CGEvent-Post ohne Flags.
- **Click/Drag Pinch-Hysterese getrennt.** Pinch-Drag stiehlt Click-Lock.
- **CADisplayLink / CVDisplayLink** statt Timer .common. Target 120 Hz.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **VNDetectHumanBodyPose als Prop-Veto.**
- **destEdgePad Pref je Display-UUID** persist. Laptop 24, 5K 64.
- **Fill-Cap Pref** Laptop vs 5K, getrennt von Warp-Cap.
- **Kalman-Zeiger** 2D constant-velocity statt 1-Euro + Predict.
- **NSEvent.mouseLocation Ground-Truth** 4 Hz, RMS > 8 px Reanchor.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s, eine Karte je Display-UUID.
- **Two-mode Pointer:** Desk absolut, 0,8 s Dwell relativ.
- **6-Punkt-Kalib** gegen Kissen.
- **Dead-Man:** Touch/Optic ID, Leertaste 0,4 s, Faust-Timeout Pref 2–8 s (bugfix 1.5.8).
- **Fling-Fenster Pref** und **Wischen nur offene Hand** (bugfix 1.5.8).
- **Latency-HUD** Tick zu AX-move, über 40 ms Gain halb.
- **Tests splitten** (GestureTests).
- **AX kAXFocusedUIElementChanged** statt Poll.
- **IOHID Event-Tap** statt CGEvent-Post.
- **Low-Power:** Vision 12 fps Cap.
- **palmScale Kalman** 0,035…0,31 statt Keep-Hysterese allein.
- **Per-Hand Keep-Bit** statt nur lastS1 — slotBindSkipsProp keep:true bleibt Gitarren-Diebstahl wenn S1 lebt.
- **HUD-Chips Magnet am Cursor.**
- **Pointer-Accel je Display-Hz.**
- **Watch / UWB Pinch-Confirm.**
- **Gaze-gated Click** VNFace-Yaw.
- **iPhone Action Button = Not-Aus.**
- **Menu-Bar Extra:** letzte 8 Gesten.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **Triple-Pinch = Mission Control.**
- **Wrist-Roll = Scroll** pose3D.
- **Palm-Reach Not-Aus Pref-Winkel** 20–40°.
- **Metal-Preview 420f** direkt.
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick.**

# Helios Nachtrag 1.5.125 — 2026-09-06

Binary **1.5.125 Build 144**. destClampMap Latch, Keep 0,03, Naht-Hold Pref. Analyse in ANALYSE.md.

## In 1.5.125 gelandet

1. destClampMapHolds Latch — leeres currentScreenID nur 1 Screen
2. destClampSameScreen — Map keine Mauer wenn Punkt auf dem 5K
3. clampMapped Zielpunkt, nicht cursorSmooth
4. palmHandScaleHyst 0,03 — Keep 0,29 S1
5. destEdgeSkipPref 40–240 ms ControlPanel „Naht-Hold“
6. Tests + MARKETING_VERSION 1.5.125 (Build 144)

`bugfix` 1.5.8 gelesen, nicht gemergt. Fling-Fenster Pref, Dead-Man 2–8 s, Wischen nur offene Hand bleiben Prefs.

## Nächste, zusätzlich

- **Fling-Fenster Pref** aus bugfix 1.5.8. Fenster-Wurf 0,18–0,55 s statt hart.
- **Dead-Man Faust-Timeout Pref 2–8 s** aus bugfix 1.5.8.
- **Wischen nur offene Hand** Pref-Toggle (bugfix 1.5.8).
- **CADisplayLink / CVDisplayLink** statt Timer .common. Target 120 Hz.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **VNDetectHumanBodyPose als Prop-Veto.**
- **destEdgePad Pref je Display-UUID** persist. Laptop 24, 5K 64.
- **Fill-Cap Pref** Laptop vs 5K, getrennt von Warp-Cap.
- **Kalman-Zeiger** 2D constant-velocity statt 1-Euro + Predict.
- **NSEvent.mouseLocation Ground-Truth** 4 Hz, RMS > 8 px Reanchor.
- **Overlay CAMetalLayer** unabhängig von der Kamera.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s, eine Karte je Display-UUID.
- **Two-mode Pointer:** Desk absolut, 0,8 s Dwell relativ.
- **6-Punkt-Kalib** gegen Kissen.
- **Dead-Man:** Touch/Optic ID, Leertaste 0,4 s.
- **maximumHandCount 2 + Joint-Group** statt Observation-first.
- **Latency-HUD** Tick zu AX-move, über 40 ms Gain halb.
- **Tests splitten** (GestureTests).
- **AX kAXFocusedUIElementChanged** statt Poll.
- **IOHID Event-Tap** statt CGEvent-Post.
- **Low-Power:** Vision 12 fps Cap.
- **lastScreenID Relativ-Pfad seed** aus destEdgeNearest beim ersten Tick.
- **palmScale Kalman** 0,035…0,31 statt Keep-Hysterese allein.
- **Per-Hand Keep-Bit** statt nur lastS1.
- **HUD-Chips Magnet am Cursor.**
- **Pointer-Accel je Display-Hz.**
- **Watch / UWB Pinch-Confirm.**
- **Gaze-gated Click** VNFace-Yaw.
- **iPhone Action Button = Not-Aus.**
- **Menu-Bar Extra:** letzte 8 Gesten.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **Triple-Pinch = Mission Control.**
- **Wrist-Roll = Scroll** pose3D.
- **Palm-Reach Not-Aus Pref-Winkel** 20–40°.
- **Metal-Preview 420f** direkt.
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick.**

# Helios Nachtrag 1.5.123 — 2026-09-06


Binary **1.5.123 Build 143**. Prop nie S1, 40 px Overlap 5K-Pad, destBounds = quartzBounds. Analyse in ANALYSE.md.

## In 1.5.123 gelandet

1. slotAllocMinID / slotBindSkipsProp — Prop nie S1
2. pointerKeepPrefersHand — Pool S1 vor Observation-first
3. destEdgeNearest min Interior < Gap → größerer Schirm
4. destEdgeScreenHolds — displayTick Zielschirm 160 ms
5. visQuartz + SpaceMap.load quartzBounds
6. Tests + MARKETING_VERSION 1.5.123 (Build 143)

`bugfix` 1.5.8 gelesen, nicht gemergt. Fling-Fenster Pref, Dead-Man 2–8 s, Wischen nur offene Hand bleiben Prefs.

## Nächste, zusätzlich

- **CADisplayLink / CVDisplayLink** statt Timer .common. Target 120 Hz. destEdgeScreenHolds sitzt, vsync fehlt.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **VNDetectHumanBodyPose als Prop-Veto** statt Hart-Schwelle 0,28 — Continuity zittert um 0,28.
- **palmScale Kalman** 0,035…0,28 statt Hart-Schwelle.
- **destEdgeSkip Pref** 40–240 ms im ControlPanel.
- **destEdgePad Pref je Display-UUID** persist.
- **Fill-Cap Pref** Laptop vs 5K, getrennt von Warp-Cap.
- **Kalman-Zeiger** 2D constant-velocity statt 1-Euro + Predict.
- **HUD-Chips Magnet am Cursor**, nicht Top-Bar.
- **NSEvent.mouseLocation Ground-Truth** vs CGWarp-Drift. 4 Hz, RMS > 8 px = reanchor.
- **Touch ID / Optic ID Dead-Man.**
- **Leertaste Dead-Man** 0,4 s.
- **Two-mode Pointer:** Desk absolut, 0,8 s Dwell relativ.
- **6-Punkt-Kalib** gegen Kissenverzerrung.
- **Tests splitted.** GestureTests > 2,6k Zeilen.
- **Fling-Fenster Pref** aus bugfix 1.5.8.
- **Dead-Man Faust-Timeout Pref 2–8 s** aus bugfix 1.5.8.
- **Wischen nur offene Hand** Pref-Toggle (bugfix 1.5.8).
- **maximumHandCount 2 + Joint-Group** statt Slot S1/S2 Observation-first — Scale-Gate sitzt, Vision-Order bleibt.
- **Latency-HUD** Kamera-Tick → AX-move. Über 40 ms Gain halbieren.
- **Overlay CAMetalLayer** unabhängig von der Kamera-Rate.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s.
- **AX kAXFocusedUIElementChanged** statt Poll.

# Helios Nachtrag 1.5.122 — 2026-09-06

Binary **1.5.122 Build 142**. Prop-S1 Crop an S2, Clamp kein Laptop-first, Seam-Hold kein Wall. Analyse in ANALYSE.md.

## In 1.5.122 gelandet

1. palmROISlotPalm Prop → erste handgroße (S2), nur Prop Full
2. palmROISecondHands — Full nur ≥2 echte Hände
3. lastS1 nur handgroß
4. destClampScreen destEdgeNearest statt screens.first
5. screenSeamHolds gibt Seam an den Nachbarschirm ab
6. destEdgeNearest Overlap: größerer Schirm
7. clampQuartz / screenContaining quartzBounds
8. Tests + MARKETING_VERSION 1.5.122 (Build 142)

`bugfix` 1.5.8 gelesen, nicht gemergt. Fling-Fenster Pref, Dead-Man 2–8 s, Wischen nur offene Hand bleiben Prefs.

## Nächste, zusätzlich

- **destEdgeSkip Pref** 40–240 ms im ControlPanel, nicht nur frameDt.
- **destEdgePad Pref je Display-UUID** persist.
- **Fill-Cap Pref** Laptop vs 5K, getrennt von Warp-Cap.
- **Kalman-Zeiger** 2D constant-velocity statt 1-Euro + Predict.
- **HUD-Chips Magnet am Cursor**, nicht Top-Bar.
- **Pointer-Accel je Display-Hz.**
- **CADisplayLink / CVDisplayLink** statt Timer .common. Target 120 Hz.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **NSEvent.mouseLocation Ground-Truth** vs CGWarp-Drift. 4 Hz, RMS > 8 px = reanchor.
- **Touch ID / Optic ID Dead-Man.**
- **SpaceMap je Display-UUID.** destBounds auf quartzBounds — Homographie sonst NSScreen.frame.
- **Two-mode Pointer:** Desk absolut, 0,8 s Dwell relativ.
- **6-Punkt-Kalib** gegen Kissenverzerrung.
- **Watch / UWB Pinch-Confirm.**
- **Gaze-gated Click** VNFace-Yaw.
- **IOHID Event-Tap** statt CGEvent-Post.
- **Low-Power Akku:** Vision 12 fps Cap.
- **Tests splitted.** GestureTests > 2,6k Zeilen.
- **Fling-Fenster Pref** aus bugfix 1.5.8.
- **Dead-Man Faust-Timeout Pref 2–8 s** aus bugfix 1.5.8.
- **Wischen nur offene Hand** Pref-Toggle (bugfix 1.5.8).
- **Palm-Reach Not-Aus Pref-Winkel** 20–40°.
- **Metal-Preview 420f** direkt.
- **Latency-HUD** Kamera-Tick → AX-move. Über 40 ms Gain halbieren.
- **iPhone Action Button = Not-Aus.**
- **Menu-Bar Extra:** letzte 8 Gesten.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **Triple-Pinch = Mission Control.**
- **Wrist-Roll = Scroll** pose3D.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s.
- **overlayChipCap Pref** 4–8.
- **destEdgeHasNeighbor Gap Pref** 16–64 px.
- **Click-Lock vs destEdgeApplies.**
- **Continuity LiDAR-Z** statt Vision-3D. VNDetectHumanBodyPose Prop-Veto.
- **AX kAXFocusedUIElementChanged** statt Poll.
- **Audio-Tick bei Pinch-Down.**
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick.**
- **jointConfEMA Alpha Pref** 0,20–0,50.
- **pinchWristMAD Rest Pref** 0,008–0,020.
- **Relativ-Snap Pref** 0,40–2,0 s.
- **Occlusion Pref** 1–3 Ticks / TTL 0,20–0,80.
- **Two-Hand Scale Gain Pref.**
- **PIP-Deflexion Pref 20–40°.**
- **Warp-Cap und Teleport-Mul Pref getrennt.**
- **palmVelScreen Pref-TTL** 0,20–1,0.
- **destEdgePad Pref je Hz:** 8 fps Continuity Pad × 1,4.
- **AX-Warp Reanchor nach destEdgeCross** 1 Frame.
- **Overlay CAMetalLayer** unabhängig von der Kamera-Rate.
- **Accessibility Switch Control** als zweiter Dead-Man.
- **Leertaste Dead-Man** 0,4 s.
- **palmScale Kalman** 0,035…0,28 statt Hart-Schwelle — Continuity zittert um 0,28.
- **HandTracker S1-Latch:** Prop darf Slot nicht stehlen — scale-gate vor Observation-first.
- **ROI-Pad Pref** 1,4–2,2× Palma.
- **Cursor-Trail 8 Samples** HUD.
- **maximumHandCount 2 + Joint-Group** statt Slot S1/S2 Observation-first.
- **displayTick vsync:** CADisplayLink, nicht Timer.common — 90 Hz Fill driftet gegen ProMotion.
- **destEdgeScreenAt Hold 160 ms Zielschirm** nach Cross — Clamp sitzt, PadAt kann nachziehen.
- **SpaceMap destBounds = quartzBounds** der Kalib, nicht NSScreen.frame.

Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

Nur main.

# Helios Nachtrag 1.5.121 — 2026-09-06

Binary **1.5.121 Build 141**. Prop-S1 kein Crop, Zweit-Hand immer Full, ROI wieder an für handgroße S1. Analyse in ANALYSE.md.

## In 1.5.121 gelandet

1. palmScaleIsHand 0,035…0,28 — Gitarre/Rumpf kein Crop
2. palmROISlotPalm Prop-S1 nil (Full), last-S1 keep nur handgroß
3. palmVisionUsesROI true — Crop nur um Hand
4. palmROISecondNils immer true — 8 fps Kill-Hand Full
5. Tests + MARKETING_VERSION 1.5.121 (Build 141)

`bugfix` 1.5.8 gelesen, nicht gemergt. Fling-Fenster Pref, Dead-Man 2–8 s, Wischen nur offene Hand bleiben Prefs.

## Nächste, zusätzlich

- **Prop-S1 Crop an erste handgroße (S2)** statt Full — 8 fps Tick, echte Hand im Crop.
- **VNDetectHumanBodyPose Prop-Veto.** Gitarre/Rumpf ist Body, nicht Hand. Scale-Gate 0,28 ist hart.
- **palmScale Kalman** 0,035…0,28 statt Hart-Schwelle. Continuity 8 fps zittert um 0,28.
- **Continuity LiDAR-Z** als SlotPalm-Scale statt Vision-bbox.
- **HandTracker S1-Latch:** Prop darf Slot nicht stehlen — scale-gate vor Observation-first.
- **visionROIMap Heuristik halten.** Apple Vision ROI- vs Image-space gemischt; nicht pauschal mappen.
- **palmROIMissRetries 8 fps Expand** sitzt; Full-Pass nur 24 fps — Pref wenn Continuity 15 fps liefert.
- **maximumHandCount 2 + Joint-Group** statt Slot S1/S2 Observation-first.
- **destEdgeSkip Pref** 40–240 ms im ControlPanel, nicht nur frameDt.
- **destEdgePad Pref je Display-UUID** persist.
- **Fill-Cap Pref** Laptop vs 5K, getrennt von Warp-Cap.
- **Kalman-Zeiger** 2D constant-velocity statt 1-Euro + Predict. Predict war der Seam-Overshoot.
- **HUD-Chips Magnet am Cursor**, nicht Top-Bar.
- **Pointer-Accel je Display-Hz.**
- **CADisplayLink / CVDisplayLink** statt Timer .common. Target 120 Hz.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **NSEvent.mouseLocation Ground-Truth** vs CGWarp-Drift. 4 Hz, RMS > 8 px = reanchor.
- **Touch ID / Optic ID Dead-Man.**
- **SpaceMap je Display-UUID.**
- **Two-mode Pointer:** Desk absolut, 0,8 s Dwell relativ.
- **6-Punkt-Kalib** gegen Kissenverzerrung.
- **Watch / UWB Pinch-Confirm.**
- **Gaze-gated Click** VNFace-Yaw.
- **IOHID Event-Tap** statt CGEvent-Post.
- **Low-Power Akku:** Vision 12 fps Cap.
- **Tests splitted.** GestureTests > 2,6k Zeilen.
- **Fling-Fenster Pref** aus bugfix 1.5.8.
- **Dead-Man Faust-Timeout Pref 2–8 s** aus bugfix 1.5.8.
- **Wischen nur offene Hand** Pref-Toggle (bugfix 1.5.8).
- **Palm-Reach Not-Aus Pref-Winkel** 20–40°.
- **Metal-Preview 420f** direkt.
- **Latency-HUD** Kamera-Tick → AX-move. Über 40 ms Gain halbieren.
- **iPhone Action Button = Not-Aus.**
- **Menu-Bar Extra:** letzte 8 Gesten.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **Triple-Pinch = Mission Control.**
- **Wrist-Roll = Scroll** pose3D.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s.
- **overlayChipCap Pref** 4–8.
- **destEdgeHasNeighbor Gap Pref** 16–64 px.
- **Click-Lock vs destEdgeApplies.**
- **Continuity LiDAR-Z** statt Vision-3D.
- **AX kAXFocusedUIElementChanged** statt Poll.
- **Audio-Tick bei Pinch-Down.**
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick.**
- **jointConfEMA Alpha Pref** 0,20–0,50.
- **pinchWristMAD Rest Pref** 0,008–0,020.
- **Relativ-Snap Pref** 0,40–2,0 s.
- **Occlusion Pref** 1–3 Ticks / TTL 0,20–0,80.
- **Two-Hand Scale Gain Pref.**
- **PIP-Deflexion Pref 20–40°.**
- **Warp-Cap und Teleport-Mul Pref getrennt.**
- **palmVelScreen Pref-TTL** 0,20–1,0.
- **destEdgePad Pref je Hz:** 8 fps Continuity Pad × 1,4.
- **AX-Warp Reanchor nach destEdgeCross** 1 Frame — Snap sitzt, AX kann nachziehen.
- **Overlay CAMetalLayer** unabhängig von der Kamera-Rate.
- **Accessibility Switch Control** als zweiter Dead-Man.
- **Leertaste Dead-Man** 0,4 s — Faust-Timeout reicht nicht am Schreibtisch.
- **Per-Monitor SpaceMap Homographie**, nicht eine Karte für Laptop+5K.
- **SpaceMap destBounds auf quartzBounds.** Homographie sonst NSScreen.frame, destEdge Hardware — zwei Seam-Welten.
- **destEdgeScreenAt Hold nach Cross 160 ms Zielschirm.** displayTick 90 Hz sonst Laptop-Pad im Rest-Overlap.
- **Cursor-Trail 8 Samples** HUD, Diagnose ohne Console.
- **Hand-Scale Pref** 0,20–0,40 statt Hart 0,28.
- **ROI-Pad Pref** 1,4–2,2× Palma — 1,8 fraß den Rand bei 8 fps nicht, fraß den Tick bei 24.
- **S1-Prop: Slot nicht Observation-first** — BodyPose oder Scale vor id == "S1".

Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

Nur main.

# Helios Nachtrag 1.5.120 — 2026-09-06

Binary **1.5.120 Build 140**. destEdgeSkip 160 ms + frameDt, Blend/Predict tot nach Cross, screenKey innerster, toward-Dead, palmVel EMA, CGDisplayBounds. Analyse in ANALYSE.md.

## In 1.5.120 gelandet

1. destEdgeSkipHold 160 ms / 1,25·Tick — 8 fps Hold stirbt nicht vor dem nächsten Frame
2. screenBlendSkipsCross / pointerPredictSkipsCross — Cross snappt, kein Rückzug
3. screenKey destEdgeNearest — Überlapp kein Laptop-first
4. destEdgeTowardOf 4 px — Noise nicht falsche Kante
5. palmVelScreenEMA 8 fps — destEdgeStep sieht Coast, nicht JUMP
6. quartzBounds = CGDisplayBounds roh (kein fromCocoa-Flip), Relativ+Clamp dieselbe Quelle
7. ControlPanel Pad destEdgeNearest
8. Tests + MARKETING_VERSION 1.5.120 (Build 140)

`bugfix` 1.5.8 gelesen, nicht gemergt. Fling-Fenster Pref, Dead-Man 2–8 s, Wischen nur offene Hand bleiben Prefs.

## Nächste, zusätzlich

- **destEdgeSkip Pref** 40–240 ms im ControlPanel, nicht nur frameDt.
- **destEdgePad Pref je Display-UUID** persist.
- **Fill-Cap Pref** Laptop vs 5K, getrennt von Warp-Cap.
- **Kalman-Zeiger** 2D constant-velocity statt 1-Euro + Predict. Predict war der Seam-Overshoot.
- **HUD-Chips Magnet am Cursor**, nicht Top-Bar.
- **Pointer-Accel je Display-Hz.**
- **CADisplayLink / CVDisplayLink** statt Timer .common. Target 120 Hz.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **NSEvent.mouseLocation Ground-Truth** vs CGWarp-Drift. 4 Hz, RMS > 8 px = reanchor.
- **Touch ID / Optic ID Dead-Man.**
- **SpaceMap je Display-UUID.**
- **Two-mode Pointer:** Desk absolut, 0,8 s Dwell relativ.
- **6-Punkt-Kalib** gegen Kissenverzerrung.
- **Watch / UWB Pinch-Confirm.**
- **Gaze-gated Click** VNFace-Yaw.
- **IOHID Event-Tap** statt CGEvent-Post.
- **Low-Power Akku:** Vision 12 fps Cap.
- **Tests splitted.** GestureTests > 2,6k Zeilen.
- **Fling-Fenster Pref** aus bugfix 1.5.8.
- **Dead-Man Faust-Timeout Pref 2–8 s** aus bugfix 1.5.8.
- **Wischen nur offene Hand** Pref-Toggle (bugfix 1.5.8).
- **Palm-Reach Not-Aus Pref-Winkel** 20–40°.
- **Metal-Preview 420f** direkt.
- **Latency-HUD** Kamera-Tick → AX-move. Über 40 ms Gain halbieren.
- **iPhone Action Button = Not-Aus.**
- **Menu-Bar Extra:** letzte 8 Gesten.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **Triple-Pinch = Mission Control.**
- **Wrist-Roll = Scroll** pose3D.
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s.
- **overlayChipCap Pref** 4–8.
- **destEdgeHasNeighbor Gap Pref** 16–64 px.
- **Click-Lock vs destEdgeApplies.**
- **Continuity LiDAR-Z** statt Vision-3D.
- **AX kAXFocusedUIElementChanged** statt Poll.
- **Audio-Tick bei Pinch-Down.**
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick.**
- **jointConfEMA Alpha Pref** 0,20–0,50.
- **pinchWristMAD Rest Pref** 0,008–0,020.
- **Relativ-Snap Pref** 0,40–2,0 s.
- **Occlusion Pref** 1–3 Ticks / TTL 0,20–0,80.
- **Two-Hand Scale Gain Pref.**
- **PIP-Deflexion Pref 20–40°.**
- **Warp-Cap und Teleport-Mul Pref getrennt.**
- **palmVelScreen Pref-TTL** 0,20–1,0.
- **destEdgePad Pref je Hz:** 8 fps Continuity Pad × 1,4.
- **AX-Warp Reanchor nach destEdgeCross** 1 Frame — Snap sitzt, AX kann nachziehen.
- **Overlay CAMetalLayer** unabhängig von der Kamera-Rate.
- **Accessibility Switch Control** als zweiter Dead-Man.
- **Leertaste Dead-Man** 0,4 s — Faust-Timeout reicht nicht am Schreibtisch.
- **Per-Monitor SpaceMap Homographie**, nicht eine Karte für Laptop+5K.
- **SpaceMap destBounds auf quartzBounds.** Homographie sonst NSScreen.frame, destEdge Hardware — zwei Seam-Welten.
- **destEdgeScreenAt Hold nach Cross 160 ms Zielschirm.** displayTick 90 Hz sonst Laptop-Pad im Rest-Overlap.
- **Cursor-Trail 8 Samples** HUD, Diagnose ohne Console.

Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

Nur main.

# Helios Nachtrag 1.5.115 — 2026-09-05

Binary **1.5.115 Build 135**. destEdgeCrosses innerster, Cross-Hold 80 ms, FillAxis pad. Analyse in ANALYSE.md.

## In 1.5.115 gelandet

1. destEdgeCrosses destEdgeNearest — Überlapp kein Laptop-first
2. destEdgeSkipNow 80 ms — Seam-Jitter stottert nicht
3. destEdgeFillAxis(pad:) — 5K-Slider
4. Tests + MARKETING_VERSION 1.5.115 (Build 135)

## Nächste, zusätzlich

- **CGDisplayBounds** statt NSScreen.frame Cocoa→Quartz. 16 px Seam-Overlap ist oft Conversion, nicht Hardware.
- **destEdgeSkip Pref** 40–160 ms. Hart 80 zu kurz bei 8 fps (ein Tick 125 ms).
- **Predict 1 Frame tot nach Cross.** pointerPredict schießt sonst über die Seam.
- **AX-Warp Reanchor nach destEdgeCross** 1 Frame.
- **destEdgePad Pref je Display-UUID** persist.
- **Fill-Cap Pref** Laptop vs 5K, getrennt von Warp-Cap.
- **HUD-Chips als Magnet am Cursor**, nicht Top-Bar.
- **Pointer-Accel je Display-Hz.** 8 fps Continuity ≠ 120 Hz ProMotion.
- **CADisplayLink / CVDisplayLink** statt Timer .common. Target 120 Hz.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **Continuity 8 fps palmVel EMA** vor destEdgeStep.
- **destEdgeMul diagonal:** towardX-Noise überspringt Y-Nachbar (gestapelte Monitore).
- **NSEvent.mouseLocation Ground-Truth** vs CGWarp-Drift. Sample 4 Hz, RMS > 8 px = warp-reanchor.
- **Touch ID / Optic ID als Dead-Man.**
- **SpaceMap je Display-UUID.**
- **Two-mode Pointer:** Desk absolut, nach 0,8 s Dwell relativ.
- **6-Punkt-Kalib** gegen Kissenverzerrung.
- **Watch / UWB Pinch-Confirm.**
- **Gaze-gated Click.**
- **IOHID Event-Tap** statt CGEvent-Post.
- **Low-Power Akku:** Vision 12 fps Cap.
- **Tests splitted.** GestureTests > 2,5k Zeilen.
- **Fling-Fenster Pref.** bugfix 1.5.8 nicht mergen, Pref nachziehen.
- **Dead-Man Faust-Timeout Pref 2–8 s** aus bugfix 1.5.8.
- **Wischen nur offene Hand** (bugfix 1.5.8) Pref-Toggle.
- **Palm-Reach Not-Aus Pref-Winkel** 20–40°.
- **Metal-Preview 420f** direkt.
- **Latency-HUD** Kamera-Tick → AX-move. Über 40 ms Gain halbieren.
- **iPhone Action Button = Not-Aus.**
- **Menu-Bar Extra:** letzte 8 Gesten.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **Triple-Pinch = Mission Control**, hinter Pref.
- **Wrist-Roll = Scroll** aus pose3D, hinter Pref.
- **VNFace-Yaw Gain-Dämpfer.**
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s.
- **overlayChipCap Pref** 4–8.
- **destEdgeHasNeighbor Gap Pref** 16–64 px.
- **Click-Lock vs destEdgeApplies:** Button am Seam muss den Nachbarschirm erreichen dürfen.
- Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

Nur main.

# Helios Nachtrag 1.5.113 — 2026-09-05

Binary **1.5.113 Build 133**. destEdgeNearest innerster, FillAxis toward, Seam still. Analyse in ANALYSE.md.

## In 1.5.113 gelandet

1. destEdgeNearest innerster contains — Laptop stiehlt 5K nicht
2. destEdgeFillAxis toward + NeighborMul + screens
3. destEdgeHasNeighbor toward≈0 nearer-edge — Seam still Gain 1
4. Tests + MARKETING_VERSION 1.5.113 (Build 133)

## Nächste, zusätzlich

- **destEdgeCross Hysterese 80 ms** nach Screen-Wechsel, Jitter 1 px skippt nicht jedes Frame.
- **destEdgePad Pref je Display-UUID** persist, nicht nur live Screen-At.
- **Fill-Cap Pref** Laptop vs 5K, getrennt von Warp-Cap.
- **HUD-Chips als Magnet am Cursor**, nicht Top-Bar — 5K-Mitte sonst tot.
- **Pointer-Accel je Display-Hz.** 8 fps Continuity ≠ 120 Hz ProMotion.
- **Wrist-Roll = Scroll** aus pose3D, hinter Pref.
- **jointConfEMA Alpha Pref** 0,20–0,50.
- **pinchWristMAD Rest Pref** 0,008–0,020.
- **NSEvent.mouseLocation Ground-Truth** vs CGWarp-Drift. Sample 4 Hz, RMS > 8 px = warp-reanchor.
- **Touch ID / Optic ID als Dead-Man.**
- **HP/PREDICT/VEL/JUMP/MUTE/LAT/OCC in VoiceOver-Queue** 1,2 s.
- **SpaceMap je Display-UUID.**
- **Two-mode Pointer:** Desk absolut, nach 0,8 s Dwell relativ.
- **CGDisplayStream** Overlay-Paint, DisplayLink nur Cursor.
- **Kalib RMS HUD** live neben EDGE.
- **Reduce Transparency:** Overlay peak-hold aus.
- **CADisplayLink / CVDisplayLink** statt Timer — .common sitzt, vsync fehlt. Target 120 Hz ProMotion.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **Tests splitted.** GestureTests 2,4k Zeilen.
- **AX kAXFocusedUIElementChanged** statt Poll.
- **6-Punkt-Kalib** gegen Kissenverzerrung.
- **Watch / UWB Pinch-Confirm.**
- **Continuity LiDAR-Z** statt Vision-3D.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **IOHID Event-Tap** statt CGEvent-Post.
- **palmVelScreen Pref-TTL** 0,20–1,0 statt hart 0,40.
- **Warp-Cap und Teleport-Mul Pref getrennt.** Fill 4× vs Warp 3× verwirrt.
- **Fling-Fenster Pref.** bugfix 1.5.8 nicht mergen, Pref nachziehen.
- **Low-Power Akku:** Vision 12 fps Cap.
- **Audio-Tick bei Pinch-Down** hinter Pref.
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick Pref.**
- **Triple-Pinch = Mission Control**, hinter Pref.
- **VNFace-Yaw Gain-Dämpfer.**
- **Gaze-gated Click.**
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s.
- **Menu-Bar Extra:** letzte 8 Gesten, Caps-Lock-LED = Scharf.
- **iPhone Action Button = Not-Aus.**
- **Metal-Preview 420f** direkt, kein NSImage-CGImage.
- **Latency-HUD** Kamera-Tick → AX-move. Über 40 ms Gain halbieren.
- **Occlusion Pref** 1–3 Ticks / TTL 0,20–0,80.
- **Dead-Man Faust-Timeout Pref 2–8 s** aus bugfix 1.5.8, nicht hart 1,6.
- **Wischen nur offene Hand** (bugfix 1.5.8) Pref-Toggle.
- **Relativ-Snap Pref** 0,40–2,0 s statt hart 0,80.
- **screenBlend nach Seam 0,12 s** zieht den Cross zurück — Pref 0 oder Snap.
- **destEdgePad Pref je Hz:** 8 fps Continuity Pad × 1,4.
- **Palm-Reach Not-Aus Pref-Winkel** 20–40° statt hart 32.
- **Click-Lock AX Timeout Pref.**
- **Two-Hand Scale Gain Pref.**
- **HUD destEdgeChip in overlayChipCap**, nicht Extra-Slot — 7. Chip deckt Cursor.
- **destEdgeHasNeighbor Gap Pref** 16–64 px.
- **destEdgeMul diagonal:** towardX-Noise überspringt Y-Nachbar (gestapelte Monitore).
- **FillAxis in displayTick verdrahten** — Fill bleibt destEdgeVel (X+Y).
- **Continuity 8 fps palmVel EMA** vor destEdge.
- **AX-Warp Reanchor nach destEdgeCross** 1 Frame.
- **destEdgeCrosses first-contains** analog destEdgeNearest innerster, Gap-Logik halten.

# Helios Nachtrag 1.5.112 — 2026-09-05


Binary **1.5.112 Build 132**. destEdgeHasNeighbor, Coast toward, Y-Coast, Pad-Fallback 2560, Chip nearer-edge. Analyse in ANALYSE.md.

## In 1.5.112 gelandet

1. destEdgeHasNeighbor / destEdgeNeighborMul — Seam-Outbound Gain 1, Pad≠Lead
2. destEdgeVel/Step/Fill(screens:) — Kamera-Tick 20 px vor der Naht nicht mehr Mauer
3. Coast-τ toward + HasNeighbor — Inbound 8 px nicht τ 21 ms
4. palmVelScreenTeleportX/Y — X-JUMP lässt Y-Coast
5. destEdgePadWidthOf [] / PadNow nil → 2560 (Clamshell + 5K)
6. destEdgeChipOf nearer-edge + screens — Seam kein EDGE, Void EDGE
7. Tests + MARKETING_VERSION 1.5.112 (Build 132)

## Nächste, zusätzlich

- **destEdgeCross Hysterese 80 ms** nach Screen-Wechsel, Jitter 1 px skippt nicht jedes Frame.
- **destEdgePad Pref je Display-UUID** persist, nicht nur live Screen-At.
- **Fill-Cap Pref** Laptop vs 5K, getrennt von Warp-Cap.
- **HUD-Chips als Magnet am Cursor**, nicht Top-Bar — 5K-Mitte sonst tot.
- **Pointer-Accel je Display-Hz.** 8 fps Continuity ≠ 120 Hz ProMotion.
- **HasNeighbor vertikal.** Laptop unter 5K: axisY-Seam dieselbe Probe.
- **destEdgeGap Pref 8–64.** Hart 32 px verfehlt 4K-Bezel-Lücke.
- **FillToward nach HasNeighbor optional.** Lead bleibt für Gap > 32; Pad-Zone ist redundant.
- **Wrist-Roll = Scroll** aus pose3D, hinter Pref.
- **jointConfEMA Alpha Pref** 0,20–0,50.
- **pinchWristMAD Rest Pref** 0,008–0,020.
- **NSEvent.mouseLocation Ground-Truth** vs CGWarp-Drift. Sample 4 Hz, RMS > 8 px = warp-reanchor.
- **Touch ID / Optic ID als Dead-Man.**
- **HP/PREDICT/VEL/JUMP/MUTE/LAT/OCC in VoiceOver-Queue** 1,2 s.
- **SpaceMap je Display-UUID.**
- **Two-mode Pointer:** Desk absolut, nach 0,8 s Dwell relativ.
- **CGDisplayStream** Overlay-Paint, DisplayLink nur Cursor.
- **Kalib RMS HUD** live neben EDGE.
- **Reduce Transparency:** Overlay peak-hold aus.
- **CADisplayLink / CVDisplayLink** statt Timer — .common sitzt, vsync fehlt. Target 120 Hz ProMotion.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **Tests splitted.** GestureTests > 2,4k Zeilen.
- **AX kAXFocusedUIElementChanged** statt Poll.
- **6-Punkt-Kalib** gegen Kissenverzerrung.
- **Watch / UWB Pinch-Confirm.**
- **Continuity LiDAR-Z** statt Vision-3D.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **IOHID Event-Tap** statt CGEvent-Post.
- **palmVelScreen Pref-TTL** 0,20–1,0 statt hart 0,40.
- **Warp-Cap und Teleport-Mul Pref getrennt.** Fill 4× vs Warp 3× verwirrt.
- **Fling-Fenster Pref.** bugfix 1.5.8 nicht mergen, Pref nachziehen.
- **Low-Power Akku:** Vision 12 fps Cap.
- **Audio-Tick bei Pinch-Down** hinter Pref.
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick Pref.**
- **Triple-Pinch = Mission Control**, hinter Pref.
- **VNFace-Yaw Gain-Dämpfer.**
- **Gaze-gated Click.**
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s.
- **Menu-Bar Extra:** letzte 8 Gesten, Caps-Lock-LED = Scharf.
- **iPhone Action Button = Not-Aus.**
- **Metal-Preview 420f** direkt, kein NSImage-CGImage.
- **Latency-HUD** Kamera-Tick → AX-move. Über 40 ms Gain halbieren.
- **Occlusion Pref** 1–3 Ticks / TTL 0,20–0,80.
- **Dead-Man Faust-Timeout Pref 2–8 s** aus bugfix 1.5.8, nicht hart 1,6.
- **Wischen nur offene Hand** (bugfix 1.5.8) Pref-Toggle.
- **Relativ-Snap Pref** 0,40–2,0 s statt hart 0,80.
- **Laterality Need Pref** 2–5 Ticks.
- **OCC Follow α Pref** 1,0 vs 0,6 gedämpft.
- **overlayChipCap Pref** 4–8.
- **Click-Lock vs destEdgeApplies:** Button am Seam muss den Nachbarschirm erreichen dürfen.
- **destEdgeFillAxis screens.** Nur-X-Dämpfer am Void, Seam-X frei wie destEdgeFill.
- **PIP-Deflexion Pref 20–40°.** 1.5.110 hart 32° — Krallen-Hände sonst Idle.
- Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

Nur main.


# Helios Nachtrag 1.5.108 — 2026-09-05

Binary **1.5.108 Build 128**. destEdge toward, Fill-Lead, Gap-Cross, Chip-Ordnung. Analyse in ANALYSE.md.

## In 1.5.108 gelandet

1. destEdgeMulX/Y toward — Inbound 5K Gain 1
2. destEdgeFillLead pad+16 — Rückweg 5K→Laptop
3. destEdgeNearest + destEdgeCrosses Gap 32 px (nur anderer Schirm)
4. overlayChipCap Original-Lage, ForEach offset
5. Tests + MARKETING_VERSION 1.5.108 (Build 128)

## Nächste, zusätzlich

- **destEdgeHasNeighbor** im Mul — Seam-Outbound Gain 1 ohne FillToward-Lead. Pad und Lead entkoppelt.
- **destEdgeCross Hysterese 80 ms** nach Screen-Wechsel, Jitter 1 px skippt nicht jedes Frame.
- **destEdgePad Pref je Display-UUID** persist, nicht nur live Screen-At.
- **Fill-Cap Pref** Laptop vs 5K, getrennt von Warp-Cap.
- **HUD-Chips als Magnet am Cursor**, nicht Top-Bar — 5K-Mitte sonst tot.
- **Pointer-Accel je Display-Hz.** 8 fps Continuity ≠ 120 Hz ProMotion.
- **Wrist-Roll = Scroll** aus pose3D, hinter Pref.
- **jointConfEMA Alpha Pref** 0,20–0,50.
- **pinchWristMAD Rest Pref** 0,008–0,020.
- **NSEvent.mouseLocation Ground-Truth** vs CGWarp-Drift. Sample 4 Hz, RMS > 8 px = warp-reanchor.
- **Touch ID / Optic ID als Dead-Man.**
- **HP/PREDICT/VEL/JUMP/MUTE/LAT/OCC in VoiceOver-Queue** 1,2 s.
- **SpaceMap je Display-UUID.**
- **Two-mode Pointer:** Desk absolut, nach 0,8 s Dwell relativ.
- **CGDisplayStream** Overlay-Paint, DisplayLink nur Cursor.
- **Kalib RMS HUD** live neben EDGE.
- **Reduce Transparency:** Overlay peak-hold aus.
- **CADisplayLink / CVDisplayLink** statt Timer — .common sitzt, vsync fehlt. Target 120 Hz ProMotion.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **Tests splitted.** GestureTests 2,3k Zeilen.
- **AX kAXFocusedUIElementChanged** statt Poll.
- **6-Punkt-Kalib** gegen Kissenverzerrung.
- **Watch / UWB Pinch-Confirm.**
- **Continuity LiDAR-Z** statt Vision-3D.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **IOHID Event-Tap** statt CGEvent-Post.
- **palmVelScreen Pref-TTL** 0,20–1,0 statt hart 0,40.
- **Warp-Cap und Teleport-Mul Pref getrennt.** Fill 4× vs Warp 3× verwirrt.
- **Fling-Fenster Pref.** bugfix 1.5.8 nicht mergen, Pref nachziehen.
- **Low-Power Akku:** Vision 12 fps Cap.
- **Audio-Tick bei Pinch-Down** hinter Pref.
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick Pref.**
- **Triple-Pinch = Mission Control**, hinter Pref.
- **VNFace-Yaw Gain-Dämpfer.**
- **Gaze-gated Click.**
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s.
- **Menu-Bar Extra:** letzte 8 Gesten, Caps-Lock-LED = Scharf.
- **iPhone Action Button = Not-Aus.**
- **Metal-Preview 420f** direkt, kein NSImage-CGImage.
- **Latency-HUD** Kamera-Tick → AX-move. Über 40 ms Gain halbieren.
- **Occlusion Pref** 1–3 Ticks / TTL 0,20–0,80.
- **Dead-Man Faust-Timeout Pref 2–8 s** aus bugfix 1.5.8, nicht hart 1,6.
- **Wischen nur offene Hand** (bugfix 1.5.8) Pref-Toggle.
- **Relativ-Snap Pref** 0,40–2,0 s statt hart 0,80.
- **Laterality Need Pref** 2–5 Ticks.
- **OCC Follow α Pref** 1,0 vs 0,6 gedämpft.
- **overlayChipCap Pref** 4–8.
- **palmVelScreen Achsen getrennt.** X-Teleport darf Y-Coast nicht 0 setzen.
- **destEdgePadNow Launch-Fallback 2560** wenn `NSScreen.screens` leer (Clamshell + 5K).
- **Click-Lock vs destEdgeApplies:** Button am Seam muss den Nachbarschirm erreichen dürfen.
- Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

Nur main.

# Helios Nachtrag 1.5.107 — 2026-09-05

Binary **1.5.107 Build 127**. destEdge exact+Cross, Step-Pad, Laterality-Veto, Chip-Keep. Analyse in ANALYSE.md.

## In 1.5.107 gelandet

1. destEdgeScreenAt exact + nearest — Seam 16 px tot
2. destEdgePadAt über Screen-At, nicht screens.first
3. destEdgeStep(pad:) = destEdgePadNow
4. destEdgeCrosses / destEdgeFillToward — Seam ohne Dämpfer
5. slotLateralityPrefers — Match-Slot sperrt Mismatch
6. overlayChipKeep Danger zuerst, unique
7. Tests + MARKETING_VERSION 1.5.107 (Build 127)

## Nächste, zusätzlich

- **destEdgeCross Hysterese 24 px** — Jitter an der Seam skippt nicht jedes Frame.
- **destEdgePad Pref je Display-UUID** persist, nicht nur live Screen-At.
- **Fill-Cap Pref** Laptop vs 5K, getrennt von Warp-Cap.
- **HUD-Chips als Magnet am Cursor**, nicht Top-Bar — 5K-Mitte sonst tot.
- **Pointer-Accel je Display-Hz.** 8 fps Continuity ≠ 120 Hz ProMotion.
- **Wrist-Roll = Scroll** aus pose3D, hinter Pref.
- **screenChanged 80 ms destEdge off** nach Cross, Coast auf dem 5K nicht sofort Pad 64.
- **jointConfEMA Alpha Pref** 0,20–0,50.
- **pinchWristMAD Rest Pref** 0,008–0,020.
- **NSEvent.mouseLocation Ground-Truth** vs CGWarp-Drift. Sample 4 Hz, RMS > 8 px = warp-reanchor.
- **Touch ID / Optic ID als Dead-Man.**
- **HP/PREDICT/VEL/JUMP/MUTE/LAT/OCC in VoiceOver-Queue** 1,2 s.
- **SpaceMap je Display-UUID.**
- **Two-mode Pointer:** Desk absolut, nach 0,8 s Dwell relativ.
- **CGDisplayStream** Overlay-Paint, DisplayLink nur Cursor.
- **Kalib RMS HUD** live neben EDGE.
- **Reduce Transparency:** Overlay peak-hold aus.
- **CADisplayLink / CVDisplayLink** statt Timer — .common sitzt, vsync fehlt. Target 120 Hz ProMotion.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **Tests splitted.**
- **AX kAXFocusedUIElementChanged** statt Poll.
- **6-Punkt-Kalib** gegen Kissenverzerrung.
- **Watch / UWB Pinch-Confirm.**
- **Continuity LiDAR-Z** statt Vision-3D.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **IOHID Event-Tap** statt CGEvent-Post.
- **palmVelScreen Pref-TTL** 0,20–1,0 statt hart 0,40.
- **Warp-Cap und Teleport-Mul Pref getrennt.** Fill 4× vs Warp 3× verwirrt.
- **Fling-Fenster Pref.** bugfix 1.5.8 nicht mergen, Pref nachziehen.
- **Low-Power Akku:** Vision 12 fps Cap.
- **Audio-Tick bei Pinch-Down** hinter Pref.
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick Pref.**
- **Triple-Pinch = Mission Control**, hinter Pref.
- **VNFace-Yaw Gain-Dämpfer.**
- **Gaze-gated Click.**
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s.
- **Menu-Bar Extra:** letzte 8 Gesten, Caps-Lock-LED = Scharf.
- **iPhone Action Button = Not-Aus.**
- **Metal-Preview 420f** direkt, kein NSImage-CGImage.
- **Latency-HUD** Kamera-Tick → AX-move. Über 40 ms Gain halbieren.
- **Occlusion Pref** 1–3 Ticks / TTL 0,20–0,80.
- **Dead-Man Faust-Timeout Pref 2–8 s** aus bugfix 1.5.8, nicht hart 1,6.
- **Wischen nur offene Hand** (bugfix 1.5.8) Pref-Toggle.
- **Relativ-Snap Pref** 0,40–2,0 s statt hart 0,80.
- **Laterality Need Pref** 2–5 Ticks.
- **OCC Follow α Pref** 1,0 vs 0,6 gedämpft.
- **overlayChipCap Pref** 4–8.
- **ForEach chip id:** Index, nicht `id: \.self` — unique sitzt, Index bleibt robuster.
- Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

Nur main.

# Helios Nachtrag 1.5.106 — 2026-09-05

Binary **1.5.106 Build 126**. destEdge Screen-At, Chip-Cap 6 + Tone, slotLateralityDist. Analyse in ANALYSE.md.

## In 1.5.106 gelandet

1. destEdgeScreenAt / destEdgePadAt — Screen unter dem Cursor; Teleport-Cap und ControlPanel
2. overlayChipCap 6 + overlayChipTone
3. slotLateralityDist Mismatch +0,10
4. Tests + MARKETING_VERSION 1.5.106 (Build 126)

## Nächste, zusätzlich

- **destEdgePad Pref je Display-UUID** persist, nicht nur live Screen-At.
- **jointConfEMA Alpha Pref** 0,20–0,50.
- **pinchWristMAD Rest Pref** 0,008–0,020.
- **NSEvent.mouseLocation Ground-Truth** vs CGWarp-Drift. Sample 4 Hz, RMS > 8 px = warp-reanchor.
- **Touch ID / Optic ID als Dead-Man.**
- **HP/PREDICT/VEL/JUMP/MUTE/LAT/OCC in VoiceOver-Queue** 1,2 s.
- **SpaceMap je Display-UUID.**
- **Two-mode Pointer:** Desk absolut, nach 0,8 s Dwell relativ.
- **CGDisplayStream** Overlay-Paint, DisplayLink nur Cursor.
- **Kalib RMS HUD** live neben EDGE.
- **Reduce Transparency:** Overlay peak-hold aus.
- **CADisplayLink / CVDisplayLink** statt Timer — .common sitzt, vsync fehlt. Target 120 Hz ProMotion.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **Tests splitted.**
- **AX kAXFocusedUIElementChanged** statt Poll.
- **6-Punkt-Kalib** gegen Kissenverzerrung.
- **Watch / UWB Pinch-Confirm.**
- **Continuity LiDAR-Z** statt Vision-3D.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **IOHID Event-Tap** statt CGEvent-Post.
- **palmVelScreen Pref-TTL** 0,20–1,0 statt hart 0,40.
- **Fill-Cap Pref** Laptop vs 5K.
- **Warp-Cap und Teleport-Mul Pref getrennt.** Fill 4× vs Warp 3× verwirrt.
- **Fling-Fenster Pref.** bugfix 1.5.8 nicht mergen, Pref nachziehen.
- **Low-Power Akku:** Vision 12 fps Cap.
- **Audio-Tick bei Pinch-Down** hinter Pref.
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick Pref.**
- **Triple-Pinch = Mission Control**, hinter Pref.
- **VNFace-Yaw Gain-Dämpfer.**
- **Gaze-gated Click.**
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s.
- **Menu-Bar Extra:** letzte 8 Gesten, Caps-Lock-LED = Scharf.
- **iPhone Action Button = Not-Aus.**
- **Metal-Preview 420f** direkt, kein NSImage-CGImage.
- **Latency-HUD** Kamera-Tick → AX-move. Über 40 ms Gain halbieren.
- **mappedSnapFill Flag** statt lastVelJump als Mute-Träger.
- **Occlusion Pref** 1–3 Ticks / TTL 0,20–0,80.
- **Dead-Man Faust-Timeout Pref 2–8 s** aus bugfix 1.5.8, nicht hart 1,6.
- **Wischen nur offene Hand** (bugfix 1.5.8) Pref-Toggle.
- **Relativ-Snap Pref** 0,40–2,0 s statt hart 0,80.
- **Laterality Need Pref** 2–5 Ticks.
- **OCC Follow α Pref** 1,0 vs 0,6 gedämpft.
- **overlayChipCap Pref** 4–8.
- **destEdgeScreenAt Seam-Pad** unabhängig von screenSeamPad 24.
- **cursorWarpCapAxis steal** auf Screen-At.
- **ForEach chip id:** Index, nicht `id: \.self`.
- Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

Nur main.

# Helios Nachtrag 1.5.105 — 2026-09-05

Binary **1.5.105 Build 125**. Laterality kein Claim-Flip, OCC Tip folgt Palm, pinchClickAbortsOcc, Pad max-Screen. Analyse in ANALYSE.md.

## In 1.5.105 gelandet

1. palmLateralityClaimFlips immer false — Bind vor Chirality
2. palmLateralityTakes — zweite Hand Unknown, kein S1↔S2
3. fingerOcclusionFollows — Tip += Palm-Delta, lastTip zurück
4. pinchClickAbortsOcc — HUD kein Klick — OCC
5. destEdgePadWidthOf / destEdgePadNow — max Screen, steal live
6. Tests + MARKETING_VERSION 1.5.105 (Build 125)

## Nächste, zusätzlich

- **palmLateralityTakes HUD `WAIT`.** Zweite Hand Unknown sonst tot ohne Chip.
- **OCC Follow-Clamp.** Palm-Jump > 0,25 (Rebase/Handoff) Tip nicht teleportieren.
- **Laterality-Lock persist** 0,80 s über Dropout. Slot vergisst L/R sonst neu.
- **OCC Z-Follow** aus pose3DZ, nicht nur XY-Palm.
- **pinchClickAbortsOcc Pref** — Default an. Debug aus.
- **Slot-sticky Chirality** 8 Frames nach Unknown, bevor Vision neu bindet.
- **destEdgePad Pref je Display-UUID**, nicht Union / NSScreen.main.
- **jointConfEMA Alpha Pref** 0,20–0,50.
- **pinchWristMAD Rest Pref** 0,008–0,020.
- **NSEvent.mouseLocation Ground-Truth** vs CGWarp-Drift. Sample 4 Hz, RMS > 8 px = warp-reanchor.
- **Touch ID / Optic ID als Dead-Man.**
- **HP/PREDICT/VEL/JUMP/MUTE/LAT/OCC/WAIT in VoiceOver-Queue** 1,2 s.
- **SpaceMap je Display-UUID.**
- **Two-mode Pointer:** Desk absolut, nach 0,8 s Dwell relativ.
- **Overlay Chip-Stack Cap 6.**
- **CGDisplayStream** Overlay-Paint, DisplayLink nur Cursor.
- **Kalib RMS HUD** live neben EDGE.
- **Reduce Transparency:** Overlay peak-hold aus.
- **CADisplayLink / CVDisplayLink** statt Timer — .common sitzt, vsync fehlt. Target 120 Hz ProMotion.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **Tests splitted.**
- **AX kAXFocusedUIElementChanged** statt Poll.
- **6-Punkt-Kalib** gegen Kissenverzerrung.
- **Watch / UWB Pinch-Confirm.**
- **Continuity LiDAR-Z** statt Vision-3D.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **IOHID Event-Tap** statt CGEvent-Post.
- **palmVelScreen Pref-TTL** 0,20–1,0 statt hart 0,40.
- **Fill-Cap Pref** Laptop vs 5K.
- **Warp-Cap und Teleport-Mul Pref getrennt.** Fill 4× vs Warp 3× verwirrt.
- **Fling-Fenster Pref.** bugfix 1.5.8 nicht mergen, Pref nachziehen.
- **Low-Power Akku:** Vision 12 fps Cap.
- **Audio-Tick bei Pinch-Down** hinter Pref.
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick Pref.**
- **Triple-Pinch = Mission Control**, hinter Pref.
- **VNFace-Yaw Gain-Dämpfer.**
- **Gaze-gated Click.**
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s.
- **Menu-Bar Extra:** letzte 8 Gesten, Caps-Lock-LED = Scharf.
- **iPhone Action Button = Not-Aus.**
- **Metal-Preview 420f** direkt, kein NSImage-CGImage.
- **Latency-HUD** Kamera-Tick → AX-move. Über 40 ms Gain halbieren.
- **mappedSnapFill Flag** statt lastVelJump als Mute-Träger.
- **Occlusion Pref** 1–3 Ticks / TTL 0,20–0,80.
- **Dead-Man Faust-Timeout Pref 2–8 s** aus bugfix 1.5.8, nicht hart 1,6.
- **Wischen nur offene Hand** (bugfix 1.5.8) Pref-Toggle.
- **Relativ-Snap Pref** 0,40–2,0 s statt hart 0,80.
- **Laterality Need Pref** 2–5 Ticks.
- **destEdgePadNow Launch-Fallback 2560** wenn `NSScreen.screens` leer (Clamshell + 5K).
- Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

# Helios Nachtrag 1.5.104 — 2026-09-05

Binary **1.5.104 Build 124**. Occlusion 2-Tick + TTL, Relativ-Snap nach Dropout, JUMP-Slow mute, Laterality 3 Ticks. Analyse in ANALYSE.md.

## In 1.5.104 gelandet

1. fingerOcclusionFresh / Confirm — lastTip TTL 0,40 s, 2 Ticks, DIP kein Pinch-Tip, HUD OCC
2. cursorWarpSnapsRestore Relativ nach Dropout > 0,80 s
3. palmHighpassMutesJump Slow=dx nach JUMP/Hold
4. palmLateralityDebounce 3 Ticks
5. Tests + MARKETING_VERSION 1.5.104 (Build 124)

## Nächste, zusätzlich

- **destEdgePad je Display-UUID**, nicht Union / NSScreen.main.
- **jointConfEMA Alpha Pref** 0,20–0,50.
- **pinchWristMAD Rest Pref** 0,008–0,020.
- **NSEvent.mouseLocation Ground-Truth** vs CGWarp-Drift. Sample 4 Hz, RMS > 8 px = warp-reanchor.
- **Touch ID / Optic ID als Dead-Man.**
- **HP/PREDICT/VEL/JUMP/MUTE/LAT/OCC in VoiceOver-Queue** 1,2 s.
- **SpaceMap je Display-UUID.**
- **Two-mode Pointer:** Desk absolut, nach 0,8 s Dwell relativ.
- **Overlay Chip-Stack Cap 6.**
- **CGDisplayStream** Overlay-Paint, DisplayLink nur Cursor.
- **Kalib RMS HUD** live neben EDGE.
- **Reduce Transparency:** Overlay peak-hold aus.
- **CADisplayLink / CVDisplayLink** statt Timer — .common sitzt, vsync fehlt. Target 120 Hz ProMotion.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **Tests splitted.**
- **AX kAXFocusedUIElementChanged** statt Poll.
- **6-Punkt-Kalib** gegen Kissenverzerrung.
- **Watch / UWB Pinch-Confirm.**
- **Continuity LiDAR-Z** statt Vision-3D.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **IOHID Event-Tap** statt CGEvent-Post.
- **palmVelScreen Pref-TTL** 0,20–1,0 statt hart 0,40.
- **Fill-Cap Pref** Laptop vs 5K.
- **Warp-Cap und Teleport-Mul Pref getrennt.** Fill 4× vs Warp 3× verwirrt.
- **Fling-Fenster Pref.** bugfix 1.5.8 nicht mergen, Pref nachziehen.
- **Low-Power Akku:** Vision 12 fps Cap.
- **Audio-Tick bei Pinch-Down** hinter Pref.
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick Pref.**
- **Triple-Pinch = Mission Control**, hinter Pref.
- **VNFace-Yaw Gain-Dämpfer.**
- **Gaze-gated Click.**
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s.
- **Menu-Bar Extra:** letzte 8 Gesten, Caps-Lock-LED = Scharf.
- **iPhone Action Button = Not-Aus.**
- **Metal-Preview 420f** direkt, kein NSImage-CGImage.
- **Latency-HUD** Kamera-Tick → AX-move. Über 40 ms Gain halbieren.
- **mappedSnapFill Flag** statt lastVelJump als Mute-Träger.
- **Kalman lastIndexTip** während OCC, nicht freeze auf tot-Pose.
- **Occlusion Pref** 1–3 Ticks / TTL 0,20–0,80.
- **Dead-Man Faust-Timeout Pref 2–8 s** aus bugfix 1.5.8, nicht hart 1,6.
- **Wischen nur offene Hand** (bugfix 1.5.8) Pref-Toggle.
- **Relativ-Snap Pref** 0,40–2,0 s statt hart 0,80.
- **Laterality Need Pref** 2–5 Ticks.
- Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

Nur main.

# Helios Nachtrag 1.5.103 — 2026-09-05

Binary **1.5.103 Build 123**. Tip-Restore tot, live PAD Chip, Wi-Fi-Veto. Analyse in ANALYSE.md.

## In 1.5.103 gelandet

1. jointConfRestores — Tips nicht restore (Phantom-Pinch tot)
2. destEdgePadLiveChip Slider vs live Pad
3. continuityIsUSB Wi-Fi-Veto
4. Tests + MARKETING_VERSION 1.5.103 (Build 123)

## Nächste, zusätzlich

- **fingerOcclusion DIP-Restore Pref.** Zweiter Phantom-Pinch-Pfad: lastIndexTip aus DIP. Hinter Pref oder 2-Tick Confirm.
- **destEdgePad je Display-UUID**, nicht Union / NSScreen.main.
- **jointConfEMA Alpha Pref** 0,20–0,50.
- **Relativ Warp-Snap** nach Dropout > 0,80 s. Relativ bleibt Hold.
- **pinchWristMAD Rest Pref** 0,008–0,020.
- **NSEvent.mouseLocation Ground-Truth** vs CGWarp-Drift. Sample 4 Hz, RMS > 8 px = warp-reanchor.
- **Touch ID / Optic ID als Dead-Man.**
- **HP/PREDICT/VEL/JUMP/MUTE/LAT in VoiceOver-Queue** 1,2 s.
- **SpaceMap je Display-UUID.**
- **Two-mode Pointer:** Desk absolut, nach 0,8 s Dwell relativ.
- **Overlay Chip-Stack Cap 6.**
- **CGDisplayStream** Overlay-Paint, DisplayLink nur Cursor.
- **Kalib RMS HUD** live neben EDGE.
- **Reduce Transparency:** Overlay peak-hold aus.
- **CADisplayLink / CVDisplayLink** statt Timer — .common sitzt, vsync fehlt. Target 120 Hz ProMotion.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **Tests splitted.**
- **AX kAXFocusedUIElementChanged** statt Poll.
- **6-Punkt-Kalib** gegen Kissenverzerrung.
- **Watch / UWB Pinch-Confirm.**
- **Continuity LiDAR-Z** statt Vision-3D.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **IOHID Event-Tap** statt CGEvent-Post.
- **palmVelScreen Pref-TTL** 0,20–1,0 statt hart 0,40.
- **Fill-Cap Pref** Laptop vs 5K.
- **Warp-Cap und Teleport-Mul Pref getrennt.** Fill 4× vs Warp 3× verwirrt.
- **Fling-Fenster Pref.**
- **Low-Power Akku:** Vision 12 fps Cap.
- **Audio-Tick bei Pinch-Down** hinter Pref.
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick Pref.**
- **Triple-Pinch = Mission Control**, hinter Pref.
- **VNFace-Yaw Gain-Dämpfer.**
- **Gaze-gated Click.**
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s.
- **Menu-Bar Extra:** letzte 8 Gesten, Caps-Lock-LED = Scharf.
- **iPhone Action Button = Not-Aus.**
- **Metal-Preview 420f** direkt, kein NSImage-CGImage.
- **Latency-HUD** Kamera-Tick → AX-move. Über 40 ms Gain halbieren.
- **mappedSnapFill Flag** statt lastVelJump als Mute-Träger.
- **palmHighpass DC nach JUMP mute.**
- **Vision-Flip Debounce 3 Ticks** bevor otherClaimed den Lock löst.
- Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

Nur main.

# Helios Nachtrag 1.5.102 — 2026-09-05

Binary **1.5.102 Build 122**. Warp-Snap Restore mapped, Relativ bleibt Hold. Analyse in ANALYSE.md.

## In 1.5.102 gelandet

1. cursorWarpSnapsRestore — mapped Teleport Snap auf q, Hold-Deadlock tot
2. cursorWarpRestoreOf — lastMapped bleibt, MUTE 1 Tick nicht ewig
3. Tests + MARKETING_VERSION 1.5.102 (Build 122)

## Nächste, zusätzlich

- **Relativ Warp-Snap** nach Dropout > 0,80 s. Relativ bleibt Hold.
- **destEdgePad je Display-UUID**, nicht Union. Slider sitzt global.
- **jointConfEMA Alpha Pref** 0,20–0,50.
- **pinchWristMAD Rest Pref** 0,008–0,020.
- **NSEvent.mouseLocation Ground-Truth** vs CGWarp-Drift. Sample 4 Hz, RMS > 8 px = warp-reanchor.
- **Touch ID / Optic ID als Dead-Man.**
- **HP/PREDICT/VEL/JUMP/MUTE/LAT in VoiceOver-Queue** 1,2 s.
- **SpaceMap je Display-UUID.**
- **Two-mode Pointer:** Desk absolut, nach 0,8 s Dwell relativ.
- **Overlay Chip-Stack Cap 6.**
- **CGDisplayStream** Overlay-Paint, DisplayLink nur Cursor.
- **Kalib RMS HUD** live neben EDGE.
- **Reduce Transparency:** Overlay peak-hold aus.
- **CADisplayLink / CVDisplayLink** statt Timer — .common sitzt, vsync fehlt.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **Tests splitted.**
- **AX kAXFocusedUIElementChanged** statt Poll.
- **6-Punkt-Kalib** gegen Kissenverzerrung.
- **Watch / UWB Pinch-Confirm.**
- **Continuity LiDAR-Z** statt Vision-3D.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **IOHID Event-Tap** statt CGEvent-Post.
- **palmVelScreen Pref-TTL** 0,20–1,0 statt hart 0,40.
- **Fill-Cap Pref** Laptop vs 5K.
- **Warp-Cap und Teleport-Mul Pref getrennt.** Fill 4× vs Warp 3× verwirrt.
- **Fling-Fenster Pref.**
- **displayTick CADisplayLink** target 120 Hz ProMotion, nicht Timer 90.
- **Low-Power Akku:** Vision 12 fps Cap.
- **Audio-Tick bei Pinch-Down** hinter Pref.
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick Pref.**
- **Triple-Pinch = Mission Control**, hinter Pref.
- **VNFace-Yaw Gain-Dämpfer.**
- **Gaze-gated Click.**
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s.
- **Menu-Bar Extra:** letzte 8 Gesten, Caps-Lock-LED = Scharf.
- **iPhone Action Button = Not-Aus.**
- **Metal-Preview 420f** direkt, kein NSImage-CGImage.
- **Latency-HUD** Kamera-Tick → AX-move. Über 40 ms Gain halbieren.
- **mappedSnapFill Flag** statt lastVelJump als Mute-Träger.
- Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

Nur main.

# Helios Nachtrag 1.5.101 — 2026-09-05

Binary **1.5.101 Build 121**. Warp-Hold JUMP, Hold-Release Teleport, MUTE bis Release, Laterality `L`/`R`, USB über modelID/UVC/transportType. Analyse in ANALYSE.md.

## In 1.5.101 gelandet

1. palmWarpHoldJumps / applyWarpHold — Freeze = JUMP, Fill mute
2. palmWarpHoldReleaseJumps — Hold-Release Teleport, Fill 0
3. palmVelChip `JUMP · MUTE`
4. palmLateralityChip HUD `L`/`R`
5. continuityIsUSB modelID + localizedName + UVC + transportType FourCC
6. displayTickMutesJump(held:) — MUTE bis Release, nicht 11 ms
7. warpHeldJump an Reset-Pfaden 0
8. Tests + MARKETING_VERSION 1.5.101 (Build 121)

## Nächste, zusätzlich

- **destEdgePad je Display-UUID**, nicht Union. Slider sitzt global.
- **jointConfEMA Alpha Pref** 0,20–0,50.
- **pinchWristMAD Rest Pref** 0,008–0,020.
- **NSEvent.mouseLocation Ground-Truth** vs CGWarp-Drift. Sample 4 Hz, RMS > 8 px = warp-reanchor.
- **Touch ID / Optic ID als Dead-Man.**
- **HP/PREDICT/VEL/JUMP/MUTE in VoiceOver-Queue** 1,2 s.
- **SpaceMap je Display-UUID.**
- **Two-mode Pointer:** Desk absolut, nach 0,8 s Dwell relativ.
- **Overlay Chip-Stack Cap 6.**
- **CGDisplayStream** Overlay-Paint, DisplayLink nur Cursor.
- **Kalib RMS HUD** live neben EDGE.
- **Reduce Transparency:** Overlay peak-hold aus.
- **CADisplayLink / CVDisplayLink** statt Timer — .common sitzt, vsync fehlt.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **Tests splitted.**
- **AX kAXFocusedUIElementChanged** statt Poll.
- **6-Punkt-Kalib** gegen Kissenverzerrung.
- **Watch / UWB Pinch-Confirm.**
- **Continuity LiDAR-Z** statt Vision-3D.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **IOHID Event-Tap** statt CGEvent-Post.
- **palmVelScreen Pref-TTL** 0,20–1,0 statt hart 0,40.
- **Fill-Cap Pref** Laptop vs 5K.
- **Warp-Cap und Teleport-Mul Pref getrennt.** Fill 4× vs Warp 3× verwirrt.
- **Fling-Fenster Pref.**
- **displayTick CADisplayLink** target 120 Hz ProMotion, nicht Timer 90.
- **Low-Power Akku:** Vision 12 fps Cap.
- **Audio-Tick bei Pinch-Down** hinter Pref.
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick Pref.**
- **Triple-Pinch = Mission Control**, hinter Pref.
- **VNFace-Yaw Gain-Dämpfer.**
- **Gaze-gated Click.**
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s.
- **Menu-Bar Extra:** letzte 8 Gesten, Caps-Lock-LED = Scharf.
- **iPhone Action Button = Not-Aus.**
- **Metal-Preview 420f** direkt, kein NSImage-CGImage.
- **Latency-HUD** Kamera-Tick → AX-move. Über 40 ms Gain halbieren.
- **palmLaterality in bindSlot vor Slot-Alloc** — claimed.contains(Vision) vor Lock stiehlt L.
- **destEdgePad Pref je Screen-UUID in SpaceMap.**
- **Reduce Motion: Warp-Hold freeze aus, Snap auf dest.**
- **Click-Lock nach AX-Role (AXButton)** nicht nur Bundle.
- **Stereo Continuity+Built-in** für echte Z-Tiefe.
- **Warp-Hold vs 5K RMS:** Homographie-Rauschen > Warp-Cap = Dauer-Hold. RMS-Gate vor Hold.
- **palmVelScreenKeep während Hold nicht aus mad-0 beleben.**
- **CGEventSource coalescing** vs Warp-Hold freeze — Event-Tap sieht 0-Vel, App-Switch Wisch stirbt.
- **Continuity Desk-View Yaw** als Palm-Reach-Not-Aus Floor, nicht nur Z.
- **Slot-Alloc nach Laterality-Lock**, nicht davor: zwei .left-Obs tauschen S1/S2 bevor Lock hält.
- **Dead-Man aus bugfix 1.5.8:** Faust-Timeout Pref 2–8 s, nicht hart.
- **Wischen nur offene Hand** (bugfix 1.5.8) Pref-Toggle — Faust-Wisch dockt sonst.
- Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

Nur main.

# Helios Nachtrag 1.5.100 — 2026-09-05


Binary **1.5.100 Build 120**. Fill-Mute nach JUMP, palmVelAt nil, Laterality-Lock, destEdgePad Slider, Joint-Conf EMA, USB/WIFI HUD. Analyse in ANALYSE.md.

## In 1.5.100 gelandet

1. displayTickMutesJump — Fill 1 Frame tot nach JUMP
2. palmVelAtOf nil statt Sentinel 0
3. palmLateralityLock — Vision-Chirality Flip tot
4. destEdgePad Pref-Slider 24–160
5. jointConfEMA statt raw Floor
6. formatTransportChip HUD `USB` / `WIFI`
7. Tests + MARKETING_VERSION 1.5.100 (Build 120)

## Nächste, zusätzlich

- **destEdgePad je Display-UUID**, nicht Union. Slider sitzt global.
- **JUMP-mute HUD `MUTE`** 1 Frame neben JUMP.
- **Laterality HUD `L`/`R`** wenn Lock die Vision-Seite hält.
- **jointConfEMA Alpha Pref** 0,20–0,50.
- **Continuity transportType** statt uniqueID enthält `usb`.
- **pinchWristMAD Rest Pref** 0,008–0,020.
- **NSEvent.mouseLocation Ground-Truth** vs CGWarp-Drift. Sample 4 Hz, RMS > 8 px = warp-reanchor.
- **Touch ID / Optic ID als Dead-Man.**
- **HP/PREDICT/VEL/JUMP in VoiceOver-Queue** 1,2 s.
- **SpaceMap je Display-UUID.**
- **Two-mode Pointer:** Desk absolut, nach 0,8 s Dwell relativ.
- **Overlay Chip-Stack Cap 6.**
- **CGDisplayStream** Overlay-Paint, DisplayLink nur Cursor.
- **Kalib RMS HUD** live neben EDGE.
- **Reduce Transparency:** Overlay peak-hold aus.
- **CADisplayLink / CVDisplayLink** statt Timer — .common sitzt, vsync fehlt.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **Tests splitted.**
- **AX kAXFocusedUIElementChanged** statt Poll.
- **6-Punkt-Kalib** gegen Kissenverzerrung.
- **Watch / UWB Pinch-Confirm.**
- **Continuity LiDAR-Z** statt Vision-3D.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **IOHID Event-Tap** statt CGEvent-Post.
- **palmVelScreen Pref-TTL** 0,20–1,0 statt hart 0,40.
- **Fill-Cap Pref** Laptop vs 5K.
- **Warp-Cap und Teleport-Mul Pref getrennt.** Fill 4× vs Warp 3× verwirrt.
- **Fling-Fenster Pref.**
- **displayTick CADisplayLink** target 120 Hz ProMotion, nicht Timer 90.
- **Low-Power Akku:** Vision 12 fps Cap.
- **Audio-Tick bei Pinch-Down** hinter Pref.
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick Pref.**
- **Triple-Pinch = Mission Control**, hinter Pref.
- **VNFace-Yaw Gain-Dämpfer.**
- **Gaze-gated Click.**
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s.
- **Menu-Bar Extra:** letzte 8 Gesten, Caps-Lock-LED = Scharf.
- **iPhone Action Button = Not-Aus.**
- **Metal-Preview 420f** direkt, kein NSImage-CGImage.
- **Latency-HUD** Kamera-Tick → AX-move. Über 40 ms Gain halbieren.
- **palmVelAt rebase + Laterality in einem Tick** — sitzt getrennt (1.5.100).
- Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

Nur main.

# Helios Nachtrag 1.5.99 — 2026-09-05

Binary **1.5.99 Build 119**. Vel-TTL 0,40 s, JUMP, Fill lastMapped2 = current. Analyse in ANALYSE.md.

## In 1.5.99 gelandet

1. palmVelScreenFresh TTL 0,40 s — Ghost-Coast tot, kurzer Dropout hält
2. palmVelScreenTeleport 4× Pad — HUD `JUMP`
3. palmMappedPair — Fill nach JUMP 0. displayLinkVelocity fresh
4. Tests + MARKETING_VERSION 1.5.99 (Build 119)

## Nächste, zusätzlich

- **destEdgePad Pref-Slider** 24–160, Default destEdgePadOf. Math sitzt (1.5.98).
- **pinchWristMAD Rest Pref** 0,008–0,020.
- **Continuity USB/Wi-Fi HUD** `USB` / `WIFI`.
- **NSEvent.mouseLocation Ground-Truth** vs CGWarp-Drift. Sample 4 Hz, RMS > 8 px = warp-reanchor.
- **Hand-Laterality-Lock** links bleibt links — Vision-UUID-Swap sonst S1/S2.
- **Joint-Conf EMA** statt raw Floor 0,10.
- **Touch ID / Optic ID als Dead-Man.**
- **HP/PREDICT/VEL/JUMP in VoiceOver-Queue** 1,2 s.
- **SpaceMap je Display-UUID.**
- **Two-mode Pointer:** Desk absolut, nach 0,8 s Dwell relativ.
- **Overlay Chip-Stack Cap 6.**
- **CGDisplayStream** Overlay-Paint, DisplayLink nur Cursor.
- **Kalib RMS HUD** live neben EDGE.
- **Reduce Transparency:** Overlay peak-hold aus.
- **CADisplayLink / CVDisplayLink** statt Timer — .common sitzt, vsync fehlt.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **Tests splitted.**
- **AX kAXFocusedUIElementChanged** statt Poll.
- **6-Punkt-Kalib** gegen Kissenverzerrung.
- **Watch / UWB Pinch-Confirm.**
- **Continuity LiDAR-Z** statt Vision-3D.
- **Per-App Gestenprofile UI.**
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **IOHID Event-Tap** statt CGEvent-Post.
- **palmVelScreen Pref-TTL** 0,20–1,0 statt hart 0,40.
- **Fill-Cap Pref** Laptop vs 5K.
- **Laterality + Vel-Rebase** in einem Tick.
- **palmVelAt nil statt 0.** Sentinel 0 ist tot, Optional sauberer.
- **Warp-Cap und Teleport-Mul Pref getrennt.** Fill 4× vs Warp 3× verwirrt.
- **displayTick nach JUMP 1 Frame mute** unabhängig von lastMapped2.

# Helios Nachtrag 1.5.98 — 2026-09-05

Binary **1.5.98 Build 118**. Actor-Vel 0, lastMapped nil, Scale-Abort, VEL-HUD. Analyse in ANALYSE.md.

## In 1.5.98 gelandet

1. palmVelScreenResets / palmVelScreenAfterActor — Vel 0 bei S1→S2
2. palmMappedClears lastMapped nil — kein Teleport-Vel
3. palmVelChip HUD `VEL 0` peak-hold
4. scaleAbortClick 2→1 lastScrollAt
5. destEdgePadPref 24–160
6. Tests + MARKETING_VERSION 1.5.98 (Build 118)

## Nächste, zusätzlich

- **destEdgePad Pref-Slider** 24–160, Default destEdgePadOf. Per-Display, nicht Union. Math sitzt.
- **pinchWristMAD Rest Pref** 0,008–0,020.
- **Continuity USB/Wi-Fi HUD** `USB` / `WIFI`.
- **NSEvent.mouseLocation Ground-Truth** vs CGWarp-Drift. Sample 4 Hz, RMS > 8 px = warp-reanchor.
- **Hand-Laterality-Lock** links bleibt links — Vision-UUID-Swap sonst S1/S2.
- **Joint-Conf EMA** statt raw Floor 0,10.
- **Touch ID / Optic ID als Dead-Man.**
- **HP/PREDICT/VEL in VoiceOver-Queue** 1,2 s.
- **SpaceMap je Display-UUID.**
- **Two-mode Pointer:** Desk absolut, nach 0,8 s Dwell relativ.
- **Overlay Chip-Stack Cap 6.**
- **CGDisplayStream** Overlay-Paint, DisplayLink nur Cursor.
- **Kalib RMS HUD** live neben EDGE.
- **Reduce Transparency:** Overlay peak-hold aus.
- **CADisplayLink / CVDisplayLink** statt Timer — .common sitzt, vsync fehlt.
- **Frame-Pump mit Aegis:** eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **Tests splitted.** Eine `run()`-Funktion, jeder Patch redeclare.
- **AX kAXFocusedUIElementChanged** statt Poll.
- **6-Punkt-Kalib** gegen Kissenverzerrung.
- **Watch / UWB Pinch-Confirm.**
- **Continuity LiDAR-Z** statt Vision-3D.
- **Per-App Gestenprofile UI** (Safari Klick-Lock, Figma aus).
- **Hover-Dwell Dock** 0,45 s ohne Pinch.
- **Stereo Continuity+Built-in** für echte Z-Tiefe.
- **IOHID Event-Tap** statt CGEvent-Post.
- **Metal-Preview 420f** direkt, kein NSImage-CGImage.
- **Latency-HUD** Kamera-Tick → AX-move. Über 40 ms Gain halbieren.
- **Audio-Tick bei Pinch-Down** hinter Pref.
- **Faust = Maustaste Pref.**
- **Pinch-Index = Klick, Pinch-Mittel = Rechtsklick Pref.**
- **Triple-Pinch = Mission Control**, hinter Pref.
- **VNFace-Yaw Gain-Dämpfer** (Blick weg → Cursor träge).
- **Gaze-gated Click.**
- **SpaceMap Auto-Recalib** RMS > 24 px / 2 s.
- **Low-Power Akku:** Vision 12 fps Cap.
- **Continuity Desk-View eigener Format-Zweig** analog Aegis yaw-floor 0,36.
- **Fill-Cap Pref** Laptop vs 5K.
- **palmarer Dead-Man über AirPods-Mikro.**
- **iPhone Action Button = Not-Aus.**
- **Menu-Bar Extra:** letzte 8 Gesten, Caps-Lock-LED = Scharf.
- **Pinch-Hold Peak-Hold Chip `WRIST` analog Skip-AX.**
- **displayTick CADisplayLink** target 120 Hz ProMotion, nicht Timer 90.
- **Vision joint-confidence < 0,35 = Landmark tot**, nicht 0,5 interpolate.
- **Fling-Fenster Pref.** bugfix `flingFromTrail` nicht nachziehen.
- **palmVelScreen = 0 bei Actor-Switch** — sitzt (1.5.98).
- **Scale-Abort wenn zweite Hand droppt** — sitzt (1.5.98).
- Shared XPC Frame-Pump mit Aegis bleibt die größte einzelne Effizienz.

Nur main.

# Helios Nachtrag 1.5.97 — 2026-09-05

Binary **1.5.97 Build 117**. Slow-TTL 2 s, palmHighpassFresh. Analyse in ANALYSE.md.

## In 1.5.97 gelandet

1. palmHighpassFresh TTL 2 s — stale Slow = dx
2. palmSlowByActor.at
3. Tests + MARKETING_VERSION 1.5.97 (Build 117)

## Nächste, zusätzlich

- **palmVelScreen = 0 bei Actor-Switch** — Slow restored/seed, Vel nicht.
- **destEdgePad Pref-Slider** 24–160, Default destEdgePadOf. Per-Display, nicht Union.
- **pinchWristMAD Rest Pref** 0,008–0,020.
- **Continuity USB/Wi-Fi HUD** `USB` / `WIFI`.
- **NSEvent.mouseLocation Ground-Truth** vs CGWarp-Drift.
- **Hand-Laterality-Lock** links bleibt links.
- **Joint-Conf EMA** statt raw Floor.
- **Touch ID / Optic ID als Dead-Man.**
- **HP/PREDICT in VoiceOver-Queue** 1,2 s.
- **Scale-Abort** wenn zweite Hand droppt.
- **SpaceMap je Display-UUID.**
- **Two-mode Pointer:** Desk absolut, nach 0,8 s Dwell relativ.
- **Overlay Chip-Stack Cap 6.**
- **CGDisplayStream** Overlay-Paint, DisplayLink nur Cursor.
- **Kalib RMS HUD** live neben EDGE.
- **Reduce Transparency:** Overlay peak-hold aus.

# Helios Nachtrag 1.5.96 — 2026-09-05


Binary **1.5.96 Build 116**. Center Stage `.app` vor Disable, HeliosCatch. Crash 1.5.87 macOS 27 `_setCenterStageEnabled`. Analyse in ANALYSE.md.

## In 1.5.96 gelandet

1. centerStageNeedsAppControl — `.user`/`.cooperative` → `.app`
2. applyCenterStage HeliosCatch, force setzt ohne Getter
3. Tests + MARKETING_VERSION 1.5.96 (Build 116)

# Helios Nachtrag 1.5.95 — 2026-09-05

Binary **1.5.95 Build 115**. CI GestureTests ohne QuartzCore (`CACurrentMediaTime` → 100). 1.5.94 Logik bleibt.

# Helios Nachtrag 1.5.94 — 2026-09-05

Binary **1.5.94 Build 114**. Ghost-Hochpass, AX 16 px, Ring kein Sturm, Enhance nur Nacht, Timer .common, destEdge 5K, Scale 8 fps, PREDICT-HUD, Warp-X=Pad, Wrist-Abort. Analyse in ANALYSE.md.

## In 1.5.94 gelandet

1. palmHighpassResets Ghost hält — Slow je Actor, Seed=dx
2. palmHighpassChip HUD `α 0,15 S1`
3. axHitCacheDist 8 fps 16 px
4. ringRebuilds nur Geometry
5. enhanceDownscales nur luma<0,30
6. displayLinkTimerCommonMode Timer .common
7. destEdgePadOf 2,5 % / Floor 40 — destEdgeMul Gain dieselbe Zahl
8. scaleMoved(dt:) 8 fps Dead × 1,8
9. pointerPredictChip HUD `PREDICT n`
10. cursorWarpCapX(width:) = destEdgePadOf
11. pinchHoldAborts Wrist-MAD > Rest × 2,8
12. Tests + MARKETING_VERSION 1.5.94 (Build 114)

## Nächste, zusätzlich zur alten Liste

- **CADisplayLink / CVDisplayLink** statt Timer — .common sitzt (1.5.94), vsync fehlt.
- Frame-Pump mit Aegis: eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- Tests splitted. Eine `run()`-Funktion, jeder Patch redeclare.
- Overlay-Occlusion-Mesh (Palm-Polygon), nicht nur Tip-Distanz.
- AX kAXFocusedUIElementChanged statt Poll.
- 6-Punkt-Kalib gegen Kissenverzerrung.
- Watch / UWB Pinch-Confirm.
- Continuity LiDAR-Z statt Vision-3D.
- Per-App Gestenprofile UI (Safari Klick-Lock, Figma aus).
- Hover-Dwell Dock 0,45 s ohne Pinch.
- Stereo Continuity+Built-in für echte Z-Tiefe.
- IOHID Event-Tap statt CGEvent-Post.
- VoiceOver-Queue 1,2 s WARP/EDGE/STEAL/α.
- Metal-Preview 420f direkt, kein NSImage-CGImage.
- Latency-HUD Kamera-Tick → AX-move. Über 40 ms Gain halbieren.
- Audio-Tick bei Pinch-Down hinter Pref.
- Faust = Maustaste Pref.
- Pinch-Index = Klick, Pinch-Mittel = Rechtsklick Pref.
- Triple-Pinch = Mission Control, hinter Pref.
- VNFace-Yaw Gain-Dämpfer (Blick weg → Cursor träge).
- Gaze-gated Click.
- SpaceMap Auto-Recalib RMS > 24 px / 2 s.
- Low-Power Akku: Vision 12 fps Cap.
- Overlay PREDICT Chip — sitzt (1.5.94).
- destEdgePadOf / destEdgeMul Gain — sitzt (1.5.94).
- palmHighpass je Hand Map — sitzt (1.5.94). HUD α sitzt.
- AX 16 px 8 fps — sitzt (1.5.94).
- Ring Alloc-Sturm — sitzt (1.5.94).
- Enhance nur Nacht — sitzt (1.5.94).
- Timer .common — sitzt (1.5.94).
- Scale 8 fps Dead — sitzt (1.5.94).
- pinchHoldAborts Wrist-MAD — sitzt (1.5.94).
- cursorWarpCapX = PadOf — sitzt (1.5.94).
- ** Continuity Desk-View eigener Format-Zweig** analog Aegis yaw-floor 0,36.
- ** Fill-Cap Pref** Laptop vs 5K.
- ** palmarer Dead-Man über AirPods-Mikro.**
- ** iPhone Action Button = Not-Aus.**
- ** Menu-Bar Extra:** letzte 8 Gesten, Caps-Lock-LED = Scharf.
- ** Pinch-Hold Peak-Hold Chip `WRIST` analog Skip-AX.**
- ** displayTick CADisplayLink target 120 Hz ProMotion, nicht Timer 90.**
- ** Vision joint-confidence < 0,35 = Landmark tot, nicht 0,5 interpolate.**
- Shared XPC Frame-Pump mit Aegis 2.1.110 bleibt die größte einzelne Effizienz.

Nur main.


# Helios Nachtrag 1.5.93 — 2026-09-05

Binary **1.5.93 Build 113**. STEAL-HUD, 0° Vision, Hochpass je Hand, AX 2 Frames, Ring-Cap 12, ROI-Latch, TypeID Probe. Analyse in ANALYSE.md.

## In 1.5.93 gelandet

1. ringSlotStealChip / formatStealChip — HUD `STEAL n`
2. visionBufferOrientation — 0° Capture .up, kein 90° Palm
3. palmHighpassResets — Slow je Actor
4. axProbeTTL 260 ms / axHitCacheNeed 2 Frames
5. ringSlotCap 12
6. palmROILatchChip `ROI S1`
7. axTypeIDHolds in loadProbe
8. Tests + MARKETING_VERSION 1.5.93 (Build 113)

## In 1.5.92 gelandet

1. enhanceDestFormat — Ping/Pong 420f/420v
2. ringSlotStealDrops — Slot −1 nicht an Vision
3. palmROISecondNils / palmVisionROI(dt:) — 8 fps zwei Hände ROI
4. pinchOpenHolds — Open-Need in Sekunden
5. overlayGhostPeakHold 2 Frames
6. axProbeWakeInvalidates → invalidateAXProbe
7. ControlPanel Atem-Hochpass 0,08–0,25
8. Tests + MARKETING_VERSION 1.5.92 (Build 112)

## In 1.5.91 gelandet

1. visionTakesNative / ringCopyConverts — GPUFrameRing hält 420f/420v
2. pinchOpenNeedSec
3. flingFromTrail (Center-Dead am letzten Sample)
4. clamshellWakeReselects → reselectFormat
5. destEdgeFillAxis benannt
6. videoStabilizationApplies + CameraSession `#if os(iOS)`
7. Tests + MARKETING_VERSION 1.5.91 (Build 111)

## In 1.5.90 gelandet

1. displayLinkCoastTauAxis / Coast tauX/tauY — X am Rand stirbt, Y frei
2. pinchClickNeed ≥ pinchOpenNeed × dt — 15 fps zwei Uhren tot
3. deadManFistChip IDLE 1,2 — Faust vor Gaze-%
4. hudChipPeakHold 1 Frame WARP
5. palmHighpassAlpha 0,08–0,25
6. pointerPredictApplies Reduce Motion
7. reconnectCenterStageOff Continuity
8. Tests + MARKETING_VERSION 1.5.90 (Build 110)

## In 1.5.89 gelandet

1. destEdgeFill = destEdgeVel am Fill-Punkt — X Rand, Y frei. palmVelScreen roh
2. pinchCloseNeed / pinchPoseHoldNeed / poseHoldNeed dt ≥ 0,055 wie 8 fps
3. deadManFist 1,6 s aus bugfix 1.5.8, nicht mergen
4. palmHighpass Engine (Homographie + Relativ)
5. continuityUsbHold 400 ms + formatHopHold
6. pinchClickBlocksAfterScroll 180 ms
7. videoStabilizationOff Continuity (Math; macOS-API fehlt)
8. Tests + MARKETING_VERSION 1.5.89 (Build 109)

## In 1.5.88 gelandet

1. pinchWantOpen Extra-Margin ab 15 fps, pinchOpenNeed 15 fps = 2
2. luma420Lift 420v, enhanceSkipsCopy > 8 ms
3. formatScore Desk-View 4:3 1920×1440
4. pinchClickNeedsStill / pinchClickFires
5. destHudChip MAP≠STEAL → WARP → EDGE
6. formatCopyChip `COPY` > 8 ms
7. Tests + MARKETING_VERSION 1.5.88 (Build 108)

## In 1.5.87 gelandet

1. GestureTests `ptrPred` — `run()` redeclare `pred` brach swiftc
2. `availableVideoPixelFormatTypes` statt ObjC-CV-Infix
3. Tests + MARKETING_VERSION 1.5.87 (Build 107)

## In 1.5.86 gelandet

1. cursorWarpHoldsSmoothOf — nur überlaufende Achse freeze
2. cursorWarpCapAxis Breite/Höhe
3. displayLinkCursorOf Clamp je Achse
4. destMapStealChip MAP≠STEAL
5. Tests + MARKETING_VERSION 1.5.86 (Build 106)

## In 1.5.85 gelandet

1. Continuity sessionPreset aus — Preset clampte auf 8
2. lockFrameRate continuity 24 statt hart 30
3. displayLinkTimerRetarget 8↔24, thermalHoldsFormat 2 s unter 12
4. pinchClickNeed 15 fps interpoliert, Tip-Floor 0,10, AE 1,2 s
5. palmROI 1,8×, 8 fps kein Full-Pass
6. cursorWarpCapX = destEdgePad, pointerPredict 1 Frame
7. Format-Chip HUD, CS-Off Format nochmal, 422 vor BGRA
8. Tests + MARKETING_VERSION 1.5.85 (Build 105)

## Nächste, zusätzlich zur alten Liste

- Frame-Pump mit Aegis: eine Session, ein Buffer, eine TCC. XPC `helios.aegis.camera`.
- **CADisplayLink / CVDisplayLink** statt `Timer.scheduledTimer` — vsync, kein Coalesce-Burst.
- **Tests splitted.** Eine `run()`-Funktion, jeder Patch redeclare (`pred` 1.5.85/86). Ein File je Thema.
- destEdgeFillSkip tot nach Passthrough — Konstante kann weg.
- Overlay-Occlusion-Mesh (Palm-Polygon), nicht nur Tip-Distanz.
- AX kAXFocusedUIElementChanged statt Poll.
- 6-Punkt-Kalib gegen Kissenverzerrung.
- Watch / UWB (Nearby Interaction) als Pinch-Confirm.
- Continuity LiDAR-Z (iPhone Pro) statt Vision-3D.
- Per-App Gestenprofile (Safari Klick-Lock an, Figma aus).
- Hover-Dwell Dock 0,45 s ohne Pinch.
- Zwei-Finger-Rad auf Karten (AX scrollWheel).
- Stereo Continuity+Built-in für echte Z-Tiefe.
- Pointer-Acceleration aus Trackpad-Prefs lesen.
- Game-Controller / Siri Remote als Dead-Man.
- Click-Lock nach AX-Role (AXButton), nicht nur Bundle.
- Relativ-Zeiger Acceleration-Curve Pref (langsam/normal/flick).
- SpaceMap Auto-Recalib wenn RMS > 24 px für 2 s.
- Low-Power auf Akku: Vision 12 fps Cap.
- Kalib-Wizard UI mit Live-RMS und Abbruch > 40 px.
- Latency-HUD Kamera-Tick → AX-move. Über 40 ms Gain halbieren.
- Pinch-Index = Klick, Pinch-Mittel = Rechtsklick Pref.
- VoiceOver: „Safari, Link, 40 %“.
- Peek-through: Overlay 30 % wenn Cursor 1,2 s still.
- Menu-Bar Extra: letzte 8 Gesten, Tap = Undo-Stack 8. Caps-Lock-LED = Scharf.
- Audio-Click (leiser Tick) bei Pinch-Down.
- Triple-Pinch = Mission Control, hinter Pref.
- iPhone Action Button = Not-Aus.
- VNFace-Yaw als Gain-Dämpfer (Blick weg → Cursor träge).
- Pinch-Druck aus Tip-Konfidenz als Klick-Force.
- Haptic bei Steal-Relock und Ghost-Reconnect.
- Desk-View Homographie 8 Punkte, nicht 4 Ecken.
- Overlay peak-hold Ghost-Knochen 2 Frames — sitzt (1.5.92).
- Vision-Hand-ML Drop-in analog Aegis `.mlmodel`.
- Continuity Night-ISO Cap, AE nicht 3 s jagen nach Faust.
- Gaze-gated Click. VNFace-Yaw zur Bildschirmmitte, sonst kein Down.
- destEdge HUD `EDGE X 8` VoiceOver. Chip sitzt, Screen-Reader liest nichts.
- **GPUFrameRing Slot-Steal messen.** — sitzt (1.5.92) drop. **HUD `STEAL` sitzt (1.5.93).**
- **IOKit clamshell wake → reselectFormat.** — sitzt (1.5.91). AX-Cache nach Sleep — sitzt (1.5.92).
- **Vision .right nur Portrait-Buffer.** **0° Capture .up sitzt (1.5.93).**
- **AX TypeID Probe-Cache.** — sitzt invalidate nach Klappe (1.5.92). **TypeID in loadProbe sitzt (1.5.93).**
- **Metal-Preview 420f direkt.** NSImage-Preview aus Planar ohne BGRA-Kopie.
- **Two-hand ROI nil bleibt.** — sitzt 8 fps ROI halten (1.5.92). **Latch HUD `ROI S1` sitzt (1.5.93).**
- **Session-Preset `.inputPriority` wenn SDK das kann** — heute Preset komplett aus bei Continuity.
- **Shared XPC Frame-Pump mit Aegis 2.1.108** bleibt die größte einzelne Effizienz — dieselbe 0°-Geometrie.
- ** palmarer Dead-Man über AirPods-Mikro** — naher Fingertip-Klick als Confirm, ohne Watch.
- ** Overlay `PREDICT` Chip** wenn pointerPredict > 8 px.
- ** Continuity thermal Night-ISO Cap** analog Faust-AE, nicht nur Format halten.
- destEdgeFillAxis — sitzt (1.5.89).
- Dead-Man Faust 1,6 s — sitzt (1.5.89).
- palmHighpass Engine — sitzt (1.5.89). Alpha-Clamp sitzt (1.5.90). **Slider sitzt (1.5.92).**
- **Fling-Fenster Pref.** bugfix `flingFromTrail` nicht nachziehen — main-Fling ist Pinch-Trail.
- **MAP≠STEAL VoiceOver.** Chip sitzt, Screen-Reader liest nichts.
- Vision 420f native Ring — sitzt (1.5.91). Enhance 420 — sitzt (1.5.92).
- **pinchOpenNeed und pinchClickNeed koppeln.** — sitzt (1.5.90). pinchOpenHolds Sekunden — sitzt (1.5.92).
- **Center Stage nach Lid-Open.** reconnectCenterStageOff sitzt (1.5.90). reselectFormat sitzt (1.5.91). AX sitzt (1.5.92).
- **cursorWarpChip 1 Frame peak-hold.** — sitzt (1.5.90). Ghost 2 Frames — sitzt (1.5.92).
- **Fill-Cap Pref** Laptop vs 5K statt nur Screen-Diagonale.
- **IOHID Event-Tap statt CGEvent-Post** für Klick-Latency unter Continuity 15 fps.
- **Continuity Desk-View eigener Format-Zweig** analog Aegis yaw-floor 0,36.
- ** USB/Wi-Fi Continuity-Hysterese 400 ms** — sitzt (1.5.89).
- ** Pinch-Up Click-Lock 180 ms** — sitzt (1.5.89).
- ** Reduce Motion: pointerPredict aus** — sitzt (1.5.90). Overlay peak-hold Ghost 2 Frames — sitzt (1.5.92).
- VideoStabilization aus — Math sitzt (1.5.89), macOS-API fehlt.
- ** Dead-Man HUD Countdown** `IDLE 1,2` — sitzt (1.5.90).
- ** Fill-Coast × destEdgeMul.** — sitzt (1.5.90). tauX/tauY.
- ** palmHighpass Pref 0,08–0,25.** — sitzt Slider (1.5.92).
- ** Audio-Tick bei Pinch-Down** hinter Pref.
- ** destEdgePad aus PPI / Bezel-Lücke**, nicht hart 40 px — 5K vs 13″.
- ** Pinch-Hold abort wenn Wrist-MAD > Rest** — Tremor-Klick-Lock.
- ** Zwei-Hand-Scale Hysterese analog pinchCloseNeed.**
- ** AX Hit-Test Cache 2 Frames bei 8 fps.** — sitzt TTL 260 ms (1.5.93).
- ** Faust = Maustaste Pref** (offene Hand Hover, Faust Down).
- ** Overlay Ghost-Knochen peak-hold 2 Frames** — sitzt (1.5.92).
- ** ControlPanel Hochpass-Slider 0,08–0,25.** — sitzt (1.5.92).
- ** HUD `STEAL` wenn Ring Slot −1 droppt** — sitzt (1.5.93).
- ** palmHighpass je Hand (S1/S2).** — sitzt Reset (1.5.93). HUD α je Slot fehlt.
- ** Pinch-Force aus Tip-Spread-Ableitung** als Extra-Confirm neben still.
- ** Overlay VoiceOver-Queue 1,2 s** WARP/EDGE/STEAL, nicht jedes Frame.
- ** DisplayLink statt Timer** bleibt vsync; Coalesce-Burst 8↔24.
- ** Continuity LiDAR-Z** Pinch-Tiefe statt nur Vision-Scale.
- ** Per-App Gestenprofil** Safari Klick-Lock, Figma aus — click-lock.txt sitzt, UI fehlt.
- pinchWantOpen 15 fps Extra-Margin — sitzt.
- pinchOpenNeed 15 fps 2 — sitzt.
- luma420Lift 420v — sitzt.
- enhanceSkipsCopy — sitzt.
- formatScore 4:3 — sitzt.
- pinchClickNeedsStill — sitzt.
- destHudChip WARP — sitzt.
- formatCopyChip COPY — sitzt.
- Warp-Smooth je Achse — sitzt.
- Fill-Cap je Achse — sitzt.
- MAP≠STEAL — sitzt.
- ptrPred — sitzt.
- availableVideoPixelFormatTypes — sitzt.
- Continuity 24 fps anfragen — sitzt.
- palmROI expand 1,8× — sitzt.
- Timer-Retarget — sitzt.
- Joint-Conf Floor Continuity 0,10 — sitzt.
- warpCapX = destEdgePad — sitzt.
- Pointer-Predict 1 Frame — sitzt.
- sessionPreset Continuity aus — sitzt.
- H.264/422 Fallback vor BGRA — sitzt.
- thermal 2 s unter 12 — sitzt.
- activeFormat nach CS-Off nochmal — sitzt.

Nur main.

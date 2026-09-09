# Analyse Helios 1.6.102 + Aegis 2.1.249 — 2026-09-09 (Pass 51)

Kein Merge von `bugfix`. Predict bleibt 0. Kein neues *Need(dt). Kein neues leftover*-Flag.

## Helios — warum Gesten schlecht wirken

1. Continuity ~8 Hz. HUD-Lerp + palmWidth + Body/8 + Closedness-held sitzen. Predict bleibt 0.
2. analogClosed Mix + held freeze (Pass 50). Pass 51: Start/Hold Grab dieselbe `closedSmooth` — roh pinchClosedness leak't nicht mehr unter Hold 0,48.
3. Deadman hart 0,004 (Pass 50 tot). Pass 51: `palmDeadZone(dt)` 8 Hz ×1,55. Landmark 0,01 clutcht.
4. Ampel-Dwell roh 40 px @ 8 Hz. Pass 51: `magnet()` snapped.
5. Zwei Apps, eine Kamera. Mutex sample-fresh. Ohne CameraBroker zwei Vision, zwei TCC.
6. `bugfix` (~85 Versionen hinter main) — Merge wäre ein Wipe.

## Aegis — warum Identitäten schlecht wirken

1. leftoverPick twinPair nil ohne Live-Paar (2.1.247). Ada+Bob ohne Prints leftover darf.
2. leftoverGhostAspectLock hypot-Aspect (2.1.248). Trail-Hash live. roiEvery aus dt.
3. leftoverCaptureHistByHash war Burst-Kopie. Pass 51: Cap 8 Put, leftoverPick Lookup.
4. leftoverHoldsTrack yawAbs: nil bewusst. leftoverPrintBudgetYawDelta **Of je UUID**.
5. leftoverCaptureHistOf Box-first (≥3) bewusst — Gast erbt Annas Median nicht. Flash nach 3 Frames bleibt ein Loch.
6. LiveCapture `@MainActor`. Gallery linear. CameraBroker fehlt. CGImage-Kopie.

## Ineffizienzen (beide)

- Aegis: CGImage-Kopie statt `VNImageRequestHandler(cvPixelBuffer:)`. Helios sitzt auf PixelBuffer.
- SwiftUI Overlay-Rows statt Metal.
- Mutex-Datei statt XPC/IOSurface.
- Aegis Gallery linear leftoverHoldXMatch, skaliert nicht über Haushalts-Größe.

## Bugfix-Protokoll (Pass 51)

Pass 1 — Helios Deadman nie clutcht. Fix: palmDeadmanStill × palmDeadZone(dt).

Pass 2 — analog held freeze, Start/Hold roh. Fix: pinchStartsGrab/pinchHoldsGrab closedSmooth.

Pass 3 — Ampel-Dwell 40 px Reset. Fix: magnet() chromeDwellAt.

Pass 4 — Capture-Hist Burst pollutet Median. Fix: leftoverCaptureHistPut Cap 8 + leftoverPick Lookup.

## Nächster sinnvoller Code-Pass

1. CameraBroker XPC + IOSurface (Spec `docs/CameraBroker.md`). P0.
2. VNImageRequestHandler(cvPixelBuffer:) Aegis LiveCapture.
3. leftoverCaptureHistOf leftover wenn länger als Burst.
4. magnet() HUD-Cursor (Dwell sitzt).
5. Wrist-Vel Pinch-Veto / Per-Finger 4-Tip-Gate.
6. Overlay CAMetalLayer.

# Analyse Helios 1.6.101 + Aegis 2.1.248 — 2026-09-09 (Pass 50)

Kein Merge von `bugfix`. Predict bleibt 0. Kein neues *Need(dt). Kein neues leftover*-Flag.

## Helios — warum Gesten schlecht wirken

1. Continuity ~8 Hz. HUD-Lerp + palmWidth + Body/8 sitzen. Predict bleibt 0.
2. analogClosed Mix lerp't Closedness×z×Kontakt. Pass 50: Closedness **held freeze** — 8-Hz-Drop öffnet den Zug nicht.
3. ROI Scale lerp (Pass 50) statt Hart 1,6/3. Full every aus dt: 250 ms Wand bei 8 und 24 Hz.
4. 720@24 konnte 1080@15 nicht gewinnen (Cold-Start −90). Pass 50: `cameraFormatPromoted` +320 wenn gemessen ≥12 und Format ≥12. 1080@8 tot.
5. Zwei Apps, eine Kamera. Mutex sample-fresh. Ohne CameraBroker zwei Vision, zwei TCC.
6. `bugfix` (~85 Versionen hinter main) — Merge wäre ein Wipe.

## Aegis — warum Identitäten schlecht wirken

1. leftoverPick twinPair nil ohne Live-Paar (2.1.247). Ada+Bob ohne Prints leftover darf.
2. leftoverGhostAspectLock linear W/H dehnte die Box. Pass 50: hypot-Aspect, last Ratio, Size-Blend.
3. leftoverTrailWriteHash tot — leftoverLiveHash rief Hold-Hash. Pass 50: Trail-Hash live (Alias).
4. ROI/skipDetect every 2 @ 24 fps = Hitch. Pass 50: every aus dt (8 Hz /2, 24 Hz /4).
5. leftoverHoldsTrack yawAbs: nil bewusst. leftoverPrintBudgetYawDelta **Of je UUID** — global würde Ada still mit Twin-Drehung mitdrucken.
6. leftoverScore Twin-Penalty ist frame-global (ein twinPair) — Argmax ändert sich nicht. Kein Bug.
7. LiveCapture `@MainActor`. Gallery linear. CameraBroker fehlt. CGImage-Kopie.

## Ineffizienzen (beide)

- Aegis: CGImage-Kopie statt `VNImageRequestHandler(cvPixelBuffer:)`. Helios sitzt auf PixelBuffer.
- SwiftUI Overlay-Rows statt Metal.
- Mutex-Datei statt XPC/IOSurface.
- Aegis Gallery linear leftoverHoldXMatch, skaliert nicht über Haushalts-Größe.

## Bugfix-Protokoll (Pass 50)

Pass 1 — Helios analog Hold droppt 8 Hz. Fix: pinchClosednessSmooth held.

Pass 2 — Scale Hart-Cliff 12 fps. Fix: visionRoiScale lerp.

Pass 3 — 720@24 nie 1080@15. Fix: cameraFormatPromoted in bestFormat.

Pass 4 — Full-ROI 83 ms @ 24 fps. Fix: every aus dt, 250 ms Wand.

Pass 5 — Ghost-Box Stretch. Fix: leftoverGhostAspectLock hypot-Aspect.

Pass 6 — Trail-Hash tot. Fix: leftoverTrailWriteHash leftoverLiveHash.

Pass 7 — Detect 12 Hz @ 24 fps. Fix: roiEvery aus dt.

## Nächster sinnvoller Code-Pass

1. CameraBroker XPC + IOSurface (Spec `docs/CameraBroker.md`). P0.
2. VNImageRequestHandler(cvPixelBuffer:) Aegis LiveCapture.
3. LiveCapture off MainActor.
4. HNSW Gallery.
5. Wrist-Vel Pinch-Veto / Per-Finger 4-Tip-Gate.
6. Overlay CAMetalLayer.

P0: CameraBroker. Branch `bugfix` nicht mergen.

# Analyse Helios 1.6.100 + Aegis 2.1.247 — 2026-09-09

Kein Merge von `bugfix`. Predict bleibt 0. Kein neues *Need(dt). Kein neues leftover*-Flag.

## Helios — warum Gesten schlecht wirken

1. Continuity ~8 Hz. HUD-Lerp + palmWidth sitzen. Predict bleibt 0.
2. analogClosed Mix lerp't Closedness×z×Kontakt. Faust/Schnabel/Pinzette teilen eine Achse.
3. ROI Scale 1,6 + Full/2 sitzt. Body-Pose war **immer skip** @ 8 Hz — L/R tot. Pass 49: jedes 8. Tick.
4. Zwei Apps, eine Kamera. Mutex sample-fresh. Ohne CameraBroker zwei Vision, zwei TCC.
5. `bugfix` (1.6.15) ist 80 Versionen hinter main — Merge wäre ein Wipe.

## Aegis — warum Identitäten schlecht wirken

1. leftoverPick twinPair Live sitzt (2.1.246), Fallback war Gallery-Centroid. Ohne 32-d Vec (erstes Sample, skipPrints) → Ada+Bob Hard-Veto 0,88. Pass 49: nil statt Gallery.
2. liveRoiPeriodicFull Default 8 = 1 s Walk-in. leftoverDetectSkipTick every 4 = Detect tot 3/4. Pass 49: both every 2.
3. leftoverHoldsTrack yawAbs: nil bewusst. LiveCapture `@MainActor`. Gallery linear. CameraBroker fehlt. CGImage-Kopie.

## Erweiterung (neu)

943. **CameraBroker XPC + IOSurface.** P0. Spec `docs/CameraBroker.md`.
944. **VNImageRequestHandler(cvPixelBuffer:)** Aegis.
945. **LiveCapture off MainActor.**
946. **HNSW Gallery.**
947. **Adaptive skipDetect** visionMs + stillFor.
948. **visionRoiScale lerp.**
949. **Per-Finger 4-Tip-Gate.**
950. **Wrist-Vel Pinch-Veto.**

P0: CameraBroker. Branch `bugfix` nicht mergen.

# Analyse Helios 1.6.99 + Aegis 2.1.246 — 2026-09-09

Kein Merge von `bugfix`. Predict bleibt 0. Kein neues *Need(dt). Kein neues leftover*-Flag.

## Helios — warum Gesten schlecht wirken

1. Continuity ~8 Hz. HUD-Lerp + palmWidth sitzen (1.6.98). Predict bleibt 0.
2. analogClosed Mix lerp't Closedness×z×Kontakt. Faust/Schnabel/Pinzette teilen eine Achse.
3. ROI Scale 1,6 (1.6.98) + Full/2 (1.6.99, war /4 = 500 ms). Zweite Palme 250 ms.
4. Zwei Apps, eine Kamera. Mutex sample-fresh (1.6.98). Ohne CameraBroker zwei Vision, zwei TCC.
5. `bugfix` (1.6.15) ist 80 Versionen hinter main — Merge wäre ein Wipe.

## Aegis — warum Identitäten schlecht wirken

1. leftoverPick twinPair war Gallery-Centroid (Ada vs Schwester 0,90). Zwei Live-Kisten Ada+Bob → Hard-Veto 0,88 obwohl Live-Cosine 0,40. Pass 48: max paarweise Live-Print.
2. leftoverPrintYawMerge printCommitted sitzt (2.1.245). leftoverHoldsTrack yawAbs: nil bewusst.
3. LiveCapture `@MainActor`. skipDetect every 4. Gallery linear. CameraBroker fehlt. CGImage-Kopie.

## Erweiterung (neu)

936. **CameraBroker XPC + IOSurface.** P0.
937. **Adaptive ROI every aus dt.**
938. **VNImageRequestHandler(cvPixelBuffer:)** Aegis.
939. **HNSW Gallery.**
940. **LiveCapture off MainActor.**
941. **Per-Finger 4-Tip-Gate.**
942. **Body-Pose @ 8 Hz jedes 8. Tick.**

P0: CameraBroker. Branch `bugfix` nicht mergen.

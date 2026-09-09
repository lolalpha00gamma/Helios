# Analyse Helios 1.6.97 + Aegis 2.1.244 — 2026-09-09

Kein Merge von `bugfix`. Predict bleibt 0. Kein neues *Need(dt). Kein neues leftover*-Flag.

## Helios — warum Gesten schlecht wirken

1. Continuity ~8 Hz. HUD-Lerp/Coast + palmWidth-Cap sitzen (1.6.96). Samples 125 ms. Predict bleibt 0.
2. analogClosed mischt jetzt Closedness×z×Kontakt, Mix lerp't. Faust/Schnabel/Pinzette teilen weiter eine Achse — Kontakt ist ein Skalar, kein 4-Tip-Gate.
3. ROI Miss-1 + Full/4, Scale 3. Zweite Hand außerhalb des Crops erst nach 500 ms.
4. Zwei Apps, eine Kamera. Mutex+TERM. Ohne CameraBroker zwei Vision, zwei TCC.
5. `bugfix` (1.6.15) ist 80 Versionen hinter main — Merge wäre ein Wipe, kein Fix. IOHID/AX/JSONL dort neu schreiben, nicht mergen.

## Aegis — warum Identitäten schlecht wirken

1. leftoverTwinSameShot saß nur im HardVeto. leftoverAmbiguousBlocks ließ Schärfe Ada unter zwei Live-Kisten wählen (Spread < 0,08). Pass 46 blockt Same-shot Rank.
2. leftoverPrintYawMerge `printedIds: []` ist bewusst tot — Stamp committet.
3. leftoverHoldsTrack `yawAbs: nil` bewusst: Overlay-Hold 0,64 auf Profil.
4. LiveCapture `@MainActor`. skipDetect every 4. Gallery linear. CameraBroker fehlt.

## Erweiterung (neu)

890. **CameraBroker XPC + IOSurface** mit Aegis. P0.
891. **formatPromoted 720p24 → 1080p15.**
892. **ROI scale 1,6** Continuity.
893. **VNTrackObjectRequest.**
894. **DisplayLink Pause bei Freeze.**
895. **Overlay palmWidth Lerp** prev→next.
896. **leftoverPrintYawMerge printedIds: printCommitted** (jetzt `[]` = no-op).
897. **sampleCursorYieldsToCoast** immer false.
898. **HNSW Gallery.**
899. **LiveCapture off MainActor.**
900. **Per-Finger 4-Tip-Gate.**

P0: CameraBroker. Branch `bugfix` nicht mergen.

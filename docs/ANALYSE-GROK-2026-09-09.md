# Analyse Helios 1.6.98 + Aegis 2.1.245 — 2026-09-09

Kein Merge von `bugfix`. Predict bleibt 0. Kein neues *Need(dt). Kein neues leftover*-Flag.

## Helios — warum Gesten schlecht wirken

1. Continuity ~8 Hz. HUD-Lerp/Coast + palmWidth-Lerp sitzen (1.6.98). Samples 125 ms. Predict bleibt 0.
2. analogClosed mischt Closedness×z×Kontakt, Mix lerp't. Faust/Schnabel/Pinzette teilen weiter eine Achse — Kontakt ist ein Skalar, kein 4-Tip-Gate.
3. ROI Miss-1 + Full/4, Scale 1,6 Continuity / 3 Built-in (1.6.98). Hart-Schwelle 0,10 s, kein Lerp.
4. Zwei Apps, eine Kamera. Mutex Stamp+Lock nur frisches Sample (1.6.98). Ohne CameraBroker zwei Vision, zwei TCC.
5. `bugfix` (1.6.15) ist 80 Versionen hinter main — Merge wäre ein Wipe, kein Fix. IOHID/AX/JSONL dort neu schreiben, nicht mergen.

## Aegis — warum Identitäten schlecht wirken

1. leftoverTwinSameShot saß nur im HardVeto. leftoverAmbiguousBlocks ließ Schärfe Ada unter zwei Live-Kisten wählen. Pass 46 blockt Same-shot Rank.
2. leftoverPrintYawMerge printedIds: printCommitted (1.6.98 / 2.1.245). Stamp-Miss seedet. leftoverHoldsTrack yawAbs: nil bewusst.
3. leftoverLastHash nach Coast-Wipe live ∪ Coast (2.1.245). leftoverOccupiedOthers roh — GhostDrop sitzt nur im Merge-Pfad.
4. LiveCapture `@MainActor`. skipDetect every 4. Gallery linear. CameraBroker fehlt.

## Erweiterung (neu)

901. **CameraBroker XPC + IOSurface** mit Aegis. P0.
902. **formatPromoted 720p24 → 1080p15.**
903. **VNTrackObjectRequest.**
904. **DisplayLink Pause bei Freeze.**
905. **visionRoiScale lerp** statt Hart 0,10 s.
906. **sampleCursorYieldsToCoast** immer false.
907. **HNSW Gallery.**
908. **LiveCapture off MainActor.**
909. **Per-Finger 4-Tip-Gate.**
910. **leftoverOccupiedOthers leftoverOccupiedGhostDrop.**
911. **Mutex stamp+lock atomic.**
912. **SpaceMap Recenter ScreenParameters.**

P0: CameraBroker. Branch `bugfix` nicht mergen.

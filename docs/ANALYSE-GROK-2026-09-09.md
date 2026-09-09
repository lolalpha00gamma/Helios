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

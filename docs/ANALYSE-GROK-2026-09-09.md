# Analyse Helios 1.6.96 + Aegis 2.1.243 — 2026-09-09

Kein Merge von `bugfix`. Predict bleibt 0. Kein neues *Need(dt).

## Warum Gesten schlecht wirken

Continuity ~8 Hz. HUD-Lerp/Coast sitzen, Samples 125 ms. Pinch ist ein Skalar. ROI Miss-1 + Full/4. Zwei Apps, eine Kamera. GestureEngine-Helfer waren oft tot ohne Call-Site.

## Erweiterung (neu)

856. **CameraBroker XPC + IOSurface** mit Aegis. P0.
857. **hudCoast Cap aus palmWidth.**
858. **Per-Finger-Kontakt** analog mix.
859. **formatPromoted** 720p24 → 1080p15 nach inputPriority.
860. **SpaceMap Recenter nach Wake.**
861. **VNTrackObjectRequest** auf lastRoi.
862. **DisplayLink Pause bei Freeze.**
863. **Cover-Lead Homographie Blend.**
864. **Vision joint-conf** in analogClosed.
865. **HeliosAegisKit** Mutex einmal.

P0: CameraBroker. Branch `bugfix` nicht mergen.

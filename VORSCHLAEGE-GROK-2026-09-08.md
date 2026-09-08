# Helios Vorschläge — 2026-09-08 (Pass 2, 1.6.41)

Stand 1.6.41 / Build 74. Ergänzung, keine Kopie der erledigten Fusion/Retry/Q/Drag-Fixes.

## Gelandet in 1.6.41 (dieser Pass)

Source-Tag, Reliability-Decay, Format-Retry 3 s, Kalman-Q(fps), pinchBecameDrag × dt. Kein viertes `*Need(dt)` für dieselbe Pinch-Kante außer Drag — das war die offene 1.6.40-Liste #12/#47/#29.

## Erweiterung (neu, nicht in der 1.6.41-Liste)

51. **Continuity-Format-Leiter** 720p@24 → 960p@15 → 640p@30, nicht ein Retry desselben 1080p@8.
52. **Zwei-Hand Pinch als Enum** Unseen/Tentative/Held/Released — `pinchHeld` + sechs Uhren bleibt die Uhr.
53. **Pointer-Accel × backingScaleFactor** je NSScreen, nicht 48 px universal.
54. **HUD Pose-Chips am DisplayLink** auch wenn Detect 8 Hz friert.
55. **Session-Watchdog** Idle nur fps>0 UND keine Aegis-Face UND 8 s leer.
56. **mmap leftover-Boxen** Helios↔Aegis, nicht Datei-Poll.
57. **Palm-Silhouette Click-Lock** Aspect Kante-an = kein Klick.
58. **Per-Finger One-Euro**, nicht nur pinchRatio.
59. **VoiceOver-Rotor** Peace-Hold mappt Rotor, nicht System-Cmd.
60. **Fail-closed TCC** AX-Drop → freeze, nie CGWarp(0,0).
61. **Cover-Lead Blend nur Quality-Gap** (Liste 31, noch offen).
62. **Track-ID über uniqueID** Palm-Raum + letzte Homographie (Liste 30).
63. **Stereo Mac+Phone z aus Disparität**, Lift-Gewicht dann wirklich 0,06.
64. **On-Device Create ML** aus `gesten.jsonl` ohne Bundle-Modell.
65. **Tests ohne Vision.framework** Fusion/HMM auf Linux-CI (reine Double-Math).

P0 bleibt CameraBroker. P1 DisplayLink. P2 Pose-Hold-SM. Kein 1.6.42-dt-Pflaster ohne eines davon.

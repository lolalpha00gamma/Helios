# Helios Vorschläge — 2026-09-08

Stand 1.6.40 / Build 73. Ergänzung zu `VORSCHLAEGE.md`, keine Kopie der erledigten dt-Fixes.

## Warum poorly: Kurzform

8 fps Continuity + Stub-Depth + korrelierte Fusion + HUD am Detect-Takt. Die 1.6.32–40-Serie hat die Uhr geflickt, nicht die Architektur.

## Erweiterung (neu, nicht in der 1.6.40-Liste)

26. **Pose als Hold-SM** Unseen / Tentative / Held / Released — statt `pinchHeld` Bool + sechs Uhren.
27. **Reliability-Decay** fehlender Fusion-Quellen (EstimateFusion Pass 1).
28. **fused.source = argmax Gewicht**, nicht immer geometry2D.
29. **Format-Renegotiate Retry** nach 3 s wenn fps wieder < 12 (einmal reicht nicht).
30. **Track-ID über uniqueID-Wechsel** per Palm-Raum + letzte Homographie, nicht nur recenter.
31. **Cover-Lead Blend nur bei Quality-Gap**, nicht sobald Lead einen Landmark-Tick verliert.
32. **Clutch-Radius × dpi** — 48 px auf 5K ist ein anderes Totfeld als auf 1080p.
33. **Peace/Kill/Scroll Prioritätstabelle** eine Datei, nicht verstreute `if` in GestureEngine.
34. **Session-JSONL Replay** gegen CoordTests, nicht nur Live-HUD.
35. **Vision revision unpin + Fallback** wenn Continuity die gepinnte Revision droppt.
36. **Zwei-Session CPU-Budget** — Cover auf 12 fps hard-cap, Lead bekommt die Queue.
37. **AX tree snapshot 200 ms**, nicht hitTest-Punkt-Cache 1 Frame.
38. **Pinch analog 0…1 × Fensterhöhe** als Magnify-Gain, Bool-Zoom nur Lock.
39. **Gaze-from-Aegis Click-Lock** Shared Memory / Mutex, nicht Poll-Datei.
40. **HeliosAegisKit** IOSurface + flock v2 + PTS. P0 mit Aegis.
41. **Watch-Kompass** nur Confirm, nie Cursor.
42. **On-Device Create ML** aus `gesten.jsonl` ohne Bundle-Datei-Pflicht.
43. **Stereo Mac+Phone** z aus Disparität, Lift-Gewicht dann wirklich 0,06.
44. **Dead-Man sichtbar** HUD-Ring 8 s bevor Idle, nicht stiller Rearm.
45. **Per-App Gain Profil Datei** `~/Library/Application Support/Helios/apps.json`, nicht nur Enum.
46. **Overlay Metal Strip** Fusion-Gewichte 90 Hz, Detect 8–24.
47. **Kalman-Q(fps)** 1.6.40 hat Reibung 0,94 fest.
48. **Handedness Vote Körper nur bei zwei Handgelenken sichtbar**, sonst Vision-Label.
49. **emptyHandsHold nicht Cursor und Gate gleichzeitig** — Gate drop, Cursor coast.
50. **Tests ohne Vision.framework** für Fusion/HMM auf Linux-CI (reine Double-Math), Mac nur Golden-Frames.

P0 bleibt CameraBroker. P1 DisplayLink. P2 Fusion Source-Tag. Kein 1.6.41-dt-Pflaster ohne eines davon.

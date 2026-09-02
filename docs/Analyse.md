# Analyse, Fehlerbehebung, öffentlicher Abgleich

Stand: 2026-09-02. Helios 1.6.1. Alle fünf Phasen aus `docs/Erkennung.md`
laufen gleichzeitig — kein Stufenplan. 1.6.1 kollabiert korrelierte Quellen.

## 1. Bestand vor der Umstellung (1.5.7)

Eine Quelle: `VNDetectHumanHandPoseRequest`, 21 Gelenke ohne z.
One-Euro, Radial-`isExtended`, binäre Posen, PinchGate und 2-Frame-Halter
alle an der Chiralität hängend. Das bricht bei:

- Verkürzung (Hand zur Kamera) — offene Hand wird Faust
- Kippung — `palmScale` schrumpft, Pinzette fällt raus
- zwei Hände auf derselben Bildseite — Zustand überschrieben
- 1280×720 — `hypot` mischt 128 px und 72 px (bis 78 % Diagonalefehler)
- 15 vs 60 fps — Streaks in Frames, nicht Sekunden
- grober Landmark-Sprung — Filter folgt ihm
- classify auf geglättet, PinchGate auf roh — drei Sonderfälle kitten das

1.5.7 hatte die **Aktionsseite** schon repariert (AX in Cocoa, Flick-Wischen,
Faust ohne Klick, Peace 0,9 s, Not-Aus 0,8 s). Die **Erkennung** blieb 2D.

## 2. Was jetzt läuft

```
Frame ─┬─► 2D   Gelenkwinkel, Softmax, isotropes palmScale
       ├─► 3D   Knochenlängen-Lift (jede Webcam)
       ├─► Tiefe  AVCaptureDepthDataOutput, sonst Gewicht 0
       └─► Zeit  12×8 Merkmale, optional HeliosTemporal.mlmodel
                 └─► log-Pooling + inverse Varianz + HMM (Sekunden)
```

Track-ID (gierig 2×2 auf Palm-Abstand) statt Links/Rechts als Schlüssel.
Chiralität bleibt Attribut. Ausreißer: 3,5·Median, One-Euro mit dt in
Sekunden. Wurf/Wischen/Skalieren in **Handbreiten**. Systemaktionen ab
Pose-p ≥ 0,62. 1.5.7-Sicherheit bleibt: Not-Aus 0,8 s und openScore ≥ 4,
Scharf-Ruhe 0,7 s, Peace 0,9 s, Cooldown bewegt den Cursor weiter.

Bekannte Restgrenze: ohne echte Tiefe ist 3D-Lift aus denselben 2D-Punkten
*nicht unabhängig*. Deshalb fällt sein Basisgewicht von 0,28 auf 0,12,
sobald `AVCaptureDepthDataOutput` liefert. Lift bleibt Backup.

## 3. Fehler, die die Umstellung schließt

| # | Bug | Fix |
|---|---|---|
| 1 | Perspektivische Verkürzung | 3D-Winkel + optionale Tiefe |
| 2 | palmScale-Kippung | Median aus vier Strecken + Achsenkorrektur |
| 3 | Chiralität als Schlüssel | ungarische Track-ID, Chiralität nur Label |
| 4 | anisotrope hypot | `AspectSpace` x′ = x·(w/h) |
| 5 | binäre Kanten Faust/offen | Softmax über 7 Klassen |
| 6 | Konfidenz nur Schwelle | Gewicht in Merkmal, quality, Fusion |
| 7 | Frame-Streaks | Sekunden (HMM 80 ms, PinchGate 32/55 ms) |
| 8 | zwei Wahrheiten classify/Pinch | beide auf geglätteten Punkten |
| 9 | Ausreißer | 3,5 · Median, extrapolieren statt folgen |
| 10 | absolute Bildschwellen | Handbreiten (Wisch 0,85, Wurf 2,6 hw/s) |

Zusätzlich in dieser Runde behoben:

- **Lift-Palm in Iso-Koordinaten** würde die Fusion verschieben → Palm bleibt
  Vision-[0,1], nur Winkel laufen in 3D.
- **Tiefen-Attach am Default-Format** fand kein Depth-Format, obwohl ein
  anderes Format welches hat → Output hängt, sobald *irgendein* Format Tiefe
  kann; `activeDepthDataFormat` nach `bestFormat`.
- **Isotropie-Test** verglich 0,1 in x mit 0,1 in y (das *ist* der Bug) →
  100 px gegen 100 px.
- **FusionStrip** war unverdrahtet.
- **pbxproj** kannte AspectSpace/Lift/Fusion nicht — Xcode hätte die neuen
  Dateien ignoriert.

## 4. Öffentliche Repos — Abgleich

Inspiriert von Tracker, Desktop-Control und 3D-Lift, inklusive Windows/Linux.

| Projekt | Plattform | Übernommen | Verworfen / warum nicht |
|---|---|---|---|
| [google-ai-edge/mediapipe Hands](https://github.com/google-ai-edge/mediapipe) | alle | 21 Landmarken; **x/y getrennt auf Breite/Höhe normiert** (genau unser Bug); z in x-Skala; Handedness als Attribut + Score; Tracking statt Re-Detect | Palm-Detector-CNN — Vision ersetzt ihn. World-Landmarks in Metern brauchen ihren Regressor. |
| [casiez/OneEuroFilter](https://github.com/casiez/OneEuroFilter) | C++/JS | minCutoff + β·\|dx\|, **dt in Sekunden** | — |
| [geaxgx/depthai_hand_tracker](https://github.com/geaxgx/depthai_hand_tracker) | Linux / OAK-D | Body-Pre-Focus: Unterarm-Achse als Qualitäts-Prior (`forearmGate`). Stereo-xyz wo Hardware es hat | Eigenes Palm-CNN; OAK-only Runtime |
| [CalciferZh/minimal-hand](https://github.com/CalciferZh/minimal-hand) | Python | IK/Knochenlängen für 2D→3D, Restfehler als quality | 100 fps GPU-IK-Netz, zu schwer fürs HUD |
| [kinivi/hand-gesture-recognition-mediapipe](https://github.com/kinivi/hand-gesture-recognition-mediapipe) | Python | Landmarken → kleines zeitliches Netz (12 Frames) | SVM/MLP von Grund auf — wir trainieren aus `gesten.jsonl` |
| [vladmandic/human](https://github.com/vladmandic/human) | Web | getrennte Body- und Hand-Modelle, Gesture als Verteilung nicht als argmax | TF.js-Bundle |
| [handtracking-io/yoha](https://github.com/handtracking-io/yoha) | Web | Track-Identität über Palm-Nähe | eigene Detektoren |
| [ultraleap/UnityPlugin](https://github.com/ultraleap/UnityPlugin) | Win/macOS | Pose-Stabilität, **Pinch als Analogwert 0…1** (kein Bool) | Stereo-IR-Hardware |
| [xinghaochen/awesome-hand-pose-estimation](https://github.com/xinghaochen/awesome-hand-pose-estimation) | Survey | MANO-Knochenverhältnisse fürs Lift | Mesh-Fit |
| [ahmetg0/AirTouch](https://github.com/ahmetg0/AirTouch) | macOS | One-Euro 1:1 (CHI 2012), Webcam-Desktop ohne Headset | bleibt 2D |
| [sunnycho100/HandCursor](https://github.com/sunnycho100/HandCursor) | iOS/macOS | Stabilisierungsschicht vor Gestenlogik | Ein-Hand, kein Fusion |
| [sayginsaman/hand-gesture-desktop-controller](https://github.com/sayginsaman/hand-gesture-desktop-controller) | Win/Linux Python | PyAutoGUI-Mapping Webcam → Desktop | MediaPipe-JS/Python, keine nativen AX-Rechte |
| [ThatsPelle/HandFlow](https://github.com/ThatsPelle/HandFlow) | Windows | nativer Cursor aus Webcam | Electron, kein macOS-AX |
| [vkDemon1/GestureApp](https://github.com/vkDemon1/GestureApp) | Windows | TFLite-Gesten + MediaPipe | PyQt6, keine Fusion |
| [Sarab-Rehman-1918/GestureDesk](https://github.com/Sarab-Rehman-1918/GestureDesk) | Win/Linux | Touchless Desktop, optionales Face-Lock | OpenCV+PyAutoGUI |

Was fast niemand von denen hat und Helios jetzt hat:

1. **Log-Meinungspooling** mehrerer Quellen (2D / Lift / Tiefe / Zeit) statt
   Winner-takes-all.
2. **Unabhängigkeit der Fehler** — Lift-Gewicht fällt, sobald echte Tiefe da
   ist. MediaPipe mischt z aus demselben 2D-Netz; wir tun das bewusst nicht
   als zweite Stimme, wenn ein Depth-Kanal existiert.
3. **Native macOS-AX** (Fenster greifen, Snap, Papierkorb) — die Python-Clones
   klicken nur die Maus.
4. **Schwellen in Handbreiten**, nicht Bildanteilen — Abstand zur Kamera ändert
   die Gesten nicht mehr.

MediaPipe selbst warnt: x und y sind *getrennt* normiert. Deren Landmark-Modell
gibt z bereits in x-Skala aus; Vision tut das nicht, deshalb Lift + optionale
Tiefe.

## 5. Was offen bleibt

- `HeliosTemporal.mlmodel` liegt nicht im Bundle. Heuristik übernimmt
  (quality ≤ 0,62). Training: Create ML auf exportiertem `gesten.jsonl`
  (Feld `label` + 12×8 Merkmale), Output als `macos/Helios/HeliosTemporal.mlmodel`.
- Echte Tiefe nur wenn irgendein Format `supportedDepthDataFormats` hat
  (Continuity Camera mit LiDAR / manche iPhone-Continuity, fast keine
  Built-in-Mac-Webcam).
- Kein On-Device-Training.
- 3D-Lift-Vorzeichen ist kinematisch (curl-in / zeitlich) — bei einer
  völlig neuen Pose ohne History kann z kippen, bis das HMM hält.
- Tests laufen nicht in dieser Linux-Sandbox (kein Vision.framework).
  Lokal: `swift macos/HeliosTests/CoordTests.swift` und der GestureTests-@main.

## 6. Dateien

| Datei | Rolle |
|---|---|
| `AspectSpace.swift` | isotropes x′ = x·(w/h) |
| `HandEstimate.swift` | gemeinsame Schätz-Schnittstelle |
| `EstimateFusion.swift` | log-Pooling, inverse Varianz, adaptive Gewichte |
| `PoseHMM.swift` | Vorwärtsfilter, Umschalten ≥ 80 ms und p ≥ 0,62 |
| `Lift3D.swift` | z² = L² − (Δx²+Δy²) |
| `TemporalNet.swift` | Heuristik-GRU / optionales Core ML |
| `DepthCapture.swift` | echte Tiefe, sonst nil |
| `FusionStrip.swift` | Inspector: Gewichte, Pose-p, Tiefe an/nur Lift |
| `LandmarkSmoothing.swift` | One-Euro + 3,5·Median |
| `GestureClassifier.swift` | Winkel, Softmax, robustes palmScale |
| `HandTracker.swift` | Track-ID, Unterarm-Prior, Fusion |
| `GestureEngine.swift` | Handbreiten + 1.5.7-Sicherheit + p ≥ 0,70 |
| `CameraSession.swift` | Depth-Output, Format mit Depth-Bonus |
| `SessionExport.swift` | `z`, `label` für Create ML |

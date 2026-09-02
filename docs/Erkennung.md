# Erkennung — implementiert (kein Phasenplan)

Stand: 2026-09-02, Helios 1.6.0. Alle fünf Phasen aus dem
Konsolidierungsdokument laufen gleichzeitig. Fällt eine Quelle aus, geht
ihr Fusionsgewicht auf 0.

## Pipeline

```
Frame ─┬─► 2D  Vision-Landmarken, Gelenkwinkel, isotrope Geometrie
       ├─► 3D  Knochenlängen-Lifting  (jede Webcam)
       ├─► Tiefe  AVCaptureDepthDataOutput  (falls das Gerät sie hat)
       └─► Zeit  12-Frame-Merkmale, optional HeliosTemporal.mlmodel
                 └─► log-Pooling + inverse Varianz + HMM (Sekunden)
```

## Dateien

| Datei | Rolle |
|---|---|
| `AspectSpace.swift` | x·(w/h), alle Abstände isotrop |
| `HandEstimate.swift` | gemeinsame Schätz-Schnittstelle |
| `EstimateFusion.swift` | log-Pooling, inverse Varianz, adaptive Gewichte |
| `PoseHMM.swift` | Vorwärtsfilter, Umschalten ≥ 80 ms und p ≥ 0.62 |
| `Lift3D.swift` | z² = L² − (Δx²+Δy²), Vorzeichen aus Kinematik + Zeit |
| `TemporalNet.swift` | Heuristik-GRU / optionales Core ML |
| `DepthCapture.swift` | echte Tiefe, sonst nil |
| `LandmarkSmoothing.swift` | One-Euro + 3,5·Median-Ausreißer |
| `GestureClassifier.swift` | Winkel, Softmax, robustes palmScale |
| `HandTracker.swift` | Track-ID (ungarisch), Unterarm-Prior, Fusion |
| `GestureEngine.swift` | Schwellen in Handbreiten, Aktionen ab p ≥ 0.70 |
| `FusionStrip.swift` | Inspector-Diagnose |

## Gewichte

Start: 2D 0.40, 3D-Lift 0.28, Tiefe 0.22, Zeit 0.25.
Ist echte Tiefe da, fällt das Lift-Gewicht auf 0.12 — die Fehler der
Tiefenquelle dürfen nicht dieselben 2D-Punkte sein.

## Aktions-Sicherheit (aus 1.5.7, bleibt)

Not-Aus 0,8 s und openScore ≥ 4. Scharf-Ruhe 0,7 s (Faust wird kein Klick).
Peace 0,9 s. Cooldown bewegt den Cursor weiter, blockt nur Aktionen.
Wischen ist ein Flick (0,08–0,40 s, 0,85 Handbreiten, waagerecht).

## Core ML

Bundle-Datei `HeliosTemporal.mlmodelc` (12 × 8 Merkmale → 7 Klassen).
Fehlt sie: Heuristik mit quality ≤ 0.62.
Training aus `gesten.jsonl` Feld `label` (Create ML / coremltools),
nicht on-device.

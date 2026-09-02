# Erkennung — implementiert (kein Phasenplan)

Stand: 2026-09-02, Helios 1.6.6. Alle fünf Phasen aus dem
Konsolidierungsdokument laufen gleichzeitig. Fällt eine Quelle aus, geht
ihr Fusionsgewicht auf 0. Korrelierte Quellen (Lift/Zeit ≈ 2D) werden
kollabiert, sonst flacht die Pose unter das Aktions-Tor.

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
| `PoseHMM.swift` | Vorwärtsfilter, Umschalten ≥ 50 ms und p ≥ 0.48 |
| `Lift3D.swift` | z² = L² − (Δx²+Δy²), Vorzeichen aus Kinematik + Zeit |
| `TemporalNet.swift` | Heuristik-GRU / optionales Core ML |
| `DepthCapture.swift` | echte Tiefe, sonst nil |
| `LandmarkSmoothing.swift` | One-Euro + 3,5·Median-Ausreißer |
| `GestureClassifier.swift` | Winkel, Softmax, robustes palmScale, Pinch-Timeout 0,32 s |
| `HandTracker.swift` | Track-ID, Unterarm-Prior, kein Chirality-Doppel-Flip |
| `GestureEngine.swift` | Schwellen in Handbreiten, Aktionen ab p ≥ 0.62 |
| `FusionStrip.swift` | Inspector-Diagnose, kollabierte Quellen |

## Gewichte

Start: 2D 0.62, 3D-Lift 0.14, Tiefe 0.32, Zeit 0.16.
Ist echte Tiefe da, fällt das Lift-Gewicht auf 0.06. Überlappen Lift oder
Zeit die 2D-Verteilung zu mehr als 80 %, fällt ihr Rohgewicht auf 22 % —
sonst ist die Fusion drei Stimmen desselben Fehlers.

Softmax-Temperatur 0.75. Aktions-Tor 62 %.

## Aktions-Sicherheit (aus 1.5.7, bleibt)

Not-Aus 0,8 s und openScore ≥ 4, Kill-Grace 0,14 s. Scharf-Ruhe 0,7 s
(Faust wird kein Klick). Peace 1,1 s, nur Steuerhand, andere Hand nicht offen.
Cooldown bewegt den Cursor weiter, blockt nur Aktionen. Wischen ist ein Flick
(0,08–0,40 s, 0,85 Handbreiten, waagerecht, offene Steuerhand), plus Mute 0,75 s
nach Pinzette und Gegenrichtungs-Sperre 1,1 s. Kein ⌘⇥-Fallback. Werfen aus den letzten 120 ms;
nach echtem Zug 2,4× Schwelle. Dead-Man 8 s ohne Hand → Idle. Relativ-Zeiger:
Palm-Hochpass gegen Atem. Pinzette-Actor ist die Hand, die das Gate geschlossen
hat. Klick wenn still (< 0,45 Handbreiten). Zwei-Pinzetten-Skalieren ab 0,55 Handbreiten,
Gegenrichtung 1,8×. Doppelklatschen: Palmenabstand fällt in ≤ 0,28 s unter 1,4 Handbreiten
mit ≥ 5,5 HW/s, zweites Mal in 0,14–0,90 s — nur Kamera, kein Audio. Läuft im Idle.

## Core ML

Bundle-Datei `HeliosTemporal.mlmodelc` (12 × 8 Merkmale → 7 Klassen).
Fehlt sie: Heuristik mit quality ≤ 0.62.
Training aus `gesten.jsonl` Feld `label` (Create ML / coremltools),
nicht on-device.

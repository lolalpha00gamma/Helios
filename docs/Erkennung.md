# Erkennung — implementiert (kein Phasenplan)

Stand: 2026-09-02. Alle fünf Phasen aus dem Konsolidierungsdokument laufen
gleichzeitig. Fällt eine Quelle aus, geht ihr Fusionsgewicht auf 0.

## Pipeline

Frame -> 2D Vision + Gelenkwinkel + isotrop
      -> 3D Knochenlängen-Lifting (jede Webcam)
      -> Tiefe AVCaptureDepthDataOutput (falls vorhanden)
      -> Zeit 12-Frame-Merkmale, optional HeliosTemporal.mlmodel
      -> log-Pooling + inverse Varianz + HMM (Sekunden)

## Dateien

| Datei | Rolle |
|---|---|
| AspectSpace.swift | x*(w/h), alle Abstände isotrop |
| HandEstimate.swift | gemeinsame Schätz-Schnittstelle |
| EstimateFusion.swift | log-Pooling, inverse Varianz, adaptive Gewichte |
| PoseHMM.swift | Vorwärtsfilter, Umschalten >= 80 ms und p >= 0.62 |
| Lift3D.swift | z^2 = L^2 - (dx^2+dy^2) |
| TemporalNet.swift | Heuristik-GRU / optionales Core ML |
| DepthCapture.swift | echte Tiefe, sonst nil |
| LandmarkSmoothing.swift | One-Euro + 3,5*Median-Ausreißer |
| GestureClassifier.swift | Winkel, Softmax, robustes palmScale |
| HandTracker.swift | Track-ID, Unterarm-Prior, Fusion |
| GestureEngine.swift | Schwellen in Handbreiten, Aktionen ab p >= 0.70 |

Startgewichte: 2D 0.40, 3D-Lift 0.28, Tiefe 0.22, Zeit 0.25.
Ist echte Tiefe da, fällt das Lift-Gewicht auf 0.12.

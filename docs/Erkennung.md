# Erkennung: Bestand, Fehlerquellen, Fusionsplan

## 1. Was heute läuft

Eine einzige Methode, rein 2D:

| Stufe | Datei | Verfahren |
|---|---|---|
| Bild | `CameraSession.swift`, `FrameEnhancer.swift` | 720p BGRA, nur neuester Frame, Belichtungsanhebung unterhalb Luma 0.30 |
| Landmarken | `HandTracker.swift` | `VNDetectHumanHandPoseRequest`, max. 2 Hände, ANE/GPU, 21 Gelenke, **x/y normiert, kein z** |
| Glättung | `LandmarkSmoothing.swift` | One-Euro-Filter je Gelenk (minCutoff 6.2, beta 0.16) |
| Pose | `GestureClassifier.swift` | handgeschriebene Geometrie-Heuristik, harte Schwellen |
| Pinzette | `PinchGate` | Hysterese auf Rohabständen, Streak-Zähler |
| Stabilisierung | `HandTracker.stabilize` | Pose muss 2 Frames halten |
| Semantik | `GestureEngine.swift` | Zustandsautomat auf `pose`, `pinchClosed`, Palm-Trajektorie |

Kein Tiefenkanal, kein Core-ML-Modell, keine zeitliche Modellierung, keine Redundanz. Fällt Vision für einen Frame aus oder liegt daneben, gibt es nichts, was das auffängt — nur die Hysterese, die den alten Zustand konserviert.

## 2. Warum das schwankt

### 2.1 Systematisch (Verfahrensgrenze)

1. **Perspektivische Verkürzung.** `isExtended` misst den radialen Abstand Gelenk→Handwurzel in der Bildebene. Zeigt die Hand zur Kamera, projiziert ein gestreckter Finger kurz — er zählt als gebeugt. Ergebnis: offene Hand wird zur Faust, sobald man nach vorn deutet. Ohne z ist das nicht auflösbar.
2. **`palmScale` als Bezugsgröße.** Alle Verhältnisse (Pinzette 0.42/0.33/0.54, Reichweite 0.78/0.82) werden auf den Abstand Handwurzel→Mittelfinger-MCP normiert. Der schrumpft beim Kippen der Hand, ohne dass sich die Geste ändert — die Verhältnisse steigen, die Pinzette fällt heraus.
3. **Seitenverwechslung.** Bei `chirality == .unknown` wird nach `wrist.x < 0.5` geraten. Beide Hände links im Bild ⇒ beide „links": zweite Hand überschreibt Glättungs- und PinchGate-Zustand der ersten (`leftSmooth`, `leftPinch` sind pro Seite, nicht pro Track). Kreuzende Hände tauschen die Identität, `pointerHandID` wechselt, der Cursor springt auf die Mausposition zurück (`actorMapped`).

### 2.2 Handwerkliche Fehler

4. **Seitenverhältnis fehlt.** Vision normiert x und y unabhängig auf [0,1]. Bei 1280×720 entspricht 0.1 in x = 128 px, 0.1 in y = 72 px. Jedes `hypot(dx, dy)` im Klassifikator, in `PinchGate`, in `resolveFling` und `driveSwipe` mischt zwei verschiedene Einheiten. Diagonale Abstände sind je nach Richtung um bis zu 78 % verzerrt — deshalb löst dieselbe Pinzette waagerecht und senkrecht unterschiedlich aus.
5. **Binäre Merkmale, harte Kanten.** Jeder Finger ist gestreckt oder nicht; daraus `fingers == 0 → Faust`, `>= 3 → offen`, dazwischen `unknown`. Ein Finger, der um die Schwelle zittert, kippt die gesamte Pose. Zwei gestreckte Finger, die nicht Zeige+Mittel sind, landen in `unknown` und werden von `stabilize` als alte Pose weitergereicht.
6. **Konfidenz wird nicht gewichtet.** `p.confidence` dient nur als Schwelle (0.18/0.22) und als Anzeige. Ein Gelenk mit 0.19 zählt genauso viel wie eines mit 0.95.
7. **Frame-Zähler statt Zeit.** `stabilize` (2 Frames) und die Streaks in `PinchGate` (2 bzw. 3 Frames) hängen an der Bildrate. Bei 60 fps sind das 33 ms, bei 15 fps 200 ms — das Gerät bestimmt das Verhalten.
8. **Zwei Wahrheiten.** `classify` rechnet auf geglätteten Punkten, `PinchGate` auf Rohpunkten. Die Widersprüche werden hinterher in `HandTracker.analyze` mit drei Sonderfällen geflickt (`if pinchState.closed, pose == .fist || .unknown || .point → .pinch`).
9. **Keine Ausreißerabwehr.** Der One-Euro-Filter folgt einem grob falschen Landmark, statt ihn zu verwerfen; bei schneller Bewegung erhöht `beta` die Grenzfrequenz zusätzlich.
10. **Absolute Schwellen ohne Skalierung.** `thumbsUp` verlangt `tip.y > wrist.y + 0.08`, Wurf verlangt `speed > 0.38`, Wischen `|dx| > 0.12` — alles in Bildkoordinaten. Weiter weg von der Kamera wird dieselbe Bewegung kleiner und löst nicht mehr aus.

## 3. Zielarchitektur

Drei Schätzer, ein gemeinsames Format, eine Fusion. Kein Schätzer darf Pflicht sein.

```
Frame ─┬─► 2D-Schätzer  (Vision-Landmarken + Geometrie)  ─┐
       ├─► 3D-Schätzer  (Tiefe oder monokulares Lifting) ─┼─► Fusion ─► Filter ─► GestureEngine
       └─► KI-Schätzer  (Core ML über Landmarkenfolge)   ─┘
```

**Gemeinsames Format** (neu, `HandEstimate.swift`):

```swift
struct HandEstimate {
    var probabilities: [HandPose: Double]   // Summe 1, keine harten Entscheidungen
    var pinchClosedness: Double             // 0…1 statt Bool
    var palm: CGPoint                       // seitenverhältnis-korrigiert
    var palmVariance: CGFloat               // Messunsicherheit, nicht Konfidenz
    var quality: Double                     // 0…1 Frame-Güte dieses Schätzers
    var available: Bool
}
```

**Fusion** (`EstimateFusion.swift`):
- Klassen: gewichtetes logarithmisches Meinungspooling, `p ∝ Π pᵢ^wᵢ`. Gewicht `wᵢ = zuverlässigkeitᵢ · qualitätᵢ`, danach normiert. Fällt ein Schätzer aus, geht sein Gewicht auf 0 und die Summe renormiert sich — keine Sonderpfade.
- Skalare (Palm-Punkt, Pinzettenmaß): inverse Varianzgewichtung, `x̂ = Σ(xᵢ/σᵢ²) / Σ(1/σᵢ²)`, Restvarianz `1/Σ(1/σᵢ²)`. Das ist der Punkt der Übung: die Varianz des gewichteten Mittels liegt unter der jedes Einzelschätzers, bei drei gleich guten Quellen bei einem Drittel, die Streuung also bei 58 %.
- Zeitlich: HMM-Vorwärtsfilter über die 7 Posen mit expliziter Übergangsmatrix und **Zeitkonstanten in Sekunden**, ersetzt `stabilize` und die Streak-Zähler. Umschalten erst, wenn die a-posteriori-Wahrscheinlichkeit einer anderen Pose über 0.62 liegt und dort ≥ 80 ms bleibt.
- Selbstbewertung: gleitendes Fenster (5 s) über die Abweichung jedes Schätzers vom Fusionsergebnis; chronisch abweichende Schätzer verlieren Gewicht bis auf ein Minimum von 0.1, erholen sich aber wieder.

## 4. Arbeitsschritte

### Phase 0 — Fundament (Voraussetzung für alles Weitere)

| # | Aufgabe | Datei |
|---|---|---|
| 0.1 | `AspectSpace`: Umrechnung Vision-Normkoordinaten → isotrope Einheiten (x mit `w/h` skaliert). Alle Abstände, Geschwindigkeiten, Winkel darauf umstellen. | neu `AspectSpace.swift`, dann `GestureClassifier`, `PinchGate`, `GestureEngine` |
| 0.2 | Track-Identität statt Chiralität: Hände über Palm-Nähe zum Vorframe zuordnen (ungarische Zuordnung über 2 Kandidaten), Glättung und Gates pro Track-ID halten. Chiralität wird Attribut, nicht Schlüssel. | `HandTracker.swift` |
| 0.3 | Alle Frame-Zähler durch Sekunden ersetzen. | `HandTracker`, `PinchGate` |
| 0.4 | Ausreißerabwehr vor der Glättung: Gelenk verwerfen, wenn Sprung > 3,5 · Median-Sprung der letzten 10 Frames, und Wert extrapolieren. | `LandmarkSmoothing.swift` |
| 0.5 | `HandEstimate` + `EstimateFusion` einziehen, vorerst mit dem 2D-Schätzer als einziger Quelle. Verhalten muss identisch bleiben. | neu |

Nach Phase 0 sind die Punkte 3, 4, 7, 9 aus Abschnitt 2 erledigt, ohne dass eine neue Erkennungsart dazukommt.

### Phase 1 — 2D verbessern

| # | Aufgabe |
|---|---|
| 1.1 | Fingerstreckung über **Gelenkwinkel** statt Radialabstand: Winkel MCP→PIP→TIP, streckung = `clamp((180° − winkel)/…)` als kontinuierlicher Wert 0…1. Unempfindlich gegen Verkürzung in erster Näherung. |
| 1.2 | Posen als Punktzahlen statt Verzweigungen: je Pose ein Merkmalsvektor (Streckungen, Pinzettenmaß, Daumenrichtung, Handachse), Wahrscheinlichkeit über Softmax. `unknown` entfällt als Auffangbecken. |
| 1.3 | `palmScale` robuster: Median aus vier Strecken (Wurzel→MCPs) statt einer einzigen, plus Winkelkorrektur über die Handachse. |
| 1.4 | Gelenkkonfidenz als Gewicht in jedes Merkmal, Frame-Güte = gewichteter Mittelwert der beteiligten Konfidenzen → `quality`. |
| 1.5 | Eine Wahrheit: `classify` und Pinzettenmaß beide auf denselben (gefilterten) Punkten; die drei Flick-Sonderfälle in `analyze` fallen weg. |
| 1.6 | Zweite 2D-Quelle als Prior: `VNDetectHumanBodyPoseRequest` liefert Unterarm-Achse; Handachse, die stark davon abweicht, senkt `quality` (fängt Fehldetektionen an Gesichtern/Objekten ab). |

### Phase 2 — 3D ergänzen (heute komplett fehlend)

Zwei Wege, in dieser Reihenfolge, beide hinter derselben Schnittstelle:

| # | Aufgabe |
|---|---|
| 2.1 | **Monokulares Lifting** (funktioniert mit jeder Webcam): Handmodell mit festen Knochenlängenverhältnissen, z je Gelenk aus `z² = L² − (Δx² + Δy²)` unter schwacher Perspektive, Vorzeichen aus Kinematik-Kette und Zeitkontinuität. Kalibrierung der absoluten Handgröße in den ersten offenen-Hand-Frames. |
| 2.2 | Aus den 3D-Punkten: echte Fingerwinkel, echter Daumen-Zeige-Abstand, echte Handnormale → zweiter, von 2D unabhängiger Posen-Schätzer. Löst Punkt 1 und 2 aus Abschnitt 2. |
| 2.3 | `quality` des 3D-Schätzers aus dem Rekonstruktionsrestfehler (Abweichung der rekonstruierten Knochenlängen vom Modell). Bei starker Verkürzung sinkt sie automatisch — genau dann übernimmt die Fusion die anderen Quellen. |
| 2.4 | **Echte Tiefe, wenn vorhanden**: `AVCaptureDevice.activeFormat.supportedDepthDataFormats` prüfen (Continuity Camera, externe Tiefenkameras). Bei Verfügbarkeit `AVCaptureDepthDataOutput` zeitsynchron dazuschalten und z je Landmarke direkt lesen — ersetzt 2.1 als Quelle, gleiche Schnittstelle, `quality` aus der Tiefenkonfidenzkarte. Kein Gerätezwang: fehlt die Tiefe, bleibt es bei 2.1. |
| 2.5 | Absoluter Handabstand aus 3D → alle verbliebenen absoluten Schwellen (Wurf, Wischen, Daumen hoch) in Handbreiten statt Bildanteilen. Löst Punkt 10. |

### Phase 3 — KI ergänzen (heute komplett fehlend)

| # | Aufgabe |
|---|---|
| 3.1 | Datenaufnahme: `SessionExport` schreibt bereits `gesten.jsonl` (Pose, Seite, Gelenke x/y/Konfidenz je Frame). Um z, Zeitstempel und ein Labelfeld erweitern; Aufnahmemodus im Testmodus, der eine angesagte Geste über n Sekunden mitschneidet. |
| 3.2 | Modell: kleines zeitliches Netz über die letzten 12 Frames à 21 Gelenke × (x, y, z, Konfidenz), handwurzelzentriert und auf Handgröße normiert. GRU oder 1D-TCN, ~50 k Parameter, Ausgabe 7 Klassen. Training mit Create ML / coremltools, Ablage als `.mlpackage` im Bundle. |
| 3.3 | Laufzeit: `MLModel` mit `MLComputeUnits.all` über `MetalHub`, Inferenz nur alle 2 Frames, letztes Ergebnis wird gehalten — Latenzbudget ≤ 3 ms. |
| 3.4 | Der KI-Schätzer liefert direkt eine Verteilung über die 7 Posen; Softmax-Temperatur so kalibriert, dass die Konfidenz der tatsächlichen Trefferquote entspricht (Validierungsmenge), sonst dominiert er die Fusion zu Unrecht. |
| 3.5 | Fehlt das Modell im Bundle oder schlägt das Laden fehl: `available = false`, Gewicht 0. Die App muss ohne Modell vollständig funktionieren. |
| 3.6 | Nachtrainieren aus eigenen Aufnahmen als Menüpunkt vorbereiten (Export der gelabelten Daten reicht in Stufe 1; On-Device-Training nicht Teil dieses Plans). |

### Phase 4 — Fusion scharf schalten

| # | Aufgabe |
|---|---|
| 4.1 | Startgewichte: 2D 0.40, 3D 0.35, KI 0.25. Erst nach Messung anpassen. |
| 4.2 | Adaptive Gewichte nach Abschnitt 3 aktivieren. |
| 4.3 | HMM-Filter ersetzt `stabilize` und die `PinchGate`-Streaks; `PinchGate` bleibt als 2D-Merkmalslieferant, nicht mehr als Entscheider. |
| 4.4 | `GestureEngine` bekommt die fusionierte Pose plus deren Wahrscheinlichkeit; Aktionen mit Systemwirkung verlangen ≥ 0.70, Anzeige-Aktionen ≥ 0.50. |
| 4.5 | Diagnose im Kontrollfeld: je Schätzer Gewicht, Güte, Abweichung vom Fusionsergebnis. Ohne diese Anzeige ist eine Fehlersuche in einem Drei-Quellen-System aussichtslos. |

## 5. Prüfung

- `GestureTests.swift` um Fälle erweitern, die heute fehlschlagen: verkürzte Hand (Zeigen zur Kamera), gekippte Hand, zwei Hände auf derselben Bildseite, kreuzende Hände.
- Regressionsmenge aus aufgenommenen `gesten.jsonl`-Dateien; ein Abspielwerkzeug schiebt sie durch die Pipeline und meldet Trefferquote und **Umschaltrate pro Sekunde** — die Umschaltrate ist die eigentliche Zielgröße gegen das Flackern.
- Messwerte je Phase festhalten: Trefferquote je Pose, Umschaltrate, Standardabweichung des Palm-Punkts bei ruhender Hand, Ende-zu-Ende-Latenz.

## 6. Reihenfolge und Nutzen

Phase 0 und 1 beheben die Mehrzahl der heutigen Aussetzer ohne neue Abhängigkeiten und sind Voraussetzung für die Fusion. Phase 2 beseitigt die Verfahrensgrenze (fehlendes z), Phase 3 fängt ab, was Geometrie prinzipiell nicht trennt. Erst Phase 4 liefert die Varianzreduktion, nach der gefragt ist — und die setzt voraus, dass die drei Quellen tatsächlich unabhängige Fehler machen, weshalb 3D nicht bloß aus denselben 2D-Punkten abgeleitet werden darf, sobald echte Tiefe verfügbar ist.

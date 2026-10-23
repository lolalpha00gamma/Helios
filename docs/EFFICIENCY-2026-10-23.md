# Funktionsgleiche Vereinfachungen vom 23. Oktober 2026

Die 2D-Gestenklassifikatoren berechneten dieselbe Zahl gestreckter Finger mehrfach pro Aufruf. Swift und Python verwenden den Wert jetzt wieder; die 3D-Variante nutzt die vorhandene Zählung der anderen Finger. Die Auswahl des lexikografisch kleinsten Hot-Keys verwendet `min()` statt `sorted().first`. Die privaten, unreferenzierten AX-Helfer `frontWindow` und `pressButton` sind entfernt.

Validierung: macOS-Build erfolgreich; eigenständige Swift-GestureTests erfolgreich; Python-Klassifikator-Ausgaben für 5.000 deterministisch erzeugte Gelenkdatensätze exakt gleich zur Ausgangsfassung. Fünf abwechselnde Messungen ergaben als Median 75,69 ms vorher und 72,42 ms nachher (etwa 4,3 % weniger Laufzeit). Diese lokale Messung betrifft nur die Python-Klassifikatorfunktion und sagt nichts über Kamera-, Tracking- oder Gesamt-App-Latenz aus.

Vorhandene Änderungen anderer Arbeiten bleiben separat im Arbeitsverzeichnis. Kein UI-Eingriff. Vorschläge für ausreichend breite Menütexte: „Scharf“ → „Gestensteuerung aktivieren“, „Idle“ → „Gestensteuerung pausieren“, „Aktionskalibrierung“ → „Gesten einrichten“. Keine umfassende visuelle Abnahme aller macOS-/Windows-Zustände.

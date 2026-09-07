# Helios — Licht, Gesten, Gesichter

## Schreibtisch wechseln

Bisher: **offene Hand schnell waagerecht wischen** wechselt die *App* (`switchApp`).

Schreibtisch / Mission-Control-Space ist **nicht** dieselbe Geste.
Neue Zuordnung:

- **Zwei offene Hände, gleiche Richtung, schneller Wisch** → Space links/rechts
  (Control+Pfeil, wie Trackpad mit drei Fingern).
- Eine Hand wischen bleibt App-Wechsel.

## OK-Geste (Dateisystem)

Daumen- und Zeigefingerspitze berühren sich zum Kreis, Mittel/Ring/Klein gestreckt
(„OK“). Öffnet Finder am Home-Ordner. Weitere Kreise = Unterordner der aktuellen Ebene.
Pinzette ohne gestreckte restliche Finger bleibt Klick, nicht OK.

## Low-Light

- FrameEnhancer: mehr Belichtung unter luma 0,38, kein Stauchen unter 1280 px bei Dunkelheit.
- macOS **Edge Light** (Tahoe 26.2+, Apple Silicon) ist ein System-Videoeffekt um den Bildschirmrand.
  Helios kann den System-Effekt nicht per öffentlicher API einschalten. Bei Dunkelheit den Rand
  selbst aufhellen oder in einem Video-Call-Menü Edge Light aktivieren.
  Anleitung: https://support.apple.com/en-us/125934

## Gesichter

```
python3 tools/enroll_faces.py --who owner --shots 20
python3 tools/enroll_faces.py --who others --shots 20
```

Ordner `faces/owner` und `faces/others`. Genau **ein** Gesicht pro Foto.
Keine fremden Gesichter ohne Einwilligung laden. Für Forschung optional LFW:
http://vis-www.cs.umass.edu/lfw/

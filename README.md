# Helios **1.6.2**

Native macOS-App: Gestensteuerung über den Kamera-Livestream, holografisches HUD, Fenster- und Cursorsteuerung.

Privates Repo. Keine Open-Source-Lizenzdatei.

Ziel: **macOS 26+** (Golden Gate / 27), **Apple Silicon**, **arm64**.

## Start

**Nur die DMG-Datei laden, nicht Source code (zip):**

[Helios.dmg](https://github.com/bpms9cmnxc-debug/Helios/releases/latest/download/Helios.dmg)

1. `Helios.dmg` doppelklicken (kein Entpacken)
2. Helios nach **Programme** ziehen — nicht aus dem Image starten
3. Erster Start (nicht notarisierte Ad-hoc-Signatur): **Systemeinstellungen → Datenschutz & Sicherheit → Trotzdem öffnen**
4. Rechte: Kamera, Bedienungshilfen, Eingabeüberwachung. Nach jedem Update Schalter **aus und wieder an**.

Auf der Release-Seite stehen automatisch auch *Source code (zip)* / *tar.gz*. Das ist GitHub-Quelltext, **nicht** die App.

## Neu in 1.6.2

1.6.1 hat Fusion und Tor repariert — die Pose kam trotzdem selten über 62 %, Flicks starben im Smoother, und die falsche Hand hat `forearmGate` gefüttert.

- **HMM normiert**, Velocity-Prior gegen Fehl-Pinch, Gate = max(committed, best). Umschalten 18/38 ms.
- **Smoothing-Cap aus dem aktuellen Frame**, nicht 80 Frames Idle. Flicks bleiben Flicks.
- **Körperpose stimmt L/R ab.** Track-Zuordnung mit Palm-Velocity.
- **Trackpad-Beschleunigung**, Zwei-Pinzetten nur gegenüberliegend, Clutch ignoriert eigene CGEvents 120 ms.
- Log sagt **62 %**, nicht 70 %.

## Neu in 1.6.1

1.6.0 hat vier Quellen fusioniert, aber drei davon waren dasselbe 2D-Signal. Die Pose kam selten über 70 %, also hat das Aktions-Tor fast alles geschluckt. 1.5.8 hat Scroll/Rechtsklick/Dwell in der README behauptet — der Code war leer.

- **Fusion entkoppelt.** 2D führt. Lift und Zeit-Heuristik kollabieren, wenn sie die 2D-Verteilung nur kopieren. Aktions-Tor 62 %.
- **Kein L/R-Doppel-Flip** auf der schon gespiegelten Frontkamera.
- **Zwei-Pinzetten** belegen den Tick auch nach der 0,35 s-Bestätigung.
- **Tracks** überleben Flicks (0,42 iso). HMM schaltet schneller.
- **Scroll** (zwei offene Hände vertikal), **Rechtsklick** (Pinzette + Ring), **Dwell-Klick** (optional, 1 s still).
- Dropout 180 ms, Pinch-Timeout 0,32 s, Latenz-Sparkline, Idle-Banner nach Not-Aus.

Details: [docs/Erkennung.md](./docs/Erkennung.md), [VORSCHLAEGE.md](./VORSCHLAEGE.md).

## Neu in 1.6.0

Erkennung ist nicht mehr nur 2D. Vier Quellen laufen parallel und werden fusioniert.

- **Isotroper Raum.** Vision-x/y sind unabhängig [0,1] — Abstände laufen in x′ = x·(w/h).
- **Track-ID statt Chiralität.** Zwei Hände auf derselben Bildseite überschreiben sich nicht mehr.
- **Gelenkwinkel + Softmax** statt Radialabstand und binärer Kanten.
- **3D-Lift** über MANO-Knochenlängen plus echte Tiefe, wo das Format sie hat.
- **Zeitnetz** 12 Frames, optional `HeliosTemporal.mlmodel`.
- 1.5.7-Sicherheit bleibt: Not-Aus 0,8 s, Scharf-Ruhe 0,7 s, Peace 0,9 s, Flick-Wischen.

## Gesten

| Geste | Wirkung |
|---|---|
| Faust halten | Scharf schalten |
| Offene Hand bewegen | Cursor (Trackpad: heben = neu ansetzen) |
| Pinzette kurz | Klick |
| Pinzette + Ringfinger kurz | Rechtsklick |
| Pinzette oder Faust + ziehen | Fenster verschieben |
| In die Papierkorb-Ecke ziehen und loslassen | Fenster zu / Finder-Auswahl in den Papierkorb |
| Werfen nach oben | Wegwerfen |
| Werfen nach unten | Minimieren |
| Werfen nach links/rechts | Andocken |
| Pinzette + zu sich ziehen | Fenster füllen |
| Zwei Pinzetten | Skalieren |
| Offene Hand **schnell** waagerecht wischen | App wechseln |
| Zwei offene Hände vertikal | Scroll |
| Offene Hand 1 s still (optional) | Dwell-Klick |
| Peace halten (~0,9 s) | Fensteraufnahme auf den Schreibtisch |
| Daumen hoch | App hervorholen |
| Beide Handflächen (~0,8 s) | Not-Aus → Idle (erst Faust macht wieder scharf) |

**Testmodus** (⌘T): Erkennung anzeigen, keine Systemaktionen.

Aktive App bekommt einen Umriss. HUD liegt auf jedem Monitor. Keine Stimme.

## Bau

Xcode 26/27, macOS 26 SDK:

```
xcodebuild -project macos/Helios.xcodeproj -scheme Helios -configuration Release ARCHS=arm64
swift macos/HeliosTests/CoordTests.swift
```

GitHub Actions legt bei jedem Push auf `main` eine `Helios.dmg` als Release ab.

Ad-hoc-Signatur. Developer ID + Notarisierung braucht ein Apple-Zertifikat — ohne das muss der Nutzer nach jedem Update die TCC-Schalter neu setzen.

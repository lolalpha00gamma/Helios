# Helios **1.6.6**

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

## Neu in 1.6.6

1.6.5 hat Peace vs. Point und Greifen über `perform()`. Replay blieb ein JSONL-Export, der Katalog eine Tabelle im Switch.

- **Session-Replay im HUD.** Landmark-JSONL Frame für Frame, Play/Pause/Slider, ohne Xcode.
- **Profil-Katalog JSON** (`helios.profiles.json`), Extra/Blocked-Overrides bleiben.

## Neu in 1.6.5

1.6.4 hat 9-Punkt-Maps und den Profil-Editor — Safari hat trotzdem gegriffen, Peace hat Screenshots beim Zeigen ausgelöst, und der Clutch hat eigene Events nur über 120 ms erkannt.

- **Greifen läuft über `perform()`.** Safari/Chrome-Profil blockt AX-Drag wirklich; vorher rief `driveGrab` `beginWindowDrag` direkt.
- **Peace vs. Point.** Zwei Finger plus Daumen-an-MCP ist kein Victory — Spreizung und Daumen zählen.
- **Palm-Deadzone an palmWidth.** Nah an der Kamera zittert der Zeiger in den äußeren 15 % nicht mehr.
- **Kalibrier-RMSE.** Nach 9 Punkten: Fehler in Pixeln. > 12 px → „Mitte nochmal“.
- **Display-Reconfig** lädt die Karte neu (`didChangeScreenParameters`).
- **Per-App Scroll-Richtung.** Browser default invertiert (Natural), Finder nicht — Toggle im Profil-Editor.
- **HID-Stempel** auf eigenen CGEvents (`eventSourceUserData`), Clutch nicht nur Zeitfenster.

## Neu in 1.6.4

1.6.3 hat die falsche Hand und Kill-vs-Scroll repariert — ein Homography für alle Schirme, starre App-Profile und ein Lock ohne Hysterese haben sich trotzdem falsch angefühlt.

- **9-Punkt-Kalibrier-Gitter** (DLT least squares), 4 Ecken bleiben gültig.
- **SpaceMap pro Display-ID** (`helios.spaceMap.{id}`), Fallback auf die alte Ein-Schlüssel-Karte.
- **Profil-Editor.** Safari-Werfen darf wieder an; Defaults bleiben konservativ. Overrides in UserDefaults.
- **Dominant-Lock-Hysterese 200 ms**, bevor die zweite Hand den Cursor kriegt.
- **Scroll-Gain an palmWidth** — große/nahe Hände scrollen feiner (unit 0,12 bleibt ~18 Ticks).
- **Tasten-Clutch 400 ms** nach echtem keyDown — kein Pinch im gerade getippten Feld.
- **Kill-Abbrechen.** Faust + eine offene Hand bricht den 0,8-s-Hold ab, ohne Idle zu erzwingen.

## Neu in 1.6.3

1.6.2 hat Fusion und HMM repariert — die App hat trotzdem mit der falschen Hand gesteuert, Kill hat Scroll geschluckt, und ein Flick in Safari hat das Fenster geschlossen.

- **Rechtshänder ist Default.** `leftHanded` war `true` ohne UserDefaults-Key.
- **Kill vs. Scroll.** Zwei offene Hände, die sich vertikal bewegen, sind Scroll. Still halten 0,8 s bleibt Not-Aus. Die ersten 0,35 s belegen den Tick nicht.
- **Dominant-Hand-Lock** nach 1,2 s (Timer läuft durch, nicht pro Frame zurück). Zweite Hand pincht den Zeiger nicht weg.
- **Vision-Orientierung** aus `videoRotationAngle`, nicht hart `.up`.
- **SpaceMap hybrid:** außen 15 % Homographie, innen Trackpad-Relativ.
- **Per-App-Profile.** Safari/Chrome: kein Werfen/Greifen (Flick schließt sonst das Fenster). Wischen = App-Wechsel bleibt. Finder: Werfen an.
- **Zwei-Pinzetten** ziehen AX-Kanten, nicht isotrop um die Palme.
- Adaptive Kamera-FPS (Idle 8, Hand 24–30), Fusion-Temperatur im Inspector.

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

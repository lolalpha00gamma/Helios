# Helios **1.5.7**

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

## Neu in 1.5.7

Fenster trafen oft das falsche Ziel: AX-Hit-Test und Snap liefen in Quartz-Y statt Cocoa. Offene Hand zum Cursor hat nebenbei App-Wechsel ausgelöst. Faust-Scharf wurde zum Klick. Peace hat den Cursor 4 s eingefroren. Details: [VORSCHLAEGE.md](./VORSCHLAEGE.md).

- **AX in Cocoa.** `AXUIElementCopyElementAtPosition` und `AXPosition` bekommen Cocoa-Koordinaten.
- **Snap auf `visibleFrame`.** Andocken/Füllen nutzt den Cocoa-sichtbaren Bereich, nicht das geflippte Quartz-Rect.
- **Wischen = Flick.** Nur schnell, waagerecht, `dx > 0.20`, `speed > 0.85`. Langsames Cursor-Führen wechselt keine App.
- **Scharf-Ruhe 0,7 s.** Die Arming-Faust startet kein Halten/Klick.
- **Cooldown bewegt den Cursor weiter.** Nur Aktionen pausieren.
- **Not-Aus 0,8 s, openScore ≥ 4.** Kein Kill durch zwei lockere Hände.
- **Zwei Pinzetten belegen den Tick** schon in der 0,35 s-Bestätigung.
- **Maus-Clutch** hört auch `mouseMoved`.
- **Peace 0,9 s.** Weniger Fehl-Screenshots.
- **Chirality eindeutig.** Zwei Hände teilen sich keinen Smoother mehr.

## Gesten

| Geste | Wirkung |
|---|---|
| Faust halten | Scharf schalten |
| Offene Hand bewegen | Cursor (Trackpad: heben = neu ansetzen) |
| Pinzette kurz | Klick |
| Pinzette oder Faust + ziehen | Fenster verschieben |
| In die Papierkorb-Ecke ziehen und loslassen | Fenster zu / Finder-Auswahl in den Papierkorb |
| Werfen nach oben | Wegwerfen |
| Werfen nach unten | Minimieren |
| Werfen nach links/rechts | Andocken |
| Pinzette + zu sich ziehen | Fenster füllen |
| Zwei Pinzetten | Skalieren |
| Offene Hand **schnell** waagerecht wischen | App wechseln |
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

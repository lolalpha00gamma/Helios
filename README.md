# Helios

Native macOS-App: Gestensteuerung über den Kamera-Livestream, holografisches HUD, Fenster- und Cursorsteuerung.

Privates Repo. Keine Open-Source-Lizenzdatei.

Ziel: **macOS 27 Golden Gate**, **Apple Silicon M4 Pro**, **arm64**.

## Start

1. [Releases](https://github.com/lolalpha00gamma/Helios/releases) → `Helios.dmg`
2. Image öffnen, Helios nach **Programme** ziehen
3. Erster Start: Rechtsklick auf Helios → **Öffnen**
4. Rechte erlauben:
   - Kamera
   - Bedienungshilfen
   - Eingabeüberwachung

## Gesten

| Geste | Wirkung |
|---|---|
| Faust 0,8 s halten | Scharf / Idle |
| Zeigefinger | Cursor über alle Monitore |
| Pinzette (kurz) | Klick |
| Pinzette + ziehen | Fenster verschieben |
| In Papierkorb werfen | Fenster zu / Finder-Auswahl in den Papierkorb |
| Werfen nach links/rechts | Fenster andocken |
| Werfen nach unten | Minimieren |
| Pinzette + zu sich ziehen | Fenster füllen |
| Zwei Pinzetten | Skalieren |
| Wischen (zeigen) | App wechseln |
| Zeigen oben / unten halten | Zoom / Minimieren |
| Peace halten | Fensteraufnahme auf den Schreibtisch |
| Daumen hoch | App hervorholen |
| Eine offene Hand halten | Mission Control |
| Beide Handflächen | Not-Aus → Idle |

**Testmodus** (Standard, ⌘T): Hände, Finger und Gelenke werden live beschriftet. Es gibt **keine** Systemaktionen. Zum Steuern Testmodus aus.

Aktive App bekommt einen holografischen Umriss. HUD liegt auf jedem Monitor.

Keine Stimme.

## Bau

Xcode 27, macOS 27 SDK:

```
xcodebuild -project macos/Helios.xcodeproj -scheme Helios -configuration Release ARCHS=arm64
```

GitHub Actions (`macos-26` + Xcode 27) legt bei jedem Push auf `main` eine signierte `Helios.dmg` als Release ab.

Ad-hoc-Signatur ist Standard. Gatekeeper-sauber (Developer ID + Notar) erst mit Apple-Zertifikat in den Secrets.

# Helios **1.6.15**

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

## Neu in 1.6.15

1.6.14 hat Cmd/Opt-Klick und Peace-Deadzone — Traffic-Lights haben trotzdem HID 4 px daneben geklickt, die zweite Hand war unsichtbar bis der Pinch aufging, Peace während Scroll wirkte tot, und `Cmd-Klick` umging das Profil. Doppelklatschen aus `main` 1.6.6 fehlte auf `bugfix`.

- **AXPress auf Magnet.** Schließen/Mini/Zoom/Knopf/Checkbox: `AXUIElementPerformAction`, HID nur Fallback. Modifier-Klicks bleiben HID.
- **HUD-Chord.** Zweite Faust/Peace/Point → SHIFT/CMD/OPT-Chip bevor der Pinch aufgeht.
- **Peace-HUD dunkel.** Während Scroll-Pause `PEACE · SCROLL`, nicht stiller Ring.
- **Cmd/Opt im Profil.** `GestureAction.from` kennt die Namen, Safari-Block greift.
- **2× klatschen → Scharf.** Sichtbarer Palmenschlag, kein Mikrofon. Not-Aus verwechselt das nicht mit Kill.
- **Focus-Poll 120 ms.** invertHorizontal folgt dem Fenster unter dem Cursor, nicht 400 ms später.

## Neu in 1.6.14

1.6.13 hat Magnet-HID und Shift-Klick — Peace stillhalten hat trotzdem gescrollt (Jitter × Gain ≈ Ticks), der Screenshot traf das Vordergrund-Fenster, Pinch auf Schließen wurde zum Titelleisten-Drag, und der HUD sagte nur „Magnet“.

- **Peace-Scroll-Deadzone 0,12 Handbreiten.** Stillhalten ist Aufnahme, kein `lastScrollAt`. Zwei offene Palmen bleiben frei.
- **Screenshot unter dem Cursor.** `TargetProbe.windowAt`, nicht `focused`. Ohne Fenster: 16:9-Region um den Zeiger.
- **Click-Lock auf Magnet-Rollen.** Schließen/Mini/Zoom/Checkbox/Radio/Tab/Knopf kleben bis 0,30 Handbreiten.
- **Cmd/Opt-Klick.** Peace der zweiten Hand = Cmd, Point = Opt. Faust bleibt Shift.
- **Magnet-Chip.** „SCHLIESSEN“ / „SLIDER“ / „KNOPF“, nicht nur Magnet.
- **Per-App invertHorizontal.** Terminal XOR't wheel2, Safari nicht. Toggle im Profil-Editor.

## Neu in 1.6.13

1.6.12 hat Slider und Peace-Cooldown — der Magnet hat trotzdem 4 px neben dem Schließen-Knopf geklickt, der Fail-Chip hat durch 4 geteilt, Rechtsklick wurde zum Ghost-Linksklick, und Safari-History ging rückwärts.

- **Magnet trifft HID.** `applyMagnet` setzt `lastPosted` und bewegt den Cursor; Klick landet auf Schließen/Slider, nicht 4 px daneben.
- **Peace-Cooldown ehrlich.** HUD zeigt Restsekunden, nicht remain×4. Fail 0,8 s startet voll, nicht bei 20 %.
- **Rechtsklick schluckt Pinch.** Nach 140 ms Ringfinger kein Folge-Linksklick beim Öffnen.
- **wheel2 ohne Profil-XOR.** Safari-Invert dreht nur vertikal; History/Seitenscroll bleibt Natural.
- **Shift-Klick.** Faust der zweiten Hand während Pinch = Shift+Klick (Finder/Xcode).
- **I-Beam über Text.** AXTextArea/WebArea zeigt Text-Cursor, nicht den Pfeil.
- **Peace-Region.** Ohne Fenster: `screencapture -R` 720×450 um den Cursor, nicht der ganze Schirm.
- **Text-Dwell 80 ms.** HID-Down erst nach 80 ms Pinch, sonst Ghost-Doppelklick in Inputs.

## Neu in 1.6.12

1.6.11 hat Peace vs Scroll und Textauswahl — Slider zitterten trotzdem aus dem Magnet, ein fehlgeschlagener Screenshot sperrte 4 s, Zwei-Finger ging nur vertikal, und Text-Drag lief in die Toolbar.

- **Click-Lock Slider.** Pinch auf AXSlider/Incrementor klebt bis 0,30 Handbreiten, kein Zitter-Drag.
- **Peace-Cooldown 0,8 s** nach fehlgeschlagenem Screenshot, 4 s nur nach Treffer.
- **Zwei-Finger waagerecht.** Klar horizontale Peace-Bewegung = `wheel2` (Browser-History/Shift-Scroll).
- **Text-Drag bricht an Chrome ab.** AXButton/Toolbar/Tab beendet die Auswahl, nicht den Textkörper daneben.
- **Natural-Scroll.** `com.apple.swipescrolldirection` XOR Profil-Invert — Natural-aus dreht Safari nicht doppelt.
- **Tasten-Clutch.** `flagsChanged` + Repeat 550 ms; Shift/Cmd/Opt/Ctrl halten Injektion, CapsLock nicht.

## Neu in 1.6.11

1.6.10 hat den Cursor nach der Maus nicht mehr gewarpt — Peace hat trotzdem nach 0,9 s Scroll ein Screenshot gemacht, der HUD-Chip hat „Nachlauf“ als Tastatur gelabelt, Scroll starb hart am Lift, und Pinch über Text hat nur „Titelleiste halten“ gesagt.

- **Peace vs. Scroll.** Während der letzten 400 ms Scroll zählt Peace nicht. Danach 1,2 s Hold, sonst 0,9 s. Zwei-Finger-Scroll macht keine Aufnahme mehr.
- **Nachlauf-Chip.** HUD sagt `NACHLAUF 150 ms`, nicht `TASTATUR ×400`.
- **Scroll-Inertia 180 ms.** Zwei-Finger-Lift rollt aus, analog Trackpad.
- **Warp-Guard 80 px.** Erstes Post-Clutch-Frame mit Sprung verwerfen, falls Resync versagt.
- **Pinch-auf-Text = Auswahl.** HID-Drag über dem Textkörper, nicht Fenstergriff. Safari-Profil blockt weiter AX-Drag.
- **Magnet + Cache.** AXTab / AXMenuItem / AXIncrementor, Hit-Test 30 ms.
- **HUD folgt der Konsole.** `pinHUDToConsole` im Focus-Poll, nicht nur beim Kalibrier-Start.
- **Screenshot-Fallback** auf den Schirm unter dem Cursor, nicht `NSScreen.main`.

## Neu in 1.6.10

1.6.9 hat Pinch während Clutch geschluckt — nach der Pause hat `placeCursor` den Zeiger trotzdem um die Palm-Deltas der Pause gewarpt, Zwei-Hand-Scroll brauchte zwei offene Palmen, und das HUD-Chrome klebte an `NSScreen.main`.

- **Clutch-Exit-Grace 150 ms.** Nach Maus/Tastatur bleibt Injektion tot; HUD sagt „Nachlauf“.
- **Pointer-Resync.** Während Clutch kein Palm-Integral — der Hardware-Cursor bleibt, kein Warp danach.
- **Ein-Hand-Zwei-Finger-Scroll.** Peace (Zeigefinger+Mittel), zweite Hand palm-unten oder fehlt.
- **HUD auf dem Konsolen-Schirm.** Kalibrierung nimmt den Schirm des Helios-Fensters, nicht den Menüleisten-Hauptbildschirm.
- **4 px AX-Magnet.** Stillgehaltener Pinch rastet auf Schließen/Mini/Zoom/Slider.

## Neu in 1.6.9

1.6.8 hat den Cursor auf der dominanten Hand gelassen — Pinch während der Maus-Pause wurde danach trotzdem zum Klick, Pinch über Text hat das Fenster gestohlen, und Palm-unten hat mitgescrollt.

- **Clutch schluckt den Pinch.** Finger zu während „Maus hat Vorrang“ → nach der Pause kein Klick/Drag, bis die Hand wieder offen ist.
- **Hover-Intent 200 ms auf der Titelleiste.** Pinch + 0,18 Handbreiten über Text startet kein AX-Drag. Nur die oberen 36 pt (Traffic Lights).
- **Ghost-Cursor.** Während Clutch gestrichelter Ring „GEIST“ — zeigt, wohin Helios würde, ohne wie ein live Cursor auszusehen.
- **Kalibrier-Log sagt 9 Punkte**, nicht „4 Ecken“. Wizard: HUD zuerst auf den gemeinten Schirm ziehen.
- **Palm-unten zählt nicht zum Zwei-Hand-Scroll.** Handrücken-Rest 0,6 s blockt nicht mehr den Scroll der anderen Hand.

## Neu in 1.6.8

1.6.7 hat das Fenster folgen lassen — die zweite Hand hat trotzdem den Cursor geklaut, 3D-Fusion hat Peace beim Zeigen zurückgebracht, und luma < 0,20 hat Scroll in dunklen Zimmern getötet.

- **Cursor bleibt auf der dominanten Hand.** `placeCursor(primary)` immer. Die zweite Hand greift/peace’t ohne den Zeiger zu stehlen.
- **3D-Peace wie 2D.** Spreizung und Daumen-an-MCP in `features3D` — Victory ist kein Zwei-Finger-Point mehr.
- **Low-Light weich.** luma < 0,20 blockt Klick/Greifen/Peace, Scroll und Wischen bleiben. 0,20–0,28 dämpft nur Klick.
- **Peace-Cooldown-Chip** 4 s im HUD, sonst wirkt die App tot.
- **Kalibrier-Undo.** Letzten Punkt zurück, nicht nur Skip.
- **Clutch-Restzeit-Ring** am Cursor (Maus 850 ms / Tastatur 400 ms).
- **AX unter der Hand.** Greifen fällt nicht mehr auf frontmost, wenn ein CGWindow unter dem Cursor liegt.
- **80 ms Pinch-Jitter-Floor** nach Drag-Start: unter 4 px kein `updateWindowDrag`.

## Neu in 1.6.7

1.6.6 hat Replay und den Profil-Katalog — das Fenster blieb trotzdem stehen, sobald der Griff saß.

- **`driveGrab` folgt wirklich.** Die fehlende Klammer hat `updateWindowDrag` nur im Begin-Frame ausgeführt. Jetzt jeder Frame, solange `isDragging`.
- **Profil bricht Drag ab.** Safari-Fokus mitten im Zug beendet AX, statt das Fenster in den Browser zu ziehen.
- **Lock-Reset.** `dominantLostAt` überlebte Idle nicht mehr.
- **RMSE live** im HUD ab 4 Punkten. Punkt hinter dem Deckel **überspringen** — Homographie aus den restlichen Paaren.
- **Peace-Ring** 0,9 s am Cursor. **Clutch-LED** Maus/Tastatur. **Monitor-Kompass** grün/rot.
- **Handrücken 0,6 s** → Idle ohne Not-Aus. **luma < 0,20** keine Systemaktion.

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
| Zwei Finger (Peace) stillhalten (~0,9 s) | Fensteraufnahme unter dem Cursor. Jitter < 0,12 Handbreiten scrollt nicht |
| Zwei Finger (Peace) bewegen (Deadzone 0,12) | Scroll. Klar waagerecht = `wheel2` |
| Offene Hand 1 s still (optional) | Dwell-Klick |
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

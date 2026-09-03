# Helios **1.6.25**

Native macOS-App: Gestensteuerung über den Kamera-Livestream, holografisches HUD, Fenster- und Cursorsteuerung.

Privates Repo. Keine Open-Source-Lizenzdatei.

Ziel: **macOS 26+** (Golden Gate / 27), **Apple Silicon**, **arm64**.

## Start

**Nur die DMG-Datei laden, nicht Source code (zip):**

[Helios.dmg](https://github.com/lolalpha00gamma/Helios/releases/latest/download/Helios.dmg)

1. `Helios.dmg` doppelklicken (kein Entpacken)
2. Helios nach **Programme** ziehen — nicht aus dem Image starten
3. Erster Start (nicht notarisierte Ad-hoc-Signatur): **Systemeinstellungen → Datenschutz & Sicherheit → Trotzdem öffnen**
4. Rechte: Kamera, Bedienungshilfen, Eingabeüberwachung. Nach jedem Update Schalter **aus und wieder an**.

Auf der Release-Seite stehen automatisch auch *Source code (zip)* / *tar.gz*. Das ist GitHub-Quelltext, **nicht** die App.

## Neu in 1.6.25

1.6.24 hat Scroll vs Kill und Freeze-Chip — Continuity tötete den Zeiger trotzdem, sobald keine Pinzette da war. Die Maus-Pause sah eigene Cursor-Events. Kamerawechsel behielt die alte Homographie.

- **Zeiger hält** zwei Fehlframes, auch ohne Pinzette.
- **Clutch nur echte Hardware.** Kein Local-Monitor, Mini-Zucken unter 1,2 px zählt nicht.
- **Kamera-Zeitstempel** steuert Filter und Gesten. uniqueID-Wechsel setzt Zeiger und Homographie neu.
- **Zwei-Pinzetten** an gegenüberliegenden Fensterhälften. Werfen aus den letzten 2–3 Samples.

## Neu in 1.6.24

1.6.23 hat Profile tot und Lock freeze — Scroll brauchte **zwei offene Hände** und war derselbe Kandidat wie Not-Aus. Ein Palm-Zucken hat gescrollt, während Kill 1,35 s zählte. `pinchActor` stempelte den Fehlframe auf die Wanduhr (testMode / Continuity lügen). Gate-Auf feuerte Folge-Klick.

- **Scroll nur Steuerhand.** Genau eine offene Hand. Zwei offene = Not-Aus, Scroll-Anker weg.
- **Pinch-Miss auf Tick-Takt** (`lastTickNow`), nicht `CACurrentMediaTime`.
- **Release 120 ms tot** nach Gate-Auf — Öffnen ist kein zweiter Klick.
- **HUD `T1 freeze`** wenn Lock-ID einen Fehlframe hält.

## Neu in 1.6.23

1.6.22 hat Faust/Ampel — CoordTests widersprechen sich (Xcode voll **und** aus), Continuity tötet den Zug nach 180 ms, Steuerhand teleportiert, Zwei-Pinzetten springen.

- **Profile wieder tot** (wie 1.6.17). Xcode/Safari/Finder voll. 1.6.22 hat die App in Xcode stumm geschaltet und die Tests zerlegt.
- **Steuerhand friert** einen Fehlframe (`preferredHoldID`), statt auf L/R zu springen.
- **Zwei-Pinzetten** sortiert nach Track-ID.
- **Continuity-Hold** `emptyHandsHold(dt)` ≥ 0,22 s (zwei 8-fps-Fehlframes).

## Neu in 1.6.22

Warum Klick und Zug weiter zufällig kamen: das Pinch-Gate schloss bei jeder nahen Daumen/Zeigefinger-Spitze — **Faust war Pinzette**. HMM-Closedness hielt den Wert hoch. Heranziehen feuerte im Klick-Fenster. Ampel-Verweilen zählte während du über Schließen zielst.

- **Faust ≠ Pinzette.** Gate und Greifen brauchen Reach (Spitzen weg vom Handgelenk) oder gestreckten Zeigefinger. Faust-Spitzen an der Palme starten keinen Klick/Zug. Gate **öffnet**, sobald es keine Pinzette mehr ist — Faust hält keinen Klick.
- **Closedness nur vom Gate**, nicht `max(HMM, Gate)`. HMM-Hold täuscht keine Pinzette mehr vor.
- **Halten ohne Drag braucht Reach.** Faust nach dem Klick startet keinen Zug; erst ein echter Drag darf Faust tragen.
- **Heranziehen nur nach echtem Drag** (≥ 0,35 s). Atmen maximiert das Fenster nicht.
- **Ampel nur still.** 18 px Bewegung setzt das 0,55-s-Verweilen zurück — Schließen beim Zielen ist tot.
- **App-Profile wieder an.** Xcode aus, Safari Klick/Scroll, Finder Werfen.
- **Aktions-Tor 0,52–0,68.** Flaches Softmax feuert nicht mehr bei 48 %.
- Cover bestätigt Pinch nur im Band 0,40–0,62, erfindet ihn nicht.
- **Zeigefinger-Score** ist der Classifier-Wert, nicht nur „über 0,52“.

## Neu in 1.6.21


Erkennung: weniger Fehlklicks.

- **Pinzette** kommt vom Gate, nicht von Faust-Pose oder HMM-Hold.
- **Cooldown** lässt ein laufendes Ziehen weiterlaufen.
- **Not-Aus** bricht bei leichter Bewegung ab — Zwei-Hand-Scroll tötet nicht.
- **Tastatur** tippt nur, wenn der Zeiger stillsteht.

## Neu in 1.6.20

Schneller tippen, L/R am Spiegel, Aktionskalibrierung für Grok.

- **Tippen:** Taste 0,12 s halten reicht. Keine Pinzette.
- **Links/Rechts:** Frontkamera-Spiegel dreht Vision um — deine rechte Hand ist wieder rechts.
- **Aktionskalibrierung:** 12 Gesten × 3, Countdown + 2 s Aufnahme. Testmodus, kein Fensterzugriff. „Für Grok kopieren“ legt Markdown in die Zwischenablage.

## Neu in 1.6.19

1.6.18 hat Ampel und Luft-Tastatur — Continuity blieb tot, die Steuerhand sprang, die Tastatur feuerte beim Zielen.

- **dt-Cap 200 ms.** Filter, Pinch-Vel und Kalibrier-Hold kappen 125-ms-Frames nicht mehr auf 80 ms.
- **Steuerhand bleibt Lock-ID.** L/R-Flip teleportiert den Cursor nicht. Pinzette friert, fällt nie auf die andere Hand.
- **Ampel-Verweilen startet neu**, wenn du weggehst oder nach dem Auslösen wieder kommst.
- **Heranziehen = Palm-Y** (Hand zu sich), nicht Mittelfinger-Spannweite.
- **Fling-Fenster × Frame-dt.** 8 fps hat sonst nur ein Sample im 120-ms-Fenster.
- **Luft-Tastatur:** Zeigen 0,85 s **unten** öffnet. Tippen per Verweilen.

## Neu in 1.6.18

Schließen/Vollbild per Verweilen, große getrennte Ampel-Knöpfe, Luft-Tastatur, Schrägzug, Wischen.

- **Ampel.** Schließen, Minimieren, Vollbild liegen 118 px auseinander, 80 px groß. 0,55 s Verweilen löst aus — kein Pinzetten-Zielen auf 12-px-Punkte.
- **Luft-Tastatur.** Zeigen 0,4 s öffnet QWERTZ. Pinzette tippt, Faust schließt. Menü ☀ oder Umschalt-⌘K.
- **Schrägzug.** Totzone gilt der Strecke, nicht je Achse. Seitwärts und gleichzeitig hoch/runter geht. Diagonales Loslassen dockt nicht mehr falsch.
- **Wischen.** Offene Hand, weichere Schwelle, kürzere Mute nach Pinzette.

## Neu in 1.6.17

Erkennung war rucklig und hinterher: doppeltes Glätten, Body-Pose in jedem Frame, HMM-Reset bei einem Fehlframe, Safari/Xcode-Profile haben Aktionen geschluckt.

- **Zeiger folgt der Hand.** Kalibriert ohne Hochpass-Kleber. Ein leichtes Follow, kein 0,55-Nachziehen.
- **Zwei Ringe.** Links gelb, rechts cyan. Die Systemmaus folgt der aktiven Hand.
- **Weniger Latenz.** Body-Pose nur jedes 4. Frame. Luma nicht jeden Tick. Fehlframe friert 90 ms, statt Pose zu löschen.
- **Gelbe gestrichelte Linie** war der Kasten um die linke Hand im Kamerabild — weg. Beim Greifen ist die Linie zum Fenster jetzt durchgezogen.
- Aktions-Tor wieder um 0,48–0,60. App-Profile greifen nicht mehr.

## Neu in 1.6.16

Osmo/Cover hat allein Aktionen ausgelöst (schräger Blickwinkel, falsche Pinzette) — Kalibrierung rutschte weg, ohne dass du etwas getan hast.

- **Mac führt.** Cover ist nur Ergänzung für Finger- und Handlage. Keine eigenen Klicks, Züge, Würfe.
- Ohne Hand in der Mac-Kamera passiert nichts, auch wenn Osmo etwas sieht.
- Cover darf Pinch nur **bestätigen**, nicht erfinden. Lage wird gemischt, wenn beide Homographien einig sind; sonst Mac.
- Cover-Kalibrierung: Pinzette zählt nur, wenn die Mac-Kamera sie auch sieht.

## Neu in 1.6.15

Kein Zurückspringen. 1.6.13 hat beim Klick auf die Konsole den Fokus an die App darunter zurückgegeben. Helios aktiviert keine andere App mehr. Die Konsole bleibt, wenn du sie anwählst; SwiftUI holt sie nicht über andere Fenster und schubst dich nicht weg.

## Neu in 1.6.14

Klick und Gesten wirkten weiter zufällig: die Pinzette sprang auf die **andere Hand**, sobald Vision einen Frame verlor (Kommentar: „nicht springen“ — Code sprang). Flaches Softmax blieb über 62 %, Continuity 8 fps war tot, HMM-Hold drückte die Pose-Prob unter das Tor.

- **Pinzette bleibt an der Lock-Hand.** Fehlender Frame friert, klickt nicht mit der Steuerhand.
- **Aktions-Tor folgt der Fusion-Entropie** (spitz 55 %, flach 72 %). HUD zeigt H und Tor.
- **Hochpass an Frame-dt.** 8 fps nicht mehr wie 24 fps. Ecken 2 % Ruhezone.
- **Hände auf dem Tisch** 1,2 s → Idle.
- **Per-App-Profil:** Xcode aus, Safari nur Klick/Scroll, Finder Werfen.
- HMM-Hold behält die letzte echte Pose-Prob.

## Neu in 1.6.13

Nach vorn nur, wenn du die Konsole **selbst** anwählst (Fenster klicken, Menüleiste ☀ → Konsole, Dock). Gesten-Klicks, Klicks in anderen Apps und Kamera-Ticks holen sie nicht.

## Neu in 1.6.12

Die Konsole ist wieder da — und bleibt stehen. Sie springt nicht mehr bei jedem Kamera-Frame über die App, die du steuerst.

- **UI bleibt.** Standard: Konsole sichtbar, auch bei Scharf. Der Schalter „Konsole bei Scharf ausblenden“ ist aus.
- **Kein Vordergrund-Diebstahl.** SwiftUI hat das Fenster bei jedem Tick key gemacht. Jetzt: nur nach vorn, wenn du Konsole, Dock oder das Fenster selbst klickst. Sonst gibt Helios den Fokus sofort zurück, das Fenster bleibt wo es war (`stationary`, `hidesOnDeactivate = false`).
- Beenden und Osmo-Livestream aus 1.6.11 unverändert.

## Neu in 1.6.11

Die Konsole wirkte abgestürzt und Helios ließ sich nicht beenden: nach **Scharf** wurde die App zum Accessory ohne Dock — das SwiftUI-Fenster war weg, Cmd+Q traf die App darunter. Osmo lief intern, ohne Livestream in der Konsole.

- **Beenden geht wieder.** Dock bleibt. Menüleiste ☀ → **Helios beenden**, oder Helios im Dock → Cmd+Q. Das rote Fenster-X schließt nur die Konsole, nicht die App.
- **Konsole zurück:** Menüleiste ☀ → Konsole, oder Helios im Dock klicken. Sie bleibt offen, bis du sie schließt — Scharf holt sie nicht mehr sofort weg.
- **Osmo als Livestream.** Bei Mac+Osmo / iPhone+Osmo zwei Bilder: Lead oben, Cover/Osmo darunter, plus zweiter Chip im HUD. Cover-Kamera ist wählbar, nicht nur Auto-Paar. Osmo/DJI am Namen erkannt. 1080p-Webcam erlaubt.

## Neu in 1.6.10

Die Installations-DMG fehlte unter Releases: die Tests vor dem Paket sind seit 1.6.0 rot gelaufen, deshalb wurde nie `Helios.dmg` hochgeladen. Latest blieb **v1.5.7**.

- **Fling-Totzone:** Mini-Ruck tot in der *kalibrierten* Schirmmitte. Echter Wurf am Rand bleibt Werfen — der Test hat einen vollen Wurf in der Mitte erwartet und CI blockiert.
- **Faust ≠ Pinzette.** Eingeringelte Finger mit Daumen neben dem Zeigefinger waren Pinzette (Klick). Pinzette braucht einen gestreckten Zeigefinger.
- **HMM hält die letzte echte Pose.** `unknown` ersetzt keine offene Hand/Faust mehr; der Track stirbt nach 0,18 s ohne Beobachtung.
- **Build auf dem Mac:** Tiefenkanal ist iOS-only — Fusion läuft ohne z, 2D/3D-Lift bleiben.

## Neu in 1.6.9

Multi-Kamera war nur ein Picker für **eine** Quelle. Jetzt echte Paare, jede Quelle mit eigener Homographie.

- **Mac + iPhone**, **Mac + Osmo**, **iPhone + Osmo (ohne Mac)**. Lead macht Gesten, Cover ist der zweite Blickwinkel.
- **Kalibrierung pro Kamera:** 4 Bildschirmecken in DIESER Sicht. Homographie schluckt Winkel, Weitwinkel, Spiegelung. Danach automatisch die zweite Quelle.
- **Winkel-Unco:** weichen die gemappten Zeiger > 140 px ab, gewinnt Lead — kein Mittelwert aus zwei falschen Winkeln.
- Cover nur wenn Lead die Hand verliert (Hysterese). Continuity ist oft exklusiv zur Mac-Kamera — Osmo per USB ist die robuste zweite Quelle.

## Neu in 1.6.8

Die zweite Hand im Bild hat 1.6.7 praktisch ausgeschaltet: Not-Aus zählte 0,8 s und **blockte jede andere Geste schon während des Haltens**. Ein unsicherer Körper-Vote hat L/R getauscht, der Cursor sprang. `.unknown` im Softmax hat klare Posen unter 62 % gedrückt.

- **Not-Aus 1,35 s**, nur zwei echte offene Hände, weit auseinander, still. Klick/Wischen/Skalieren laufen während des Zählens. Pinzette ist kein Kill.
- **Vision L/R bleibt**, außer der Körper ist sich sehr sicher (Abstand-Verhältnis < 0,50) oder Vision sagt unbekannt.
- **Kein Cursor-Sprung** wenn die Track-ID wechselt — Palme neu verankern, Zeiger bleibt.
- **unknown-Logit −1,8**, HMM hält die letzte echte Pose.
- **palmWidth geglättet** pro Hand, Fling/Wischen bei Zoom der Webcam ruhiger.

## Neu in 1.6.7

Die rechte Hand war die Steuerhand — im Code stand trotzdem `leftHanded = true`. Vision hat L/R oft getauscht, die Kalibrierung hat in der Bildschirmmitte gezittert, und bei wenigen fps hat Helios die eigene Mausbewegung als „Maus hat Vorrang“ gewertet.

- **Rechtshänder default.** Neue Installationen und leeres Pref: rechte Hand steuert. Linkshänder-Schalter bleibt.
- **Körperpose stimmt L/R ab.** `VNDetectHumanBodyPose` votiert über die Handgelenke, wenn Vision die Hände vertauscht. `forearmGate` dämpft weiter die Qualität.
- **SpaceMap hybrid.** Nur die äußeren 15 % absolut (Ecken erreichbar), innen Trackpad-Relativ — kein Homographie-Zittern in der Mitte. Kalibrierung merkt die Display-ID.
- **Maus-Clutch ignoriert eigene Events.** 48 px / 120 ms um den letzten `CGEvent`. Delta ≈ 0 zählt nicht als Hardware.
- **Pointer-Beschleunigung** (quadratisch): Feinzielen bleibt langsam, Schwung wird schneller.
- **Fling-Totzone am Schirmmittelpunkt**, sobald kalibriert — nicht mehr Kamerabild-Mitte.
- **Aktions-Log 62 %** (war Text „70 %“ bei Tor 0,62). Fusion-Temperatur als Inspector-Slider. Peace-Ring + Clutch-LED im HUD.

## Neu in 1.6.6

**2× klatschen weckt Helios**, auch wenn die Konsole weg ist und nur die Kamera im Hintergrund läuft. Rein visuell: zwei Hände, Palmenabstand fällt schnell unter Kontakt und wieder auf — **kein Mikrofon**. Faust bleibt der andere Weg zu Scharf. Not-Aus (beide Hände offen, Abstand) zählt nicht als Klatschen. Die Kamera bleibt aktiv, damit das im Hintergrund ankommt.

## Neu in 1.6.5

Der cyanfarbene Rahmen war **kein eigenes Fenster** — er markierte das Fenster unter der Hand. Standard an, plus Schreibtisch-Hintergrund = Umriss über den ganzen Monitor, SwiftUI interpolierte die Höhe, Wischen ohne zweite App schickte ⌘⇥. Die Konsole (selbst mit Cyan-Rahmen um die Kamera) kam nach SwiftUI-Updates wieder nach vorn. Zwei Pinzetten haben bei 0,28 Handbreiten Zittern die Fensterhöhe gepumpt.

- **App-Umriss aus.** Einmalig zurückgesetzt. Nur noch beim Greifen/Halten, wenn du ihn einschaltest. Schreibtisch/Wallpaper wird nie umrandet. Keine Animation zwischen Fenstern.
- **Konsole bleibt weg.** Nach Scharf: `orderOut` plus Wächter gegen `didBecomeKey` / `didBecomeMain`. SwiftUI darf sie nicht zurückholen. Menüleiste → Konsole.
- **Keine ⌘⇥-Krücke** mehr, wenn nur eine App offen ist — das war der System-Umschalter.
- **Skalieren** braucht 0,55 Handbreiten, Gegenrichtung 1,8× — Höhe pumpt nicht mehr.
- Konsole: linke Spalte scrollt, Fenster wächst nicht mit dem Inhalt.

## Neu in 1.6.4

Sitzung 2026-09-02: Pinzette wurde zum Greifen, Öffnen zum App-Wechsel, Zug nach unten zum Minimieren, die Konsole lag über den Apps, zwei Hände stahlen sich Pinzette und Cursor.

- **Pinzette kurz und still = Klick.** Zug erst ab 0,45 Handbreiten oder 28 px — 0,18 war Palm-Zittern. Die Hand, die das Gate schließt, bleibt der Actor.
- **Ziehen hält.** Loslassen nach echtem Fensterzug dockt/minimiert nicht, außer der Ruck ist klar (2,4× Werfen-Schwelle). Vertikal ablegen geht.
- **Kein Hin-und-her-Wischen.** 0,75 s Mute nach Pinzette, Gegenrichtung 1,1 s gesperrt, nur die Steuerhand wischt.
- **Zwei Pinzetten** ab `pinchClosedness > 0,42`, Bestätigung 80 ms — Skalieren stiehlt nicht mehr der erste Klick.
- **Peace** nur allein auf der Steuerhand, 1,1 s, nicht während die andere Hand offen ist (Öffnen ≠ Aufnahme).
- **Konsole aus bei Scharf.** HUD bleibt Overlay, wird nie Key-Window. Menüleiste → Konsole.
- **Kalibrierung = Anschlag**, nicht Kamerarand. Kleineres Viereck gilt.
- **Loupe + Magnet** an Schließen / Minimieren / Vollbild, wenn die Pinzette in der Titelleiste zielt.
- **Kamera-Picker:** Mac, iPhone-Kontinuität, Desk View, USB (Osmo Action 3 im Webcam-Modus). LiDAR/TrueDepth nur wenn das Format Tiefe liefert.

## Neu in 1.6.3

PR `bugfix` (1.5.8 Fling-Fenster / Dead-Man / Palm-Hochpass) war nie in `main`. 1.6.0–1.6.2 haben Fusion und AX, aber Werfen mittelte weiter den ganzen Pinch-Trail.

- **Werfen aus 120 ms.** Ziehen + Ruck zählt, nicht der Mittelwert über das Halten. Mini-Zucken in der Bildmitte dockt nicht — ein echter Wurf aus der Mitte schon. Schwellen bleiben Handbreiten.
- **Dead-Man 8 s.** Keine Hand → Idle, Faust muss neu scharf schalten. Der 180-ms-Dropout bleibt für kurze Verluste.
- **Palm-Hochpass + Totzone 0,012.** Relativ-Zeiger folgt der Geste, nicht dem Atem. SpaceMap teilt die Totzone, glättet weicher (0,55).
- **Wischen nur offene Hand** (`openScore ≥ 3`) — Peace wechselt keine Apps. Flick-Schwellen aus 1.6.1 bleiben.
- **Kill-Grace 0,14 s.** Zweite Hand am Bildrand ist kein Not-Aus.
- **Kamera-Winkel** über `videoRotationAngle`. HUD: „Relativ — kalibrieren für absolut“, ohne den Zeiger zu blocken.

## Neu in 1.6.2

Koordinaten, AX, Threads und HUD — die Erkennung aus 1.6.1 bleibt.

- **Fensterumriss sitzt.** Overlay rechnet mit Quartz-minY (obere Kante), nicht maxY. Umriss, Greifstrahl und Schirmwahl lagen eine Fensterhöhe zu tief.
- **AX crasht nicht** mehr, wenn eine App ein unerwartetes Attribut liefert (CFGetTypeID statt Force-Cast).
- **Hauptthread bleibt frei.** Peace-Aufnahme, Finder-Papierkorb und Quarantäne-xattr laufen nicht mehr synchron auf main. Fensterzug hält nur den letzten Zielpunkt, solange AX beschäftigt ist.
- **Maus hat Vorrang** auch ohne gedrückte Taste. Clutch-Monitore und der Rechte-Timer werden beim Beenden abgemeldet.
- **Kalibrierung** zählt die Haltezeit nur mit geschlossener Pinzette. Export überschreibt nur Helios-Dateien, löscht keinen Ordner.
- **Fadenkreuz-Schalter** blendet den Hand-Marker wirklich aus. Fehlende Rechte erscheinen als HUD-Zeile, nicht als modaler Alert in der Gestenschleife. Pinzette gehalten ohne Zug → Protokoll „kein Zug“, nicht „fehlgeschlagen“. Klick-Pause ebenfalls nicht als Fehler.
- Homographie einmal cachen, Vision-Revision pinnen, Helligkeit über CIAreaAverage statt GPU-Buffer-Lock.

Details: [docs/Erkennung.md](./docs/Erkennung.md), [VORSCHLAEGE.md](./VORSCHLAEGE.md).

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
| **2× klatschen** (Kamera, kein Ton) | Scharf, auch im Hintergrund |
| Offene Hand bewegen | Cursor (Trackpad: heben = neu ansetzen) |
| Pinzette kurz | Klick (still, nicht ziehen) |
| Pinzette + Ringfinger kurz | Rechtsklick |
| Pinzette oder Faust + ziehen | Fenster verschieben; Loslassen = ablegen |
| In die Papierkorb-Ecke ziehen und loslassen | Fenster zu / Finder-Auswahl in den Papierkorb |
| Werfen nach oben (Ruck, nicht das Ziehen) | Wegwerfen |
| Werfen nach unten | Minimieren |
| Werfen nach links/rechts | Andocken |
| Pinzette + zu sich ziehen | Fenster füllen |
| Zwei Pinzetten | Skalieren |
| Offene Hand **schnell** waagerecht wischen | App wechseln |
| Zwei offene Hände vertikal | Scroll |
| Offene Hand 1 s still (optional) | Dwell-Klick |
| Peace allein halten (~1,1 s) | Fensteraufnahme auf den Schreibtisch |
| Daumen hoch | App hervorholen |
| Beide Handflächen (~0,8 s, nicht zusammen) | Not-Aus → Idle (Faust **oder** 2× klatschen macht wieder scharf) |

**Testmodus** (⌘T): Erkennung anzeigen, keine Systemaktionen.

Aktive App bekommt nur beim Greifen einen Umriss, und nur wenn der Schalter an ist (Standard aus). HUD liegt auf jedem Monitor. Keine Stimme.

Bei Scharf blendet Helios die Konsole aus (Menüleiste holt sie zurück), damit die anderen Apps sichtbar bleiben.

## Kameras

Paar in der Konsole, oder eine Quelle.

| Paar / Quelle | Rolle |
|---|---|
| Eine Kamera | Nur die gewählte Quelle |
| Mac + iPhone | Mac führt (vorn), iPhone Kontinuität oder Desk View als zweiter Winkel |
| Mac + Osmo | Mac führt, Osmo Action 3 USB-Webcam (seitlich/weit) |
| iPhone + Osmo | **Kein Mac.** iPhone führt, Osmo deckt den toten Winkel |
| LiDAR | Nur wenn Kontinuität ein Tiefenformat liefert |

Kalibrierung: erst Lead 4 Ecken, dann Cover dieselben Bildschirmecken aus dem anderen Winkel. Jede Homographie gehört zu genau dieser Kamera (Blickwinkel, Weitwinkel, Spiegelung).

Continuity blockt oft die Mac-Kamera — dann bleibt Lead allein. Osmo per USB ist die robuste zweite Quelle. Cover-Vision läuft gedrosselt (~20 fps).

## Bau

Xcode 26/27, macOS 26 SDK:

```
xcodebuild -project macos/Helios.xcodeproj -scheme Helios -configuration Release ARCHS=arm64
swiftc macos/Helios/CoordMath.swift macos/HeliosTests/CoordTests.swift -o /tmp/coordtests && /tmp/coordtests
```

GitHub Actions legt bei jedem Push auf `main` eine `Helios.dmg` als Release ab.

Ad-hoc-Signatur. Developer ID + Notarisierung braucht ein Apple-Zertifikat — ohne das muss der Nutzer nach jedem Update die TCC-Schalter neu setzen.

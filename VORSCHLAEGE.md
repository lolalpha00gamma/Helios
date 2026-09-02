# Helios — Vorschlagsliste

Stand: **1.6.14**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes.

## In 1.6.14 erledigt

Warum 1.6.13 weiter falsch klickte und Gesten verschluckte: Pinzette-Lock fiel bei einem verlorenen Frame auf die **Steuerhand** (Kommentar sagte das Gegenteil). Fusion-Entropie fehlte — flaches Softmax blieb ≥ 0,62 und `perform()` feuerte Zufall. Continuity 8 fps nutzte denselben Hochpass wie 24 fps. HMM-Hold gab die verdünnte `next[current]` als Pose-Prob, also blockte das 62-%-Tor die gehaltene Faust.

1. **Pinzette friert.** Fehlende Lock-ID → letzte Hand, nie `primary`. Fehlklick der anderen Hand ist tot.
2. **Aktions-Tor an Entropie.** Spitz 0,55 / flach 0,72. HUD zeigt H und Tor.
3. **Hochpass × dt.** 8 fps Alpha hoch, Deadzone ×1,55. Ecken 2 % Ruhezone.
4. **Hände auf dem Tisch** 1,2 s unten still → Idle, kein Not-Aus.
5. **Per-App-Profil.** Xcode aus, Safari Klick/Scroll, Finder Werfen. HUD + Konsole.
6. **HMM-Hold behält lastRealProb** — unknown drückt die Pose nicht unter das Tor.
7. MARKETING_VERSION 1.6.14 (Build 44).

## In 1.6.13 / 1.6.12 erledigt

Konsole stiehlt den Vordergrund nicht mehr. Nur direkte Wahl (Fenster, ☀, Dock) holt sie nach vorn. Standard: sichtbar auch bei Scharf.

## In 1.6.11 erledigt

Konsole wirkte tot, Cmd+Q traf die App darunter, Osmo ohne Livestream.

- Beenden über Dock/Menü. Konsole bleibt bis man sie schließt.
- Osmo als zweites Bild, Cover wählbar.

## In 1.6.10 erledigt

Die Installations-DMG fehlte unter Releases (Tests rot). Faust mit eingerollten Fingern war Pinzette.

- Fling-Totzone nur Mini-Ruck in der *kalibrierten* Schirmmitte.
- Faust ≠ Pinzette: Pinzette braucht gestreckten Zeigefinger.
- HMM hält die letzte echte Pose; Track stirbt nach 0,18 s.
- Build: Tiefenkanal iOS-only.

## In 1.6.9 erledigt

- Zwei `AVCaptureSession`s: Mac+iPhone, Mac+Osmo, iPhone+Osmo ohne Mac.
- Kalibrierung **pro Kamera** (eigene Homographie = Blickwinkel/FOV/Spiegelung).
- Winkel-Unco: >140 px Abweichung → Lead, kein Blend.
- Cover nur wenn Lead die Hand verliert.

## In 1.6.8 erledigt

Warum 1.6.7 sich tot anfühlte, sobald die zweite Hand im Bild war: Not-Aus zählte 0,8 s jede zwei offenen Hände und **return true während des Zählens** — Klick, Wischen, Skalieren starben. Körperpose überschrieb Vision L/R schon bei Verhältnis 0,72 → Steuerhand-Tausch → Cursor-Teleport. Softmax/HMM hatten `.unknown` mit Logit 0,35, Pose fiel unter das 0,62-Tor.

- **Not-Aus nur nach 1,35 s** zwei `openPalm`, Abstand ≥ Klatschen-offen, still. Während des Haltens laufen andere Gesten weiter. Pinzette / Zwei-Pinzette überspringt. Grace blockt nicht.
- **Körper-Vote nur bei Vision-unbekannt oder Verhältnis < 0,50.** Schwacher Wrist-Treffer kippt die Steuerhand nicht mehr.
- **Cursor bleibt** beim Track-Wechsel: Palme neu verankern, `cursorSmooth` behalten.
- **unknown-Logit −1,8.** HMM hält die aktuelle Pose, wenn unknown schwach führt.
- **palmWidth-EMA** pro Track (0,22) — Fling/Wischen bei Webcam-Zoom stabil.

## In 1.6.7 erledigt

Warum es sich tot anfühlte: `leftHanded = true` (Prefs-Fallback auch), Vision L/R ohne Körper-Vote, kalibrierte Homographie 100 % absolut (Mitte zittert), Clutch hat eigene `mouseMoved` bei <12 fps als Hardware gewertet, linearer Gain, Fling-Totzone an der Kameramitte, Log „70 %“ bei Tor 62 %.

- Default **Rechtshänder**. Prefs-Fallback `false`.
- **Körperpose-Vote** für Chirality (`leftWrist`/`rightWrist`, Verhältnis < 0,72).
- **SpaceMap hybrid** äußere 15 % absolut / innen Relativ. **Per-Display-ID**.
- **Clutch:** 48 px + 120 ms um letzten eigenen CGEvent, Delta < 0,5 ignoriert.
- **Pointer-Accel** (quadratisch). Fling-Totzone am **Schirmmittelpunkt** wenn kalibriert.
- Fusion-Temperatur Slider. Peace-Ring, Clutch-LED. Log „Pose < 62 %“.

## In 1.6.6 erledigt

- 2× klatschen (sichtbar, Palmenabstand) weckt Scharf im Hintergrund. Kein Mikrofon.
- Not-Aus nur mit Händen auseinander — Kontakt ist Klatschen.
- Kamera-Keep-Alive, damit Idle/Accessory weiter Frames bekommt.

## In 1.6.5 erledigt

- App-Umriss ist kein Fenster: Standard aus, nur Greifen, kein Schreibtisch, keine Höhen-Animation.
- Konsole kommt nach Scharf nicht zurück (Key/Main-Wächter).
- Wischen landet nicht per ⌘⇥ im System-Umschalter.
- Zwei-Pinzetten-Skalieren ohne Höhen-Pumpe (0,55 + Gegenrichtungs-Sperre).
- Konsolen-Höhe nicht mehr vom Inhalt getrieben.

## In 1.6.4 erledigt (Sitzung 2026-09-02)

- Pinzette bleibt an der Hand, die das Gate geschlossen hat.
- Klick wenn still (< 0,45 Handbreiten / 14 px), Zug erst darüber.
- Fling nach echtem Fensterzug braucht 2,4× Schwelle — Ablegen ist kein Minimieren.
- Wischen: Mute 0,75 s nach Pinzette, Gegenrichtung 1,1 s, nur Steuerhand.
- Zwei-Pinzetten 80 ms / `pinchClosedness`.
- Peace 1,1 s, nur allein auf der Steuerhand.
- Konsole bei Scharf aus, HUD-Panel wird nie Key.
- Kalibrierung akzeptiert den persönlichen Anschlag.
- Chrom-Loupe + Magnet an Schließen/Mini/Zoom.
- Kamera-Picker (Mac / Kontinuität / Desk View / USB).

## In 1.6.3 erledigt (aus 1.5.8 `bugfix`, nicht nochmal mergen)

`bugfix` / PR #1 war 1.5.8 gegen 1.5.7. `main` ist 1.6.2 — Fusion, Handbreiten, Flick, Dropout. Roh mergen würde das zerlegen.

| 1.5.8 | 1.6.2 vorher | 1.6.3 |
|---|---|---|
| Fling-Fenster 120 ms | first→last über 0,5 s Trail (Bug) | Fenster, in **Handbreiten** |
| Totzone Bildmitte | fehlte | nur Mini-Zucken; Wurf aus der Mitte bleibt |
| Dead-Man 8 s | nur 180 ms Dropout | 8 s → Idle + Rearm |
| Palm-Hochpass + Dead 0,012 | Dead 0,003, kein Hochpass | Hochpass am Relativ-Zeiger, Totzone auch SpaceMap |
| Wischen `openScore ≥ 3` | `≥ 2` (Peace wischte) | ≥ 3, Flick-Zahlen aus 1.6.1 |
| Kill-Grace 0,14 s | 0,28 s hart | 0,14 s |
| `videoRotationAngle` | Vision immer `.up` | Winkel nach dem Format |
| HUD Kalibrierung fehlt | fehlte | Zeile in der Top-Bar, Relativ läuft |
| Peace 0,80 / Clutch 1,2 s | Peace 0,90 / Clutch 0,85 | **behalten** — 1.6.x ist hier besser |
| CI auf `bugfix` | — | **nicht** — nur `main` |

## In 1.6.2 erledigt

Koordinaten, AX, Threads, HUD — nicht die Erkennung (die war 1.6.0/1.6.1).

1. **localRect** nimmt Quartz-minY als Overlay-oben. Umriss, Greifstrahl, `intersects` lagen eine Fensterhöhe zu tief. Tests decken Haupt- und Zweitbildschirm ab.
2. **AX ohne Force-Cast.** `CFGetTypeID` vor jedem `AXUIElement`/`AXValue`.
3. **Main nicht blockieren.** `screencapture` und Finder-AppleScript vom Hauptthread, xattr beim Start auf Utility-Queue. Fensterzug koalesziert (letzter Punkt, Timeout auch am Drag-Element).
4. **dlopen einmal.** Installationsort/Translokation gecacht, nicht pro Cursor-Frame.
5. **PinchGate und HMM** resetten beim Handverlust. Kalibrier-Hold nur mit Pinzette.
6. **Export** löscht keinen bestehenden Ordner rekursiv.
7. **mirroredFlag** hinter demselben Lock wie der Frame-Handler. `apply()` koalesziert wie FramePump (letzter Stand, Vision-Zeitstempel).
8. **README** zeigt auf `lolalpha00gamma/Helios`. Homographie gecacht. Rechte-Demand ohne modalen Alert. Klick-Pause und Pinzette-ohne-Zug sind kein Fehler im Protokoll. `snapFocused` am Engine-Cursor. Wischen nimmt keine Faust. Vision-Revision gepinnt, `usesCPUOnly` weg. Luma über CIAreaAverage. Toter Code (HandBeacon, Reticle, missionControl) raus. Fadenkreuz steuert den Hand-Marker. permTimer und Clutch-Monitore werden beim Beenden abgemeldet. Maus-Clutch auch bei `mouseMoved`.

## In 1.6.1 erledigt


1. **Korrelierte Fusion.** Lift3D und Temporal-Heuristik sind dieselben 2D-Punkte (plus klebriges z-Vorzeichen). 1.6.0 hat sie als unabhängige Stimmen gepoolt → flaches Softmax → Pose < 70 % → `perform()` hat *jede* Systemaktion blockiert. Jetzt: 2D führt (0,62), Lift/Zeit kollabieren bei >80 % Überlappung, Softmax-Temperatur 0,75, Tor 62 %.
2. **Kein Chirality-Doppel-Flip.** Der Frontkamera-Buffer ist schon `isVideoMirrored`. Ein zweiter L/R-Tausch hat Linkshänder die rechte Hand als Steuerhand gegeben. Unbekannt fällt auf Bildposition, gespiegelt vs. ungespiegelt getrennt.
3. **Zwei-Pinzetten nach 0,35 s** belegen den Tick weiter — sonst feuern Klick und Wischen während des Skalierens.
4. **Track-Zuordnung 0,42** (war 0,22 iso) plus Chirality-Bonus. Flicks verlieren die ID nicht mehr.
5. **HMM** τ=0,11 s, Umschalten ab p≥0,48 / 50 ms. 0,62 + 180 ms hat Gestenwechsel verschluckt.
6. **PinchGate.** Occludierte Spitzen halten max. 0,32 s zu, nicht ewig.
7. **Dropout 180 ms.** Ein verlorener Vision-Frame beendet Drag nicht mit einem Fehlklick.
8. **Scroll / Rechtsklick / Dwell** wirklich verdrahtet (1.5.8 hatte sie nur in der README). Dwell aus by default.
9. **HUD:** Idle-Banner nach Not-Aus, Latenz-Sparkline (30 Frames), Fusion zeigt kollabierte Quellen.
10. **Not-Aus und Zwei-Pinzetten** bewegen den Cursor weiter.

## In 1.6.0 / 1.5.8 / 1.5.7 erledigt (nicht nochmal bauen)

Fusion 2D/3D/Tiefe/Zeit verdrahtet. AX in Cocoa. Flick-Wischen. Faust-Scharf ohne Folge-Klick. Cooldown friert den Cursor nicht ein. Not-Aus 0,8 s. Chirality teilt sich keinen Smoother. Maus-Clutch inkl. `mouseMoved`. Peace 0,9 s.

## Nächste Fixes (klein, hoher Nutzen)

- **Zwei-Pinzetten Skalieren** an gegenüberliegenden Fensterkanten, nicht am Palmenabstand.
- **Session-Replay** der Landmark-CSV direkt im HUD, Frame für Frame — ohne Xcode.
- **Clutch nur globale Hardware** — Local-Monitor ganz weglassen (eigene Events kommen lokal an).
- **Kalibrier-Quad sichtbar** als dünnes Viereck der vier Anschläge, nicht nur Ecken-Marken.
- **Peace-Fortschritt auch in der Konsole**, nicht nur HUD-Ring.
- **Klick-Tick** optional (system sound), aus by default.
- **Profil-Override** in der Konsole (Safari voll, Xcode nur Scroll) — Defaults bleiben hart.
- **Pinzette-Hysterese pro fps** an `sampleDt` koppeln (8 fps 0,45 Handbreiten zu knapp).
- **Fusion-Temperatur auto** aus Landmark-Qualität, Slider bleibt Override.
- **CGEvent 1-px Jiggler ignorieren** (manche Mäuse senden Idle-Ticks).

## Größere Erweiterungen

- **Developer ID + Notarisierung.** Ohne das muss TCC nach jedem Update neu an.
- **VoiceOver-Ansage** der letzten Aktion, ausgeschaltet by default.
- **Fenstertiling über Stage Manager** statt nur AX-Snap.
- **Swift Testing** in Xcode, Gesten-Zeitreihen als Fixtures.
- **LiDAR/TrueDepth** (`DepthCapture`) verdrahten, sobald ein Mac es hat — Datei existiert, Session hängt am Format.
- **Echtes Temporal-CoreML** (`HeliosTemporal.mlmodel`) statt Heuristik. Ohne Modell bleibt Zeit ein 2D-Echo.
- **Zoom/Trackpad-Magnify** als Geste (Pinzette + offene zweite Hand).
- **Mission Control / Schreibtisch.** Drei Finger hoch / runter, hinter Extra-Schalter.
- **Apple Watch als Not-Aus.** Krone oder Action-Taste tötet Injektion, wenn die Kamera die Hände nicht sieht.
- **Umgebungslicht → HUD.** Bei dunklem Schreibtisch Overlay dämpfen, nicht den Bildinhalt überstrahlen.
- **Hand-Velocity-Prior** im HMM (schnelle Faust ist kein Pinch).
- **Zwei-Personen-Szenen.** Wenn Körperpose zwei Torsi sieht, zweite Hand nie als Steuerhand.
- **Hover-Dwell nur über AX-Knöpfen**, nicht frei auf dem Schreibtisch.
- **Desk-View als zweite Karte**, nicht als Steuerkamera (Aufsicht für Kill/Klatschen).
- **Gesten-Lexikon.** Nutzer hält 1,5 s eine Pose, speichert sie als benannte Aktion (ohne CoreML-Training).
- **Watch-IMU Fusion.** Handgelenk-Beschleunigung als Clutch/Kill, wenn die Webcam die Hände verliert.
- **Overlay auf Stage-Manager-Spaces** — AX sieht oft nur das aktuelle Space.
- **Zwei-Personen-Szenen.** Wenn Körperpose zwei Torsi sieht, zweite Hand nie als Steuerhand.
- **Cursor-Gain pro Display-PPI**, nicht eine Zahl für Laptop+5K.
- **Kill-Geste ein Finger-Y** (beide Zeigefinger kreuzen) als Alternative zu zwei offenen Palmen.
- **Osmo IMU** wenn USB das liefert — Cover-Winkel ohne zweite Homographie grob schätzen.
- **App-Profil JSON** neben Defaults, damit der Nutzer Xcode doch Scroll erlauben kann ohne Rebuild.
- **Fling-Richtung an Stage-Manager** (links = recent, nicht nur AX-Snap).

## Nicht tun

- Stimme / Diktat als Geste — kollidiert mit Kill und Peace.
- Mehr als zwei Hände. Vision max. 2 ist die ehrliche Grenze.
- Cursor während Pinch-Hold einfrieren (war Absicht für Klick-Zielen — bleibt).
- Fusion-Dateien wieder aus dem Target nehmen.
- Lift3D und Temporal wieder als unabhängige Voter mit Gewicht ≥ 0,25.
- Aktions-Tor wieder auf 70 % ohne die Fusion zu schärfen.
- `tick` bei Cooldown wieder komplett returnen — der Cursor muss laufen.
- Faust nachträglich zur Pinzette ummappen.
- PR #1 / Branch `bugfix` mergen — 1.6.3 hat die fehlenden Stücke, der Branch ist 1.5.7.
- Not-Aus wieder `return true` während des Zählens.
- Körperpose Vision L/R immer überschreiben.
- `.unknown` wieder mit positivem Softmax-Logit.
- Cursor bei Track-ID-Wechsel auf die neue Palme teleportieren.
- Pinzette-Lock auf `primary` fallen lassen, wenn die Hand einen Frame fehlt.
- Aktions-Tor wieder hart 0,62 ohne Entropie.
- HMM-Hold `next[current]` (verdünnt) als Pose-Prob zurückgeben.
- Hochpass 0,08 unabhängig von Frame-dt.
- Per-App-Profil wieder alle Aktionen in Xcode/Safari.

# Helios — Vorschlagsliste

Stand: **1.6.6**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes.

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

- **Per-App-Profile.** Safari: nur Klick/Scroll. Finder: Werfen/Papierkorb. Xcode: aus.
- **Kalibrierung merken pro Display-ID**, nicht nur ein Homography für alle Schirme.
- **SpaceMap hybrid:** nur in den äußeren 15 % absolut, innen Trackpad-Relativ.
- **Maus-Clutch ignoriert eigene CGEvents** härter (delta=0 Filter) — bei <12 fps kann `mouseMoved` Helios selbst pausieren.
- **Chirality über Körperpose**, wenn Vision L/R vertauscht (`VNDetectHumanBodyPose`) — `forearmGate` existiert, L/R-Vote noch nicht.
- **Zwei-Pinzetten Skalieren** an gegenüberliegenden Fensterkanten, nicht am Palmenabstand.
- **Pointer-Beschleunigung** wie Trackpad (nichtlinear), damit Feinzielen in der Bildschirmmitte nicht zittert.
- **Session-Replay** der Landmark-CSV direkt im HUD, Frame für Frame — ohne Xcode.
- **Fusion-Temperatur** als Inspector-Slider (Debug), nicht hart 0,75.
- **Fling-Totzone am Bildschirm-Mittelpunkt**, sobald kalibriert (jetzt: Kamerabild-Mitte).
- Default nicht wieder `leftHanded = true`.
- **Zwei Sessions parallel** (Mac + Desk View oder Mac + Osmo), Vision nur auf der führenden.

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

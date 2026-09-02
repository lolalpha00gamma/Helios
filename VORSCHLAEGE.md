# Helios — Vorschlagsliste

Stand: **1.6.2**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes.

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

# Helios — Vorschlagsliste

Stand: **1.6.4**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes.

## In 1.6.4 erledigt

Warum 1.6.3 sich auf zwei Schirmen und in Safari trotzdem falsch anfühlte: eine Homographie für alle Displays, keine Profil-Overrides, Lock ohne Hysterese, Scroll unabhängig von der Palme, Tippen injizierte Pinches, Kill ohne Abbruch.

1. **9-Punkt-Gitter.** DLT least squares (`AtA` 8×8), 4-Punkt-Gauss bleibt der Pfad für gespeicherte Ecken-Karten.
2. **SpaceMap pro `CGDirectDisplayID`.** Key `helios.spaceMap.{id}`, Fallback `helios.spaceMap`. Cursor wechselt die Karte, wenn der Schirm eine eigene hat.
3. **Profil-Editor.** Extra/Blocked in `helios.profileOverrides`. Safari-Werfen darf an, Default bleibt aus.
4. **Dominant-Lock-Hysterese 200 ms.** Die zweite Hand stiehlt den Cursor nicht in dem Frame, in dem die erste das Bild verlässt.
5. **Scroll-Gain `2,2 / palmWidth`.** unit 0,12 ≈ 18 Ticks wie bisher; große Palme feiner.
6. **Tasten-Clutch.** Global+Local `keyDown` → 400 ms keine Gesten-Injektion.
7. **Kill-Abbrechen.** Faust + eine offene Hand während des Holds → Hold weg, kein Idle.

## In 1.6.3 erledigt

Warum 1.6.2 sich trotzdem falsch anfühlte: Default Linkshänder, Kill fraß Scroll, zweite Hand stahl den Cursor, Safari-Werfen schloss Fenster.

1. **`leftHanded` Default false.** UserDefaults ohne Key war `true` — die Mehrheit hat mit der falschen Hand den Cursor geführt.
2. **Kill vs. Scroll.** Zwei offene Hände mit vertikaler Geschwindigkeit > 0,7 Handbreiten/s sind Scroll, kein Not-Aus. Still halten 0,8 s bleibt Kill. Die ersten 0,35 s belegen den Tick nicht; die Nachlauf-Sperre ist 0,18 s.
3. **Dominant-Hand-Lock** nach 1,2 s. Der Timer läuft durch (nicht pro Frame zurückgesetzt). Die zweite Hand pincht nicht den Zeiger weg; sie darf weiter scrollen/skalieren/killen.
4. **Vision-Orientierung** aus `videoRotationAngle` der Capture-Connection, nicht hart `.up`. Continuity/geklapptes MacBook kippt Yaw nicht mehr.
5. **SpaceMap hybrid.** Äußere 15 % der Kalibrier-Quad absolut (Homographie), innen Trackpad-Relativ.
6. **Zwei-Pinzetten an Fensterkanten.** Links/rechts ziehen die AX-Kanten, nicht isotrop um die Palme.
7. **Per-App-Profile.** Safari/Chrome: kein Werfen/Greifen (sonst schließt ein Flick das Fenster). Wischen = App-Wechsel bleibt. Finder: Werfen an. Xcode: nur Klick/Scroll/Rechtsklick.
8. **Adaptive Kamera-FPS.** Idle 8 fps, Hand im Bild native 24–30.
9. **Fusion-Temperatur** als Inspector-Slider (0,35…1,20), Default 0,75.

## In 1.6.2 erledigt

Warum 1.6.1 sich trotzdem tot anfühlte: Fusion und Tor standen, aber drei Filter haben die Pose vor dem Tor erwürgt.

1. **HMM-Übergänge normiert + Velocity-Prior.** `pLeave` wurde vorher nicht auf die Zielposen verteilt — Masse sickerte ab, committed Pose starb unter 62 %. Schnelle Palme (`palmSpeed > 2,2`) dämpft Pinch: eine Wischbewegung ist keine Pinzette. Umschalten 18/38 ms, Pinch-EMA τ=0,04 bei Extremen. Gate-Konfidenz = max(committed, best).
2. **Landmark-Smoothing ohne Idle-Cap.** 80-Frame-Median aus Ruhe hat Flicks als Ausreißer behandelt. Cap kommt aus dem aktuellen Frame (History nur wenn <4 Gelenke), Floor 1,2, Blend 0,55/0,45.
3. **Körper-Chirality.** `VNDetectHumanBodyPose` Left/Right-Wrist stimmt ab, wenn Vision L/R tauscht. `forearmGate` bekommt damit den richtigen Ellbogen.
4. **Track-Zuordnung mit Velocity.** Palm + `lastVel * dt` statt letzte Position. Chirality-Bonus 0,06, Schwell 0,55.
5. **Nichtlineare Pointer-Beschleunigung** in `stepCursor` (Trackpad-Kurve: Feinzielen in der Mitte, Flicks am Rand).
6. **Zwei-Pinzetten nur gegenüberliegend** (Δx ≥ 0,22). Zwei Pinzetten an einer Palme skalieren nicht mehr.
7. **Maus-Clutch ignoriert eigene CGEvents** 120 ms, außer Delta > 9 (echte Hardware).
8. **Daumen-hoch 3D** verlangt geschlossene restliche Finger, wie 2D.
9. **Log sagt 62 %**, nicht 70 % — das Tor war schon 0,62.

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

- **Session-Replay** der Landmark-CSV direkt im HUD, Frame für Frame — ohne Xcode.
- **Peace vs. Point.** Zwei Finger plus Daumen-an-MCP wird noch als Peace gelesen.
- **Profil-Bundle-Liste** als JSON-Datei im Bundle, nicht nur die Tabelle in `AppGestureProfile`.
- **Kalibrier-RMSE** nach 9 Punkten anzeigen. Wenn > 12 px: „nochmal Mitte“.
- **Display-Reconfig.** `CGDisplayRegisterReconfigurationCallback` lädt die Karte neu, statt mit der Union weiterzulaufen.
- **Palm-Deadzone an palmWidth.** Feinzielen nah an der Kamera zittert sonst in den äußeren 15 %.
- **Per-App Scroll-Richtung.** Finder vs. Browser invertieren, analog zum Trackpad-Natural-Scroll.
- **HID-Filter für eigene Events** über `CGEventSourceStateID` statt Zeitfenster — Clutch wird unempfindlich gegen fps.

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
- **Zwei-Personen-Szenen.** Wenn Körperpose zwei Torsi sieht, zweite Person nie als Steuerhand.
- **Gesten-Grammatik.** Sequenzen (Pinch → Flick = Tab wechseln) statt einer Pose = einer Aktion.
- **Kalman auf Palme 3D**, sobald Tiefe da ist — One-Euro bleibt für 2D.
- **Click-Lock** für Slider: Pinch halten rastet, Bewegung ohne Zittern am Thumb.
- **Aegis-Bridge.** Eine Kamera-Session, zwei Consumer — TCC nur einmal.
- **Blick (wenn das SDK es hergibt)** disambiguiert welches Fenster gemeint ist, bevor AX rät.
- **Stage-Manager-Spaces.** Ein SpaceMap pro `CGSSpace`, sonst springt der Cursor nach Space-Wechsel.
- **Continuity-Desk-View.** Wenn die iPhone-Kamera als Continuity hängt, HUD-Vorschau spiegeln wie die Frontkamera.
- **Zwei-Hand-Rotate.** Gegenläufige Palmen um die gemeinsame Mitte = Fenster drehen (nur wo AX es hergibt).
- **Desk vs. Couch.** Ein Gain-Profil für 40 cm Kameraabstand, eines für 1,5 m — palmWidth wählt.
- **Pointer-Trail im HUD.** Letzte 12 Palm-Punkte als Debug, aus by default.
- **Accessibility-Zoom folgt.** Wenn Zoom an ist, bewegt die Palme den Fokus-Rect, nicht den 1:1-Cursor.

## Nicht tun

- Stimme / Diktat als Geste — kollidiert mit Kill und Peace.
- Mehr als zwei Hände. Vision max. 2 ist die ehrliche Grenze.
- Cursor während Pinch-Hold einfrieren (war Absicht für Klick-Zielen — bleibt).
- Fusion-Dateien wieder aus dem Target nehmen.
- Lift3D und Temporal wieder als unabhängige Voter mit Gewicht ≥ 0,25.
- Aktions-Tor wieder auf 70 % ohne die Fusion zu schärfen.
- HMM-Übergänge wieder unnormiert (Masse sickerte, Pose < 62 %).
- Idle-Median als Flick-Cap.
- `leftHanded` wieder default true.
- Kill bei zwei offenen Händen unabhängig von Bewegung (frisst Scroll).

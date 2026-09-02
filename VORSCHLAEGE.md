# Helios — Vorschlagsliste

Stand: **1.6.12**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes.

## In 1.6.12 erledigt

Warum 1.6.11 Slider trotzdem zittert, Peace nach Fehlschlag 4 s tot ist, Browser nicht seitwärts scrollt und Text-Drag in die Toolbar läuft: Magnet ließ nach 0,18 Handbreiten los. `drivePeace` setzte Cooldown immer auf 4 s. `driveScroll` kannte nur Y. `updateTextDrag` hat die AX-Rolle nicht geprüft. Natural-Scroll des Systems war unsichtbar. `keyDown` ohne Repeat/Modifier ließ Tippen in Gesten laufen.

1. **Click-Lock** auf AXSlider/Incrementor bis 0,30 Handbreiten. Magnet-Cache hält die Rolle.
2. **Peace-Cooldown 0,8 s** nach Fehlschlag (`perform` gibt den Treffer zurück).
3. **Horizontal-Scroll** (`wheel2`) bei klarem Δx.
4. **Text-Drag bricht** an Button/Toolbar/Tab.
5. **Natural-Scroll XOR Profil.** Natural-aus dreht Safari nicht doppelt.
6. **Tasten-Clutch.** `flagsChanged` + Repeat 550 ms, Modifier halten, CapsLock nicht.

## In 1.6.11 erledigt

Warum 1.6.10 nach der Maus den Cursor hält, aber Peace trotzdem Screenshots beim Scrollen macht, der HUD-Chip Nachlauf als Tastatur zeigt, Scroll hart stirbt und Pinch über Text nichts selektiert: `driveScroll` hat `peaceSince` geleert, `drivePeace` hat ihn im selben Frame neu gestartet. HUD hat nur Maus/Tastatur. Scroll-Ticks endeten am Lift. AX-Hit-Test jeden Frame, nur Button/Slider.

1. **Peace-Hold nach Scroll.** `nil` in den ersten 400 ms, dann 1,2 s, sonst 0,9 s.
2. **HUD-Chip Nachlauf.** `CoordMath.clutchChip` — nicht TASTATUR×400.
3. **Scroll-Coast 180 ms.**
4. **Warp-Guard 80 px** auf den ersten zwei Post-Clutch-Frames.
5. **Textauswahl** ab 0,08 Handbreiten über dem Textkörper (HID, nicht AX-Fenster).
6. **Magnet-Rollen + 30 ms Cache.** Tab/Menü/Stepper.
7. **HUD-Pin im Focus-Poll.** Konsole wandert, Overlay folgt.
8. **Screenshot auf Cursor-Schirm.**

## In 1.6.10 erledigt

Warum 1.6.9 nach der Maus den Cursor trotzdem warpt, mit einer Hand nicht scrollt und das HUD auf dem falschen Schirm liegt: `placeCursor` hat während `mousePaused` `lastPalm`/`cursorSmooth` weiterintegriert. `allowsInjection` wurde im Frame nach `pauseUntil` wieder true. `driveScroll` wollte zwei offene Palmen. Overlay-Chrome hing an `NSScreen.main`. Pinch neben dem Schließen-Knopf hat um 4 px daneben geklickt.

1. **Clutch-Exit-Grace 150 ms.** Injektion bleibt tot; HUD „Nachlauf“.
2. **Pointer-Resync.** Während Clutch Hardware-Cursor, keine Palm-Deltas.
3. **Ein-Hand-Zwei-Finger-Scroll.** Peace, zweite Hand palm-unten oder fehlt.
4. **HUD auf Konsolen-Schirm.** Kalibrierung nimmt den Schirm des Helios-Fensters.
5. **4 px AX-Magnet.** Stillgehaltener Pinch rastet auf Schließen/Mini/Zoom/Slider.

## In 1.6.9 erledigt

Warum 1.6.8 sich nach der Maus und über Text trotzdem falsch anfühlte: `mousePaused` hat nur das Label gesetzt, `driveGrab` lief weiter, Pinch während Clutch wurde zum Klick. Pinch + 0,18 Handbreiten über Safari-Text hat das Fenster gegriffen. Palm-unten hat 0,6 s gewartet und trotzdem mitgescrollt.

1. **Clutch schluckt Pinch.** Kein Folge-Klick/Drag nach „Maus hat Vorrang“. Finger müssen erst wieder offen sein.
2. **Hover-Intent 200 ms Titelleiste (36 pt).** Pinch über Text stiehlt kein Fenster.
3. **Ghost-Cursor.** Gestrichelter Ring „GEIST“ während Clutch, nicht wie ein live Cursor.
4. **Kalibrier-Log 9 Punkte** (nicht „4 Ecken“). HUD-Prompt: Fenster auf den gemeinten Schirm ziehen.
5. **Palm-unten raus aus Zwei-Hand-Scroll.** Rest-Hand zählt nicht als Scroll-Partner.

## In 1.6.8 erledigt

Warum 1.6.7 sich in dunklen Zimmern und mit zwei Händen trotzdem tot anfühlte: `placeCursor(actor)` hat den Dominant-Lock unterlaufen, 3D-Peace hatte keinen Spreizungs-Term, luma < 0,20 hat Scroll mitblockt, und nach Aufnahme war 4 s Stille ohne Chip.

1. **Cursor auf Primary.** Zweite Hand greift/peace’t, stiehlt den Zeiger nicht.
2. **3D-Peace + Spreizung + Daumen-an-MCP**, analog 2D. Fusion bringt Victory beim Zeigen nicht zurück.
3. **Low-Light weich.** < 0,20: Klick/Greifen/Peace/Werfen raus, Scroll/Wischen an. 0,20–0,28 nur Klick dämpfen.
4. **Peace-Cooldown-Chip** 4 s (sonst „tot“).
5. **Kalibrier-Undo** des letzten Samples/Skips.
6. **Clutch-Restzeit-Ring** am Cursor, Label mit ms.
7. **AX unter der Hand.** `beginWindowDrag` fällt nicht auf frontmost, wenn ein CGWindow unter dem Cursor existiert.
8. **80 ms Pinch-Jitter-Floor** nach Drag-Start (< 4 px kein `updateWindowDrag`).

## In 1.6.7 erledigt

Warum 1.6.6 das Fenster anfasste und dann stehen ließ: `driveGrab` hat die schließende Klammer nach `beginWindowDrag` verloren. `updateWindowDrag` hing im `if pinchBecameDrag, !isDragging` — nach dem ersten erfolgreichen Griff nie wieder.

1. **`driveGrab`-Klammer.** `updateWindowDrag` läuft jeden Frame, solange `isDragging`. Das Fenster folgt der Hand.
2. **AX-Drag hart abbrechen**, wenn das Profil Greifen blockt, während `isDragging` schon true ist (App-Wechsel mitten im Zug).
3. **`dominantLostAt` / `lastPreferred` im `reset()`.** Lock-Hysterese überlebte Idle und stahl den Cursor nach Not-Aus.
4. **RMSE live** während der 9 Punkte, sobald ≥ 4 Samples da sind — nicht erst am Ende.
5. **Punkt überspringen.** Ecke hinter dem MacBook-Deckel fällt raus; Homographie aus den restlichen Paaren (`gridIndices`).
6. **Peace-Hold-Ring** am Cursor (0,9 s `strokeEnd`) plus Prozent in der Top-Bar.
7. **Clutch-LED.** „Maus hat Vorrang“ / „Tastatur 400 ms“ im HUD, nicht nur im Log.
8. **HUD-Kompass.** Pro Monitor grün/rot, ob `helios.spaceMap.{id}` existiert.
9. **Palm-unten-Rest.** Offene Hand, Finger nach unten, 0,6 s → Idle ohne Kill-Latch.
10. **Low-Light-Gate.** `luma < 0,20` blockt Systemaktionen, Cursor bleibt.

## In 1.6.6 erledigt

1. **Session-Replay im HUD.** `gesten.jsonl` Frame für Frame, Play/Pause/Slider — ohne Xcode.
2. **Profil-Katalog JSON.** `helios.profiles.json` plus Bundled-Default (inkl. `invertScroll`). Editor-Overrides bleiben Extra/Blocked.

## In 1.6.5 erledigt

Warum 1.6.4 sich in Safari und beim Zeigen trotzdem falsch anfühlte: Greifen umging `perform()`, Peace feuerte beim Zwei-Finger-Point, Deadzone war absolut, Clutch nur ein Zeitfenster.

1. **`driveGrab` über `perform("Greifen")`.** Safari-Profil blockt AX-Drag. Vorher `beginWindowDrag` direkt.
2. **Peace vs. Point.** Daumen-an-MCP und enge Finger senken Peace-Logits; Spreizung hebt sie.
3. **Palm-Deadzone `0,025 · palmWidth`.** unit 0,12 bleibt 0,003; nah an der Kamera größer.
4. **Kalibrier-RMSE.** Ungeklammerte Reprojektion. > 12 px: „Mitte nochmal“.
5. **Display-Reconfig.** `NSApplication.didChangeScreenParametersNotification` lädt `helios.spaceMap.{id}`.
6. **Per-App Scroll-Richtung.** Browser invertieren by default; Toggle im Profil-Editor.
7. **HID-Stempel** `eventSourceUserData = 'HELI'` plus PID-Fallback. 120-ms-Fenster bleibt Backup.

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

- **Shift-Klick.** Faust der zweiten Hand während Pinch = Shift+Klick (Finder/Xcode-Mehrfach).
- **I-Beam.** Magnet auf AXTextArea zeigt Text-Cursor, nicht den Pfeil.
- **Peace-Region.** `screencapture -R` wenn kein Fenster unter der Hand.
- **Rechtsklick-Hold 140 ms vs. Text-Drag:** Ringfinger-Pinch darf keine Auswahl starten.
- **Horizontal-Invert getrennt.** Safari-History (wheel2) nicht denselben XOR wie Seitenscroll.

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
- **Aegis-Bridge.** Eine Kamera-Session, zwei Consumer — TCC nur einmal.
- **Blick (wenn das SDK es hergibt)** disambiguiert welches Fenster gemeint ist, bevor AX rät.
- **Stage-Manager-Spaces.** Ein SpaceMap pro `CGSSpace`, sonst springt der Cursor nach Space-Wechsel.
- **Continuity-Desk-View.** Wenn die iPhone-Kamera als Continuity hängt, HUD-Vorschau spiegeln wie die Frontkamera.
- **Zwei-Hand-Rotate.** Gegenläufige Palmen um die gemeinsame Mitte = Fenster drehen (nur wo AX es hergibt).
- **Desk vs. Couch.** Ein Gain-Profil für 40 cm Kameraabstand, eines für 1,5 m — palmWidth wählt.
- **Pointer-Trail im HUD.** Letzte 12 Palm-Punkte als Debug, aus by default.
- **Accessibility-Zoom folgt.** Wenn Zoom an ist, bewegt die Palme den Fokus-Rect, nicht den 1:1-Cursor.
- **Per-Space Homography.** Nach Mission-Control-Wechsel die Karte des aktiven Space, nicht die des Displays.
- **Haptic über Trackpad**, wenn ein Klick sitzt (Force Touch, aus by default).
- **Menu-Bar Extra.** Helios-Menü ohne HUD: Scharf/Idle, letzte Aktion, luma.
- **Per-App Pointer-Gain.** Xcode feiner, Finder grober — analog invertScroll.
- **Edge-Rail Snap während Drag.** Langsames Pinch an der Bildschirmkante dockt, ohne Werfen.
- **Zwei-Display-Warp.** Unkalibrierter Zweitmonitor interpoliert aus dem kalibrierten, statt Relativsprung.
- **Session-Heatmap.** Palm-Dichte über 5 min als Debug, wo die Homographie wehtut.
- **Siri-Remote / Stream Deck** als zweiter Kill-Pfad, wenn die Kamera zu ist.
- **Hands-over-keyboard detector.** Tastatur-Clutch länger, solange Handgelenke über der Tastatur sind (Körperpose).
- **Auto-Gain aus palmWidth-Histogramm.** Session lernt 40 cm vs. 1,5 m, ohne Desk/Couch-Toggle.
- **Farbblinden-HUD.** Cyan/Amber zusätzlich mit Form (Ring/Raute), nicht nur Farbe.
- **Gesten-Makro-Recorder.** Eine Sequenz aufzeichnen, als Profil-Extra speichern.
- **Bezel-Warp.** Unkalibrierter Nachbarschirm interpoliert den Cursor über die Naht, statt Relativsprung.
- **Ruhe-Pose als Modifier-Lock.** Palm-unten an der nicht-dominanten Hand = Scroll-only, Klick tot.
- **Kalibrier-Heatmap nach 9 Punkten.** Welche Zelle RMSE > 12 px hat, dort nochmal.
- **Clutch-Statistik.** Wie oft Maus vs. Geste gewinnt — Gain zu hoch, wenn Clutch dauernd feuert.
- **Scroll-Gain aus palmWidth-Histogramm der Peace-Hand**, analog Desk/Couch.
- **Kalibrier-Schirm merken.** Nach Reconfig HUD wieder auf denselben Display-ID, nicht neu raten.
- **Edge-Rail während Text-Drag aus.** Sonst dockt eine Auswahl am Bildschirmrand.
- **Pinch-Klick vs. Text: Dwell 80 ms** bevor HID-Down, sonst Doppelklick-Ghost in Inputs.
- **AX-SelectedText lesen** nach Text-Drag, in die Zwischenablage nur auf Extra-Geste (nicht still).
- **Scroll-Coast an palmeWidth.** Große Peace-Hand = längerer Nachlauf, kleine = kürzer.
- **HUD-Kompass blinkt**, wenn der Konsolen-Schirm keine SpaceMap hat und der Cursor dort ankommt.
- **Rechtsklick-Hold 140 ms vs. Text-Drag:** Ringfinger-Pinch darf keine Auswahl starten.
- **Mission-Control drei Finger** hinter Extra-Schalter, sobald Peace/Scroll entzerrt ist.
- **Per-App Text-Drag aus.** Terminal/Xcode-Vim: Pinch bleibt Klick, keine Selection.

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
- Greifen wieder an `perform()` vorbei (`beginWindowDrag` direkt).
- Peace-Logits ohne Daumen- und Spreizungs-Term.
- `updateWindowDrag` wieder in den begin-if nesten.
- `dominantLostAt` im Reset vergessen.
- `placeCursor(pinchActor)` — zweite Hand stiehlt den Zeiger.
- luma < 0,20 wieder alle Systemaktionen inkl. Scroll.
- `beginWindowDrag` wieder `?? frontWindow()`, wenn ein CGWindow unter der Hand liegt.
- 3D-Peace ohne Spreizung (Fusion bringt Victory-on-Point zurück).
- Pinch während Clutch als Klick nach der Pause.
- `beginWindowDrag` über Textkörper, ohne Titelleisten-Hover.
- Palm-unten in denselben Scroll-Pool wie offene Handflächen.
- Kalibrier-Log wieder „4 Ecken“ nach 9-Punkt-DLT.
- `placeCursor` während Clutch (warpt den Zeiger nach der Pause).
- Injektion im ersten Frame nach `pauseUntil` ohne 150 ms Grace.
- HUD-Chrome hart an `NSScreen.main` klemmen, wenn die Konsole auf einem anderen Schirm sitzt.
- Peace-Hold während aktivem Zwei-Finger-Scroll als Aufnahme feuern.
- Nachlauf-Chip wieder als TASTATUR labeln.
- Scroll ohne 180 ms Coast (stirbt hart).
- Warp-Guard weglassen und Palm-Integral nach Clutch wieder durchlassen.
- Text-Pinch wieder als Fenstergriff über dem Textkörper.
- AX-Hit-Test jeden Frame ohne Cache.
- Magnet nur auf Button/Slider (Tabs und Menüs daneben klicken).
- Slider-Magnet nach 0,18 Handbreiten loslassen (Zitter-Drag).
- Peace-Cooldown 4 s nach fehlgeschlagenem Screenshot.
- Zwei-Finger nur vertikal (Browser kann nicht seitwärts).
- Text-Drag über AXButton/Toolbar weiterziehen.
- Tasten-Clutch nur auf den ersten `keyDown` (Repeat und Modifier durchlassen).
- Natural-Scroll des Systems ignorieren und Profil doppelt invertieren.

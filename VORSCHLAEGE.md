# Helios — Vorschlagsliste

Stand: **1.5.8**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes.

## In 1.5.8 erledigt

1. **Build-Bruch.** `LandmarkSmoothing` nutzte `AspectSpace`/`JointGeom`, die Dateien lagen nicht im Xcode-Target — 1.5.7 kompiliert nicht. Fusion-Dateien sind jetzt im Target.
2. **Fusion verdrahtet.** 2D + 3D-Lift + Temporal → `EstimateFusion` → `PoseHMM`. Vorher tot im Ordner, Erkennung blieb die alte If-Kette.
3. **1–2 Frames Dropout** beenden Drag/Klick nicht mehr (180 ms Hold).
4. **PinchGate.** Fehlende Spitzen halten max. 0,32 s zu, nicht ewig — Drag klebt nicht.
5. **Not-Aus und Zwei-Pinzetten** lassen den Cursor weiterlaufen.
6. **Scroll.** Zwei offene Hände vertikal.
7. **Rechtsklick.** Pinzette + Ringfinger kurz.
8. **Dwell-Klick.** Optional, offene Hand 1 s still.
9. **HUD:** Idle-Banner nach Not-Aus, Latenz-Sparkline, Fusion-Streifen.
10. **Fusion/HMM/Temporal reset** wenn eine Hand aus dem Bild fällt — sonst klebt die alte Pose am nächsten Auftauchen.

## In 1.5.7 erledigt (nicht nochmal bauen)

1. AX-Hit-Test und Snap in Cocoa statt Quartz
2. Wischen nur als Flick, nicht als Cursor-Führen
3. Faust-Scharf ohne Folge-Klick (`armedQuietUntil`)
4. Cooldown friert den Cursor nicht ein
5. Not-Aus langsamer und strenger
6. Zwei-Pinzetten-Wait belegte den Tick nicht
7. Doppelte Chirality teilte sich den One-Euro-Smoother
8. Hardware-Maus nur über `leftMouseDragged` erkannt
9. `reset()` ließ Kill/Peace/Cooldown liegen
10. Peace zu kurz (0,55 s)

## Nächste Fixes (klein, hoher Nutzen)

- **Per-App-Profile.** Safari: nur Klick/Scroll. Finder: Werfen/Papierkorb. Xcode: aus.
- **Kalibrierung merken pro Display-ID**, nicht nur ein Homography für alle Schirme.
- **SpaceMap hybrid:** nur in den äußeren 15 % absolut, innen Trackpad-Relativ.
- **Maus-Clutch ignoriert eigene CGEvents** härter (delta=0 Filter) — bei <12 fps kann `mouseMoved` Helios selbst pausieren.
- **Chirality über Körperpose**, wenn Vision L/R vertauscht (`VNDetectHumanBodyPose`).
- **Zwei-Pinzetten Skalieren** an gegenüberliegenden Fensterkanten, nicht am Palmenabstand.
- **Pointer-Beschleunigung** wie Trackpad (nichtlinear), damit Feinzielen in der Bildschirmmitte nicht zittert.
- **Session-Replay** der Landmark-CSV direkt im HUD, Frame für Frame — ohne Xcode.

## Größere Erweiterungen

- **Developer ID + Notarisierung.** Ohne das muss TCC nach jedem Update neu an.
- **VoiceOver-Ansage** der letzten Aktion, ausgeschaltet by default.
- **Fenstertiling über Stage Manager** statt nur AX-Snap.
- **Swift Testing** in Xcode, Gesten-Zeitreihen als Fixtures.
- **LiDAR/TrueDepth** (`DepthCapture`) verdrahten, sobald ein Mac es hat — Datei existiert, Session nicht.
- **Echtes Temporal-CoreML** (`HeliosTemporal.mlmodel`) statt Heuristik.
- **Zoom/Trackpad-Magnify** als Geste (Pinzette + offene zweite Hand).
- **Mission Control / Schreibtisch.** Drei Finger hoch / runter, hinter Extra-Schalter.
- **Apple Watch als Not-Aus.** Krone oder Action-Taste tötet Injektion, wenn die Kamera die Hände nicht sieht.
- **Umgebungslicht → HUD.** Bei dunklem Schreibtisch Overlay dämpfen, nicht den Bildinhalt überstrahlen.

## Nicht tun

- Stimme / Diktat als Geste — kollidiert mit Kill und Peace.
- Mehr als zwei Hände. Vision max. 2 ist die ehrliche Grenze.
- Cursor während Pinch-Hold einfrieren (war Absicht für Klick-Zielen — bleibt).
- Fusion-Dateien wieder aus dem Target nehmen.

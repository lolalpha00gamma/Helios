# Helios — Vorschlagsliste

Stand: **1.5.7**. Die Punkte unten sind Erweiterungen, kein Backlog der schon gelandeten Fixes.

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

- **Rechtsklick.** Pinzette + Ringfinger oder drei Finger kurz → `rightMouse`.
- **Scroll.** Zwei offene Hände vertikal, oder eine Faust + offene Hand. Getrennt von Wischen.
- **Mission Control / Schreibtisch.** Drei Finger hoch / runter, hinter einem Extra-Schalter.
- **HUD-Latenz.** Letzte 30 Frames als Sparkline im Panel — sonst bleibt 200 ms unsichtbar.
- **Kill-Bestätigung.** Nach Not-Aus 0,4 s Overlay „Idle“, damit klar ist warum nichts mehr geht.
- **Per-App-Profile.** Safari: nur Klick/Scroll. Finder: Werfen/Papierkorb. Xcode: aus.
- **Kalibrierung merken pro Display-ID**, nicht nur ein Homography für alle Schirme.

## Größere Erweiterungen

- **Dwell-Click** als Alternative zur Pinzette (Accessibility).
- **Körperpose** (`VNDetectHumanBodyPose`) zur Chirality, wenn Vision L/R vertauscht.
- **Relative + absolute Mischung:** SpaceMap nur in den äußeren 15 %, innen Trackpad-Relativ — weniger Ecken-Jagd.
- **Swift Testing** in Xcode, nicht nur `swiftc`-Main-Tests. Gesten-Zeitreihen als Fixtures.
- **Developer ID + Notarisierung.** Ohne das muss TCC nach jedem Update neu an.
- **VoiceOver-Ansage** der letzten Aktion, ausgeschaltet by default.
- **Fenstertiling über Stage Manager** statt nur AX-Snap, sobald die API stabil ist.

## Nicht tun

- Stimme / Diktat als Geste — kollidiert mit Kill und Peace.
- Mehr als zwei Hände. Vision max. 2 ist die ehrliche Grenze.
- Cursor während Pinch-Hold einfrieren (war Absicht für Klick-Zielen — bleibt).

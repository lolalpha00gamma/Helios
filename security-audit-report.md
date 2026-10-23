# Security- und Bugfix-Audit: Helios

**Datum:** 2026-10-23
**Dateiinventar zu Beginn:** 90 Dateien (ohne Git-/Build-/Cache-Verzeichnisse).

## Ergebnis

Drei bestätigte Probleme wurden behoben: unzureichende Modellintegrität, öffentliche dynamische Logs und zu weitgehendes Löschen von Dateiattributen. Bestehende Änderungen aus anderen Arbeiten werden nicht in den Audit-Commit aufgenommen.

## Methode und Grenzen

Alle inventarisierten Dateien wurden byteweise eingelesen und nach Dateityp erfasst; Textdateien wurden automatisiert auf relevante Muster und parsebare Konfigurationen geprüft. Manuelle Prüfung konzentrierte sich auf Eingabegrenzen, Berechtigungen, Netzwerk-/Dateidatenflüsse, Fehlerpfade und die Änderungen. Binärdateien wurden nicht dekompiliert. Dies ist kein Nachweis einer vollständigen manuellen Prüfung jeder Codezeile und keine Garantie auf Fehlerfreiheit.

Nach mehreren Korrekturrunden erfolgten drei aufeinanderfolgende Nachprüfungen: A – Dateiintegrität/Syntax/Konfiguration; B – erneutes Einlesen und Prüfung der betroffenen Sicherheitsdatenflüsse; C – erneuter Gesamtdatei-Scan, Exploit-Ketten und Abgleich mit den Regressionsergebnissen. Dabei wurden keine weiteren bestätigten Befunde im beschriebenen Prüfumfang gefunden. Offene Befunde und Testgrenzen bleiben ausdrücklich bestehen.

## Befunde und Korrekturen

### H1 · MEDIUM · Modell akzeptiert ohne Inhaltsprüfung

- **Status:** behoben
- **Datei:** [windows/helios/model_asset.py](/Users/linusludwig/Documents/Dev/Helios/windows/helios/model_asset.py:10)
- **Klasse:** CWE-494
- **Befund/Voraussetzung:** Bisher genügte die Existenz eines gebündelten Modells bzw. eine Mindestgröße im Cache. Ein beschädigtes oder ersetztes Modell wurde an den nativen Parser weitergegeben; eine Parser-Ausnutzung wurde nicht nachgewiesen. Der gemeinsame .part-Pfad war außerdem rennanfällig.
- **Korrektur:** Version 1 des offiziellen MediaPipe-Modells, exakte Größe und SHA-256 festlegen; Download begrenzen, eindeutige temporäre Datei nutzen, erst nach vollständiger Prüfung atomar veröffentlichen. Gebündelte Modelle und Cache ebenfalls prüfen; LOCALAPPDATA beachten.

### H2 · MEDIUM · Dynamische Logdaten öffentlich markiert

- **Status:** behoben
- **Datei:** [macos/Helios/AuditLog.swift](/Users/linusludwig/Documents/Dev/Helios/macos/Helios/AuditLog.swift:43)
- **Klasse:** CWE-532
- **Befund/Voraussetzung:** Gerätenamen und weitere variable Inhalte konnten im Systemlog ohne Privacy-Redaktion erscheinen. Zugriff auf diese Logs ist Voraussetzung.
- **Korrektur:** Dynamischen Text als private markieren. Die feste Ereigniskategorie bleibt öffentlich; ausdrücklich ausgelöste Exporte bleiben unverändert.

### H3 · LOW · Installation entfernte alle erweiterten Dateiattribute

- **Status:** behoben
- **Datei:** [macos/Helios/AppInstall.swift](/Users/linusludwig/Documents/Dev/Helios/macos/Helios/AppInstall.swift:161)
- **Klasse:** CWE-732 / Integrität von Metadaten
- **Befund/Voraussetzung:** xattr -cr entfernte rekursiv auch Metadaten, die mit der beabsichtigten Quarantänebehandlung nichts zu tun haben.
- **Korrektur:** Löschen auf com.apple.quarantine beschränken.

## Kombinierte Exploit-Ketten

Ein ersetztes Modell erreicht einen nativen ML-Parser. Ohne nachgewiesene Parserlücke ist dies keine belegte RCE-Kette und wird nicht als kritisch ausgewiesen. Die neue Inhaltsprüfung unterbindet unbemerkten Inhaltswechsel beim Laden unter dem normalen Benutzer-/Cache-Vertrauensmodell.

## Validierung

macOS-Debug-Build erfolgreich. Bestehende eigenständige Swift-Prüfungen CoordTests, SpaceMapTests und GestureTests erfolgreich. Windows-Klassifikator-Test erfolgreich; zwei neue Python-Tests für kurze, überlange, inhaltlich falsche Downloads, korrekten Cache, Fehlererhalt und temporäre Bereinigung erfolgreich. Kein Windows-Rechner oder Kamera-/Eingabehardware getestet; das Xcode-Scheme enthält keine Test-Targets.

Logs, Ausgangsinventar und Sicherung der ursprünglichen Dateien liegen in `/tmp/codex-audit-20261023/`; dieser temporäre Pfad ist kein dauerhaftes Beweisarchiv. Tests wurden mit Xcode 27.1 RC ausgeführt.

## Verbleibende Risiken

Python-Abhängigkeiten sind weiterhin Mindestversionen ohne vollständige Lockdatei. Es wurde kein vollständiger aktueller CVE-Scan aller transitiven Pakete ausgeführt; keine sichere Versionskombination für Windows behauptet. Der bestehende Release-Workflow lädt weiterhin latest; die Laufzeit akzeptiert ausschließlich den gepinnten Inhalt und lädt bei Bedarf Version 1 nach. Workflow-Änderungen und Releases waren laut Projektregeln nicht Teil dieser Arbeit. Die bestehende automatische Quarantäneentfernung bleibt Produktverhalten. Gegen einen Angreifer mit Schreibrechten im gleichen Benutzerkontext ist die Pfadprüfung allein keine vollständige Sicherheitsgrenze.

## Git-Status

Audit-Änderungen werden getrennt von bereits vorhandenen Änderungen auf main gestaged. Ein einzelner Commit mit [skip ci] ist vorgesehen; tatsächlicher Push-Status steht im projektübergreifenden Bericht.

## Statistik

| Schweregrad | Befunde | Behoben | Offen |
|---|---:|---:|---:|
| CRITICAL | 0 | 0 | 0 |
| HIGH | 0 | 0 | 0 |
| MEDIUM | 2 | 2 | 0 |
| LOW | 1 | 1 | 0 |

## Modellherkunft

Gepinnte Datei: [MediaPipe hand_landmarker Version 1](https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task), am Audittag aus der offiziellen Quelle gelesen. Größe: 7.819.105 Bytes. SHA-256: `fbc2a30080c3c557093b5ddfc334698132eb341044ccee322ccf8bcf3607cde1`. Dies pinnt den Inhalt; es ist keine unabhängige Sicherheitsbewertung des Modells.

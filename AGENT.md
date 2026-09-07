# Agent-Regeln — Helios

Gilt für jeden Agenten (Grok, Claude, Cursor, Codex) und jeden Menschen an diesem Repo. Verbindlich.

## 0. GitHub Actions Minuten (höchste Priorität)

macOS-Runner rechnen mit Faktor ~10. Jeder Push auf `main` startet `.github/workflows/release-dmg.yml` auf `macos-latest` inklusive Xcode-Build, Sign, Notarize. Agent-Pushes (Grok/Claude) haben den Großteil der Minuten verbraucht.

### Pflicht

1. **Kein Push auf `main`, wenn der Nutzer keinen Commit verlangt.** Lesen und vorschlagen reicht.
2. **Jeder Commit, der kein DMG braucht, trägt `[skip ci]` oder `[ci skip]` in der Commit-Message.** Markdown, Docs, Agent-Dateien: immer skip.
3. **Kein `workflow_dispatch`.** Kein Re-Run des DMG-Jobs, außer der Nutzer sagt ausdrücklich «DMG bauen» / «notarize».
4. **Keine zusätzlichen macOS-Jobs, keine OS-Matrix.** Ein Runner, nur wenn wirklich gebaut wird.
5. **Keine Schedule-Workflows** anlegen.
6. **Keine Pull-Request-Trigger** auf macOS (der Workflow hatte `pull_request` — nicht wieder einschalten, nicht nutzen).
7. **Änderungen bündeln.** Ein Commit statt zehn.
8. **Workflow-YAML nur ändern, um Minuten zu sparen oder wenn der Nutzer es will.** Nie Trigger erweitern.
9. **Kein `timeout-minutes` über 25** ohne Nutzerauftrag (Notarize braucht Wartezeit, trotzdem deckeln).
10. **Lokaler Build bevorzugen.** Sign/Notarize auf GitHub nur auf ausdrücklichen Release-Wunsch.

### Erlaubt ohne Skip nur wenn

- der Nutzer ausdrücklich `Helios.dmg` / Release / Notarize verlangt, **und**
- Swift/Xcode/Entitlements/Projekt betroffen sind.

### Verboten

- Push nur damit CI baut
- zweiten macOS-Workflow anlegen
- Actions-Runs über die API starten
- PR öffnen «damit der Mac-Job läuft»

## 1. Branch-Regel

1. Alle Arbeit nur auf `main`.
2. Keine Feature-/Agent-Branches (`bugfix`, `feature/*`, `fix/*`, `claude/*`, `grok/*`, `cursor/*`, `codex/*`, `agent/*`).
3. Kein Push auf einen anderen Ref als `refs/heads/main`.
4. Keine Pull-Requests als Arbeitsweg.
5. Nebenbranches nicht fortsetzen.

Wenn ein Tool einen Branch erzwingen will: ablehnen. Dateien direkt auf `main` schreiben.

## 2. Dateien dieser Policy

- `AGENT.md` — kanonisch
- `agent.md` — Kurzverweis
- `CLAUDE.md` — dieselben Constraints für Claude Code

# CLAUDE.md — Helios

Lies zuerst `AGENT.md`. Die Regeln dort sind bindend.

## Actions-Minuten — für Claude zwingend

Dieses private Repo verbraucht GitHub Actions Minuten vor allem durch Agent-Pushes auf `main`. Der Workflow `Helios.dmg` läuft auf **jedem** Push nach `main` auf `macos-latest` (Build, Sign, oft Notarize). Eine echte Minute kostet ~10 Abrechnungsminuten.

Du (Claude) darfst:

- Dateien lesen, analysieren, Diffs vorschlagen
- nur dann committen/pushen, wenn der Nutzer das ausdrücklich will
- bei jedem nicht-DMG-Commit `[skip ci]` in die Message schreiben
- Markdown und Agent-Dateien immer mit `[skip ci]` pushen

Du darfst nicht:

- `workflow_dispatch` oder Re-Runs auslösen
- neue macOS-Jobs oder eine OS-Matrix anlegen
- `on: schedule` oder `pull_request` für den DMG-Job setzen
- PRs oder Nebenbranches anlegen
- «mal eben pushen, damit CI baut»
- mehrere Mini-Pushes statt eines gebündelten Commits

DMG/Notarize auf GitHub-hosted macOS nur, wenn der Nutzer wörtlich ein Image / Release verlangt.

Default-Branch: nur `main`.

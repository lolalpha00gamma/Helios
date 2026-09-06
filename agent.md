# Agent-Regeln — nur `main`

Diese Datei gilt für jeden Agenten, jedes Tool und jeden Menschen, der an diesem Repository arbeitet. Sie ist verbindlich.

## Pflicht

1. **Alle Arbeit findet ausschließlich auf `main` statt.** Commit und Push gehen nur nach `main`.
2. **Keine Abzweigungen.** Es dürfen keine Feature-, Fix-, Agent- oder Tool-Branches angelegt werden. Das schließt unter anderem ein: `bugfix`, `feature/*`, `fix/*`, `claude/*`, `grok/*`, `cursor/*`, `codex/*`, `agent/*`.
3. **Keine separaten Pushes.** Kein Push auf einen anderen Ref als `refs/heads/main`. Keine Forks als Arbeitskopie.
4. **Keine Pull-Requests als Arbeitsweg.** Änderungen werden direkt auf `main` committed. PRs aus Nebenbranches sind verboten.
5. **Bestehende Nebenbranches sind Altlast.** Nicht darauf weiterarbeiten. Fehlende Lösungen von dort — falls noch nicht auf `main` — als direkten Commit auf `main` nachziehen. Den Nebenbranch nicht fortsetzen und keinen neuen anlegen.

## Verboten

- `git checkout -b …` / `git switch -c …`
- `git push origin <nicht-main>`
- GitHub: Create branch, Compare & pull request als Arbeitsweg
- Temporäre Agent-Branches, auch wenn das Tool das als Default vorschlägt

## Wenn ein Tool einen Branch erzwingen will

Ablehnen. Dateien direkt auf `main` schreiben (Commit auf `main`). Keinen Workaround-Branch anlegen.

## Default-Branch

`main` ist der einzige erlaubte Arbeitsbranch.

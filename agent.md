# Agent-Regeln — nur `main` + sparsame Actions

Kanonisch: `AGENT.md` und `CLAUDE.md`.

## Actions (kurz)

- Kein Push ohne ausdrücklichen Nutzerwunsch.
- Jeder Commit ohne DMG-Bedarf: `[skip ci]` in der Message.
- Kein `workflow_dispatch`, keine macOS-Matrix, kein cron, kein PR-Trigger.
- macOS-Runner nur für echtes Release, sonst lokal bauen.

## Branch

1. Alle Arbeit ausschließlich auf `main`.
2. Keine Abzweigungen (`bugfix`, `feature/*`, `fix/*`, `claude/*`, `grok/*`, `cursor/*`, `codex/*`, `agent/*`).
3. Kein Push auf einen anderen Ref als `refs/heads/main`.
4. Keine Pull-Requests als Arbeitsweg.
5. Nebenbranches nicht fortsetzen.

Wenn ein Tool einen Branch erzwingen will: ablehnen. Dateien direkt auf `main` schreiben.

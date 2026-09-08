# Helios Vorschläge — 2026-09-08 (Pass 3, 1.6.43)

Stand 1.6.43 / Build 76. Ergänzung, keine Kopie der erledigten Fusion/Retry/Q/Drag/Leiter-Fixes.

## Gelandet in 1.6.43 (dieser Pass)

Format-Leiter 720p@24 → 960p@15 → 640p@30. PinchHoldPhase Math. pointerWarpAllowed fail-closed. Kein viertes `*Need(dt)`.

## Erweiterung (neu, nicht in der 1.6.42-Liste)

66. **PinchHoldPhase in GestureEngine** — Gate/HMM lesen Phase, nicht Bool.
67. **DisplayLink 90 Hz** HUD unabhängig von Detect 8 Hz. P1.
68. **CameraBroker XPC + IOSurface** mit Aegis. P0.
69. **uniqueID sticky** Continuity-Reconnect ohne Homographie-Reset.
70. **Clutch-Radius × backingScaleFactor** Retina vs 1x.
71. **AX-Hit-Cache × Fenster-ID** Resize während Freeze sonst tot.
72. **Two-pinch vs scroll hysteresis** Coast darf Pinch-Start nicht fressen.
73. **JSONL Session-Replay** Gesten-Regression ohne Vision auf Linux-CI.
74. **Watch-IMU Pinch-Confirm** wenn Vision-Spitzen tot.
75. **SpaceMap Re-Calib** Palm-Aspect nach Drehung.

P0 CameraBroker. P1 DisplayLink. P2 PinchHoldPhase verdrahten. Kein 1.6.44-dt-Pflaster ohne eines davon.

# Helios Vorschläge — 2026-09-08 (Pass 7, 1.6.44)

Stand 1.6.44 / Build 77. Ergänzung, keine Kopie der erledigten Leiter/Phase-Math/AX-Fixes.

## Gelandet in 1.6.44 (dieser Pass)

DisplayLink 90 Hz HUD mit `hudLerpT` (1 Frame Lag, Freeze snap). PinchHoldPhase in GestureEngine (`driveGrab` + `dropPinchHold`). Kein viertes `*Need(dt)`.

## Erweiterung (neu, nicht in der 1.6.43-Liste)

76. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC, eine Session. P0.
77. **HeliosAegisKit** gemeinsamer Broker + Mutex-PTS.
78. **uniqueID sticky** Continuity-Reconnect ohne Homographie-Reset.
79. **Clutch-Radius × backingScaleFactor** Retina vs 1x.
80. **AX-Hit-Cache × Fenster-ID** Resize während Freeze sonst tot.
81. **Two-pinch vs scroll hysteresis** Coast darf Pinch-Start nicht fressen.
82. **JSONL Session-Replay** Gesten-Regression ohne Vision auf Linux-CI.
83. **Watch-IMU Pinch-Confirm** wenn Vision-Spitzen tot.
84. **SpaceMap Re-Calib** Palm-Aspect nach Drehung.
85. **DepthCapture an Continuity LiDAR** wirklich verdrahten (Datei ist Stub).
86. **HMM liest PinchHoldPhase** statt gate-Bool — Gate ist verdrahtet, PoseHMM noch nicht.
87. **HUD Pose-Chips am DisplayLink** auch wenn Detect 8 Hz friert (Chips folgen noch mark()).
88. **Session-Watchdog** Idle nur fps>0 UND keine Aegis-Face UND 8 s leer.
89. **Pointer-Accel × backingScaleFactor** je NSScreen.
90. **mmap leftover-Boxen** Helios↔Aegis, Palm-Occlusion.

P0 CameraBroker. Kein 1.6.45-dt-Pflaster ohne CameraBroker oder LiDAR-Depth.

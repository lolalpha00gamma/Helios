# Helios Vorschläge — 2026-09-08 (Pass 8, 1.6.45)

Stand 1.6.45. Ergänzung zu 1.6.44 (DisplayLink, PinchHoldPhase in driveGrab).

## Gelandet in 1.6.45

PoseHMM `pinchHeld` + `pinchHoldBoost`. HMM folgt dem Gate, nicht nur der Closedness-EMA.

## Erweiterung (neu)

91. **HandTracker reicht `pinchState.closed` als pinchHeld** in `hmm.step`. Signatur liegt, Call-Site fehlt noch. P0 klein.
92. **`let dt` Shadow in HandTracker** zweite Variable `dtPalm`.
93. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0 groß.
94. **uniqueID sticky** Continuity ohne Homographie-Reset.
95. **Clutch-Radius × backingScaleFactor**.
96. **AX-Hit-Cache × Fenster-ID** während Freeze.
97. **Two-pinch vs Scroll-Hysterese**.
98. **JSONL Session-Replay** ohne Vision auf Linux.
99. **Watch-IMU Pinch-Confirm**.
100. **SpaceMap Re-Calib** nach Drehung.
101. **DepthCapture an Continuity-LiDAR** statt Stub.
102. **HUD Pose-Chips am DisplayLink** unabhängig von mark().
103. **Session-Watchdog** Idle = fps>0 UND keine Aegis-Face UND 8 s leer.
104. **Pointer-Accel × backingScaleFactor**.
105. **mmap leftover-Boxen** Helios↔Aegis Palm-Occlusion.
106. **Format-Leiter nach Drop unter 12 fps neu verhandeln**.
107. **Kalman-Palme während Freeze**.
108. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.

P0: Call-Site pinchHeld, dann CameraBroker. Kein weiteres dt-Pflaster.

# Helios Vorschläge — 2026-09-08 (Pass 9, 1.6.45)

Stand 1.6.45. Call-Site pinchHeld, dtPalm, Format-Retry.

## Gelandet in 1.6.45

- HMM `pinchHeld: pinchState.closed`
- dtPalm = sampleDt
- cameraFormatRenegotiateRetry verdrahtet

## Erweiterung (neu)

91. **uniqueID sticky** Continuity ohne Homographie-Reset. P0 klein.
92. **PTS-Sprung = Freeze** nicht Dropout.
93. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0 groß.
94. **Clutch-Radius × backingScaleFactor**.
95. **AX-Hit-Cache × Fenster-ID** während Freeze.
96. **Two-pinch vs Scroll-Hysterese**.
97. **JSONL Session-Replay** ohne Vision auf Linux.
98. **Watch-IMU Pinch-Confirm**.
99. **SpaceMap Re-Calib** nach Drehung.
100. **DepthCapture an Continuity-LiDAR** statt Stub.
101. **HUD Pose-Chips am DisplayLink** unabhängig von mark().
102. **Session-Watchdog** Idle = fps>0 UND keine Aegis-Face UND 8 s leer.
103. **Pointer-Accel × backingScaleFactor**.
104. **mmap leftover-Boxen** Helios↔Aegis Palm-Occlusion.
105. **lastFormatHeight Reset** nach uniqueID-Wechsel.
106. **Kalman-Palme in HandTracker** während Freeze.
107. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
108. **PinchHold analog** Closedness-Mix, nicht nur Bool.

P0: uniqueID sticky, dann CameraBroker. Kein weiteres dt-Pflaster.

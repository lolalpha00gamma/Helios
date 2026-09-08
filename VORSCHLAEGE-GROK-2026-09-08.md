# Helios Vorschläge — 2026-09-08 (Pass 10, 1.6.46)

Stand 1.6.46. uniqueID sticky, PTS-Freeze, lastFormatHeight, Kalman-Palme.

## Gelandet in 1.6.46

- cameraIDSticky / HomographyResets / SpaceMap.retarget
- ptsJumpIsFreeze + ptsWallStamp
- lastFormatHeightResets + cameraPreferredID (Name, ` · Tiefe` strip)
- HandTracker freezeKalmanPredict + lastVel

## Erweiterung (neu)

91. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0 groß.
92. **Clutch-Radius × backingScaleFactor**.
93. **AX-Hit-Cache × Fenster-ID** während Freeze.
94. **Two-pinch vs Scroll-Hysterese**.
95. **JSONL Session-Replay** ohne Vision auf Linux.
96. **Watch-IMU Pinch-Confirm**.
97. **SpaceMap Re-Calib** nach Display-Drehung, nicht uniqueID-Flicker.
98. **DepthCapture an Continuity-LiDAR** statt Stub.
99. **HUD Pose-Chips am DisplayLink** unabhängig von mark().
100. **Session-Watchdog** Idle = fps>0 UND keine Aegis-Face UND 8 s leer.
101. **Pointer-Accel × backingScaleFactor**.
102. **mmap leftover-Boxen** Helios↔Aegis Palm-Occlusion.
103. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
104. **PinchHold analog** Closedness-Mix, nicht nur Bool.
105. **Continuity 420v-Luma-Sprung = Freeze** (nicht nur PTS).
106. **Sleep/Wake Camera-Recovery** ohne Homographie-Reset.
107. **CGEvent-Tap coalescing 90 Hz**, nicht 8 Hz Vision.
108. **Slot-ID persist** über uniqueID-Flicker (Hand-ID nicht neu minten).
109. **IOHID Force-Click vs Pinch** disambiguieren.

P0: CameraBroker. Kein weiteres dt-Pflaster.

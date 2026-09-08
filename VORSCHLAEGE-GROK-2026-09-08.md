# Helios Vorschläge — 2026-09-08 (Pass 13, 1.6.50)

Stand 1.6.50. Clutch×Scale, AX-Window-Cache, reduced-motion, Vision-Stale, Pinch analog.

## Gelandet in 1.6.50

- clutchOwnRadiusScaled backingScaleFactor
- axWindowCacheHolds Bounds während Coast
- hudCoastAllowed reduceMotion
- visionStale 400 ms FramePump
- pinchAnalog Closedness×zSep

## Erweiterung (neu)

125. **Stereo Mac+iPhone Disparität** statt Lift-z.
126. **Watch Double-Tap** Confirm.
127. **App-Grammar** Safari vs Finder vs Xcode.
128. **JSONL Session-Replay** ohne Vision auf Linux.
129. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
130. **Slot-ID persist** über uniqueID-Flicker.
131. **IOHID Force-Click vs Pinch.**
132. **mmap leftover-Boxen** Helios↔Aegis Palm-Occlusion.
133. **DepthCapture an Continuity-LiDAR.**
134. **CGEvent-Tap coalescing 90 Hz** unabhängig von Coast.
135. **Two-pinch vs Scroll-Hysterese.**
136. **SpaceMap Re-Calib** nach Display-Drehung.

P0: CameraBroker. Kein neues *Need(dt).

# Helios Vorschläge — 2026-09-08 (Pass 12, 1.6.49)

Stand 1.6.49. 720-Lock persist, 24 fps, Click-Vel, HUD-Coast, Per-Display, Body-Skip.

## Gelandet in 1.6.49

- helios.formatHeight + prefers720 phone (Mac 1080)
- cameraLockFps 24
- isDrag palmVelHW Click/Need
- hudCoastPoint + DisplayLink OS-Cursor
- spaceMapDisplayID
- visionSkipsBody 8 fps

## Erweiterung (neu)

118. **Stereo Mac+iPhone Disparität** statt Lift-z.
119. **Clutch-Radius × backingScaleFactor** nach 90 Hz Coast.
120. **AX-Fenster-ID Cache** während Coast.
121. **reduced-motion HUD** ohne Coast.
122. **FramePump Vision-Timeout 400 ms** (VN unkündbar).
123. **Pinch analog** Closedness×zSep.
124. **Watch Double-Tap** Confirm.

P0: CameraBroker. Kein neues *Need(dt).

# Helios Vorschläge — 2026-09-08 (Pass 11, 1.6.48)

Stand 1.6.48. inputPriority, Native 420, Freeze-Cursor, Pinch/AX halten, Wake.

## Gelandet in 1.6.48

- sessionPreset inputPriority / 720p, nie 1080 zuerst
- Native 420 vor BGRA
- freezeDrivesCursor + lastHandsLive.shifted
- emptyHandsHoldDropsPinch / ReleaseAX nur beyondHold
- didWake start() ohne Leiter-Wipe

## Erweiterung (neu)

110. **Click-vs-Drag** Palm-Velocity-Histogramm.
111. **Per-Display SpaceMap** Screen-Wechsel.
112. **720p-Lock persist** UserDefaults.
113. **Pair-Stereo-Tiefe** Mac+iPhone.
114. **Watch Double-Tap** Click-Confirm.
115. **App-Grammar** Safari vs Finder vs Xcode.
116. **HUD reduced-motion.**
117. **Vision-Cancel-Token** bei FramePump-Drop.

P0: CameraBroker. Kein weiteres dt-Pflaster.

# Helios Vorschläge — 2026-09-08 (Pass 10b, 1.6.47)

Stand 1.6.47. start() hält Leiter, lastFormatHeight sticky, Mac nie.

## Gelandet in 1.6.47

- start() ohne lastFormatHeight=1080 Wipe
- lastFormatHeightResets via cameraIDSticky (Mac nie, Osmo ja)
- lastAppliedCameraRole

## Erweiterung (neu)

91. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0 groß.
92. **Clutch-Radius × backingScaleFactor**.
93. **AX-Hit-Cache × Fenster-ID** während Freeze.
94. **Two-pinch vs Scroll-Hysterese**.
95. **JSONL Session-Replay** ohne Vision auf Linux.
96. **Watch-IMU Pinch-Confirm**.
97. **SpaceMap Re-Calib** nach Display-Drehung.
98. **Sleep/Wake Camera-Recovery**.
99. **Slot-ID persist** über uniqueID-Flicker.
100. **DepthCapture an Continuity-LiDAR**.

P0: CameraBroker. Kein weiteres dt-Pflaster.

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

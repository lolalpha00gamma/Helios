# Helios Vorschläge — 2026-09-08 (Pass 20, 1.6.57)

Stand 1.6.57. Predict, Zwei-Hand-Clutch, Stage-Clamp, Hand-Box.

## Gelandet in 1.6.57

- pointerPredict / pointerPredictPoint Cap 48
- twoHandClutch livePalms ≥ 2, nicht Zwei-Pinch
- stageManagerClamp / Offspace visibleFrame
- handBoxFromPalm / handBoxTrackKeeps / Step

## Erweiterung (neu)

206. **USB-C 30 fps Promote** gemessen ≥ 22, nicht cold 30.
207. **VNTrackObjectRequest** echte Hand-Observation.
208. **Fling-Cap × Screen-Höhe.**
209. **Click-Tick Sound.**
210. **Miss-Click Heatmap.**
211. **iPhone Ultraweit FOV.**
212. **Per-Display pointerGain Pref.**
213. **Aegis-Gaze Pinch-Confirm.**
214. **Watch Double-Tap.**
215. **Palm-Vel JSONL** Predict-Tuning.

P0: CameraBroker. Kein neues *Need(dt).

# Helios Vorschläge — 2026-09-08 (Pass 19, 1.6.56)

Stand 1.6.56. One-Euro, 24-fps Kaltstart, Bezel-Hop, Deadman.

## Gelandet in 1.6.56

- oneEuroFilter / oneEuroMinCutoff × jitterRms
- cameraFormatColdStartBias 720@24 > claimed 1080@30
- Cover cameraLockDuration
- bezelHopAllows 80 pt
- palmDeadmanClutch 2 s

## Erweiterung (neu)

196. **VNTrack Hand-Box persist.**
197. **Stage-Manager Space-Clamp.**
198. **Pointer 1-Frame Predict** 8 Hz.
199. **USB-C Wired Continuity.**
200. **Two-Hand Clutch.**
201. **Aegis-Gaze Pinch-Confirm.**
202. **Click-Tick Sound.**
203. **Miss-Click Heatmap.**
204. **iPhone Ultraweit FOV.**
205. **Per-Display pointerGain Pref.**

P0: CameraBroker. Kein neues *Need(dt).

# Helios Vorschläge — 2026-09-08 (Pass 18, 1.6.55)

Stand 1.6.55. Adaptive Gain, HUD-Sharing, Edge-Resistance, Display-Gap.

## Gelandet in 1.6.55

- pointerGainAdaptive / jitterRms
- hudSharingExcluded → NSWindow.sharingType .none
- edgeResistance 0,35 am Rand
- displayGapWarp + stepCursor auf aktuellem Schirm

## Erweiterung (neu)

186. **One-Euro Filter** Cursor min-cutoff × Jitter.
187. **Continuity 24-fps Leiter** bevor 8 Hz.
188. **Bezel-Hop Hysterese** 80 pt.
189. **Stage-Manager Space-Clamp.**
190. **Palm-Deadman 2 s** → Clutch.
191. **iPhone Ultraweit FOV.**
192. **Click-Tick Sound.**
193. **Aegis-Gaze Pinch-Confirm.**
194. **Per-Display pointerGain Pref.**
195. **VNTrack Hand-Box persist.**

P0: CameraBroker. Kein neues *Need(dt).

# Helios Vorschläge — 2026-09-08 (Pass 17, 1.6.54)

Stand 1.6.54. Per-Display Scale, Deadzone×Scale, Scroll-Momentum, Homographie-Rotation, Click-Energy.

## Gelandet in 1.6.54

- ScreenGeometry.backingScale(quartz:) statt NSScreen.main
- deadzoneScaled
- twoPinchScrollMomentum → scrollCoast
- spaceMapRotationKey + HomographyStore.rotation
- clickEnergy / isClick closedness

## Erweiterung (neu)

176. **Adaptive Gain aus Jitter-RMS.**
177. **HUD aus Screen-Capture ausschließen.**
178. **Multi-Display Warp über die Lücke.**
179. **Aegis-Gaze Pinch-Confirm.**
180. **Per-Display pointerGain Pref.**
181. **Window-Edge Resistance.**
182. **Continuity HDR Tone-Map.**
183. **Air-Keyboard Shortcut-Overlay.**
184. **Freeze-Kalman über uniqueID.**
185. **Watch Haptic on Click.**

P0: CameraBroker. Kein neues *Need(dt).

# Helios Vorschläge — 2026-09-08 (Pass 16, 1.6.53)

Stand 1.6.53. Pointer-Gain×Scale, Scroll-Ticks×Scale, Rotation-Nudge, Click-Hitch.

## Gelandet in 1.6.53

- pointerGainScaled backingScaleFactor
- twoPinchScrollTicks scale
- spaceMapRotationNudge / Wipe
- clickHitchNeed / FromFreeze

## Erweiterung (neu)

165. **Per-Display backingScaleFactor** Cursor auf 5K vs Sidecar.
166. **Two-pinch Scroll-Momentum** nach Loslassen.
167. **Homographie-Cache keyed by rotation.**
168. **Deadzone × Scale.**
169. **Click-Energy** statt nur Hold-Dauer.
170. **VNTrack Hand-Box persist** bei Continuity 8 Hz.
171. **Fling-Cap × Screen-Höhe.**
172. **Session-Watchdog** Idle = fps>0 UND keine Aegis-Face UND 8 s leer.
173. **Air-Keyboard Dwell × Scale.**
174. **Overlay CAMetalLayer.**
175. **MediaPipe Hands Fallback.**

P0: CameraBroker. Kein neues *Need(dt).

# Helios Vorschläge — 2026-09-08 (Pass 15, 1.6.52)

Stand 1.6.52. Two-pinch Hysterese, Rotation-Recalib, CGEvent 90 Hz.

## Gelandet in 1.6.52

- twoPinchAxisHysteresis + PrefersScroll
- spaceMapNeedsRecalib / rotation stamp
- sampleCursorYieldsToCoast
- cgEventCoalesceDue 90 Hz

## Erweiterung (neu)

153. **Pointer-Accel × backingScaleFactor.**
154. **VNTrack Hand-Box persist** bei Continuity 8 Hz.
155. **Two-pinch Scroll-Ticks × backingScale.**
156. **SpaceMap Rotation-Nudge** statt Wipe.
157. **Click-Hitch Debounce** Continuity-Miss ≠ Double-Click.
158. **Per-App Scroll-Gain** Safari vs Xcode vs Preview.
159. **Pinch-Hold analog × Kalman-Q** statt Bool-OR.
160. **Fling-Cap × Screen-Höhe.**
161. **Session-Watchdog** Idle = fps>0 UND keine Aegis-Face UND 8 s leer.
162. **Air-Keyboard Dwell × Scale.**
163. **Overlay CAMetalLayer.**
164. **MediaPipe Hands Fallback.**

P0: CameraBroker. Kein neues *Need(dt).

# Helios Vorschläge — 2026-09-08 (Pass 14, 1.6.51)

Stand 1.6.51. Two-pinch vs Scroll, Coast-Cap×Scale, Jiggle×Scale.

## Gelandet in 1.6.51

- scrollAllowed twoPinch + scrollMuteAfterTwoPinch
- hudCoastCapScaled backingScaleFactor
- clutchJiggleScaled

## Erweiterung (neu)

137. **Stereo Mac+iPhone Disparität** statt Lift-z.
138. **Watch Double-Tap** Confirm.
139. **App-Grammar** Safari vs Finder vs Xcode.
140. **JSONL Session-Replay** ohne Vision auf Linux.
141. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
142. **Slot-ID persist** über uniqueID-Flicker.
143. **IOHID Force-Click vs Pinch.**
144. **mmap leftover-Boxen** Helios↔Aegis Palm-Occlusion.
145. **DepthCapture an Continuity-LiDAR.**
146. **CGEvent-Tap coalescing 90 Hz** unabhängig von Coast.
147. **SpaceMap Re-Calib** nach Display-Drehung.
148. **Pointer-Accel × backingScaleFactor.**
149. **Fling-Cap × Screen-Höhe.**
150. **Session-Watchdog** Idle = fps>0 UND keine Aegis-Face UND 8 s leer.
151. **Air-Keyboard Dwell × Scale.**
152. **Overlay CAMetalLayer.**

P0: CameraBroker. Kein neues *Need(dt).

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

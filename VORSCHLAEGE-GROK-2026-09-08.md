# Helios Vorschläge — 2026-09-08 (Pass 30, 1.6.73)

Stand 1.6.73. Zwei Palmen in der Lock-Zeile, Interrupt-Release, Heartbeat ohne Frame, Scroll-Sign.

## Gelandet in 1.6.73

- cameraMutexActorPalms Actor+Clutch, Lock-Zeile zwei UV
- sessionWasInterrupted → releaseCameraMutex
- Mutex-Beat 80 ms ohne Frame
- twoPinchScrollHolds analog Zoom

## Erweiterung (neu)

355. **Mutex flock timeout / lock-free stamp.** EX|NB failt während Aegis LOCK_SH. Fill 220 ms verpasst den Frame. P1.
356. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
357. **VNTrackObjectRequest** echte Hand-Observation, ROI-Miss ohne Full-Retry. P1.
358. **SpaceMap load per Bezel-Hop**, nicht erst 20. Sidecar trägt sonst 5K-H bis RECAL.
359. **Overlay CAMetalLayer.**
360. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
361. **Continuity 15-fps Probe** gemessen, nicht claimed.
362. **Watch Double-Tap** destruktive Klicks.
363. **Click-Tick Sound.**
364. **JSONL Palm-Vel** Predict-Tuning.
365. **iPhone Ultraweit FOV** statt Center-Stage-Crop.
366. **DepthCapture an Continuity-LiDAR.**
367. **Per-Display pointerGain Pref.**
368. **Air-Keyboard Shortcut-Overlay.**
369. **Stereo Mac+iPhone Disparität.**
370. **Pointer-Gain × Continuity-FOV.**
371. **Deadman-Ring** Overlay, nicht nur Clutch.
372. **Homographie Recalib Tipp-Tap** nach RECAL.
373. **Mission-Control Zwei-Palm-Spread.**
374. **Aegis-Gaze Pinch-Confirm.**
375. **Mutex-PTS nur wall, nie last-frame** wenn Beat ohne Sample — Aegis Fill sonst 80 ms hinter dem Continuity-PTS.
376. **drei Palmen** (zweite Clutch + dritte Drop) nur wenn Helios drei Hände trackt.
377. **Scroll-Streak analog Zoom-EdgeHold** — ein gleichsinniger Tick reicht noch für 8 Hz Jitter.

P0: CameraBroker. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.

# Helios Vorschläge — 2026-09-08 (Pass 29, 1.6.70)

Stand 1.6.70. Mutex-Write live, Actor-Palm live, Zoom-Sign am Streak. Predict bleibt 0.

## Gelandet in 1.6.70

- CameraSession beatCameraMutex Unix-PTS + Palme, Heartbeat 80 ms
- mutexActorPalm Steuerhand nur live, nicht Dropout-Coast
- twoPinchZoomHolds am Scale-Streak, lastScaleSign schon im Hold
- MUTEX-Chip ControlPanel

## Erweiterung (neu)

331. **Zwei Palmen in die Lock-Zeile.** Clutch-Hand skippt Aegis-Prints sonst nicht. P1.
332. **Mutex-Release bei sessionWasInterrupted**, nicht nur `stop()`. Continuity-Drop lässt stale Claim. P1.
333. **Mutex Heartbeat ohne neuen Frame** wenn Vision 8 Hz und Aegis LOCK_SH 220 ms den Continuity-Frame verpasst. P1.
334. **twoPinchScrollTicks Vorzeichen-Hold** analog Zoom — Continuity-Jitter scrollt rauf/runter.
335. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
336. **VNTrackObjectRequest** echte Hand-Observation, ROI-Miss ohne Full-Retry. P1.
337. **Overlay CAMetalLayer.**
338. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
339. **Continuity 15-fps Probe** gemessen, nicht claimed.
340. **SpaceMap load per Bezel-Hop**, nicht erst 20. Sidecar trägt sonst 5K-H bis RECAL.
341. **Watch Double-Tap** destruktive Klicks.
342. **Click-Tick Sound.**
343. **JSONL Palm-Vel** Predict-Tuning.
344. **iPhone Ultraweit FOV** statt Center-Stage-Crop.
345. **DepthCapture an Continuity-LiDAR.**
346. **Per-Display pointerGain Pref.**
347. **Air-Keyboard Shortcut-Overlay.**
348. **Stereo Mac+iPhone Disparität.**
349. **Pointer-Gain × Continuity-FOV.**
350. **Deadman-Ring** Overlay, nicht nur Clutch.
351. **Mutex flock timeout / lock-free stamp.** EX|NB failt während Aegis-Read.
352. **Homographie Recalib Tipp-Tap** nach RECAL, nicht nur Reload derselben Palmen.
353. **Mission-Control Zwei-Palm-Spread.**
354. **Aegis-Gaze Pinch-Confirm.**

P0: CameraBroker. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.

# Helios Vorschläge — 2026-09-08 (Pass 28, 1.6.67)

Stand 1.6.67. Pinch×Palme live. Predict bleibt 0, Mutex-Writer bleibt tot (1.6.66 Cursor-Fix).

## Gelandet in 1.6.67

- pinchStartsGrab / pinchHoldsGrab palmWidth = hand.palmWidth
- pinchClosednessNeed palmWidth am Steuerhand-Filter

## Erweiterung (neu)

311. **Mutex-Write zurück.** 1.6.66 löschte `beatCameraMutex`. Aegis PTS-Fill und Palm-skipPrint tot. Ohne Cursor-Pfad, nur CameraSession. P0 für Duo.
312. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
313. **VNTrackObjectRequest** echte Hand-Observation. P1.
314. **Mission-Control Zwei-Palm-Spread.**
315. **Aegis-Gaze Pinch-Confirm.**
316. **Watch Double-Tap** destruktive Klicks.
317. **Click-Tick Sound.**
318. **JSONL Palm-Vel.**
319. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
320. **iPhone Ultraweit FOV** statt Center-Stage-Crop.
321. **DepthCapture an Continuity-LiDAR.**
322. **Per-Display pointerGain Pref.**
323. **Overlay CAMetalLayer.**
324. **Air-Keyboard Shortcut-Overlay.**
325. **Stereo Mac+iPhone Disparität.**
326. **Continuity 15-fps Probe** gemessen, nicht claimed.
327. **Pointer-Gain × Continuity-FOV.**
328. **Deadman-Ring** Overlay.
329. **Actor-Palm in Mutex**, nicht `hands.first`.
330. **twoPinchZoomHolds wieder am Streak** — 1.6.66 setzte `ok: true`.

P0: CameraBroker + Mutex-Write ohne Cursor. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.

# Helios Vorschläge — 2026-09-08 (Pass 26, 1.6.65)

Stand 1.6.65. Mutex-Write, Predict×Schirm, Zoom-Sign, Bezel-Decay, RECAL→SpaceMap.

## Gelandet in 1.6.65

- CameraSession beatCameraMutex Unix-PTS + Palme
- pointerPredictCap × ScreenGeometry.height(quartz:)
- twoPinchZoomHolds am Scale-Streak
- bezelHopDecay 2 s
- consumeBezelHopRecalib → reloadSpaceMap, einmal pro Welle

## Erweiterung (neu)

291. **Mutex PTS lock-free / LOCK_SH stamp.** EX|NB failt während Aegis-Read. Fill 220 ms verpasst den Continuity-Frame. P1.
292. **SpaceMap load per Bezel-Hop**, nicht erst 20. Sidecar trägt sonst 5K-H bis RECAL.
293. **Predict-Cap × backingScaleFactor.** Sidecar 2× Punkte vs Pixel — Cap in pt, Event in px.
294. **Actor-Palm in Mutex**, nicht `hands.first`. Zweite Hand skippt Aegis-Prints falsch.
295. **lastScaleSign schon im Streak.** Erster Zoom-Jitter zählt, Sign sitzt erst nach Fire.
296. **VNTrackObjectRequest** echte Hand-Observation, ROI-Miss ohne Full-Retry. P1.
297. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
298. **Mission-Control Zwei-Palm-Spread.**
299. **Aegis-Gaze Pinch-Confirm.**
300. **Watch Double-Tap** destruktive Klicks.
301. **Click-Tick Sound.**
302. **JSONL Palm-Vel** Predict-Tuning.
303. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
304. **iPhone Ultraweit FOV** statt Center-Stage-Crop.
305. **DepthCapture an Continuity-LiDAR.**
306. **Per-Display pointerGain Pref.**
307. **Overlay CAMetalLayer.**
308. **Air-Keyboard Shortcut-Overlay.**
309. **Stereo Mac+iPhone Disparität.**
310. **Continuity 15-fps Probe** gemessen, nicht claimed.
311. **Pointer-Gain × Continuity-FOV** (Ultraweit vs Crop).
312. **Deadman-Ring** Overlay, nicht nur Clutch.
313. **Homographie Recalib Tipp-Tap** nach RECAL, nicht nur Reload derselben Palmen.

P0: CameraBroker. Kein neues *Need(dt). Branch `bugfix` (1.6.15) nicht mergen.

# Helios Vorschläge — 2026-09-08 (Pass 25, 1.6.63)

Stand 1.6.63. PTS-Wall, Palm-UV, Predict×Schirm, Zoom-Sign, Bezel-20.

## Gelandet in 1.6.63

- cameraMutexPtsWall statt Media-PTS
- cameraMutexPalm x y w vor v2
- pointerPredictCap × ScreenGeometry.height(quartz:)
- twoPinchZoomHolds gleichsinnig
- bezelHopRecalib 20 → RECAL-Chip

## Erweiterung (neu)

271. **VNTrackObjectRequest** echte Hand-Observation, ROI-Miss ohne Full-Retry. P1.
272. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
273. **Mutex-PTS pro Frame** nicht nur Heartbeat 2 s — obsFill Skew 220 ms trifft sonst selten.
274. **Mission-Control Zwei-Palm-Spread.**
275. **Aegis-Gaze Pinch-Confirm.**
276. **Watch Double-Tap** destruktive Klicks.
277. **Click-Tick Sound.**
278. **JSONL Palm-Vel** Predict-Tuning.
279. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
280. **iPhone Ultraweit FOV** statt Center-Stage-Crop.
281. **DepthCapture an Continuity-LiDAR.**
282. **Per-Display pointerGain Pref.**
283. **Overlay CAMetalLayer.**
284. **Bezel-Hop Count decay** wenn 2 s kein Hop — Chip klebt sonst bis Reset.
285. **Air-Keyboard Shortcut-Overlay.**
286. **Stereo Mac+iPhone Disparität.**
287. **Continuity 15-fps Probe** gemessen, nicht claimed.
288. **Pointer-Gain × Continuity-FOV** (Ultraweit vs Crop).
289. **Deadman-Ring** Overlay, nicht nur Clutch.
290. **Homographie Recalib nach RECAL-Chip** ein Tipp-Tap, nicht nur HUD.

P0: CameraBroker. Kein neues *Need(dt). Branch `bugfix` (1.6.15) nicht mergen.

# Helios Vorschläge — 2026-09-08 (Pass 24, 1.6.62)

Stand 1.6.62. Mutex, Pinch×Palme, Size-Key, Watchdog, Predict×Höhe.

## Gelandet in 1.6.62

- cameraMutexLockedLine / Claim in CameraSession
- pinchStartsGrab palmWidth
- spaceMapSizeKey HomographyStore
- sessionWatchdogEmpty
- pointerPredictCap screenH

## Erweiterung (neu)

249. **VNTrackObjectRequest** echte Hand-Observation, ROI-Miss ohne Full-Retry.
250. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
251. **Mission-Control Zwei-Palm-Spread.**
252. **Aegis-Gaze Pinch-Confirm.**
253. **Watch Double-Tap.**
254. **Click-Tick Sound.**
255. **JSONL Palm-Vel** Predict-Tuning.
256. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
257. **iPhone Ultraweit FOV** statt Center-Stage-Crop.
258. **DepthCapture an Continuity-LiDAR.**
259. **Per-Display pointerGain Pref.**
260. **Overlay CAMetalLayer.**
261. **One-Euro + Predict Fusion** (bereits Sample=Euro, Vel=Euro — Cap jetzt × Höhe).
262. **Air-Keyboard Shortcut-Overlay.**
263. **Stereo Mac+iPhone Disparität.**

264. **Continuity 15-fps Probe** gemessen, nicht claimed. 8 Hz bleibt der Engpass.
265. **Zwei-Pinch Zoom-Hysterese** gegen Continuity-Jitter.
266. **SpaceMap Auto-Recal** nach 20 Bezel-Hops.
267. **Pointer-Gain × Continuity-FOV** (Ultraweit vs Crop).
268. **Deadman-Ring** Overlay, nicht nur Clutch.
269. **Mutex PTS Fill** mit Aegis obsFillUsesMutexPts — Helios schreibt PTS, Aegis füllt.
270. **Watch Double-Tap Confirm** für destruktive Klicks.

P0: CameraBroker. Kein neues *Need(dt). Branch `bugfix` (1.6.15) nicht mergen.

# Helios Vorschläge — 2026-09-08 (Pass 23, 1.6.61)

Stand 1.6.61. Center Stage, AE-Lock, Chirality, ROI, Pinch×Palme, Fling-Achse.

## Gelandet in 1.6.61

- centerStageOff / NeedsAppControl — Palme nicht aus dem Continuity-Crop
- cameraLocksExposure / WhiteBalance role phone
- chiralityLock prev hält nach Dropout
- visionRoiFromPalm 2×, Miss → Full
- pinchClosednessNeed × palmWidth
- flingAxisDead × palmWidth

## Erweiterung (neu)

236. **VNTrackObjectRequest** echte Hand-Observation, ROI-Miss ohne Full-Retry.
237. **Display-Reconfig SpaceMap-Nudge** ohne Wipe.
238. **Mission-Control Zwei-Palm-Spread.**
239. **AVCapture Mutex-File** ohne XPC — Datei liegt, Claim-Race bleibt.
240. **Aegis-Gaze Pinch-Confirm.**
241. **Watch Double-Tap.**
242. **Click-Tick Sound.**
243. **Session-Watchdog** 8 s leer.
244. **Per-Display pointerGain Pref.**
245. **JSONL Palm-Vel** Predict-Tuning.
246. **MediaPipe Hands Fallback** wenn Vision 8 Hz stirbt.
247. **iPhone Ultraweit FOV** statt Center-Stage-Crop.
248. **One-Euro + Predict** Fusion statt Oder.

P0: CameraBroker. Kein neues *Need(dt). Branch `bugfix` (1.6.15) nicht mergen.

# Helios Vorschläge — 2026-09-08 (Pass 22, 1.6.59)


Stand 1.6.59. Track-TTL, Pinch-Reset, Osmo-Rolle, USB-Promote gated.

## Gelandet in 1.6.59

- tracks.removeAll / assign live → trackDropoutNeed, nicht 0,18
- pinch.reset → emptyHandsHold, nicht 0,12
- cameraFormatColdStartBias ohne osmo
- cameraFormatUsbRole gated Promote — Phone bleibt 24

## Erweiterung (neu)

226. **Continuity Center Stage off.**
227. **Vision ROI 2× Palm-Box.**
228. **Chirality-Lock** nach Dropout.
229. **Continuity AE/WB-Lock.**
230. **Fling-Achsen-Deadzone × palmWidth.**
231. **Display-Reconfig SpaceMap-Nudge.**
232. **Pinch-Hysterese × palmWidth.**
233. **AVCapture Mutex-File** ohne XPC.
234. **Mission-Control Zwei-Palm-Spread.**
235. **VNTrackObjectRequest.**

P0: CameraBroker. Kein neues *Need(dt).

# Helios Vorschläge — 2026-09-08 (Pass 21, 1.6.58)

Stand 1.6.58. Predict-Clutch, USB-C-Promote, Fling-Cap, Scroll-Gain.

## Gelandet in 1.6.58

- pointerPredictArmed / Cap 0 bei Clutch
- cameraLockFpsPromote gemessen ≥ 22 → 30
- flingTeleport 42 % Schirmhöhe
- scrollGainFor Safari/Xcode

## Erweiterung (neu)

216. **VNTrackObjectRequest** echte Hand-Observation.
217. **Predict-Cap × Screen-Höhe.**
218. **Click-Tick Sound.**
219. **Miss-Click Heatmap.**
220. **iPhone Ultraweit FOV.**
221. **Per-Display pointerGain Pref.**
222. **Aegis-Gaze Pinch-Confirm.**
223. **Watch Double-Tap.**
224. **Palm-Vel JSONL** Predict-Tuning.
225. **Session-Watchdog** 8 s leer.

P0: CameraBroker. Kein neues *Need(dt).

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

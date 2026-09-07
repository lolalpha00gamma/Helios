# Helios 1.5.185 — Klick, Ziehen, rechte Hand

Helios **1.5.185** (Build 204). Nur `main`. Repo privat.

1.5.184 folgte der Palme, aber L/R-Lock leerte den Pool (keine Aktionen), Roh-Jitter brach die Pinzette, <8 Gelenke warf die rechte Hand weg.

1. Kein Seiten-Lock. Scharf haelt den Slot, nicht Vision-Links/Rechts.
2. L/R aus Position. Spiegel: links im Bild = linke Hand.
3. Leichte EMA auf Palme/Gelenken — kein Hochpass, kein Schwung zurueck.
4. Pinzette haelt den Cursor. Loslassen = Klick. Palme ziehen = Fenster.
5. Faust/Kante: 4 Gelenke reichen. DIP-Occlusion wieder fuer die Pinzette.

# Helios + Aegis — Analyse 2026-09-07 (1.5.184)

Helios **1.5.184** (Build 203). Nur `main`. Repo privat.

Taktikwechsel, diesmal vollständig:

1. Cursor = `SpaceMap.linear(palm)` jeden Vision-Tick. Kein Highpass, kein Coast, kein Kalman, keine alte Homographie. Hand links → Cursor links.
2. Idle warpt trotzdem. Vorher folgte der Zeiger nur nach Faust-Scharf — HUD bewegte sich, der Cursor nicht.
3. Overlay = Live-Joints. Ghost/Lerp/DIP-Restore/Coast tot. Skelett bleibt nicht in der Luft.
4. Vision-Hand mit ≥3 Gelenken durch. Scale/Span-Veto raus.
5. Panel: Feinheiten-Slider weg. `mutexTermSentAt` Swift-6-safe, sonst kein DMG.

# Helios + Aegis — Analyse 2026-09-07 (1.5.183)

Helios **1.5.183** (Build 202). Nur `main`. Repo privat.

Taktikwechsel: Palme → Bildschirm direkt. Highpass/Coast/One-Euro/Overlay-Lerp tot. Die haben den Cursor zurückgezogen und das Skelett verspätet.

# Helios + Aegis — Analyse 2026-09-07 (1.5.182)

Helios **1.5.182** (Build 201). Aegis **2.1.183 alpha** (Build 208). Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.181: Ghost-Knochen, Kalman-P, Peak-Assign. Overlay-Opacity sprang 1→0,50. HUD nur Actor-Ghost (S1). Aegis Peak ohne Remint-Map tot — Advance wischte tot-UUID.

## Warum Overlay und Namen nach 1.5.181 weiter rissen

1. **overlayLerpHands kopiert `to.isGhost`.** Opacity diskret. Continuity 8 fps: S2-Coast knallt 50 % Alpha, Knochen lerpen.
2. **HUD Actor-Slot.** overlayGhostAny zählt S2, Statuschip nicht. Zwei-Pinzette 8 fps ohne Why.
3. **Aegis leftoverHoldRemintMap leer.** Vision mintet UUID, x/Hash miss. PeakHeld bleibt alt. leftoverOverlayPeakAdvance `!live` wischt Ada. Overlay „?“ trotz Assign-Live.
4. **leftoverOverlayPeakRemain nicht in remintKeys.** Peak-Remain-only Keys fehlten im Plan.
5. Von `bugfix` (1.5.8 / 2.1.15) bewusst nicht gemergt: IOHID Event-Tap, AX SetPosition/Frame, Per-App-Gain, JSONL.

## Was 1.5.182 / 2.1.183 ändert

1. overlayGhostBlend + overlayLerpGhostBlend — Opacity 1→0,50 über dt. TrackedHand.ghostBlend.
2. overlayGhostSlotChip HUD `S2 · ghost` / `S1+S2 · ghost`.
3. Aegis leftoverOverlayPeakIoUAdopt unique IoU ≥ 0,40. leftoverOverlayPeakStoredBoxes Streak vor Kalman.
4. leftoverOverlayPeakRemain in remintKeys.
5. Tests + MARKETING 1.5.182 / 2.1.183 (Build 201 / 208). Schema 15 bleibt.

`bugfix` mergen: nein.

# Helios + Aegis — Analyse 2026-09-07 (1.5.181)

Helios **1.5.181** (Build 200). Aegis **2.1.182 alpha** (Build 207). Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.180: Lerp-Hitch, Reanchor-RMS, Overlay-Dt. Canvas `where !isGhost` fraß S2-Coast. Kalman-P = 0 auf Fill-Gap. Aegis leftoverMirrorPending kopierte Peak nicht.

## Warum Overlay und Zeiger nach 1.5.180 weiter rissen

1. **TrackingOverlay filtert Ghosts.** 1.5.174 overlayGhostAny + drawHand-Opacity saßen. Canvas und Labels `where !hand.isGhost` zeichneten S2-Coast nie. Continuity 8 fps: zweite Hand tot.
2. **palmKalmanPX/Y = 0 auf Fill-Gap.** Display-Uhr reset't Kamera-P. Vel 0 ist richtig, P tot → nächster Fill fliegt.
3. **Aegis leftoverMirrorPending** remintete leftoverNameLockHeld, nicht leftoverOverlayPeakHeld. Assign-Live → Peak auf alter UUID, Overlay „?“ Tick 1.
4. Von `bugfix` bewusst nicht gemergt: IOHID Event-Tap, AX SetPosition/Frame, Per-App-Gain, JSONL.

## Was 1.5.181 / 2.1.182 ändert

1. overlayDrawsGhost — Canvas + Wrist-Chip Ghost.
2. pointerKalmanResetsPOnGap false — Vel 0, P hält.
3. Aegis leftoverAssignAtomic PeakHeld/Remain in leftoverMirrorPending.
4. Tests + MARKETING 1.5.181 / 2.1.182 (Build 200 / 207). Schema 15 bleibt.

`bugfix` mergen: nein.

# Helios + Aegis — Analyse 2026-09-07 (1.5.180)

Helios **1.5.180** (Build 199). Aegis **2.1.181 alpha** (Build 206). Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.179: Overlay-Lerp an, Fill-Uhr Ghost, Reanchor-Split. Hub-Doppelframe snappt Lerp. Floor 0,05 freeze. Reanchor hart 8 px. Aegis Overlay „?“ nach Remint.

## Warum es nach 1.5.179 weiter riss

1. **Hub-Doppelframe 8–20 ms.** overlayLerpShould false → Tabellen leer, 8 fps Snap.
2. **overlayLerpDt Floor 0,05.** t=1 nach 50 ms, Freeze 75 ms.
3. **pointerReanchor 8 px hart.** 60 fps 5 px Drift bleibt, Studio snappt.
4. **Aegis Remint-UUID.** Hist keep 1 vs Need 3 → 1–3 Frames „?“.

## Was 1.5.180 / 2.1.181 ändert

1. overlayLerpHitchKeeps Cap 2, From/To halten
2. overlayLerpDtOf ohne Floor
3. pointerReanchorRms(dt)
4. leftoverOverlayPeak 3 Frames, PeakName Display
5. Tests + MARKETING 1.5.180 / 2.1.181 (Build 199 / 206)

`bugfix` mergen: nein.

# Helios + Aegis — Analyse 2026-09-07 (1.5.179)

Helios **1.5.179** (Build 198). Aegis **2.1.180 alpha** (Build 205). Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.178: Fill-Gap Kamera-Rebase, MAD-Cap. OverlayLerp blieb false. Fill-Gap lastHandSeen ohne Ghost. Reanchor am displayTick. Aegis StoreName vor Gast, Held nach TTL tot.

## Warum es nach 1.5.178 weiter riss

1. **overlayLerpShould hart false.** Continuity 8 fps Skelett-Ruck. overlayLerpT clamp 1 — Lerp wieder sicher.
2. **Fill-Gap lastHandSeen.** liveHandRefreshesDeadMan = !ghost. S1-Coast, lastHandSeen friert, Fill tot, Overlay ghostet.
3. **pointerReanchor am displayTick und Fill.** NSEvent > 8 px zieht 90 Hz Fill zurück. Kamera-Tick darf reanchorn.
4. **Aegis leftoverNameLockHeldSurvive emptyKeeps:false.** TTL → Held weg. StoreName braucht poseAt/Until. Hist keep 1 vs Need 3 → „?“.

## Was 1.5.179 / 2.1.180 ändert

1. overlayLerpShould 0,045…0,20
2. lastFillSeen / obsFillSeesHand(ghost:true). Dead-Man bleibt !ghost
3. pointerReanchorAppliesFill false an Fill + displayTick
4. leftoverOverlayGuestOf sticky + Hist-Tail, leftoverNameLockHeldCoast
5. Tests + MARKETING 1.5.179 / 2.1.180 (Build 198 / 205)

`bugfix` mergen: nein.

# Helios + Aegis — Analyse 2026-09-07 (1.5.174)

Helios **1.5.174** (Build 193). Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.173: S2 Hist+Coast. applyCoastGhost ghostete live S2. Overlay nur S1. Vision-Flip. spanW verworfen. Hung-live.

## Warum Overlay nach 1.5.173 weiter riss

1. **applyCoastGhost Rest = Ghost.** S1-Dropout tötet Zwei-Pinzette.
2. **S2 ohne Vel/Ghost-Skelett.** lastS2Palm tot für Overlay.
3. **overlayGhostPeakHold actorHandID.** S2 1 Frame.
4. **Kein Chirality-Freeze.** S1↔S2 nach beiden gesehen.
5. **obsLooksLikeHand `_ = spanW`.** Gitarre mit 16 Mini-Joints = Hand.
6. **Faust 2-Frame Gate.** Click nach dem Falten.
7. **Mutex live nie kill.** Aegis ¾R unsichtbar, Twin-Tie beide tot.

## Was 1.5.174 ändert

1. **palmCoastRestStaysLive.** Nur fehlendes Slot Ghost, mit Vel.
2. **overlayGhostAny + S2 Chip ghost.**
3. **palmChiralityFreeze 800 ms.**
4. **palmSpanBandVeto** in obsLooksLikeHand.
5. **fistFormingPreArm.** Hung-live 12 s.
6. Tests + MARKETING 1.5.174 (Build 193). Aegis 2.1.176 Enroll/Twin-Tie.

`bugfix` mergen: nein. IOHID/AX/CameraBroker bleiben Liste.

# Helios + Aegis — Analyse 2026-09-07 (1.5.173)

Helios **1.5.173** (Build 192). Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.172: Live-Scale Bind, S2 Conf. S1-Hist veto'te S2. lastS2 nil nach 1 Miss. Keep 0,72 machte Gitarre 0,29 neben Palma zur Hand.

## Warum Overlay nach 1.5.172 weiter riss

1. **palmBindScaleClass(hist: lastS1ScaleRing) auf alle Obs.** S1 Compact 0,14, S2 0,29 → Hist-Veto Scale 1. Zweite Hand tot.
2. **lastS2Palm nil nach 1 Miss.** S1 Coast 2–4 Ticks, S2 0. 8 fps Zwei-Pinzette tot.
3. **Keep-Radius im Gitarrenband.** nearLast + keep:true = isHand(0,29). Gitarre neben Palma = S1.
4. **obsLooksLikeHand nur isHand.** 16 Joints 0,31 = Prop. Dense-Hand zur Kamera nie S2.
5. **S1∩S2 Pinch.** Hand-über-Hand Click ohne Mute.
6. **Aegis ROI um alle Kalman.** Ada still im Crop, Twin-Print-Budget tot. Overlay ohne `still`.

## Was 1.5.173 ändert

1. **palmBindScaleHistOf.** S2 eigener Ring. Unbound leer.
2. **s2MissTicks / palmCoastKeepsS2.** lastS2 hält 2–4 Ticks.
3. **palmScaleIsHand keep ohne Band.** Approaching (steigend < 0,12) = Hand. Sprung = Gitarre.
4. **palmScaleRanksHand.** 16 Joints im Band = Hand, 6 = Prop. Compact vor Joint-Group.
5. **palmPinchMuteOverlap.** driveGrab `kein Klick — S1∩S2`. Scale davor.
6. **palmScaleClassChip.** HUD `S1 0.14` / `S1 Gitarre`.
7. Tests + MARKETING 1.5.173 (Build 192). Aegis 2.1.175 Skip-HUD + ROI.

`bugfix` mergen: nein. IOHID/AX/CameraBroker bleiben Liste.

# Helios + Aegis — Analyse 2026-09-07 (1.5.172)

Helios **1.5.172** (Build 191). Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.171: isHand-Band 0,28/0,40. Keep nur lastS1. `palmBindScaleOf` mischte trotzdem lastS1 0,14 in Gitarre 0,29 → 0,21 = isHand. Compact-Tie, Conf 0,95. S2-Dip las lastS1Conf.

## Warum Overlay nach 1.5.171 weiter Gitarre nahm

1. **palmBindScaleOf auf alle Observations.** ticks≥3: 0,45×0,29+0,55×0,14 = 0,21. isHand-Band 0,28 tot. Compact beide < 0,28, Conf 0,95 = S1 Prop.
2. **obsLooksLikeHand(scaleLive EMA).** Zweiter Loop dieselbe Mischung. Guitar-Hist-Veto nur bei med < 0,22 — Tick 0 Ring leer.
3. **S2 Conf-Dip = lastS1.** 1-Frame Dip der zweiten Hand `continue`. Zwei-Hand-Pinzette tot.
4. **Aegis printBudget min(stillFor) / max(|yaw|).** Twin bewegt → Ada druckt mit. leftoverPrintYawMerge kopierte Ada-Yaw, Δ 0, Skip bleibt global tot.

## Was 1.5.172 ändert

1. **palmBindScaleClass / Live-Scale.** Bind und looksLikeHand auf scLive. EMA nur lastS1 Overlay.
2. **palmSlotConfPrev / KeepNear / lastS2.** S2 Dip hält. Keep S2 ohne S1-Hist.
3. Tests + MARKETING 1.5.172 (Build 191). Aegis 2.1.174 Print je Gesicht.

`bugfix` mergen: nein. IOHID/AX/CameraBroker bleiben Liste.

# Helios + Aegis — Analyse 2026-09-07 (1.5.171)

Helios **1.5.171** (Build 190). Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.170: Compact vor Conf. `palmHandScaleMax` blieb 0,72 — Gitarre 0,29 war weiter `palmScaleIsHand`. Keep global auf alle Blobs.

## Was 1.5.171 ändert

1. **palmHandScaleMax 0,28 / Close 0,40 / KeepMax 0,72.** Neu-Alloc: Desk oder Nah. Band 0,28…0,40 = Prop. Keep nur lastS1.
2. **palmSlotNearLast / palmSlotBindConf.** Keep und Conf-EMA nur am Incumbent.
3. Compact, MedianRecords, Guitar-Hist, Conf-Dip aus 1.5.170 bleiben.
4. Tests + MARKETING 1.5.171 (Build 190). Aegis 2.1.173.

`bugfix` mergen: nein.

# Helios + Aegis — Analyse 2026-09-07 (1.5.170)


Helios **1.5.170** (Build 189). Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.169: Hist-Prior vor Conf. Ohne Hist gewann Gitarre Conf 0,95. Guitar-Hist (S1 0,29) ließ Compact-Prior 1 = 1, Conf wieder Gitarre. leftoverFaceTrackKalmanPredict unverdrahtet. printBudget ohne Still.

## Warum Overlay nach 1.5.169 weiter Gitarre nahm

1. **palmBindHandsFirst Conf ohne Compact.** 0,29 und 0,14 sind beide palmScaleIsHand (< 0,72). Tick 0, Ring leer: Conf 0,95 = S1 Prop.
2. **Hist-Prior bei Guitar-Median.** med 0,29, jump 0 → Prior 1 für Gitarre und Hand. Compact erholt S1 nicht.
3. **lastS1ScaleRing nahm 0,29.** Sobald Gitarre S1 war, Ring = Guitar-Cluster. Veto tot, Prior tot.
4. **1-Frame Conf-Dip.** minConf skippt S1, Bind mintet Gitarre.

## Was 1.5.170 ändert

1. **palmBindCompactPrefers** vor Conf. Compact < 0,28 vor Gitarre-Range, auch ohne Hist.
2. **palmScaleHistPrior Guitar-Hist.** med ≥ 0,28 → Compact 1, Gitarre 0.
3. **palmScaleMedianRecords** — 0,29 nicht in den Ring.
4. **palmSlotConfHolds** — 1-Frame Dip hält S1.
5. Tests + MARKETING 1.5.170 (Build 189). Aegis 2.1.172 stillFor/Kalman-Predict/Coast-Stamp/??.

`bugfix` mergen: nein. IOHID/AX/Per-App-Gain/JSONL bleiben Liste.

# Helios + Aegis — Analyse 2026-09-06 (1.5.167)


Helios **1.5.167** (Build 186). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.166: Hist-Veto Live. Mutex-Read kill't tote PIDs, WRITE unter LOCK_EX nicht. Aegis 12 s tot nach Helios-Crash.

## Was 1.5.167 ändert

1. **cameraMutexWriteAllowed / LockedLine(pidLive:).** CameraSession kill(2) vor LOCK_EX-Write. Toter Holder → Lock frei.
2. Tests + MARKETING 1.5.167 (Build 186). Aegis 2.1.169 Remint-Lookup.

`bugfix` mergen: nein.

# Helios + Aegis — Analyse 2026-09-06 (1.5.166)


Helios **1.5.166** (Build 185). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.165: Bind-Conf. Gitarre 0,29 vs Hand-Cluster 0,14 — Conf-Tie, kein Hist-Veto. Bind-EMA 0,21 unter Scale-Max 0,72.

## Warum Overlay nach 1.5.165 weiter Gitarre nahm

1. **palmBindScaleOf EMA.** 0,45×0,29+0,55×0,14 = 0,21. Scale-Max 0,72 = Hand. Conf-Tie sitzt, Sprung nicht.
2. **Aegis printBudget |yaw|.** Langsame Drehung 5° skippt Print. leftoverHold-Zahl vom Frontal-Tick tauft Twin.
3. **Coast ohne Vec.** skipPrints + livePrintEmpty = leftoverHold 0,85, nicht Cache-Cosine.

## Was 1.5.166 ändert

1. **palmScaleHistVeto auf Live-Scale.** Enges Cluster + Sprung ≥ 0,12 über 0,28 = Prop. EMA-Bound tot.
2. Tests + MARKETING 1.5.166 (Build 185). Aegis 2.1.168 Coast-Vec + Print-Yaw-Δ.

`bugfix` mergen: nein.

# Helios + Aegis — Analyse 2026-09-06 (1.5.165)

Helios **1.5.165** (Build 184). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.164: expected-gen CAS, ClaimChip. Aegis FaceTrack remintete Hold, nicht Name-Hist/Print-Trail. Overlay Gast nach UUID-Remint. Bind Observation-Order.

## Was 1.5.165 ändert

1. **palmBindHandsFirst(confs:).** Höhere Vision-Conf vor Observation-Order. Gitarre/Zweite Hand stiehlt S1 nicht mehr nur weil Vision sie zuerst liefert.
2. Tests + MARKETING 1.5.165 (Build 184). Aegis 2.1.167 remintet Live-Skalare + Arrays.

`bugfix` mergen: nein.

# Helios + Aegis — Analyse 2026-09-06 (1.5.164)

Helios **1.5.164** (Build 183). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.163: ClaimBackoff. LockedLine bumpte Gen ohne SH-Read-Abgleich. HUD ohne Fail-Count.

## Was 1.5.164 ändert

1. **cameraMutexCasAllows / expectedGen.** Aegis mismatch tot, Helios Vorrang.
2. **cameraMutexClaimChip.** `helios · 1nb` / `backoff` im HUD.
3. Tests + MARKETING 1.5.164 (Build 183).

`bugfix` mergen: nein.

# Helios + Aegis — Analyse 2026-09-06 (1.5.163)

Helios **1.5.163** (Build 182). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.162: ClaimDue 80 ms, fsync, Yield-Pref. LOCK_NB-Fail retried alle 80 ms.

## Was 1.5.163 ändert

1. **cameraMutexClaimBackoffFails 3 / ClaimBackoffDt 400 ms.** SkipClaim busy und Write-Fail zählen.
2. Tests + MARKETING 1.5.163 (Build 182).

`bugfix` mergen: nein.

# Helios + Aegis — Analyse 2026-09-06 (1.5.159)

Helios **1.5.159** (Build 178). Nur `main`. Repo privat.

Kalib speichert Reichweite, nicht Cursor-an-Ecke. Pinzette zur Kamera. Leiste oben aus per Default. Cursor folgt ohne DidMove-Gate.

# Helios + Aegis — Analyse 2026-09-06 (1.5.158)

Helios **1.5.158** (Build 177). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.157: Cursor warpt, Hand reicht zum Scharf. Mutex weiter in `/tmp` ohne flock. Aegis-Yield klebte ewig und ließ die Continuity-Session laufen — 8 fps, zwei Prozesse, eine Kamera.

## Warum Kamera und Overlay nach 1.5.157 weiter rissen

1. **Lock in `/tmp`, Write ohne flock.** `atomically: true` ist Rename, kein Exclusive. Zwei Claims lesen „frei“ und schreiben beide. tmp-Cleaner / Reboot löscht den Stamp, Aegis glaubt die Cam sei frei.
2. **Yield klebt.** `YieldsNow = wasYielded || Helios`. Einmal gewichen, nie zurück. Heartbeat stoppt, Session bleibt auf Continuity.
3. **Kein Dual-Read.** Helios und Aegis mussten dieselbe tmp-Datei treffen. Ein veralteter Partner sieht nichts.
4. README hing bei **1.5.152** während Binary 1.5.157 war.

## Was 1.5.158 ändert

1. **Caches + Dual-Read/Write.** `~/Library/Caches/HeliosAegis/helios.aegis.camera.lock`, Legacy `/tmp` weiter gelesen und geschrieben.
2. **fcntl flock LOCK_EX** vor dem Write. Torn Rename tot.
3. **YieldsNow** löst wenn Holder Aegis ist. `YieldReconfigure` (Aegis 2.1.161) legt die Session auf Built-in um.
4. README / ANALYSE / Vorschläge = MARKETING 1.5.158 (Build 177).

`bugfix` mergen: nein. CameraBroker-XPC, Overlay-Metal, Body-Pose-Veto bleiben Liste.

# Helios + Aegis — Analyse 2026-09-06 (1.5.157)

Helios **1.5.157** (Build 176). Nur `main`. Repo privat.

Cursor tot weil: Engine droppt <8 Joints, Faust-Pose kein Warp, DisplayLink skippt Vision, Arm nur nach Öffnen+Faust. Jetzt: 4 Joints reichen, jede Hand scharf nach 0,55 s, Vision warpt immer, Faust bewegt den Zeiger.

# Helios + Aegis — Analyse 2026-09-06 (1.5.156)

Helios **1.5.156** (Build 175). Nur `main`. Repo privat.

Cursor-Clutch und Conf-Freeze 0,30 hielten den Zeiger. Close-Hand Scale-Cap 0,28 war tot. Einstellungen hinter Feinheiten, Panel scrollt. Hover = Pinzetten-Vorschau, kein extra Modus.

# Helios + Aegis — Analyse 2026-09-06 (1.5.155)

Helios **1.5.155** (Build 174). Nur `main`. Repo privat.

Vollbild-Skelett war ROI-Overlay (Gelenke im Crop aufs Preview). Span-/Gitarren-Veto ist tot. Faust nah an der Kamera nicht mehr als Blob.

# Helios + Aegis — Analyse 2026-09-06 (1.5.154)

Helios **1.5.154** (Build 173). Nur `main`. Repo privat.

Faust und flache 90°-Kante starben an Fingerkette, MCP-Fächer, Tip-Conf 0,40 und Revision1. Overlay-Gitarre bleibt am großen Span. Latest Vision-Revision.

# Helios + Aegis — Analyse 2026-09-06 (1.5.153)

Helios **1.5.153** (Build 172). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

Ghost 4 s, DIP-Kalman-Freeze, Overlay-Lerp und Pointer-Latch 4 s waren die Restursache für Pose in der Luft. Overlay nur Live. Ghost 100 ms. Built-in 30–60 fps. Mutex aus 1.5.152 bleibt.

# Helios + Aegis — Analyse 2026-09-06 (1.5.152)

Helios **1.5.152** (Build 171). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.151: 60 fps, Overlay-Snap t>1, One-Euro 14. Mutex `Int(now)` Sekundenraster. PID in der Lockzeile ungenutzt. Crash = 12 s toter Lock. Aegis-Heartbeat überschreibt Helios alle 2 s — Continuity hoppt.

## Warum Overlay, Cursor und Kamera nach 1.5.151 weiter rissen

1. **Mutex-Stamp `Int(now)`.** Claim 12,9 / Parse 13,0 zählt als 1 s. Heartbeat und Stale lügen um bis zu 999 ms.
2. **PID tot.** Zeile schreibt pid, Parse liest ihn nicht. Helios-Crash hält Aegis 12 s vom Lock.
3. **Aegis-Heartbeat ohne Claim-Gate.** Helios startet, schreibt Lock, Aegis Timer schreibt alle 2 s zurück. Zwei Sessions, 8 fps, TCC.
4. **Yield nur beim Configure.** Helios nach Aegis: Aegis bleibt auf Continuity und kämpft.

## Was 1.5.152 ändert

1. **cameraMutexLine %.3f.** Millisekunden, alte Sekunden-Zeilen bleiben lesbar.
2. **cameraMutexPid / Parse pidLive.** Toter PID = Lock frei. CameraSession `kill(pid,0)`.
3. **cameraMutexClaimWrites.** Helios Vorrang. Aegis schreibt nie über Helios.
4. **cameraMutexYieldsNow.** Aegis-Heartbeat liest neu, weicht live, stoppt den Timer.
5. Tests + MARKETING_VERSION 1.5.152 (Build 171).

Aegis 2.1.160: Claim-Gate, HungarianX n>8 Greedy+2-opt, Detect-Skip. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`. Frame-Pump XPC und flock bleiben auf der Liste.

# Helios + Aegis — Analyse 2026-09-06 (1.5.151)

Helios **1.5.151** (Build 170). Nur `main`. Repo privat.

Latenz: Built-in 60 fps statt Kappe 30. Overlay-Lerp nur unter 22 fps, t>1 snap (kein Extrapolate in die Luft). One-Euro Cutoff 14 bei 8 fps. Display-Coast 100 ms statt 350.

# Helios + Aegis — Analyse 2026-09-06 (1.5.150)

Helios **1.5.150** (Build 169). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.149: DisplayPulse je Screen, Cursor-Gate auf den **ganzen** Tick, Geometry 32 Frames, Vision trotzdem `.up`. FrameSink warf `videoRotationAngle` weg. Clamshell/5K ließ tote Links stehen.

## Warum Overlay und Cursor nach 1.5.149 weiter rissen

1. **Cursor-Gate fraß Overlay-Lerp.** Pulse vom anderen Schirm `return` vor Debounce. HUD auf dem 5K fror zwischen 8-fps-Frames. Warp lief auf dem Quellschirm-vsync.
2. **Kein Layout-Rearm.** `didChangeScreenParameters` nur `pollFocus`. Klappe zu / 5K an: CADisplayLink auf totem Panel, neuer Schirm ohne Link.
3. **FrameSink ohne Winkel.** `visionBufferOrientation(..., rotationApplied: false)` ist immer `.up`. Continuity 90° = 90°-Palm. Geometry-Reassert setzt Connection 0°, liest den Live-Winkel nicht.

## Was 1.5.150 ändert

1. **displayLinkIsDest.** Warp nur Zielschirm. Overlay-Lerp läuft trotzdem.
2. **displayLinkLayoutToken.** Rearm bei Clamshell/5K.
3. **visionOrientationLive.** FrameSink gibt `connection.videoRotationAngle` weiter. Applied → up, sonst Tag 0/90/180/270.
4. Tests + MARKETING_VERSION 1.5.150 (Build 169).

Aegis 2.1.159: HungarianX Print-Cost, Spark Hash persist. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`. Frame-Pump XPC und IOHID bleiben auf der Liste.

# Helios + Aegis — Analyse 2026-09-06 (1.5.149)

Helios **1.5.149** (Build 168). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.147/148: Smooth dt, Span max-Paar, DisplayPulse `NSScreen.displayLink` auf **main**. Studio 60 + Laptop 120 ein Link. Gitarre-Hals passiert Span/Conf/Kette. 20× Remint in Aegis divergiert. Helios+Aegis reißen Continuity.

## Warum Overlay und Cursor nach 1.5.148 weiter rissen

1. **DisplayPulse = NSScreen.main.** Hz war max(screens), der Link saß auf main. Laptop 120 treibt Studio-Overlay. vsync drift, Seam-Stutter.
2. **Kein MCP-Fächer-Veto.** Gitarrenhals ist kollinear. Fingerkette und Span lassen eine Linie mit 4 MCP durch. S1 = Prop.
3. **Bind-Scale roh.** Gitarre 0,29 / Hand 0,14 flackert jeden Tick. lastS1Scale ungenutzt vor Bind.
4. **Kamera ohne Mutex.** Helios und Aegis starten Continuity parallel — 8 fps, TCC-Dialog, Format-Hop.
5. **Capture-Geometrie einmal.** Klappe/Continuity dreht den Buffer, Vision bleibt .up.

## Was 1.5.149 ändert

1. **DisplayPulse je NSScreen** + `displayLinkDebounce` 4 ms + **Cursor-Screen-Gate**. Fill nur der Schirm unter der Maus — Laptop 120 feuert nicht den Studio-Tick.
2. **palmMCPFanDeg / palmMCPCollinearVeto 18°.** Gitarre-Hals tot, Close-Hand hält. `obsLooksLikeHand fanOk`.
3. **palmBindScaleOf** EMA 3 Ticks auf lastS1. Gitarre-Flicker bleibt Hand-Band.
4. **cameraMutex** Datei `helios.aegis.camera.lock`. Heartbeat alle 8 Frames, Stale 12 s (3 s war tot auf Continuity 8 fps). Helios claimed, Aegis weicht auf Built-in.
5. **applyCaptureGeometry alle 32 Frames.** Lid/Continuity ohne KVO-Crash.
6. **HUD Chirality `← L` / `R →`** (`bugfix` Pfeil, nicht mergen).
7. Tests + MARKETING_VERSION 1.5.149 (Build 168).

Aegis 2.1.158: Remint-Plan einmal, Spark Hash-Persist, Quality-Produkt, Continuity-Taufe 0,76, Unsure-Chip verdrahtet, Mutex-Heartbeat. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`. Zwei echte DisplayLinks sitzen. Frame-Pump XPC bleibt auf der Liste.

# Helios + Aegis — Analyse 2026-09-06 (1.5.148)

Helios **1.5.148** (Build 167). Nur `main`. Repo privat.

DisplayPulse: `NSScreen.displayLink` statt `CADisplayLink(target:)` — SDK 26.5 bricht sonst den App-Build. usesCPUOnly weg. GitHub-Release nur mit echter Helios.dmg dieser Version.

# Helios + Aegis — Analyse 2026-09-06 (1.5.147)

Helios **1.5.147** (Build 166). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.146: Finger-Paare, Tip-Conf, Frozen-Write tot. Smooth fest 0,35. Span nur Index–Klein. DisplayPulse NSScreen.main.

## Warum Overlay und Cursor nach 1.5.146 weiter rissen

1. **obsSmoothJump 0,35 fest.** Continuity 8 fps braucht 0,35. Webcam 24 fps Slot-Steal 0,14 setzt One-Euro nicht — Smoother mischt Gitarre in die Hand.
2. **palmScaleSpanVeto Index–Klein.** Gitarre ohne die zwei Gelenke: Span 0, Classifier `return med`.
3. **DisplayPulse NSScreen.main.** Laptop+5K: main oft Laptop 120, Studio-Overlay 60. vsync drift.

## Was 1.5.147 ändert

1. **obsSmoothJumpOf(dt).** 8 fps 0,35, 24 fps ~0,12. chiralityHolds bleibt.
2. **palmScaleSpanOf.** Max-Paar aller MCP.
3. **displayLinkHzOf(fpsList:).** Max über NSScreen.screens, nicht main.
4. Tests + MARKETING_VERSION 1.5.147 (Build 166).

Aegis 2.1.157: MissCoast return, Spark Hash-Rebind. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`. Zwei DisplayLinks (Studio 60 + Laptop 120) bleiben offen.

# Helios + Aegis — Analyse 2026-09-06 (1.5.146)

Helios **1.5.146** (Build 165). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.145: Fingerkette hart, Conf-Mittel, Chirality, ROI-Totpfad. compactMap-Zip paart Middle-MCP mit Ring-Tip. Gitarre Wrist 0,80 Tips 0,10 passiert Mittel. Freeze schreibt lastFrozenROI auch bei ROI-aus.

## Warum Overlay und Cursor nach 1.5.145 weiter rissen

1. **obsFingerChainOk compactMap-Zip.** Fehlender Middle-Tip: MCP-Array 4, Tip-Array 3. Index i paart Middle-MCP mit Ring-Tip. Gitarre 2 Zufallspaare = Kette.
2. **obsJointConfOk nur Wrist+MCP.** Gitarre Indoor Wrist 0,80 MCP 0,68 Mittel 0,71, Tips 0,10. Conf-Gate hält Prop.
3. **lastFrozenROI bei ROI-aus.** `!freezeROI { lastFrozenROI = activeROI }`. Coast-Altlast, ThawProp tot-gegated aber Freeze-Clock tickt.

## Was 1.5.146 ändert

1. **obsFingerChainPairs.** Finger-Index, unpaired skip. compactMap-Zip tot.
2. **obsJointConfOk tips.** Tip-Mittel < Floor tot, auch wenn Wrist hoch.
3. **palmROIFrozenWrite.** ROI-aus schreibt kein Frozen, löscht Altlast.
4. Tests + MARKETING_VERSION 1.5.146 (Build 165).

Aegis 2.1.156: Steal 2-opt, Held emptyKeeps, CostIoU. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`. Capture-Orientation KVO, HUD Chirality-Pfeil bleiben auf der Liste.

# Helios + Aegis — Analyse 2026-09-06 (1.5.145)

Helios **1.5.145** (Build 164). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.144: HandCount 4, Fingerkette, Span-Veto Prop, Smooth 0,35. Fingerkette ohne Wrist = MCP≥2. ROI tot, Coast schreibt lastFrozenROI, ThawProp emitEmpty. L/R-Flip setzt One-Euro. Indoor-Blur 0,28 bindet als Hand.

## Warum Overlay und Cursor nach 1.5.144 weiter rissen

1. **obsFingerChainOk ohne Wrist.** `mcps.count >= 2` — Gitarre ohne Wrist und ein Tip bei 3 MCP = Kette. Mid-Gitarre bindet S1.
2. **ROI tot, Coast-Follow live.** palmVisionUsesROI false, palmROICoastFollows(true) schrieb lastFrozenROI. Nächster Tick ThawProp emitEmpty — echte Hand weg.
3. **ThawProp ignorierte ROI-aus.** Frozen-Altlast + Gitarre-Hit = emitEmpty, Cursor-Sprung.
4. **One-Euro bei Chirality-Flip.** Vision L/R-Rauschen = Smoother-Reset, Overlay-Snap.
5. **Kein Joint-Conf-Gate.** Wrist+MCP 0,22 Indoor-Blur zählt als Hand, Gitarre-Rumpf auch.

## Was 1.5.145 ändert

1. **obsFingerChainOk.** Ohne Wrist tot. n<2 tot. Gitarre ohne Kette fällt.
2. **obsJointConfOk.** Mittel Wrist+MCP < 0,40 tot. Sparse 0,22.
3. **obsSmoothChiralityHolds.** L↔R setzt One-Euro nicht.
4. **palmROICoastFollows / palmROIThawProp.** Default ROI-aus. Coast schreibt kein Frozen. ThawProp emitEmpty tot.
5. Tests + MARKETING_VERSION 1.5.145 (Build 164).

Aegis 2.1.155: Print stiehlt Remint, Ghost-HOLD PairCommit, Held Survive. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`. Capture-Orientation KVO, Dead-Man Prefs sitzen seit 1.5.127. Pairwise-Heatmap bleibt Aegis.

# Helios + Aegis — Analyse 2026-09-06 (1.5.144)

Helios **1.5.144** (Build 163). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.143: Sparse/Close-Hand, Bind denser, Gitarre 0,29 tot. Vision `maximumHandCount = 2` bleibt. Span-Veto beide Äste `med`. Flick 0,22 setzt One-Euro. Mid-Gitarre ohne Fingerkette als S1.

## Warum Overlay und Cursor nach 1.5.143 weiter rissen

1. **maximumHandCount 2.** Revision1 rankt größte Blob zuerst. Gitarre + Rumpf füllen beide Slots. Sparse/Bind sieht die echte Hand nie.
2. **palmScaleSpanVeto tot.** Classifier beide Äste `return med`. Gitarre Wrist–MCP wie Hand, Scale 0,25 bindet vor 0,27 ohne lastS1.
3. **obsSmoothResets 0,22.** Continuity 8 fps Flick ~20 cm = One-Euro-Reset jede Geste. Overlay-Snap. 1.5.143 VORSCHLAEGE nannte Cap 0,35.
4. **Mid-Gitarre ohne Kette.** Close-Hand darf groß sein (1.5.143). Gitarre 0,50×0,44 kompakt ohne Tip>MCP. chainOk fehlte.

## Was 1.5.144 ändert

1. **obsHandCountCap 4.** Vision 4 Slots — Hand überlebt Rank hinter Gitarre+Rumpf. Sparse/Close-Hand bleibt.
2. **obsFingerChainOk.** Tip>MCP, Sparse ohne Kette hält. Mid-Gitarre tot, Close-Hand nicht.
3. **obsScaleMarksProp.** Span-Veto markiert Prop > 0,28 statt `med`.
4. **obsSmoothJump 0,35.** Flick hält One-Euro. Gitarre→Hand 0,38 setzt weiter.
5. Publish-Fallback 1.5.144.
6. Tests + MARKETING_VERSION 1.5.144 (Build 163).

Aegis 2.1.154: DropHold Ghosts+Miss, Publish 15. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`. `bugfix` sagte max 2 Hände — 1.5.144 bricht das bewusst, Gitarre frisst die zwei Slots.

# Helios + Aegis — Analyse 2026-09-06 (1.5.143)

Helios **1.5.143** (Build 162). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.142: ROI tot, Vision Revision1, Span-Filter, Overlay roh. Sparse/Close-Hand tot. Gitarre 0,29 Keep. Bind klein-first ohne Dichte.

## Warum Overlay und Cursor nach 1.5.142 weiter rissen

1. **obsLooksLikeHand jointCount < 8.** fingerSparseKeepsPalm tot. 8 fps Dropout 5 Gelenke = Gitarre, S1 weg.
2. **obsLooksLikeHand keep:true.** Gitarre 0,29 kompakt bindet als Hand. Default muss hart 0,28.
3. **obsLooksLikeHand Fläche 0,38.** Close-Hand 0,55×0,70 = 0,39 tot. Desk Continuity typisch.
4. **Bind ohne counts.** lastS1 tot: Gitarre 0,25 vor Hand 0,27. Span-Filter lässt kompakte Gitarre durch.

## Was 1.5.143 ändert

1. **obsLooksLikeHand keep/sparse.** Default hart. Sparse 8 fps hält. Fläche 0,38 tot — nur Preview-Füllung 0,70×0,58.
2. **palmBindHandsFirst counts.** Dichte Hand vor sparsamer Gitarre wenn last fehlt.
3. Tests + MARKETING_VERSION 1.5.143 (Build 162).

Aegis 2.1.153: Spark persist + Tick lastHash, Capture-Hist remaining, DropDangling keep leer. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-06 (1.5.142)

Helios **1.5.142** (Build 161). Nur `main`. Repo privat.

Taktikwechsel: ROI-Thaw (1.5.132–141) tot. Overlay-Zeichnung war nie das Problem.

1. **Vision Revision1**, Vollbild wie 1.6 / 1.5.66. Kein Crop um S1.
2. **Falschpose raus.** Gelenk-Span + Palma: Gitarre (fast Preview) wird nicht S1.
3. **Overlay = Rohpunkte.** Kalman nur für Pose.
4. **Smoother-Reset** bei Palm-Sprung > 0,22.
5. **Builder macos-15**, weil macos-26 nicht startet. Image unsigniert.

# Helios + Aegis — Analyse 2026-09-06 (1.5.141)

Helios **1.5.141** (Build 160). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.140: ROI Thaw Prop skip-bind, Freeze TTL, S1 Laterality, Coast Click 180 ms. Bind Hands-First nur Scale — Gitarre 0,25 vor Hand 0,27. Freeze-Clock stampt unfrozen, TTL feuert sofort.

## Warum Overlay und Cursor nach 1.5.140 weiter rissen

1. **Bind Hands-First nur Scale.** Zwei Blobs unter 0,28: kleiner zuerst. Gitarre 0,25 vor Hand 0,27. lastS1Palm ungenutzt.
2. **Freeze-Clock unfrozen.** `!freezeROI` stampt lastFrozenAt. Nach 400 ms Tracking feuert TTL sofort — Freeze hält nie.
3. **Scale-Pass ohne ROI-Map.** Frozen-Crop Punkte 0…1 der ROI. palmScale 0,40 = Prop, handHit tot, ThawProp skip-bind jede Hand im Crop.

## Was 1.5.141 ändert

1. **palmBindHandsFirst palms+last.** Unter 0,28 gewinnt Näher zu lastS1.
2. **palmROIFreezeClock.** Clock nur während Freeze. Unfrozen-Snapshot lastFrozenAt = 0.
3. **Scale-Pass visionROIMap.** handHit und Bind in Bild 0…1, nicht ROI-Raum.
4. Tests + MARKETING_VERSION 1.5.141 (Build 160).

Aegis 2.1.152: DropDangling Hold-Key. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-06 (1.5.140)

Helios **1.5.140** (Build 159). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.139: ROI Thaw Same-Tick/Expand, FullAfter 24 fps, Bind Hands-First. Frozen-Crop trifft Gitarre: observations nicht leer, Thaw-Miss tot. Freeze 400 ms ohne TTL. Gitarre als S2 klaut S1-Laterality. Coast-Return klickt. ThawProp band Gitarre als S1 denselben Tick. Coast-Lock 80 ms tot bei 8 fps.

## Warum Overlay und Cursor nach 1.5.139 weiter rissen

1. **Frozen-Crop Prop-Hit.** Thaw nur Empty-Miss oder Full/Expand. Gitarre im Crop = Hit, Freeze bleibt, echte Hand nie im Bild.
2. **ROI Freeze ohne TTL.** 2 Frozen-Miss nur wenn leer. Prop hält den Crop ewig, Center Stage wandert.
3. **S2 Laterality = S1.** Gitarre als S2 mit gleicher Seite — claimedSame braucht locked≠0. Neuer Slot locked=live, dann Flip nach 3 Ticks.
4. **Coast-Return Klick.** Ghost 2 Ticks, Live: Pinch-Zittern feuert Click. Scroll-Lock 180 ms, Coast 0. 80 ms tot beim nächsten 8-fps-Tick (125 ms).
5. **ThawProp band Gitarre.** Frozen Hit ohne Hand taut, bindet Prop als S1 denselben Tick, Cursor-Sprung.

## Was 1.5.140 ändert

1. **palmROIThawProp.** Frozen Hit ohne handgroße Observation taut, nächster Tick Full. emitEmpty — Gitarre nicht S1.
2. **palmROIFreezeTTL 400 ms.** Frozen-Crop stirbt auch ohne Thaw-Hit.
3. **palmLateralityBlocksS2.** S1-Seite nach Bind. Gitarre S2 → Unknown.
4. **pinchClickBlocksAfterCoast 180 ms.** Dropout-Klick tot auch 8 fps.
5. Tests + MARKETING_VERSION 1.5.140 (Build 159).

Aegis 2.1.151: Rank-Rebase nur `#101`, DropDangling Key hält, Jump Cam, PairCommitMiss persist. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-06 (1.5.139)

Helios **1.5.139** (Build 158). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.138: Overlay t>1 Extrapolate, Lerp 24 fps, Thaw 2 Frozen-Miss, Scale-Ring S1. Freeze taut nur FullNext Hit. 24 fps Same-Tick Full / Expand findet die Hand, Frozen-Crop bleibt. Observation-first bindet Gitarre als S1.

## Warum Overlay und Cursor nach 1.5.138 weiter rissen

1. **ROI Thaw nur FullNext Hit.** 24 fps `palmROIMissFullNext` tot. Same-Tick Full Hit lässt lastFrozenROI. Expand findet die Hand, nächster Tick Frozen-Crop. Ping-Pong.
2. **24 fps Expand 2× leer nie Full.** FullNext nur dt≥0,08. Crop-Miss 2 Ticks, Freeze bleibt, Gitarre frisst S1.
3. **Observation-first.** Vision größte Blob zuerst = Gitarre. palmBindHandsFirst fehlte.

## Was 1.5.139 ändert

1. **palmROIThawHit sameTickFull / expandHit.** 24 fps Full und Expand-Hit tauen Freeze.
2. **palmROIMissFullAfter / palmROIMissExpandAdvance.** Full nach 2 Expand auch 24 fps.
3. **palmBindHandsFirst.** HandTracker Observation-Loop bindet Hands vor Prop.
4. Tests + MARKETING_VERSION 1.5.139 (Build 158).

Aegis 2.1.150: PairCommit Hold, Remint Dest Twin, Bins Rank-Rebase, Jump Slider. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-06 (1.5.138)

Helios **1.5.138** (Build 157). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.137: Overlay 90 Hz Bezier, Wrist-MCP Median, Span-Veto. Lerp clampte t≤1 — Overlay freeze 8 fps nach dem Snap. 24 fps snapte (dt 0,04). Frozen-ROI nach Same-Tick Full leer ewig. S2/Prop schrieb den Scale-Ring nach Coast.

## Warum Overlay und Cursor nach 1.5.137 weiter rissen

1. **Overlay t≤1 Freeze.** overlayLerpT clamp 1. Continuity 8 fps: Overlay erreicht die letzte Pose und steht, bis der nächste Vision-Tick kommt. lastVel ungenutzt. Skelett hinkt 125 ms.
2. **Lerp 24 fps tot.** overlayLerpShould dt≥0,05. Continuity 24 fps (0,042) snappt. CADisplayLink 90 Hz zeichnet denselben Knochen.
3. **ROI Thaw nur FullNext Hit.** 24 fps Same-Tick Full leer: Freeze bleibt, FullNext nie. Gitarre im Crop, Hand tot.
4. **Scale-Ring S2 nach Coast.** else-if schrieb lastS1ScaleRing von der nächsten handgroßen Blob. Gitarre 0,29 nach Dropout.

## Was 1.5.138 ändert

1. **overlayVel / overlayExtrapolate / overlayBezier t>1.** LerpT Cap 2,5. Overlay folgt lastVel nach dem Snap.
2. **overlayLerpShould dt≥0,012.** 24 fps lerpt, 90 fps snap.
3. **palmROIThawMiss 2 Frozen-Miss.** Thaw auch ohne FullNext. Nächster Tick Full.
4. **palmScaleMedianKeeps nur S1.** S2/Prop stiehlt den Ring nicht.
5. Tests + MARKETING_VERSION 1.5.138 (Build 157).

Aegis 2.1.149: Pair dest==key persist, Occupied Twin-weg Rank, KeepBoxes PredictOnly Kalman. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-06 (1.5.137)

Helios **1.5.137** (Build 156). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.136: ROI Thaw FullNext, Coast Follow, FullNext Lock. Overlay lerp saß in GestureMath, AppState veröffentlichte Vision-Pose roh. palmScale nur Wrist–Mittel-MCP. Gitarre halluziniert denselben Span.

## Warum Overlay und Cursor nach 1.5.136 weiter rissen

1. **Overlay-Skelett 8 fps.** overlayPalmLerp / overlayLerpT getestet, nie verdrahtet. fireDisplayTick markiert nur den Cursor bei Continuity. TrackingOverlay zeichnet `state.hands` am Kamera-Tick. Continuity 8 fps = Knochen-Ruck.
2. **palmScale Wrist–Mittel allein.** Index/Ring/Klein ignoriert. Gitarre trifft denselben Mittel-MCP-Abstand wie eine Hand. Index–Klein-Span als Fallback war Prop.
3. **Scale ohne Median.** Ein Tick 0,40 (Gitarre/Rumpf) kroch Kalman trotz Clamp. Median 8 Ticks hält die Hand.

## Was 1.5.137 ändert

1. **overlayLerpShould / overlayBezier / overlayLerpHands.** Continuity dt ≥ 0,05: Overlay interpoliert zwei Vision-Poses (Smoothstep). 24 fps snap.
2. **AppState lerpPublishedHands.** CADisplayLink setzt `hands` 90 Hz. Vision-Tick t=0 (from), Fill t→1. Stop/Dunkel wischt Buffer.
3. **palmScaleWristMCP Median** über Index/Mittel/Ring/Klein. **palmScaleSpanVeto** wenn Span Hand und Wrist Prop, oder Span ≥ 1,8×. GestureClassifier Quelle Wrist–MCP.
4. **palmScaleMedian 8 Ticks** vor Kalman in HandTracker lastS1Scale.
5. Tests + MARKETING_VERSION 1.5.137 (Build 156).

Aegis 2.1.148: PairCommit Keeps, Kalman PredictOnly Ghost, KeepBoxes Ghost-Kalman, Jump Pref 0,30–0,50. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-06 (1.5.136)

Helios **1.5.136** (Build 155). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.135: ROI FullNext, Empty-Coast, Kalman Clamp, Pulse-Alive. Freeze nach FullNext blieb alt. Coast-ROI still Center Stage. roiMissFullNext außerhalb Lock.

## Warum Overlay und Cursor nach 1.5.135 weiter rissen

1. **ROI Freeze nach FullNext tot.** FullNext findet die Hand, freezeROI bleibt true (keepHand), lastFrozenROI alt. Nächster Tick Frozen-Miss, FullNext, Ping-Pong.
2. **Coast-ROI still.** applyCoastGhost predictet lastS1, Frozen-ROI bleibt Center-Stage-Crop. Gitarre frisst den Tick.
3. **roiMissFullNext außerhalb Lock.** Analyze nach unlock, reset() unter Lock. Race.

## Was 1.5.136 ändert

1. **palmROIThawHit.** FullNext Hit → lastFrozenROI nil, nächster Tick Live.
2. **palmROICoastFollows / palmROIFollow.** Coast Frozen-ROI folgt Predict.
3. **roiMissFullNext unter erstem Lock.** takeFull Snapshot.
4. Tests + MARKETING_VERSION 1.5.136 (Build 155).

Aegis 2.1.147: Backup remaining, HashTrail remaining Schema 15, KeepBoxes nach Survive, Hungarian wide FillX. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-06 (1.5.135)

Helios **1.5.135** (Build 154). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.134: WarpWriter Token, Need Auto, Vel-Decay, ROI Freeze. Crop-Miss 8 fps nie Full. emitEmpty wischte Coast. Kalman kroch in Prop. Pulse tot = Cursor tot.

## Warum Overlay und Cursor nach 1.5.134 weiter rissen

1. **ROI-Miss nie Full bei Continuity.** palmROIMissAllowsFull `dt < 0,08`. 8 fps dt=0,125. Expand 1,8×, Hand außerhalb Frozen-ROI, S1 tot. Crop frisst den Tick.
2. **emitEmpty umging Coast.** Observation leer → Latch, dann lastS1/ROI nil. Indoor Dropout 1 Frame wischt Keep. Coast lief nur wenn S2/Prop noch da.
3. **palmScaleKalman kroch in Prop.** q=0,18, 0,12→0,29 ohne Jump. Keep 0,29 = Gitarre. Slot-Jump sitzt am Bind, Kalman umgeht ihn.
4. **displayLinkUsesCA hart true.** Pulse 0 (Start) und Pulse tot: Vision skippt, Fill feuert nicht. Cursor tot bis CADisplayLink lebt.

## Was 1.5.135 ändert

1. **palmROIMissFullNext.** 8 fps Expand leer → nächster Tick Full. 24 fps Same-Tick bleibt.
2. **palmCoastEmptyKeeps.** emitEmpty Coast Need Ticks, lastS1/ROI stehen.
3. **palmScaleKalman Clamp.** Hand next ≥ 0,28 → 0,279. Prop-prev kriecht weiter.
4. **displayLinkPulseAlive.** lastDisplayTick > 80 ms tot → Vision warpt. Chip FILL/VISION folgt Pulse.
5. Tests + MARKETING_VERSION 1.5.135 (Build 154).

Aegis 2.1.146: skipKalmanReset Compile, KeepBoxes Miss-Kalman, HashHold remaining, Hungarian n=8, Occupied stored Rank. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-06 (1.5.134)

Helios **1.5.134** (Build 153). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.133: Coast-Vel Return, Joint-Shift, Inject-Skip, Ghost-Coast. Drei Bool-Skips. Need hart Pref. lastVel voll während Coast. warpWriterChip fehlte (Compile). ROI folgt Center Stage.

## Warum Overlay und Cursor nach 1.5.133 weiter rissen

1. **warpWriterChip tot.** HUD und Tests riefen GestureMath.warpWriterChip — Funktion fehlte. 1.5.132/133 Compile-Loch.
2. **Drei Bool-Skips.** Vision/Press/Inject derselbe `linkArmed`-Test. Kein Token, Double-Warp unsichtbar wenn einer driftet.
3. **Coast Need hart Pref.** Indoor 4 fps Dropout 3 Ticks. Pref 2 tot, S1 auf S2/Prop.
4. **lastS1Vel voll während Coast.** Predict 2 Ticks, Vel ungedämpft. Ghost fliegt, Return-Cap fehlte (VelOnHit gab lastVel roh).
5. **ROI folgt Center Stage.** Lock/Coast: Crop wandert auf Gitarre. Jump-Veto dämpft, Crop frisst S1.

## Was 1.5.134 ändert

1. **WarpWriter FILL/VISION Token.** warpWriterSkips. warpWriterChip. Vision/Press/Inject Wrappers.
2. **palmCoastNeedAuto.** dt ≥ 0,20 → Need 3. 8 fps Pref 2.
3. **palmCoastVelDecay** Miss 1 voll, α 0,82. **palmCoastReturnVel** Cap 0,08.
4. **palmROIFreeze / palmROILocked.** Lock oder Coast: last ROI steht. Second-Hand Full bleibt.
5. Tests + MARKETING_VERSION 1.5.134 (Build 153).

Aegis 2.1.145: Miss-Need 2 Auto, JPEG Schema-11 stale, Kalman Restore 2 Ticks, Occupied Yaw+Rank, Hungarian n=6. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-06 (1.5.133)

Helios **1.5.133** (Build 152). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.132: Press-Skip, Fill Press, Coast Predict, Coast Pref, Ghost Alpha, Writer-Chip. Coast-Vel sprang beim Return. Not-Aus injectCursor warpt. Overlay-Knochen still.

## Warum Overlay und Cursor nach 1.5.132 weiter rissen

1. **Coast-Return Vel-Sprung.** lastS1Palm blieb pre-coast. Live-S1: vel = palm − alt. 2 Ticks Weg = Sprung, nächster Dropout fliegt.
2. **Coast-Knochen still.** Predict nur palm. Overlay-Joints 8 fps Halt, Palm wandert.
3. **injectCursor umging den Skip.** Not-Aus / killGrace: 8 fps CGWarp vs Fill 60 Hz. Double-Warp.
4. **Ghost-Alpha `remaining == 0`.** Latch remaining 0 = Coast-Alpha. overlayGhostIsCoast.

## Was 1.5.133 ändert

1. **palmCoastVelOnHit.** Coast-Return hält lastVel, kein Sprung.
2. **lastS1Palm folgt Predict.** Return-Delta klein.
3. **palmCoastShift.** Joints + displayJoints um Palm-Delta.
4. **warpWriterInjectSkips.** Not-Aus skippt CGWarp wenn Link armed.
5. **overlayGhostIsCoast remaining ≤ 0.** Coast remaining 0 explizit.
6. Tests + MARKETING_VERSION 1.5.133 (Build 152).

Aegis 2.1.144: Miss-Coast Kalman/Streak/Faces, JPEG remaining Schema 13. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-06 (1.5.132)

Helios **1.5.132** (Build 151). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.131: Palm-Coast 2 Ticks, ein Warp-Writer. Press-Pfad umging den Skip. Coast-Ghost still. Need hart 2. Overlay voll S1. Kein HUD welcher Writer.

## Warum Overlay und Cursor nach 1.5.131 weiter rissen

1. **Press-Pfad warpt trotzdem.** warpWriterVisionSkips nur den Follow-Pfad. `isMousePressed` moveCursor immer. displayTick mutet Fill bei mouseDown. Klick = 8 fps Vision-Warp, Fill tot.
2. **Coast-Ghost still.** palmCoast kopiert lastPose. 2 Ticks Halt, dann Sprung. lastVel ungenutzt.
3. **Coast need hart 2.** Indoor 4 fps Dropout 3 Ticks. S1 tot, Cursor auf S2/Prop.
4. **Overlay Ghost voll.** TrackingOverlay 0,35 für Latch, Coast sah aus wie Live-S1.
5. **Kein Writer-Chip.** Double-Warp unsichtbar.

## Was 1.5.132 ändert

1. **warpWriterPressSkips.** Press-Pfad skippt wie Follow wenn CADisplayLink armed.
2. **displayTickFillsPress.** Fill während mouseDown, nicht AX-Drag.
3. **palmCoastPredict.** Ghost-Palm += lastVel, Cap 0,08 Bild.
4. **palmCoastNeedPref 1–4.** ControlPanel Slider. Indoor 3.
5. **overlayGhostAlpha** Coast 0,50 / Latch 0,35. **warpWriterChip** FILL/VISION.
6. Tests + MARKETING_VERSION 1.5.132 (Build 151).

Aegis 2.1.143: Miss-Coast 1 Frame, Occupied Spatial-emit, JPEG Cap, Kalman Schema 12, HungarianX n=5. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-06 (1.5.131)

Helios **1.5.131** (Build 150). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.130: Scale-Jump-Veto, Fill-Cap UUID, Slot-Kalman, DisplayLink Hz. S1-Miss 1 Tick stahl lastPalm von S2. Vision-Tick und displayTick beide CGWarp.

## Warum Overlay und Cursor nach 1.5.130 weiter rissen

1. **S1-Miss stiehlt lastS1.** Continuity droppt S1, Frame hat S2/Prop. else-if schrieb lastS1Palm von S2. Cursor sprang.
2. **Zwei Warp-Writer.** placeCursor/moveCursor auf dem Vision-Tick und displayTick. Double-Warp an der Seam, 8 fps vs 60 Hz.

## Was 1.5.131 ändert

1. **palmCoastKeepsS1 2 Ticks.** Ghost-S1, lastS1 nicht von S2. Tick 3 gibt frei.
2. **warpWriterVisionSkips.** CADisplayLink armed: nur displayTick warpt. Vision setzt HUD/cursorSmooth.
3. Tests + MARKETING_VERSION 1.5.131 (Build 150).

Aegis 2.1.142: Remint vor Survive, Occupied Spatial, JPEG persist Schema 11. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-06 (1.5.130)

Helios **1.5.130** (Build 149). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.129: Fill-Cap Slider, Pinch Cursor-px, Keep-Bit je Slot. Keep-Hyst 0,29 ließ Gitarre S1 stehlen. Fill-Cap per Breite, nicht UUID. CADisplayLink hart 120. Pad-Slider ohne Schirmname. PalmSlot.scale roh.

## Warum Overlay und Cursor nach 1.5.129 weiter rissen

1. **slotKeepBit Hyst ohne Scale-Jump.** S1 0,12 → 0,29 Keep true. Gitarre bindet S1. slotBindSkipsProp keep:true blieb.
2. **PalmSlot.scale roh.** Kalman nur lastS1. bindSlot las 0,12, Live 0,29, Hyst fraß den Sprung.
3. **fillCapPrefOf per Breite.** Clamshell: Studio-28 auf dem Laptop wenn lastScreen noch 5K-Width im Kopf, UUID fehlte.
4. **displayLinkPreferredHz 120 hart.** Studio 60 skippt vsync, Cursor an der Seam stottert.
5. **destEdgePadMap UI lastScreenID still.** Slider schreibt UUID, Label zeigte nur px.

## Was 1.5.130 ändert

1. **slotScaleJumpVeto 0,12.** Keep tot bei Objektwechsel. Gitarre 0,29 stiehlt S1 nicht.
2. **PalmSlot.scale Kalman.** bindSlot prevScale, nicht roh.
3. **fillCapByUUID + fillCapMap.** Prefs persist. Laptop/Studio Defaults bleiben Floor.
4. **displayLinkHzOf.** NSScreen.maximumFramesPerSecond, Floor 30 Cap 120. Arrangement re-arm.
5. **destEdgePadScreenName.** ControlPanel Chip + localizedName.
6. Tests + MARKETING_VERSION 1.5.130 (Build 149).

Aegis 2.1.140: Schema 10 StreakBox, Kalman Remint, JPEG per Hash, HungarianX n=4. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-06 (1.5.129)

Helios **1.5.129** (Build 148). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.128: CADisplayLink 120, Kalman-Scale, Pad-UUID, Keep je Hand. Fill-Cap hart 12/28. pinchClickVsDrag unverdrahtet. slotBindSkipsProp keep:true immer.

## Warum Overlay und Cursor nach 1.5.128 weiter rissen

1. **fillCapPref hart 12/28.** Continuity 8 fps Laptop-Flick tot, 5K Warp und Fill vermischt. Kein Slider.
2. **pinchClickVsDrag tot.** GestureEngine prüfte `pinchDragMoved` Palm 0,05. Click-Lock stahl Drag, 8 fps Zittern klickte.
3. **slotBindSkipsProp keep:true immer.** Gitarre 0,29 (Hyst) band S1. PalmSlot ohne Scale — Keep-Bit nicht persistiert.

## Was 1.5.129 ändert

1. **fillCapPrefOf + Slider.** Laptop 8–24 / Studio 12–48. Prefs persist. displayTick restCap.
2. **pinchClickVsDrag Cursor-px.** Origin `pinchCursor0`, Click <6, Drag ≥12, Band tot. pressLocksClick bleibt BUTTON.
3. **slotKeepBit je Slot.** PalmSlot.scale. bindSlot prev Keep. Leer prev keep:true — Test „Keep-Hand darf S1“ 0,29 hält. prev false: Gitarre 0,29 stiehlt S1 nicht.
4. Tests + MARKETING_VERSION 1.5.129 (Build 148).

Aegis 2.1.139: Rank Spatial Dist, HungarianX, Hamming Solo, JPEG TTL Pref. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Die drei Prefs sitzen seit 1.5.127 auf `main`. Nur `main`.

# Helios + Aegis — Analyse 2026-09-06 (1.5.128)

Helios **1.5.128** (Build 147). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.127: lastScreenID folgt, Overlap auto, Faust 2-Frame, Reanchor, bugfix-Prefs. Drei Uhren, Prop-Scale, ein Pad für Laptop+5K.

## Warum Overlay und Cursor nach 1.5.127 weiter rissen

1. **Drei Uhren.** Continuity oft 8 fps, Fill `Timer.common` ~90 Hz coalesced gegen vsync, Overlay an Kamera-Rate. Reanchor sitzt, vsync fehlte.
2. **palmScale 8 fps um 0,28.** Keep-Hysterese allein: Gitarre Observation-first S1, echte Hand S2. Kalman fehlt.
3. **destEdgePad ein Slider.** Laptop 24 auf dem 5K. Clamshell-Wake ohne Arrangement-Hash.
4. **Keep nur lastS1.** Gitarre als S2 stiehlt den Zeiger. Pinch-Click und Drag dieselbe Hysterese.
5. **Fill-Cap unabhängig von Breite.** Warp-Cap und Fill vermischt. Overlay 8 fps ohne Lerp.

## Was 1.5.128 ändert

1. **CADisplayLink 120 Hz.** `DisplayPulse` vsync. Timer-Retarget nur wenn Link tot.
2. **palmScaleKalman** q=0,18. HandTracker lastS1Scale. Prop kriecht, Hand bleibt.
3. **destEdgePadMap je Display-UUID.** Prefs persist. Arrangement-Hash → pollFocus Recalib.
4. **pointerKeepPerHand.** S1 vor S2. Pinch Click <6 px, Drag ≥12, Band tot.
5. **fillCapPref** Laptop 12 / 5K 28. Overlay-Lerp zwischen zwei Vision-Poses.
6. Tests + MARKETING_VERSION 1.5.128 (Build 147).

Aegis 2.1.138: Schema 9 PairStreak/Commit/Streak, Hungarian n=3, Seen remaining. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Die drei Prefs sitzen seit 1.5.127 auf `main`. Nur `main`.

# Helios + Aegis — Analyse 2026-09-06 (1.5.127)

Helios **1.5.127** (Build 146). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.126: lastScreenID Relativ-Seed, Prop-Alloc keep:false. Seed hielt current für immer — Laptop-Map auf dem 5K.

## Warum Overlay und Cursor nach 1.5.126 weiter rissen

1. **`screenKeySeed` sticky.** `if current { return current }`. Relativ-Pfad seedete Laptop und folgte nie. SpaceMap.load blieb Laptop, destClampMap Latch korrekt, Homographie falsch.
2. **Overlap hart 32 px.** 16 px Cocoa-Seam vs 40 px Pad zwei Welten. destEdgeNearest nahm Interior-Gap 32 auch ohne Overlap.
3. **Faust 8 fps = Klick-Burst.** Ein Frame Faust zündet Grab. Continuity zittert um Pose.
4. **CGWarp ohne Ground-Truth.** displayTick 90 Hz coaster, NSEvent.mouseLocation nie. Drift wächst.
5. **bugfix 1.5.8 Prefs fehlten.** Dead-Man 1,6 s fest, Fling 120 ms, Wischen auch Faust.

## Was 1.5.127 ändert

1. **`screenKeySeed` folgt.** Interior klar auf dem Nachbarschirm (innNext > Gap, innCur < Gap) wechselt. Seam hält current.
2. **`destEdgeOverlapGap`.** Intersection aus CGDisplayBounds, Floor 16 Cap 64. destEdgeNearest nutzt max(32, Overlap).
3. **`fistClickDebounce` 2 Frames.** Continuity-Zittern kein Burst.
4. **`pointerReanchor`.** displayTick vs NSEvent.mouseLocation, RMS > 8 px, nicht während Drag/Pinch.
5. **Dead-Man Pref 1,6–8 s, Fling-Fenster 120–550 ms, Wischen nur offene Hand.** Aus bugfix 1.5.8, nicht gemergt.
6. **`NSApplication.didChangeScreenParameters`** → pollFocus (SpaceMap + Overlay).
7. Tests + MARKETING_VERSION 1.5.127 (Build 146).

Aegis 2.1.137: PairLast persist, NameLock remaining, HoldTrail UUID, FillX Pref, AssignLive atomar. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-06 (1.5.126)

Helios **1.5.126** (Build 145). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.125: destClampMap Latch, Keep 0,03, Naht-Hold Pref. Relativ-Pfad schrieb lastScreenID nie. slotAllocMinID(keep:true) mintete Gitarre 0,29 als S1.

## Warum Overlay und Cursor nach 1.5.125 weiter rissen

1. **lastScreenID nur im Absolut-Pfad.** `clampMapped` / `placeCursor` Relativ ließen `lastScreenID = nil`. `destClampMapHolds` sah current=nil, 2 Screens → Map tot. `SpaceMap.load` ohne Screen-ID. Laptop-Map und 5K blieben zwei Welten.
2. **`slotAllocMinID` immer keep:true.** Hart 0,28 + Hyst 0,03 = 0,29 mintet S1. Gitarre nach Continuity-Zittern wieder Overlay-S1. Keep gehört zum Rebind, nicht zum Neu-Alloc.
3. Drei Uhren bleiben: Continuity oft 8 fps, Fill Timer.common ~90 Hz, Overlay an Kamera-Rate. CADisplayLink fehlt. Eine Homographie für Laptop+5K. CGWarp ohne `NSEvent.mouseLocation`-Reanchor.

## Was 1.5.126 ändert

1. **`screenKeySeed`.** Relativ-Pfad seedet lastScreenID aus destEdgeNearest. current bleibt. `clampMapped` + `placeCursor`.
2. **`slotAllocMinID(keep: false)` Default.** Neu 0,29 = S2. Keep 0,29 nur explizit. Prop mintet nicht S1.
3. Tests + MARKETING_VERSION 1.5.126 (Build 145).

Aegis 2.1.136: HoldMove overwrite, Twin-Yaw-Tie, Schema 7 leftoverHold/LastHash/NameLockHeld. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`. Prefs aus bugfix (Fling-Fenster, Dead-Man 2–8 s, Wischen nur offene Hand) bleiben in VORSCHLAEGE.

# Helios + Aegis — Analyse 2026-09-06 (1.5.125)

Helios **1.5.125** (Build 144). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.123: Prop nie S1, 40 px Overlap 5K-Pad, destEdgeScreenHolds. 1.5.124 Review ohne Code. Cursor weiter Laptop-Map, Hand 0,29 = Prop.

## Warum 1.5.123 weiter kroch

1. **`destClampMapHolds` `return true` bei leerem currentScreenID.** Relativ-Pfad schreibt `lastScreenID` spät. Laptop-Map klemmt den 5K. Kommentar sagte Latch 1 Screen, Code hielt immer.
2. **Map-ID match = Mauer.** Punkt schon auf dem 5K, destClampScreen gab mapBounds zurück. destEdgeNearest tot.
3. **`clampMapped` `cursorSmooth ?? p`.** Fill auf dem Laptop, Ziel auf dem 5K: destClampScreen sah Laptop, destClamp klemmt den 5K-Punkt zurück.
4. **Hart 0,28.** Continuity 8 fps zittert. Hand 0,29 mintet S2 (`slotAllocMinID`), lastS1 Keep stirbt.
5. **destEdgeSkip 160 ms fest.** 80 ms stirbt vor 8 fps. REVIEW 1.5.124: Pref fehlt.

## Was 1.5.125 ändert

1. **`destClampMapHolds` Latch.** Ohne currentScreenID nur 1 Screen.
2. **`destClampSameScreen`.** Map-ID match, Punkt auf dem Nachbarschirm: Map keine Mauer.
3. **`clampMapped` Punkt = Ziel**, nicht cursorSmooth.
4. **`palmHandScaleHyst` 0,03.** Keep 0,29 S1, 0,32 tot. slotAllocMinID / slotBindSkipsProp / ROI / lastS1.
5. **`destEdgeSkipPref` 40–240 ms.** ControlPanel „Naht-Hold“.
6. Tests + MARKETING_VERSION 1.5.125 (Build 144).

Aegis 2.1.135: leftoverStoredHashMerge, leftoverHoldByHashRescue. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`. Prefs aus bugfix (Fling-Fenster, Dead-Man 2–8 s, Wischen nur offene Hand) bleiben in VORSCHLAEGE.

# Helios + Aegis — Analyse 2026-09-06 (1.5.123)


Helios **1.5.123** (Build 143). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.122: Prop-S2 Crop, Clamp destEdgeNearest. Gitarre blieb S1. 40 px Cocoa-Overlap max-Interior Laptop. SpaceMap destBounds fromCocoa(frame), destEdge CGDisplayBounds.

## Warum Overlay und Cursor nach 1.5.122 weiter auseinander liefen

1. **Observation-first S1.** Vision größte Blob zuerst = Gitarre. `palmROISlotPalm` croppt S2, `bindSlot` mintet Prop als S1. Overlay cyan, Cursor, Faust-Arm: Gitarre.
2. **`pointerKeepInPool` first.** Pool-Reihenfolge = Observation. Ohne Keep = Gitarre auch als S2.
3. **`destEdgeNearest` all interiors < Gap.** 40 px Cocoa-Overlap: 4 px auf dem 5K, 36 px Laptop. max-Interior = Laptop-Pad. displayTick 90 Hz dämpft den 5K.
4. **SpaceMap `fromCocoa(s.frame)` vs `quartzBounds`.** Homographie und destEdge zwei Seam-Welten. Kalib visibleFrame Cocoa, destEdge Hardware.

## Was 1.5.123 ändert

1. **`slotAllocMinID` / `slotBindSkipsProp`.** Prop nie S1. Hand mintet S1, Gitarre S2.
2. **`pointerKeepPrefersHand`.** Pool S1 vor Observation-first. Keep bleibt.
3. **`destEdgeNearest` min Interior < Gap → größerer Schirm.** 40 px Overlap 4 px auf dem 5K = 5K-Pad.
4. **`destEdgeScreenHolds`.** displayTick hält Zielschirm 160 ms nach Cross.
5. **`ScreenGeometry.visQuartz`.** Kalib und linear von CGDisplayBounds + Menüleiste. `SpaceMap.load` `quartzBounds`.
6. Tests + MARKETING_VERSION 1.5.123 (Build 143).

Aegis 2.1.133: HoldByHash Solo, AssignLiveGate UI. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-06 (1.5.122)

Helios **1.5.122** (Build 142). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.121: Prop-S1 Full. `palmROISecondNils` immer true. destClampScreen `screens.first` inset −8. screenSeamHolds 24 px Wall auf den 5K.

## Warum Overlay und Cursor nach 1.5.121 weiter auseinander liefen

1. **Gitarre + Hand = immer Full.** `roiSecond = liveCount >= 2`. Prop zählt. `palmROISecondNils` true → `palmVisionROI` nil. 1.5.121 SlotPalm nil war tot — Full fraß den 8-fps-Tick, Overlay weiter Gitarre.
2. **`palmROISlotPalm` Prop-S1 `return nil`.** S2 (echte Hand) nie Crop. Continuity 8 fps Full + Gitarre als S1.
3. **`lastS1Palm` auch Prop.** Keep-Scale 0,42, nächster Tick Full.
4. **`destClampScreen` `screens.first` + inset −8.** Laptop+5K: 4 px auf dem 5K = Laptop. `destClamp` klemmt den Cursor auf den Laptop — destEdgeSkip/Cross wirkungslos.
5. **`screenSeamHolds` 24 px ohne Neighbor.** 15 px auf dem 5K hält last=Laptop. Relative-Pfad kommt nie rüber.
6. **`destEdgeNearest` max-Interior bei Overlap.** 16 px Seam: 4 px auf dem 5K, Laptop-Interior größer → Laptop-Pad.

## Was 1.5.122 ändert

1. **`palmROISlotPalm` Prop → erste handgroße (S2).** Nur Prop allein Full.
2. **`palmROISecondHands`.** Full nur bei ≥2 handgroßen. Gitarre zählt nicht.
3. **`lastS1` nur handgroß.** Prop nicht Keep.
4. **`destClampScreen` destEdgeNearest.** Kein screens.first.
5. **`screenSeamHolds(screens:)`.** Anderer Schirm unter dem Punkt = Hold tot. Void hält.
6. **`destEdgeNearest` Overlap:** alle Interior < Gap → größerer Schirm (5K).
7. **`clampQuartz` / `screenContaining` quartzBounds + destEdgeNearest.** Cocoa-frame first-contains tot.
8. Tests + MARKETING_VERSION 1.5.122 (Build 142).

Aegis 2.1.132: Pair bleibt nach AssignLive, Value-Remint, AssignLive x-Rescue. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-06 (1.5.121)

Helios **1.5.121** (Build 141). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen.

1.5.119: ROI aus (Vollbild, 8 fps Tick tot). 1.5.120: destEdgeSkip 160 ms, Cross Snap. Overlay-Pfad unverändert seit 1.5.40.

## Warum Overlay und echte Hand weiter auseinander liefen

1. **Prop-S1.** Gitarre/Rumpf (scale ≥ 0,28) wird S1. Crop um last-S1: echte Hand außerhalb. Continuity 8 fps hält den Crop — kein Skelett.
2. **Zweit-Hand 8 fps.** `palmROISecondNils` nur `dt < 0,08`. 125 ms Tick hält S1-ROI, Kill-Hand tot.
3. **1.5.119 Workaround.** `palmVisionUsesROI` false = immer Full. Langsam, zwei Hände + Gitarre fressen den Tick.
4. **1.5.117 Remap.** Nur wenn BBox aus der ROI ragt. Image-space der Gitarre sitzt IN der ROI → kein Map.

## Was 1.5.121 ändert

1. **`palmScaleIsHand` 0,035…0,28.** Prop-S1: `palmROISlotPalm` nil → Full.
2. **last-S1 keep nur handgroß.** Sonst erste Hand oder nil (Full).
3. **`palmVisionUsesROI` true.** Crop nur um Hand, nicht Prop.
4. **`palmROISecondNils` immer true.** Zweite Hand Full auch bei 8 fps.
5. Tests (Gitarre S1 → nil, 8 fps zwei Hände Full) + MARKETING 1.5.121 (Build 141).

Aegis 2.1.131: Pair HoldMove + Value-Remint, x-Rescue 0,28. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-06 (1.5.120)

Helios **1.5.120** (Build 140). Nur `main`. Repo privat. `bugfix` ist 1.5.8 — nichts mergen. Prefs aus bugfix (Fling-Fenster, Dead-Man 2–8 s, Wischen nur offene Hand) bleiben in VORSCHLAEGE.

## Warum 1.5.119 noch kroch / Overlay nach Cross riss

1. **`destEdgeSkipNow` 80 ms.** Continuity 8 fps = 125 ms/Tick. Hold stirbt vor dem nächsten Kamera-Frame. displayTick 90 Hz dämpft den 5K 45 ms lang — Cursor stottert nach der Naht.
2. **`screenBlend` 0,12 s nach Screen-Wechsel.** destEdgeCross snappt auf den 5K, Blend interpoliert 120 ms zurück auf den Laptop.
3. **`pointerPredict` nach Cross.** Vel = Sprung über die Seam. Predict addiert noch 40 ms Overshoot.
4. **`screenKey` first-contains.** 16 px Überlapp: lastScreenID = Laptop obwohl der Cursor auf dem 5K sitzt. Blend/Map laden den falschen Schirm.
5. **`destEdgeMulX` toward-Noise.** 1–3 px Jitter wählt maxX obwohl minX näher ist (gestapelte Monitore, 8 fps).
6. **`palmVelScreen` roh bei 8 fps.** 125-ms-Sprung, destEdgeStep sieht JUMP statt Coast.
7. **ControlPanel Pad `screens.first` + inset −8.** Laptop-Pad auf dem 5K analog destEdgeNearest vor 1.5.113.
8. **NSScreen.frame Cocoa→Quartz.** 16 px Seam oft Conversion, nicht Hardware. `quartzBounds` darf CGDisplayBounds nicht nochmal `fromCocoa` flippen — sonst 5K unter dem Laptop.

## Was 1.5.120 ändert

1. **`destEdgeSkipHold`.** Default 160 ms, max(pref, 1,25·frameDt), Cap 240 ms. Engine reicht rawFrameDt.
2. **`screenBlendSkipsCross`.** Cross: kein Blend, Snap.
3. **`pointerPredictSkipsCross`.** Cross: Predict tot.
4. **`screenKey` destEdgeNearest.** Innerster Schirm, nicht screens.first.
5. **`destEdgeTowardOf` 4 px.** Noise = nearer-edge. destEdgeMulX/Y + HasNeighbor.
6. **`palmVelScreenEMA`.** 8 fps α 0,45, 24 fps α 0,55. JUMP bleibt instant 0.
7. **`ScreenGeometry.quartzBounds` / `quartzScreens`.** CGDisplayBounds roh (schon Quartz). Relativ-Schritt und Clamp dieselbe Quelle.
8. **ControlPanel Pad destEdgeNearest.**
9. Tests + MARKETING_VERSION 1.5.120 (Build 140).

Aegis 2.1.130: Hash-Rescue wenn x > Pad, Tick-Copy nach Transfer. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-05 (1.5.119)

Helios **1.5.119** (Build 139). Nur `main`. Repo privat. Overlay-Pfad unverändert seit 1.5.40.

## Warum 1.5.117 noch scheiße war

1. **`vis()` / `fitted()` nie das Problem.** 1.5.66, 1.5.99, 1.5.118, 1.6: identisch. Y-Flip Vision, Letterbox auf dem Preview.
2. **ROI ab 1.5.67.** Crop um last-S1. 1.5.92: 8 fps hält den Crop, zweite Hand kein Full. Continuity sieht die Gitarre als größere Hand → S1. Echte Hand unten rechts außerhalb des Crops → kein Skelett drauf.
3. **1.5.117 Remap.** Nur wenn BBox aus der ROI ragt. Image-space der Gitarren-Pose sitzt IN der ROI → kein Map, Crop bleibt, gleiche Abweichung.
4. **Faust S2.** isExtended seit 1.5.109/116 mit PIP 18° + Span 1,52. Gemischte/falsche Pose plus Slot-Jump.

## Was 1.5.119 ändert

1. **`palmVisionUsesROI` false.** Wie 1.5.66 und 1.6: Vollbild.
2. Tests + MARKETING 1.5.119 (Build 139).

`bugfix` mergen: nein. Nur `main`. Repo bleibt privat.

# Helios + Aegis — Analyse 2026-09-05 (1.5.118)


Helios **1.5.118** (Build 138). Nur `main`. Repo privat.

## 1.5.117 → 1.5.118 (DMG, Rechte)

1. **GitHub-HTML statt Image.** Privates Repo: der Latest-Link liefert Login/404-HTML als `.dmg`. Finder öffnet das nicht.
2. **Ad-hoc auf dem Image.** `codesign -` auf UDZO: Finder „kann nicht geöffnet werden“.
3. **Rechte.** LICENSE Alle Rechte vorbehalten, Tony Rogers. Source-zip räumt nichts ein.

## Was 1.5.118 ändert

1. LICENSE proprietary. Copyright in Info.plist.
2. DMG unsigniert, plus Helios.zip.
3. Tests unverändert + MARKETING 1.5.118 (Build 138).

`bugfix` mergen: nein. Nur `main`. Repo bleibt privat.

# Helios + Aegis — Analyse 2026-09-05 (1.5.117)


Helios **1.5.117** (Build 137). Nur `main`. Overlay-Skelett ≠ Hand.

## 1.5.116 → 1.5.117 (warum das Tracking das ganze Bild spannte)

1. **`regionOfInterest` ohne Remap.** `palmVisionROI` croppt um S1. `recognizedPoints` bleiben 0…1 der ROI. Overlay `vis()` nimmt Vollbild: Wrist unten links, Spitzen oben, echte Hand unten rechts.
2. **Palma in ROI-Raum.** Frame 1 volles Bild (ok), Frame 2 Palma ~0,5/0,5 der Crop = Bildmitte. Slot-Dist mintet S2. Pose auf Mischkoordinaten = Faust. One-Euro mischt Thumb (Bild) und restliche Finger (ROI).
3. **8 fps hält S1-ROI.** Continuity geht nicht Full-Pass. Der Crop sitzt fest, das Overlay bleibt falsch.

## Was 1.5.117 ändert

1. **`visionPointFromROI`.** `roi.origin + p * roi.size`. Full-ROI Identität.
2. **`visionROIMap`.** Map nur wenn die BBox aus der ROI ragt. Image-space (Apple-Doku) nicht doppelt stauchen.
3. **HandTracker** mappt sofort nach `recognizedPoints`, vor Chirality/Slot/Smoother/Occlusion.
4. Tests + MARKETING_VERSION 1.5.117 (Build 137).

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-05 (1.5.115)

Helios **1.5.115** (Build 135). Aegis **2.1.129**. Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.114: Snap-Quartz, Focus aus, Kralle 22°. destEdgeCrosses first-contains. FillAxis ohne pad. Seam-Jitter 1 px.

## 1.5.114 → 1.5.115 (warum Cursor auf dem 5K noch kroch / Seam stotterte)

1. **destEdgeCrosses first contains.** destEdgeNearest innerster seit 1.5.113. Crosses nahm `screens.first`. Laptop+5K überlappen 16 px: Punkt auf dem 5K = Laptop. FillToward/Step sehen keinen Cross. destEdge dämpft mit Laptop-Pad auf dem 5K.
2. **Kein Cross-Hold.** 1 px Jitter an der Seam: Cross an/aus jedes Frame. Fill 90 Hz dämpft, lässt, dämpft — Cursor stottert.
3. **destEdgeFillAxis ohne pad.** Hart 40, 5K-Slider tot. displayTick bleibt destEdgeFill (X+Y per-axis) — FillAxis nur X wäre Top-Void-Regression.

## Was 1.5.115 ändert

1. **`destEdgeCrosses` destEdgeNearest.** from/to innerster. Gap dist ≤ 32, Void same-screen.
2. **`destEdgeSkipNow` 80 ms.** Engine Kamera-Tick, Relativ, Fill.
3. **`destEdgeFillAxis(pad:)`.** Slider sitzt. Tests.
4. Tests + MARKETING_VERSION 1.5.115 (Build 135).

Aegis 2.1.129: AssignLive 1+1, Pair/Streak Remint, StreakBox Live. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-05 (1.5.113)

Helios **1.5.113** (Build 133). Aegis **2.1.128**. Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.112: destEdgeHasNeighbor Probe, Coast toward, TeleportX/Y, Pad-Fallback 2560, Chip nearer-edge. destEdgeNearest first contains. FillAxis ohne toward. HasNeighbor toward=0 tot.

## 1.5.112 → 1.5.113 (warum 5K-Landung noch Laptop-Pad nahm / FillAxis Inbound tot / Seam still kroch)

1. **destEdgeNearest first contains.** Laptop und 5K überlappen 16 px. screens.first = Laptop. destEdgeHasNeighbor home = Laptop, Pad 36, Probe falsche Kante. Cursor auf dem 5K kriecht.
2. **destEdgeFillAxis ohne toward/screens.** 1.5.110 Fill inbound frei, FillAxis min(left,right) am x=8. Y frei, X tot.
3. **destEdgeHasNeighbor toward=0.** palmVelScreenFresh tot nach Landung. ChipOf synthetisiert nearer-edge, Coast/Fill nicht. τ gekürzt 8 px hinter der Seam.

## Was 1.5.113 ändert

1. **`destEdgeNearest` innerster** contains, Tie größerer Schirm. `destEdgeInterior`.
2. **`destEdgeFillAxis` toward + NeighborMul + screens.** Inbound frei, Void dämpft, Seam Gain 1.
3. **`destEdgeHasNeighbor` toward≈0 = nearer-edge.** Seam still Gain 1. Void still dämpft.
4. Tests + MARKETING_VERSION 1.5.113 (Build 133).

Aegis 2.1.128: AssignLive Remint, leftoverHold UUID/Bins Remint. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-05 (1.5.112)

Helios **1.5.112** (Build 132). Aegis **2.1.127**. Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.111: palmLateralityCode `right:`. destEdgeStep dämpfte 20 px vor der Seam. Coast-τ ohne toward. palmVel hypot 0-setzte Y. PadNow Fallback 1440.

## 1.5.111 → 1.5.112 (warum Cursor 20 px vor der Naht kroch / Fill-Y nach JUMP tot / Clamshell-Pad 36)

1. **destEdgeStep ohne Nachbar.** FillToward sitzt am 90-Hz-Fill, nicht am 8-fps-Kamera-Tick. `from` 20 px vor der Seam, `to` noch auf dem Laptop → destEdgeMulX Gain ~0,43. Cursor kriecht, obwohl 5K 8 px hinter der Kante liegt.
2. **Coast-τ destEdgeMulX ohne toward.** Inbound 8 px: min(left,right)=8, Gain 0,48, τ 21 ms statt voll. Rückweg nach 5K-Landung klebt.
3. **palmVelScreenTeleport hypot.** X-Sprung 400 px setzte Y-Coast 0. destEdgeFillAxis braucht Y entlang der Bezel.
4. **destEdgePadWidthOf [] = 1440.** Clamshell + Studio, `NSScreen.screens` leer beim Launch: Pad 36 statt 5K 64.
5. **destEdgeChipOf ohne screens / OR beider Kanten.** HUD zeigte EDGE an der Seam (Mauer) oder blendete Void-EDGE, weil die Gegenseite einen Nachbarn hat.

## Was 1.5.112 ändert

1. **`destEdgeHasNeighbor` / `destEdgeNeighborMul`.** Probe 8 px hinter der Kante, Dist ≤ Gap 32. Seam-Outbound Gain 1. Void behält Mul. Pad und Lead entkoppelt.
2. **`destEdgeVel` / `Step` / `Fill(screens:)`.** Engine Kamera-Tick und Fill reichen screensNow.
3. **Coast-τ `toward` + HasNeighbor.** Inbound und Seam voll, Void dämpft.
4. **`palmVelScreenTeleportX/Y` + `palmVelScreenOf(teleportX:teleportY:)`.** Achsen getrennt.
5. **`destEdgePadWidthOf` Fallback 2560. `destEdgePadNow` fallback 2560.**
6. **`destEdgeChipOf` nearer-edge + screens.** Seam kein EDGE, Void EDGE X. Engine reicht screens.
7. Tests + MARKETING_VERSION 1.5.112 (Build 132).

Aegis 2.1.127: leftoverXAmbiguous relativ 2·d, FillX Spread. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.


# Helios + Aegis — Analyse 2026-09-05 (1.5.108)

Helios **1.5.108** (Build 128). Aegis **2.1.126**. Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.107: destEdge exact+Cross, Step-Pad, Laterality-Veto, Chip-Keep. destEdgeMulX = min(left,right). FillToward Lead 48 < 5K-Pad 64. Chip-Cap reordert. ForEach id:\.self.

## 1.5.107 → 1.5.108 (warum Cursor auf dem 5K noch kroch / Rückweg Laptop tot / HUD sprang)

1. **destEdgeMulX/Y min(left,right).** Nach Laptop→5K sitzt der Cursor 4–20 px hinter der Seam. Inbound (weg vom Rand, zur 5K-Mitte) war dist=8, Gain 0,39. Fill 90 Hz kroch. destEdgeFillToward skippt nur, wenn Lead den Nachbarschirm trifft — nach der Landung bleibt Lead auf dem 5K.
2. **destEdgeFillToward lead 48, Pad 64.** Rückweg 5K→Laptop: 50 px vor der Seam, Lead 48 bleibt auf dem 5K, destEdge dämpft den Cross.
3. **destEdgeCrosses beide contains.** Seam-Lücke (Displays nicht bündig): `to` in der Gap → false → destEdge klebt.
4. **overlayChipCap ranked.prefix.** JUMP nach vorn, HUD-Chips tauschen jede Overflow-Frame die Lage. ForEach `id: \.self` crasht bei Duplikat.

## Was 1.5.108 ändert

1. **`destEdgeMulX/Y(toward:)`.** Nur die Kante in Bewegungsrichtung. Inbound = Gain 1. Void-Outbound dämpft.
2. **`destEdgeFillLead(pad:)`** = max(48, pad+16). 5K Lead 80. FillToward am Engine-Tick.
3. **`destEdgeNearest` / `destEdgeCrosses` Gap.** Lücke ≤ 32 px zum *anderen* Schirm = Cross. Void bleibt dämpfen.
4. **`overlayChipCap` Keep-Set, Original-Reihenfolge.** HUD ForEach `id: \.offset`.
5. Tests + MARKETING_VERSION 1.5.108 (Build 128).

Aegis 2.1.126: FillX greedy Dist, HoldX Occupied+Spread. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-05 (1.5.107)

Helios **1.5.107** (Build 127). Aegis **2.1.124**. Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.106: destEdgeScreenAt inset −8, Pad screens.first, destEdgeStep ohne Pref, Chip prefix, Laterality nur +0,10.

## 1.5.106 → 1.5.107 (warum Cursor auf dem 5K noch kroch / S1↔S2 / HUD JUMP tot)

1. **destEdgeScreenAt inset −8.** Laptop und 5K überlappen 16 px an der Seam. `screens.first` = Laptop. 4 px auf dem 5K = Laptop-Pad 36. Fill Gain 0,35.
2. **destEdgeStep pad Default 40.** Slider 24–160 tot am Kamera-Tick. Fill nutzte destEdgePadNow, Step nicht.
3. **from auf Laptop, to auf 5K.** destEdgeStep/Fill dämpfen mit Laptop-Pad — Seam ist eine Mauer.
4. **slotLateralityDist +0,10.** Zwei .left, Match-Slot 0,12 entfernt, Mismatch 0,05+0,10=0,15 gewinnt. S1↔S2.
5. **overlayChipCap prefix.** JUMP/OCC hinter HP/LAT. Duplikate crashen `ForEach id:\.self`.

## Was 1.5.107 ändert

1. **`destEdgeScreenAt` exact + nearest.** Kein Seam-Steal. **`destEdgePadAt`** dieselbe Screen-Quelle.
2. **`destEdgeStep(pad:)`** = destEdgePadNow. Slider sitzt am Kamera-Tick.
3. **`destEdgeCrosses` / `destEdgeSkipsCross` / `destEdgeFillToward`.** Seam ohne Dämpfer.
4. **`slotLateralityMatches` / `slotLateralityPrefers`.** Match-Slot sperrt Mismatch.
5. **`overlayChipKeep`.** Danger zuerst, unique.
6. Tests + MARKETING_VERSION 1.5.107 (Build 127).

Aegis 2.1.124: FillX Pad 0,12, TWIN 1/2/3, Gate Keep. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-05 (1.5.106)

Helios **1.5.106** (Build 126). Aegis **2.1.123**. Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.105: Claim-Flip tot, OCC Palm-Follow, Pad max-Screen. destEdge steal zuerst. HUD-Stack unbegrenzt. bindSlot nur Palm-Dist.

## 1.5.105 → 1.5.106 (warum Cursor auf dem 5K noch kroch / HUD den Cursor deckte / S1↔S2 nach Nähe)

1. **destEdgeScreen steal zuerst.** Seam-Hysterese hält Laptop während der Cursor auf dem 5K ist. destEdgePadNow(steal) = Laptop-Pad. Teleport-Cap 40 px auf dem 5K = JUMP·MUTE.
2. **destEdgePadWidthOf = max.** ControlPanel immer 5K-Pad, auch auf dem Laptop. Over-Dämpfer.
3. **HUD Chip-Stack unbegrenzt.** HP/VEL/JUMP/MUTE/LAT/OCC/PREDICT deckt den Cursor.
4. **bindSlot nur Palm-Dist.** Zwei .left-Obs, nächster Slot nach Nähe = S1↔S2.

## Was 1.5.106 ändert

1. **`destEdgeScreenAt` / `destEdgePadAt`.** Screen unter dem Cursor. Teleport-Cap, HUD-Pad, Fill-Dest.
2. **`overlayChipCap` 6 + `overlayChipTone`.** VEL/OCC Danger, PREDICT/ROI Cyan.
3. **`slotLateralityDist`.** Mismatch +0,10.
4. Tests + MARKETING_VERSION 1.5.106 (Build 126).

Aegis 2.1.123: FillX, Gate Cap 6. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-05 (1.5.105)

Helios **1.5.105** (Build 125). Aegis **2.1.121**. Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.104: Occlusion 2-Tick, Relativ-Snap, JUMP-Slow, Laterality 3 Ticks. `claimed.contains` vor Bind stahl S2. OCC lastTip freeze. NSScreen.main Pad.

## 1.5.104 → 1.5.105 (warum S1↔S2 / Phantom-Klick unter OCC / Laptop-Pad am 5K)

1. **`claimed.contains(.left)` vor bindSlot.** Zweite `.left` wurde `.right`. Laterality-Lock saß auf dem falschen Slot. S1↔S2.
2. **OCC lastTip freeze.** `fingerOcclusionTip` restauriert lastTip. Palme wandert, Tip steht. Pinch-Ratio fällt → Phantom-Klick. OCC-Release feuerte Down.
3. **`destEdgePadLiveChip` `NSScreen.main`.** Engine `destEdgePadOf(steal)`, UI Laptop-Breite neben 5K. Pad 36 statt 64.

## Was 1.5.105 ändert

1. **`palmLateralityClaimFlips` immer false.** Bind zuerst. **`palmLateralityTakes`:** zweite Hand Unknown, kein Flip.
2. **`fingerOcclusionFollows`.** Tip += Palm-Delta, lastTip zurückschreiben. **`pinchClickAbortsOcc`.** HUD `kein Klick — OCC`.
3. **`destEdgePadWidthOf` / `destEdgePadNow`.** Max-Screen-Breite, steal live in Engine/Chip/Teleport.
4. Tests + MARKETING_VERSION 1.5.105 (Build 125).

Aegis 2.1.121: Twin-Rank Exact `hash#101`, Occupied others live+stored, leftoverLastHash empty-Wipe. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-05 (1.5.104)

Helios **1.5.104** (Build 124). Aegis **2.1.120**. Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.103: Tip-Restore tot, live PAD, Wi-Fi-Veto. Occlusion injizierte lastIndexTip/DIP ohne TTL. Relativ nach Dropout Hold-Freeze. JUMP ließ Atem-DC. Vision-Flip 1 Tick stahl L.

## 1.5.103 → 1.5.104 (warum Pinch noch klickte / Relativ nach Dropout tot / Cursor nach JUMP riss)

1. **Occlusion lastTip/DIP ohne Gate.** jointConfRestores skippt Tips. fingerOcclusionTip nahm lastTip ewig oder DIP. DIP drückt Pinch-Ratio. 1 Frame Jitter = Phantom-Klick.
2. **Relativ Warp-Snap nur mapped.** Dropout > 0,80 s: Palm-Sprung, Hold friert from. Cursor tot bis Faust-neu.
3. **palmHighpass nach JUMP.** Slow hält Atem-DC. Restore-Tick fast = Sprung.
4. **Laterality otherClaimed 1 Tick.** Vision-Flip löst Lock, S1↔S2.

## Was 1.5.104 ändert

1. **`fingerOcclusionFresh` TTL 0,40 s. `fingerOcclusionConfirm` 2 Ticks.** DIP kein Pinch-Tip. HUD `OCC`.
2. **`cursorWarpSnapsRestore` Relativ nach Dropout > 0,80 s.** Sonst Hold.
3. **`palmHighpassMutesJump`.** JUMP/Hold Slow=dx.
4. **`palmLateralityDebounce` 3 Ticks.** Flip hält, Claim löst.
5. Tests + MARKETING_VERSION 1.5.104 (Build 124).

Aegis 2.1.120: Twin x-order, empty Hash-Wipe, INDOOR/LOCK/Adopt Slider. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-05 (1.5.103)

Helios **1.5.103** (Build 123). Aegis **2.1.119**. Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.102: Warp-Snap Restore. jointConfEMA restored Tips = Phantom-Pinch. Slider 24 vs live Pad 64 unsichtbar. uniqueID `USB-WiFi-Bridge` = USB.

## 1.5.102 → 1.5.103 (warum Cursor noch klickte / HUD log)

1. **jointConfEMA restored Tips.** Occlusion: EMA hält indexTip, raw nil → lastJoints. Pinch aus Phantom-Spitze.
2. **destEdgePad Slider vs live Pad.** Pref 24, 5K Floor 64. UI zeigte 24 px.
3. **continuityIsUSB ohne Wi-Fi-Veto.** Blob `usb`+`wifi` = USB. Continuity-Bridge logt falsch.

## Was 1.5.103 ändert

1. **`jointConfRestores`.** Tips nicht restore. Palm-Knochen bleiben.
2. **`destEdgePadLiveChip`.** ControlPanel `24 px · PAD 64`.
3. **`continuityIsUSB` Wi-Fi-Veto.** `wifi`/`wi-fi`/`wireless` schlägt USB-String. `transportUSB` bleibt USB.
4. Tests + MARKETING_VERSION 1.5.103 (Build 123).

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-05 (1.5.102)

Helios **1.5.102** (Build 122). Aegis **2.1.118**. Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.101: Warp-Hold JUMP, MUTE bis Release, Laterality HUD, USB transportType. Hold schreibt `from` jedes Frame — mapped Restore 400 px bleibt ewig MUTE, Cursor tot.

## 1.5.101 → 1.5.102 (warum Cursor nach Restore klebte)

1. **`applyWarpHold` Deadlock.** from→q 400 px = Teleport, Hold schreibt cursorSmooth=from. Nächster Tick from wieder old, q wieder 400 px. MUTE bis Release kommt nie. Relativ bleibt Hold.
2. **Snap fehlte.** Fill-Mute 1.5.100/101 hält Vel, Cursor nie auf q.

## Was 1.5.102 ändert

1. **`cursorWarpSnapsRestore`.** mapped Teleport Snap auf q vor Hold. Relativ kein Snap.
2. **`cursorWarpRestoreOf`.** lastMapped unangetastet — placeCursor JUMP. warpHeldJump=false, MUTE 1 Tick.
3. Tests + MARKETING_VERSION 1.5.102 (Build 122).

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-05 (1.5.101)

Helios **1.5.101** (Build 121). Aegis **2.1.117**. Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.100: Fill-Mute, Laterality, destEdgePad Slider, Joint-EMA, USB/WIFI. Warp-Hold freeze setzte cursorDidMove=false — placeCursor sah JUMP nicht. Hold-Release 64 px bei 8 fps = 500 px/s Coast. uniqueID ohne `usb` = WIFI trotz UVC. MUTE/L/R unsichtbar. Fill-Mute 1 Tick = 11 ms während Hold 125 ms. LOCK-AND nil wischt Overlay.

## 1.5.100 → 1.5.101 (warum Cursor nach Warp-Hold noch schoss / USB tot wirkte)

1. **`cursorWarpHoldsSmoothOf` ohne JUMP.** Freeze schreibt lastMapped=held, cursorDidMove=false. placeCursor else-Zweig wischt jumpMuteFill. Release: (edged−held)/dt bei Pad 64 = Coast auf den Nachbarschirm.
2. **Hold-Release kein Teleport.** 4× Pad fängt 400 px, nicht 64 px Catch-up.
3. **`continuityIsUSB` nur uniqueID.** Continuity uniqueID enthält selten `usb`. UVC/modelID tot. HUD `WIFI` am Kabel.
4. **MUTE/Laterality ohne HUD.** Fill tot und L/R-Lock unsichtbar.
5. **Fill-Mute 1 Tick.** Timer 90 Hz unmutet nach 11 ms, Warp-Hold sitzt 1 Kamera-Frame (8 fps = 125 ms). Coast in der Hold-Lücke.
6. **`warpHeldJump` Leck.** Reset-Pfade (Slot leer, Rebase, Actor, Map-tot) wischten jumpMuteFill, nicht warpHeldJump. Nächster Tick falscher JUMP oder Coast.

## Was 1.5.101 ändert

1. **`palmWarpHoldJumps` / `applyWarpHold`.** Freeze = JUMP. lastMapped2=held, Vel 0, Fill mute.
2. **`palmWarpHoldReleaseJumps`.** Hold→Live = Teleport. Fill-Delta 0.
3. **`palmVelChip` `JUMP · MUTE`.** Fill tot sichtbar.
4. **`palmLateralityChip` HUD `L`/`R`.** Vision-Flip gehalten.
5. **`continuityIsUSB` modelID + localizedName + `transportType` FourCC `usb `/`uvc `.**
6. **`displayTickMutesJump(held:)`.** Hold: MUTE bleibt. `displayTickClearsJumpMute` erst nach Release.
7. **`warpHeldJump` an allen Reset-Pfaden 0.**
8. Tests + MARKETING_VERSION 1.5.101 (Build 121).

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-05 (1.5.100)


Helios **1.5.100** (Build 120). Aegis **2.1.116**. Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.99: JUMP lastMapped2, Vel-TTL. Fill lief denselben Tick weiter. palmVelAt Sentinel 0. Vision-Chirality S1↔S2. destEdgePad Pref Math ohne Slider. Joint-Conf raw Floor. Continuity USB/Wi-Fi unsichtbar.

## 1.5.99 → 1.5.100 (warum Cursor nach JUMP noch schoss / S1/S2 tauschen)

1. **displayTick nach JUMP.** palmMappedPair schreibt lastMapped2 = current, Timer .common feuert im selben Intervall (c−prev)/dt nochmal. Fill mute 1 Frame.
2. **palmVelAt = 0 Sentinel.** Fresh prüft `savedAt > 0`. Optional nil = tot, 0 nicht mehr als Zeit.
3. **Vision-Chirality Flip.** Observation L/R hoppt, Slot S1 wird S2. Laterality-Lock hält die Seite solange die andere Hand sie nicht beansprucht.
4. **destEdgePad Pref Math ohne Slider.** 24–160 saß, UI nicht — 5K blieb Floor 40 in der Praxis.
5. **Joint-Conf raw Floor 0,10.** Ein Frame 0,05 droppt den Landmark, Overlay flackert.
6. **Continuity USB vs Wi-Fi.** HUD `420f 15–24` ohne Transport. USB-Desk-View und Wi-Fi sehen gleich tot aus.

## Was 1.5.100 ändert

1. **`displayTickMutesJump`.** Fill 1 Frame tot nach JUMP / Actor-Vel-0. HUD bleibt `JUMP`.
2. **`palmVelAtOf` Optional.** Teleport/Reset = nil.
3. **`palmLateralityLock`.** Links bleibt Links. HandTracker Slot laterality.
4. **destEdgePad Slider** 24–160. Pref + destEdgePadOf Floor. ControlPanel Rand-Dämpfung.
5. **`jointConfEMA`.** Floor auf EMA, nicht raw. Flicker tot.
6. **`formatTransportChip` HUD `USB` / `WIFI`.** Continuity uniqueID.
7. Tests + MARKETING_VERSION 1.5.100 (Build 120).

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-05 (1.5.99)

Helios **1.5.99** (Build 119). Aegis **2.1.114**. Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.98: Actor-Vel 0, lastMapped nil, Scale-Abort. Ghost hält Vel — mad 0 Keep nach 8 s Dropout = Coast. lastMapped nach Restore = Teleport ohne Actor-Wechsel. Fill las lastMapped2→lastMapped und schoss trotz Vel 0.

## 1.5.98 → 1.5.99 (warum Cursor nach langem Dropout noch schoss)

1. **Ghost hält Vel ohne TTL.** 1.5.98: Actor-Switch tot, gleiche Hand nach 8 s dunkel: Keep mad 0 hält 800 px/s. Fill 90 Hz.
2. **lastMapped nach Restore ohne Teleport-Gate.** Homographie driftet, (c−prev)/dt = Sprung. Warp hält den Tick, Fill nicht.
3. **Fill lastMapped2 nach JUMP.** palmVelScreen 0, displayLinkVelocity nimmt (c−prev)/dt weil hypot ≥ 8. 400 px Restore = 3200 px/s Coast.

## Was 1.5.99 ändert

1. **`palmVelScreenFresh` TTL 0,40 s.** Keep stale → Vel 0. Kurzer Ghost bleibt. `savedAt 0` tot.
2. **`palmVelScreenTeleport` 4× Pad.** 400 px tot, Flick 72 px bleibt. HUD `JUMP`.
3. **`palmMappedPair`.** JUMP: lastMapped2 = current. Fill-Delta 0. `displayLinkVelocity(fresh:)` stale tot.
4. Tests + MARKETING_VERSION 1.5.99 (Build 119).

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-05 (1.5.98)

Helios **1.5.98** (Build 118). Aegis **2.1.113**. Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.97: Slow-TTL 2 s. Slow je Actor restored. Screen-Vel und lastMapped nicht. S1→S2: Fill coaster S1, nächster Tick (S2−S1)/dt. Zwei-Hand-Scale 2→1 = Pinch-Klick.

## 1.5.97 → 1.5.98 (warum Cursor nach Handwechsel noch riss / Scale klickte)

1. **`palmVelScreen` nach Actor-Switch.** Slow seedet, Vel nicht. mad 0 hält S1-Vel. Fill 125 ms auf den Nachbarschirm.
2. **`lastMapped` der anderen Hand.** cursorDidMove nächster Tick = Teleport-Vel.
3. **Zwei-Hand-Scale ohne Abort.** closedCount 2→1, `twoHandSpan = nil`, lastScrollAt tot → Pinch-Klick.

## Was 1.5.98 ändert

1. **`palmVelScreenResets` / `palmVelScreenAfterActor`.** Vel 0, lastMapped nil, HUD `VEL 0`.
2. **`scaleAbortClick`.** 2→1 setzt lastScrollAt — Pinch-Klick 180 ms tot.
3. **`destEdgePadPref` 24–160.** Math für Slider.
4. Tests + MARKETING_VERSION 1.5.98 (Build 118).

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-05 (1.5.97)

Helios **1.5.97** (Build 117). Aegis **2.1.112**. Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.96: Center Stage `.app` + HeliosCatch. Slow je Actor ohne TTL — Dropout 8 s, Restore = S1-Atem von vor 10 s als Bias, Cursor-Sprung.

## 1.5.96 → 1.5.97 (warum Cursor nach langem Dropout noch riss)

1. **`palmHighpassLoad` ohne Alter.** Map hielt Slow unbegrenzt. S1 weg 8 s, zurück: erster Δ minus totem DC = Sprung. Seed=dx fehlte nach TTL.

## Was 1.5.97 ändert

1. **`palmHighpassFresh` TTL 2 s.** Stale → Slow=dx wie neue Hand.
2. **`palmSlowByActor.at`.** Load prüft frisch.
3. Tests + MARKETING_VERSION 1.5.97 (Build 117).

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-05 (1.5.96)


Helios **1.5.96** (Build 116). Crash 1.5.87 auf macOS 27: `CameraSession.configureAndRun` → `+[AVCaptureDevice_Tundra _setCenterStageEnabled:forcedSet:]`. Default-Control-Mode `.user` darf `isCenterStageEnabled` nicht setzen.

## 1.5.95 → 1.5.96 (warum Helios 5 s nach Start abort() macht)

1. **`AVCaptureDevice.isCenterStageEnabled = false` ohne Control-Mode.** Default ist `.user`. Apple: Setter wirft dann. Stack: `helios.camera` / `applyCenterStage(force: true)` nach `startRunning`.
2. **Kein HeliosCatch um den Setter.** `configureAndRun` rief `applyCenterStage` nackt. ObjC-Exception = SIGABRT, Swift fängt das nicht.

## Was 1.5.96 ändert

1. **`centerStageNeedsAppControl`.** Mode ≠ `.app` → `.app`, dann disable.
2. **`applyCenterStage` in HeliosCatch.** Getter/Setter/Control-Mode. force:true setzt direkt aus, ohne Getter.
3. Tests + MARKETING_VERSION 1.5.96 (Build 116).

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-05 (1.5.95)

Helios **1.5.95** (Build 115). Aegis **2.1.111**. CI 1.5.93/1.5.94: GestureTests `CACurrentMediaTime` ohne QuartzCore — DMG tot. Fix: Fling-Trail t=100.

# Helios + Aegis — Analyse 2026-09-05 (1.5.94)


Helios **1.5.94** (Build 114). Aegis **2.1.110**. Kein Xcode in der Linux-Sandbox; CI auf macos-26. Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.93: STEAL-HUD, 0° Vision, Hochpass Reset S1→S2, AX 260 ms, Ring-Cap 12. Ghost nil-Reset sprang. AX 2,5 px. Ring slots<4 Alloc-Sturm. Enhance 1920→960 bei Tag. Timer .default. JPEG-Probe nil = Taufe. destEdgeMul Gain hart 40. Warp-X 40 vs EDGE 64. PREDICT ohne HUD. Pinch-Hold bei Wrist-MAD.

## 1.5.93 → 1.5.94 (warum Cursor nach Dropout sprang / MAGNET flackerte / Desk-View dumpf / Nachbarschirm)

1. **`palmHighpassResets(nil, S1) = true`.** Continuity-Ghost wischte Slow. Erster Live-Frame = volles Δ inklusive Atem. Per-Actor-Map fehlte — S1↔S2 seedete 0, Sprung.
2. **AX Hit-Cache 2,5 px.** 8 fps Fill > 2,5 px/Tick. `axHitCacheNeed` Math ohne Dist. MAGNET/BUTTON jeder Tick neu.
3. **GPUFrameRing `slots.count < 4`.** Failed-Alloc oder 3 Slots = 8 Buffer jede Frame. Indoor Continuity starb.
4. **Enhance downscale immer bei w>960.** luma≥0,30 gab trotzdem 960. Desk-View 1920 Landmark tot.
5. **Timer.scheduledTimer .default.** Tracking/AX coalesced Fill. 8↔24 Retarget-Loch.
6. **destEdgePad 40 hart.** 5K 2560 pt Rand 1,5 % — X auf den Nachbarschirm. 13″ 2,8 %.
7. **Zwei-Hand-Scale ohne dt.** 8 fps jedes Zittern ein Scale.
8. **destEdgeMul Gain hart 40.** Dist schon PadOf, Gain nicht — 5K 50 px = Gain 1.
9. **cursorWarpCapX = 40.** EDGE 64, Warp 40: X-Rand zwei Zahlen.
10. **PREDICT Math ohne HUD.** Overlay vor der Hand unsichtbar.
11. **Pinch-Hold ignoriert Wrist-MAD.** Zitter-Hand zieht Fenster, Click-Still allein reicht nicht.

## Was 1.5.94 ändert

1. **`palmHighpassResets` Ghost hält. `palmHighpassLoad` je Actor, Seed=dx.** HUD `α 0,15 S1`.
2. **`axHitCacheDist` 8 fps 16 px.** SystemControl verdrahtet TTL.
3. **`ringRebuilds` nur Geometry/Format.** Kein Alloc-Sturm.
4. **`enhanceDownscales` nur luma<0,30.** Tag volle Desk-View.
5. **Timer `.common`.** `displayLinkTimerCommonMode`.
6. **`destEdgePadOf` 2,5 % Breite, Floor 40.** 5K 64 pt. destEdgeMul Gain dieselbe Zahl.
7. **`scaleMoved(dt:)` 8 fps Dead × 1,8.**
8. **`cursorWarpCapX(width:)` = destEdgePadOf.** HUD `PREDICT n`. `pinchHoldAborts` Wrist-MAD.
9. Tests + MARKETING_VERSION 1.5.94 (Build 114).

`bugfix` mergen: nein. Nur `main`. Ideen (Fling-Fenster, Dead-Man, Palm-Hochpass) liegen seit 1.5.89 auf main.


# Helios + Aegis — Analyse 2026-09-05 (1.5.93)

Helios **1.5.93** (Build 113). Aegis **2.1.109**. Kein Xcode in der Linux-Sandbox; CI auf macos-26. Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.92: Enhance 420, Slot-Steal drop, ROI 8 fps, Open-Uhr, Ghost 2 Frames. Steal ohne HUD. Portrait-Buffer .right bei 0° Capture = 90° Palm. Hochpass eine Slow-State für beide Hände. AX 180 ms = 1,4 Ticks. Ring wuchs unbegrenzt.

## 1.5.92 → 1.5.93 (warum Indoor tot wirkte / Cursor nach Format-Hop und Handwechsel riss)

1. **Slot −1 drop ohne HUD.** Indoor Continuity füllt den Ring, Nutzer sieht `420f 15–24`, nicht dass Vision Frames verliert.
2. **`previewOrientationRaw` height>width → .right.** Capture steht auf 0°. Desk-View/Continuity-Portrait = 90° Palm, Faust tot.
3. **palmHighpass eine Slow-X/Y.** Actor S1→S2 übernimmt S1-Atem als S2-Bias — Cursor-Sprung.
4. **AX Probe 180 ms bei 8 fps.** 1,4 Frames, MAGNET/BUTTON flackert. 2 Frames = 260 ms.
5. **GPUFrameRing extra slots unbounded.** Steal-Pfad wuchs, Release hielt nicht mit.
6. **Zwei-Hand-ROI Latch ohne Chip.** 8 fps S1-ROI sitzt, Kill-Hand unsichtbar.
7. **AX TypeID in loadProbe fehlte.** CopyElementAtPosition nach Sleep tot, `as?` immer true.

## Was 1.5.93 ändert

1. **`ringSlotStealChip` / `formatStealChip`.** HUD `STEAL n`, Decay.
2. **`visionBufferOrientation`.** 0° Capture immer .up. Preview gleich.
3. **`palmHighpassResets`.** Slow je Actor, Reset bei S1↔S2.
4. **`axProbeTTL` 8 fps 260 ms.** `axHitCacheNeed` 2 Frames.
5. **`ringSlotCap` 12.** Danach Steal-Drop, nicht wachsen.
6. **`palmROILatchChip` `ROI S1`.**
7. **`axTypeIDHolds` in loadProbe.**
8. Tests + MARKETING_VERSION 1.5.93 (Build 113).

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-05 (1.5.92)

Helios **1.5.92** (Build 112). Aegis **2.1.108**. Kein Xcode in der Linux-Sandbox; CI auf macos-26. Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.91: Ring hielt 420f, Enhance wandelte weiter nach BGRA. Slot −1 reichte den Kamera-Buffer. Zwei-Hand-ROI nil auch bei 8 fps. Pinch-Open zählte Frames. Overlay-Ghost 1 Frame. Klappe-auf AX-Cache tot. Hochpass-Slider fehlte.

## 1.5.91 → 1.5.92 (warum Indoor-Continuity und Overlay noch hakelten)

1. **FrameEnhancer Ping/Pong immer BGRA.** GPUFrameRing hielt 420f, Enhance kopierte nach 32BGRA — Indoor 420 tot.
2. **GPUFrameRing Slot −1.** `copy` steals, Vision liest, AVFoundation überschreibt denselben Buffer.
3. **Zwei-Hand-ROI `nil` unabhängig von dt.** 8 fps Full-Pass frisst den Tick, Kill-Hand droppt S1.
4. **`pinchOpenNeed` Frames vs `pinchClickNeed` Sekunden.** dt-Jitter 0,05↔0,07 sprang 3↔2.
5. **Overlay Ghost 1 Frame.** 8 fps Knochen flackern.
6. **Klappe-auf AX-Cache.** TypeID tot nach Sleep, MAGNET/BUTTON auf Leiche.
7. **Hochpass Pref ohne Slider.** 0,15 fest für zitternde vs ruhige Hand.

## Was 1.5.92 ändert

1. **`enhanceDestFormat`.** Ping/Pong bleibt 420f/420v.
2. **`ringSlotStealDrops`.** Slot −1 Frame droppen, nicht Vision auf Kamera-Buffer.
3. **`palmROISecondNils` / `palmVisionROI(dt:)`.** 8 fps S1-ROI halten, 15/24 Full für Kill.
4. **`pinchOpenHolds`.** Open-Need in Sekunden, dieselbe Uhr wie Click.
5. **`overlayGhostPeakHold` 2 Frames.**
6. **`axProbeWakeInvalidates` → `invalidateAXProbe`.**
7. **ControlPanel Atem-Hochpass 0,08–0,25.**
8. Tests + MARKETING_VERSION 1.5.92 (Build 112).

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-05 (1.5.91)

Helios **1.5.91** (Build 111). Aegis **2.1.107**. Kein Xcode in der Linux-Sandbox; CI auf macos-26. Nur `main`. `bugfix` ist 1.5.8 — nichts mergen.

1.5.90: Fill-Coast je Achse, Pinch-Uhren, Dead-Man HUD, WARP peak-hold. Ring wandelte weiter 420f→BGRA. Werfen prüfte den Trail-Anfang. Klappe-auf ließ Continuity bei 8.

## 1.5.90 → 1.5.91 (warum Cursor und Continuity noch hakelig waren)

1. **GPUFrameRing immer BGRA.** Continuity liefert 420f. Jede Frame CPU-Convert. VNDetectHumanHandPoseRequest nimmt 420f nativ.
2. **resolveFling Center-Dead am Trail-Anfang.** Pinch in der Mitte, Flick nach außen = tot.
3. **Kein Lid-Wake.** reconnectCenterStageOff sitzt, reselectFormat nach Klappe-auf fehlt.
4. **enhanceSkipsCopy ohne converts.** Native 420-Blit > 8 ms skippt Enhance fälschlich.

## Was 1.5.91 ändert

1. **`visionTakesNative` / `ringCopyConverts`.** GPUFrameRing hält 420f/420v.
2. **`pinchOpenNeedSec`.** Dieselbe Uhr wie pinchClickNeed (1.5.90 koppelt Click ≥ Open×dt).
3. **`flingFromTrail`.** Center-Dead am letzten Sample.
4. **`clamshellWakeReselects` → reselectFormat.**
5. **`destEdgeFillAxis` benannt.** destEdgeFill bleibt destEdgeVel.
6. **`videoStabilizationApplies` + CameraSession `#if os(iOS)`.**
7. Tests + MARKETING_VERSION 1.5.91 (Build 111).

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-05 (1.5.90)


Helios **1.5.90** (Build 110). Aegis **2.1.106**. Kein Xcode in der Linux-Sandbox; CI auf macos-26. Nur `main`. `bugfix` ist 1.5.8 — nichts mergen, Ideen nachgezogen.

## 1.5.89 → 1.5.90 (warum Cursor am Rand und Pinch bei 15 fps noch hakelten)

1.5.89: destEdgeFillAxis, Dead-Man Faust 1,6 s, USB-Hysterese. Fill dämpft Vel am Bezel, Coast-τ blieb 55 ms — X kroch nach dem Flick auf den Nachbarschirm. pinchClickNeed 90 ms vs pinchOpenNeed 2 Frames bei 15 fps = zwei Uhren, Phantom-Klick. Dead-Man-HUD zeigte Gaze-IDLE %, nicht Faust-Countdown. WARP-Chip 8 fps ein Frame, Overlay flackert. Hochpass 0,15 fest. Predict trotz Reduce Motion.

## Was 1.5.90 ändert

1. **`displayLinkCoastTauAxis` / Coast je Achse.** X-τ × destEdgeMul, Y frei. Fill-Coast nicht 0,35².
2. **`pinchClickNeed` koppelt Open × dt.** 15 fps 110 ms, nicht interpolierte 90 ms vor Gate.
3. **`deadManFistChip` `IDLE 1,2`.** GestureEngine.deadManChip Faust vor Gaze-%.
4. **`hudChipPeakHold` 1 Frame.** WARP/EDGE 8 fps nicht flackern.
5. **`palmHighpassAlpha` Pref 0,08–0,25.**
6. **`pointerPredictApplies` Reduce Motion aus.**
7. **`reconnectCenterStageOff`.** Continuity/Lid CS nochmal aus.
8. Tests + MARKETING_VERSION 1.5.90 (Build 110).

Aegis 2.1.106: Hunt 10 fps, leftoverAdopt Lock 0,80 s, Spark peak-hold, JPEG/Blink-Math. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-05 (1.5.89)

Helios **1.5.89** (Build 109). Aegis **2.1.105**. Kein Xcode in der Linux-Sandbox; CI auf macos-26. Nur `main`. `bugfix` ist 1.5.8 — nichts mergen, Ideen nachgezogen.

## 1.5.88 → 1.5.89 (warum Cursor und Continuity noch schlecht waren)

1.5.88: Pinch 15 fps, 420v-Luma, Desk-View 4:3, WARP-HUD. Fill blieb Passthrough: Kamera-Tick dämpft, Fill läuft 90 Hz ohne Bezel → X auf den Nachbarschirm. Dead-Man 8 s nach Faust. USB-Blink 8→24 hoppt sofort. Atem bewegt den Cursor. Pinch-Klick nach Zwei-Finger-Rad. `bugfix` Fling/Dead-Man/Palm-Hochpass lagen auf 1.5.8.

## Was 1.5.89 ändert

1. **`destEdgeFillAxis`.** Fill = `destEdgeVel` am Fill-Punkt. X am Rand, Y frei. palmVelScreen roh — nicht 0,35².
2. **`pinchCloseNeed` / `poseHoldNeed` 15 fps wie 8.** Open bleibt 1.5.88 (15 = 2).
3. **`deadManFist` 1,6 s** aus bugfix 1.5.8. Faust-Weg = Idle, 8 s bleibt Fallback.
4. **`palmHighpass` in der Engine.** Atem raus, Flick bleibt.
5. **`continuityUsbHold` 400 ms** + `formatHopHold`.
6. **`pinchClickBlocksAfterScroll` 180 ms** nach Scale/Wischen.
7. **`videoStabilizationOff`.** Math; macOS hat kein preferredVideoStabilizationMode.
8. Tests + MARKETING_VERSION 1.5.89 (Build 109).

`bugfix` mergen: nein. Nur `main`.

# Helios + Aegis — Analyse 2026-09-05 (1.5.88)

Helios **1.5.88** (Build 108). Aegis **2.1.104**. Kein Xcode in der Linux-Sandbox; CI auf macos-26. Nur `main`. `bugfix` ist 1.5.8 / Build 30 — nichts mergen.

## 1.5.87 → 1.5.88

1.5.87 (main): CI-Fix. `GestureTests.run()` redeclare `pred`. Swift-Overlay `availableVideoPixelFormatTypes` ([OSType]), Parameter `videoOut`. Live blieb hakelig: Pinch-Ratio bei 15 fps wie 24, 420v Luma Nacht, Desk-View 4:3 tot, Enhance nach teurer 420f-Kopie, Pinch-Down trotz zitterndem Wrist, WARP-Chip nur Math.

## Warum der Zeiger nach 1.5.87 noch klebte / tot wirkte

1. **`pinchWantOpen` Extra-Margin nur `dt ≥ 0,08`.** Continuity 15 fps (0,067) öffnet bei Ratio 0,59 ohne Vel — Phantom-Klick. Need interpoliert, Ratio-Pfad noch 24.
2. **`pinchOpenNeed` 15 fps = 3.** Wie 24 fps. 200 ms klebrige Pinzette, ratio-only nicht 2.
3. **`luma420` ohne VideoRange-Lift.** 420v Offset 16 → Luma 0,06, Enhance und Faust-AE jagen Indoor.
4. **`formatScore` height ≤ 1080.** Desk-View 4:3 1920×1440 / 1440×1080 Score −1, Session nimmt 800p@8.
5. **Ring 420f→BGRA jede Frame + Enhance.** Copy > 8 ms frisst den Tick, Vision droppt.
6. **Pinch-Down nur Need.** Wrist 0,08 bei interpolierter Need 133 ms = Klick mitten im Flick.
7. **`cursorWarpChip` Math ohne HUD.** destEdgeChip zeigte EDGE/MAP≠STEAL, nicht WARP Y.
8. **Format-Chip ohne Copy.** Nutzer sieht `420f 15–24`, nicht dass der Ring 12 ms kopiert.

`bugfix` (Fling/Dead-Man/Palm-Hochpass) hinter main, nichts nachziehen.

## Was 1.5.88 wirklich ändert

1. pinchWantOpen Extra-Margin ab 15 fps. pinchOpenNeed 15 fps = 2.
2. luma420Lift 420v Offset 16. enhanceSkipsCopy > 8 ms.
3. formatScore 4:3 bis 1920×1440, Portrait Desk-View.
4. pinchClickNeedsStill / pinchClickFires.
5. destHudChip MAP≠STEAL → WARP → EDGE. formatCopyChip `COPY` > 8 ms.
6. Tests + MARKETING_VERSION 1.5.88 (Build 108).

1.5.87 bleibt: `ptrPred`, `availableVideoPixelFormatTypes` + `videoOut`.
1.5.86 bleibt: cursorWarpHoldsSmoothOf je Achse, cursorWarpCapAxis, displayLinkCursorOf Clamp je Achse, destMapStealChip MAP≠STEAL.

Aegis 2.1.104: Live 5→15 fps, kein RotationCoordinator, leftoverTrailWriteOk ohne Yaw-Block, Spark ¾ ohne UUID-Mix. Siehe `lolalpha00gamma/aegis-scanner`.

`bugfix` mergen: nein. Nur `main`.

# Analyse, Fehlerbehebung, öffentlicher Abgleich

Siehe docs/Erkennung.md für die laufende Pipeline.

## Vorher
Eine 2D-Quelle, Radial-isExtended, Chiralität als Schlüssel, anisotrope hypot, Frame-Streaks.

## Jetzt
Track-ID, isotrop, Winkel, Softmax, Ausreißer, HMM in Sekunden, Fusion 2D+Lift+Tiefe+Zeit.
Systemaktionen ab Pose p>=0.70. Wurf/Wischen in Handbreiten.

## Repos
- google-ai-edge/mediapipe Hands: 21 Punkte, z~x, handedness als Attribut. x/y getrennt normiert = unser alter Bug.
- casiez/OneEuroFilter: dt in Sekunden.
- geaxgx/depthai_hand_tracker: Body-Pre-Focus -> Unterarm-Prior.
- CalciferZh/minimal-hand: Knochenlängen 2D->3D.
- kinivi/hand-gesture-recognition-mediapipe: Landmarken -> kleines Netz / gesten.jsonl.
- vladmandic/human, handtracking-io/yoha, jaredrhod/barehands: Track über Palm, Gesture als Verteilung.
- ultraleap/UnityPlugin: Pinch analog 0..1, HMM-Stabilität.
- xinghaochen/awesome-hand-pose-estimation: MANO-Verhältnisse.

Lift-3D ist nicht unabhängig von 2D. Echte Tiefe senkt das Lift-Gewicht auf 0.12.

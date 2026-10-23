from __future__ import annotations

import time

import numpy as np

from .classifier import classify
from .coord import MP

from .model_asset import model_path


class HandTracker:
    def __init__(self):
        self._landmarker = None
        self._err = ""
        self._ts = 0
        try:
            from mediapipe.tasks.python import BaseOptions
            from mediapipe.tasks.python.vision import (
                HandLandmarker,
                HandLandmarkerOptions,
                RunningMode,
            )

            opts = HandLandmarkerOptions(
                base_options=BaseOptions(model_asset_path=str(model_path())),
                running_mode=RunningMode.VIDEO,
                num_hands=2,
                min_hand_detection_confidence=0.45,
                min_hand_presence_confidence=0.45,
                min_tracking_confidence=0.45,
            )
            self._landmarker = HandLandmarker.create_from_options(opts)
        except Exception as e:
            self._err = str(e)

    @property
    def error(self) -> str:
        return self._err

    def process(self, bgr: np.ndarray, mirrored: bool = True, now: float | None = None) -> list[dict]:
        if self._landmarker is None or bgr is None:
            return []
        import mediapipe as mp

        rgb = bgr[:, :, ::-1].copy()
        if mirrored:
            rgb = np.ascontiguousarray(rgb[:, ::-1, :])
        ts = int((now or time.perf_counter()) * 1000)
        if ts <= self._ts:
            ts = self._ts + 1
        self._ts = ts
        img = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
        try:
            res = self._landmarker.detect_for_video(img, ts)
        except Exception:
            return []
        hands = []
        n = len(res.hand_landmarks or [])
        for i in range(n):
            lms = res.hand_landmarks[i]
            joints = {}
            for name, idx in MP.items():
                p = lms[idx]
                joints[name] = (float(p.x), float(p.y))
            feat = classify(joints)
            handed = "unknown"
            if res.handedness and i < len(res.handedness) and res.handedness[i]:
                cat = res.handedness[i][0].category_name.lower()
                # MediaPipe reports the physical hand. After a selfie flip the
                # label still matches the person, not the image side.
                handed = "left" if "left" in cat else "right" if "right" in cat else "unknown"
            feat.update(
                {
                    "id": f"{handed}-{i}",
                    "chirality": handed,
                    "joints": joints,
                    "quality": float(res.handedness[i][0].score) if res.handedness and i < len(res.handedness) else 0.6,
                }
            )
            hands.append(feat)
        # one left, one right — duplicate chirality split by x
        if len(hands) == 2 and hands[0]["chirality"] == hands[1]["chirality"]:
            a, b = hands
            if a["palm"][0] > b["palm"][0]:
                a, b = b, a
            a["chirality"] = "right"
            b["chirality"] = "left"
            hands = [a, b]
        return hands

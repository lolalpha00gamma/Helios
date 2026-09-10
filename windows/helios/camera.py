from __future__ import annotations

import cv2
import numpy as np


class Camera:
    def __init__(self, index: int = 0):
        self.index = index
        self.cap = None
        self.err = ""
        self.open(index)

    def open(self, index: int) -> None:
        self.close()
        self.index = index
        cap = cv2.VideoCapture(index, cv2.CAP_DSHOW)
        if not cap or not cap.isOpened():
            cap = cv2.VideoCapture(index)
        if not cap or not cap.isOpened():
            self.err = f"Kamera {index} nicht gefunden"
            self.cap = None
            return
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
        cap.set(cv2.CAP_PROP_FPS, 30)
        cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
        self.cap = cap
        self.err = ""

    def read(self) -> np.ndarray | None:
        if self.cap is None:
            return None
        ok, frame = self.cap.read()
        return frame if ok else None

    def close(self) -> None:
        if self.cap is not None:
            self.cap.release()
            self.cap = None

    @staticmethod
    def devices() -> list[int]:
        found = []
        for i in range(6):
            cap = cv2.VideoCapture(i, cv2.CAP_DSHOW)
            if cap.isOpened():
                found.append(i)
                cap.release()
        return found or [0]

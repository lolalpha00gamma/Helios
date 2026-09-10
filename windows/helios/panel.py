from __future__ import annotations

import cv2
import numpy as np

from .version import VERSION

CYAN = (255, 224, 63)
AMBER = (74, 184, 255)
VOID = (18, 12, 8)


class Panel:
    WIN = "Helios"

    def __init__(self):
        cv2.namedWindow(self.WIN, cv2.WINDOW_NORMAL)
        cv2.resizeWindow(self.WIN, 960, 620)

    def render(self, frame: np.ndarray | None, engine, hands: list[dict], cam_err: str = "") -> None:
        if frame is None:
            img = np.zeros((540, 960, 3), np.uint8)
            img[:] = (18, 12, 8)
            cv2.putText(img, cam_err or "Keine Kamera", (40, 280), cv2.FONT_HERSHEY_SIMPLEX, 0.9, AMBER, 2)
        else:
            img = cv2.flip(frame, 1).copy()
            self._skeleton(img, hands)
        h, w = img.shape[:2]
        bar = np.zeros((72, w, 3), np.uint8)
        bar[:] = VOID
        armed = engine.mode == "armed"
        cv2.putText(
            bar,
            f"HELIOS  {VERSION}   Windows 11",
            (16, 28),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.62,
            CYAN,
            1,
            cv2.LINE_AA,
        )
        status = "SCHARF" if armed else "BEREIT"
        cv2.putText(bar, status, (16, 56), cv2.FONT_HERSHEY_SIMPLEX, 0.55, AMBER if armed else CYAN, 1, cv2.LINE_AA)
        cv2.putText(
            bar,
            f"{engine.fps:.0f} fps   {engine.ms:.0f} ms   {engine.action}",
            (180, 56),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.45,
            (200, 200, 200),
            1,
            cv2.LINE_AA,
        )
        help_h = 54
        helpb = np.zeros((help_h, w, 3), np.uint8)
        helpb[:] = VOID
        cv2.putText(
            helpb,
            "Faust = Scharf   Pinzette = Klick/Zug   Ring = Rechts   Wischen = App/Schreibtisch   Zeigen = Tastatur   Q = Ende   S = Scharf   Esc = Idle",
            (12, 22),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.38,
            CYAN,
            1,
            cv2.LINE_AA,
        )
        cv2.putText(
            helpb,
            "OK-Zeichen = Explorer   Peace = Aufnahme   Daumen hoch = Fenster vorn   Beide offen = Not-Aus",
            (12, 42),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.38,
            (180, 180, 180),
            1,
            cv2.LINE_AA,
        )
        out = np.vstack([bar, img, helpb])
        cv2.imshow(self.WIN, out)

    def _skeleton(self, img, hands):
        h, w = img.shape[:2]
        chains = [
            ("wrist", "thumb_mcp", "thumb_ip", "thumb_tip"),
            ("wrist", "index_mcp", "index_pip", "index_dip", "index_tip"),
            ("wrist", "middle_mcp", "middle_pip", "middle_dip", "middle_tip"),
            ("wrist", "ring_mcp", "ring_pip", "ring_dip", "ring_tip"),
            ("wrist", "little_mcp", "little_pip", "little_dip", "little_tip"),
        ]
        for hand in hands:
            j = hand.get("joints") or {}
            def xy(name):
                p = j.get(name)
                if not p:
                    return None
                return int(p[0] * w), int(p[1] * h)

            col = AMBER if hand.get("closedness", 0) >= 0.24 else CYAN
            for chain in chains:
                pts = [xy(n) for n in chain]
                pts = [p for p in pts if p]
                for a, b in zip(pts, pts[1:]):
                    cv2.line(img, a, b, col, 2, cv2.LINE_AA)
                for p in pts:
                    cv2.circle(img, p, 3, col, -1, cv2.LINE_AA)
            palm = xy("wrist")
            if palm:
                label = f"{hand.get('chirality', '')} {hand.get('pose_de', '')} {int(hand.get('prob', 0)*100)}%"
                cv2.putText(img, label, (palm[0] + 8, palm[1] - 8), cv2.FONT_HERSHEY_SIMPLEX, 0.45, col, 1, cv2.LINE_AA)

    def poll(self) -> int:
        return cv2.waitKey(1) & 0xFF

    def close(self):
        cv2.destroyWindow(self.WIN)

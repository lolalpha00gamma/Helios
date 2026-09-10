"""Shared gesture math. Image UV: x right, y down, 0…1. Screen: pixels, y down."""

from __future__ import annotations

import math
from typing import Iterable, Sequence

POSE = ("unknown", "fist", "openPalm", "pinch", "point", "thumbsUp", "peace")
POSE_DE = {
    "unknown": "—",
    "fist": "Faust",
    "openPalm": "Offene Hand",
    "pinch": "Pinzette",
    "point": "Zeigen",
    "thumbsUp": "Daumen hoch",
    "peace": "Zwei Finger",
}

MP = {
    "wrist": 0,
    "thumb_cmc": 1, "thumb_mcp": 2, "thumb_ip": 3, "thumb_tip": 4,
    "index_mcp": 5, "index_pip": 6, "index_dip": 7, "index_tip": 8,
    "middle_mcp": 9, "middle_pip": 10, "middle_dip": 11, "middle_tip": 12,
    "ring_mcp": 13, "ring_pip": 14, "ring_dip": 15, "ring_tip": 16,
    "little_mcp": 17, "little_pip": 18, "little_dip": 19, "little_tip": 20,
}

FINGERS = {
    "thumb": ("thumb_tip", "thumb_ip", "thumb_mcp"),
    "index": ("index_tip", "index_pip", "index_mcp"),
    "middle": ("middle_tip", "middle_pip", "middle_mcp"),
    "ring": ("ring_tip", "ring_pip", "ring_mcp"),
    "little": ("little_tip", "little_pip", "little_mcp"),
}


def dist(a: Sequence[float], b: Sequence[float]) -> float:
    return math.hypot(a[0] - b[0], a[1] - b[1])


def clamp(v: float, lo: float = 0.0, hi: float = 1.0) -> float:
    return lo if v < lo else hi if v > hi else v


def vision_u(x: float, mirrored: bool) -> float:
    return x if mirrored else 1.0 - x


def softmax(logits: Sequence[float], temperature: float = 0.72) -> list[float]:
    t = max(1e-4, temperature)
    m = max(logits)
    ex = [math.exp((v - m) / t) for v in logits]
    s = sum(ex) or 1.0
    return [e / s for e in ex]


def angle(a, b, c) -> float:
    bax, bay = a[0] - b[0], a[1] - b[1]
    bcx, bcy = c[0] - b[0], c[1] - b[1]
    na = math.hypot(bax, bay)
    nc = math.hypot(bcx, bcy)
    if na < 1e-6 or nc < 1e-6:
        return math.pi
    cosv = (bax * bcx + bay * bcy) / (na * nc)
    return math.acos(clamp(cosv, -1.0, 1.0))


def extension_score(ang: float) -> float:
    # straight ~ pi, curled ~ 0.7
    return clamp((ang - 0.9) / 1.7)


def palm_scale(j: dict) -> float:
    w = j.get("wrist")
    spans = []
    if w:
        for k in ("middle_mcp", "index_mcp", "ring_mcp", "little_mcp"):
            if k in j:
                spans.append(dist(w, j[k]))
    if "index_mcp" in j and "little_mcp" in j:
        spans.append(dist(j["index_mcp"], j["little_mcp"]))
    if not spans:
        return 0.12
    spans.sort()
    return max(0.04, spans[len(spans) // 2])


def palm_center(j: dict) -> tuple[float, float]:
    pts = [j[k] for k in ("index_mcp", "middle_mcp", "ring_mcp", "little_mcp") if k in j]
    if len(pts) >= 2:
        return sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts)
    return j.get("wrist") or j.get("index_mcp") or (0.5, 0.5)


def pinch_closedness(j: dict, scale: float) -> tuple[float, float, float]:
    t, i = j.get("thumb_tip"), j.get("index_tip")
    if t and i:
        d = dist(t, i)
    else:
        t, i = j.get("thumb_ip"), j.get("index_pip")
        d = dist(t, i) * 1.12 if t and i else scale
    ratio = d / max(0.03, scale)
    closed = clamp((0.52 - ratio) / 0.40)
    w = j.get("wrist")
    reach = 1.0
    if w and t and i:
        m = ((t[0] + i[0]) / 2, (t[1] + i[1]) / 2)
        reach = dist(m, w) / max(0.03, scale)
    return closed, ratio, reach


def looks_like_pinch(reach: float, index: float, closedness: float) -> bool:
    if closedness > 0.92 and reach < 0.55 and index < 0.35:
        return False
    return reach >= 0.85 or index >= 0.45


def pinch_starts(gate: bool, closedness: float, reach: float, index: float) -> bool:
    if not looks_like_pinch(reach, index, closedness):
        return False
    return gate or closedness > 0.28


def pinch_meter(gate: bool, closedness: float, is_fist: bool = False, rest: bool = False) -> bool:
    if is_fist or rest:
        return False
    return gate or closedness >= 0.24


def linear_map(palm: tuple[float, float], screen: tuple[int, int, int, int]) -> tuple[int, int]:
    x, y, w, h = screen
    u = clamp((palm[0] - 0.10) / 0.80)
    v = clamp((palm[1] - 0.10) / 0.80)
    return int(x + u * w), int(y + v * h)


def apply_homography(h: list[float], palm: tuple[float, float], screen: tuple[int, int, int, int]) -> tuple[int, int]:
    if not h or len(h) < 9:
        return linear_map(palm, screen)
    u, v = palm
    w = h[6] * u + h[7] * v + h[8]
    if abs(w) < 1e-8:
        return linear_map(palm, screen)
    px = (h[0] * u + h[1] * v + h[2]) / w
    py = (h[3] * u + h[4] * v + h[5]) / w
    x, y, sw, sh = screen
    return int(clamp(px, x, x + sw)), int(clamp(py, y, y + sh))


def homography(src: list[tuple[float, float]], dst: list[tuple[float, float]]) -> list[float] | None:
    if len(src) < 4 or len(dst) < 4:
        return None
    # DLT 4-point
    a = []
    b = []
    for (x, y), (u, v) in zip(src[:4], dst[:4]):
        a.append([x, y, 1, 0, 0, 0, -u * x, -u * y])
        b.append(u)
        a.append([0, 0, 0, x, y, 1, -v * x, -v * y])
        b.append(v)
    try:
        import numpy as np
        sol, *_ = np.linalg.lstsq(np.array(a, float), np.array(b, float), rcond=None)
        return [float(v) for v in list(sol) + [1.0]]
    except Exception:
        return None


def hold_advance(phase: str, closed: bool, held_for: float, dt: float) -> tuple[str, float]:
    if closed:
        t = held_for + dt
        if phase in ("unseen", "released"):
            return ("tentative" if t < 0.045 else "held", t)
        if phase == "tentative":
            return ("held" if t >= 0.045 else "tentative", t)
        return ("held", t)
    if phase == "held":
        return ("released", 0.0)
    return ("unseen", 0.0)

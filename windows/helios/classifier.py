from __future__ import annotations

from .coord import (
    FINGERS,
    POSE,
    POSE_DE,
    angle,
    clamp,
    dist,
    extension_score,
    palm_center,
    palm_scale,
    pinch_closedness,
    softmax,
)


def finger_score(j: dict, finger: str, scale: float) -> float:
    tip_k, pip_k, mcp_k = FINGERS[finger]
    t, p, m = j.get(tip_k), j.get(pip_k), j.get(mcp_k)
    if not (t and p and m):
        return 0.0
    score = extension_score(angle(m, p, t))
    w = j.get("wrist")
    if w:
        tip_d, pip_d = dist(t, w), dist(p, w)
        radial = min(1.0, (tip_d - pip_d) / max(0.02, scale * 0.45)) if tip_d > pip_d else 0.0
        score = score * 0.72 + radial * 0.28
    return clamp(score)


def classify(j: dict) -> dict:
    scale = palm_scale(j)
    palm = palm_center(j)
    thumb = finger_score(j, "thumb", scale)
    index = finger_score(j, "index", scale)
    middle = finger_score(j, "middle", scale)
    ring = finger_score(j, "ring", scale)
    little = finger_score(j, "little", scale)
    closed, ratio, reach = pinch_closedness(j, scale)
    w = j.get("wrist")
    tip = j.get("thumb_tip")
    thumb_up = 0.0
    if tip and w:
        dy = (w[1] - tip[1]) / max(0.03, scale)  # up in image = smaller y
        thumb_up = clamp((dy - 0.35) / 0.7) * thumb

    logits = {
        "fist": ((1 - index) + (1 - middle) + (1 - ring) + (1 - little)) * 1.1
        - closed * 0.4
        - index * 2.0,
        "openPalm": (index + middle + ring + little) * 1.15,
        "pinch": closed * 4.4 + reach * 0.8 - (middle + ring) * 0.7 - (1 - index) * 1.2,
        "point": index * 4.2 - (middle + ring + little) * 1.6,
        "peace": (index + middle) * 2.1 - (ring + little) * 2.2,
        "thumbsUp": thumb_up * 4.2
        + ((1 - index) + (1 - middle) + (1 - ring) + (1 - little)) * 1.1
        - sum(1 for s in (index, middle, ring, little) if s > 0.55) * 1.8
        - closed * 1.4,
        "unknown": -1.8,
    }
    keys = list(POSE)
    sm = softmax([logits.get(k, -2.0) for k in keys], 0.72)
    probs = {k: sm[i] for i, k in enumerate(keys)}
    if sum(1 for s in (index, middle, ring, little) if s > 0.55) >= 2:
        probs["thumbsUp"] = min(probs["thumbsUp"], 0.06)
    pose = max(probs, key=probs.get)
    ext = {"thumb": thumb, "index": index, "middle": middle, "ring": ring, "little": little}
    open_score = sum(1 for s in (index, middle, ring, little) if s > 0.55)
    return {
        "pose": pose,
        "pose_de": POSE_DE[pose],
        "prob": probs[pose],
        "probs": probs,
        "closedness": closed,
        "ratio": ratio,
        "reach": reach,
        "palm": palm,
        "palm_width": scale,
        "ext": ext,
        "open_score": open_score,
        "index": index,
        "thumb_up": thumb_up,
    }

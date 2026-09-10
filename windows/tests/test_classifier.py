"""Run without MediaPipe: python windows/tests/test_classifier.py"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from helios.classifier import classify
from helios.coord import pinch_meter, pinch_starts, vision_u


def hand(tips_y: float, index_y: float | None = None, thumb_up: bool = False) -> dict:
    # Same geometry as macos GestureTests (Vision y-up).
    wrist = (0.50, 0.20)
    mcp_y = 0.34
    pip_y = 0.20 + (tips_y + 0.14) * 0.5
    j = {
        "wrist": wrist,
        "index_mcp": (0.46, mcp_y),
        "index_pip": (0.45, pip_y),
        "index_tip": (0.44, index_y if index_y is not None else tips_y),
        "middle_mcp": (0.50, mcp_y),
        "middle_pip": (0.50, pip_y),
        "middle_tip": (0.50, tips_y),
        "ring_mcp": (0.54, mcp_y),
        "ring_pip": (0.55, pip_y),
        "ring_tip": (0.56, tips_y),
        "little_mcp": (0.58, mcp_y),
        "little_pip": (0.59, pip_y),
        "little_tip": (0.60, tips_y),
        "thumb_mcp": (0.44, mcp_y),
        "thumb_ip": (0.45, mcp_y + 0.01),
        "thumb_tip": (0.46, 0.60 if thumb_up else mcp_y - 0.02),
    }
    return j


def main() -> int:
    fails = 0

    def ok(c, msg):
        nonlocal fails
        if not c:
            print("FAIL", msg)
            fails += 1

    open_h = hand(0.72)
    r = classify(open_h)
    ok(r["pose"] == "openPalm", f"offene Hand got {r['pose']}")

    fist = hand(0.32)
    r = classify(fist)
    ok(r["pose"] == "fist", f"Faust got {r['pose']}")

    point = hand(0.32, index_y=0.74)
    point["middle_tip"] = (0.50, 0.34)
    point["ring_tip"] = (0.56, 0.33)
    point["little_tip"] = (0.60, 0.32)
    r = classify(point)
    ok(r["pose"] == "point", f"Zeigen got {r['pose']}")

    ok(abs(vision_u(0.2, True) - 0.2) < 1e-6, "visionU mirrored")
    ok(abs(vision_u(0.2, False) - 0.8) < 1e-6, "visionU unmirrored")
    ok(not pinch_meter(True, 0.9, is_fist=True), "Meter Faust")
    ok(pinch_starts(True, 0.7, 1.3, 0.8), "pinchStarts Pinzette")
    ok(not pinch_starts(True, 0.9, 0.2, 0.1), "pinchStarts Faust")

    if fails:
        print(fails, "fehlgeschlagen")
        return 1
    print("Windows classifier tests OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

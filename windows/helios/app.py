from __future__ import annotations

import sys
import time
import traceback
from pathlib import Path

from .camera import Camera
from .engine import Engine
from .overlay import Overlay
from .panel import Panel
from .tracker import HandTracker
from .version import VERSION


def _log_path() -> Path:
    p = Path.home() / "AppData" / "Local" / "Helios"
    p.mkdir(parents=True, exist_ok=True)
    return p / "helios.log"


def main(argv: list[str] | None = None) -> int:
    argv = argv if argv is not None else sys.argv[1:]
    log = _log_path()
    try:
        return _run(argv, log)
    except Exception:
        log.write_text(traceback.format_exc(), encoding="utf-8")
        raise


def _run(argv: list[str], log: Path) -> int:
    cam_index = 0
    if "--camera" in argv:
        i = argv.index("--camera")
        if i + 1 < len(argv):
            cam_index = int(argv[i + 1])
    print(f"Helios {VERSION} für Windows 11")
    print(f"Log: {log}")
    cam = Camera(cam_index)
    tracker = HandTracker()
    if tracker.error:
        print("MediaPipe:", tracker.error)
    engine = Engine()
    overlay = Overlay()
    panel = Panel()
    try:
        while True:
            frame = cam.read()
            now = time.perf_counter()
            hands = tracker.process(frame, mirrored=True, now=now) if frame is not None else []
            engine.tick(hands, now)
            overlay.render(engine.snapshot(), hands)
            panel.render(frame, engine, hands, cam.err)
            key = panel.poll()
            if key in (ord("q"), ord("Q")):
                break
            if key == 27:
                engine.mode = "idle"
                engine.must_rearm = True
                engine._drop_pinch(now)
                engine.action = "Idle"
            elif key in (ord("s"), ord("S")):
                engine.mode = "armed"
                engine.action = "Scharf"
            elif key in (ord("q"), ord("Q")):
                break
            elif key in (ord("o"), ord("O")):
                overlay.visible = not overlay.visible
            elif key in (ord("c"), ord("C")):
                cam.open((cam.index + 1) % 6)
    finally:
        overlay.close()
        panel.close()
        cam.close()
        engine.inject.release()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

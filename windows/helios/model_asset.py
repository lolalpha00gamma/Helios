"""Load only the pinned MediaPipe hand model, publishing downloads atomically."""
from __future__ import annotations

import hashlib
import os
import tempfile
import urllib.request
from pathlib import Path

MODEL_URL = (
    "https://storage.googleapis.com/mediapipe-models/hand_landmarker/"
    "hand_landmarker/float16/1/hand_landmarker.task"
)
MODEL_SIZE = 7_819_105
MODEL_SHA256 = "fbc2a30080c3c557093b5ddfc334698132eb341044ccee322ccf8bcf3607cde1"


def verified(path: Path) -> bool:
    try:
        with path.open("rb") as source:
            if os.fstat(source.fileno()).st_size != MODEL_SIZE:
                return False
            digest = hashlib.sha256()
            total = 0
            while chunk := source.read(1 << 16):
                total += len(chunk)
                if total > MODEL_SIZE:
                    return False
                digest.update(chunk)
        return total == MODEL_SIZE and digest.hexdigest() == MODEL_SHA256
    except OSError:
        return False


def model_path(*, bundled: Path | None = None, cache: Path | None = None) -> Path:
    if bundled is None:
        bundled = Path(__file__).resolve().parent / "models" / "hand_landmarker.task"
    if verified(bundled):
        return bundled
    if cache is None:
        local = Path(os.environ.get("LOCALAPPDATA", Path.home() / "AppData" / "Local"))
        cache = local / "Helios" / "hand_landmarker.task"
    if verified(cache):
        return cache
    cache.parent.mkdir(parents=True, exist_ok=True)
    temporary: Path | None = None
    try:
        # Unique files also prevent two starting processes from sharing/truncating a .part file.
        with tempfile.NamedTemporaryFile(dir=cache.parent, prefix="hand-", suffix=".part", delete=False) as output:
            temporary = Path(output.name)
            with urllib.request.urlopen(MODEL_URL, timeout=30) as response:
                total = 0
                while chunk := response.read(1 << 16):
                    total += len(chunk)
                    if total > MODEL_SIZE:
                        raise RuntimeError("hand_landmarker.task hat eine ungültige Größe")
                    output.write(chunk)
        if not verified(temporary):
            raise RuntimeError("hand_landmarker.task ist unvollständig oder verändert")
        temporary.replace(cache)
        return cache
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)

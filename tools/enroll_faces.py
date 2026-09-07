#!/usr/bin/env python3
"""Helios-Gesichter sammeln.

Legt zwei Ordner an:
  faces/owner/   — nur du, ein Gesicht pro Bild
  faces/others/  — andere Personen, ebenfalls ein Gesicht pro Bild

Nutzung:
  python3 tools/enroll_faces.py              # Kamera, 20 Frames von dir
  python3 tools/enroll_faces.py --who others # andere Person vor die Kamera
  python3 tools/enroll_faces.py --shots 30

Keine Massen-Downloads fremder Gesichter. Für „others“ eigene Fotos
oder den öffentlichen Datensatz LFW (nur Forschung):
  http://vis-www.cs.umass.edu/lfw/
Je Datei muss genau eine Person zeigen.
"""
from __future__ import annotations

import argparse
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "faces"


def ensure_dirs() -> tuple[Path, Path]:
    owner = ROOT / "owner"
    others = ROOT / "others"
    owner.mkdir(parents=True, exist_ok=True)
    others.mkdir(parents=True, exist_ok=True)
    return owner, others


def capture(dest: Path, shots: int, label: str) -> None:
    try:
        import cv2
    except ImportError:
        raise SystemExit("pip3 install opencv-python")

    cam = cv2.VideoCapture(0)
    if not cam.isOpened():
        raise SystemExit("Keine Kamera.")
    cascade = cv2.CascadeClassifier(
        cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
    )
    saved = 0
    print(f"{label}: Leertaste speichert, q beendet. Ziel {shots} Bilder.")
    while saved < shots:
        ok, frame = cam.read()
        if not ok:
            break
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        faces = cascade.detectMultiScale(gray, 1.2, 5, minSize=(80, 80))
        vis = frame.copy()
        if len(faces) == 1:
            x, y, w, h = faces[0]
            cv2.rectangle(vis, (x, y), (x + w, y + h), (0, 220, 180), 2)
            cv2.putText(vis, "1 Gesicht — Leertaste", (12, 28), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 220, 180), 2)
        elif len(faces) == 0:
            cv2.putText(vis, "kein Gesicht", (12, 28), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 80, 255), 2)
        else:
            cv2.putText(vis, f"{len(faces)} Gesichter — nur EINE Person im Bild", (12, 28), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 80, 255), 2)
            for (x, y, w, h) in faces:
                cv2.rectangle(vis, (x, y), (x + w, y + h), (0, 80, 255), 1)
        cv2.putText(vis, f"{saved}/{shots} {label}", (12, vis.shape[0] - 16), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (220, 220, 220), 2)
        cv2.imshow("Helios enroll", vis)
        key = cv2.waitKey(20) & 0xFF
        if key == ord("q"):
            break
        if key == 32 and len(faces) == 1:
            x, y, w, h = faces[0]
            pad = int(0.25 * max(w, h))
            x0 = max(0, x - pad)
            y0 = max(0, y - pad)
            crop = frame[y0 : y + h + pad, x0 : x + w + pad]
            path = dest / f"{label}_{int(time.time() * 1000)}.jpg"
            cv2.imwrite(str(path), crop)
            saved += 1
            print(path)
    cam.release()
    cv2.destroyAllWindows()
    print(f"fertig: {saved} in {dest}")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--who", choices=("owner", "others"), default="owner")
    p.add_argument("--shots", type=int, default=20)
    args = p.parse_args()
    owner, others = ensure_dirs()
    dest = owner if args.who == "owner" else others
    capture(dest, args.shots, args.who)


if __name__ == "__main__":
    main()

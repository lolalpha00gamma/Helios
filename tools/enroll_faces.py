#!/usr/bin/env python3
"""Helios-Gesichter auf den Schreibtisch.

  ~/Desktop/Helios-Gesichter/owner   — du, Kamera, ein Gesicht pro Bild
  ~/Desktop/Helios-Gesichter/others  — öffentliche Gesichter (Hugging Face)

others: FairFace (nateraw/fairface), CC BY 4.0, zugeschnittene Einzelgesichter.
Quelle: https://huggingface.co/datasets/nateraw/fairface
Paper: https://arxiv.org/abs/1908.04913

  python3 tools/enroll_faces.py --owner --shots 24
  python3 tools/enroll_faces.py --others --count 400
  python3 tools/enroll_faces.py --owner --others
"""
from __future__ import annotations

import argparse
import sys
import time
from pathlib import Path

DESK = Path.home() / "Desktop" / "Helios-Gesichter"
OWNER = DESK / "owner"
OTHERS = DESK / "others"
HF_ID = "nateraw/fairface"


def ensure() -> None:
    OWNER.mkdir(parents=True, exist_ok=True)
    OTHERS.mkdir(parents=True, exist_ok=True)
    print(f"Ordner: {DESK}")


def capture_owner(shots: int) -> None:
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
    print(f"owner: Leertaste speichert, q beendet. Ziel {shots}.")
    while saved < shots:
        ok, frame = cam.read()
        if not ok:
            break
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        faces = cascade.detectMultiScale(gray, 1.2, 5, minSize=(80, 80))
        vis = frame.copy()
        n = len(faces)
        if n == 1:
            x, y, w, h = faces[0]
            cv2.rectangle(vis, (x, y), (x + w, y + h), (0, 220, 180), 2)
            msg = "1 Gesicht — Leertaste"
            col = (0, 220, 180)
        elif n == 0:
            msg, col = "kein Gesicht", (0, 80, 255)
        else:
            msg, col = f"{n} Gesichter — nur EINE Person", (0, 80, 255)
            for x, y, w, h in faces:
                cv2.rectangle(vis, (x, y), (x + w, y + h), (0, 80, 255), 1)
        cv2.putText(vis, msg, (12, 28), cv2.FONT_HERSHEY_SIMPLEX, 0.7, col, 2)
        cv2.putText(
            vis,
            f"{saved}/{shots}  {OWNER}",
            (12, vis.shape[0] - 16),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.55,
            (220, 220, 220),
            2,
        )
        cv2.imshow("Helios owner", vis)
        key = cv2.waitKey(20) & 0xFF
        if key == ord("q"):
            break
        if key == 32 and n == 1:
            x, y, w, h = faces[0]
            pad = int(0.25 * max(w, h))
            crop = frame[
                max(0, y - pad) : y + h + pad,
                max(0, x - pad) : x + w + pad,
            ]
            path = OWNER / f"owner_{int(time.time() * 1000)}.jpg"
            cv2.imwrite(str(path), crop)
            saved += 1
            print(path)
    cam.release()
    cv2.destroyAllWindows()
    print(f"owner fertig: {saved} in {OWNER}")


def download_others(count: int) -> None:
    print(f"Hugging Face {HF_ID} — stream, max {count} Einzelgesichter …")
    try:
        from datasets import load_dataset
    except ImportError:
        raise SystemExit("pip3 install datasets pillow")
    try:
        from PIL import Image
    except ImportError:
        raise SystemExit("pip3 install pillow")

    ds = load_dataset(HF_ID, split="train", streaming=True)
    saved = 0
    for i, row in enumerate(ds):
        if saved >= count:
            break
        img = row.get("img") or row.get("image")
        if img is None and row.get("img_bytes"):
            from io import BytesIO

            img = Image.open(BytesIO(row["img_bytes"]))
        if img is None:
            continue
        if not isinstance(img, Image.Image):
            try:
                img = Image.fromarray(img)
            except Exception:
                continue
        img = img.convert("RGB")
        path = OTHERS / f"other_{saved:04d}.jpg"
        img.save(path, quality=92)
        saved += 1
        if saved % 50 == 0:
            print(f"  {saved}/{count}")
    print(f"others fertig: {saved} in {OTHERS}")
    print("Lizenz FairFace: CC BY 4.0, Forschung. Ein Gesicht pro Datei (Crop).")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--owner", action="store_true", help="Kamera → owner")
    p.add_argument("--others", action="store_true", help="Hugging Face → others")
    p.add_argument("--shots", type=int, default=24)
    p.add_argument("--count", type=int, default=400)
    args = p.parse_args()
    if not args.owner and not args.others:
        args.owner = True
        args.others = True
    ensure()
    if args.others:
        download_others(args.count)
    if args.owner:
        capture_owner(args.shots)


if __name__ == "__main__":
    main()

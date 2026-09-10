from __future__ import annotations

import time

from .coord import hold_advance, linear_map, looks_like_pinch, pinch_meter, pinch_starts
from .inject import Injector, primary_screen, virtual_screen


class Engine:
    def __init__(self):
        self.inject = Injector()
        self.mode = "idle"
        self.action = "Helios bereit"
        self.cursor = None
        self.closedness = 0.0
        self.pinch_held = False
        self.pinch_phase = "unseen"
        self.pinch_for = 0.0
        self.pinch_origin = None
        self.became_drag = False
        self.fist_since = None
        self.point_since = None
        self.peace_since = None
        self.thumbs_since = None
        self.ring_since = None
        self.swipe = []
        self.scroll_y = None
        self.two_pinch = None
        self.two_span = None
        self.kill_since = None
        self.cooldown = 0.0
        self.last_arm = 0.0
        self.must_rearm = False
        self.fps = 0.0
        self.ms = 0.0
        self._last = time.perf_counter()
        self._frames = 0
        self._fps_t = time.perf_counter()
        self.homography = None
        self.thumb_px = None
        self.index_px = None
        self.palms_px = {}
        self.test_mode = False

    def _screen(self):
        return virtual_screen()

    def _map(self, palm):
        scr = self._screen()
        if self.homography:
            from .coord import apply_homography

            return apply_homography(self.homography, palm, scr)
        return linear_map(palm, scr)

    def tick(self, hands: list[dict], now: float | None = None) -> None:
        now = now if now is not None else time.perf_counter()
        dt = max(0.008, now - self._last)
        self._last = now
        self._frames += 1
        if now - self._fps_t >= 0.5:
            self.fps = self._frames / (now - self._fps_t)
            self._fps_t = now
            self._frames = 0
        t0 = time.perf_counter()
        self.palms_px = {}
        self.thumb_px = self.index_px = None
        actor = None
        if hands:
            actor = max(hands, key=lambda h: h.get("prob", 0))
            for h in hands:
                self.palms_px[h["id"]] = self._map(h["palm"])
            self.cursor = self._map(actor["palm"])
            j = actor.get("joints") or {}
            if "thumb_tip" in j:
                self.thumb_px = self._map(j["thumb_tip"])
            if "index_tip" in j:
                self.index_px = self._map(j["index_tip"])
            self.closedness = actor.get("closedness", 0)
        else:
            self.cursor = None
            self.closedness = 0.0

        if now < self.cooldown:
            self.ms = (time.perf_counter() - t0) * 1000
            return

        if self._kill(hands, now):
            self.ms = (time.perf_counter() - t0) * 1000
            return
        self._arm(hands, now)
        if self.mode != "armed":
            if self.pinch_held:
                self._drop_pinch(now)
            self.ms = (time.perf_counter() - t0) * 1000
            return

        if actor and self.cursor and not self.test_mode:
            if self.inject.button_down:
                self.inject.move(*self.cursor)
            else:
                self.inject.move(*self.cursor)

        if self._two_pinch(hands, now):
            self.ms = (time.perf_counter() - t0) * 1000
            return
        if actor:
            if self._right_click(actor, now):
                self.ms = (time.perf_counter() - t0) * 1000
                return
            self._pinch(actor, now, dt)
            self._point(actor, now)
            self._peace(actor, hands, now)
            self._thumbs(actor, now)
        self._swipe(hands, actor, now)
        self._scroll(hands, actor, now)
        self.ms = (time.perf_counter() - t0) * 1000

    def _arm(self, hands, now):
        if self.mode == "armed":
            return
        fisting = any(h.get("pose") == "fist" for h in hands)
        if fisting:
            if self.fist_since is None:
                self.fist_since = now
            need = 0.85 if self.must_rearm else 0.55
            if now - self.fist_since >= need and now - self.last_arm > 0.6:
                self.mode = "armed"
                self.must_rearm = False
                self.fist_since = None
                self.last_arm = now
                self.cooldown = now + 0.35
                self.action = "Scharf"
        else:
            self.fist_since = None

    def _kill(self, hands, now) -> bool:
        open_h = [h for h in hands if h.get("pose") == "openPalm" and h.get("open_score", 0) >= 3]
        if len(open_h) >= 2:
            if self.kill_since is None:
                self.kill_since = now
            if now - self.kill_since >= 0.7:
                self.mode = "idle"
                self.must_rearm = True
                self.kill_since = None
                self._drop_pinch(now)
                self.action = "Not-Aus"
                self.cooldown = now + 0.8
                return True
            self.action = "Not-Aus halten"
            return False
        self.kill_since = None
        return False

    def _drop_pinch(self, now):
        if self.pinch_held or self.inject.button_down:
            self.inject.release()
        self.pinch_held = False
        self.pinch_phase = "unseen"
        self.pinch_for = 0.0
        self.pinch_origin = None
        self.became_drag = False

    def _pinch(self, hand, now, dt):
        closed = hand.get("closedness", 0)
        reach = hand.get("reach", 1)
        index = hand.get("index", 0)
        pose = hand.get("pose")
        meter = pinch_meter(
            False,
            closed,
            is_fist=pose == "fist" and not self.became_drag,
            rest=not self.pinch_held and pose in ("openPalm", "thumbsUp"),
        )
        start = pinch_starts(False, closed, reach, index) or (
            meter and looks_like_pinch(reach, index, closed)
        )
        hold = start if not self.pinch_held else (closed >= 0.18 or start)
        phase, held = hold_advance(self.pinch_phase, hold, self.pinch_for, dt)
        self.pinch_phase, self.pinch_for = phase, held
        grabbing = phase == "held"
        if grabbing and not self.pinch_held:
            self.pinch_held = True
            self.became_drag = False
            self.pinch_origin = self.cursor
            self.action = "Halten"
            if self.cursor and not self.test_mode:
                self.inject.press(*self.cursor)
        elif grabbing and self.pinch_held:
            if self.cursor and self.pinch_origin:
                dx = abs(self.cursor[0] - self.pinch_origin[0])
                dy = abs(self.cursor[1] - self.pinch_origin[1])
                if (dx * dx + dy * dy) ** 0.5 >= 40:
                    self.became_drag = True
                    self.action = "Ziehen"
        elif not grabbing and self.pinch_held:
            was_drag = self.became_drag
            origin = self.pinch_origin
            had = self.inject.button_down
            self.inject.release()
            self.pinch_held = False
            self.pinch_phase = "released"
            self.became_drag = False
            self.pinch_origin = None
            ext = hand.get("ext") or {}
            others = sum(1 for k in ("middle", "ring", "little") if ext.get(k, 0) > 0.55)
            if others >= 2 and closed >= 0.2:
                if not self.test_mode:
                    self.inject.open_explorer()
                self.action = "Explorer"
            elif not was_drag:
                if had:
                    self.action = "Klick"
                elif self.cursor and not self.test_mode:
                    self.inject.click(*self.cursor)
                    self.action = "Klick"
                else:
                    self.action = "Klick"
            else:
                self.action = "Loslassen"
            self.cooldown = now + 0.16

    def _right_click(self, hand, now) -> bool:
        if self.pinch_held:
            self.ring_since = None
            return False
        ext = hand.get("ext") or {}
        ring_out = ext.get("ring", 0) > 0.55
        mid_in = ext.get("middle", 0) < 0.45
        pinchish = hand.get("closedness", 0) >= 0.22
        if pinchish and ring_out and mid_in:
            if self.ring_since is None:
                self.ring_since = now
            if now - self.ring_since >= 0.32:
                if self.cursor and not self.test_mode:
                    self.inject.right_click(*self.cursor)
                self.action = "Rechtsklick"
                self.ring_since = None
                self.cooldown = now + 0.4
                return True
            self.action = "Rechtsklick …"
            return True
        self.ring_since = None
        return False

    def _two_pinch(self, hands, now) -> bool:
        pinches = [
            h
            for h in hands
            if h.get("closedness", 0) > 0.28 and looks_like_pinch(h.get("reach", 1), h.get("index", 0), h.get("closedness", 0))
        ]
        if len(pinches) < 2:
            self.two_pinch = None
            self.two_span = None
            return False
        if self.pinch_held:
            self._drop_pinch(now)
        p0, p1 = pinches[0]["palm"], pinches[1]["palm"]
        span = ((p0[0] - p1[0]) ** 2 + (p0[1] - p1[1]) ** 2) ** 0.5
        if self.two_pinch is None:
            self.two_pinch = now
            self.two_span = span
            return True
        if now - self.two_pinch < 0.18:
            return True
        if self.two_span and abs(span - self.two_span) > 0.04:
            scale = 1.0 + (span - self.two_span) * 1.4
            scale = max(0.82, min(1.22, scale))
            if not self.test_mode:
                self.inject.resize_foreground(scale)
            self.action = "Skalieren"
            self.two_span = span
            self.cooldown = now + 0.12
        return True

    def _swipe(self, hands, actor, now):
        if self.pinch_held or now < self.cooldown:
            self.swipe = []
            return
        open_h = [h for h in hands if h.get("pose") == "openPalm" and h.get("prob", 0) >= 0.8]
        if not open_h:
            self.swipe = []
            return
        hand = actor if actor in open_h else open_h[0]
        self.swipe.append((now, hand["palm"][0], hand["palm"][1]))
        self.swipe = [s for s in self.swipe if now - s[0] <= 0.5]
        if len(self.swipe) < 3:
            return
        x0, y0 = self.swipe[0][1], self.swipe[0][2]
        x1, y1 = hand["palm"]
        unit = max(0.04, hand.get("palm_width", 0.1))
        dx = (x1 - x0) / unit
        dy = (y1 - y0) / unit
        dt = now - self.swipe[0][0]
        if dt < 0.08 or dt > 0.55:
            return
        if abs(dx) < 1.2 or abs(dx) < abs(dy) * 1.4:
            return
        forward = dx < 0
        two = len(open_h) >= 2
        if not self.test_mode:
            if two:
                self.inject.switch_desktop(forward)
                self.action = "Nächster Schreibtisch" if forward else "Vorheriger Schreibtisch"
            else:
                self.inject.switch_app(forward)
                self.action = "Nächste App" if forward else "Vorherige App"
        else:
            self.action = "Test: Wischen"
        self.swipe = []
        self.cooldown = now + 0.4

    def _scroll(self, hands, actor, now):
        if self.pinch_held or self.two_pinch:
            self.scroll_y = None
            return
        open_h = [h for h in hands if h.get("open_score", 0) >= 3]
        if len(open_h) != 1:
            self.scroll_y = None
            return
        hand = open_h[0]
        if hand.get("pose") != "openPalm" or hand.get("prob", 0) < 0.7:
            self.scroll_y = None
            return
        y = hand["palm"][1]
        if self.scroll_y is None:
            self.scroll_y = y
            return
        unit = max(0.04, hand.get("palm_width", 0.1))
        dy = (y - self.scroll_y) / unit
        if abs(dy) < 0.18:
            return
        ticks = int(max(-8, min(8, -dy * 4)))
        if ticks and not self.test_mode:
            self.inject.scroll(ticks)
        self.action = "Scroll"
        self.scroll_y = y

    def _point(self, hand, now):
        if hand.get("pose") != "point" or hand.get("prob", 0) < 0.55:
            self.point_since = None
            return
        if self.point_since is None:
            self.point_since = now
        if now - self.point_since >= 0.85:
            if not self.test_mode:
                self.inject.os_keyboard()
            self.action = "Bildschirmtastatur"
            self.point_since = None
            self.cooldown = now + 1.2

    def _peace(self, hand, hands, now):
        other = any(h["id"] != hand["id"] and h.get("open_score", 0) >= 3 for h in hands)
        if other or hand.get("pose") != "peace" or hand.get("prob", 0) < 0.5:
            self.peace_since = None
            return
        if self.peace_since is None:
            self.peace_since = now
        if now - self.peace_since >= 1.0:
            if not self.test_mode:
                self.inject.screenshot()
            self.action = "Aufnahme"
            self.peace_since = None
            self.cooldown = now + 3

    def _thumbs(self, hand, now):
        ok = hand.get("pose") == "thumbsUp" and hand.get("prob", 0) >= 0.75 and hand.get("open_score", 0) <= 1
        if not ok:
            self.thumbs_since = None
            return
        if self.thumbs_since is None:
            self.thumbs_since = now
        if now - self.thumbs_since >= 0.9 and self.cursor:
            hwnd = self.inject.window_at(*self.cursor) if not self.test_mode else 0
            if not self.test_mode:
                self.inject.foreground(hwnd)
            self.action = "Hervorholen"
            self.thumbs_since = None
            self.cooldown = now + 2

    def snapshot(self) -> dict:
        return {
            "mode": self.mode,
            "action": self.action,
            "cursor": self.cursor,
            "closedness": self.closedness,
            "fps": self.fps,
            "ms": self.ms,
            "pinch_line": self.pinch_held or self.closedness >= 0.24,
            "thumb_px": self.thumb_px,
            "index_px": self.index_px,
            "palms_px": self.palms_px,
        }

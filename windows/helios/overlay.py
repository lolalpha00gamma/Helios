"""Click-through layered HUD covering the virtual desktop."""

from __future__ import annotations

import ctypes
import ctypes.wintypes as wt

import cv2
import numpy as np

from .inject import virtual_screen
from .version import VERSION

user32 = ctypes.windll.user32
gdi32 = ctypes.windll.gdi32

WS_POPUP = 0x80000000
WS_EX_LAYERED = 0x00080000
WS_EX_TRANSPARENT = 0x00000020
WS_EX_TOPMOST = 0x00000008
WS_EX_TOOLWINDOW = 0x00000080
WS_EX_NOACTIVATE = 0x08000000
HWND_TOPMOST = -1
ULW_ALPHA = 0x02
AC_SRC_OVER = 0
AC_SRC_ALPHA = 1
SWP_SHOWWINDOW = 0x0040
SW_SHOWNOACTIVATE = 4
CYAN = (255, 224, 63)
AMBER = (74, 184, 255)
VOID = (16, 10, 7)
OK = (138, 224, 62)


class BLENDFUNCTION(ctypes.Structure):
    _fields_ = [
        ("BlendOp", ctypes.c_byte),
        ("BlendFlags", ctypes.c_byte),
        ("SourceConstantAlpha", ctypes.c_byte),
        ("AlphaFormat", ctypes.c_byte),
    ]


class BITMAPINFOHEADER(ctypes.Structure):
    _fields_ = [
        ("biSize", wt.DWORD),
        ("biWidth", wt.LONG),
        ("biHeight", wt.LONG),
        ("biPlanes", wt.WORD),
        ("biBitCount", wt.WORD),
        ("biCompression", wt.DWORD),
        ("biSizeImage", wt.DWORD),
        ("biXPelsPerMeter", wt.LONG),
        ("biYPelsPerMeter", wt.LONG),
        ("biClrUsed", wt.DWORD),
        ("biClrImportant", wt.DWORD),
    ]


class BITMAPINFO(ctypes.Structure):
    _fields_ = [("bmiHeader", BITMAPINFOHEADER), ("bmiColors", wt.DWORD * 3)]


WNDPROC = ctypes.WINFUNCTYPE(ctypes.c_ssize_t, wt.HWND, wt.UINT, wt.WPARAM, wt.LPARAM)


def _wndproc(hwnd, msg, wparam, lparam):
    if msg == 0x0010:  # WM_CLOSE
        return 0
    return user32.DefWindowProcW(hwnd, msg, wparam, lparam)


_WNDPROC_REF = WNDPROC(_wndproc)


class WNDCLASSW(ctypes.Structure):
    _fields_ = [
        ("style", wt.UINT),
        ("lpfnWndProc", WNDPROC),
        ("cbClsExtra", ctypes.c_int),
        ("cbWndExtra", ctypes.c_int),
        ("hInstance", wt.HINSTANCE),
        ("hIcon", wt.HICON),
        ("hCursor", wt.HANDLE),
        ("hbrBackground", wt.HBRUSH),
        ("lpszMenuName", wt.LPCWSTR),
        ("lpszClassName", wt.LPCWSTR),
    ]


def _register() -> None:
    hinst = ctypes.windll.kernel32.GetModuleHandleW(None)
    cls = WNDCLASSW()
    cls.lpfnWndProc = _WNDPROC_REF
    cls.hInstance = hinst
    cls.lpszClassName = "HeliosHUD"
    user32.RegisterClassW(ctypes.byref(cls))


class Overlay:
    def __init__(self):
        self.hwnd = None
        self._x = self._y = self._w = self._h = 0
        self.visible = True
        try:
            _register()
        except Exception:
            pass
        self._create()

    def _create(self) -> None:
        x, y, w, h = virtual_screen()
        self._x, self._y, self._w, self._h = x, y, w, h
        hinst = ctypes.windll.kernel32.GetModuleHandleW(None)
        ex = WS_EX_LAYERED | WS_EX_TRANSPARENT | WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE
        hwnd = user32.CreateWindowExW(
            ex, "HeliosHUD", "Helios HUD", WS_POPUP, x, y, w, h, None, None, hinst, None
        )
        self.hwnd = hwnd
        user32.SetWindowPos(hwnd, HWND_TOPMOST, x, y, w, h, SWP_SHOWWINDOW)
        user32.ShowWindow(hwnd, SW_SHOWNOACTIVATE)

    def close(self) -> None:
        if self.hwnd:
            user32.DestroyWindow(self.hwnd)
            self.hwnd = None

    def render(self, state: dict, hands: list[dict]) -> None:
        if not self.hwnd or not self.visible:
            return
        w, h = self._w, self._h
        if w < 8 or h < 8:
            return
        img = np.zeros((h, w, 4), np.uint8)
        mode = state.get("mode", "idle")
        armed = mode == "armed"
        bar_w, bar_h = min(420, w - 40), 28
        bx = (w - bar_w) // 2
        by = 8
        _rect(img, bx, by, bar_w, bar_h, (*VOID, 200))
        label = f"HELIOS  {VERSION}   {'SCHARF' if armed else 'BEREIT'}   {state.get('fps', 0):.0f} fps   {state.get('ms', 0):.0f} ms"
        color = AMBER if armed else CYAN
        cv2.putText(img, label, (bx + 10, by + 20), cv2.FONT_HERSHEY_SIMPLEX, 0.42, (*color, 255), 1, cv2.LINE_AA)
        action = state.get("action") or ""
        if action:
            tw = 12 * len(action) + 24
            _rect(img, w // 2 - tw // 2, by + 34, tw, 22, (*VOID, 180))
            cv2.putText(
                img,
                action,
                (w // 2 - tw // 2 + 10, by + 50),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.42,
                (*AMBER, 255),
                1,
                cv2.LINE_AA,
            )
        cursor = state.get("cursor")
        if cursor and armed:
            cx, cy = int(cursor[0] - self._x), int(cursor[1] - self._y)
            closed = float(state.get("closedness", 0))
            col = AMBER if closed >= 0.24 else CYAN
            cv2.circle(img, (cx, cy), 18, (*col, 220), 2, cv2.LINE_AA)
            cv2.circle(img, (cx, cy), 3, (*col, 255), -1, cv2.LINE_AA)
            if state.get("pinch_line") and state.get("thumb_px") and state.get("index_px"):
                a, b = state["thumb_px"], state["index_px"]
                pa = (int(a[0] - self._x), int(a[1] - self._y))
                pb = (int(b[0] - self._x), int(b[1] - self._y))
                cv2.line(img, pa, pb, (*col, 230), 2, cv2.LINE_AA)
        for hand in hands:
            palm = state.get("palms_px", {}).get(hand.get("id"))
            if not palm:
                continue
            px, py = int(palm[0] - self._x), int(palm[1] - self._y)
            pose = hand.get("pose_de", "")
            cv2.putText(img, pose, (px + 14, py - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (*CYAN, 220), 1, cv2.LINE_AA)
        self._blit(img)

    def _blit(self, bgra: np.ndarray) -> None:
        h, w = bgra.shape[:2]
        # Windows DIB is BGRA, bottom-up unless height negative.
        buf = np.ascontiguousarray(bgra)
        bmi = BITMAPINFO()
        bmi.bmiHeader.biSize = ctypes.sizeof(BITMAPINFOHEADER)
        bmi.bmiHeader.biWidth = w
        bmi.bmiHeader.biHeight = -h
        bmi.bmiHeader.biPlanes = 1
        bmi.bmiHeader.biBitCount = 32
        bmi.bmiHeader.biCompression = 0
        hdc_screen = user32.GetDC(0)
        hdc_mem = gdi32.CreateCompatibleDC(hdc_screen)
        dib = ctypes.c_void_p()
        hbm = gdi32.CreateDIBSection(hdc_mem, ctypes.byref(bmi), 0, ctypes.byref(dib), None, 0)
        if not hbm or not dib:
            gdi32.DeleteDC(hdc_mem)
            user32.ReleaseDC(0, hdc_screen)
            return
        ctypes.memmove(dib, buf.ctypes.data, buf.nbytes)
        gdi32.SelectObject(hdc_mem, hbm)
        blend = BLENDFUNCTION(AC_SRC_OVER, 0, 255, AC_SRC_ALPHA)
        size = wt.SIZE(w, h)
        pt_src = wt.POINT(0, 0)
        pt_dst = wt.POINT(self._x, self._y)
        user32.UpdateLayeredWindow(
            self.hwnd,
            hdc_screen,
            ctypes.byref(pt_dst),
            ctypes.byref(size),
            hdc_mem,
            ctypes.byref(pt_src),
            0,
            ctypes.byref(blend),
            ULW_ALPHA,
        )
        gdi32.DeleteObject(hbm)
        gdi32.DeleteDC(hdc_mem)
        user32.ReleaseDC(0, hdc_screen)


def _rect(img, x, y, w, h, color):
    x0, y0 = max(0, x), max(0, y)
    x1, y1 = min(img.shape[1], x + w), min(img.shape[0], y + h)
    if x1 <= x0 or y1 <= y0:
        return
    overlay = img[y0:y1, x0:x1]
    a = color[3] / 255.0
    overlay[:, :, :3] = (overlay[:, :, :3] * (1 - a) + np.array(color[:3]) * a).astype(np.uint8)
    overlay[:, :, 3] = np.maximum(overlay[:, :, 3], color[3])

"""Win32 pointer, keys, windows. No pywin32 — ctypes only."""

from __future__ import annotations

import ctypes
import ctypes.wintypes as wt
import time

user32 = ctypes.windll.user32
gdi32 = ctypes.windll.gdi32
kernel32 = ctypes.windll.kernel32

ULONG_PTR = ctypes.c_uint64 if ctypes.sizeof(ctypes.c_void_p) == 8 else ctypes.c_uint32

MOUSEEVENTF_MOVE = 0x0001
MOUSEEVENTF_LEFTDOWN = 0x0002
MOUSEEVENTF_LEFTUP = 0x0004
MOUSEEVENTF_RIGHTDOWN = 0x0008
MOUSEEVENTF_RIGHTUP = 0x0010
MOUSEEVENTF_WHEEL = 0x0800
MOUSEEVENTF_ABSOLUTE = 0x8000
MOUSEEVENTF_VIRTUALDESK = 0x4000
WHEEL_DELTA = 120
KEYEVENTF_KEYUP = 0x0002
VK_SHIFT = 0x10
VK_CONTROL = 0x11
VK_MENU = 0x12
VK_LWIN = 0x5B
VK_LEFT = 0x25
VK_RIGHT = 0x27
VK_ESCAPE = 0x1B
VK_E = 0x45
VK_O = 0x4F
VK_SNAPSHOT = 0x2C
SW_MINIMIZE = 6
SW_MAXIMIZE = 3
SW_RESTORE = 9
SWP_NOSIZE = 0x0001
SWP_NOZORDER = 0x0004

INPUT_MOUSE = 0
INPUT_KEYBOARD = 1


class MOUSEINPUT(ctypes.Structure):
    _fields_ = [
        ("dx", wt.LONG),
        ("dy", wt.LONG),
        ("mouseData", wt.DWORD),
        ("dwFlags", wt.DWORD),
        ("time", wt.DWORD),
        ("dwExtraInfo", ULONG_PTR),
    ]


class KEYBDINPUT(ctypes.Structure):
    _fields_ = [
        ("wVk", wt.WORD),
        ("wScan", wt.WORD),
        ("dwFlags", wt.DWORD),
        ("time", wt.DWORD),
        ("dwExtraInfo", ULONG_PTR),
    ]


class HARDWAREINPUT(ctypes.Structure):
    _fields_ = [("uMsg", wt.DWORD), ("wParamL", wt.WORD), ("wParamH", wt.WORD)]


class INPUT_UNION(ctypes.Union):
    _fields_ = [("mi", MOUSEINPUT), ("ki", KEYBDINPUT), ("hi", HARDWAREINPUT)]


class INPUT(ctypes.Structure):
    _fields_ = [("type", wt.DWORD), ("union", INPUT_UNION)]


def _dpi() -> None:
    try:
        ctypes.windll.shcore.SetProcessDpiAwareness(2)
    except Exception:
        user32.SetProcessDPIAware()


def virtual_screen() -> tuple[int, int, int, int]:
    x = user32.GetSystemMetrics(76)
    y = user32.GetSystemMetrics(77)
    w = user32.GetSystemMetrics(78)
    h = user32.GetSystemMetrics(79)
    return x, y, w, h


def primary_screen() -> tuple[int, int, int, int]:
    return 0, 0, user32.GetSystemMetrics(0), user32.GetSystemMetrics(1)


def _abs(x: int, y: int) -> tuple[int, int]:
    vx, vy, vw, vh = virtual_screen()
    if vw <= 0 or vh <= 0:
        return 0, 0
    ax = int((x - vx) * 65535 / max(1, vw - 1))
    ay = int((y - vy) * 65535 / max(1, vh - 1))
    return ax, ay


def _send(inputs: list[INPUT]) -> None:
    n = len(inputs)
    arr = (INPUT * n)(*inputs)
    user32.SendInput(n, ctypes.byref(arr), ctypes.sizeof(INPUT))


def _mouse(flags: int, x: int | None = None, y: int | None = None, data: int = 0) -> INPUT:
    dx = dy = 0
    if x is not None and y is not None:
        dx, dy = _abs(x, y)
        flags |= MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_VIRTUALDESK | MOUSEEVENTF_MOVE
    mi = MOUSEINPUT(dx, dy, data, flags, 0, 0)
    return INPUT(INPUT_MOUSE, INPUT_UNION(mi=mi))


def _key(vk: int, up: bool = False) -> INPUT:
    ki = KEYBDINPUT(vk, 0, KEYEVENTF_KEYUP if up else 0, 0, 0)
    return INPUT(INPUT_KEYBOARD, INPUT_UNION(ki=ki))


class Injector:
    def __init__(self):
        _dpi()
        self.button_down = False
        self.last = (0, 0)
        self.last_click = 0.0

    def move(self, x: int, y: int) -> None:
        self.last = (int(x), int(y))
        flags = MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_VIRTUALDESK
        if self.button_down:
            _send([_mouse(flags, x, y)])
        else:
            _send([_mouse(flags, x, y)])

    def press(self, x: int, y: int) -> str:
        if self.button_down:
            self.move(x, y)
            return "Halten"
        self.move(x, y)
        _send([_mouse(MOUSEEVENTF_LEFTDOWN, x, y)])
        self.button_down = True
        return "Halten"

    def release(self) -> None:
        if not self.button_down:
            return
        x, y = self.last
        _send([_mouse(MOUSEEVENTF_LEFTUP, x, y)])
        self.button_down = False

    def click(self, x: int, y: int) -> str:
        now = time.perf_counter()
        if now - self.last_click < 0.12:
            return "Klick-Hitch"
        self.last_click = now
        if self.button_down:
            self.move(x, y)
            self.release()
            return "Klick"
        self.move(x, y)
        _send([_mouse(MOUSEEVENTF_LEFTDOWN, x, y), _mouse(MOUSEEVENTF_LEFTUP, x, y)])
        return "Klick"

    def right_click(self, x: int, y: int) -> str:
        if self.button_down:
            self.release()
        self.move(x, y)
        _send([_mouse(MOUSEEVENTF_RIGHTDOWN, x, y), _mouse(MOUSEEVENTF_RIGHTUP, x, y)])
        return "Rechtsklick"

    def scroll(self, ticks: int) -> str:
        if ticks == 0:
            return "—"
        x, y = self.last
        _send([_mouse(MOUSEEVENTF_WHEEL, x, y, int(ticks * WHEEL_DELTA))])
        return "Scroll"

    def chord(self, *vks: int, hold: float = 0.05) -> None:
        _send([_key(v) for v in vks])
        time.sleep(hold)
        _send([_key(v, up=True) for v in reversed(vks)])

    def switch_desktop(self, forward: bool) -> str:
        self.chord(VK_LWIN, VK_CONTROL, VK_RIGHT if forward else VK_LEFT)
        return "Nächster Schreibtisch" if forward else "Vorheriger Schreibtisch"

    def switch_app(self, forward: bool) -> str:
        if forward:
            self.chord(VK_MENU, VK_ESCAPE)
        else:
            self.chord(VK_MENU, VK_SHIFT, VK_ESCAPE)
        return "Nächste App" if forward else "Vorherige App"

    def open_explorer(self) -> str:
        self.chord(VK_LWIN, VK_E)
        return "Explorer"

    def os_keyboard(self) -> str:
        self.chord(VK_LWIN, VK_CONTROL, VK_O)
        return "Bildschirmtastatur"

    def screenshot(self) -> str:
        user32.keybd_event(VK_SNAPSHOT, 0, 0, 0)
        user32.keybd_event(VK_SNAPSHOT, 0, KEYEVENTF_KEYUP, 0)
        return "Aufnahme"

    def window_at(self, x: int, y: int) -> int:
        return int(user32.WindowFromPoint(wt.POINT(int(x), int(y))))

    def foreground(self, hwnd: int) -> str:
        if not hwnd:
            return "Kein Fenster"
        user32.ShowWindow(hwnd, SW_RESTORE)
        user32.SetForegroundWindow(hwnd)
        return "Hervorholen"

    def resize_foreground(self, scale: float) -> str:
        hwnd = user32.GetForegroundWindow()
        if not hwnd:
            return "Kein Fenster"
        r = wt.RECT()
        user32.GetWindowRect(hwnd, ctypes.byref(r))
        cx = (r.left + r.right) // 2
        cy = (r.top + r.bottom) // 2
        w = max(200, int((r.right - r.left) * scale))
        h = max(150, int((r.bottom - r.top) * scale))
        user32.SetWindowPos(hwnd, 0, cx - w // 2, cy - h // 2, w, h, SWP_NOZORDER)
        return "Skalieren"

    def minimize_foreground(self) -> str:
        hwnd = user32.GetForegroundWindow()
        if hwnd:
            user32.ShowWindow(hwnd, SW_MINIMIZE)
        return "Minimieren"

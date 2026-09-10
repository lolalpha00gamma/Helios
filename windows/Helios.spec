# PyInstaller — Windows 11 Helios
import sys
from PyInstaller.utils.hooks import collect_data_files, collect_dynamic_libs

from pathlib import Path

block_cipher = None
root = Path(SPECPATH)
model = root / "helios" / "models" / "hand_landmarker.task"
datas = collect_data_files("mediapipe")
if model.exists():
    datas += [(str(model), "helios/models")]
binaries = collect_dynamic_libs("mediapipe")

a = Analysis(
    [str(root / "Helios.py")],
    pathex=[str(root)],
    binaries=binaries,
    datas=datas,
    hiddenimports=[
        "mediapipe",
        "mediapipe.tasks",
        "mediapipe.tasks.python",
        "mediapipe.tasks.python.vision",
        "cv2",
        "numpy",
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)
pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)
exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name="Helios",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=False,
    disable_windowed_traceback=False,
    icon=None,
)

# Helios für Windows 11

Gleiche Gestensteuerung wie die macOS-App: Webcam, Handerkennung (MediaPipe), Overlay, Maus und Fenster.

## Installieren

1. Release **Helios-windows.zip** entpacken.
2. `Helios.exe` starten (kein Admin nötig, außer du willst erhöhte Fenster steuern).
3. Windows fragt nach der **Kamera** — erlauben.
4. Faust halten → **SCHARF**. Danach Pinzette = Klick.

Oder aus dem Quellcode (Python 3.11+):

```
pip install -r requirements.txt
python Helios.py
```

Beim ersten Start lädt Helios das Hand-Modell (~7 MB) nach `%LOCALAPPDATA%\Helios\`.

## Gesten

| Geste | Aktion |
|---|---|
| Faust ~0,6 s | Scharf |
| Beide Hände offen still | Not-Aus (Idle) |
| Pinzette kurz | Klick |
| Pinzette ziehen | Ziehen |
| Pinzette + Ringfinger | Rechtsklick |
| Zwei Pinzetten | Fenster skalieren |
| Eine offene Hand wischen | Nächste/vorige App |
| Zwei offene Hände wischen | Virtueller Schreibtisch (Win+Strg+←/→) |
| Offene Hand hoch/runter | Scroll |
| Zeigen 0,85 s | Bildschirmtastatur |
| OK-Zeichen | Explorer |
| Peace ~1 s | Aufnahme (Druck) |
| Daumen hoch | Fenster unter dem Zeiger nach vorn |

Tasten im Kamerafenster: **S** Scharf, **Esc** Idle, **Q** Ende, **C** nächste Kamera, **O** Overlay.

## Hinweise

- Windows 11, x64. Webcam oder Continuity/Phone-Link-Kamera.
- Overlay liegt über allen Fenstern, klickt aber durch.
- Log: `%LOCALAPPDATA%\Helios\helios.log`
- Version entspricht der macOS-Linie (`1.6.113`).

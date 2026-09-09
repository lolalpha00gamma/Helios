# CameraBroker — Spezifikation (kein Feature-Fleisch)

P0 für Helios + Aegis. Eine Continuity-Kamera, zwei Apps, zwei TCC, zwei Vision.

## Ziel

Ein Prozess hält `AVCaptureSession`. Helios und Aegis holen Frames über XPC, nicht über eine zweite Session.

## Transport

- XPC Mach-Service `app.helios.aegis.camerabroker`.
- Frame: `IOSurface` (kein CGImage-Hop). `CVPixelBuffer` bleibt shared.
- Heartbeat 2 s. Stale 12 s. Ersetzt `helios.aegis.camera.lock` Datei.

## Rollen

- **Helios:** Hands + Body-Pose. ROI + palmWidth an den Broker (Aegis skipPrints Palme).
- **Aegis:** Faces. skipDetect / skipPrints lokal. `VNImageRequestHandler(cvPixelBuffer:)`.
- **Broker:** Format, AE-Lock Continuity, Center Stage off, 420v, Leiter 720p24.

## Nicht in diesem Pass

Kein XPC-Target, kein Entitlement, kein Info.plist, kein Daemon. Spec only.

Predict bleibt 0. Branch `bugfix` nicht mergen.

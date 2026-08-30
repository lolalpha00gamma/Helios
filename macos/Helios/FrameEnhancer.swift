import CoreImage
import CoreVideo
import Foundation

/// Kontrast/Belichtung nur für Vision — Geometrie bleibt 1:1 zum Preview.
final class FrameEnhancer: @unchecked Sendable {
    private let ci = CIContext(options: [.useSoftwareRenderer: false, .cacheIntermediates: false])
    private var pool: CVPixelBuffer?
    private let lock = NSLock()

    /// Raster-Stichprobe, kein CI-Filter — unter 0,2 ms.
    func luma(of pb: CVPixelBuffer) -> CGFloat {
        CVPixelBufferLockBaseAddress(pb, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pb, .readOnly) }
        let w = CVPixelBufferGetWidth(pb)
        let h = CVPixelBufferGetHeight(pb)
        guard w > 8, h > 8 else { return 0.5 }
        let stepX = max(1, w / 16)
        let stepY = max(1, h / 16)
        var sum: UInt64 = 0
        var n: UInt64 = 0
        if CVPixelBufferGetPlaneCount(pb) >= 1,
           let base = CVPixelBufferGetBaseAddressOfPlane(pb, 0)
        {
            let stride = CVPixelBufferGetBytesPerRowOfPlane(pb, 0)
            let ptr = base.assumingMemoryBound(to: UInt8.self)
            var y = 0
            while y < h {
                let row = ptr + y * stride
                var x = 0
                while x < w {
                    sum += UInt64(row[x])
                    n += 1
                    x += stepX
                }
                y += stepY
            }
        } else if let base = CVPixelBufferGetBaseAddress(pb) {
            let stride = CVPixelBufferGetBytesPerRow(pb)
            let ptr = base.assumingMemoryBound(to: UInt8.self)
            var y = 0
            while y < h {
                let row = ptr + y * stride
                var x = 0
                while x < w {
                    let i = x * 4
                    let b = UInt64(row[i])
                    let g = UInt64(row[i + 1])
                    let r = UInt64(row[i + 2])
                    sum += (r + g * 2 + b) / 4
                    n += 1
                    x += stepX
                }
                y += stepY
            }
        }
        guard n > 0 else { return 0.5 }
        return CGFloat(sum) / CGFloat(n * 255)
    }

    func enhance(_ pb: CVPixelBuffer, luma: CGFloat) -> CVPixelBuffer {
        guard luma < 0.46 else { return pb }
        var image = CIImage(cvPixelBuffer: pb)
        let ev = min(1.8, max(0.15, (0.46 - luma) * 3.8))
        if let f = CIFilter(name: "CIExposureAdjust") {
            f.setValue(image, forKey: kCIInputImageKey)
            f.setValue(ev, forKey: kCIInputEVKey)
            if let o = f.outputImage { image = o }
        }
        if luma < 0.28, let f = CIFilter(name: "CIHighlightShadowAdjust") {
            f.setValue(image, forKey: kCIInputImageKey)
            f.setValue(0.72, forKey: "inputShadowAmount")
            f.setValue(0.18, forKey: "inputHighlightAmount")
            if let o = f.outputImage { image = o }
        }
        if let f = CIFilter(name: "CIColorControls") {
            f.setValue(image, forKey: kCIInputImageKey)
            f.setValue(1.18, forKey: kCIInputContrastKey)
            f.setValue(1.04, forKey: kCIInputSaturationKey)
            if let o = f.outputImage { image = o }
        }
        if luma < 0.22, let f = CIFilter(name: "CIUnsharpMask") {
            f.setValue(image, forKey: kCIInputImageKey)
            f.setValue(0.35, forKey: kCIInputIntensityKey)
            f.setValue(1.6, forKey: kCIInputRadiusKey)
            if let o = f.outputImage { image = o }
        }
        return render(image, like: pb) ?? pb
    }

    private func render(_ image: CIImage, like src: CVPixelBuffer) -> CVPixelBuffer? {
        let w = CVPixelBufferGetWidth(src)
        let h = CVPixelBufferGetHeight(src)
        lock.lock()
        defer { lock.unlock() }
        if let pool,
           CVPixelBufferGetWidth(pool) == w,
           CVPixelBufferGetHeight(pool) == h
        {
            ci.render(image, to: pool)
            return pool
        }
        var out: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferIOSurfacePropertiesKey as String: [:] as CFDictionary,
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        CVPixelBufferCreate(kCFAllocatorDefault, w, h, kCVPixelFormatType_32BGRA, attrs as CFDictionary, &out)
        guard let out else { return nil }
        ci.render(image, to: out)
        pool = out
        return out
    }
}

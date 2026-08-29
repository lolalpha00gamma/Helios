import CoreImage
import CoreVideo
import Foundation

/// Kontrast/Belichtung nur für Vision — Geometrie bleibt 1:1 zum Preview.
final class FrameEnhancer: @unchecked Sendable {
    private let ci = CIContext(options: [.useSoftwareRenderer: false, .cacheIntermediates: false])
    private var pool: CVPixelBuffer?
    private let lock = NSLock()

    func luma(of pb: CVPixelBuffer) -> CGFloat {
        let w = CVPixelBufferGetWidth(pb)
        let h = CVPixelBufferGetHeight(pb)
        guard w > 8, h > 8 else { return 0.5 }
        let src = CIImage(cvPixelBuffer: pb)
        let scale = 48 / max(CGFloat(w), CGFloat(h))
        let small = src.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let extent = small.extent
        guard let filter = CIFilter(name: "CIAreaAverage") else { return 0.5 }
        filter.setValue(small, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)
        guard let out = filter.outputImage else { return 0.5 }
        var pixel = [UInt8](repeating: 0, count: 4)
        ci.render(
            out,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )
        return (CGFloat(pixel[0]) + CGFloat(pixel[1]) + CGFloat(pixel[2])) / (3 * 255)
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

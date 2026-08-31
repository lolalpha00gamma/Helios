import CoreImage
import CoreVideo
import Foundation

/// Belichtung/Kontrast auf der GPU. Geometrie bleibt 1:1 zum Preview.
final class FrameEnhancer: @unchecked Sendable {
    private var ping: CVPixelBuffer?
    private var pong: CVPixelBuffer?
    private var usePing = true
    private let lock = NSLock()
    private var lumaScratch: CVPixelBuffer?

    func luma(of pb: CVPixelBuffer) -> CGFloat {
        let img = CIImage(cvPixelBuffer: pb)
        let extent = img.extent
        guard extent.width > 8, extent.height > 8 else { return 0.5 }
        guard let avg = CIFilter(name: "CIAreaAverage") else { return cpuLuma(pb) }
        avg.setValue(img, forKey: kCIInputImageKey)
        avg.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)
        guard let out = avg.outputImage else { return cpuLuma(pb) }
        lock.lock()
        if lumaScratch == nil {
            lumaScratch = MetalHub.makeBuffer(width: 1, height: 1)
        }
        let dest = lumaScratch
        lock.unlock()
        guard let dest else { return cpuLuma(pb) }
        MetalHub.ci.render(out, to: dest, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), colorSpace: nil)
        CVPixelBufferLockBaseAddress(dest, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(dest, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(dest) else { return 0.5 }
        let p = base.assumingMemoryBound(to: UInt8.self)
        let b = CGFloat(p[0])
        let g = CGFloat(p[1])
        let r = CGFloat(p[2])
        return (r + g * 2 + b) / (4 * 255)
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
        if ping == nil || CVPixelBufferGetWidth(ping!) != w || CVPixelBufferGetHeight(ping!) != h {
            ping = MetalHub.makeBuffer(width: w, height: h)
            pong = MetalHub.makeBuffer(width: w, height: h)
        }
        usePing.toggle()
        let dest = usePing ? ping : pong
        lock.unlock()
        guard let dest else { return nil }
        MetalHub.ci.render(image, to: dest)
        return dest
    }

    private func cpuLuma(_ pb: CVPixelBuffer) -> CGFloat {
        CVPixelBufferLockBaseAddress(pb, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pb, .readOnly) }
        let w = CVPixelBufferGetWidth(pb)
        let h = CVPixelBufferGetHeight(pb)
        guard w > 8, h > 8, let base = CVPixelBufferGetBaseAddress(pb) else { return 0.5 }
        let stride = CVPixelBufferGetBytesPerRow(pb)
        let ptr = base.assumingMemoryBound(to: UInt8.self)
        let stepX = max(1, w / 16)
        let stepY = max(1, h / 16)
        var sum: UInt64 = 0
        var n: UInt64 = 0
        var y = 0
        while y < h {
            let row = ptr + y * stride
            var x = 0
            while x < w {
                let i = x * 4
                let b = UInt64(row[i])
                let g = UInt64(row[i + 1])
                let r = UInt64(row[i + 2])
                sum += 30 * r + 59 * g + 11 * b
                n += 1
                x += stepX
            }
            y += stepY
        }
        guard n > 0 else { return 0.5 }
        return CGFloat(sum) / CGFloat(n * 100 * 255)
    }
}

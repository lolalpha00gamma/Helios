import CoreImage
import CoreVideo
import Foundation

/// Belichtung/Kontrast auf der GPU. Geometrie bleibt 1:1 zum Preview.
final class FrameEnhancer: @unchecked Sendable {
    private var ping: CVPixelBuffer?
    private var pong: CVPixelBuffer?
    private var usePing = true
    private let lock = NSLock()

    func luma(of pb: CVPixelBuffer) -> CGFloat {
        let fmt = CVPixelBufferGetPixelFormatType(pb)
        if fmt == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            || fmt == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        {
            return luma420(pb)
        }
        CVPixelBufferLockBaseAddress(pb, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pb, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(pb) else { return 0.5 }
        let w = CVPixelBufferGetWidth(pb)
        let h = CVPixelBufferGetHeight(pb)
        let stride = CVPixelBufferGetBytesPerRow(pb)
        let ptr = base.assumingMemoryBound(to: UInt8.self)
        var sum: CGFloat = 0
        var n: CGFloat = 0
        let stepX = max(1, w / 16)
        let stepY = max(1, h / 12)
        var y = 0
        while y < h {
            var x = 0
            let row = ptr.advanced(by: y * stride)
            while x < w {
                let i = x * 4
                let b = CGFloat(row[i])
                let g = CGFloat(row[i + 1])
                let r = CGFloat(row[i + 2])
                sum += r + g * 2 + b
                n += 1
                x += stepX
            }
            y += stepY
        }
        guard n > 0 else { return 0.5 }
        return sum / (n * 4 * 255)
    }

    private func luma420(_ pb: CVPixelBuffer) -> CGFloat {
        CVPixelBufferLockBaseAddress(pb, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pb, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddressOfPlane(pb, 0) else { return 0.5 }
        let w = CVPixelBufferGetWidthOfPlane(pb, 0)
        let h = CVPixelBufferGetHeightOfPlane(pb, 0)
        let stride = CVPixelBufferGetBytesPerRowOfPlane(pb, 0)
        let ptr = base.assumingMemoryBound(to: UInt8.self)
        var sum: CGFloat = 0
        var n: CGFloat = 0
        let stepX = max(1, w / 16)
        let stepY = max(1, h / 12)
        var y = 0
        while y < h {
            var x = 0
            let row = ptr.advanced(by: y * stride)
            while x < w {
                sum += CGFloat(row[x])
                n += 1
                x += stepX
            }
            y += stepY
        }
        guard n > 0 else { return 0.5 }
        return GestureMath.luma420Lift(osType: CVPixelBufferGetPixelFormatType(pb), luma: sum / (n * 255))
    }

    func enhance(_ pb: CVPixelBuffer, luma: CGFloat) -> CVPixelBuffer {
        guard GestureMath.enhanceDownscales(luma: luma) else { return pb }
        let scaled = downscale(pb) ?? pb
        var image = CIImage(cvPixelBuffer: scaled)
        let ev = min(1.4, max(0.12, (0.30 - luma) * 3.2))
        if let f = CIFilter(name: "CIExposureAdjust") {
            f.setValue(image, forKey: kCIInputImageKey)
            f.setValue(ev, forKey: kCIInputEVKey)
            if let o = f.outputImage { image = o }
        }
        return render(image, like: scaled) ?? scaled
    }

    private func downscale(_ pb: CVPixelBuffer) -> CVPixelBuffer? {
        let w = CVPixelBufferGetWidth(pb)
        let h = CVPixelBufferGetHeight(pb)
        guard w > 960 else { return pb }
        let s = 960 / CGFloat(w)
        let tw = 960
        let th = max(2, Int((CGFloat(h) * s).rounded()))
        let fmt = GestureMath.enhanceDestFormat(osType: CVPixelBufferGetPixelFormatType(pb))
        lock.lock()
        if ping == nil || CVPixelBufferGetWidth(ping!) != tw || CVPixelBufferGetHeight(ping!) != th
            || CVPixelBufferGetPixelFormatType(ping!) != fmt
        {
            ping = MetalHub.makeBuffer(width: tw, height: th, format: fmt)
            pong = MetalHub.makeBuffer(width: tw, height: th, format: fmt)
        }
        usePing.toggle()
        let dest = usePing ? ping : pong
        lock.unlock()
        guard let dest else { return pb }
        let img = CIImage(cvPixelBuffer: pb).transformed(by: CGAffineTransform(scaleX: s, y: s))
        MetalHub.ci.render(img, to: dest, bounds: CGRect(x: 0, y: 0, width: tw, height: th), colorSpace: nil)
        return dest
    }

    private func render(_ image: CIImage, like src: CVPixelBuffer) -> CVPixelBuffer? {
        let w = CVPixelBufferGetWidth(src)
        let h = CVPixelBufferGetHeight(src)
        let fmt = GestureMath.enhanceDestFormat(osType: CVPixelBufferGetPixelFormatType(src))
        lock.lock()
        if ping == nil || CVPixelBufferGetWidth(ping!) != w || CVPixelBufferGetHeight(ping!) != h
            || CVPixelBufferGetPixelFormatType(ping!) != fmt
        {
            ping = MetalHub.makeBuffer(width: w, height: h, format: fmt)
            pong = MetalHub.makeBuffer(width: w, height: h, format: fmt)
        }
        usePing.toggle()
        let dest = usePing ? ping : pong
        lock.unlock()
        guard let dest else { return nil }
        MetalHub.ci.render(image, to: dest)
        return dest
    }
}

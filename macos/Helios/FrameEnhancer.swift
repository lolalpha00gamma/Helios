import CoreImage
import CoreVideo
import Foundation

/// Belichtung/Kontrast auf der GPU. Geometrie bleibt 1:1 zum Preview.
/// Bei Dunkelheit nicht mehr auf 960 px stauchen — kleine Hände gehen sonst verloren.
final class FrameEnhancer: @unchecked Sendable {
    private var ping: CVPixelBuffer?
    private var pong: CVPixelBuffer?
    private var usePing = true
    private let lock = NSLock()
    private(set) var lastLuma: CGFloat = 0.5
    private(set) var wantsEdgeLight = false

    func luma(of pb: CVPixelBuffer) -> CGFloat {
        let img = CIImage(cvPixelBuffer: pb)
        let extent = img.extent
        guard extent.width > 2, extent.height > 2 else { return 0.5 }
        let sx = min(48 / extent.width, 1)
        let sy = min(36 / extent.height, 1)
        let small = img.transformed(by: CGAffineTransform(scaleX: sx, y: sy))
        guard let filter = CIFilter(name: "CIAreaAverage") else { return 0.5 }
        filter.setValue(small, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: small.extent), forKey: kCIInputExtentKey)
        guard let out = filter.outputImage else { return 0.5 }
        var pixel = [UInt8](repeating: 0, count: 4)
        MetalHub.ci.render(
            out,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .BGRA8,
            colorSpace: nil
        )
        let b = CGFloat(pixel[0])
        let g = CGFloat(pixel[1])
        let r = CGFloat(pixel[2])
        let L = (r + g * 2 + b) / (4 * 255)
        lastLuma = L
        wantsEdgeLight = L < 0.28
        return L
    }

    func enhance(_ pb: CVPixelBuffer, luma: CGFloat) -> CVPixelBuffer {
        lastLuma = luma
        wantsEdgeLight = luma < 0.28
        let scaled = downscale(pb) ?? pb
        guard luma < 0.38 else { return scaled }
        var image = CIImage(cvPixelBuffer: scaled)
        let ev = min(1.85, max(0.18, (0.38 - luma) * 4.4))
        if let f = CIFilter(name: "CIExposureAdjust") {
            f.setValue(image, forKey: kCIInputImageKey)
            f.setValue(ev, forKey: kCIInputEVKey)
            if let o = f.outputImage { image = o }
        }
        if luma < 0.22, let f = CIFilter(name: "CIColorControls") {
            f.setValue(image, forKey: kCIInputImageKey)
            f.setValue(1.12, forKey: kCIInputContrastKey)
            f.setValue(1.06, forKey: kCIInputSaturationKey)
            if let o = f.outputImage { image = o }
        }
        if luma < 0.18, let f = CIFilter(name: "CIHighlightShadowAdjust") {
            f.setValue(image, forKey: kCIInputImageKey)
            f.setValue(0.55, forKey: "inputShadowAmount")
            if let o = f.outputImage { image = o }
        }
        if luma < 0.16, let f = CIFilter(name: "CINoiseReduction") {
            f.setValue(image, forKey: kCIInputImageKey)
            f.setValue(0.04, forKey: "inputNoiseLevel")
            f.setValue(0.6, forKey: "inputSharpness")
            if let o = f.outputImage { image = o }
        }
        return render(image, like: scaled) ?? scaled
    }

    private func downscale(_ pb: CVPixelBuffer) -> CVPixelBuffer? {
        let w = CVPixelBufferGetWidth(pb)
        let h = CVPixelBufferGetHeight(pb)
        let cap = lastLuma < 0.28 ? 1280 : 960
        guard w > cap else { return pb }
        let s = CGFloat(cap) / CGFloat(w)
        let tw = cap
        let th = max(2, Int((CGFloat(h) * s).rounded()))
        lock.lock()
        if ping == nil || CVPixelBufferGetWidth(ping!) != tw || CVPixelBufferGetHeight(ping!) != th {
            ping = MetalHub.makeBuffer(width: tw, height: th)
            pong = MetalHub.makeBuffer(width: tw, height: th)
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
}

import CoreImage
import CoreML
import CoreVideo
import Foundation
import Metal
import Vision

/// Ein Metal-Gerät, eine Command-Queue, ein CIContext — volle GPU, kein Low-Power.
enum MetalHub {
    static let device: MTLDevice? = MTLCreateSystemDefaultDevice()

    static let queue: MTLCommandQueue? = {
        guard let device else { return nil }
        return device.makeCommandQueue()
    }()

    static let ci: CIContext = {
        if let queue {
            let opts: [CIContextOption: Any] = [
                .useSoftwareRenderer: false,
                .cacheIntermediates: false,
                .name: "HeliosGPU",
                .priorityRequestLow: false
            ]
            return CIContext(mtlCommandQueue: queue, options: opts)
        }
        return CIContext(options: [
            .useSoftwareRenderer: false,
            .cacheIntermediates: false,
            .priorityRequestLow: false
        ])
    }()

    static var metalPixelAttrs: [String: Any] {
        [
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:] as CFDictionary,
            kCVPixelBufferCGImageCompatibilityKey as String: true
        ]
    }

    static func makeBuffer(width: Int, height: Int, format: OSType = kCVPixelFormatType_32BGRA) -> CVPixelBuffer? {
        var pb: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, format, metalPixelAttrs as CFDictionary, &pb)
        return pb
    }

    /// GPU-Kopie, damit AVFoundation den Kamera-Buffer wiederverwenden kann.
    static func copy(_ src: CVPixelBuffer, into dst: CVPixelBuffer) {
        let image = CIImage(cvPixelBuffer: src)
        ci.render(image, to: dst)
    }

    static func bindVision(_ request: VNRequest) {
        request.preferBackgroundProcessing = false
        let devices = MLComputeDevice.allComputeDevices
        let ane = devices.first { $0 is MLNeuralEngineComputeDevice }
        let gpu = devices.first { $0 is MLGPUComputeDevice }
        if let ane {
            request.setComputeDevice(ane, for: .main)
        } else if let gpu {
            request.setComputeDevice(gpu, for: .main)
        }
    }
}

/// GPU-Buffer mit In-Flight-Markierung — Vision und Kamera teilen keinen Slot.
final class GPUFrameRing: @unchecked Sendable {
    private var slots: [CVPixelBuffer] = []
    private var busy: [Bool] = []
    private var width = 0
    private var height = 0
    private var pendingW = 0
    private var pendingH = 0
    private let lock = NSLock()

    func copy(_ src: CVPixelBuffer) -> (CVPixelBuffer, Int) {
        let w = CVPixelBufferGetWidth(src)
        let h = CVPixelBufferGetHeight(src)
        lock.lock()
        rebuildIfIdle(width: w, height: h)
        if width != w || height != h {
            pendingW = w
            pendingH = h
            lock.unlock()
            // In-flight slots keep the old size. One-off until release() rebuilds.
            if let dst = MetalHub.makeBuffer(width: w, height: h) {
                MetalHub.copy(src, into: dst)
                return (dst, -1)
            }
            return (src, -1)
        }
        var idx: Int?
        for i in 0..<busy.count where !busy[i] {
            idx = i
            break
        }
        if idx == nil, let extra = MetalHub.makeBuffer(width: w, height: h) {
            slots.append(extra)
            busy.append(false)
            idx = slots.count - 1
        }
        guard let i = idx, i < slots.count else {
            lock.unlock()
            return (src, -1)
        }
        busy[i] = true
        let dst = slots[i]
        lock.unlock()
        MetalHub.copy(src, into: dst)
        return (dst, i)
    }

    func release(_ slot: Int) {
        guard slot >= 0 else { return }
        lock.lock()
        if slot < busy.count { busy[slot] = false }
        if pendingW > 0 {
            rebuildIfIdle(width: pendingW, height: pendingH)
        }
        lock.unlock()
    }

    /// Caller holds `lock`.
    private func rebuildIfIdle(width w: Int, height h: Int) {
        guard w > 0, h > 0 else { return }
        let need = slots.count < 4 || width != w || height != h
        guard need, !busy.contains(true) else { return }
        slots = (0..<8).compactMap { _ in MetalHub.makeBuffer(width: w, height: h) }
        busy = Array(repeating: false, count: slots.count)
        width = w
        height = h
        pendingW = 0
        pendingH = 0
    }
}

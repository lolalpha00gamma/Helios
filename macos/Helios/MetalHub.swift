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

/// Acht GPU-Buffer im Kreis — Vision liest, während die Kamera schreibt.
final class GPUFrameRing: @unchecked Sendable {
    private var slots: [CVPixelBuffer] = []
    private var index = 0
    private var width = 0
    private var height = 0
    private let lock = NSLock()

    func copy(_ src: CVPixelBuffer) -> CVPixelBuffer {
        let w = CVPixelBufferGetWidth(src)
        let h = CVPixelBufferGetHeight(src)
        lock.lock()
        if slots.count != 8 || width != w || height != h {
            slots = (0..<8).compactMap { _ in MetalHub.makeBuffer(width: w, height: h) }
            width = w
            height = h
            index = 0
        }
        guard !slots.isEmpty else {
            lock.unlock()
            return src
        }
        let dst = slots[index]
        index = (index + 1) % slots.count
        lock.unlock()
        MetalHub.copy(src, into: dst)
        return dst
    }
}

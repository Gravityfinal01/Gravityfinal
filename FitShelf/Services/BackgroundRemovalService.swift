import Vision
import UIKit
import CoreImage

actor BackgroundRemovalService {
    static let shared = BackgroundRemovalService()
    private init() {}

    func removeBackground(from original: UIImage) async -> UIImage {
        // Vision works on raw pixels; make them upright first or portrait photos come out sideways.
        let image = original.normalizedUp()
        guard let cgImage = image.cgImage else { return image }
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            guard let result = request.results?.first else { return image }
            let pixelBuffer = try result.generateMaskedImage(
                ofInstances: result.allInstances,
                from: handler,
                croppedToInstancesExtent: false
            )
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            guard let cgOut = context.createCGImage(ciImage, from: ciImage.extent) else {
                return image
            }
            return UIImage(cgImage: cgOut, scale: image.scale, orientation: .up)
        } catch {
            return image
        }
    }
}

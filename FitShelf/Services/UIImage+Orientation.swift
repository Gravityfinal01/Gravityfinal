import UIKit

extension UIImage {
    /// Redraws the image so its pixels are upright and `imageOrientation == .up`.
    /// Camera photos are stored sideways with an orientation flag; anything that reads
    /// `cgImage` directly (Vision, CoreImage) ignores that flag and sees them rotated.
    func normalizedUp() -> UIImage {
        guard imageOrientation != .up else { return self }
        return redraw(size: size) { draw(in: CGRect(origin: .zero, size: size)) }
    }

    /// Rotates 90 degrees clockwise, keeping transparency.
    func rotated90Clockwise() -> UIImage {
        let src = normalizedUp()
        let newSize = CGSize(width: src.size.height, height: src.size.width)
        return redraw(size: newSize) {
            guard let ctx = UIGraphicsGetCurrentContext() else { return }
            ctx.translateBy(x: newSize.width / 2, y: newSize.height / 2)
            ctx.rotate(by: .pi / 2)
            src.draw(in: CGRect(x: -src.size.width / 2, y: -src.size.height / 2,
                                width: src.size.width, height: src.size.height))
        }
    }

    /// Shrinks so the longest side is at most `maxSide` points (never enlarges).
    func downscaled(maxSide: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxSide else { return self }
        let ratio = maxSide / longest
        let newSize = CGSize(width: (size.width * ratio).rounded(), height: (size.height * ratio).rounded())
        return redraw(size: newSize) { draw(in: CGRect(origin: .zero, size: newSize)) }
    }

    private func redraw(size: CGSize, _ body: () -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in body() }
    }
}

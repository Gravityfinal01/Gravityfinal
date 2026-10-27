import UIKit

// On-device helpers that make Apple Vision's classifier work better on clothing cutouts.

extension UIImage {
    /// The cutout cropped to the garment and placed on white, at most 512px.
    /// Vision reads transparent pixels as black and sees a small item in a big frame;
    /// this gives it what it was trained on: an object filling a plain photo.
    func preparedForClassification() -> UIImage {
        let upright = normalizedUp()
        guard let scan = AlphaScan(upright), let box = scan.foregroundRect else {
            return upright.downscaled(maxSide: 512)
        }
        // Pad around the garment so its outline is fully visible.
        let pad = max(box.width, box.height) * 0.08
        let crop = box.insetBy(dx: -pad, dy: -pad).intersection(CGRect(origin: .zero, size: upright.size))
        let side: CGFloat = 512
        let ratio = side / max(crop.width, crop.height)
        let outSize = CGSize(width: (crop.width * ratio).rounded(), height: (crop.height * ratio).rounded())

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: outSize, format: format).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: outSize))
            upright.draw(in: CGRect(x: -crop.minX * ratio, y: -crop.minY * ratio,
                                    width: upright.size.width * ratio, height: upright.size.height * ratio))
        }
    }

    /// Most common colour of the garment, as a plain name ("Black", "Navy", "Beige"...).
    /// Uses only visible pixels of a cutout; for opaque photos, the centre of the frame.
    func dominantColorName() -> String? {
        guard let scan = AlphaScan(normalizedUp()) else { return nil }
        var counts = [Int](repeating: 0, count: NamedColor.palette.count)
        var sampled = 0
        let cx = Double(scan.width) / 2, cy = Double(scan.height) / 2
        for y in 0..<scan.height {
            for x in 0..<scan.width {
                let i = (y * scan.width + x) * 4
                let a = scan.pixels[i + 3]
                if scan.hasTransparency {
                    guard a > 200 else { continue }
                } else {
                    // No cutout: sample the middle 60% where the garment usually is.
                    guard abs(Double(x) - cx) < Double(scan.width) * 0.3,
                          abs(Double(y) - cy) < Double(scan.height) * 0.3 else { continue }
                }
                let r = Double(scan.pixels[i]), g = Double(scan.pixels[i + 1]), b = Double(scan.pixels[i + 2])
                counts[NamedColor.nearest(r, g, b)] += 1
                sampled += 1
            }
        }
        guard sampled > 40, let best = counts.indices.max(by: { counts[$0] < counts[$1] }) else { return nil }
        return NamedColor.palette[best].name
    }
}

/// Small RGBA copy of an image (max 96px) used for fast pixel scans.
private struct AlphaScan {
    let width: Int
    let height: Int
    let pixels: [UInt8]
    let scaleBack: CGFloat
    let hasTransparency: Bool

    init?(_ image: UIImage) {
        guard let cg = image.cgImage else { return nil }
        let maxSide: CGFloat = 96
        let s = min(1, maxSide / max(image.size.width, image.size.height))
        // Locals first: the closure below can't touch `self` before every field is set.
        let w = max(1, Int(image.size.width * s))
        let h = max(1, Int(image.size.height * s))
        var buf = [UInt8](repeating: 0, count: w * h * 4)
        let ok: Bool = buf.withUnsafeMutableBytes { raw in
            guard let ctx = CGContext(data: raw.baseAddress, width: w, height: h, bitsPerComponent: 8,
                                      bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard ok else { return nil }
        // Un-premultiply so colours of semi-transparent edges aren't darkened.
        for i in stride(from: 0, to: buf.count, by: 4) where buf[i + 3] > 0 && buf[i + 3] < 255 {
            let a = Double(buf[i + 3]) / 255
            for c in 0..<3 { buf[i + c] = UInt8(min(255, Double(buf[i + c]) / a)) }
        }
        width = w
        height = h
        scaleBack = 1 / s
        pixels = buf
        hasTransparency = stride(from: 3, to: buf.count, by: 4).contains { buf[$0] < 200 }
    }

    /// Bounding box of non-transparent pixels in the original image's points, or nil if
    /// the image has no transparency (nothing to crop) or is empty.
    var foregroundRect: CGRect? {
        guard hasTransparency else { return nil }
        var minX = width, minY = height, maxX = -1, maxY = -1
        for y in 0..<height {
            for x in 0..<width where pixels[(y * width + x) * 4 + 3] > 24 {
                minX = min(minX, x); maxX = max(maxX, x)
                minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        guard maxX >= minX, maxY >= minY else { return nil }
        // Bitmap memory is stored top row first, matching UIKit's coordinates.
        return CGRect(x: CGFloat(minX) * scaleBack, y: CGFloat(minY) * scaleBack,
                      width: CGFloat(maxX - minX + 1) * scaleBack, height: CGFloat(maxY - minY + 1) * scaleBack)
    }
}

private enum NamedColor {
    static let palette: [(name: String, r: Double, g: Double, b: Double)] = [
        ("Black", 28, 28, 30), ("Charcoal", 64, 66, 72), ("Grey", 140, 140, 145), ("White", 240, 240, 240),
        ("Cream", 238, 228, 205), ("Beige", 210, 188, 152), ("Brown", 110, 72, 45), ("Tan", 180, 140, 95),
        ("Red", 190, 35, 45), ("Burgundy", 110, 25, 40), ("Pink", 235, 150, 180), ("Orange", 230, 125, 45),
        ("Yellow", 235, 205, 60), ("Olive", 110, 110, 55), ("Green", 55, 135, 75), ("Mint", 160, 220, 180),
        ("Teal", 30, 120, 125), ("Light Blue", 145, 185, 230), ("Blue", 45, 95, 195), ("Navy", 30, 40, 78),
        ("Purple", 115, 65, 150), ("Lavender", 185, 165, 225),
    ]

    static func nearest(_ r: Double, _ g: Double, _ b: Double) -> Int {
        var best = 0, bestD = Double.greatestFiniteMagnitude
        for (i, c) in palette.enumerated() {
            // Weighted RGB distance; roughly tracks how different colours look.
            let d = 2 * (r - c.r) * (r - c.r) + 4 * (g - c.g) * (g - c.g) + 3 * (b - c.b) * (b - c.b)
            if d < bestD { bestD = d; best = i }
        }
        return best
    }
}

/// Remembers which Vision labels you filed under which type, so the next similar photo
/// gets it right. Stored on device in UserDefaults; nothing leaves the phone.
enum LearnedLabels {
    private static let key = "learnedVisionLabels"

    /// label -> ("sub:<raw>" or "cat:<raw>") -> times chosen
    static var table: [String: [String: Int]] {
        UserDefaults.standard.dictionary(forKey: key) as? [String: [String: Int]] ?? [:]
    }

    static func normalize(_ label: String) -> String {
        label.lowercased().replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ")
    }

    static func learn(labels: [String], category: ClothingCategory, subcategory: ClothingSubcategory?) {
        guard category != .other, !labels.isEmpty else { return }
        var t = table
        let target = subcategory.map { "sub:\($0.rawValue)" } ?? "cat:\(category.rawValue)"
        for label in labels.prefix(6) {
            let l = normalize(label)
            var row = t[l] ?? [:]
            row[target, default: 0] += 1
            t[l] = row
        }
        // Keep the table small.
        if t.count > 600 { t = Dictionary(uniqueKeysWithValues: t.sorted { $0.value.values.reduce(0, +) > $1.value.values.reduce(0, +) }.prefix(400).map { ($0.key, $0.value) }) }
        UserDefaults.standard.set(t, forKey: key)
    }
}

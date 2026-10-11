import UIKit

/// Loads full-size item images and outfit snapshots from disk / Photos.
/// Prefers the local PNG because it keeps the transparent background from
/// background removal; Photos re-encodes and flattens it.
enum ClothingImageLoader {
    static var imagesDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("images")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func load(_ item: ClothingItem, targetSize: CGSize = CGSize(width: 1400, height: 1400)) async -> UIImage? {
        let url = imagesDirectory.appendingPathComponent(item.localImagePath)
        if let local = await loadFile(url) { return local }

        if let photosId = item.photosAssetIdentifier {
            return await PhotoLibraryService.shared.loadImage(identifier: photosId, targetSize: targetSize)
        }
        return nil
    }

    static func loadSnapshot(_ outfit: Outfit) async -> UIImage? {
        guard let path = outfit.snapshotPath else { return nil }
        return await loadFile(imagesDirectory.appendingPathComponent(path))
    }

    static func deleteSnapshot(_ outfit: Outfit) {
        guard let path = outfit.snapshotPath else { return }
        try? FileManager.default.removeItem(at: imagesDirectory.appendingPathComponent(path))
    }

    private static func loadFile(_ url: URL) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            guard let data = try? Data(contentsOf: url) else { return UIImage?.none }
            return UIImage(data: data)
        }.value
    }
}

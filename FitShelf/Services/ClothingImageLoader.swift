import UIKit

/// Reads and writes item images and outfit snapshots.
///
/// Each image lives in two places:
///   - `Documents/images/<file>.png`, a fast local cache;
///   - `ClothingItem.imageData` / `Outfit.snapshotData`, stored by SwiftData as an external
///     asset. That copy is what iCloud (CloudKit) syncs, so a second device or a reinstall
///     gets the pictures back, not just the names.
/// Loading prefers the local file, falls back to the synced data (re-creating the file),
/// then to the optional Photos copy.
enum ClothingImageLoader {
    /// Longest side of stored cutouts, in pixels. Keeps sync and storage light.
    static let maxStoredSide: CGFloat = 1600

    static var imagesDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("images")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Items

    @MainActor
    static func load(_ item: ClothingItem, targetSize: CGSize = CGSize(width: 1400, height: 1400)) async -> UIImage? {
        let url = imagesDirectory.appendingPathComponent(item.localImagePath)
        if let local = await loadFile(url) { return local }

        if let data = item.imageData, let image = UIImage(data: data) {
            try? data.write(to: url)  // restore the local cache on this device
            return image
        }

        if let photosId = item.photosAssetIdentifier {
            return await PhotoLibraryService.shared.loadImage(identifier: photosId, targetSize: targetSize)
        }
        return nil
    }

    /// Upright, size-capped PNG bytes for storage.
    static func pngForStorage(_ image: UIImage) -> Data? {
        image.normalizedUp().downscaled(maxSide: maxStoredSide / max(image.scale, 1)).pngData()
    }

    /// Replaces an item's picture. Uses a new filename so every cached view reloads.
    @MainActor
    static func replaceImage(of item: ClothingItem, with image: UIImage) -> Bool {
        guard let data = pngForStorage(image) else { return false }
        let newName = "\(item.id.uuidString)_\(Int(Date().timeIntervalSince1970)).png"
        guard (try? data.write(to: imagesDirectory.appendingPathComponent(newName))) != nil else { return false }
        if !item.localImagePath.isEmpty {
            try? FileManager.default.removeItem(at: imagesDirectory.appendingPathComponent(item.localImagePath))
        }
        item.localImagePath = newName
        item.imageData = data
        return true
    }

    /// Copies the local file into `imageData` for items saved before images were synced.
    @MainActor
    static func backfillSyncedData(_ items: [ClothingItem]) -> Bool {
        var changed = false
        for item in items where item.imageData == nil && !item.localImagePath.isEmpty {
            let url = imagesDirectory.appendingPathComponent(item.localImagePath)
            if let data = try? Data(contentsOf: url) {
                item.imageData = data
                changed = true
            }
        }
        return changed
    }

    // MARK: - Outfit snapshots

    @MainActor
    static func loadSnapshot(_ outfit: Outfit) async -> UIImage? {
        if let path = outfit.snapshotPath {
            let url = imagesDirectory.appendingPathComponent(path)
            if let local = await loadFile(url) { return local }
            if let data = outfit.snapshotData, let image = UIImage(data: data) {
                try? data.write(to: url)
                return image
            }
        }
        return outfit.snapshotData.flatMap(UIImage.init(data:))
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

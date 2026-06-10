import Foundation
import Photos
import UIKit

// Saves clothing photos to the iOS Photos Library.
// Photos sync automatically via iCloud Photos — no server required.
class PhotoLibraryService {
    static let shared = PhotoLibraryService()

    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    }

    /// Saves the image to the Photos Library and returns the new asset's localIdentifier.
    func save(_ image: UIImage) async throws -> String {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw PhotoLibraryError.notAuthorized
        }

        var assetIdentifier: String?
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            assetIdentifier = request.placeholderForCreatedAsset?.localIdentifier
        }

        guard let identifier = assetIdentifier else {
            throw PhotoLibraryError.saveFailed
        }
        return identifier
    }

    /// Fetches a UIImage for a previously saved PHAsset.
    func loadImage(identifier: String, targetSize: CGSize = PHImageManagerMaximumSize) async -> UIImage? {
        let options = PHFetchOptions()
        let results = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: options)
        guard let asset = results.firstObject else { return nil }

        return await withCheckedContinuation { continuation in
            let requestOptions = PHImageRequestOptions()
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.isNetworkAccessAllowed = true
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: requestOptions
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    func deleteAsset(identifier: String) async throws {
        let results = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard results.count > 0 else { return }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(results)
        }
    }
}

enum PhotoLibraryError: LocalizedError {
    case notAuthorized
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized: return "Photo Library access not granted. Enable in Settings."
        case .saveFailed: return "Failed to save photo to library."
        }
    }
}

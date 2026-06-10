import SwiftData
import Foundation

enum SyncStatus: String, Codable {
    case local      // not yet synced to any remote
    case syncing
    case synced
    case failed
}

@Model
class ClothingItem {
    var id: UUID
    var name: String
    // Stored as rawValue strings for reliable SwiftData predicate support
    var categoryRaw: String
    var color: String?
    var brand: String?
    var tags: [String]
    var localImagePath: String          // filename inside Documents/images/
    var photosAssetIdentifier: String?  // PHAsset.localIdentifier when saved to Photos Library
    var immichAssetId: String?
    var immichAlbumId: String?
    var syncStatusRaw: String
    var deletedLocally: Bool
    var dateAdded: Date

    init(
        id: UUID = UUID(),
        name: String,
        category: ClothingCategory,
        color: String? = nil,
        brand: String? = nil,
        tags: [String] = [],
        localImagePath: String,
        photosAssetIdentifier: String? = nil,
        immichAssetId: String? = nil,
        immichAlbumId: String? = nil,
        syncStatus: SyncStatus = .local,
        deletedLocally: Bool = false,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = category.rawValue
        self.color = color
        self.brand = brand
        self.tags = tags
        self.localImagePath = localImagePath
        self.photosAssetIdentifier = photosAssetIdentifier
        self.immichAssetId = immichAssetId
        self.immichAlbumId = immichAlbumId
        self.syncStatusRaw = syncStatus.rawValue
        self.deletedLocally = deletedLocally
        self.dateAdded = dateAdded
    }

    var category: ClothingCategory {
        get { ClothingCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .local }
        set { syncStatusRaw = newValue.rawValue }
    }
}

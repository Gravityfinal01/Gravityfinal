import SwiftData
import Foundation

enum SyncStatus: String, Codable {
    case local      // not yet synced to any remote
    case syncing
    case synced
    case failed
}

// CloudKit-backed SwiftData requires every stored property to be optional or
// have a default, and every relationship to be optional. Keep it that way.
@Model
class ClothingItem {
    var id: UUID = UUID()
    var name: String = ""
    // Stored as rawValue strings for reliable SwiftData predicate support
    var categoryRaw: String = ClothingCategory.other.rawValue
    var subcategoryRaw: String?
    var color: String?
    var brand: String?
    var tags: [String] = []
    var localImagePath: String = ""      // filename inside Documents/images/
    var photosAssetIdentifier: String?   // PHAsset.localIdentifier when a copy was saved to Photos
    var immichAssetId: String?
    var immichAlbumId: String?
    var syncStatusRaw: String = SyncStatus.local.rawValue
    var deletedLocally: Bool = false
    var dateAdded: Date = Date()

    /// Inverse of Outfit.items. Maintained by SwiftData.
    var outfits: [Outfit]?

    init(
        id: UUID = UUID(),
        name: String,
        category: ClothingCategory,
        subcategory: ClothingSubcategory? = nil,
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
        self.subcategoryRaw = subcategory?.rawValue
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
        // fromLegacy also handles current raw values, so old and new rows both resolve.
        get { ClothingCategory.fromLegacy(categoryRaw).category }
        set { categoryRaw = newValue.rawValue }
    }

    var subcategory: ClothingSubcategory? {
        get {
            if let raw = subcategoryRaw, let sub = ClothingSubcategory(rawValue: raw) { return sub }
            return ClothingCategory.fromLegacy(categoryRaw).subcategory
        }
        set { subcategoryRaw = newValue?.rawValue }
    }

    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .local }
        set { syncStatusRaw = newValue.rawValue }
    }
}

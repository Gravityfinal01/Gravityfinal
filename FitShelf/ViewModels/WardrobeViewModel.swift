import SwiftUI
import SwiftData

enum SyncState: Equatable {
    case idle, syncing, error(String)
}

@MainActor
class WardrobeViewModel: ObservableObject {
    @Published var syncState: SyncState = .idle
    @Published var pendingSyncCount = 0

    private var immichService: ImmichService?
    private var networkMonitor: NetworkMonitor?
    private var modelContext: ModelContext?

    func setup(immichService: ImmichService, networkMonitor: NetworkMonitor, context: ModelContext) {
        self.immichService = immichService
        self.networkMonitor = networkMonitor
        self.modelContext = context
        migrateLegacyCategories()
        updatePendingCount()
    }

    /// One-time rewrite of rows saved under the old flat category scheme ("shirt", "hoodie", …)
    /// so they show up under the new Tops/Sweaters/etc. filters. No-op once everything is migrated.
    private func migrateLegacyCategories() {
        guard let context = modelContext else { return }
        let all = (try? context.fetch(FetchDescriptor<ClothingItem>())) ?? []
        var changed = false
        for item in all where ClothingCategory(rawValue: item.categoryRaw) == nil {
            let mapped = ClothingCategory.fromLegacy(item.categoryRaw)
            item.categoryRaw = mapped.category.rawValue
            if item.subcategoryRaw == nil, let sub = mapped.subcategory {
                item.subcategoryRaw = sub.rawValue
            }
            changed = true
        }
        if changed { try? context.save() }
    }

    func updatePendingCount() {
        guard let context = modelContext else { return }
        let all = (try? context.fetch(FetchDescriptor<ClothingItem>())) ?? []
        pendingSyncCount = all.filter {
            $0.syncStatusRaw == SyncStatus.local.rawValue && !$0.deletedLocally
        }.count
    }

    func syncPendingItems() async {
        guard let context = modelContext,
              let immich = immichService,
              let monitor = networkMonitor,
              monitor.isOnLocalNetwork else { return }

        guard StorageBackend.current.requiresImmich else { return }

        syncState = .syncing

        let all = (try? context.fetch(FetchDescriptor<ClothingItem>())) ?? []
        let pending = all.filter {
            $0.syncStatusRaw == SyncStatus.local.rawValue && !$0.deletedLocally
        }

        for item in pending {
            do {
                let imagesDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("images")
                let imageURL = imagesDir.appendingPathComponent(item.localImagePath)
                guard let imageData = try? Data(contentsOf: imageURL) else { continue }

                let assetId = try await immich.uploadAsset(
                    imageData: imageData, itemId: item.id, filename: item.localImagePath)
                let albumId = try await immich.ensureAlbum(named: item.category.immichAlbumName)
                try await immich.addAsset(assetId, toAlbum: albumId)

                item.immichAssetId = assetId
                item.immichAlbumId = albumId
                item.syncStatus = .synced
                try? context.save()
            } catch {
                item.syncStatus = .failed
                try? context.save()
            }
        }

        syncState = .idle
        updatePendingCount()
        immichService?.lastSyncDate = Date()
    }

    func deleteItem(_ item: ClothingItem, context: ModelContext) async {
        // Remove from Photos Library if applicable
        if let photosId = item.photosAssetIdentifier {
            try? await PhotoLibraryService.shared.deleteAsset(identifier: photosId)
        }

        // Remove from Immich if applicable
        if let assetId = item.immichAssetId {
            try? await immichService?.deleteAsset(assetId)
        }

        // Remove local image file
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("images")
            .appendingPathComponent(item.localImagePath)
        try? FileManager.default.removeItem(at: url)

        context.delete(item)
        try? context.save()
        updatePendingCount()
    }
}

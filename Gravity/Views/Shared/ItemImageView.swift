import SwiftUI
import Photos

/// Shows a clothing item's photo. Prefers Photos Library, falls back to local file, then Immich.
struct ItemImageView: View {
    let item: ClothingItem
    var size: CGSize = CGSize(width: 200, height: 250)

    @EnvironmentObject private var immichService: ImmichService
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @State private var localImage: UIImage?
    @State private var photosImage: UIImage?

    var body: some View {
        ZStack {
            if let img = photosImage ?? localImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let assetId = item.immichAssetId,
                      networkMonitor.isOnLocalNetwork,
                      let url = immichService.thumbnailURL(assetId: assetId) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderIcon
                    default:
                        ProgressView()
                    }
                }
            } else {
                placeholderIcon
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .task(id: item.id) {
            await loadImages()
        }
    }

    private var placeholderIcon: some View {
        Image(systemName: item.category.systemImage)
            .font(.system(size: 40))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGray6))
    }

    private func loadImages() async {
        // Try Photos Library first (fastest for local network, works offline)
        if let photosId = item.photosAssetIdentifier {
            let img = await PhotoLibraryService.shared.loadImage(
                identifier: photosId,
                targetSize: CGSize(width: size.width * 2, height: size.height * 2)
            )
            await MainActor.run { photosImage = img }
            if img != nil { return }
        }

        // Fall back to local Documents file
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("images")
            .appendingPathComponent(item.localImagePath)
        let img = await Task.detached(priority: .userInitiated) {
            guard let data = try? Data(contentsOf: url) else { return UIImage?.none }
            return UIImage(data: data)
        }.value
        await MainActor.run { localImage = img }
    }
}

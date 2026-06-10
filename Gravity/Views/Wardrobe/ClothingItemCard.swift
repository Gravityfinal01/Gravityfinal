import SwiftUI

struct ClothingItemCard: View {
    let item: ClothingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ItemImageView(item: item, size: CGSize(width: 180, height: 200))
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let color = item.color {
                        Text(color)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let brand = item.brand {
                        Text("· \(brand)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                syncBadge
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private var syncBadge: some View {
        switch item.syncStatus {
        case .local:
            Label("Not synced", systemImage: "icloud.slash")
                .font(.caption2)
                .foregroundStyle(.orange)
        case .syncing:
            Label("Syncing…", systemImage: "arrow.triangle.2.circlepath")
                .font(.caption2)
                .foregroundStyle(.blue)
        case .synced:
            EmptyView()
        case .failed:
            Label("Sync failed", systemImage: "exclamationmark.icloud")
                .font(.caption2)
                .foregroundStyle(.red)
        }
    }
}

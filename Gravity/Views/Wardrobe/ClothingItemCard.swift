import SwiftUI

struct ClothingItemCard: View {
    let item: ClothingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                CheckerboardTile()

                ItemImageView(item: item, size: CGSize(width: 180, height: 200))
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)

                Label(item.category.displayName, systemImage: item.category.systemImage)
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(8)
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let color = item.color {
                        Text(color.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let brand = item.brand {
                        Text(item.color != nil ? "\u{00b7} \(brand)" : brand)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                syncBadge
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
    }

    @ViewBuilder
    private var syncBadge: some View {
        switch item.syncStatus {
        case .local:
            Image(systemName: "icloud.slash")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .syncing:
            Label("Syncing\u{2026}", systemImage: "arrow.triangle.2.circlepath")
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

private struct CheckerboardTile: View {
    var body: some View {
        Canvas { ctx, size in
            let tile: CGFloat = 14
            var x: CGFloat = 0
            while x < size.width {
                var y: CGFloat = 0
                while y < size.height {
                    let isEven = (Int(x / tile) + Int(y / tile)) % 2 == 0
                    ctx.fill(
                        Path(CGRect(x: x, y: y, width: tile, height: tile)),
                        with: .color(isEven ? Color(.systemGray6) : Color(.systemGray5))
                    )
                    y += tile
                }
                x += tile
            }
        }
    }
}

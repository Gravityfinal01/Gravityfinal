import SwiftUI
import SwiftData

/// Browser for saved outfits. Tapping one loads it back onto the canvas.
struct SavedOutfitsView: View {
    let onSelect: (Outfit) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Outfit.lastModified, order: .reverse) private var outfits: [Outfit]
    @State private var outfitToDelete: Outfit?

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            Group {
                if outfits.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(outfits) { outfit in
                                Button {
                                    onSelect(outfit)
                                    dismiss()
                                } label: {
                                    OutfitCard(outfit: outfit)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        outfitToDelete = outfit
                                    } label: {
                                        Label("Delete Outfit", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(14)
                    }
                }
            }
            .navigationTitle("Saved Outfits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Delete this outfit?", isPresented: .init(
                get: { outfitToDelete != nil },
                set: { if !$0 { outfitToDelete = nil } }
            ), titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let outfit = outfitToDelete { delete(outfit) }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No saved outfits yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Build one on the canvas and tap Save Outfit.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func delete(_ outfit: Outfit) {
        ClothingImageLoader.deleteSnapshot(outfit)
        modelContext.delete(outfit)
        try? modelContext.save()
        outfitToDelete = nil
    }
}

private struct OutfitCard: View {
    let outfit: Outfit
    @State private var snapshot: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Color(.systemGray6)
                if let snapshot {
                    Image(uiImage: snapshot)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "square.3.layers.3d")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(height: 190)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(outfit.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            let count = outfit.items?.count ?? 0
            Text("\(count) item\(count == 1 ? "" : "s") \u{00b7} \(outfit.lastModified.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .task(id: outfit.snapshotPath) {
            snapshot = await ClothingImageLoader.loadSnapshot(outfit)
        }
    }
}

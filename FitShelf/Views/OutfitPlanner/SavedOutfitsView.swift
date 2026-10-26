import SwiftUI
import SwiftData

/// Gallery of saved outfits. Tap one to open it; share, edit on the canvas, rename or delete.
struct SavedOutfitsView: View {
    /// Loads an outfit back onto the canvas.
    let onSelect: (Outfit) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Query(sort: \Outfit.lastModified, order: .reverse) private var outfits: [Outfit]

    @State private var outfitToDelete: Outfit?
    @State private var outfitToShare: Outfit?
    @State private var outfitToRename: Outfit?
    @State private var renameText = ""

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 14), count: sizeClass == .regular ? 4 : 2)
    }

    var body: some View {
        NavigationStack {
            Group {
                if outfits.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 18) {
                            ForEach(outfits) { outfit in
                                NavigationLink(value: outfit) {
                                    OutfitCard(outfit: outfit)
                                }
                                .buttonStyle(.plain)
                                .contextMenu { menu(for: outfit) }
                            }
                        }
                        .padding(14)
                    }
                }
            }
            .navigationTitle("Outfits")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Outfit.self) { outfit in
                OutfitDetailView(
                    outfit: outfit,
                    onEdit: { edit(outfit) },
                    onShare: { outfitToShare = outfit },
                    onRename: { startRename(outfit) },
                    onDelete: { outfitToDelete = outfit }
                )
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $outfitToShare) { outfit in
                ShareOutfitSheet(name: outfit.name) {
                    await OutfitSnapshotRenderer.snapshot(for: outfit)
                }
            }
            .alert("Rename Outfit", isPresented: .init(
                get: { outfitToRename != nil },
                set: { if !$0 { outfitToRename = nil } }
            )) {
                TextField("Outfit name", text: $renameText)
                Button("Save") { commitRename() }
                Button("Cancel", role: .cancel) { outfitToRename = nil }
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

    @ViewBuilder
    private func menu(for outfit: Outfit) -> some View {
        Button { outfitToShare = outfit } label: { Label("Share", systemImage: "square.and.arrow.up") }
        Button { edit(outfit) } label: { Label("Edit on Canvas", systemImage: "hand.draw") }
        Button { startRename(outfit) } label: { Label("Rename", systemImage: "pencil") }
        Divider()
        Button(role: .destructive) { outfitToDelete = outfit } label: { Label("Delete", systemImage: "trash") }
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

    private func edit(_ outfit: Outfit) {
        onSelect(outfit)
        dismiss()
    }

    private func startRename(_ outfit: Outfit) {
        renameText = outfit.name
        outfitToRename = outfit
    }

    private func commitRename() {
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let outfit = outfitToRename, !trimmed.isEmpty {
            outfit.name = trimmed
            outfit.lastModified = Date()
            try? modelContext.save()
        }
        outfitToRename = nil
    }

    private func delete(_ outfit: Outfit) {
        ClothingImageLoader.deleteSnapshot(outfit)
        modelContext.delete(outfit)
        try? modelContext.save()
        outfitToDelete = nil
    }
}

// MARK: - Grid card

private struct OutfitCard: View {
    let outfit: Outfit
    @State private var snapshot: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Checkerboard(tile: 12)
                if let snapshot {
                    Image(uiImage: snapshot)
                        .resizable()
                        .scaledToFit()
                        .padding(6)
                } else {
                    Image(systemName: "square.3.layers.3d")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                }
            }
            .aspectRatio(0.8, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 3)

            Text(outfit.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            let count = outfit.items?.count ?? 0
            Text("\(count) piece\(count == 1 ? "" : "s") \u{00b7} \(outfit.lastModified.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .task(id: outfit.snapshotPath) {
            snapshot = await OutfitSnapshotRenderer.snapshot(for: outfit)
        }
    }
}

// MARK: - Detail

private struct OutfitDetailView: View {
    let outfit: Outfit
    let onEdit: () -> Void
    let onShare: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    @State private var snapshot: UIImage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ZStack {
                    Checkerboard(tile: 16)
                    if let snapshot {
                        Image(uiImage: snapshot)
                            .resizable()
                            .scaledToFit()
                            .padding(10)
                    } else {
                        ProgressView()
                    }
                }
                .aspectRatio(0.8, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(outfit.name).font(.title2.bold())
                    Text("Saved \(outfit.lastModified.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    Button(action: onShare) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: onEdit) {
                        Label("Edit on Canvas", systemImage: "hand.draw")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                }

                let items = outfit.items ?? []
                if !items.isEmpty {
                    Text("Pieces")
                        .font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(items) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    ItemImageView(item: item, size: CGSize(width: 84, height: 100))
                                        .background(Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    Text(item.name)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .frame(width: 84, alignment: .leading)
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: onRename) { Label("Rename", systemImage: "pencil") }
                    Button(role: .destructive, action: onDelete) { Label("Delete", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task(id: outfit.snapshotPath) {
            snapshot = await OutfitSnapshotRenderer.snapshot(for: outfit)
        }
    }
}

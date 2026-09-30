import SwiftUI
import SwiftData

/// Full-size viewer for a single item, reached by tapping it in the wardrobe.
struct ClothingDetailView: View {
    let item: ClothingItem
    let wardrobeVM: WardrobeViewModel

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var showEdit = false
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    Checkerboard(tile: 18)
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                    } else {
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 430)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 12) {
                    Text(item.name)
                        .font(.title2.bold())

                    HStack(spacing: 8) {
                        infoPill(item.subcategory?.singularName ?? item.category.singularName,
                                 systemImage: item.category.systemImage,
                                 tint: .accentColor)
                        if let color = item.color, !color.isEmpty {
                            infoPill(color.capitalized, systemImage: "paintpalette", tint: .secondary)
                        }
                        if let brand = item.brand, !brand.isEmpty {
                            infoPill(brand, systemImage: "tag", tint: .secondary)
                        }
                    }

                    if !item.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(item.tags.prefix(12), id: \.self) { tag in
                                    Text(tag.replacingOccurrences(of: "_", with: " "))
                                        .font(.caption)
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 4)
                                        .background(Color(.systemGray6))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    Text("Added \(item.dateAdded.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 12)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 14) {
                    Button("Edit") { showEdit = true }
                    Menu {
                        Button(role: .destructive) { confirmDelete = true } label: {
                            Label("Delete Item", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            EditClothingView(item: item)
        }
        .confirmationDialog("Delete this item?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                // Leave the screen before the model is removed so nothing renders a deleted row.
                dismiss()
                Task { await wardrobeVM.deleteItem(item, context: modelContext) }
            }
        }
        .task(id: item.id) {
            image = await ClothingImageLoader.load(item)
        }
    }

    private func infoPill(_ text: String, systemImage: String, tint: Color) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tint.opacity(0.12))
            .foregroundStyle(tint)
            .clipShape(Capsule())
    }
}

import SwiftUI
import SwiftData

/// Sheet for editing an existing item. Works on local copies so Cancel discards cleanly.
struct EditClothingView: View {
    let item: ClothingItem

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var category: ClothingCategory
    @State private var subcategory: ClothingSubcategory?
    @State private var brand: String
    @State private var color: String
    /// Loaded photo and how many quarter turns the user has applied (0...3).
    @State private var photo: UIImage?
    @State private var quarterTurns = 0

    init(item: ClothingItem) {
        self.item = item
        _name = State(initialValue: item.name)
        _category = State(initialValue: item.category)
        _subcategory = State(initialValue: item.subcategory)
        _brand = State(initialValue: item.brand ?? "")
        _color = State(initialValue: item.color ?? "")
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ZStack(alignment: .bottomTrailing) {
                        Checkerboard(tile: 16)
                        if let photo {
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFit()
                                .padding(12)
                                .rotationEffect(.degrees(Double(quarterTurns) * 90))
                        } else {
                            ProgressView()
                        }
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { quarterTurns = (quarterTurns + 1) % 4 }
                        } label: {
                            Label("Rotate", systemImage: "rotate.right")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .padding(10)
                        .disabled(photo == nil)
                    }
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .listRowInsets(EdgeInsets())
                }

                Section("Name") {
                    TextField("e.g. Blue Denim Jacket", text: $name)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(ClothingCategory.allCases) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                    if category.hasSubcategories {
                        SubcategoryChips(category: category, selection: $subcategory)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 0))
                    }
                }

                Section("Details") {
                    TextField("Brand", text: $brand)
                    TextField("Color", text: $color)
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(trimmedName.isEmpty)
                }
            }
            .onChange(of: category) { _, newCategory in
                if let sub = subcategory, sub.parent != newCategory { subcategory = nil }
            }
            .task { photo = await ClothingImageLoader.load(item) }
        }
    }

    private func save() {
        if category != item.category || subcategory != item.subcategory {
            LearnedLabels.learn(labels: item.tags, category: category, subcategory: subcategory)
        }
        item.name = trimmedName
        item.category = category
        item.subcategory = subcategory
        item.brand = brand.trimmingCharacters(in: .whitespaces).isEmpty ? nil : brand.trimmingCharacters(in: .whitespaces)
        item.color = color.trimmingCharacters(in: .whitespaces).isEmpty ? nil : color.trimmingCharacters(in: .whitespaces)
        if quarterTurns > 0, var rotated = photo {
            for _ in 0..<quarterTurns { rotated = rotated.rotated90Clockwise() }
            _ = ClothingImageLoader.replaceImage(of: item, with: rotated)
        }
        try? modelContext.save()
        dismiss()
    }
}

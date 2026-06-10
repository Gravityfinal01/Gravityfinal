import SwiftUI
import SwiftData

struct ClothingGridView: View {
    let category: ClothingCategory?
    let searchText: String
    let vm: WardrobeViewModel

    @Query private var items: [ClothingItem]
    @Environment(\.modelContext) private var modelContext
    @State private var itemToDelete: ClothingItem?

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    init(category: ClothingCategory?, searchText: String, vm: WardrobeViewModel) {
        self.category = category
        self.searchText = searchText
        self.vm = vm

        if let cat = category {
            let rawValue = cat.rawValue
            _items = Query(
                filter: #Predicate<ClothingItem> { $0.categoryRaw == rawValue && $0.deletedLocally == false },
                sort: \ClothingItem.dateAdded,
                order: .reverse
            )
        } else {
            _items = Query(
                filter: #Predicate<ClothingItem> { $0.deletedLocally == false },
                sort: \ClothingItem.dateAdded,
                order: .reverse
            )
        }
    }

    private var displayedItems: [ClothingItem] {
        guard !searchText.isEmpty else { return items }
        return items.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.brand?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }

    var body: some View {
        Group {
            if displayedItems.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(displayedItems) { item in
                            ClothingItemCard(item: item)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        itemToDelete = item
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(12)
                }
            }
        }
        .confirmationDialog("Delete this item?", isPresented: .init(
            get: { itemToDelete != nil },
            set: { if !$0 { itemToDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    Task { await vm.deleteItem(item, context: modelContext) }
                    itemToDelete = nil
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tshirt")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text(category == nil ? "Your wardrobe is empty" : "No \(category!.displayName.lowercased()) yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Tap the + tab to add your first item.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
}

import SwiftUI
import SwiftData

struct ClothingGridView: View {
    let category: ClothingCategory?
    let subcategory: ClothingSubcategory?
    let searchText: String
    let vm: WardrobeViewModel

    @AppStorage(WardrobeLayout.storageKey) private var layoutRaw = WardrobeLayout.detailed.rawValue
    @Query private var items: [ClothingItem]
    @Environment(\.modelContext) private var modelContext
    @State private var itemToDelete: ClothingItem?
    @State private var itemToEdit: ClothingItem?

    init(category: ClothingCategory?, subcategory: ClothingSubcategory? = nil, searchText: String, vm: WardrobeViewModel) {
        self.category = category
        self.subcategory = subcategory
        self.searchText = searchText
        self.vm = vm

        if let sub = subcategory {
            let subRaw = sub.rawValue
            _items = Query(
                filter: #Predicate<ClothingItem> { $0.subcategoryRaw == subRaw && $0.deletedLocally == false },
                sort: \ClothingItem.dateAdded,
                order: .reverse
            )
        } else if let cat = category {
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

    private var layout: WardrobeLayout { WardrobeLayout(rawValue: layoutRaw) ?? .detailed }

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
                switch layout {
                case .list:
                    listLayout
                case .compact:
                    gridLayout(columns: 3, spacing: 8) { compactCell($0) }
                case .detailed:
                    gridLayout(columns: 2, spacing: 12) { ClothingItemCard(item: $0) }
                }
            }
        }
        .navigationDestination(for: ClothingItem.self) { item in
            ClothingDetailView(item: item, wardrobeVM: vm)
        }
        .sheet(item: $itemToEdit) { item in
            EditClothingView(item: item)
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

    // MARK: - Layouts

    private func gridLayout<Cell: View>(
        columns: Int,
        spacing: CGFloat,
        @ViewBuilder cell: @escaping (ClothingItem) -> Cell
    ) -> some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
                spacing: spacing
            ) {
                ForEach(displayedItems) { item in
                    NavigationLink(value: item) {
                        cell(item)
                    }
                    .buttonStyle(.plain)
                    .contextMenu { itemMenu(item) }
                }
            }
            .padding(spacing + 4)
        }
    }

    private var listLayout: some View {
        List {
            ForEach(displayedItems) { item in
                NavigationLink(value: item) {
                    listRow(item)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        itemToDelete = item
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button {
                        itemToEdit = item
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
                .contextMenu { itemMenu(item) }
            }
        }
        .listStyle(.plain)
    }

    private func listRow(_ item: ClothingItem) -> some View {
        HStack(spacing: 12) {
            ItemImageView(item: item, size: CGSize(width: 56, height: 56))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: item.category.systemImage)
                        .font(.caption2)
                    Text(item.subcategory?.singularName ?? item.category.singularName)
                    if let brand = item.brand, !brand.isEmpty {
                        Text("\u{00b7} \(brand)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private func compactCell(_ item: ClothingItem) -> some View {
        ItemImageView(item: item, size: CGSize(width: 115, height: 140))
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func itemMenu(_ item: ClothingItem) -> some View {
        Button {
            itemToEdit = item
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        Button(role: .destructive) {
            itemToDelete = item
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Empty state

    private var emptyTitle: String {
        if let sub = subcategory { return "No \(sub.displayName.lowercased()) yet" }
        if let cat = category { return "No \(cat.displayName.lowercased()) yet" }
        return "Your wardrobe is empty"
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tshirt")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text(emptyTitle)
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

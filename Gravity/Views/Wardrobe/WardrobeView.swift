import SwiftUI
import SwiftData

struct WardrobeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var immichService: ImmichService
    @EnvironmentObject private var networkMonitor: NetworkMonitor

    @StateObject private var vm = WardrobeViewModel()
    @State private var selectedCategory: ClothingCategory?
    @State private var selectedSubcategory: ClothingSubcategory?
    @State private var searchText = ""
    @State private var showSyncSheet = false
    @State private var syncRotation: Double = 0
    @AppStorage("storageBackend") private var storageBackendRaw = StorageBackend.local.rawValue

    /// Sync UI only makes sense when an Immich server is part of the storage setup.
    private var syncEnabled: Bool {
        (StorageBackend(rawValue: storageBackendRaw) ?? .local).requiresImmich
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryPills
                if let cat = selectedCategory, cat.hasSubcategories {
                    subcategoryPills(for: cat)
                }
                ClothingGridView(
                    category: selectedCategory,
                    subcategory: selectedSubcategory,
                    searchText: searchText,
                    vm: vm
                )
            }
            .navigationTitle("Wardrobe")
            .searchable(text: $searchText, prompt: "Search clothes…")
            .toolbar {
                if syncEnabled {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        syncButton
                    }
                }
            }
            .task {
                vm.setup(
                    immichService: immichService,
                    networkMonitor: networkMonitor,
                    context: modelContext
                )
            }
            .onChange(of: networkMonitor.isOnLocalNetwork) { _, isLocal in
                if isLocal {
                    Task { await vm.syncPendingItems() }
                }
            }
            .onChange(of: vm.syncState == .syncing) { _, syncing in
                if syncing {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        syncRotation = 360
                    }
                } else {
                    withAnimation(.default) {
                        syncRotation = 0
                    }
                }
            }
        }
    }

    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                pill(label: "All", category: nil)
                ForEach(ClothingCategory.allCases) { cat in
                    pill(label: cat.displayName, category: cat)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func subcategoryPills(for category: ClothingCategory) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                subPill(label: "All", subcategory: nil)
                ForEach(category.subcategories) { sub in
                    subPill(label: sub.displayName, subcategory: sub)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }

    private func subPill(label: String, subcategory: ClothingSubcategory?) -> some View {
        let selected = selectedSubcategory == subcategory
        return Button {
            selectedSubcategory = subcategory
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(selected ? Color.accentColor.opacity(0.18) : Color(.systemGray6))
                .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func pill(label: String, category: ClothingCategory?) -> some View {
        Button {
            selectedCategory = category
            selectedSubcategory = nil
        } label: {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(selectedCategory == category ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(selectedCategory == category ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var syncButton: some View {
        Button {
            showSyncSheet = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .rotationEffect(.degrees(syncRotation))
                if vm.pendingSyncCount > 0 {
                    Text("\(vm.pendingSyncCount)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 8, y: -8)
                }
            }
        }
        .sheet(isPresented: $showSyncSheet) {
            SyncStatusSheet(vm: vm)
                .presentationDetents([.medium])
        }
    }
}

private struct SyncStatusSheet: View {
    @ObservedObject var vm: WardrobeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: vm.pendingSyncCount > 0 ? "icloud.and.arrow.up" : "checkmark.icloud")
                    .font(.system(size: 48))
                    .foregroundStyle(vm.pendingSyncCount > 0 ? .orange : .green)

                Text(vm.pendingSyncCount > 0
                     ? "\(vm.pendingSyncCount) item(s) waiting to sync"
                     : "All items synced")
                    .font(.headline)

                if case .error(let msg) = vm.syncState {
                    Text(msg).font(.caption).foregroundStyle(.red)
                }

                Button("Sync Now") {
                    Task { await vm.syncPendingItems() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.syncState == .syncing)
            }
            .padding()
            .navigationTitle("Sync Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

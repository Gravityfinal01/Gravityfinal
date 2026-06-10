import SwiftUI
import SwiftData

struct WardrobeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var immichService: ImmichService
    @EnvironmentObject private var networkMonitor: NetworkMonitor

    @StateObject private var vm = WardrobeViewModel()
    @State private var selectedCategory: ClothingCategory?
    @State private var searchText = ""
    @State private var showSyncSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryPills
                ClothingGridView(category: selectedCategory, searchText: searchText, vm: vm)
            }
            .navigationTitle("Wardrobe")
            .searchable(text: $searchText, prompt: "Search clothes…")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    syncButton
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

    private func pill(label: String, category: ClothingCategory?) -> some View {
        Button {
            selectedCategory = category
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
                Image(systemName: vm.syncState == .syncing ? "arrow.triangle.2.circlepath" : "arrow.triangle.2.circlepath")
                    .symbolEffect(.rotate, isActive: vm.syncState == .syncing)
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

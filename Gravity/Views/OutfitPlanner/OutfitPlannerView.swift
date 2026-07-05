import SwiftUI
import SwiftData

struct OutfitPlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClothingItem.dateAdded, order: .reverse)
    private var allItems: [ClothingItem]

    @StateObject private var vm = OutfitPlannerViewModel()
    @State private var showSaveSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CanvasView(vm: vm)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                itemDrawer
                    .frame(height: 110)
            }
            .navigationTitle("Outfit Planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") { vm.clearCanvas() }
                        .disabled(vm.canvasEntries.isEmpty)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            vm.suggestOutfit(from: activeItems)
                        } label: {
                            Label("Suggest", systemImage: "wand.and.stars")
                        }
                        .disabled(activeItems.isEmpty)

                        Button("Save") { showSaveSheet = true }
                            .disabled(vm.canvasEntries.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $showSaveSheet) {
                SaveOutfitSheet(vm: vm, context: modelContext)
                    .presentationDetents([.medium])
            }
        }
    }

    private var activeItems: [ClothingItem] {
        allItems.filter { !$0.deletedLocally }
    }

    private var itemDrawer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tap to add")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(activeItems) { item in
                        Button {
                            vm.addItem(item)
                        } label: {
                            ItemImageView(item: item, size: CGSize(width: 70, height: 80))
                                .frame(width: 70, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    vm.canvasEntries.contains(where: { $0.item.id == item.id })
                                    ? RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Color.accentColor, lineWidth: 2)
                                    : nil
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color(.systemBackground))
    }
}

private struct SaveOutfitSheet: View {
    @ObservedObject var vm: OutfitPlannerViewModel
    let context: ModelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Outfit Name") {
                    TextField("e.g. Monday Look", text: $vm.outfitName)
                }
                Section {
                    Button("Save Outfit") {
                        vm.saveOutfit(context: context, snapshot: nil)
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Save Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

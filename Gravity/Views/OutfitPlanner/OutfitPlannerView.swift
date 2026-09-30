import SwiftUI
import SwiftData

struct OutfitPlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClothingItem.dateAdded, order: .reverse)
    private var allItems: [ClothingItem]

    @StateObject private var vm = OutfitPlannerViewModel()
    @State private var mode: PlannerMode = .canvas
    @State private var showSaveSheet = false
    @State private var showSavedOutfits = false
    @State private var drawerCategory: ClothingCategory?
    @State private var canvasSize = CGSize(width: 390, height: 480)

    enum PlannerMode: String, CaseIterable, Identifiable {
        case canvas = "Canvas"
        case human = "Human"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Mode", selection: $mode) {
                    ForEach(PlannerMode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                switch mode {
                case .canvas: canvasMode
                case .human:  humanPlaceholder
                }
            }
            .navigationTitle("Outfits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSavedOutfits = true
                    } label: {
                        Label("Saved", systemImage: "rectangle.stack")
                    }
                }
            }
            .sheet(isPresented: $showSaveSheet) {
                SaveOutfitSheet(vm: vm) {
                    let snapshot = await OutfitSnapshotRenderer.render(
                        entries: vm.canvasEntries, canvasSize: canvasSize)
                    vm.saveOutfit(context: modelContext, snapshot: snapshot)
                }
                .presentationDetents([.height(260)])
            }
            .sheet(isPresented: $showSavedOutfits) {
                SavedOutfitsView { outfit in
                    vm.loadOutfit(outfit)
                    mode = .canvas
                }
            }
            .overlay(alignment: .top) {
                if vm.justSaved { savedToast }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.justSaved)
            .onChange(of: vm.justSaved) { _, saved in
                guard saved else { return }
                Task {
                    try? await Task.sleep(for: .seconds(1.6))
                    vm.justSaved = false
                }
            }
        }
    }

    private var activeItems: [ClothingItem] {
        allItems.filter { !$0.deletedLocally }
    }

    private var drawerItems: [ClothingItem] {
        guard let cat = drawerCategory else { return activeItems }
        return activeItems.filter { $0.category == cat }
    }

    // MARK: - Canvas mode

    private var canvasMode: some View {
        VStack(spacing: 0) {
            CanvasView(vm: vm)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { canvasSize = geo.size }
                            .onChange(of: geo.size) { _, newSize in canvasSize = newSize }
                    }
                )

            Divider()
            itemDrawer
            Divider()
            actionBar
        }
    }

    private var itemDrawer: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    drawerChip("All", category: nil)
                    ForEach(ClothingCategory.allCases) { cat in
                        drawerChip(cat.displayName, category: cat)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if drawerItems.isEmpty {
                        Text(drawerCategory == nil ? "Add items in the Add Item tab" : "Nothing in this category yet")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .frame(height: 80)
                    }
                    ForEach(drawerItems) { item in
                        let onCanvas = vm.canvasEntries.contains(where: { $0.item.id == item.id })
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                vm.addItem(item)
                            }
                        } label: {
                            ItemImageView(item: item, size: CGSize(width: 70, height: 80))
                                .frame(width: 70, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Color.accentColor, lineWidth: onCanvas ? 2 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .frame(height: 140)
        .background(Color(.systemBackground))
    }

    private func drawerChip(_ label: String, category: ClothingCategory?) -> some View {
        let selected = drawerCategory == category
        return Button {
            drawerCategory = category
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(selected ? Color.accentColor.opacity(0.18) : Color(.systemGray6))
                .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation { vm.clearCanvas() }
            } label: {
                Label("Clear", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .disabled(vm.isEmpty)

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    vm.suggestOutfit(from: activeItems)
                }
            } label: {
                Label("Suggest", systemImage: "wand.and.stars")
            }
            .buttonStyle(.bordered)
            .disabled(activeItems.isEmpty)

            Spacer(minLength: 0)

            Button {
                showSaveSheet = true
            } label: {
                Label(vm.loadedOutfit == nil ? "Save Outfit" : "Update Outfit",
                      systemImage: "square.and.arrow.down")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }

    private var savedToast: some View {
        Label(vm.loadedOutfit == nil ? "Outfit saved" : "Outfit updated", systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
            .padding(.top, 56)
            .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Human mode (placeholder)

    private var humanPlaceholder: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "figure.stand")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            Text("Coming soon")
                .font(.title3.weight(.semibold))
            Text("Drop clothes onto a body model and they'll snap into place by category.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Save sheet

private struct SaveOutfitSheet: View {
    @ObservedObject var vm: OutfitPlannerViewModel
    let onSave: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isSaving = false
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Outfit Name") {
                    TextField("e.g. Monday Look", text: $vm.outfitName)
                        .focused($nameFocused)
                        .submitLabel(.done)
                }
                Section {
                    Button {
                        Task {
                            isSaving = true
                            await onSave()
                            isSaving = false
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                            } else {
                                Text(vm.loadedOutfit == nil ? "Save Outfit" : "Update Outfit")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .navigationTitle(vm.loadedOutfit == nil ? "Save Outfit" : "Update Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
            }
            .onAppear { nameFocused = vm.outfitName.isEmpty }
        }
    }
}

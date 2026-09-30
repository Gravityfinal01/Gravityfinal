import SwiftUI
import SwiftData

@MainActor
class OutfitPlannerViewModel: ObservableObject {
    typealias CanvasEntry = (item: ClothingItem, state: CanvasItemState)

    @Published var canvasEntries: [CanvasEntry] = []
    @Published var outfitName = ""
    /// Set when an outfit was loaded from Saved Outfits; Save then updates it in place.
    @Published var loadedOutfit: Outfit?
    /// Briefly true after a save so the view can flash a confirmation.
    @Published var justSaved = false

    // Reserved for the upcoming body-model ("Human") mode.
    @Published var slots: [String: ClothingItem] = [:]

    var isEmpty: Bool { canvasEntries.isEmpty }

    var sortedEntries: [CanvasEntry] {
        canvasEntries.sorted { $0.state.zIndex < $1.state.zIndex }
    }

    // MARK: - Canvas

    func addItem(_ item: ClothingItem, at offset: CGSize? = nil) {
        if canvasEntries.contains(where: { $0.item.id == item.id }) {
            bringToFront(item.id)
            return
        }
        let z = (canvasEntries.map(\.state.zIndex).max() ?? -1) + 1
        let state = CanvasItemState(
            offsetX: Double(offset?.width ?? CGFloat.random(in: -40...40)),
            offsetY: Double(offset?.height ?? CGFloat.random(in: -40...40)),
            zIndex: z
        )
        canvasEntries.append((item, state))
    }

    func updateState(for itemId: UUID, state: CanvasItemState) {
        guard let idx = canvasEntries.firstIndex(where: { $0.item.id == itemId }) else { return }
        canvasEntries[idx].state = state
    }

    func removeItem(_ itemId: UUID) {
        canvasEntries.removeAll { $0.item.id == itemId }
    }

    func bringToFront(_ itemId: UUID) {
        let maxZ = (canvasEntries.map(\.state.zIndex).max() ?? 0) + 1
        guard let idx = canvasEntries.firstIndex(where: { $0.item.id == itemId }) else { return }
        canvasEntries[idx].state.zIndex = maxZ
    }

    func sendToBack(_ itemId: UUID) {
        let minZ = (canvasEntries.map(\.state.zIndex).min() ?? 0) - 1
        guard let idx = canvasEntries.firstIndex(where: { $0.item.id == itemId }) else { return }
        canvasEntries[idx].state.zIndex = minZ
    }

    func clearCanvas() {
        canvasEntries.removeAll()
        slots.removeAll()
        outfitName = ""
        loadedOutfit = nil
    }

    // MARK: - Suggest

    func suggestOutfit(from items: [ClothingItem]) {
        clearCanvas()

        let tops    = items.filter { $0.category == .tops || $0.category == .sweaters }
        let jackets = items.filter { $0.category == .jackets }
        let dresses = items.filter { $0.category == .dresses }
        let bottoms = items.filter { $0.category == .bottoms }
        let shoes   = items.filter { $0.category == .shoes }
        let accs    = items.filter { $0.category == .accessories }

        // Pick a dress when it's the only complete option, otherwise flip a coin so
        // both dresses and top+bottom combos get suggested over time.
        let canDoSeparates = !tops.isEmpty && !bottoms.isEmpty
        if let dress = dresses.randomElement(), !canDoSeparates || Bool.random() {
            addItem(dress, at: Self.defaultOffset(for: .dresses))
        } else {
            if let top    = tops.randomElement()    { addItem(top,    at: Self.defaultOffset(for: .tops)) }
            if let bottom = bottoms.randomElement() { addItem(bottom, at: Self.defaultOffset(for: .bottoms)) }
        }
        if let jacket = jackets.randomElement(), Bool.random() {
            addItem(jacket, at: Self.defaultOffset(for: .jackets))
        }
        if let shoe = shoes.randomElement() { addItem(shoe, at: Self.defaultOffset(for: .shoes)) }
        if let acc  = accs.randomElement()  { addItem(acc,  at: Self.defaultOffset(for: .accessories)) }
    }

    /// Rough "where this kind of thing goes" placement, relative to canvas centre.
    private static func defaultOffset(for category: ClothingCategory) -> CGSize {
        switch category {
        case .tops, .sweaters:     return CGSize(width: 0,    height: -120)
        case .jackets:             return CGSize(width: -110, height: -100)
        case .dresses:             return CGSize(width: 0,    height: -40)
        case .bottoms:             return CGSize(width: 0,    height: 40)
        case .shoes:               return CGSize(width: 0,    height: 190)
        case .accessories, .other: return CGSize(width: 115,  height: -100)
        }
    }

    // MARK: - Save / Load

    func saveOutfit(context: ModelContext, snapshot: UIImage?) {
        let states = Dictionary(uniqueKeysWithValues: canvasEntries.map { ($0.item.id.uuidString, $0.state) })
        let trimmed = outfitName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "My Outfit" : trimmed

        let outfit: Outfit
        if let existing = loadedOutfit {
            outfit = existing
            outfit.name = name
            outfit.items = canvasEntries.map(\.item)
            outfit.canvasStates = states
            outfit.lastModified = Date()
        } else {
            outfit = Outfit(
                name: name,
                items: canvasEntries.map(\.item),
                canvasStatesData: try? JSONEncoder().encode(states)
            )
            context.insert(outfit)
        }

        if let snapshot, let jpeg = snapshot.jpegData(compressionQuality: 0.85) {
            // New filename each save so cached thumbnails refresh.
            ClothingImageLoader.deleteSnapshot(outfit)
            let filename = "\(outfit.id.uuidString)_\(Int(Date().timeIntervalSince1970)).jpg"
            try? jpeg.write(to: ClothingImageLoader.imagesDirectory.appendingPathComponent(filename))
            outfit.snapshotPath = filename
        }

        try? context.save()
        loadedOutfit = outfit
        outfitName = name
        justSaved = true
    }

    func loadOutfit(_ outfit: Outfit) {
        clearCanvas()
        loadedOutfit = outfit
        outfitName = outfit.name

        let states = outfit.canvasStates
        if states.isEmpty {
            // Saved without layout data (e.g. by the earlier body-model version): place by category.
            for item in outfit.items {
                addItem(item, at: Self.defaultOffset(for: item.category))
            }
            return
        }

        canvasEntries = outfit.items.compactMap { item in
            states[item.id.uuidString].map { (item: item, state: $0) }
        }
        for item in outfit.items where states[item.id.uuidString] == nil {
            addItem(item, at: Self.defaultOffset(for: item.category))
        }
    }

    // MARK: - Body-model slots (unused until "Human" mode ships)

    func addToSlot(_ item: ClothingItem) {
        let zone = item.category.bodyZone
        if zone == .fullBody {
            slots.removeValue(forKey: BodyZone.torso.rawValue)
            slots.removeValue(forKey: BodyZone.legs.rawValue)
        } else if zone == .torso || zone == .legs {
            slots.removeValue(forKey: BodyZone.fullBody.rawValue)
        }
        slots[zone.rawValue] = item
    }

    func removeFromSlot(_ key: String) {
        slots.removeValue(forKey: key)
    }
}

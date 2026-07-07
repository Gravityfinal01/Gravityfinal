import SwiftUI
import SwiftData

@MainActor
class OutfitPlannerViewModel: ObservableObject {
    // Body-figure slot system (zone key → item)
    @Published var slots: [String: ClothingItem] = [:]

    // Legacy canvas (kept for potential future use)
    @Published var canvasEntries: [(item: ClothingItem, state: CanvasItemState)] = []
    @Published var outfitName = ""
    @Published var isSaved = false

    // MARK: - Slot operations

    func addToSlot(_ item: ClothingItem) {
        let zone = item.category.bodyZone
        // Conflict resolution: dress clears top+bottom; top/bottom clears dress
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

    func clearCanvas() {
        slots.removeAll()
        canvasEntries.removeAll()
        outfitName = ""
        isSaved = false
    }

    // MARK: - Suggest outfit

    func suggestOutfit(from items: [ClothingItem]) {
        clearCanvas()

        let tops     = items.filter { [.shirt, .hoodie, .jacket].contains($0.category) }
        let dresses  = items.filter { $0.category == .dress }
        let bottoms  = items.filter { $0.category == .pants || $0.category == .shorts }
        let shoes    = items.filter { $0.category == .shoes }
        let accs     = items.filter { $0.category == .accessories }

        if let dress = dresses.randomElement() {
            slots[BodyZone.fullBody.rawValue] = dress
        } else {
            if let top    = tops.randomElement()    { slots[BodyZone.torso.rawValue] = top }
            if let bottom = bottoms.randomElement() { slots[BodyZone.legs.rawValue]  = bottom }
        }
        if let shoe = shoes.randomElement() { slots[BodyZone.feet.rawValue]        = shoe }
        if let acc  = accs.randomElement()  { slots[BodyZone.accessories.rawValue] = acc }
    }

    // MARK: - Save / Load

    func saveOutfit(context: ModelContext, snapshot: UIImage?) {
        // Encode slots as [zoneKey: itemUUID]
        let slotsDict = slots.mapValues { $0.id.uuidString }
        let data = try? JSONEncoder().encode(slotsDict)

        let outfit = Outfit(
            name: outfitName.isEmpty ? "My Outfit" : outfitName,
            items: Array(slots.values),
            canvasStatesData: data
        )

        if let snapshot,
           let jpeg = snapshot.jpegData(compressionQuality: 0.85) {
            let filename = "\(outfit.id.uuidString)_outfit.jpg"
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("images")
                .appendingPathComponent(filename)
            try? FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? jpeg.write(to: url)
            outfit.snapshotPath = filename
        }

        context.insert(outfit)
        try? context.save()
        isSaved = true
    }

    func loadOutfit(_ outfit: Outfit) {
        outfitName = outfit.name
        slots.removeAll()
        canvasEntries.removeAll()

        // Decode [zoneKey: itemUUID] format
        if let data = outfit.canvasStatesData,
           let slotsDict = try? JSONDecoder().decode([String: String].self, from: data) {
            let byUUID = Dictionary(uniqueKeysWithValues: outfit.items.map { ($0.id.uuidString, $0) })
            for (zoneKey, uuid) in slotsDict {
                slots[zoneKey] = byUUID[uuid]
            }
        }
    }

    // MARK: - Legacy canvas helpers (unused by body figure mode)

    func addItem(_ item: ClothingItem) {
        guard !canvasEntries.contains(where: { $0.item.id == item.id }) else { return }
        let z = (canvasEntries.map(\.state.zIndex).max() ?? -1) + 1
        canvasEntries.append((item, CanvasItemState(
            offsetX: Double.random(in: -40...40),
            offsetY: Double.random(in: -40...40),
            zIndex: z
        )))
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

    var sortedEntries: [(item: ClothingItem, state: CanvasItemState)] {
        canvasEntries.sorted { $0.state.zIndex < $1.state.zIndex }
    }
}

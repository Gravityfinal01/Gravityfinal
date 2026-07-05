import SwiftUI
import SwiftData

@MainActor
class OutfitPlannerViewModel: ObservableObject {
    @Published var canvasEntries: [(item: ClothingItem, state: CanvasItemState)] = []
    @Published var outfitName = ""
    @Published var isSaved = false

    var sortedEntries: [(item: ClothingItem, state: CanvasItemState)] {
        canvasEntries.sorted { $0.state.zIndex < $1.state.zIndex }
    }

    func addItem(_ item: ClothingItem) {
        guard !canvasEntries.contains(where: { $0.item.id == item.id }) else { return }
        let z = (canvasEntries.map(\.state.zIndex).max() ?? -1) + 1
        let state = CanvasItemState(
            offsetX: Double.random(in: -40...40),
            offsetY: Double.random(in: -40...40),
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
        outfitName = ""
        isSaved = false
    }

    func suggestOutfit(from items: [ClothingItem]) {
        clearCanvas()

        let tops = items.filter { [.shirt, .hoodie, .jacket].contains($0.category) }
        let dresses = items.filter { $0.category == .dress }
        let bottoms = items.filter { $0.category == .pants || $0.category == .shorts }
        let shoes = items.filter { $0.category == .shoes }
        let accessories = items.filter { $0.category == .accessories }

        var picked: [ClothingItem] = []
        if let dress = dresses.randomElement() {
            picked.append(dress)
        } else {
            if let top = tops.randomElement() { picked.append(top) }
            if let bottom = bottoms.randomElement() { picked.append(bottom) }
        }
        if let shoe = shoes.randomElement() { picked.append(shoe) }
        if let acc = accessories.randomElement() { picked.append(acc) }

        for item in picked { addItem(item) }

        // Arrange: top-center, bottom-center, shoes below, accessory to the side
        let layout: [(Double, Double)] = [
            (0, -130),
            (0, 60),
            (0, 190),
            (140, -70)
        ]
        for (i, _) in canvasEntries.enumerated() {
            guard i < layout.count else { break }
            canvasEntries[i].state.offsetX = layout[i].0
            canvasEntries[i].state.offsetY = layout[i].1
        }
    }

    func saveOutfit(context: ModelContext, snapshot: UIImage?) {
        let statesDict = Dictionary(uniqueKeysWithValues: canvasEntries.map {
            ($0.item.id.uuidString, $0.state)
        })

        let outfit = Outfit(
            name: outfitName.isEmpty ? "My Outfit" : outfitName,
            items: canvasEntries.map(\.item),
            canvasStatesData: try? JSONEncoder().encode(statesDict)
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
        let states = outfit.canvasStates
        canvasEntries = outfit.items.map { item in
            let state = states[item.id.uuidString] ?? CanvasItemState()
            return (item, state)
        }
    }
}

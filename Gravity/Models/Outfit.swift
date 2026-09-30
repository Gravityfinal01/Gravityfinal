import SwiftData
import Foundation

// CloudKit-backed SwiftData requires defaults on stored properties and optional
// relationships. `items` is optional for that reason; read it as `items ?? []`.
@Model
class Outfit {
    var id: UUID = UUID()
    var name: String = ""
    @Relationship(deleteRule: .nullify, inverse: \ClothingItem.outfits)
    var items: [ClothingItem]?
    var canvasStatesData: Data?     // encoded [String (UUID): CanvasItemState]
    var snapshotPath: String?       // filename in Documents/images/
    var dateCreated: Date = Date()
    var lastModified: Date = Date()

    init(
        id: UUID = UUID(),
        name: String,
        items: [ClothingItem] = [],
        canvasStatesData: Data? = nil,
        snapshotPath: String? = nil,
        dateCreated: Date = Date(),
        lastModified: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.items = items
        self.canvasStatesData = canvasStatesData
        self.snapshotPath = snapshotPath
        self.dateCreated = dateCreated
        self.lastModified = lastModified
    }

    var canvasStates: [String: CanvasItemState] {
        get {
            guard let data = canvasStatesData else { return [:] }
            return (try? JSONDecoder().decode([String: CanvasItemState].self, from: data)) ?? [:]
        }
        set {
            canvasStatesData = try? JSONEncoder().encode(newValue)
        }
    }
}

import SwiftUI
import SwiftData

enum CategorizationState: Equatable {
    case idle, classifying, enriching, complete, error(String)
}

@MainActor
class AddClothingViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var categorizationState: CategorizationState = .idle
    @Published var result: CategorizationResult?
    @Published var editableName = ""
    @Published var editableBrand = ""
    @Published var editableCategory: ClothingCategory = .other
    @Published var isSaving = false
    @Published var didSave = false

    private static var imagesDir: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("images")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func processImage(_ image: UIImage, aiService: AICategorizationService) async {
        selectedImage = image
        categorizationState = .classifying

        // Phase 1: fast on-device Vision
        let visionResult = await aiService.classifyWithVision(image: image)
        result = visionResult
        editableCategory = visionResult.category
        editableName = visionResult.category.singularName
        categorizationState = .enriching

        // Phase 2: Ollama enrichment (if configured)
        let fullResult = await aiService.categorize(image: image)
        result = fullResult
        editableCategory = fullResult.category
        if let color = fullResult.color {
            editableName = "\(color.capitalized) \(fullResult.category.singularName)"
        }
        categorizationState = .complete
    }

    func saveItem(context: ModelContext) async {
        guard let image = selectedImage else { return }
        isSaving = true
        defer { isSaving = false }

        let itemId = UUID()
        let filename = "\(itemId.uuidString).jpg"
        let imageURL = Self.imagesDir.appendingPathComponent(filename)

        guard let jpeg = image.jpegData(compressionQuality: 0.85) else { return }
        try? jpeg.write(to: imageURL)

        // Optionally save to Photos Library so iCloud Photos syncs it
        var photosId: String?
        let storageBackend = UserDefaults.standard.string(forKey: "storageBackend") ?? "local"
        if storageBackend == "photos" || storageBackend == "photosAndImmich" {
            photosId = try? await PhotoLibraryService.shared.save(image)
        }

        let name = editableName.isEmpty ? editableCategory.singularName : editableName
        let item = ClothingItem(
            id: itemId,
            name: name,
            category: editableCategory,
            color: result?.color,
            brand: editableBrand.isEmpty ? nil : editableBrand,
            tags: result?.tags ?? [],
            localImagePath: filename,
            photosAssetIdentifier: photosId
        )
        context.insert(item)
        try? context.save()

        // Background Immich sync if configured
        if storageBackend == "immich" || storageBackend == "photosAndImmich" {
            Task.detached {
                // Sync handled by WardrobeViewModel.syncPendingItems()
            }
        }

        didSave = true
    }

    func reset() {
        selectedImage = nil
        categorizationState = .idle
        result = nil
        editableName = ""
        editableBrand = ""
        editableCategory = .other
        isSaving = false
        didSave = false
    }
}

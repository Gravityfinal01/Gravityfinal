import SwiftUI
import SwiftData

enum CategorizationState: Equatable {
    case idle, removingBackground, classifying, enriching, complete, error(String)
}

@MainActor
class AddClothingViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var processedImage: UIImage?
    @Published var categorizationState: CategorizationState = .idle
    @Published var result: CategorizationResult?
    @Published var editableName = ""
    @Published var editableBrand = ""
    @Published var editableCategory: ClothingCategory = .other {
        didSet {
            // Drop a subcategory that no longer belongs to the chosen parent.
            if let sub = editableSubcategory, sub.parent != editableCategory {
                editableSubcategory = nil
            }
        }
    }
    @Published var editableSubcategory: ClothingSubcategory?
    @Published var isSaving = false
    @Published var didSave = false

    /// Rotated by reset() so an in-flight processImage() stops writing results
    /// after the user discards the photo mid-analysis.
    private var processingToken = UUID()

    private static var imagesDir: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("images")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func processImage(_ image: UIImage, aiService: AICategorizationService) async {
        let token = UUID()
        processingToken = token

        selectedImage = image
        processedImage = nil
        categorizationState = .removingBackground

        // Step 0: on-device background removal (iOS 17+)
        let bgRemoved = await BackgroundRemovalService.shared.removeBackground(from: image)
        guard processingToken == token else { return }
        processedImage = bgRemoved

        categorizationState = .classifying

        // Phase 1: fast on-device Vision
        let visionResult = await aiService.classifyWithVision(image: bgRemoved)
        guard processingToken == token else { return }
        result = visionResult
        editableCategory = visionResult.category
        editableSubcategory = visionResult.subcategory
        editableName = Self.defaultName(editableCategory, editableSubcategory, color: nil)
        categorizationState = .enriching

        // Phase 2: Ollama enrichment (if configured)
        let fullResult = await aiService.categorize(image: bgRemoved)
        guard processingToken == token else { return }
        result = fullResult
        editableCategory = fullResult.category
        // Prefer Ollama's subcategory; otherwise keep Vision's if it still fits the parent.
        if let sub = fullResult.subcategory {
            editableSubcategory = sub
        } else if let sub = visionResult.subcategory, sub.parent == fullResult.category {
            editableSubcategory = sub
        }
        editableName = Self.defaultName(editableCategory, editableSubcategory, color: fullResult.color)
        categorizationState = .complete
    }

    private static func defaultName(_ category: ClothingCategory, _ subcategory: ClothingSubcategory?, color: String?) -> String {
        let base = subcategory?.singularName ?? category.singularName
        if let color, !color.isEmpty { return "\(color.capitalized) \(base)" }
        return base
    }

    func saveItem(context: ModelContext) async {
        guard let image = processedImage ?? selectedImage else { return }
        isSaving = true
        defer { isSaving = false }

        let itemId = UUID()
        let filename = "\(itemId.uuidString).png"
        let imageURL = Self.imagesDir.appendingPathComponent(filename)

        guard let png = image.pngData() else { return }
        try? png.write(to: imageURL)

        var photosId: String?
        let storageBackend = UserDefaults.standard.string(forKey: "storageBackend") ?? "local"
        if storageBackend == "photos" || storageBackend == "photosAndImmich" {
            photosId = try? await PhotoLibraryService.shared.save(image)
        }

        let name = editableName.isEmpty
            ? Self.defaultName(editableCategory, editableSubcategory, color: nil)
            : editableName
        let item = ClothingItem(
            id: itemId,
            name: name,
            category: editableCategory,
            subcategory: editableSubcategory,
            color: result?.color,
            brand: editableBrand.isEmpty ? nil : editableBrand,
            tags: result?.tags ?? [],
            localImagePath: filename,
            photosAssetIdentifier: photosId
        )
        context.insert(item)
        try? context.save()

        if storageBackend == "immich" || storageBackend == "photosAndImmich" {
            Task.detached { }
        }

        didSave = true
    }

    func reset() {
        processingToken = UUID()
        selectedImage = nil
        processedImage = nil
        categorizationState = .idle
        result = nil
        editableName = ""
        editableBrand = ""
        editableCategory = .other
        editableSubcategory = nil
        isSaving = false
        didSave = false
    }
}

import Foundation
import Vision
import UIKit

// MARK: - Result Types

struct CategorizationResult {
    var category: ClothingCategory
    var subcategory: ClothingSubcategory? = nil
    var color: String?
    var tags: [String]
    var confidence: Double
    var source: AISource

    enum AISource {
        case vision, ollama, hybrid
    }
}

private struct OllamaResponse: Codable {
    let response: String
}

private struct OllamaClothingJSON: Codable {
    let category: String
    let subcategory: String?
    let color: String?
    let brand: String?
    let tags: [String]
}

// MARK: - Service

@MainActor
class AICategorizationService: ObservableObject {
    @Published var isAnalyzing = false

    private var ollamaBaseURL: String { UserDefaults.standard.string(forKey: "ollamaBaseURL") ?? "" }
    private var ollamaModel: String { UserDefaults.standard.string(forKey: "ollamaModel") ?? "llava" }
    private var useOllama: Bool { UserDefaults.standard.bool(forKey: "useOllama") }

    // MARK: Public entry point — runs Vision immediately, enriches with Ollama if enabled

    func categorize(image: UIImage) async -> CategorizationResult {
        isAnalyzing = true
        defer { isAnalyzing = false }

        let visionResult = await classifyWithVision(image: image)

        if useOllama && !ollamaBaseURL.isEmpty {
            if let enriched = try? await enrichWithOllama(image: image, visionFallback: visionResult.category) {
                return enriched
            }
        }
        return visionResult
    }

    // MARK: On-device Vision pass (~100ms, always offline)

    func classifyWithVision(image: UIImage) async -> CategorizationResult {
        guard let cgImage = image.normalizedUp().cgImage else {
            return CategorizationResult(category: .other, color: nil, tags: [], confidence: 0, source: .vision)
        }

        return await withCheckedContinuation { continuation in
            let request = VNClassifyImageRequest { req, error in
                guard let observations = req.results as? [VNClassificationObservation], error == nil else {
                    continuation.resume(returning: CategorizationResult(
                        category: .other, color: nil, tags: [], confidence: 0, source: .vision))
                    return
                }
                let top = observations.filter { $0.confidence > 0.01 }.prefix(30)
                let (category, subcategory) = self.mapVisionToCategory(Array(top))
                let tags = top.map { $0.identifier }
                continuation.resume(returning: CategorizationResult(
                    category: category,
                    subcategory: subcategory,
                    color: nil,
                    tags: tags,
                    confidence: Double(top.first?.confidence ?? 0),
                    source: .vision
                ))
            }
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    /// Scores every label Vision returns (weighted by its confidence) against clothing keywords,
    /// plus what this user has taught it by correcting earlier items, and picks the best type.
    /// Keywords match whole words only, so "ring" no longer fires on "earring" or "string".
    private func mapVisionToCategory(_ observations: [VNClassificationObservation]) -> (ClothingCategory, ClothingSubcategory?) {
        let subRules: [(keywords: [String], sub: ClothingSubcategory)] = [
            // Tops
            (["t shirt", "tshirt", "tee", "tee shirt", "jersey"], .tshirt),
            (["long sleeve", "longsleeve", "long sleeved shirt"], .longSleeve),
            (["button down", "button up", "dress shirt", "oxford shirt", "flannel", "shirt collar"], .buttonUp),
            (["polo", "polo shirt"], .polo),
            (["tank top", "tank", "camisole", "sleeveless shirt", "singlet"], .tankTop),
            // Bottoms
            (["shorts", "bermuda shorts", "cutoffs"], .shorts),
            (["jeans", "denim", "blue jeans"], .jeans),
            (["sweatpants", "joggers", "jogger", "track pants", "trackpants"], .sweatpants),
            (["slacks", "chinos", "chino", "trousers", "dress pants", "khakis"], .dressPants),
            (["skirt", "miniskirt", "kilt"], .skirt),
            // Jackets
            (["puffer", "puffer jacket", "down jacket", "quilted jacket", "parka"], .puffer),
            (["vest", "gilet", "waistcoat"], .vest),
            (["coat", "overcoat", "trench coat", "raincoat", "blazer", "peacoat"], .coat),
            // Sweaters
            (["zip up", "zip hoodie", "zipper"], .zipUp),
            (["hoodie", "hoody", "hooded sweatshirt"], .hoodie),
            (["turtleneck", "turtle neck", "roll neck", "polo neck"], .turtleneck),
            (["cardigan"], .cardigan),
            (["crewneck", "crew neck", "sweatshirt"], .crewneck),
            (["sweater", "pullover", "jumper", "knitwear", "wool sweater"], .sweater),
            // Shoes
            (["boot", "boots", "cowboy boot", "hiking boot", "chelsea boot"], .boots),
            (["sneaker", "sneakers", "trainer", "running shoe", "athletic shoe", "tennis shoe", "basketball shoe"], .athletic),
            (["high heel", "high heels", "heel", "stiletto", "pump"], .heels),
            (["loafer", "dress shoe", "brogue", "oxford shoe", "derby shoe"], .dressShoes),
            (["ballet flat", "flats"], .flats),
            (["sandal", "sandals", "flip flop", "flip flops", "slide"], .sandals),
            // Accessories
            (["bag", "purse", "handbag", "backpack", "tote", "tote bag", "satchel", "clutch"], .bag),
            (["earring", "earrings"], .earrings),
            (["bracelet", "bangle"], .bracelet),
            (["necklace", "pendant", "chain"], .necklace),
            (["wristwatch", "watch"], .watch),
            (["belt", "belt buckle"], .belt),
            (["ring", "wedding ring"], .ring),
        ]

        let catRules: [(keywords: [String], cat: ClothingCategory)] = [
            (["shirt", "blouse", "top", "clothing top"], .tops),
            (["pants", "leggings", "bottoms"], .bottoms),
            (["jacket", "windbreaker", "outerwear", "bomber jacket", "denim jacket", "leather jacket"], .jackets),
            (["shoe", "shoes", "footwear"], .shoes),
            (["dress", "gown", "frock", "jumpsuit", "sundress"], .dresses),
            (["hat", "cap", "beanie", "scarf", "glove", "gloves", "jewelry", "accessory", "sunglasses"], .accessories),
        ]

        func matches(_ label: String, _ keyword: String) -> Bool {
            let padded = " \(label) "
            return padded.contains(" \(keyword) ") || padded.contains(" \(keyword)s ")
        }

        let learned = LearnedLabels.table
        var subScores: [ClothingSubcategory: Double] = [:]
        var catScores: [ClothingCategory: Double] = [:]

        for observation in observations {
            let label = LearnedLabels.normalize(observation.identifier)
            let weight = Double(observation.confidence)

            var matchedSub = false
            for rule in subRules where rule.keywords.contains(where: { matches(label, $0) }) {
                subScores[rule.sub, default: 0] += weight
                matchedSub = true
            }
            // "dress shirt" is a shirt, not a dress: skip broad rules when a specific one matched.
            if !matchedSub {
                for rule in catRules where rule.keywords.contains(where: { matches(label, $0) }) {
                    catScores[rule.cat, default: 0] += weight
                }
            }

            // What this user filed similar photos under before.
            for (target, count) in learned[label] ?? [:] {
                let boost = weight * min(Double(count), 5) * 0.6
                if target.hasPrefix("sub:"), let sub = ClothingSubcategory(rawValue: String(target.dropFirst(4))) {
                    subScores[sub, default: 0] += boost
                } else if target.hasPrefix("cat:"), let cat = ClothingCategory(rawValue: String(target.dropFirst(4))) {
                    catScores[cat, default: 0] += boost
                }
            }
        }

        for (sub, score) in subScores { catScores[sub.parent, default: 0] += score }

        guard let best = catScores.max(by: { $0.value < $1.value }), best.value >= 0.02 else {
            return (.other, nil)
        }
        let sub = subScores.filter { $0.key.parent == best.key }.max(by: { $0.value < $1.value })?.key
        return (best.key, sub)
    }

    // MARK: Ollama enrichment — local network only, adds color/brand/tags

    private func enrichWithOllama(image: UIImage, visionFallback: ClothingCategory) async throws -> CategorizationResult? {
        guard let url = URL(string: "\(ollamaBaseURL)/api/generate"),
              let jpeg = image.jpegData(compressionQuality: 0.65) else { return nil }

        let base64 = jpeg.base64EncodedString()
        let subcategoryList = ClothingSubcategory.allCases.map(\.rawValue).joined(separator: "|")
        let prompt = """
        Analyze this clothing item photo. Reply ONLY with this exact JSON (no markdown, no extra text):
        {"category":"<tops|bottoms|jackets|sweaters|shoes|dresses|accessories|other>","subcategory":"<\(subcategoryList)|null>","color":"<primary color>","brand":null,"tags":["tag1","tag2"]}
        Use null for subcategory if the category is dresses or other, or if unsure.
        """

        let body: [String: Any] = [
            "model": ollamaModel,
            "stream": false,
            "prompt": prompt,
            "images": [base64]
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            return nil
        }

        let ollamaResp = try JSONDecoder().decode(OllamaResponse.self, from: data)
        guard let parsed = parseOllamaJSON(ollamaResp.response) else { return nil }

        // A valid subcategory is the most specific signal, so let it decide the parent.
        let subcategory = ClothingSubcategory.lenient(parsed.subcategory)
        let category = subcategory?.parent
            ?? ClothingCategory(rawValue: parsed.category.lowercased())
            ?? visionFallback
        return CategorizationResult(
            category: category,
            subcategory: subcategory,
            color: parsed.color,
            tags: parsed.tags,
            confidence: 0.9,
            source: .hybrid
        )
    }

    private func parseOllamaJSON(_ text: String) -> OllamaClothingJSON? {
        // Strip markdown fences if present, extract first JSON object
        var src = text
        if let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}") {
            src = String(text[start...end])
        }
        guard let data = src.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(OllamaClothingJSON.self, from: data)
    }
}

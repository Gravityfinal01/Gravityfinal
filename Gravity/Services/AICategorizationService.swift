import Foundation
import Vision
import UIKit

// MARK: - Result Types

struct CategorizationResult {
    var category: ClothingCategory
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
        guard let cgImage = image.cgImage else {
            return CategorizationResult(category: .other, color: nil, tags: [], confidence: 0, source: .vision)
        }

        return await withCheckedContinuation { continuation in
            let request = VNClassifyImageRequest { req, error in
                guard let observations = req.results as? [VNClassificationObservation], error == nil else {
                    continuation.resume(returning: CategorizationResult(
                        category: .other, color: nil, tags: [], confidence: 0, source: .vision))
                    return
                }
                let top = observations.filter { $0.confidence > 0.05 }.prefix(15)
                let category = self.mapVisionToCategory(Array(top))
                let tags = top.map { $0.identifier }
                continuation.resume(returning: CategorizationResult(
                    category: category,
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

    private func mapVisionToCategory(_ observations: [VNClassificationObservation]) -> ClothingCategory {
        let ids = observations.map { $0.identifier.lowercased() }

        let rules: [(keywords: [String], category: ClothingCategory)] = [
            (["shirt", "t-shirt", "tshirt", "blouse", "top_", "polo", "tank"], .shirt),
            (["pants", "trousers", "jeans", "chinos", "leggings", "slacks", "jogger"], .pants),
            (["hoodie", "hoody", "sweatshirt", "sweater", "pullover", "jumper"], .hoodie),
            (["jacket", "coat", "blazer", "parka", "windbreaker", "cardigan", "overcoat"], .jacket),
            (["shoe", "boot", "sneaker", "sandal", "loafer", "heel", "footwear", "trainer"], .shoes),
            (["dress", "gown", "skirt", "frock", "jumpsuit"], .dress),
            (["shorts", "bermuda", "cutoff"], .shorts),
            (["bag", "hat", "cap", "belt", "scarf", "glove", "watch", "jewelry", "accessory", "accessori"], .accessories),
        ]

        for id in ids {
            for rule in rules {
                if rule.keywords.contains(where: { id.contains($0) }) {
                    return rule.category
                }
            }
        }
        return .other
    }

    // MARK: Ollama enrichment — local network only, adds color/brand/tags

    private func enrichWithOllama(image: UIImage, visionFallback: ClothingCategory) async throws -> CategorizationResult? {
        guard let url = URL(string: "\(ollamaBaseURL)/api/generate"),
              let jpeg = image.jpegData(compressionQuality: 0.65) else { return nil }

        let base64 = jpeg.base64EncodedString()
        let prompt = """
        Analyze this clothing item photo. Reply ONLY with this exact JSON (no markdown, no extra text):
        {"category":"<shirt|pants|hoodie|jacket|shoes|dress|shorts|accessories|other>","color":"<primary color>","brand":null,"tags":["tag1","tag2"]}
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

        let category = ClothingCategory(rawValue: parsed.category.lowercased()) ?? visionFallback
        return CategorizationResult(
            category: category,
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

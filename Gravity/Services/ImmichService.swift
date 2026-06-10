import Foundation
import UIKit

// MARK: - DTOs

struct ImmichAssetDTO: Codable {
    let id: String
    let originalFileName: String?
}

struct ImmichAlbumDTO: Codable {
    let id: String
    let albumName: String
}

struct ImmichUploadResponse: Codable {
    let id: String
    let status: String
}

// MARK: - Errors

enum ImmichError: LocalizedError {
    case notConfigured
    case unauthorized
    case notFound
    case networkError(Error)
    case serverError(Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Immich server not configured in Settings."
        case .unauthorized: return "Invalid API key."
        case .notFound: return "Resource not found."
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .serverError(let code): return "Server error HTTP \(code)."
        case .invalidResponse: return "Invalid response from Immich."
        }
    }
}

// MARK: - Service

@MainActor
class ImmichService: ObservableObject {
    @Published var isConnected = false
    @Published var lastSyncDate: Date?

    private var albumCache: [String: String] = [:]

    var baseURL: String { UserDefaults.standard.string(forKey: "immichBaseURL") ?? "" }
    var apiKey: String { UserDefaults.standard.string(forKey: "immichAPIKey") ?? "" }

    private func request(_ path: String, method: String = "GET") throws -> URLRequest {
        guard !baseURL.isEmpty, let url = URL(string: baseURL + path) else {
            throw ImmichError.notConfigured
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        return req
    }

    private func check(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw ImmichError.invalidResponse }
        switch http.statusCode {
        case 200...299: return
        case 401: throw ImmichError.unauthorized
        case 404: throw ImmichError.notFound
        default: throw ImmichError.serverError(http.statusCode)
        }
    }

    // MARK: Connection test

    func ping() async throws {
        let req = try request("/api/user/me")
        let (_, response) = try await URLSession.shared.data(for: req)
        try check(response)
        isConnected = true
    }

    // MARK: Upload

    func uploadAsset(imageData: Data, itemId: UUID, filename: String) async throws -> String {
        guard !baseURL.isEmpty, let url = URL(string: baseURL + "/api/assets") else {
            throw ImmichError.notConfigured
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = "GravityBoundary\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let now = ISO8601DateFormatter().string(from: Date())
        var body = Data()

        func field(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        field("deviceAssetId", itemId.uuidString)
        field("deviceId", "com.wardrobe.ai")
        field("fileCreatedAt", now)
        field("fileModifiedAt", now)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"assetData\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        req.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: req)
        try check(response)
        let result = try JSONDecoder().decode(ImmichUploadResponse.self, from: data)
        return result.id
    }

    // MARK: Albums

    func ensureAlbum(named albumName: String) async throws -> String {
        if let cached = albumCache[albumName] { return cached }

        let req = try request("/api/albums")
        let (data, response) = try await URLSession.shared.data(for: req)
        try check(response)
        let albums = try JSONDecoder().decode([ImmichAlbumDTO].self, from: data)

        if let existing = albums.first(where: { $0.albumName == albumName }) {
            albumCache[albumName] = existing.id
            return existing.id
        }

        var createReq = try request("/api/albums", method: "POST")
        createReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        createReq.httpBody = try JSONEncoder().encode(["albumName": albumName])
        let (createData, createResponse) = try await URLSession.shared.data(for: createReq)
        try check(createResponse)
        let newAlbum = try JSONDecoder().decode(ImmichAlbumDTO.self, from: createData)
        albumCache[albumName] = newAlbum.id
        return newAlbum.id
    }

    func addAsset(_ assetId: String, toAlbum albumId: String) async throws {
        var req = try request("/api/albums/\(albumId)/assets", method: "PUT")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["ids": [assetId]])
        let (_, response) = try await URLSession.shared.data(for: req)
        try check(response)
    }

    func deleteAsset(_ assetId: String) async throws {
        var req = try request("/api/assets", method: "DELETE")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["ids": [assetId]])
        let (_, _) = try await URLSession.shared.data(for: req)
    }

    // MARK: Thumbnail URL (uses apiKey query param so AsyncImage works without custom headers)

    func thumbnailURL(assetId: String) -> URL? {
        URL(string: "\(baseURL)/api/assets/\(assetId)/thumbnail?size=preview&apiKey=\(apiKey)")
    }
}

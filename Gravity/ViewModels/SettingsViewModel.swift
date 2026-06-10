import SwiftUI

enum StorageBackend: String, CaseIterable, Identifiable {
    case local = "local"
    case photos = "photos"
    case immich = "immich"
    case photosAndImmich = "photosAndImmich"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .local: return "On-Device Only"
        case .photos: return "Photos Library (iCloud)"
        case .immich: return "Immich Server"
        case .photosAndImmich: return "Photos Library + Immich"
        }
    }

    var description: String {
        switch self {
        case .local: return "Photos stored only on this iPhone."
        case .photos: return "Saved to Photos app. Syncs via iCloud Photos — no server needed."
        case .immich: return "Photos synced to your self-hosted Immich server (Unraid, etc.)."
        case .photosAndImmich: return "Saved to Photos + backed up to Immich."
        }
    }

    var requiresImmich: Bool { self == .immich || self == .photosAndImmich }
}

enum ConnectionState: Equatable {
    case untested, testing, success, failure(String)
}

@MainActor
class SettingsViewModel: ObservableObject {
    @AppStorage("storageBackend") var storageBackendRaw: String = StorageBackend.local.rawValue
    @AppStorage("immichBaseURL") var immichBaseURL = ""
    @AppStorage("immichAPIKey") var immichAPIKey = ""
    @AppStorage("ollamaBaseURL") var ollamaBaseURL = ""
    @AppStorage("ollamaModel") var ollamaModel = "llava"
    @AppStorage("useOllama") var useOllama = false

    @Published var immichTestResult: ConnectionState = .untested
    @Published var ollamaTestResult: ConnectionState = .untested

    var storageBackend: StorageBackend {
        get { StorageBackend(rawValue: storageBackendRaw) ?? .local }
        set { storageBackendRaw = newValue.rawValue }
    }

    func testImmich(service: ImmichService) async {
        immichTestResult = .testing
        do {
            try await service.ping()
            immichTestResult = .success
        } catch let e as ImmichError {
            immichTestResult = .failure(e.localizedDescription ?? "Unknown error")
        } catch {
            immichTestResult = .failure(error.localizedDescription)
        }
    }

    func testOllama() async {
        ollamaTestResult = .testing
        guard !ollamaBaseURL.isEmpty, let url = URL(string: "\(ollamaBaseURL)/api/tags") else {
            ollamaTestResult = .failure("Invalid URL")
            return
        }
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                ollamaTestResult = .success
            } else {
                ollamaTestResult = .failure("Server returned an error")
            }
        } catch {
            ollamaTestResult = .failure(error.localizedDescription)
        }
    }
}

import SwiftUI

enum StorageBackend: String, CaseIterable, Identifiable {
    case local = "local"
    case icloud = "icloud"
    case immich = "immich"

    static let storageKey = "storageBackend"
    static let photosCopyKey = "saveCopyToPhotos"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .local:  return "On This iPhone"
        case .icloud: return "iCloud"
        case .immich: return "Your Own Server (Immich)"
        }
    }

    var description: String {
        switch self {
        case .local:  return "Nothing leaves the device. Deleting the app deletes your wardrobe."
        case .icloud: return "Your whole wardrobe syncs to every device on your Apple ID and survives reinstalls. Stays out of your Photos app."
        case .immich: return "For people who run an Immich photo server at home. Set the address below."
        }
    }

    var systemImage: String {
        switch self {
        case .local:  return "iphone"
        case .icloud: return "icloud"
        case .immich: return "server.rack"
        }
    }

    var requiresImmich: Bool { self == .immich }
    var usesICloud: Bool { self == .icloud }

    /// Tolerates raw values from the earlier scheme where Photos was itself a backend.
    static func resolve(_ raw: String?) -> StorageBackend {
        switch raw {
        case "photos":          return .local
        case "photosAndImmich": return .immich
        default:                return StorageBackend(rawValue: raw ?? "") ?? .local
        }
    }

    static var current: StorageBackend {
        resolve(UserDefaults.standard.string(forKey: storageKey))
    }

    static var saveCopyToPhotos: Bool {
        UserDefaults.standard.bool(forKey: photosCopyKey)
    }

    /// One-time rewrite of the old "photos" / "photosAndImmich" values into the
    /// new backend + "also save to Photos" toggle. Safe to call every launch.
    static func migrateLegacyDefaults() {
        let defaults = UserDefaults.standard
        guard let raw = defaults.string(forKey: storageKey),
              raw == "photos" || raw == "photosAndImmich" else { return }
        defaults.set(true, forKey: photosCopyKey)
        defaults.set(resolve(raw).rawValue, forKey: storageKey)
    }
}

enum ConnectionState: Equatable {
    case untested, testing, success, failure(String)
}

@MainActor
class SettingsViewModel: ObservableObject {
    @AppStorage(StorageBackend.storageKey) var storageBackendRaw: String = StorageBackend.local.rawValue
    @AppStorage(StorageBackend.photosCopyKey) var saveCopyToPhotos = false
    @AppStorage("immichBaseURL") var immichBaseURL = ""
    @AppStorage("immichAPIKey") var immichAPIKey = ""
    @AppStorage("ollamaBaseURL") var ollamaBaseURL = ""
    @AppStorage("ollamaModel") var ollamaModel = "llava"
    @AppStorage("useOllama") var useOllama = false

    @Published var immichTestResult: ConnectionState = .untested
    @Published var ollamaTestResult: ConnectionState = .untested

    var storageBackend: StorageBackend {
        get { StorageBackend.resolve(storageBackendRaw) }
        set { storageBackendRaw = newValue.rawValue }
    }

    /// True when the iCloud choice differs from what the running data store was opened with.
    var needsRestartForStorage: Bool {
        guard let active = DataStore.activeBackend else { return false }
        return active.usesICloud != storageBackend.usesICloud
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

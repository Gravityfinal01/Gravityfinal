import SwiftUI
import SwiftData

@main
struct GravityApp: App {
    @StateObject private var immichService = ImmichService()
    @StateObject private var aiService = AICategorizationService()
    @StateObject private var networkMonitor = NetworkMonitor()

    @AppStorage(WelcomeView.completedKey) private var hasCompletedWelcome = false
    @AppStorage(AppAppearance.storageKey) private var appearanceRaw = AppAppearance.system.rawValue
    @AppStorage(ThemeColor.storageKey) private var themeRaw = ThemeColor.blue.rawValue

    init() {
        StorageBackend.migrateLegacyDefaults()
    }

    private var appearance: AppAppearance { AppAppearance(rawValue: appearanceRaw) ?? .system }
    private var theme: ThemeColor { ThemeColor(rawValue: themeRaw) ?? .blue }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedWelcome {
                    // The data store is opened only after the welcome flow, so the
                    // storage choice made there (iCloud or not) applies immediately.
                    MainAppView()
                } else {
                    WelcomeView()
                }
            }
            .environmentObject(immichService)
            .environmentObject(aiService)
            .environmentObject(networkMonitor)
            .preferredColorScheme(appearance.colorScheme)
            .tint(theme.color)
            // Deprecated, but still the only modifier that redirects `Color.accentColor`,
            // which the custom pills/chips/rings use. `.tint` alone only affects controls.
            .accentColor(theme.color)
        }
    }
}

/// Owns the ModelContainer for the lifetime of the main UI.
private struct MainAppView: View {
    @StateObject private var store = DataStoreHolder()

    var body: some View {
        RootView()
            .modelContainer(store.container)
    }
}

/// Created once (StateObject), so the container is built exactly one time per app run.
@MainActor
private final class DataStoreHolder: ObservableObject {
    let container: ModelContainer = DataStore.makeContainer()
}

enum DataStore {
    /// The storage backend the current container was opened with. Settings compares
    /// against this to tell the user a restart is needed after switching iCloud on/off.
    private(set) static var activeBackend: StorageBackend?

    static func makeContainer() -> ModelContainer {
        let schema = Schema([ClothingItem.self, Outfit.self])
        let backend = StorageBackend.current
        activeBackend = backend

        let config = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: backend.usesICloud ? .automatic : .none
        )
        if let container = try? ModelContainer(for: schema, configurations: [config]) {
            return container
        }

        // iCloud unavailable (not signed in, capability missing, etc.). Open locally so
        // the app still works; sync will attach on a later launch once iCloud is available.
        activeBackend = .local
        let local = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [local])
        } catch {
            fatalError("Could not open the Gravity data store: \(error)")
        }
    }
}

import SwiftUI
import SwiftData

@main
struct GravityApp: App {
    @StateObject private var immichService = ImmichService()
    @StateObject private var aiService = AICategorizationService()
    @StateObject private var networkMonitor = NetworkMonitor()

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(for: [ClothingItem.self, Outfit.self])
                .environmentObject(immichService)
                .environmentObject(aiService)
                .environmentObject(networkMonitor)
        }
    }
}

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            WardrobeView()
                .tabItem {
                    Label("Wardrobe", systemImage: "tshirt")
                }

            AddClothingView()
                .tabItem {
                    Label("Add Item", systemImage: "plus.circle.fill")
                }

            OutfitPlannerView()
                .tabItem {
                    Label("Outfits", systemImage: "square.3.layers.3d")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

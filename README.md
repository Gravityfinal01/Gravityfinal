# Gravity — Wardrobe App

iPhone app to manage your wardrobe, plan outfits, and optionally sync photos to your self-hosted Immich server or iCloud Photos.

## Features

- **Wardrobe browser** — grid view of all clothes, filtered by category (shirt, pants, hoodie, jacket, shoes, dress, shorts, accessories)
- **AI categorization** — on-device Apple Vision auto-detects clothing type (~100ms); optional Ollama enrichment adds color, brand, and tags using a local LLM on your Unraid server
- **Outfit planner canvas** — drag, pinch-to-scale, and rotate items on a canvas to plan daily outfits; save as named outfits
- **Flexible storage** — four options selectable in Settings:
  - **On-Device Only** — photos stay on your iPhone
  - **Photos Library (iCloud)** — saved to Photos app, syncs via iCloud Photos automatically
  - **Immich Server** — syncs to your self-hosted Immich instance (Unraid, etc.)
  - **Photos + Immich** — both

## Getting Started

### Prerequisites

- Xcode 15+ on macOS
- XcodeGen: `brew install xcodegen`
- iPhone/Simulator running iOS 17+

### Setup

```bash
git clone <repo-url>
cd Gravityfinal
xcodegen generate          # creates Gravity.xcodeproj
open Gravity.xcodeproj
```

In Xcode:
1. Select your **Development Team** in Signing & Capabilities
2. Choose your iPhone or a Simulator as the run target
3. Press **Cmd+R** to build and run

### Optional: Immich (Unraid)

1. In your Immich web UI: **Account Settings → API Keys → New API Key**
2. In the app: **Settings → Photo Storage → Immich Server**
3. Enter your server URL (e.g. `http://192.168.1.100:2283`) and API key
4. Tap **Test Connection**

### Optional: Ollama AI Enrichment

Ollama must be running on your local network with a vision model installed:

```bash
# On your Unraid server or any local machine
ollama pull llava       # or: moondream (lighter), llava:13b (better)
ollama serve
```

In the app: **Settings → Local AI → Enable Ollama** and enter the server URL.

## Architecture

```
Gravity/
├── Models/           ClothingItem, Outfit (SwiftData), ClothingCategory enum
├── Services/         ImmichService, AICategorizationService, PhotoLibraryService, NetworkMonitor
├── ViewModels/       WardrobeVM, AddClothingVM, OutfitPlannerVM, SettingsVM
└── Views/
    ├── Wardrobe/     WardrobeView + ClothingGridView (@Query driven)
    ├── AddClothing/  Camera + PhotosPicker + AI result + save
    ├── OutfitPlanner/CanvasView + DraggableClothingLayer (simultaneous gestures)
    └── Settings/     Storage backend picker + Immich/Ollama config
```

**Offline-first**: Photos are always saved locally to `Documents/images/` first. Remote sync (Immich) is best-effort and retried when back on local network.

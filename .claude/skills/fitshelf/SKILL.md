---
name: fitshelf
description: Project memory for FitShelf, the owner's iOS wardrobe app (repo gravityfinal01/gravityfinal). Load whenever the conversation is about FitShelf, the wardrobe app, its features, roadmap, App Store release, product promises, or any code in this repository, so decisions already made are respected and not re-litigated.
---

# FitShelf — project memory

FitShelf is a SwiftUI iOS wardrobe app. Users photograph clothes, the background is
cut out, the type is detected on-device, and outfits are planned on a canvas.
Earlier names: "Gravity" (still in the bundle ID) and "Closetry". Don't use either
in user-facing text.

## The promises (the guiding rule)

The welcome screen promises: **no subscriptions, no in-app purchases, no ads, no
accounts or sign-ups, every update included.** Every change must keep these true.
The wording is chosen to hold whether the app is free or a one-time price.
Anything that needs servers, accounts, IAP or cloud AI is out unless the owner
explicitly changes this rule. Data stays with the user.

## Tech facts

- SwiftUI, Swift 5.9, iOS 17+, iPhone and iPad (`TARGETED_DEVICE_FAMILY 1,2`).
- XcodeGen: `project.yml` is the source of truth. `*.xcodeproj` is gitignored.
  Regenerate with `xcodegen generate`. Version and build numbers live in
  `project.yml` (`MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`) and Info.plist
  reads them from there. Bump the build number for each App Store upload.
  Current: 2.0 (build 4).
- Bundle ID `com.totowardrobe.gravity`, iCloud container `iCloud.com.totowardrobe.gravity`.
- Persistence: SwiftData with CloudKit sync. **Every stored property on a `@Model`
  must be optional or have a default**, because CloudKit requires it. Images sync
  as CloudKit assets (see `ClothingImageLoader`). Category is stored as a rawValue
  string so predicates work.
- No test target. The owner builds and runs on a Mac in Xcode. A Linux cloud
  container can't build or run the app, so say so rather than claiming it was verified.
- There is an encryption exemption in Info.plist for App Store submission.

## Code layout (`FitShelf/`)

- `Models/`: `ClothingItem`, `Outfit`, `ClothingCategory`, `CanvasItemState`,
  `AppPreferences` (theme, accent colours: blue, sky, lavender, purple, pink,
  red, yellow (softened), green, brown; wardrobe layout).
- `Services/`:
  - `ClothingVision` and `AICategorizationService`: on-device detection (see below).
  - `BackgroundRemovalService`: cutouts.
  - `UIImage+Orientation`: fixes sideways camera images.
  - `ImmichService`, `PhotoLibraryService`: storage.
  - `NetworkMonitor`.
- `ViewModels/`: AddClothing, OutfitPlanner, Settings, Wardrobe.
- `Views/`:
  - `Onboarding/WelcomeView`: the promises.
  - `Wardrobe/`: grid, card, detail, edit.
  - `AddClothing/`: camera, categorization result.
  - `OutfitPlanner/`: canvas, draggable layer, body figure, saved outfits
    gallery, `OutfitSharing`, `OutfitSnapshotRenderer`.
  - `Settings/`.
  - `Shared/`.
- Categories in code: Tops, Bottoms, Jackets, Sweaters, Shoes, Dresses,
  Accessories, Other, each with subcategory chips. (The README's older list is out of date.)

## Features shipped

- Wardrobe grid by category. A cloud icon (no text) shows sync state.
- Add Item: camera or photo, then background removal, auto-detection, and a rotate button.
- Canvas: one-finger drag, two-finger pinch and rotate anywhere, a 90° rotate
  button, and saving named outfits.
- **Storage** (Settings): On-Device Only, iCloud Photos, Immich (self-hosted, on
  the owner's Unraid server, URL plus API key with Test Connection), or Photos +
  Immich. A local copy is always kept so the app works offline.
- **2.0**:
  - Upright cutouts, and photos and outfit snapshots synced via iCloud.
  - Outfit gallery with a detail view, Share, Edit on Canvas, Rename and Delete.
  - A 1080×1350 share card with the outfit name and "Made with FitShelf",
    shared through the system share sheet.
- **Detection (build 4)**:
  - The cutout is cropped to its visible pixels (8% padding) and placed on
    white at 512px before Vision sees it.
  - Labels are scored by confidence over Vision's top 30, with whole-word
    keyword matching. Specific matches beat broad ones.
  - Local dominant colour is mapped to 22 names ("Navy Hoodie").
  - The app learns from the user's corrections. This data is stored on device only.
- Ollama (optional, local LLM) can add colour, brand and tags for self-hosters.
- Settings: theme, accent colours, layout, and a feedback link (Tally form
  `https://tally.so/r/9qL6xE`).

## Decisions already made (don't reopen without the owner)

- **AI stays fully on-device. No cloud AI, no API keys** (a "bring your own key"
  idea was considered and dropped). Ollama stays for self-hosters, possibly moved
  under a collapsed "Advanced" section.
- **No social features.** They need accounts and servers.
- **Donations are not in the app.** The link lives only on Discord and the Notion
  support page, so "No in-app purchases" stays true.
- A one-time price is planned for later. It's free for now.

## Roadmap

- **2.0 to do:** set `AppLinks.appStoreURL` in `OutfitSharing.swift` once the App
  Store page exists, so shares include a download link.
- **2.1:**
  - A Support section at the bottom of Settings: a Discord invite, a separate
    "Report a bug" Tally form, and the existing suggestion link moved there.
  - Detection candidates: Apple's on-device foundation models (if they accept
    images), or a bundled Core ML clothing classifier trained with Create ML on
    a licensed dataset.
- **Later (UX polish):**
  - Restyle with the slate / mint / galaxy-blue palette from the store screenshots.
  - Faster Add Item flow and batch adding.
  - Canvas snapping guides, undo/redo and backgrounds.
  - Haptics and small animations.
  - Empty states and first-run hints.
  - An accessibility pass (Dynamic Type, VoiceOver, contrast).
  - An iPad landscape and Split View layout.
  - "Human mode" (body-model view, currently "Coming soon").

## Open items

- Before 1.0 ships: deploy the CloudKit schema to production (CloudKit Console >
  `iCloud.com.totowardrobe.gravity` > Deploy Schema Changes) after one simulator
  run signed into iCloud.
- Seller name shows the owner's legal name (Individual account). Hiding it needs an
  LLC (e.g. "TotodoApps LLC"), a D-U-N-S number and an account conversion. Ask Apple
  Support first.
- The store screenshots are illustrated mockups. Replace them with real ones if
  App Review flags guideline 2.3.3.
- Repo cleanup, when the owner approves: remove "Claude" from early commit
  authors and rename the branch to `main`.

## Working with the owner

- Keep user-facing copy short, plain and honest. It must match the promises.
- `ROADMAP.md` is the living plan. Update it when a decision is made or something ships.
- Commit messages: a short imperative title with a few bullet points of why.

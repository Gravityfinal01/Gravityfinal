# FitShelf roadmap

Notes for upcoming releases. Nothing here is built yet.

## 2.0 — Fixes and outfit sharing (built, ready to ship)

- Upright cutouts (camera rotation fix) and a rotate button on Add Item and Edit Item.
- Canvas: one-finger drag, two-finger pinch and rotate anywhere, 90° rotate button.
- Photos and outfit snapshots sync through iCloud.
- New outfit gallery: bigger cards, detail view, Share, Edit on Canvas, Rename, Delete.
- Share card (1080 x 1350) with outfit name and "Made with FitShelf", shared through
  the system share sheet. Also a Share button on the canvas.
- To do: set `AppLinks.appStoreURL` in `OutfitSharing.swift` once the App Store page
  exists, so shares include a download link.

## 2.1 — Support section and smarter AI

### Support section (bottom of Settings)
- Discord invite link.
- "Report a bug" form (a second Tally form, separate from suggestions).
- Existing "Share a suggestion" link moves here.
- **Donations:** decided, not in the app. The donation link lives on the
  Discord server and the Notion support page only. This keeps the app free of
  In-App Purchase and keeps the "No in-app purchases" promise true.

### AI detection (decided)

No cloud AI and no API keys: too complicated for a wardrobe app. Detection stays
fully on-device. Ollama stays as it is today for self-hosters; consider moving it
under a collapsed "Advanced" section.

Shipped in 2.0 (build 4):
- Cutout cropped to the garment and placed on white before classifying.
- Confidence-weighted scoring over Vision's top 30 labels, whole-word matching.
- Local colour detection, so names read "Black T-Shirt" without Ollama.
- Learns from the user's own corrections (stored on device).

Next candidates:
- Apple's on-device foundation models, if they accept images in the current SDK.
- A bundled Core ML clothing classifier (trained with Create ML on a licensed
  clothing dataset) for much better type detection.

## Later — A better, cleaner experience

Social features are off the table: they would need accounts and servers and
break the app's promises (no accounts, no servers, data stays with the user).
Later updates focus on making FitShelf the nicest wardrobe app to use.

Guiding rule: every change must keep the promises on the welcome screen true.

Ideas to explore:
- Restyle with the slate / mint / galaxy-blue palette from the store screenshots.
- Smoother Add Item flow: fewer taps from photo to saved, batch adding several
  pieces in one go.
- Canvas polish: snapping guides, undo/redo, background choices for outfits.
- Haptics and small animations on save, rotate and share.
- Better empty states and first-run hints in each tab.
- Accessibility pass: Dynamic Type, VoiceOver labels, contrast in every theme.
- iPad layout tuned for landscape and Split View.
- Human mode (body-model view), currently "Coming soon".

## Other open items

- **Before releasing 1.0:** deploy the CloudKit schema to production
  (CloudKit Console > `iCloud.com.totowardrobe.gravity` > Deploy Schema
  Changes), after running a simulator build signed into iCloud once.
- **Seller name:** shows the legal name on an Individual account. Hiding it
  needs an LLC (e.g. TotodoApps LLC), a D-U-N-S number and an account
  conversion. Ask Apple Support what the developer/seller name shows after
  conversion before starting.
- **One-time price:** planned later; see the publishing guide, section 6.1.
- **Store screenshots:** currently illustrated mockups; replace with real
  screenshots (neutral items) if App Review flags guideline 2.3.3.
- **Repo:** remove "Claude" from early commit authors and rename the branch to
  `main`, when approved.

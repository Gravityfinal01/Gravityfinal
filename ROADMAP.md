# FitShelf roadmap

Notes for upcoming releases. Nothing here is built yet.

## 1.1 — Share outfits (next update, top priority)

Goal: let people show off outfits and bring in new downloads.

- **Outfit gallery.** Replace the current Saved Outfits sheet with a proper
  gallery: larger cards, a full-screen outfit view, rename, duplicate, delete,
  sort by newest.
- **Share button.** On each outfit, share a rendered image through the system
  share sheet (Messages, WhatsApp, Instagram Stories, AirDrop, Save Image).
  - Reuse `OutfitSnapshotRenderer`; render a clean "share card" version:
    outfit on a soft background, outfit name, small FitShelf logo and
    "Made with FitShelf" plus the App Store link once the app is live.
  - SwiftUI `ShareLink` with a `Transferable` image is enough; no server needed.
- **Privacy:** sharing is user-initiated and sends nothing to us, so the
  "Data Not Collected" label stays accurate.
- **Store:** update screenshots and What's New to show sharing.

## 1.2 — Support section and smarter AI

### Support section (bottom of Settings)
- Discord invite link.
- "Report a bug" form (a second Tally form, separate from suggestions).
- Existing "Share a suggestion" link moves here.
- **Donations:** decided, not in the app. The donation link lives on the
  Discord server and the Notion support page only. This keeps the app free of
  In-App Purchase and keeps the "No in-app purchases" promise true.

### Better AI detection, as an option
Keep Apple Vision as the default, add opt-in stronger detectors:
- **Apple on-device foundation models** (Apple Intelligence devices). Fits the
  "AI that never leaves home" promise. Check whether the current SDK accepts
  image input before committing to it.
- **MCP support:** let the user point FitShelf at their own MCP server or
  model endpoint, the same way Ollama works today (user-entered address,
  off by default). Makes room for whatever model they prefer.
- If any option ever sends photos to a third-party cloud service, the App
  Privacy label, privacy policy and welcome screen copy must all change, and
  the user must opt in explicitly.

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

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
- **Donations, careful:** Apple requires tips for an app to go through
  In-App Purchase (guideline 3.1.1). An external Ko-fi/PayPal/Buy Me a Coffee
  link inside the app is likely to be rejected. Options: a consumable
  "Tip jar" IAP (needs the Paid Apps Agreement, banking and tax first), or
  leave donations out of the app and link them only from the support website.
  Also note the welcome screen promises "No in-app purchases": a tip jar
  conflicts with that wording, so the copy would need to change first.

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

## Later — Social

A space to browse outfits other users chose to share. Big change, plan it
on its own:
- Needs a server, accounts and storage: breaks the current "no accounts,
  no servers" promise, so the welcome copy, privacy policy and privacy label
  all change.
- Apple guideline 1.2 for user-generated content requires: content filtering,
  a way to report posts, a way to block users, and published contact info.
- Moderation effort and hosting cost are ongoing.
- Lighter first step: public share links (1.1) plus a hashtag/Discord
  channel, to see if people actually want a feed before building one.

## Other open items

- **Before releasing 1.0:** deploy the CloudKit schema to production
  (CloudKit Console > `iCloud.com.totowardrobe.gravity` > Deploy Schema
  Changes), after running a simulator build signed into iCloud once.
- **Seller name:** shows the legal name on an Individual account. Hiding it
  needs an LLC (e.g. TotodoApps LLC), a D-U-N-S number and an account
  conversion. Ask Apple Support what the developer/seller name shows after
  conversion before starting.
- **One-time price:** planned later; see the publishing guide, section 6.1.
- **Human mode:** body-model outfit view, currently "Coming soon".
- **App palette:** optional restyle with the slate / mint / galaxy-blue palette
  used in the store screenshots.
- **Store screenshots:** currently illustrated mockups; replace with real
  screenshots (neutral items) if App Review flags guideline 2.3.3.
- **Repo:** remove "Claude" from early commit authors and rename the branch to
  `main`, when approved.

import SwiftUI

/// First-launch welcome flow (3 pages). Every claim here is checked against what
/// the app actually does; keep them in sync if storage or AI behaviour changes.
///
/// Branding: add an image set named `WelcomeLogo` to Assets.xcassets and it
/// replaces the placeholder icon on the first page. No code change needed.
struct WelcomeView: View {
    static let completedKey = "hasCompletedWelcome"
    static let logoAssetName = "WelcomeLogo"

    @AppStorage(WelcomeView.completedKey) private var hasCompletedWelcome = false
    @AppStorage("storageBackend") private var storageBackendRaw = StorageBackend.local.rawValue
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private let pageCount = 3

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if page < pageCount - 1 {
                    Button("Skip") { finish() }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 20)
                        .padding(.top, 12)
                }
            }
            .frame(height: 44)

            TabView(selection: $page) {
                welcomePage.tag(0)
                storagePage.tag(1)
                aiPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)

            VStack(spacing: 18) {
                HStack(spacing: 7) {
                    ForEach(0..<pageCount, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Color.accentColor : Color(.systemGray4))
                            .frame(width: i == page ? 20 : 7, height: 7)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: page)
                    }
                }

                Button {
                    if page < pageCount - 1 {
                        page += 1
                    } else {
                        finish()
                    }
                } label: {
                    Text(page < pageCount - 1 ? "Continue" : "Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 28)
        }
        .background(Color(.systemBackground))
        .interactiveDismissDisabled()
    }

    private func finish() {
        hasCompletedWelcome = true
        dismiss()
    }

    // MARK: - Page 1: welcome + free forever

    private var welcomePage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                logo
                    .padding(.top, 8)

                VStack(spacing: 6) {
                    Text("Thanks for downloading.")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    Text("Snap a photo of anything you own. The background is cut out, the type is sorted for you, and you can build outfits on a canvas so a good combination is never forgotten.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Free. Forever.")
                        .font(.headline)
                    BulletRow(symbol: "xmark.circle.fill", text: "No subscriptions, ever.")
                    BulletRow(symbol: "xmark.circle.fill", text: "No in-app purchases.")
                    BulletRow(symbol: "xmark.circle.fill", text: "No accounts or sign-ups.")
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 16)
        }
    }

    /// Custom graphic if `WelcomeLogo` exists in the asset catalog, else a placeholder.
    @ViewBuilder
    private var logo: some View {
        if let image = UIImage(named: Self.logoAssetName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: 140)
        } else {
            Image(systemName: "tshirt.fill")
                .font(.system(size: 54, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .frame(width: 110, height: 110)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(Circle())
        }
    }

    // MARK: - Page 2: storage

    private var storagePage: some View {
        PageScaffold(
            symbol: "lock.shield.fill",
            title: "Your photos stay yours",
            subtitle: "There are no company servers. Pick where your photos live."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(spacing: 10) {
                    storageOption(.local,
                                  symbol: "iphone",
                                  detail: "Only on this iPhone. Nothing leaves the device.")
                    storageOption(.photos,
                                  symbol: "photo.on.rectangle.angled",
                                  detail: "Saved to your Photos app and synced through your own iCloud.")
                    storageOption(.immich,
                                  symbol: "server.rack",
                                  detail: "Backed up to an Immich server you run at home. Set the address in Settings.")
                }

                Text("A copy always stays on your iPhone so the app works offline. You can change this any time in Settings.")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Page 3: local AI

    private var aiPage: some View {
        PageScaffold(
            symbol: "cpu.fill",
            title: "AI that never leaves home",
            subtitle: "Nothing is sent to us or anyone else."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                BulletRow(symbol: "scissors",
                          text: "Background removal and categorization run on your iPhone using Apple's on-device Vision.")
                BulletRow(symbol: "house.fill",
                          text: "Optionally connect Ollama on a computer in your home for richer colors and tags. It only talks to the address you enter.")
                BulletRow(symbol: "eye.slash.fill",
                          text: "No analytics, no tracking, no cloud AI. Your photos are never uploaded anywhere you didn't choose.")

                Text("Storage, AI, light or dark mode, and how the wardrobe is laid out all live in Settings.")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Storage option row

    private func storageOption(_ backend: StorageBackend, symbol: String, detail: String) -> some View {
        let selected = storageBackendRaw == backend.rawValue
        return Button {
            storageBackendRaw = backend.rawValue
        } label: {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(selected ? Color.white : Color.accentColor)
                    .frame(width: 36, height: 36)
                    .background(selected ? Color.accentColor : Color.accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(backend.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Color.accentColor : Color(.systemGray3))
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(selected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Building blocks

private struct PageScaffold<Content: View>: View {
    let symbol: String
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                Image(systemName: symbol)
                    .font(.system(size: 54, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 110, height: 110)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(Circle())
                    .padding(.top, 8)

                VStack(spacing: 6) {
                    Text(title)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                content
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 16)
        }
    }
}

private struct BulletRow: View {
    let symbol: String
    let text: String
    var tint: Color = .accentColor

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .frame(width: 22)
                .padding(.top, 2)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

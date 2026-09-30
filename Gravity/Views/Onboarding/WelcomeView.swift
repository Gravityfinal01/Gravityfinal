import SwiftUI

/// First-launch welcome flow. Every claim here is checked against what the app
/// actually does; keep them in sync if storage or AI behaviour changes.
struct WelcomeView: View {
    static let completedKey = "hasCompletedWelcome"

    @AppStorage(WelcomeView.completedKey) private var hasCompletedWelcome = false
    @AppStorage("storageBackend") private var storageBackendRaw = StorageBackend.local.rawValue
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private let pageCount = 5

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
                freePage.tag(1)
                storagePage.tag(2)
                aiPage.tag(3)
                tourPage.tag(4)
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

    // MARK: - Pages

    private var welcomePage: some View {
        PageScaffold(
            symbol: "tshirt.fill",
            title: "Welcome to Gravity",
            subtitle: "Thanks for downloading Gravity."
        ) {
            Text("Snap a photo of anything you own. Gravity cuts out the background, sorts it by type, and lets you build outfits on a canvas so you never forget a good combination again.")
        }
    }

    private var freePage: some View {
        PageScaffold(
            symbol: "gift.fill",
            title: "Free. Forever.",
            subtitle: "No catch, no upsell."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                BulletRow(symbol: "xmark.circle.fill", text: "No subscriptions, ever.")
                BulletRow(symbol: "xmark.circle.fill", text: "No in-app purchases.")
                BulletRow(symbol: "xmark.circle.fill", text: "No accounts or sign-ups.")
                BulletRow(symbol: "checkmark.circle.fill", text: "Every feature is available to everyone, from day one.", tint: .green)
            }
        }
    }

    private var storagePage: some View {
        PageScaffold(
            symbol: "lock.shield.fill",
            title: "Your photos stay yours",
            subtitle: "Gravity has no servers of its own."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Pick where your clothing photos live. You can change this any time in Settings.")
                    .foregroundStyle(.secondary)

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

                Text("Whichever you choose, a copy is kept on your iPhone so the app works offline.")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
    }

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
                          text: "Optionally connect Ollama on a computer in your home for richer colors and tags. It only ever talks to the address you enter.")
                BulletRow(symbol: "eye.slash.fill",
                          text: "No analytics, no tracking, no cloud AI. Your photos are never uploaded to Gravity or any third party.")
            }
        }
    }

    private var tourPage: some View {
        PageScaffold(
            symbol: "map.fill",
            title: "Where things live",
            subtitle: "A quick tour of the tabs."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                TourRow(symbol: "tshirt", title: "Wardrobe",
                        text: "Everything you own, filtered by type. Tap an item to see it large, long-press to edit.")
                TourRow(symbol: "plus.circle.fill", title: "Add Item",
                        text: "Camera or library. The background is removed and the type is guessed for you.")
                TourRow(symbol: "square.3.layers.3d", title: "Outfits",
                        text: "Drag pieces onto a canvas, then save the look so you can find it again.")
                TourRow(symbol: "gear", title: "Settings",
                        text: "Storage, local AI, light or dark mode, and how the wardrobe is laid out.")
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
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text(subtitle)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
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

private struct TourRow: View {
    let symbol: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 30)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

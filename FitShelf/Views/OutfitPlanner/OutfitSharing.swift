import SwiftUI

enum AppLinks {
    /// Public App Store page, appended to shared outfits. Fill in the numeric Apple ID from
    /// App Store Connect > App Information, e.g. "https://apps.apple.com/app/id1234567890".
    /// Left nil, shares go out without a link.
    static let appStoreURL: URL? = nil
}

/// Renders an outfit snapshot into a 1080 x 1350 portrait card (Instagram feed/Stories friendly).
@MainActor
enum OutfitShareCard {
    static let size = CGSize(width: 1080, height: 1350)

    static func render(name: String, snapshot: UIImage) -> UIImage? {
        let renderer = ImageRenderer(content: OutfitShareCardView(name: name, snapshot: snapshot))
        renderer.scale = 1
        return renderer.uiImage
    }

    static func message(for name: String) -> String {
        var text = "My outfit \u{201C}\(name)\u{201D}, made with FitShelf."
        if let url = AppLinks.appStoreURL { text += " \(url.absoluteString)" }
        return text
    }
}

private struct OutfitShareCardView: View {
    let name: String
    let snapshot: UIImage

    var body: some View {
        VStack(spacing: 34) {
            Image(uiImage: snapshot)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 940, maxHeight: 1000)
                .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 30, y: 14)

            Text(name)
                .font(.system(size: 66, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.85))
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                if let logo = UIImage(named: "ShareLogo") {
                    Image(uiImage: logo)
                        .resizable()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                Text("Made with FitShelf")
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.55))
            }
        }
        .padding(70)
        .frame(width: OutfitShareCard.size.width, height: OutfitShareCard.size.height)
        .background(
            LinearGradient(
                colors: [Color(red: 0.93, green: 0.91, blue: 0.98), Color(red: 0.87, green: 0.95, blue: 0.90)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .environment(\.colorScheme, .light)
    }
}

/// Preview of the share card with a single Share button (Messages, Instagram, AirDrop, Save Image...).
struct ShareOutfitSheet: View {
    let name: String
    let makeSnapshot: @MainActor () async -> UIImage?

    @Environment(\.dismiss) private var dismiss
    @State private var card: UIImage?
    @State private var failed = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer(minLength: 0)
                if let card {
                    Image(uiImage: card)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.15), radius: 14, y: 6)
                        .padding(.horizontal, 28)

                    ShareLink(
                        item: Image(uiImage: card),
                        subject: Text(name),
                        message: Text(OutfitShareCard.message(for: name)),
                        preview: SharePreview(name, image: Image(uiImage: card))
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 28)
                } else if failed {
                    ContentUnavailableView("Couldn't make the image", systemImage: "exclamationmark.triangle",
                                           description: Text("Try adding the pieces to the canvas again."))
                } else {
                    ProgressView("Preparing your outfit\u{2026}")
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 20)
            .navigationTitle("Share Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                guard card == nil else { return }
                if let snapshot = await makeSnapshot(), let rendered = OutfitShareCard.render(name: name, snapshot: snapshot) {
                    card = rendered
                } else {
                    failed = true
                }
            }
        }
    }
}

import SwiftUI

/// Renders the current canvas arrangement to a UIImage for the saved-outfits grid.
/// Rebuilds the layout from item states (same geometry as DraggableClothingLayer)
/// rather than screenshotting the live view, so it works while a sheet is up.
@MainActor
enum OutfitSnapshotRenderer {
    static let itemSize = CGSize(width: 120, height: 150)

    static func render(entries: [(item: ClothingItem, state: CanvasItemState)], canvasSize: CGSize) async -> UIImage? {
        guard !entries.isEmpty else { return nil }

        var images: [UUID: UIImage] = [:]
        for entry in entries {
            if let img = await ClothingImageLoader.load(entry.item, targetSize: CGSize(width: 600, height: 600)) {
                images[entry.item.id] = img
            }
        }

        let sorted = entries.sorted { $0.state.zIndex < $1.state.zIndex }
        let size = CGSize(width: max(canvasSize.width, 200), height: max(canvasSize.height, 200))

        let content = ZStack {
            Color(.systemGray6)
            ForEach(sorted, id: \.item.id) { entry in
                if let img = images[entry.item.id] {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: itemSize.width, height: itemSize.height)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .scaleEffect(CGFloat(entry.state.scale))
                        .rotationEffect(Angle(radians: entry.state.rotation))
                        .offset(x: CGFloat(entry.state.offsetX), y: CGFloat(entry.state.offsetY))
                }
            }
        }
        .frame(width: size.width, height: size.height)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        return renderer.uiImage
    }
}

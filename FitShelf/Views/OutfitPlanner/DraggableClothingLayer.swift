import SwiftUI

/// One piece on the outfit canvas. Handles one-finger drag and tap-to-select.
/// Two-finger pinch and rotate live on CanvasView so they work anywhere on the canvas,
/// not only when both fingers land on this (small) view.
///
/// Every change is written back through `onUpdate` while the gesture runs, so nothing
/// depends on `onEnded` firing. (SwiftUI can cancel a gesture without calling it, which
/// is what made rotations snap back before.)
struct DraggableClothingLayer: View {
    let item: ClothingItem
    let state: CanvasItemState
    let isSelected: Bool
    let onUpdate: (CanvasItemState) -> Void
    let onSelect: () -> Void
    let onRotateQuarter: () -> Void
    let onBringToFront: () -> Void
    let onSendToBack: () -> Void
    let onRemove: () -> Void

    /// Item state when the current drag began. Cleared when the gesture ends or is cancelled.
    @State private var dragStart: CanvasItemState?
    @GestureState private var isDragging = false

    static let itemSize = CGSize(width: 120, height: 150)

    var body: some View {
        ItemImageView(item: item, size: Self.itemSize)
            .frame(width: Self.itemSize.width, height: Self.itemSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .padding(-4)
                }
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Button(action: onRotateQuarter) {
                        Image(systemName: "rotate.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Rotate 90 degrees")
                    .offset(x: 14, y: -14)
                    // Keep the button readable at any size the item is pinched to.
                    .scaleEffect(1 / max(CGFloat(state.scale), 0.4))
                }
            }
            .scaleEffect(CGFloat(state.scale))
            .rotationEffect(Angle(radians: state.rotation))
            .offset(x: CGFloat(state.offsetX), y: CGFloat(state.offsetY))
            .zIndex(Double(state.zIndex))
            .gesture(dragGesture)
            .onTapGesture { onSelect() }
            .onChange(of: isDragging) { _, active in
                if !active { dragStart = nil }
            }
            .contextMenu {
                Button(action: onRotateQuarter) {
                    Label("Rotate 90°", systemImage: "rotate.right")
                }
                Button(action: onBringToFront) {
                    Label("Bring to Front", systemImage: "square.3.layers.3d.top.filled")
                }
                Button(action: onSendToBack) {
                    Label("Send to Back", systemImage: "square.3.layers.3d.bottom.filled")
                }
                Divider()
                Button(role: .destructive, action: onRemove) {
                    Label("Remove from Canvas", systemImage: "xmark.circle")
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .updating($isDragging) { _, active, _ in active = true }
            .onChanged { value in
                if dragStart == nil {
                    dragStart = state
                    onSelect()
                }
                guard let start = dragStart else { return }
                var s = state
                s.offsetX = start.offsetX + Double(value.translation.width)
                s.offsetY = start.offsetY + Double(value.translation.height)
                onUpdate(s)
            }
            .onEnded { _ in dragStart = nil }
    }
}

import SwiftUI

struct DraggableClothingLayer: View {
    let item: ClothingItem
    let state: CanvasItemState
    let canvasSize: CGSize
    let onUpdate: (CanvasItemState) -> Void
    let onBringToFront: () -> Void
    let onSendToBack: () -> Void
    let onRemove: () -> Void

    // Live gesture deltas — reset to identity when gesture ends
    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var scaleAmount: CGFloat = 1.0
    @GestureState private var rotationAmount: Angle = .zero

    private let itemWidth: CGFloat = 120
    private let itemHeight: CGFloat = 150

    var body: some View {
        ItemImageView(item: item, size: CGSize(width: itemWidth, height: itemHeight))
            .frame(width: itemWidth, height: itemHeight)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            // Apply committed state + live gesture deltas
            .scaleEffect(CGFloat(state.scale) * scaleAmount)
            .rotationEffect(Angle(radians: state.rotation) + rotationAmount)
            .offset(
                x: CGFloat(state.offsetX) + dragOffset.width,
                y: CGFloat(state.offsetY) + dragOffset.height
            )
            .zIndex(Double(state.zIndex))
            .simultaneousGesture(dragGesture)
            .simultaneousGesture(magnifyGesture)
            .simultaneousGesture(rotateGesture)
            .onTapGesture { onBringToFront() }
            .contextMenu {
                Button { onBringToFront() } label: {
                    Label("Bring to Front", systemImage: "square.3.layers.3d.top.filled")
                }
                Button { onSendToBack() } label: {
                    Label("Send to Back", systemImage: "square.3.layers.3d.bottom.filled")
                }
                Divider()
                Button(role: .destructive) { onRemove() } label: {
                    Label("Remove from Canvas", systemImage: "xmark.circle")
                }
            }
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                var s = state
                s.offsetX += Double(value.translation.width)
                s.offsetY += Double(value.translation.height)
                onUpdate(s)
            }
    }

    private var magnifyGesture: some Gesture {
        MagnificationGesture()
            .updating($scaleAmount) { value, state, _ in
                state = value
            }
            .onEnded { value in
                var s = state
                s.scale = max(0.2, min(3.0, s.scale * Double(value)))
                onUpdate(s)
            }
    }

    private var rotateGesture: some Gesture {
        RotationGesture()
            .updating($rotationAmount) { value, state, _ in
                state = value
            }
            .onEnded { value in
                var s = state
                s.rotation += value.radians
                onUpdate(s)
            }
    }
}

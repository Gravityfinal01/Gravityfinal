import SwiftUI

struct CanvasView: View {
    @ObservedObject var vm: OutfitPlannerViewModel

    /// Selected item's state when the current pinch/rotate began.
    @State private var pinchStart: CanvasItemState?
    @GestureState private var isPinching = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                CheckerboardBackground()
                    .ignoresSafeArea(edges: .top)
                    .contentShape(Rectangle())
                    .onTapGesture { vm.selectedItemId = nil }

                ForEach(vm.sortedEntries, id: \.item.id) { entry in
                    DraggableClothingLayer(
                        item: entry.item,
                        state: entry.state,
                        isSelected: vm.selectedItemId == entry.item.id,
                        onUpdate: { newState in
                            vm.updateState(for: entry.item.id, state: newState)
                        },
                        onSelect: {
                            vm.selectedItemId = entry.item.id
                            vm.bringToFront(entry.item.id)
                        },
                        onRotateQuarter: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                vm.rotateQuarterTurn(entry.item.id)
                            }
                        },
                        onBringToFront: { vm.bringToFront(entry.item.id) },
                        onSendToBack: { vm.sendToBack(entry.item.id) },
                        onRemove: { vm.removeItem(entry.item.id) }
                    )
                }

                if vm.canvasEntries.isEmpty {
                    emptyCanvasHint
                }
            }
        }
        .clipShape(Rectangle())
        .simultaneousGesture(pinchRotateGesture)
        .onChange(of: isPinching) { _, active in
            if !active { pinchStart = nil }
        }
    }

    /// Two fingers anywhere on the canvas resize and rotate the selected piece
    /// (or the front-most one if nothing is selected).
    private var pinchRotateGesture: some Gesture {
        MagnifyGesture()
            .simultaneously(with: RotateGesture())
            .updating($isPinching) { _, active, _ in active = true }
            .onChanged { value in
                guard let id = vm.selectedItemId ?? vm.sortedEntries.last?.item.id,
                      let current = vm.state(for: id) else { return }
                if pinchStart == nil {
                    pinchStart = current
                    vm.selectedItemId = id
                }
                guard let start = pinchStart else { return }
                var s = current
                if let magnification = value.first?.magnification {
                    s.scale = min(3.0, max(0.3, start.scale * Double(magnification)))
                }
                if let rotation = value.second?.rotation {
                    s.rotation = start.rotation + rotation.radians
                }
                vm.updateState(for: id, state: s)
            }
            .onEnded { _ in pinchStart = nil }
    }

    private var emptyCanvasHint: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.draw")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("Tap items below to add them.\nDrag to move. Use two fingers to resize and rotate.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

private struct CheckerboardBackground: View {
    var body: some View {
        Canvas { ctx, size in
            let tile: CGFloat = 20
            var x: CGFloat = 0
            while x < size.width {
                var y: CGFloat = 0
                while y < size.height {
                    let isEven = (Int(x / tile) + Int(y / tile)) % 2 == 0
                    ctx.fill(
                        Path(CGRect(x: x, y: y, width: tile, height: tile)),
                        with: .color(isEven ? Color(.systemGray6) : Color(.systemGray5))
                    )
                    y += tile
                }
                x += tile
            }
        }
    }
}

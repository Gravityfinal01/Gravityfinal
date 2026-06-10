import SwiftUI

struct CanvasView: View {
    @ObservedObject var vm: OutfitPlannerViewModel

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Canvas background
                Color(.systemGray6)
                    .ignoresSafeArea(edges: .top)

                // Grid lines for visual reference
                canvasGrid

                // Clothing layers sorted by zIndex
                ForEach(vm.sortedEntries, id: \.item.id) { entry in
                    DraggableClothingLayer(
                        item: entry.item,
                        state: entry.state,
                        canvasSize: geo.size,
                        onUpdate: { newState in
                            vm.updateState(for: entry.item.id, state: newState)
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
    }

    private var canvasGrid: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 40
            var path = Path()
            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += spacing
            }
            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }
            ctx.stroke(path, with: .color(.secondary.opacity(0.15)), lineWidth: 0.5)
        }
    }

    private var emptyCanvasHint: some View {
        VStack(spacing: 8) {
            Image(systemName: "hand.tap")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("Tap items below to add them to the canvas")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

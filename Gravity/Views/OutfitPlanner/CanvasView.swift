import SwiftUI

struct CanvasView: View {
    @ObservedObject var vm: OutfitPlannerViewModel

    var body: some View {
        GeometryReader { geo in
            ZStack {
                CheckerboardBackground()
                    .ignoresSafeArea(edges: .top)

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

    private var emptyCanvasHint: some View {
        VStack(spacing: 12) {
            Image(systemName: "tshirt")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("Tap items below or use\nSuggest to build an outfit")
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

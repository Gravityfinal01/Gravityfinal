import SwiftUI

/// Subtle two-tone checkerboard used behind transparent clothing cutouts.
struct Checkerboard: View {
    var tile: CGFloat = 14
    var light: Color = Color(.systemGray6)
    var dark: Color = Color(.systemGray5)

    var body: some View {
        Canvas { ctx, size in
            var x: CGFloat = 0
            while x < size.width {
                var y: CGFloat = 0
                while y < size.height {
                    let isEven = (Int(x / tile) + Int(y / tile)) % 2 == 0
                    ctx.fill(
                        Path(CGRect(x: x, y: y, width: tile, height: tile)),
                        with: .color(isEven ? light : dark)
                    )
                    y += tile
                }
                x += tile
            }
        }
    }
}

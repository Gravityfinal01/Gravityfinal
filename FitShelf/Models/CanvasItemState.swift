import Foundation

struct CanvasItemState: Codable {
    var offsetX: Double
    var offsetY: Double
    var scale: Double
    var rotation: Double
    var zIndex: Int

    init(offsetX: Double = 0, offsetY: Double = 0,
         scale: Double = 1.0, rotation: Double = 0, zIndex: Int = 0) {
        self.offsetX = offsetX
        self.offsetY = offsetY
        self.scale = scale
        self.rotation = rotation
        self.zIndex = zIndex
    }
}

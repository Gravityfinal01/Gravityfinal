import SwiftUI

// MARK: - BodyZone

enum BodyZone: String, Hashable, CaseIterable {
    case torso, fullBody, legs, feet, accessories

    func zoneRect(mx: CGFloat, my: CGFloat, fw: CGFloat, fh: CGFloat) -> CGRect {
        let ox = mx - fw / 2
        let oy = my - fh / 2
        switch self {
        case .torso:
            return CGRect(x: ox + fw * 0.21, y: oy + fh * 0.14, width: fw * 0.58, height: fh * 0.38)
        case .fullBody:
            return CGRect(x: ox + fw * 0.21, y: oy + fh * 0.14, width: fw * 0.58, height: fh * 0.74)
        case .legs:
            return CGRect(x: ox + fw * 0.11, y: oy + fh * 0.50, width: fw * 0.78, height: fh * 0.37)
        case .feet:
            return CGRect(x: ox + fw * 0.05, y: oy + fh * 0.88, width: fw * 0.90, height: fh * 0.10)
        case .accessories:
            return CGRect(x: ox + fw * 0.62, y: oy + fh * 0.14, width: fw * 0.34, height: fh * 0.13)
        }
    }

    var zIndex: Double {
        switch self {
        case .accessories:       return 4
        case .torso, .fullBody:  return 3
        case .legs:              return 2
        case .feet:              return 1
        }
    }
}

extension ClothingCategory {
    var bodyZone: BodyZone {
        switch self {
        case .shirt, .hoodie, .jacket: return .torso
        case .dress:                   return .fullBody
        case .pants, .shorts:          return .legs
        case .shoes:                   return .feet
        case .accessories, .other:     return .accessories
        }
    }
}

// MARK: - BodyFigureView

struct BodyFigureView: View {
    @ObservedObject var vm: OutfitPlannerViewModel

    var body: some View {
        GeometryReader { geo in
            let fh = min(geo.size.height * 0.88, 480.0)
            let fw = fh * 0.42
            let mx = geo.size.width / 2
            let my = geo.size.height / 2

            ZStack {
                Color(.systemGray6).ignoresSafeArea(edges: .top)

                MannequinOutline()
                    .frame(width: fw, height: fh)
                    .position(x: mx, y: my)

                ForEach(Array(vm.slots.keys).sorted(), id: \.self) { key in
                    if let item = vm.slots[key], let zone = BodyZone(rawValue: key) {
                        let rect = zone.zoneRect(mx: mx, my: my, fw: fw, fh: fh)
                        ClothingSlotView(item: item) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                vm.removeFromSlot(key)
                            }
                        }
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                        .zIndex(zone.zIndex)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                    }
                }

                if vm.slots.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "hand.tap")
                            .font(.title3)
                        Text("Tap items below\nto dress the figure")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundStyle(.tertiary)
                    .position(x: mx, y: my + fh * 0.54)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: Set(vm.slots.keys))
        }
    }
}

// MARK: - MannequinOutline

private struct MannequinOutline: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let cx = w / 2
            let lineShading = GraphicsContext.Shading.color(Color.primary.opacity(0.20))
            let fillShading = GraphicsContext.Shading.color(Color.primary.opacity(0.06))
            let lw: CGFloat = 1.5

            // HEAD
            let head = Path(ellipseIn: CGRect(x: cx - w*0.17, y: h*0.005, width: w*0.34, height: h*0.125))
            ctx.fill(head, with: fillShading)
            ctx.stroke(head, with: lineShading, lineWidth: lw)

            // NECK
            let neck = Path(roundedRect: CGRect(x: cx - w*0.065, y: h*0.125, width: w*0.13, height: h*0.05), cornerRadius: 3)
            ctx.fill(neck, with: fillShading)
            ctx.stroke(neck, with: lineShading, lineWidth: lw)

            // TORSO (wide at shoulders, curves in at waist, slight hip flare)
            var torso = Path()
            torso.move(to: CGPoint(x: cx - w*0.43, y: h*0.17))
            torso.addQuadCurve(
                to: CGPoint(x: cx - w*0.27, y: h*0.50),
                control: CGPoint(x: cx - w*0.44, y: h*0.37))
            torso.addLine(to: CGPoint(x: cx - w*0.28, y: h*0.53))
            torso.addLine(to: CGPoint(x: cx + w*0.28, y: h*0.53))
            torso.addLine(to: CGPoint(x: cx + w*0.27, y: h*0.50))
            torso.addQuadCurve(
                to: CGPoint(x: cx + w*0.43, y: h*0.17),
                control: CGPoint(x: cx + w*0.44, y: h*0.37))
            torso.closeSubpath()
            ctx.fill(torso, with: fillShading)
            ctx.stroke(torso, with: lineShading, lineWidth: lw)

            // LEFT ARM
            var lArm = Path()
            lArm.move(to: CGPoint(x: cx - w*0.43, y: h*0.17))
            lArm.addLine(to: CGPoint(x: cx - w*0.50, y: h*0.18))
            lArm.addLine(to: CGPoint(x: cx - w*0.47, y: h*0.46))
            lArm.addLine(to: CGPoint(x: cx - w*0.41, y: h*0.46))
            lArm.closeSubpath()
            ctx.fill(lArm, with: fillShading)
            ctx.stroke(lArm, with: lineShading, lineWidth: lw)

            // RIGHT ARM
            var rArm = Path()
            rArm.move(to: CGPoint(x: cx + w*0.43, y: h*0.17))
            rArm.addLine(to: CGPoint(x: cx + w*0.50, y: h*0.18))
            rArm.addLine(to: CGPoint(x: cx + w*0.47, y: h*0.46))
            rArm.addLine(to: CGPoint(x: cx + w*0.41, y: h*0.46))
            rArm.closeSubpath()
            ctx.fill(rArm, with: fillShading)
            ctx.stroke(rArm, with: lineShading, lineWidth: lw)

            // LEFT LEG
            let lLeg = Path(roundedRect: CGRect(x: cx - w*0.40, y: h*0.53, width: w*0.34, height: h*0.35), cornerRadius: 10)
            ctx.fill(lLeg, with: fillShading)
            ctx.stroke(lLeg, with: lineShading, lineWidth: lw)

            // RIGHT LEG
            let rLeg = Path(roundedRect: CGRect(x: cx + w*0.06, y: h*0.53, width: w*0.34, height: h*0.35), cornerRadius: 10)
            ctx.fill(rLeg, with: fillShading)
            ctx.stroke(rLeg, with: lineShading, lineWidth: lw)

            // LEFT FOOT
            let lFoot = Path(roundedRect: CGRect(x: cx - w*0.44, y: h*0.88, width: w*0.38, height: h*0.10), cornerRadius: 5)
            ctx.fill(lFoot, with: fillShading)
            ctx.stroke(lFoot, with: lineShading, lineWidth: lw)

            // RIGHT FOOT
            let rFoot = Path(roundedRect: CGRect(x: cx + w*0.06, y: h*0.88, width: w*0.38, height: h*0.10), cornerRadius: 5)
            ctx.fill(rFoot, with: fillShading)
            ctx.stroke(rFoot, with: lineShading, lineWidth: lw)
        }
    }
}

// MARK: - ClothingSlotView

private struct ClothingSlotView: View {
    let item: ClothingItem
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ItemImageView(item: item, size: CGSize(width: 200, height: 300))
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 4)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color(.systemGray))
                    .font(.caption)
                    .padding(3)
            }
        }
    }
}

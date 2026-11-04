import SwiftUI

/// Gold "Sirius" star: bright white-gold core with long radiating rays that gently pulse.
struct SiriusStar: View {
    var size: CGFloat
    @State private var pulse = false
    private let gold = Color(hex: "#FFD36B")
    private let paleGold = Color(hex: "#FFF1C4")

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [paleGold.opacity(0.9), gold.opacity(0.45), gold.opacity(0.12), .clear],
                                     center: .center, startRadius: 0, endRadius: size * 1.1))
                .frame(width: size * 2.3, height: size * 2.3)
                .scaleEffect(pulse ? 1.08 : 0.92)

            ray(length: size * 2.4, thickness: size * 0.07)
            ray(length: size * 2.4, thickness: size * 0.07).rotationEffect(.degrees(90))
            ray(length: size * 1.3, thickness: size * 0.04).rotationEffect(.degrees(45)).opacity(0.7)
            ray(length: size * 1.3, thickness: size * 0.04).rotationEffect(.degrees(-45)).opacity(0.7)
            ray(length: size * 0.8, thickness: size * 0.025).rotationEffect(.degrees(22.5)).opacity(0.4)
            ray(length: size * 0.8, thickness: size * 0.025).rotationEffect(.degrees(-22.5)).opacity(0.4)
            ray(length: size * 0.8, thickness: size * 0.025).rotationEffect(.degrees(67.5)).opacity(0.4)
            ray(length: size * 0.8, thickness: size * 0.025).rotationEffect(.degrees(-67.5)).opacity(0.4)

            FourPointStar()
                .fill(LinearGradient(colors: [.white, gold], startPoint: .top, endPoint: .bottom))
                .frame(width: size, height: size)
                .shadow(color: gold.opacity(0.95), radius: 8)
                .shadow(color: gold.opacity(0.6), radius: 16)

            Circle().fill(Color.white).frame(width: size * 0.2, height: size * 0.2)
                .shadow(color: .white, radius: 5)
        }
        .scaleEffect(pulse ? 1.04 : 0.97)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { pulse = true }
        }
    }

    private func ray(length: CGFloat, thickness: CGFloat) -> some View {
        Capsule()
            .fill(LinearGradient(colors: [.clear, paleGold.opacity(0.95), .clear], startPoint: .leading, endPoint: .trailing))
            .frame(width: length, height: max(thickness, 0.8))
    }
}

/// Dark sphere whose light only clings to the rim. `lightSide` (-1 left … 1 right) pushes the lit sliver to one side;
/// 0 lights the whole edge evenly.
struct RimLitSphere: View {
    var diameter: CGFloat
    var lightSide: CGFloat = 0
    var rim: Color = Color(hex: "#F3CE94")
    var body: some View {
        let dark = Color(hex: "#07060B")
        let side = lightSide
        // Light falls off smoothly from the rim toward the dark body (no hard edge).
        let radius = side == 0 ? diameter * 0.5 : diameter * 0.95
        let stops: [Gradient.Stop] = side == 0
            ? [.init(color: .clear, location: 0.0), .init(color: .clear, location: 0.40),
               .init(color: rim.opacity(0.06), location: 0.58), .init(color: rim.opacity(0.16), location: 0.72),
               .init(color: rim.opacity(0.40), location: 0.86), .init(color: rim.opacity(0.80), location: 0.95),
               .init(color: rim, location: 1.0)]
            : [.init(color: .clear, location: 0.0), .init(color: .clear, location: 0.42),
               .init(color: rim.opacity(0.07), location: 0.56), .init(color: rim.opacity(0.20), location: 0.68),
               .init(color: rim.opacity(0.48), location: 0.78), .init(color: rim.opacity(0.85), location: 0.88),
               .init(color: rim, location: 0.96)]
        return Circle()
            .fill(RadialGradient(colors: [Color(hex: "#15121A"), dark], center: .center, startRadius: 0, endRadius: diameter * 0.55))
            .overlay(
                Circle().fill(RadialGradient(stops: stops,
                                             center: UnitPoint(x: 0.5 - side * 0.3, y: 0.5),
                                             startRadius: 0, endRadius: radius))
            )
            .frame(width: diameter, height: diameter)
            .clipShape(Circle())
            .shadow(color: rim.opacity(0.4), radius: diameter * 0.08)
    }
}

/// Moon, little planets and the corner star behind the match-result screen.
struct RevealSkyDecor: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                // Big moon, upper-left: dark body, bright only along the edge.
                RimLitSphere(diameter: w * 0.62, lightSide: 0)
                    .overlay(craters(d: w * 0.62))
                    .position(x: w * 0.04, y: h * 0.055)

                // Three small planets on the left: right edge lit.
                RimLitSphere(diameter: 16, lightSide: 1).position(x: w * 0.07, y: h * 0.30)
                RimLitSphere(diameter: 10, lightSide: 1).position(x: w * 0.12, y: h * 0.355)
                RimLitSphere(diameter: 30, lightSide: 1).position(x: w * 0.035, y: h * 0.43)

                // One planet on the right: left edge lit.
                RimLitSphere(diameter: 28, lightSide: -1).position(x: w * 0.965, y: h * 0.40)

                // Top-right Sirius.
                SiriusStar(size: 26).position(x: w * 0.91, y: h * 0.17)
            }
        }
        .allowsHitTesting(false)
    }

    private func craters(d: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.05)).frame(width: d * 0.22).offset(x: d * 0.18, y: d * 0.12)
            Circle().fill(Color.white.opacity(0.04)).frame(width: d * 0.14).offset(x: d * 0.05, y: d * 0.26)
            Circle().fill(Color.white.opacity(0.04)).frame(width: d * 0.1).offset(x: d * 0.28, y: -d * 0.08)
        }
        .clipShape(Circle())
    }
}

import SwiftUI

struct GlowCTAButton: View {
    let title: String
    var lavender: Color = ABColor.lavender
    var isEnabled: Bool = true
    var showsArrow: Bool = true
    var showSparkle: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(ABFont.body(16.5, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(isEnabled ? 0.95 : 0.4))

                if showsArrow {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(isEnabled ? 0.95 : 0.35))
                    }
                    .padding(.trailing, 26)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(GlowCapsule.fill)
            .overlay(GlowCapsule.border)
            .overlay(alignment: .top) {
                Capsule(style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.55),
                                Color.white.opacity(0.08),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .padding(.horizontal, 10)
                    .padding(.top, 1)
                    .frame(height: 18)
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .leading) {
                if showSparkle {
                    ZStack {
                        Text("✦")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.95))
                            .shadow(color: Color.white.opacity(0.75), radius: 3)
                            .shadow(color: lavender.opacity(0.55), radius: 6)

                        Text("✦")
                            .font(.system(size: 7))
                            .foregroundStyle(Color.white.opacity(0.7))
                            .offset(x: 9, y: -9)
                    }
                    .padding(.leading, 20)
                }
            }
            .clipShape(Capsule(style: .continuous))
            .shadow(color: Color.black.opacity(isEnabled ? 0.22 : 0), radius: 14, y: 8)
            .shadow(color: lavender.opacity(isEnabled ? 0.28 : 0), radius: 18, y: 6)
            .opacity(isEnabled ? 1 : 0.75)
        }
        .buttonStyle(CrystalPressStyle(isEnabled: isEnabled))
        .disabled(!isEnabled)
    }
}

enum GlowCapsule {
    static var fill: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)

            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.10),
                            Color(hex: "#B5ABF5").opacity(0.10),
                            ABColor.lavender.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Capsule(style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "#E2DDFF").opacity(0.55),
                            ABColor.lavender.opacity(0.28)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2.5
                )
                .blur(radius: 4)
                .opacity(0.85)
        }
    }

    static var border: some View {
        Capsule(style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.62),
                        Color(hex: "#E2DDFF").opacity(0.40),
                        ABColor.lavender.opacity(0.22)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

extension View {
    func glowInputSurface() -> some View {
        self
            .background {
                ZStack {
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.04))
                    Capsule(style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#E2DDFF").opacity(0.45),
                                    ABColor.lavender.opacity(0.22)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                        .blur(radius: 3.5)
                        .opacity(0.75)
                }
            }
            .overlay(GlowCapsule.border)
    }
}

struct CrystalPressStyle: ButtonStyle {
    var isEnabled: Bool = true
    var pressScale: CGFloat = 0.975

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .scaleEffect(pressed && isEnabled && !reduceMotion ? pressScale : 1)
            .brightness(pressed && isEnabled ? -0.03 : 0)
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: pressed)
    }
}

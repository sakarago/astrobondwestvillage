import SwiftUI

/// Crystal glass plate — transparent frost + bevel + soft depth.
struct CrystalPlateModifier: ViewModifier {
    var cornerRadius: CGFloat = 22
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if scheme == .light {
            content
                .background {
                    ZStack {
                        shape.fill(Color.white.opacity(0.72))
                        shape.fill(LinearGradient(colors: [Color.white.opacity(0.85), .clear, Color(hex: "#F6D9CB").opacity(0.45)],
                                                  startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                }
                .clipShape(shape)
                .overlay(
                    shape.strokeBorder(
                        LinearGradient(colors: [Color.white, Color(hex: "#E9CBBB").opacity(0.7), Color.white.opacity(0.5)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1)
                )
                .shadow(color: Color(hex: "#B98B78").opacity(0.22), radius: 14, y: 8)
        } else {
            content
                .background {
                    ZStack {
                        shape.fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                        shape.fill(Color.white.opacity(0.04))
                        shape.fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.18), .clear, Color.black.opacity(0.16)],
                                startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .blendMode(.overlay)
                    }
                }
                .clipShape(shape)
                .overlay(
                    shape.strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.50), ABColor.lavenderSoft.opacity(0.22), Color.white.opacity(0.06)],
                            startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.22), radius: 14, y: 8)
                .shadow(color: ABColor.lavender.opacity(0.12), radius: 16, y: 6)
        }
    }
}

extension View {
    func crystalPlate(cornerRadius: CGFloat = 22) -> some View {
        modifier(CrystalPlateModifier(cornerRadius: cornerRadius))
    }
}

/// A small "bezel" — used for icon-only chrome buttons (gear, filters, back,
/// overflow…) that previously read as nearly-invisible flat glass. Adds a
/// brighter top-down gradient, a raised-edge stroke that's lighter on top
/// than on the bottom, a soft specular highlight near the top edge, and a
/// grounding drop shadow so the button visibly pops off the background
/// instead of blending into it.
private struct CrystalIconBezel: ViewModifier {
    var size: CGFloat
    var cornerRadius: CGFloat
    var pressed: Bool = false
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if scheme == .light {
            content
                .frame(width: size, height: size)
                .background {
                    ZStack {
                        shape.fill(Color.white.opacity(0.85))
                        shape.fill(LinearGradient(colors: [Color.white, Color(hex: "#F6DDD0").opacity(0.7)], startPoint: .top, endPoint: .bottom))
                    }
                }
                .overlay(shape.strokeBorder(LinearGradient(colors: [Color.white, Color(hex: "#E3C3B1")], startPoint: .top, endPoint: .bottom), lineWidth: 1.1))
                .clipShape(shape)
                .shadow(color: Color(hex: "#B98B78").opacity(pressed ? 0.15 : 0.30), radius: pressed ? 4 : 9, y: pressed ? 2 : 5)
                .scaleEffect(pressed ? 0.93 : 1)
        } else {
        content
            .frame(width: size, height: size)
            .background {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                    shape.fill(Color.white.opacity(0.05))
                    shape.fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.30),
                                Color.white.opacity(0.04),
                                Color.black.opacity(0.22)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    shape.fill(
                        RadialGradient(
                            colors: [ABColor.lavender.opacity(0.28), .clear],
                            center: .topLeading,
                            startRadius: 1,
                            endRadius: size * 1.1
                        )
                    )
                }
            }
            .overlay(
                shape.strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.85),
                            ABColor.lavenderSoft.opacity(0.4),
                            Color.black.opacity(0.35)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.1
                )
            )
            .overlay(alignment: .top) {
                Capsule()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: size * 0.46, height: 1.5)
                    .blur(radius: 0.4)
                    .offset(y: size * 0.17)
                    .opacity(pressed ? 0.25 : 1)
            }
            .clipShape(shape)
            .shadow(color: Color.black.opacity(pressed ? 0.16 : 0.38), radius: pressed ? 4 : 10, y: pressed ? 2 : 6)
            .shadow(color: ABColor.lavender.opacity(pressed ? 0.10 : 0.26), radius: pressed ? 5 : 12, y: 3)
            .scaleEffect(pressed ? 0.93 : 1)
        }
    }
}

extension View {
    /// For plain, non-Button chrome (e.g. inside a `Menu` label).
    func crystalIconBezel(size: CGFloat = 40, cornerRadius: CGFloat = 14, pressed: Bool = false) -> some View {
        modifier(CrystalIconBezel(size: size, cornerRadius: cornerRadius, pressed: pressed))
    }
}

/// Same bezel, wired to a real `Button`'s press state for a tactile,
/// spring-back 3D feel instead of a static flat icon.
struct CrystalIconButtonStyle: ButtonStyle {
    var size: CGFloat = 40
    var cornerRadius: CGFloat = 14

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .crystalIconBezel(size: size, cornerRadius: cornerRadius, pressed: configuration.isPressed)
            .animation(.spring(response: 0.28, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

struct CrystalCTAButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ABFont.body(16.5, weight: .semibold))
                .foregroundStyle(ABColor.ctaText.opacity(isEnabled ? 0.95 : 0.4))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background {
                    if scheme == .light {
                        Capsule(style: .continuous)
                            .fill(LinearGradient(colors: [Color(hex: "#F8D3C4"), Color(hex: "#EBA999")], startPoint: .top, endPoint: .bottom))
                    } else {
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.10),
                                    ABColor.lavender.opacity(0.12)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    ABColor.glassTint.opacity(0.60),
                                    ABColor.lavenderSoft.opacity(0.35),
                                    ABColor.lavender.opacity(0.22)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .clipShape(Capsule(style: .continuous))
                .shadow(color: (scheme == .light ? ABColor.peachGlow : Color.black).opacity(0.28), radius: 12, y: 7)
                .shadow(color: (scheme == .light ? ABColor.peachGlow : ABColor.lavender).opacity(0.25), radius: 16, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.75)
    }
}

/// The app-wide backdrop. Rebuilt around `cosmic_match_bg` — a near-black
/// deep-space starfield asset that shipped with the project but was never
/// actually wired up — instead of a brighter purple-twilight gradient, so
/// the whole app reads closer to the moodier, more mysterious feel the
/// previous version's background had.
struct CosmicBackdrop: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        if scheme == .light { lightBody } else { darkBody }
    }

    private var lightBody: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#FFF9F3"), Color(hex: "#FAEBDF"), Color(hex: "#F4DFE0")],
                           startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Color(hex: "#F9C9B5").opacity(0.55), .clear],
                           center: .topLeading, startRadius: 10, endRadius: 420)
            RadialGradient(colors: [Color(hex: "#CDBDF7").opacity(0.45), .clear],
                           center: .bottomTrailing, startRadius: 10, endRadius: 460)
        }
        .ignoresSafeArea()
    }

    private var darkBody: some View {
        ZStack {
            // Near-black base first, so edges/aspect gaps around the photo
            // (different screen sizes) never show anything lighter.
            Color(hex: "#040308")
                .ignoresSafeArea()

            Image("cosmic_match_bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            // Just a hint of the brand's violet, low enough to read as
            // "something glows far away in the dark" rather than a colored
            // wash over the whole screen.
            RadialGradient(
                colors: [ABColor.lavender.opacity(0.10), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 380
            )
            .ignoresSafeArea()

            // Soft vignette — keeps the center a touch open for content
            // while the edges stay deep and mysterious.
            RadialGradient(
                colors: [.clear, Color.black.opacity(0.5)],
                center: .center,
                startRadius: 200,
                endRadius: 520
            )
            .ignoresSafeArea()
        }
    }
}

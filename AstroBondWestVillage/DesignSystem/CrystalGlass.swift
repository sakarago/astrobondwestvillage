import SwiftUI

/// Crystal glass plate — transparent frost + bevel + soft depth.
struct CrystalPlateModifier: ViewModifier {
    var cornerRadius: CGFloat = 22

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                    shape.fill(Color.white.opacity(0.04))
                    shape.fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                .clear,
                                Color.black.opacity(0.16)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.overlay)
                }
            }
            .clipShape(shape)
            .overlay(
                shape.strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.50),
                            ABColor.lavenderSoft.opacity(0.22),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            )
            .shadow(color: Color.black.opacity(0.22), radius: 14, y: 8)
            .shadow(color: ABColor.lavender.opacity(0.12), radius: 16, y: 6)
    }
}

extension View {
    func crystalPlate(cornerRadius: CGFloat = 22) -> some View {
        modifier(CrystalPlateModifier(cornerRadius: cornerRadius))
    }
}

struct CrystalCTAButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ABFont.body(16.5, weight: .semibold))
                .foregroundStyle(Color.white.opacity(isEnabled ? 0.95 : 0.4))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background {
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
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.60),
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
                .shadow(color: Color.black.opacity(0.22), radius: 12, y: 7)
                .shadow(color: ABColor.lavender.opacity(0.25), radius: 16, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.75)
    }
}

struct CosmicBackdrop: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: "#16131F"),
                ABColor.space,
                Color(hex: "#1A1528")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay {
            RadialGradient(
                colors: [ABColor.lavender.opacity(0.18), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()
        }
    }
}

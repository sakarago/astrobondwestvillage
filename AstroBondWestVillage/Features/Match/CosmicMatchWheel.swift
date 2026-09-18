import SwiftUI

/// Illustrated cosmic wheel from the original heart-tab Eşleşme screen:
/// the disk spins, edge-light and stars kick in, and the center shows BOND
/// until a match lands (then that person's sun glyph).
struct CosmicMatchWheel: View {
    var rotation: Double
    var isSpinning: Bool
    var isRevealed: Bool = false
    var size: CGFloat = 278
    var revealedGlyph: String? = nil
    var revealedSignIndex: Int? = nil
    var onTap: (() -> Void)? = nil

    @State private var streakRotation: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var glowPulse: CGFloat = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            edgeGlow
            spinStars
            lightStreaks

            Image("cosmic_wheel")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation))

            if isRevealed {
                highlightWedge
                matchedGlyphGlow
            }

            centerControl
        }
        .frame(width: size + 64, height: size + 64)
        .contentShape(Circle())
        .onTapGesture { onTap?() }
        .onChange(of: isSpinning) { _, spinning in
            if spinning {
                intensifyMotion()
            } else if isRevealed {
                settleGlow()
            } else {
                restGlow()
            }
        }
        .onChange(of: isRevealed) { _, revealed in
            if revealed { settleGlow() }
            else if !isSpinning { restGlow() }
        }
        .accessibilityLabel(isRevealed ? "Eşleşme çarkı" : "Çarkı çevirerek eşleş")
    }

    @ViewBuilder
    private var centerControl: some View {
        if isSpinning {
            EmptyView()
        } else if isRevealed {
            centerRing {
                Text(revealedGlyph ?? "✦")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundStyle(.white)
            }
            .allowsHitTesting(false)
        } else {
            Button {
                onTap?()
            } label: {
                centerRing {
                    VStack(spacing: 5) {
                        AstroBondEmblem(size: 30)
                        Text("BOND")
                            .font(ABFont.body(13, weight: .bold))
                            .tracking(2.5)
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Çarkı çevirerek eşleş")
        }
    }

    private func centerRing<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        ZStack {
            Circle()
                .fill(Color.clear)
                .frame(width: 100, height: 100)
                .overlay(Circle().stroke(ABColor.lavender.opacity(0.95), lineWidth: 1.6))
                .shadow(color: ABColor.lavender.opacity(isRevealed ? 0.28 : 0.42), radius: isRevealed ? 14 : 18)
                .overlay {
                    Circle()
                        .stroke(ABColor.lavender.opacity(isRevealed ? 0.18 : 0.42), lineWidth: 4)
                        .blur(radius: isRevealed ? 2 : 6)
                        .scaleEffect(isRevealed ? 1 : glowPulse)
                }
            content()
        }
    }

    private var edgeGlow: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "#F2F4F8"), Color(hex: "#B7BDC7").opacity(0.4)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: size, height: size)
                .blur(radius: 12)
                .scaleEffect(glowPulse)
                .opacity(glowOpacity)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.clear, Color(hex: "#CDD2DB").opacity(0.28), Color.clear],
                        center: .center,
                        startRadius: size * 0.42,
                        endRadius: size * 0.66
                    )
                )
                .frame(width: size * 1.5, height: size * 1.5)
                .scaleEffect(glowPulse)
                .opacity(glowOpacity)
        }
        .allowsHitTesting(false)
    }

    private var spinStars: some View {
        let count = 16
        let radius = size * 0.56
        return ZStack {
            ForEach(0..<count, id: \.self) { i in
                let ang = Double(i) / Double(count) * 2 * .pi
                let r = radius + (i % 3 == 0 ? 16 : (i % 3 == 1 ? -10 : 4))
                let sz = CGFloat(i % 3 == 0 ? 15 : (i % 3 == 1 ? 9 : 12))
                Image(systemName: i % 2 == 0 ? "sparkle" : "star.fill")
                    .font(.system(size: sz, weight: .semibold))
                    .foregroundStyle(.white)
                    .opacity((0.55 + 0.45 * sin(streakRotation * .pi / 180 + Double(i))) * glowOpacity)
                    .offset(x: r * cos(ang), y: r * sin(ang))
            }
        }
        .rotationEffect(.degrees(streakRotation * 0.15))
        .allowsHitTesting(false)
    }

    private var lightStreaks: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .trim(from: 0, to: 0.05)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0)],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: size * 1.02, height: size * 1.02)
                    .rotationEffect(.degrees(Double(i) * 120))
            }
        }
        .rotationEffect(.degrees(streakRotation))
        .opacity(glowOpacity)
        .allowsHitTesting(false)
    }

    private var highlightWedge: some View {
        let angle = signAngle
        return CosmicWedgeShape(
            startAngle: .degrees(angle - 15),
            endAngle: .degrees(angle + 15)
        )
        .fill(
            RadialGradient(
                colors: [ABColor.lavender.opacity(0.0), ABColor.lavender.opacity(0.5)],
                center: .center,
                startRadius: size * 0.10,
                endRadius: size * 0.50
            )
        )
        .frame(width: size, height: size)
        .blur(radius: 2)
        .blendMode(.screen)
        .allowsHitTesting(false)
    }

    private var matchedGlyphGlow: some View {
        let r = size * 0.385
        let a = signAngle * .pi / 180
        return Circle()
            .fill(
                RadialGradient(
                    colors: [Color.white.opacity(0.55), ABColor.lavender.opacity(0.0)],
                    center: .center, startRadius: 1, endRadius: 28
                )
            )
            .frame(width: 56, height: 56)
            .offset(x: r * cos(a), y: r * sin(a))
            .blendMode(.screen)
            .allowsHitTesting(false)
    }

    /// Aries at the top, clockwise — same convention as the original wheel art.
    private var signAngle: Double {
        Double(revealedSignIndex ?? 8) * 30 - 90
    }

    private func intensifyMotion() {
        guard !reduceMotion else {
            glowOpacity = 1
            return
        }
        withAnimation(.linear(duration: 6)) { streakRotation += 360 * 9 }
        withAnimation(.easeIn(duration: 0.8)) { glowOpacity = 1 }
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            glowPulse = 1.12
        }
    }

    private func settleGlow() {
        withAnimation(.easeOut(duration: 0.6)) { glowPulse = 1 }
        withAnimation(.easeOut(duration: 0.9)) { glowOpacity = 0.35 }
    }

    private func restGlow() {
        withAnimation(.easeOut(duration: 0.4)) {
            glowOpacity = 0
            glowPulse = 1
        }
    }
}

struct AstroBondEmblem: View {
    var size: CGFloat = 30
    private let gold = Color(hex: "#E4E8EF")

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.0, to: 0.78)
                .stroke(
                    LinearGradient(
                        colors: [gold, gold.opacity(0.5)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: size * 0.07, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(130))
            Text("✦")
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(gold)
                .offset(y: -size * 0.03)
        }
        .frame(width: size, height: size)
    }
}

struct AstroBondLogoMark: View {
    var body: some View {
        VStack(spacing: 7) {
            Text("✦")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: "#C9CFD9"))
            Text("ASTROBOND")
                .font(ABFont.display(17, weight: .regular))
                .tracking(6.5)
                .foregroundStyle(Color.white.opacity(0.95))
                .padding(.leading, 6.5)
        }
    }
}

private struct CosmicWedgeShape: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}

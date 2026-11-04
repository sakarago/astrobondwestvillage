import SwiftUI

/// Illustrated cosmic wheel from the Eşleşme screen:
/// the disk spins, edge-light and stars kick in, and the center shows
/// "EŞLEŞ" until a match lands (then that person's sun glyph).
struct CosmicMatchWheel: View {
    var rotation: Double
    var isSpinning: Bool
    var isRevealed: Bool = false
    var size: CGFloat = 278
    var revealedGlyph: String? = nil
    var revealedSignIndex: Int? = nil
    var showsTapPrompt: Bool = false
    var onTap: (() -> Void)? = nil

    @State private var streakRotation: Double = 0
    @State private var glowOpacity: Double = 0.45
    @State private var glowPulse: CGFloat = 1
    @State private var haloRotation: Double = 0
    @State private var twinkle: Double = 0
    @State private var nebulaRotation: Double = 0
    @State private var starFlash: Double = 1
    @State private var ripple: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            searchAtmosphere
            outerFieldStars
            edgeGlow
            if isSpinning { spinStars }
            lightStreaks
            searchOrbitRings

            ZodiacWheelDisk(size: size)
                .rotationEffect(.degrees(rotation))

            if isRevealed {
                highlightWedge
                matchedGlyphGlow
            }

            if !isSpinning && !isRevealed {
                // Fixed Aries pointer, like the design mock.
                Image(systemName: "chevron.up")
                    .font(.system(size: size * 0.028, weight: .semibold))
                    .foregroundStyle(ABColor.lavenderSoft.opacity(0.7))
                    .offset(y: -size * 0.285)
                    .allowsHitTesting(false)
            }

            centerControl
            searchPlanets
        }
        .frame(width: size + 128, height: size + 128)
        .contentShape(Circle())
        .onTapGesture { onTap?() }
        .onAppear {
            if !isSpinning && !isRevealed { restGlow() }
            else { startTwinkle() }
        }
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
            centerRing {
                ZStack {
                    innerFieldStars
                    CosmicSparkStar(size: size * 0.125, pulse: glowPulse)
                }
            }
            .allowsHitTesting(false)
        } else if isRevealed {
            revealedCenter
                .allowsHitTesting(false)
        } else {
            Button {
                onTap?()
            } label: {
                centerRing {
                    if showsTapPrompt {
                        ZStack {
                            innerFieldStars
                            // Only the star flashes; the label stays steady just below it.
                            CosmicSparkStar(size: size * 0.17, pulse: glowPulse)
                                .opacity(starFlash)
                                .scaleEffect(0.92 + 0.08 * starFlash)
                                .offset(y: -size * 0.025)
                            Text("EŞLEŞ")
                                .font(ABFont.body(size * 0.038, weight: .bold))
                                .tracking(2.6)
                                .foregroundStyle(.white)
                                .shadow(color: ABColor.lavenderSoft.opacity(0.85), radius: 6)
                                .offset(y: size * 0.105)
                            Image(systemName: "chevron.down")
                                .font(.system(size: size * 0.03, weight: .semibold))
                                .foregroundStyle(ABColor.lavenderSoft.opacity(0.9))
                                .offset(y: size * 0.16)
                        }
                    } else {
                        VStack(spacing: 5) {
                            AstroBondEmblem(size: size * 0.11)
                            Text("BAĞ")
                                .font(ABFont.body(13, weight: .bold))
                                .tracking(2.5)
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Çarkı çevirerek eşleş")
        }
    }

    private var centerDiameter: CGFloat { size * 0.45 }

    /// Purple while searching, soft gold on the result screen.
    private var accent: Color { isRevealed ? ABColor.warm : ABColor.lavender }
    private var accentSoft: Color { isRevealed ? Color(hex: "#F6E7CF") : ABColor.lavenderSoft }

    /// Matched sign inside a dark sphere with a soft gold rim.
    private var revealedCenter: some View {
        let d = size * 0.30
        let warm = ABColor.warm
        return ZStack {
            Circle().fill(
                RadialGradient(
                    colors: [Color(hex: "#4A3B4D"), Color(hex: "#150E18"), Color(hex: "#07050A")],
                    center: UnitPoint(x: 0.35, y: 0.3),
                    startRadius: 2, endRadius: d * 0.7
                )
            )
            .frame(width: d, height: d)
            Circle()
                .stroke(
                    LinearGradient(colors: [warm.opacity(0.95), warm.opacity(0.25)], startPoint: .top, endPoint: .bottom),
                    lineWidth: 1.6
                )
                .frame(width: d, height: d)
            Circle()
                .stroke(warm.opacity(0.4), lineWidth: 6)
                .blur(radius: 7)
                .frame(width: d, height: d)
            Text(revealedGlyph ?? "✦")
                .font(.system(size: d * 0.5))
                .foregroundStyle(warm)
                .shadow(color: warm.opacity(0.7), radius: 8)
        }
    }

    private func centerRing<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        let d = centerDiameter
        let attention = !isSpinning && !isRevealed
        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            ABColor.lavender.opacity(0.42),
                            Color.black.opacity(0.45)
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: d * 0.58
                    )
                )
                .frame(width: d, height: d)

            Circle()
                .stroke(ABColor.lavender.opacity(0.98), lineWidth: 2)
                .frame(width: d, height: d)
                .shadow(color: ABColor.lavender.opacity(isRevealed ? 0.35 : 0.95), radius: isRevealed ? 14 : 22)

            Circle()
                .stroke(ABColor.lavenderSoft.opacity(0.7), lineWidth: 10)
                .blur(radius: 8)
                .frame(width: d, height: d)
                .scaleEffect(isRevealed ? 1 : glowPulse)
                .opacity(isRevealed ? 0.35 : max(glowOpacity, 0.55))

            Circle()
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
                .frame(width: d * 0.92, height: d * 0.92)
                .opacity(0.7)

            if attention {
                // Raised 3D bevel: bright top edge, dark bottom edge.
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.95),
                                ABColor.lavenderSoft.opacity(0.6),
                                ABColor.lavender.opacity(0.35),
                                Color.black.opacity(0.55)
                            ],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 4
                    )
                    .frame(width: d, height: d)

                // Inner shadow for depth.
                Circle()
                    .stroke(Color.black.opacity(0.55), lineWidth: 12)
                    .frame(width: d, height: d)
                    .blur(radius: 7)
                    .offset(y: 4)
                    .clipShape(Circle())

                // Glossy specular highlight on the upper cap.
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.42), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: d * 0.62, height: d * 0.26)
                    .offset(y: -d * 0.34)
                    .blur(radius: 1.5)

                // Rim flashes in sync with the star.
                Circle()
                    .stroke(ABColor.lavenderSoft, lineWidth: 5)
                    .frame(width: d, height: d)
                    .blur(radius: 5)
                    .opacity(0.15 + 0.85 * starFlash)

                // "Click me" ripple radiating outward.
                Circle()
                    .stroke(ABColor.lavenderSoft.opacity(0.8), lineWidth: 2)
                    .frame(width: d, height: d)
                    .scaleEffect(1 + 0.45 * ripple)
                    .opacity((1 - ripple) * 0.75)
            }

            if !isRevealed {
                Circle()
                    .trim(from: 0, to: 0.22)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white, ABColor.lavenderSoft.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
                    )
                    .frame(width: d * 1.08, height: d * 1.08)
                    .rotationEffect(.degrees(haloRotation))
                    .opacity(0.85)
            }

            content()
        }
        .shadow(color: Color.black.opacity(attention ? 0.55 : 0), radius: 10, y: 8)
        .scaleEffect(isRevealed || isSpinning || reduceMotion ? 1 : (0.97 + 0.03 * glowPulse))
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
                        colors: [Color.clear, accent.opacity(0.22), Color.clear],
                        center: .center,
                        startRadius: size * 0.38,
                        endRadius: size * 0.66
                    )
                )
                .frame(width: size * 1.5, height: size * 1.5)
                .scaleEffect(glowPulse)
                .opacity(glowOpacity)
        }
        .allowsHitTesting(false)
    }

    private var outerFieldStars: some View {
        ZStack {
            AmbientStarField(
                count: 26,
                innerRadius: size * 0.515,
                outerRadius: size * 0.62,
                twinkle: twinkle,
                maxStarSize: size * 0.034,
                seed: 11
            )
            AmbientStarField(
                count: 18,
                innerRadius: size * 0.64,
                outerRadius: size * 0.78,
                twinkle: twinkle + 0.8,
                maxStarSize: size * 0.026,
                seed: 53
            )
        }
        .allowsHitTesting(false)
    }

    private var innerFieldStars: some View {
        AmbientStarField(
            count: 12,
            innerRadius: centerDiameter * 0.22,
            outerRadius: centerDiameter * 0.44,
            twinkle: twinkle + 1.1,
            maxStarSize: size * 0.022,
            seed: 29
        )
        .allowsHitTesting(false)
    }

    private var searchAtmosphere: some View {
        ZStack {
            Ellipse()
                .fill(
                    AngularGradient(
                        colors: [
                            Color.clear,
                            accent.opacity(0.22),
                            accentSoft.opacity(0.18),
                            Color.clear,
                            accent.opacity(0.32),
                            Color.clear
                        ],
                        center: .center
                    )
                )
                .frame(width: size * 1.55, height: size * 1.18)
                .blur(radius: 22)
                .rotationEffect(.degrees(nebulaRotation))

            Ellipse()
                .fill(
                    AngularGradient(
                        colors: [
                            Color.clear,
                            accentSoft.opacity(0.16),
                            Color.clear,
                            accent.opacity(0.28),
                            Color.clear
                        ],
                        center: .center
                    )
                )
                .frame(width: size * 1.28, height: size * 1.48)
                .blur(radius: 18)
                .rotationEffect(.degrees(-nebulaRotation * 0.7))
        }
        .opacity(isSpinning ? 1 : (isRevealed ? 0.6 : 0))
        .animation(.easeInOut(duration: 0.55), value: isSpinning)
        .animation(.easeInOut(duration: 0.55), value: isRevealed)
        .blendMode(.screen)
        .allowsHitTesting(false)
    }

    private var searchOrbitRings: some View {
        ZStack {
            if isRevealed {
                Circle().stroke(accent.opacity(0.35), lineWidth: 0.8)
                    .frame(width: size * 1.10, height: size * 1.10)
                Ellipse().stroke(accentSoft.opacity(0.25), lineWidth: 0.8)
                    .frame(width: size * 1.30, height: size * 1.0)
                    .rotationEffect(.degrees(-18))
            }
            Circle()
                .trim(from: 0.08, to: 0.46)
                .stroke(
                    AngularGradient(
                        colors: [Color.clear, accentSoft, accent, Color.clear],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 2.4, lineCap: .round)
                )
                .frame(width: size * 1.10, height: size * 1.10)
                .rotationEffect(.degrees(-streakRotation * 0.35))
                .blur(radius: 0.4)

            Circle()
                .trim(from: 0.58, to: 0.88)
                .stroke(
                    AngularGradient(
                        colors: [Color.clear, Color.white.opacity(0.85), accentSoft.opacity(0.4), Color.clear],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 1.6, lineCap: .round)
                )
                .frame(width: size * 1.18, height: size * 1.18)
                .rotationEffect(.degrees(streakRotation * 0.22))

            Circle()
                .stroke(
                    accent.opacity(0.18),
                    style: StrokeStyle(lineWidth: 1, dash: [2, 7])
                )
                .frame(width: size * 1.24, height: size * 1.24)
                .rotationEffect(.degrees(-nebulaRotation * 0.5))
        }
        .opacity(isSpinning ? 1 : (isRevealed ? 0.6 : 0))
        .animation(.easeInOut(duration: 0.55), value: isSpinning)
        .animation(.easeInOut(duration: 0.55), value: isRevealed)
        .allowsHitTesting(false)
    }

    private var searchPlanets: some View {
        ZStack {
            SearchPlanet(diameter: size * 0.16, tint: accent)
                .offset(x: -size * 0.50, y: -size * 0.40)
            SearchPlanet(diameter: size * 0.13, tint: accent)
                .offset(x: size * 0.48, y: size * 0.44)
        }
        .opacity(isSpinning ? 1 : 0)
        .animation(.easeInOut(duration: 0.55), value: isSpinning)
        .animation(.easeInOut(duration: 0.55), value: isRevealed)
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
                Image(systemName: "sparkle")
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
                colors: [ABColor.warm.opacity(0.0), ABColor.warm.opacity(0.55)],
                center: .center,
                startRadius: size * 0.16,
                endRadius: size * 0.50
            )
        )
        .frame(width: size, height: size)
        .blur(radius: 2)
        .blendMode(.screen)
        .allowsHitTesting(false)
    }

    private var matchedGlyphGlow: some View {
        let r = size * 0.31
        let a = signAngle * .pi / 180
        return Circle()
            .fill(
                RadialGradient(
                    colors: [Color.white.opacity(0.55), ABColor.warm.opacity(0.0)],
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
        withAnimation(.linear(duration: 6)) { streakRotation += 360 * 4 }
        withAnimation(.linear(duration: 6)) { nebulaRotation += 140 }
        withAnimation(.easeIn(duration: 0.8)) { glowOpacity = 1 }
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            glowPulse = 1.12
        }
        startTwinkle()
    }

    private func settleGlow() {
        withAnimation(.easeOut(duration: 0.6)) { glowPulse = 1 }
        withAnimation(.easeOut(duration: 0.9)) { glowOpacity = 0.35 }
    }

    private func restGlow() {
        if reduceMotion {
            glowOpacity = 0.45
            glowPulse = 1
            return
        }
        glowOpacity = 0.42
        glowPulse = 1
        // Attention-grabbing on/off flash of the center star.
        starFlash = 1
        withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
            starFlash = 0.12
        }
        ripple = 0
        withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
            ripple = 1
        }
        withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) {
            glowPulse = 1.1
            glowOpacity = 0.78
        }
        let current = haloRotation.truncatingRemainder(dividingBy: 360)
        haloRotation = current
        withAnimation(.linear(duration: 9).repeatForever(autoreverses: false)) {
            haloRotation = current + 360
        }
        startTwinkle()
    }

    private func startTwinkle() {
        guard !reduceMotion else { return }
        withAnimation(.linear(duration: 3.6).repeatForever(autoreverses: false)) {
            twinkle += .pi * 2
        }
    }
}

private struct SearchPlanet: View {
    var diameter: CGFloat
    var tint: Color = ABColor.lavender

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.28))
                .frame(width: diameter * 1.55, height: diameter * 1.55)
                .blur(radius: 10)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "#6A5A62"),
                            Color(hex: "#1A1028"),
                            Color(hex: "#07040E")
                        ],
                        center: UnitPoint(x: 0.34, y: 0.30),
                        startRadius: 2,
                        endRadius: diameter * 0.72
                    )
                )
                .frame(width: diameter, height: diameter)
            Circle()
                .stroke(tint.opacity(0.22), lineWidth: 1)
                .frame(width: diameter, height: diameter)
        }
        .shadow(color: tint.opacity(0.45), radius: 10)
    }
}

/// Four-pointed compass star with a white core, lens flare, and purple bloom.
struct CosmicSparkStar: View {
    var size: CGFloat
    var pulse: CGFloat = 1

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            ABColor.lavenderSoft.opacity(0.7),
                            ABColor.lavender.opacity(0.25),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 1,
                        endRadius: size * 0.85
                    )
                )
                .frame(width: size * 1.9, height: size * 1.9)
                .blur(radius: 1.2)
                .scaleEffect(pulse)

            flare(width: size * 1.55, height: size * 0.055)
            flare(width: size * 0.055, height: size * 1.55)
            flare(width: size * 0.85, height: size * 0.03)
                .rotationEffect(.degrees(45))
                .opacity(0.55)
            flare(width: size * 0.85, height: size * 0.03)
                .rotationEffect(.degrees(-45))
                .opacity(0.55)

            FourPointStar()
                .fill(
                    LinearGradient(
                        colors: [Color.white, ABColor.lavenderSoft],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: Color.white.opacity(0.95), radius: 8)
                .shadow(color: ABColor.lavender.opacity(0.9), radius: 14)

            FourPointStar()
                .fill(Color.white.opacity(0.9))
                .frame(width: size * 0.38, height: size * 0.38)
                .rotationEffect(.degrees(45))

            Circle()
                .fill(Color.white)
                .frame(width: size * 0.16, height: size * 0.16)
                .blur(radius: 0.4)
        }
        .frame(width: size * 1.9, height: size * 1.9)
        .allowsHitTesting(false)
    }

    private func flare(width: CGFloat, height: CGFloat) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [Color.clear, Color.white, Color.clear],
                    startPoint: width > height ? .leading : .top,
                    endPoint: width > height ? .trailing : .bottom
                )
            )
            .frame(width: width, height: height)
            .blur(radius: 0.5)
    }
}

struct FourPointStar: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let waist = outer * 0.09
        let points = [
            CGPoint(x: c.x, y: c.y - outer),
            CGPoint(x: c.x + waist, y: c.y - waist),
            CGPoint(x: c.x + outer, y: c.y),
            CGPoint(x: c.x + waist, y: c.y + waist),
            CGPoint(x: c.x, y: c.y + outer),
            CGPoint(x: c.x - waist, y: c.y + waist),
            CGPoint(x: c.x - outer, y: c.y),
            CGPoint(x: c.x - waist, y: c.y - waist)
        ]
        var path = Path()
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

private struct AmbientStarField: View {
    var count: Int
    var innerRadius: CGFloat
    var outerRadius: CGFloat
    var twinkle: Double
    var maxStarSize: CGFloat
    var seed: Int

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let u = CGFloat((i * 73 + seed * 17) % 1000) / 1000
                let v = CGFloat((i * 191 + seed * 41) % 1000) / 1000
                let ang = Double(u) * 2 * .pi
                let r = innerRadius + (outerRadius - innerRadius) * v
                let sz = maxStarSize * (0.28 + u * 0.72)
                let phase = Double(i) * 0.63 + Double(seed) * 0.05
                let opacity = 0.28 + 0.72 * (0.5 + 0.5 * sin(twinkle + phase))
                let sparkle = i % 3 != 1

                Group {
                    if sparkle {
                        FourPointStar()
                            .fill(Color.white)
                            .frame(width: sz, height: sz)
                            .shadow(color: Color.white.opacity(0.7), radius: 2)
                    } else {
                        Circle()
                            .fill(Color.white)
                            .frame(width: sz * 0.45, height: sz * 0.45)
                    }
                }
                .opacity(opacity)
                .offset(x: r * CGFloat(cos(ang)), y: r * CGFloat(sin(ang)))
            }
        }
    }
}

/// Drawn zodiac disk so sign names can be Turkish. Aries sits at the top.
private struct ZodiacWheelDisk: View {
    var size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(0.08),
                            Color(hex: "#07060C").opacity(0.62)
                        ],
                        center: .center,
                        startRadius: size * 0.06,
                        endRadius: size * 0.50
                    )
                )
                .frame(width: size, height: size)

            Circle()
                .stroke(Color.white.opacity(0.22), lineWidth: 8)
                .blur(radius: 6)
                .frame(width: size, height: size)

            ring(diameter: size, line: 1.2, opacity: 0.68)
            ring(diameter: size * 0.80, line: 0.85, opacity: 0.40)
            ring(diameter: size * 0.62, line: 0.75, opacity: 0.32)
            ring(diameter: size * 0.44, line: 1.0, opacity: 0.48)

            ForEach(0..<12, id: \.self) { i in
                Capsule()
                    .fill(Color.white.opacity(0.30))
                    .frame(width: 0.85, height: size * 0.28)
                    .offset(y: -size * 0.36)
                    .rotationEffect(.degrees(Double(i) * 30 + 15))
            }

            ForEach(Array(ZodiacSign.allCases.enumerated()), id: \.offset) { i, sign in
                let angle = Double(i) * 30
                let rad = angle * .pi / 180

                Text(sign.glyph)
                    .font(.system(size: size * 0.082, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .shadow(color: .white.opacity(0.75), radius: 4)
                    .shadow(color: Color(hex: "#FFE3B0").opacity(0.5), radius: 8)
                    .offset(
                        x: size * 0.31 * sin(rad),
                        y: -size * 0.31 * cos(rad)
                    )

                Text(sign.labelTR.uppercased(with: Locale(identifier: "tr_TR")))
                    .font(.system(size: size * 0.033, weight: .semibold, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(Color.white)
                    .shadow(color: .white.opacity(0.4), radius: 2.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .rotationEffect(.degrees(angle))
                    .offset(
                        x: size * 0.445 * sin(rad),
                        y: -size * 0.445 * cos(rad)
                    )
            }
        }
        .frame(width: size, height: size)
        .shadow(color: Color.white.opacity(0.16), radius: 12)
    }

    private func ring(diameter: CGFloat, line: CGFloat, opacity: Double) -> some View {
        Circle()
            .stroke(Color.white.opacity(opacity), lineWidth: line)
            .frame(width: diameter, height: diameter)
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
    /// Result screen variant: a bright four-point star between ASTR and BOND.
    var flare: Bool = false

    var body: some View {
        if flare {
            HStack(spacing: 2) {
                Text("ASTR")
                SiriusStar(size: 20)
                    .frame(width: 34, height: 34)
                Text("BOND")
            }
            .font(ABFont.display(17, weight: .regular))
            .tracking(5)
            .foregroundStyle(Color.white.opacity(0.95))
            .frame(height: 44)
        } else {
            plain
        }
    }

    private var plain: some View {
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

extension ABColor {
    /// Soft gold/beige used on the match-result screen.
    static let warm = Color(hex: "#EBD3B0")
}

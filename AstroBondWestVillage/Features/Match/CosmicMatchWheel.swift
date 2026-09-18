import SwiftUI

/// Match wheel: illustrated disk + a real, dense chart overlay (zodiac, houses,
/// ticks, planets). When a match is active it becomes a two-person synastry
/// wheel (your placements in gold, theirs in lavender) with aspect lines
/// connecting the two — so "spin → reveal" and "thumbs" read as one object,
/// not a decorative background with buttons bolted on somewhere else.
struct CosmicMatchWheel: View {
    var rotation: Double
    var isSpinning: Bool
    var size: CGFloat = 318
    var showsPointer: Bool = true
    var interactive: Bool = true
    /// Seed for "my" chart placements — stable per user so it always looks the same.
    var mySeed: String = "self"
    /// Seed for the revealed match's placements. Nil = single natal chart.
    var theirSeed: String? = nil
    /// Real placements, when known, anchor the Sun/Moon glyphs to their
    /// actual signs and rotate the house wheel so House 1 starts at the
    /// real Ascendant — instead of the whole chart being pure hashed noise.
    var mySun: ZodiacSign? = nil
    var myMoon: ZodiacSign? = nil
    var myRising: ZodiacSign? = nil
    /// The revealed match's real Sun sign, when known (`MatchCard.sunSign`)
    /// — without this the wheel used to place their ☉ glyph at a random
    /// degree even though their actual sign was already shown elsewhere on
    /// the same screen (the pill under their name), so the two disagreed.
    var theirSun: ZodiacSign? = nil
    var myChart: NatalChart? = nil
    var theirChart: NatalChart? = nil
    var onFlick: (() -> Void)?

    @State private var dragRotation: Double = 0
    @State private var pulse: CGFloat = 1
    @State private var streak: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var totalRotation: Double { rotation + dragRotation }

    var body: some View {
        ZStack {
            aura
            starField
            lightStreaks

            ZStack {
                Image("cosmic_wheel")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .opacity(myChart == nil ? 0.55 : 0.16)

                Circle()
                    .fill(Color(hex: "#0A0810").opacity(myChart == nil ? 0.34 : 0.22))
                    .frame(width: size, height: size)

                if let myChart {
                    ChartWheelView(
                        chart: myChart,
                        overlay: theirSeed != nil ? theirChart : nil
                    )
                    .frame(width: size, height: size)
                    .padding(2)
                } else {
                    NatalWheelCanvas(
                        size: size,
                        mySeed: mySeed,
                        theirSeed: theirSeed,
                        mySun: mySun,
                        myMoon: myMoon,
                        myRising: myRising,
                        theirSun: theirSun,
                        myChart: myChart,
                        theirChart: theirChart
                    )
                    .frame(width: size, height: size)
                }

                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                ABColor.lavenderSoft.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.2
                    )
                    .frame(width: size, height: size)
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .rotationEffect(.degrees(totalRotation))
            .shadow(color: Color.black.opacity(0.55), radius: 22, y: 14)
            .shadow(color: ABColor.lavender.opacity(isSpinning ? 0.45 : 0.22), radius: 28, y: 0)

            if showsPointer { pointer }
            if myChart == nil { centerSeal }
        }
        .frame(width: size, height: size + (showsPointer ? 32 : 4))
        .frame(maxWidth: .infinity)
        .contentShape(Circle())
        .onTapGesture(count: 2) {
            guard interactive, !isSpinning else { return }
            onFlick?()
        }
        .simultaneousGesture(interactive ? spinGesture : nil)
        .onAppear { startAmbientMotion() }
        .onChange(of: isSpinning) { _, spinning in
            if spinning { intensifyMotion() } else { startAmbientMotion() }
        }
        .accessibilityLabel(theirSeed != nil ? "Senkronizasyon haritası" : "Doğum haritası çarkı")
        .accessibilityHint(
            interactive
                ? (theirSeed != nil ? "Bağ özetini açmak için çift dokun" : "Çevirmek için çarka çift dokun")
                : ""
        )
    }

    private var aura: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            ABColor.lavender.opacity(isSpinning ? 0.42 : 0.22),
                            Color(hex: "#4A3A6A").opacity(0.18),
                            .clear
                        ],
                        center: .center,
                        startRadius: size * 0.18,
                        endRadius: size * 0.78
                    )
                )
                .frame(width: size, height: size)
                .blur(radius: 14)
                .scaleEffect(pulse)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.55), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: size, height: size)
                .blur(radius: 10)
                .scaleEffect(pulse)
                .opacity(isSpinning ? 0.95 : 0.55)
        }
        .allowsHitTesting(false)
    }

    private var starField: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1 / 24)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, canvasSize in
                let c = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                for i in 0..<42 {
                    var rng = Seeded(seed: UInt64(i * 97 + 11))
                    let ang = rng.next() * .pi * 2
                    let rad = size * (0.48 + rng.next() * 0.22)
                    let twinkle = 0.35 + 0.65 * abs(sin(t * (0.8 + rng.next()) + Double(i)))
                    let r = 0.6 + rng.next() * 1.8
                    let rect = CGRect(
                        x: c.x + cos(ang) * rad - r,
                        y: c.y + sin(ang) * rad - r,
                        width: r * 2,
                        height: r * 2
                    )
                    ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(twinkle * (isSpinning ? 1 : 0.7))))
                }
            }
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }

    private var lightStreaks: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .trim(from: 0, to: 0.07)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.85), Color.white.opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(Double(i) * 90 + streak))
                    .opacity(isSpinning ? 0.9 : 0.25)
            }
        }
        .allowsHitTesting(false)
    }

    private var pointer: some View {
        VStack(spacing: 2) {
            Image(systemName: "triangle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, ABColor.lavenderSoft],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .rotationEffect(.degrees(180))
                .shadow(color: ABColor.lavender.opacity(0.9), radius: 8)
            Capsule()
                .fill(ABColor.lavenderSoft.opacity(0.7))
                .frame(width: 2, height: 10)
            Spacer()
        }
        .frame(height: size + 28)
        .offset(y: -14)
        .allowsHitTesting(false)
    }

    private var centerSeal: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.28),
                            ABColor.lavender.opacity(0.35),
                            Color(hex: "#0C0A12")
                        ],
                        center: .center,
                        startRadius: 1,
                        endRadius: size * 0.13
                    )
                )
                .frame(width: size * 0.2, height: size * 0.2)
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.7), ABColor.lavenderSoft.opacity(0.25), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: ABColor.lavender.opacity(0.45), radius: 12)

            Text(theirSeed != nil ? "✦✦" : "✦")
                .font(.system(size: size * 0.055, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.92))
                .shadow(color: .white.opacity(0.5), radius: 4)
        }
        .allowsHitTesting(false)
    }

    private var spinGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onChanged { value in
                guard !isSpinning else { return }
                // Only twist the disk on mostly-horizontal flicks so a vertical
                // finger movement can still scroll the Eşleşme page.
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                dragRotation = value.translation.width * 0.4
            }
            .onEnded { value in
                guard !isSpinning else {
                    dragRotation = 0
                    return
                }
                withAnimation(.easeOut(duration: 0.3)) { dragRotation = 0 }
                let horizontal = abs(value.translation.width) > abs(value.translation.height) * 1.2
                let velocity = abs(value.predictedEndTranslation.width - value.translation.width)
                if horizontal, velocity > 100 || abs(value.translation.width) > 70 {
                    onFlick?()
                }
            }
    }

    private func startAmbientMotion() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
            pulse = 1.04
        }
        withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
            streak = 360
        }
    }

    private func intensifyMotion() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
            pulse = 1.08
        }
        withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
            streak += 360
        }
    }
}

// MARK: - Comprehensive chart canvas

/// Draws a real-looking natal chart: zodiac ring w/ element tints + glyphs,
/// degree ticks, 12 numbered house spokes, and a full 10-planet set. When
/// `theirSeed` is provided, draws a second planet ring for the match plus
/// aspect lines between the two charts (the actual "synastry" visual).
private struct NatalWheelCanvas: View {
    let size: CGFloat
    let mySeed: String
    let theirSeed: String?
    var mySun: ZodiacSign? = nil
    var myMoon: ZodiacSign? = nil
    var myRising: ZodiacSign? = nil
    var theirSun: ZodiacSign? = nil
    var myChart: NatalChart? = nil
    var theirChart: NatalChart? = nil

    private let signs = ZodiacSign.allCases
    private let planets: [String] = ["☉", "☽", "☿", "♀", "♂", "♃", "♄", "♅", "♆", "♇"]

    private let myTint = Color(hex: "#F0CE7E")
    private let theirTint = Color(hex: "#C9B8FF")

    /// With a known Ascendant, the whole ring rotates so House 1 (and the
    /// rising sign's wedge) starts at the top of the wheel instead of
    /// Aries always defaulting there — the wheel then actually reflects
    /// *your* chart's orientation, not an arbitrary fixed one.
    private var baseOffset: Double {
        guard let myRising else { return -90 }
        return -90 - Double(myRising.index) * 30
    }

    var body: some View {
        Canvas { ctx, canvasSize in
            let c = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let R = min(canvasSize.width, canvasSize.height) / 2
            let zodiacOuter = R * 0.97
            let zodiacInner = R * 0.78
            let houseR = R * 0.70
            // Two clearly separated belts so the two-person bi-wheel actually
            // reads as two rings, not one scattered cluster of dots.
            let outerPlanetR = R * 0.62
            let innerPlanetR = R * 0.32
            let aspectCoreR = R * 0.20

            // Zodiac wedges tinted by element
            for (i, _) in signs.enumerated() {
                let a0 = Angle.degrees(Double(i) * 30 + baseOffset)
                let a1 = Angle.degrees(Double(i + 1) * 30 + baseOffset)
                var wedge = Path()
                wedge.addArc(center: c, radius: zodiacOuter, startAngle: a0, endAngle: a1, clockwise: false)
                wedge.addArc(center: c, radius: zodiacInner, startAngle: a1, endAngle: a0, clockwise: true)
                wedge.closeSubpath()
                ctx.fill(wedge, with: .color(elementColor(i).opacity(0.30)))
                ctx.stroke(wedge, with: .color(Color.white.opacity(0.12)), lineWidth: 0.7)
            }

            // Degree ticks
            for deg in stride(from: 0, to: 360, by: 5) {
                let major = deg % 30 == 0
                let mid = deg % 10 == 0
                let ang = Angle.degrees(Double(deg) + baseOffset).radians
                let r0 = zodiacOuter - (major ? R * 0.05 : mid ? R * 0.03 : R * 0.016)
                var tick = Path()
                tick.move(to: CGPoint(x: c.x + cos(ang) * r0, y: c.y + sin(ang) * r0))
                tick.addLine(to: CGPoint(x: c.x + cos(ang) * zodiacOuter, y: c.y + sin(ang) * zodiacOuter))
                ctx.stroke(
                    tick,
                    with: .color(Color.white.opacity(major ? 0.55 : mid ? 0.3 : 0.14)),
                    lineWidth: major ? 1.3 : 0.6
                )
            }

            // House spokes + numbers. House 1 (the Ascendant cusp) is drawn
            // brighter and gold when we know the real rising sign, so it
            // reads as "this is the anchor", not just another spoke.
            for i in 0..<12 {
                let isAscendant = i == 0 && myRising != nil
                let ang = Angle.degrees(Double(i) * 30 + baseOffset).radians
                var spoke = Path()
                spoke.move(to: CGPoint(x: c.x + cos(ang) * aspectCoreR * 0.5, y: c.y + sin(ang) * aspectCoreR * 0.5))
                spoke.addLine(to: CGPoint(x: c.x + cos(ang) * houseR, y: c.y + sin(ang) * houseR))
                ctx.stroke(
                    spoke,
                    with: .color(isAscendant ? myTint.opacity(0.85) : Color.white.opacity(i % 3 == 0 ? 0.32 : 0.14)),
                    lineWidth: isAscendant ? 1.8 : (i % 3 == 0 ? 1.2 : 0.6)
                )

                let mid = Angle.degrees(Double(i) * 30 + 15 + baseOffset).radians
                let p = CGPoint(x: c.x + cos(mid) * houseR * 0.82, y: c.y + sin(mid) * houseR * 0.82)
                ctx.draw(
                    Text(isAscendant ? "ASC" : "\(i + 1)")
                        .font(.system(size: R * (isAscendant ? 0.038 : 0.045), weight: .bold, design: .rounded))
                        .foregroundStyle(isAscendant ? myTint : Color.white.opacity(0.4)),
                    at: p,
                    anchor: .center
                )
            }

            // Concentric rings
            for r in [zodiacOuter, zodiacInner, houseR, aspectCoreR] {
                let ring = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
                ctx.stroke(ring, with: .color(Color.white.opacity(0.22)), lineWidth: 0.9)
            }

            // Colored belt tracks — this is what actually sells "two charts,
            // one wheel": a warm ring for you, a cool ring for the match,
            // each visibly its own lane rather than dots floating in space.
            func belt(_ r: CGFloat, _ tint: Color, _ width: CGFloat) {
                let ring = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
                ctx.stroke(ring, with: .color(tint.opacity(0.16)), lineWidth: width * 2.4)
                ctx.stroke(ring, with: .color(tint.opacity(0.75)), lineWidth: width)
            }
            belt(innerPlanetR, myTint, R * 0.014)
            if theirSeed != nil {
                belt(outerPlanetR, theirTint, R * 0.014)
            }

            // Sign glyphs
            for (i, sign) in signs.enumerated() {
                let mid = Angle.degrees(Double(i) * 30 + 15 + baseOffset).radians
                let gr = (zodiacOuter + zodiacInner) / 2
                let p = CGPoint(x: c.x + cos(mid) * gr, y: c.y + sin(mid) * gr)
                ctx.draw(
                    Text(sign.glyph)
                        .font(.system(size: R * 0.09, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.92)),
                    at: p,
                    anchor: .center
                )
            }

            // Planet placements — Sun/Moon anchor to your real signs when
            // known; the rest stay deterministic-per-seed (no ephemeris yet).
            let myAngles = planetAngles(seed: mySeed, sun: mySun, moon: myMoon, chart: myChart)
            let myPts = points(angles: myAngles, center: c, radius: innerPlanetR)

            if let theirSeed {
                let theirAngles = planetAngles(seed: theirSeed, sun: theirSun, moon: nil, chart: theirChart)
                let theirPts = points(angles: theirAngles, center: c, radius: outerPlanetR)
                drawAspects(
                    ctx: ctx, from: myPts, to: theirPts,
                    fromAngles: myAngles, toAngles: theirAngles,
                    fromTint: myTint, toTint: theirTint
                )
                drawPlanets(ctx: ctx, pts: myPts, angles: myAngles, tint: myTint, r: R)
                drawPlanets(ctx: ctx, pts: theirPts, angles: theirAngles, tint: theirTint, r: R)
            } else {
                drawPlanets(ctx: ctx, pts: myPts, angles: myAngles, tint: myTint, r: R)
            }

            // Outer silver rim highlight
            let rim = Path(ellipseIn: CGRect(x: c.x - zodiacOuter, y: c.y - zodiacOuter, width: zodiacOuter * 2, height: zodiacOuter * 2))
            ctx.stroke(
                rim,
                with: .linearGradient(
                    Gradient(colors: [Color.white.opacity(0.7), ABColor.lavenderSoft.opacity(0.4), Color.white.opacity(0.12)]),
                    startPoint: CGPoint(x: c.x - zodiacOuter, y: c.y - zodiacOuter),
                    endPoint: CGPoint(x: c.x + zodiacOuter, y: c.y + zodiacOuter)
                ),
                lineWidth: 1.6
            )
        }
    }

    private func points(angles: [Double], center: CGPoint, radius: CGFloat) -> [CGPoint] {
        angles.map { deg in
            let ang = Angle.degrees(deg + baseOffset).radians
            return CGPoint(x: center.x + cos(ang) * radius, y: center.y + sin(ang) * radius)
        }
    }

    private func drawPlanets(ctx: GraphicsContext, pts: [CGPoint], angles: [Double], tint: Color, r: CGFloat) {
        for (i, p) in pts.enumerated() {
            // Soft glow halo behind the bead so each belt visibly "lights up"
            // instead of reading as a flat dot lost in the chart's clutter.
            let haloR = r * 0.095
            let halo = Path(ellipseIn: CGRect(x: p.x - haloR, y: p.y - haloR, width: haloR * 2, height: haloR * 2))
            ctx.fill(
                halo,
                with: .radialGradient(
                    Gradient(colors: [tint.opacity(0.55), tint.opacity(0)]),
                    center: p,
                    startRadius: 0,
                    endRadius: haloR
                )
            )

            let beadR = r * 0.034
            let bead = Path(ellipseIn: CGRect(x: p.x - beadR, y: p.y - beadR, width: beadR * 2, height: beadR * 2))
            ctx.fill(bead, with: .color(tint))
            ctx.stroke(bead, with: .color(Color.white.opacity(0.75)), lineWidth: 0.8)
            ctx.draw(
                Text(planets[i % planets.count])
                    .font(.system(size: r * 0.058, weight: .bold))
                    .foregroundStyle(Color.white),
                at: CGPoint(x: p.x, y: p.y - r * 0.082),
                anchor: .center
            )
        }
    }

    private func drawAspects(
        ctx: GraphicsContext,
        from: [CGPoint],
        to: [CGPoint],
        fromAngles: [Double],
        toAngles: [Double],
        fromTint: Color,
        toTint: Color
    ) {
        var drawn = 0
        for i in 0..<fromAngles.count {
            for j in 0..<toAngles.count {
                if drawn >= 16 { return }
                let diff = angularDistance(fromAngles[i], toAngles[j])
                guard aspectStyle(for: diff) != nil else { continue }
                var line = Path()
                line.move(to: from[i])
                line.addLine(to: to[j])
                ctx.stroke(
                    line,
                    with: .linearGradient(
                        Gradient(colors: [fromTint.opacity(0.8), toTint.opacity(0.8)]),
                        startPoint: from[i],
                        endPoint: to[j]
                    ),
                    lineWidth: 1.5
                )
                drawn += 1
            }
        }
    }

    private func aspectStyle(for diff: Double) -> (Color, String)? {
        let orb = 7.0
        if diff <= orb { return (Color.white, "Kavuşum") }
        if abs(diff - 60) <= orb { return (Color(hex: "#8FD4B0"), "Sextil") }
        if abs(diff - 90) <= orb { return (Color(hex: "#D48F8F"), "Kare") }
        if abs(diff - 120) <= orb { return (Color(hex: "#8FD48F"), "Üçgen") }
        if abs(diff - 180) <= orb { return (Color(hex: "#D48FA0"), "Karşıt") }
        return nil
    }

    private func angularDistance(_ a: Double, _ b: Double) -> Double {
        let d = abs(a - b).truncatingRemainder(dividingBy: 360)
        return min(d, 360 - d)
    }

    /// `planets[0]` is ☉, `[1]` is ☽, `[2]`/`[3]` are ☿/♀. When the real sun
    /// and/or moon sign are known, those two are placed at a random degree
    /// *within that sign's wedge* instead of anywhere on the wheel — so the
    /// wheel actually agrees with the "☉ Güneş"/"☽ Ay" pills shown elsewhere
    /// on the same screen. Mercury/Venus are nudged near the Sun's degree
    /// (real planets never stray far from it) for a touch more plausibility.
    /// Everything else remains deterministic-per-seed placeholder placement,
    /// since a real ephemeris isn't wired in yet.
    private func planetAngles(seed: String, sun: ZodiacSign?, moon: ZodiacSign?, chart: NatalChart?) -> [Double] {
        if let chart {
            let longs = Planet.allCases.compactMap { chart.planet($0)?.longitude }
            if longs.count == planets.count { return longs }
        }
        var rng = Seeded(seed: stableHash(seed))
        var angles: [Double] = []

        func degreeWithin(_ sign: ZodiacSign) -> Double {
            Double(sign.index) * 30 + rng.next() * 30
        }

        let sunAngle = sun.map(degreeWithin) ?? rng.next() * 360
        angles.append(sunAngle)
        let moonAngle = moon.map(degreeWithin) ?? rng.next() * 360
        angles.append(moonAngle)
        angles.append(normalizeDegree(sunAngle + (rng.next() - 0.5) * 52))
        angles.append(normalizeDegree(sunAngle + (rng.next() - 0.5) * 92))

        var guardCount = 0
        while angles.count < planets.count && guardCount < 800 {
            let candidate = rng.next() * 360
            guardCount += 1
            if angles.allSatisfy({ angularDistance($0, candidate) > 14 }) {
                angles.append(candidate)
            }
        }
        while angles.count < planets.count {
            angles.append(Double(angles.count) * 36)
        }
        return angles
    }

    private func normalizeDegree(_ d: Double) -> Double {
        let m = d.truncatingRemainder(dividingBy: 360)
        return m < 0 ? m + 360 : m
    }

    private func stableHash(_ s: String) -> UInt64 {
        var h: UInt64 = 14695981039346656037
        for b in s.utf8 {
            h ^= UInt64(b)
            h &*= 1099511628211
        }
        return h
    }

    private func elementColor(_ index: Int) -> Color {
        switch index % 4 {
        case 0: return Color(hex: "#C48A6A")
        case 1: return Color(hex: "#8FAE7A")
        case 2: return Color(hex: "#7AA0C4")
        default: return Color(hex: "#7A8EC4")
        }
    }
}

private struct Seeded {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 0x9E3779B97F4A7C15 }
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1
        return Double((state >> 11) & 0x1FFFFF) / Double(0x1FFFFF)
    }
}

import SwiftUI

/// A dedicated, "professional" bi-wheel for the Sinastri detail screen.
///
/// Unlike `CosmicMatchWheel` (the decorative single/dual overlay used for the
/// spin-to-reveal moment), this draws an actual two-ring chart: a zodiac band
/// with element-tinted glyphs, twelve house spokes with As/Ds/MC/IC axis
/// labels, and both people's Sun/Moon/Mercury/Venus/Mars ticks with a
/// degree°minute' readout under each glyph — the way a printed synastry
/// chart actually looks, rather than a handful of glowing dots.
struct SynastryWheelCanvas: View {
    let points: [SynastryPoint]
    var mineColor: Color = Color(hex: "#F0CE7E")
    var theirColor: Color = Color(hex: "#C9B8FF")

    private let planetOrder = ["sun", "moon", "mercury", "venus", "mars"]
    /// Ascendant placed at the left (9 o'clock), like a real chart.
    private let ascLon: CGFloat = 76

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let R = min(cx, cy) - 4

            let rZod = R * 0.865
            let rMid = R * 0.585
            let rHouse = R * 0.330
            let rHole = R * 0.240

            ctx.fill(circlePath(cx, cy, R), with: .color(.black.opacity(0.18)))

            for r in [R, rZod, rMid, rHouse, rHole] {
                ctx.stroke(circlePath(cx, cy, r), with: .color(.white.opacity(0.5)), lineWidth: 1)
            }

            // Zodiac wedge dividers
            for i in 0..<12 {
                let lon = CGFloat(i * 30)
                var p = Path(); p.move(to: pt(cx, cy, rZod, lon)); p.addLine(to: pt(cx, cy, R, lon))
                ctx.stroke(p, with: .color(.white.opacity(0.45)), lineWidth: 0.8)
            }

            // Degree ticks — every 5°, longer every 30°.
            for k in 0..<72 {
                let lon = CGFloat(k) * 5
                let major = k % 6 == 0
                let len: CGFloat = major ? R * 0.030 : R * 0.016
                var p = Path(); p.move(to: pt(cx, cy, rZod, lon)); p.addLine(to: pt(cx, cy, rZod + len, lon))
                ctx.stroke(p, with: .color(.white.opacity(major ? 0.55 : 0.24)), lineWidth: major ? 1 : 0.55)
            }

            // Sign glyphs, element-tinted
            for i in 0..<12 {
                let sign = ZodiacSign.allCases[i]
                let gp = pt(cx, cy, (rZod + R) / 2 + R * 0.012, CGFloat(i * 30) + 15)
                ctx.draw(
                    Text(sign.glyph)
                        .font(.system(size: R * 0.075, weight: .medium))
                        .foregroundColor(elementColor(sign)),
                    at: gp
                )
            }

            // House spokes — corner axes (1/4/7/10) drawn brighter/thicker.
            for i in 0..<12 {
                let cusp = ascLon + CGFloat(i * 30)
                let axis = i % 3 == 0
                var p = Path(); p.move(to: pt(cx, cy, rHole, cusp)); p.addLine(to: pt(cx, cy, rZod, cusp))
                ctx.stroke(p, with: .color(.white.opacity(axis ? 0.88 : 0.42)), lineWidth: axis ? 1.5 : 0.75)
            }
            for i in 0..<12 {
                let mid = ascLon + CGFloat(i * 30) + 15
                ctx.draw(
                    Text("\(i + 1)")
                        .font(.system(size: R * 0.046, weight: .semibold))
                        .foregroundColor(.white.opacity(0.58)),
                    at: pt(cx, cy, (rHole + rHouse) / 2, mid)
                )
            }

            // Axis labels
            let axes: [(CGFloat, String)] = [
                (ascLon, "AS"), (ascLon + 180, "DS"), (ascLon + 270, "MC"), (ascLon + 90, "IC")
            ]
            for (lon, label) in axes {
                ctx.draw(
                    Text(label)
                        .font(.system(size: R * 0.05, weight: .bold))
                        .foregroundColor(Color(hex: "#9FD98F")),
                    at: pt(cx, cy, rHole + R * 0.045, lon + 7)
                )
            }

            // Planets — outer belt = them, inner belt = you.
            for label in planetOrder {
                guard let row = points.first(where: { $0.id == label }) else { continue }
                drawPlanet(ctx, cx: cx, cy: cy, ringOuter: rZod,
                           lon: lonOf(row.theirs, row.theirDegree), glyph: row.glyph,
                           deg: row.theirDegree, minute: row.theirMinute, color: theirColor, R: R)
                drawPlanet(ctx, cx: cx, cy: cy, ringOuter: rMid,
                           lon: lonOf(row.mine, row.mineDegree), glyph: row.glyph,
                           deg: row.mineDegree, minute: row.mineMinute, color: mineColor, R: R)
            }

            // Outer rim highlight
            let rim = Path(ellipseIn: CGRect(x: cx - rZod, y: cy - rZod, width: rZod * 2, height: rZod * 2))
            ctx.stroke(
                rim,
                with: .linearGradient(
                    Gradient(colors: [Color.white.opacity(0.7), ABColor.lavenderSoft.opacity(0.4), Color.white.opacity(0.12)]),
                    startPoint: CGPoint(x: cx - rZod, y: cy - rZod),
                    endPoint: CGPoint(x: cx + rZod, y: cy + rZod)
                ),
                lineWidth: 1.4
            )
        }
    }

    private func drawPlanet(_ ctx: GraphicsContext, cx: CGFloat, cy: CGFloat, ringOuter: CGFloat,
                            lon: CGFloat, glyph: String, deg: Int, minute: Int, color: Color, R: CGFloat) {
        var tick = Path()
        tick.move(to: pt(cx, cy, ringOuter, lon))
        tick.addLine(to: pt(cx, cy, ringOuter - R * 0.022, lon))
        ctx.stroke(tick, with: .color(color), lineWidth: 1.2)

        ctx.draw(Text(glyph)
            .font(.system(size: R * 0.066, weight: .semibold))
            .foregroundColor(color), at: pt(cx, cy, ringOuter - R * 0.072, lon))
        ctx.draw(Text("\(deg)°")
            .font(.system(size: R * 0.040, weight: .semibold))
            .foregroundColor(.white.opacity(0.85)), at: pt(cx, cy, ringOuter - R * 0.128, lon))
        ctx.draw(Text("\(minute)'")
            .font(.system(size: R * 0.036, weight: .regular))
            .foregroundColor(.white.opacity(0.55)), at: pt(cx, cy, ringOuter - R * 0.176, lon))
    }

    private func circlePath(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
    }

    private func lonOf(_ s: ZodiacSign, _ deg: Int) -> CGFloat { CGFloat(s.index) * 30 + CGFloat(deg) }

    private func pt(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ lonDeg: CGFloat) -> CGPoint {
        let a = (180 - (lonDeg - ascLon)) * .pi / 180
        return CGPoint(x: cx + r * cos(a), y: cy + r * sin(a))
    }

    private func elementColor(_ s: ZodiacSign) -> Color {
        switch s.element {
        case .fire: return Color(hex: "#E0785A")
        case .earth: return Color(hex: "#8FA86B")
        case .air: return Color(hex: "#6FA8D8")
        case .water: return Color(hex: "#8C86E0")
        }
    }
}

/// Turkish key explaining the wheel's planet + sign glyphs, shown underneath.
struct SynastryKeyView: View {
    private let planets: [(glyph: String, name: String)] = [
        ("☉", "Güneş"), ("☽", "Ay"), ("☿", "Merkür"),
        ("♀", "Venüs"), ("♂", "Mars"), ("↑", "Yükselen"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            keyHeader("GEZEGENLER")
            let cols = [GridItem(.flexible(), alignment: .leading),
                        GridItem(.flexible(), alignment: .leading),
                        GridItem(.flexible(), alignment: .leading)]
            LazyVGrid(columns: cols, alignment: .leading, spacing: 9) {
                ForEach(Array(planets.enumerated()), id: \.offset) { _, p in
                    keyRow(glyph: p.glyph, name: p.name, color: ABColor.lavenderSoft)
                }
            }

            keyHeader("BURÇLAR").padding(.top, 4)
            LazyVGrid(columns: cols, alignment: .leading, spacing: 9) {
                ForEach(ZodiacSign.allCases, id: \.self) { sign in
                    keyRow(glyph: sign.glyph, name: sign.labelTR, color: elementColor(sign))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func keyHeader(_ text: String) -> some View {
        Text(text)
            .font(ABFont.body(10, weight: .bold))
            .tracking(2)
            .foregroundStyle(.white.opacity(0.45))
    }

    private func keyRow(glyph: String, name: String, color: Color) -> some View {
        HStack(spacing: 7) {
            Text(glyph)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 18, alignment: .center)
            Text(name)
                .font(ABFont.body(12, weight: .medium))
                .foregroundStyle(.white.opacity(0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private func elementColor(_ s: ZodiacSign) -> Color {
        switch s.element {
        case .fire: return Color(hex: "#E0785A")
        case .earth: return Color(hex: "#8FA86B")
        case .air: return Color(hex: "#6FA8D8")
        case .water: return Color(hex: "#8C86E0")
        }
    }
}

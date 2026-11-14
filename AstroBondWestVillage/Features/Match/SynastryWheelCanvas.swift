import SwiftUI

/// Warm gold ink — matches the match-found birthmap palette.
private let wheelInk = Color(hex: "#F0CE7E")

/// A dedicated bi-wheel for the Sinastri detail screen (fallback when full
/// natal charts aren't loaded yet). Oriented on *your* rising; outer belt =
/// them, inner belt = you. Glyph + degree only — no minute stacks — so it
/// stays readable at a large size.
struct SynastryWheelCanvas: View {
    let points: [SynastryPoint]
    var mineColor: Color = Color(hex: "#F0CE7E")
    var theirColor: Color = Color(hex: "#E8B9A0")

    private let planetOrder = ["sun", "moon", "rising", "mercury", "venus", "mars", "mc"]

    /// Orient the wheel on the signed-in user's rising (matches ChartWheelView).
    private var ascLon: CGFloat {
        if let rising = points.first(where: { $0.id == "rising" }) {
            return lonOf(rising.mine, rising.mineDegree)
        }
        return 0
    }

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let R = min(cx, cy) - 2
            let asc = ascLon

            let rZod = R * 0.88
            let rMid = R * 0.62
            let rHouse = R * 0.36
            let rHole = R * 0.26

            ctx.fill(circlePath(cx, cy, R), with: .color(Color(hex: "#07060C").opacity(0.55)))

            for r in [R, rZod, rMid, rHouse, rHole] {
                ctx.stroke(circlePath(cx, cy, r), with: .color(wheelInk.opacity(0.5)), lineWidth: 1)
            }

            for i in 0..<12 {
                let lon = CGFloat(i * 30)
                var p = Path(); p.move(to: pt(cx, cy, rZod, lon, asc: asc)); p.addLine(to: pt(cx, cy, R, lon, asc: asc))
                ctx.stroke(p, with: .color(wheelInk.opacity(0.45)), lineWidth: 0.8)
            }

            for k in 0..<72 {
                let lon = CGFloat(k) * 5
                let major = k % 6 == 0
                let len: CGFloat = major ? R * 0.030 : R * 0.016
                var p = Path()
                p.move(to: pt(cx, cy, rZod, lon, asc: asc))
                p.addLine(to: pt(cx, cy, rZod + len, lon, asc: asc))
                ctx.stroke(p, with: .color(wheelInk.opacity(major ? 0.55 : 0.24)), lineWidth: major ? 1 : 0.55)
            }

            for i in 0..<12 {
                let sign = ZodiacSign.allCases[i]
                let gp = pt(cx, cy, (rZod + R) / 2 + R * 0.012, CGFloat(i * 30) + 15, asc: asc)
                ctx.draw(
                    Text(sign.glyph)
                        .font(.system(size: R * 0.070, weight: .medium))
                        .foregroundColor(elementColor(sign)),
                    at: gp
                )
            }

            for i in 0..<12 {
                let cusp = asc + CGFloat(i * 30)
                let axis = i % 3 == 0
                var p = Path()
                p.move(to: pt(cx, cy, rHole, cusp, asc: asc))
                p.addLine(to: pt(cx, cy, rZod, cusp, asc: asc))
                ctx.stroke(p, with: .color(wheelInk.opacity(axis ? 0.88 : 0.42)), lineWidth: axis ? 1.5 : 0.75)
            }

            for i in 0..<12 {
                let mid = asc + CGFloat(i * 30) + 15
                ctx.draw(
                    Text("\(i + 1)")
                        .font(.system(size: R * 0.036, weight: .semibold))
                        .foregroundColor(wheelInk.opacity(0.42)),
                    at: pt(cx, cy, (rHole + rHouse) / 2, mid, asc: asc)
                )
            }

            // Real chart angles — AC on the left by construction.
            let axes: [(CGFloat, String)] = [
                (asc, "AC"), (asc + 180, "DC"), (asc + 270, "MC"), (asc + 90, "IC")
            ]
            for (lon, label) in axes {
                ctx.draw(
                    Text(label)
                        .font(.system(size: R * 0.042, weight: .bold))
                        .foregroundColor(Color(hex: "#F6E7CF")),
                    at: pt(cx, cy, rHole + R * 0.055, lon + 6, asc: asc)
                )
            }

            for label in planetOrder {
                guard let row = points.first(where: { $0.id == label }) else { continue }
                drawPlanet(
                    ctx, cx: cx, cy: cy, ringOuter: rZod,
                    lon: lonOf(row.theirs, row.theirDegree),
                    glyph: row.glyph, degree: row.theirDegree,
                    color: theirColor, R: R, asc: asc
                )
                drawPlanet(
                    ctx, cx: cx, cy: cy, ringOuter: rMid,
                    lon: lonOf(row.mine, row.mineDegree),
                    glyph: row.glyph, degree: row.mineDegree,
                    color: mineColor, R: R, asc: asc
                )
            }

            let rim = Path(ellipseIn: CGRect(x: cx - rZod, y: cy - rZod, width: rZod * 2, height: rZod * 2))
            ctx.stroke(
                rim,
                with: .linearGradient(
                    Gradient(colors: [wheelInk.opacity(0.85), Color(hex: "#F6E7CF").opacity(0.45), wheelInk.opacity(0.12)]),
                    startPoint: CGPoint(x: cx - rZod, y: cy - rZod),
                    endPoint: CGPoint(x: cx + rZod, y: cy + rZod)
                ),
                lineWidth: 1.4
            )
        }
    }

    private func drawPlanet(
        _ ctx: GraphicsContext, cx: CGFloat, cy: CGFloat, ringOuter: CGFloat,
        lon: CGFloat, glyph: String, degree: Int, color: Color, R: CGFloat, asc: CGFloat
    ) {
        var tick = Path()
        tick.move(to: pt(cx, cy, ringOuter, lon, asc: asc))
        tick.addLine(to: pt(cx, cy, ringOuter - R * 0.024, lon, asc: asc))
        ctx.stroke(tick, with: .color(color), lineWidth: 1.2)

        ctx.draw(
            Text(glyph)
                .font(.system(size: R * 0.064, weight: .semibold))
                .foregroundColor(color),
            at: pt(cx, cy, ringOuter - R * 0.078, lon, asc: asc)
        )
        // Degree only (no minutes) — keeps the larger wheel readable.
        ctx.draw(
            Text("\(degree)°")
                .font(.system(size: R * 0.034, weight: .semibold))
                .foregroundColor(wheelInk.opacity(0.72)),
            at: pt(cx, cy, ringOuter - R * 0.128, lon, asc: asc)
        )
    }

    private func circlePath(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
    }

    private func lonOf(_ s: ZodiacSign, _ deg: Int) -> CGFloat {
        CGFloat(s.index) * 30 + CGFloat(deg)
    }

    private func pt(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ lonDeg: CGFloat, asc: CGFloat) -> CGPoint {
        // Same convention as ChartWheelView: Ascendant at the left.
        let rel = lonDeg - asc
        let clockFromTop = (270.0 - rel) * .pi / 180.0
        return CGPoint(x: cx + r * sin(clockFromTop), y: cy - r * cos(clockFromTop))
    }

    private func elementColor(_ s: ZodiacSign) -> Color {
        switch s.element {
        case .fire: return Color(hex: "#E8B07A")
        case .earth: return Color(hex: "#C9B07A")
        case .air: return Color(hex: "#F0CE7E")
        case .water: return Color(hex: "#E8B9A0")
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
                    keyRow(glyph: p.glyph, name: p.name, color: ABColor.warm)
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
                .fill(wheelInk.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(wheelInk.opacity(0.08), lineWidth: 1)
        )
    }

    private func keyHeader(_ text: String) -> some View {
        Text(text)
            .font(ABFont.body(10, weight: .bold))
            .tracking(2)
            .foregroundStyle(wheelInk.opacity(0.45))
    }

    private func keyRow(glyph: String, name: String, color: Color) -> some View {
        HStack(spacing: 7) {
            Text(glyph)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 18, alignment: .center)
            Text(name)
                .font(ABFont.body(12, weight: .medium))
                .foregroundStyle(wheelInk.opacity(0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private func elementColor(_ s: ZodiacSign) -> Color {
        switch s.element {
        case .fire: return Color(hex: "#E8B07A")
        case .earth: return Color(hex: "#C9B07A")
        case .air: return Color(hex: "#F0CE7E")
        case .water: return Color(hex: "#E8B9A0")
        }
    }
}

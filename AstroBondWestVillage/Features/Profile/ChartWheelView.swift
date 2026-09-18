import SwiftUI

/// Original AstroBond natal wheel (Time Nomad–style):
/// outer zodiac, house cusps + degree labels, planet glyphs with anti-collision,
/// inner aspect web, AC/DC/MC/IC. Ascendant is always at the left.
struct ChartWheelView: View {
    let chart: NatalChart
    /// Optional second chart — drawn as an outer planet ring (synastry).
    var overlay: NatalChart? = nil
    var onPlanetTap: ((PlanetPosition) -> Void)? = nil

    @State private var animationProgress: Double = 0

    private var topAspects: [AspectEntity] {
        Array(chart.aspects.sorted { $0.strength > $1.strength }.prefix(14))
    }

    private var laidOutPlanets: [LaidOutPlanet] {
        layoutPlanets(chart.planets)
    }

    private var laidOutOverlay: [LaidOutPlanet] {
        overlay.map { layoutPlanets($0.planets) } ?? []
    }

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let c = CGPoint(x: size / 2, y: size / 2)
            let R = size / 2 - 4
            let asc = chart.ascendant.longitude

            let c1 = R
            let c2 = R * 0.78
            let c3 = R * 0.52
            let c4 = R * 0.30

            let zodiacMidR = (c1 + c2) / 2
            let cuspDegR = c1 * 0.965
            let planetBaseR = overlay == nil ? (c2 + c3) / 2 : (c3 + c4) / 2 + (c2 - c3) * 0.08
            let overlayPlanetR = (c2 + c3) / 2 + (c2 - c3) * 0.18
            let romanR = (c3 + c4) / 2
            let axisLabelR = c3 * 0.92
            let aspectR = c4 * 0.92

            let signFont = size * 0.048
            let degFont = size * 0.026
            let planetFont = size * 0.050
            let planetDegFont = size * 0.024
            let romanFont = size * 0.032
            let axisFont = size * 0.028
            let aspectFont = size * 0.018

            ZStack {
                Canvas { ctx, _ in
                    drawStructure(
                        ctx, c: c, asc: asc,
                        c1: c1, c2: c2, c3: c3, c4: c4,
                        aspectR: aspectR
                    )
                }
                .frame(width: size, height: size)
                .opacity(0.45 + 0.55 * animationProgress)

                ForEach(ZodiacSign.allCases, id: \.self) { sign in
                    let mid = sign.startDegree + 15
                    let pos = pt(mid, zodiacMidR, center: c, asc: asc)
                    Text(sign.lineGlyph)
                        .font(.system(size: signFont, weight: .medium))
                        .foregroundStyle(signColor(sign))
                        .position(x: pos.x, y: pos.y)
                }

                ForEach(chart.houses, id: \.number) { house in
                    let pos = pt(house.cuspLongitude, cuspDegR, center: c, asc: asc)
                    Text(degreeLabel(house.cuspLongitude))
                        .font(.system(size: degFont, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                        .padding(.horizontal, 2)
                        .background(Capsule().fill(Color(hex: "#12131A").opacity(0.75)))
                        .position(x: pos.x, y: pos.y)
                }

                ForEach(laidOutPlanets, id: \.planet.planet) { item in
                    planetNode(
                        item,
                        baseR: planetBaseR,
                        band: c2 - c3,
                        size: size,
                        c: c,
                        asc: asc,
                        planetFont: planetFont,
                        planetDegFont: planetDegFont,
                        tint: nil
                    )
                }

                ForEach(laidOutOverlay, id: \.planet.planet) { item in
                    planetNode(
                        item,
                        baseR: overlayPlanetR,
                        band: c2 - c3,
                        size: size,
                        c: c,
                        asc: asc,
                        planetFont: planetFont * 0.92,
                        planetDegFont: planetDegFont,
                        tint: Color(hex: "#C9B8FF")
                    )
                }

                ForEach(Array(chart.houses.enumerated()), id: \.offset) { idx, house in
                    let next = chart.houses[(idx + 1) % chart.houses.count]
                    let span = ((next.cuspLongitude - house.cuspLongitude) + 360)
                        .truncatingRemainder(dividingBy: 360)
                    let midL = house.cuspLongitude + span / 2
                    let pos = pt(midL, romanR, center: c, asc: asc)
                    Text(house.romanNumeral)
                        .font(.system(size: romanFont, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.40))
                        .position(x: pos.x, y: pos.y)
                }

                ForEach(chart.houses.filter { [1, 4, 7, 10].contains($0.number) }, id: \.number) { house in
                    if let axis = axisLabel(for: house.number) {
                        let pos = pt(house.cuspLongitude, axisLabelR, center: c, asc: asc)
                        Text(axis)
                            .font(.system(size: axisFont, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: "#E8ECF2"))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(hex: "#16171D").opacity(0.9)))
                            .position(x: pos.x, y: pos.y)
                    }
                }

                ForEach(Array(topAspects.prefix(6).enumerated()), id: \.offset) { _, aspect in
                    if let p1 = chart.planet(aspect.planet1),
                       let p2 = chart.planet(aspect.planet2) {
                        let a = pt(p1.longitude, aspectR, center: c, asc: asc)
                        let b = pt(p2.longitude, aspectR, center: c, asc: asc)
                        let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
                        Text(aspect.type.glyph)
                            .font(.system(size: aspectFont, weight: .bold))
                            .foregroundStyle(aspectColor(aspect.type))
                            .padding(1.5)
                            .background(Circle().fill(Color(hex: "#16171D").opacity(0.9)))
                            .position(x: mid.x, y: mid.y)
                            .opacity(animationProgress)
                    }
                }
            }
            .frame(width: size, height: size)
            .clipped()
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2)) { animationProgress = 1.0 }
            }
    }

    @ViewBuilder
    private func planetNode(
        _ item: LaidOutPlanet,
        baseR: Double,
        band: Double,
        size: CGFloat,
        c: CGPoint,
        asc: Double,
        planetFont: CGFloat,
        planetDegFont: CGFloat,
        tint: Color?
    ) -> some View {
        let r = baseR + item.radiusOffset * band * 0.35
        let gp = pt(item.displayLongitude, r, center: c, asc: asc)
        let dp = pt(item.displayLongitude, r - size * 0.042, center: c, asc: asc)
        Group {
            if let onPlanetTap {
                Button { onPlanetTap(item.planet) } label: {
                    planetGlyph(item.planet.planet, size: planetFont, tint: tint)
                }
                .buttonStyle(.plain)
            } else {
                planetGlyph(item.planet.planet, size: planetFont, tint: tint)
            }
        }
        .position(x: gp.x, y: gp.y)
        .scaleEffect(animationProgress)

        Text(degreeLabel(item.planet.longitude))
            .font(.system(size: planetDegFont, weight: .semibold, design: .rounded))
            .foregroundStyle((tint ?? .white).opacity(0.65))
            .position(x: dp.x, y: dp.y)
            .opacity(animationProgress)
    }

    private func drawStructure(
        _ ctx: GraphicsContext, c: CGPoint, asc: Double,
        c1: Double, c2: Double, c3: Double, c4: Double,
        aspectR: Double
    ) {
        for sign in ZodiacSign.allCases {
            let start = sign.startDegree
            var path = Path()
            path.move(to: c)
            for step in 0...12 {
                let lon = start + Double(step) * 2.5
                let p = pt(lon, c1, center: c, asc: asc)
                path.addLine(to: p)
            }
            path.closeSubpath()
            ctx.fill(path, with: .color(signColor(sign).opacity(0.14)))
        }

        let ring = Color.white.opacity(0.55)
        let ringSoft = Color.white.opacity(0.22)

        strokeCircle(ctx, c, c1, ring, 1.2)
        strokeCircle(ctx, c, c2, ring, 1.0)
        strokeCircle(ctx, c, c3, ringSoft, 0.9)
        strokeCircle(ctx, c, c4, ringSoft, 0.9)

        for i in 0..<12 {
            let lon = Double(i) * 30
            let p1 = pt(lon, c1, center: c, asc: asc)
            let p2 = pt(lon, c2, center: c, asc: asc)
            line(ctx, p1, p2, ringSoft, 0.6)
        }

        for d in 0..<360 {
            let len: Double = d % 10 == 0 ? (c1 - c2) * 0.22
                : (d % 5 == 0 ? (c1 - c2) * 0.14 : (c1 - c2) * 0.08)
            let p1 = pt(Double(d), c1, center: c, asc: asc)
            let p2 = pt(Double(d), c1 - len, center: c, asc: asc)
            line(ctx, p1, p2, d % 10 == 0 ? ring : ringSoft, d % 10 == 0 ? 0.65 : 0.35)
        }

        for house in chart.houses {
            let angular = [1, 4, 7, 10].contains(house.number)
            let outer = pt(house.cuspLongitude, c1, center: c, asc: asc)
            if angular {
                line(ctx, outer, c, ring, 1.15)
            } else {
                let inner = pt(house.cuspLongitude, c4, center: c, asc: asc)
                line(ctx, outer, inner, ringSoft, 0.55)
            }
        }

        for aspect in topAspects {
            guard let p1 = chart.planet(aspect.planet1),
                  let p2 = chart.planet(aspect.planet2) else { continue }
            let a = pt(p1.longitude, aspectR, center: c, asc: asc)
            let b = pt(p2.longitude, aspectR, center: c, asc: asc)
            let (baseWidth, dash) = aspectStroke(aspect.type)
            let lw = baseWidth * (0.55 + 0.45 * aspect.strength)
            let color = aspectColor(aspect.type).opacity(0.30 + 0.45 * aspect.strength)
            var path = Path()
            path.move(to: a)
            path.addLine(to: b)
            ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: lw, dash: dash))
        }

        ctx.fill(Path(ellipseIn: circleRect(c, 2.5)), with: .color(.white.opacity(0.7)))
    }

    private struct LaidOutPlanet {
        let planet: PlanetPosition
        let displayLongitude: Double
        let radiusOffset: Double
    }

    private func layoutPlanets(_ planets: [PlanetPosition]) -> [LaidOutPlanet] {
        let sorted = planets.sorted { $0.longitude < $1.longitude }
        guard !sorted.isEmpty else { return [] }
        let minSep = 7.0
        var display = sorted.map(\.longitude)
        var radius = Array(repeating: 0.0, count: sorted.count)
        for i in 1..<sorted.count {
            let prev = display[i - 1]
            var cur = display[i]
            var delta = cur - prev
            if delta < 0 { delta += 360 }
            if delta < minSep {
                cur = prev + minSep
                if cur >= 360 { cur -= 360 }
                display[i] = cur
                radius[i] = radius[i - 1] == 0 ? 1 : 0
            }
        }
        if sorted.count > 1 {
            var delta = (display[0] + 360) - display[sorted.count - 1]
            if delta < 0 { delta += 360 }
            if delta < minSep { radius[0] = 1 }
        }
        return zip(sorted.indices, sorted).map { i, p in
            LaidOutPlanet(planet: p, displayLongitude: display[i], radiusOffset: radius[i])
        }
    }

    private func planetGlyph(_ planet: Planet, size: CGFloat, tint: Color?) -> some View {
        let color = tint ?? planetColor(planet)
        return Text(planet.glyph)
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(color)
            .shadow(color: color.opacity(0.45), radius: 3)
    }

    private func pt(_ L: Double, _ r: Double, center c: CGPoint, asc: Double) -> CGPoint {
        let rel = L - asc
        let clockFromTop = (270.0 - rel) * .pi / 180.0
        return CGPoint(
            x: c.x + r * sin(clockFromTop),
            y: c.y - r * cos(clockFromTop)
        )
    }

    private func circleRect(_ c: CGPoint, _ r: Double) -> CGRect {
        CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)
    }

    private func strokeCircle(_ ctx: GraphicsContext, _ c: CGPoint, _ r: Double, _ color: Color, _ w: CGFloat) {
        ctx.stroke(Path(ellipseIn: circleRect(c, r)), with: .color(color), lineWidth: w)
    }

    private func line(_ ctx: GraphicsContext, _ a: CGPoint, _ b: CGPoint, _ color: Color, _ w: CGFloat) {
        var p = Path()
        p.move(to: a)
        p.addLine(to: b)
        ctx.stroke(p, with: .color(color), lineWidth: w)
    }

    private func degreeLabel(_ longitude: Double) -> String {
        let within = ZodiacSign.degreeWithinSign(longitude: longitude)
        let d = Int(within)
        let m = Int((within - Double(d)) * 60)
        return String(format: "%d°%02d'", d, m)
    }

    private func axisLabel(for house: Int) -> String? {
        switch house {
        case 1: return "AC"
        case 4: return "IC"
        case 7: return "DC"
        case 10: return "MC"
        default: return nil
        }
    }

    private func signColor(_ sign: ZodiacSign) -> Color {
        switch sign.element {
        case .fire: return Color(hex: "#E8736B")
        case .earth: return Color(hex: "#8FC06A")
        case .air: return Color(hex: "#5BC6C6")
        case .water: return Color(hex: "#6BA6E8")
        }
    }

    private func planetColor(_ planet: Planet) -> Color {
        switch planet {
        case .sun: return Color(hex: "#E8A24A")
        case .moon: return Color(hex: "#6BA6E8")
        case .mercury: return Color(hex: "#86C06A")
        case .venus: return Color(hex: "#9ACB6E")
        case .mars: return Color(hex: "#E8736B")
        case .jupiter: return Color(hex: "#E0944A")
        case .saturn: return Color(hex: "#C9CFD9")
        case .uranus: return Color(hex: "#D98CC0")
        case .neptune: return Color(hex: "#6B8CE8")
        case .pluto: return Color(hex: "#B07FD0")
        }
    }

    private func aspectColor(_ type: AspectType) -> Color {
        switch type {
        case .trine, .sextile: return Color(hex: "#5C8CE0")
        case .square, .opposition: return Color(hex: "#E0655C")
        case .conjunction: return Color(hex: "#9AA0AB")
        }
    }

    private func aspectStroke(_ type: AspectType) -> (CGFloat, [CGFloat]) {
        switch type {
        case .opposition: return (1.1, [])
        case .trine: return (1.0, [])
        case .square: return (0.9, [])
        case .sextile: return (0.8, [3, 3])
        case .conjunction: return (0.7, [1.5, 2.5])
        }
    }
}

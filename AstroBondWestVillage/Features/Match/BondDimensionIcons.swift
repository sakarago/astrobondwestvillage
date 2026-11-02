import SwiftUI

// BondDimensionIcons.swift — the Sinastri "Astro Bond Profili" four-icon
// grid: LOVE (heart · red), SEX (galaxy spiral · pink), MIND (constellation ·
// purple), TRUST (lotus · blue). Each icon carries a fixed outer glow — no
// blinking, no animation — ported from the original AstroBond app's design.

enum BondIconKind: CaseIterable, Identifiable {
    case love, sex, mind, trust
    var id: String { title }

    var title: String {
        switch self {
        case .love: return "AŞK BAĞI"
        case .sex: return "TUTKU BAĞI"
        case .mind: return "ZİHİN BAĞI"
        case .trust: return "GÜVEN BAĞI"
        }
    }

    /// Generic fallback note — only used if a real per-match dimension blurb
    /// isn't available yet (see `MatchDetailSheet.dimensionPercent`).
    var note: String {
        switch self {
        case .love: return "Derin sevgi ve sözsüz anlayış."
        case .sex: return "Yüksek çekim, güçlü kıvılcım."
        case .mind: return "Fikirleriniz birbirini besliyor."
        case .trust: return "Sarsılmaz güven, sağlam zemin."
        }
    }

    var tint: Color {
        switch self {
        case .love: return Color(hex: "#FF6168")
        case .sex: return Color(hex: "#ED6BB0")
        case .mind: return Color(hex: "#9385F5")
        case .trust: return Color(hex: "#57C2E6")
        }
    }

    var gradient: [Color] {
        switch self {
        case .love: return [Color(hex: "#FF9AA0"), Color(hex: "#E63B5A")]
        case .sex: return [Color(hex: "#FF86C2"), Color(hex: "#C24E9C")]
        case .mind: return [Color(hex: "#AFA2FF"), Color(hex: "#6E5FD6")]
        case .trust: return [Color(hex: "#84DAF1"), Color(hex: "#3E92C8")]
        }
    }
}

/// A single bond icon with a fixed (non-animated) outer glow.
struct BondDimensionIcon: View {
    let kind: BondIconKind
    var size: CGFloat = 36

    private var grad: LinearGradient {
        LinearGradient(colors: kind.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        Group {
            switch kind {
            case .love: loveIcon
            case .sex: sexIcon
            case .mind: mindIcon
            case .trust: trustIcon
            }
        }
        .frame(width: size, height: size)
        .shadow(color: kind.tint.opacity(0.75), radius: size * 0.28)
        .shadow(color: kind.tint.opacity(0.40), radius: size * 0.55)
    }

    private var loveIcon: some View {
        BondHeart()
            .fill(grad)
            .overlay(
                BondHeart()
                    .fill(Color.white.opacity(0.18))
                    .scaleEffect(0.42)
                    .offset(x: -size * 0.10, y: -size * 0.12)
            )
    }

    private var sexIcon: some View {
        ZStack {
            GalaxySpiral()
                .stroke(grad, style: StrokeStyle(lineWidth: size * 0.075, lineCap: .round))
            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: size * 0.12, height: size * 0.12)
                .shadow(color: kind.tint, radius: size * 0.12)
            sparkle.frame(width: size * 0.18, height: size * 0.18)
                .offset(x: size * 0.34, y: -size * 0.30)
            sparkle.frame(width: size * 0.12, height: size * 0.12)
                .offset(x: -size * 0.34, y: size * 0.26)
        }
    }

    private var sparkle: some View {
        BondSpark().fill(kind.gradient.first ?? .white)
    }

    private var mindIcon: some View {
        let n = 7
        let r = size * 0.42
        let c = CGPoint(x: size / 2, y: size / 2)
        let pts: [CGPoint] = (0..<n).map { i in
            let a = Double(i) / Double(n) * 2 * .pi - .pi / 2
            return CGPoint(x: c.x + r * CGFloat(cos(a)), y: c.y + r * CGFloat(sin(a)))
        }
        return ZStack {
            Path { p in
                for i in 0..<n { p.move(to: pts[i]); p.addLine(to: pts[(i + 1) % n]) }
                for i in [0, 2, 4] { p.move(to: c); p.addLine(to: pts[i]) }
            }
            .stroke(grad, style: StrokeStyle(lineWidth: size * 0.04, lineJoin: .round))

            ForEach(0..<n, id: \.self) { i in
                Circle().fill(grad)
                    .frame(width: size * 0.12, height: size * 0.12)
                    .position(pts[i])
            }
            Circle().fill(grad)
                .frame(width: size * 0.15, height: size * 0.15)
                .position(c)
        }
    }

    private var trustIcon: some View {
        ZStack {
            LotusShape()
                .stroke(grad, style: StrokeStyle(lineWidth: size * 0.05, lineCap: .round, lineJoin: .round))
            LotusShape()
                .fill(grad.opacity(0.12))
        }
    }
}

// MARK: - Shapes

private struct BondHeart: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w / 2, y: h * 0.96))
        p.addCurve(to: CGPoint(x: w * 0.02, y: h * 0.30),
                   control1: CGPoint(x: w * 0.12, y: h * 0.72),
                   control2: CGPoint(x: w * 0.02, y: h * 0.48))
        p.addArc(center: CGPoint(x: w * 0.26, y: h * 0.28), radius: w * 0.24,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addArc(center: CGPoint(x: w * 0.74, y: h * 0.28), radius: w * 0.24,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addCurve(to: CGPoint(x: w / 2, y: h * 0.96),
                   control1: CGPoint(x: w * 0.98, y: h * 0.48),
                   control2: CGPoint(x: w * 0.88, y: h * 0.72))
        p.closeSubpath()
        return p
    }
}

private struct GalaxySpiral: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let maxR = min(rect.width, rect.height) * 0.46
        for arm in 0..<2 {
            let off = Double(arm) * .pi
            var first = true
            var t = 0.30
            while t <= 3.7 {
                let rr = maxR * CGFloat(t / 3.7)
                let a = t * 1.55 + off
                let pnt = CGPoint(x: c.x + rr * CGFloat(cos(a)), y: c.y + rr * CGFloat(sin(a)))
                if first { path.move(to: pnt); first = false } else { path.addLine(to: pnt) }
                t += 0.11
            }
        }
        return path
    }
}

private struct BondSpark: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let cx = w / 2, cy = h / 2
        var p = Path()
        p.move(to: CGPoint(x: cx, y: 0))
        p.addQuadCurve(to: CGPoint(x: w, y: cy), control: CGPoint(x: cx + w * 0.12, y: cy - h * 0.12))
        p.addQuadCurve(to: CGPoint(x: cx, y: h), control: CGPoint(x: cx + w * 0.12, y: cy + h * 0.12))
        p.addQuadCurve(to: CGPoint(x: 0, y: cy), control: CGPoint(x: cx - w * 0.12, y: cy + h * 0.12))
        p.addQuadCurve(to: CGPoint(x: cx, y: 0), control: CGPoint(x: cx - w * 0.12, y: cy - h * 0.12))
        p.closeSubpath()
        return p
    }
}

private struct LotusShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let base = CGPoint(x: rect.midX, y: rect.maxY * 0.90)
        let H = rect.height
        let petals: [(Double, CGFloat, CGFloat)] = [
            (-54, 0.52, 0.16), (-28, 0.74, 0.18), (0, 0.92, 0.20), (28, 0.74, 0.18), (54, 0.52, 0.16)
        ]
        for (deg, len, wid) in petals {
            addPetal(&path, base: base, angleDeg: deg, length: H * len, width: H * wid)
        }
        return path
    }

    private func addPetal(_ path: inout Path, base: CGPoint, angleDeg: Double, length: CGFloat, width: CGFloat) {
        let a = (angleDeg - 90) * .pi / 180
        let dir = CGVector(dx: CGFloat(cos(a)), dy: CGFloat(sin(a)))
        let perp = CGVector(dx: -dir.dy, dy: dir.dx)
        let tip = CGPoint(x: base.x + dir.dx * length, y: base.y + dir.dy * length)
        let lc = CGPoint(x: base.x + dir.dx * length * 0.5 + perp.dx * width,
                         y: base.y + dir.dy * length * 0.5 + perp.dy * width)
        let rc = CGPoint(x: base.x + dir.dx * length * 0.5 - perp.dx * width,
                         y: base.y + dir.dy * length * 0.5 - perp.dy * width)
        path.move(to: base)
        path.addQuadCurve(to: tip, control: lc)
        path.addQuadCurve(to: base, control: rc)
    }
}

#Preview("Bond Icons") {
    HStack(spacing: 22) {
        ForEach(BondIconKind.allCases) { kind in
            VStack(spacing: 8) {
                BondDimensionIcon(kind: kind, size: 40)
                Text(kind.title)
                    .font(ABFont.body(11, weight: .bold))
                    .foregroundStyle(kind.tint)
            }
        }
    }
    .padding(40)
    .background(Color.black)
}

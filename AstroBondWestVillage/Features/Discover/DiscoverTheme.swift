import UserNotifications
import SwiftUI

/// Warm night / peach palette + shared building blocks for the Keşfet screens.
enum DT {
    static let bgTop = Color(hex: "#150F26")
    static let bgMid = Color(hex: "#1C1530")
    static let card = Color(hex: "#1C1530")
    static let accent = Color(hex: "#FFD9A0")
    static let accentSoft = Color(hex: "#F1C9A0")
    static let violet = Color(hex: "#C9A27A")   // warm line colour (name kept for call sites)
    static let cream = Color(hex: "#F6EBE1")
    static let ink = Color(hex: "#2B2237")
    static let inkSoft = Color(hex: "#6E6272")
    static let gold = Color(hex: "#E4B867")
}

/// Semantic colours that flip between dark pages and light (peach / cream) pages.
struct Th: Equatable {
    var light: Bool
    var primary: Color { light ? DT.ink : .white }
    var secondary: Color { light ? DT.inkSoft : Color.white.opacity(0.65) }
    var accent: Color { light ? Color(hex: "#9A5B3C") : DT.accent }
    var cardFill: Color { light ? Color.white.opacity(0.62) : Color.black.opacity(0.38) }
    var cardStroke: Color { light ? Color.white.opacity(0.85) : Color.white.opacity(0.16) }
    var chipOn: Color { light ? Color(hex: "#3A2E3F") : Color(hex: "#7A5A4A").opacity(0.7) }
    var chipOff: Color { light ? Color.black.opacity(0.05) : Color.white.opacity(0.08) }
}

private struct ThKey: EnvironmentKey { static let defaultValue = Th(light: false) }
extension EnvironmentValues {
    var th: Th { get { self[ThKey.self] } set { self[ThKey.self] = newValue } }
}

/// Page background — mirrors the tile it was opened from.
enum ScreenBackdrop: Equatable {
    case night
    case violet
    case peach
    case image(String)
    case gradient([String], icon: String?)
    var isLight: Bool { self == .peach }
}

private struct StarGen: RandomNumberGenerator {
    var s: UInt64
    mutating func next() -> UInt64 { s = s &* 6364136223846793005 &+ 1442695040888963407; return s }
}

struct ScreenBackdropView: View {
    var backdrop: ScreenBackdrop = .night
    var body: some View {
        ZStack {
            switch backdrop {
            case .night:
                night
            case .violet:
                violet
            case .peach:
                LinearGradient(colors: [Color(hex: "#FBEEE3"), Color(hex: "#F1D3BE")], startPoint: .top, endPoint: .bottom)
            case .image(let name):
                Color.clear.overlay { Image(name).resizable().scaledToFill() }.clipped()
                LinearGradient(colors: [.black.opacity(0.4), .black.opacity(0.82)], startPoint: .top, endPoint: .bottom)
            case .gradient(let hex, let icon):
                LinearGradient(colors: hex.map { Color(hex: $0) }, startPoint: .topLeading, endPoint: .bottomTrailing)
                if let icon {
                    Image(systemName: icon).font(.system(size: 220, weight: .ultraLight))
                        .foregroundStyle(Color.white.opacity(0.06)).offset(x: 90, y: -230)
                }
            }
        }
        .ignoresSafeArea()
    }

    private var violet: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#07040F"), Color(hex: "#150B2E"), Color(hex: "#07040F")], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Color(hex: "#7B5CFF").opacity(0.32), .clear], center: UnitPoint(x: 0.5, y: 0.5), startRadius: 0, endRadius: 330)
            Canvas { ctx, size in
                var g = StarGen(s: 23)
                for _ in 0..<90 {
                    let x = Double.random(in: 0...size.width, using: &g)
                    let y = Double.random(in: 0...size.height, using: &g)
                    let r = Double.random(in: 0.4...1.6, using: &g)
                    let o = Double.random(in: 0.2...0.9, using: &g)
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(Color(hex: "#E6DCFF").opacity(o)))
                }
            }
        }
    }

    private var night: some View {
        ZStack {
            LinearGradient(colors: [DT.bgTop, DT.bgMid, Color(hex: "#0F0B1D")], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Color(hex: "#7A5A4A").opacity(0.30), .clear], center: UnitPoint(x: 0.5, y: 0.1), startRadius: 0, endRadius: 400)
            Canvas { ctx, size in
                var g = StarGen(s: 11)
                for _ in 0..<70 {
                    let x = Double.random(in: 0...size.width, using: &g)
                    let y = Double.random(in: 0...size.height, using: &g)
                    let r = Double.random(in: 0.4...1.3, using: &g)
                    let o = Double.random(in: 0.2...0.7, using: &g)
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(.white.opacity(o)))
                }
            }
        }
    }
}

/// Standard page: purple backdrop, back button (+ optional share), optional title block.
struct DiscoverScreen<Content: View>: View {
    var backdrop: ScreenBackdrop = .night
    var title: String? = nil
    var subtitle: String? = nil
    var shareText: String? = nil
    @ViewBuilder var content: Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            ScreenBackdropView(backdrop: backdrop)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .semibold)).foregroundStyle(Th(light: backdrop.isLight).primary)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Th(light: backdrop.isLight).chipOff))
                                .overlay(Circle().strokeBorder(Th(light: backdrop.isLight).cardStroke, lineWidth: 1))
                        }
                        Spacer()
                        if let shareText {
                            ShareLink(item: shareText) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 15, weight: .medium)).foregroundStyle(Th(light: backdrop.isLight).primary)
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(Th(light: backdrop.isLight).chipOff))
                                    .overlay(Circle().strokeBorder(Th(light: backdrop.isLight).cardStroke, lineWidth: 1))
                            }
                        }
                    }
                    if let title {
                        Text(title)
                            .font(ABFont.display(34, weight: .regular)).foregroundStyle(Th(light: backdrop.isLight).primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let subtitle {
                        Text(subtitle).font(ABFont.body(14)).foregroundStyle(Th(light: backdrop.isLight).secondary)
                    }
                    content
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 130)
            }
        }
        .environment(\.th, Th(light: backdrop.isLight))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct PillChips: View {
    @Environment(\.th) private var th
    let items: [String]
    @Binding var selection: Int
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { i, t in
                    Button { selection = i } label: {
                        Text(t).font(ABFont.body(13, weight: .semibold))
                            .foregroundStyle(selection == i ? Color.white : th.secondary)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(Capsule().fill(selection == i ? th.chipOn : th.chipOff))
                            .overlay(Capsule().strokeBorder(th.cardStroke, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// Dark glass row used in all list screens.
struct DTRow<Leading: View>: View {
    @Environment(\.th) private var th
    var title: String
    var subtitle: String? = nil
    var caption: String? = nil
    var showChevron = true
    @ViewBuilder var leading: Leading

    var body: some View {
        HStack(spacing: 14) {
            leading
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(ABFont.body(15, weight: .semibold)).foregroundStyle(th.primary)
                    .fixedSize(horizontal: false, vertical: true)
                if let caption {
                    Text(caption).font(ABFont.body(11.5, weight: .medium)).foregroundStyle(th.accent)
                }
                if let subtitle {
                    Text(subtitle).font(ABFont.body(12)).foregroundStyle(th.secondary)
                        .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            if showChevron {
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(th.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(th.cardFill))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(th.cardStroke, lineWidth: 1))
    }
}

/// Small glowing sphere used as a list icon.
struct Orb: View {
    var hex: String
    var size: CGFloat = 46
    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [Color(hex: hex).opacity(0.95), Color(hex: hex).opacity(0.55), Color.black.opacity(0.85)],
                                 center: UnitPoint(x: 0.3, y: 0.28), startRadius: 1, endRadius: size * 0.85))
            .frame(width: size, height: size)
            .overlay(Circle().strokeBorder(Color.white.opacity(0.22), lineWidth: 0.8))
            .shadow(color: Color(hex: hex).opacity(0.5), radius: 8)
    }
}

struct EventOrb: View {
    let kind: SkyEvent.Kind
    var size: CGFloat = 46
    var body: some View {
        switch kind {
        case .fullMoon: Orb(hex: "#CFC2F2", size: size)
        case .newMoon: Orb(hex: "#4B3C80", size: size)
        case .retrograde: Orb(hex: "#C0674F", size: size)
        case .eclipse:
            ZStack {
                Circle().fill(RadialGradient(colors: [Color(hex: "#FFD9A0").opacity(0.9), .clear], center: .center, startRadius: size * 0.3, endRadius: size * 0.75))
                    .frame(width: size * 1.4, height: size * 1.4)
                Circle().fill(Color.black).frame(width: size * 0.8, height: size * 0.8)
            }.frame(width: size, height: size)
        case .solstice: Orb(hex: "#E8B867", size: size)
        }
    }
}

/// Navy tarot card with gold foil and a glowing symbol.
struct TarotCardFace: View {
    var symbol: String
    var width: CGFloat = 110
    var glow: Bool = false
    var body: some View {
        let h = width * 1.5
        let gold = DT.gold
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.1, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: "#1B2150"), Color(hex: "#0B0E2A")], startPoint: .top, endPoint: .bottom))
            RoundedRectangle(cornerRadius: width * 0.1, style: .continuous)
                .strokeBorder(LinearGradient(colors: [Color(hex: "#F6DFA8"), gold.opacity(0.6)], startPoint: .top, endPoint: .bottom), lineWidth: 1.4)
            RoundedRectangle(cornerRadius: width * 0.07, style: .continuous)
                .strokeBorder(gold.opacity(0.4), lineWidth: 0.8).padding(width * 0.06)
            Circle().strokeBorder(gold.opacity(0.35), lineWidth: 0.8).frame(width: width * 0.66, height: width * 0.66)
            Circle().strokeBorder(gold.opacity(0.2), lineWidth: 0.8).frame(width: width * 0.86, height: width * 0.86)
            Image(systemName: symbol)
                .font(.system(size: width * 0.30, weight: .ultraLight))
                .foregroundStyle(Color(hex: "#F1CE86"))
                .shadow(color: Color(hex: "#F1CE86").opacity(0.8), radius: width * 0.08)
            Image(systemName: "sparkle").font(.system(size: width * 0.09)).foregroundStyle(Color(hex: "#F1CE86")).offset(y: -h * 0.36)
            Image(systemName: "sparkle").font(.system(size: width * 0.09)).foregroundStyle(Color(hex: "#F1CE86")).offset(y: h * 0.36)
        }
        .frame(width: width, height: h)
        .shadow(color: glow ? gold.opacity(0.7) : .black.opacity(0.4), radius: glow ? 22 : 9)
    }
}

enum DailyMessageNotifier {
    /// Schedules a gentle daily "your card is waiting" notification (09:00). Asks permission once.
    static func scheduleDaily() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "AstroBond"
            content.body = "Bugünün mesajı seni bekliyor ✨ Kartını seç; evrenin bugün sana söylediği şeyi keşfet."
            content.sound = .default
            var comps = DateComponents(); comps.hour = 9; comps.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            center.removePendingNotificationRequests(withIdentifiers: ["daily.message"])
            center.add(UNNotificationRequest(identifier: "daily.message", content: content, trigger: trigger))
        }
    }
}


/// Ornate violet tarot card (moon / sun emblems) with lilac foil edges.
struct VioletTarotCard: View {
    enum Emblem { case crescent, sun }
    var emblem: Emblem
    var width: CGFloat = 110
    var glow: Bool = false

    private let foil = Color(hex: "#E9C9F2")
    private let lilac = Color(hex: "#9B86FF")
    private let rose = Color(hex: "#E8BCD2")

    var body: some View {
        let h = width * 1.66
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.1, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: "#1D1042"), Color(hex: "#08051C")], startPoint: .top, endPoint: .bottom))
            RoundedRectangle(cornerRadius: width * 0.1, style: .continuous)
                .strokeBorder(LinearGradient(colors: [foil, lilac.opacity(0.7), foil.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.7)
            RoundedRectangle(cornerRadius: width * 0.07, style: .continuous)
                .strokeBorder(foil.opacity(0.35), lineWidth: 0.8).padding(width * 0.055)
            // arched inner frame
            Capsule().strokeBorder(foil.opacity(0.30), lineWidth: 0.9)
                .frame(width: width * 0.74, height: h * 0.80)
            // fine orbit lines
            ForEach(0..<3, id: \.self) { i in
                Ellipse().strokeBorder(lilac.opacity(0.18 - Double(i) * 0.04), lineWidth: 0.7)
                    .frame(width: width * (0.55 + CGFloat(i) * 0.12), height: h * (0.52 + CGFloat(i) * 0.12))
                    .rotationEffect(.degrees(Double(i) * 28 - 20))
            }
            // star dots
            ForEach(0..<7, id: \.self) { i in
                Circle().fill(foil.opacity(0.7)).frame(width: 1.8, height: 1.8)
                    .offset(x: CGFloat([-0.28, 0.25, -0.12, 0.3, -0.3, 0.1, 0.0][i]) * width,
                            y: CGFloat([-0.36, -0.25, 0.33, 0.2, 0.05, -0.4, 0.42][i]) * h)
            }
            emblemView
        }
        .frame(width: width, height: h)
        .shadow(color: glow ? lilac.opacity(0.95) : lilac.opacity(0.45), radius: glow ? 20 : 10)
    }

    @ViewBuilder private var emblemView: some View {
        switch emblem {
        case .crescent:
            ZStack {
                Circle().fill(rose.opacity(0.25)).frame(width: width * 0.5, height: width * 0.5).blur(radius: 10)
                ZStack {
                    Circle().fill(LinearGradient(colors: [Color(hex: "#F4D6E4"), rose], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Circle().fill(Color.black).frame(width: width * 0.30, height: width * 0.30)
                        .offset(x: width * 0.075, y: -width * 0.02).blendMode(.destinationOut)
                }
                .frame(width: width * 0.30, height: width * 0.30)
                .compositingGroup()
                .shadow(color: rose.opacity(0.9), radius: 5)
            }
            .offset(y: -width * 0.02)
        case .sun:
            ZStack {
                Circle().fill(RadialGradient(colors: [rose.opacity(0.55), .clear], center: .center, startRadius: 0, endRadius: width * 0.42))
                    .frame(width: width * 0.9, height: width * 0.9)
                ForEach(0..<24, id: \.self) { i in
                    Capsule().fill(LinearGradient(colors: [rose, rose.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                        .frame(width: i % 2 == 0 ? 1.8 : 1.1, height: width * (i % 2 == 0 ? 0.22 : 0.15))
                        .offset(y: -width * 0.22)
                        .rotationEffect(.degrees(Double(i) * 15))
                }
                Circle().strokeBorder(rose, lineWidth: 1.4).frame(width: width * 0.28, height: width * 0.28)
                Circle().fill(RadialGradient(colors: [Color.white, rose], center: .center, startRadius: 0, endRadius: width * 0.1))
                    .frame(width: width * 0.16, height: width * 0.16)
                    .shadow(color: rose, radius: 6)
            }
        }
    }
}

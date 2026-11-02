import SwiftUI

enum CartoonAvatar: String, CaseIterable, Identifiable, Codable, Sendable {
    case m01, m02, m03, m04, m05, m06, m07, m08, m09, m10
    case m11, m12, m13, m14, m15, m16, m17, m18
    case f01, f02, f03, f04, f05, f06, f07, f08, f09, f10
    case f11, f12, f13, f14, f15, f16, f17, f18

    var id: String { rawValue }

    var isMalePack: Bool { rawValue.hasPrefix("m") }

    static func options(for gender: Gender) -> [CartoonAvatar] {
        switch gender {
        case .man:
            return allCases.filter(\.isMalePack)
        case .woman:
            return allCases.filter { !$0.isMalePack }
        case .nonBinary, .other, .preferNotSay:
            return Array(allCases)
        }
    }

    static func from(id: String?) -> CartoonAvatar? {
        guard let id else { return nil }
        return CartoonAvatar(rawValue: id)
    }

    fileprivate var style: AvatarStyle {
        switch self {
        case .m01: return .init(skin: "#F0C7A0", hairColor: "#2B1A12", iris: "#5B3A29", blush: "#F4A09A", bg: ["#3A2F55", "#1C1630"], cloth: "#4A3A72", hair: .shortFade, eyes: .soft, smile: .warm, accessory: .none)
        case .m02: return .init(skin: "#E8B888", hairColor: "#111111", iris: "#3D5A80", blush: "#E8918A", bg: ["#1F3A4A", "#102028"], cloth: "#1A4A5C", hair: .spiky, eyes: .bright, smile: .grin, accessory: .none)
        case .m03: return .init(skin: "#C68642", hairColor: "#1A100A", iris: "#2F2A26", blush: "#D9786C", bg: ["#4A2C3A", "#24141C"], cloth: "#5C3048", hair: .curl, eyes: .soft, smile: .smirk, accessory: .earring)
        case .m04: return .init(skin: "#FFD7B5", hairColor: "#6B4423", iris: "#4A7C59", blush: "#F2A39A", bg: ["#2A3F36", "#14241E"], cloth: "#2E5648", hair: .wavyShort, eyes: .bright, smile: .warm, accessory: .none)
        case .m05: return .init(skin: "#D4A574", hairColor: "#0E0E0E", iris: "#6B4E3D", blush: "#E08A80", bg: ["#3A3420", "#1C1810"], cloth: "#3A3830", hair: .undercut, eyes: .cool, smile: .smirk, accessory: .glasses)
        case .m06: return .init(skin: "#8D5524", hairColor: "#0A0A0A", iris: "#3E2723", blush: "#C96B60", bg: ["#3A2450", "#1A1028"], cloth: "#4A2870", hair: .afro, eyes: .bright, smile: .grin, accessory: .none)
        case .m07: return .init(skin: "#F3D0C0", hairColor: "#A67C52", iris: "#5C6BC0", blush: "#F0A8A0", bg: ["#243848", "#121E28"], cloth: "#2A4860", hair: .wavyShort, eyes: .soft, smile: .warm, accessory: .none)
        case .m08: return .init(skin: "#C98A5A", hairColor: "#3E2723", iris: "#AD1457", blush: "#E07A72", bg: ["#4A2030", "#241018"], cloth: "#6A2848", hair: .curl, eyes: .heart, smile: .warm, accessory: .earring)
        case .m09: return .init(skin: "#E8B898", hairColor: "#2F1E14", iris: "#00838F", blush: "#E89890", bg: ["#1A3338", "#0E1C20"], cloth: "#1A4850", hair: .spiky, eyes: .starry, smile: .grin, accessory: .none)
        case .m10: return .init(skin: "#B56B45", hairColor: "#1C100A", iris: "#455A64", blush: "#D08078", bg: ["#1C3330", "#0E1C1A"], cloth: "#244840", hair: .baldish, eyes: .cool, smile: .smirk, accessory: .glasses)
        case .m11: return .init(skin: "#F2C2A0", hairColor: "#1A120C", iris: "#2E7D32", blush: "#E89890", bg: ["#2A2040", "#141024"], cloth: "#3A2860", hair: .buzz, eyes: .bright, smile: .closed, accessory: .none)
        case .m12: return .init(skin: "#C68642", hairColor: "#0D0D0D", iris: "#1565C0", blush: "#D9786C", bg: ["#102838", "#08141C"], cloth: "#183848", hair: .loc, eyes: .soft, smile: .warm, accessory: .hoops)
        case .m13: return .init(skin: "#FFD7B5", hairColor: "#4A3728", iris: "#6A1B9A", blush: "#F2A39A", bg: ["#3A2048", "#1C1028"], cloth: "#4A2868", hair: .shag, eyes: .lash, smile: .grin, accessory: .none)
        case .m14: return .init(skin: "#8D5524", hairColor: "#111111", iris: "#EF6C00", blush: "#C96B60", bg: ["#3A2418", "#1C120C"], cloth: "#4A3020", hair: .afro, eyes: .cool, smile: .smirk, accessory: .roundGlasses)
        case .m15: return .init(skin: "#E8B888", hairColor: "#C9A227", iris: "#00838F", blush: "#E8918A", bg: ["#1A3040", "#0C1820"], cloth: "#204858", hair: .shortFade, eyes: .starry, smile: .warm, accessory: .none)
        case .m16: return .init(skin: "#D4A574", hairColor: "#2B1A12", iris: "#3D5A80", blush: "#E08A80", bg: ["#241828", "#120C18"], cloth: "#382848", hair: .undercut, eyes: .bright, smile: .grin, accessory: .noseStud)
        case .m17: return .init(skin: "#F3D0C0", hairColor: "#6B4423", iris: "#AD1457", blush: "#F0A8A0", bg: ["#3A1830", "#1C0C18"], cloth: "#501838", hair: .wavyShort, eyes: .heart, smile: .warm, accessory: .beanie)
        case .m18: return .init(skin: "#B56B45", hairColor: "#0A0A0A", iris: "#4A7C59", blush: "#D08078", bg: ["#1C2A20", "#0C1610"], cloth: "#243828", hair: .loc, eyes: .soft, smile: .closed, accessory: .earring)

        case .f01: return .init(skin: "#F0C7A0", hairColor: "#4A148C", iris: "#6A1B9A", blush: "#FF8A9A", bg: ["#3A2448", "#1C1028"], cloth: "#4A2870", hair: .bob, eyes: .lash, smile: .warm, accessory: .earring)
        case .f02: return .init(skin: "#FFD7B5", hairColor: "#1A1A1A", iris: "#1565C0", blush: "#FF9AA8", bg: ["#1E3040", "#101820"], cloth: "#284860", hair: .long, eyes: .soft, smile: .warm, accessory: .none)
        case .f03: return .init(skin: "#E8B888", hairColor: "#BF360C", iris: "#EF6C00", blush: "#FF8F80", bg: ["#3A2A18", "#1C140C"], cloth: "#5C3818", hair: .pony, eyes: .bright, smile: .grin, accessory: .earring)
        case .f04: return .init(skin: "#C68642", hairColor: "#212121", iris: "#7B1FA2", blush: "#E07A72", bg: ["#322040", "#180F20"], cloth: "#482860", hair: .bun, eyes: .soft, smile: .smirk, accessory: .none)
        case .f05: return .init(skin: "#F3D0C0", hairColor: "#6D4C41", iris: "#2E7D32", blush: "#FF9AA8", bg: ["#1E3224", "#101C14"], cloth: "#284830", hair: .wavyLong, eyes: .lash, smile: .warm, accessory: .earring)
        case .f06: return .init(skin: "#D4A574", hairColor: "#880E4F", iris: "#C2185B", blush: "#FF8A9A", bg: ["#3A1824", "#1C0C12"], cloth: "#581830", hair: .long, eyes: .heart, smile: .grin, accessory: .none)
        case .f07: return .init(skin: "#8D5524", hairColor: "#0D0D0D", iris: "#00695C", blush: "#D07068", bg: ["#1A302C", "#0E1A18"], cloth: "#204840", hair: .afro, eyes: .soft, smile: .warm, accessory: .hoops)
        case .f08: return .init(skin: "#E8B898", hairColor: "#3E2723", iris: "#EC407A", blush: "#FF9AA8", bg: ["#3A2030", "#1C1018"], cloth: "#502038", hair: .bob, eyes: .starry, smile: .warm, accessory: .none)
        case .f09: return .init(skin: "#FFCCBC", hairColor: "#5D4037", iris: "#5C6BC0", blush: "#FF9AA8", bg: ["#222840", "#121420"], cloth: "#303858", hair: .pony, eyes: .bright, smile: .smirk, accessory: .glasses)
        case .f10: return .init(skin: "#B56B45", hairColor: "#4A148C", iris: "#FFB300", blush: "#E08A80", bg: ["#2E2818", "#16140C"], cloth: "#484020", hair: .bun, eyes: .cool, smile: .grin, accessory: .earring)
        case .f11: return .init(skin: "#F0C7A0", hairColor: "#1A1A1A", iris: "#1565C0", blush: "#FF8A9A", bg: ["#1A2840", "#0C1420"], cloth: "#243050", hair: .pixie, eyes: .lash, smile: .warm, accessory: .none)
        case .f12: return .init(skin: "#C68642", hairColor: "#3E2723", iris: "#2E7D32", blush: "#E07A72", bg: ["#1C3024", "#0C1812"], cloth: "#284838", hair: .braid, eyes: .soft, smile: .closed, accessory: .hoops)
        case .f13: return .init(skin: "#FFD7B5", hairColor: "#BF360C", iris: "#6A1B9A", blush: "#FF9AA8", bg: ["#3A2048", "#1C1028"], cloth: "#4A2870", hair: .twinTail, eyes: .bright, smile: .grin, accessory: .headband)
        case .f14: return .init(skin: "#8D5524", hairColor: "#1A100A", iris: "#C2185B", blush: "#D07068", bg: ["#301820", "#180C10"], cloth: "#481828", hair: .hijab, eyes: .lash, smile: .warm, accessory: .none)
        case .f15: return .init(skin: "#E8B888", hairColor: "#880E4F", iris: "#00838F", blush: "#FF8F80", bg: ["#183038", "#0C181C"], cloth: "#204850", hair: .bangs, eyes: .starry, smile: .smirk, accessory: .roundGlasses)
        case .f16: return .init(skin: "#F3D0C0", hairColor: "#4A148C", iris: "#EF6C00", blush: "#FF9AA8", bg: ["#3A2410", "#1C1208"], cloth: "#5C3810", hair: .wavyLong, eyes: .heart, smile: .grin, accessory: .noseStud)
        case .f17: return .init(skin: "#D4A574", hairColor: "#0D0D0D", iris: "#5C6BC0", blush: "#FF8A9A", bg: ["#202040", "#101028"], cloth: "#303060", hair: .pixie, eyes: .cool, smile: .warm, accessory: .beanie)
        case .f18: return .init(skin: "#B56B45", hairColor: "#6D4C41", iris: "#7B1FA2", blush: "#E08A80", bg: ["#2A1830", "#140C18"], cloth: "#3A2048", hair: .braid, eyes: .lash, smile: .closed, accessory: .earring)
        }
    }
}

private struct AvatarStyle {
    enum Hair {
        case shortFade, spiky, curl, wavyShort, afro, baldish, bob, long, pony, bun, wavyLong
        case loc, pixie, braid, twinTail, buzz, shag, bangs, hijab, undercut
    }
    enum Eyes { case soft, bright, cool, heart, starry, lash }
    enum Smile { case warm, grin, smirk, closed }
    enum Accessory { case none, earring, glasses, hoops, roundGlasses, headband, noseStud, beanie }

    let skin: String
    let hairColor: String
    let iris: String
    let blush: String
    let bg: [String]
    let cloth: String
    let hair: Hair
    let eyes: Eyes
    let smile: Smile
    let accessory: Accessory

    init(skin: String, hairColor: String, iris: String, blush: String, bg: [String], cloth: String, hair: Hair, eyes: Eyes, smile: Smile, accessory: Accessory) {
        self.skin = skin
        self.hairColor = hairColor
        self.iris = iris
        self.blush = blush
        self.bg = bg
        self.cloth = cloth
        self.hair = hair
        self.eyes = eyes
        self.smile = smile
        self.accessory = accessory
    }
}

struct CartoonAvatarView: View {
    let avatar: CartoonAvatar
    var size: CGFloat = 64

    private var s: AvatarStyle { avatar.style }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: s.bg.map { Color(hex: $0) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: size * 0.28, height: size * 0.28)
                .offset(x: -size * 0.18, y: -size * 0.22)
                .blur(radius: size * 0.04)

            Circle()
                .fill(Color(hex: s.skin).opacity(0.22))
                .frame(width: size * 0.78, height: size * 0.78)
                .blur(radius: size * 0.06)
                .offset(y: size * 0.04)

            collar
            backHair
            ears
            neck
            face
            frontHair
            accessoryLayer
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var collar: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [Color(hex: s.cloth), Color(hex: s.cloth).opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size * 0.72, height: size * 0.28)
            .offset(y: size * 0.42)
    }

    private var ears: some View {
        HStack(spacing: size * 0.52) {
            Ellipse().fill(Color(hex: s.skin)).frame(width: size * 0.11, height: size * 0.15)
            Ellipse().fill(Color(hex: s.skin)).frame(width: size * 0.11, height: size * 0.15)
        }
        .offset(y: size * 0.08)
    }

    private var neck: some View {
        Capsule()
            .fill(Color(hex: s.skin).opacity(0.95))
            .frame(width: size * 0.22, height: size * 0.18)
            .offset(y: size * 0.34)
    }

    private var face: some View {
        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: s.skin).opacity(1),
                            Color(hex: s.skin).opacity(0.88)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.58, height: size * 0.66)
                .offset(y: size * 0.05)
                .shadow(color: .black.opacity(0.14), radius: size * 0.03, y: size * 0.02)

            Ellipse()
                .fill(Color.white.opacity(0.18))
                .frame(width: size * 0.22, height: size * 0.12)
                .offset(x: -size * 0.08, y: -size * 0.04)
                .blur(radius: size * 0.02)

            HStack(spacing: size * 0.28) {
                Ellipse().fill(Color(hex: s.blush).opacity(0.48)).frame(width: size * 0.12, height: size * 0.075)
                Ellipse().fill(Color(hex: s.blush).opacity(0.48)).frame(width: size * 0.12, height: size * 0.075)
            }
            .offset(y: size * 0.14)

            eyesRow

            Capsule()
                .fill(Color(hex: s.skin).opacity(0.55))
                .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 0.6))
                .frame(width: size * 0.05, height: size * 0.07)
                .offset(y: size * 0.12)

            mouth
        }
    }

    private var eyesRow: some View {
        HStack(spacing: size * 0.12) {
            eye
            eye
        }
        .offset(y: size * 0.0)
    }

    @ViewBuilder
    private var eye: some View {
        switch s.eyes {
        case .heart:
            Text("♥")
                .font(.system(size: size * 0.13))
                .foregroundStyle(Color(hex: "#FF5C8A"))
        case .starry:
            Text("✦")
                .font(.system(size: size * 0.13, weight: .bold))
                .foregroundStyle(Color(hex: s.iris))
        default:
            ZStack {
                Ellipse()
                    .fill(Color.white)
                    .frame(
                        width: size * (s.eyes == .bright || s.eyes == .lash ? 0.135 : 0.12),
                        height: size * (s.eyes == .cool ? 0.08 : 0.112)
                    )
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: s.iris).opacity(0.7), Color(hex: s.iris)],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.045
                        )
                    )
                    .frame(width: size * 0.078, height: size * 0.078)
                Circle()
                    .fill(Color.black.opacity(0.88))
                    .frame(width: size * 0.036, height: size * 0.036)
                Circle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: size * 0.02, height: size * 0.02)
                    .offset(x: -size * 0.015, y: -size * 0.015)
                if s.eyes == .lash {
                    HStack(spacing: size * 0.012) {
                        ForEach(0..<4, id: \.self) { i in
                            Capsule()
                                .fill(Color.black.opacity(0.72))
                                .frame(width: size * 0.012, height: size * 0.045)
                                .rotationEffect(.degrees(Double(i) * 14 - 21))
                        }
                    }
                    .offset(y: -size * 0.07)
                }
                Capsule()
                    .fill(Color(hex: s.hairColor).opacity(0.88))
                    .frame(width: size * 0.11, height: size * 0.016)
                    .offset(y: -size * 0.078)
                    .rotationEffect(.degrees(s.eyes == .cool ? -8 : (s.eyes == .lash ? 4 : 0)))
            }
        }
    }

    @ViewBuilder
    private var mouth: some View {
        switch s.smile {
        case .warm:
            Capsule()
                .fill(Color(hex: "#C75B6A"))
                .frame(width: size * 0.16, height: size * 0.045)
                .overlay(
                    Capsule()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: size * 0.1, height: size * 0.012)
                        .offset(y: -size * 0.008)
                )
                .offset(y: size * 0.22)
        case .grin:
            Capsule()
                .fill(Color(hex: "#B84A5A"))
                .frame(width: size * 0.2, height: size * 0.08)
                .overlay(
                    Capsule()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: size * 0.15, height: size * 0.025)
                        .offset(y: -size * 0.012)
                )
                .offset(y: size * 0.22)
        case .smirk:
            Capsule()
                .fill(Color(hex: "#C75B6A"))
                .frame(width: size * 0.14, height: size * 0.035)
                .rotationEffect(.degrees(14))
                .offset(x: size * 0.03, y: size * 0.22)
        case .closed:
            Capsule()
                .stroke(Color(hex: "#C75B6A"), lineWidth: size * 0.018)
                .frame(width: size * 0.14, height: size * 0.04)
                .offset(y: size * 0.22)
        }
    }

    @ViewBuilder
    private var backHair: some View {
        let c = Color(hex: s.hairColor)
        switch s.hair {
        case .long, .wavyLong, .bangs:
            Capsule().fill(c).frame(width: size * 0.74, height: size * 0.82).offset(y: size * 0.12)
        case .afro:
            Circle().fill(c).frame(width: size * 0.92, height: size * 0.92).offset(y: -size * 0.02)
            Circle().fill(c.opacity(0.85)).frame(width: size * 0.38).offset(x: -size * 0.28, y: size * 0.04)
            Circle().fill(c.opacity(0.85)).frame(width: size * 0.38).offset(x: size * 0.28, y: size * 0.04)
        case .pony:
            Capsule().fill(c).frame(width: size * 0.18, height: size * 0.44)
                .rotationEffect(.degrees(28)).offset(x: size * 0.3, y: -size * 0.18)
        case .twinTail:
            Capsule().fill(c).frame(width: size * 0.16, height: size * 0.46)
                .rotationEffect(.degrees(-26)).offset(x: -size * 0.3, y: -size * 0.12)
            Capsule().fill(c).frame(width: size * 0.16, height: size * 0.46)
                .rotationEffect(.degrees(26)).offset(x: size * 0.3, y: -size * 0.12)
        case .braid:
            Capsule().fill(c).frame(width: size * 0.16, height: size * 0.55)
                .offset(x: size * 0.28, y: size * 0.16)
            VStack(spacing: -size * 0.02) {
                ForEach(0..<4, id: \.self) { _ in
                    Circle().fill(c).frame(width: size * 0.14)
                }
            }
            .offset(x: size * 0.28, y: size * 0.12)
        case .loc:
            HStack(spacing: size * 0.02) {
                ForEach(0..<5, id: \.self) { i in
                    Capsule().fill(c)
                        .frame(width: size * 0.08, height: size * (0.42 + CGFloat(i % 2) * 0.1))
                        .offset(y: size * 0.06)
                }
            }
            .offset(y: -size * 0.22)
        case .hijab:
            Ellipse().fill(c).frame(width: size * 0.92, height: size * 0.95).offset(y: size * 0.04)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var frontHair: some View {
        let c = Color(hex: s.hairColor)
        let shine = Color.white.opacity(0.2)
        switch s.hair {
        case .shortFade, .buzz:
            shortFadeHair(c, shine)
        case .undercut:
            ZStack {
                Capsule().fill(c).frame(width: size * 0.58, height: size * 0.26).offset(y: -size * 0.2)
                Capsule().fill(c).frame(width: size * 0.22, height: size * 0.18).offset(x: size * 0.18, y: -size * 0.08)
                Capsule().fill(shine).frame(width: size * 0.16, height: size * 0.05).offset(x: -size * 0.08, y: -size * 0.24)
            }
        case .spiky:
            spikyHair(c)
        case .curl, .wavyShort, .shag:
            curlHair(c)
        case .baldish:
            Capsule().fill(c.opacity(0.9)).frame(width: size * 0.28, height: size * 0.1).offset(y: -size * 0.26)
        case .afro, .loc:
            EmptyView()
        case .bob, .pixie:
            bobHair(c, shine)
        case .long, .wavyLong:
            longBangs(c)
        case .bangs:
            ZStack {
                longBangs(c)
                HStack(spacing: size * 0.01) {
                    Capsule().fill(c).frame(width: size * 0.12, height: size * 0.2).rotationEffect(.degrees(-8))
                    Capsule().fill(c).frame(width: size * 0.14, height: size * 0.18)
                    Capsule().fill(c).frame(width: size * 0.12, height: size * 0.2).rotationEffect(.degrees(8))
                }
                .offset(y: -size * 0.04)
            }
        case .pony, .twinTail:
            ponyFront(c)
        case .bun:
            bunHair(c, shine)
        case .braid:
            Capsule().fill(c).frame(width: size * 0.64, height: size * 0.26).offset(y: -size * 0.16)
        case .hijab:
            ZStack {
                Capsule().fill(c).frame(width: size * 0.7, height: size * 0.28).offset(y: -size * 0.16)
                HStack {
                    Capsule().fill(c).frame(width: size * 0.14, height: size * 0.42)
                    Spacer(minLength: 0)
                    Capsule().fill(c).frame(width: size * 0.14, height: size * 0.42)
                }
                .frame(width: size * 0.7)
                .offset(y: size * 0.08)
            }
        }
    }

    private func shortFadeHair(_ c: Color, _ shine: Color) -> some View {
        ZStack {
            Capsule().fill(c).frame(width: size * 0.62, height: size * 0.28).offset(y: -size * 0.2)
            Capsule().fill(shine).frame(width: size * 0.2, height: size * 0.06).offset(x: -size * 0.1, y: -size * 0.24)
        }
    }

    private func spikyHair(_ c: Color) -> some View {
        HStack(spacing: size * 0.012) {
            ForEach(0..<7, id: \.self) { i in
                let h = size * (0.18 + CGFloat(i % 3) * 0.055)
                Capsule().fill(c)
                    .frame(width: size * 0.075, height: h)
                    .rotationEffect(.degrees(Double(i) * 7 - 21))
            }
        }
        .offset(y: -size * 0.28)
    }

    private func curlHair(_ c: Color) -> some View {
        ZStack {
            Capsule().fill(c).frame(width: size * 0.72, height: size * 0.32).offset(y: -size * 0.18)
            HStack {
                Circle().fill(c).frame(width: size * 0.2)
                Spacer(minLength: 0)
                Circle().fill(c).frame(width: size * 0.2)
            }
            .frame(width: size * 0.74)
            .offset(y: -size * 0.02)
        }
    }

    private func bobHair(_ c: Color, _ shine: Color) -> some View {
        ZStack {
            Capsule().fill(c).frame(width: size * 0.74, height: size * 0.38).offset(y: -size * 0.12)
            Capsule().fill(shine).frame(width: size * 0.18, height: size * 0.05).offset(x: -size * 0.12, y: -size * 0.2)
        }
    }

    private func longBangs(_ c: Color) -> some View {
        ZStack {
            Capsule().fill(c).frame(width: size * 0.66, height: size * 0.3).offset(y: -size * 0.16)
            HStack(spacing: size * 0.02) {
                Capsule().fill(c).frame(width: size * 0.14, height: size * 0.16).rotationEffect(.degrees(-12))
                Capsule().fill(c).frame(width: size * 0.16, height: size * 0.14)
                Capsule().fill(c).frame(width: size * 0.14, height: size * 0.16).rotationEffect(.degrees(12))
            }
            .offset(y: -size * 0.08)
        }
    }

    private func ponyFront(_ c: Color) -> some View {
        ZStack {
            Capsule().fill(c).frame(width: size * 0.64, height: size * 0.28).offset(y: -size * 0.18)
            Capsule().fill(c).frame(width: size * 0.2, height: size * 0.12).offset(y: -size * 0.08)
        }
    }

    private func bunHair(_ c: Color, _ shine: Color) -> some View {
        ZStack {
            Capsule().fill(c).frame(width: size * 0.64, height: size * 0.26).offset(y: -size * 0.16)
            Circle().fill(c).frame(width: size * 0.26).offset(y: -size * 0.34)
            Circle().fill(shine).frame(width: size * 0.08).offset(x: -size * 0.04, y: -size * 0.38)
        }
    }

    @ViewBuilder
    private var accessoryLayer: some View {
        let gold = LinearGradient(colors: [Color(hex: "#F3E5AB"), Color(hex: "#D4AF37")], startPoint: .top, endPoint: .bottom)
        switch s.accessory {
        case .none:
            EmptyView()
        case .earring:
            Circle().fill(gold)
                .frame(width: size * 0.07, height: size * 0.07)
                .offset(x: size * 0.28, y: size * 0.16)
        case .hoops:
            Circle().stroke(Color(hex: "#D4AF37"), lineWidth: size * 0.018)
                .frame(width: size * 0.1, height: size * 0.1)
                .offset(x: size * 0.29, y: size * 0.18)
            Circle().stroke(Color(hex: "#D4AF37"), lineWidth: size * 0.018)
                .frame(width: size * 0.1, height: size * 0.1)
                .offset(x: -size * 0.29, y: size * 0.18)
        case .glasses:
            HStack(spacing: size * 0.04) {
                Circle().stroke(Color.white.opacity(0.88), lineWidth: size * 0.016)
                    .frame(width: size * 0.16, height: size * 0.16)
                Circle().stroke(Color.white.opacity(0.88), lineWidth: size * 0.016)
                    .frame(width: size * 0.16, height: size * 0.16)
            }
            .overlay(Rectangle().fill(Color.white.opacity(0.7)).frame(width: size * 0.05, height: size * 0.012))
        case .roundGlasses:
            HStack(spacing: size * 0.03) {
                Circle().fill(Color.white.opacity(0.12))
                    .overlay(Circle().stroke(Color(hex: "#D4AF37"), lineWidth: size * 0.016))
                    .frame(width: size * 0.17, height: size * 0.17)
                Circle().fill(Color.white.opacity(0.12))
                    .overlay(Circle().stroke(Color(hex: "#D4AF37"), lineWidth: size * 0.016))
                    .frame(width: size * 0.17, height: size * 0.17)
            }
        case .headband:
            Capsule()
                .fill(ABColor.lavenderSoft.opacity(0.9))
                .frame(width: size * 0.62, height: size * 0.07)
                .offset(y: -size * 0.18)
        case .noseStud:
            Circle().fill(gold)
                .frame(width: size * 0.035, height: size * 0.035)
                .offset(x: size * 0.04, y: size * 0.13)
        case .beanie:
            Capsule()
                .fill(Color(hex: s.cloth))
                .frame(width: size * 0.72, height: size * 0.28)
                .offset(y: -size * 0.28)
            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: size * 0.1)
                .offset(y: -size * 0.4)
        }
    }
}

struct CartoonAvatarPicker: View {
    let gender: Gender
    @Binding var selection: CartoonAvatar?

    private let columns = [GridItem(.adaptive(minimum: 64), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AVATARIN")
                .font(ABFont.label(12))
                .foregroundStyle(ABColor.inkMuted)
            Text("Yüzler arasından seç — gerçek fotoğraf 10 mesaj sonra açılana kadar profil fotoğrafın olur.")
                .font(ABFont.body(12))
                .foregroundStyle(ABColor.inkMuted.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(CartoonAvatar.options(for: gender)) { avatar in
                    Button {
                        selection = avatar
                    } label: {
                        CartoonAvatarView(avatar: avatar, size: 64)
                            .overlay(
                                Circle()
                                    .stroke(
                                        selection == avatar
                                            ? ABColor.lavenderSoft
                                            : Color.white.opacity(0.18),
                                        lineWidth: selection == avatar ? 3 : 1
                                    )
                            )
                            .shadow(
                                color: ABColor.lavender.opacity(selection == avatar ? 0.4 : 0.08),
                                radius: selection == avatar ? 10 : 4, y: 3
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onChange(of: gender) { _, newGender in
            if let selected = selection,
               !CartoonAvatar.options(for: newGender).contains(selected) {
                selection = nil
            }
        }
    }
}

// CartoonAvatar.swift
// 10 male + 10 female soft illustrated face presets (no ML / no API).

import SwiftUI

enum CartoonAvatar: String, CaseIterable, Identifiable, Codable, Sendable {
    case m01, m02, m03, m04, m05, m06, m07, m08, m09, m10
    case f01, f02, f03, f04, f05, f06, f07, f08, f09, f10

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
        case .m01: return .init(skin: "#F0C7A0", hair: "#2B1A12", iris: "#5B3A29", blush: "#F4A09A", bg: ["#3A2F55", "#1C1630"], hair: .shortFade, eyes: .soft, smile: .warm, accessory: .none)
        case .m02: return .init(skin: "#E8B888", hair: "#111111", iris: "#3D5A80", blush: "#E8918A", bg: ["#1F3A4A", "#102028"], hair: .spiky, eyes: .bright, smile: .grin, accessory: .none)
        case .m03: return .init(skin: "#C68642", hair: "#1A100A", iris: "#2F2A26", blush: "#D9786C", bg: ["#4A2C3A", "#24141C"], hair: .curl, eyes: .soft, smile: .smirk, accessory: .earring)
        case .m04: return .init(skin: "#FFD7B5", hair: "#6B4423", iris: "#4A7C59", blush: "#F2A39A", bg: ["#2A3F36", "#14241E"], hair: .wavyShort, eyes: .bright, smile: .warm, accessory: .none)
        case .m05: return .init(skin: "#D4A574", hair: "#0E0E0E", iris: "#6B4E3D", blush: "#E08A80", bg: ["#3A3420", "#1C1810"], hair: .shortFade, eyes: .cool, smile: .smirk, accessory: .glasses)
        case .m06: return .init(skin: "#8D5524", hair: "#0A0A0A", iris: "#3E2723", blush: "#C96B60", bg: ["#3A2450", "#1A1028"], hair: .afro, eyes: .bright, smile: .grin, accessory: .none)
        case .m07: return .init(skin: "#F3D0C0", hair: "#A67C52", iris: "#5C6BC0", blush: "#F0A8A0", bg: ["#243848", "#121E28"], hair: .wavyShort, eyes: .soft, smile: .warm, accessory: .none)
        case .m08: return .init(skin: "#C98A5A", hair: "#3E2723", iris: "#AD1457", blush: "#E07A72", bg: ["#4A2030", "#241018"], hair: .curl, eyes: .heart, smile: .warm, accessory: .earring)
        case .m09: return .init(skin: "#E8B898", hair: "#2F1E14", iris: "#00838F", blush: "#E89890", bg: ["#1A3338", "#0E1C20"], hair: .spiky, eyes: .starry, smile: .grin, accessory: .none)
        case .m10: return .init(skin: "#B56B45", hair: "#1C100A", iris: "#455A64", blush: "#D08078", bg: ["#1C3330", "#0E1C1A"], hair: .baldish, eyes: .cool, smile: .smirk, accessory: .glasses)
        case .f01: return .init(skin: "#F0C7A0", hair: "#4A148C", iris: "#6A1B9A", blush: "#FF8A9A", bg: ["#3A2448", "#1C1028"], hair: .bob, eyes: .bright, smile: .warm, accessory: .earring)
        case .f02: return .init(skin: "#FFD7B5", hair: "#1A1A1A", iris: "#1565C0", blush: "#FF9AA8", bg: ["#1E3040", "#101820"], hair: .long, eyes: .soft, smile: .warm, accessory: .none)
        case .f03: return .init(skin: "#E8B888", hair: "#BF360C", iris: "#EF6C00", blush: "#FF8F80", bg: ["#3A2A18", "#1C140C"], hair: .pony, eyes: .bright, smile: .grin, accessory: .earring)
        case .f04: return .init(skin: "#C68642", hair: "#212121", iris: "#7B1FA2", blush: "#E07A72", bg: ["#322040", "#180F20"], hair: .bun, eyes: .soft, smile: .smirk, accessory: .none)
        case .f05: return .init(skin: "#F3D0C0", hair: "#6D4C41", iris: "#2E7D32", blush: "#FF9AA8", bg: ["#1E3224", "#101C14"], hair: .wavyLong, eyes: .bright, smile: .warm, accessory: .earring)
        case .f06: return .init(skin: "#D4A574", hair: "#880E4F", iris: "#C2185B", blush: "#FF8A9A", bg: ["#3A1824", "#1C0C12"], hair: .long, eyes: .heart, smile: .grin, accessory: .none)
        case .f07: return .init(skin: "#8D5524", hair: "#0D0D0D", iris: "#00695C", blush: "#D07068", bg: ["#1A302C", "#0E1A18"], hair: .afro, eyes: .soft, smile: .warm, accessory: .earring)
        case .f08: return .init(skin: "#E8B898", hair: "#3E2723", iris: "#EC407A", blush: "#FF9AA8", bg: ["#3A2030", "#1C1018"], hair: .bob, eyes: .starry, smile: .warm, accessory: .none)
        case .f09: return .init(skin: "#FFCCBC", hair: "#5D4037", iris: "#5C6BC0", blush: "#FF9AA8", bg: ["#222840", "#121420"], hair: .pony, eyes: .bright, smile: .smirk, accessory: .glasses)
        case .f10: return .init(skin: "#B56B45", hair: "#4A148C", iris: "#FFB300", blush: "#E08A80", bg: ["#2E2818", "#16140C"], hair: .bun, eyes: .cool, smile: .grin, accessory: .earring)
        }
    }
}

private struct AvatarStyle {
    enum Hair { case shortFade, spiky, curl, wavyShort, afro, baldish, bob, long, pony, bun, wavyLong }
    enum Eyes { case soft, bright, cool, heart, starry }
    enum Smile { case warm, grin, smirk }
    enum Accessory { case none, earring, glasses }

    let skin: String
    let hairColor: String
    let iris: String
    let blush: String
    let bg: [String]
    let hair: Hair
    let eyes: Eyes
    let smile: Smile
    let accessory: Accessory

    init(skin: String, hair: String, iris: String, blush: String, bg: [String], hair hairStyle: Hair, eyes: Eyes, smile: Smile, accessory: Accessory) {
        self.skin = skin
        self.hairColor = hair
        self.iris = iris
        self.blush = blush
        self.bg = bg
        self.hair = hairStyle
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

            // Soft ambient glow behind the head
            Circle()
                .fill(Color(hex: s.skin).opacity(0.22))
                .frame(width: size * 0.78, height: size * 0.78)
                .blur(radius: size * 0.06)
                .offset(y: size * 0.04)

            backHair
            neck
            face
            frontHair
            accessoryLayer
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
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
                        colors: [Color(hex: s.skin), Color(hex: s.skin).opacity(0.88)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.58, height: size * 0.66)
                .offset(y: size * 0.05)
                .shadow(color: .black.opacity(0.12), radius: size * 0.03, y: size * 0.02)

            // Cheeks
            HStack(spacing: size * 0.28) {
                Ellipse().fill(Color(hex: s.blush).opacity(0.45)).frame(width: size * 0.11, height: size * 0.07)
                Ellipse().fill(Color(hex: s.blush).opacity(0.45)).frame(width: size * 0.11, height: size * 0.07)
            }
            .offset(y: size * 0.14)

            eyesRow
            // Soft nose
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
                // Lid / white
                Ellipse()
                    .fill(Color.white)
                    .frame(width: size * (s.eyes == .bright ? 0.13 : 0.12),
                           height: size * (s.eyes == .cool ? 0.08 : 0.11))
                // Iris
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: s.iris).opacity(0.95), Color(hex: s.iris)],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.045
                        )
                    )
                    .frame(width: size * 0.075, height: size * 0.075)
                // Pupil
                Circle()
                    .fill(Color.black.opacity(0.85))
                    .frame(width: size * 0.035, height: size * 0.035)
                // Highlight
                Circle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: size * 0.02, height: size * 0.02)
                    .offset(x: -size * 0.015, y: -size * 0.015)
                // Soft brow
                Capsule()
                    .fill(Color(hex: s.hairColor).opacity(0.85))
                    .frame(width: size * 0.1, height: size * 0.015)
                    .offset(y: -size * 0.075)
                    .rotationEffect(.degrees(s.eyes == .cool ? -8 : 0))
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
        }
    }

    @ViewBuilder
    private var backHair: some View {
        let c = Color(hex: s.hairColor)
        switch s.hair {
        case .long, .wavyLong:
            Capsule().fill(c).frame(width: size * 0.72, height: size * 0.78).offset(y: size * 0.12)
        case .afro:
            Circle().fill(c).frame(width: size * 0.9, height: size * 0.9).offset(y: -size * 0.02)
        case .pony:
            Capsule().fill(c).frame(width: size * 0.18, height: size * 0.42)
                .rotationEffect(.degrees(28)).offset(x: size * 0.3, y: -size * 0.18)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var frontHair: some View {
        let c = Color(hex: s.hairColor)
        let shine = Color.white.opacity(0.18)
        switch s.hair {
        case .shortFade:
            shortFadeHair(c, shine)
        case .spiky:
            spikyHair(c)
        case .curl, .wavyShort:
            curlHair(c)
        case .baldish:
            Capsule().fill(c.opacity(0.9)).frame(width: size * 0.28, height: size * 0.1).offset(y: -size * 0.26)
        case .afro:
            EmptyView()
        case .bob:
            bobHair(c, shine)
        case .long, .wavyLong:
            longBangs(c)
        case .pony:
            ponyFront(c)
        case .bun:
            bunHair(c, shine)
        }
    }

    private func shortFadeHair(_ c: Color, _ shine: Color) -> some View {
        ZStack {
            Capsule().fill(c).frame(width: size * 0.62, height: size * 0.28).offset(y: -size * 0.2)
            Capsule().fill(shine).frame(width: size * 0.2, height: size * 0.06).offset(x: -size * 0.1, y: -size * 0.24)
        }
    }

    private func spikyHair(_ c: Color) -> some View {
        HStack(spacing: size * 0.015) {
            ForEach(0..<6, id: \.self) { i in
                let h = size * (0.2 + CGFloat(i % 3) * 0.05)
                Capsule().fill(c)
                    .frame(width: size * 0.08, height: h)
                    .rotationEffect(.degrees(Double(i) * 7 - 17.5))
            }
        }
        .offset(y: -size * 0.28)
    }

    private func curlHair(_ c: Color) -> some View {
        ZStack {
            Capsule().fill(c).frame(width: size * 0.7, height: size * 0.32).offset(y: -size * 0.18)
            HStack {
                Circle().fill(c).frame(width: size * 0.2)
                Spacer(minLength: 0)
                Circle().fill(c).frame(width: size * 0.2)
            }
            .frame(width: size * 0.72)
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
        switch s.accessory {
        case .none:
            EmptyView()
        case .earring:
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#F3E5AB"), Color(hex: "#D4AF37")],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: size * 0.07, height: size * 0.07)
                .offset(x: size * 0.28, y: size * 0.16)
        case .glasses:
            HStack(spacing: size * 0.04) {
                Circle().stroke(Color.white.opacity(0.85), lineWidth: size * 0.015)
                    .frame(width: size * 0.16, height: size * 0.16)
                Circle().stroke(Color.white.opacity(0.85), lineWidth: size * 0.015)
                    .frame(width: size * 0.16, height: size * 0.16)
            }
            .offset(y: size * 0.0)
        }
    }
}

/// Grid for onboarding / settings — pick one illustrated face.
struct CartoonAvatarPicker: View {
    let gender: Gender
    @Binding var selection: CartoonAvatar?

    private let columns = [GridItem(.adaptive(minimum: 68), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AVATARIN")
                .font(ABFont.label(12))
                .foregroundStyle(ABColor.inkMuted)
            Text("Bu yüz, gerçek fotoğraf 10 mesaj sonra açılana kadar profil fotoğrafın olur.")
                .font(ABFont.body(12))
                .foregroundStyle(ABColor.inkMuted.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(CartoonAvatar.options(for: gender)) { avatar in
                    Button {
                        selection = avatar
                    } label: {
                        CartoonAvatarView(avatar: avatar, size: 68)
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

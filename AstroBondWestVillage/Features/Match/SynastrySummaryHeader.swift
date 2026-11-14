import SwiftUI

/// "SİNASTRİ" header block: title, the couple with the bond seal, and the bond name
/// with its tap-to-expand Turkish description. Shared by `MatchDetailSheet` and the
/// confirmed-match state under the wheel on the Eşleşme tab.
struct SynastrySummaryHeader: View {
    let card: MatchCard
    var myName: String = "Sen"
    var myPhotoURL: String? = nil
    var myCartoonAvatarId: String? = nil
    let mySun: ZodiacSign?
    let report: BondStory.Report

    @State private var showBondInfo = false

    private let mineTint = Color(hex: "#F0CE7E")
    private let theirTint = ABColor.lavenderSoft

    var body: some View {
        VStack(spacing: 18) {
            titleBlock
            coupleHeader
            bondNameSection
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 6) {
            Text("SİNASTRİ")
                .font(ABFont.body(12, weight: .bold))
                .tracking(5)
                .foregroundStyle(ABColor.lavenderSoft.opacity(0.9))
            Text("İki ruhun ortak yıldız haritası")
                .font(ABFont.body(12.5))
                .foregroundStyle(ABColor.inkMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private var coupleHeader: some View {
        HStack(alignment: .top, spacing: 4) {
            personColumn(name: myName, sign: mySun, tint: mineTint) {
                PersonAvatar(name: myName, photoURL: myPhotoURL, cartoonAvatarId: myCartoonAvatarId, sunSign: mySun, unlocked: true, size: 52)
            }
            bondSeal
            personColumn(name: card.displayName, sign: card.sunSign, tint: theirTint) {
                PersonAvatar(name: card.displayName, photoURL: card.photoURL, cartoonAvatarId: card.cartoonAvatarId, sunSign: card.sunSign, unlocked: false, size: 52)
            }
        }
    }

    private func personColumn<Avatar: View>(
        name: String, sign: ZodiacSign?, tint: Color, @ViewBuilder avatar: () -> Avatar
    ) -> some View {
        VStack(spacing: 10) {
            avatar()
            Text(name)
                .font(ABFont.display(15))
                .foregroundStyle(ABColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .frame(maxWidth: .infinity)
            if let sign {
                Text("\(sign.glyph) \(sign.labelTR)")
                    .font(ABFont.body(12, weight: .medium))
                    .foregroundStyle(tint.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var bondSeal: some View {
        VStack(spacing: 7) {
            ZStack {
                Circle().stroke(ABColor.veil.opacity(0.12), lineWidth: 6)
                Circle()
                    .stroke(
                        AngularGradient(colors: [ABColor.lavender, mineTint, ABColor.lavenderSoft, ABColor.lavender], center: .center),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(ABColor.lavenderSoft)
                    .shadow(color: ABColor.lavender.opacity(0.6), radius: 6)
            }
            .frame(width: 60, height: 60)
            .shadow(color: ABColor.lavender.opacity(0.4), radius: 14)
            Text(report.bondTier.tierTagline)
                .font(ABFont.body(10, weight: .semibold))
                .foregroundStyle(ABColor.lavenderSoft)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 88)
    }

    private var bondNameSection: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                    showBondInfo.toggle()
                }
            } label: {
                VStack(spacing: 7) {
                    Text(report.bondTier.english)
                        .font(ABFont.display(24))
                        .foregroundStyle(
                            LinearGradient(colors: [ABColor.ink, ABColor.lavenderSoft], startPoint: .top, endPoint: .bottom)
                        )
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        Text(showBondInfo ? "Açıklamayı gizle" : "Açıklama için dokun")
                            .font(ABFont.body(12, weight: .semibold))
                            .foregroundStyle(ABColor.lavenderSoft.opacity(0.9))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(ABColor.lavenderSoft.opacity(0.9))
                            .rotationEffect(.degrees(showBondInfo ? 180 : 0))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            if showBondInfo {
                VStack(alignment: .leading, spacing: 10) {
                    Text(report.bondTier.turkish)
                        .font(ABFont.display(18))
                        .foregroundStyle(ABColor.lavenderSoft)
                    Text(report.bondTier.summary)
                        .font(ABFont.body(14))
                        .foregroundStyle(ABColor.ink.opacity(0.85))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .crystalPlate(cornerRadius: 20)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

/// Prominent action pill: glowing gradient, moving sheen, SF Symbol icon.
struct GlowActionButton: View {
    var title: String
    var icon: String = "sparkles"
    var isLoading = false
    let action: () -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sheen: CGFloat = -1.2

    private var colors: [Color] {
        scheme == .light
            ? [Color(hex: "#F5B7A6"), Color(hex: "#D98FB5"), Color(hex: "#9B86E6")]
            : [Color(hex: "#B79BFF"), Color(hex: "#8E6CF0"), Color(hex: "#E7A8D9")]
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                }
                Text(title)
                    .font(ABFont.body(17, weight: .bold))
                    .tracking(0.6)
            }
            .foregroundStyle(Color.white)
            .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background {
                ZStack {
                    Capsule(style: .continuous)
                        .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                    // Top gloss
                    Capsule(style: .continuous)
                        .fill(LinearGradient(colors: [Color.white.opacity(0.38), .clear], startPoint: .top, endPoint: .center))
                        .padding(2)
                    // Moving sheen
                    GeometryReader { geo in
                        LinearGradient(colors: [.clear, Color.white.opacity(0.45), .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: geo.size.width * 0.35)
                            .rotationEffect(.degrees(18))
                            .offset(x: geo.size.width * sheen)
                    }
                    .clipShape(Capsule(style: .continuous))
                }
            }
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [Color.white.opacity(0.85), Color.white.opacity(0.15)], startPoint: .top, endPoint: .bottom),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: colors[1].opacity(0.55), radius: 18, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.2).delay(0.6).repeatForever(autoreverses: false)) {
                sheen = 1.4
            }
        }
    }
}

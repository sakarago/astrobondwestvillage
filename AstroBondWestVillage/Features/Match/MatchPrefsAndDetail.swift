import SwiftUI

struct MatchPrefsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var prefs: MatchPrefsStore.Snapshot
    let onSave: (MatchPrefsStore.Snapshot) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackdrop()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        section("Bağ türü") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(MatchIntent.allCases) { intent in
                                    Button {
                                        prefs.intent = intent
                                    } label: {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Image(systemName: intent.iconName)
                                                .foregroundStyle(ABColor.lavenderSoft)
                                            Text(intent.titleTR)
                                                .font(ABFont.body(15, weight: .semibold))
                                                .foregroundStyle(ABColor.ink)
                                            Text(intent.subtitle)
                                                .font(ABFont.body(12))
                                                .foregroundStyle(ABColor.inkMuted)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(14)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .strokeBorder(
                                                    prefs.intent == intent
                                                        ? ABColor.lavenderSoft.opacity(0.8)
                                                        : Color.white.opacity(0.12),
                                                    lineWidth: prefs.intent == intent ? 1.4 : 1
                                                )
                                        )
                                        .background(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .fill(prefs.intent == intent ? ABColor.lavender.opacity(0.2) : Color.white.opacity(0.04))
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        section("Cinsiyet tercihleri") {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                                ForEach(Gender.allCases.filter { $0 != .preferNotSay }) { gender in
                                    let on = prefs.preferredGenders.contains(gender)
                                    Button {
                                        if on {
                                            prefs.preferredGenders.removeAll { $0 == gender }
                                        } else {
                                            prefs.preferredGenders.append(gender)
                                        }
                                    } label: {
                                        Text(gender.labelTR)
                                            .font(ABFont.body(13, weight: .semibold))
                                            .foregroundStyle(on ? Color.white : ABColor.inkMuted)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Capsule().fill(on ? ABColor.lavender.opacity(0.45) : Color.white.opacity(0.06)))
                                            .overlay(Capsule().strokeBorder(Color.white.opacity(on ? 0.35 : 0.12), lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        section("Yaş aralığı") {
                            Toggle("Filtrele", isOn: $prefs.ageEnabled)
                                .tint(ABColor.lavender)
                                .font(ABFont.body(15))
                                .foregroundStyle(ABColor.ink)
                            if prefs.ageEnabled {
                                HStack {
                                    Text("\(prefs.ageMin)")
                                        .foregroundStyle(ABColor.inkMuted)
                                    Slider(
                                        value: Binding(
                                            get: { Double(prefs.ageMin) },
                                            set: { prefs.ageMin = Int($0) }
                                        ),
                                        in: 18...60,
                                        step: 1
                                    )
                                    .tint(ABColor.lavenderSoft)
                                    Text("\(prefs.ageMax)")
                                        .foregroundStyle(ABColor.inkMuted)
                                }
                                Slider(
                                    value: Binding(
                                        get: { Double(prefs.ageMax) },
                                        set: { prefs.ageMax = max(prefs.ageMin, Int($0)) }
                                    ),
                                    in: 18...70,
                                    step: 1
                                )
                                .tint(ABColor.lavenderSoft)
                            }
                        }

                        section("Konum") {
                            Toggle("Şehir filtresi", isOn: $prefs.locationEnabled)
                                .tint(ABColor.lavender)
                                .font(ABFont.body(15))
                                .foregroundStyle(ABColor.ink)
                            if prefs.locationEnabled {
                                TextField("Şehir", text: $prefs.searchCity)
                                    .font(ABFont.body(15))
                                    .foregroundStyle(ABColor.ink)
                                    .padding(12)
                                    .crystalPlate(cornerRadius: 14)
                                Text("Mesafe ≈ \(Int(prefs.maxDistanceKm)) km")
                                    .font(ABFont.body(13))
                                    .foregroundStyle(ABColor.inkMuted)
                                Slider(value: $prefs.maxDistanceKm, in: 10...500, step: 10)
                                    .tint(ABColor.lavenderSoft)
                            }
                        }

                        CrystalCTAButton(title: "Kaydet") {
                            onSave(prefs)
                            dismiss()
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(ABColor.inkMuted)
                }
                ToolbarItem(placement: .principal) {
                    Text("Eşleşme tercihleri")
                        .font(ABFont.body(16, weight: .semibold))
                        .foregroundStyle(ABColor.ink)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(ABFont.body(11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(ABColor.inkMuted)
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(16)
            .crystalPlate(cornerRadius: 22)
        }
    }
}

/// "Sinastri" — the full-screen mirror-soul detail for a match: bond name +
/// tier, a four-dimension Astro Bond profile, a professional dual-wheel
/// synastry chart, a written "Ruhsal Bağlantı" read, strengths/challenges,
/// a few "Astro Anlar" snapshots, and a point-by-point sign comparison table.
/// Modeled after the original AstroBond app's Sinastri screen (see
/// `CosmicMatchProfileCardView`), rebuilt against this app's own Crystal
/// design system and its own (deterministic, no-live-ephemeris) data model.
struct MatchDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let card: MatchCard
    /// Seed for *your* placements on the shared wheel below — stable per
    /// user, same convention as `CosmicMatchWheel.mySeed` everywhere else.
    var mySeed: String = "self"
    var myName: String = "Sen"
    var myPhotoURL: String? = nil
    var myCartoonAvatarId: String? = nil
    let mySun: ZodiacSign?
    var myMoon: ZodiacSign? = nil
    var myRising: ZodiacSign? = nil
    var seedChart: NatalChart? = nil
    let intent: MatchIntent
    /// When provided, shows a "Mesaj Gönder" CTA that hands off to the
    /// caller (accept + open chat) before dismissing this sheet. Left `nil`
    /// when already inside the conversation (e.g. opened from `ChatView`'s
    /// "Bağ özeti"), where a CTA to message would be redundant.
    var onMessage: (() -> Void)? = nil
    var onBack: (() -> Void)? = nil

    @State private var showBondInfo = false
    @State private var myChart: NatalChart?
    @State private var theirChart: NatalChart?

    private let mineTint = Color(hex: "#F0CE7E")
    private let theirTint = ABColor.lavenderSoft

    private var report: BondStory.Report {
        BondStory.report(
            mySun: mySun,
            their: card,
            intent: intent,
            myChart: myChart ?? seedChart,
            theirChart: theirChart
        )
    }

    private var points: [SynastryPoint] {
        SynastryChart.points(
            mySeed: mySeed,
            mySun: mySun,
            myMoon: myMoon,
            myRising: myRising,
            card: card,
            myChart: myChart ?? seedChart,
            theirChart: theirChart
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 6)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    titleBlock
                    coupleHeader
                    bondNameSection
                    bondProfileSection
                    wheelSection
                    connectionCard
                    rareMatchCard
                    strengthsChallengesSection
                    snapshotsSection
                    comparisonSection
                    notesSection

                    if let onMessage {
                        CrystalCTAButton(title: "Mesaj Gönder") {
                            onMessage()
                            dismiss()
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            CosmicBackdrop()
                .allowsHitTesting(false)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if myChart == nil {
                if let seedChart {
                    myChart = seedChart
                } else {
                    myChart = await ChartService.shared.fetchOrSynthesize(
                        userId: mySeed, sun: mySun, moon: myMoon, rising: myRising
                    )
                }
            }
            theirChart = await ChartService.shared.fetchOrSynthesize(
                userId: card.id, sun: card.sunSign, moon: card.moonSign, rising: card.risingSign
            )
        }
    }

    // MARK: Top bar + title

    private var topBar: some View {
        HStack {
            Button(action: goBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(ABColor.ink)
                    .crystalIconBezel(size: 40, cornerRadius: 14)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            Text("✦ ASTROBOND")
                .font(ABFont.body(10, weight: .bold))
                .tracking(2)
                .foregroundStyle(ABColor.inkMuted)
                .allowsHitTesting(false)

            Spacer(minLength: 0)

            ShareLink(item: shareText) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ABColor.ink)
                    .crystalIconBezel(size: 40, cornerRadius: 14)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .fixedSize()
        }
    }

    private func goBack() {
        if let onBack {
            onBack()
        } else {
            dismiss()
        }
    }

    private var shareText: String {
        "\(card.displayName) ile bağımız: \(report.bondTier.english) (\(report.bondTier.turkish)) ✦ AstroBond"
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

    // MARK: Couple header + bond seal (no bare numbers)

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
                Circle().stroke(Color.white.opacity(0.12), lineWidth: 6)
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

    // MARK: Bond name (tap → Turkish description)

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
                            LinearGradient(colors: [.white, ABColor.lavenderSoft], startPoint: .top, endPoint: .bottom)
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

    // MARK: Astro Bond profile (LOVE / SEX / MIND / TRUST)

    private var bondProfileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Astro Bond Profili", subtitle: "Dört boyutta bağınız")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 14) {
                ForEach(BondIconKind.allCases) { kind in
                    dimensionCard(kind)
                }
            }
        }
        .padding(16)
        .crystalPlate(cornerRadius: 24)
    }

    /// Original Sinastri mapping: one overall score with a small per-bond offset,
    /// plus the fixed LOVE/SEX/MIND/TRUST captions — not hashed leftover blurbs.
    private func bondPercent(_ kind: BondIconKind) -> Int {
        let base = report.overall
        let offset: Int
        switch kind {
        case .love: offset = 6
        case .sex: offset = -3
        case .mind: offset = 2
        case .trust: offset = -8
        }
        return min(98, max(42, base + offset))
    }

    private func dimensionCard(_ kind: BondIconKind) -> some View {
        let pct = bondPercent(kind)
        let fraction = CGFloat(pct) / 100
        return VStack(spacing: 7) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.10), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(
                        AngularGradient(colors: kind.gradient, center: .center, startAngle: .degrees(0), endAngle: .degrees(360)),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: kind.tint.opacity(0.5), radius: 5)
                BondDimensionIcon(kind: kind, size: 22)
            }
            .frame(width: 62, height: 62)
            .padding(.top, 2)

            Text("%\(pct)")
                .font(ABFont.body(15, weight: .bold))
                .foregroundStyle(ABColor.lavenderSoft)
            Text(kind.title)
                .font(ABFont.body(11, weight: .bold))
                .tracking(1)
                .foregroundStyle(ABColor.lavenderSoft.opacity(0.9))
                .lineLimit(1)
            Text(kind.note)
                .font(ABFont.body(10.5))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 5)
    }

    // MARK: Synastry wheel (professional bi-wheel) + Turkish key

    private var wheelSection: some View {
        VStack(spacing: 14) {
            sectionHeader(title: "Sinastri Haritası", subtitle: "İki doğum haritasının birleşik sinastri çarkı")
            if let mine = myChart ?? seedChart, let theirChart {
                ChartWheelView(chart: mine, overlay: theirChart)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .padding(8)
                    .background(Color.black.opacity(0.28))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            } else {
                SynastryWheelCanvas(points: points, mineColor: mineTint, theirColor: theirTint)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .clipped()
            }
            HStack(spacing: 8) {
                legendDot(color: mineTint, label: "Sen · iç")
                legendDot(color: theirTint, label: "\(card.displayName) · dış")
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            SynastryKeyView()
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .crystalPlate(cornerRadius: 28)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 9, height: 9)
                .shadow(color: color.opacity(0.7), radius: 4)
            Text(label)
                .font(ABFont.body(11, weight: .semibold))
                .foregroundStyle(ABColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    // MARK: Soul connection

    private var connectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkle")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [ABColor.lavenderSoft, ABColor.lavender], startPoint: .top, endPoint: .bottom)
                    )
                Text("Ruhsal Bağlantı")
                    .font(ABFont.display(19))
                    .foregroundStyle(ABColor.ink)
            }
            Text(report.connectionSummary)
                .font(ABFont.body(14))
                .foregroundStyle(ABColor.ink.opacity(0.85))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .crystalPlate(cornerRadius: 24)
    }

    // MARK: Rare / karmic highlight (only for the top bond ranks)

    @ViewBuilder
    private var rareMatchCard: some View {
        if let rare = report.rareHighlight {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Color(hex: "#E8C39A").opacity(0.16))
                        Circle().strokeBorder(Color(hex: "#E8C39A").opacity(0.5), lineWidth: 1)
                        Text("☋").font(.system(size: 18)).foregroundStyle(Color(hex: "#F3DEC2"))
                    }
                    .frame(width: 42, height: 42)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rare.badgeTitle)
                            .font(ABFont.display(18))
                            .foregroundStyle(ABColor.ink)
                        Text(rare.badgeSubtitle)
                            .font(ABFont.body(11, weight: .medium))
                            .foregroundStyle(Color(hex: "#F3DEC2").opacity(0.9))
                    }
                    Spacer(minLength: 0)
                }
                hairline
                VStack(alignment: .leading, spacing: 6) {
                    Text(rare.heading)
                        .font(ABFont.body(11, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(Color(hex: "#E8C39A"))
                    Text(rare.note)
                        .font(ABFont.body(13.5))
                        .foregroundStyle(ABColor.ink.opacity(0.82))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .crystalPlate(cornerRadius: 26)
        }
    }

    // MARK: Strengths & challenges

    private var strengthsChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Güçlü & Zorlu Yönler")
            VStack(spacing: 10) {
                ForEach(report.strengths) { item in
                    insightRow(item, tint: mineTint, positive: true)
                }
                if !report.strengths.isEmpty, !report.challenges.isEmpty {
                    hairline.padding(.vertical, 2)
                }
                ForEach(report.challenges) { item in
                    insightRow(item, tint: Color(hex: "#E8A0A0"), positive: false)
                }
            }
            .padding(16)
            .crystalPlate(cornerRadius: 22)
        }
    }

    private func insightRow(_ item: BondStory.Insight, tint: Color, positive: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(tint.opacity(0.16))
                Circle().strokeBorder(tint.opacity(0.45), lineWidth: 1)
                Image(systemName: positive ? "arrow.up.right" : "exclamationmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tint)
            }
            .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(ABFont.body(14, weight: .bold))
                    .foregroundStyle(ABColor.ink)
                Text(item.detail)
                    .font(ABFont.body(13))
                    .foregroundStyle(ABColor.inkMuted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Snapshots (swipeable)

    private var snapshotsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Astro Anlar", subtitle: "Kaydırarak ilişkinin küçük kesitlerini gör")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(report.snapshots.enumerated()), id: \.element.id) { idx, snap in
                        snapshotCard(snap, index: idx)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
    }

    private func snapshotCard(_ snap: BondStory.Snapshot, index: Int) -> some View {
        let isMine = index % 2 == 0
        let tint = isMine ? mineTint : theirTint
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Circle().fill(tint).frame(width: 7, height: 7)
                Text(snap.eyebrow)
                    .font(ABFont.body(10, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(tint)
            }
            Text(snap.body)
                .font(ABFont.body(13.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(15)
        .frame(width: 214, height: 136, alignment: .topLeading)
        .crystalPlate(cornerRadius: 22)
    }

    // MARK: Comparison table

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Burç Karşılaştırması", subtitle: "İki haritanın nokta nokta görünümü")
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("NOKTA")
                        .font(ABFont.body(10, weight: .bold)).tracking(1)
                        .foregroundStyle(ABColor.inkMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(myName.uppercased())
                        .font(ABFont.body(10, weight: .bold))
                        .foregroundStyle(mineTint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(card.displayName.uppercased())
                        .font(ABFont.body(10, weight: .bold))
                        .foregroundStyle(theirTint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                ForEach(points) { row in
                    hairline
                    comparisonRow(row)
                }
            }
            .padding(.vertical, 4)
            .crystalPlate(cornerRadius: 22)
        }
    }

    private func comparisonRow(_ row: SynastryPoint) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(row.glyph)
                    .font(.system(size: 13))
                    .foregroundStyle(ABColor.ink.opacity(0.85))
                    .frame(width: 24, alignment: .leading)
                Text(row.label)
                    .font(ABFont.body(12.5, weight: .semibold))
                    .foregroundStyle(ABColor.ink.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            signCell(row.mine, tint: mineTint).frame(maxWidth: .infinity, alignment: .leading)
            signCell(row.theirs, tint: theirTint).frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private func signCell(_ sign: ZodiacSign, tint: Color) -> some View {
        HStack(spacing: 6) {
            Text(sign.glyph)
                .font(.system(size: 13))
                .foregroundStyle(tint)
            Text(sign.labelTR)
                .font(ABFont.body(12.5, weight: .medium))
                .foregroundStyle(ABColor.ink.opacity(0.88))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    // MARK: Leftover astrological notes (element/modality/aspect one-liners)

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Astrolojik Notlar")
            VStack(alignment: .leading, spacing: 8) {
                ForEach(report.aspects, id: \.self) { line in
                    HStack(alignment: .top, spacing: 8) {
                        Text("✧").foregroundStyle(ABColor.lavenderSoft)
                        Text(line)
                            .font(ABFont.body(13))
                            .foregroundStyle(ABColor.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .crystalPlate(cornerRadius: 22)
    }

    // MARK: Shared bits

    private var hairline: some View {
        Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
    }

    private func sectionHeader(title: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(ABFont.display(19))
                .foregroundStyle(ABColor.ink)
            if let subtitle {
                Text(subtitle)
                    .font(ABFont.body(12))
                    .foregroundStyle(ABColor.inkMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

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
                                                        : ABColor.veil.opacity(0.12),
                                                    lineWidth: prefs.intent == intent ? 1.4 : 1
                                                )
                                        )
                                        .background(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .fill(prefs.intent == intent ? ABColor.lavender.opacity(0.2) : ABColor.veil.opacity(0.04))
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
                                            .foregroundStyle(on ? ABColor.ink : ABColor.inkMuted)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Capsule().fill(on ? ABColor.lavender.opacity(0.45) : ABColor.veil.opacity(0.06)))
                                            .overlay(Capsule().strokeBorder(ABColor.veil.opacity(on ? 0.35 : 0.12), lineWidth: 1))
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
    /// Sticky "Mesaj Gönder" action. When nil, the button still shows and
    /// simply returns via `onBack` / dismiss (e.g. opened from Messages chat).
    var onMessage: (() -> Void)? = nil
    var onBack: (() -> Void)? = nil

    @State private var myChart: NatalChart?
    @State private var theirChart: NatalChart?
    @State private var selectedBond: BondIconKind?
    @State private var selectedPlacement: PlacementRead?

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
                    SynastrySummaryHeader(
                        card: card, myName: myName, myPhotoURL: myPhotoURL,
                        myCartoonAvatarId: myCartoonAvatarId, mySun: mySun, report: report
                    )
                    bondProfileSection
                    wheelSection
                    comparisonSection
                    connectionCard
                    rareMatchCard
                    strengthsChallengesSection
                    snapshotsSection
                    notesSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            stickyMessageBar(action: {
                if let onMessage {
                    onMessage()
                } else {
                    goBack()
                }
            })
        }
        .background { revealBackdrop }
        .contentShape(Rectangle())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $selectedBond) { kind in
            BondDimensionExplainView(
                kind: kind,
                percent: bondPercent(kind),
                myName: myName,
                theirName: card.displayName,
                mySun: mySun,
                theirSun: card.sunSign,
                myMoon: myMoon,
                theirMoon: card.moonSign,
                myUserId: mySeed
            )
        }
        .fullScreenCover(item: $selectedPlacement) { row in
            PlacementExplainView(
                row: row,
                myName: myName,
                theirName: card.displayName,
                myUserId: mySeed
            )
        }
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

    /// Same warm nebula + moons as the match-found (yes/no) screen.
    private var revealBackdrop: some View {
        ZStack {
            Color(hex: "#040308")
            Image("reveal_bg")
                .resizable()
                .scaledToFill()
            RevealSkyDecor()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    /// Pinned above the home indicator via safeAreaInset; content scrolls above it.
    private func stickyMessageBar(action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 36)
            .allowsHitTesting(false)

            GlowActionButton(
                title: "Mesaj Gönder",
                icon: "paperplane.fill",
                colors: [Color(hex: "#F0CE7E"), ABColor.warm, Color(hex: "#E8B9A0")],
                action: action
            )
            .padding(.horizontal, 22)
            // Extra lift so the pill clears the home indicator comfortably.
            .padding(.bottom, 28)
        }
        .background(Color.black.opacity(0.55).ignoresSafeArea(edges: .bottom))
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

    // MARK: Astro Bond profile (LOVE / SEX / MIND / TRUST)

    private var bondProfileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Astro Bağ Profili", subtitle: "Dört boyutta bağınız")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 14) {
                ForEach(BondIconKind.allCases) { kind in
                    dimensionCard(kind)
                }
            }
        }
        .padding(16)
        .revealGlass(cornerRadius: 24)
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
        return Button {
            selectedBond = kind
        } label: {
            VStack(spacing: 7) {
                ZStack {
                    Circle().stroke(ABColor.veil.opacity(0.10), lineWidth: 3)
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
                    .foregroundStyle(ABColor.warm)
                Text(kind.title)
                    .font(ABFont.body(11, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(ABColor.warm.opacity(0.9))
                    .lineLimit(1)
                Text(kind.note)
                    .font(ABFont.body(10.5))
                    .foregroundStyle(ABColor.ink.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text("Detay →")
                    .font(ABFont.body(10, weight: .semibold))
                    .foregroundStyle(ABColor.warm.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Bu bağ yüzdesinin açıklamasını açar")
    }

    // MARK: Synastry wheel (professional bi-wheel) + Turkish key

    private var wheelSection: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("Sinastri Haritası")
                    .font(ABFont.display(19))
                    .foregroundStyle(ABColor.ink)
                Text("İki doğum haritasının birleşik sinastri çarkı")
                    .font(ABFont.body(12))
                    .foregroundStyle(ABColor.inkMuted)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)

            // Width comes from the card, so the disk cannot run off the phone edges.
            GeometryReader { geo in
                let side = geo.size.width
                Group {
                    if let mine = myChart ?? seedChart, let theirChart {
                        ChartWheelView(chart: mine, overlay: theirChart, paper: true)
                    } else {
                        SynastryWheelCanvas(points: points, mineColor: Color(hex: "#F0CE7E"), theirColor: Color(hex: "#E8B9A0"))
                    }
                }
                .frame(width: side, height: side)
            }
            .aspectRatio(1, contentMode: .fit)

            HStack(spacing: 8) {
                legendDot(color: Color(hex: "#F0CE7E"), label: "Sen · iç")
                legendDot(color: Color(hex: "#E8B9A0"), label: "\(card.displayName) · dış")
            }
            .frame(maxWidth: .infinity)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .revealGlass(cornerRadius: 28, warmWash: true)
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
                        LinearGradient(colors: [Color(hex: "#F0CE7E"), ABColor.warm], startPoint: .top, endPoint: .bottom)
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
        .revealGlass(cornerRadius: 24)
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
                        Text("☋").font(.system(size: 18)).foregroundStyle(Color.adaptive(light: "#8A6240", dark: "#F3DEC2"))
                    }
                    .frame(width: 42, height: 42)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rare.badgeTitle)
                            .font(ABFont.display(18))
                            .foregroundStyle(ABColor.ink)
                        Text(rare.badgeSubtitle)
                            .font(ABFont.body(11, weight: .medium))
                            .foregroundStyle(Color.adaptive(light: "#8A6240", dark: "#F3DEC2").opacity(0.9))
                    }
                    Spacer(minLength: 0)
                }
                hairline
                VStack(alignment: .leading, spacing: 6) {
                    Text(rare.heading)
                        .font(ABFont.body(11, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(Color.adaptive(light: "#A9743F", dark: "#E8C39A"))
                    Text(rare.note)
                        .font(ABFont.body(13.5))
                        .foregroundStyle(ABColor.ink.opacity(0.82))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .revealGlass(cornerRadius: 26)
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
            .revealGlass(cornerRadius: 22)
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
                .foregroundStyle(ABColor.ink.opacity(0.9))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(15)
        .frame(width: 214, height: 136, alignment: .topLeading)
        .revealGlass(cornerRadius: 22)
    }

    // MARK: Comparison table

    /// Image-style pairs: planet band, then you | them. Angles include the opposite houses.
    private var comparisonRows: [PlacementRead] {
        func point(_ id: String) -> SynastryPoint? { points.first { $0.id == id } }
        func opposite(_ sign: ZodiacSign) -> ZodiacSign {
            ZodiacSign.allCases[(sign.index + 6) % 12]
        }
        var rows: [PlacementRead] = []
        if let p = point("moon") { rows.append(.init(glyph: p.glyph, label: "Ay", mine: p.mine, theirs: p.theirs)) }
        if let p = point("venus") { rows.append(.init(glyph: p.glyph, label: "Venüs", mine: p.mine, theirs: p.theirs)) }
        if let p = point("mars") { rows.append(.init(glyph: p.glyph, label: "Mars", mine: p.mine, theirs: p.theirs)) }
        if let p = point("rising") {
            rows.append(.init(glyph: "As", label: "Yükselen", mine: p.mine, theirs: p.theirs))
            rows.append(.init(glyph: "Ds", label: "Alçalan", mine: opposite(p.mine), theirs: opposite(p.theirs)))
        }
        if let p = point("mc") {
            rows.append(.init(glyph: "MC", label: "Tepe", mine: p.mine, theirs: p.theirs))
            rows.append(.init(glyph: "IC", label: "Dip", mine: opposite(p.mine), theirs: opposite(p.theirs)))
        }
        return rows
    }

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Burç Karşılaştırması", subtitle: "Bir satıra dokun — ikinize ayrı etkisini gör")
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    comparisonName(myName, mark: "☉", tint: Color(hex: "#F0CE7E"))
                    Rectangle().fill(ABColor.warm.opacity(0.22)).frame(width: 1)
                    comparisonName(card.displayName, mark: "☾", tint: Color(hex: "#E8B9A0"))
                }
                .padding(.vertical, 14)

                ForEach(comparisonRows) { row in
                    Button {
                        selectedPlacement = row
                    } label: {
                        VStack(spacing: 0) {
                            HStack(spacing: 6) {
                                Text("\(row.glyph)  \(row.label)")
                                    .font(ABFont.body(14, weight: .semibold))
                                    .foregroundStyle(ABColor.ink)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(ABColor.warm.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(ABColor.warm.opacity(0.14))

                            HStack(spacing: 0) {
                                comparisonSign(row.mine)
                                Rectangle().fill(ABColor.warm.opacity(0.18)).frame(width: 1)
                                comparisonSign(row.theirs)
                            }
                            .padding(.vertical, 14)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(ABColor.warm.opacity(0.28), lineWidth: 1)
            )
            .revealGlass(cornerRadius: 22)
        }
    }

    private func comparisonName(_ name: String, mark: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Text(mark)
                .font(.system(size: 16))
                .foregroundStyle(tint)
            Text(name)
                .font(ABFont.body(16, weight: .semibold))
                .foregroundStyle(ABColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private func comparisonSign(_ sign: ZodiacSign) -> some View {
        HStack(spacing: 8) {
            Text(sign.glyph)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: "#F6E7CF"))
            Text(sign.labelTR)
                .font(ABFont.body(15, weight: .medium))
                .foregroundStyle(ABColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Image(systemName: "arrow.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ABColor.warm.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Leftover astrological notes (element/modality/aspect one-liners)

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Astrolojik Notlar")
            VStack(alignment: .leading, spacing: 8) {
                ForEach(report.aspects, id: \.self) { line in
                    HStack(alignment: .top, spacing: 8) {
                        Text("✧").foregroundStyle(ABColor.warm)
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
        .revealGlass(cornerRadius: 22)
    }

    // MARK: Shared bits

    private var hairline: some View {
        Rectangle().fill(ABColor.veil.opacity(0.08)).frame(height: 1)
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

/// One tappable row of the burç comparison table.
private struct PlacementRead: Identifiable, Hashable {
    var id: String { "\(label)|\(mine.rawValue)|\(theirs.rawValue)" }
    let glyph: String
    let label: String
    let mine: ZodiacSign
    let theirs: ZodiacSign
}

/// Explains one placement twice: how it lands on you, and how it lands on them.
private struct PlacementExplainView: View {
    @Environment(\.dismiss) private var dismiss
    let row: PlacementRead
    let myName: String
    let theirName: String
    let myUserId: String

    @State private var mineText = ""
    @State private var theirText = ""
    @State private var togetherText = ""
    @State private var usedAI = false
    @State private var loading = true

    private let mineTint = Color(hex: "#F0CE7E")
    private let theirTint = Color(hex: "#E8B9A0")

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(ABColor.ink)
                        .crystalIconBezel(size: 40, cornerRadius: 14)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                Spacer()
                if usedAI {
                    Label("sana özel", systemImage: "sparkle")
                        .font(ABFont.body(12, weight: .semibold))
                        .foregroundStyle(ABColor.warm)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(ABColor.warm.opacity(0.16)))
                        .overlay(Capsule().strokeBorder(ABColor.warm.opacity(0.45), lineWidth: 1))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("\(row.glyph)  \(row.label)")
                            .font(ABFont.display(32))
                            .foregroundStyle(ABColor.ink)
                        Text("\(row.mine.glyph) \(row.mine.labelTR)   →   \(row.theirs.glyph) \(row.theirs.labelTR)")
                            .font(ABFont.body(15, weight: .medium))
                            .foregroundStyle(ABColor.warm)
                            .multilineTextAlignment(.center)
                        Text("Aynı nokta, iki farklı etki")
                            .font(ABFont.body(13, weight: .semibold))
                            .foregroundStyle(ABColor.ink.opacity(0.65))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    personCard(
                        name: myName,
                        sign: row.mine,
                        eyebrow: "SENDE",
                        tint: mineTint,
                        body: mineText
                    )
                    personCard(
                        name: theirName,
                        sign: row.theirs,
                        eyebrow: "ONDA",
                        tint: theirTint,
                        body: theirText
                    )
                    personCard(
                        name: "İkiniz",
                        sign: nil,
                        eyebrow: "ARANIZDA",
                        tint: ABColor.warm,
                        body: togetherText
                    )

                    if loading {
                        HStack(spacing: 8) {
                            ProgressView().tint(ABColor.warm)
                            Text("Gökyüzü ikiniz için ayrı ayrı yazıyor…")
                                .font(ABFont.body(13, weight: .medium))
                                .foregroundStyle(ABColor.ink.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                Image("reveal_bg").resizable().scaledToFill().ignoresSafeArea()
                Color.black.opacity(0.28).ignoresSafeArea()
            }
        }
        .task { await loadCopy() }
    }

    private func personCard(name: String, sign: ZodiacSign?, eyebrow: String, tint: Color, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(sign?.glyph ?? "✦")
                    .font(.system(size: 18))
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(tint.opacity(0.16)))
                VStack(alignment: .leading, spacing: 1) {
                    Text(eyebrow)
                        .font(ABFont.body(10, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(tint)
                    Text(sign.map { "\(name) · \($0.labelTR)" } ?? name)
                        .font(ABFont.display(20))
                        .foregroundStyle(ABColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            Text(body.isEmpty ? "…" : body)
                .font(ABFont.body(16))
                .foregroundStyle(ABColor.ink.opacity(0.9))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(tint.opacity(0.12))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(tint.opacity(0.35), lineWidth: 1)
        )
    }

    private func loadCopy() async {
        mineText = localLine(name: myName, sign: row.mine, forSelf: true)
        theirText = localLine(name: theirName, sign: row.theirs, forSelf: false)
        togetherText = "\(row.mine.labelTR) ve \(row.theirs.labelTR), \(row.label.lowercased()) hattında aynı şeyi istemez. Biri yaklaşırken diğeri kendi temposunu korur."
        loading = DiscoverAI.isAvailable
        var sky = UserSky()
        sky.userId = myUserId
        sky.name = myName
        let out = await DiscoverAI.placement(
            label: row.label,
            myName: myName,
            theirName: theirName,
            mySign: row.mine.labelTR,
            theirSign: row.theirs.labelTR,
            sky: sky
        )
        withAnimation(.easeInOut(duration: 0.25)) {
            mineText = out.mine
            theirText = out.theirs
            togetherText = out.together
            usedAI = out.usedAI
            loading = false
        }
    }

    /// Offline copy that is not the same sentence for both people.
    private func localLine(name: String, sign: ZodiacSign, forSelf: Bool) -> String {
        let element = sign.element.labelTR
        if forSelf {
            return "\(name), \(row.label) burcun \(sign.labelTR) (\(element)). Bu noktada sen ilişkiyi içeriden kurarsın: önce kendi ihtiyacını duyarsın, sonra karşına açılırsın. \(theirName) bunu senin temposu olarak yaşar."
        }
        return "\(name) için aynı \(row.label) noktası \(sign.labelTR) (\(element)) üzerinden işler. O, senin yaptığın gibi içeri kapanmaz; tepkisini dışarı ve ilişkiye doğru verir. Bu yüzden aynı satır ikinizde iki ayrı alışkanlık üretir."
    }
}

// MARK: - Bond dimension explain (AI-enriched when available)

/// Full-screen read for one Astro Bond percentage — how this pair matches, and what the % means.
private struct BondDimensionExplainView: View {
    @Environment(\.dismiss) private var dismiss
    let kind: BondIconKind
    let percent: Int
    let myName: String
    let theirName: String
    let mySun: ZodiacSign?
    let theirSun: ZodiacSign?
    let myMoon: ZodiacSign?
    let theirMoon: ZodiacSign?
    let myUserId: String

    @State private var matchText: String = ""
    @State private var percentText: String = ""
    @State private var usedAI = false
    @State private var loading = true

    private var vibe: String {
        switch percent {
        case 88...: return "Nadir bir kıvılcım"
        case 75..<88: return "Sıcak ve akıcı"
        case 60..<75: return "Merak uyandıran"
        default: return "Yavaş açılan bir bağ"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(ABColor.ink)
                        .crystalIconBezel(size: 40, cornerRadius: 14)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                Spacer()
                if usedAI {
                    Label("sana özel", systemImage: "sparkle")
                        .font(ABFont.body(12, weight: .semibold))
                        .foregroundStyle(kind.tint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(kind.tint.opacity(0.16)))
                        .overlay(Capsule().strokeBorder(kind.tint.opacity(0.45), lineWidth: 1))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    hero
                    explainBlock(
                        icon: "heart.text.square.fill",
                        eyebrow: "BU İKİLİDE",
                        title: "Nasıl hissedilir?",
                        body: matchText
                    )
                    explainBlock(
                        icon: "moon.stars.fill",
                        eyebrow: "YÜZDE",
                        title: "Ne anlatıyor?",
                        body: percentText
                    )
                    if loading {
                        HStack(spacing: 8) {
                            ProgressView().tint(kind.tint)
                            Text("Gökyüzü senin için yazıyor…")
                                .font(ABFont.body(13, weight: .medium))
                                .foregroundStyle(ABColor.ink.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 48)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                Image("reveal_bg").resizable().scaledToFill().ignoresSafeArea()
                Color.black.opacity(0.28).ignoresSafeArea()
                RadialGradient(
                    colors: [kind.tint.opacity(0.28), .clear],
                    center: .top,
                    startRadius: 10,
                    endRadius: 340
                )
                .ignoresSafeArea()
            }
        }
        .task { await loadCopy() }
    }

    private var hero: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(kind.tint.opacity(0.16))
                    .frame(width: 148, height: 148)
                    .blur(radius: 8)
                Circle().stroke(kind.tint.opacity(0.18), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: CGFloat(percent) / 100)
                    .stroke(
                        AngularGradient(colors: kind.gradient + [kind.gradient[0]], center: .center),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: kind.tint.opacity(0.7), radius: 8)
                VStack(spacing: 2) {
                    BondDimensionIcon(kind: kind, size: 26)
                    Text("\(percent)")
                        .font(ABFont.display(52, weight: .regular))
                        .foregroundStyle(
                            LinearGradient(colors: [.white, kind.gradient[0]], startPoint: .top, endPoint: .bottom)
                        )
                    Text("%")
                        .font(ABFont.body(13, weight: .bold))
                        .foregroundStyle(kind.tint)
                        .offset(y: -6)
                }
            }
            .frame(width: 156, height: 156)

            Text(kind.title)
                .font(ABFont.display(28))
                .foregroundStyle(ABColor.ink)
                .multilineTextAlignment(.center)
            Text(vibe)
                .font(ABFont.body(14, weight: .semibold))
                .foregroundStyle(kind.tint)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(kind.tint.opacity(0.14)))
            Text("\(myName)  ×  \(theirName)")
                .font(ABFont.body(13, weight: .medium))
                .foregroundStyle(ABColor.ink.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func explainBlock(icon: String, eyebrow: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(kind.tint)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(kind.tint.opacity(0.16)))
                VStack(alignment: .leading, spacing: 1) {
                    Text(eyebrow)
                        .font(ABFont.body(10, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(kind.tint.opacity(0.9))
                    Text(title)
                        .font(ABFont.display(20))
                        .foregroundStyle(ABColor.ink)
                }
            }
            Text(body.isEmpty ? "…" : body)
                .font(ABFont.body(16))
                .foregroundStyle(ABColor.ink.opacity(0.9))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [kind.tint.opacity(0.16), Color(hex: "#F3E0B8").opacity(0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(kind.tint.opacity(0.35), lineWidth: 1)
        )
    }

    private func loadCopy() async {
        matchText = "\(myName) ile \(theirName) arasında \(kind.title.lowercased()) yaklaşık %\(percent). \(kind.note)"
        percentText = kind.meaning
        loading = DiscoverAI.isAvailable
        var sky = UserSky()
        sky.userId = myUserId
        sky.name = myName
        sky.sun = mySun
        sky.moon = myMoon
        sky.rising = nil
        let out = await DiscoverAI.bondDimension(
            kindTitle: kind.title,
            meaning: kind.meaning,
            percent: percent,
            note: kind.note,
            myName: myName,
            theirName: theirName,
            mySun: mySun?.labelTR,
            theirSun: theirSun?.labelTR,
            myMoon: myMoon?.labelTR,
            theirMoon: theirMoon?.labelTR,
            sky: sky
        )
        withAnimation(.easeInOut(duration: 0.25)) {
            matchText = out.matchText
            percentText = out.percentText
            usedAI = out.usedAI
            loading = false
        }
    }
}

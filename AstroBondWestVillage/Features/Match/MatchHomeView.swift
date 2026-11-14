import SwiftUI
import UIKit

@MainActor
@Observable
final class MatchViewModel {
    enum Phase: Equatable {
        case idle
        case spinning
        case revealed
        /// Thumbs-up given: full-screen synastry summary with "Ortak Sinastriyi Gör".
        case matched
    }

    var phase: Phase = .idle
    var pool: [MatchCard] = []
    var active: MatchCard?
    var wheelRotation: Double = 0
    var isLoading = false
    var message: String?
    var openChat: ConversationSummary?
    var isOpeningChat = false
    var remainingReveals = DailyRevealQuotaStore.dailyLimit
    var todayDecisions: [MatchDecisionsStore.Record] = []
    var prefs = MatchPrefsStore.shared.snapshot
    var detailCard: MatchCard?
    var mySun: ZodiacSign?
    var myMoon: ZodiacSign?
    var myRising: ZodiacSign?
    var myName: String = "Sen"
    var myPhotoURL: String?
    var myCartoonAvatarId: String?
    var myChart: NatalChart?
    var theirChart: NatalChart?

    private let matches = MatchService()
    private let messaging = MessagingService()
    private let profiles = ProfileService()
    private let decisions = MatchDecisionsStore.shared
    private let quota = DailyRevealQuotaStore.shared
    private let spinDuration: Double = 6.0
    private var spinTask: Task<Void, Never>?
    private var myUserId: String?

    /// Wheel shows the match (revealed or already confirmed).
    var showsResult: Bool { phase == .revealed || phase == .matched }
    var canMatch: Bool { remainingReveals > 0 }
    var hasUnrevealedCandidates: Bool { !pool.isEmpty }
    var canSpinForNewMatch: Bool { canMatch && hasUnrevealedCandidates }
    var quotaLabel: String { "Sınırsız eşleşme" }
    var todaysAccepted: [MatchDecisionsStore.Record] {
        todayDecisions.filter(\.accepted)
    }

    func bootstrap(userId: String) async {
        myUserId = userId
        prefs = MatchPrefsStore.shared.snapshot
        refreshLocal(userId: userId)
        if let snap = try? await profiles.fetchSnapshot(userId: userId) {
            mySun = snap.sunSign
            myMoon = snap.moonSign
            myRising = snap.risingSign
            if !snap.displayName.trimmingCharacters(in: .whitespaces).isEmpty {
                myName = snap.displayName
            }
            myPhotoURL = snap.photoURL
            myCartoonAvatarId = snap.cartoonAvatarId
        }
        myChart = try? await ChartService.shared.ensureOwnChart(userId: userId)
        if let chart = myChart {
            mySun = chart.sunSign
            myMoon = chart.moonSign
            myRising = chart.risingSign
        }
        await load()
    }

    func refreshLocal(userId: String) {
        remainingReveals = quota.remaining(for: userId)
        todayDecisions = decisions.todayHistory(for: userId)
    }

    func load() async {
        isLoading = true
        message = nil
        defer { isLoading = false }
        do {
            var cards = try await matches.fetchCandidates()
            cards = applyLocalFilters(cards)
            if let uid = myUserId {
                let rejected = decisions.rejectedIds(for: uid)
                let accepted = decisions.acceptedIds(for: uid)
                cards = cards.filter { !rejected.contains($0.id) && !accepted.contains($0.id) }
            }
            pool = cards
        } catch {
            message = error.localizedDescription
        }
    }

    func persistPrefs(_ next: MatchPrefsStore.Snapshot) {
        prefs = next
        MatchPrefsStore.shared.snapshot = next
    }

    func spin() {
        guard phase == .idle else { return }
        spinTask?.cancel()
        message = nil
        phase = .spinning

        withAnimation(.easeInOut(duration: spinDuration)) {
            // Whole turns only, so the matched sign lands where its highlight is drawn.
            wheelRotation += 360 * 2
        }

        spinTask = Task {
            async let network: MatchCard? = revealNext()
            try? await Task.sleep(nanoseconds: UInt64(spinDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            if let card = await network {
                active = card
                theirChart = await ChartService.shared.fetchOrSynthesize(
                    userId: card.id,
                    sun: card.sunSign,
                    moon: card.moonSign,
                    rising: card.risingSign
                )
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    phase = .revealed
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    phase = .idle
                }
            }
        }
    }

    func reject(myUserId: String) {
        guard let active else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        decisions.reject(myUserId: myUserId, card: active)
        dismissReveal()
        refreshLocal(userId: myUserId)
    }

    /// Thumbs-up: keep them on today's strip, open a Messages thread, return to the wheel.
    func acceptReveal(myUserId: String) {
        guard let active else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        let card = active
        decisions.accept(myUserId: myUserId, card: card)
        ConversationsStore.shared.upsert(
            ConversationSummary(
                id: "pending-\(card.id)",
                otherUserId: card.id,
                otherName: card.displayName,
                otherPhotoURL: card.photoURL,
                otherCartoonAvatarId: card.cartoonAvatarId,
                otherSunSign: card.sunSign,
                lastMessage: "Astro Bond açıldı. İlk mesajı sen at!",
                lastMessageAt: Date(),
                unreadCount: 0
            )
        )
        refreshLocal(userId: myUserId)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            phase = .matched
        }
        Task { await ConversationsStore.shared.ensureConversation(otherUserId: card.id) }
    }

    func dismissReveal() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            active = nil
            theirChart = nil
            phase = .idle
            message = nil
        }
    }

    func acceptAndChat(myUserId: String) async {
        guard let active else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        isOpeningChat = true
        message = nil
        defer { isOpeningChat = false }
        decisions.accept(myUserId: myUserId, card: active)
        refreshLocal(userId: myUserId)
        do {
            let conversation = try await messaging.getOrCreateConversation(otherUserId: active.id)
            self.active = nil
            theirChart = nil
            phase = .idle
            openChat = conversation
            ConversationsStore.shared.upsert(conversation)
        } catch {
            message = error.localizedDescription
        }
    }

    func message(card: MatchCard, myUserId: String) async {
        if active?.id == card.id {
            await acceptAndChat(myUserId: myUserId)
            return
        }
        decisions.accept(myUserId: myUserId, card: card)
        refreshLocal(userId: myUserId)
        isOpeningChat = true
        message = nil
        defer { isOpeningChat = false }
        do {
            let conversation = try await messaging.getOrCreateConversation(otherUserId: card.id)
            openChat = conversation
            ConversationsStore.shared.upsert(conversation)
        } catch {
            message = error.localizedDescription
        }
    }

    private func revealNext() async -> MatchCard? {
        if pool.isEmpty { await load() }
        guard let next = pool.first else {
            message = MatchServiceError.emptyPool.localizedDescription
            return nil
        }
        do {
            try await matches.reveal(userId: next.id)
            if let uid = myUserId {
                quota.recordReveal(for: uid)
                refreshLocal(userId: uid)
            }
            pool.removeAll { $0.id == next.id }
            return next
        } catch {
            message = error.localizedDescription
            return nil
        }
    }

    private func applyLocalFilters(_ cards: [MatchCard]) -> [MatchCard] {
        cards.filter { card in
            if prefs.ageEnabled {
                if card.age > 0, (card.age < prefs.ageMin || card.age > prefs.ageMax) {
                    return false
                }
            }
            if prefs.locationEnabled, let city = card.city, !city.isEmpty {
                let needle = prefs.searchCity.trimmingCharacters(in: .whitespacesAndNewlines)
                if !needle.isEmpty,
                   !city.localizedCaseInsensitiveContains(needle),
                   !needle.localizedCaseInsensitiveContains(city) {
                    return false
                }
            }
            return true
        }
    }
}

struct MatchHomeView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.hideTabBar) private var hideTabBar
    @Environment(\.compactTabBar) private var compactTabBar
    @Environment(\.activeTab) private var activeTab
    @State private var model = MatchViewModel()
    @State private var intents: Set<MatchIntent> = []
    @State private var orientations: Set<MatchOrientation> = []
    @State private var homoTypes: Set<MatchHomoType> = []
    @State private var showSelectionNotice = false
    @State private var showDailyLimit = false
    @State private var showNoCandidates = false

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            ZStack {
                CosmicBackdrop()

                // Warm nebula + moons behind the match result.
                Color.clear
                    .ignoresSafeArea()
                    .overlay {
                        Image("reveal_bg")
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
                    .opacity(model.showsResult ? 1 : 0)
                    .animation(.easeInOut(duration: 0.8), value: model.phase)
                    .allowsHitTesting(false)

                RevealSkyDecor()
                    .opacity(model.showsResult ? 1 : 0)
                    .animation(.easeInOut(duration: 0.8), value: model.phase)

                // Each match phase is a full-screen page that slides as a whole.
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    let idleWheel = min(w * 0.80, h * 0.41)
                    let resultWheel = min(w * 0.74, h * 0.40)

                    ZStack {
                        switch model.phase {
                        case .idle, .spinning:
                            matchingStagePage(width: w, height: h, wheelSize: idleWheel)
                                .transition(Self.fullScreenSlide)
                        case .revealed:
                            if let match = model.active {
                                revealedPage(match, width: w, height: h, wheelSize: resultWheel)
                                    .transition(Self.fullScreenSlide)
                            }
                        case .matched:
                            if let match = model.active {
                                matchedPage(match, width: w, height: h, wheelSize: resultWheel)
                                    .transition(Self.fullScreenSlide)
                            }
                        }
                    }
                    .animation(.spring(response: 0.55, dampingFraction: 0.86), value: model.phase)
                }

            }
            .toolbar(.hidden, for: .navigationBar)
            // Above the floating tab bar so Mesaj Gönder / back aren't covered or dead.
            .fullScreenCover(item: $model.detailCard) { card in
                MatchDetailSheet(
                    card: card,
                    mySeed: session.user?.id ?? "self",
                    myName: model.myName,
                    myPhotoURL: model.myPhotoURL,
                    myCartoonAvatarId: model.myCartoonAvatarId,
                    mySun: model.mySun,
                    myMoon: model.myMoon,
                    myRising: model.myRising,
                    seedChart: model.myChart,
                    intent: model.prefs.intent,
                    onMessage: {
                        model.detailCard = nil
                        hideTabBar?.wrappedValue = true
                        if let id = session.user?.id {
                            Task { await model.message(card: card, myUserId: id) }
                        }
                    },
                    onBack: { model.detailCard = nil }
                )
                .onAppear { hideTabBar?.wrappedValue = true }
                .onDisappear {
                    if model.openChat == nil {
                        hideTabBar?.wrappedValue = false
                    }
                }
            }
            .task {
                if let id = session.user?.id {
                    await model.bootstrap(userId: id)
                }
            }
            .onChange(of: activeTab?.wrappedValue) { _, tab in
                guard tab == 1 else { return }
                if let id = session.user?.id {
                    Task { await model.load() }
                }
            }
            .onChange(of: model.phase) { _, phase in
                compactTabBar?.wrappedValue = false
            }
            .onDisappear { compactTabBar?.wrappedValue = false }
            .alert("Günlük eşleşme hakkın doldu", isPresented: $showDailyLimit) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("Yeni eşleşmeler için yarın tekrar dene. Bugünkü eşleşmelerine aşağıdan dönebilirsin.")
            }
            .alert("Eşleşme bulunamadı", isPresented: Binding(
                get: { model.message != nil && model.phase == .idle },
                set: { if !$0 { model.message = nil } }
            )) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(failureText)
            }
            .alert("Yeni eşleşme yok", isPresented: $showNoCandidates) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("Bugün gösterilecek başka profil kalmadı. Aşağıdaki eşleşmelerine dönebilir veya yarın tekrar çevirebilirsin.")
            }
            .navigationDestination(item: $model.openChat) { conv in
                ChatView(conversation: conv, onBack: { model.openChat = nil })
            }
        }
    }

    /// Whole-screen vertical slide used between match stages and ortak sinastri.
    private static var fullScreenSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }

    private var failureText: String {
        let m = model.message ?? ""
        if m.contains("hakkın doldu"), DailyRevealQuotaStore.isUnlimited {
            return "\(m)\nSunucu günlük 3 eşleşme sınırı uyguluyor. Test için Supabase'de profiles.is_premium = true yapabilirsin."
        }
        return m
    }

    private var header: some View {
        VStack(spacing: 5) {
            AstroBondLogoMark(flare: model.showsResult)
            Text("BAĞ GÖRÜNENDEN ÖNCE BAŞLAR")
                .font(ABFont.body(10, weight: .medium))
                .tracking(2.2)
                .foregroundStyle(ABColor.ink.opacity(0.55))
            Text(model.quotaLabel)
                .font(ABFont.body(11, weight: .medium))
                .foregroundStyle(ABColor.lavenderSoft)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Capsule(style: .continuous).fill(ABColor.lavender.opacity(0.18)))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(ABColor.lavender.opacity(0.45), lineWidth: 1)
                )
        }
    }

    private func wheelStack(size: CGFloat) -> some View {
        CosmicMatchWheel(
            rotation: model.wheelRotation,
            isSpinning: model.phase == .spinning,
            isRevealed: model.showsResult,
            size: size,
            revealedGlyph: model.active?.sunSign?.lineGlyph,
            revealedSignIndex: model.active?.sunSign?.index,
            showsTapPrompt: true,
            onTap: startSpin
        )
    }

    /// Idle / spinning: logo + wheel + prefs (or "searching") scroll together as one page.
    private func matchingStagePage(width w: CGFloat, height h: CGFloat, wheelSize: CGFloat) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                header
                    .padding(.top, h * 0.044)
                wheelStack(size: wheelSize)
                    .frame(width: w, height: wheelSize)
                    .padding(.top, 14)
                    .padding(.bottom, 8)

                if model.phase == .spinning {
                    VStack(spacing: 10) {
                        Text("Eşleşme aranıyor...")
                            .font(ABFont.display(26, weight: .regular))
                            .foregroundStyle(ABColor.ink)
                            .multilineTextAlignment(.center)
                        Text("Yıldızlar seninle uyumlu ruhları keşfediyor.")
                            .font(ABFont.body(14))
                            .foregroundStyle(ABColor.ink.opacity(0.55))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 8)
                } else {
                    VStack(spacing: 14) {
                        if showSelectionNotice {
                            Text("Önce bağ ve eşleşme tercihinden seçim yap, sonra çarkın ortasına bas.")
                                .font(ABFont.body(12.5, weight: .medium))
                                .foregroundStyle(ABColor.ink.opacity(0.95))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Capsule(style: .continuous).fill(ABColor.lavender.opacity(0.16)))
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(ABColor.lavender.opacity(0.55), lineWidth: 1)
                                )
                        }

                        BondSettingsPanel(
                            intents: $intents,
                            orientations: $orientations,
                            homoTypes: $homoTypes,
                            prefs: $model.prefs
                        )

                        if !model.todaysAccepted.isEmpty {
                            todaysMatchesStrip
                                .padding(.top, 6)
                        }
                    }
                    .padding(.horizontal, 22)
                }
            }
            .padding(.bottom, 130)
            .frame(width: w)
        }
        .frame(width: w, height: h, alignment: .top)
    }

    /// Pre-confirm reveal: whole page (logo, wheel, card, actions) slides as one unit.
    private func revealedPage(_ match: MatchCard, width w: CGFloat, height h: CGFloat, wheelSize: CGFloat) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                header
                    .padding(.top, h * 0.044)
                wheelStack(size: wheelSize)
                    .frame(width: w, height: wheelSize)
                    .padding(.top, 14)
                    .padding(.bottom, 6)
                revealedCard(match)
                    .padding(.horizontal, 22)
                revealedActions
                    .padding(.top, 4)
            }
            .padding(.bottom, 130)
            .frame(width: w)
        }
        .frame(width: w, height: h, alignment: .top)
    }

    /// Confirmed match: the whole screen becomes one scrollable page (logo, wheel, synastry summary,
    /// "Ortak Sinastriyi Gör"); the back arrow returns to the match selections.
    private func matchedPage(_ match: MatchCard, width w: CGFloat, height h: CGFloat, wheelSize: CGFloat) -> some View {
        let report = BondStory.report(
            mySun: model.mySun,
            their: match,
            intent: model.prefs.intent,
            myChart: model.myChart,
            theirChart: model.theirChart
        )
        return ZStack(alignment: .topLeading) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    header
                        .padding(.top, h * 0.044)
                    wheelStack(size: wheelSize)
                        .frame(width: w, height: wheelSize)
                        .padding(.top, 14)
                        .padding(.bottom, 10)

                    SynastrySummaryHeader(
                        card: match,
                        myName: model.myName,
                        myPhotoURL: model.myPhotoURL,
                        myCartoonAvatarId: model.myCartoonAvatarId,
                        mySun: model.mySun,
                        report: report
                    )
                    .padding(.horizontal, 22)

                    GlowActionButton(
                        title: "Ortak Sinastriyi Gör",
                        icon: "sparkles",
                        colors: [Color(hex: "#F0CE7E"), ABColor.warm, Color(hex: "#E8B9A0")]
                    ) {
                        model.detailCard = match
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 4)
                }
                .padding(.bottom, 130)
                .frame(width: w)
            }

            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { model.dismissReveal() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(ABColor.ink)
                    .crystalIconBezel(size: 40, cornerRadius: 14)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.leading, 14)
            .padding(.top, h * 0.044 - 2)
            .accessibilityLabel("Eşleşme seçimlerine dön")
        }
        .frame(width: w, height: h, alignment: .top)
    }

    private var todaysMatchesStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BUGÜNKÜ EŞLEŞMELER")
                .font(ABFont.body(10, weight: .bold))
                .foregroundStyle(ABColor.ink.opacity(0.45))
                .padding(.leading, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(model.todaysAccepted) { rec in
                        Button {
                            model.detailCard = card(from: rec)
                        } label: {
                            VStack(spacing: 6) {
                                PersonAvatar(
                                    name: rec.displayName,
                                    photoURL: rec.photoURL,
                                    cartoonAvatarId: rec.cartoonAvatarId,
                                    sunSign: rec.sunSign,
                                    unlocked: false,
                                    size: 52
                                )
                                .overlay {
                                    if model.detailCard?.id == rec.id || model.active?.id == rec.id {
                                        Circle().stroke(ABColor.lavender, lineWidth: 2)
                                    }
                                }
                                Text(rec.displayName.components(separatedBy: " ").first ?? rec.displayName)
                                    .font(ABFont.body(11, weight: .medium))
                                    .foregroundStyle(ABColor.ink.opacity(0.75))
                                    .lineLimit(1)
                            }
                            .frame(width: 64)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Reveal ("Eşleşme sonucu") card + actions

    private func revealedCard(_ match: MatchCard) -> some View {
        let score = BondStory.report(
            mySun: model.mySun,
            their: match,
            intent: model.prefs.intent,
            myChart: model.myChart,
            theirChart: model.theirChart
        ).overall
        let warm = ABColor.warm

        return HStack(alignment: .top, spacing: 16) {
            // Zodiac sphere instead of a photo.
            ZStack {
                Circle().fill(
                    RadialGradient(
                        colors: [Color(hex: "#5B4B5E"), Color(hex: "#1A121D"), Color(hex: "#09060C")],
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: 2, endRadius: 70
                    )
                )
                // Moon-like surface: rim light on the left + soft craters.
                Circle().fill(
                    RadialGradient(colors: [warm.opacity(0.38), .clear],
                                   center: UnitPoint(x: 0.05, y: 0.5), startRadius: 0, endRadius: 70)
                )
                ForEach(Array([(-22.0, -26.0, 14.0), (18.0, -30.0, 9.0), (28.0, 6.0, 16.0),
                               (-30.0, 18.0, 10.0), (4.0, 30.0, 12.0), (-8.0, -4.0, 7.0)].enumerated()), id: \.offset) { _, c in
                    Circle()
                        .fill(ABColor.panel.opacity(0.22))
                        .overlay(Circle().stroke(warm.opacity(0.15), lineWidth: 0.6))
                        .frame(width: c.2, height: c.2)
                        .offset(x: c.0, y: c.1)
                }
                Circle().strokeBorder(
                    LinearGradient(colors: [warm.opacity(0.95), warm.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1.6
                )
                Text(match.sunSign?.glyph ?? "✦")
                    .font(.system(size: 46))
                    .foregroundStyle(warm)
                    .shadow(color: warm.opacity(0.6), radius: 8)
            }
            .frame(width: 96, height: 96)
            .clipShape(Circle())
            .shadow(color: warm.opacity(0.28), radius: 12)

            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .top) {
                    Text(match.displayName)
                        .font(ABFont.display(24, weight: .regular))
                        .foregroundStyle(ABColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 4)
                    Menu {
                        Button("Gizle", systemImage: "eye.slash") {
                            if let id = session.user?.id { model.reject(myUserId: id) }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(ABColor.ink.opacity(0.7))
                            .frame(width: 28, height: 24)
                    }
                }

                if let sign = match.sunSign {
                    HStack(spacing: 10) {
                        Text(sign.glyph)
                            .font(.system(size: 17))
                            .foregroundStyle(warm)
                            .frame(width: 34, height: 34)
                            .overlay(Circle().stroke(warm.opacity(0.5), lineWidth: 1))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(sign.labelTR.uppercased(with: Locale(identifier: "tr_TR")))
                                .font(ABFont.body(14, weight: .bold))
                                .tracking(0.8)
                                .foregroundStyle(ABColor.ink)
                            Text(sign.dateRangeText)
                                .font(ABFont.body(11.5))
                                .foregroundStyle(ABColor.ink.opacity(0.6))
                        }
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(warm)
                    Text("%\(score)")
                        .font(ABFont.display(21, weight: .bold))
                        .foregroundStyle(ABColor.ink)
                    Text("Astro Uyum")
                        .font(ABFont.display(14, weight: .regular))
                        .foregroundStyle(ABColor.ink.opacity(0.75))
                }

                Button {
                    model.detailCard = match
                } label: {
                    HStack(spacing: 6) {
                        Text("Profili gör")
                        Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold))
                    }
                    .font(ABFont.body(13.5, weight: .medium))
                    .foregroundStyle(ABColor.ink.opacity(0.9))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(ABColor.panel.opacity(0.42))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [warm.opacity(0.75), warm.opacity(0.18)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
        .shadow(color: warm.opacity(0.12), radius: 14)
    }

    private var revealedActions: some View {
        HStack(spacing: 0) {
            Spacer()
            revealButton(icon: "heart.fill", label: "İlgimi çekti") {
                if let id = session.user?.id { model.acceptReveal(myUserId: id) }
            }
            Spacer()
            revealButton(icon: "sparkle", label: "Yeni bir eşleşme") {
                guard let id = session.user?.id else { return }
                model.reject(myUserId: id)
                Task {
                    try? await Task.sleep(nanoseconds: 450_000_000)
                    startSpin()
                }
            }
            Spacer()
        }
        .background(alignment: .top) {
            ZStack {
                Ellipse().stroke(ABColor.warm.opacity(0.35), lineWidth: 1)
                    .frame(width: 360, height: 70)
                    .rotationEffect(.degrees(-4))
                Ellipse().stroke(ABColor.warm.opacity(0.18), lineWidth: 1)
                    .frame(width: 390, height: 96)
                    .rotationEffect(.degrees(3))
            }
            .offset(y: 4)
            .allowsHitTesting(false)
        }
    }

    private func revealButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        let isHeart = icon == "heart.fill"
        let glow = isHeart ? Color(hex: "#E7B8FF") : Color(hex: "#FFD36B")
        return Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    // Soft halo
                    Circle().fill(glow.opacity(0.35)).frame(width: 104, height: 104).blur(radius: 18)
                    // Glassy body
                    Circle().fill(RadialGradient(colors: [glow.opacity(0.42), Color(hex: "#1A1322").opacity(0.85)],
                                                 center: UnitPoint(x: 0.5, y: 0.3), startRadius: 2, endRadius: 52))
                        .frame(width: 88, height: 88)
                    // Top highlight
                    Circle().fill(LinearGradient(colors: [Color.white.opacity(0.35), .clear], startPoint: .top, endPoint: .center))
                        .frame(width: 80, height: 80)
                        .offset(y: -3)
                        .mask(Circle().frame(width: 88, height: 88))
                    Circle().strokeBorder(
                        LinearGradient(colors: [Color(hex: "#FFF3D6"), glow, glow.opacity(0.35)], startPoint: .top, endPoint: .bottom),
                        lineWidth: 2.4
                    )
                    .frame(width: 88, height: 88)
                    Circle().strokeBorder(glow.opacity(0.35), lineWidth: 1).frame(width: 98, height: 98)

                    if isHeart {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundStyle(LinearGradient(colors: [.white, Color(hex: "#E9C8FF")], startPoint: .top, endPoint: .bottom))
                            .shadow(color: glow, radius: 8)
                            .shadow(color: glow.opacity(0.8), radius: 16)
                    } else {
                        FourPointStar()
                            .fill(LinearGradient(colors: [.white, Color(hex: "#FFD36B")], startPoint: .top, endPoint: .bottom))
                            .frame(width: 44, height: 44)
                            .shadow(color: glow, radius: 8)
                            .shadow(color: glow.opacity(0.8), radius: 16)
                    }
                }
                .frame(width: 104, height: 104)
                Text(label)
                    .font(ABFont.body(14, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .shadow(color: .black.opacity(0.6), radius: 3)
            }
        }
        .buttonStyle(.plain)
    }

    private func card(from rec: MatchDecisionsStore.Record) -> MatchCard {
        MatchCard(
            id: rec.id,
            displayName: rec.displayName,
            age: rec.age,
            city: rec.city,
            sunSign: rec.sunSign,
            moonSign: nil,
            risingSign: nil,
            bio: "",
            photoURL: rec.photoURL,
            cartoonAvatarId: rec.cartoonAvatarId
        )
    }

    private func startSpin() {
        guard model.phase == .idle else { return }
        guard !intents.isEmpty, !orientations.isEmpty else {
            presentSelectionNotice()
            return
        }
        guard model.hasUnrevealedCandidates else {
            showNoCandidates = true
            return
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        applySelections()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            model.spin()
        }
    }

    private func applySelections() {
        var next = model.prefs
        if let primary = MatchIntent.allCases.first(where: { intents.contains($0) }) {
            next.intent = primary
        }
        var genders: [Gender] = []
        if orientations.contains(.kadin) { genders.append(.woman) }
        if orientations.contains(.erkek) { genders.append(.man) }
        if orientations.contains(.lgbt) {
            genders.append(.nonBinary)
            genders.append(.other)
        }
        if !genders.isEmpty { next.preferredGenders = genders }
        model.persistPrefs(next)
    }

    private func presentSelectionNotice() {
        withAnimation(.easeInOut(duration: 0.2)) { showSelectionNotice = true }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) { showSelectionNotice = false }
            }
        }
    }
}

// MARK: - Bond / gender pills (original Cosmic Match)

private enum MatchOrientation: String, CaseIterable, Identifiable {
    case kadin, erkek, lgbt
    var id: String { rawValue }
    var title: String {
        switch self {
        case .kadin: return "Kadın"
        case .erkek: return "Erkek"
        case .lgbt: return "LGBT"
        }
    }
}

private enum MatchHomoType: String, CaseIterable, Identifiable {
    case gay, lezbiyen
    var id: String { rawValue }
    var title: String {
        switch self {
        case .gay: return "Gay"
        case .lezbiyen: return "Lezbiyen"
        }
    }
}

private struct BondSettingsPanel: View {
    @Binding var intents: Set<MatchIntent>
    @Binding var orientations: Set<MatchOrientation>
    @Binding var homoTypes: Set<MatchHomoType>
    @Binding var prefs: MatchPrefsStore.Snapshot

    var body: some View {
        VStack(spacing: 13) {
            orientationSection
            bondieSection
        }
        .padding(.horizontal, 23)
        .frame(maxWidth: .infinity)
    }

    private var orientationSection: some View {
        VStack(spacing: 3) {
            sectionHeading("Eşleşme tercihin nedir?")
            HStack(spacing: 8) {
                ForEach(MatchOrientation.allCases) { option in
                    SelectablePill(title: option.title, selected: orientations.contains(option)) {
                        toggleOrientation(option)
                    }
                }
            }
            if orientations.contains(.lgbt) {
                HStack(spacing: 8) {
                    ForEach(MatchHomoType.allCases) { type in
                        SelectablePill(title: type.title, selected: homoTypes.contains(type)) {
                            toggleHomoType(type)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.85), value: orientations.contains(.lgbt))
    }

    private var bondieSection: some View {
        VStack(spacing: 8) {
            sectionHeading("Nasıl bir bağ kurmak istiyorsun?")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 7), GridItem(.flexible(), spacing: 7)], spacing: 7) {
                ForEach(MatchIntent.allCases) { item in
                    SelectablePill(title: item.bondLabel, selected: intents.contains(item)) {
                        toggleIntent(item)
                    }
                }
            }
        }
    }

    private func sectionHeading(_ title: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(ABFont.display(18, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    LinearGradient(
                        colors: [ABColor.ink, ABColor.ink.opacity(0.88)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .fixedSize(horizontal: false, vertical: true)
            Capsule()
                .fill(ABColor.lavender.opacity(0.85))
                .frame(width: 26, height: 3)
        }
        .frame(maxWidth: .infinity)
    }

    private func toggleIntent(_ item: MatchIntent) {
        withAnimation(.spring(response: 0.26, dampingFraction: 0.8)) {
            if intents.contains(item) { intents.remove(item) } else { intents.insert(item) }
        }
        persist()
    }

    private func toggleOrientation(_ option: MatchOrientation) {
        withAnimation(.spring(response: 0.26, dampingFraction: 0.8)) {
            if orientations.contains(option) {
                orientations.remove(option)
                if option == .lgbt { homoTypes.removeAll() }
            } else {
                orientations.insert(option)
            }
        }
        persist()
    }

    private func toggleHomoType(_ type: MatchHomoType) {
        withAnimation(.spring(response: 0.26, dampingFraction: 0.8)) {
            if homoTypes.contains(type) { homoTypes.remove(type) } else { homoTypes.insert(type) }
        }
        persist()
    }

    private func persist() {
        if let primary = MatchIntent.allCases.first(where: { intents.contains($0) }) {
            prefs.intent = primary
        }
        var genders: [Gender] = []
        if orientations.contains(.kadin) { genders.append(.woman) }
        if orientations.contains(.erkek) { genders.append(.man) }
        if orientations.contains(.lgbt) {
            genders.append(.nonBinary)
            genders.append(.other)
        }
        if !genders.isEmpty { prefs.preferredGenders = genders }
        MatchPrefsStore.shared.snapshot = prefs
    }
}

private struct SelectablePill: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ABFont.body(13, weight: .medium))
                .foregroundStyle(ABColor.ink.opacity(selected ? 1 : 0.9))
                .padding(.horizontal, 12)
                .frame(height: 37)
                .frame(maxWidth: .infinity)
                .background {
                    Capsule(style: .continuous)
                        .fill(selected ? ABColor.lavender.opacity(0.38) : ABColor.panel.opacity(0.88))
                }
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(ABColor.lavender.opacity(selected ? 0.9 : 0.5), lineWidth: 1)
                )
                .shadow(color: ABColor.lavender.opacity(selected ? 0.28 : 0), radius: selected ? 12 : 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

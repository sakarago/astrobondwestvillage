import SwiftUI
import UIKit

@MainActor
@Observable
final class MatchViewModel {
    enum Phase: Equatable {
        case idle
        case spinning
        case revealed
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

    var canMatch: Bool { remainingReveals > 0 }
    var hasUnrevealedCandidates: Bool { !pool.isEmpty }
    var canSpinForNewMatch: Bool { canMatch && hasUnrevealedCandidates }
    var quotaLabel: String {
        let used = DailyRevealQuotaStore.dailyLimit - remainingReveals
        return "Bugün \(used)/\(DailyRevealQuotaStore.dailyLimit) eşleşme"
    }
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
        if let uid = myUserId, quota.remaining(for: uid) <= 0 {
            message = MatchServiceError.dailyLimit.localizedDescription
            return
        }
        spinTask?.cancel()
        message = nil
        phase = .spinning

        withAnimation(.easeInOut(duration: spinDuration)) {
            wheelRotation += 360 * 1.35
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
        dismissReveal()
        refreshLocal(userId: myUserId)
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

                GeometryReader { geo in
                    let tabClearance: CGFloat = 118
                    let usable = max(geo.size.height - tabClearance, 320)
                    let wheelSize = min(geo.size.width * 0.78, usable * 0.44, 320)

                    VStack(spacing: 0) {
                        header
                            .padding(.top, 8)
                        wheelStack(size: wheelSize)
                            .padding(.top, 2)
                        bottomArea
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .layoutPriority(1)
                            .padding(.horizontal, 22)
                    }
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
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
                compactTabBar?.wrappedValue = phase == .revealed
            }
            .onDisappear { compactTabBar?.wrappedValue = false }
            .alert("Günlük eşleşme hakkın doldu", isPresented: $showDailyLimit) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("Yeni eşleşmeler için yarın tekrar dene. Bugünkü eşleşmelerine aşağıdan dönebilirsin.")
            }
            .alert("Yeni eşleşme yok", isPresented: $showNoCandidates) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("Bugün gösterilecek başka profil kalmadı. Aşağıdaki eşleşmelerine dönebilir veya yarın tekrar çevirebilirsin.")
            }
            .navigationDestination(item: $model.detailCard) { card in
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
                        hideTabBar?.wrappedValue = true
                        model.detailCard = nil
                        if let id = session.user?.id {
                            Task { await model.message(card: card, myUserId: id) }
                        }
                    },
                    onBack: { model.detailCard = nil }
                )
                .navigationBarBackButtonHidden(true)
                .toolbar(.hidden, for: .navigationBar)
                .onAppear { hideTabBar?.wrappedValue = true }
                .onDisappear {
                    if model.openChat == nil {
                        hideTabBar?.wrappedValue = false
                    }
                }
            }
            .navigationDestination(item: $model.openChat) { conv in
                ChatView(conversation: conv, onBack: { model.openChat = nil })
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            AstroBondLogoMark()
            Text("BAĞ GÖRÜNENDEN ÖNCE BAŞLAR")
                .font(ABFont.body(10, weight: .medium))
                .tracking(2.2)
                .foregroundStyle(Color.white.opacity(0.55))
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
            isRevealed: model.phase == .revealed,
            size: size,
            revealedGlyph: model.active?.sunSign?.lineGlyph,
            revealedSignIndex: model.active?.sunSign?.index,
            showsTapPrompt: true,
            onTap: startSpin
        )
    }

    @ViewBuilder
    private var bottomArea: some View {
        switch model.phase {
        case .idle:
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    if showSelectionNotice {
                        Text("Önce bağ ve eşleşme tercihinden seçim yap, sonra çarkın ortasına bas.")
                            .font(ABFont.body(12.5, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.95))
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
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .transition(.opacity)

        case .spinning:
            VStack(spacing: 10) {
                Text("Eşleşme aranıyor...")
                    .font(ABFont.display(26, weight: .regular))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("Yıldızlar seninle uyumlu ruhları keşfediyor.")
                    .font(ABFont.body(14))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
            .padding(.top, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .transition(.opacity)

        case .revealed:
            if let match = model.active {
                VStack(spacing: 10) {
                    matchedProfileCard(match)
                    if !model.todaysAccepted.isEmpty {
                        todaysMatchesStrip
                    }
                    if model.canSpinForNewMatch {
                        Text("Başka biri için çarkı tekrar çevir")
                            .font(ABFont.body(12, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.45))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 8)
                .padding(.bottom, 36)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var todaysMatchesStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BUGÜNKÜ EŞLEŞMELER")
                .font(ABFont.body(10, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.45))
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
                                    .foregroundStyle(Color.white.opacity(0.75))
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

    private func matchedProfileCard(_ match: MatchCard) -> some View {
        let score = BondStory.report(
            mySun: model.mySun,
            their: match,
            intent: model.prefs.intent,
            myChart: model.myChart,
            theirChart: model.theirChart
        ).overall

        return VStack(spacing: 14) {
            HStack {
                thumbButton(up: false) {
                    if let id = session.user?.id { model.reject(myUserId: id) }
                }
                Spacer()
                thumbButton(up: true) {
                    if let id = session.user?.id { model.acceptReveal(myUserId: id) }
                }
            }

            Button {
                model.detailCard = match
            } label: {
                HStack(spacing: 16) {
                    PersonAvatar(
                        name: match.displayName,
                        photoURL: match.photoURL,
                        cartoonAvatarId: match.cartoonAvatarId,
                        sunSign: match.sunSign,
                        unlocked: false,
                        size: 100
                    )
                    .opacity(0.84)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(match.displayName)
                            .font(ABFont.display(20))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if match.age > 0 {
                            Text("\(match.age)")
                                .font(ABFont.body(13, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.55))
                        }

                        Divider().background(Color.white.opacity(0.14))

                        if let sign = match.sunSign {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle().stroke(Color.white.opacity(0.25), lineWidth: 1)
                                        .frame(width: 40, height: 40)
                                    Text(sign.lineGlyph)
                                        .font(.system(size: 19))
                                        .foregroundStyle(.white)
                                }
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(sign.labelTR.uppercased())
                                        .font(ABFont.body(14, weight: .bold))
                                        .tracking(1)
                                        .foregroundStyle(.white)
                                    Text(sign.dateRangeText)
                                        .font(ABFont.body(11))
                                        .foregroundStyle(Color.white.opacity(0.45))
                                }
                            }
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color(hex: "#E4E8EF"))
                            Text("%\(score)")
                                .font(ABFont.display(19, weight: .bold))
                                .foregroundStyle(.white)
                            Text("UYUMLU")
                                .font(ABFont.body(12, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(Color.white.opacity(0.6))
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Text("Profili gör")
                .font(ABFont.body(12, weight: .medium))
                .foregroundStyle(ABColor.lavenderSoft.opacity(0.85))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [ABColor.lavenderSoft.opacity(0.5), ABColor.lavender.opacity(0.28)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 4
                )
                .blur(radius: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color(hex: "#E2DDFF").opacity(0.55), ABColor.lavender.opacity(0.24)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
    }

    private func thumbButton(up: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: up ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.white.opacity(0.06)))
                .overlay(
                    Circle().stroke(ABColor.lavender.opacity(up ? 0.9 : 0.6), lineWidth: 1.2)
                )
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
        guard model.canMatch else {
            showDailyLimit = true
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
        VStack(spacing: 16) {
            orientationSection
            bondieSection
        }
        .frame(maxWidth: .infinity)
    }

    private var orientationSection: some View {
        VStack(spacing: 12) {
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
        VStack(spacing: 12) {
            sectionHeading("Nasıl bir bağ kurmak istiyorsun?")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(MatchIntent.allCases) { item in
                    SelectablePill(title: item.bondLabel, selected: intents.contains(item)) {
                        toggleIntent(item)
                    }
                }
            }
        }
    }

    private func sectionHeading(_ title: String) -> some View {
        Text(title)
            .font(ABFont.display(18, weight: .regular))
            .multilineTextAlignment(.center)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.white, Color(hex: "#E4E2F2").opacity(0.88)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .fixedSize(horizontal: false, vertical: true)
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
                .foregroundStyle(Color.white.opacity(selected ? 1 : 0.9))
                .padding(.horizontal, 12)
                .frame(height: 44)
                .frame(maxWidth: .infinity)
                .background {
                    Capsule(style: .continuous)
                        .fill(selected ? ABColor.lavender.opacity(0.38) : Color.white.opacity(0.07))
                }
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(ABColor.lavender.opacity(selected ? 0.9 : 0.32), lineWidth: 1)
                )
                .shadow(color: ABColor.lavender.opacity(selected ? 0.28 : 0), radius: selected ? 12 : 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

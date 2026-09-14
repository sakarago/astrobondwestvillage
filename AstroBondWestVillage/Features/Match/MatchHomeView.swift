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
    var showPrefs = false
    var showDetail = false
    var mySun: ZodiacSign?

    private let matches = MatchService()
    private let messaging = MessagingService()
    private let profiles = ProfileService()
    private let decisions = MatchDecisionsStore.shared
    private let quota = DailyRevealQuotaStore.shared
    private let spinDuration: Double = 4.2
    private var spinTask: Task<Void, Never>?
    private var myUserId: String?

    func bootstrap(userId: String) async {
        myUserId = userId
        prefs = MatchPrefsStore.shared.snapshot
        refreshLocal(userId: userId)
        if let snap = try? await profiles.fetchSnapshot(userId: userId) {
            mySun = snap.sunSign
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
            if phase == .idle, pool.isEmpty {
                message = MatchServiceError.emptyPool.localizedDescription
            }
        } catch {
            message = error.localizedDescription
        }
    }

    func savePrefs(_ next: MatchPrefsStore.Snapshot) {
        prefs = next
        MatchPrefsStore.shared.snapshot = next
        showPrefs = false
        Task { await load() }
    }

    func spin() {
        guard phase != .spinning else { return }
        if let uid = myUserId, quota.remaining(for: uid) <= 0 {
            message = MatchServiceError.dailyLimit.localizedDescription
            return
        }
        spinTask?.cancel()
        message = nil
        phase = .spinning

        withAnimation(.timingCurve(0.15, 0.05, 0.1, 1.0, duration: spinDuration)) {
            wheelRotation += 360 * 4 + Double.random(in: 40...280)
        }

        spinTask = Task {
            async let network: MatchCard? = revealNext()
            try? await Task.sleep(nanoseconds: UInt64(spinDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            if let card = await network {
                active = card
                phase = .revealed
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                phase = .idle
            }
        }
    }

    func reject(myUserId: String) {
        guard let active else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        decisions.reject(myUserId: myUserId, card: active)
        self.active = nil
        phase = .idle
        message = nil
        refreshLocal(userId: myUserId)
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
            openChat = conversation
            // Instant inbox update — the Messages tab view stays mounted in
            // the background (see MainTabView), so it won't re-run its own
            // load on its own; push the result to the shared store instead.
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
    @State private var model = MatchViewModel()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header

                    CosmicMatchWheel(
                        rotation: model.wheelRotation,
                        isSpinning: model.phase == .spinning,
                        size: 300,
                        mySeed: session.user?.id ?? "self",
                        theirSeed: model.phase == .revealed ? model.active?.id : nil
                    ) {
                        model.spin()
                    }

                    if model.phase == .revealed, let active = model.active {
                        matchCard(active)
                            .padding(.horizontal, 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        bondPrefsStrip
                            .padding(.horizontal, 20)

                        if !model.todayDecisions.isEmpty {
                            todayStrip
                        }
                    }

                    if let message = model.message {
                        Text(message)
                            .font(ABFont.body(13))
                            .foregroundStyle(Color(hex: "#C69A9A"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }

                    if model.phase != .revealed {
                        CrystalCTAButton(
                            title: model.phase == .spinning ? "Çevriliyor…" : "Çarkı Çevir",
                            isEnabled: model.phase != .spinning && !model.isLoading && model.remainingReveals > 0
                        ) {
                            model.spin()
                        }
                        .padding(.horizontal, 28)
                    }

                    Spacer(minLength: 120)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.86), value: model.phase)
            .toolbar(.hidden, for: .navigationBar)
            .task {
                if let id = session.user?.id {
                    await model.bootstrap(userId: id)
                }
            }
            .sheet(isPresented: $model.showPrefs) {
                MatchPrefsSheet(prefs: model.prefs) { model.savePrefs($0) }
            }
            .sheet(isPresented: $model.showDetail) {
                if let active = model.active {
                    MatchDetailSheet(
                        card: active,
                        mySun: model.mySun,
                        intent: model.prefs.intent
                    )
                    .presentationDetents([.medium, .large])
                }
            }
            .navigationDestination(item: $model.openChat) { conv in
                ChatView(conversation: conv)
                    .onAppear { hideTabBar?.wrappedValue = true }
                    .onDisappear { hideTabBar?.wrappedValue = false }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Eşleşme")
                        .font(ABFont.display(30))
                        .foregroundStyle(ABColor.ink)
                    Text(subtitle)
                        .font(ABFont.body(13))
                        .foregroundStyle(ABColor.inkMuted)
                }
                Spacer()
                Button {
                    model.showPrefs = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(ABColor.ink)
                        .frame(width: 42, height: 42)
                        .crystalPlate(cornerRadius: 14)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)

            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                Text("Bugün \(model.remainingReveals)/\(DailyRevealQuotaStore.dailyLimit)")
                    .font(ABFont.body(13, weight: .semibold))
            }
            .foregroundStyle(ABColor.lavenderSoft)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .crystalPlate(cornerRadius: 16)
        }
        .padding(.top, 16)
    }

    private var subtitle: String {
        switch model.phase {
        case .idle: return model.isLoading ? "Adaylar yükleniyor…" : "Çarkı çevir veya sürükle"
        case .spinning: return "Yıldızlar hizalanıyor…"
        case .revealed: return "Altın: sen · Lavanta: eşleşme — kaydır ya da seç"
        }
    }

    private var bondPrefsStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bağ ayarı")
                .font(ABFont.body(12, weight: .semibold))
                .foregroundStyle(ABColor.inkMuted)
                .tracking(0.6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MatchIntent.allCases) { intent in
                        Button {
                            var next = model.prefs
                            next.intent = intent
                            model.prefs = next
                            MatchPrefsStore.shared.snapshot = next
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: intent.iconName)
                                    .font(.system(size: 11, weight: .semibold))
                                Text(intent.titleTR)
                                    .font(ABFont.body(13, weight: .semibold))
                            }
                            .foregroundStyle(model.prefs.intent == intent ? Color.white : ABColor.inkMuted)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background {
                                Capsule(style: .continuous)
                                    .fill(model.prefs.intent == intent ? ABColor.lavender.opacity(0.45) : Color.white.opacity(0.06))
                            }
                            .overlay(
                                Capsule(style: .continuous)
                                    .strokeBorder(
                                        model.prefs.intent == intent
                                            ? ABColor.lavenderSoft.opacity(0.7)
                                            : Color.white.opacity(0.12),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .crystalPlate(cornerRadius: 20)
    }

    private var todayStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bugünün kararları")
                .font(ABFont.body(12, weight: .semibold))
                .foregroundStyle(ABColor.inkMuted)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(model.todayDecisions) { rec in
                        VStack(spacing: 8) {
                            ZStack(alignment: .bottomTrailing) {
                                PersonAvatar(
                                    name: rec.displayName,
                                    photoURL: rec.photoURL,
                                    sunSign: rec.sunSign,
                                    unlocked: false,
                                    size: 52
                                )
                                Image(systemName: rec.accepted ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(rec.accepted ? Color(hex: "#A8D4B8") : Color(hex: "#D4A8A8"))
                                    .padding(4)
                                    .background(Circle().fill(Color.black.opacity(0.55)))
                                    .offset(x: 4, y: 4)
                            }
                            Text(rec.displayName.components(separatedBy: " ").first ?? rec.displayName)
                                .font(ABFont.body(11, weight: .medium))
                                .foregroundStyle(ABColor.inkMuted)
                                .lineLimit(1)
                                .frame(width: 64)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    @State private var dragOffset: CGSize = .zero

    private func matchCard(_ card: MatchCard) -> some View {
        VStack(spacing: 16) {
            Button {
                model.showDetail = true
            } label: {
                VStack(spacing: 12) {
                    PersonAvatar(
                        name: card.displayName,
                        photoURL: card.photoURL,
                        sunSign: card.sunSign,
                        unlocked: false,
                        size: 76
                    )

                    Text(card.displayName)
                        .font(ABFont.display(26))
                        .foregroundStyle(ABColor.ink)

                    HStack(spacing: 10) {
                        if card.age > 0 { Text("\(card.age)") }
                        if let sign = card.sunSign {
                            Text("\(sign.glyph) \(sign.labelTR)")
                        }
                        if let city = card.city, !city.isEmpty {
                            Text("· \(city)")
                        }
                    }
                    .font(ABFont.body(14, weight: .medium))
                    .foregroundStyle(ABColor.inkMuted)

                    if !card.bio.isEmpty {
                        Text(card.bio)
                            .font(ABFont.body(14))
                            .foregroundStyle(ABColor.ink.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }

                    Text("Bağ detayını gör")
                        .font(ABFont.body(13, weight: .semibold))
                        .foregroundStyle(ABColor.lavenderSoft)
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 28) {
                thumbButton(
                    system: "hand.thumbsdown.fill",
                    tint: Color(hex: "#D4A0A0"),
                    label: "Geç"
                ) {
                    if let id = session.user?.id {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            model.reject(myUserId: id)
                        }
                        dragOffset = .zero
                    }
                }

                thumbButton(
                    system: "hand.thumbsup.fill",
                    tint: Color(hex: "#A8D4B8"),
                    label: model.isOpeningChat ? "…" : "Kabul"
                ) {
                    Task {
                        if let id = session.user?.id {
                            await model.acceptAndChat(myUserId: id)
                        }
                        dragOffset = .zero
                    }
                }
                .disabled(model.isOpeningChat)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .crystalPlate(cornerRadius: 28)
        .overlay(alignment: .topLeading) {
            decisionStamp(text: "GEÇ", tint: Color(hex: "#D4A0A0"))
                .opacity(dragOffset.width < -24 ? min(1, Double(-dragOffset.width - 24) / 60) : 0)
                .padding(18)
        }
        .overlay(alignment: .topTrailing) {
            decisionStamp(text: "KABUL", tint: Color(hex: "#A8D4B8"))
                .opacity(dragOffset.width > 24 ? min(1, Double(dragOffset.width - 24) / 60) : 0)
                .padding(18)
        }
        .offset(x: dragOffset.width)
        .rotationEffect(.degrees(Double(dragOffset.width / 18)))
        .gesture(
            DragGesture()
                .onChanged { value in
                    guard !model.isOpeningChat else { return }
                    dragOffset = value.translation
                }
                .onEnded { value in
                    guard !model.isOpeningChat else { return }
                    if value.translation.width > 110 {
                        Task {
                            if let id = session.user?.id {
                                await model.acceptAndChat(myUserId: id)
                            }
                            dragOffset = .zero
                        }
                    } else if value.translation.width < -110 {
                        if let id = session.user?.id {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                model.reject(myUserId: id)
                            }
                        }
                        dragOffset = .zero
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            dragOffset = .zero
                        }
                    }
                }
        )
        .animation(.interactiveSpring(), value: dragOffset)
    }

    private func decisionStamp(text: String, tint: Color) -> some View {
        Text(text)
            .font(ABFont.body(13, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(tint, lineWidth: 1.6)
            )
            .rotationEffect(.degrees(text == "GEÇ" ? -12 : 12))
    }

    private func thumbButton(system: String, tint: Color, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: system)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 72, height: 72)
                    .background {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                    }
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [tint.opacity(0.7), Color.white.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(color: tint.opacity(0.35), radius: 12, y: 4)

                Text(label)
                    .font(ABFont.body(12, weight: .semibold))
                    .foregroundStyle(ABColor.inkMuted)
            }
        }
        .buttonStyle(.plain)
    }
}

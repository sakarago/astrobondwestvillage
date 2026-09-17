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
    var myMoon: ZodiacSign?
    var myRising: ZodiacSign?
    var openingRecordId: String?

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
            myMoon = snap.moonSign
            myRising = snap.risingSign
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
            // Clear the reveal *before* navigating — otherwise this card (and
            // its thumbs) was still sitting there, fully decided, whenever you
            // came back from Chat, since nothing ever reset `active`/`phase`.
            self.active = nil
            phase = .idle
            openChat = conversation
            // Instant inbox update — the Messages tab view stays mounted in
            // the background (see MainTabView), so it won't re-run its own
            // load on its own; push the result to the shared store instead.
            ConversationsStore.shared.upsert(conversation)
        } catch {
            message = error.localizedDescription
        }
    }

    /// Tapping a face in "Bugünün kararları" used to do nothing at all. If it
    /// was an accept, it's an actual match — take them straight to that chat
    /// (creating the conversation if it somehow doesn't exist yet). If it was
    /// a pass, there's no conversation to open, so say so instead of just
    /// silently eating the tap.
    func openChat(for record: MatchDecisionsStore.Record) async {
        guard record.accepted else {
            message = "\(record.displayName) kişisini geçtin — mesajlaşma yok."
            return
        }
        guard openingRecordId == nil else { return }
        openingRecordId = record.id
        message = nil
        defer { openingRecordId = nil }
        do {
            let conversation = try await messaging.getOrCreateConversation(otherUserId: record.id)
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
    @State private var model = MatchViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // This screen was missing its own backdrop entirely — every
                // other tab wraps its content in `CosmicBackdrop()` *inside*
                // its NavigationStack, but this one relied on MainTabView's
                // background showing through, which a NavigationStack does
                // NOT reliably let happen. That's why "Eşleşme" and the wheel
                // read as washed-out/invisible. Add the same backdrop, plus a
                // touch of extra darkening at the very top since the wheel's
                // own glow can otherwise wash out the header sitting above it.
                CosmicBackdrop()
                LinearGradient(
                    colors: [Color.black.opacity(0.24), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 220)
                .frame(maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea(edges: .top)

                matchScroll
            }
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
                        mySeed: session.user?.id ?? "self",
                        mySun: model.mySun,
                        myMoon: model.myMoon,
                        myRising: model.myRising,
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

    private var matchScroll: some View {
        ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header

                    if let note = dailyNote {
                        dailyNoteCard(note)
                            .padding(.horizontal, 20)
                    }

                    CosmicMatchWheel(
                        rotation: model.wheelRotation,
                        isSpinning: model.phase == .spinning,
                        size: 300,
                        mySeed: session.user?.id ?? "self",
                        theirSeed: model.phase == .revealed ? model.active?.id : nil,
                        mySun: model.mySun,
                        myMoon: model.myMoon,
                        myRising: model.myRising
                    ) {
                        // While a match is revealed the wheel IS the synastry
                        // chart — double-tapping it should open the written
                        // summary of that chart, not spin away the match you
                        // just got (which is what silently happened before:
                        // spin() would restart and swap out `active`).
                        if model.phase == .revealed {
                            model.showDetail = true
                        } else {
                            model.spin()
                        }
                    }
                    .zIndex(0)

                    if model.phase == .revealed, let active = model.active {
                        synastryLegend(active)
                            .transition(.opacity)
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

                    Spacer(minLength: 120)
                }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: model.phase)
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Eşleşme")
                        .font(ABFont.display(30))
                        .foregroundStyle(ABColor.ink)
                        .shadow(color: .black.opacity(0.55), radius: 8, y: 2)
                    Text(subtitle)
                        .font(ABFont.body(13))
                        .foregroundStyle(ABColor.inkMuted)
                        .shadow(color: .black.opacity(0.5), radius: 6, y: 1)
                }
                Spacer()
                Button {
                    model.showPrefs = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(ABColor.ink)
                        .crystalIconBezel(size: 42, cornerRadius: 14)
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
        case .idle: return model.isLoading ? "Adaylar yükleniyor…" : "Çevirmek için çarka çift dokun"
        case .spinning: return "Yıldızlar hizalanıyor…"
        case .revealed: return "Senkron haritası hazır — detay için çarka çift dokun"
        }
    }

    /// Makes the "the wheel just became a two-person chart" moment explicit —
    /// the wheel's own gold/lavender belts can be subtle at a glance, so spell
    /// it out with named, colored swatches right underneath it. Also doubles
    /// as an obvious, single-tap way into the bond summary, since the
    /// double-tap-the-wheel gesture alone isn't very discoverable.
    private func synastryLegend(_ card: MatchCard) -> some View {
        Button {
            model.showDetail = true
        } label: {
            HStack(spacing: 14) {
                legendDot(color: Color(hex: "#F0CE7E"), label: "Sen")
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ABColor.inkMuted)
                legendDot(color: Color(hex: "#C9B8FF"), label: card.displayName)
                Divider().frame(height: 14).overlay(Color.white.opacity(0.15))
                Text("Bağ özeti")
                    .font(ABFont.body(12, weight: .semibold))
                    .foregroundStyle(ABColor.lavenderSoft)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(ABColor.lavenderSoft)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .crystalPlate(cornerRadius: 16)
        }
        .buttonStyle(.plain)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 9, height: 9)
                .shadow(color: color.opacity(0.7), radius: 4)
            Text(label)
                .font(ABFont.body(12, weight: .semibold))
                .foregroundStyle(ABColor.ink)
                .lineLimit(1)
        }
    }

    /// The "Günlük İçgörü" (Daily Insight) notification toggle in Settings
    /// has had nothing behind it — no actual daily note ever existed here.
    /// This brings that back: a short, personalized note recomputed once a
    /// day from your real sun/moon/rising, so it's unique to your chart and
    /// to you specifically (not just "everyone with this sun sign").
    private var dailyNote: DailyNote? {
        guard let uid = session.user?.id, model.mySun != nil else { return nil }
        return DailyNoteEngine.note(for: Date(), userId: uid, sun: model.mySun, moon: model.myMoon, rising: model.myRising)
    }

    private func dailyNoteCard(_ note: DailyNote) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BUGÜNÜN NOTU")
                        .font(ABFont.body(11, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(ABColor.lavenderSoft)
                    Text(note.dateLabel)
                        .font(ABFont.body(11))
                        .foregroundStyle(ABColor.inkMuted)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill").font(.system(size: 10, weight: .bold))
                    Text("\(note.energyScore)")
                        .font(ABFont.body(12, weight: .bold))
                }
                .foregroundStyle(Color(hex: "#F0CE7E"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.08)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 1))
            }

            Text(note.headline)
                .font(ABFont.display(17))
                .foregroundStyle(ABColor.ink)

            Text(note.body)
                .font(ABFont.body(13.5))
                .foregroundStyle(ABColor.ink.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                noteTag("✦ \(note.focus)")
                noteTag("🎨 \(note.luckyHue)")
            }
        }
        .padding(16)
        .crystalPlate(cornerRadius: 22)
    }

    private func noteTag(_ text: String) -> some View {
        Text(text)
            .font(ABFont.body(11, weight: .semibold))
            .foregroundStyle(ABColor.lavenderSoft)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.06)))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
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
                        Button {
                            Task { await model.openChat(for: rec) }
                        } label: {
                            VStack(spacing: 8) {
                                ZStack(alignment: .bottomTrailing) {
                                    PersonAvatar(
                                        name: rec.displayName,
                                        photoURL: rec.photoURL,
                                        sunSign: rec.sunSign,
                                        unlocked: false,
                                        size: 52
                                    )
                                    .opacity(rec.accepted ? 1 : 0.55)
                                    .overlay {
                                        if model.openingRecordId == rec.id {
                                            Circle().fill(Color.black.opacity(0.45))
                                            ProgressView().tint(.white)
                                        }
                                    }

                                    Image(systemName: rec.accepted ? "message.fill" : "hand.thumbsdown.fill")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(rec.accepted ? Color(hex: "#A8D4B8") : Color(hex: "#D4A8A8"))
                                        .padding(4)
                                        .background(Circle().fill(Color.black.opacity(0.55)))
                                        .offset(x: 4, y: 4)
                                }
                                Text(rec.displayName.components(separatedBy: " ").first ?? rec.displayName)
                                    .font(ABFont.body(11, weight: .medium))
                                    .foregroundStyle(rec.accepted ? ABColor.ink : ABColor.inkMuted)
                                    .lineLimit(1)
                                    .frame(width: 64)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(model.openingRecordId != nil)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func matchCard(_ card: MatchCard) -> some View {
        VStack(spacing: 18) {
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

            // Solid, opaque pills (not glass-on-glass) so they never wash out
            // against the card behind them, and no gesture is attached to the
            // card above them anymore — nothing can steal or block their taps.
            HStack(spacing: 28) {
                thumbButton(
                    system: "hand.thumbsdown.fill",
                    tint: Color(hex: "#E8A0A0"),
                    label: "Geç"
                ) {
                    if let id = session.user?.id {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            model.reject(myUserId: id)
                        }
                    }
                }

                thumbButton(
                    system: "hand.thumbsup.fill",
                    tint: Color(hex: "#A0E8B8"),
                    label: model.isOpeningChat ? "…" : "Kabul"
                ) {
                    Task {
                        if let id = session.user?.id {
                            await model.acceptAndChat(myUserId: id)
                        }
                    }
                }
                .disabled(model.isOpeningChat)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .crystalPlate(cornerRadius: 28)
        .zIndex(5)
    }

    private func thumbButton(system: String, tint: Color, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: system)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color(hex: "#15131F"))
                    .frame(width: 72, height: 72)
                    .background {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [tint, tint.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay(
                        Circle().strokeBorder(Color.white.opacity(0.6), lineWidth: 1.2)
                    )
                    .shadow(color: tint.opacity(0.55), radius: 14, y: 6)
                    .shadow(color: Color.black.opacity(0.35), radius: 8, y: 4)

                Text(label)
                    .font(ABFont.body(12, weight: .semibold))
                    .foregroundStyle(ABColor.ink)
            }
        }
        .buttonStyle(.plain)
    }
}

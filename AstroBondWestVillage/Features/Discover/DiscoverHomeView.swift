import SwiftUI

enum DiscoverRoute: Hashable {
    case tarot, daily, events, allSigns, love, guide, more
    case event(String)
    case signs(ZodiacSign?)
    case note(DiscoverNote)
}

/// "Keşfet" — 01 Ana Sayfa. Every box leads to a page written from the signed-in user's own chart.
struct DiscoverHomeView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.activeTab) private var activeTab

    @State private var sky = UserSky()
    @State private var path: [DiscoverRoute] = []

    private let profiles = ProfileService()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                DT.cream.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        hero
                        VStack(alignment: .leading, spacing: 22) {
                            messageCard
                            eventsSection
                            signsSection
                            topicCards
                            moreSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .padding(.bottom, 130)
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: DiscoverRoute.self) { route in destination(route) }
        }
        .task {
            await loadSky()
        }
        .onChange(of: activeTab?.wrappedValue) { _, tab in
            if tab == 0 { Task { await loadSky() } } else { path = [] }
        }
    }

    // MARK: Routing

    @ViewBuilder
    private func destination(_ route: DiscoverRoute) -> some View {
        switch route {
        case .tarot: TarotFlowView(sky: sky)
        case .daily: NoteDetailPage(note: DiscoverContent.dailyReading(sky).backed(.image("discover_hero")), sky: sky)
        case .events: EventsListView(sky: sky)
        case .event(let id):
            if let e = DiscoverContent.upcomingEvents(limit: 30).first(where: { $0.id == id }) {
                EventDetailView(event: e, sky: sky)
            }
        case .signs(let s): SignsView(sky: sky, initial: s)
        case .allSigns: AllSignsView(sky: sky)
        case .love:
            TopicListView(title: "Aşk ve İlişki\nAstrolojisi", subtitle: "Yıldızlar, kalbinin dilini biliyor.", chips: nil, topics: DiscoverContent.loveTopics(sky), backdrop: .image("discover_love"))
        case .guide:
            TopicListView(title: "Astroloji\nRehberi", subtitle: "Öğren, keşfet, derinleş.", chips: ["Tümü", "Gezegenler", "Evler", "Burçlar"], topics: DiscoverContent.guideTopics(sky), backdrop: .image("discover_guide"))
        case .more: MoreView(sky: sky)
        case .note(let n): NoteDetailPage(note: n, sky: sky)
        }
    }

    // MARK: Data

    private func loadSky() async {
        guard let id = session.user?.id else { return }
        if sky.userId != id { sky.userId = id }
        if let snap = try? await profiles.fetchSnapshot(userId: id) {
            sky.name = snap.displayName
            sky.sun = snap.sunSign
            sky.moon = snap.moonSign
            sky.rising = snap.risingSign
        }
        if let chart = try? await ChartService.shared.ensureOwnChart(userId: id) {
            sky.sun = chart.sunSign
            sky.moon = chart.moonSign
            sky.rising = chart.risingSign
            sky.venus = chart.venusPosition?.sign
            sky.mars = chart.marsPosition?.sign
            sky.mercury = chart.planet(.mercury)?.sign
            sky.dominantElement = chart.dominantElement
        }
    }

    // MARK: Sections

    private let ink = DT.ink
    private let inkSoft = DT.inkSoft
    private let cream = DT.cream

    private var hero: some View {
        ZStack(alignment: .top) {
            Color.clear
                .frame(height: 360)
                .overlay { Image("discover_hero").resizable().scaledToFill() }
                .clipped()
                .overlay(LinearGradient(colors: [.black.opacity(0.35), .clear, cream.opacity(0.0), cream], startPoint: .top, endPoint: .bottom))

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Keşfet").font(ABFont.display(38, weight: .regular)).foregroundStyle(.white)
                        Text("GÖKYÜZÜNÜN HİKÂYESİ").font(ABFont.body(11, weight: .medium)).tracking(2.6).foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer()
                    Image(systemName: "sparkle").font(.system(size: 20, weight: .light)).foregroundStyle(.white).padding(.top, 10)
                }
                .padding(.top, 64)

                VStack(alignment: .leading, spacing: 10) {
                    Text("GÖKYÜZÜNDE BUGÜN").font(ABFont.body(10.5, weight: .medium)).tracking(2).foregroundStyle(.white.opacity(0.75))
                    Text("Bugünün enerjisi\nsana ne söylüyor?").font(ABFont.display(26, weight: .regular)).foregroundStyle(.white).lineSpacing(2)
                    Text(DiscoverContent.heroSubtitle(sky)).font(ABFont.body(13.5)).foregroundStyle(.white.opacity(0.88)).lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                    Button { path.append(.daily) } label: {
                        HStack(spacing: 8) { Text("Günün yorumunu oku"); Image(systemName: "arrow.right") }
                            .font(ABFont.body(14, weight: .semibold)).foregroundStyle(.white)
                            .padding(.horizontal, 20).padding(.vertical, 12)
                            .background(Capsule().fill(Color(hex: "#7A5A4A").opacity(0.55)))
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 1))
                    }
                    .buttonStyle(.plain).padding(.top, 4)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(LinearGradient(colors: [Color.black.opacity(0.55), Color.black.opacity(0.28)], startPoint: .leading, endPoint: .trailing)))
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(Color.white.opacity(0.28), lineWidth: 1))
                .padding(.top, 22)
            }
            .padding(.horizontal, 16)
        }
    }

    private var messageCard: some View {
        ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: "#FBEEE3"), Color(hex: "#F1D3BE")], startPoint: .leading, endPoint: .trailing))
            Color.clear
                .overlay(alignment: .trailing) {
                    Image("discover_tarot").resizable().scaledToFill()
                        .frame(width: 190, height: 190)
                        .mask(LinearGradient(colors: [.clear, .black, .black], startPoint: .leading, endPoint: .init(x: 0.3, y: 0.5)))
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            VStack(alignment: .leading, spacing: 8) {
                Text("GÜNÜN MESAJI").font(ABFont.body(10, weight: .semibold)).tracking(2).foregroundStyle(inkSoft)
                Text("Evrenin sana özel bir mesajı var.").font(ABFont.display(19, weight: .semibold)).foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(sky.firstName.isEmpty ? "3 kartan birini seç, mesajını keşfet." : "\(sky.firstName), 3 kartan birini seç, mesajını keşfet.")
                    .font(ABFont.body(12.5)).foregroundStyle(inkSoft).fixedSize(horizontal: false, vertical: true)
                Button { path.append(.tarot) } label: {
                    HStack(spacing: 6) { Text("Kartını Seç"); Image(systemName: "arrow.right") }
                        .font(ABFont.body(13, weight: .semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Capsule().fill(Color(hex: "#3A2E3F")))
                }
                .buttonStyle(.plain).padding(.top, 2)
            }
            .padding(18)
            .frame(width: 200, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 190)
        .shadow(color: Color(hex: "#C79A80").opacity(0.25), radius: 14, y: 8)
    }

    private var eventsSection: some View {
        let events = Array(DiscoverContent.upcomingEvents().prefix(5))
        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader("YAKLAŞAN GÖKYÜZÜ OLAYLARI") { path.append(.events) }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(events) { e in
                        Button { path.append(.event(e.id)) } label: { eventCard(e) }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, -16)
        }
    }

    private func eventCard(_ e: SkyEvent) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            EventOrb(kind: e.kind, size: 52).frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text(e.title).font(ABFont.display(14.5, weight: .medium)).foregroundStyle(.white)
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                Text(e.dateText).font(ABFont.body(10.5, weight: .medium)).foregroundStyle(Color(hex: "#F1C9A0"))
                Text(DiscoverContent.eventPersonalLine(e, sky)).font(ABFont.body(10.5)).foregroundStyle(.white.opacity(0.68))
                    .lineLimit(3).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(width: 150, height: 176, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: "#1C1530"), Color(hex: "#0F0B1D")], startPoint: .top, endPoint: .bottom)))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }

    private var signsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("GÜNLÜK BURÇ YORUMLARI") { path.append(.allSigns) }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ZodiacSign.allCases, id: \.self) { sign in
                        let mine = sign == sky.sun
                        Button { path.append(.signs(sign)) } label: {
                            VStack(spacing: 6) {
                                Text(sign.glyph).font(.system(size: 24)).foregroundStyle(elementTint(sign))
                                    .frame(width: 58, height: 58)
                                    .background(Circle().fill(Color.white.opacity(mine ? 0.95 : 0.55)))
                                    .overlay(Circle().strokeBorder(mine ? Color(hex: "#D9A25F") : Color(hex: "#E2C9BC"), lineWidth: mine ? 2 : 1))
                                    .shadow(color: mine ? Color(hex: "#D9A25F").opacity(0.5) : .clear, radius: 8)
                                Text(sign.labelTR).font(ABFont.body(11.5, weight: mine ? .bold : .medium)).foregroundStyle(ink)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, -16)
        }
    }

    private func elementTint(_ s: ZodiacSign) -> Color {
        switch s.element {
        case .fire: return Color(hex: "#C25A3A")
        case .earth: return Color(hex: "#6B7F4A")
        case .air: return Color(hex: "#7A62B5")
        case .water: return Color(hex: "#3F78A8")
        }
    }

    private var topicCards: some View {
        HStack(spacing: 12) {
            topicCard(image: "discover_love", title: "Aşk ve İlişki\nAstrolojisi", subtitle: "Yıldızlar, kalbinin\ndilini biliyor.") { path.append(.love) }
            topicCard(image: "discover_guide", title: "Astroloji Rehberi", subtitle: "Öğren, keşfet,\nderinleş.") { path.append(.guide) }
        }
    }

    private func topicCard(image: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                Color.clear.overlay { Image(image).resizable().scaledToFill() }.clipped()
                LinearGradient(colors: [.black.opacity(0.1), .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(ABFont.display(17, weight: .medium)).foregroundStyle(.white).fixedSize(horizontal: false, vertical: true)
                    Text(subtitle).font(ABFont.body(11)).foregroundStyle(.white.opacity(0.8))
                    HStack(spacing: 5) { Text("Keşfet"); Image(systemName: "arrow.right") }
                        .font(ABFont.body(12, weight: .semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.7), lineWidth: 1)).padding(.top, 2)
                }
                .padding(12)
            }
            .frame(maxWidth: .infinity).frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var moreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("KEŞFET – EK İÇERİKLER") { path.append(.more) }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    extra("Haftalık\nGökyüzü Gündemi", icon: "calendar", colors: ["#2A2F6B", "#0F1235"], note: DiscoverContent.weeklyNote(sky))
                    extra("Yeni Başlayanlar\nİçin Astroloji", icon: "leaf", colors: ["#C99A6B", "#8E6446"], note: DiscoverContent.beginnerNote(sky))
                    extra("Ritüeller\nve Öneriler", icon: "flame", colors: ["#5A2A2E", "#1D0D12"], note: DiscoverContent.ritualNote(sky))
                }
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, -16)
        }
    }

    private func extra(_ title: String, icon: String, colors: [String], note: DiscoverNote) -> some View {
        Button { path.append(.note(note.backed(.gradient(colors, icon: icon)))) } label: {
            VStack(alignment: .leading) {
                Image(systemName: icon).font(.system(size: 18)).foregroundStyle(Color(hex: "#FFE3B0"))
                Spacer()
                Text(title).font(ABFont.display(14.5, weight: .medium)).foregroundStyle(.white)
                    .lineLimit(2).minimumScaleFactor(0.85).multilineTextAlignment(.leading)
            }
            .padding(14)
            .frame(width: 176, height: 104, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: colors.map { Color(hex: $0) }, startPoint: .topLeading, endPoint: .bottomTrailing)))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(_ title: String, seeAll: @escaping () -> Void) -> some View {
        HStack {
            Text(title).font(ABFont.body(11.5, weight: .semibold)).tracking(1.8).foregroundStyle(ink)
            Spacer()
            Button("Tümünü Gör", action: seeAll).font(ABFont.body(11.5, weight: .medium)).foregroundStyle(inkSoft)
        }
    }
}

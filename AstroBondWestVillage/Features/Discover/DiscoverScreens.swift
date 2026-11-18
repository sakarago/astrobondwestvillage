import SwiftUI

private struct CircleIconButtonStyle {
    static func label(_ system: String, _ th: Th) -> some View {
        Image(systemName: system).font(.system(size: 15, weight: .semibold)).foregroundStyle(th.primary)
            .frame(width: 36, height: 36).background(Circle().fill(th.chipOff))
            .overlay(Circle().strokeBorder(th.cardStroke, lineWidth: 1))
    }
}

/// Small status line shown while the on-device model writes, and after it did.
private struct AIStatusLine: View {
    enum State { case idle, loading, done }
    let state: State
    let th: Th
    var body: some View {
        switch state {
        case .idle: EmptyView()
        case .loading:
            HStack(spacing: 6) {
                ProgressView().controlSize(.mini).tint(th.accent)
                Text("Gökyüzü senin için yazıyor…").font(ABFont.body(11.5)).foregroundStyle(th.secondary)
            }
        case .done:
            HStack(spacing: 5) {
                Image(systemName: "sparkle").font(.system(size: 10))
                Text("Yapay zekâ ile sana özel yazıldı").font(ABFont.body(11.5))
            }
            .foregroundStyle(th.accent.opacity(0.9))
        }
    }
}

// MARK: - 02 / 03 / 04  Günün Mesajı (card pick → opening → result)

struct TarotFlowView: View {
    let sky: UserSky
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    private var th: Th { Th(light: false) }
    private var lav: Color { Color.adaptive(light: "#6C56D6", dark: "#C9B6FF") }

    private enum Stage { case pick, opening, result }
    @State private var stage: Stage = .pick
    @State private var picked = 0
    @State private var spin = 0.0
    @State private var pulse = false
    @State private var aiResult: DiscoverContent.CardResult?
    @State private var aiState: AIStatusLine.State = .idle
    @State private var showReflect = false
    @State private var hasNote = false

    private let allEmblems: [VioletTarotCard.Emblem] = [.crescent, .sun, .star]

    private var storageKey: String {
        let c = Calendar.current
        return "dailyCard.\(sky.userId).\(c.component(.year, from: Date())).\(c.ordinality(of: .day, in: .year, for: Date()) ?? 0)"
    }

    var body: some View {
        ZStack {
            ScreenBackdropView(backdrop: .violet)
            switch stage {
            case .pick: pickStage.transition(.opacity)
            case .opening: openingStage.transition(.opacity)
            case .result: resultStage.transition(.opacity)
            }
        }
        .environment(\.th, th)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showReflect, onDismiss: {
            hasNote = !(UserDefaults.standard.string(forKey: storageKey + ".note") ?? "").isEmpty
        }) {
            let r = aiResult ?? DiscoverContent.cardResult(sky, card: picked)
            ReflectionSheet(question: r.question, key: storageKey + ".note")
        }
        .onAppear {
            hasNote = !(UserDefaults.standard.string(forKey: storageKey + ".note") ?? "").isEmpty
        }
    }

    // 02 — pick (shuffle, then choose)
    private var pickStage: some View {
        VStack(spacing: 14) {
            topBar(share: nil)
            Spacer().frame(height: 14)
            Text("Günün Mesajı").font(ABFont.display(38, weight: .regular)).foregroundStyle(th.primary)
            Capsule().fill(th.primary.opacity(0.5)).frame(width: 38, height: 1.5)
            Text("Evren, bugün sana ne söylüyor?\nİçinden geçenle uyumlanan kartı seç.")
                .font(ABFont.body(14)).multilineTextAlignment(.center).foregroundStyle(th.primary.opacity(0.78)).lineSpacing(3)
                .padding(.top, 4).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            // Disk tipped 90°: surface faces up. Cards stay face-on and swell as they come forward.
            GeometryReader { geo in
                let cardW: CGFloat = 112
                let orbitW: CGFloat = 92
                let orbitH = orbitW * 1.66
                let tilt: CGFloat = 0.46
                let radiusX = max(
                    86,
                    min(
                        (geo.size.width - orbitW * 1.16) / 2,
                        (geo.size.height - orbitH * 0.9) / (2 * tilt)
                    )
                )
                let radiusZ = radiusX * tilt
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    let turns = timeline.date.timeIntervalSinceReferenceDate / 4.5
                    let angle = turns.truncatingRemainder(dividingBy: 1) * 360
                    ZStack {
                        orbitSky(time: timeline.date.timeIntervalSinceReferenceDate, size: geo.size)

                        ForEach(0..<3, id: \.self) { contentId in
                            let rad = (angle + Double(contentId) * 120) * .pi / 180
                            let depth = cos(rad)
                            let near = (depth + 1) / 2
                            Button {
                                choose(contentId)
                            } label: {
                                VioletTarotCard(
                                    emblem: allEmblems[contentId],
                                    width: cardW,
                                    glow: near > 0.72
                                )
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(CGFloat(0.66 + 0.52 * near))
                            .opacity(0.55 + 0.45 * near)
                            .offset(x: CGFloat(sin(rad)) * radiusX, y: CGFloat(depth) * radiusZ)
                            .zIndex(10 + depth)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .frame(height: 400)
            Spacer(minLength: 0)
            Text("Kartlar yaklaşıp uzaklaşır.\nSeni çağırana dokun.")
                .font(ABFont.body(13.5, weight: .medium)).foregroundStyle(th.primary)
                .multilineTextAlignment(.center).lineSpacing(3)
                .frame(maxWidth: .infinity).padding(.vertical, 13)
                .background(Capsule().fill(Color.white.opacity(0.07)))
                .overlay(Capsule().strokeBorder(lav.opacity(0.45), lineWidth: 1))
                .padding(.horizontal, 6)
            Spacer().frame(height: 112)
        }
        .padding(.horizontal, 20)
    }

    /// Fixed scatter so the night sky doesn't jump between frames. Fractions of the orbit frame.
    private static let skyStars: [(x: CGFloat, y: CGFloat, phase: Double)] = [
        (0.06, 0.10, 0.2), (0.16, 0.22, 1.7), (0.28, 0.08, 2.4), (0.41, 0.16, 0.6),
        (0.57, 0.07, 3.1), (0.72, 0.14, 1.1), (0.86, 0.09, 2.2), (0.94, 0.24, 0.4),
        (0.08, 0.40, 2.8), (0.93, 0.46, 1.5), (0.04, 0.62, 0.9), (0.18, 0.78, 3.4),
        (0.33, 0.90, 1.9), (0.52, 0.86, 0.3), (0.68, 0.92, 2.6), (0.84, 0.74, 1.3),
        (0.95, 0.66, 3.6), (0.12, 0.54, 2.0), (0.78, 0.34, 0.8), (0.62, 0.28, 3.8),
        (0.48, 0.38, 1.6), (0.36, 0.58, 2.9)
    ]

    private static let skyFlashes: [(x: CGFloat, y: CGFloat, phase: Double)] = [
        (0.22, 0.18, 0.4), (0.74, 0.22, 1.8), (0.14, 0.72, 2.7),
        (0.84, 0.68, 0.9), (0.50, 0.12, 3.3)
    ]

    /// Distant stars, brief flares, and a few far planets. Drawn behind the cards.
    private func orbitSky(time: TimeInterval, size: CGSize) -> some View {
        ZStack {
            ForEach(Array(Self.skyStars.enumerated()), id: \.offset) { index, star in
                let twinkle = 0.5 + 0.5 * sin(time * (index % 3 == 0 ? 2.8 : 1.3) + star.phase)
                let bright = index % 5 == 0
                Group {
                    if index % 4 == 0 {
                        Image(systemName: "sparkle")
                            .font(.system(size: bright ? 11 : 7, weight: .light))
                            .foregroundStyle(bright ? Color.white : lav)
                    } else {
                        Circle()
                            .fill(index % 3 == 0 ? Color.white : lav.opacity(0.9))
                            .frame(width: bright ? 3.2 : 1.8, height: bright ? 3.2 : 1.8)
                    }
                }
                .shadow(color: (bright ? Color.white : lav).opacity(0.8), radius: bright ? 4 : 1)
                .opacity(0.2 + 0.8 * twinkle)
                .scaleEffect(bright ? 0.85 + twinkle * 0.45 : 1.0)
                .position(x: star.x * size.width, y: star.y * size.height)
            }

            ForEach(Array(Self.skyFlashes.enumerated()), id: \.offset) { _, flash in
                let burst = pow(max(0, sin(time * 1.6 + flash.phase)), 14)
                Image(systemName: "sparkles")
                    .font(.system(size: 8 + burst * 16, weight: .light))
                    .foregroundStyle(Color.white)
                    .shadow(color: lav.opacity(0.95), radius: 8)
                    .opacity(0.05 + burst)
                    .position(x: flash.x * size.width, y: flash.y * size.height)
            }

            distantPlanet(
                color: Color(hex: "#F0CE7E"),
                diameter: 16,
                ring: true,
                x: 0.10 * size.width + CGFloat(sin(time * 0.18)) * 7,
                y: 0.30 * size.height + CGFloat(cos(time * 0.15)) * 5
            )
            distantPlanet(
                color: Color(hex: "#E8B9A0"),
                diameter: 11,
                ring: false,
                x: 0.88 * size.width + CGFloat(cos(time * 0.14)) * 6,
                y: 0.20 * size.height + CGFloat(sin(time * 0.12)) * 5
            )
            distantPlanet(
                color: Color(hex: "#9BB7FF"),
                diameter: 8,
                ring: false,
                x: 0.82 * size.width + CGFloat(sin(time * 0.11 + 1)) * 8,
                y: 0.82 * size.height + CGFloat(cos(time * 0.1)) * 4
            )
            distantPlanet(
                color: Color(hex: "#C9B6FF"),
                diameter: 13,
                ring: true,
                x: 0.16 * size.width + CGFloat(cos(time * 0.09)) * 5,
                y: 0.86 * size.height + CGFloat(sin(time * 0.13)) * 4
            )
        }
        .allowsHitTesting(false)
    }

    private func distantPlanet(color: Color, diameter: CGFloat, ring: Bool, x: CGFloat, y: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [color.opacity(0.55), .clear], center: .center, startRadius: 0, endRadius: diameter))
                .frame(width: diameter * 2.4, height: diameter * 2.4)
            if ring {
                Ellipse()
                    .strokeBorder(color.opacity(0.75), lineWidth: 1)
                    .frame(width: diameter * 1.9, height: diameter * 0.55)
                    .rotationEffect(.degrees(-18))
            }
            Circle()
                .fill(RadialGradient(colors: [color.opacity(0.95), color.opacity(0.45)], center: .init(x: 0.35, y: 0.35), startRadius: 0, endRadius: diameter * 0.7))
                .frame(width: diameter, height: diameter)
                .shadow(color: color.opacity(0.7), radius: 4)
        }
        .position(x: x, y: y)
    }

    private func choose(_ contentIndex: Int) {
        picked = contentIndex
        aiResult = nil
        UserDefaults.standard.set(contentIndex, forKey: storageKey)
        DailyMessageNotifier.scheduleDaily()
        withAnimation(.easeInOut(duration: 0.5)) { stage = .opening }
        withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) { spin = 360 }
        Task {
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            await MainActor.run { withAnimation(.easeInOut(duration: 0.6)) { stage = .result } }
        }
    }

    // 03 — opening animation
    private var openingStage: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                ForEach(0..<4, id: \.self) { i in
                    Circle().strokeBorder(lav.opacity(0.45 - Double(i) * 0.1), lineWidth: 1)
                        .frame(width: 240 + CGFloat(i) * 56, height: 240 + CGFloat(i) * 56)
                        .scaleEffect(pulse ? 1.05 : 0.96)
                }
                Circle().fill(RadialGradient(colors: [Color(hex: "#7B5CFF").opacity(0.55), .clear], center: .center, startRadius: 0, endRadius: 190))
                    .frame(width: 400, height: 400)
                ForEach(0..<8, id: \.self) { i in
                    Image(systemName: "sparkle").font(.system(size: 10)).foregroundStyle(lav)
                        .offset(y: -160).rotationEffect(.degrees(Double(i) * 45 + spin))
                }
                VioletTarotCard(emblem: allEmblems[picked], width: 160, glow: true)
                    .rotation3DEffect(.degrees(pulse ? 8 : -8), axis: (x: 0, y: 1, z: 0))
            }
            .frame(height: 420)
            Text("Mesajın seninle buluşuyor...").font(ABFont.display(22, weight: .regular)).foregroundStyle(th.primary)
            Text("Evrenin rehberliğinde.").font(ABFont.body(13)).foregroundStyle(th.primary.opacity(0.7))
            Spacer()
            Spacer().frame(height: 100)
        }
        .onAppear { withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { pulse.toggle() } }
    }

    // 04 — result
    private var resultStage: some View {
        let r = aiResult ?? DiscoverContent.cardResult(sky, card: picked)
        return ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                topBar(share: "\(r.title)\n\n\(r.body)\n\n— AstroBond")
                ZStack {
                    Circle().fill(RadialGradient(colors: [Color(hex: "#7B5CFF").opacity(0.5), .clear], center: .center, startRadius: 0, endRadius: 170))
                        .frame(width: 340, height: 340)
                    VioletTarotCard(emblem: allEmblems[picked], width: 140, glow: true)
                }
                .frame(height: 300)
                Text(r.title)
                    .font(ABFont.display(28, weight: .regular)).foregroundStyle(th.primary)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                Text(r.body)
                    .font(ABFont.body(14)).foregroundStyle(th.primary.opacity(0.78)).lineSpacing(4)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 8) {
                    Text("BUGÜN KENDİNE SOR").font(ABFont.body(10.5, weight: .semibold)).tracking(2).foregroundStyle(lav)
                    Button { showReflect = true } label: {
                        HStack {
                            Text(r.question).font(ABFont.body(14.5, weight: .medium)).foregroundStyle(th.primary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: hasNote ? "checkmark.circle.fill" : "chevron.right")
                                .foregroundStyle(hasNote ? lav : th.primary.opacity(0.5))
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white.opacity(0.07)))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(lav.opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 6)
                AIStatusLine(state: aiState, th: th)
                Button {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        stage = .pick
                        aiResult = nil
                    }
                } label: {
                    Text("Başka bir kart çek")
                        .font(ABFont.body(13.5, weight: .semibold))
                        .foregroundStyle(lav)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 130)
        }
        .task(id: stage == .result) {
            guard stage == .result, aiResult == nil else { return }
            aiState = DiscoverAI.isAvailable ? .loading : .idle
            let base = DiscoverContent.cardResult(sky, card: picked)
            let out = await DiscoverAI.cardResult(base, card: picked, sky: sky)
            if out.usedAI { withAnimation { aiResult = out.result } }
            aiState = out.usedAI ? .done : .idle
        }
    }

    private func topBar(share: String?) -> some View {
        HStack {
            Button { dismiss() } label: { CircleIconButtonStyle.label("chevron.left", th) }
            Spacer()
            if let share {
                ShareLink(item: share) { CircleIconButtonStyle.label("square.and.arrow.up", th) }
            }
        }
    }
}

// MARK: - 05  Yaklaşan Gökyüzü Olayları

struct EventsListView: View {
    let sky: UserSky
    @State private var filter = 0
    private let chips = ["Tümü", "Dolunay", "Yeni Ay", "Retro", "Diğer"]

    private func matches(_ e: SkyEvent) -> Bool {
        switch filter {
        case 1: return e.kind == .fullMoon
        case 2: return e.kind == .newMoon
        case 3: return e.kind == .retrograde
        case 4: return e.kind == .eclipse || e.kind == .solstice
        default: return true
        }
    }

    var body: some View {
        let events = DiscoverContent.upcomingEvents(limit: 20).filter(matches)
        DiscoverScreen(backdrop: .night, title: "Yaklaşan Gökyüzü\nOlayları", subtitle: "Yakın zamanda bizi neler bekliyor?") {
            PillChips(items: chips, selection: $filter)
            if events.isEmpty {
                Text("Bu kategoride yakın zamanda olay yok.").font(ABFont.body(13)).foregroundStyle(ABColor.inkMuted)
            }
            ForEach(events) { e in
                NavigationLink(value: DiscoverRoute.event(e.id)) {
                    DTRow(title: e.title, subtitle: DiscoverContent.eventPersonalLine(e, sky), caption: e.dateText) {
                        EventOrb(kind: e.kind, size: 44)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - 06  Olay detayı

struct EventDetailView: View {
    let event: SkyEvent
    let sky: UserSky
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    private var th: Th { Th(light: false) }
    @State private var aiNote: DiscoverNote?
    @State private var aiState: AIStatusLine.State = .idle

    private var label: String {
        switch event.kind {
        case .fullMoon: return "DOLUNAY"
        case .newMoon: return "YENİ AY"
        case .retrograde: return "RETRO"
        case .eclipse: return "TUTULMA"
        case .solstice: return "GÜNDÖNÜMÜ"
        }
    }

    var body: some View {
        let note = aiNote ?? DiscoverContent.eventNote(event, sky)
        ZStack {
            ScreenBackdropView(backdrop: .night)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    ZStack(alignment: .top) {
                        Color.clear.frame(height: 340)
                            .overlay { Image("discover_hero").resizable().scaledToFill() }
                            .clipped()
                            .mask(LinearGradient(colors: [.black, .black, .clear], startPoint: .top, endPoint: .bottom))
                        HStack {
                            Button { dismiss() } label: {
                                Image(systemName: "chevron.left").font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                                    .frame(width: 36, height: 36).background(Circle().fill(Color.black.opacity(0.35)))
                            }
                            Spacer()
                            ShareLink(item: "\(event.title) · \(event.dateText)\n\(event.blurb)") {
                                Image(systemName: "square.and.arrow.up").font(.system(size: 15)).foregroundStyle(.white)
                                    .frame(width: 36, height: 36).background(Circle().fill(Color.black.opacity(0.35)))
                            }
                        }
                        .padding(.horizontal, 20).padding(.top, 56)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text(label).font(ABFont.body(11, weight: .semibold)).tracking(2.4).foregroundStyle(th.accent)
                        Text(event.title).font(ABFont.display(36, weight: .regular)).foregroundStyle(th.primary)
                        Text(event.dateText).font(ABFont.body(14, weight: .medium)).foregroundStyle(th.light ? th.accent : DT.accentSoft)
                        Text(event.blurb).font(ABFont.body(14.5)).foregroundStyle(th.primary.opacity(0.8)).lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sana Etki").font(ABFont.display(20, weight: .medium)).foregroundStyle(th.primary)
                            AIStatusLine(state: aiState, th: th)
                            ForEach(note.sections) { s in
                                Text(s.text).font(ABFont.body(13.5)).foregroundStyle(th.primary.opacity(0.78)).lineSpacing(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(th.cardFill))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(th.cardStroke, lineWidth: 1))
                        NavigationLink(value: DiscoverRoute.note(DiscoverContent.eventSignEffects(event, sky))) {
                            HStack {
                                Text("Burçlara Göre Etkiler").font(ABFont.body(14.5, weight: .semibold))
                                Spacer(); Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(.white).padding(16)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(th.chipOn))
                            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DT.gold.opacity(0.5), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20).padding(.top, -70)
                }
                .padding(.bottom, 130)
            }
            .ignoresSafeArea(edges: .top)
        }
        .environment(\.th, th)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            aiState = DiscoverAI.isAvailable ? .loading : .idle
            let out = await DiscoverAI.enrich(DiscoverContent.eventNote(event, sky), sky: sky)
            if out.usedAI { withAnimation { aiNote = out.note } }
            aiState = out.usedAI ? .done : .idle
        }
    }
}

// MARK: - 07 / 08  Günlük burç yorumları

struct SignsView: View {
    let sky: UserSky
    @State private var selected: ZodiacSign
    @State private var aiRows: [SignDetailRow]?
    @State private var aiRelation: String?
    @State private var aiState: AIStatusLine.State = .idle
    private let th = Th(light: true)

    init(sky: UserSky, initial: ZodiacSign?) {
        self.sky = sky
        _selected = State(initialValue: initial ?? sky.sun ?? .aries)
    }

    var body: some View {
        let rows = aiRows ?? DiscoverContent.signRows(selected, sky)
        let dayDF: DateFormatter = { let d = DateFormatter(); d.locale = Locale(identifier: "tr_TR"); d.dateFormat = "EEEE"; return d }()
        DiscoverScreen(backdrop: .peach, title: "Günlük\nBurç Yorumları", subtitle: "Senin için bugün neler var?") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ZodiacSign.allCases, id: \.self) { s in
                        Button { withAnimation(.easeInOut(duration: 0.2)) { selected = s } } label: {
                            VStack(spacing: 5) {
                                Text(s.glyph).font(.system(size: 22)).foregroundStyle(selected == s ? Color.white : elementTint(s))
                                    .frame(width: 54, height: 54)
                                    .background(Circle().fill(selected == s ? th.chipOn : Color.white.opacity(0.6)))
                                    .overlay(Circle().strokeBorder(selected == s ? Color(hex: "#D9A25F") : Color(hex: "#E2C9BC"), lineWidth: selected == s ? 2 : 1))
                                    .shadow(color: selected == s ? Color(hex: "#D9A25F").opacity(0.5) : .clear, radius: 8)
                                Text(s.labelTR).font(ABFont.body(11.5, weight: selected == s ? .bold : .medium)).foregroundStyle(th.primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Text(selected.glyph).font(.system(size: 26)).foregroundStyle(elementTint(selected))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selected.labelTR).font(ABFont.display(22, weight: .medium)).foregroundStyle(th.primary)
                        Text("\(selected.dateRangeText), \(dayDF.string(from: Date()).capitalized(with: Locale(identifier: "tr_TR")))")
                            .font(ABFont.body(12)).foregroundStyle(th.secondary)
                    }
                }
                Text(aiRelation ?? DiscoverContent.signRelation(selected, sky))
                    .font(ABFont.body(12.5)).foregroundStyle(th.accent).lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                AIStatusLine(state: aiState, th: th)
                ForEach(rows) { r in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: r.icon).font(.system(size: 15)).foregroundStyle(th.accent).frame(width: 26)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(r.title).font(ABFont.body(13.5, weight: .semibold)).foregroundStyle(th.primary)
                            Text(r.text).font(ABFont.body(12.5)).foregroundStyle(th.secondary).lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Divider().overlay(Color.black.opacity(0.08))
                }
            }
            .padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(th.cardFill))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(th.cardStroke, lineWidth: 1))

            NavigationLink(value: DiscoverRoute.allSigns) {
                HStack { Text("Tüm Burçlar").font(ABFont.body(14, weight: .semibold)); Spacer(); Image(systemName: "chevron.right") }
                    .foregroundStyle(th.primary).padding(16)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(th.cardFill))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(th.cardStroke, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .task(id: selected) {
            aiRows = nil; aiRelation = nil
            aiState = DiscoverAI.isAvailable ? .loading : .idle
            let base = DiscoverContent.signRows(selected, sky)
            let pseudo = DiscoverNote(
                icon: "sparkle", eyebrow: "GÜNLÜK BURÇ YORUMU", title: selected.labelTR,
                intro: DiscoverContent.signRelation(selected, sky),
                sections: base.map { NoteSection(heading: $0.title, text: $0.text) }
            )
            let out = await DiscoverAI.enrich(pseudo, sky: sky)
            if out.usedAI {
                withAnimation {
                    aiRelation = out.note.intro
                    aiRows = zip(base, out.note.sections).map { SignDetailRow(icon: $0.icon, title: $0.title, text: $1.text) }
                }
            }
            aiState = out.usedAI ? .done : .idle
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
}

struct AllSignsView: View {
    let sky: UserSky
    var body: some View {
        DiscoverScreen(backdrop: .peach, title: "Tüm Burçlar", subtitle: "Bugünün enerjisini tüm burçlar için keşfet.") {
            ForEach(ZodiacSign.allCases, id: \.self) { s in
                NavigationLink(value: DiscoverRoute.signs(s)) {
                    DTRow(title: s.labelTR, subtitle: s.dateRangeText) {
                        Text(s.glyph).font(.system(size: 20)).foregroundStyle(DT.ink)
                            .frame(width: 40, height: 40).background(Circle().fill(Color.white.opacity(0.7)))
                            .overlay(Circle().strokeBorder(s == sky.sun ? Color(hex: "#D9A25F") : Color(hex: "#E2C9BC"), lineWidth: s == sky.sun ? 2 : 1))
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - 09 / 10  Topic lists (love, guide)

struct TopicListView: View {
    let title: String
    let subtitle: String
    let chips: [String]?
    let topics: [DiscoverTopic]
    let backdrop: ScreenBackdrop
    @State private var filter = 0

    var body: some View {
        let shown = (chips == nil || filter == 0) ? topics : topics.filter { $0.category == chips![filter] }
        DiscoverScreen(backdrop: backdrop, title: title, subtitle: subtitle) {
            if let chips { PillChips(items: chips, selection: $filter) }
            ForEach(shown) { t in
                NavigationLink(value: DiscoverRoute.note(t.note.backed(backdrop))) {
                    DTRow(title: t.title, subtitle: t.subtitle) { Orb(hex: t.tint, size: 46) }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - 11  Daha fazlasını keşfet

struct MoreView: View {
    let sky: UserSky
    var body: some View {
        DiscoverScreen(backdrop: .night, title: "Daha Fazlasını\nKeşfet", subtitle: "Astrolojiyle yolculuğa devam et.") {
            card("calendar", ["#2A2F6B", "#0F1235"], "Haftalık Gökyüzü Gündemi", "Bu hafta hangi enerjiler seninle?", DiscoverContent.weeklyNote(sky))
            card("leaf", ["#C99A6B", "#8E6446"], "Yeni Başlayanlar İçin Astroloji", "Temel kavramlarla başla.", DiscoverContent.beginnerNote(sky))
            card("flame", ["#5A2A2E", "#1D0D12"], "Ritüeller ve Öneriler", "Gökyüzünle uyumlan.", DiscoverContent.ritualNote(sky))
        }
    }

    private func card(_ icon: String, _ colors: [String], _ title: String, _ sub: String, _ note: DiscoverNote) -> some View {
        NavigationLink(value: DiscoverRoute.note(note.backed(.gradient(colors, icon: icon)))) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: colors.map { Color(hex: $0) }, startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: icon).font(.system(size: 90, weight: .ultraLight)).foregroundStyle(.white.opacity(0.12))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(14)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(ABFont.display(20, weight: .medium)).foregroundStyle(.white)
                    Text(sub).font(ABFont.body(12)).foregroundStyle(.white.opacity(0.8))
                }
                .padding(16)
            }
            .frame(height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Daily reading

struct DailyReadingPage: View {
    let sky: UserSky
    @Environment(\.dismiss) private var dismiss
    @State private var aiNote: DiscoverNote?
    @State private var aiState: AIStatusLine.State = .idle

    private var base: DiscoverNote { DiscoverContent.dailyReading(sky).backed(.image("discover_hero")) }
    private var note: DiscoverNote { aiNote ?? base }
    private var day: DailyNote {
        DailyNoteEngine.note(for: Date(), userId: sky.userId, sun: sky.sun, moon: sky.moon, rising: sky.rising)
    }
    private var th: Th { Th(light: false) }

    var body: some View {
        let moon = DiscoverContent.moonDay()
        ZStack {
            ScreenBackdropView(backdrop: .image("discover_hero"))
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Button { dismiss() } label: { CircleIconButtonStyle.label("chevron.left", th) }
                        Spacer()
                        ShareLink(item: shareText) { CircleIconButtonStyle.label("square.and.arrow.up", th) }
                    }
                    Text(note.eyebrow)
                        .font(ABFont.body(11, weight: .semibold)).tracking(2).foregroundStyle(Color(hex: "#FFD9A0"))
                    AIStatusLine(state: aiState, th: th)
                    Text(note.title)
                        .font(ABFont.display(34, weight: .regular)).foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    placementRow
                    HStack(spacing: 8) {
                        statTile(icon: moon.symbol, label: "AY", value: moon.title)
                        energyTile
                        colorTile
                    }
                    Text(note.intro)
                        .font(ABFont.body(15.5)).foregroundStyle(.white.opacity(0.9)).lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(note.sections) { section in
                        sectionCard(section)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 130)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            aiState = DiscoverAI.isAvailable ? .loading : .idle
            let out = await DiscoverAI.enrich(base, sky: sky)
            if out.usedAI { withAnimation { aiNote = out.note } }
            aiState = out.usedAI ? .done : .idle
        }
    }

    private var shareText: String {
        ([note.title, note.intro] + note.sections.map { "\($0.heading): \($0.text)" }).joined(separator: "\n\n")
    }

    private var placementRow: some View {
        HStack(spacing: 8) {
            if let sun = sky.sun { placeChip("\(sun.glyph) \(sun.labelTR)") }
            if let moon = sky.moon { placeChip("\(moon.glyph) \(moon.labelTR)") }
            if let rising = sky.rising { placeChip("↑ \(rising.labelTR)") }
        }
    }

    private func placeChip(_ title: String) -> some View {
        Text(title)
            .font(ABFont.body(12, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.12)))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.22), lineWidth: 0.8))
    }

    private var energyTile: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.16), lineWidth: 3.5)
                Circle()
                    .trim(from: 0, to: CGFloat(day.energyScore) / 100)
                    .stroke(Color(hex: "#E4B867"), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(day.energyScore)").font(ABFont.display(15, weight: .medium)).foregroundStyle(.white)
            }
            .frame(width: 46, height: 46)
            Text("ENERJİ").font(ABFont.body(9, weight: .semibold)).tracking(1.2).foregroundStyle(.white.opacity(0.7))
            Text(day.focus).font(ABFont.body(12.5, weight: .semibold)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .readingGlass()
    }

    private var colorTile: some View {
        statTile(icon: "circle.fill", label: "RENK", value: day.luckyHue, tint: Color(hex: DiscoverContent.hueHex(day.luckyHue)))
    }

    private func statTile(icon: String, label: String, value: String, tint: Color = Color(hex: "#FFD9A0")) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 22, weight: .light)).foregroundStyle(tint).frame(height: 46)
            Text(label).font(ABFont.body(9, weight: .semibold)).tracking(1.2).foregroundStyle(.white.opacity(0.7))
            Text(value).font(ABFont.body(12.5, weight: .semibold)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .readingGlass()
    }

    private func sectionCard(_ section: NoteSection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon(for: section.heading))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "#E4B867"))
                Text(section.heading.uppercased(with: Locale(identifier: "tr_TR")))
                    .font(ABFont.body(12, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(Color(hex: "#FFD9A0"))
            }
            Text(section.text)
                .font(ABFont.body(15))
                .foregroundStyle(.white.opacity(0.92))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .readingGlass()
    }

    private func icon(for heading: String) -> String {
        let h = heading.lowercased(with: Locale(identifier: "tr_TR"))
        if h.contains("gökyüzü") { return "moon.stars" }
        if h.contains("aşk") { return "heart" }
        if h.contains("iş") { return "briefcase" }
        if h.contains("beden") || h.contains("ruh") { return "leaf" }
        if h.contains("dene") { return "checkmark.circle" }
        return "questionmark.circle"
    }
}

private extension View {
    func readingGlass() -> some View {
        self
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.black.opacity(0.38)))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.white.opacity(0.16), lineWidth: 1))
    }
}

// MARK: - Generic note page

struct NoteDetailPage: View {
    let baseNote: DiscoverNote
    let sky: UserSky
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var aiNote: DiscoverNote?
    @State private var aiState: AIStatusLine.State = .idle

    init(note: DiscoverNote, sky: UserSky) { self.baseNote = note; self.sky = sky }

    private var note: DiscoverNote { aiNote ?? baseNote }

    var body: some View {
        let th = Th(light: note.backdrop.isLight)
        ZStack {
            ScreenBackdropView(backdrop: note.backdrop)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Button { dismiss() } label: { CircleIconButtonStyle.label("chevron.left", th) }
                        Spacer()
                        ShareLink(item: "\(note.title)\n\(note.intro)") { CircleIconButtonStyle.label("square.and.arrow.up", th) }
                    }
                    Text(note.eyebrow).font(ABFont.body(11, weight: .semibold)).tracking(2).foregroundStyle(th.accent)
                        .padding(.top, 6)
                    AIStatusLine(state: aiState, th: th)
                    Text(note.title).font(ABFont.display(32, weight: .regular)).foregroundStyle(th.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(note.intro).font(ABFont.body(15)).foregroundStyle(th.primary.opacity(0.85)).lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(note.sections) { s in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(s.heading).font(ABFont.body(13, weight: .bold)).foregroundStyle(th.accent)
                            Text(s.text).font(ABFont.body(14.5)).foregroundStyle(th.primary.opacity(0.9)).lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(th.cardFill))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(th.cardStroke, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 130)
            }
        }
        .environment(\.th, th)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            aiState = DiscoverAI.isAvailable ? .loading : .idle
            let out = await DiscoverAI.enrich(baseNote, sky: sky)
            if out.usedAI { withAnimation { aiNote = out.note } }
            aiState = out.usedAI ? .done : .idle
        }
    }
}


/// Journal sheet for the daily card question; the note is saved on-device per day.
struct ReflectionSheet: View {
    let question: String
    let key: String
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var focused: Bool
    @Environment(\.colorScheme) private var scheme
    private var th: Th { Th(light: false) }
    private var lav: Color { Color.adaptive(light: "#6C56D6", dark: "#C9B6FF") }

    var body: some View {
        ZStack {
            ScreenBackdropView(backdrop: .violet)
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("BUGÜN KENDİNE SOR").font(ABFont.body(10.5, weight: .semibold)).tracking(2).foregroundStyle(lav)
                    Spacer()
                    Button("Kapat") { save(); dismiss() }.font(ABFont.body(14)).foregroundStyle(th.primary.opacity(0.8))
                }
                Text(question).font(ABFont.display(26, weight: .regular)).foregroundStyle(th.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Aklına gelen ilk cevabı yaz. Notun sadece bu cihazda saklanır.")
                    .font(ABFont.body(13)).foregroundStyle(th.primary.opacity(0.65))
                TextEditor(text: $text)
                    .focused($focused)
                    .scrollContentBackground(.hidden)
                    .font(ABFont.body(15)).foregroundStyle(th.primary)
                    .padding(12)
                    .frame(minHeight: 180, maxHeight: 280)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill((th.light ? Color.white.opacity(0.7) : Color.white.opacity(0.07))))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(lav.opacity(0.4), lineWidth: 1))
                Button { save(); dismiss() } label: {
                    Text("Kaydet").font(ABFont.body(15, weight: .semibold)).foregroundStyle(Color(hex: "#1A1033"))
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Capsule().fill(lav))
                }
                Spacer()
            }
            .padding(22)
        }
        .presentationDetents([.large])
        .onAppear {
            text = UserDefaults.standard.string(forKey: key) ?? ""
            focused = true
        }
    }

    private func save() {
        UserDefaults.standard.set(text.trimmingCharacters(in: .whitespacesAndNewlines), forKey: key)
    }
}

import Foundation

/// The user's own sky, as far as we know it. Everything on the Keşfet page is derived from this,
/// so each box reads differently for each person (and each day).
struct UserSky: Equatable {
    var userId: String = ""
    var name: String = ""
    var sun: ZodiacSign?
    var moon: ZodiacSign?
    var rising: ZodiacSign?
    var venus: ZodiacSign?
    var mars: ZodiacSign?
    var mercury: ZodiacSign?
    var dominantElement: ZodiacSign.Element?

    /// "Aslan güneşin" style fragments with graceful fallbacks when a placement is unknown.
    var firstName: String { name.split(separator: " ").first.map(String.init) ?? "" }
    var anchor: ZodiacSign { rising ?? sun ?? .aries }
}

extension DiscoverNote: Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension DiscoverNote {
    func backed(_ b: ScreenBackdrop) -> DiscoverNote { var c = self; c.backdrop = b; return c }
}

struct NoteSection: Identifiable, Equatable {
    let id = UUID()
    let heading: String
    let text: String
}

struct DiscoverNote: Identifiable, Equatable {
    var backdrop: ScreenBackdrop = .night
    let id = UUID()
    let icon: String
    let eyebrow: String
    let title: String
    let intro: String
    let sections: [NoteSection]
}

struct SkyEvent: Identifiable, Equatable {
    enum Kind { case retrograde, newMoon, fullMoon, eclipse, solstice }
    let id: String
    let kind: Kind
    let title: String
    let dateText: String
    let start: Date
    let end: Date
    let sign: ZodiacSign
    let blurb: String
}

enum DiscoverContent {
    // MARK: - Seeded randomness

    private struct RNG {
        var state: UInt64
        init(_ key: String) {
            var h: UInt64 = 14695981039346656037
            for b in key.utf8 { h ^= UInt64(b); h &*= 1099511628211 }
            state = h &* 0x9E3779B97F4A7C15
        }
        mutating func next() -> Double {
            state = state &* 6364136223846793005 &+ 1
            return Double((state >> 11) & 0x1FFFFF) / Double(0x1FFFFF)
        }
        mutating func pick<T>(_ a: [T]) -> T { a[min(a.count - 1, Int(next() * Double(a.count)))] }
    }

    private static func dayKey(_ date: Date) -> String {
        let c = Calendar.current
        return "\(c.component(.year, from: date))-\(c.ordinality(of: .day, in: .year, for: date) ?? 0)"
    }

    private static func rng(_ sky: UserSky, _ date: Date, _ salt: String) -> RNG {
        RNG("\(sky.userId)|\(dayKey(date))|\(sky.sun?.rawValue ?? "")\(sky.moon?.rawValue ?? "")\(sky.rising?.rawValue ?? "")|\(salt)")
    }

    private static func lower(_ s: String) -> String { s.lowercased(with: Locale(identifier: "tr_TR")) }

    // MARK: - Houses

    private static let houseThemes = [
        "kimliğin ve yeni başlangıçların", "paran ve değerlerin", "iletişimin ve yakın çevren",
        "evin ve ailen", "aşkın ve yaratıcılığın", "günlük düzenin ve sağlığın",
        "ilişkilerin ve ortaklıkların", "dönüşümün ve ortak kaynakların", "ufkunun ve öğrenme alanın",
        "kariyerin ve itibarın", "dostlukların ve hayallerin", "iç dünyan ve dinlenmen"
    ]

    /// Whole-sign house of `sign` counted from the user's rising sign (or sun if rising is unknown).
    static func house(of sign: ZodiacSign, for sky: UserSky) -> Int {
        let all = ZodiacSign.allCases
        let a = all.firstIndex(of: sky.anchor) ?? 0
        let b = all.firstIndex(of: sign) ?? 0
        return ((b - a) % 12 + 12) % 12 + 1
    }

    static func houseTheme(_ house: Int) -> String { houseThemes[(house - 1 + 12) % 12] }

    // MARK: - Hero / daily note

    static func heroSubtitle(_ sky: UserSky, date: Date = Date()) -> String {
        let note = DailyNoteEngine.note(for: date, userId: sky.userId, sun: sky.sun, moon: sky.moon, rising: sky.rising)
        let who = sky.firstName.isEmpty ? "" : "\(sky.firstName), "
        if let sun = sky.sun, let moon = sky.moon {
            return "\(who)\(sun.labelTR) güneşin ve \(moon.labelTR) ayınla bugün \(lower(note.focus)) öne çıkıyor."
        }
        return "\(who)bugün enerjin en çok \(lower(note.focus)) alanında hissedilecek."
    }

    private static let loveLines: [ZodiacSign.Element: [String]] = [
        .fire: ["Cesur bir adım ya da içten bir mesaj ilgiyi hemen canlandırır.", "Heyecanını saklama; sıcaklığın bugün çekici geliyor."],
        .earth: ["Küçük, somut bir ilgi göstergesi bugün bin söze bedel.", "Acele etme; güven yavaş ama sağlam kurulur."],
        .air: ["Bir sohbet, bir espri ya da bir fikir paylaşımı kalpleri yaklaştırır.", "Merakın bugün en iyi flört aracın."],
        .water: ["Sezgilerin bugün karşındakinin ruh halini açıkça okuyor.", "Duygularını yumuşak bir dille paylaşmak iyi gelir."]
    ]
    private static let workLines: [ZodiacSign.Element: [String]] = [
        .fire: ["Bekleyen bir işi başlatmak için güçlü bir gün.", "Liderlik alman gereken bir an olabilir."],
        .earth: ["Planlı ilerlemek bugün somut sonuç getirir.", "Detaylara verdiğin emek fark edilecek."],
        .air: ["Görüşmeler ve yazışmalar bugün verimli.", "Yeni bir bağlantı kapı açabilir."],
        .water: ["Sezgisel kararların bugün isabetli.", "Ekip içinde dinleyici olmak sana avantaj sağlar."]
    ]
    private static let mindLines: [ZodiacSign.Element: [String]] = [
        .fire: ["Enerjini yürüyüş ya da spora aktar.", "Sabırsızlığını bir hedefe çevir."],
        .earth: ["Topraklanmak için doğada kısa bir mola ver.", "Düzenli bir akşam rutini seni dengeler."],
        .air: ["Zihnin hızlı; ekranlardan kısa bir mola ver.", "Düşüncelerini yazmak zihnini rahatlatır."],
        .water: ["Suyla temas (duş, banyo) seni yeniler.", "Yalnız kalacağın bir saat ruhuna iyi gelir."]
    ]

    static func dailyReading(_ sky: UserSky, date: Date = Date()) -> DiscoverNote {
        let note = DailyNoteEngine.note(for: date, userId: sky.userId, sun: sky.sun, moon: sky.moon, rising: sky.rising)
        var r = rng(sky, date, "daily")
        let sunEl = (sky.sun ?? .aries).element
        let moonEl = (sky.moon ?? sky.sun ?? .aries).element
        return DiscoverNote(
            icon: "sun.max",
            eyebrow: "GÜNÜN YORUMU · \(note.dateLabel.uppercased(with: Locale(identifier: "tr_TR")))",
            title: note.headline,
            intro: note.body,
            sections: [
                .init(heading: "Aşk & İlişkiler", text: r.pick(loveLines[moonEl] ?? [])),
                .init(heading: "İş & Para", text: r.pick(workLines[sunEl] ?? [])),
                .init(heading: "Ruh Hali", text: r.pick(mindLines[moonEl] ?? [])),
                .init(heading: "Enerji & Şans", text: "Bugünkü enerji seviyen yaklaşık %\(note.energyScore). Şanslı rengin: \(lower(note.luckyHue))."),
            ]
        )
    }

    // MARK: - Daily card (3 cards)

    static let cardNames = ["Güneş Kartı", "Ay Kartı", "Yıldız Kartı"]

    private static let cardPools: [[String]] = [
        ["Özünle hareket et; bugün kendi sesin en doğru pusulan.", "Görünür olmaktan çekinme, ışığın birine yol gösteriyor.", "Bir hedef için ilk adımı atmanın tam zamanı.", "Cömert davran; verdiğin ilgi sana kat kat dönecek."],
        ["Sezgin bugün sessizce ama net konuşuyor; dinle.", "Bir duyguyu bastırmak yerine adlandırmak seni rahatlatır.", "Geçmişten gelen bir hatıra bugün şifa veriyor.", "Kendine nazik ol; dinlenmek de ilerlemektir."],
        ["Bir dilek tut; evren küçük işaretlerle yanıt verecek.", "Beklenmedik bir haber ufkunu açabilir.", "Umudunu taşıyan biriyle konuşmak enerjini yükseltir.", "Uzun vadeli bir hayal için bugün küçük bir not al."]
    ]

    static func cardMessage(_ sky: UserSky, card: Int, date: Date = Date()) -> NoteSection {
        var r = rng(sky, date, "card\(card)")
        let body = r.pick(cardPools[card])
        let link: String
        switch card {
        case 0: link = sky.sun.map { "\($0.glyph) \($0.labelTR) güneşin için: " } ?? ""
        case 1: link = sky.moon.map { "\($0.glyph) \($0.labelTR) ayın için: " } ?? ""
        default: link = sky.rising.map { "\($0.glyph) \($0.labelTR) yükselenin için: " } ?? ""
        }
        return .init(heading: cardNames[card], text: link + body)
    }

    // MARK: - Sky events

    private static func d(_ y: Int, _ m: Int, _ day: Int) -> Date {
        var c = DateComponents(); c.year = y; c.month = m; c.day = day; c.hour = 12
        return Calendar.current.date(from: c) ?? Date()
    }

    private static let rawEvents: [(String, SkyEvent.Kind, String, String, Date, Date, ZodiacSign)] = [
        ("mrx-26", .retrograde, "Merkür Retrosu", "24 Eki – 13 Kas 2026", d(2026, 10, 24), d(2026, 11, 13), .scorpio),
        ("nm-1126", .newMoon, "Akrep Yeni Ayı", "9 Kasım 2026", d(2026, 11, 9), d(2026, 11, 9), .scorpio),
        ("fm-1126", .fullMoon, "İkizler Dolunayı", "24 Kasım 2026", d(2026, 11, 24), d(2026, 11, 24), .gemini),
        ("nm-1226", .newMoon, "Yay Yeni Ayı", "9 Aralık 2026", d(2026, 12, 9), d(2026, 12, 9), .sagittarius),
        ("sol-26", .solstice, "Kış Gündönümü", "21 Aralık 2026", d(2026, 12, 21), d(2026, 12, 21), .capricorn),
        ("fm-1226", .fullMoon, "Yengeç Dolunayı", "24 Aralık 2026", d(2026, 12, 24), d(2026, 12, 24), .cancer),
        ("nm-0127", .newMoon, "Oğlak Yeni Ayı", "7 Ocak 2027", d(2027, 1, 7), d(2027, 1, 7), .capricorn),
        ("fm-0127", .fullMoon, "Aslan Dolunayı", "22 Ocak 2027", d(2027, 1, 22), d(2027, 1, 22), .leo),
        ("ecl-0227", .eclipse, "Halkalı Güneş Tutulması", "6 Şubat 2027", d(2027, 2, 6), d(2027, 2, 6), .aquarius),
    ]

    private static func eventBlurb(_ kind: SkyEvent.Kind, _ sign: ZodiacSign) -> String {
        switch kind {
        case .retrograde: return "İletişim, planlar ve eski konular yeniden gündeme gelir; acele etmeden gözden geçir."
        case .newMoon: return "Yeni niyetler için tohum ekme zamanı; \(sign.labelTR) temasında bir başlangıç yap."
        case .fullMoon: return "Duygular belirginleşir, bir konu tamamlanır; \(sign.labelTR) teması aydınlanır."
        case .eclipse: return "Hayatında yön değiştirecek güçlü bir kapanış ve açılış penceresi."
        case .solstice: return "Güneş \(sign.labelTR) burcuna geçer; yılın en uzun gecesi içe dönmeye davet eder."
        }
    }

    static func upcomingEvents(now: Date = Date(), limit: Int = 6) -> [SkyEvent] {
        let startOfToday = Calendar.current.startOfDay(for: now)
        return rawEvents
            .filter { $0.5 >= startOfToday }
            .sorted { $0.4 < $1.4 }
            .prefix(limit)
            .map { SkyEvent(id: $0.0, kind: $0.1, title: $0.2, dateText: $0.3, start: $0.4, end: $0.5, sign: $0.6, blurb: eventBlurb($0.1, $0.6)) }
    }

    /// One-line personal angle on an event ("Senin 8. evinde — dönüşümün…").
    static func eventPersonalLine(_ e: SkyEvent, _ sky: UserSky) -> String {
        let h = house(of: e.sign, for: sky)
        return "Senin \(h). evinde: \(houseTheme(h)) öne çıkıyor."
    }

    static func eventNote(_ e: SkyEvent, _ sky: UserSky) -> DiscoverNote {
        let h = house(of: e.sign, for: sky)
        var extra = ""
        if let sun = sky.sun {
            if sun == e.sign { extra = "Güneş burcunla aynı işaret: etki doğrudan sana dokunuyor." }
            else if sun.element == e.sign.element { extra = "\(sun.labelTR) güneşin bu olayla aynı elementte; uyumlu ve destekleyici." }
            else if sun.element.isChallenging(to: e.sign.element) { extra = "\(sun.labelTR) güneşin için biraz sürtünmeli; sabır ve esneklik iste." }
            else { extra = "\(sun.labelTR) güneşin için dengeli bir etki." }
        }
        return DiscoverNote(
            icon: "moon.stars",
            eyebrow: e.dateText.uppercased(with: Locale(identifier: "tr_TR")),
            title: e.title,
            intro: e.blurb,
            sections: [
                .init(heading: "Senin Haritanda", text: "\(e.sign.labelTR) burcu senin \(h). evine denk geliyor: \(houseTheme(h)) alanı gündemde. \(extra)"),
                .init(heading: "Ne Yapmalı?", text: eventAdvice(e.kind, e.sign.element)),
            ]
        )
    }

    private static func eventAdvice(_ kind: SkyEvent.Kind, _ el: ZodiacSign.Element) -> String {
        let tone: String
        switch el {
        case .fire: tone = "Enerjini kontrollü kullan ve sabırsızlığa kapılma."
        case .earth: tone = "Somut adımlar at ve düzenini koru."
        case .air: tone = "Konuşmadan önce düşün, yazmadan önce oku."
        case .water: tone = "Duygularına alan aç ama kararlarını sezgiyle birlikte mantıkla da tart."
        }
        switch kind {
        case .retrograde: return "Önemli imzaları ve büyük satın almaları ertele, yedek al, eski bağlantıları kontrol et. \(tone)"
        case .newMoon: return "Üç net niyet yaz ve bu hafta bunlardan birine küçük bir adım at. \(tone)"
        case .fullMoon: return "Neyi bırakman gerektiğini not al; akşam sakin bir ritüelle günü kapat. \(tone)"
        case .eclipse: return "Büyük kararları birkaç gün dinlendir; dönüşümü zorlama, akışa yer ver. \(tone)"
        case .solstice: return "Yılı gözden geçir, bir niyet belirle ve ışığa dair küçük bir ritüel yap. \(tone)"
        }
    }

    static func allEventsNote(_ sky: UserSky) -> DiscoverNote {
        DiscoverNote(
            icon: "moon.stars", eyebrow: "YAKLAŞAN GÖKYÜZÜ OLAYLARI", title: "Gökyüzü Takvimin",
            intro: "Aşağıdaki olaylar senin haritandaki evlere göre yorumlandı.",
            sections: upcomingEvents(limit: 12).map {
                .init(heading: "\($0.title) · \($0.dateText)", text: eventPersonalLine($0, sky) + " " + $0.blurb)
            }
        )
    }

    // MARK: - Daily horoscope per sign

    static func signReading(_ sign: ZodiacSign, _ sky: UserSky, date: Date = Date()) -> DiscoverNote {
        var r = RNG("\(dayKey(date))|sign|\(sign.rawValue)|\(sky.userId)")
        let el = sign.element
        let h = house(of: sign, for: sky)
        var relation = ""
        if let sun = sky.sun {
            if sun == sign { relation = "Bu senin güneş burcun; bugün en çok sen hissedeceksin." }
            else if sun.element == el { relation = "\(sun.labelTR) güneşinle aynı elementte, bu yüzden bu burcun enerjisiyle kolay akarsın." }
            else if sun.element.isComplementary(to: el) { relation = "\(sun.labelTR) güneşinle tamamlayıcı bir element; bu burçla karşılaşmalar sana iyi gelir." }
            else if sun.element.isChallenging(to: el) { relation = "\(sun.labelTR) güneşinle zıt tonda; bu burçla iletişimde sabırlı ol." }
            else { relation = "\(sun.labelTR) güneşinle nötr bir ilişki; merak seni yönlendirsin." }
        }
        let general: [ZodiacSign.Element: [String]] = [
            .fire: ["Bugün cesur ve hareketli bir gün; kıvılcım bırak.", "Girişkenliğin ödüllendirilir ama öfkeni yönet."],
            .earth: ["Sağlam ve verimli bir gün; küçük adımlar büyür.", "Maddi konularda sabırlı ve gerçekçi ol."],
            .air: ["Zihinsel olarak çok canlı bir gün; fikirler uçuşur.", "Sosyal bağlantılar yeni kapılar açabilir."],
            .water: ["Duyguların derin; sezgilerine güven.", "Şefkat ve anlayış bugün en büyük gücün."]
        ]
        return DiscoverNote(
            icon: "sparkle", eyebrow: "GÜNLÜK BURÇ YORUMU", title: "\(sign.glyph) \(sign.labelTR)",
            intro: r.pick(general[el] ?? []),
            sections: [
                .init(heading: "Senin İçin", text: relation.isEmpty ? "Bu burç senin \(h). evinde." : "\(relation) Bu burç senin \(h). evinde: \(houseTheme(h))."),
                .init(heading: "Aşk", text: r.pick(loveLines[el] ?? [])),
                .init(heading: "İş & Para", text: r.pick(workLines[el] ?? [])),
                .init(heading: "Tarih Aralığı", text: "\(sign.dateRangeText) · \(sign.element.labelTR) · \(sign.modality.labelTR) · Yönetici: \(sign.rulerTR)"),
            ]
        )
    }

    static func allSignsNote(_ sky: UserSky, date: Date = Date()) -> DiscoverNote {
        DiscoverNote(
            icon: "sparkles", eyebrow: "GÜNLÜK BURÇ YORUMLARI", title: "Bugün 12 Burç",
            intro: "Her burcun günü, senin haritana göre kısaca.",
            sections: ZodiacSign.allCases.map {
                let n = signReading($0, sky, date: date)
                return .init(heading: n.title, text: n.intro + " " + (n.sections.first?.text ?? ""))
            }
        )
    }

    // MARK: - Love astrology

    private static let venusLines: [ZodiacSign.Element: String] = [
        .fire: "tutkulu, doğrudan ve macera arayan bir sevme biçimin var",
        .earth: "sadık, duyusal ve güven odaklı seviyorsun",
        .air: "zihinsel bağ kurarak, konuşarak ve oyunbazlıkla seviyorsun",
        .water: "derin, sezgisel ve tamamen içine girerek seviyorsun"
    ]
    private static let marsLines: [ZodiacSign.Element: String] = [
        .fire: "arzunu hızlı ve net gösterirsin",
        .earth: "yavaş ama kararlı ve dokunsal ilerlersin",
        .air: "söz ve zekâ ile cezbedersin",
        .water: "duygusal yakınlık kurmadan açılmazsın"
    ]

    static func loveNote(_ sky: UserSky, date: Date = Date()) -> DiscoverNote {
        var r = rng(sky, date, "love")
        let venus = sky.venus ?? sky.moon ?? sky.sun ?? .libra
        let mars = sky.mars ?? sky.sun ?? .aries
        let venusLabel = sky.venus == nil ? "Aşk dilin" : "Venüs \(venus.glyph) \(venus.labelTR)"
        let compat = ZodiacSign.allCases.filter { $0 != (sky.sun ?? .aries) && ($0.element == (sky.sun ?? .aries).element || $0.element.isComplementary(to: (sky.sun ?? .aries).element)) }
            .map(\.labelTR).joined(separator: ", ")
        return DiscoverNote(
            icon: "heart", eyebrow: "AŞK VE İLİŞKİ ASTROLOJİSİ", title: "Kalbinin Haritası",
            intro: "\(sky.firstName.isEmpty ? "" : sky.firstName + ", ")yıldızlar kalbinin dilini şöyle okuyor.",
            sections: [
                .init(heading: venusLabel, text: "\(venusLines[venus.element] ?? "")."),
                .init(heading: "Mars \(mars.glyph) \(mars.labelTR)", text: "Çekimde \(marsLines[mars.element] ?? "")."),
                .init(heading: "Bugün Aşk İçin", text: r.pick(loveLines[(sky.moon ?? venus).element] ?? [])),
                .init(heading: "Uyumlu Burçlar", text: compat.isEmpty ? "Eşleşme çarkında sana en uyumlu kişileri keşfet." : "Elementsel olarak sana en kolay akan burçlar: \(compat)."),
            ]
        )
    }

    // MARK: - Guide (learn your chart)

    static func guideNote(_ sky: UserSky) -> DiscoverNote {
        var sections: [NoteSection] = []
        if let s = sky.sun {
            sections.append(.init(heading: "☉ Güneş · \(s.labelTR)", text: "Özün ve yaşam enerjin. \(s.element.labelTR) elementi (\(s.element.blurbTR)) ve \(s.modality.labelTR.lowercased()) nitelik (\(s.modality.blurbTR)). Yöneticin \(s.rulerTR)."))
        }
        if let m = sky.moon {
            sections.append(.init(heading: "☽ Ay · \(m.labelTR)", text: "Duygusal dünyan ve ihtiyaçların. \(m.element.labelTR) tonu: \(m.element.blurbTR) bir iç dünya."))
        }
        if let a = sky.rising {
            sections.append(.init(heading: "↑ Yükselen · \(a.labelTR)", text: "Dünyaya göründüğün yüz ve ilk izlenim. \(a.element.labelTR) elementi: dışarıya \(a.element.blurbTR) bir enerji yayıyorsun."))
        }
        if let de = sky.dominantElement {
            sections.append(.init(heading: "Baskın Element · \(de.labelTR)", text: "Haritandaki gezegenler en çok \(de.labelTR.lowercased()) elementinde toplanıyor: \(de.blurbTR) bir temel."))
        }
        if sections.isEmpty {
            sections.append(.init(heading: "Başlangıç", text: "Profilini tamamlayınca Güneş, Ay ve Yükselen yorumların burada belirecek."))
        }
        return DiscoverNote(
            icon: "book", eyebrow: "ASTROLOJİ REHBERİ", title: "Haritanı Oku",
            intro: "Büyük üçlün senin kozmik imzan. İşte kısaca anlamları.", sections: sections
        )
    }

    // MARK: - Extra content

    static func weeklyNote(_ sky: UserSky, from date: Date = Date()) -> DiscoverNote {
        let df = DateFormatter(); df.locale = Locale(identifier: "tr_TR"); df.dateFormat = "EEEE, d MMM"
        let sections: [NoteSection] = (0..<7).compactMap { i in
            guard let day = Calendar.current.date(byAdding: .day, value: i, to: date) else { return nil }
            let n = DailyNoteEngine.note(for: day, userId: sky.userId, sun: sky.sun, moon: sky.moon, rising: sky.rising)
            return .init(heading: df.string(from: day).capitalized(with: Locale(identifier: "tr_TR")), text: "\(n.headline) · Enerji %\(n.energyScore) · Şanslı renk: \(lower(n.luckyHue)).")
        }
        return DiscoverNote(icon: "calendar", eyebrow: "HAFTALIK GÖKYÜZÜ GÜNDEMİ", title: "Bu Hafta Sende",
                            intro: "Önümüzdeki 7 gün için kişisel odak ve enerji tahminin.", sections: sections)
    }

    static func beginnerNote(_ sky: UserSky) -> DiscoverNote {
        let sun = sky.sun?.labelTR ?? "Güneş burcun"
        let moon = sky.moon?.labelTR ?? "Ay burcun"
        let rising = sky.rising?.labelTR ?? "Yükselenin"
        return DiscoverNote(
            icon: "leaf", eyebrow: "YENİ BAŞLAYANLAR İÇİN ASTROLOJİ", title: "3 Adımda Başla",
            intro: "Astrolojiye senin haritanla girelim.",
            sections: [
                .init(heading: "1 · Güneşin: \(sun)", text: "Kim olduğunu ve neyle parladığını anlatır. Günlük burç yorumlarını önce buradan oku."),
                .init(heading: "2 · Ayın: \(moon)", text: "Neye ihtiyaç duyduğunu ve nasıl rahatladığını gösterir. Duygusal kararlarında Ay'ına bak."),
                .init(heading: "3 · Yükselenin: \(rising)", text: "İlk izlenimini ve hayata yaklaşımını anlatır. Yeni insanlarla tanışırken bu kapıdan girersin."),
                .init(heading: "Sonra", text: "Eşleşme sekmesinde karşındakinin büyük üçlüsünü senin haritanla karşılaştır."),
            ]
        )
    }

    private static let rituals: [ZodiacSign.Element: [String]] = [
        .fire: ["Bir mum yak ve bugün bırakmak istediğin şeyi yazıp yak.", "Güneş doğarken 5 dakika nefes çalışması yap."],
        .earth: ["Çıplak ayakla toprağa bas ve 10 derin nefes al.", "Evinde küçük bir düzenleme yap ve bir bitkiyle ilgilen."],
        .air: ["Pencereyi aç, 3 dilek söyle ve rüzgârın taşımasına izin ver.", "Akşam telefonsuz bir saat geçirip günlük tut."],
        .water: ["Deniz tuzlu ılık bir banyo yap ve niyetini fısılda.", "Bir bardak suyu ay ışığına bırak, sabah niyetle iç."]
    ]
    private static let crystals: [ZodiacSign.Element: String] = [
        .fire: "Karneol", .earth: "Yeşim", .air: "Berrak kuvars", .water: "Ay taşı"
    ]

    static func ritualNote(_ sky: UserSky, date: Date = Date()) -> DiscoverNote {
        var r = rng(sky, date, "ritual")
        let el = (sky.moon ?? sky.sun ?? .pisces).element
        let n = DailyNoteEngine.note(for: date, userId: sky.userId, sun: sky.sun, moon: sky.moon, rising: sky.rising)
        return DiscoverNote(
            icon: "flame", eyebrow: "RİTÜELLER VE ÖNERİLER", title: "Bugünün Ritüeli",
            intro: "Ayının \(el.labelTR.lowercased()) tonuna göre hazırlandı.",
            sections: [
                .init(heading: "Ritüel", text: r.pick(rituals[el] ?? [])),
                .init(heading: "Taş", text: "\(crystals[el] ?? "Kuvars") bugün yanında taşıman için iyi bir eşlikçi."),
                .init(heading: "Renk", text: "Şanslı rengin: \(lower(n.luckyHue)). Kıyafet ya da aksesuarla ekle."),
                .init(heading: "Odak", text: "Bugünün odağı: \(lower(n.focus))."),
            ]
        )
    }

    static func extrasAllNote(_ sky: UserSky) -> DiscoverNote {
        let notes = [weeklyNote(sky), beginnerNote(sky), ritualNote(sky)]
        return DiscoverNote(
            icon: "square.grid.2x2", eyebrow: "KEŞFET · EK İÇERİKLER", title: "Sana Özel Seçkiler", intro: "Üç kısa rehber, senin haritana göre.",
            sections: notes.map { .init(heading: $0.title, text: $0.intro + " " + ($0.sections.first?.text ?? "")) }
        )
    }
}


// MARK: - Screens added for the purple Keşfet redesign

struct DiscoverTopic: Identifiable {
    let id = UUID()
    let category: String
    let title: String
    let subtitle: String
    let tint: String
    let note: DiscoverNote
}

struct SignDetailRow: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let text: String
}

extension DiscoverContent {
    private static let cardTitles: [[String]] = [
        ["Bırak, sana ait olan yolunu bulsun.", "Işığın bugün birine yol gösteriyor.", "İlk adımı atmak için doğru an bu.", "Verdiğin ilgi sana kat kat dönecek."],
        ["Sezgin sessizce ama net konuşuyor.", "Hissettiğini adlandırmak seni hafifletir.", "Geçmiş bugün sana şifa getiriyor.", "Dinlenmek de ilerlemenin bir parçası."],
        ["Bir dilek tut, evren işaretlerle yanıtlar.", "Beklenmedik bir haber ufkunu açar.", "Umut taşıyan biriyle konuş.", "Uzun vadeli hayalin için küçük bir not al."]
    ]
    private static let askQuestions = [
        "Nasıl zorlamayı bırakabilirim?", "Bugün neye gerçekten ihtiyacım var?", "Kimden ya da neden uzaklaşmam gerekiyor?",
        "Hangi korkum beni durduruyor?", "Bugün kendime hangi iyiliği borçluyum?", "Neyi affetmem gerekiyor?"
    ]

    struct CardResult { let title: String; let body: String; let question: String }

    static func cardResult(_ sky: UserSky, card: Int, date: Date = Date()) -> CardResult {
        var r = rng(sky, date, "result\(card)")
        let title = r.pick(cardTitles[card])
        let msg = cardMessage(sky, card: card, date: date)
        let who: String
        switch card {
        case 0: who = sky.sun.map { "\($0.glyph) \($0.labelTR) güneşin" } ?? "Güneşin"
        case 1: who = sky.moon.map { "\($0.glyph) \($0.labelTR) ayın" } ?? "Ayın"
        default: who = sky.rising.map { "\($0.glyph) \($0.labelTR) yükselenin" } ?? "Yükselenin"
        }
        let body = "Her yeni bugün çemberi zamanda değişir. \(who) bugün sana şunu fısıldıyor: \(msg.text.components(separatedBy: ": ").last ?? msg.text)"
        return CardResult(title: title, body: body, question: r.pick(askQuestions))
    }

    static func signRows(_ sign: ZodiacSign, _ sky: UserSky, date: Date = Date()) -> [SignDetailRow] {
        var r = RNG("\(dayKey(date))|rows|\(sign.rawValue)|\(sky.userId)")
        let el = sign.element
        let tips: [ZodiacSign.Element: [String]] = [
            .fire: ["Küçük bir hedef belirle ve hemen başla.", "Enerjini hareketle boşalt."],
            .earth: ["Bir işi bitir, sonra dinlen.", "Bedenini toprakla buluştur: yürü."],
            .air: ["Bir arkadaşını ara, fikrini paylaş.", "Düşüncelerini üç cümleyle yaz."],
            .water: ["Kendine sıcak bir içecek hazırla ve sessizlikte otur.", "Bir şarkıyla duygularını akıt."]
        ]
        return [
            .init(icon: "heart", title: "Aşk & İlişkiler", text: r.pick(loveLines[el] ?? [])),
            .init(icon: "briefcase", title: "Kariyer & Üretkenlik", text: r.pick(workLines[el] ?? [])),
            .init(icon: "drop", title: "Duygusal Durum", text: r.pick(mindLines[el] ?? [])),
            .init(icon: "sparkle", title: "Günün Önerisi", text: r.pick(tips[el] ?? [])),
        ]
    }

    static func signRelation(_ sign: ZodiacSign, _ sky: UserSky) -> String {
        let h = house(of: sign, for: sky)
        guard let sun = sky.sun else { return "Bu burç senin \(h). evinde: \(houseTheme(h))." }
        let rel: String
        if sun == sign { rel = "Bu senin güneş burcun; bugün en çok sen hissedeceksin." }
        else if sun.element == sign.element { rel = "\(sun.labelTR) güneşinle aynı element." }
        else if sun.element.isComplementary(to: sign.element) { rel = "\(sun.labelTR) güneşinle tamamlayıcı." }
        else if sun.element.isChallenging(to: sign.element) { rel = "\(sun.labelTR) güneşinle sürtünmeli; sabır iste." }
        else { rel = "\(sun.labelTR) güneşinle nötr." }
        return "\(rel) Senin \(h). evinde: \(houseTheme(h))."
    }

    static func eventSignEffects(_ e: SkyEvent, _ sky: UserSky) -> DiscoverNote {
        let me = sky
        return DiscoverNote(
            icon: "sparkles", eyebrow: "BURÇLARA GÖRE ETKİLER", title: e.title,
            intro: "\(e.sign.labelTR) burcundaki bu olay her burcun farklı bir alanına dokunur.",
            sections: ZodiacSign.allCases.map { s in
                var u = me; u.rising = s
                let h = house(of: e.sign, for: u)
                return .init(heading: "\(s.glyph) \(s.labelTR)", text: "\(h). ev etkisi: \(houseTheme(h)).")
            }
        )
    }

    // MARK: Topic lists

    static func loveTopics(_ sky: UserSky) -> [DiscoverTopic] {
        let sun = sky.sun ?? .aries
        let venus = sky.venus ?? sky.moon ?? sun
        let mars = sky.mars ?? sun
        let moon = sky.moon ?? sun
        let good = ZodiacSign.allCases.filter { $0 != sun && ($0.element == sun.element || $0.element.isComplementary(to: sun.element)) }.map(\.labelTR).joined(separator: ", ")
        let hard = ZodiacSign.allCases.filter { $0.element.isChallenging(to: sun.element) }.map(\.labelTR).joined(separator: ", ")
        func n(_ icon: String, _ eyebrow: String, _ title: String, _ intro: String, _ secs: [NoteSection]) -> DiscoverNote {
            DiscoverNote(icon: icon, eyebrow: eyebrow, title: title, intro: intro, sections: secs)
        }
        return [
            .init(category: "Tümü", title: "Venüs Burcu", subtitle: "Aşk dilin ve sevme biçimin", tint: "#C98A9B",
                  note: n("heart", "AŞK VE İLİŞKİ", "Venüs \(venus.glyph) \(venus.labelTR)", "\(venusLines[venus.element] ?? "").",
                          [.init(heading: "İlişkide Güçlü Yanın", text: "\(venus.element.labelTR) elementi: \(venus.element.blurbTR) bir sevgi dili."),
                           .init(heading: "Dikkat Et", text: "Beklentilerini açıkça söylemek, \(lower(venus.labelTR)) enerjisinin en büyük sınavı.")])),
            .init(category: "Tümü", title: "Mars ve Çekim Dinamikleri", subtitle: "Arzu ve tutkunun yönü", tint: "#C0674F",
                  note: n("flame", "AŞK VE İLİŞKİ", "Mars \(mars.glyph) \(mars.labelTR)", "Çekimde \(marsLines[mars.element] ?? "").",
                          [.init(heading: "Çekim Tarzın", text: "\(mars.modality.labelTR) nitelik: \(mars.modality.blurbTR)."),
                           .init(heading: "Uyum İpucu", text: "Seni en iyi anlayan, \(mars.element.labelTR.lowercased()) tonuna saygı duyan kişi.")])),
            .init(category: "Tümü", title: "Ay Burcu", subtitle: "Duygusal ihtiyaçların", tint: "#9C93C7",
                  note: n("moon", "AŞK VE İLİŞKİ", "Ay \(moon.glyph) \(moon.labelTR)", "Duygusal güvenliğin \(moon.element.blurbTR) bir ortamda büyür.",
                          [.init(heading: "İhtiyacın", text: "Yakınlıkta \(moon.element.labelTR.lowercased()) elementi gibi: \(moon.element.blurbTR)."),
                           .init(heading: "Partnerine Söyle", text: "Ne zaman yalnız kalmak, ne zaman sarılmak istediğini ona açıkça anlat.")])),
            .init(category: "Tümü", title: "İki Burcun Uyumu", subtitle: "Güneş burcuna göre uyum", tint: "#B58BC9",
                  note: n("person.2", "AŞK VE İLİŞKİ", "\(sun.labelTR) için Uyum", "Elementsel akışa göre seni en çok destekleyen ve zorlayan burçlar.",
                          [.init(heading: "Kolay Akan Burçlar", text: good.isEmpty ? "—" : good),
                           .init(heading: "Emek İsteyen Burçlar", text: hard.isEmpty ? "—" : hard),
                           .init(heading: "Not", text: "Gerçek uyum tüm harita karşılaştırmasıyla belli olur: Eşleşme sekmesindeki sinastri bunu gösterir.")])),
            .init(category: "Tümü", title: "Sinastri Rehberi", subtitle: "Haritaların buluşması", tint: "#8C8FB5",
                  note: n("circle.hexagongrid", "AŞK VE İLİŞKİ", "Sinastri Nedir?", "İki kişinin doğum haritasının üst üste konup karşılaştırılmasıdır.",
                          [.init(heading: "Neye Bakılır?", text: "Güneş–Ay, Venüs–Mars ve açı ilişkileri; çekim, güven ve sürtünme alanlarını gösterir."),
                           .init(heading: "Sende", text: "Güneşin \(sun.labelTR), ayın \(moon.labelTR): karşındakinin bu noktalarla nasıl konuştuğuna bak.")])),
        ]
    }

    static func guideTopics(_ sky: UserSky) -> [DiscoverTopic] {
        let sun = sky.sun ?? .aries
        let anchor = sky.anchor
        func n(_ icon: String, _ cat: String, _ title: String, _ intro: String, _ secs: [NoteSection]) -> DiscoverNote {
            DiscoverNote(icon: icon, eyebrow: "ASTROLOJİ REHBERİ · \(cat.uppercased(with: Locale(identifier: "tr_TR")))", title: title, intro: intro, sections: secs)
        }
        let houses: [NoteSection] = (1...12).map { h in
            let all = ZodiacSign.allCases
            let idx = ((all.firstIndex(of: anchor) ?? 0) + h - 1) % 12
            return .init(heading: "\(h). Ev · \(all[idx].labelTR)", text: "Konu: \(houseTheme(h)).")
        }
        return [
            .init(category: "Gezegenler", title: "Gezegenler neyi temsil eder?", subtitle: "Güneş, Ay, Venüs ve ötesi", tint: "#B7906F",
                  note: n("globe", "Gezegenler", "Gökyüzünün Oyuncuları", "Her gezegen yaşamının farklı bir yönünü anlatır.",
                          [.init(heading: "☉ Güneş", text: "Özün ve yaşam enerjin. Sende: \(sun.labelTR)."),
                           .init(heading: "☽ Ay", text: "Duyguların. Sende: \(sky.moon?.labelTR ?? "—")."),
                           .init(heading: "☿ Merkür", text: "Düşünme ve iletişim. Sende: \(sky.mercury?.labelTR ?? "—")."),
                           .init(heading: "♀ Venüs", text: "Sevgi ve zevk. Sende: \(sky.venus?.labelTR ?? "—")."),
                           .init(heading: "♂ Mars", text: "Eylem ve arzu. Sende: \(sky.mars?.labelTR ?? "—").")])),
            .init(category: "Evler", title: "Evler ne anlama gelir?", subtitle: "Hayatın 12 alanı", tint: "#9C6F78",
                  note: n("house", "Evler", "12 Ev", "Evler hayatın alanlarını gösterir. Haritan \(anchor.labelTR) ile başlıyor.", houses)),
            .init(category: "Gezegenler", title: "Retro hareket ne demek?", subtitle: "Geriye giden gezegenler", tint: "#C07F5A",
                  note: n("arrow.uturn.backward", "Gezegenler", "Retro Hareket", "Bir gezegen gökyüzünde geriye gidiyormuş gibi görünür; gerçekte bu bir bakış açısı etkisidir.",
                          [.init(heading: "Ne Yapılır?", text: "Gözden geçir, yeniden dene, tamamla. Yeni büyük başlangıçları erteleyebilirsin."),
                           .init(heading: "Merkür Retrosu", text: "İletişim, yolculuk ve teknolojide gecikmeler olabilir. Yedek al, mesajlarını iki kez oku.")])),
            .init(category: "Burçlar", title: "Burçlar arasındaki uyum", subtitle: "Element ve nitelikler", tint: "#8F8BC2",
                  note: n("person.2", "Burçlar", "Elementler & Nitelikler", "Ateş ve Hava birbirini besler; Toprak ve Su birbirini taşır.",
                          [.init(heading: "Senin Elementin", text: "\(sun.element.labelTR): \(sun.element.blurbTR)."),
                           .init(heading: "Niteliğin", text: "\(sun.modality.labelTR): \(sun.modality.blurbTR).")])),
            .init(category: "Burçlar", title: "Doğum haritası nasıl okunur?", subtitle: "Adım adım rehber", tint: "#7E78B8",
                  note: n("map", "Burçlar", "Haritanı Oku", "Önce üçlüne bak: Güneş, Ay, Yükselen.",
                          [.init(heading: "1 · Güneş", text: sun.labelTR), .init(heading: "2 · Ay", text: sky.moon?.labelTR ?? "—"),
                           .init(heading: "3 · Yükselen", text: sky.rising?.labelTR ?? "—"),
                           .init(heading: "4 · Evler & Açılar", text: "Sonra gezegenlerin hangi evde olduğuna ve birbirleriyle açılarına bak.")])),
            .init(category: "Gezegenler", title: "Astroloji açıları", subtitle: "Gezegenler arası konuşma", tint: "#8CA0C2",
                  note: n("angle", "Gezegenler", "Açılar", "Gezegenler birbirine belirli açılarla bakınca konuşur.",
                          [.init(heading: "Kavuşum 0°", text: "Enerjiler birleşir."), .init(heading: "Üçgen 120°", text: "Akıcı ve destekleyici."),
                           .init(heading: "Kare 90°", text: "Gerilim ve gelişim."), .init(heading: "Karşıt 180°", text: "Denge arayışı.")])),
        ]
    }
}

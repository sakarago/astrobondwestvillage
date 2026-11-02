import Foundation

enum MatchIntent: String, CaseIterable, Identifiable, Codable, Sendable {
    case romantic
    case relationship
    case business
    case friends

    var id: String { rawValue }

    var titleTR: String {
        switch self {
        case .romantic: return "Romantik"
        case .relationship: return "İlişki"
        case .business: return "İş"
        case .friends: return "Arkadaş"
        }
    }

    var subtitle: String {
        switch self {
        case .romantic: return "Çekim & bağ"
        case .relationship: return "Uzun vadeli"
        case .business: return "Ortaklık"
        case .friends: return "Dostluk"
        }
    }

    var iconName: String {
        switch self {
        case .romantic: return "heart.fill"
        case .relationship: return "link"
        case .business: return "briefcase.fill"
        case .friends: return "person.2.fill"
        }
    }

    /// Match-home pill copy — English product names, as on the Eşleşme mock.
    var bondLabel: String {
        switch self {
        case .romantic: return "RomanticBond"
        case .relationship: return "SexBond"
        case .business: return "BusinessBond"
        case .friends: return "FriendBond"
        }
    }
}

@MainActor
final class MatchPrefsStore {
    static let shared = MatchPrefsStore()
    private let defaults = UserDefaults.standard
    private let key = "wv.match.prefs.v1"

    struct Snapshot: Codable, Equatable, Sendable {
        var intent: MatchIntent
        var preferredGenders: [Gender]
        var ageEnabled: Bool
        var ageMin: Int
        var ageMax: Int
        var locationEnabled: Bool
        var searchCity: String
        var maxDistanceKm: Double
    }

    var snapshot: Snapshot {
        get {
            guard let data = defaults.data(forKey: key),
                  let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) else {
                return .default
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: key)
            }
        }
    }
}

extension MatchPrefsStore.Snapshot {
    static let `default` = MatchPrefsStore.Snapshot(
        intent: .romantic,
        preferredGenders: [.woman, .man],
        ageEnabled: false,
        ageMin: 22,
        ageMax: 45,
        locationEnabled: false,
        searchCity: "İstanbul",
        maxDistanceKm: 100
    )
}

/// Deterministic bond story for match detail (no server synastry engine yet).
enum BondStory {
    struct Dimension: Identifiable, Equatable {
        let id: String
        let title: String
        let score: Int
        let blurb: String
    }

    struct Insight: Identifiable, Equatable {
        let id: String
        let title: String
        let detail: String
    }

    struct Snapshot: Identifiable, Equatable {
        let id: String
        let eyebrow: String
        let body: String
    }

    /// Only surfaced for the top two bond ranks — a genuinely rare/karmic
    /// highlight should feel special, not appear on every single match.
    struct RareHighlight: Equatable {
        let badgeTitle: String
        let badgeSubtitle: String
        let heading: String
        let note: String
    }

    struct Report: Equatable {
        let title: String
        let headline: String
        let overall: Int
        let dimensions: [Dimension]
        let aspects: [String]
        /// 1 = strongest/most-favorable read, 5 = most sensitive/complex —
        /// same hierarchy `BondTier` uses, derived from `overall`.
        let rank: Int
        let bondTier: BondTier
        let connectionSummary: String
        let strengths: [Insight]
        let challenges: [Insight]
        let snapshots: [Snapshot]
        let rareHighlight: RareHighlight?
    }

    static func report(
        mySun: ZodiacSign?,
        their: MatchCard,
        intent: MatchIntent,
        myChart: NatalChart? = nil,
        theirChart: NatalChart? = nil
    ) -> Report {
        if let myChart, let theirChart {
            return report(from: CalculateCompatibilityUseCase().execute(chart1: myChart, chart2: theirChart), their: their, intent: intent)
        }
        return hashedReport(mySun: mySun, their: their, intent: intent)
    }

    /// Maps the original 100-point synastry engine onto the Sinastri UI model.
    private static func report(from compatibility: CompatibilityReport, their: MatchCard, intent: MatchIntent) -> Report {
        let overall = compatibility.totalScore
        let rank: Int
        switch overall {
        case 88...: rank = 1
        case 78..<88: rank = 2
        case 68..<78: rank = 3
        case 58..<68: rank = 4
        default: rank = 5
        }
        let dimensions = compatibility.breakdown.filter { $0.maxScore > 0 }.map { cat in
            Dimension(
                id: cat.category.rawValue,
                title: cat.category.rawValue,
                score: Int((cat.percentage * 100).rounded()),
                blurb: cat.description
            )
        }
        let aspects = compatibility.topSynastryAspects.map(\.description)
        let seed = stableSeed(their.id + compatibility.userId1 + intent.rawValue)
        return Report(
            title: compatibility.overallLabel.rawValue,
            headline: "\(their.displayName) ile \(intent.titleTR.lowercased()) bağınızın özeti",
            overall: overall,
            dimensions: dimensions,
            aspects: aspects.isEmpty ? compatibility.strengths : aspects,
            rank: rank,
            bondTier: BondCategory.from(intent: intent).tier(rank: rank),
            connectionSummary: compatibility.overallLabel.description,
            strengths: compatibility.strengths.enumerated().map { Insight(id: "s-\($0.offset)", title: titleFromInsight($0.element), detail: $0.element) },
            challenges: compatibility.challenges.enumerated().map { Insight(id: "c-\($0.offset)", title: titleFromInsight($0.element), detail: $0.element) },
            snapshots: pickSnapshots(seed: seed, count: 4),
            rareHighlight: rank <= 2 ? rareHighlight(rank: rank, mySun: nil, theirSun: their.sunSign) : nil
        )
    }

    private static func titleFromInsight(_ text: String) -> String {
        String(text.split(separator: "—").first ?? Substring(text)).trimmingCharacters(in: .whitespaces)
    }

    private static func hashedReport(mySun: ZodiacSign?, their: MatchCard, intent: MatchIntent) -> Report {
        let seed = stableSeed(their.id + (mySun?.rawValue ?? "x") + intent.rawValue)
        let dims: [(String, String, [String])] = [
            ("Kimya", "chemistry", ["İlk bakışta kıvılcım", "Yavaş ısınan çekim", "Sessiz ama yoğun"]),
            ("İletişim", "talk", ["Aynı dilde konuşuyorsunuz", "Bazen çeviri gerekir", "Derin sohbet potansiyeli"]),
            ("Güven", "trust", ["Stabil zemin", "Dikkatli adımlar", "Açık kalp ister"]),
            ("Büyüme", "grow", ["Birlikte yükselme", "Ayna etkisi", "Öğretici bağ"])
        ]
        var dimensions: [Dimension] = []
        var total = 0
        for (i, d) in dims.enumerated() {
            let score = 55 + Int(seed >> (i * 5) & 0x1F)
            let clamped = min(96, max(52, score))
            total += clamped
            dimensions.append(Dimension(
                id: d.1,
                title: d.0,
                score: clamped,
                blurb: d.2[Int(seed >> (i * 3) & 0x3) % d.2.count]
            ))
        }

        // Unlike the four dimensions above (deterministic-but-arbitrary
        // hashes), this one is a genuine rule-based read: classical
        // astrology's element compatibility wheel, computed from both
        // people's *actual* sun signs when both are known.
        var elementNote: String?
        if let mySun, let theirSun = their.sunSign {
            let (score, blurb) = elementCompatibility(mySun.element, theirSun.element)
            total += score
            dimensions.append(Dimension(
                id: "element",
                title: "Element Uyumu",
                score: score,
                blurb: blurb
            ))
            elementNote = "\(mySun.element.labelTR) (\(mySun.labelTR)) + \(theirSun.element.labelTR) (\(theirSun.labelTR)) → \(blurb.lowercased())"
        }

        let overall = total / dimensions.count
        let title: String
        switch overall {
        case 85...: title = "Kozmik Bağ"
        case 75..<85: title = "Güçlü Rezonans"
        case 65..<75: title = "Uyumlu Çekim"
        default: title = "Keşif Bağı"
        }
        var aspects = [
            "Güneş–Ay gerilim/uyum çizgisi",
            "Venüs teması: \(intent.titleTR.lowercased()) odaklı",
            "Merkür diyaloğu açık",
            their.sunSign.map { "\($0.glyph) \($0.labelTR) vurgusu (yönetici: \($0.rulerTR))" } ?? "Burç vurgusu gizli"
        ]
        if let elementNote { aspects.append(elementNote) }
        var modalityNote: String?
        if let mySun, let theirSun = their.sunSign {
            let note = mySun.modality == theirSun.modality
                ? "İkiniz de \(mySun.modality.labelTR.lowercased()) nitelikte — aynı tempoda hareket ediyorsunuz."
                : "\(mySun.modality.labelTR) ve \(theirSun.modality.labelTR) nitelikler bir arada — biri başlatır, diğeri sürdürür ya da uyarlar."
            modalityNote = note
            aspects.append(note)
        }

        let rank: Int
        switch overall {
        case 88...: rank = 1
        case 78..<88: rank = 2
        case 68..<78: rank = 3
        case 58..<68: rank = 4
        default: rank = 5
        }
        let bondTier = BondCategory.from(intent: intent).tier(rank: rank)

        return Report(
            title: title,
            headline: "\(their.displayName) ile \(intent.titleTR.lowercased()) bağınızın özeti",
            overall: overall,
            dimensions: dimensions,
            aspects: aspects,
            rank: rank,
            bondTier: bondTier,
            connectionSummary: connectionSummary(mySun: mySun, theirSun: their.sunSign, modalityNote: modalityNote),
            strengths: pickInsights(from: strengthBank, seed: seed, count: 3, offset: 0),
            challenges: pickInsights(from: challengeBank, seed: seed, count: 2, offset: 11),
            snapshots: pickSnapshots(seed: seed, count: 4),
            rareHighlight: rank <= 2 ? rareHighlight(rank: rank, mySun: mySun, theirSun: their.sunSign) : nil
        )
    }

    /// "Ruhsal Bağlantı" paragraph — built from the actual element/modality
    /// vocabulary already defined on `ZodiacSign`, not a random pick, so it
    /// reads as a genuine (if simplified) read of the two charts when both
    /// suns are known, and a warmer generic fallback otherwise.
    private static func connectionSummary(mySun: ZodiacSign?, theirSun: ZodiacSign?, modalityNote: String?) -> String {
        guard let mySun, let theirSun else {
            return "Haritalarınız derin duygusal anlayış ve zihinsel uyumla dolu güçlü bir ruh bağı ortaya koyuyor. Birbirinizi sınırların ötesinde, daha iyi bir versiyonunuza doğru büyümeye teşvik ediyorsunuz."
        }
        let mineBlurb = mySun.element.blurbTR
        let theirBlurb = theirSun.element.blurbTR
        let tempo = modalityNote ?? ""
        return "Sen \(mineBlurb) bir enerji taşırken, o \(theirBlurb) bir tempoyla yaklaşıyor. \(tempo) Haritalarınız derin bir anlayışla dolu; birbirinizi sınırların ötesinde, daha iyi bir versiyonunuza doğru büyümeye teşvik ediyorsunuz."
    }

    private static func rareHighlight(rank: Int, mySun: ZodiacSign?, theirSun: ZodiacSign?) -> RareHighlight {
        let signNote: String
        if let mySun, let theirSun {
            signNote = "\(mySun.labelTR) ve \(theirSun.labelTR) arasındaki bu hizalanma sık rastlanan bir şey değil."
        } else {
            signNote = "Bu hizalanma sık rastlanan bir şey değil."
        }
        if rank == 1 {
            return RareHighlight(
                badgeTitle: "Çok Nadir Bir Bağ",
                badgeSubtitle: "En üst düzey · kadersel hizalanma",
                heading: "GÜNEY AY DÜĞÜMÜ BAĞI",
                note: "Geçmiş yaşam aşinalığı ve kadersel bir bağ. \(signNote) Ruhlarınız sanki daha önce karşılaşmış; bu yakınlık tesadüf değil, bir hatırlayış."
            )
        }
        return RareHighlight(
            badgeTitle: "Nadir Bir Bağ",
            badgeSubtitle: "Üst düzey · seyrek görülen uyum",
            heading: "KARMİK YANKI",
            note: "Aranızda tanıdık, neredeyse hatırlanan bir yakınlık var. \(signNote) Bu bağ, üzerinde durmaya değer nadir bağlardan biri."
        )
    }

    private static func pickInsights(from bank: [Insight], seed: UInt64, count: Int, offset: Int) -> [Insight] {
        guard !bank.isEmpty else { return [] }
        var picked: [Insight] = []
        var used: Set<Int> = []
        var i = 0
        while picked.count < count && used.count < bank.count {
            let shifted = (seed >> UInt64((offset + i) % 58)) &+ UInt64(i * 7)
            let idx = Int(shifted % UInt64(bank.count))
            if !used.contains(idx) {
                used.insert(idx)
                picked.append(bank[idx])
            }
            i += 1
        }
        return picked
    }

    private static func pickSnapshots(seed: UInt64, count: Int) -> [Snapshot] {
        guard !snapshotBank.isEmpty else { return [] }
        var picked: [Snapshot] = []
        var used: Set<Int> = []
        var i = 0
        while picked.count < count && used.count < snapshotBank.count {
            let shifted = (seed >> UInt64((30 + i) % 58)) &+ UInt64(i * 13)
            let idx = Int(shifted % UInt64(snapshotBank.count))
            if !used.contains(idx) {
                used.insert(idx)
                picked.append(snapshotBank[idx])
            }
            i += 1
        }
        return picked
    }

    private static let strengthBank: [Insight] = [
        .init(id: "ay-gunes", title: "Ay – Güneş üçgeni", detail: "Duygusal güven ve doğal anlayış; sözsüz bile birbirinizi hissedersiniz."),
        .init(id: "merkur", title: "Merkür kavuşumu", detail: "Aynı dili konuşursunuz; fikirler arasında bitmeyen, akıcı bir sohbet var."),
        .init(id: "venus-mars", title: "Venüs – Mars çekimi", detail: "Güçlü kıvılcım ve karşılıklı arzu; tutku kolayca tutuşur."),
        .init(id: "jupiter", title: "Jüpiter uyumu", detail: "Birlikteyken şanslı hissedersiniz; ufkunuz birlikte genişler."),
        .init(id: "ay-venus", title: "Ay – Venüs sekstili", detail: "Şefkat kolay akar; küçük jestler bile derin anlam taşır."),
        .init(id: "gunes-gunes", title: "Güneş – Güneş uyumu", detail: "Kimlikleriniz birbirini gölgelemek yerine besliyor."),
        .init(id: "merkur-venus", title: "Merkür – Venüs teması", detail: "Nazik ve şakacı bir iletişim biçimini paylaşıyorsunuz."),
        .init(id: "ay-ay", title: "Ay – Ay uyumu", detail: "Duygusal ritimleriniz örtüşüyor; aynı anda sakinleşip aynı anda coşuyorsunuz."),
    ]

    private static let challengeBank: [Insight] = [
        .init(id: "saturn-kare", title: "Satürn karesi", detail: "Sorumluluk ve özgürlük arasında zaman zaman gerilim çıkabilir."),
        .init(id: "sabit-burc", title: "Sabit burç inadı", detail: "İkiniz de geri adım atmakta zorlanır; tartışmalar uzayabilir."),
        .init(id: "mars-saturn", title: "Mars – Satürn sürtünmesi", detail: "Biri hızlı hareket etmek isterken diğeri frenlemek isteyebilir."),
        .init(id: "oncu-burc", title: "İki öncü burç", detail: "İkiniz de başlatmayı sever — kim liderlik edecek, zaman zaman konuşulmalı."),
        .init(id: "degisken", title: "Değişken enerji", detail: "Planlar sık değişebilir; netlik için bilinçli çaba gerekir."),
        .init(id: "uranus", title: "Uranüs teması", detail: "Beklenmedik anlar ilişkiyi hem heyecanlandırır hem dengesizleştirebilir."),
    ]

    private static let snapshotBank: [Snapshot] = [
        .init(id: "ilk-izlenim", eyebrow: "İLK İZLENİM", body: "Tanıştığınız an tanıdık gelir; sanki birbirinizi çoktan biliyormuşsunuz gibi."),
        .init(id: "gunluk-hayat", eyebrow: "GÜNLÜK HAYAT", body: "Rutin asla sıkıcı olmaz — küçük maceralar bulmakta ustasınız."),
        .init(id: "tartisma", eyebrow: "TARTIŞMA", body: "Ateşli başlar ama çabuk geçer; ikiniz de kin tutmazsınız."),
        .init(id: "yakinlik", eyebrow: "YAKINLIK", body: "Fiziksel bağ güçlü; dokunuş sizin için ayrı bir dil."),
        .init(id: "uzun-vade", eyebrow: "UZUN VADE", body: "Birlikte büyüdükçe bağ derinleşir, zamanla daha da güçlenir."),
        .init(id: "sohbet", eyebrow: "SOHBET", body: "Konular hiç tükenmez; saatler dakika gibi geçer."),
        .init(id: "kriz-ani", eyebrow: "KRİZ ANI", body: "Zor bir günde ilk aranacak kişi birbirinizsiniz."),
        .init(id: "hediye", eyebrow: "KÜÇÜK JESTLER", body: "Birbirinizi hatırladığınızı gösteren ufak dokunuşlarla doludur bu bağ."),
    ]

    /// Classical element compatibility: same element resonates, Fire↔Air and
    /// Earth↔Water are the traditionally "easy" complementary pairs, Fire↔Water
    /// and Earth↔Air are the traditionally "friction-prone" pairs, everything
    /// else lands in between. This is a real (if simplified) rule, not a hash.
    private static func elementCompatibility(_ a: ZodiacSign.Element, _ b: ZodiacSign.Element) -> (Int, String) {
        if a == b { return (89, "Aynı element — anında tanıdık gelen bir ritim.") }
        let easy: [Set<ZodiacSign.Element>] = [[.fire, .air], [.earth, .water]]
        let hard: [Set<ZodiacSign.Element>] = [[.fire, .water], [.earth, .air]]
        if easy.contains(Set([a, b])) { return (79, "Doğal olarak besleyen, kolay akan bir eşleşme.") }
        if hard.contains(Set([a, b])) { return (58, "Zıt tempo — dikkatle yönetilirse büyüten bir sürtünme.") }
        return (68, "Nötr — ne çok kolay ne çok zor, öğrenmeye açık.") // fire/earth or air/water
    }

    private static func stableSeed(_ s: String) -> UInt64 {
        var h: UInt64 = 14695981039346656037
        for b in s.utf8 {
            h ^= UInt64(b)
            h &*= 1099511628211
        }
        return h
    }
}

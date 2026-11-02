import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Question categories for the chat "Bir Soru Keşfet" panel.
enum QuestionCategory: String, CaseIterable, Identifiable {
    case love, personal, lifestyle, values, fun, all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .love: return "Aşk & İlişki"
        case .personal: return "Kişisel"
        case .lifestyle: return "Yaşam Tarzı"
        case .values: return "Değerler"
        case .fun: return "Eğlenceli"
        case .all: return "Hepsi"
        }
    }

    var subtitle: String {
        switch self {
        case .love: return "Duygular, bağ, romantizm"
        case .personal: return "Kendini tanıma, hayata bakış"
        case .lifestyle: return "Günlük yaşam, alışkanlıklar"
        case .values: return "İnançlar, öncelikler"
        case .fun: return "Hafif ve keyifli sorular"
        case .all: return "Sürpriz soru"
        }
    }

    var icon: String {
        switch self {
        case .love: return "heart"
        case .personal: return "moon"
        case .lifestyle: return "sun.max"
        case .values: return "leaf"
        case .fun: return "globe.europe.africa"
        case .all: return "sparkle"
        }
    }
}

/// Pre-loaded, hand-written question bank (instant, offline, moderated).
enum ConversationQuestions {
    static let bank: [QuestionCategory: [String]] = [
        .love: [
            "Bir ilişkide kendini en çok ne zaman güvende hissedersin?",
            "Sence aşkta en önemli şey nedir: tutku mu, güven mi?",
            "İlk buluşmada seni en çok ne etkiler?",
            "Sevgini en çok nasıl gösterirsin?",
            "Bir ilişkide asla taviz vermeyeceğin şey ne?",
            "İlk bakışta aşka inanır mısın?",
            "Romantik bir akşam senin için nasıl geçer?",
            "Bir ilişkide en çok neyi özlersin: ilgiyi mi, zamanı mı?",
            "Hayatındaki en güzel sürpriz ne oldu?",
            "Kıskançlık sende nasıl görünür?",
            "Birini gerçekten tanımak için sence ne kadar zaman gerekir?",
            "Aşkta ilk adımı atan taraf olmak sana nasıl hissettirir?"
        ],
        .personal: [
            "Seni en iyi anlatan üç kelime ne olurdu?",
            "Son zamanlarda kendinle ilgili öğrendiğin bir şey ne?",
            "Zor bir günde seni ne toparlar?",
            "Geçmişteki kendine ne söylemek isterdin?",
            "Seni en çok ne korkutur, en çok ne cesaretlendirir?",
            "Yalnız kalmak sana iyi gelir mi, yoksa yorar mı?",
            "Hayatında dönüm noktası dediğin an hangisiydi?",
            "Başkalarının seni yanlış anladığı yön ne?",
            "Kendinle gurur duyduğun son an neydi?",
            "Beş yıl sonra kendini nerede görüyorsun?",
            "Hangi huyunu değiştirmek isterdin?",
            "Seni en çok ne düşündürür?"
        ],
        .lifestyle: [
            "Mükemmel bir hafta sonu senin için nasıl geçer?",
            "Sabah insanı mısın, gece kuşu mu?",
            "Evde mi, dışarıda mı daha mutlusun?",
            "Günün en sevdiğin saati hangisi?",
            "Vazgeçemediğin bir alışkanlığın var mı?",
            "Tatilde plan mı yaparsın, akışa mı bırakırsın?",
            "Yemek yapmayı sever misin? En iyi yaptığın yemek ne?",
            "Müzik açmadan yola çıkabilir misin?",
            "Son izlediğin ve etkilendiğin film ya da dizi neydi?",
            "Doğada vakit geçirmek senin için ne ifade eder?",
            "Hayalindeki ev nasıl bir yer?",
            "Haftanın en sevdiğin günü hangisi, neden?"
        ],
        .values: [
            "Hayatta senin için vazgeçilmez olan değer nedir?",
            "Dürüstlük mü, nezaket mi? Biri seçilmek zorunda kalsa?",
            "Sence insanı insan yapan şey ne?",
            "Aile senin için ne kadar önemli?",
            "Para mı, zaman mı daha değerli?",
            "Bir arkadaşlıkta en çok neye değer verirsin?",
            "Affetmek sence güç müdür, zayıflık mı?",
            "Hayatta pişman olmamak için ne yaparsın?",
            "Sana göre başarı nedir?",
            "Kaderin varlığına inanır mısın?",
            "Bir insanda gördüğün anda uzaklaştıran şey ne?",
            "Başkaları için yaptığın en anlamlı şey neydi?"
        ],
        .fun: [
            "Bir süper gücün olsa hangisini seçerdin?",
            "Dünyanın herhangi bir yerinde bir hafta geçirebilsen nereye giderdin?",
            "Tarihten biriyle yemek yeseydin kim olurdu?",
            "Seni en çok güldüren şey nedir?",
            "Hayvan olsaydın hangisi olurdun?",
            "Ücretsiz sınırsız bir şey yiyebilseydin ne olurdu?",
            "Çocukken en sevdiğin çizgi film hangisiydi?",
            "Sadece bir şarkıyla yaşasan hangisi olurdu?",
            "En komik utanç anın ne?",
            "Burcunun sana en çok uyan özelliği hangisi?",
            "Yarın tatil ilan edilse ilk ne yaparsın?",
            "Bir günlüğüne başka biri olsan kim olurdun?"
        ]
    ]

    /// Fresh question from the on-device model, or the bank when the model is
    /// unavailable (older/unsupported phone, Turkish unsupported), too slow
    /// (>6s) or returns something unusable.
    static func next(in category: QuestionCategory, excluding: String? = nil) async -> String {
        let generated: String? = await withTaskGroup(of: String?.self) { group in
            group.addTask { await generate(in: category) }
            group.addTask {
                try? await Task.sleep(nanoseconds: 6_000_000_000)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
        if let generated, generated != excluding { return generated }
        return random(in: category, excluding: excluding)
    }

    private static func generate(in category: QuestionCategory) async -> String? {
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, *) else { return nil }
        let model = SystemLanguageModel.default
        guard case .available = model.availability,
              model.supportsLocale(Locale(identifier: "tr_TR")) else { return nil }
        let topic = category == .all
            ? "aşk, kişisel gelişim, yaşam tarzı, değerler ya da eğlence"
            : "\(category.title) (\(category.subtitle))"
        let session = LanguageModelSession(instructions: """
            Sen bir tanışma uygulaması için sohbet açıcı sorular yazıyorsun. \
            Yalnızca Türkçe yaz. Tek bir soru yaz, en fazla 16 kelime, "?" ile bitsin. \
            Samimi, düşündürücü ve saygılı olsun. Cinsel, müstehcen, siyasi ya da \
            kırıcı içerik yazma. Açıklama, numara veya tırnak işareti ekleme.
            """)
        let seed = Int.random(in: 1...9999)
        guard let out = try? await session.respond(
            to: "Konu: \(topic). Daha önce hiç sorulmamış özgün bir soru yaz. (#\(seed))"
        ) else { return nil }
        let text = out.content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"“”'"))
        guard text.hasSuffix("?"), text.count >= 12, text.count <= 140,
              !text.contains("\n") else { return nil }
        return text
        #else
        return nil
        #endif
    }

    /// A random question from the category (never the same as `excluding`).
    static func random(in category: QuestionCategory, excluding: String? = nil) -> String {
        let pool: [String]
        if category == .all {
            pool = bank.values.flatMap { $0 }
        } else {
            pool = bank[category] ?? []
        }
        let options = pool.filter { $0 != excluding }
        return options.randomElement() ?? pool.first ?? ""
    }
}

/// Client-side daily limit for the question panel. Showing a question —
/// opening a category or tapping "Başka Soru Göster" — uses one right.
/// Unused rights do not carry over (the key is per calendar day).
@MainActor
final class DailyQuestionQuotaStore {
    static let shared = DailyQuestionQuotaStore()
    static let dailyLimit = 23

    private let defaults = UserDefaults.standard

    private func key(for userId: String) -> String {
        let day = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        return "wv.question.count.\(userId).\(Int(day))"
    }

    func used(for userId: String) -> Int { defaults.integer(forKey: key(for: userId)) }

    func remaining(for userId: String) -> Int {
        max(0, Self.dailyLimit - used(for: userId))
    }

    /// Spends one right. Returns false when none are left.
    @discardableResult
    func consume(for userId: String) -> Bool {
        guard remaining(for: userId) > 0 else { return false }
        defaults.set(used(for: userId) + 1, forKey: key(for: userId))
        return true
    }
}

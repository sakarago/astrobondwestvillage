import Foundation

// BondTier.swift
// Bağ terminolojisi — insanları sayısal yüzde yerine, niyete göre HİYERARŞİK
// bir "bağ" adıyla tanımlıyoruz (ör. "Mirror Soul" / "Ayna Ruh"). Ekranda
// bağın İngilizce adı görünür; dokununca Türkçe adı + açıklaması açılır.
// Ported from the original AstroBond app's bond-tier system so the West
// Village synastry screen carries the same "no bare numbers, always a named
// tier" feel, instead of just a percentage ring.

/// A match's intent category. Each category carries a 5-level hierarchy
/// (rank 1 = strongest/most-favorable read, rank 5 = most sensitive/complex).
enum BondCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case romantic
    case friendship
    case business
    case sex

    var id: String { rawValue }

    var turkish: String {
        switch self {
        case .romantic: return "Romantik Bağ"
        case .friendship: return "Arkadaşlık Bağı"
        case .business: return "İş & Ortaklık"
        case .sex: return "Tensel & Çekim"
        }
    }

    var tiers: [BondTier] {
        switch self {
        case .romantic:
            return [
                BondTier(category: self, rank: 1, english: "Cosmic Anchor", turkish: "Kozmik Çıpa",
                         summary: "Fırtınalı zamanlarda bile birbirini sakinleştiren, sarsılmaz bir güven ve ev hissi veren en üst düzey bağ."),
                BondTier(category: self, rank: 2, english: "Electric Echo", turkish: "Elektrik Yankısı",
                         summary: "İlk andan itibaren yüksek çekim ve yoğun tutku barındıran, adeta birbirinin zihnini okuyan dinamik ilişki."),
                BondTier(category: self, rank: 3, english: "Mirror Soul", turkish: "Ayna Ruh",
                         summary: "Kişinin kendi eksiklerini ve potansiyelini partnerinde gördüğü, yoğun kişisel dönüşüm sağlayan derin bağ."),
                BondTier(category: self, rank: 4, english: "Soft Velvet", turkish: "Yumuşak Kadife",
                         summary: "Çatışmasız, huzurlu, tarafları yormayan ama zamanla köklenen şefkat dolu ilişki seviyesi."),
                BondTier(category: self, rank: 5, english: "Crossroads", turkish: "Yol Ayrımı",
                         summary: "Çekimin çok güçlü olduğu ancak tarafların hayattaki amaçlarının sürekli çatıştığı karmaşık bağ."),
            ]
        case .friendship:
            return [
                BondTier(category: self, rank: 1, english: "Forever Anchor", turkish: "Ebedi Çıpa",
                         summary: "Yıllarca konuşulmasa bile kalındığı yerden devam edilen, ömür boyu süren o sarsılmaz dostluk."),
                BondTier(category: self, rank: 2, english: "Vibe Twin", turkish: "Frekans İkizi",
                         summary: "Espri anlayışından hayata bakışa kadar her konuda aynı dalga boyunda olan, yan yana aşırı eğlenen ikililer."),
                BondTier(category: self, rank: 3, english: "Safe Harbor", turkish: "Güvenli Liman",
                         summary: "Yanında hiçbir maske takmaya gerek olmayan, yargılanma korkusu sıfır olan korunaklı arkadaşlık seviyesi."),
                BondTier(category: self, rank: 4, english: "Catalyst", turkish: "Katalizör",
                         summary: "Birbirini sürekli yeni projelere, hobilere veya kişisel gelişime teşvik eden, vizyon açıcı dinamik dostluk."),
                BondTier(category: self, rank: 5, english: "Low-Key", turkish: "Sakin Akış",
                         summary: "Büyük dramalar veya sürekli iletişim gerektirmeyen, yan yana sessizce otururken bile huzur veren bağ."),
            ]
        case .business:
            return [
                BondTier(category: self, rank: 1, english: "Empire Builders", turkish: "İmparatorluk Kuranlar",
                         summary: "Vizyon ve stratejinin mükemmel birleştiği, sıfırdan devasa projeler üretebilecek en üst düzey iş bağı."),
                BondTier(category: self, rank: 2, english: "Catalyst Duo", turkish: "Katalizör İkili",
                         summary: "Birlikte çalışırken üretkenliği, yaratıcılığı ve motivasyonu anında ikiye katlayan, birbirini ateşleyen ortaklık."),
                BondTier(category: self, rank: 3, english: "Safe Ledger", turkish: "Güvenli Muhasebe",
                         summary: "Risklerin minimum olduğu, finansal konularda tam güven sağlayan, risksiz ve sağlam adımlarla ilerleyen bağ."),
                BondTier(category: self, rank: 4, english: "Friction Grid", turkish: "Sürtünme Ağı",
                         summary: "Ego çatışmalarının ve fikir ayrılıklarının yüksek olduğu, profesyonel kalmakta zorlanılan karmaşık iş ilişkisi."),
                BondTier(category: self, rank: 5, english: "Ghost Shift", turkish: "Hayalet Vardiya",
                         summary: "İletişim kopukluklarının yoğun olduğu, hedeflerin uyuşmadığı ve birlikte verim almanın çok zor olduğu bağ."),
            ]
        case .sex:
            return [
                BondTier(category: self, rank: 1, english: "Gravity Pull", turkish: "Yerçekimi Kuvveti",
                         summary: "Mantığın tamamen devre dışı kaldığı, karşı konulamaz ve çok nadir görülen en yoğun tensel çekim seviyesi."),
                BondTier(category: self, rank: 2, english: "Electric Current", turkish: "Elektrik Akımı",
                         summary: "İlk dokunuştan itibaren havada kıvılcımlar uçuran, yüksek enerjili ve flörtöz yönü çok güçlü olan bağ."),
                BondTier(category: self, rank: 3, english: "Slow Burn", turkish: "Köz",
                         summary: "Zamanla, tanıdıkça ve aradaki güven arttıkça derinleşen, kalıcı ve tatmin edici fiziksel uyum."),
                BondTier(category: self, rank: 4, english: "Wildfire", turkish: "Yaban Yangını",
                         summary: "Çok hızlı ve tutkulu başlayan ancak saman alevi gibi çabuk sönme veya tarafları duygusal olarak yıpratma riski taşıyan bağ."),
                BondTier(category: self, rank: 5, english: "Muted Pulse", turkish: "Kısık Nabız",
                         summary: "Arkadaşlık veya iş bağı çok güçlü olsa da aradaki fiziksel çekimin ve tensel enerjinin düşük kaldığı durumlar."),
            ]
        }
    }

    func tier(rank: Int) -> BondTier {
        tiers.first { $0.rank == rank } ?? tiers[0]
    }

    /// Maps this app's four match intents onto the closest bond category —
    /// there's no separate "sex" intent in `MatchIntent`, so a strong
    /// romantic-intent read with a high element/attraction score is the
    /// closest existing signal for it (surfaced via the SEX BOND icon on the
    /// synastry screen, not as its own top-level category).
    static func from(intent: MatchIntent) -> BondCategory {
        switch intent {
        case .romantic: return .romantic
        case .relationship: return .romantic
        case .business: return .business
        case .friends: return .friendship
        }
    }
}

/// A single level within a bond category's hierarchy.
struct BondTier: Identifiable, Equatable, Hashable, Codable, Sendable {
    let category: BondCategory
    let rank: Int
    let english: String
    let turkish: String
    let summary: String

    var id: String { "\(category.rawValue)-\(rank)" }

    /// Short, word-based tagline shown instead of a bare number.
    var tierTagline: String {
        switch rank {
        case 1: return "En üst düzey bağ"
        case 2: return "Çok güçlü bağ"
        case 3: return "Dengeli bağ"
        case 4: return "Karmaşık bağ"
        default: return "Hassas bağ"
        }
    }
}

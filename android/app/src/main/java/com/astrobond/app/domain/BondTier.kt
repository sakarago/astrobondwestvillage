package com.astrobond.app.domain

/** Port of Domain/BondTier.swift. */
enum class BondCategory(val wire: String, val turkish: String) {
    ROMANTIC("romantic", "Romantik Bağ"), FRIENDSHIP("friendship", "Arkadaşlık Bağı"),
    BUSINESS("business", "İş & Ortaklık"), SEX("sex", "Tensel & Çekim");

    val tiers: List<BondTier> get() = TIERS.getValue(this)
    fun tier(rank: Int) = tiers.firstOrNull { it.rank == rank } ?: tiers[0]

    companion object {
        fun from(intent: MatchIntent) = when (intent) {
            MatchIntent.ROMANTIC, MatchIntent.RELATIONSHIP -> ROMANTIC
            MatchIntent.BUSINESS -> BUSINESS
            MatchIntent.FRIENDS -> FRIENDSHIP
        }
    }
}

data class BondTier(val category: BondCategory, val rank: Int, val english: String, val turkish: String, val summary: String) {
    val tagline: String get() = when (rank) {
        1 -> "En üst düzey bağ"; 2 -> "Çok güçlü bağ"; 3 -> "Dengeli bağ"; 4 -> "Karmaşık bağ"; else -> "Hassas bağ"
    }
}

private fun t(c: BondCategory, r: Int, en: String, tr: String, s: String) = BondTier(c, r, en, tr, s)

private val TIERS: Map<BondCategory, List<BondTier>> = mapOf(
    BondCategory.ROMANTIC to listOf(
        t(BondCategory.ROMANTIC, 1, "Cosmic Anchor", "Kozmik Çıpa",
            "Fırtınalı zamanlarda bile birbirini sakinleştiren, sarsılmaz bir güven ve ev hissi veren en üst düzey bağ."),
        t(BondCategory.ROMANTIC, 2, "Electric Echo", "Elektrik Yankısı",
            "İlk andan itibaren yüksek çekim ve yoğun tutku barındıran, adeta birbirinin zihnini okuyan dinamik ilişki."),
        t(BondCategory.ROMANTIC, 3, "Mirror Soul", "Ayna Ruh",
            "Kişinin kendi eksiklerini ve potansiyelini partnerinde gördüğü, yoğun kişisel dönüşüm sağlayan derin bağ."),
        t(BondCategory.ROMANTIC, 4, "Soft Velvet", "Yumuşak Kadife",
            "Çatışmasız, huzurlu, tarafları yormayan ama zamanla köklenen şefkat dolu ilişki seviyesi."),
        t(BondCategory.ROMANTIC, 5, "Crossroads", "Yol Ayrımı",
            "Çekimin çok güçlü olduğu ancak tarafların hayattaki amaçlarının sürekli çatıştığı karmaşık bağ."),
    ),
    BondCategory.FRIENDSHIP to listOf(
        t(BondCategory.FRIENDSHIP, 1, "Forever Anchor", "Ebedi Çıpa",
            "Yıllarca konuşulmasa bile kalındığı yerden devam edilen, ömür boyu süren o sarsılmaz dostluk."),
        t(BondCategory.FRIENDSHIP, 2, "Vibe Twin", "Frekans İkizi",
            "Espri anlayışından hayata bakışa kadar her konuda aynı dalga boyunda olan, yan yana aşırı eğlenen ikililer."),
        t(BondCategory.FRIENDSHIP, 3, "Safe Harbor", "Güvenli Liman",
            "Yanında hiçbir maske takmaya gerek olmayan, yargılanma korkusu sıfır olan korunaklı arkadaşlık seviyesi."),
        t(BondCategory.FRIENDSHIP, 4, "Catalyst", "Katalizör",
            "Birbirini sürekli yeni projelere, hobilere veya kişisel gelişime teşvik eden, vizyon açıcı dinamik dostluk."),
        t(BondCategory.FRIENDSHIP, 5, "Low-Key", "Sakin Akış",
            "Büyük dramalar veya sürekli iletişim gerektirmeyen, yan yana sessizce otururken bile huzur veren bağ."),
    ),
    BondCategory.BUSINESS to listOf(
        t(BondCategory.BUSINESS, 1, "Empire Builders", "İmparatorluk Kuranlar",
            "Vizyon ve stratejinin mükemmel birleştiği, sıfırdan devasa projeler üretebilecek en üst düzey iş bağı."),
        t(BondCategory.BUSINESS, 2, "Catalyst Duo", "Katalizör İkili",
            "Birlikte çalışırken üretkenliği, yaratıcılığı ve motivasyonu anında ikiye katlayan, birbirini ateşleyen ortaklık."),
        t(BondCategory.BUSINESS, 3, "Safe Ledger", "Güvenli Muhasebe",
            "Risklerin minimum olduğu, finansal konularda tam güven sağlayan, risksiz ve sağlam adımlarla ilerleyen bağ."),
        t(BondCategory.BUSINESS, 4, "Friction Grid", "Sürtünme Ağı",
            "Ego çatışmalarının ve fikir ayrılıklarının yüksek olduğu, profesyonel kalmakta zorlanılan karmaşık iş ilişkisi."),
        t(BondCategory.BUSINESS, 5, "Ghost Shift", "Hayalet Vardiya",
            "İletişim kopukluklarının yoğun olduğu, hedeflerin uyuşmadığı ve birlikte verim almanın çok zor olduğu bağ."),
    ),
    BondCategory.SEX to listOf(
        t(BondCategory.SEX, 1, "Gravity Pull", "Yerçekimi Kuvveti",
            "Mantığın tamamen devre dışı kaldığı, karşı konulamaz ve çok nadir görülen en yoğun tensel çekim seviyesi."),
        t(BondCategory.SEX, 2, "Electric Current", "Elektrik Akımı",
            "İlk dokunuştan itibaren havada kıvılcımlar uçuran, yüksek enerjili ve flörtöz yönü çok güçlü olan bağ."),
        t(BondCategory.SEX, 3, "Slow Burn", "Köz",
            "Zamanla, tanıdıkça ve aradaki güven arttıkça derinleşen, kalıcı ve tatmin edici fiziksel uyum."),
        t(BondCategory.SEX, 4, "Wildfire", "Yaban Yangını",
            "Çok hızlı ve tutkulu başlayan ancak saman alevi gibi çabuk sönme veya tarafları duygusal olarak yıpratma riski taşıyan bağ."),
        t(BondCategory.SEX, 5, "Muted Pulse", "Kısık Nabız",
            "Arkadaşlık veya iş bağı çok güçlü olsa da aradaki fiziksel çekimin ve tensel enerjinin düşük kaldığı durumlar."),
    ),
)

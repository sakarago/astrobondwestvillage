package com.astrobond.app.domain

enum class MatchIntent(val wire: String, val titleTR: String, val subtitle: String, val bondLabel: String) {
    ROMANTIC("romantic", "Romantik", "Çekim & bağ", "RomanticBond"),
    RELATIONSHIP("relationship", "İlişki", "Uzun vadeli", "SexBond"),
    BUSINESS("business", "İş", "Ortaklık", "BusinessBond"),
    FRIENDS("friends", "Arkadaş", "Dostluk", "FriendBond");

    companion object { fun fromWire(s: String?) = entries.firstOrNull { it.wire == s } ?: ROMANTIC }
}

data class MatchCard(
    val id: String, val displayName: String, val age: Int, val city: String?, val sunSign: ZodiacSign?,
    val moonSign: ZodiacSign?, val risingSign: ZodiacSign?, val bio: String, val photoURL: String?, val cartoonAvatarId: String?,
)

data class MatchPrefs(
    val intent: MatchIntent = MatchIntent.ROMANTIC,
    val preferredGenders: List<Gender> = listOf(Gender.WOMAN, Gender.MAN),
    val ageEnabled: Boolean = false, val ageMin: Int = 22, val ageMax: Int = 45,
    val locationEnabled: Boolean = false, val searchCity: String = "İstanbul", val maxDistanceKm: Double = 100.0,
)

/** Port of BondStory (Infrastructure/Match/MatchPrefsStore.swift): deterministic bond report for a match. */
object BondStory {
    data class Dimension(val id: String, val title: String, val score: Int, val blurb: String)
    data class Insight(val id: String, val title: String, val detail: String)
    data class Snapshot(val id: String, val eyebrow: String, val body: String)
    data class RareHighlight(val badgeTitle: String, val badgeSubtitle: String, val heading: String, val note: String)
    data class Report(
        val title: String, val headline: String, val overall: Int, val dimensions: List<Dimension>, val aspects: List<String>,
        val rank: Int, val bondTier: BondTier, val connectionSummary: String, val strengths: List<Insight>,
        val challenges: List<Insight>, val snapshots: List<Snapshot>, val rareHighlight: RareHighlight?,
    )

    fun report(mySun: ZodiacSign?, their: MatchCard, intent: MatchIntent, myChart: NatalChart? = null, theirChart: NatalChart? = null): Report =
        if (myChart != null && theirChart != null) fromCompat(CompatibilityEngine.execute(myChart, theirChart), their, intent)
        else hashed(mySun, their, intent)

    private fun rankOf(o: Int) = when { o >= 88 -> 1; o >= 78 -> 2; o >= 68 -> 3; o >= 58 -> 4; else -> 5 }

    private fun fromCompat(c: CompatibilityReport, their: MatchCard, intent: MatchIntent): Report {
        val overall = c.totalScore
        val rank = rankOf(overall)
        val dims = c.breakdown.filter { it.maxScore > 0 }.map { Dimension(it.category.tr, it.category.tr, Math.round(it.percentage * 100).toInt(), it.description) }
        val aspects = c.topSynastryAspects.map { it.description }
        val seed = stableSeed(their.id + c.userId1 + intent.wire)
        return Report(
            c.overallLabel.tr, "${their.displayName} ile ${intent.titleTR.lowercase()} bağınızın özeti", overall, dims,
            aspects.ifEmpty { c.strengths }, rank, BondCategory.from(intent).tier(rank), c.overallLabel.description,
            c.strengths.mapIndexed { i, s -> Insight("s-$i", titleOf(s), s) },
            c.challenges.mapIndexed { i, s -> Insight("c-$i", titleOf(s), s) },
            pickSnapshots(seed, 4), if (rank <= 2) rare(rank, null, their.sunSign) else null,
        )
    }

    private fun titleOf(t: String) = t.split("—").first().trim()

    private fun hashed(mySun: ZodiacSign?, their: MatchCard, intent: MatchIntent): Report {
        val seed = stableSeed(their.id + (mySun?.wire ?: "x") + intent.wire)
        val dims = listOf(
            Triple("Kimya", "chemistry", listOf("İlk bakışta kıvılcım", "Yavaş ısınan çekim", "Sessiz ama yoğun")),
            Triple("İletişim", "talk", listOf("Aynı dilde konuşuyorsunuz", "Bazen çeviri gerekir", "Derin sohbet potansiyeli")),
            Triple("Güven", "trust", listOf("Stabil zemin", "Dikkatli adımlar", "Açık kalp ister")),
            Triple("Büyüme", "grow", listOf("Birlikte yükselme", "Ayna etkisi", "Öğretici bağ")),
        )
        val out = mutableListOf<Dimension>()
        var total = 0
        dims.forEachIndexed { i, d ->
            val score = 55 + (((seed shr (i * 5)) and 0x1FUL).toInt())
            val cl = minOf(96, maxOf(52, score))
            total += cl
            out += Dimension(d.second, d.first, cl, d.third[(((seed shr (i * 3)) and 0x3UL).toInt()) % d.third.size])
        }
        var elementNote: String? = null
        val theirSun = their.sunSign
        if (mySun != null && theirSun != null) {
            val (score, blurb) = elementCompat(mySun.element, theirSun.element)
            total += score
            out += Dimension("element", "Element Uyumu", score, blurb)
            elementNote = "${mySun.element.labelTR} (${mySun.labelTR}) + ${theirSun.element.labelTR} (${theirSun.labelTR}) → ${blurb.lowercase()}"
        }
        val overall = total / out.size
        val title = when { overall >= 85 -> "Kozmik Bağ"; overall >= 75 -> "Güçlü Rezonans"; overall >= 65 -> "Uyumlu Çekim"; else -> "Keşif Bağı" }
        val aspects = mutableListOf(
            "Güneş–Ay gerilim/uyum çizgisi", "Venüs teması: ${intent.titleTR.lowercase()} odaklı", "Merkür diyaloğu açık",
            theirSun?.let { "${it.glyph} ${it.labelTR} vurgusu (yönetici: ${it.rulerTR})" } ?: "Burç vurgusu gizli",
        )
        elementNote?.let { aspects += it }
        var modalityNote: String? = null
        if (mySun != null && theirSun != null) {
            modalityNote = if (mySun.modality == theirSun.modality)
                "İkiniz de ${mySun.modality.labelTR.lowercase()} nitelikte — aynı tempoda hareket ediyorsunuz."
            else "${mySun.modality.labelTR} ve ${theirSun.modality.labelTR} nitelikler bir arada — biri başlatır, diğeri sürdürür ya da uyarlar."
            aspects += modalityNote
        }
        val rank = rankOf(overall)
        return Report(
            title, "${their.displayName} ile ${intent.titleTR.lowercase()} bağınızın özeti", overall, out, aspects, rank,
            BondCategory.from(intent).tier(rank), connection(mySun, theirSun, modalityNote),
            pickInsights(STRENGTHS, seed, 3, 0), pickInsights(CHALLENGES, seed, 2, 11), pickSnapshots(seed, 4),
            if (rank <= 2) rare(rank, mySun, theirSun) else null,
        )
    }

    private fun connection(my: ZodiacSign?, th: ZodiacSign?, mod: String?): String {
        if (my == null || th == null)
            return "Haritalarınız derin duygusal anlayış ve zihinsel uyumla dolu güçlü bir ruh bağı ortaya koyuyor. Birbirinizi sınırların ötesinde, daha iyi bir versiyonunuza doğru büyümeye teşvik ediyorsunuz."
        return "Sen ${my.element.blurbTR} bir enerji taşırken, o ${th.element.blurbTR} bir tempoyla yaklaşıyor. ${mod ?: ""} Haritalarınız derin bir anlayışla dolu; birbirinizi sınırların ötesinde, daha iyi bir versiyonunuza doğru büyümeye teşvik ediyorsunuz."
    }

    private fun rare(rank: Int, my: ZodiacSign?, th: ZodiacSign?): RareHighlight {
        val sign = if (my != null && th != null) "${my.labelTR} ve ${th.labelTR} arasındaki bu hizalanma sık rastlanan bir şey değil." else "Bu hizalanma sık rastlanan bir şey değil."
        return if (rank == 1) RareHighlight("Çok Nadir Bir Bağ", "En üst düzey · kadersel hizalanma", "GÜNEY AY DÜĞÜMÜ BAĞI",
            "Geçmiş yaşam aşinalığı ve kadersel bir bağ. $sign Ruhlarınız sanki daha önce karşılaşmış; bu yakınlık tesadüf değil, bir hatırlayış.")
        else RareHighlight("Nadir Bir Bağ", "Üst düzey · seyrek görülen uyum", "KARMİK YANKI",
            "Aranızda tanıdık, neredeyse hatırlanan bir yakınlık var. $sign Bu bağ, üzerinde durmaya değer nadir bağlardan biri.")
    }

    private fun <T> pick(bank: List<T>, seed: ULong, count: Int, offset: Int, mul: Int, shift: (Int) -> Int): List<T> {
        if (bank.isEmpty()) return emptyList()
        val picked = mutableListOf<T>(); val used = mutableSetOf<Int>()
        var i = 0
        while (picked.size < count && used.size < bank.size) {
            val shifted = (seed shr shift(i)) + (i * mul).toULong()
            val idx = (shifted % bank.size.toULong()).toInt()
            if (used.add(idx)) picked += bank[idx]
            i++
        }
        return picked
    }

    private fun pickInsights(bank: List<Insight>, seed: ULong, count: Int, offset: Int) = pick(bank, seed, count, offset, 7) { (offset + it) % 58 }
    private fun pickSnapshots(seed: ULong, count: Int) = pick(SNAPSHOTS, seed, count, 30, 13) { (30 + it) % 58 }

    private fun elementCompat(a: Element, b: Element): Pair<Int, String> {
        if (a == b) return 89 to "Aynı element — anında tanıdık gelen bir ritim."
        val pair = setOf(a, b)
        return when {
            pair == setOf(Element.FIRE, Element.AIR) || pair == setOf(Element.EARTH, Element.WATER) -> 79 to "Doğal olarak besleyen, kolay akan bir eşleşme."
            pair == setOf(Element.FIRE, Element.WATER) || pair == setOf(Element.EARTH, Element.AIR) -> 58 to "Zıt tempo — dikkatle yönetilirse büyüten bir sürtünme."
            else -> 68 to "Nötr — ne çok kolay ne çok zor, öğrenmeye açık."
        }
    }

    /** FNV-1a 64, same as iOS `stableSeed`. */
    fun stableSeed(s: String): ULong {
        var h = 14695981039346656037UL
        for (b in s.toByteArray(Charsets.UTF_8)) { h = h xor b.toUByte().toULong(); h *= 1099511628211UL }
        return h
    }

    private val STRENGTHS = listOf(
        Insight("ay-gunes", "Ay – Güneş üçgeni", "Duygusal güven ve doğal anlayış; sözsüz bile birbirinizi hissedersiniz."),
        Insight("merkur", "Merkür kavuşumu", "Aynı dili konuşursunuz; fikirler arasında bitmeyen, akıcı bir sohbet var."),
        Insight("venus-mars", "Venüs – Mars çekimi", "Güçlü kıvılcım ve karşılıklı arzu; tutku kolayca tutuşur."),
        Insight("jupiter", "Jüpiter uyumu", "Birlikteyken şanslı hissedersiniz; ufkunuz birlikte genişler."),
        Insight("ay-venus", "Ay – Venüs sekstili", "Şefkat kolay akar; küçük jestler bile derin anlam taşır."),
        Insight("gunes-gunes", "Güneş – Güneş uyumu", "Kimlikleriniz birbirini gölgelemek yerine besliyor."),
        Insight("merkur-venus", "Merkür – Venüs teması", "Nazik ve şakacı bir iletişim biçimini paylaşıyorsunuz."),
        Insight("ay-ay", "Ay – Ay uyumu", "Duygusal ritimleriniz örtüşüyor; aynı anda sakinleşip aynı anda coşuyorsunuz."),
    )
    private val CHALLENGES = listOf(
        Insight("saturn-kare", "Satürn karesi", "Sorumluluk ve özgürlük arasında zaman zaman gerilim çıkabilir."),
        Insight("sabit-burc", "Sabit burç inadı", "İkiniz de geri adım atmakta zorlanır; tartışmalar uzayabilir."),
        Insight("mars-saturn", "Mars – Satürn sürtünmesi", "Biri hızlı hareket etmek isterken diğeri frenlemek isteyebilir."),
        Insight("oncu-burc", "İki öncü burç", "İkiniz de başlatmayı sever — kim liderlik edecek, zaman zaman konuşulmalı."),
        Insight("degisken", "Değişken enerji", "Planlar sık değişebilir; netlik için bilinçli çaba gerekir."),
        Insight("uranus", "Uranüs teması", "Beklenmedik anlar ilişkiyi hem heyecanlandırır hem dengesizleştirebilir."),
    )
    private val SNAPSHOTS = listOf(
        Snapshot("ilk-izlenim", "İLK İZLENİM", "Tanıştığınız an tanıdık gelir; sanki birbirinizi çoktan biliyormuşsunuz gibi."),
        Snapshot("gunluk-hayat", "GÜNLÜK HAYAT", "Rutin asla sıkıcı olmaz — küçük maceralar bulmakta ustasınız."),
        Snapshot("tartisma", "TARTIŞMA", "Ateşli başlar ama çabuk geçer; ikiniz de kin tutmazsınız."),
        Snapshot("yakinlik", "YAKINLIK", "Fiziksel bağ güçlü; dokunuş sizin için ayrı bir dil."),
        Snapshot("uzun-vade", "UZUN VADE", "Birlikte büyüdükçe bağ derinleşir, zamanla daha da güçlenir."),
        Snapshot("sohbet", "SOHBET", "Konular hiç tükenmez; saatler dakika gibi geçer."),
        Snapshot("kriz-ani", "KRİZ ANI", "Zor bir günde ilk aranacak kişi birbirinizsiniz."),
        Snapshot("hediye", "KÜÇÜK JESTLER", "Birbirinizi hatırladığınızı gösteren ufak dokunuşlarla doludur bu bağ."),
    )
}

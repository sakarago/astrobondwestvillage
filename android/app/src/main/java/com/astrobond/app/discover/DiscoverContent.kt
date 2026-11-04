package com.astrobond.app.discover

import com.astrobond.app.domain.Element
import com.astrobond.app.domain.ZodiacSign
import java.time.LocalDate
import java.time.format.TextStyle
import java.util.Locale

private val TR = Locale("tr", "TR")
private fun lower(s: String) = s.lowercase(TR)
private fun upper(s: String) = s.uppercase(TR)
private fun capitalizeWords(s: String) = s.split(" ").joinToString(" ") { w -> w.replaceFirstChar { it.titlecase(TR) } }

/** FNV-1a 64 — identical to iOS `stableHash`. */
internal fun fnv(s: String): ULong {
    var h = 14695981039346656037UL
    for (b in s.toByteArray(Charsets.UTF_8)) { h = h xor b.toUByte().toULong(); h *= 1099511628211UL }
    return h
}

/** iOS `Seeded` / `DiscoverContent.RNG` (same LCG). */
internal class Rng(var state: ULong) {
    constructor(key: String) : this(fnv(key) * 0x9E3779B97F4A7C15UL)
    fun next(): Double {
        state = state * 6364136223846793005UL + 1UL
        return ((state shr 11) and 0x1FFFFFUL).toDouble() / 0x1FFFFF.toDouble()
    }
    fun <T> pick(a: List<T>): T = a[minOf(a.size - 1, (next() * a.size).toInt())]
}

/** The user's own sky (port of `UserSky`). */
data class UserSky(
    val userId: String = "", val name: String = "", val sun: ZodiacSign? = null, val moon: ZodiacSign? = null,
    val rising: ZodiacSign? = null, val venus: ZodiacSign? = null, val mars: ZodiacSign? = null,
    val mercury: ZodiacSign? = null, val dominantElement: Element? = null,
) {
    val firstName: String get() = name.trim().split(" ").firstOrNull().orEmpty()
    val anchor: ZodiacSign get() = rising ?: sun ?: ZodiacSign.ARIES
}

data class NoteSection(val heading: String, val text: String)

enum class Backdrop { NIGHT, VIOLET, PEACH, HERO, LOVE, GUIDE, GRADIENT }

data class DiscoverNote(
    val icon: String, val eyebrow: String, val title: String, val intro: String, val sections: List<NoteSection>,
    val backdrop: Backdrop = Backdrop.NIGHT, val gradient: List<String> = emptyList(),
) { fun backed(b: Backdrop, gradient: List<String> = emptyList()) = copy(backdrop = b, gradient = gradient) }

enum class EventKind { RETROGRADE, NEW_MOON, FULL_MOON, ECLIPSE, SOLSTICE }

data class SkyEvent(val id: String, val kind: EventKind, val title: String, val dateText: String, val start: LocalDate, val end: LocalDate, val sign: ZodiacSign, val blurb: String)

data class DailyNote(val dateLabel: String, val headline: String, val body: String, val focus: String, val energyScore: Int, val luckyHue: String)

data class DiscoverTopic(val category: String, val title: String, val subtitle: String, val tint: String, val note: DiscoverNote)
data class SignDetailRow(val icon: String, val title: String, val text: String)
data class CardResult(val title: String, val body: String, val question: String)

/** Port of Infrastructure/Astrology/DailyNoteEngine.swift. Deterministic per day + user + chart. */
object DailyNoteEngine {
    private val focuses = listOf("Aşk", "Sosyal Çevre", "Kariyer", "İçe Dönüş", "Yaratıcılık", "Denge", "İletişim")
    private val luckyHues = listOf("Lavanta", "Altın", "Deniz mavisi", "Gül kurusu", "Zümrüt", "Gümüş", "Mercan")

    fun note(date: LocalDate, userId: String, sun: ZodiacSign?, moon: ZodiacSign?, rising: ZodiacSign?): DailyNote {
        val seed = fnv("$userId|${date.year}|${date.dayOfYear}|${sun?.wire ?: ""}|${moon?.wire ?: ""}|${rising?.wire ?: ""}")
        val rng = Rng(seed * 0x9E3779B97F4A7C15UL)
        val focus = focuses[(rng.next() * focuses.size).toInt() % focuses.size]
        val hue = luckyHues[(rng.next() * luckyHues.size).toInt() % luckyHues.size]
        val energy = 54 + (rng.next() * 44).toInt()
        val parts = mutableListOf<String>()
        if (sun != null) parts += "${sun.glyph} ${sun.labelTR} güneşin bugün ${sun.element.blurbTR} bir tavırla öne çıkıyor."
        if (moon != null) parts += "${moon.glyph} ${moon.labelTR} ayın iç dünyanı ${lower(moon.element.labelTR)} bir tonla renklendiriyor."
        parts += if (rising != null) "Dışa yansıyan ${rising.labelTR} yükselenin bugün özellikle ${lower(focus)} alanında konuşuyor."
        else "Enerjini bugün en çok ${lower(focus)} alanında hissedeceksin."
        val label = "${date.dayOfMonth} ${date.month.getDisplayName(TextStyle.FULL, TR)}"
        return DailyNote(label, "Bugün odak: $focus", parts.joinToString(" "), focus, energy, hue)
    }
}

/** Port of Infrastructure/Astrology/DiscoverContent.swift (1:1, same seeded randomness so text matches iOS). */
object DiscoverContent {
    private fun dayKey(d: LocalDate) = "${d.year}-${d.dayOfYear}"
    private fun rng(sky: UserSky, d: LocalDate, salt: String) =
        Rng("${sky.userId}|${dayKey(d)}|${sky.sun?.wire ?: ""}${sky.moon?.wire ?: ""}${sky.rising?.wire ?: ""}|$salt")

    private val houseThemes = listOf(
        "kimliğin ve yeni başlangıçların", "paran ve değerlerin", "iletişimin ve yakın çevren", "evin ve ailen",
        "aşkın ve yaratıcılığın", "günlük düzenin ve sağlığın", "ilişkilerin ve ortaklıkların", "dönüşümün ve ortak kaynakların",
        "ufkunun ve öğrenme alanın", "kariyerin ve itibarın", "dostlukların ve hayallerin", "iç dünyan ve dinlenmen",
    )

    fun house(sign: ZodiacSign, sky: UserSky): Int = ((sign.ordinal - sky.anchor.ordinal) % 12 + 12) % 12 + 1
    fun houseTheme(h: Int) = houseThemes[(h - 1 + 12) % 12]

    fun heroSubtitle(sky: UserSky, date: LocalDate = LocalDate.now()): String {
        val note = DailyNoteEngine.note(date, sky.userId, sky.sun, sky.moon, sky.rising)
        val who = if (sky.firstName.isEmpty()) "" else "${sky.firstName}, "
        val sun = sky.sun; val moon = sky.moon
        return if (sun != null && moon != null) "$who${sun.labelTR} güneşin ve ${moon.labelTR} ayınla bugün ${lower(note.focus)} öne çıkıyor."
        else "${who}bugün enerjin en çok ${lower(note.focus)} alanında hissedilecek."
    }

    private val loveLines = mapOf(
        Element.FIRE to listOf("Cesur bir adım ya da içten bir mesaj ilgiyi hemen canlandırır.", "Heyecanını saklama; sıcaklığın bugün çekici geliyor."),
        Element.EARTH to listOf("Küçük, somut bir ilgi göstergesi bugün bin söze bedel.", "Acele etme; güven yavaş ama sağlam kurulur."),
        Element.AIR to listOf("Bir sohbet, bir espri ya da bir fikir paylaşımı kalpleri yaklaştırır.", "Merakın bugün en iyi flört aracın."),
        Element.WATER to listOf("Sezgilerin bugün karşındakinin ruh halini açıkça okuyor.", "Duygularını yumuşak bir dille paylaşmak iyi gelir."),
    )
    private val workLines = mapOf(
        Element.FIRE to listOf("Bekleyen bir işi başlatmak için güçlü bir gün.", "Liderlik alman gereken bir an olabilir."),
        Element.EARTH to listOf("Planlı ilerlemek bugün somut sonuç getirir.", "Detaylara verdiğin emek fark edilecek."),
        Element.AIR to listOf("Görüşmeler ve yazışmalar bugün verimli.", "Yeni bir bağlantı kapı açabilir."),
        Element.WATER to listOf("Sezgisel kararların bugün isabetli.", "Ekip içinde dinleyici olmak sana avantaj sağlar."),
    )
    private val mindLines = mapOf(
        Element.FIRE to listOf("Enerjini yürüyüş ya da spora aktar.", "Sabırsızlığını bir hedefe çevir."),
        Element.EARTH to listOf("Topraklanmak için doğada kısa bir mola ver.", "Düzenli bir akşam rutini seni dengeler."),
        Element.AIR to listOf("Zihnin hızlı; ekranlardan kısa bir mola ver.", "Düşüncelerini yazmak zihnini rahatlatır."),
        Element.WATER to listOf("Suyla temas (duş, banyo) seni yeniler.", "Yalnız kalacağın bir saat ruhuna iyi gelir."),
    )

    fun dailyReading(sky: UserSky, date: LocalDate = LocalDate.now()): DiscoverNote {
        val note = DailyNoteEngine.note(date, sky.userId, sky.sun, sky.moon, sky.rising)
        val r = rng(sky, date, "daily")
        val sunEl = (sky.sun ?: ZodiacSign.ARIES).element
        val moonEl = (sky.moon ?: sky.sun ?: ZodiacSign.ARIES).element
        return DiscoverNote("sun", "GÜNÜN YORUMU · ${upper(note.dateLabel)}", note.headline, note.body, listOf(
            NoteSection("Aşk & İlişkiler", r.pick(loveLines.getValue(moonEl))),
            NoteSection("İş & Para", r.pick(workLines.getValue(sunEl))),
            NoteSection("Ruh Hali", r.pick(mindLines.getValue(moonEl))),
            NoteSection("Enerji & Şans", "Bugünkü enerji seviyen yaklaşık %${note.energyScore}. Şanslı rengin: ${lower(note.luckyHue)}."),
        ), Backdrop.HERO)
    }

    // --- daily card ---
    val cardNames = listOf("Güneş Kartı", "Ay Kartı", "Yıldız Kartı")
    private val cardPools = listOf(
        listOf("Özünle hareket et; bugün kendi sesin en doğru pusulan.", "Görünür olmaktan çekinme, ışığın birine yol gösteriyor.", "Bir hedef için ilk adımı atmanın tam zamanı.", "Cömert davran; verdiğin ilgi sana kat kat dönecek."),
        listOf("Sezgin bugün sessizce ama net konuşuyor; dinle.", "Bir duyguyu bastırmak yerine adlandırmak seni rahatlatır.", "Geçmişten gelen bir hatıra bugün şifa veriyor.", "Kendine nazik ol; dinlenmek de ilerlemektir."),
        listOf("Bir dilek tut; evren küçük işaretlerle yanıt verecek.", "Beklenmedik bir haber ufkunu açabilir.", "Umudunu taşıyan biriyle konuşmak enerjini yükseltir.", "Uzun vadeli bir hayal için bugün küçük bir not al."),
    )

    fun cardMessage(sky: UserSky, card: Int, date: LocalDate = LocalDate.now()): NoteSection {
        val r = rng(sky, date, "card$card")
        val body = r.pick(cardPools[card])
        val link = when (card) {
            0 -> sky.sun?.let { "${it.glyph} ${it.labelTR} güneşin için: " } ?: ""
            1 -> sky.moon?.let { "${it.glyph} ${it.labelTR} ayın için: " } ?: ""
            else -> sky.rising?.let { "${it.glyph} ${it.labelTR} yükselenin için: " } ?: ""
        }
        return NoteSection(cardNames[card], link + body)
    }

    // --- events (hand-written list — verify before release) ---
    private data class Raw(val id: String, val kind: EventKind, val title: String, val dateText: String, val start: LocalDate, val end: LocalDate, val sign: ZodiacSign)
    private fun d(y: Int, m: Int, day: Int) = LocalDate.of(y, m, day)
    private val rawEvents = listOf(
        Raw("mrx-26", EventKind.RETROGRADE, "Merkür Retrosu", "24 Eki – 13 Kas 2026", d(2026, 10, 24), d(2026, 11, 13), ZodiacSign.SCORPIO),
        Raw("nm-1126", EventKind.NEW_MOON, "Akrep Yeni Ayı", "9 Kasım 2026", d(2026, 11, 9), d(2026, 11, 9), ZodiacSign.SCORPIO),
        Raw("fm-1126", EventKind.FULL_MOON, "İkizler Dolunayı", "24 Kasım 2026", d(2026, 11, 24), d(2026, 11, 24), ZodiacSign.GEMINI),
        Raw("nm-1226", EventKind.NEW_MOON, "Yay Yeni Ayı", "9 Aralık 2026", d(2026, 12, 9), d(2026, 12, 9), ZodiacSign.SAGITTARIUS),
        Raw("sol-26", EventKind.SOLSTICE, "Kış Gündönümü", "21 Aralık 2026", d(2026, 12, 21), d(2026, 12, 21), ZodiacSign.CAPRICORN),
        Raw("fm-1226", EventKind.FULL_MOON, "Yengeç Dolunayı", "24 Aralık 2026", d(2026, 12, 24), d(2026, 12, 24), ZodiacSign.CANCER),
        Raw("nm-0127", EventKind.NEW_MOON, "Oğlak Yeni Ayı", "7 Ocak 2027", d(2027, 1, 7), d(2027, 1, 7), ZodiacSign.CAPRICORN),
        Raw("fm-0127", EventKind.FULL_MOON, "Aslan Dolunayı", "22 Ocak 2027", d(2027, 1, 22), d(2027, 1, 22), ZodiacSign.LEO),
        Raw("ecl-0227", EventKind.ECLIPSE, "Halkalı Güneş Tutulması", "6 Şubat 2027", d(2027, 2, 6), d(2027, 2, 6), ZodiacSign.AQUARIUS),
    )

    private fun eventBlurb(k: EventKind, s: ZodiacSign) = when (k) {
        EventKind.RETROGRADE -> "İletişim, planlar ve eski konular yeniden gündeme gelir; acele etmeden gözden geçir."
        EventKind.NEW_MOON -> "Yeni niyetler için tohum ekme zamanı; ${s.labelTR} temasında bir başlangıç yap."
        EventKind.FULL_MOON -> "Duygular belirginleşir, bir konu tamamlanır; ${s.labelTR} teması aydınlanır."
        EventKind.ECLIPSE -> "Hayatında yön değiştirecek güçlü bir kapanış ve açılış penceresi."
        EventKind.SOLSTICE -> "Güneş ${s.labelTR} burcuna geçer; yılın en uzun gecesi içe dönmeye davet eder."
    }

    fun upcomingEvents(now: LocalDate = LocalDate.now(), limit: Int = 6): List<SkyEvent> =
        rawEvents.filter { !it.end.isBefore(now) }.sortedBy { it.start }.take(limit)
            .map { SkyEvent(it.id, it.kind, it.title, it.dateText, it.start, it.end, it.sign, eventBlurb(it.kind, it.sign)) }

    fun eventPersonalLine(e: SkyEvent, sky: UserSky): String { val h = house(e.sign, sky); return "Senin $h. evinde: ${houseTheme(h)} öne çıkıyor." }

    fun eventNote(e: SkyEvent, sky: UserSky): DiscoverNote {
        val h = house(e.sign, sky)
        val sun = sky.sun
        val extra = when {
            sun == null -> ""
            sun == e.sign -> "Güneş burcunla aynı işaret: etki doğrudan sana dokunuyor."
            sun.element == e.sign.element -> "${sun.labelTR} güneşin bu olayla aynı elementte; uyumlu ve destekleyici."
            sun.element.isChallenging(e.sign.element) -> "${sun.labelTR} güneşin için biraz sürtünmeli; sabır ve esneklik iste."
            else -> "${sun.labelTR} güneşin için dengeli bir etki."
        }
        return DiscoverNote("moon", upper(e.dateText), e.title, e.blurb, listOf(
            NoteSection("Senin Haritanda", "${e.sign.labelTR} burcu senin $h. evine denk geliyor: ${houseTheme(h)} alanı gündemde. $extra"),
            NoteSection("Ne Yapmalı?", eventAdvice(e.kind, e.sign.element)),
        ))
    }

    private fun eventAdvice(k: EventKind, el: Element): String {
        val tone = when (el) {
            Element.FIRE -> "Enerjini kontrollü kullan ve sabırsızlığa kapılma."
            Element.EARTH -> "Somut adımlar at ve düzenini koru."
            Element.AIR -> "Konuşmadan önce düşün, yazmadan önce oku."
            Element.WATER -> "Duygularına alan aç ama kararlarını sezgiyle birlikte mantıkla da tart."
        }
        return when (k) {
            EventKind.RETROGRADE -> "Önemli imzaları ve büyük satın almaları ertele, yedek al, eski bağlantıları kontrol et. $tone"
            EventKind.NEW_MOON -> "Üç net niyet yaz ve bu hafta bunlardan birine küçük bir adım at. $tone"
            EventKind.FULL_MOON -> "Neyi bırakman gerektiğini not al; akşam sakin bir ritüelle günü kapat. $tone"
            EventKind.ECLIPSE -> "Büyük kararları birkaç gün dinlendir; dönüşümü zorlama, akışa yer ver. $tone"
            EventKind.SOLSTICE -> "Yılı gözden geçir, bir niyet belirle ve ışığa dair küçük bir ritüel yap. $tone"
        }
    }

    fun allEventsNote(sky: UserSky) = DiscoverNote("moon", "YAKLAŞAN GÖKYÜZÜ OLAYLARI", "Gökyüzü Takvimin", "Aşağıdaki olaylar senin haritandaki evlere göre yorumlandı.",
        upcomingEvents(limit = 12).map { NoteSection("${it.title} · ${it.dateText}", eventPersonalLine(it, sky) + " " + it.blurb) })

    // --- per-sign horoscope ---
    private val general = mapOf(
        Element.FIRE to listOf("Bugün cesur ve hareketli bir gün; kıvılcım bırak.", "Girişkenliğin ödüllendirilir ama öfkeni yönet."),
        Element.EARTH to listOf("Sağlam ve verimli bir gün; küçük adımlar büyür.", "Maddi konularda sabırlı ve gerçekçi ol."),
        Element.AIR to listOf("Zihinsel olarak çok canlı bir gün; fikirler uçuşur.", "Sosyal bağlantılar yeni kapılar açabilir."),
        Element.WATER to listOf("Duyguların derin; sezgilerine güven.", "Şefkat ve anlayış bugün en büyük gücün."),
    )

    fun signReading(sign: ZodiacSign, sky: UserSky, date: LocalDate = LocalDate.now()): DiscoverNote {
        val r = Rng("${dayKey(date)}|sign|${sign.wire}|${sky.userId}")
        val el = sign.element
        val h = house(sign, sky)
        val sun = sky.sun
        val relation = when {
            sun == null -> ""
            sun == sign -> "Bu senin güneş burcun; bugün en çok sen hissedeceksin."
            sun.element == el -> "${sun.labelTR} güneşinle aynı elementte, bu yüzden bu burcun enerjisiyle kolay akarsın."
            sun.element.isComplementary(el) -> "${sun.labelTR} güneşinle tamamlayıcı bir element; bu burçla karşılaşmalar sana iyi gelir."
            sun.element.isChallenging(el) -> "${sun.labelTR} güneşinle zıt tonda; bu burçla iletişimde sabırlı ol."
            else -> "${sun.labelTR} güneşinle nötr bir ilişki; merak seni yönlendirsin."
        }
        val intro = r.pick(general.getValue(el))
        return DiscoverNote("sparkle", "GÜNLÜK BURÇ YORUMU", "${sign.glyph} ${sign.labelTR}", intro, listOf(
            NoteSection("Senin İçin", if (relation.isEmpty()) "Bu burç senin $h. evinde." else "$relation Bu burç senin $h. evinde: ${houseTheme(h)}."),
            NoteSection("Aşk", r.pick(loveLines.getValue(el))),
            NoteSection("İş & Para", r.pick(workLines.getValue(el))),
            NoteSection("Tarih Aralığı", "${sign.dateRangeText} · ${sign.element.labelTR} · ${sign.modality.labelTR} · Yönetici: ${sign.rulerTR}"),
        ))
    }

    fun allSignsNote(sky: UserSky, date: LocalDate = LocalDate.now()) = DiscoverNote("sparkles", "GÜNLÜK BURÇ YORUMLARI", "Bugün 12 Burç", "Her burcun günü, senin haritana göre kısaca.",
        ZodiacSign.entries.map { val n = signReading(it, sky, date); NoteSection(n.title, n.intro + " " + (n.sections.firstOrNull()?.text ?: "")) })

    // --- love ---
    private val venusLines = mapOf(
        Element.FIRE to "tutkulu, doğrudan ve macera arayan bir sevme biçimin var",
        Element.EARTH to "sadık, duyusal ve güven odaklı seviyorsun",
        Element.AIR to "zihinsel bağ kurarak, konuşarak ve oyunbazlıkla seviyorsun",
        Element.WATER to "derin, sezgisel ve tamamen içine girerek seviyorsun",
    )
    private val marsLines = mapOf(
        Element.FIRE to "arzunu hızlı ve net gösterirsin", Element.EARTH to "yavaş ama kararlı ve dokunsal ilerlersin",
        Element.AIR to "söz ve zekâ ile cezbedersin", Element.WATER to "duygusal yakınlık kurmadan açılmazsın",
    )

    fun loveNote(sky: UserSky, date: LocalDate = LocalDate.now()): DiscoverNote {
        val r = rng(sky, date, "love")
        val venus = sky.venus ?: sky.moon ?: sky.sun ?: ZodiacSign.LIBRA
        val mars = sky.mars ?: sky.sun ?: ZodiacSign.ARIES
        val me = sky.sun ?: ZodiacSign.ARIES
        val venusLabel = if (sky.venus == null) "Aşk dilin" else "Venüs ${venus.glyph} ${venus.labelTR}"
        val compat = ZodiacSign.entries.filter { it != me && (it.element == me.element || it.element.isComplementary(me.element)) }.joinToString(", ") { it.labelTR }
        return DiscoverNote("heart", "AŞK VE İLİŞKİ ASTROLOJİSİ", "Kalbinin Haritası",
            "${if (sky.firstName.isEmpty()) "" else sky.firstName + ", "}yıldızlar kalbinin dilini şöyle okuyor.", listOf(
                NoteSection(venusLabel, "${venusLines[venus.element] ?: ""}."),
                NoteSection("Mars ${mars.glyph} ${mars.labelTR}", "Çekimde ${marsLines[mars.element] ?: ""}."),
                NoteSection("Bugün Aşk İçin", r.pick(loveLines.getValue((sky.moon ?: venus).element))),
                NoteSection("Uyumlu Burçlar", if (compat.isEmpty()) "Eşleşme çarkında sana en uyumlu kişileri keşfet." else "Elementsel olarak sana en kolay akan burçlar: $compat."),
            ))
    }

    // --- guide ---
    fun guideNote(sky: UserSky): DiscoverNote {
        val s = mutableListOf<NoteSection>()
        sky.sun?.let { s += NoteSection("☉ Güneş · ${it.labelTR}", "Özün ve yaşam enerjin. ${it.element.labelTR} elementi (${it.element.blurbTR}) ve ${lower(it.modality.labelTR)} nitelik (${it.modality.blurbTR}). Yöneticin ${it.rulerTR}.") }
        sky.moon?.let { s += NoteSection("☽ Ay · ${it.labelTR}", "Duygusal dünyan ve ihtiyaçların. ${it.element.labelTR} tonu: ${it.element.blurbTR} bir iç dünya.") }
        sky.rising?.let { s += NoteSection("↑ Yükselen · ${it.labelTR}", "Dünyaya göründüğün yüz ve ilk izlenim. ${it.element.labelTR} elementi: dışarıya ${it.element.blurbTR} bir enerji yayıyorsun.") }
        sky.dominantElement?.let { s += NoteSection("Baskın Element · ${it.labelTR}", "Haritandaki gezegenler en çok ${lower(it.labelTR)} elementinde toplanıyor: ${it.blurbTR} bir temel.") }
        if (s.isEmpty()) s += NoteSection("Başlangıç", "Profilini tamamlayınca Güneş, Ay ve Yükselen yorumların burada belirecek.")
        return DiscoverNote("book", "ASTROLOJİ REHBERİ", "Haritanı Oku", "Büyük üçlün senin kozmik imzan. İşte kısaca anlamları.", s)
    }

    // --- extras ---
    fun weeklyNote(sky: UserSky, from: LocalDate = LocalDate.now()): DiscoverNote {
        val sections = (0 until 7).map { i ->
            val day = from.plusDays(i.toLong())
            val n = DailyNoteEngine.note(day, sky.userId, sky.sun, sky.moon, sky.rising)
            val head = capitalizeWords("${day.dayOfWeek.getDisplayName(TextStyle.FULL, TR)}, ${day.dayOfMonth} ${day.month.getDisplayName(TextStyle.SHORT, TR)}")
            NoteSection(head, "${n.headline} · Enerji %${n.energyScore} · Şanslı renk: ${lower(n.luckyHue)}.")
        }
        return DiscoverNote("calendar", "HAFTALIK GÖKYÜZÜ GÜNDEMİ", "Bu Hafta Sende", "Önümüzdeki 7 gün için kişisel odak ve enerji tahminin.", sections)
    }

    fun beginnerNote(sky: UserSky): DiscoverNote {
        val sun = sky.sun?.labelTR ?: "Güneş burcun"; val moon = sky.moon?.labelTR ?: "Ay burcun"; val rising = sky.rising?.labelTR ?: "Yükselenin"
        return DiscoverNote("leaf", "YENİ BAŞLAYANLAR İÇİN ASTROLOJİ", "3 Adımda Başla", "Astrolojiye senin haritanla girelim.", listOf(
            NoteSection("1 · Güneşin: $sun", "Kim olduğunu ve neyle parladığını anlatır. Günlük burç yorumlarını önce buradan oku."),
            NoteSection("2 · Ayın: $moon", "Neye ihtiyaç duyduğunu ve nasıl rahatladığını gösterir. Duygusal kararlarında Ay'ına bak."),
            NoteSection("3 · Yükselenin: $rising", "İlk izlenimini ve hayata yaklaşımını anlatır. Yeni insanlarla tanışırken bu kapıdan girersin."),
            NoteSection("Sonra", "Eşleşme sekmesinde karşındakinin büyük üçlüsünü senin haritanla karşılaştır."),
        ))
    }

    private val rituals = mapOf(
        Element.FIRE to listOf("Bir mum yak ve bugün bırakmak istediğin şeyi yazıp yak.", "Güneş doğarken 5 dakika nefes çalışması yap."),
        Element.EARTH to listOf("Çıplak ayakla toprağa bas ve 10 derin nefes al.", "Evinde küçük bir düzenleme yap ve bir bitkiyle ilgilen."),
        Element.AIR to listOf("Pencereyi aç, 3 dilek söyle ve rüzgârın taşımasına izin ver.", "Akşam telefonsuz bir saat geçirip günlük tut."),
        Element.WATER to listOf("Deniz tuzlu ılık bir banyo yap ve niyetini fısılda.", "Bir bardak suyu ay ışığına bırak, sabah niyetle iç."),
    )
    private val crystals = mapOf(Element.FIRE to "Karneol", Element.EARTH to "Yeşim", Element.AIR to "Berrak kuvars", Element.WATER to "Ay taşı")

    fun ritualNote(sky: UserSky, date: LocalDate = LocalDate.now()): DiscoverNote {
        val r = rng(sky, date, "ritual")
        val el = (sky.moon ?: sky.sun ?: ZodiacSign.PISCES).element
        val n = DailyNoteEngine.note(date, sky.userId, sky.sun, sky.moon, sky.rising)
        return DiscoverNote("flame", "RİTÜELLER VE ÖNERİLER", "Bugünün Ritüeli", "Ayının ${lower(el.labelTR)} tonuna göre hazırlandı.", listOf(
            NoteSection("Ritüel", r.pick(rituals.getValue(el))),
            NoteSection("Taş", "${crystals[el] ?: "Kuvars"} bugün yanında taşıman için iyi bir eşlikçi."),
            NoteSection("Renk", "Şanslı rengin: ${lower(n.luckyHue)}. Kıyafet ya da aksesuarla ekle."),
            NoteSection("Odak", "Bugünün odağı: ${lower(n.focus)}."),
        ))
    }

    fun extrasAllNote(sky: UserSky): DiscoverNote {
        val notes = listOf(weeklyNote(sky), beginnerNote(sky), ritualNote(sky))
        return DiscoverNote("square.grid.2x2", "KEŞFET · EK İÇERİKLER", "Sana Özel Seçkiler", "Üç kısa rehber, senin haritana göre.",
            notes.map { NoteSection(it.title, it.intro + " " + (it.sections.firstOrNull()?.text ?: "")) })
    }

    // --- redesign screens ---
    private val cardTitles = listOf(
        listOf("Bırak, sana ait olan yolunu bulsun.", "Işığın bugün birine yol gösteriyor.", "İlk adımı atmak için doğru an bu.", "Verdiğin ilgi sana kat kat dönecek."),
        listOf("Sezgin sessizce ama net konuşuyor.", "Hissettiğini adlandırmak seni hafifletir.", "Geçmiş bugün sana şifa getiriyor.", "Dinlenmek de ilerlemenin bir parçası."),
        listOf("Bir dilek tut, evren işaretlerle yanıtlar.", "Beklenmedik bir haber ufkunu açar.", "Umut taşıyan biriyle konuş.", "Uzun vadeli hayalin için küçük bir not al."),
    )
    private val askQuestions = listOf(
        "Nasıl zorlamayı bırakabilirim?", "Bugün neye gerçekten ihtiyacım var?", "Kimden ya da neden uzaklaşmam gerekiyor?",
        "Hangi korkum beni durduruyor?", "Bugün kendime hangi iyiliği borçluyum?", "Neyi affetmem gerekiyor?",
    )

    fun cardResult(sky: UserSky, card: Int, date: LocalDate = LocalDate.now()): CardResult {
        val r = rng(sky, date, "result$card")
        val title = r.pick(cardTitles[card])
        val msg = cardMessage(sky, card, date)
        val who = when (card) {
            0 -> sky.sun?.let { "${it.glyph} ${it.labelTR} güneşin" } ?: "Güneşin"
            1 -> sky.moon?.let { "${it.glyph} ${it.labelTR} ayın" } ?: "Ayın"
            else -> sky.rising?.let { "${it.glyph} ${it.labelTR} yükselenin" } ?: "Yükselenin"
        }
        val body = "Her yeni bugün çemberi zamanda değişir. $who bugün sana şunu fısıldıyor: ${msg.text.split(": ").last()}"
        return CardResult(title, body, r.pick(askQuestions))
    }

    private val tips = mapOf(
        Element.FIRE to listOf("Küçük bir hedef belirle ve hemen başla.", "Enerjini hareketle boşalt."),
        Element.EARTH to listOf("Bir işi bitir, sonra dinlen.", "Bedenini toprakla buluştur: yürü."),
        Element.AIR to listOf("Bir arkadaşını ara, fikrini paylaş.", "Düşüncelerini üç cümleyle yaz."),
        Element.WATER to listOf("Kendine sıcak bir içecek hazırla ve sessizlikte otur.", "Bir şarkıyla duygularını akıt."),
    )

    fun signRows(sign: ZodiacSign, sky: UserSky, date: LocalDate = LocalDate.now()): List<SignDetailRow> {
        val r = Rng("${dayKey(date)}|rows|${sign.wire}|${sky.userId}")
        val el = sign.element
        return listOf(
            SignDetailRow("heart", "Aşk & İlişkiler", r.pick(loveLines.getValue(el))),
            SignDetailRow("briefcase", "Kariyer & Üretkenlik", r.pick(workLines.getValue(el))),
            SignDetailRow("drop", "Duygusal Durum", r.pick(mindLines.getValue(el))),
            SignDetailRow("sparkle", "Günün Önerisi", r.pick(tips.getValue(el))),
        )
    }

    fun signRelation(sign: ZodiacSign, sky: UserSky): String {
        val h = house(sign, sky)
        val sun = sky.sun ?: return "Bu burç senin $h. evinde: ${houseTheme(h)}."
        val rel = when {
            sun == sign -> "Bu senin güneş burcun; bugün en çok sen hissedeceksin."
            sun.element == sign.element -> "${sun.labelTR} güneşinle aynı element."
            sun.element.isComplementary(sign.element) -> "${sun.labelTR} güneşinle tamamlayıcı."
            sun.element.isChallenging(sign.element) -> "${sun.labelTR} güneşinle sürtünmeli; sabır iste."
            else -> "${sun.labelTR} güneşinle nötr."
        }
        return "$rel Senin $h. evinde: ${houseTheme(h)}."
    }

    fun eventSignEffects(e: SkyEvent, sky: UserSky) = DiscoverNote("sparkles", "BURÇLARA GÖRE ETKİLER", e.title,
        "${e.sign.labelTR} burcundaki bu olay her burcun farklı bir alanına dokunur.",
        ZodiacSign.entries.map { s -> val h = house(e.sign, sky.copy(rising = s)); NoteSection("${s.glyph} ${s.labelTR}", "$h. ev etkisi: ${houseTheme(h)}.") })

    fun loveTopics(sky: UserSky): List<DiscoverTopic> {
        val sun = sky.sun ?: ZodiacSign.ARIES
        val venus = sky.venus ?: sky.moon ?: sun
        val mars = sky.mars ?: sun
        val moon = sky.moon ?: sun
        val good = ZodiacSign.entries.filter { it != sun && (it.element == sun.element || it.element.isComplementary(sun.element)) }.joinToString(", ") { it.labelTR }
        val hard = ZodiacSign.entries.filter { it.element.isChallenging(sun.element) }.joinToString(", ") { it.labelTR }
        fun n(icon: String, eyebrow: String, title: String, intro: String, secs: List<NoteSection>) = DiscoverNote(icon, eyebrow, title, intro, secs)
        return listOf(
            DiscoverTopic("Tümü", "Venüs Burcu", "Aşk dilin ve sevme biçimin", "#C98A9B", n("heart", "AŞK VE İLİŞKİ", "Venüs ${venus.glyph} ${venus.labelTR}", "${venusLines[venus.element] ?: ""}.", listOf(
                NoteSection("İlişkide Güçlü Yanın", "${venus.element.labelTR} elementi: ${venus.element.blurbTR} bir sevgi dili."),
                NoteSection("Dikkat Et", "Beklentilerini açıkça söylemek, ${lower(venus.labelTR)} enerjisinin en büyük sınavı.")))),
            DiscoverTopic("Tümü", "Mars ve Çekim Dinamikleri", "Arzu ve tutkunun yönü", "#C0674F", n("flame", "AŞK VE İLİŞKİ", "Mars ${mars.glyph} ${mars.labelTR}", "Çekimde ${marsLines[mars.element] ?: ""}.", listOf(
                NoteSection("Çekim Tarzın", "${mars.modality.labelTR} nitelik: ${mars.modality.blurbTR}."),
                NoteSection("Uyum İpucu", "Seni en iyi anlayan, ${lower(mars.element.labelTR)} tonuna saygı duyan kişi.")))),
            DiscoverTopic("Tümü", "Ay Burcu", "Duygusal ihtiyaçların", "#9C93C7", n("moon", "AŞK VE İLİŞKİ", "Ay ${moon.glyph} ${moon.labelTR}", "Duygusal güvenliğin ${moon.element.blurbTR} bir ortamda büyür.", listOf(
                NoteSection("İhtiyacın", "Yakınlıkta ${lower(moon.element.labelTR)} elementi gibi: ${moon.element.blurbTR}."),
                NoteSection("Partnerine Söyle", "Ne zaman yalnız kalmak, ne zaman sarılmak istediğini ona açıkça anlat.")))),
            DiscoverTopic("Tümü", "İki Burcun Uyumu", "Güneş burcuna göre uyum", "#B58BC9", n("person.2", "AŞK VE İLİŞKİ", "${sun.labelTR} için Uyum", "Elementsel akışa göre seni en çok destekleyen ve zorlayan burçlar.", listOf(
                NoteSection("Kolay Akan Burçlar", good.ifEmpty { "—" }), NoteSection("Emek İsteyen Burçlar", hard.ifEmpty { "—" }),
                NoteSection("Not", "Gerçek uyum tüm harita karşılaştırmasıyla belli olur: Eşleşme sekmesindeki sinastri bunu gösterir.")))),
            DiscoverTopic("Tümü", "Sinastri Rehberi", "Haritaların buluşması", "#8C8FB5", n("circle.hexagongrid", "AŞK VE İLİŞKİ", "Sinastri Nedir?", "İki kişinin doğum haritasının üst üste konup karşılaştırılmasıdır.", listOf(
                NoteSection("Neye Bakılır?", "Güneş–Ay, Venüs–Mars ve açı ilişkileri; çekim, güven ve sürtünme alanlarını gösterir."),
                NoteSection("Sende", "Güneşin ${sun.labelTR}, ayın ${moon.labelTR}: karşındakinin bu noktalarla nasıl konuştuğuna bak.")))),
        ).map { it.copy(note = it.note.backed(Backdrop.LOVE)) }
    }

    fun guideTopics(sky: UserSky): List<DiscoverTopic> {
        val sun = sky.sun ?: ZodiacSign.ARIES
        val anchor = sky.anchor
        fun n(icon: String, cat: String, title: String, intro: String, secs: List<NoteSection>) =
            DiscoverNote(icon, "ASTROLOJİ REHBERİ · ${upper(cat)}", title, intro, secs)
        val houses = (1..12).map { h -> val idx = (anchor.ordinal + h - 1) % 12; NoteSection("$h. Ev · ${ZodiacSign.entries[idx].labelTR}", "Konu: ${houseTheme(h)}.") }
        return listOf(
            DiscoverTopic("Gezegenler", "Gezegenler neyi temsil eder?", "Güneş, Ay, Venüs ve ötesi", "#B7906F", n("globe", "Gezegenler", "Gökyüzünün Oyuncuları", "Her gezegen yaşamının farklı bir yönünü anlatır.", listOf(
                NoteSection("☉ Güneş", "Özün ve yaşam enerjin. Sende: ${sun.labelTR}."), NoteSection("☽ Ay", "Duyguların. Sende: ${sky.moon?.labelTR ?: "—"}."),
                NoteSection("☿ Merkür", "Düşünme ve iletişim. Sende: ${sky.mercury?.labelTR ?: "—"}."), NoteSection("♀ Venüs", "Sevgi ve zevk. Sende: ${sky.venus?.labelTR ?: "—"}."),
                NoteSection("♂ Mars", "Eylem ve arzu. Sende: ${sky.mars?.labelTR ?: "—"}.")))),
            DiscoverTopic("Evler", "Evler ne anlama gelir?", "Hayatın 12 alanı", "#9C6F78", n("house", "Evler", "12 Ev", "Evler hayatın alanlarını gösterir. Haritan ${anchor.labelTR} ile başlıyor.", houses)),
            DiscoverTopic("Gezegenler", "Retro hareket ne demek?", "Geriye giden gezegenler", "#C07F5A", n("arrow.uturn.backward", "Gezegenler", "Retro Hareket", "Bir gezegen gökyüzünde geriye gidiyormuş gibi görünür; gerçekte bu bir bakış açısı etkisidir.", listOf(
                NoteSection("Ne Yapılır?", "Gözden geçir, yeniden dene, tamamla. Yeni büyük başlangıçları erteleyebilirsin."),
                NoteSection("Merkür Retrosu", "İletişim, yolculuk ve teknolojide gecikmeler olabilir. Yedek al, mesajlarını iki kez oku.")))),
            DiscoverTopic("Burçlar", "Burçlar arasındaki uyum", "Element ve nitelikler", "#8F8BC2", n("person.2", "Burçlar", "Elementler & Nitelikler", "Ateş ve Hava birbirini besler; Toprak ve Su birbirini taşır.", listOf(
                NoteSection("Senin Elementin", "${sun.element.labelTR}: ${sun.element.blurbTR}."), NoteSection("Niteliğin", "${sun.modality.labelTR}: ${sun.modality.blurbTR}.")))),
            DiscoverTopic("Burçlar", "Doğum haritası nasıl okunur?", "Adım adım rehber", "#7E78B8", n("map", "Burçlar", "Haritanı Oku", "Önce üçlüne bak: Güneş, Ay, Yükselen.", listOf(
                NoteSection("1 · Güneş", sun.labelTR), NoteSection("2 · Ay", sky.moon?.labelTR ?: "—"), NoteSection("3 · Yükselen", sky.rising?.labelTR ?: "—"),
                NoteSection("4 · Evler & Açılar", "Sonra gezegenlerin hangi evde olduğuna ve birbirleriyle açılarına bak.")))),
            DiscoverTopic("Gezegenler", "Astroloji açıları", "Gezegenler arası konuşma", "#8CA0C2", n("angle", "Gezegenler", "Açılar", "Gezegenler birbirine belirli açılarla bakınca konuşur.", listOf(
                NoteSection("Kavuşum 0°", "Enerjiler birleşir."), NoteSection("Üçgen 120°", "Akıcı ve destekleyici."),
                NoteSection("Kare 90°", "Gerilim ve gelişim."), NoteSection("Karşıt 180°", "Denge arayışı.")))),
        ).map { it.copy(note = it.note.backed(Backdrop.GUIDE)) }
    }
}

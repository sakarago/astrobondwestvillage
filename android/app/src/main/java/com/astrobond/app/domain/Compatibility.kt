package com.astrobond.app.domain

import java.time.Instant
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

enum class CompatibilityCategory(val tr: String, val weight: Int, val emoji: String) {
    SUN("Güneş Uyumu", 15, "☉"), MOON("Ay Uyumu", 20, "☽"), VENUS_MARS("Venüs-Mars Sinerjisi", 25, "♀♂"),
    ASCENDANT("Yükselen Uyumu", 15, "↑"), COMPOSITE("Karma Etkiler", 25, "⚹"),
}

data class CategoryScore(val category: CompatibilityCategory, val score: Int, val maxScore: Int, val description: String) {
    val percentage: Double get() = if (maxScore > 0) score.toDouble() / maxScore else 0.0
}

enum class CompatibilityLabel(val tr: String, val description: String) {
    UNIVERSAL_HARMONY("Evrensel Uyum", "Nadir görülen kozmik bir uyum. İkinizin enerji alanları mükemmel örtüşüyor."),
    DEEP_BOND("Derin Bağ", "Güçlü ve anlamlı bir bağ. Birbirinizi derin bir düzeyde anlayabilirsiniz."),
    COMPATIBLE("Uyumlu", "Sağlıklı ve uyumlu bir ilişki potansiyeli. Birlikte büyüyebilirsiniz."),
    GROWTH_AREA("Gelişim Alanı", "Farklılıklarınız sizi tamamlıyor. Birbirinizden öğrenecek çok şeyiniz var."),
    CHALLENGING("Zorlayıcı", "Güçlü farklılıklar mevcut. Bilinçli çabayla değerli bir ilişki kurulabilir.");

    companion object {
        fun from(score: Int) = when (score) {
            in 90..100 -> UNIVERSAL_HARMONY; in 75..89 -> DEEP_BOND; in 60..74 -> COMPATIBLE
            in 45..59 -> GROWTH_AREA; else -> CHALLENGING
        }
    }
}

data class CompatibilityReport(
    val userId1: String, val userId2: String, val totalScore: Int, val breakdown: List<CategoryScore>,
    val strengths: List<String>, val challenges: List<String>, val overallLabel: CompatibilityLabel,
    val topSynastryAspects: List<SynastryAspect>, val calculatedAt: Instant,
) { val normalizedScore: Double get() = totalScore / 100.0 }

/** 1:1 port of CalculateCompatibilityUseCase.swift (100 points: sun 15, moon 20, venus-mars 25, asc 15, composite 25). */
object CompatibilityEngine {
    private class R(val score: CategoryScore, val strengths: List<String> = emptyList(), val challenges: List<String> = emptyList())

    fun execute(c1: NatalChart, c2: NatalChart): CompatibilityReport {
        val breakdown = mutableListOf<CategoryScore>()
        val strengths = mutableListOf<String>()
        val challenges = mutableListOf<String>()
        fun add(r: R) { breakdown += r.score; strengths += r.strengths; challenges += r.challenges }

        add(sun(c1.sunSign, c2.sunSign))
        add(moon(c1.moonSign, c2.moonSign))
        add(venusMars(c1, c2))
        if (c1.birthData.time.isKnown && c2.birthData.time.isKnown) add(asc(c1.risingSign, c2.risingSign))
        else breakdown += CategoryScore(CompatibilityCategory.ASCENDANT, 0, 0, "Doğum saati bilinmediğinden bu kategori değerlendirilmedi.")
        val syn = NatalChart.synastryAspects(c1, c2, 5)
        add(composite(syn))

        val total = min(100, max(0, breakdown.sumOf { it.score }))
        return CompatibilityReport(c1.userId, c2.userId, total, breakdown, strengths.take(5), challenges.take(3),
            CompatibilityLabel.from(total), syn, Instant.now())
    }

    private fun sun(a: ZodiacSign, b: ZodiacSign): R {
        var p = 0; val s = mutableListOf<String>(); val c = mutableListOf<String>()
        when {
            a == b -> { p = 15; s += "Aynı Güneş burcu — temel değerlerde derin bir anlayış paylaşıyorsunuz." }
            a.element == b.element -> { p = 15; s += "${a.element.labelTR} elementi paylaşıyorsunuz — doğal bir uyum var." }
            a.element.isComplementary(b.element) -> { p = 10; s += "Tamamlayıcı elementler (${a.element.labelTR}-${b.element.labelTR}) — birbirinizi dengeleyen enerjiler." }
            a.isSquare(b) -> { p = 2; c += "${a.labelTR} ile ${b.labelTR} kare açısında — ortak noktalar bulmak çaba gerektirebilir." }
            else -> p = 5
        }
        return R(CategoryScore(CompatibilityCategory.SUN, p, 15, "${a.glyph} ${a.labelTR} × ${b.glyph} ${b.labelTR}"), s, c)
    }

    private fun moon(a: ZodiacSign, b: ZodiacSign): R {
        var p = 0; val s = mutableListOf<String>(); val c = mutableListOf<String>()
        when {
            a == b -> { p = 20; s += "Aynı Ay burcu — duygusal dünyalarınız mükemmel uyum içinde." }
            a.element == b.element -> { p = 12; s += "Ay burçlarınız aynı elementte — duygusal anlayış güçlü." }
            a.isTrine(b) -> { p = 15; s += "Ay burçları üçgen açısında — duygusal akış doğal ve rahat." }
            a.isSextile(b) -> { p = 15; s += "Ay burçları sekstil açısında — duygusal iletişim akıcı." }
            a.isOpposite(b) -> { p = 8; s += "Karşıt Ay burçları — farklı duygusal ihtiyaçlar farkındalıkla köprü kurabilir." }
            a.isSquare(b) -> { p = 3; c += "Ay burçları kare açısında — duygusal ihtiyaçlar zaman zaman çatışabilir." }
            else -> p = 6
        }
        return R(CategoryScore(CompatibilityCategory.MOON, p, 20, "${a.glyph} ${a.labelTR} Ayı × ${b.glyph} ${b.labelTR} Ayı"), s, c)
    }

    private class VM(val points: Int, val strengths: List<String>, val challenges: List<String>)

    private fun vmScore(venus: PlanetPosition, mars: PlanetPosition): VM {
        val diff = abs(venus.longitude - mars.longitude)
        val angle = min(diff, 360 - diff)
        return when (AspectType.from(angle)) {
            AspectType.CONJUNCTION, AspectType.TRINE -> VM(25, listOf("Venüs ve Mars güçlü bir uyum içinde — romantik çekim yoğun."), emptyList())
            AspectType.SEXTILE -> VM(18, listOf("Venüs-Mars sekstil — romantik enerji akıcı ve doğal."), emptyList())
            AspectType.OPPOSITION -> VM(12, listOf("Venüs-Mars karşıtlığı — güçlü çekim, farkındalık gerektirir."), emptyList())
            AspectType.SQUARE -> VM(10, emptyList(), listOf("Venüs-Mars kare — tutku var ama sürtüşme olabilir."))
            null -> VM(5, emptyList(), emptyList())
        }
    }

    private fun venusMars(c1: NatalChart, c2: NatalChart): R {
        val v1 = c1.planet(Planet.VENUS); val m1 = c1.planet(Planet.MARS)
        val v2 = c2.planet(Planet.VENUS); val m2 = c2.planet(Planet.MARS)
        if (v1 == null || m1 == null || v2 == null || m2 == null)
            return R(CategoryScore(CompatibilityCategory.VENUS_MARS, 12, 25, "Venüs-Mars verisi eksik"))
        val s1 = vmScore(v1, m2); val s2 = vmScore(v2, m1)
        val pts = max(s1.points, s2.points)
        val pick = if (s1.points >= s2.points) s1 else s2
        val st = pick.strengths.toMutableList()
        if (v1.sign.element.isComplementary(m2.sign.element)) st += "Venüs ve Mars elementleri tamamlayıcı — çekim güçlü."
        return R(CategoryScore(CompatibilityCategory.VENUS_MARS, pts, 25, "Venüs ${v1.sign.glyph} × Mars ${m2.sign.glyph}"), st, pick.challenges)
    }

    private fun asc(a: ZodiacSign, b: ZodiacSign): R {
        val p: Int; val s = mutableListOf<String>()
        when {
            a.isOpposite(b) -> { p = 15; s += "Karşıt yükselen burçlar — 'karşıtlar çekilir' dinamiği güçlü." }
            a.element == b.element -> { p = 15; s += "Yükselen burçlar aynı elementte — ilk izlenim ve iletişim doğal." }
            a.isTrine(b) -> { p = 12; s += "Yükselen burçlar üçgen açısında — birliktelik akıcı ve rahat hissettiriyor." }
            else -> p = 8
        }
        return R(CategoryScore(CompatibilityCategory.ASCENDANT, p, 15, "${a.glyph} ${a.labelTR} × ${b.glyph} ${b.labelTR} Yükselen"), s)
    }

    private fun composite(aspects: List<SynastryAspect>): R {
        var pts = 0; val s = mutableListOf<String>(); val c = mutableListOf<String>()
        for (a in aspects.take(5)) {
            if (a.type.harmonious) {
                pts += if (a.planet1.benefic || a.planet2.benefic) 5 else 4
                s += "${a.description} — ${a.type.wire.lowercase()} enerjisi uyumlu."
            } else {
                pts -= if (a.planet1.malefic || a.planet2.malefic) 2 else 1
                c += "${a.description} — dikkat ve farkındalık gerektirir."
            }
        }
        pts = max(0, min(25, pts))
        return R(CategoryScore(CompatibilityCategory.COMPOSITE, pts, 25, "${aspects.size} önemli sinastri aspekti"), s, c)
    }
}

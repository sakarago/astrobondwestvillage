package com.astrobond.app.domain

/** Port of Domain/ProfileModels.swift (ZodiacSign, Gender). Wire names match the iOS app / DB. */
enum class Element(val wire: String, val labelTR: String, val blurbTR: String) {
    FIRE("fire", "Ateş", "girişken, doğrudan ve hızlı tutuşan"),
    EARTH("earth", "Toprak", "somut, sabırlı ve köklü"),
    AIR("air", "Hava", "meraklı, sözel ve bağlantı arayan"),
    WATER("water", "Su", "sezgisel, duygusal ve derin");

    fun isComplementary(o: Element) =
        (this == FIRE && o == AIR) || (this == AIR && o == FIRE) ||
            (this == EARTH && o == WATER) || (this == WATER && o == EARTH)

    fun isChallenging(o: Element) =
        (this == FIRE && o == WATER) || (this == WATER && o == FIRE) ||
            (this == EARTH && o == AIR) || (this == AIR && o == EARTH)

    companion object { fun fromWire(s: String) = entries.firstOrNull { it.wire == s } ?: FIRE }
}

enum class Modality(val wire: String, val labelTR: String, val blurbTR: String) {
    CARDINAL("cardinal", "Öncü", "başlatır, harekete geçirir"),
    FIXED("fixed", "Sabit", "sürdürür, derinleştirir"),
    MUTABLE("mutable", "Değişken", "uyum sağlar, dönüştürür");

    companion object { fun fromWire(s: String) = entries.firstOrNull { it.wire == s } ?: CARDINAL }
}

enum class Gender(val stableName: String, val labelTR: String) {
    WOMAN("woman", "Kadın"),
    MAN("man", "Erkek"),
    NON_BINARY("nonBinary", "İkili olmayan"),
    OTHER("other", "Diğer"),
    PREFER_NOT_SAY("preferNotSay", "Belirtmek istemiyorum");

    companion object {
        fun fromStableName(n: String?) = entries.firstOrNull { it.stableName == n } ?: PREFER_NOT_SAY
    }
}

enum class ZodiacSign(
    val wire: String, val englishName: String, val glyph: String, val labelTR: String,
    val dateRangeText: String, val element: Element, val modality: Modality, val rulerTR: String,
) {
    ARIES("aries", "Aries", "♈︎", "Koç", "21 Mar – 19 Nis", Element.FIRE, Modality.CARDINAL, "♂ Mars"),
    TAURUS("taurus", "Taurus", "♉︎", "Boğa", "20 Nis – 20 May", Element.EARTH, Modality.FIXED, "♀ Venüs"),
    GEMINI("gemini", "Gemini", "♊︎", "İkizler", "21 May – 20 Haz", Element.AIR, Modality.MUTABLE, "☿ Merkür"),
    CANCER("cancer", "Cancer", "♋︎", "Yengeç", "21 Haz – 22 Tem", Element.WATER, Modality.CARDINAL, "☽ Ay"),
    LEO("leo", "Leo", "♌︎", "Aslan", "23 Tem – 22 Ağu", Element.FIRE, Modality.FIXED, "☉ Güneş"),
    VIRGO("virgo", "Virgo", "♍︎", "Başak", "23 Ağu – 22 Eyl", Element.EARTH, Modality.MUTABLE, "☿ Merkür"),
    LIBRA("libra", "Libra", "♎︎", "Terazi", "23 Eyl – 22 Eki", Element.AIR, Modality.CARDINAL, "♀ Venüs"),
    SCORPIO("scorpio", "Scorpio", "♏︎", "Akrep", "23 Eki – 21 Kas", Element.WATER, Modality.FIXED, "♇ Plüton"),
    SAGITTARIUS("sagittarius", "Sagittarius", "♐︎", "Yay", "22 Kas – 21 Ara", Element.FIRE, Modality.MUTABLE, "♃ Jüpiter"),
    CAPRICORN("capricorn", "Capricorn", "♑︎", "Oğlak", "22 Ara – 19 Oca", Element.EARTH, Modality.CARDINAL, "♄ Satürn"),
    AQUARIUS("aquarius", "Aquarius", "♒︎", "Kova", "20 Oca – 18 Şub", Element.AIR, Modality.FIXED, "♅ Uranüs"),
    PISCES("pisces", "Pisces", "♓︎", "Balık", "19 Şub – 20 Mar", Element.WATER, Modality.MUTABLE, "♆ Neptün");

    val index: Int get() = ordinal
    val startDegree: Double get() = ordinal * 30.0

    fun isTrine(o: ZodiacSign) = element == o.element
    fun isSextile(o: ZodiacSign) = element.isComplementary(o.element)
    fun isSquare(o: ZodiacSign): Boolean { val d = kotlin.math.abs(index - o.index); return d == 3 || d == 9 }
    fun isOpposite(o: ZodiacSign) = kotlin.math.abs(index - o.index) == 6

    companion object {
        fun sunSign(month: Int, day: Int): ZodiacSign {
            val md = month * 100 + day
            return when (md) {
                in 321..419 -> ARIES
                in 420..520 -> TAURUS
                in 521..620 -> GEMINI
                in 621..722 -> CANCER
                in 723..822 -> LEO
                in 823..922 -> VIRGO
                in 923..1022 -> LIBRA
                in 1023..1121 -> SCORPIO
                in 1122..1221 -> SAGITTARIUS
                in 1222..1231, in 101..119 -> CAPRICORN
                in 120..218 -> AQUARIUS
                else -> PISCES
            }
        }

        fun fromEnglishName(n: String?): ZodiacSign? =
            n?.let { name -> entries.firstOrNull { it.englishName.equals(name, ignoreCase = true) } }

        fun normalize(deg: Double): Double = ((deg % 360) + 360) % 360
        fun from(longitude: Double): ZodiacSign = entries[(normalize(longitude) / 30).toInt() % 12]
        fun degreeWithinSign(longitude: Double): Double = normalize(longitude) % 30
        fun houseSign(house: Int, ascendant: ZodiacSign): ZodiacSign = entries[(ascendant.index + house - 1 + 1200) % 12]
    }
}

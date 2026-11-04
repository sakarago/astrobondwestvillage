package com.astrobond.app.domain

import kotlinx.serialization.json.*
import java.time.Instant
import java.time.LocalDate
import java.util.Locale
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

enum class Planet(val tr: String, val glyph: String, val personal: Boolean, val benefic: Boolean, val malefic: Boolean) {
    SUN("Güneş", "☉", true, true, false),
    MOON("Ay", "☽", true, true, false),
    MERCURY("Merkür", "☿", true, false, false),
    VENUS("Venüs", "♀", true, true, false),
    MARS("Mars", "♂", true, false, true),
    JUPITER("Jüpiter", "♃", false, true, false),
    SATURN("Satürn", "♄", false, false, true),
    URANUS("Uranüs", "♅", false, false, false),
    NEPTUNE("Neptün", "♆", false, false, false),
    PLUTO("Plüton", "♇", false, false, true);

    /** Swift raw value == Swiss Ephemeris body id (0...9). */
    val id: Int get() = ordinal
    val name2: String get() = tr

    companion object { fun fromId(i: Int) = entries.getOrElse(i) { SUN } }
}

/** Raw values are the Turkish strings stored in `charts.chart_json`. */
enum class AspectType(val wire: String, val angle: Double, val orb: Double, val harmonious: Boolean, val glyph: String) {
    CONJUNCTION("Kavuşum", 0.0, 8.0, true, "☌"),
    SEXTILE("Sekstil", 60.0, 4.0, true, "⚹"),
    SQUARE("Kare", 90.0, 6.0, false, "□"),
    TRINE("Üçgen", 120.0, 6.0, true, "△"),
    OPPOSITION("Karşıtlık", 180.0, 8.0, false, "☍");

    companion object {
        fun fromWire(s: String) = entries.firstOrNull { it.wire == s } ?: CONJUNCTION
        fun from(angleDifference: Double): AspectType? {
            val n = ((angleDifference % 360) + 360) % 360
            val a = min(n, 360 - n)
            return entries.firstOrNull { abs(a - it.angle) <= it.orb }
        }
    }
}

data class BirthLocation(
    val city: String, val country: String, val latitude: Double, val longitude: Double, val utcOffset: Double,
) {
    companion object { val UNKNOWN = BirthLocation("Bilinmiyor", "", 0.0, 0.0, 0.0) }
}

data class BirthTime(val hour: Int, val minute: Int, val isKnown: Boolean) {
    val fractionalHour: Double get() = hour + minute / 60.0
    companion object {
        val UNKNOWN = BirthTime(12, 0, false)
        fun known(h: Int, m: Int) = BirthTime(h, m, true)
    }
}

data class BirthData(val date: LocalDate, val time: BirthTime, val location: BirthLocation) {
    /** Port of BirthData.julianDay(): UT = local time - utc offset. */
    fun julianDay(): Double =
        julianDayNumber(date.year, date.monthValue, date.dayOfMonth, time.fractionalHour - location.utcOffset)
}

fun julianDayNumber(year: Int, month: Int, day: Int, hour: Double): Double {
    var y = year; var m = month
    if (m <= 2) { y -= 1; m += 12 }
    val a = (y / 100.0).toInt()
    val b = 2 - a + (a / 4.0).toInt()
    val base = ((365.25 * (y + 4716)).toInt()).toDouble() + ((30.6001 * (m + 1)).toInt()).toDouble() + day + b - 1524.5
    return base + hour / 24.0
}

data class ZodiacPoint(val sign: ZodiacSign, val degree: Double, val longitude: Double) {
    companion object {
        fun of(longitude: Double): ZodiacPoint {
            val l = ZodiacSign.normalize(longitude)
            return ZodiacPoint(ZodiacSign.from(l), ZodiacSign.degreeWithinSign(l), l)
        }
    }
}

data class PlanetPosition(
    val planet: Planet, val sign: ZodiacSign, val degree: Double, val longitude: Double,
    val house: Int, val isRetrograde: Boolean,
)

data class HouseEntity(val number: Int, val sign: ZodiacSign, val cuspLongitude: Double, val planets: List<Planet>) {
    val roman: String get() = listOf("I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII").getOrElse(number - 1) { "$number" }
    val theme: String get() = when (number) {
        1 -> "Kimlik, Görünüm, Yeni Başlangıçlar"
        2 -> "Değerler, Para, Sahip Olunanlar"
        3 -> "İletişim, Kardeşler, Kısa Seyahatler"
        4 -> "Ev, Aile, Kökenler"
        5 -> "Yaratıcılık, Aşk, Eğlence"
        6 -> "Sağlık, Çalışma, Günlük Yaşam"
        7 -> "İlişkiler, Ortaklıklar, Evlilik"
        8 -> "Dönüşüm, Miras, Gizem"
        9 -> "Felsefe, Uzak Seyahatler, Yükseköğretim"
        10 -> "Kariyer, Statü, Kamuoyu Kimliği"
        11 -> "Dostluklar, Gruplar, Umutlar"
        12 -> "Bilinçdışı, Gizlilik, Maneviyat"
        else -> ""
    }
}

data class AspectEntity(val planet1: Planet, val planet2: Planet, val type: AspectType, val orb: Double, val isApplying: Boolean) {
    val strength: Double get() = max(0.0, 1.0 - orb / type.orb)
}

data class SynastryAspect(
    val planet1: Planet, val chart1Sign: ZodiacSign, val planet2: Planet, val chart2Sign: ZodiacSign,
    val type: AspectType, val orb: Double,
) {
    val strength: Double get() = max(0.0, 1.0 - orb / type.orb)
    val description: String get() = "${planet1.glyph}${planet1.tr} ${type.glyph} ${planet2.glyph}${planet2.tr}"
}

data class NatalChart(
    val userId: String,
    val calculatedAt: Instant,
    val birthData: BirthData,
    val planets: List<PlanetPosition>,
    val houses: List<HouseEntity>,
    val aspects: List<AspectEntity>,
    val ascendant: ZodiacPoint,
    val midheaven: ZodiacPoint,
    val dominantElement: Element,
    val dominantModality: Modality,
    val elementCounts: Map<Element, Int>,
    val modalityCounts: Map<Modality, Int>,
) {
    fun planet(p: Planet) = planets.firstOrNull { it.planet == p }
    val sunSign get() = planet(Planet.SUN)?.sign ?: ZodiacSign.ARIES
    val moonSign get() = planet(Planet.MOON)?.sign ?: ZodiacSign.ARIES
    val risingSign get() = ascendant.sign

    companion object {
        fun synastryAspects(c1: NatalChart, c2: NatalChart, limit: Int = 5): List<SynastryAspect> {
            val out = mutableListOf<SynastryAspect>()
            for (p1 in c1.planets) for (p2 in c2.planets) {
                val diff = abs(p1.longitude - p2.longitude)
                val angle = min(diff, 360 - diff)
                for (t in AspectType.entries) {
                    val orb = abs(angle - t.angle)
                    if (orb <= t.orb) out += SynastryAspect(p1.planet, p1.sign, p2.planet, p2.sign, t, orb)
                }
            }
            return out.sortedByDescending { it.strength }.take(limit)
        }
    }
}

class NatalChartException(message: String) : Exception(message)

/**
 * JSON codec matching Swift `Codable` output stored in `charts.chart_json`:
 * Planet = Int, enums = raw strings, `[Enum: Int]` dictionaries = flat [k, v, k, v] arrays,
 * Date = ISO-8601 string (reference-date seconds are also accepted when reading).
 */
object ChartJson {
    private val ref2001 = Instant.parse("2001-01-01T00:00:00Z")

    private fun JsonElement.num() = jsonPrimitive.double
    private fun JsonElement.int() = jsonPrimitive.double.toInt()

    private fun dateOf(e: JsonElement?): Instant {
        val p = e?.jsonPrimitive ?: return Instant.EPOCH
        return if (p.isString) runCatching { Instant.parse(p.content) }.getOrDefault(Instant.EPOCH)
        else ref2001.plusMillis((p.double * 1000).toLong())
    }

    private fun <K> counts(e: JsonElement?, key: (String) -> K): Map<K, Int> {
        val out = linkedMapOf<K, Int>()
        when (e) {
            is JsonArray -> e.chunked(2).forEach { if (it.size == 2) out[key(it[0].jsonPrimitive.content)] = it[1].int() }
            is JsonObject -> e.forEach { (k, v) -> out[key(k)] = v.int() }
            else -> {}
        }
        return out
    }

    fun decode(root: JsonObject): NatalChart {
        val bd = root["birthData"]?.jsonObject
        val bt = bd?.get("timeOfBirth")?.jsonObject
        val bl = bd?.get("location")?.jsonObject
        val birth = BirthData(
            date = LocalDate.ofEpochDay(0),
            time = BirthTime(bt?.get("hour")?.int() ?: 12, bt?.get("minute")?.int() ?: 0, bt?.get("isKnown")?.jsonPrimitive?.boolean ?: false),
            location = BirthLocation(
                bl?.get("city")?.jsonPrimitive?.content ?: "", bl?.get("country")?.jsonPrimitive?.content ?: "",
                bl?.get("latitude")?.num() ?: 0.0, bl?.get("longitude")?.num() ?: 0.0, bl?.get("utcOffset")?.num() ?: 0.0,
            ),
        )
        fun point(o: JsonObject?) = ZodiacPoint.of(o?.get("longitude")?.num() ?: 0.0)
        return NatalChart(
            userId = root["userId"]!!.jsonPrimitive.content,
            calculatedAt = dateOf(root["calculatedAt"]),
            birthData = birth,
            planets = root["planets"]?.jsonArray.orEmpty().map {
                val o = it.jsonObject
                PlanetPosition(
                    Planet.fromId(o["planet"]!!.int()), signOf(o["sign"]!!), o["degree"]!!.num(),
                    o["longitude"]!!.num(), o["house"]!!.int(), o["isRetrograde"]!!.jsonPrimitive.boolean,
                )
            },
            houses = root["houses"]?.jsonArray.orEmpty().map {
                val o = it.jsonObject
                HouseEntity(o["number"]!!.int(), signOf(o["sign"]!!), o["cuspLongitude"]!!.num(),
                    o["planets"]!!.jsonArray.map { p -> Planet.fromId(p.int()) })
            },
            aspects = root["aspects"]?.jsonArray.orEmpty().map {
                val o = it.jsonObject
                AspectEntity(Planet.fromId(o["planet1"]!!.int()), Planet.fromId(o["planet2"]!!.int()),
                    AspectType.fromWire(o["type"]!!.jsonPrimitive.content), o["orb"]!!.num(),
                    o["isApplying"]?.jsonPrimitive?.boolean ?: false)
            },
            ascendant = point(root["ascendant"]?.jsonObject),
            midheaven = point(root["midheaven"]?.jsonObject),
            dominantElement = Element.fromWire(root["dominantElement"]?.jsonPrimitive?.content ?: "fire"),
            dominantModality = Modality.fromWire(root["dominantModality"]?.jsonPrimitive?.content ?: "cardinal"),
            elementCounts = counts(root["elementCounts"]) { Element.fromWire(it) },
            modalityCounts = counts(root["modalityCounts"]) { Modality.fromWire(it) },
        )
    }

    private fun signOf(e: JsonElement) = ZodiacSign.entries.first { it.wire == e.jsonPrimitive.content }

    private fun iso(i: Instant): String =
        java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
            .withZone(java.time.ZoneOffset.UTC).format(i)

    /** Encodes with birth data stripped exactly like iOS `stripBirthData` (public row must not hold real DOB/place). */
    fun encodeStripped(c: NatalChart): JsonObject = buildJsonObject {
        put("userId", c.userId)
        put("calculatedAt", iso(c.calculatedAt))
        putJsonObject("birthData") {
            put("dateOfBirth", iso(Instant.EPOCH))
            putJsonObject("timeOfBirth") {
                put("hour", if (c.birthData.time.isKnown) 12 else 12)
                put("minute", 0)
                put("isKnown", c.birthData.time.isKnown)
            }
            putJsonObject("location") {
                put("city", BirthLocation.UNKNOWN.city); put("country", ""); put("latitude", 0.0)
                put("longitude", 0.0); put("utcOffset", 0.0)
            }
        }
        putJsonArray("planets") {
            c.planets.forEach {
                addJsonObject {
                    put("planet", it.planet.id); put("sign", it.sign.wire); put("degree", it.degree)
                    put("longitude", it.longitude); put("house", it.house); put("isRetrograde", it.isRetrograde)
                }
            }
        }
        putJsonArray("houses") {
            c.houses.forEach { h ->
                addJsonObject {
                    put("number", h.number); put("sign", h.sign.wire); put("cuspLongitude", h.cuspLongitude)
                    putJsonArray("planets") { h.planets.forEach { add(it.id) } }
                }
            }
        }
        putJsonArray("aspects") {
            c.aspects.forEach {
                addJsonObject {
                    put("planet1", it.planet1.id); put("planet2", it.planet2.id); put("type", it.type.wire)
                    put("orb", it.orb); put("isApplying", it.isApplying)
                }
            }
        }
        putJsonObject("ascendant") { put("sign", c.ascendant.sign.wire); put("degree", c.ascendant.degree); put("longitude", c.ascendant.longitude) }
        putJsonObject("midheaven") { put("sign", c.midheaven.sign.wire); put("degree", c.midheaven.degree); put("longitude", c.midheaven.longitude) }
        put("dominantElement", c.dominantElement.wire)
        put("dominantModality", c.dominantModality.wire)
        putJsonArray("elementCounts") { c.elementCounts.forEach { (k, v) -> add(k.wire); add(v) } }
        putJsonArray("modalityCounts") { c.modalityCounts.forEach { (k, v) -> add(k.wire); add(v) } }
    }
}

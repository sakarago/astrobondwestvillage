package com.astrobond.app.astro

import com.astrobond.app.domain.*
import java.time.Instant

/** Port of SimplifiedAstronomyCalculator.swift (Swiss Ephemeris: Placidus when birth time known, else whole sign). */
object ChartEngine {
    fun calculateNatalChart(birth: BirthData, userId: String): NatalChart {
        val jd = birth.julianDay()
        val coords = Planet.entries.associateWith { SwissEph.calc(jd, it.id) }

        val (cusps, asc, mc) = if (birth.time.isKnown) {
            val h = SwissEph.placidus(jd, birth.location.latitude, birth.location.longitude)
            Triple(DoubleArray(12) { ZodiacSign.normalize(h.cusps[it]) }, ZodiacSign.normalize(h.asc), ZodiacSign.normalize(h.mc))
        } else wholeSign(coords.getValue(Planet.SUN).longitude)

        val positions = Planet.entries.map { p ->
            val c = coords.getValue(p)
            val lon = ZodiacSign.normalize(c.longitude)
            PlanetPosition(
                p, ZodiacSign.from(lon), ZodiacSign.degreeWithinSign(lon), lon, houseNumber(lon, cusps),
                retrograde(p, c.speedLongitude),
            )
        }.sortedBy { it.planet.id }

        val houses = (0 until 12).map { i ->
            HouseEntity(i + 1, ZodiacSign.from(cusps[i]), cusps[i], positions.filter { it.house == i + 1 }.map { it.planet })
        }

        val (domEl, elCounts) = dominant(positions, Element.entries, { it.sign.element })
        val (domMod, modCounts) = dominant(positions, Modality.entries, { it.sign.modality })

        return NatalChart(
            userId, Instant.now(), birth, positions, houses, aspects(positions),
            ZodiacPoint.of(asc), ZodiacPoint.of(mc), domEl, domMod, elCounts, modCounts,
        )
    }

    fun transits(jdUt: Double): List<PlanetPosition> = Planet.entries.map { p ->
        val c = SwissEph.calc(jdUt, p.id)
        val lon = ZodiacSign.normalize(c.longitude)
        PlanetPosition(p, ZodiacSign.from(lon), ZodiacSign.degreeWithinSign(lon), lon, 1, retrograde(p, c.speedLongitude))
    }

    private fun retrograde(p: Planet, speed: Double) = when (p) { Planet.SUN, Planet.MOON -> false; else -> speed < 0 }

    private fun wholeSign(sunLon: Double): Triple<DoubleArray, Double, Double> {
        val first = ZodiacSign.from(sunLon).startDegree
        return Triple(DoubleArray(12) { ZodiacSign.normalize(first + it * 30.0) }, first, ZodiacSign.normalize(first + 270))
    }

    private fun houseNumber(longitude: Double, cusps: DoubleArray): Int {
        val l = ZodiacSign.normalize(longitude)
        for (i in 0 until 12) {
            val s = cusps[i]; val e = cusps[(i + 1) % 12]
            if (s <= e) { if (l >= s && l < e) return i + 1 } else if (l >= s || l < e) return i + 1
        }
        return 1
    }

    private fun aspects(pos: List<PlanetPosition>): List<AspectEntity> {
        val out = mutableListOf<AspectEntity>()
        for (i in pos.indices) for (j in i + 1 until pos.size) {
            val p1 = pos[i]; val p2 = pos[j]
            val diff = Math.abs(p1.longitude - p2.longitude)
            val angle = minOf(diff, 360 - diff)
            for (t in AspectType.entries) {
                val orb = Math.abs(angle - t.angle)
                if (orb <= t.orb) {
                    out += AspectEntity(p1.planet, p2.planet, t, orb, p1.planet.personal && !p2.planet.personal)
                    break
                }
            }
        }
        return out.sortedByDescending { it.strength }
    }

    private fun <K> dominant(pos: List<PlanetPosition>, keys: List<K>, sel: (PlanetPosition) -> K): Pair<K, Map<K, Int>> {
        val counts = linkedMapOf<K, Int>().apply { keys.forEach { put(it, 0) } }
        pos.forEach { counts[sel(it)] = counts.getValue(sel(it)) + if (it.planet.personal) 2 else 1 }
        // Swift picks an arbitrary max on ties; first key in declaration order is used here.
        val best = counts.entries.fold(null as Map.Entry<K, Int>?) { a, e -> if (a == null || e.value > a.value) e else a }!!.key
        return best to counts
    }
}

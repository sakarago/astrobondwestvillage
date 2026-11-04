package com.astrobond.app.ui.profile

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Fill
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.input.pointer.pointerInput
import com.astrobond.app.domain.*
import com.astrobond.app.ui.theme.hex
import kotlin.math.*

fun planetColor(p: Planet): Color = hex(when (p) {
    Planet.SUN -> "#E8A24A"; Planet.MOON -> "#6BA6E8"; Planet.MERCURY -> "#86C06A"; Planet.VENUS -> "#9ACB6E"; Planet.MARS -> "#E8736B"
    Planet.JUPITER -> "#E0944A"; Planet.SATURN -> "#C9CFD9"; Planet.URANUS -> "#D98CC0"; Planet.NEPTUNE -> "#6B8CE8"; Planet.PLUTO -> "#B07FD0"
})
fun signColor(s: ZodiacSign): Color = hex(when (s.element) { Element.FIRE -> "#E8736B"; Element.EARTH -> "#8FC06A"; Element.AIR -> "#5BC6C6"; Element.WATER -> "#6BA6E8" })
fun aspectColor(t: AspectType): Color = hex(when (t) { AspectType.TRINE, AspectType.SEXTILE -> "#6EA4FF"; AspectType.SQUARE, AspectType.OPPOSITION -> "#FF6E66"; AspectType.CONJUNCTION -> "#D4D8E0" })

private class Laid(val p: PlanetPosition, val lon: Double, val radiusOffset: Double)

private fun layout(planets: List<PlanetPosition>): List<Laid> {
    val sorted = planets.sortedBy { it.longitude }
    if (sorted.isEmpty()) return emptyList()
    val minSep = 7.0
    val display = sorted.map { it.longitude }.toMutableList()
    val radius = MutableList(sorted.size) { 0.0 }
    for (i in 1 until sorted.size) {
        val prev = display[i - 1]; var cur = display[i]
        var delta = cur - prev; if (delta < 0) delta += 360
        if (delta < minSep) { cur = prev + minSep; if (cur >= 360) cur -= 360; display[i] = cur; radius[i] = if (radius[i - 1] == 0.0) 1.0 else 0.0 }
    }
    if (sorted.size > 1) { var delta = (display[0] + 360) - display[sorted.size - 1]; if (delta < 0) delta += 360; if (delta < minSep) radius[0] = 1.0 }
    return sorted.indices.map { Laid(sorted[it], display[it], radius[it]) }
}

private fun degreeLabel(lon: Double): String {
    val w = ZodiacSign.degreeWithinSign(lon); val d = w.toInt(); val m = ((w - d) * 60).toInt()
    return "%d°%02d'".format(d, m)
}

/**
 * Port of ChartWheelView: zodiac band, house cusps, planets with anti-collision, aspect web, AC/IC/DC/MC.
 * Ascendant at the left. Android addition: drag around the centre to rotate the wheel; tap a planet for details.
 */
@Composable
fun ChartWheel(chart: NatalChart, modifier: Modifier = Modifier, onPlanetTap: (PlanetPosition) -> Unit) {
    var rot by remember { mutableFloatStateOf(0f) }
    var canvasSize by remember { mutableStateOf(androidx.compose.ui.unit.IntSize.Zero) }
    val laid = remember(chart) { layout(chart.planets) }
    val aspects = remember(chart) { chart.aspects.sortedByDescending { it.strength } }

    // geometry shared by drawing and hit-testing
    fun geom(size: Float): FloatArray { val rim = max(18f, size * 0.055f); val R = size / 2 - rim; return floatArrayOf(R, R * 0.80f, R * 0.54f, R * 0.32f) }
    fun pt(lon: Double, r: Float, size: Float): Offset {
        val rel = lon - chart.ascendant.longitude - rot
        val a = Math.toRadians(270.0 - rel)
        return Offset(size / 2 + (r * sin(a)).toFloat(), size / 2 - (r * cos(a)).toFloat())
    }

    Canvas(
        modifier.fillMaxWidth().aspectRatio(1f)
            .pointerInput(chart) {
                detectTapGestures { tap ->
                    val size = this.size.width.toFloat(); val g = geom(size); val base = (g[1] + g[2]) / 2
                    laid.minByOrNull { (pt(it.lon, base + it.radiusOffset.toFloat() * (g[1] - g[2]) * 0.32f, size) - tap).getDistance() }
                        ?.takeIf { (pt(it.lon, base + it.radiusOffset.toFloat() * (g[1] - g[2]) * 0.32f, size) - tap).getDistance() < size * 0.06f }?.let { onPlanetTap(it.p) }
                }
            }
            .pointerInput(chart) {
                detectDragGestures { change, drag ->
                    val c = Offset(this.size.width / 2f, this.size.height / 2f)
                    val p = change.position - c; val prev = p - drag
                    // finger clockwise => wheel clockwise
                    rot += (Math.toDegrees(atan2(p.y, p.x).toDouble()) - Math.toDegrees(atan2(prev.y, prev.x).toDouble())).toFloat()
                    change.consume()
                }
            },
    ) {
        val size = this.size.width
        canvasSize = androidx.compose.ui.unit.IntSize(size.roundToInt(), size.roundToInt())
        val g = geom(size); val c1 = g[0]; val c2 = g[1]; val c3 = g[2]; val c4 = g[3]
        val c = Offset(size / 2, size / 2)
        val aspectR = c4 * 0.90f
        val ring = Color.White.copy(0.78f); val ringMid = Color.White.copy(0.42f); val ringSoft = Color.White.copy(0.28f)

        drawCircle(hex("#0C0D12").copy(0.94f), c1, c)
        for (sign in ZodiacSign.entries) {
            val start = sign.startDegree
            val path = Path()
            path.moveTo(pt(start, c1, size).x, pt(start, c1, size).y)
            for (s in 1..16) pt(start + s * (30.0 / 16), c1, size).let { path.lineTo(it.x, it.y) }
            for (s in 16 downTo 0) pt(start + s * (30.0 / 16), c2, size).let { path.lineTo(it.x, it.y) }
            path.close()
            drawPath(path, signColor(sign).copy(0.22f), style = Fill)
            drawPath(path, signColor(sign).copy(0.28f), style = Stroke(0.8f))
        }
        drawCircle(ring, c1, c, style = Stroke(3f)); drawCircle(ring, c2, c, style = Stroke(2.5f))
        drawCircle(ringMid, c3, c, style = Stroke(2f)); drawCircle(ringMid, c4, c, style = Stroke(2f)); drawCircle(ringSoft, aspectR * 0.18f, c, style = Stroke(1.4f))
        for (i in 0 until 12) drawLine(ring, pt(i * 30.0, c1, size), pt(i * 30.0, c2, size), 2f)
        for (d in 0 until 360) {
            val major = d % 10 == 0; val mid = d % 5 == 0
            val len = (c1 - c2) * (if (major) 0.38f else if (mid) 0.22f else 0.12f)
            drawLine(if (major) ring else ringSoft, pt(d.toDouble(), c1, size), pt(d.toDouble(), c1 - len, size), if (major) 1.8f else if (mid) 1.1f else 0.7f)
        }
        for (h in chart.houses) {
            val ang = h.number in listOf(1, 4, 7, 10)
            drawLine(if (ang) Color.White.copy(0.88f) else ringSoft, pt(h.cuspLongitude, c1, size), pt(h.cuspLongitude, if (ang) c4 * 0.12f else c4, size), if (ang) 3f else 1.7f)
        }
        for (p in chart.planets) drawLine(planetColor(p.planet).copy(0.55f), pt(p.longitude, c3, size), pt(p.longitude, c4, size), 1.4f)
        for (a in aspects) {
            val p1 = chart.planet(a.planet1) ?: continue; val p2 = chart.planet(a.planet2) ?: continue
            val (bw, dash) = when (a.type) { AspectType.OPPOSITION -> 1.45f to null; AspectType.TRINE -> 1.30f to null; AspectType.SQUARE -> 1.20f to null
                AspectType.SEXTILE -> 1.0f to floatArrayOf(7f, 5.6f); AspectType.CONJUNCTION -> 0.95f to floatArrayOf(3.2f, 4.4f) }
            drawLine(aspectColor(a.type).copy((0.42 + 0.50 * a.strength).toFloat()), pt(p1.longitude, aspectR, size), pt(p2.longitude, aspectR, size),
                max(0.85f, bw * (0.75f + 0.55f * a.strength.toFloat())) * 2f, pathEffect = dash?.let { PathEffect.dashPathEffect(it) })
        }
        drawCircle(Color.White.copy(0.85f), 6f, c)

        // text layer
        fun text(s: String, at: Offset, px: Float, color: Color, bold: Boolean = false, bg: Color? = null) {
            val paint = android.graphics.Paint().apply { isAntiAlias = true; textSize = px; textAlign = android.graphics.Paint.Align.CENTER; this.color = color.toArgb(); isFakeBoldText = bold }
            if (bg != null) {
                val w = paint.measureText(s) + px * 0.5f
                drawContext.canvas.nativeCanvas.drawRoundRect(at.x - w / 2, at.y - px * 0.8f, at.x + w / 2, at.y + px * 0.35f, px, px, android.graphics.Paint().apply { this.color = bg.toArgb() })
            }
            drawContext.canvas.nativeCanvas.drawText(s, at.x, at.y + px * 0.35f, paint)
        }
        val zr = (c1 + c2) / 2
        for (s in ZodiacSign.entries) text(s.glyph, pt(s.startDegree + 15, zr, size), size * 0.046f, signColor(s))
        for (h in chart.houses) text(degreeLabel(h.cuspLongitude), pt(h.cuspLongitude, c1 * 0.935f, size), size * 0.024f, Color.White.copy(0.82f), true, hex("#0E0F14").copy(0.82f))
        val romanR = (c3 + c4) / 2
        chart.houses.forEachIndexed { i, h ->
            val next = chart.houses[(i + 1) % chart.houses.size]
            val span = ((next.cuspLongitude - h.cuspLongitude) + 360) % 360
            text(h.roman, pt(h.cuspLongitude + span / 2, romanR, size), size * 0.030f, Color.White.copy(0.48f))
        }
        for (h in chart.houses.filter { it.number in listOf(1, 4, 7, 10) }) {
            val label = when (h.number) { 1 -> "AC"; 4 -> "IC"; 7 -> "DC"; else -> "MC" }
            text(label, pt(h.cuspLongitude, c3 * 0.90f, size), size * 0.026f, hex("#F2F4F8"), true, hex("#12131A").copy(0.92f))
        }
        val base = (c2 + c3) / 2; val band = c2 - c3
        for (l in laid) {
            val r = base + l.radiusOffset.toFloat() * band * 0.32f
            text(l.p.planet.glyph, pt(l.lon, r, size), size * 0.050f, planetColor(l.p.planet))
            text(degreeLabel(l.p.longitude), pt(l.lon, r - size * 0.040f, size), size * 0.022f, Color.White.copy(0.72f), true)
        }
    }
}

private fun Color.toArgb(): Int = android.graphics.Color.argb((alpha * 255).toInt(), (red * 255).toInt(), (green * 255).toInt(), (blue * 255).toInt())

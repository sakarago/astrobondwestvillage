package com.astrobond.app.ui.match

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.sp
import com.astrobond.app.domain.ZodiacSign
import com.astrobond.app.ui.theme.ABFont
import com.astrobond.app.ui.theme.ABColor
import com.astrobond.app.ui.theme.hex
import kotlin.math.cos
import kotlin.math.sin

private val Warm = hex("#EBD3B0")

/**
 * Simplified Compose rendition of iOS `CosmicMatchWheel`: a zodiac disk that spins 2 full turns over 6s,
 * a pulsing centre button ("EŞLEŞ"), and — once revealed — a highlighted wedge on the matched sign.
 * (The iOS atmosphere effects — star streaks, orbit planets, ripples — are not ported yet.)
 */
@Composable
fun CosmicWheel(size: Dp, rotation: Float, spinning: Boolean, revealed: Boolean, revealedSign: ZodiacSign?, tapLabel: String, onTap: () -> Unit) {
    val angle by animateFloatAsState(rotation, tween(if (spinning) 6000 else 0, easing = FastOutSlowInEasing), label = "wheel")
    val pulse by rememberInfiniteTransition(label = "pulse").animateFloat(0.55f, 1f, infiniteRepeatable(tween(1400), RepeatMode.Reverse), label = "p")
    val accent = if (revealed) Warm else ABColor.Lavender
    Box(Modifier.size(size).clickable(interactionSource = remember { MutableInteractionSource() }, indication = null, enabled = !spinning && !revealed, onClick = onTap), contentAlignment = Alignment.Center) {
        Canvas(Modifier.size(size).rotate(angle)) {
            val r = this.size.minDimension / 2
            val c = center
            drawCircle(Brush.radialGradient(listOf(accent.copy(0.22f), Color.Transparent), c, r), r)
            drawCircle(accent.copy(0.8f), r * 0.98f, c, style = Stroke(2f))
            drawCircle(accent.copy(0.35f), r * 0.66f, c, style = Stroke(1.5f))
            drawCircle(Color.Black.copy(0.35f), r * 0.97f, c)
            drawCircle(accent.copy(0.5f), r * 0.80f, c, style = Stroke(1f))
            val paint = android.graphics.Paint().apply {
                isAntiAlias = true; color = android.graphics.Color.argb(230, 230, 220, 255)
                textSize = r * 0.12f; textAlign = android.graphics.Paint.Align.CENTER
            }
            ZodiacSign.entries.forEachIndexed { i, s ->
                val a = Math.toRadians((i * 30 + 15 - 90).toDouble())
                val rr = r * 0.73f
                rotate(i * 30f, c) { drawLine(accent.copy(0.4f), Offset(c.x, c.y - r * 0.66f), Offset(c.x, c.y - r * 0.97f), 1.2f) }
                drawContext.canvas.nativeCanvas.drawText(s.glyph, (c.x + rr * cos(a)).toFloat(), (c.y + rr * sin(a) + paint.textSize * 0.35f).toFloat(), paint)
            }
            if (revealed && revealedSign != null) {
                rotate(revealedSign.index * 30f, c) {
                    drawArc(accent.copy(0.35f), -90f, 30f, true, Offset(c.x - r * 0.97f, c.y - r * 0.97f), Size(r * 1.94f, r * 1.94f))
                }
            }
        }
        // fixed Aries pointer
        if (!spinning && !revealed) Text("▲", color = ABColor.LavenderSoft.copy(0.7f), fontSize = (size.value * 0.04f).sp, modifier = Modifier.align(Alignment.TopCenter).padding(top = size * 0.12f))
        // centre
        Box(Modifier.size(size * 0.45f), contentAlignment = Alignment.Center) {
            Canvas(Modifier.size(size * 0.45f)) {
                val r = this.size.minDimension / 2
                drawCircle(Brush.radialGradient(listOf(accent.copy(0.28f), Color(0xEE0F0B1D)), center, r), r)
                drawCircle(accent.copy(0.8f), r, center, style = Stroke(2.4f))
            }
            when {
                spinning -> Text("✦", color = hex("#FFD36B").copy(pulse), fontSize = (size.value * 0.13f).sp)
                revealed -> Text(revealedSign?.glyph ?: "✦", color = Warm, fontSize = (size.value * 0.16f).sp)
                else -> androidx.compose.foundation.layout.Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("✦", color = hex("#FFD36B").copy(pulse), fontSize = (size.value * 0.13f).sp)
                    Text(tapLabel, style = ABFont.body((size.value * 0.04f), FontWeight.Bold), color = Color.White, letterSpacing = 2.6.sp)
                }
            }
        }
    }
}

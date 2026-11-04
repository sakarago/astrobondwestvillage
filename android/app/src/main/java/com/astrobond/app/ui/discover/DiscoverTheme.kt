package com.astrobond.app.ui.discover

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.astrobond.app.R
import com.astrobond.app.discover.*
import com.astrobond.app.domain.Element
import com.astrobond.app.domain.ZodiacSign
import com.astrobond.app.ui.theme.*
import kotlin.random.Random

/** Port of `ScreenBackdropView` (Features/Discover/DiscoverTheme.swift). */
@Composable
fun ScreenBackdropView(backdrop: Backdrop, gradient: List<String> = emptyList()) {
    Box(Modifier.fillMaxSize()) {
        when (backdrop) {
            Backdrop.NIGHT -> Night(DT.BgTop, 11)
            Backdrop.VIOLET -> Violet()
            Backdrop.PEACH -> Box(Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(hex("#FBEEE3"), hex("#F1D3BE")))))
            Backdrop.HERO, Backdrop.LOVE, Backdrop.GUIDE -> {
                Image(painterResource(when (backdrop) { Backdrop.HERO -> R.drawable.discover_hero; Backdrop.LOVE -> R.drawable.discover_love; else -> R.drawable.discover_guide }), null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
                Box(Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(Color.Black.copy(0.4f), Color.Black.copy(0.82f)))))
            }
            Backdrop.GRADIENT -> Box(Modifier.fillMaxSize().background(Brush.linearGradient(gradient.map { hex(it) }.ifEmpty { listOf(DT.BgTop, DT.BgMid) })))
        }
    }
}

@Composable
private fun Stars(seed: Int, count: Int, color: Color, rMax: Float) {
    Canvas(Modifier.fillMaxSize()) {
        val rnd = Random(seed)
        repeat(count) {
            drawCircle(color.copy(alpha = 0.2f + rnd.nextFloat() * 0.6f), (0.4f + rnd.nextFloat() * rMax) * 1.5f, Offset(rnd.nextFloat() * size.width, rnd.nextFloat() * size.height))
        }
    }
}

@Composable
private fun Night(top: Color, seed: Int) {
    Box(Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(top, DT.BgMid, DT.BgBottom)))) {
        Box(Modifier.fillMaxSize().background(Brush.radialGradient(listOf(hex("#7A5A4A").copy(0.30f), Color.Transparent), Offset(540f, 100f), 1100f)))
        Stars(seed, 70, Color.White, 1.3f)
    }
}

@Composable
private fun Violet() {
    Box(Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(hex("#07040F"), hex("#150B2E"), hex("#07040F"))))) {
        Box(Modifier.fillMaxSize().background(Brush.radialGradient(listOf(hex("#7B5CFF").copy(0.32f), Color.Transparent), Offset(540f, 1000f), 900f)))
        Stars(23, 90, hex("#E6DCFF"), 1.6f)
    }
}

val Backdrop.isLight get() = this == Backdrop.PEACH

/** Standard page: backdrop, back button (+ optional share), optional title block. */
@Composable
fun DiscoverScaffold(backdrop: Backdrop, onBack: () -> Unit, title: String? = null, subtitle: String? = null, share: (() -> Unit)? = null, gradient: List<String> = emptyList(), content: @Composable ColumnScope.() -> Unit) {
    BackHandler(onBack = onBack)
    val th = Th(backdrop.isLight)
    CompositionLocalProvider(LocalTh provides th) {
        Box(Modifier.fillMaxSize()) {
            ScreenBackdropView(backdrop, gradient)
            Column(Modifier.fillMaxSize().statusBarsPadding().verticalScroll(rememberScrollState()).padding(horizontal = 20.dp).padding(top = 8.dp, bottom = 130.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    CircleButton("‹", th, onBack)
                    if (share != null) CircleButton("⇪", th, share)
                }
                if (title != null) Text(title, style = ABFont.display(34f, FontWeight.Normal), color = th.primary)
                if (subtitle != null) Text(subtitle, style = ABFont.body(14f), color = th.secondary)
                content()
            }
        }
    }
}

@Composable
fun CircleButton(label: String, th: Th, onClick: () -> Unit) {
    Box(Modifier.size(36.dp).clip(CircleShape).background(th.chipOff).border(1.dp, th.cardStroke, CircleShape).clickable(onClick = onClick), contentAlignment = Alignment.Center) {
        Text(label, color = th.primary, fontSize = 20.sp)
    }
}

@Composable
fun PillChips(items: List<String>, selection: Int, onSelect: (Int) -> Unit) {
    val th = LocalTh.current
    Row(Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        items.forEachIndexed { i, t ->
            Text(t, style = ABFont.body(13f, FontWeight.SemiBold), color = if (selection == i) Color.White else th.secondary,
                modifier = Modifier.clip(CircleShape).background(if (selection == i) th.chipOn else th.chipOff).border(1.dp, th.cardStroke, CircleShape).clickable { onSelect(i) }.padding(horizontal = 16.dp, vertical = 8.dp))
        }
    }
}

/** Dark glass row used in all list screens (`DTRow`). */
@Composable
fun DTRow(title: String, subtitle: String? = null, caption: String? = null, onClick: () -> Unit, leading: @Composable () -> Unit) {
    val th = LocalTh.current
    Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(20.dp)).background(th.cardFill).border(1.dp, th.cardStroke, RoundedCornerShape(20.dp)).clickable(onClick = onClick).padding(14.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
        leading()
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(title, style = ABFont.body(15f, FontWeight.SemiBold), color = th.primary)
            if (caption != null) Text(caption, style = ABFont.body(11.5f, FontWeight.Medium), color = th.accent)
            if (subtitle != null) Text(subtitle, style = ABFont.body(12f), color = th.secondary)
        }
        Text("›", color = th.secondary, fontSize = 20.sp)
    }
}

/** Small glowing sphere (list icon). */
@Composable
fun Orb(color: String, size: Dp = 46.dp) {
    val c = hex(color)
    Box(Modifier.size(size).shadow(8.dp, CircleShape, spotColor = c.copy(0.5f)).clip(CircleShape)
        .background(Brush.radialGradient(listOf(c.copy(0.95f), c.copy(0.55f), Color.Black.copy(0.85f)), Offset(size.value * 1.3f * 0.3f, size.value * 1.3f * 0.28f), size.value * 2.6f))
        .border(0.8.dp, Color.White.copy(0.22f), CircleShape))
}

@Composable
fun EventOrb(kind: EventKind, size: Dp = 46.dp) = when (kind) {
    EventKind.FULL_MOON -> Orb("#CFC2F2", size)
    EventKind.NEW_MOON -> Orb("#4B3C80", size)
    EventKind.RETROGRADE -> Orb("#C0674F", size)
    EventKind.SOLSTICE -> Orb("#E8B867", size)
    EventKind.ECLIPSE -> Box(Modifier.size(size), contentAlignment = Alignment.Center) {
        Box(Modifier.size(size * 1.3f).background(Brush.radialGradient(listOf(hex("#FFD9A0").copy(0.9f), Color.Transparent)), CircleShape))
        Box(Modifier.size(size * 0.8f).background(Color.Black, CircleShape))
    }
}

fun elementTint(s: ZodiacSign): Color = when (s.element) {
    Element.FIRE -> hex("#C25A3A"); Element.EARTH -> hex("#6B7F4A"); Element.AIR -> hex("#7A62B5"); Element.WATER -> hex("#3F78A8")
}

/** Ornate violet tarot card (crescent / sun emblems), simplified from `VioletTarotCard`. */
@Composable
fun VioletTarotCard(sun: Boolean, width: Dp, glow: Boolean = false, modifier: Modifier = Modifier) {
    val foil = hex("#E9C9F2"); val lilac = hex("#9B86FF"); val rose = hex("#E8BCD2")
    val h = width * 1.66f
    Canvas(modifier.size(width, h).shadow(if (glow) 20.dp else 10.dp, RoundedCornerShape(width * 0.1f), spotColor = lilac.copy(if (glow) 0.95f else 0.45f))) {
        val w = size.width; val hh = size.height
        drawRoundRect(Brush.verticalGradient(listOf(hex("#1D1042"), hex("#08051C"))), cornerRadius = androidx.compose.ui.geometry.CornerRadius(w * 0.1f))
        drawRoundRect(Brush.linearGradient(listOf(foil, lilac.copy(0.7f), foil.copy(0.8f))), cornerRadius = androidx.compose.ui.geometry.CornerRadius(w * 0.1f), style = Stroke(w * 0.016f))
        drawRoundRect(foil.copy(0.35f), Offset(w * 0.055f, w * 0.055f), Size(w * 0.89f, hh - w * 0.11f), androidx.compose.ui.geometry.CornerRadius(w * 0.07f), Stroke(1f))
        drawRoundRect(foil.copy(0.30f), Offset(w * 0.13f, hh * 0.1f), Size(w * 0.74f, hh * 0.8f), androidx.compose.ui.geometry.CornerRadius(w * 0.37f), Stroke(1.2f))
        val cx = w / 2; val cy = hh / 2
        if (!sun) {
            drawCircle(rose.copy(0.25f), w * 0.25f, Offset(cx, cy))
            drawCircle(Brush.linearGradient(listOf(hex("#F4D6E4"), rose)), w * 0.15f, Offset(cx, cy))
            drawCircle(hex("#1D1042"), w * 0.13f, Offset(cx + w * 0.075f, cy - w * 0.02f))
        } else {
            drawCircle(Brush.radialGradient(listOf(rose.copy(0.55f), Color.Transparent), Offset(cx, cy), w * 0.42f), w * 0.42f, Offset(cx, cy))
            repeat(24) { i ->
                val a = Math.toRadians(i * 15.0); val r1 = w * 0.16f; val r2 = w * (if (i % 2 == 0) 0.38f else 0.31f)
                drawLine(rose, Offset(cx + (r1 * Math.cos(a)).toFloat(), cy + (r1 * Math.sin(a)).toFloat()), Offset(cx + (r2 * Math.cos(a)).toFloat(), cy + (r2 * Math.sin(a)).toFloat()), if (i % 2 == 0) 2f else 1.2f)
            }
            drawCircle(rose, w * 0.14f, Offset(cx, cy), style = Stroke(2f))
            drawCircle(Color.White, w * 0.06f, Offset(cx, cy))
        }
    }
}

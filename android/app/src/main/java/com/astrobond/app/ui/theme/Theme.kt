package com.astrobond.app.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

/** iOS `Th`: semantic colours that flip between dark pages and light (peach) pages. */
data class Th(val light: Boolean = false) {
    val primary: Color get() = if (light) DT.Ink else Color.White
    val secondary: Color get() = if (light) DT.InkSoft else Color.White.copy(alpha = 0.65f)
    val accent: Color get() = if (light) hex("#9A5B3C") else DT.Accent
    val cardFill: Color get() = if (light) Color.White.copy(alpha = 0.62f) else Color.Black.copy(alpha = 0.38f)
    val cardStroke: Color get() = if (light) Color.White.copy(alpha = 0.85f) else Color.White.copy(alpha = 0.16f)
    val chipOn: Color get() = if (light) hex("#3A2E3F") else hex("#7A5A4A").copy(alpha = 0.7f)
    val chipOff: Color get() = if (light) Color.Black.copy(alpha = 0.05f) else Color.White.copy(alpha = 0.08f)
}

val LocalTh = staticCompositionLocalOf { Th() }

private val AstroBondColors = darkColorScheme(
    primary = ABColor.Lavender,
    onPrimary = Color.White,
    primaryContainer = ABColor.Lavender.copy(alpha = 0.25f),
    onPrimaryContainer = ABColor.LavenderSoft,
    secondary = DT.Accent,
    onSecondary = DT.Ink,
    tertiary = DT.Gold,
    background = ABColor.Backdrop,
    onBackground = ABColor.Ink,
    surface = DT.BgMid,
    onSurface = ABColor.Ink,
    surfaceVariant = DT.BgTop,
    onSurfaceVariant = ABColor.InkMuted,
    outline = Color.White.copy(alpha = 0.16f),
    error = hex("#C0674F"),
)

/** The app is dark-only (iOS forces a cosmic dark look everywhere). */
@Composable
fun AstroBondTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = AstroBondColors, typography = ABTypography) {
        CompositionLocalProvider(LocalTh provides Th(light = false), content = content)
    }
}

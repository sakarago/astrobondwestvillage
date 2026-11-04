package com.astrobond.app.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.sp

/**
 * iOS `ABFont`: display = serif, body/label = rounded.
 * Android has no system rounded face; SansSerif is used until a rounded font
 * (e.g. Nunito) is bundled in res/font.
 */
object ABFont {
    fun display(size: Float, weight: FontWeight = FontWeight.SemiBold) =
        TextStyle(fontFamily = FontFamily.Serif, fontSize = size.sp, fontWeight = weight)

    fun body(size: Float, weight: FontWeight = FontWeight.Normal) =
        TextStyle(fontFamily = FontFamily.SansSerif, fontSize = size.sp, fontWeight = weight)

    fun label(size: Float) = body(size, FontWeight.SemiBold)
}

private fun TextStyle.lh(lineHeight: TextUnit) = copy(lineHeight = lineHeight)

val ABTypography = Typography(
    displayLarge = ABFont.display(34f, FontWeight.Normal),
    headlineMedium = ABFont.display(28f, FontWeight.Normal),
    titleLarge = ABFont.display(22f),
    titleMedium = ABFont.body(16f, FontWeight.SemiBold),
    bodyLarge = ABFont.body(16f).lh(22.sp),
    bodyMedium = ABFont.body(14f).lh(20.sp),
    bodySmall = ABFont.body(12f),
    labelLarge = ABFont.label(16.5f),
    labelMedium = ABFont.label(13f),
    labelSmall = ABFont.label(12f),
)

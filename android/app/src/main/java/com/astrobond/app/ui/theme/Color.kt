package com.astrobond.app.ui.theme

import androidx.compose.ui.graphics.Color

/** Parses "#RRGGBB" / "#AARRGGBB" like iOS `Color(hex:)`. */
fun hex(value: String): Color {
    val s = value.trim().removePrefix("#")
    val v = s.toLong(16)
    return when (s.length) {
        3 -> Color(
            red = ((v shr 8) and 0xF).toInt() * 17,
            green = ((v shr 4) and 0xF).toInt() * 17,
            blue = (v and 0xF).toInt() * 17,
        )
        6 -> Color(
            red = ((v shr 16) and 0xFF).toInt(),
            green = ((v shr 8) and 0xFF).toInt(),
            blue = (v and 0xFF).toInt(),
        )
        8 -> Color(
            alpha = ((v shr 24) and 0xFF).toInt(),
            red = ((v shr 16) and 0xFF).toInt(),
            green = ((v shr 8) and 0xFF).toInt(),
            blue = (v and 0xFF).toInt(),
        )
        else -> Color.Black
    }
}

/** iOS `ABColor` (DesignSystem/ColorHex.swift). */
object ABColor {
    val Lavender = hex("#8F7FF7")
    val LavenderSoft = hex("#D6CFFF")
    val Ink = hex("#F4F6FA")
    val InkMuted = hex("#A6ACB6")
    val Space = hex("#0A0A0C")
    val Backdrop = hex("#040308")
}

/** iOS `DT` (Features/Discover/DiscoverTheme.swift): warm night / peach palette. */
object DT {
    val BgTop = hex("#150F26")
    val BgMid = hex("#1C1530")
    val BgBottom = hex("#0F0B1D")
    val Card = hex("#1C1530")
    val Accent = hex("#FFD9A0")
    val AccentSoft = hex("#F1C9A0")
    val Violet = hex("#C9A27A") // warm line colour (name kept to match iOS)
    val Cream = hex("#F6EBE1")
    val Ink = hex("#2B2237")
    val InkSoft = hex("#6E6272")
    val Gold = hex("#E4B867")
}

package com.astrobond.app.ui.theme

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.astrobond.app.R

/** Border gradient shared by crystal surfaces (iOS CrystalPlate stroke). */
private val CrystalStroke = Brush.linearGradient(
    listOf(Color.White.copy(0.50f), ABColor.LavenderSoft.copy(0.22f), Color.White.copy(0.06f)),
)

/**
 * Crystal glass plate. iOS uses `.ultraThinMaterial`; Compose has no cheap
 * backdrop blur on all API levels, so frost is approximated with a translucent
 * dark fill + the same bevel gradient and stroke.
 */
fun Modifier.crystalPlate(shape: Shape = RoundedCornerShape(22.dp)): Modifier =
    this
        .shadow(14.dp, shape, ambientColor = ABColor.Lavender.copy(0.12f), spotColor = Color.Black.copy(0.22f))
        .clip(shape)
        .background(Color(0x990F0B1D))
        .background(Color.White.copy(alpha = 0.04f))
        .background(
            Brush.linearGradient(listOf(Color.White.copy(0.18f), Color.Transparent, Color.Black.copy(0.16f))),
        )
        .border(1.dp, CrystalStroke, shape)

/** Pill-shaped crystal surface (tab bar, CTA, glow inputs). */
fun Modifier.crystalCapsule(): Modifier = crystalPlate(RoundedCornerShape(percent = 50))

/** iOS `CosmicBackdrop`: near-black base + starfield image + lavender glow + vignette. */
@Composable
fun CosmicBackdrop(modifier: Modifier = Modifier, content: @Composable BoxScope.() -> Unit = {}) {
    Box(modifier.fillMaxSize().background(ABColor.Backdrop)) {
        Image(
            painter = painterResource(R.drawable.cosmic_match_bg),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.fillMaxSize(),
        )
        Box(
            Modifier.fillMaxSize().background(
                Brush.radialGradient(
                    colors = listOf(ABColor.Lavender.copy(0.10f), Color.Transparent),
                    center = Offset(Float.POSITIVE_INFINITY, 0f),
                    radius = 1000f,
                ),
            ),
        )
        Box(
            Modifier.fillMaxSize().background(
                Brush.radialGradient(colors = listOf(Color.Transparent, Color.Black.copy(0.5f))),
            ),
        )
        content()
    }
}

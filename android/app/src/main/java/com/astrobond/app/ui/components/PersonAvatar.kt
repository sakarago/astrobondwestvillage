package com.astrobond.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.SubcomposeAsyncImage
import com.astrobond.app.domain.ZodiacSign
import com.astrobond.app.ui.theme.ABColor
import com.astrobond.app.ui.theme.hex

/** Port of Features/Shared/PersonAvatar.swift. Photo only when `unlocked`, else cartoon avatar, else sun glyph / initial. */
@Composable
fun PersonAvatar(name: String, photoURL: String?, cartoonAvatarId: String?, sunSign: ZodiacSign?, unlocked: Boolean, size: Dp = 52.dp, modifier: Modifier = Modifier) {
    val ctx = LocalContext.current
    @Composable fun fallback() {
        val cartoon = CartoonAvatar.from(ctx, cartoonAvatarId)
        if (cartoon != null) CartoonAvatarView(cartoon, size)
        else Text(sunSign?.glyph ?: name.take(1).uppercase(), color = Color.White.copy(0.9f), fontSize = (size.value * 0.38f).sp)
    }
    Box(
        modifier.size(size).clip(CircleShape)
            .background(Brush.linearGradient(listOf(ABColor.Lavender.copy(0.45f), hex("#2A2438"))))
            .border(1.2.dp, Brush.linearGradient(listOf(Color.White.copy(0.55f), ABColor.LavenderSoft.copy(0.3f))), CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        if (unlocked && !photoURL.isNullOrEmpty()) {
            SubcomposeAsyncImage(photoURL, null, contentScale = ContentScale.Crop, modifier = Modifier.size(size), error = { fallback() }, loading = { fallback() })
        } else fallback()
    }
}

package com.astrobond.app.ui.components

import android.content.Context
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.astrobond.app.domain.Gender
import com.astrobond.app.ui.theme.hex
import kotlinx.serialization.json.*

/**
 * Port of DesignSystem/CartoonAvatar.swift. Ids (m01…m18, f01…f18) are the values stored in
 * `profiles.cartoon_avatar_id`. Colours come from assets/avatars.json (generated from the Swift
 * table); the drawing is a simplified flat rendition of the iOS illustration.
 */
data class CartoonAvatar(
    val id: String, val skin: String, val hair: String, val iris: String, val blush: String,
    val bg1: String, val bg2: String, val cloth: String, val hairStyle: String, val eyes: String, val smile: String,
) {
    val isMalePack get() = id.startsWith("m")

    companion object {
        private var cache: List<CartoonAvatar>? = null
        fun all(context: Context): List<CartoonAvatar> = cache ?: synchronized(this) {
            cache ?: Json.parseToJsonElement(context.assets.open("avatars.json").bufferedReader().use { it.readText() })
                .jsonArray.map {
                    val o = it.jsonObject
                    fun s(k: String) = o[k]!!.jsonPrimitive.content
                    CartoonAvatar(s("id"), s("skin"), s("hair"), s("iris"), s("blush"), s("bg1"), s("bg2"), s("cloth"), s("hairStyle"), s("eyes"), s("smile"))
                }.also { cache = it }
        }

        fun options(context: Context, g: Gender): List<CartoonAvatar> = all(context).let { list ->
            when (g) { Gender.MAN -> list.filter { it.isMalePack }; Gender.WOMAN -> list.filter { !it.isMalePack }; else -> list }
        }

        fun from(context: Context, id: String?) = all(context).firstOrNull { it.id == id }
    }
}

@Composable
fun CartoonAvatarView(avatar: CartoonAvatar, size: Dp, modifier: Modifier = Modifier) {
    Canvas(modifier.size(size).clip(CircleShape)) {
        val w = this.size.width
        drawRect(Brush.verticalGradient(listOf(hex(avatar.bg1), hex(avatar.bg2))))
        // shoulders
        drawOval(hex(avatar.cloth), Offset(w * 0.12f, w * 0.70f), Size(w * 0.76f, w * 0.60f))
        val hair = hex(avatar.hair)
        val longHair = avatar.hairStyle in setOf("long", "wavyLong", "bob", "pony", "bun", "twinTail", "braid", "hijab")
        if (avatar.hairStyle == "afro") drawCircle(hair, w * 0.34f, Offset(w * 0.5f, w * 0.40f))
        if (longHair) drawRoundRect(hair, Offset(w * 0.26f, w * 0.26f), Size(w * 0.48f, w * 0.56f), androidx.compose.ui.geometry.CornerRadius(w * 0.2f))
        // neck + head
        drawRect(hex(avatar.skin).copy(alpha = 0.9f), Offset(w * 0.44f, w * 0.60f), Size(w * 0.12f, w * 0.14f))
        drawOval(hex(avatar.skin), Offset(w * 0.30f, w * 0.24f), Size(w * 0.40f, w * 0.46f))
        // fringe
        if (avatar.hairStyle != "baldish") {
            drawArc(hair, 180f, 180f, true, Offset(w * 0.28f, w * 0.20f), Size(w * 0.44f, w * 0.34f))
        }
        // eyes, blush, smile
        val ey = w * 0.46f
        listOf(0.41f, 0.59f).forEach { x ->
            drawCircle(Color.White, w * 0.045f, Offset(w * x, ey))
            drawCircle(hex(avatar.iris), w * 0.028f, Offset(w * x, ey))
            drawCircle(hex(avatar.blush).copy(alpha = 0.45f), w * 0.04f, Offset(w * (x + if (x < 0.5f) -0.04f else 0.04f), w * 0.55f))
        }
        val grin = avatar.smile == "grin"
        drawArc(Color(0xFF7A3B3B), 15f, 150f, grin, Offset(w * 0.43f, w * (if (grin) 0.52f else 0.54f)), Size(w * 0.14f, w * 0.09f), style = if (grin) androidx.compose.ui.graphics.drawscope.Fill else Stroke(w * 0.012f))
    }
}

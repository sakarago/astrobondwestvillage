package com.astrobond.app.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Check
import com.astrobond.app.ui.theme.*

private val GlowStroke = Brush.linearGradient(
    listOf(Color.White.copy(0.62f), hex("#E2DDFF").copy(0.40f), ABColor.Lavender.copy(0.22f)),
)

/** iOS GlowCTAButton: pill with lavender glow, sparkle on the left, arrow on the right. */
@Composable
fun GlowButton(
    title: String, onClick: () -> Unit, modifier: Modifier = Modifier,
    enabled: Boolean = true, showArrow: Boolean = true, showSparkle: Boolean = true,
) {
    val shape = CircleShape
    Box(
        modifier
            .fillMaxWidth().height(54.dp)
            .alpha(if (enabled) 1f else 0.75f)
            .shadow(14.dp, shape, ambientColor = ABColor.Lavender, spotColor = ABColor.Lavender.copy(0.6f))
            .clip(shape)
            .background(Color(0x990F0B1D))
            .background(Brush.verticalGradient(listOf(Color.White.copy(0.10f), hex("#B5ABF5").copy(0.10f), ABColor.Lavender.copy(0.05f))))
            .border(1.dp, GlowStroke, shape)
            .clickable(enabled = enabled, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Text(title, style = ABFont.body(16.5f, androidx.compose.ui.text.font.FontWeight.SemiBold), color = Color.White.copy(if (enabled) 0.95f else 0.4f))
        if (showSparkle) Text("✦", color = Color.White.copy(0.95f), fontSize = 13.sp, modifier = Modifier.align(Alignment.CenterStart).padding(start = 20.dp))
        if (showArrow) Icon(Icons.AutoMirrored.Filled.ArrowForward, null, tint = Color.White.copy(if (enabled) 0.95f else 0.35f),
            modifier = Modifier.align(Alignment.CenterEnd).padding(end = 22.dp).size(18.dp))
    }
}

/** iOS `glowInputSurface` capsule text field with leading icon. */
@Composable
fun GlowTextField(
    value: String, onValueChange: (String) -> Unit, placeholder: String, modifier: Modifier = Modifier,
    leading: ImageVector? = null, password: Boolean = false, keyboardType: KeyboardType = KeyboardType.Text,
) {
    Row(
        modifier.fillMaxWidth().clip(CircleShape).background(Color.White.copy(0.04f))
            .border(1.dp, GlowStroke, CircleShape).padding(horizontal = 18.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (leading != null) Icon(leading, null, tint = hex("#C8A56E").copy(0.7f), modifier = Modifier.size(18.dp))
        TextField(
            value = value, onValueChange = onValueChange, singleLine = true,
            placeholder = { Text(placeholder, color = hex("#9AA0AB").copy(0.7f)) },
            visualTransformation = if (password) PasswordVisualTransformation() else VisualTransformation.None,
            keyboardOptions = KeyboardOptions(keyboardType = if (password) KeyboardType.Password else keyboardType),
            colors = TextFieldDefaults.colors(
                focusedContainerColor = Color.Transparent, unfocusedContainerColor = Color.Transparent,
                focusedIndicatorColor = Color.Transparent, unfocusedIndicatorColor = Color.Transparent,
                focusedTextColor = Color.White, unfocusedTextColor = Color.White, cursorColor = ABColor.LavenderSoft,
            ),
            modifier = Modifier.weight(1f),
        )
    }
}

/** iOS `CrystalField`: label above a rounded glass text input. */
@Composable
fun CrystalField(label: String, value: String, onValueChange: (String) -> Unit, modifier: Modifier = Modifier) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(label, style = ABFont.label(12f), color = ABColor.InkMuted)
        TextField(
            value = value, onValueChange = onValueChange, singleLine = true,
            colors = TextFieldDefaults.colors(
                focusedContainerColor = Color.White.copy(0.04f), unfocusedContainerColor = Color.White.copy(0.04f),
                focusedIndicatorColor = Color.Transparent, unfocusedIndicatorColor = Color.Transparent,
                focusedTextColor = ABColor.Ink, unfocusedTextColor = ABColor.Ink, cursorColor = ABColor.LavenderSoft,
            ),
            shape = RoundedCornerShape(18.dp),
            modifier = Modifier.fillMaxWidth().border(1.dp, Brush.linearGradient(listOf(Color.White.copy(0.45f), ABColor.LavenderSoft.copy(0.25f), Color.White.copy(0.08f))), RoundedCornerShape(18.dp)),
        )
    }
}

@Composable
fun Chip(title: String, selected: Boolean, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val shape = CircleShape
    Box(
        modifier.clip(shape)
            .background(if (selected) ABColor.Lavender.copy(0.28f) else Color.White.copy(0.06f))
            .border(1.dp, if (selected) ABColor.LavenderSoft.copy(0.55f) else Color.White.copy(0.12f), shape)
            .clickable(onClick = onClick).padding(horizontal = 16.dp, vertical = 12.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(title, style = ABFont.body(14f, androidx.compose.ui.text.font.FontWeight.Medium), color = Color.White.copy(if (selected) 1f else 0.75f), textAlign = TextAlign.Center)
    }
}

@Composable
fun LogoBlock(modifier: Modifier = Modifier) {
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("✦", color = hex("#C8A56E"), fontSize = 22.sp)
        Text("ASTROBOND", style = ABFont.display(17f, androidx.compose.ui.text.font.FontWeight.Normal), color = Color.White.copy(0.95f), letterSpacing = 6.5.sp)
    }
}

@Composable
fun ProgressDots(current: Int, total: Int, modifier: Modifier = Modifier) {
    Row(modifier, horizontalArrangement = Arrangement.spacedBy(7.dp)) {
        repeat(total) { i ->
            Box(
                Modifier.weight(1f).height(4.dp).clip(CircleShape).background(
                    when { i == current -> ABColor.LavenderSoft; i < current -> ABColor.LavenderSoft.copy(0.55f); else -> Color.White.copy(0.15f) },
                ),
            )
        }
    }
}

@Composable
fun noRipple() = remember { MutableInteractionSource() }

@Composable
fun CheckBadge(on: Boolean) {
    Box(Modifier.size(22.dp).clip(RoundedCornerShape(6.dp)).background(if (on) ABColor.Lavender else Color.Transparent)
        .border(BorderStroke(1.dp, Color.White.copy(0.4f)), RoundedCornerShape(6.dp)), contentAlignment = Alignment.Center) {
        if (on) Icon(Icons.Filled.Check, null, tint = Color.White, modifier = Modifier.size(16.dp))
    }
}

package com.astrobond.app.ui.discover

import android.content.Context
import android.content.Intent
import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.Canvas
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.astrobond.app.R
import com.astrobond.app.discover.*
import com.astrobond.app.domain.ZodiacSign
import com.astrobond.app.notify.DailyMessageNotifier
import com.astrobond.app.ui.theme.*
import kotlinx.coroutines.delay
import java.time.LocalDate
import java.util.Locale

private fun share(ctx: Context, text: String) {
    ctx.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text), null))
}

private val Lav = hex("#C9B6FF")

/** Port of TarotFlowView: pick → opening → result. One card per day, remembered on-device; reflection note saved per day. */
@Composable
fun TarotFlow(sky: UserSky, onBack: () -> Unit) {
    val ctx = LocalContext.current
    val prefs = remember { ctx.getSharedPreferences("astrobond.discover", Context.MODE_PRIVATE) }
    val askNotifications = com.astrobond.app.notify.rememberNotificationPermissionRequest { DailyMessageNotifier.scheduleDaily(ctx) }
    val today = LocalDate.now()
    val key = "dailyCard.${sky.userId}.${today.year}.${today.dayOfYear}"
    var picked by remember { mutableIntStateOf(prefs.getInt(key, -1)) }
    var stage by remember { mutableIntStateOf(if (picked >= 0) 2 else 0) } // 0 pick, 1 opening, 2 result
    var showReflect by remember { mutableStateOf(false) }
    var hasNote by remember { mutableStateOf(!prefs.getString("$key.note", "").isNullOrEmpty()) }
    val pulse by rememberInfiniteTransition(label = "t").animateFloat(-8f, 8f, infiniteRepeatable(tween(1200), RepeatMode.Reverse), label = "r")

    LaunchedEffect(stage) { if (stage == 1) { delay(2600); stage = 2 } }
    androidx.activity.compose.BackHandler(onBack = onBack)
    CompositionLocalProvider(LocalTh provides Th(false)) {
        Box(Modifier.fillMaxSize()) {
            ScreenBackdropView(Backdrop.VIOLET)
            Column(Modifier.fillMaxSize().statusBarsPadding().padding(horizontal = 20.dp, vertical = 8.dp)) {
                val r = if (picked >= 0) DiscoverContent.cardResult(sky, picked) else null
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    CircleButton("‹", Th(false), onBack)
                    if (stage == 2 && r != null) CircleButton("⇪", Th(false)) { share(ctx, "${r.title}\n\n${r.body}\n\n— AstroBond") }
                }
                when (stage) {
                    0 -> Column(Modifier.fillMaxSize().padding(bottom = 112.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.SpaceEvenly) {
                        Text(stringResource(R.string.tarot_title), style = ABFont.display(38f, FontWeight.Normal), color = Color.White)
                        Text(stringResource(R.string.tarot_sub), style = ABFont.body(14f), color = Color.White.copy(0.75f), textAlign = TextAlign.Center)
                        Box(Modifier.fillMaxWidth().height(260.dp), contentAlignment = Alignment.Center) {
                            Canvas(Modifier.fillMaxSize()) {
                                drawCircle(Brush.radialGradient(listOf(hex("#7B5CFF").copy(0.45f), Color.Transparent), center, 500f), 500f)
                                repeat(3) { drawCircle(Lav.copy(0.30f - it * 0.08f), 200f + it * 70f, style = Stroke(1.5f)) }
                            }
                            Row(horizontalArrangement = Arrangement.spacedBy((-14).dp), verticalAlignment = Alignment.Bottom) {
                                (0..2).forEach { i ->
                                    VioletTarotCard(sun = i == 1, width = if (i == 1) 108.dp else 96.dp, glow = i == 1,
                                        modifier = Modifier.rotate((i - 1) * 9f).clickable {
                                            picked = i; prefs.edit().putInt(key, i).apply()
                                            if (com.astrobond.app.data.NotificationPrefs(ctx).dailyInsight) askNotifications(); stage = 1
                                        })
                                }
                            }
                        }
                        Text(stringResource(R.string.tarot_one_card), style = ABFont.body(14f, FontWeight.SemiBold), color = Color.White)
                        Text(stringResource(R.string.tarot_hint), style = ABFont.body(12.5f), color = Color.White.copy(0.65f), textAlign = TextAlign.Center)
                    }
                    1 -> Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
                        VioletTarotCard(sun = picked == 1, width = 160.dp, glow = true, modifier = Modifier.graphicsLayer { rotationY = pulse; cameraDistance = 16f * density })
                        Spacer(Modifier.height(24.dp))
                        Text(stringResource(R.string.tarot_opening), style = ABFont.display(22f, FontWeight.Normal), color = Color.White)
                        Text(stringResource(R.string.tarot_opening_sub), style = ABFont.body(13f), color = Color.White.copy(0.7f))
                    }
                    else -> if (r != null) Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(top = 12.dp, bottom = 130.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(18.dp)) {
                        VioletTarotCard(sun = picked == 1, width = 140.dp, glow = true)
                        Text(r.title, style = ABFont.display(26f, FontWeight.Normal), color = Color.White, textAlign = TextAlign.Center)
                        Text(r.body, style = ABFont.body(14.5f), color = Color.White.copy(0.85f), textAlign = TextAlign.Center)
                        Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(20.dp)).background(Color.White.copy(0.07f)).border(1.dp, Lav.copy(0.3f), RoundedCornerShape(20.dp)).clickable { showReflect = true }.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Text(stringResource(R.string.ask_yourself), style = ABFont.body(10.5f, FontWeight.SemiBold), color = Lav, letterSpacing = 2.sp)
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(r.question, style = ABFont.body(14.5f, FontWeight.Medium), color = Color.White, modifier = Modifier.weight(1f))
                                Text(if (hasNote) "✓" else "›", color = Lav, fontSize = 20.sp)
                            }
                        }
                        Text(stringResource(R.string.tarot_come_back), style = ABFont.body(12f), color = Color.White.copy(0.55f))
                    }
                }
            }
        }
        if (showReflect && picked >= 0) {
            val q = DiscoverContent.cardResult(sky, picked).question
            var text by remember { mutableStateOf(prefs.getString("$key.note", "") ?: "") }
            fun close() { prefs.edit().putString("$key.note", text).apply(); hasNote = text.isNotEmpty(); showReflect = false }
            AlertDialog(onDismissRequest = ::close, containerColor = hex("#150B2E"),
                confirmButton = { TextButton(::close) { Text(stringResource(R.string.save), color = Lav) } },
                title = { Text(q, style = ABFont.display(22f, FontWeight.Normal), color = Color.White) },
                text = { Column { Text(stringResource(R.string.reflect_hint), style = ABFont.body(12f), color = Color.White.copy(0.6f)); Spacer(Modifier.height(8.dp))
                    TextField(text, { text = it }, modifier = Modifier.fillMaxWidth().heightIn(min = 140.dp), colors = TextFieldDefaults.colors(focusedContainerColor = Color.White.copy(0.08f), unfocusedContainerColor = Color.White.copy(0.08f), focusedTextColor = Color.White, unfocusedTextColor = Color.White)) } })
        }
    }
}

@Composable
fun EventsList(sky: UserSky, onBack: () -> Unit, push: (Route) -> Unit) {
    var filter by remember { mutableIntStateOf(0) }
    val chips = listOf("Tümü", "Dolunay", "Yeni Ay", "Retro", "Diğer")
    val events = DiscoverContent.upcomingEvents(limit = 20).filter {
        when (filter) { 1 -> it.kind == EventKind.FULL_MOON; 2 -> it.kind == EventKind.NEW_MOON; 3 -> it.kind == EventKind.RETROGRADE; 4 -> it.kind == EventKind.ECLIPSE || it.kind == EventKind.SOLSTICE; else -> true }
    }
    DiscoverScaffold(Backdrop.NIGHT, onBack, stringResource(R.string.events_title), stringResource(R.string.events_sub)) {
        PillChips(chips, filter) { filter = it }
        if (events.isEmpty()) Text(stringResource(R.string.events_empty), style = ABFont.body(13f), color = Color.White.copy(0.6f))
        events.forEach { e -> DTRow(e.title, DiscoverContent.eventPersonalLine(e, sky), e.dateText, { push(Route.Event(e.id)) }) { EventOrb(e.kind, 44.dp) } }
    }
}

@Composable
fun EventDetail(e: SkyEvent, sky: UserSky, onBack: () -> Unit, push: (Route) -> Unit) {
    val ctx = LocalContext.current
    val note = DiscoverContent.eventNote(e, sky)
    val label = when (e.kind) { EventKind.FULL_MOON -> "DOLUNAY"; EventKind.NEW_MOON -> "YENİ AY"; EventKind.RETROGRADE -> "RETRO"; EventKind.ECLIPSE -> "TUTULMA"; EventKind.SOLSTICE -> "GÜNDÖNÜMÜ" }
    DiscoverScaffold(Backdrop.NIGHT, onBack, share = { share(ctx, "${e.title} · ${e.dateText}\n${e.blurb}") }) {
        Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) { EventOrb(e.kind, 120.dp) }
        Text(label, style = ABFont.body(11f, FontWeight.SemiBold), color = DT.Accent, letterSpacing = 2.4.sp)
        Text(e.title, style = ABFont.display(36f, FontWeight.Normal), color = Color.White)
        Text(e.dateText, style = ABFont.body(14f, FontWeight.Medium), color = DT.AccentSoft)
        Text(e.blurb, style = ABFont.body(14.5f), color = Color.White.copy(0.8f))
        Text(stringResource(R.string.effect_on_you), style = ABFont.display(20f, FontWeight.Medium), color = Color.White)
        note.sections.forEach { Text(it.text, style = ABFont.body(13.5f), color = Color.White.copy(0.78f)) }
        DTRow(stringResource(R.string.effects_by_sign), onClick = { push(Route.Note(DiscoverContent.eventSignEffects(e, sky))) }) { Text("✦", color = DT.Accent) }
    }
}

@Composable
fun SignsView(sky: UserSky, initial: ZodiacSign?, onBack: () -> Unit, push: (Route) -> Unit) {
    var selected by remember { mutableStateOf(initial ?: sky.sun ?: ZodiacSign.ARIES) }
    val th = Th(true)
    val rows = DiscoverContent.signRows(selected, sky)
    val day = LocalDate.now().dayOfWeek.getDisplayName(java.time.format.TextStyle.FULL, Locale("tr", "TR")).replaceFirstChar { it.titlecase(Locale("tr", "TR")) }
    DiscoverScaffold(Backdrop.PEACH, onBack, stringResource(R.string.signs_title), stringResource(R.string.signs_sub)) {
        Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            ZodiacSign.entries.forEach { s ->
                Column(Modifier.clickable { selected = s }, horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(5.dp)) {
                    Text(s.glyph, color = if (selected == s) Color.White else elementTint(s), fontSize = 22.sp, modifier = Modifier.then(if (selected == s) Modifier.clip(CircleShape).background(th.chipOn).padding(8.dp) else Modifier.padding(8.dp)))
                    Text(s.labelTR, style = ABFont.body(11.5f, if (selected == s) FontWeight.Bold else FontWeight.Medium), color = th.primary)
                }
            }
        }
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Text(selected.glyph, color = elementTint(selected), fontSize = 26.sp)
            Column { Text(selected.labelTR, style = ABFont.display(22f, FontWeight.Medium), color = th.primary); Text("${selected.dateRangeText}, $day", style = ABFont.body(12f), color = th.secondary) }
        }
        Text(DiscoverContent.signRelation(selected, sky), style = ABFont.body(13.5f), color = th.primary.copy(0.85f))
        rows.forEach { r ->
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Icon(when (r.icon) { "heart" -> Icons.Filled.Favorite; "briefcase" -> Icons.Filled.Work; "drop" -> Icons.Filled.WaterDrop; else -> Icons.Filled.AutoAwesome }, null, tint = th.accent, modifier = Modifier.size(22.dp))
                Column(verticalArrangement = Arrangement.spacedBy(3.dp)) { Text(r.title, style = ABFont.body(13.5f, FontWeight.SemiBold), color = th.primary); Text(r.text, style = ABFont.body(12.5f), color = th.secondary) }
            }
            HorizontalDivider(color = Color.Black.copy(0.08f))
        }
        DTRow(stringResource(R.string.all_signs), onClick = { push(Route.AllSigns) }) { Text("✦", color = th.accent) }
    }
}

@Composable
fun AllSigns(onBack: () -> Unit, push: (Route) -> Unit) = DiscoverScaffold(Backdrop.PEACH, onBack, stringResource(R.string.all_signs), stringResource(R.string.all_signs_sub)) {
    ZodiacSign.entries.forEach { s -> DTRow(s.labelTR, s.dateRangeText, onClick = { push(Route.Signs(s)) }) { Text(s.glyph, color = DT.Ink, fontSize = 20.sp) } }
}

@Composable
fun TopicList(title: String, subtitle: String, chips: List<String>?, topics: List<DiscoverTopic>, backdrop: Backdrop, onBack: () -> Unit, push: (Route) -> Unit) {
    var filter by remember { mutableIntStateOf(0) }
    val shown = if (chips == null || filter == 0) topics else topics.filter { it.category == chips[filter] }
    DiscoverScaffold(backdrop, onBack, title, subtitle) {
        if (chips != null) PillChips(chips, filter) { filter = it }
        shown.forEach { t -> DTRow(t.title, t.subtitle, onClick = { push(Route.Note(t.note)) }) { Orb(t.tint, 46.dp) } }
    }
}

@Composable
fun MoreView(sky: UserSky, onBack: () -> Unit, push: (Route) -> Unit) = DiscoverScaffold(Backdrop.NIGHT, onBack, stringResource(R.string.more_title), stringResource(R.string.more_sub)) {
    @Composable fun card(icon: String, colors: List<String>, title: String, sub: String, note: DiscoverNote) {
        Box(Modifier.fillMaxWidth().height(130.dp).clip(RoundedCornerShape(22.dp)).background(Brush.linearGradient(colors.map { hex(it) })).clickable { push(Route.Note(note.backed(Backdrop.GRADIENT, colors))) }.padding(18.dp)) {
            Text(icon, fontSize = 64.sp, color = Color.White.copy(0.12f), modifier = Modifier.align(Alignment.TopEnd))
            Column(Modifier.align(Alignment.BottomStart), verticalArrangement = Arrangement.spacedBy(4.dp)) { Text(title, style = ABFont.display(20f, FontWeight.Medium), color = Color.White); Text(sub, style = ABFont.body(12f), color = Color.White.copy(0.8f)) }
        }
    }
    card("📅", listOf("#2A2F6B", "#0F1235"), "Haftalık Gökyüzü Gündemi", "Bu hafta hangi enerjiler seninle?", DiscoverContent.weeklyNote(sky))
    card("🌿", listOf("#C99A6B", "#8E6446"), "Yeni Başlayanlar İçin Astroloji", "Temel kavramlarla başla.", DiscoverContent.beginnerNote(sky))
    card("🔥", listOf("#5A2A2E", "#1D0D12"), "Ritüeller ve Öneriler", "Gökyüzünle uyumlan.", DiscoverContent.ritualNote(sky))
}

/** Generic note page (port of NoteDetailPage). */
@Composable
fun NotePage(note: DiscoverNote, sky: UserSky, onBack: () -> Unit) {
    val ctx = LocalContext.current
    val th = Th(note.backdrop.isLight)
    DiscoverScaffold(note.backdrop, onBack, share = { share(ctx, "${note.title}\n${note.intro}") }, gradient = note.gradient) {
        Text(note.eyebrow, style = ABFont.body(11f, FontWeight.SemiBold), color = th.accent, letterSpacing = 2.sp)
        Text(note.title, style = ABFont.display(32f, FontWeight.Normal), color = th.primary)
        Text(note.intro, style = ABFont.body(15f), color = th.primary.copy(0.85f))
        note.sections.forEach { s ->
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(s.heading, style = ABFont.body(13f, FontWeight.Bold), color = th.accent)
                Text(s.text, style = ABFont.body(14.5f), color = th.primary.copy(0.9f))
            }
        }
    }
}

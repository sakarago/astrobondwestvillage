package com.astrobond.app.ui.discover

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.astrobond.app.R
import com.astrobond.app.data.ChartRepo
import com.astrobond.app.data.ProfileRepo
import com.astrobond.app.discover.*
import com.astrobond.app.domain.Planet
import com.astrobond.app.domain.ZodiacSign
import com.astrobond.app.session.SessionViewModel
import com.astrobond.app.ui.Chrome
import com.astrobond.app.ui.theme.*
import kotlinx.coroutines.launch

sealed interface Route {
    data object Tarot : Route; data object Daily : Route; data object Events : Route; data object AllSigns : Route
    data object Love : Route; data object Guide : Route; data object More : Route
    data class Event(val id: String) : Route
    data class Signs(val sign: ZodiacSign?) : Route
    data class Note(val note: DiscoverNote) : Route
}

class DiscoverViewModel : ViewModel() {
    var sky by mutableStateOf(UserSky()); private set
    private var loadedFor: String? = null

    fun load(userId: String, force: Boolean = false) {
        if (!force && loadedFor == userId) return
        loadedFor = userId
        sky = sky.copy(userId = userId)
        viewModelScope.launch {
            runCatching { ProfileRepo.fetchSnapshot(userId) }.getOrNull()?.let { sky = sky.copy(name = it.displayName, sun = it.sunSign, moon = it.moonSign, rising = it.risingSign) }
            runCatching { ChartRepo.ensureOwnChart(userId) }.getOrNull()?.let { c ->
                sky = sky.copy(sun = c.sunSign, moon = c.moonSign, rising = c.risingSign, venus = c.planet(Planet.VENUS)?.sign,
                    mars = c.planet(Planet.MARS)?.sign, mercury = c.planet(Planet.MERCURY)?.sign, dominantElement = c.dominantElement)
            }
        }
    }
}

/** Port of DiscoverHomeView ("Keşfet"): hero, daily message card, events, signs, topics, extras; a route stack replaces NavigationStack. */
@Composable
fun DiscoverScreen(session: SessionViewModel?, vm: DiscoverViewModel = viewModel()) {
    val user = session?.user?.collectAsState()?.value
    LaunchedEffect(user?.id) { user?.id?.let { vm.load(it) } }
    val stack = remember { mutableStateListOf<Route>() }
    val sky = vm.sky
    val top = stack.lastOrNull()
    SideEffect { Chrome.hideTabBar = false }
    val back = { stack.removeLastOrNull(); Unit }
    fun push(r: Route) { stack.add(r) }

    when (top) {
        null -> Home(sky, ::push)
        Route.Tarot -> TarotFlow(sky, back)
        Route.Daily -> NotePage(DiscoverContent.dailyReading(sky), sky, back)
        Route.Events -> EventsList(sky, back, ::push)
        is Route.Event -> DiscoverContent.upcomingEvents(limit = 30).firstOrNull { it.id == top.id }?.let { EventDetail(it, sky, back, ::push) } ?: back()
        is Route.Signs -> SignsView(sky, top.sign, back, ::push)
        Route.AllSigns -> AllSigns(back, ::push)
        Route.Love -> TopicList(stringResource(R.string.love_title), stringResource(R.string.love_sub), null, DiscoverContent.loveTopics(sky), Backdrop.LOVE, back, ::push)
        Route.Guide -> TopicList(stringResource(R.string.guide_title), stringResource(R.string.guide_sub), listOf("Tümü", "Gezegenler", "Evler", "Burçlar"), DiscoverContent.guideTopics(sky), Backdrop.GUIDE, back, ::push)
        Route.More -> MoreView(sky, back, ::push)
        is Route.Note -> NotePage(top.note, sky, back)
    }
}

private val Ink = DT.Ink
private val InkSoft = DT.InkSoft

@Composable
private fun Home(sky: UserSky, push: (Route) -> Unit) {
    Column(Modifier.fillMaxSize().background(DT.Cream).verticalScroll(rememberScrollState()).padding(bottom = 130.dp)) {
        // hero
        Box(Modifier.fillMaxWidth().height(380.dp)) {
            Image(painterResource(R.drawable.discover_hero), null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
            Box(Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(Color.Black.copy(0.25f), Color.Black.copy(0.6f)))))
            Column(Modifier.statusBarsPadding().padding(horizontal = 20.dp, vertical = 12.dp)) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Column {
                        Text(stringResource(R.string.discover_title), style = ABFont.display(38f, FontWeight.Normal), color = Color.White)
                        Text(stringResource(R.string.discover_story), style = ABFont.body(11f, FontWeight.Medium), color = Color.White.copy(0.85f), letterSpacing = 2.6.sp)
                    }
                    Text("✦", color = Color.White, fontSize = 20.sp)
                }
                Spacer(Modifier.weight(1f))
                Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(24.dp)).background(Color.Black.copy(0.4f)).padding(18.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(stringResource(R.string.sky_today), style = ABFont.body(10.5f, FontWeight.Medium), color = Color.White.copy(0.75f), letterSpacing = 2.sp)
                    Text(stringResource(R.string.energy_q), style = ABFont.display(26f, FontWeight.Normal), color = Color.White)
                    Text(DiscoverContent.heroSubtitle(sky), style = ABFont.body(13.5f), color = Color.White.copy(0.88f))
                    Text(stringResource(R.string.read_daily) + "  →", style = ABFont.body(14f, FontWeight.SemiBold), color = Color.White, modifier = Modifier.clickable { push(Route.Daily) })
                }
            }
        }
        Column(Modifier.padding(horizontal = 20.dp).padding(top = 22.dp), verticalArrangement = Arrangement.spacedBy(22.dp)) {
            // message card
            Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(24.dp)).background(Brush.horizontalGradient(listOf(hex("#FBEEE3"), hex("#F1D3BE"))))) {
                Image(painterResource(R.drawable.discover_tarot), null, contentScale = ContentScale.Crop, modifier = Modifier.matchParentSize().align(Alignment.CenterEnd).background(Color.Transparent))
                Box(Modifier.matchParentSize().background(Brush.horizontalGradient(listOf(hex("#FBEEE3"), hex("#FBEEE3").copy(0.9f), Color.Transparent))))
                Column(Modifier.padding(20.dp).fillMaxWidth(0.62f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(stringResource(R.string.daily_message), style = ABFont.body(10f, FontWeight.SemiBold), color = InkSoft, letterSpacing = 2.sp)
                    Text(stringResource(R.string.universe_has_message), style = ABFont.display(19f), color = Ink)
                    Text(if (sky.firstName.isEmpty()) stringResource(R.string.pick_cards) else stringResource(R.string.pick_cards_name, sky.firstName), style = ABFont.body(12.5f), color = InkSoft)
                    Text(stringResource(R.string.pick_card) + "  →", style = ABFont.body(13.5f, FontWeight.SemiBold), color = Color.White,
                        modifier = Modifier.clip(androidx.compose.foundation.shape.CircleShape).background(Ink).clickable { push(Route.Tarot) }.padding(horizontal = 16.dp, vertical = 9.dp))
                }
            }
            // events
            val events = DiscoverContent.upcomingEvents().take(5)
            SectionHeader(stringResource(R.string.upcoming_events)) { push(Route.Events) }
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                events.forEach { e ->
                    Column(Modifier.width(170.dp).height(170.dp).clip(RoundedCornerShape(20.dp)).background(Brush.verticalGradient(listOf(DT.Card, DT.BgBottom))).clickable { push(Route.Event(e.id)) }.padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        EventOrb(e.kind, 52.dp)
                        Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                            Text(e.title, style = ABFont.display(14.5f, FontWeight.Medium), color = Color.White)
                            Text(e.dateText, style = ABFont.body(10.5f, FontWeight.Medium), color = DT.AccentSoft)
                            Text(DiscoverContent.eventPersonalLine(e, sky), style = ABFont.body(10.5f), color = Color.White.copy(0.68f), maxLines = 3)
                        }
                    }
                }
            }
            // signs
            SectionHeader(stringResource(R.string.daily_horoscopes)) { push(Route.AllSigns) }
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                ZodiacSign.entries.forEach { s ->
                    Column(Modifier.clickable { push(Route.Signs(s)) }, horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(s.glyph, color = elementTint(s), fontSize = 26.sp)
                        Text(s.labelTR, style = ABFont.body(11.5f, if (s == sky.sun) FontWeight.Bold else FontWeight.Medium), color = Ink)
                    }
                }
            }
            // topic cards
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                TopicCard(R.drawable.discover_love, stringResource(R.string.love_topic_title), stringResource(R.string.love_topic_sub), Modifier.weight(1f)) { push(Route.Love) }
                TopicCard(R.drawable.discover_guide, stringResource(R.string.guide_topic_title), stringResource(R.string.guide_topic_sub), Modifier.weight(1f)) { push(Route.Guide) }
            }
            // extras
            SectionHeader(stringResource(R.string.more_content)) { push(Route.More) }
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Extra("Haftalık\nGökyüzü Gündemi", "📅", listOf("#2A2F6B", "#0F1235")) { push(Route.Note(DiscoverContent.weeklyNote(sky).backed(Backdrop.GRADIENT, listOf("#2A2F6B", "#0F1235")))) }
                Extra("Yeni Başlayanlar\nİçin Astroloji", "🌿", listOf("#C99A6B", "#8E6446")) { push(Route.Note(DiscoverContent.beginnerNote(sky).backed(Backdrop.GRADIENT, listOf("#C99A6B", "#8E6446")))) }
                Extra("Ritüeller\nve Öneriler", "🔥", listOf("#5A2A2E", "#1D0D12")) { push(Route.Note(DiscoverContent.ritualNote(sky).backed(Backdrop.GRADIENT, listOf("#5A2A2E", "#1D0D12")))) }
            }
        }
    }
}

@Composable
private fun SectionHeader(title: String, onSeeAll: () -> Unit) = Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
    Text(title, style = ABFont.body(11.5f, FontWeight.SemiBold), color = Ink, letterSpacing = 1.8.sp, modifier = Modifier.weight(1f))
    Text(stringResource(R.string.see_all), style = ABFont.body(11.5f, FontWeight.Medium), color = InkSoft, modifier = Modifier.clickable(onClick = onSeeAll))
}

@Composable
private fun TopicCard(img: Int, title: String, sub: String, modifier: Modifier, onClick: () -> Unit) {
    Box(modifier.height(200.dp).clip(RoundedCornerShape(22.dp)).clickable(onClick = onClick)) {
        Image(painterResource(img), null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
        Box(Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(Color.Black.copy(0.1f), Color.Black.copy(0.75f)))))
        Column(Modifier.align(Alignment.BottomStart).padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(title, style = ABFont.display(17f, FontWeight.Medium), color = Color.White)
            Text(sub, style = ABFont.body(11f), color = Color.White.copy(0.8f))
            Text(stringResource(R.string.discover_btn) + " →", style = ABFont.body(11.5f, FontWeight.SemiBold), color = Color.White)
        }
    }
}

@Composable
private fun Extra(title: String, icon: String, colors: List<String>, onClick: () -> Unit) {
    Column(Modifier.width(150.dp).height(120.dp).clip(RoundedCornerShape(20.dp)).background(Brush.linearGradient(colors.map { hex(it) })).clickable(onClick = onClick).padding(14.dp), verticalArrangement = Arrangement.SpaceBetween) {
        Text(icon, fontSize = 18.sp)
        Text(title, style = ABFont.display(14.5f, FontWeight.Medium), color = Color.White)
    }
}

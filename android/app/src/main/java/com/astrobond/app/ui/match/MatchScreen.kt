package com.astrobond.app.ui.match

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.platform.LocalConfiguration
import androidx.lifecycle.viewmodel.compose.viewModel
import com.astrobond.app.R
import com.astrobond.app.domain.*
import com.astrobond.app.session.SessionViewModel
import com.astrobond.app.ui.components.*
import com.astrobond.app.ui.theme.*
import kotlinx.coroutines.delay

private val Warm = hex("#EBD3B0")

private enum class Orientation(val title: String) { KADIN("Kadın"), ERKEK("Erkek"), LGBT("LGBT") }

/** Port of MatchHomeView: idle (bond/orientation pills + today's strip), spinning, revealed (card + actions) and the detail page. */
@Composable
fun MatchScreen(session: SessionViewModel?, vm: MatchViewModel = viewModel()) {
    val user = session?.user?.collectAsState()?.value
    LaunchedEffect(user?.id) { user?.id?.let(vm::bootstrap) }
    val detail = vm.detailCard
    if (detail != null) {
        MatchDetailScreen(vm, detail, onBack = { vm.detailCard = null })
        return
    }
    var intents by remember { mutableStateOf(setOf<MatchIntent>()) }
    var orientations by remember { mutableStateOf(setOf<Orientation>()) }
    var notice by remember { mutableStateOf(false) }
    LaunchedEffect(notice) { if (notice) { delay(2000); notice = false } }

    Box(Modifier.fillMaxSize()) {
        if (vm.phase == MatchViewModel.Phase.REVEALED) {
            Image(painterResource(R.drawable.reveal_bg), null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize().alpha(0.9f))
            Box(Modifier.fillMaxSize().background(Color.Black.copy(0.35f)))
        }
        Column(Modifier.fillMaxSize().statusBarsPadding().padding(bottom = 110.dp).padding(horizontal = 20.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Spacer(Modifier.height(14.dp))
            Text("✦", color = hex("#C8A56E"), fontSize = 20.sp)
            Text(stringResource(R.string.tagline), style = ABFont.body(11f), color = Color.White.copy(0.6f), letterSpacing = 2.5.sp)
            Text(vm.quotaLabel, style = ABFont.body(12f, FontWeight.Medium), color = Color.White.copy(0.85f),
                modifier = Modifier.padding(top = 6.dp).border(1.dp, ABColor.Lavender.copy(0.45f), CircleShape).padding(horizontal = 12.dp, vertical = 4.dp))
            val wheel = minOf(LocalConfiguration.current.screenWidthDp * 0.8f, LocalConfiguration.current.screenHeightDp * 0.38f).dp
            Spacer(Modifier.height(12.dp))
            CosmicWheel(
                wheel, vm.wheelRotation, vm.phase == MatchViewModel.Phase.SPINNING, vm.phase == MatchViewModel.Phase.REVEALED,
                vm.active?.sunSign, stringResource(R.string.match_spin),
            ) {
                when {
                    intents.isEmpty() || orientations.isEmpty() -> notice = true
                    else -> {
                        applySelections(vm, intents, orientations)
                        vm.spin()
                    }
                }
            }
            Spacer(Modifier.height(12.dp))
            when (vm.phase) {
                MatchViewModel.Phase.IDLE -> Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(14.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                    if (notice) Text(stringResource(R.string.match_pick_first), style = ABFont.body(12.5f), color = Color.White, textAlign = TextAlign.Center,
                        modifier = Modifier.border(1.dp, ABColor.Lavender.copy(0.55f), RoundedCornerShape(16.dp)).padding(10.dp))
                    Heading(stringResource(R.string.match_pref_q))
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Orientation.entries.forEach { o -> Pill(o.title, o in orientations, { orientations = if (o in orientations) orientations - o else orientations + o }, Modifier) }
                    }
                    Heading(stringResource(R.string.match_bond_q))
                    FlowRowPills(MatchIntent.entries, intents) { i -> intents = if (i in intents) intents - i else intents + i }
                    if (vm.todaysAccepted.isNotEmpty()) TodayStrip(vm)
                }
                MatchViewModel.Phase.SPINNING -> Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(stringResource(R.string.match_searching), style = ABFont.display(22f), color = Color.White)
                    Text(stringResource(R.string.match_searching_sub), style = ABFont.body(13f), color = Color.White.copy(0.65f), textAlign = TextAlign.Center)
                }
                MatchViewModel.Phase.REVEALED -> vm.active?.let { RevealedBlock(vm, it, onNew = { vm.reject(); vm.spin() }) }
            }
        }
    }

    if (vm.showLimit) AlertDialog({ vm.showLimit = false }, confirmButton = { TextButton({ vm.showLimit = false }) { Text(stringResource(R.string.ok)) } },
        title = { Text(stringResource(R.string.match_limit_title)) }, text = { Text(stringResource(R.string.match_limit_body)) })
    if (vm.showNoCandidates) AlertDialog({ vm.showNoCandidates = false }, confirmButton = { TextButton({ vm.showNoCandidates = false }) { Text(stringResource(R.string.ok)) } },
        title = { Text(stringResource(R.string.match_none_title)) }, text = { Text(stringResource(R.string.match_none_body)) })
    val msg = vm.message
    if (msg != null && vm.phase == MatchViewModel.Phase.IDLE) AlertDialog({ vm.message = null }, confirmButton = { TextButton({ vm.message = null }) { Text(stringResource(R.string.ok)) } },
        title = { Text(stringResource(R.string.match_fail_title)) }, text = { Text(msg) })
}

private fun applySelections(vm: MatchViewModel, intents: Set<MatchIntent>, o: Set<Orientation>) {
    var next = vm.prefs
    MatchIntent.entries.firstOrNull { it in intents }?.let { next = next.copy(intent = it) }
    val g = buildList {
        if (Orientation.KADIN in o) add(Gender.WOMAN)
        if (Orientation.ERKEK in o) add(Gender.MAN)
        if (Orientation.LGBT in o) { add(Gender.NON_BINARY); add(Gender.OTHER) }
    }
    if (g.isNotEmpty()) next = next.copy(preferredGenders = g)
    vm.persistPrefs(next)
}

@Composable
private fun Heading(t: String) = Text(t, style = ABFont.display(17f, FontWeight.Normal), color = Color.White.copy(0.92f), textAlign = TextAlign.Center)

@Composable
private fun Pill(title: String, selected: Boolean, onClick: () -> Unit, modifier: Modifier) {
    Box(modifier.clip(CircleShape).background(if (selected) ABColor.Lavender.copy(0.38f) else hex("#12101A").copy(0.88f))
        .border(1.dp, ABColor.Lavender.copy(if (selected) 0.9f else 0.5f), CircleShape).clickable(onClick = onClick).padding(horizontal = 18.dp, vertical = 10.dp), contentAlignment = Alignment.Center) {
        Text(title, style = ABFont.body(13.5f, FontWeight.SemiBold), color = Color.White)
    }
}

@Composable
private fun FlowRowPills(all: List<MatchIntent>, sel: Set<MatchIntent>, toggle: (MatchIntent) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(7.dp)) {
        all.chunked(2).forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(7.dp)) { row.forEach { Pill(it.bondLabel, it in sel, { toggle(it) }, Modifier.width(150.dp)) } }
        }
    }
}

@Composable
private fun TodayStrip(vm: MatchViewModel) {
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(stringResource(R.string.today_matches), style = ABFont.label(11f), color = Color.White.copy(0.6f), letterSpacing = 1.5.sp)
        LazyRow(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            items(vm.todaysAccepted, key = { it.id }) { r ->
                Column(Modifier.clickable { vm.detailCard = MatchCard(r.id, r.displayName, r.age, r.city, r.sunSign, null, null, "", r.photoURL, r.cartoonAvatarId) }, horizontalAlignment = Alignment.CenterHorizontally) {
                    PersonAvatar(r.displayName, r.photoURL, r.cartoonAvatarId, r.sunSign, false, 52.dp)
                    Text(r.displayName.substringBefore(" "), style = ABFont.body(11.5f), color = Color.White.copy(0.8f))
                }
            }
        }
    }
}

@Composable
private fun RevealedBlock(vm: MatchViewModel, m: MatchCard, onNew: () -> Unit) {
    val score = remember(m, vm.myChart, vm.theirChart) { BondStory.report(vm.mySun, m, vm.prefs.intent, vm.myChart, vm.theirChart).overall }
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(26.dp)).background(Color.Black.copy(0.42f)).border(1.2.dp, Warm.copy(0.5f), RoundedCornerShape(26.dp)).padding(16.dp), horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            Box(Modifier.size(96.dp).clip(CircleShape).background(hex("#2A1F2E")).border(1.6.dp, Warm.copy(0.8f), CircleShape), contentAlignment = Alignment.Center) {
                Text(m.sunSign?.glyph ?: "✦", color = Warm, fontSize = 40.sp)
            }
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Row(verticalAlignment = Alignment.Top) {
                    Text(m.displayName, style = ABFont.display(22f), color = Color.White, modifier = Modifier.weight(1f))
                    var menu by remember { mutableStateOf(false) }
                    Box {
                        Text("⋯", color = Color.White, fontSize = 22.sp, modifier = Modifier.clickable { menu = true })
                        DropdownMenu(menu, { menu = false }) { DropdownMenuItem({ Text(stringResource(R.string.hide)) }, { menu = false; vm.reject() }) }
                    }
                }
                m.sunSign?.let { Text("${it.glyph}  ${it.labelTR.uppercase(java.util.Locale("tr", "TR"))} · ${it.dateRangeText}", style = ABFont.body(12.5f), color = Warm) }
                Text("♥ %$score  ${stringResource(R.string.astro_match)}", style = ABFont.body(14f, FontWeight.SemiBold), color = Color.White)
                Text(stringResource(R.string.see_profile) + " ›", style = ABFont.body(13f, FontWeight.SemiBold), color = Warm, modifier = Modifier.clickable { vm.detailCard = m })
            }
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
            RevealButton("♥", stringResource(R.string.liked), hex("#E7B8FF")) { vm.acceptReveal() }
            RevealButton("✦", stringResource(R.string.new_match), hex("#FFD36B"), onNew)
        }
    }
}

@Composable
private fun RevealButton(icon: String, label: String, glow: Color, onClick: () -> Unit) {
    Column(Modifier.clickable(onClick = onClick), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Box(Modifier.size(84.dp).clip(CircleShape).background(androidx.compose.ui.graphics.Brush.radialGradient(listOf(glow.copy(0.42f), hex("#1A1322").copy(0.9f))))
            .border(2.dp, glow, CircleShape), contentAlignment = Alignment.Center) { Text(icon, color = Color.White, fontSize = 30.sp) }
        Text(label, style = ABFont.body(13f, FontWeight.SemiBold), color = Color.White)
    }
}

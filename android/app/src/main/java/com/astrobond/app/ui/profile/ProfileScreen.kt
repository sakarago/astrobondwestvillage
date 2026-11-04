package com.astrobond.app.ui.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.astrobond.app.R
import com.astrobond.app.data.*
import com.astrobond.app.domain.*
import com.astrobond.app.session.SessionViewModel
import com.astrobond.app.ui.components.PersonAvatar
import com.astrobond.app.ui.theme.*
import kotlinx.coroutines.launch

class ProfileViewModel : ViewModel() {
    var snapshot by mutableStateOf<ProfileSnapshot?>(null); private set
    var chart by mutableStateOf<NatalChart?>(null); private set
    var error by mutableStateOf<String?>(null); private set
    var loading by mutableStateOf(true); private set
    private var loadedFor: String? = null

    fun load(userId: String, force: Boolean = false) {
        if (!force && loadedFor == userId) return
        loadedFor = userId; loading = true; error = null
        viewModelScope.launch {
            try { snapshot = ProfileRepo.fetchSnapshot(userId); chart = ChartRepo.ensureOwnChart(userId) } catch (e: Exception) { error = e.message }
            loading = false
        }
    }
    fun updateSnapshot(s: ProfileSnapshot) { snapshot = s }
}

private val Lav = hex("#9C8CFF")

/** Port of ProfileHomeView: header with big three, chart (TABLO / ÇEMBER), astral profile, houses, aspects, planet sheet; opens Settings. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(session: SessionViewModel?, vm: ProfileViewModel = viewModel()) {
    val user = session?.user?.collectAsState()?.value
    LaunchedEffect(user?.id) { user?.id?.let { vm.load(it) } }
    var showSettings by remember { mutableStateOf(false) }
    var selectedPlanet by remember { mutableStateOf<PlanetPosition?>(null) }
    var mode by remember { mutableIntStateOf(1) } // 0 table, 1 circle
    var expandedHouse by remember { mutableStateOf<Int?>(null) }
    var expandedPlanet by remember { mutableStateOf<Planet?>(null) }
    var expandedAspect by remember { mutableStateOf<Int?>(null) }

    if (showSettings && session != null) { SettingsScreen(session, vm.snapshot, onSaved = vm::updateSnapshot, onBack = { showSettings = false }); return }

    val chart = vm.chart; val snap = vm.snapshot
    val name = snap?.displayName?.trim().takeUnless { it.isNullOrEmpty() } ?: stringResource(R.string.unnamed)
    Column(Modifier.fillMaxSize().statusBarsPadding().verticalScroll(rememberScrollState()).padding(horizontal = 20.dp).padding(top = 14.dp, bottom = 130.dp), verticalArrangement = Arrangement.spacedBy(28.dp)) {
        // header
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            PersonAvatar(name, snap?.photoURL, snap?.cartoonAvatarId, chart?.sunSign ?: snap?.sunSign ?: ZodiacSign.ARIES, true, 60.dp)
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                Text(name, style = ABFont.display(24f), color = Color.White)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Chip3("☉", (chart?.sunSign ?: snap?.sunSign)?.labelTR ?: "—"); Chip3("☽", (chart?.moonSign ?: snap?.moonSign)?.labelTR ?: "—"); Chip3("↑", (chart?.risingSign ?: snap?.risingSign)?.labelTR ?: "—")
                }
            }
            Box(Modifier.size(42.dp).crystalPlate(RoundedCornerShape(14.dp)).clickable { showSettings = true }, contentAlignment = Alignment.Center) { Text("⚙", color = Color.White, fontSize = 20.sp) }
        }
        when {
            vm.loading && chart == null && snap == null -> Column(Modifier.fillMaxWidth().padding(top = 60.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
                CircularProgressIndicator(color = hex("#CDD2DB")); Text(stringResource(R.string.profile_loading), color = Color.White.copy(0.7f), style = ABFont.body(14f))
            }
            chart == null -> Column(Modifier.fillMaxWidth().padding(top = 20.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(14.dp)) {
                if (snap == null) { Text("✦", color = DT.Accent, fontSize = 36.sp); Text(stringResource(R.string.profile_empty_title), style = ABFont.display(22f), color = Color.White); Text(stringResource(R.string.profile_empty_sub), style = ABFont.body(14f), color = Color.White.copy(0.65f)) }
                else Text(stringResource(R.string.chart_computing), style = ABFont.body(14f), color = Color.White.copy(0.7f))
                vm.error?.let { Text(it, style = ABFont.body(12.5f), color = hex("#C69A9A")) }
                TextButton({ user?.id?.let { vm.load(it, true) } }) { Text(stringResource(R.string.retry_tr), color = Lav) }
            }
            else -> {
                Section(stringResource(R.string.your_sky), stringResource(R.string.natal_chart)) {
                    Row(horizontalArrangement = Arrangement.spacedBy(18.dp)) {
                        listOf(R.string.mode_table, R.string.mode_circle).forEachIndexed { i, r ->
                            Column(Modifier.clickable { mode = i }, horizontalAlignment = Alignment.CenterHorizontally) {
                                Text(stringResource(r), style = ABFont.label(12f), color = if (mode == i) Color.White else Color.White.copy(0.5f), letterSpacing = 1.5.sp)
                                Box(Modifier.padding(top = 6.dp).width(44.dp).height(2.dp).background(if (mode == i) Lav else Color.Transparent))
                            }
                        }
                    }
                    if (mode == 1) Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(28.dp)).border(1.dp, Color.White.copy(0.12f), RoundedCornerShape(28.dp))) { ChartWheel(chart, onPlanetTap = { selectedPlanet = it }) }
                    else Column(Modifier.fillMaxWidth().crystalPlate(RoundedCornerShape(28.dp))) {
                        chart.planets.forEachIndexed { i, p ->
                            Row(Modifier.fillMaxWidth().clickable { selectedPlanet = p }.padding(16.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                                Text(p.planet.glyph, color = planetColor(p.planet), fontSize = 22.sp)
                                Column(Modifier.weight(1f)) { Text(p.planet.tr, style = ABFont.body(15f, FontWeight.SemiBold), color = Color.White); Text("${p.sign.labelTR} • ${p.house}. Ev", style = ABFont.body(12f), color = Color.White.copy(0.6f)) }
                                Text(degreeText(p), style = ABFont.body(13f), color = Color.White.copy(0.8f))
                            }
                            if (i < chart.planets.size - 1) HorizontalDivider(color = Color.White.copy(0.08f))
                        }
                    }
                }
                Section(stringResource(R.string.soul_signature), stringResource(R.string.astral_profile), stringResource(R.string.astral_profile_sub)) {
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        Pill(stringResource(R.string.element), chart.dominantElement.labelTR, Modifier.weight(1f)); Pill(stringResource(R.string.modality), chart.dominantModality.labelTR, Modifier.weight(1f))
                    }
                    chart.planets.take(7).forEach { p ->
                        val open = expandedPlanet == p.planet
                        Column(Modifier.fillMaxWidth().crystalPlate(RoundedCornerShape(22.dp)).clickable { expandedPlanet = if (open) null else p.planet }.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                                Text(p.planet.glyph, color = planetColor(p.planet), fontSize = 24.sp)
                                Column(Modifier.weight(1f)) { Text("${p.planet.tr} ${p.sign.labelTR}", style = ABFont.body(15f, FontWeight.SemiBold), color = Color.White); Text("${p.house}. Ev${if (p.isRetrograde) " • Retro ℞" else ""}", style = ABFont.body(12f), color = Color.White.copy(0.6f)) }
                                Text(degreeText(p), style = ABFont.body(13f), color = Color.White.copy(0.8f))
                            }
                            if (open) Text(AstralReadings.planet(p.planet, p.sign), style = ABFont.body(13.5f), color = Color.White.copy(0.85f))
                        }
                    }
                }
                Section(stringResource(R.string.life_areas), stringResource(R.string.houses), stringResource(R.string.houses_sub)) {
                    chart.houses.forEach { h ->
                        val open = expandedHouse == h.number
                        Column(Modifier.fillMaxWidth().crystalPlate(RoundedCornerShape(22.dp)).clickable { expandedHouse = if (open) null else h.number }.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                                Text(h.roman, style = ABFont.body(15f, FontWeight.Bold), color = Lav, modifier = Modifier.width(34.dp))
                                Column { Text("${h.sign.glyph} ${h.sign.labelTR}", style = ABFont.body(15f, FontWeight.SemiBold), color = Color.White); Text(h.theme, style = ABFont.body(12f), color = Color.White.copy(0.6f)) }
                            }
                            if (open) {
                                Text("${h.sign.labelTR}, ${h.number}. evinde", style = ABFont.body(13f, FontWeight.Bold), color = DT.Accent)
                                Text(AstralReadings.house(h.number, h.sign), style = ABFont.body(13.5f), color = Color.White.copy(0.85f))
                                if (h.planets.isNotEmpty()) { Text(stringResource(R.string.house_planets), style = ABFont.label(11f), color = Color.White.copy(0.6f)); Text(h.planets.joinToString("  ") { "${it.glyph} ${it.tr}" }, color = Color.White, style = ABFont.body(13.5f)) }
                            }
                        }
                    }
                }
                Section(stringResource(R.string.planet_aspects), stringResource(R.string.aspects_title), stringResource(R.string.aspects_sub)) {
                    chart.aspects.sortedByDescending { it.strength }.take(12).forEachIndexed { i, a ->
                        val harmonious = a.type.harmonious; val tint = aspectColor(a.type); val open = expandedAspect == i
                        Column(Modifier.fillMaxWidth().crystalPlate(RoundedCornerShape(22.dp)).clickable { expandedAspect = if (open) null else i }.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Row { Text(stringResource(if (harmonious) R.string.harmonious_aspect else R.string.dynamic_aspect), style = ABFont.label(11f), color = tint, modifier = Modifier.weight(1f))
                                Text(if (a.orb < 0.5) stringResource(R.string.exact) else "%.1f°".format(a.orb), style = ABFont.body(12f), color = Color.White.copy(0.6f)) }
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                                Text(a.planet1.glyph, color = planetColor(a.planet1), fontSize = 22.sp); Text(a.type.glyph, color = tint, fontSize = 20.sp); Text(a.planet2.glyph, color = planetColor(a.planet2), fontSize = 22.sp)
                                Text("${a.planet1.tr} – ${a.planet2.tr}", style = ABFont.body(14f, FontWeight.SemiBold), color = Color.White)
                            }
                            Text(a.type.wire, style = ABFont.body(12.5f), color = Color.White.copy(0.65f))
                            if (open) Text(AstralReadings.aspect(a), style = ABFont.body(13.5f), color = Color.White.copy(0.85f))
                        }
                    }
                }
            }
        }
    }
    selectedPlanet?.let { p ->
        ModalBottomSheet({ selectedPlanet = null }, containerColor = hex("#15101F")) {
            Column(Modifier.fillMaxWidth().padding(horizontal = 22.dp).padding(bottom = 36.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text("${p.planet.glyph} ${p.planet.tr}", style = ABFont.display(26f), color = planetColor(p.planet))
                Text("${p.sign.glyph} ${p.sign.labelTR} · Ev ${p.house}${if (p.isRetrograde) " · ℞" else ""}", style = ABFont.body(14f), color = Color.White.copy(0.75f))
                Text("%.1f° %s".format(p.degree, p.sign.labelTR), style = ABFont.body(13f), color = Color.White.copy(0.6f))
                Text(stringResource(R.string.what_it_means), style = ABFont.label(12f), color = DT.Accent)
                Text(AstralReadings.planet(p.planet, p.sign), style = ABFont.body(14.5f), color = Color.White.copy(0.9f))
            }
        }
    }
}

private fun degreeText(p: PlanetPosition): String { val d = p.degree.toInt(); val m = ((p.degree - d) * 60).toInt(); return "%d°%02d'".format(d, m) }

@Composable private fun Chip3(sym: String, name: String) = Text("$sym $name", style = ABFont.body(11.5f, FontWeight.Medium), color = Color.White.copy(0.85f), modifier = Modifier.clip(CircleShape).background(Color.White.copy(0.08f)).border(1.dp, Color.White.copy(0.15f), CircleShape).padding(horizontal = 9.dp, vertical = 4.dp))

@Composable private fun Pill(label: String, value: String, modifier: Modifier) = Column(modifier.crystalPlate(RoundedCornerShape(20.dp)).padding(14.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
    Text(label.uppercase(), style = ABFont.label(10.5f), color = Color.White.copy(0.55f)); Text(value, style = ABFont.body(16f, FontWeight.SemiBold), color = Color.White)
}

@Composable
private fun Section(overline: String, title: String, subtitle: String? = null, content: @Composable ColumnScope.() -> Unit) = Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text("✦ $overline", style = ABFont.label(11f), color = Lav, letterSpacing = 2.sp)
        Text(title, style = ABFont.display(26f, FontWeight.Normal), color = Color.White)
        subtitle?.let { Text(it, style = ABFont.body(13f), color = Color.White.copy(0.6f)) }
    }
    content()
}

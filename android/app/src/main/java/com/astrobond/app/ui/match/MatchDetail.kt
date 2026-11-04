package com.astrobond.app.ui.match

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.activity.compose.BackHandler
import com.astrobond.app.R
import com.astrobond.app.domain.*
import com.astrobond.app.ui.components.GlowButton
import com.astrobond.app.ui.components.PersonAvatar
import com.astrobond.app.ui.theme.*

/** One synastry row (port of SynastryChart.fromCharts / hashed fallback). */
data class SynastryPoint(val id: String, val label: String, val glyph: String, val mine: ZodiacSign, val theirs: ZodiacSign, val mineDeg: Int, val mineMin: Int, val theirDeg: Int, val theirMin: Int)

private fun synastryPoints(my: NatalChart, th: NatalChart): List<SynastryPoint> {
    fun pair(id: String, label: String, glyph: String, a: ZodiacPoint, b: ZodiacPoint) =
        SynastryPoint(id, label, glyph, a.sign, b.sign, a.degree.toInt(), ((a.degree - a.degree.toInt()) * 60).toInt(), b.degree.toInt(), ((b.degree - b.degree.toInt()) * 60).toInt())
    fun pp(c: NatalChart, p: Planet) = c.planet(p)?.let { ZodiacPoint.of(it.longitude) } ?: ZodiacPoint(c.sunSign, 0.0, c.sunSign.startDegree)
    return listOf(
        pair("sun", "Güneş", "☉", pp(my, Planet.SUN), pp(th, Planet.SUN)), pair("moon", "Ay", "☽", pp(my, Planet.MOON), pp(th, Planet.MOON)),
        pair("rising", "Yükselen", "↑", my.ascendant, th.ascendant), pair("mercury", "Merkür", "☿", pp(my, Planet.MERCURY), pp(th, Planet.MERCURY)),
        pair("venus", "Venüs", "♀", pp(my, Planet.VENUS), pp(th, Planet.VENUS)), pair("mars", "Mars", "♂", pp(my, Planet.MARS), pp(th, Planet.MARS)),
        pair("mc", "MC (Tepe)", "MC", my.midheaven, th.midheaven),
    )
}

/** Sinastri page (port of MatchDetailSheet, simplified: no dual wheel yet). */
@Composable
fun MatchDetailScreen(vm: MatchViewModel, card: MatchCard, onBack: () -> Unit) {
    BackHandler(onBack = onBack)
    val th = LocalTh.current
    val theirChart = remember(card.id, vm.theirChart) { vm.theirChart?.takeIf { it.userId == card.id } }
    val report = remember(card, vm.myChart, theirChart, vm.prefs.intent) { BondStory.report(vm.mySun, card, vm.prefs.intent, vm.myChart, theirChart) }
    val points = remember(vm.myChart, theirChart) { if (vm.myChart != null && theirChart != null) synastryPoints(vm.myChart!!, theirChart) else emptyList() }

    Column(Modifier.fillMaxSize().statusBarsPadding().verticalScroll(rememberScrollState()).padding(horizontal = 20.dp).padding(top = 8.dp, bottom = 130.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Box(Modifier.size(36.dp).clip(CircleShape).background(th.chipOff).border(1.dp, th.cardStroke, CircleShape).clickable(onClick = onBack), contentAlignment = Alignment.Center) {
            Text("‹", color = th.primary, fontSize = 22.sp)
        }
        Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(stringResource(R.string.synastry), style = ABFont.label(12f), color = th.secondary, letterSpacing = 3.sp)
            Text(stringResource(R.string.synastry_sub), style = ABFont.body(13f), color = th.secondary)
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly, verticalAlignment = Alignment.CenterVertically) {
            Person(vm.myName, vm.myPhotoURL, vm.myAvatarId, vm.mySun, true)
            Text("%${report.overall}", style = ABFont.display(34f), color = DT.Accent)
            Person(card.displayName, card.photoURL, card.cartoonAvatarId, card.sunSign, false)
        }
        Card {
            Text(report.bondTier.english, style = ABFont.display(24f), color = Color.White)
            Text("${report.bondTier.turkish} · ${report.bondTier.tagline}", style = ABFont.body(13f, FontWeight.Medium), color = DT.Accent)
            Text(report.bondTier.summary, style = ABFont.body(13.5f), color = th.secondary)
        }
        report.rareHighlight?.let { r ->
            Card {
                Text("☋ ${r.badgeTitle}", style = ABFont.body(14f, FontWeight.Bold), color = hex("#F3DEC2"))
                Text(r.badgeSubtitle, style = ABFont.body(12f), color = th.secondary)
                Text(r.heading, style = ABFont.label(12f), color = DT.Accent, letterSpacing = 1.5.sp)
                Text(r.note, style = ABFont.body(13.5f), color = Color.White.copy(0.85f))
            }
        }
        Card {
            Text(report.title, style = ABFont.display(20f), color = Color.White)
            Text(report.headline, style = ABFont.body(13f), color = th.secondary)
            report.dimensions.forEach { d ->
                Row { Text(d.title, style = ABFont.body(13.5f, FontWeight.SemiBold), color = Color.White, modifier = Modifier.weight(1f)); Text("%${d.score}", color = DT.Accent, style = ABFont.body(13f)) }
                LinearProgressIndicator(progress = { d.score / 100f }, modifier = Modifier.fillMaxWidth().height(5.dp).clip(CircleShape), color = ABColor.Lavender, trackColor = Color.White.copy(0.1f))
                Text(d.blurb, style = ABFont.body(12f), color = th.secondary)
            }
        }
        Card {
            Text(stringResource(R.string.spiritual), style = ABFont.display(18f), color = Color.White)
            Text(report.connectionSummary, style = ABFont.body(13.5f), color = th.secondary)
        }
        if (points.isNotEmpty()) Card {
            points.forEach { p ->
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Text("${p.mine.glyph} ${p.mine.labelTR} ${p.mineDeg}°${p.mineMin}'", style = ABFont.body(12.5f), color = Color.White, modifier = Modifier.weight(1f))
                    Text("${p.glyph} ${p.label}", style = ABFont.label(12f), color = DT.Accent)
                    Text("${p.theirs.glyph} ${p.theirs.labelTR} ${p.theirDeg}°${p.theirMin}'", style = ABFont.body(12.5f), color = Color.White, modifier = Modifier.weight(1f), textAlign = androidx.compose.ui.text.style.TextAlign.End)
                }
            }
        }
        if (report.aspects.isNotEmpty()) Section(stringResource(R.string.aspects), report.aspects.map { "✦ $it" })
        if (report.strengths.isNotEmpty()) Section(stringResource(R.string.strengths), report.strengths.map { "${it.title} — ${it.detail}" })
        if (report.challenges.isNotEmpty()) Section(stringResource(R.string.challenges), report.challenges.map { "${it.title} — ${it.detail}" })
        report.snapshots.forEach { s ->
            Card { Text(s.eyebrow, style = ABFont.label(11f), color = DT.Accent, letterSpacing = 1.5.sp); Text(s.body, style = ABFont.body(13.5f), color = Color.White.copy(0.85f)) }
        }
        GlowButton(stringResource(R.string.send_message), { vm.accept(card); vm.message = null; onBack() }, showSparkle = false)
    }
}

@Composable
private fun Person(name: String, photo: String?, avatar: String?, sun: ZodiacSign?, unlocked: Boolean) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
        PersonAvatar(name, photo, avatar, sun, unlocked, 68.dp)
        Text(name.substringBefore(" "), style = ABFont.body(13f, FontWeight.SemiBold), color = Color.White)
        sun?.let { Text("${it.glyph} ${it.labelTR}", style = ABFont.body(12f), color = Color.White.copy(0.65f)) }
    }
}

@Composable
private fun Card(content: @Composable ColumnScope.() -> Unit) {
    val th = LocalTh.current
    Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(20.dp)).background(th.cardFill).border(1.dp, th.cardStroke, RoundedCornerShape(20.dp)).padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp), content = content)
}

@Composable
private fun Section(title: String, lines: List<String>) = Card {
    Text(title, style = ABFont.display(18f), color = Color.White)
    lines.forEach { Text(it, style = ABFont.body(13f), color = Color.White.copy(0.8f)) }
}

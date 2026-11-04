package com.astrobond.app.ui.profile

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.text.KeyboardOptions
import com.astrobond.app.R
import com.astrobond.app.data.*
import com.astrobond.app.notify.DailyMessageNotifier
import com.astrobond.app.notify.rememberNotificationPermissionRequest
import com.astrobond.app.session.SessionViewModel
import com.astrobond.app.ui.components.*
import com.astrobond.app.ui.theme.*
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.ZoneOffset

private enum class Page { MAIN, EDIT, PREMIUM, LANGUAGE, BLOCKED, HELP, ABOUT, LEGAL, FREEZE, DELETE }

/** Port of SettingsView and its sub-pages. */
@Composable
fun SettingsScreen(session: SessionViewModel, snapshot: ProfileSnapshot?, onSaved: (ProfileSnapshot) -> Unit, onBack: () -> Unit) {
    var page by remember { mutableStateOf(Page.MAIN) }
    val ctx = LocalContext.current
    val prefs = remember { NotificationPrefs(ctx) }
    BackHandler { if (page == Page.MAIN) onBack() else page = Page.MAIN }
    when (page) {
        Page.MAIN -> Main(session, prefs, ctx, onBack) { page = it }
        Page.EDIT -> EditProfile(session, snapshot, onSaved, onBack = { page = Page.MAIN })
        Page.PREMIUM -> Info(stringResource(R.string.premium), stringResource(R.string.premium_body)) { page = Page.MAIN }
        Page.LANGUAGE -> Info(stringResource(R.string.language), "✓ Türkçe") { page = Page.MAIN }
        Page.BLOCKED -> Info(stringResource(R.string.blocked_none), stringResource(R.string.blocked_none_sub)) { page = Page.MAIN }
        Page.HELP -> Help { page = Page.MAIN }
        Page.ABOUT -> Info("AstroBond", stringResource(R.string.about_new) + "\n\n" + stringResource(R.string.about_body)) { page = Page.MAIN }
        Page.LEGAL -> Info(stringResource(R.string.legal_title), stringResource(R.string.legal_body)) { page = Page.MAIN }
        Page.FREEZE -> Confirm(stringResource(R.string.freeze_account), stringResource(R.string.freeze_body), stringResource(R.string.freeze), false, { page = Page.MAIN }) { session.freezeAccount() }
        Page.DELETE -> Confirm(stringResource(R.string.delete_account), stringResource(R.string.delete_body), stringResource(R.string.delete_account), true, { page = Page.MAIN }) { session.deleteAccount() }
    }
}

@Composable
private fun Frame(title: String, onBack: () -> Unit, content: @Composable ColumnScope.() -> Unit) = Column(
    Modifier.fillMaxSize().statusBarsPadding().verticalScroll(rememberScrollState()).padding(horizontal = 20.dp).padding(top = 8.dp, bottom = 40.dp), verticalArrangement = Arrangement.spacedBy(16.dp),
) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Box(Modifier.size(36.dp).crystalPlate(RoundedCornerShape(12.dp)).clickable(onClick = onBack), contentAlignment = Alignment.Center) { Text("‹", color = Color.White, fontSize = 22.sp) }
        Text(title, style = ABFont.display(26f), color = Color.White)
    }
    content()
}

@Composable private fun Card(content: @Composable ColumnScope.() -> Unit) = Column(Modifier.fillMaxWidth().crystalPlate(RoundedCornerShape(22.dp)).padding(horizontal = 16.dp, vertical = 4.dp), content = content)
@Composable private fun Div() = HorizontalDivider(color = Color.White.copy(0.08f))

@Composable
private fun NavRow(title: String, value: String? = null, tint: Color = ABColor.Ink, onClick: () -> Unit) = Row(Modifier.fillMaxWidth().clickable(onClick = onClick).padding(vertical = 15.dp), verticalAlignment = Alignment.CenterVertically) {
    Text(title, style = ABFont.body(16f, FontWeight.Medium), color = tint, modifier = Modifier.weight(1f))
    if (value != null) Text(value, style = ABFont.body(14f), color = ABColor.InkMuted, modifier = Modifier.padding(end = 8.dp))
    Text("›", color = ABColor.InkMuted, fontSize = 20.sp)
}

@Composable
private fun ToggleRow(title: String, checked: Boolean, onChange: (Boolean) -> Unit) = Row(Modifier.fillMaxWidth().padding(vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
    Text(title, style = ABFont.body(16f, FontWeight.Medium), color = ABColor.Ink, modifier = Modifier.weight(1f))
    Switch(checked, onChange, colors = SwitchDefaults.colors(checkedTrackColor = ABColor.Lavender))
}

@Composable
private fun Main(session: SessionViewModel, prefs: NotificationPrefs, ctx: android.content.Context, onBack: () -> Unit, go: (Page) -> Unit) {
    var priv by remember { mutableStateOf(prefs.privateAccount) }
    var insight by remember { mutableStateOf(prefs.dailyInsight) }
    var match by remember { mutableStateOf(prefs.newMatches) }
    var msg by remember { mutableStateOf(prefs.messages) }
    var transit by remember { mutableStateOf(prefs.transits) }
    val error by session.error.collectAsState()
    val askNotifications = rememberNotificationPermissionRequest { DailyMessageNotifier.scheduleDaily(ctx) }
    Frame(stringResource(R.string.settings), onBack) {
        error?.takeIf { it.isNotEmpty() }?.let { Text(it, color = hex("#C69A9A"), style = ABFont.body(13f), modifier = Modifier.crystalPlate(RoundedCornerShape(16.dp)).padding(12.dp)) }
        Card {
            NavRow(stringResource(R.string.edit_profile)) { go(Page.EDIT) }; Div()
            ToggleRow(stringResource(R.string.private_account), priv) { priv = it; prefs.privateAccount = it }; Div()
            NavRow(stringResource(R.string.premium)) { go(Page.PREMIUM) }; Div()
            NavRow(stringResource(R.string.language), "Türkçe") { go(Page.LANGUAGE) }
        }
        Text(stringResource(R.string.notifications), style = ABFont.label(11f), color = ABColor.InkMuted, letterSpacing = 1.5.sp)
        Card {
            ToggleRow(stringResource(R.string.n_insight), insight) { insight = it; prefs.dailyInsight = it; if (it) askNotifications() else DailyMessageNotifier.cancel(ctx) }; Div()
            ToggleRow(stringResource(R.string.n_matches), match) { match = it; prefs.newMatches = it }; Div()
            ToggleRow(stringResource(R.string.n_messages), msg) { msg = it; prefs.messages = it }; Div()
            ToggleRow(stringResource(R.string.n_transits), transit) { transit = it; prefs.transits = it }
        }
        Card {
            NavRow(stringResource(R.string.blocked_users)) { go(Page.BLOCKED) }; Div()
            NavRow(stringResource(R.string.help_center)) { go(Page.HELP) }; Div()
            NavRow(stringResource(R.string.about_us)) { go(Page.ABOUT) }; Div()
            NavRow(stringResource(R.string.legal_info)) { go(Page.LEGAL) }
        }
        Card {
            NavRow(stringResource(R.string.sign_out)) { session.signOut() }; Div()
            NavRow(stringResource(R.string.freeze_account)) { go(Page.FREEZE) }; Div()
            NavRow(stringResource(R.string.delete_account), tint = hex("#FF9F8F")) { go(Page.DELETE) }
        }
    }
}

@Composable
private fun Info(title: String, body: String, onBack: () -> Unit) = Frame(title, onBack) { Text(body, style = ABFont.body(14.5f), color = ABColor.InkMuted) }

@Composable
private fun Help(onBack: () -> Unit) = Frame(stringResource(R.string.help_title), onBack) {
    listOf(
        "Günde kaç eşleşme alırım?" to "Ücretsiz planda günde yaklaşık 3 yeni eşleşme hakkı vardır. Kota sunucu tarafında da doğrulanır.",
        "Fotoğraf ne zaman görünür?" to "Sohbette toplam ${PhotoGate.UNLOCK_AFTER} mesajdan sonra gerçek profil fotoğrafı açılır.",
        "Doğum haritam doğru mu?" to "Haritan doğum tarih, saat ve yerinden hesaplanır. Gezegenler, evler ve açılar gerçek gök konumlarına dayanır.",
        "Hesabımı nasıl silerim?" to "Ayarlar → Hesabı Sil. Bu işlem geri alınamaz.",
    ).forEach { (q, a) -> Column(Modifier.fillMaxWidth().crystalPlate(RoundedCornerShape(18.dp)).padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(q, style = ABFont.body(15f, FontWeight.SemiBold), color = ABColor.Ink); Text(a, style = ABFont.body(14f), color = ABColor.InkMuted) } }
}

@Composable
private fun Confirm(title: String, body: String, confirm: String, destructive: Boolean, onBack: () -> Unit, action: () -> Unit) {
    var busy by remember { mutableStateOf(false) }
    Frame(title, onBack) {
        Text(body, style = ABFont.body(14.5f), color = ABColor.InkMuted)
        GlowButton(if (busy) stringResource(R.string.processing) else confirm, { busy = true; action() }, enabled = !busy, showSparkle = false)
        if (destructive) Text("⚠", color = hex("#FF9F8F"))
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun EditProfile(session: SessionViewModel, snap: ProfileSnapshot?, onSaved: (ProfileSnapshot) -> Unit, onBack: () -> Unit) {
    val ctx = LocalContext.current
    val user by session.user.collectAsState()
    val scope = rememberCoroutineScope()
    val parts = snap?.displayName?.split(" ", limit = 2).orEmpty()
    var first by remember { mutableStateOf(parts.firstOrNull() ?: "") }
    var last by remember { mutableStateOf(parts.getOrNull(1) ?: "") }
    var bio by remember { mutableStateOf(snap?.bio ?: "") }
    val owning = remember { CityOption.containing(ctx, snap?.district ?: "", snap?.city) ?: CityOption.presets(ctx).firstOrNull { it.name == snap?.city } ?: CityOption.default(ctx) }
    var city by remember { mutableStateOf(owning) }
    var district by remember { mutableStateOf(owning.districts.firstOrNull { it.name == snap?.district } ?: owning.districts.first()) }
    var birth by remember { mutableStateOf(snap?.birthDate ?: LocalDate.now().minusYears(25)) }
    var avatar by remember { mutableStateOf(snap?.cartoonAvatarId) }
    var saving by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var showDate by remember { mutableStateOf(false) }
    var pick by remember { mutableIntStateOf(0) } // 1 city 2 district

    Frame(stringResource(R.string.edit_profile), onBack) {
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            CrystalField(stringResource(R.string.first_name), first, { first = it }, Modifier.weight(1f)); CrystalField(stringResource(R.string.last_name), last, { last = it }, Modifier.weight(1f))
        }
        Text(stringResource(R.string.email_label) + ": " + (user?.email ?: "—"), style = ABFont.body(13.5f), color = ABColor.InkMuted)
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) { Text(stringResource(R.string.ob_birth_date), color = Color.White, modifier = Modifier.weight(1f))
            Chip("%02d.%02d.%d".format(birth.dayOfMonth, birth.monthValue, birth.year), true, { showDate = true }) }
        Chip("${city.name}, ${city.country}", true, { pick = 1 }, Modifier.fillMaxWidth())
        Chip(district.name, true, { pick = 2 }, Modifier.fillMaxWidth())
        CrystalField(stringResource(R.string.about_label), bio, { bio = it })
        val options = remember(snap?.gender) { CartoonAvatar.options(ctx, snap?.gender ?: com.astrobond.app.domain.Gender.PREFER_NOT_SAY) }
        LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            items(options, key = { it.id }) { a -> Box(Modifier.clickable { avatar = a.id }.then(if (avatar == a.id) Modifier.background(ABColor.LavenderSoft.copy(0.3f), CircleShape).padding(3.dp) else Modifier.padding(3.dp))) { CartoonAvatarView(a, 56.dp) } }
        }
        error?.let { Text(it, style = ABFont.body(13f), color = hex("#C69A9A")) }
        GlowButton(stringResource(if (saving) R.string.saving else R.string.save), {
            val id = user?.id ?: return@GlowButton
            saving = true; error = null
            val name = listOf(first, last).map { it.trim() }.filter { it.isNotEmpty() }.joinToString(" ").ifEmpty { "Kullanıcı" }
            scope.launch {
                try { ProfileRepo.updateProfile(id, name, bio, city, district, birth, avatar); ProfileRepo.fetchSnapshot(id)?.let(onSaved); onBack() } catch (e: Exception) { error = e.message }
                saving = false
            }
        }, enabled = !saving, showSparkle = false)
    }
    if (showDate) {
        val state = rememberDatePickerState(birth.atStartOfDay().toInstant(ZoneOffset.UTC).toEpochMilli(), selectableDates = object : SelectableDates {
            override fun isSelectableDate(utcTimeMillis: Long) = utcTimeMillis <= LocalDate.now().minusYears(18).atStartOfDay().toInstant(ZoneOffset.UTC).toEpochMilli() })
        DatePickerDialog({ showDate = false }, confirmButton = { TextButton({ state.selectedDateMillis?.let { birth = java.time.Instant.ofEpochMilli(it).atZone(ZoneOffset.UTC).toLocalDate() }; showDate = false }) { Text(stringResource(R.string.ok)) } }) { DatePicker(state) }
    }
    if (pick != 0) {
        var q by remember { mutableStateOf("") }
        val tr = java.util.Locale("tr", "TR")
        fun n(s: String) = s.lowercase(tr).replace('ı', 'i')
        val cities = remember(q) { CityOption.presets(ctx).filter { n(it.name).contains(n(q)) } }
        val districts = remember(q, city) { city.districts.filter { n(it.name).contains(n(q)) } }
        AlertDialog({ pick = 0 }, confirmButton = {}, dismissButton = { TextButton({ pick = 0 }) { Text(stringResource(R.string.close)) } }, text = {
            Column { TextField(q, { q = it }, singleLine = true, modifier = Modifier.fillMaxWidth())
                LazyColumn(Modifier.heightIn(max = 380.dp)) {
                    if (pick == 1) items(cities, key = { it.id }) { c -> Text("${c.name}, ${c.country}", Modifier.fillMaxWidth().clickable { city = c; district = c.districts.first(); pick = 0 }.padding(vertical = 12.dp)) }
                    else items(districts, key = { it.id }) { d -> Text(d.name, Modifier.fillMaxWidth().clickable { district = d; pick = 0 }.padding(vertical = 12.dp)) }
                } } })
    }
}

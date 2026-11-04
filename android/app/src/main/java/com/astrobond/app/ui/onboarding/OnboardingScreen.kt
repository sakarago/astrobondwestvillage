package com.astrobond.app.ui.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.astrobond.app.R
import com.astrobond.app.data.*
import com.astrobond.app.domain.*
import com.astrobond.app.session.SessionViewModel
import com.astrobond.app.ui.components.*
import com.astrobond.app.ui.theme.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.ZoneOffset

/** Port of OnboardingViewModel (Features/Onboarding/OnboardingFlowView.swift). */
class OnboardingViewModel : ViewModel() {
    var displayName by mutableStateOf("")
    var gender by mutableStateOf(Gender.PREFER_NOT_SAY)
    var seeking by mutableStateOf(setOf(Gender.WOMAN, Gender.MAN))
    var avatarId by mutableStateOf<String?>(null)
    var birthDate by mutableStateOf(LocalDate.now().minusYears(25))
    var timeKnown by mutableStateOf(false)
    var hour by mutableIntStateOf(12)
    var minute by mutableIntStateOf(0)
    var city by mutableStateOf<CityOption?>(null)
    var district by mutableStateOf<District?>(null)
    var step by mutableIntStateOf(0)
    var isSaving by mutableStateOf(false)
    var error by mutableStateOf<String?>(null)
    var chart by mutableStateOf<NatalChart?>(null)
    private var attempted = false

    val canContinueName get() = displayName.trim().length >= 2 && avatarId != null

    fun selectCity(c: CityOption) { city = c; district = c.districts.firstOrNull() }

    fun toggleSeeking(g: Gender) {
        seeking = if (g in seeking) { if (seeking.size > 1) seeking - g else seeking } else seeking + g
    }

    fun save(userId: String, force: Boolean = false) {
        if (attempted && !force) return
        attempted = true
        val c = city ?: return; val d = district ?: return
        isSaving = true; error = null
        viewModelScope.launch {
            try {
                val maxDob = LocalDate.now().minusYears(18)
                chart = ProfileRepo.completeOnboarding(
                    userId, displayName.trim(), gender, if (birthDate.isAfter(maxDob)) maxDob else birthDate,
                    timeKnown, hour, minute, c, d, seeking.toList(), avatarId ?: "m01",
                )
            } catch (e: Exception) { error = e.message }
            isSaving = false
        }
    }

    fun resetAttempt() { attempted = false; error = null }
}

@Composable
fun OnboardingFlow(session: SessionViewModel, vm: OnboardingViewModel = viewModel()) {
    val ctx = LocalContext.current
    LaunchedEffect(Unit) { if (vm.city == null) vm.selectCity(CityOption.default(ctx)) }
    val user by session.user.collectAsState()

    CosmicBackdrop {
        Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding().imePadding().padding(horizontal = 20.dp)) {
            if (vm.step < 3) ProgressDots(vm.step, 4, Modifier.padding(top = 16.dp, bottom = 12.dp))
            Box(Modifier.weight(1f)) {
                when (vm.step) {
                    0 -> NameStep(vm)
                    1 -> BirthStep(vm)
                    2 -> PrefsStep(vm)
                    else -> {
                        LaunchedEffect(user?.id) { user?.id?.let { vm.save(it) } }
                        ChartResultStep(vm, onBack = { vm.resetAttempt(); vm.step = 2 }, onRetry = { user?.id?.let { vm.save(it, true) } }, onContinue = session::markOnboardingComplete)
                    }
                }
            }
            if (vm.step < 3) {
                Row(Modifier.fillMaxWidth().padding(vertical = 12.dp), horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
                    if (vm.step > 0) TextButton(onClick = { vm.step -= 1 }) { Text(stringResource(R.string.back), color = Color.White.copy(0.8f)) }
                    GlowButton(
                        stringResource(if (vm.step == 2) R.string.make_chart else R.string.next), { vm.step += 1 },
                        enabled = if (vm.step == 0) vm.canContinueName else true, showSparkle = false, modifier = Modifier.weight(1f),
                    )
                }
                TextButton(onClick = { session.signOut() }, modifier = Modifier.align(Alignment.CenterHorizontally)) {
                    Text(stringResource(R.string.switch_account), style = ABFont.body(12.5f), color = Color.White.copy(0.5f))
                }
            }
        }
    }
}

@Composable
private fun StepCard(title: String, subtitle: String, content: @Composable ColumnScope.() -> Unit) {
    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).crystalPlate(androidx.compose.foundation.shape.RoundedCornerShape(28.dp)).padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(title, style = ABFont.display(28f, androidx.compose.ui.text.font.FontWeight.Normal), color = Color.White)
            Text(subtitle, style = ABFont.body(14f), color = Color.White.copy(0.62f))
        }
        content()
    }
}

@Composable
private fun Label(text: String) = Text(text, style = ABFont.label(12f), color = ABColor.InkMuted)

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun NameStep(vm: OnboardingViewModel) {
    val ctx = LocalContext.current
    StepCard(stringResource(R.string.ob_who), stringResource(R.string.ob_who_sub)) {
        CrystalField(stringResource(R.string.ob_name), vm.displayName, { vm.displayName = it })
        Label(stringResource(R.string.ob_gender))
        FlowRow(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Gender.entries.forEach { g -> Chip(g.labelTR, vm.gender == g, { vm.gender = g; vm.avatarId = null }) }
        }
        Label(stringResource(R.string.ob_avatar))
        val options = remember(vm.gender) { CartoonAvatar.options(ctx, vm.gender) }
        LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            items(options, key = { it.id }) { a ->
                val sel = vm.avatarId == a.id
                Box(Modifier.clickable { vm.avatarId = a.id }.then(if (sel) Modifier.background(ABColor.LavenderSoft.copy(0.3f), androidx.compose.foundation.shape.CircleShape).padding(3.dp) else Modifier.padding(3.dp))) {
                    CartoonAvatarView(a, 64.dp)
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun BirthStep(vm: OnboardingViewModel) {
    var showDate by remember { mutableStateOf(false) }
    var showTime by remember { mutableStateOf(false) }
    StepCard(stringResource(R.string.ob_birth), stringResource(R.string.ob_birth_sub)) {
        Row(Modifier.fillMaxWidth().clickable { showDate = true }, horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            Text(stringResource(R.string.ob_birth_date), color = Color.White)
            Chip("%02d.%02d.%d".format(vm.birthDate.dayOfMonth, vm.birthDate.monthValue, vm.birthDate.year), true, { showDate = true })
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            Text(stringResource(R.string.ob_time_known), color = Color.White)
            Switch(vm.timeKnown, { vm.timeKnown = it })
        }
        if (vm.timeKnown) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Text(stringResource(R.string.ob_time), color = Color.White)
                Chip("%02d:%02d".format(vm.hour, vm.minute), true, { showTime = true })
            }
        }
        BirthPlacePicker(vm)
    }
    if (showDate) {
        val state = rememberDatePickerState(
            initialSelectedDateMillis = vm.birthDate.atStartOfDay().toInstant(ZoneOffset.UTC).toEpochMilli(),
            selectableDates = object : SelectableDates {
                override fun isSelectableDate(utcTimeMillis: Long) =
                    utcTimeMillis <= LocalDate.now().minusYears(18).atStartOfDay().toInstant(ZoneOffset.UTC).toEpochMilli()
            },
        )
        DatePickerDialog(onDismissRequest = { showDate = false }, confirmButton = {
            TextButton(onClick = {
                state.selectedDateMillis?.let { vm.birthDate = java.time.Instant.ofEpochMilli(it).atZone(ZoneOffset.UTC).toLocalDate() }
                showDate = false
            }) { Text("Tamam") }
        }, dismissButton = { TextButton(onClick = { showDate = false }) { Text("İptal") } }) { DatePicker(state) }
    }
    if (showTime) {
        val state = rememberTimePickerState(vm.hour, vm.minute, is24Hour = true)
        AlertDialog(onDismissRequest = { showTime = false },
            confirmButton = { TextButton(onClick = { vm.hour = state.hour; vm.minute = state.minute; showTime = false }) { Text("Tamam") } },
            dismissButton = { TextButton(onClick = { showTime = false }) { Text("İptal") } },
            text = { TimePicker(state) })
    }
}

@Composable
private fun BirthPlacePicker(vm: OnboardingViewModel) {
    val ctx = LocalContext.current
    var pickCity by remember { mutableStateOf(false) }
    var pickDistrict by remember { mutableStateOf(false) }
    val city = vm.city ?: return
    Label(stringResource(R.string.ob_city))
    Chip("${city.name}, ${city.country}", true, { pickCity = true }, Modifier.fillMaxWidth())
    Label(stringResource(R.string.ob_district))
    Chip(vm.district?.name ?: "", true, { pickDistrict = true }, Modifier.fillMaxWidth())

    if (pickCity) {
        var q by remember { mutableStateOf("") }
        val all = remember { CityOption.presets(ctx) }
        val list = remember(q) { all.filter { trLower(it.name).contains(trLower(q)) } }
        PickerDialog(onDismiss = { pickCity = false }, search = q, onSearch = { q = it }, hint = stringResource(R.string.ob_city_search)) {
            items(list, key = { it.id }) { c -> PickerRow("${c.name}, ${c.country}", c == city) { vm.selectCity(c); pickCity = false } }
        }
    }
    if (pickDistrict) {
        var q by remember { mutableStateOf("") }
        val list = remember(q, city) { city.districts.filter { trLower(it.name).contains(trLower(q)) } }
        PickerDialog(onDismiss = { pickDistrict = false }, search = q, onSearch = { q = it }, hint = stringResource(R.string.ob_district)) {
            items(list, key = { it.id }) { d -> PickerRow(d.name, d == vm.district) { vm.district = d; pickDistrict = false } }
        }
    }
}

private fun trLower(s: String) = s.lowercase(java.util.Locale("tr", "TR")).replace('ı', 'i')

@Composable
private fun PickerDialog(onDismiss: () -> Unit, search: String, onSearch: (String) -> Unit, hint: String, content: androidx.compose.foundation.lazy.LazyListScope.() -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss, confirmButton = {}, dismissButton = { TextButton(onClick = onDismiss) { Text("Kapat") } },
        text = {
            Column {
                TextField(search, onSearch, placeholder = { Text(hint) }, singleLine = true, modifier = Modifier.fillMaxWidth())
                LazyColumn(Modifier.heightIn(max = 380.dp), content = content)
            }
        },
    )
}

@Composable
private fun PickerRow(text: String, selected: Boolean, onClick: () -> Unit) {
    Text(text, color = if (selected) ABColor.LavenderSoft else MaterialTheme.colorScheme.onSurface,
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick).padding(vertical = 12.dp))
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun PrefsStep(vm: OnboardingViewModel) {
    StepCard(stringResource(R.string.ob_seek), stringResource(R.string.ob_seek_sub)) {
        Label(stringResource(R.string.ob_seek_label))
        listOf(Gender.WOMAN, Gender.MAN, Gender.NON_BINARY, Gender.OTHER).forEach { g ->
            Chip(g.labelTR, g in vm.seeking, { vm.toggleSeeking(g) }, Modifier.fillMaxWidth())
        }
    }
}

@Composable
private fun ChartResultStep(vm: OnboardingViewModel, onBack: () -> Unit, onRetry: () -> Unit, onContinue: () -> Unit) {
    val chart = vm.chart
    Column(Modifier.fillMaxSize().padding(vertical = 16.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
        LogoBlock()
        Spacer(Modifier.height(28.dp))
        when {
            vm.error != null -> {
                Text(vm.error!!, color = hex("#E8A0A0"), style = ABFont.body(14f))
                Spacer(Modifier.height(16.dp))
                GlowButton(stringResource(R.string.retry), onRetry, showSparkle = false)
                TextButton(onClick = onBack) { Text(stringResource(R.string.back), color = Color.White.copy(0.7f)) }
            }
            chart == null -> {
                Text(stringResource(R.string.chart_label), style = ABFont.label(12f), color = ABColor.InkMuted)
                Text(stringResource(R.string.chart_building), style = ABFont.display(22f), color = Color.White)
                Spacer(Modifier.height(20.dp))
                CircularProgressIndicator(color = ABColor.LavenderSoft)
                Spacer(Modifier.height(16.dp))
                listOf(R.string.chart_step1, R.string.chart_step2, R.string.chart_step3, R.string.chart_step4).forEach {
                    Text(stringResource(it), style = ABFont.body(13f), color = Color.White.copy(0.55f), modifier = Modifier.padding(2.dp))
                }
            }
            else -> {
                Text(stringResource(R.string.chart_ready), style = ABFont.display(26f, androidx.compose.ui.text.font.FontWeight.Normal), color = Color.White)
                Spacer(Modifier.height(20.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    SignCard(stringResource(R.string.sun_label), chart.sunSign)
                    SignCard(stringResource(R.string.moon_label), chart.moonSign)
                    SignCard(stringResource(R.string.rising_label), chart.risingSign)
                }
                Spacer(Modifier.height(28.dp))
                GlowButton(stringResource(R.string.continue_btn), onContinue)
            }
        }
    }
}

@Composable
private fun SignCard(label: String, sign: ZodiacSign) {
    Column(Modifier.width(100.dp).crystalPlate(RoundedCornerShape(20.dp)).padding(vertical = 14.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Text(label, style = ABFont.label(11f), color = ABColor.InkMuted)
        Text(sign.glyph, fontSize = androidx.compose.ui.unit.TextUnit(30f, androidx.compose.ui.unit.TextUnitType.Sp), color = DT.Accent)
        Text(sign.labelTR, style = ABFont.body(13f, androidx.compose.ui.text.font.FontWeight.SemiBold), color = Color.White)
    }
}

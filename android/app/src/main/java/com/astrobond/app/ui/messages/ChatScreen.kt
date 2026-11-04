package com.astrobond.app.ui.messages

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewmodel.compose.viewModel
import com.astrobond.app.R
import com.astrobond.app.data.*
import com.astrobond.app.domain.*
import com.astrobond.app.ui.components.PersonAvatar
import com.astrobond.app.ui.match.MatchDetailScreen
import com.astrobond.app.ui.match.MatchViewModel
import com.astrobond.app.ui.theme.*
import java.text.SimpleDateFormat
import java.util.*

private val Rose = hex("#D9A5B3")
private val RoseSoft = hex("#F0CBD5")

/** Port of ChatView: header with Astro Uyum score, day-grouped bubbles, photo gate banner, composer, question panel. */
@Composable
fun ChatScreen(conversation: ConversationSummary, myUserId: String, onBack: () -> Unit) {
    val vm: ChatViewModel = viewModel(key = conversation.id, factory = object : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST") override fun <T : ViewModel> create(modelClass: Class<T>) = ChatViewModel(conversation) as T
    })
    val ctx = LocalContext.current
    LaunchedEffect(conversation.id) { vm.load(myUserId) }
    var draft by remember { mutableStateOf("") }
    var showQuestions by remember { mutableStateOf(false) }
    var showSynastry by remember { mutableStateOf(false) }
    var menu by remember { mutableStateOf(false) }
    val listState = rememberLazyListState()

    val score = remember(vm.myChart, vm.theirChart, vm.mySun) {
        BondStory.report(vm.mySun, vm.otherAsCard, MatchStores(ctx).prefs.intent, vm.myChart, vm.theirChart).overall
    }
    LaunchedEffect(vm.messages.size) { if (vm.messages.isNotEmpty()) listState.animateScrollToItem(listState.layoutInfo.totalItemsCount) }

    if (showSynastry) {
        val mvm: MatchViewModel = viewModel()
        LaunchedEffect(Unit) { mvm.bootstrap(myUserId); mvm.updateTheirChart(vm.theirChart) }
        MatchDetailScreen(mvm, vm.otherAsCard, onBack = { showSynastry = false })
        return
    }
    BackHandler(onBack = onBack)

    Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding().imePadding()) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Box(Modifier.size(40.dp).clip(CircleShape).background(Color.Black.copy(0.4f)).border(1.dp, Rose.copy(0.5f), CircleShape).clickable(onClick = onBack), contentAlignment = Alignment.Center) { Text("‹", color = Color.White, fontSize = 24.sp) }
            Row(Modifier.weight(1f).clickable { showSynastry = true }, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                PersonAvatar(conversation.otherName, conversation.otherPhotoURL, conversation.otherCartoonAvatarId, conversation.otherSunSign, vm.photoUnlocked, 44.dp)
                Column {
                    Text("${conversation.otherName} ☾", style = ABFont.body(16f, FontWeight.SemiBold), color = Color.White, maxLines = 1)
                    Text("♥ %$score  ${stringResource(R.string.astro_match)}", style = ABFont.body(12f), color = RoseSoft)
                }
            }
        }
        LazyColumn(Modifier.weight(1f).fillMaxWidth(), state = listState, contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            if (!vm.photoUnlocked) item {
                Text(stringResource(R.string.photo_gate, PhotoGate.UNLOCK_AFTER, vm.messages.size), style = ABFont.body(12f), color = ABColor.InkMuted, modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp), textAlign = androidx.compose.ui.text.style.TextAlign.Center)
            }
            val grouped = vm.messages.groupBy { dayKey(it.sentAt) }
            grouped.forEach { (_, msgs) ->
                item { DayChip(dayLabel(msgs.first().sentAt)) }
                items(msgs.size, key = { msgs[it].id }) { Bubble(msgs[it], mine = msgs[it].senderId == myUserId) }
            }
        }
        vm.error?.let { Text(it, style = ABFont.body(12f), color = hex("#C69A9A"), modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)) }
        Row(Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Box {
                Box(Modifier.size(46.dp).clip(CircleShape).background(Color.Black.copy(0.45f)).border(1.dp, Rose.copy(0.55f), CircleShape).clickable { menu = true }, contentAlignment = Alignment.Center) { Text("+", color = Color.White, fontSize = 22.sp) }
                DropdownMenu(menu, { menu = false }) {
                    DropdownMenuItem({ Text(stringResource(R.string.discover_question)) }, { menu = false; showQuestions = true })
                    DropdownMenuItem({ Text(stringResource(R.string.shared_synastry)) }, { menu = false; showSynastry = true })
                }
            }
            TextField(
                draft, { draft = it }, placeholder = { Text(stringResource(R.string.compose_hint), color = Color.White.copy(0.4f)) },
                modifier = Modifier.weight(1f).clip(RoundedCornerShape(26.dp)).border(1.dp, Rose.copy(0.45f), RoundedCornerShape(26.dp)),
                colors = TextFieldDefaults.colors(focusedContainerColor = Color.Black.copy(0.45f), unfocusedContainerColor = Color.Black.copy(0.45f), focusedIndicatorColor = Color.Transparent, unfocusedIndicatorColor = Color.Transparent, focusedTextColor = Color.White, unfocusedTextColor = Color.White, cursorColor = Rose),
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Send), keyboardActions = KeyboardActions(onSend = { vm.send(draft) { draft = "" } }), maxLines = 4,
            )
            val can = draft.isNotBlank() && !vm.isSending
            Box(Modifier.size(46.dp).clip(CircleShape).background(if (can) Rose else Color.White.copy(0.1f)).clickable(enabled = can) { vm.send(draft) { draft = "" } }, contentAlignment = Alignment.Center) {
                Text("↑", color = if (can) Color.Black else Color.White.copy(0.4f), fontSize = 22.sp, fontWeight = FontWeight.Bold)
            }
        }
    }
    if (showQuestions) QuestionSheet(myUserId, onDismiss = { showQuestions = false }, onShare = { q -> vm.send(q) { showQuestions = false } })
}

@Composable
private fun Bubble(m: ChatMessage, mine: Boolean) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = if (mine) Arrangement.End else Arrangement.Start) {
        Column(
            Modifier.widthIn(max = 290.dp).clip(RoundedCornerShape(20.dp))
                .background(if (mine) Rose.copy(0.28f) else Color.Black.copy(0.45f))
                .border(1.dp, if (mine) Rose.copy(0.6f) else Color.White.copy(0.14f), RoundedCornerShape(20.dp)).padding(horizontal = 14.dp, vertical = 9.dp),
            horizontalAlignment = Alignment.End,
        ) {
            Text(m.text, style = ABFont.body(15f), color = Color.White)
            Text(SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(m.sentAt)), style = ABFont.body(10.5f), color = Color.White.copy(0.5f))
        }
    }
}

@Composable
private fun DayChip(label: String) = Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
    Text(label, style = ABFont.body(12f, FontWeight.SemiBold), color = RoseSoft, modifier = Modifier.clip(CircleShape).background(Color.Black.copy(0.35f)).border(1.dp, Rose.copy(0.45f), CircleShape).padding(horizontal = 14.dp, vertical = 6.dp))
}

private fun dayKey(ms: Long) = Calendar.getInstance().apply { timeInMillis = ms }.let { it.get(Calendar.YEAR) * 1000 + it.get(Calendar.DAY_OF_YEAR) }

@Composable
private fun dayLabel(ms: Long): String {
    val today = dayKey(System.currentTimeMillis()); val k = dayKey(ms)
    return when (k) {
        today -> stringResource(R.string.today)
        today - 1 -> stringResource(R.string.yesterday)
        else -> SimpleDateFormat("d MMMM", Locale("tr", "TR")).format(Date(ms))
    }
}

/** Port of QuestionDiscoverSheet: categories → "Sana Özel Soru" card; each shown question spends one of 23 daily rights. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun QuestionSheet(myUserId: String, onDismiss: () -> Unit, onShare: (String) -> Unit) {
    val qctx = LocalContext.current
    val quota = remember { QuestionQuota(qctx) }
    var remaining by remember { mutableIntStateOf(quota.remaining(myUserId)) }
    var category by remember { mutableStateOf<QuestionCategory?>(null) }
    var question by remember { mutableStateOf<String?>(null) }
    var limit by remember { mutableStateOf(false) }
    fun show(c: QuestionCategory, excluding: String?) {
        if (!quota.consume(myUserId)) { limit = true; return }
        remaining = quota.remaining(myUserId); category = c; question = ConversationQuestions.random(c, excluding)
    }
    ModalBottomSheet(onDismiss, containerColor = hex("#15101F")) {
        Column(Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(bottom = 28.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("✦ " + stringResource(if (question == null) R.string.question_title else R.string.question_card_title), style = ABFont.display(20f), color = Color.White, modifier = Modifier.weight(1f))
                Text(stringResource(R.string.question_remaining, remaining), style = ABFont.body(11f), color = ABColor.InkMuted)
            }
            val q = question
            if (q == null) {
                Text(stringResource(R.string.question_intro), style = ABFont.body(13f), color = Color.White.copy(0.65f))
                QuestionCategory.entries.forEach { c ->
                    Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(Color.White.copy(0.06f)).clickable { show(c, null) }.padding(14.dp), horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text(c.emoji, color = DT.Accent, fontSize = 20.sp)
                        Column { Text(c.title, style = ABFont.body(15f, FontWeight.SemiBold), color = Color.White); Text(c.subtitle, style = ABFont.body(12f), color = Color.White.copy(0.6f)) }
                    }
                }
            } else {
                Text(q, style = ABFont.display(20f, FontWeight.Normal), color = Color.White, modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(20.dp)).background(Color.White.copy(0.06f)).padding(20.dp))
                com.astrobond.app.ui.components.GlowButton(stringResource(R.string.question_share), { onShare(q) }, showSparkle = false)
                TextButton({ category?.let { show(it, q) } }, Modifier.align(Alignment.CenterHorizontally)) { Text("⤮  " + stringResource(R.string.question_another), color = Color.White.copy(0.8f)) }
            }
        }
    }
    if (limit) AlertDialog({ limit = false }, confirmButton = { TextButton({ limit = false }) { Text(stringResource(R.string.ok)) } },
        title = { Text(stringResource(R.string.question_limit_title)) }, text = { Text(stringResource(R.string.question_limit_body)) })
}

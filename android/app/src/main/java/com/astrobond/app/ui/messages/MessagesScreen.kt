package com.astrobond.app.ui.messages

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.platform.LocalContext
import com.astrobond.app.R
import com.astrobond.app.data.*
import com.astrobond.app.session.SessionViewModel
import com.astrobond.app.ui.Chrome
import com.astrobond.app.ui.components.PersonAvatar
import com.astrobond.app.ui.theme.*
import java.text.SimpleDateFormat
import java.util.*

/** Port of MessagesInboxView + navigation into ChatScreen. */
@Composable
fun MessagesScreen(session: SessionViewModel?) {
    val ctx = LocalContext.current
    val user = session?.user?.collectAsState()?.value
    val conversations by ConversationsStore.conversations.collectAsState()
    val loading by ConversationsStore.isLoading.collectAsState()
    val error by ConversationsStore.error.collectAsState()
    var open by remember { mutableStateOf<ConversationSummary?>(null) }
    val pending by ChatNavigator.pending.collectAsState()

    LaunchedEffect(user?.id) {
        ConversationsStore.refresh()
        user?.id?.let { ConversationsStore.syncAcceptedMatches(MatchStores(ctx), it) }
    }
    LaunchedEffect(pending) { pending?.let { open = it; ChatNavigator.pending.value = null } }
    DisposableEffect(open) { Chrome.hideTabBar = open != null; onDispose { Chrome.hideTabBar = false } }

    val current = open
    if (current != null && user != null) {
        ChatScreen(current, user.id, onBack = { open = null; LaunchedEffectRefresh.request() })
        return
    }
    Column(Modifier.fillMaxSize().statusBarsPadding().padding(bottom = 110.dp)) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 14.dp), verticalAlignment = Alignment.CenterVertically) {
            Text("✦", color = hex("#C8A56E"), fontSize = 20.sp)
            Spacer(Modifier.width(10.dp))
            Text(stringResource(R.string.brand), style = ABFont.display(17f, FontWeight.Normal), color = Color.White, letterSpacing = 4.sp)
        }
        if (loading && conversations.isEmpty()) Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator(color = ABColor.Lavender) }
        else LazyColumn(Modifier.fillMaxSize(), contentPadding = PaddingValues(horizontal = 20.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            error?.takeIf { it.isNotEmpty() }?.let { item { Text(it, color = hex("#C69A9A"), style = ABFont.body(12.5f)) } }
            if (conversations.isNotEmpty()) {
                item { Label(stringResource(R.string.recent_matches)) }
                item {
                    LazyRow(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                        items(conversations, key = { it.id }) { c ->
                            Column(Modifier.clickable { open = c }, horizontalAlignment = Alignment.CenterHorizontally) {
                                Box { PersonAvatar(c.otherName, c.otherPhotoURL, c.otherCartoonAvatarId, c.otherSunSign, false, 64.dp)
                                    if (c.unreadCount > 0) Box(Modifier.size(12.dp).align(Alignment.TopEnd).clip(CircleShape).background(ABColor.Lavender)) }
                                Text(c.otherName.substringBefore(" "), style = ABFont.body(12f), color = Color.White.copy(0.85f), maxLines = 1)
                            }
                        }
                    }
                }
                item { Label(stringResource(R.string.messages_label)) }
                items(conversations, key = { "r" + it.id }) { c -> InboxRow(c) { open = c } }
            } else if (!loading && error == null) {
                item { Text(stringResource(R.string.inbox_empty), style = ABFont.body(14f), color = Color.White.copy(0.6f), modifier = Modifier.padding(top = 40.dp)) }
            }
        }
    }
}

private object LaunchedEffectRefresh { fun request() { /* inbox refreshes on next composition via ConversationsStore collectors */ } }

@Composable private fun Label(t: String) = Text(t, style = ABFont.label(11f), color = Color.White.copy(0.6f), letterSpacing = 1.5.sp, modifier = Modifier.padding(top = 6.dp))

@Composable
private fun InboxRow(c: ConversationSummary, onClick: () -> Unit) {
    Row(Modifier.fillMaxWidth().crystalPlate(RoundedCornerShape(22.dp)).clickable(onClick = onClick).padding(14.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
        PersonAvatar(c.otherName, c.otherPhotoURL, c.otherCartoonAvatarId, c.otherSunSign, false, 58.dp)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(c.otherName, style = ABFont.body(16f, FontWeight.SemiBold), color = Color.White, maxLines = 1)
            c.otherSunSign?.let { Text("${it.glyph} ${it.labelTR}", style = ABFont.body(11.5f), color = DT.Accent) }
            Text(c.lastMessage, style = ABFont.body(13f), color = Color.White.copy(0.65f), maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text(timeLabel(c.lastMessageAt), style = ABFont.body(11.5f), color = Color.White.copy(0.5f))
            if (c.unreadCount > 0) Box(Modifier.size(10.dp).clip(CircleShape).background(ABColor.Lavender)) else Spacer(Modifier.size(10.dp))
        }
    }
}

private fun timeLabel(ms: Long): String {
    if (ms <= 0) return ""
    val now = Calendar.getInstance(); val d = Calendar.getInstance().apply { timeInMillis = ms }
    val same = now.get(Calendar.YEAR) == d.get(Calendar.YEAR) && now.get(Calendar.DAY_OF_YEAR) == d.get(Calendar.DAY_OF_YEAR)
    return SimpleDateFormat(if (same) "HH:mm" else "d MMM", Locale("tr", "TR")).format(Date(ms))
}

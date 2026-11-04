package com.astrobond.app.ui.messages

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.astrobond.app.data.*
import com.astrobond.app.domain.*
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

/** Port of ChatViewModel (Features/Messages/ChatView.swift). One instance per open conversation. */
class ChatViewModel(val conversation: ConversationSummary) : ViewModel() {
    val messages = mutableStateListOf<ChatMessage>()
    var error by mutableStateOf<String?>(null)
    var isSending by mutableStateOf(false); private set
    var photoUnlocked by mutableStateOf(false); private set
    var myChart by mutableStateOf<NatalChart?>(null); private set
    var theirChart by mutableStateOf<NatalChart?>(null); private set
    var mySun by mutableStateOf<ZodiacSign?>(null); private set
    var myName by mutableStateOf("Sen"); private set
    var myPhotoURL by mutableStateOf<String?>(null); private set
    var myAvatarId by mutableStateOf<String?>(null); private set
    private var observe: Job? = null

    val otherAsCard get() = MatchCard(conversation.otherUserId, conversation.otherName, 0, null, conversation.otherSunSign, null, null, "", conversation.otherPhotoURL, conversation.otherCartoonAvatarId)

    private fun add(m: ChatMessage) { if (messages.none { it.id == m.id }) { messages.add(m); photoUnlocked = PhotoGate.isUnlocked(messages.size) } }

    fun load(myUserId: String) {
        viewModelScope.launch {
            error = null
            try {
                messages.clear(); MessagingRepo.fetchMessages(conversation.id).forEach(::add)
                MessagingRepo.markRead(conversation.id, myUserId)
                startObserving()
            } catch (e: Exception) { error = e.message }
            runCatching { ProfileRepo.fetchSnapshot(myUserId) }.getOrNull()?.let {
                mySun = it.sunSign; if (it.displayName.isNotBlank()) myName = it.displayName; myPhotoURL = it.photoURL; myAvatarId = it.cartoonAvatarId
            }
            myChart = runCatching { ChartRepo.ensureOwnChart(myUserId) }.getOrNull()
            theirChart = ChartRepo.fetch(conversation.otherUserId)
            myChart?.let { mySun = it.sunSign }
        }
    }

    fun send(text: String, onSuccess: () -> Unit = {}) {
        val t = text.trim()
        if (t.isEmpty() || isSending) return
        isSending = true; error = null
        viewModelScope.launch {
            try { add(MessagingRepo.sendMessage(conversation.id, t)); onSuccess() } catch (e: Exception) { error = e.message }
            isSending = false
        }
    }

    private fun startObserving() {
        observe?.cancel()
        observe = viewModelScope.launch { MessagingRepo.observeMessages(conversation.id).collect { add(it) } }
    }

    override fun onCleared() { observe?.cancel() }
}

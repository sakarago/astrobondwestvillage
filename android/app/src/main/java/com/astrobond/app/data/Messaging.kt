package com.astrobond.app.data

import android.content.Context
import com.astrobond.app.domain.ZodiacSign
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Order
import io.github.jan.supabase.realtime.PostgresAction
import io.github.jan.supabase.realtime.channel
import io.github.jan.supabase.realtime.postgresChangeFlow
import io.github.jan.supabase.realtime.realtime
import kotlinx.coroutines.flow.*
import kotlinx.serialization.json.*
import java.time.LocalDate
import java.time.OffsetDateTime

data class ConversationSummary(
    val id: String, val otherUserId: String, val otherName: String, val otherPhotoURL: String?, val otherCartoonAvatarId: String?,
    val otherSunSign: ZodiacSign?, val lastMessage: String, val lastMessageAt: Long, val unreadCount: Int,
)

data class ChatMessage(val id: String, val conversationId: String, val senderId: String, val text: String, val sentAt: Long, val isRead: Boolean)

class MessagingException(message: String) : Exception(message) {
    companion object {
        fun fromServer(raw: String?): MessagingException {
            val m = (raw ?: "").lowercase()
            return MessagingException(when {
                "daily_message_limit" in m -> "Günlük mesaj hakkın doldu (10)."
                "empty_message" in m -> "Boş mesaj gönderilemez."
                "message_too_long" in m -> "Mesaj en fazla 500 karakter olabilir."
                "messaging_not_allowed" in m -> "Bu kişiyle henüz mesajlaşamazsın."
                else -> raw ?: "Bağlantı hatası"
            })
        }
    }
}

object PhotoGate {
    const val UNLOCK_AFTER = 10
    fun isUnlocked(count: Int) = count >= UNLOCK_AFTER
}

const val FIRST_MESSAGE_HINT = "Astro Bond açıldı. İlk mesajı sen at!"

private fun parseTime(s: String?): Long = s?.let { runCatching { OffsetDateTime.parse(it).toInstant().toEpochMilli() }.getOrNull() } ?: 0L

private fun JsonObject.toConversation(): ConversationSummary {
    val preview = (str("last_message_text") ?: "").trim()
    return ConversationSummary(
        id = str("id")!!, otherUserId = str("other_user_id")!!.lowercase(), otherName = str("other_display_name") ?: "",
        otherPhotoURL = str("other_profile_photo_url"), otherCartoonAvatarId = str("other_cartoon_avatar_id"),
        otherSunSign = ZodiacSign.fromEnglishName(str("other_sun_sign")),
        lastMessage = preview.ifEmpty { FIRST_MESSAGE_HINT }, lastMessageAt = parseTime(str("last_message_at")), unreadCount = int("unread_count") ?: 0,
    )
}

private fun JsonObject.toMessage() = ChatMessage(str("id")!!, str("conversation_id")!!, str("sender_id")!!.lowercase(), str("body") ?: "", parseTime(str("sent_at")), bool("is_read") ?: false)

/** Port of MessagingService.swift. Same RPCs / table. */
object MessagingRepo {
    suspend fun listConversations(): List<ConversationSummary> = try {
        Supabase.client.postgrest.rpc("list_conversations").decodeList<JsonObject>().map { it.toConversation() }
    } catch (e: Exception) { throw MessagingException.fromServer(e.message) }

    suspend fun getOrCreateConversation(otherUserId: String): ConversationSummary = try {
        Supabase.client.postgrest.rpc("get_or_create_conversation", buildJsonObject { put("p_other_user_id", otherUserId) })
            .decodeList<JsonObject>().firstOrNull()?.toConversation() ?: throw MessagingException("Sohbet açılamadı.")
    } catch (e: MessagingException) { throw e } catch (e: Exception) { throw MessagingException.fromServer(e.message) }

    suspend fun fetchMessages(conversationId: String): List<ChatMessage> = try {
        Supabase.client.from("messages").select { filter { eq("conversation_id", conversationId) }; order("sent_at", Order.ASCENDING) }
            .decodeList<JsonObject>().map { it.toMessage() }
    } catch (e: Exception) { throw MessagingException.fromServer(e.message) }

    suspend fun sendMessage(conversationId: String, text: String): ChatMessage {
        val t = text.trim()
        if (t.isEmpty()) throw MessagingException("Boş mesaj gönderilemez.")
        if (t.length > 500) throw MessagingException("Mesaj en fazla 500 karakter olabilir.")
        return try {
            Supabase.client.postgrest.rpc("send_message", buildJsonObject { put("p_conversation_id", conversationId); put("p_text", t) })
                .decodeList<JsonObject>().firstOrNull()?.toMessage() ?: throw MessagingException("Mesaj gönderilemedi.")
        } catch (e: MessagingException) { throw e } catch (e: Exception) { throw MessagingException.fromServer(e.message) }
    }

    suspend fun markRead(conversationId: String, myUserId: String) {
        runCatching {
            Supabase.client.from("messages").update(buildJsonObject { put("is_read", true) }) {
                filter { eq("conversation_id", conversationId); neq("sender_id", myUserId); eq("is_read", false) }
            }
        }
    }

    /** Realtime INSERTs on `messages` for one conversation. Cancel the collector to unsubscribe. */
    fun observeMessages(conversationId: String): Flow<ChatMessage> = flow {
        val channel = Supabase.client.channel("messages:$conversationId")
        val inserts = channel.postgresChangeFlow<PostgresAction.Insert>(schema = "public") {
            table = "messages"
            filter("conversation_id", io.github.jan.supabase.postgrest.query.filter.FilterOperator.EQ, conversationId)
        }
        try {
            channel.subscribe(blockUntilSubscribed = true)
            inserts.collect { emit(it.record.toMessage()) }
        } finally {
            runCatching { Supabase.client.realtime.removeChannel(channel) }
        }
    }.catch { /* realtime unavailable: UI still works via send + refresh */ }
}

/** Shared inbox state (port of ConversationsStore). */
object ConversationsStore {
    private val _conversations = MutableStateFlow<List<ConversationSummary>>(emptyList())
    val conversations: StateFlow<List<ConversationSummary>> = _conversations.asStateFlow()
    val isLoading = MutableStateFlow(false)
    val error = MutableStateFlow<String?>(null)

    suspend fun refresh() {
        isLoading.value = true; error.value = null
        try { _conversations.value = MessagingRepo.listConversations().sortedByDescending { it.lastMessageAt } } catch (e: Exception) { error.value = e.message }
        isLoading.value = false
    }

    fun upsert(c: ConversationSummary) {
        val list = _conversations.value.toMutableList()
        val i = list.indexOfFirst { it.id == c.id || it.otherUserId == c.otherUserId }
        if (i >= 0) list[i] = c else list.add(0, c)
        _conversations.value = list
    }

    suspend fun ensureConversation(otherUserId: String) {
        val id = otherUserId.lowercase()
        if (_conversations.value.any { it.otherUserId == id }) return
        try { upsert(MessagingRepo.getOrCreateConversation(id)) } catch (e: Exception) { error.value = e.message }
    }

    suspend fun syncAcceptedMatches(stores: MatchStores, userId: String) { stores.acceptedIds(userId).forEach { ensureConversation(it) } }
}

/** One-shot request to open a chat from another tab (Match → Messages). */
object ChatNavigator { val pending = MutableStateFlow<ConversationSummary?>(null) }

/** Port of DailyQuestionQuotaStore: 23 question views per day. */
class QuestionQuota(context: Context) {
    private val sp = context.getSharedPreferences("astrobond.questions", Context.MODE_PRIVATE)
    private fun key(uid: String) = "q.$uid.${LocalDate.now()}"
    fun remaining(uid: String) = maxOf(0, DAILY_LIMIT - sp.getInt(key(uid), 0))
    fun consume(uid: String): Boolean { if (remaining(uid) <= 0) return false; sp.edit().putInt(key(uid), sp.getInt(key(uid), 0) + 1).apply(); return true }
    companion object { const val DAILY_LIMIT = 23 }
}

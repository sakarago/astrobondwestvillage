package com.astrobond.app.data

import android.content.Context
import com.astrobond.app.domain.*
import io.github.jan.supabase.postgrest.postgrest
import kotlinx.serialization.json.*
import java.time.LocalDate
import java.time.ZoneId

/** Port of MatchService.swift (RPCs get_daily_candidates / reveal_match). */
object MatchRepo {
    class DailyLimit : Exception("Bugünkü eşleşme hakkın doldu.")
    class EmptyPool : Exception("Şu an gösterilecek aday yok.")

    suspend fun fetchCandidates(limit: Int = 20): List<MatchCard> = try {
        Supabase.client.postgrest.rpc("get_daily_candidates", buildJsonObject { put("p_limit", limit) })
            .decodeList<JsonObject>()
            .filter { it.bool("is_demo") != true }
            .filter { !it.str("display_name").isNullOrBlank() }
            .map {
                MatchCard(
                    id = it.str("id")!!.lowercase(), displayName = it.str("display_name")!!, age = it.int("age") ?: 0, city = it.str("city"),
                    sunSign = ZodiacSign.fromEnglishName(it.str("sun_sign")), moonSign = ZodiacSign.fromEnglishName(it.str("moon_sign")),
                    risingSign = ZodiacSign.fromEnglishName(it.str("rising_sign")), bio = it.str("bio") ?: "",
                    photoURL = it.str("profile_photo_url"), cartoonAvatarId = it.str("cartoon_avatar_id"),
                )
            }
    } catch (e: Exception) { throw AppException(e.message ?: "Bağlantı hatası") }

    suspend fun reveal(userId: String) {
        try {
            Supabase.client.postgrest.rpc("reveal_match", buildJsonObject { put("p_target_user_id", userId) })
        } catch (e: Exception) {
            if (e.message?.contains("limit_reached") == true) throw DailyLimit()
            throw AppException(e.message ?: "Bağlantı hatası")
        }
    }
}

/** Local match memory (port of MatchDecisionsStore, MatchPrefsStore, DailyRevealQuotaStore). Backed by SharedPreferences. */
class MatchStores(context: Context) {
    private val sp = context.getSharedPreferences("astrobond.match", Context.MODE_PRIVATE)

    data class Record(
        val id: String, val displayName: String, val age: Int, val city: String?, val sunSignRaw: String?,
        val photoURL: String?, val cartoonAvatarId: String?, val accepted: Boolean, val decidedAt: Long,
    ) { val sunSign get() = ZodiacSign.fromEnglishName(sunSignRaw) }

    private fun ids(key: String) = sp.getStringSet(key, emptySet()).orEmpty().toSet()
    fun acceptedIds(uid: String) = ids("accepted.$uid")
    fun rejectedIds(uid: String) = ids("rejected.$uid")

    fun history(uid: String): List<Record> {
        val raw = sp.getString("history.$uid", null) ?: return emptyList()
        return runCatching {
            Json.parseToJsonElement(raw).jsonArray.map {
                val o = it.jsonObject
                Record(o.str("id")!!, o.str("displayName") ?: "", o.int("age") ?: 0, o.str("city"), o.str("sunSignRaw"),
                    o.str("photoURL"), o.str("cartoonAvatarId"), o.bool("accepted") ?: false, o.str("decidedAt")?.toLongOrNull() ?: 0L)
            }.sortedByDescending { it.decidedAt }
        }.getOrDefault(emptyList())
    }

    private fun startOfToday() = LocalDate.now().atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli()
    fun todayHistory(uid: String) = history(uid).filter { it.decidedAt >= startOfToday() }

    fun accept(uid: String, card: MatchCard) {
        sp.edit().putStringSet("accepted.$uid", acceptedIds(uid) + card.id.lowercase())
            .putStringSet("rejected.$uid", rejectedIds(uid) - card.id.lowercase()).apply()
        append(uid, card, true)
    }

    fun reject(uid: String, card: MatchCard) {
        sp.edit().putStringSet("rejected.$uid", rejectedIds(uid) + card.id.lowercase()).apply()
        append(uid, card, false)
    }

    private fun append(uid: String, card: MatchCard, accepted: Boolean) {
        val items = history(uid).filter { it.id != card.id.lowercase() }.toMutableList()
        items.add(0, Record(card.id.lowercase(), card.displayName, card.age, card.city, card.sunSign?.englishName, card.photoURL, card.cartoonAvatarId, accepted, System.currentTimeMillis()))
        val arr = buildJsonArray {
            items.take(40).forEach { r ->
                addJsonObject {
                    put("id", r.id); put("displayName", r.displayName); put("age", r.age); r.city?.let { put("city", it) }
                    r.sunSignRaw?.let { put("sunSignRaw", it) }; r.photoURL?.let { put("photoURL", it) }
                    r.cartoonAvatarId?.let { put("cartoonAvatarId", it) }; put("accepted", r.accepted); put("decidedAt", r.decidedAt.toString())
                }
            }
        }
        sp.edit().putString("history.$uid", arr.toString()).apply()
    }

    // --- prefs ---
    var prefs: MatchPrefs
        get() = MatchPrefs(
            MatchIntent.fromWire(sp.getString("p.intent", null)),
            (sp.getString("p.genders", null)?.split(",")?.filter { it.isNotEmpty() }?.map(Gender::fromStableName)) ?: listOf(Gender.WOMAN, Gender.MAN),
            sp.getBoolean("p.ageOn", false), sp.getInt("p.ageMin", 22), sp.getInt("p.ageMax", 45),
            sp.getBoolean("p.locOn", false), sp.getString("p.city", "İstanbul") ?: "İstanbul", sp.getFloat("p.km", 100f).toDouble(),
        )
        set(v) { sp.edit().putString("p.intent", v.intent.wire).putString("p.genders", v.preferredGenders.joinToString(",") { it.stableName })
            .putBoolean("p.ageOn", v.ageEnabled).putInt("p.ageMin", v.ageMin).putInt("p.ageMax", v.ageMax)
            .putBoolean("p.locOn", v.locationEnabled).putString("p.city", v.searchCity).putFloat("p.km", v.maxDistanceKm.toFloat()).apply() }

    // --- daily reveal quota: 3 per day, enforced client-side AND by the server (limit_reached). ---
    // iOS has a TEST flag `isUnlimited = true`; it is deliberately NOT ported.
    private fun quotaKey(uid: String) = "reveal.$uid.${LocalDate.now()}"
    fun used(uid: String) = sp.getInt(quotaKey(uid), 0)
    fun remaining(uid: String) = maxOf(0, DAILY_LIMIT - used(uid))
    fun recordReveal(uid: String) { sp.edit().putInt(quotaKey(uid), used(uid) + 1).apply() }

    companion object { const val DAILY_LIMIT = 3 }
}

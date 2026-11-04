package com.astrobond.app.ui.match

import android.app.Application
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.astrobond.app.data.*
import com.astrobond.app.domain.*
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/** Port of MatchViewModel (Features/Match/MatchHomeView.swift). */
class MatchViewModel(app: Application) : AndroidViewModel(app) {
    enum class Phase { IDLE, SPINNING, REVEALED }

    private val stores = MatchStores(app)
    var phase by mutableStateOf(Phase.IDLE); private set
    var pool by mutableStateOf<List<MatchCard>>(emptyList()); private set
    var active by mutableStateOf<MatchCard?>(null); private set
    var wheelRotation by mutableStateOf(0f); private set
    var isLoading by mutableStateOf(false); private set
    var message by mutableStateOf<String?>(null)
    var remaining by mutableStateOf(MatchStores.DAILY_LIMIT); private set
    var todayDecisions by mutableStateOf<List<MatchStores.Record>>(emptyList()); private set
    var prefs by mutableStateOf(stores.prefs); private set
    var detailCard by mutableStateOf<MatchCard?>(null)
    var mySun by mutableStateOf<ZodiacSign?>(null); private set
    var myMoon by mutableStateOf<ZodiacSign?>(null); private set
    var myRising by mutableStateOf<ZodiacSign?>(null); private set
    var myName by mutableStateOf("Sen"); private set
    var myPhotoURL by mutableStateOf<String?>(null); private set
    var myAvatarId by mutableStateOf<String?>(null); private set
    var myChart by mutableStateOf<NatalChart?>(null); private set
    var theirChart by mutableStateOf<NatalChart?>(null); private set
    var showLimit by mutableStateOf(false)
    var showNoCandidates by mutableStateOf(false)

    private var uid: String? = null
    val canMatch get() = remaining > 0
    val quotaLabel get() = "Bugün ${MatchStores.DAILY_LIMIT - remaining}/${MatchStores.DAILY_LIMIT} eşleşme"
    val todaysAccepted get() = todayDecisions.filter { it.accepted }

    fun bootstrap(userId: String) {
        if (uid == userId) return
        uid = userId
        prefs = stores.prefs
        refreshLocal()
        viewModelScope.launch {
            runCatching { ProfileRepo.fetchSnapshot(userId) }.getOrNull()?.let {
                mySun = it.sunSign; myMoon = it.moonSign; myRising = it.risingSign
                if (it.displayName.isNotBlank()) myName = it.displayName
                myPhotoURL = it.photoURL; myAvatarId = it.cartoonAvatarId
            }
            myChart = runCatching { ChartRepo.ensureOwnChart(userId) }.getOrNull()
            myChart?.let { mySun = it.sunSign; myMoon = it.moonSign; myRising = it.risingSign }
            load()
        }
    }

    private fun refreshLocal() {
        val u = uid ?: return
        remaining = stores.remaining(u); todayDecisions = stores.todayHistory(u)
    }

    suspend fun load() {
        isLoading = true; message = null
        try {
            var cards = filters(MatchRepo.fetchCandidates())
            uid?.let { u ->
                val rej = stores.rejectedIds(u); val acc = stores.acceptedIds(u)
                cards = cards.filter { it.id !in rej && it.id !in acc }
            }
            pool = cards
        } catch (e: Exception) { message = e.message }
        isLoading = false
    }

    fun reload() { viewModelScope.launch { load() } }

    fun persistPrefs(next: MatchPrefs) { prefs = next; stores.prefs = next }

    /** Starts the wheel. Returns false when a precondition (limit, empty pool) blocks it. */
    fun spin(): Boolean {
        if (phase != Phase.IDLE) return false
        val u = uid ?: return false
        if (stores.remaining(u) <= 0) { showLimit = true; return false }
        if (pool.isEmpty()) { showNoCandidates = true; return false }
        message = null; phase = Phase.SPINNING
        wheelRotation += 360f * 2
        viewModelScope.launch {
            val net = async { revealNext() }
            delay(SPIN_MS.toLong())
            val card = net.await()
            if (card != null) {
                active = card
                theirChart = ChartRepo.fetch(card.id)
                phase = Phase.REVEALED
            } else phase = Phase.IDLE
        }
        return true
    }

    private suspend fun revealNext(): MatchCard? {
        val u = uid ?: return null
        val next = pool.firstOrNull() ?: run { message = EmptyMsg; return null }
        return try {
            MatchRepo.reveal(next.id)
            stores.recordReveal(u); refreshLocal()
            pool = pool.filter { it.id != next.id }
            next
        } catch (e: MatchRepo.DailyLimit) { showLimit = true; null } catch (e: Exception) { message = e.message; null }
    }

    fun reject() { val a = active ?: return; uid?.let { stores.reject(it, a) }; dismissReveal(); refreshLocal() }

    fun acceptReveal() { val a = active ?: return; uid?.let { stores.accept(it, a) }; dismissReveal(); refreshLocal() }

    fun accept(card: MatchCard) { uid?.let { stores.accept(it, card) }; refreshLocal() }

    fun dismissReveal() { active = null; theirChart = null; phase = Phase.IDLE; message = null }

    private fun filters(cards: List<MatchCard>) = cards.filter { c ->
        val p = prefs
        if (p.ageEnabled && c.age > 0 && (c.age < p.ageMin || c.age > p.ageMax)) return@filter false
        if (p.locationEnabled && !c.city.isNullOrEmpty()) {
            val n = p.searchCity.trim()
            if (n.isNotEmpty() && !c.city.contains(n, true) && !n.contains(c.city, true)) return@filter false
        }
        true
    }

    companion object { const val SPIN_MS = 6000; const val EmptyMsg = "Şu an gösterilecek aday yok." }
}

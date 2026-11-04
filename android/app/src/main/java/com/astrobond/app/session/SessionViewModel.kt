package com.astrobond.app.session

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.astrobond.app.data.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

enum class Phase { LOADING, WELCOME, ONBOARDING, MAIN }

/** Port of App/SessionStore.swift. */
class SessionViewModel : ViewModel() {
    private val _phase = MutableStateFlow(Phase.LOADING)
    val phase: StateFlow<Phase> = _phase.asStateFlow()
    private val _user = MutableStateFlow<AppUser?>(null)
    val user: StateFlow<AppUser?> = _user.asStateFlow()
    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    init { bootstrap() }

    fun clearError() { _error.value = null }

    fun bootstrap() = viewModelScope.launch {
        _phase.value = Phase.LOADING
        val u = AuthRepo.currentUser()
        if (u != null) { _user.value = u; route(u.id) } else { _user.value = null; _phase.value = Phase.WELCOME }
    }

    fun signIn(email: String, password: String, onResult: (Boolean) -> Unit = {}) = viewModelScope.launch {
        _error.value = null
        try {
            val u = AuthRepo.signIn(email, password); _user.value = u; route(u.id); onResult(true)
        } catch (e: Exception) { _error.value = e.message; onResult(false) }
    }

    fun signUp(email: String, password: String, onResult: (Boolean) -> Unit = {}) = viewModelScope.launch {
        _error.value = null
        try {
            _user.value = AuthRepo.signUp(email, password); _phase.value = Phase.ONBOARDING; onResult(true)
        } catch (e: Exception) { _error.value = e.message; onResult(false) }
    }

    fun markOnboardingComplete() { _phase.value = Phase.MAIN }

    fun signOut() = viewModelScope.launch {
        _error.value = null
        try { AuthRepo.signOut() } catch (e: Exception) { _error.value = e.message }
        _user.value = null; _phase.value = Phase.WELCOME
    }

    fun freezeAccount() = viewModelScope.launch {
        val id = _user.value?.id ?: return@launch
        _error.value = null
        try { ProfileRepo.setFrozen(id, true); AuthRepo.signOut(); _user.value = null; _phase.value = Phase.WELCOME }
        catch (e: Exception) { _error.value = e.message }
    }

    fun deleteAccount() = viewModelScope.launch {
        _error.value = null
        try {
            AuthRepo.deleteAccount(); runCatching { AuthRepo.signOut() }
            _user.value = null; _phase.value = Phase.WELCOME
        } catch (e: Exception) { _error.value = e.message }
    }

    private suspend fun route(userId: String) {
        runCatching { ProfileRepo.setFrozen(userId, false) }
        _phase.value = try {
            val snap = ProfileRepo.fetchSnapshot(userId)
            if (snap != null && snap.hasBirthData) { runCatching { ChartRepo.ensureOwnChart(userId) }; Phase.MAIN } else Phase.ONBOARDING
        } catch (e: Exception) { Phase.ONBOARDING }
    }
}

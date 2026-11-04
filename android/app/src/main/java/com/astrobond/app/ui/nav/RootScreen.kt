package com.astrobond.app.ui.nav

import androidx.compose.animation.Crossfade
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.foundation.layout.Box
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import com.astrobond.app.session.Phase
import com.astrobond.app.session.SessionViewModel
import com.astrobond.app.ui.onboarding.OnboardingFlow
import com.astrobond.app.ui.theme.ABColor
import com.astrobond.app.ui.theme.CosmicBackdrop
import com.astrobond.app.ui.welcome.WelcomeFlow

/** Port of App/RootView.swift: loading → welcome → onboarding → main. */
@Composable
fun RootScreen(session: SessionViewModel = viewModel()) {
    val phase by session.phase.collectAsState()
    Crossfade(phase, label = "phase") { p ->
        when (p) {
            Phase.LOADING -> CosmicBackdrop { Box(Modifier.matchParentSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator(color = ABColor.LavenderSoft) } }
            Phase.WELCOME -> WelcomeFlow(session)
            Phase.ONBOARDING -> OnboardingFlow(session)
            Phase.MAIN -> MainShell(session)
        }
    }
}

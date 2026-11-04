package com.astrobond.app.ui.nav

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.testTag
import com.astrobond.app.ui.screens.DiscoverScreen
import com.astrobond.app.ui.screens.MatchScreen
import com.astrobond.app.ui.screens.MessagesScreen
import com.astrobond.app.ui.screens.ProfileScreen
import com.astrobond.app.ui.theme.ABColor
import com.astrobond.app.ui.theme.CosmicBackdrop
import com.astrobond.app.ui.theme.crystalCapsule

/**
 * Mirrors iOS `MainTabView`: shared cosmic backdrop, tab bodies composed on demand, a floating crystal tab bar, and the
 * Eşleşme tab selected by default.
 */
@Composable
fun MainShell(session: com.astrobond.app.session.SessionViewModel? = null) {
    var selected by rememberSaveable { mutableIntStateOf(AppTab.Match.ordinal) }

    CosmicBackdrop {
        Box(Modifier.fillMaxSize()) {
            // iOS keeps all four bodies mounted; here only the selected tab composes and
            // per-screen state lives in ViewModels / rememberSaveable.
            TabBody(AppTab.entries[selected])
            WestVillageTabBar(
                selected = selected,
                onSelect = { selected = it },
                modifier = Modifier.align(Alignment.BottomCenter),
            )
        }
    }
}

@Composable
private fun TabBody(tab: AppTab) = when (tab) {
    AppTab.Discover -> DiscoverScreen()
    AppTab.Match -> MatchScreen()
    AppTab.Messages -> MessagesScreen()
    AppTab.Profile -> ProfileScreen()
}

@Composable
fun WestVillageTabBar(selected: Int, onSelect: (Int) -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier
            .navigationBarsPadding()
            .padding(horizontal = 28.dp)
            .padding(bottom = 14.dp)
            .crystalCapsule()
            .padding(6.dp),
    ) {
        AppTab.entries.forEach { tab ->
            val on = selected == tab.ordinal
            val label = stringResource(tab.label)
            Box(
                Modifier
                    .weight(1f)
                    .height(46.dp)
                    .clip(CircleShape)
                    .then(
                        if (on) Modifier
                            .background(Color.White.copy(alpha = 0.10f))
                            .border(1.dp, ABColor.LavenderSoft.copy(alpha = 0.45f), CircleShape)
                        else Modifier,
                    )
                    .clickable { onSelect(tab.ordinal) }
                    .testTag("tab_${tab.route}"),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = tab.icon,
                    contentDescription = label,
                    tint = Color.White.copy(alpha = if (on) 1f else 0.55f),
                )
            }
        }
    }
}

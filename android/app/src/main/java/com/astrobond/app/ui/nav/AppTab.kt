package com.astrobond.app.ui.nav

import androidx.annotation.StringRes
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Message
import androidx.compose.material.icons.filled.Person
import androidx.compose.ui.graphics.vector.ImageVector
import com.astrobond.app.R

/** Order and icons mirror iOS `WestVillageTabBar` (sparkles, heart, message, person). */
enum class AppTab(val route: String, @StringRes val label: Int, val icon: ImageVector) {
    Discover("discover", R.string.tab_discover, Icons.Filled.AutoAwesome),
    Match("match", R.string.tab_match, Icons.Filled.Favorite),
    Messages("messages", R.string.tab_messages, Icons.Filled.Message),
    Profile("profile", R.string.tab_profile, Icons.Filled.Person),
}

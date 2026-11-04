package com.astrobond.app.ui.screens

import androidx.annotation.StringRes
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.astrobond.app.R
import com.astrobond.app.ui.theme.LocalTh

@Composable
private fun TabPlaceholder(@StringRes title: Int) {
    val th = LocalTh.current
    Column(
        Modifier.fillMaxSize().padding(horizontal = 20.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(stringResource(title), style = MaterialTheme.typography.displayLarge, color = th.primary)
        Text(
            stringResource(R.string.soon_body),
            style = MaterialTheme.typography.bodyMedium,
            color = th.secondary,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(top = 8.dp),
        )
    }
}

// Replaced one by one as the iOS features are ported (steps 4–7 in AndroidHandoff.md).
@Composable fun DiscoverScreen() = TabPlaceholder(R.string.tab_discover)
@Composable fun MessagesScreen() = TabPlaceholder(R.string.tab_messages)
@Composable fun ProfileScreen() = TabPlaceholder(R.string.tab_profile)

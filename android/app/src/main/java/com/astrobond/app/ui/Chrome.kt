package com.astrobond.app.ui

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

/** Shared chrome state (iOS `hideTabBar` environment): full-screen pages such as an open chat hide the floating tab bar. */
object Chrome { var hideTabBar by mutableStateOf(false) }

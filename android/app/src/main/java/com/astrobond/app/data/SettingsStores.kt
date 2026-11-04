package com.astrobond.app.data

import android.content.Context

/** Port of NotificationPrefsStore / AppLanguageStore. */
class NotificationPrefs(context: Context) {
    private val sp = context.getSharedPreferences("astrobond.settings", Context.MODE_PRIVATE)
    var dailyInsight: Boolean get() = sp.getBoolean("n.insight", true); set(v) { sp.edit().putBoolean("n.insight", v).apply() }
    var newMatches: Boolean get() = sp.getBoolean("n.match", true); set(v) { sp.edit().putBoolean("n.match", v).apply() }
    var messages: Boolean get() = sp.getBoolean("n.msg", true); set(v) { sp.edit().putBoolean("n.msg", v).apply() }
    var transits: Boolean get() = sp.getBoolean("n.transit", true); set(v) { sp.edit().putBoolean("n.transit", v).apply() }
    var privateAccount: Boolean get() = sp.getBoolean("n.private", false); set(v) { sp.edit().putBoolean("n.private", v).apply() }
}

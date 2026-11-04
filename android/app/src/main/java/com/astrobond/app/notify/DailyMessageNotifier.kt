package com.astrobond.app.notify

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import com.astrobond.app.MainActivity
import com.astrobond.app.R
import java.util.Calendar

/** Port of `DailyMessageNotifier`: a gentle daily "your card is waiting" notification at 09:00 local time. */
object DailyMessageNotifier {
    private const val CHANNEL = "daily.message"

    fun scheduleDaily(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 9); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DAY_OF_YEAR, 1)
        }
        am.setInexactRepeating(AlarmManager.RTC, cal.timeInMillis, AlarmManager.INTERVAL_DAY, pending(context))
    }

    fun cancel(context: Context) {
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(pending(context))
    }

    private fun pending(context: Context) = PendingIntent.getBroadcast(
        context, 0, Intent(context, DailyReceiver::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    internal fun post(context: Context) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.createNotificationChannel(NotificationChannel(CHANNEL, context.getString(R.string.notif_channel), NotificationManager.IMPORTANCE_DEFAULT))
        val open = PendingIntent.getActivity(context, 1, Intent(context, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        val n = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_launcher_foreground).setContentTitle("AstroBond")
            .setContentText(context.getString(R.string.daily_notification_body))
            .setStyle(NotificationCompat.BigTextStyle().bigText(context.getString(R.string.daily_notification_body)))
            .setContentIntent(open).setAutoCancel(true).build()
        runCatching { nm.notify(1, n) } // SecurityException when POST_NOTIFICATIONS is not granted
    }
}

class DailyReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) = DailyMessageNotifier.post(context)
}

/** Asks for POST_NOTIFICATIONS (Android 13+) and runs [then] either way; returns a trigger to call. */
@androidx.compose.runtime.Composable
fun rememberNotificationPermissionRequest(then: () -> Unit): () -> Unit {
    val ctx = androidx.compose.ui.platform.LocalContext.current
    val launcher = androidx.activity.compose.rememberLauncherForActivityResult(androidx.activity.result.contract.ActivityResultContracts.RequestPermission()) { then() }
    return {
        if (android.os.Build.VERSION.SDK_INT >= 33 &&
            androidx.core.content.ContextCompat.checkSelfPermission(ctx, android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED
        ) launcher.launch(android.Manifest.permission.POST_NOTIFICATIONS) else then()
    }
}

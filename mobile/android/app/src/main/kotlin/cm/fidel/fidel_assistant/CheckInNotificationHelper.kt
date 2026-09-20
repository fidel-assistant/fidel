package cm.fidel.fidel_assistant

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * Notif check-in avec 4 icônes vectorielles (RemoteViews).
 * Les actions standard Android sont limitées à 3 boutons texte — d’où le layout custom.
 */
object CheckInNotificationHelper {
    const val CHANNEL_ID = "fidel_check_in_daily"
    const val NOTIFICATION_ID = 91001500
    const val DEBUG_NOTIFICATION_ID = 91001501
    const val ACTION_TRES_MAL = "check_in_tres_mal"
    const val ACTION_PAS_TOP = "check_in_pas_top"
    const val ACTION_CA_VA = "check_in_ca_va"
    const val ACTION_SUPER = "check_in_super"
    const val EXTRA_ACTION_ID = "check_in_action_id"
    const val EXTRA_NOTIFICATION_ID = "check_in_notification_id"
    const val PREFS = "fidel_check_in_notif"
    const val KEY_PENDING_ACTION = "pending_action"
    const val ALARM_REQUEST_CODE = 91001510

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val existing = nm.getNotificationChannel(CHANNEL_ID)
        if (existing != null) return
        nm.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                context.getString(R.string.check_in_channel_name),
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = context.getString(R.string.check_in_channel_desc)
                enableVibration(true)
            },
        )
    }

    fun show(
        context: Context,
        title: String,
        body: String,
        notificationId: Int = DEBUG_NOTIFICATION_ID,
    ) {
        ensureChannel(context)

        // Couleurs fixes : les attrs theme (textColorPrimary) sortent souvent
        // sombres dans RemoteViews → texte illisible sur shade sombre.
        val titleColor = 0xFFFFFFFF.toInt()
        val bodyColor = 0xB3FFFFFF.toInt()

        val collapsed = RemoteViews(context.packageName, R.layout.notification_check_in_collapsed)
        collapsed.setTextViewText(R.id.check_in_title_collapsed, title)
        collapsed.setTextColor(R.id.check_in_title_collapsed, titleColor)

        val expanded = RemoteViews(context.packageName, R.layout.notification_check_in)
        expanded.setTextViewText(R.id.check_in_title, title)
        expanded.setTextViewText(R.id.check_in_body, body)
        expanded.setTextColor(R.id.check_in_title, titleColor)
        expanded.setTextColor(R.id.check_in_body, bodyColor)
        bindMoodClicks(context, expanded, notificationId)

        val contentIntent = PendingIntent.getActivity(
            context,
            notificationId,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("check_in_open", true)
            },
            pendingFlags(),
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_checkin)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(collapsed)
            .setCustomBigContentView(expanded)
            .setContentIntent(contentIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .build()

        NotificationManagerCompat.from(context).notify(notificationId, notification)
    }

    fun cancel(context: Context, notificationId: Int? = null) {
        val nm = NotificationManagerCompat.from(context)
        if (notificationId != null) {
            nm.cancel(notificationId)
        } else {
            nm.cancel(NOTIFICATION_ID)
            nm.cancel(DEBUG_NOTIFICATION_ID)
        }
    }

    fun scheduleDaily(
        context: Context,
        title: String,
        body: String,
        hour: Int,
        minute: Int,
        skipIfSameDayPast: Boolean,
    ) {
        ensureChannel(context)
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val triggerAt = nextTriggerMillis(hour, minute, skipIfSameDayPast)
        val intent = Intent(context, CheckInAlarmReceiver::class.java).apply {
            putExtra("title", title)
            putExtra("body", body)
        }
        val pi = PendingIntent.getBroadcast(
            context,
            ALARM_REQUEST_CODE,
            intent,
            pendingFlags() or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            } else {
                am.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            }
        } catch (_: SecurityException) {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
        }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString("title", title)
            .putString("body", body)
            .putLong("trigger_at", triggerAt)
            .apply()
    }

    fun cancelSchedule(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, CheckInAlarmReceiver::class.java)
        val pi = PendingIntent.getBroadcast(
            context,
            ALARM_REQUEST_CODE,
            intent,
            pendingFlags() or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        am.cancel(pi)
        cancel(context)
    }

    fun consumePendingAction(context: Context): String? {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val action = prefs.getString(KEY_PENDING_ACTION, null) ?: return null
        prefs.edit().remove(KEY_PENDING_ACTION).apply()
        return action
    }

    fun storePendingAction(context: Context, actionId: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(KEY_PENDING_ACTION, actionId)
            .apply()
    }

    private fun bindMoodClicks(
        context: Context,
        views: RemoteViews,
        notificationId: Int,
    ) {
        views.setOnClickPendingIntent(
            R.id.btn_mood_tres_mal,
            actionPendingIntent(context, ACTION_TRES_MAL, notificationId, 1),
        )
        views.setOnClickPendingIntent(
            R.id.btn_mood_pas_top,
            actionPendingIntent(context, ACTION_PAS_TOP, notificationId, 2),
        )
        views.setOnClickPendingIntent(
            R.id.btn_mood_ca_va,
            actionPendingIntent(context, ACTION_CA_VA, notificationId, 3),
        )
        views.setOnClickPendingIntent(
            R.id.btn_mood_super,
            actionPendingIntent(context, ACTION_SUPER, notificationId, 4),
        )
    }

    private fun actionPendingIntent(
        context: Context,
        actionId: String,
        notificationId: Int,
        requestCode: Int,
    ): PendingIntent {
        val intent = Intent(context, CheckInActionReceiver::class.java).apply {
            putExtra(EXTRA_ACTION_ID, actionId)
            putExtra(EXTRA_NOTIFICATION_ID, notificationId)
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode + notificationId,
            intent,
            pendingFlags() or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun pendingFlags(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }
    }

    private fun nextTriggerMillis(hour: Int, minute: Int, skipIfSameDayPast: Boolean): Long {
        val cal = java.util.Calendar.getInstance().apply {
            set(java.util.Calendar.SECOND, 0)
            set(java.util.Calendar.MILLISECOND, 0)
            set(java.util.Calendar.HOUR_OF_DAY, hour)
            set(java.util.Calendar.MINUTE, minute)
        }
        val now = System.currentTimeMillis()
        if (cal.timeInMillis <= now || skipIfSameDayPast) {
            cal.add(java.util.Calendar.DAY_OF_YEAR, 1)
        }
        return cal.timeInMillis
    }
}

package cm.fidel.fidel_assistant

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

/**
 * Countdown SOS 30s (annulation) — source de vérité native.
 * Offline : à l'expire → appel. Online : notifie Flutter pour confirm.
 */
class SosCountdownService : Service() {
    companion object {
        const val CHANNEL_ID = "fidel_sos_countdown"
        const val NOTIFICATION_ID = 91001605
        const val EXTRA_WAIT_MS = "wait_ms"
        const val EXTRA_PHONE = "phone"
        const val EXTRA_MODE = "mode"
        const val EXTRA_SOS_ID = "sos_id"
        const val ACTION_START = "sos_countdown_start"
        const val ACTION_STOP = "sos_countdown_stop"
        const val MODE_ONLINE = "online"
        const val MODE_OFFLINE = "offline"
        private const val DEFAULT_WAIT_MS = 30_000L
        private const val TICK_MS = 1_000L
    }

    private val handler = Handler(Looper.getMainLooper())
    private var phone: String? = null
    private var mode: String = MODE_ONLINE
    private var sosId: String? = null
    private var deadlineElapsed: Long = 0L
    private var stopped = false

    private val tick = object : Runnable {
        override fun run() {
            if (stopped) return
            val remaining = (deadlineElapsed - SystemClock.elapsedRealtime()).coerceAtLeast(0L)
            val seconds = ((remaining + 999) / 1000).toInt()
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(NOTIFICATION_ID, buildNotification(seconds))
            if (remaining <= 0L) {
                onExpire()
            } else {
                handler.postDelayed(this, TICK_MS)
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopCountdown()
                return START_NOT_STICKY
            }
            else -> {
                stopped = false
                phone = intent?.getStringExtra(EXTRA_PHONE)
                mode = intent?.getStringExtra(EXTRA_MODE) ?: MODE_ONLINE
                sosId = intent?.getStringExtra(EXTRA_SOS_ID)
                val wait = intent?.getLongExtra(EXTRA_WAIT_MS, DEFAULT_WAIT_MS) ?: DEFAULT_WAIT_MS
                deadlineElapsed = SystemClock.elapsedRealtime() + wait.coerceAtLeast(1_000L)
                ensureChannel()
                val seconds = ((wait + 999) / 1000).toInt().coerceAtLeast(1)
                startForeground(NOTIFICATION_ID, buildNotification(seconds))
                handler.removeCallbacks(tick)
                handler.post(tick)
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(tick)
        super.onDestroy()
    }

    private fun stopCountdown() {
        stopped = true
        handler.removeCallbacks(tick)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun onExpire() {
        if (stopped) return
        stopped = true
        handler.removeCallbacks(tick)
        val p = phone
        if (mode == MODE_OFFLINE && !p.isNullOrBlank()) {
            SosCallHelper.placeCall(this, p)
            notifyFlutter("countdown_expired_called")
        } else {
            notifyFlutter("countdown_expired")
        }
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun notifyFlutter(event: String) {
        val engine = FlutterEngineCache.getInstance().get(SosActionReceiver.ENGINE_ID)
        if (engine != null) {
            MethodChannel(engine.dartExecutor.binaryMessenger, SosActionReceiver.CHANNEL)
                .invokeMethod("onNativeEvent", event)
        } else {
            SosNotificationHelper.stashAction(this, event)
            val launch = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(SosNotificationHelper.EXTRA_ACTION, event)
            }
            startActivity(launch)
        }
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return
        nm.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                "SOS countdown",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Compte à rebours avant envoi SOS"
                setShowBadge(true)
            },
        )
    }

    private fun buildNotification(secondsLeft: Int): Notification {
        val cancel = PendingIntent.getBroadcast(
            this,
            NOTIFICATION_ID + 1,
            Intent(this, SosActionReceiver::class.java).apply {
                action = SosNotificationHelper.ACTION_CANCEL_COUNTDOWN
                putExtra(
                    SosNotificationHelper.EXTRA_ACTION,
                    SosNotificationHelper.ACTION_CANCEL_COUNTDOWN,
                )
            },
            PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_IMMUTABLE
                } else {
                    0
                },
        )
        val open = PendingIntent.getActivity(
            this,
            NOTIFICATION_ID,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_IMMUTABLE
                } else {
                    0
                },
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_sos)
            .setContentTitle("SOS Fidel")
            .setContentText("Annuler dans ${secondsLeft}s")
            .setContentIntent(open)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(0, "Annuler", cancel)
            .build()
    }
}

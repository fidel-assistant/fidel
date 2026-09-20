package cm.fidel.fidel_assistant

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

/**
 * Attend [EXTRA_WAIT_MS] puis lance l'appel d'urgence si non stoppé
 * (fallback après push aidants sans ack).
 */
class SosEscalationService : Service() {
    companion object {
        const val CHANNEL_ID = "fidel_sos_escalation"
        const val NOTIFICATION_ID = 91001610
        const val EXTRA_PHONE = "phone"
        const val EXTRA_WAIT_MS = "wait_ms"
        const val ACTION_START = "sos_escalation_start"
        const val ACTION_STOP = "sos_escalation_stop"
        private const val DEFAULT_WAIT_MS = 45_000L
    }

    private val handler = Handler(Looper.getMainLooper())
    private var phone: String? = null
    private val escalate = Runnable {
        val p = phone
        if (p != null) {
            SosCallHelper.placeCall(this, p)
        }
        stopSelf()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                handler.removeCallbacks(escalate)
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            else -> {
                phone = intent?.getStringExtra(EXTRA_PHONE)
                val wait = intent?.getLongExtra(EXTRA_WAIT_MS, DEFAULT_WAIT_MS) ?: DEFAULT_WAIT_MS
                ensureChannel()
                startForeground(NOTIFICATION_ID, buildNotification())
                handler.removeCallbacks(escalate)
                if (wait <= 0L) {
                    escalate.run()
                } else {
                    handler.postDelayed(escalate, wait)
                }
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(escalate)
        super.onDestroy()
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return
        nm.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                "SOS escalation",
                NotificationManager.IMPORTANCE_LOW,
            ),
        )
    }

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_sos)
            .setContentTitle("SOS Fidel")
            .setContentText("En attente des aidants…")
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}

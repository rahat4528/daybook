package com.daybook.daybook.alarm

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

class AlarmForegroundService : Service() {
    companion object {
        const val CHANNEL_ID = "daybook_wake_quest_channel"
        const val NOTIFICATION_ID = 1001
        const val MAX_RING_DURATION_MS = 15 * 60 * 1000L // 15-minute fail-safe hard cutoff
    }

    private var ringtone: Ringtone? = null
    private val handler = Handler(Looper.getMainLooper())
    private var volumeRampStep = 0

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val alarmId = intent?.getStringExtra("ALARM_ID") ?: ""
        val label = intent?.getStringExtra("LABEL") ?: "Wake Quest Alarm"
        val challengeType = intent?.getStringExtra("CHALLENGE_TYPE") ?: "math"

        startForeground(NOTIFICATION_ID, buildAlarmNotification(alarmId, label, challengeType))
        startAudioPlayback()

        // 15-minute safety timeout
        handler.postDelayed({
            stopSelf()
        }, MAX_RING_DURATION_MS)

        return START_NOT_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "DayBook Wake Quest Alarms",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Critical high-priority alarms with challenge lockouts"
                setBypassDnd(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildAlarmNotification(alarmId: String, label: String, challengeType: String): Notification {
        val fullScreenIntent = Intent(this, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("ALARM_ID", alarmId)
            putExtra("LABEL", label)
            putExtra("CHALLENGE_TYPE", challengeType)
        }

        val fullScreenPendingIntent = PendingIntent.getActivity(
            this,
            alarmId.hashCode(),
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("DayBook Wake Quest: $label")
            .setContentText("Complete the $challengeType challenge to dismiss.")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .setOngoing(true)
            .build()
    }

    private fun startAudioPlayback() {
        try {
            val alertUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

            ringtone = RingtoneManager.getRingtone(applicationContext, alertUri)?.apply {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    audioAttributes = AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setLegacyStreamType(AudioManager.STREAM_ALARM)
                        .build()
                }
                play()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        try {
            ringtone?.stop()
        } catch (ignored: Exception) {}
        AlarmReceiver.releaseWakeLock()
        super.onDestroy()
    }
}

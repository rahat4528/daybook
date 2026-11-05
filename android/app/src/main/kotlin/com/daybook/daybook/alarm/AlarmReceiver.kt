package com.daybook.daybook.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import androidx.core.content.ContextCompat

class AlarmReceiver : BroadcastReceiver() {
    companion object {
        private var wakeLock: PowerManager.WakeLock? = null

        fun acquireWakeLock(context: Context) {
            if (wakeLock == null) {
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                wakeLock = powerManager.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                    "DayBook:AlarmWakeLock"
                )
            }
            wakeLock?.acquire(3 * 60 * 1000L) // 3-minute safety limit
        }

        fun releaseWakeLock() {
            try {
                if (wakeLock?.isHeld == true) {
                    wakeLock?.release()
                }
            } catch (ignored: Exception) {}
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        acquireWakeLock(context)

        val alarmId = intent.getStringExtra("ALARM_ID") ?: ""
        val label = intent.getStringExtra("LABEL") ?: "Wake Quest"
        val challengeType = intent.getStringExtra("CHALLENGE_TYPE") ?: "math"

        val serviceIntent = Intent(context, AlarmForegroundService::class.java).apply {
            putExtra("ALARM_ID", alarmId)
            putExtra("LABEL", label)
            putExtra("CHALLENGE_TYPE", challengeType)
        }

        ContextCompat.startForegroundService(context, serviceIntent)
    }
}

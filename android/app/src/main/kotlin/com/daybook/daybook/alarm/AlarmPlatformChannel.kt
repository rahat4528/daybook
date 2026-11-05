package com.daybook.daybook.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class AlarmPlatformChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL_NAME = "com.daybook.daybook/alarm_engine"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        when (call.method) {
            "canScheduleExactAlarms" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    result.success(alarmManager.canScheduleExactAlarms())
                } else {
                    result.success(true)
                }
            }
            "requestExactAlarmPermission" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    context.startActivity(intent)
                }
                result.success(true)
            }
            "scheduleExactAlarm" -> {
                val alarmId = call.argument<String>("alarmId") ?: ""
                val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: 0L
                val label = call.argument<String>("label") ?: "Wake Quest"
                val challengeType = call.argument<String>("challengeType") ?: "math"

                scheduleAlarmClock(alarmManager, alarmId, triggerAtMillis, label, challengeType)
                result.success(true)
            }
            "cancelAlarm" -> {
                val alarmId = call.argument<String>("alarmId") ?: ""
                cancelScheduledAlarm(alarmManager, alarmId)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun scheduleAlarmClock(
        alarmManager: AlarmManager,
        alarmId: String,
        triggerAtMillis: Long,
        label: String,
        challengeType: String
    ) {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = "com.daybook.daybook.ALARM_TRIGGER"
            putExtra("ALARM_ID", alarmId)
            putExtra("LABEL", label)
            putExtra("CHALLENGE_TYPE", challengeType)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Show clock icon in status bar and set exact alarm clock info
        val clockInfoIntent = PendingIntent.getActivity(
            context,
            alarmId.hashCode(),
            Intent(context, AlarmActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val alarmClockInfo = AlarmManager.AlarmClockInfo(triggerAtMillis, clockInfoIntent)
        alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
    }

    private fun cancelScheduledAlarm(alarmManager: AlarmManager, alarmId: String) {
        val intent = Intent(context, AlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId.hashCode(),
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )
        if (pendingIntent != null) {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }
    }
}

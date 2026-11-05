package com.daybook.daybook.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
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
                    val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    context.startActivity(intent)
                }
                result.success(true)
            }
            "isBatteryOptimizationIgnored" -> {
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
                val isIgnored = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    powerManager?.isIgnoringBatteryOptimizations(context.packageName) ?: true
                } else {
                    true
                }
                result.success(isIgnored)
            }
            "requestIgnoreBatteryOptimization" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    try {
                        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                            data = Uri.parse("package:${context.packageName}")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        context.startActivity(intent)
                    } catch (e: Exception) {
                        val fallback = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        context.startActivity(fallback)
                    }
                }
                result.success(true)
            }
            "openOemAutostartSettings" -> {
                val brand = Build.MANUFACTURER.lowercase()
                val opened = openOemSettings(brand)
                result.success(opened)
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

    private fun openOemSettings(brand: String): Boolean {
        val intents = mutableListOf<Intent>()
        when {
            brand.contains("xiaomi") || brand.contains("redmi") || brand.contains("poco") -> {
                intents.add(Intent().setComponent(ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")))
                intents.add(Intent("miui.intent.action.POWER_HIDE_MODE_APP_LIST").addCategory(Intent.CATEGORY_DEFAULT))
            }
            brand.contains("samsung") -> {
                intents.add(Intent().setComponent(ComponentName("com.samsung.android.lool", "com.samsung.android.sm.ui.battery.BatteryActivity")))
                intents.add(Intent().setComponent(ComponentName("com.samsung.android.sm", "com.samsung.android.sm.ui.battery.BatteryActivity")))
            }
            brand.contains("oppo") || brand.contains("realme") -> {
                intents.add(Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")))
                intents.add(Intent().setComponent(ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity")))
            }
            brand.contains("vivo") -> {
                intents.add(Intent().setComponent(ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")))
                intents.add(Intent().setComponent(ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity")))
            }
        }
        // Fallback standard app details
        intents.add(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:${context.packageName}")
        })

        for (intent in intents) {
            try {
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                context.startActivity(intent)
                return true
            } catch (_: Exception) {}
        }
        return false
    }
}

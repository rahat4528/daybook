package com.daybook.daybook

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.daybook.daybook.alarm.AlarmPlatformChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AlarmPlatformChannel.CHANNEL_NAME)
        channel.setMethodCallHandler(AlarmPlatformChannel(this))
    }
}

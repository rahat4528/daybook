package com.daybook.daybook.alarm

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import android.graphics.Color
import android.view.Gravity
import android.widget.LinearLayout

class AlarmActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Wake screen and display over lockscreen
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        )

        val label = intent.getStringExtra("LABEL") ?: "Wake Quest"
        val challengeType = intent.getStringExtra("CHALLENGE_TYPE") ?: "math"

        // Pure OLED Black Layout with Lime Bold Highlights
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.BLACK)
            gravity = Gravity.CENTER
            setPadding(48, 48, 48, 48)
        }

        val titleView = TextView(this).apply {
            text = "DAYBOOK WAKE QUEST"
            setTextColor(Color.parseColor("#B6FF00")) // Signature Lime Accent
            textSize = 14f
            gravity = Gravity.CENTER
        }

        val clockView = TextView(this).apply {
            text = java.text.SimpleDateFormat("HH:mm", java.util.Locale.US).format(java.util.Date())
            setTextColor(Color.WHITE)
            textSize = 64f
            gravity = Gravity.CENTER
        }

        val labelView = TextView(this).apply {
            text = label
            setTextColor(Color.parseColor("#A3A3A3"))
            textSize = 16f
            gravity = Gravity.CENTER
        }

        val challengeBadge = TextView(this).apply {
            text = "Active Challenge: $challengeType"
            setTextColor(Color.parseColor("#B6FF00"))
            textSize = 13f
            gravity = Gravity.CENTER
            setPadding(0, 32, 0, 32)
        }

        val solveButton = Button(this).apply {
            text = "SOLVE CHALLENGE TO DISMISS"
            setBackgroundColor(Color.parseColor("#B6FF00"))
            setTextColor(Color.BLACK)
            setOnClickListener {
                dismissAlarm()
            }
        }

        layout.addView(titleView)
        layout.addView(clockView)
        layout.addView(labelView)
        layout.addView(challengeBadge)
        layout.addView(solveButton)

        setContentView(layout)
    }

    private fun dismissAlarm() {
        // Stop foreground alarm service and release wake lock
        val serviceIntent = Intent(this, AlarmForegroundService::class.java)
        stopService(serviceIntent)
        finish()
    }
}

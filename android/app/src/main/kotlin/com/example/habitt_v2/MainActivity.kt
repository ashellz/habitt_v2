package com.shellz.habitt

import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    // ─── Alarm screen ─────────────────────────────────────
    // Habit alarms open this activity through the notification's full-screen
    // intent. Only for those launches it may show over the lock screen and
    // turn the screen on; the alarm page in Dart clears it again on dismiss.
    // See docs/habit_alarms.md.

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (isAlarmLaunch(intent)) setShowOverLockScreen(true)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (isAlarmLaunch(intent)) setShowOverLockScreen(true)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "habitt/alarm_screen")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canUseFullScreenIntent" -> result.success(canUseFullScreenIntent())
                    "openFullScreenIntentSettings" -> result.success(openFullScreenIntentSettings())
                    "setShowOverLockScreen" -> {
                        setShowOverLockScreen(call.argument<Boolean>("show") == true)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "habitt/alarm_ring")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canRing" -> result.success(HabitAlarmScheduler.canRing(this))
                    "schedule" -> result.success(
                        HabitAlarmScheduler.schedule(
                            this,
                            call.argument<Int>("id") ?: 0,
                            call.argument<Number>("epochMs")?.toLong() ?: 0L,
                            call.argument<String>("title") ?: "",
                        )
                    )
                    "cancel" -> {
                        HabitAlarmScheduler.cancel(this, call.argument<Int>("id") ?: 0)
                        result.success(null)
                    }
                    "cancelAll" -> {
                        HabitAlarmScheduler.cancelAll(this)
                        result.success(null)
                    }
                    "setRingDuringDnd" -> {
                        HabitAlarmScheduler.setRingDuringDnd(
                            this,
                            call.argument<Boolean>("ring") == true,
                        )
                        result.success(null)
                    }
                    "configure" -> {
                        HabitAlarmScheduler.setLabels(
                            this,
                            call.argument<String>("channelName") ?: "",
                            call.argument<String>("silenceLabel") ?: "",
                        )
                        result.success(null)
                    }
                    "stopRinging" -> {
                        HabitAlarmRingService.stop(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // awesome_notifications opens the app with this action for both a tap and
    // a full-screen intent, and puts the notification in `notificationJson`.
    private fun isAlarmLaunch(intent: Intent?): Boolean {
        if (intent?.action != "SELECT_NOTIFICATION") return false
        val json = intent.getStringExtra("notificationJson") ?: return false
        return ALARM_CHANNEL_KEYS.any { json.contains("\"$it\"") }
    }

    private fun setShowOverLockScreen(show: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(show)
            setTurnScreenOn(show)
        } else {
            @Suppress("DEPRECATION")
            val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            if (show) window.addFlags(flags) else window.clearFlags(flags)
        }
    }

    // Android 14+ turns full-screen intents off for apps that aren't a clock
    // or phone app. The manifest permission still reads as granted, so this
    // asks the system directly.
    private fun canUseFullScreenIntent(): Boolean {
        if (Build.VERSION.SDK_INT < 34) return true
        val manager = getSystemService(NotificationManager::class.java)
        return manager.canUseFullScreenIntent()
    }

    private fun openFullScreenIntentSettings(): Boolean {
        if (Build.VERSION.SDK_INT < 34) return false
        return try {
            startActivity(
                Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT)
                    .setData(Uri.parse("package:$packageName"))
            )
            true
        } catch (e: Exception) {
            false
        }
    }

    companion object {
        // Keep in sync with NotificationService.alarmChannelKey and
        // NotificationService.alarmSilentChannelKey.
        private val ALARM_CHANNEL_KEYS = listOf("habit_alarm_channel", "habit_alarm_silent_channel")
    }
}

package com.shellz.habitt

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Schedules the ringing half of Android habit alarms. See docs/habit_alarms.md.
 *
 * The alarm notification itself (title, buttons, full-screen page) is still
 * posted by awesome_notifications, but on a channel without sound: Android
 * plays channel sounds as notifications, which silent / vibrate mode mutes.
 * Here a matching `AlarmManager.setAlarmClock` alarm starts
 * [HabitAlarmRingService], which plays the alarm ringtone on the alarm audio
 * stream (not affected by the ringer mode) until that notification is gone.
 *
 * Scheduled alarms are kept in prefs (id -> "epochMs|title") so they can be
 * cancelled all at once and restored after a reboot.
 */
object HabitAlarmScheduler {
    private const val TAG = "HabitAlarm"
    private const val PREFS = "habit_alarm_ring"
    private const val ALARM_PREFIX = "alarm_"
    private const val KEY_RING_IN_DND = "ring_during_dnd"
    private const val KEY_CHANNEL_NAME = "label_channel_name"
    private const val KEY_SILENCE = "label_silence"

    const val EXTRA_ID = "habit_alarm_id"
    const val EXTRA_TITLE = "habit_alarm_title"
    const val ACTION_FIRE = "com.shellz.habitt.HABIT_ALARM_FIRE"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** Exact alarms are needed, otherwise the sound could start minutes late. */
    fun canRing(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        return context.getSystemService(AlarmManager::class.java).canScheduleExactAlarms()
    }

    fun schedule(context: Context, id: Int, epochMs: Long, title: String): Boolean {
        if (epochMs <= System.currentTimeMillis()) return false
        if (!canRing(context)) return false
        return try {
            val manager = context.getSystemService(AlarmManager::class.java)
            val info = AlarmManager.AlarmClockInfo(epochMs, showIntent(context))
            manager.setAlarmClock(info, fireIntent(context, id, title))
            prefs(context).edit().putString("$ALARM_PREFIX$id", "$epochMs|$title").apply()
            true
        } catch (e: SecurityException) {
            Log.w(TAG, "exact alarm not allowed", e)
            false
        }
    }

    fun cancel(context: Context, id: Int) {
        val manager = context.getSystemService(AlarmManager::class.java)
        manager.cancel(fireIntent(context, id, ""))
        prefs(context).edit().remove("$ALARM_PREFIX$id").apply()
    }

    fun cancelAll(context: Context) {
        for (id in storedIds(context)) cancel(context, id)
    }

    /** Called after a reboot / app update, which clear AlarmManager alarms. */
    fun restore(context: Context) {
        val now = System.currentTimeMillis()
        for ((key, value) in prefs(context).all) {
            if (!key.startsWith(ALARM_PREFIX) || value !is String) continue
            val id = key.removePrefix(ALARM_PREFIX).toIntOrNull() ?: continue
            val epochMs = value.substringBefore('|').toLongOrNull() ?: continue
            val title = value.substringAfter('|', "")
            if (epochMs <= now || !schedule(context, id, epochMs, title)) {
                prefs(context).edit().remove(key).apply()
            }
        }
    }

    /** The alarm fired: forget it (it's one-shot). */
    fun markFired(context: Context, id: Int) {
        prefs(context).edit().remove("$ALARM_PREFIX$id").apply()
    }

    // ─── Do Not Disturb ───────────────────────────────────
    // Alarm-stream sound already gets through DND (alarms are allowed by
    // default), so this is the user's choice, not a permission: when it's off
    // and DND is on, the alarm doesn't ring (the notification still shows).

    fun setRingDuringDnd(context: Context, ring: Boolean) {
        prefs(context).edit().putBoolean(KEY_RING_IN_DND, ring).apply()
    }

    fun mayRingNow(context: Context): Boolean {
        if (prefs(context).getBoolean(KEY_RING_IN_DND, false)) return true
        val manager = context.getSystemService(NotificationManager::class.java)
        return manager.currentInterruptionFilter == NotificationManager.INTERRUPTION_FILTER_ALL ||
            manager.currentInterruptionFilter == NotificationManager.INTERRUPTION_FILTER_UNKNOWN
    }

    // ─── Labels ───────────────────────────────────────────
    // Text for the ringing service's own notification, localized in Dart and
    // stored here because the service runs without the Flutter engine.

    data class Labels(val channelName: String, val silence: String)

    fun setLabels(context: Context, channelName: String, silence: String) {
        prefs(context).edit()
            .putString(KEY_CHANNEL_NAME, channelName)
            .putString(KEY_SILENCE, silence)
            .apply()
    }

    fun labels(context: Context): Labels {
        val p = prefs(context)
        return Labels(
            channelName = p.getString(KEY_CHANNEL_NAME, null) ?: "Habit alarm",
            silence = p.getString(KEY_SILENCE, null) ?: "Silence",
        )
    }

    // ─── Intents ──────────────────────────────────────────

    private fun storedIds(context: Context): List<Int> =
        prefs(context).all.keys
            .filter { it.startsWith(ALARM_PREFIX) }
            .mapNotNull { it.removePrefix(ALARM_PREFIX).toIntOrNull() }

    private fun fireIntent(context: Context, id: Int, title: String): PendingIntent {
        val intent = Intent(context, HabitAlarmReceiver::class.java)
            .setAction(ACTION_FIRE)
            .putExtra(EXTRA_ID, id)
            .putExtra(EXTRA_TITLE, title)
        return PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    // What the system opens from the "next alarm" shown in the status bar /
    // quick settings.
    private fun showIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}

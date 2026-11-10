package com.shellz.habitt

import android.app.AlarmManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Starts the alarm sound when a habit alarm fires, and puts scheduled alarms
 * back after a reboot / app update (both clear AlarmManager). See
 * [HabitAlarmScheduler] and docs/habit_alarms.md.
 */
class HabitAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            HabitAlarmScheduler.ACTION_FIRE -> onFire(context, intent)
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            AlarmManager.ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED ->
                HabitAlarmScheduler.restore(context)
        }
    }

    private fun onFire(context: Context, intent: Intent) {
        val id = intent.getIntExtra(HabitAlarmScheduler.EXTRA_ID, -1)
        if (id == -1) return
        HabitAlarmScheduler.markFired(context, id)
        if (!HabitAlarmScheduler.mayRingNow(context)) {
            Log.i("HabitAlarm", "Do Not Disturb is on, not ringing alarm $id")
            return
        }
        val title = intent.getStringExtra(HabitAlarmScheduler.EXTRA_TITLE) ?: ""
        try {
            // Allowed from the background: started by an exact alarm.
            context.startForegroundService(
                HabitAlarmRingService.startIntent(context, id, title),
            )
        } catch (e: Exception) {
            Log.w("HabitAlarm", "could not start alarm sound", e)
        }
    }
}

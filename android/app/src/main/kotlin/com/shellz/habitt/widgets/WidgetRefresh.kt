package com.shellz.habitt.widgets

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.glance.appwidget.updateAll
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.time.LocalDateTime
import java.time.ZoneId

/**
 * Redraws the widgets at the next part-of-day boundary (04:00, 12:00, 19:00)
 * and when the next day starts, so they switch section and day while the app
 * is closed. One inexact alarm (`setWindow`, no exact-alarm permission), re-armed
 * after every redraw. See docs/home_widgets.md.
 */
object WidgetRefresh {
    const val ACTION_REFRESH = "com.shellz.habitt.widgets.action.REFRESH"
    private const val TAG = "HabittWidgets"

    /** Inexact window after each boundary; Android 12+ stretches anything shorter to 10 minutes. */
    private const val WINDOW_MS = 10 * 60 * 1000L

    private val receivers = listOf(
        StreakWidgetReceiver::class.java,
        StreakWeekWidgetReceiver::class.java,
        TodayRingWidgetReceiver::class.java,
        UpNextWidgetReceiver::class.java,
    )

    fun hasWidgets(context: Context): Boolean {
        val manager = AppWidgetManager.getInstance(context)
        return receivers.any { manager.getAppWidgetIds(ComponentName(context, it)).isNotEmpty() }
    }

    fun scheduleNext(context: Context) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        val pending = pendingIntent(context)
        if (!hasWidgets(context)) {
            alarms.cancel(pending)
            return
        }
        val snapshot = WidgetStore.load(context)
        val next = WidgetClock.nextUpdate(LocalDateTime.now(), snapshot?.nextDayStartsAt)
        val at = next.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()
        alarms.setWindow(AlarmManager.RTC, at, WINDOW_MS, pending)
        Log.d(TAG, "next widget refresh at $next")
    }

    suspend fun updateAll(context: Context) {
        StreakWidget().updateAll(context)
        StreakWeekWidget().updateAll(context)
        TodayRingWidget().updateAll(context)
        UpNextWidget().updateAll(context)
    }

    private fun pendingIntent(context: Context): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            0,
            Intent(context, WidgetRefreshReceiver::class.java).setAction(ACTION_REFRESH),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
}

/**
 * The boundary alarm, plus clock, time zone and locale changes, reboots and
 * app updates (alarms do not survive the last two).
 */
class WidgetRefreshReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pending = goAsync()
        CoroutineScope(Dispatchers.Default).launch {
            try {
                if (WidgetRefresh.hasWidgets(context)) WidgetRefresh.updateAll(context)
                WidgetRefresh.scheduleNext(context)
            } catch (e: Exception) {
                Log.w("HabittWidgets", "widget refresh failed", e)
            } finally {
                pending.finish()
            }
        }
    }
}

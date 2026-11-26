package com.shellz.habitt.wear.ui

import android.content.Context
import android.os.Build
import android.view.HapticFeedbackConstants
import android.view.View
import androidx.annotation.StringRes
import androidx.compose.ui.graphics.Color
import com.shellz.habitt.wear.R
import com.shellz.habitt.widgets.WidgetSnapshot

// Colours and texts shared by the Wear OS screens, the same as the watchOS app's.

object WearColors {
    val Row = Color(0xFF1C1C1E)
    val Track = Color(0xFF2C2C2E)
    val Secondary = Color(0xFFA1A1A6)
    val Note = Color(0xFFD1D1D6)
    val OffGrey = Color(0xFF565963)
    val CheckOnDone = Color(0xFF0C0C0C)
}

/**
 * UI text in the phone app's language from the snapshot, else the watch's own
 * string resource (before the first sync, or from an older phone app). Keys
 * that name the iPhone or Apple Health on the Apple Watch have a `wear*`
 * twin; only that one is read here.
 */
class WearText(private val context: Context, private val snapshot: WidgetSnapshot?) {

    fun get(key: String, @StringRes fallback: Int): String =
        snapshot?.strings?.labels?.get(key) ?: context.getString(fallback)

    /** [get] with its one placeholder (`%@` from the snapshot, `%1$s` in resources) filled in. */
    fun format(key: String, @StringRes fallback: Int, arg: String): String =
        get(key, fallback).replace("%@", arg).replace("%1\$s", arg)

    val today get() = get("today", R.string.wear_today)
    val showHabits get() = get("watchShowHabits", R.string.wear_show_habits)
    val healthNote get() = get("wearHealthNote", R.string.wear_health_note)
    val logOnPhone get() = get("wearLogOnPhone", R.string.wear_log_on_phone)
    val updateNeeded get() = get("watchUpdateNeeded", R.string.wear_update_needed)
    val updateNeededBody get() = get("wearUpdateNeededBody", R.string.wear_update_needed_body)
    val less get() = get("watchLess", R.string.wear_less)
    val more get() = get("watchMore", R.string.wear_more)
    val openOnPhone get() = context.getString(R.string.wear_open_on_phone)
    val openOnPhoneBody get() = get("watchOpenOnIPhoneBody", R.string.wear_open_on_phone_body)

    fun ofTarget(target: String) = format("watchOfTarget", R.string.wear_of_target, target)
    fun completeHabit(name: String) = format("watchCompleteHabit", R.string.wear_complete_habit, name)
    fun uncompleteHabit(name: String) = format("watchUncompleteHabit", R.string.wear_uncomplete_habit, name)

    /** Section titles in the phone's order. */
    fun part(category: Int): String = when (category) {
        2 -> get("morning", R.string.wear_morning)
        3 -> get("afternoon", R.string.wear_afternoon)
        4 -> get("evening", R.string.wear_evening)
        else -> get("anyTime", R.string.wear_any_time)
    }

    val optional get() = get("optional", R.string.wear_optional)
}

/** A confirm haptic when a habit gets completed. */
fun View.confirmHaptic() {
    performHapticFeedback(HapticFeedbackConstants.CONFIRM)
}

/** One rotary detent. */
fun View.tickHaptic() {
    performHapticFeedback(
        if (Build.VERSION.SDK_INT >= 34) HapticFeedbackConstants.SEGMENT_FREQUENT_TICK else HapticFeedbackConstants.CLOCK_TICK,
    )
}

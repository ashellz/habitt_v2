package com.shellz.habitt.watch

import com.shellz.habitt.widgets.DayBlock
import com.shellz.habitt.widgets.HabitLog
import com.shellz.habitt.widgets.WidgetHabit
import com.shellz.habitt.widgets.WidgetSnapshot
import org.json.JSONObject
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.Locale
import java.util.UUID

// The watch side of the watch ↔ phone contract (docs/watch_app.md), the Kotlin
// twin of ios/HabittWidgetsCore/.../WatchState.swift. Keep the two in step:
// same JSON, same overlay rules, same tests.

/**
 * What the watch asks the phone to do. Values are absolute ("set 8"), never
 * increments, so a resend or a duplicate is harmless.
 */
data class WatchAction(
    val v: Int = VERSION,
    val id: String,
    val type: Type,
    val habitId: Long,
    /** The `yyyy-MM-dd` key of the day block the user acted on. */
    val day: String,
    /** setAmount: the count. setDuration: seconds. Null otherwise. */
    val value: Int? = null,
    /** Watch local time, `yyyy-MM-ddTHH:mm:ss.SSS`, for ordering on the phone. */
    val at: String,
) {
    enum class Type(val key: String) {
        COMPLETE("complete"),
        UNCOMPLETE("uncomplete"),
        SET_AMOUNT("setAmount"),
        SET_DURATION("setDuration");

        companion object {
            fun of(key: String?): Type? = entries.firstOrNull { it.key == key }
        }
    }

    /** The action object itself (`{v, id, type, habitId, day, value?, at}`). */
    fun toJson(): JSONObject = JSONObject().apply {
        put("v", v)
        put("id", id)
        put("type", type.key)
        put("habitId", habitId)
        put("day", day)
        if (value != null) put("value", value)
        put("at", at)
    }

    /** The message sent to the phone: `{"watchAction": {…}}`, the same as the Apple Watch's. */
    fun message(): String = JSONObject().put("watchAction", toJson()).toString()

    companion object {
        /** Bumped only for a breaking change to this message. */
        const val VERSION = 1

        fun create(
            type: Type,
            habitId: Long,
            day: String,
            value: Int? = null,
            now: LocalDateTime = LocalDateTime.now(),
            id: String = UUID.randomUUID().toString().uppercase(Locale.ROOT),
        ) = WatchAction(id = id, type = type, habitId = habitId, day = day, value = value, at = WatchDates.localTimestamp(now))

        /** Reads an action object (the outbox the watch persists); null when unreadable. */
        fun fromJson(o: JSONObject?): WatchAction? {
            if (o == null) return null
            return try {
                WatchAction(
                    v = o.getInt("v"),
                    id = o.getString("id"),
                    type = Type.of(o.getString("type")) ?: return null,
                    habitId = o.getLong("habitId"),
                    day = o.getString("day"),
                    value = if (o.has("value") && !o.isNull("value")) o.getInt("value") else null,
                    at = o.optString("at", ""),
                )
            } catch (e: Exception) {
                null
            }
        }
    }
}

object WatchDates {
    private val timestamp = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.ROOT)

    /** `yyyy-MM-dd`. */
    fun dayKey(date: LocalDate): String = date.toString()

    /** Like Dart's `DateTime.toIso8601String()` of a local time. */
    fun localTimestamp(time: LocalDateTime): String = timestamp.format(time)
}

/** The watch's own changes on top of the phone's snapshot, until the phone confirms them. */
object WatchOverlay {
    /** How many unconfirmed actions the watch keeps at most. */
    const val MAX_OUTBOX = 100

    /** Drops actions the phone acknowledged and actions for a day the watch no longer shows. */
    fun prune(outbox: List<WatchAction>, snapshot: WidgetSnapshot, shownDay: String): List<WatchAction> {
        val acked = snapshot.watchAcks.toSet()
        return outbox.filter { it.id !in acked && it.day == shownDay }.takeLast(MAX_OUTBOX)
    }

    /** [block] with the latest outbox action of each habit applied, and done/total/perfect recounted. */
    fun apply(block: DayBlock, day: String, outbox: List<WatchAction>): DayBlock {
        val latest = LinkedHashMap<Long, WatchAction>()
        for (a in outbox) if (a.day == day) latest[a.habitId] = a
        if (latest.isEmpty()) return block

        val habits = block.habits.map { h -> latest[h.id]?.let { applying(it, h) } ?: h }
        val out = block.copy(habits = habits)
        val counted = out.ringHabits()
        val done = counted.count { it.isDone }
        return out.copy(done = done, total = counted.size, perfect = counted.isNotEmpty() && done == counted.size)
    }

    /**
     * What [action] does to [habit], mirroring the app: completing sets the
     * value to the target, un-completing resets it to 0, a value at or over the
     * target completes.
     */
    fun applying(action: WatchAction, habit: WidgetHabit): WidgetHabit {
        val target = habit.log.target
        var log = habit.log
        val completed: Boolean
        when (action.type) {
            WatchAction.Type.COMPLETE -> {
                completed = true
                if (log.kind != null) log = log.copy(value = target)
            }
            WatchAction.Type.UNCOMPLETE -> {
                completed = false
                log = log.copy(value = 0)
            }
            WatchAction.Type.SET_AMOUNT, WatchAction.Type.SET_DURATION -> {
                val value = maxOf(action.value ?: 0, 0)
                log = log.copy(value = value)
                completed = target > 0 && value >= target
            }
        }
        val progress: Double
        val state: WidgetHabit.State
        if (completed) {
            progress = 1.0
            state = WidgetHabit.State.DONE
        } else {
            progress = if (target > 0) minOf(log.value.toDouble() / target, 1.0) else 0.0
            state = if (progress > 0) WidgetHabit.State.PARTIAL else WidgetHabit.State.TODO
        }
        val h = habit.copy(completed = completed, log = log, progress = progress, state = state)
        return h.copy(progressText = progressText(h))
    }

    /**
     * The habit card's progress line for the overlaid value ("3 / 10 pages",
     * "6m / 10m"); the snapshot's own text is stale once the value changed.
     */
    fun progressText(h: WidgetHabit): String {
        val log = h.log
        return when (log.kind) {
            HabitLog.Kind.AMOUNT -> {
                val unit = if (log.unit.isEmpty()) "" else " ${log.unit}"
                when {
                    h.completed -> "${log.value}$unit"
                    log.value > 0 -> "${log.value} / ${log.target}$unit"
                    else -> "${log.target}$unit"
                }
            }
            HabitLog.Kind.DURATION -> when {
                h.completed || log.value >= log.target -> durationString(log.value)
                log.value > 0 -> "${durationString(log.value)} / ${durationString(log.target)}"
                else -> durationString(log.target)
            }
            else -> h.progressText
        }
    }

    /** Same as the app's `getDurationString`: "1h5m", "10m", "30s", "0m". */
    fun durationString(seconds: Int): String {
        val h = seconds / 3600
        val m = (seconds % 3600) / 60
        val s = seconds % 60
        val parts = buildList {
            if (h > 0) add("${h}h")
            if (m > 0) add("${m}m")
            if (s > 0) add("${s}s")
        }
        return if (parts.isEmpty()) "0m" else parts.joinToString("")
    }
}

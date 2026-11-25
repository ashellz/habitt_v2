package com.shellz.habitt.widgets

import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime

/**
 * The widget snapshot the Flutter app writes (key `habitt_snapshot`, see
 * docs/home_widgets.md). The widgets only draw it: every habit, streak and
 * schedule decision was already made in Dart. Pure Kotlin + org.json so it is
 * unit tested on the JVM.
 */
data class WidgetSnapshot(
    val dayKey: String,
    val nextDayStartsAt: LocalDateTime,
    val accentLight: Int,
    val accentDark: Int,
    val strings: Strings,
    val today: DayBlock,
    val tomorrow: DayBlock,
    /** False when the app has no habits at all, not just none today. */
    val hasHabits: Boolean = true,
) {
    data class Strings(
        val dayStreak: String,
        val daysStreak: String,
        val day: String,
        val days: String,
        val dayComplete: String,
        val dayCompleteBody: String,
        val nothingToday: String,
        val noHabits: String = DEFAULT_NO_HABITS,
    ) {
        fun streakLabel(count: Int) = if (count == 1) dayStreak else daysStreak

        fun dayLabel(count: Int) = if (count == 1) day else days
    }

    /** The block the widgets show at [now]: `tomorrow` once the next day has started. */
    fun blockAt(now: LocalDateTime): DayBlock = if (!now.isBefore(nextDayStartsAt)) tomorrow else today

    companion object {
        const val VERSION = 1

        /** Parses [json]; null for no snapshot, another version or anything malformed. */
        fun parse(json: String?): WidgetSnapshot? {
            if (json.isNullOrBlank()) return null
            return try {
                val o = JSONObject(json)
                if (o.optInt("v", -1) != VERSION) return null
                val theme = o.optJSONObject("theme")
                val s = o.optJSONObject("strings") ?: JSONObject()
                val dayStreak = s.optString("dayStreak", "day streak")
                val daysStreak = s.optString("daysStreak", "days streak")
                WidgetSnapshot(
                    dayKey = o.getString("dayKey"),
                    nextDayStartsAt = parseDateTime(o.getString("nextDayStartsAt")),
                    accentLight = parseColor(theme?.optJSONObject("light")?.optString("accent"), DEFAULT_ACCENT_LIGHT),
                    accentDark = parseColor(theme?.optJSONObject("dark")?.optString("accent"), DEFAULT_ACCENT_DARK),
                    strings = Strings(
                        dayStreak = dayStreak,
                        daysStreak = daysStreak,
                        // older snapshots have no short form: fall back to the first word
                        day = s.optString("day", dayStreak.substringBefore(' ')),
                        days = s.optString("days", daysStreak.substringBefore(' ')),
                        dayComplete = s.optString("dayComplete", "Day complete"),
                        dayCompleteBody = s.optString("dayCompleteBody", ""),
                        nothingToday = s.optString("nothingToday", ""),
                        noHabits = s.optString("noHabits", DEFAULT_NO_HABITS),
                    ),
                    today = DayBlock.parse(o.getJSONObject("today")),
                    tomorrow = DayBlock.parse(o.getJSONObject("tomorrow")),
                    hasHabits = o.optBoolean("hasHabits", true),
                )
            } catch (e: Exception) {
                null
            }
        }

        /**
         * What the widgets show before the app wrote its first snapshot (just
         * installed, never opened): no habits and a streak of 0, in the
         * device language. Never rolls over to a "tomorrow".
         */
        fun placeholder(strings: Strings, startStreak: String, weekLabels: List<String>, today: LocalDate): WidgetSnapshot {
            val week = weekLabels.mapIndexed { i, label ->
                WeekDay(label, if (i == weekLabels.lastIndex) WeekDay.Status.TODAY else WeekDay.Status.NONE, 0.0)
            }
            val block = DayBlock(
                habits = emptyList(),
                ring = emptyList(),
                done = 0,
                total = 0,
                perfect = false,
                streak = StreakInfo(0, StreakInfo.Health.DORMANT, false, startStreak, week),
                upNext = PartOfDay.entries.associateWith { null },
            )
            return WidgetSnapshot(
                dayKey = today.toString(),
                nextDayStartsAt = LocalDateTime.MAX,
                accentLight = DEFAULT_ACCENT_LIGHT,
                accentDark = DEFAULT_ACCENT_DARK,
                strings = strings,
                today = block,
                tomorrow = block,
                hasHabits = false,
            )
        }

        const val DEFAULT_NO_HABITS = "You haven’t added any habits yet"
        const val DEFAULT_ACCENT_LIGHT = 0xFF02D382.toInt()
        const val DEFAULT_ACCENT_DARK = 0xFF11F29B.toInt()

        /** Dart's `DateTime.toIso8601String()` of a local time, e.g. `2026-11-25T00:00:00.000`. */
        fun parseDateTime(s: String): LocalDateTime =
            if (s.length == 10) LocalDate.parse(s).atStartOfDay() else LocalDateTime.parse(s.removeSuffix("Z"))

        /** `#RRGGBB` → opaque ARGB int. */
        fun parseColor(hex: String?, fallback: Int): Int {
            val v = hex?.removePrefix("#") ?: return fallback
            if (v.length != 6) return fallback
            return v.toLongOrNull(16)?.let { (0xFF000000 or it).toInt() } ?: fallback
        }
    }
}

data class WidgetHabit(
    val id: Long,
    val emoji: String,
    val name: String,
    val category: Int,
    val optional: Boolean,
    val progress: Double,
    val progressText: String,
    val state: State,
) {
    enum class State { DONE, PARTIAL, TODO }

    val isDone get() = state == State.DONE
}

data class WeekDay(val label: String, val status: Status, val progress: Double) {
    enum class Status { PERFECT, PARTIAL, MISS, NONE, TODAY }
}

data class StreakInfo(
    val count: Int,
    val health: Health,
    val perfectToday: Boolean,
    val line: String,
    val week: List<WeekDay>,
) {
    enum class Health { HEALTHY, FADING, CRITICAL, DORMANT }
}

data class UpNextSection(val label: String, val icon: String, val habitIds: List<Long>)

data class DayBlock(
    val habits: List<WidgetHabit>,
    val ring: List<Long>,
    val done: Int,
    val total: Int,
    val perfect: Boolean,
    val streak: StreakInfo,
    val upNext: Map<PartOfDay, UpNextSection?>,
) {
    fun habit(id: Long): WidgetHabit? = habits.firstOrNull { it.id == id }

    /** Ring segments in order, as habits. */
    fun ringHabits(): List<WidgetHabit> = ring.mapNotNull { habit(it) }

    /** Where a tap on the Today ring goes: the first counted habit not done, null when none. */
    fun firstNotDone(): WidgetHabit? = ringHabits().firstOrNull { !it.isDone }

    fun upNextAt(time: LocalTime): UpNextSection? = upNext[PartOfDay.at(time)]

    companion object {
        fun parse(o: JSONObject): DayBlock {
            val habits = o.optJSONArray("habits").objects().map { h ->
                WidgetHabit(
                    id = h.getLong("id"),
                    emoji = h.optString("emoji", ""),
                    name = h.optString("name", ""),
                    category = h.optInt("category", 1),
                    optional = h.optBoolean("optional", false),
                    progress = h.optDouble("progress", 0.0).coerceIn(0.0, 1.0),
                    progressText = h.optString("progressText", ""),
                    state = when (h.optString("state")) {
                        "done" -> WidgetHabit.State.DONE
                        "partial" -> WidgetHabit.State.PARTIAL
                        else -> WidgetHabit.State.TODO
                    },
                )
            }
            val s = o.optJSONObject("streak") ?: JSONObject()
            val streak = StreakInfo(
                count = s.optInt("count", 0),
                health = when (s.optString("health")) {
                    "healthy" -> StreakInfo.Health.HEALTHY
                    "fading" -> StreakInfo.Health.FADING
                    "critical" -> StreakInfo.Health.CRITICAL
                    else -> StreakInfo.Health.DORMANT
                },
                perfectToday = s.optBoolean("perfectToday", false),
                line = s.optString("line", ""),
                week = s.optJSONArray("week").objects().map { d ->
                    WeekDay(
                        label = d.optString("label", ""),
                        status = when (d.optString("s")) {
                            "perfect" -> WeekDay.Status.PERFECT
                            "partial" -> WeekDay.Status.PARTIAL
                            "miss" -> WeekDay.Status.MISS
                            "today" -> WeekDay.Status.TODAY
                            else -> WeekDay.Status.NONE
                        },
                        progress = d.optDouble("p", 0.0).coerceIn(0.0, 1.0),
                    )
                },
            )
            val up = o.optJSONObject("upNext")
            val upNext = PartOfDay.entries.associateWith { part ->
                up?.optJSONObject(part.key)?.let { sec ->
                    UpNextSection(
                        label = sec.optString("label", ""),
                        icon = sec.optString("icon", part.key),
                        habitIds = sec.optJSONArray("habits").longs(),
                    )
                }
            }
            return DayBlock(
                habits = habits,
                ring = o.optJSONArray("ring").longs(),
                done = o.optInt("done", 0),
                total = o.optInt("total", 0),
                perfect = o.optBoolean("perfect", false),
                streak = streak,
                upNext = upNext,
            )
        }

        private fun JSONArray?.objects(): List<JSONObject> =
            if (this == null) emptyList() else (0 until length()).mapNotNull { optJSONObject(it) }

        private fun JSONArray?.longs(): List<Long> =
            if (this == null) emptyList() else (0 until length()).map { getLong(it) }
    }
}

/** Parts of the day as the app's `categoryIdForMinutes`: Morning 04–12, Afternoon 12–19, Evening 19–04. */
enum class PartOfDay(val key: String) {
    MORNING("morning"),
    AFTERNOON("afternoon"),
    EVENING("evening");

    companion object {
        fun at(time: LocalTime): PartOfDay = when (time.hour) {
            in 4..11 -> MORNING
            in 12..18 -> AFTERNOON
            else -> EVENING
        }

        /** Clock times at which what the widgets show can change on its own. */
        val boundaries: List<LocalTime> = listOf(LocalTime.MIDNIGHT, LocalTime.of(4, 0), LocalTime.of(12, 0), LocalTime.of(19, 0))
    }
}

/** When the widgets have to redraw next without the app: the next part-of-day boundary or day start. */
object WidgetClock {
    fun nextUpdate(now: LocalDateTime, nextDayStartsAt: LocalDateTime?): LocalDateTime {
        val candidates = mutableListOf<LocalDateTime>()
        for (dayOffset in 0L..1L) {
            val date = now.toLocalDate().plusDays(dayOffset)
            for (t in PartOfDay.boundaries) candidates += date.atTime(t)
        }
        if (nextDayStartsAt != null) candidates += nextDayStartsAt
        return candidates.filter { it.isAfter(now) }.min()
    }
}

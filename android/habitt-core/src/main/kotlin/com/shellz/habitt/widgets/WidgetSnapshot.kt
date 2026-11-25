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
 * unit tested on the JVM, and shared with the Wear OS app (docs/watch_app.md),
 * which also reads the watch fields (`completed`, `log`, `labels`, `watchAcks`).
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
    /** Ids of watch actions the app has applied or dropped, oldest first (docs/watch_app.md). */
    val watchAcks: List<String> = emptyList(),
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
        /** Every snapshot string by key, in the app's language (the watch reads its texts here). */
        val labels: Map<String, String> = emptyMap(),
    ) {
        fun streakLabel(count: Int) = if (count == 1) dayStreak else daysStreak

        fun dayLabel(count: Int) = if (count == 1) day else days
    }

    /** The block the widgets show at [now]: `tomorrow` once the next day has started. */
    fun blockAt(now: LocalDateTime): DayBlock = if (!now.isBefore(nextDayStartsAt)) tomorrow else today

    /** The `yyyy-MM-dd` key of the day shown at [now]: `dayKey`, or tomorrow's once the next day started. */
    fun shownDayKey(now: LocalDateTime): String =
        if (!now.isBefore(nextDayStartsAt)) nextDayStartsAt.toLocalDate().toString() else dayKey

    companion object {
        const val VERSION = 1

        /**
         * The snapshot's `v` without parsing the rest; null when unreadable. The
         * watch uses it to tell "from a newer app" apart from "malformed".
         */
        fun peekVersion(json: String?): Int? {
            if (json.isNullOrBlank()) return null
            return try {
                JSONObject(json).let { if (it.has("v")) it.getInt("v") else null }
            } catch (e: Exception) {
                null
            }
        }

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
                        labels = s.keys().asSequence()
                            .mapNotNull { k -> (s.opt(k) as? String)?.let { k to it } }
                            .toMap(),
                    ),
                    today = DayBlock.parse(o.getJSONObject("today")),
                    tomorrow = DayBlock.parse(o.getJSONObject("tomorrow")),
                    hasHabits = o.optBoolean("hasHabits", true),
                    watchAcks = o.optJSONArray("watchAcks").let { a ->
                        if (a == null) emptyList() else (0 until a.length()).mapNotNull { a.opt(it) as? String }
                    },
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
    /** The habit's own completed flag (`state` done also covers skipped). */
    val completed: Boolean = state == State.DONE,
    val log: HabitLog = HabitLog.NONE,
) {
    enum class State { DONE, PARTIAL, TODO }

    val isDone get() = state == State.DONE

    /** Health-linked and time-of-day habits only show their state on the watch. */
    val watchReadOnly get() = log.healthLinked || log.kind == HabitLog.Kind.TIME_OF_DAY
}

/** How a habit is logged, for the watch apps. Durations are in seconds. */
data class HabitLog(
    val kind: Kind?,
    val target: Int,
    val value: Int,
    /** Amount label for the target, already localized ("pages"); "" otherwise. */
    val unit: String = "",
    /** 1 for amounts, 60 (a minute) for durations. */
    val step: Int = 1,
    val healthLinked: Boolean = false,
    /** Amount or duration without Health sync: the watch can set its value. */
    val watchLoggable: Boolean = false,
) {
    enum class Kind(val key: String) {
        AMOUNT("amount"),
        DURATION("duration"),
        TIME_OF_DAY("timeOfDay");

        companion object {
            fun of(key: String?): Kind? = entries.firstOrNull { it.key == key }
        }
    }

    companion object {
        val NONE = HabitLog(kind = null, target = 0, value = 0)

        fun parse(o: JSONObject?): HabitLog {
            if (o == null) return NONE
            return HabitLog(
                kind = Kind.of(if (o.isNull("type")) null else o.optString("type")),
                target = o.optInt("target", 0),
                value = o.optInt("value", 0),
                unit = o.optString("unit", ""),
                step = o.optInt("step", 1).coerceAtLeast(1),
                healthLinked = o.optBoolean("healthLinked", false),
                watchLoggable = o.optBoolean("watchLoggable", false),
            )
        }
    }
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
                val state = when (h.optString("state")) {
                    "done" -> WidgetHabit.State.DONE
                    "partial" -> WidgetHabit.State.PARTIAL
                    else -> WidgetHabit.State.TODO
                }
                WidgetHabit(
                    id = h.getLong("id"),
                    emoji = h.optString("emoji", ""),
                    name = h.optString("name", ""),
                    category = h.optInt("category", 1),
                    optional = h.optBoolean("optional", false),
                    progress = h.optDouble("progress", 0.0).coerceIn(0.0, 1.0),
                    progressText = h.optString("progressText", ""),
                    state = state,
                    completed = if (h.has("completed")) h.optBoolean("completed") else state == WidgetHabit.State.DONE,
                    log = HabitLog.parse(h.optJSONObject("log")),
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

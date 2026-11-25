package com.shellz.habitt.widgets

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDateTime
import java.time.LocalTime

class WidgetSnapshotTest {

    private fun block(
        habits: String = "[]",
        ring: String = "[]",
        done: Int = 0,
        total: Int = 0,
        perfect: Boolean = false,
        count: Int = 3,
        morning: String = "null",
        afternoon: String = "null",
        evening: String = "null",
    ) = """
        {
          "habits": $habits, "ring": $ring, "done": $done, "total": $total, "perfect": $perfect,
          "streak": {"count": $count, "health": "healthy", "perfectToday": $perfect, "line": "Keep it up!",
                     "week": [{"label": "M", "s": "perfect", "p": 1.0}, {"label": "T", "s": "today", "p": 0.25}]},
          "upNext": {"morning": $morning, "afternoon": $afternoon, "evening": $evening}
        }
    """

    private val habits = """
        [
          {"id": 1, "emoji": "🪥", "name": "Brush", "category": 2, "optional": false, "progress": 1.0,
           "progressText": "Done", "state": "done", "canLog": true},
          {"id": 5, "emoji": "🚿", "name": "Shower", "category": 2, "optional": false, "progress": 0.8,
           "progressText": "8m / 10m", "state": "partial", "canLog": true},
          {"id": 7, "emoji": "📖", "name": "Read", "category": 4, "optional": false, "progress": 0.0,
           "progressText": "0 / 20 pages", "state": "todo", "canLog": true},
          {"id": 9, "emoji": "🧘", "name": "Stretch", "category": 1, "optional": true, "progress": 0.0,
           "progressText": "", "state": "todo", "canLog": false}
        ]
    """

    private fun snapshot(v: Int = 1, today: String = block(), tomorrow: String = block(count = 0)) = """
        {
          "v": $v,
          "generatedAt": "2026-11-24T08:30:00.000",
          "dayKey": "2026-11-24",
          "nextDayStartsAt": "2026-11-25T00:00:00.000",
          "theme": {"light": {"accent": "#955FD8"}, "dark": {"accent": "#BA86FF"}},
          "strings": {"dayStreak": "day streak", "daysStreak": "days streak", "day": "day", "days": "days",
                      "dayComplete": "Day complete", "dayCompleteBody": "All done.", "nothingToday": "Nothing today"},
          "today": $today,
          "tomorrow": $tomorrow
        }
    """

    private val full = snapshot(
        today = block(
            habits = habits,
            ring = "[1, 5, 7]",
            done = 1,
            total = 3,
            morning = """{"label": "Morning", "icon": "morning", "habits": [1, 5]}""",
            afternoon = """{"label": "Evening", "icon": "evening", "habits": [7]}""",
            evening = """{"label": "Evening", "icon": "evening", "habits": [7]}""",
        ),
    )

    // ─── parsing ─────────────────────────────────────────────────────

    @Test
    fun `parses a full snapshot`() {
        val s = WidgetSnapshot.parse(full)!!
        assertEquals("2026-11-24", s.dayKey)
        assertEquals(LocalDateTime.of(2026, 11, 25, 0, 0), s.nextDayStartsAt)
        assertEquals(0xFF955FD8.toInt(), s.accentLight)
        assertEquals(0xFFBA86FF.toInt(), s.accentDark)
        assertEquals("days streak", s.strings.streakLabel(2))
        assertEquals("day streak", s.strings.streakLabel(1))
        assertEquals("days", s.strings.dayLabel(0))

        val today = s.today
        assertEquals(4, today.habits.size)
        assertEquals(listOf(1, 5, 7), today.ring)
        assertEquals(1, today.done)
        assertEquals(3, today.total)
        assertFalse(today.perfect)
        val shower = today.habit(5)!!
        assertEquals("🚿", shower.emoji)
        assertEquals(WidgetHabit.State.PARTIAL, shower.state)
        assertEquals(0.8, shower.progress, 1e-9)
        assertEquals("8m / 10m", shower.progressText)
        assertTrue(today.habit(9)!!.optional)

        assertEquals(3, today.streak.count)
        assertEquals(StreakInfo.Health.HEALTHY, today.streak.health)
        assertEquals(WeekDay.Status.PERFECT, today.streak.week[0].status)
        assertEquals(WeekDay.Status.TODAY, today.streak.week[1].status)
        assertEquals(0.25, today.streak.week[1].progress, 1e-9)
        assertEquals(listOf(1, 5), today.upNext[PartOfDay.MORNING]!!.habitIds)
        assertEquals(0, s.tomorrow.streak.count)
    }

    @Test
    fun `no snapshot, garbage or another version is null`() {
        assertNull(WidgetSnapshot.parse(null))
        assertNull(WidgetSnapshot.parse(""))
        assertNull(WidgetSnapshot.parse("{not json"))
        assertNull(WidgetSnapshot.parse("{}"))
        assertNull(WidgetSnapshot.parse(snapshot(v = 2)))
    }

    @Test
    fun `older snapshot without the short day strings falls back`() {
        val s = WidgetSnapshot.parse(full.replace(""""day": "day", "days": "days",""", ""))!!
        assertEquals("day", s.strings.day)
        assertEquals("days", s.strings.days)
    }

    @Test
    fun `bad accent falls back to Habitt green`() {
        val s = WidgetSnapshot.parse(full.replace("#955FD8", "violet"))!!
        assertEquals(WidgetSnapshot.DEFAULT_ACCENT_LIGHT, s.accentLight)
    }

    @Test
    fun `ring tap goes to the first counted habit not done`() {
        val today = WidgetSnapshot.parse(full)!!.today
        assertEquals(5, today.firstNotDone()!!.id)
        assertEquals(listOf(1, 5, 7), today.ringHabits().map { it.id })
    }

    @Test
    fun `ring tap has no habit when all counted ones are done`() {
        val done = habits.replace("\"partial\"", "\"done\"").replace("\"state\": \"todo\", \"canLog\": true", "\"state\": \"done\", \"canLog\": true")
        val s = WidgetSnapshot.parse(snapshot(today = block(habits = done, ring = "[1, 5, 7]", done = 3, total = 3, perfect = true)))!!
        assertNull(s.today.firstNotDone())
        assertTrue(s.today.perfect)
    }

    // ─── block by clock ──────────────────────────────────────────────

    @Test
    fun `today until the next day starts, tomorrow from then on`() {
        val s = WidgetSnapshot.parse(full)!!
        assertEquals(3, s.blockAt(LocalDateTime.of(2026, 11, 24, 23, 59, 59)).streak.count)
        assertEquals(0, s.blockAt(LocalDateTime.of(2026, 11, 25, 0, 0)).streak.count)
        assertEquals(0, s.blockAt(LocalDateTime.of(2026, 11, 25, 9, 0)).streak.count)
        assertEquals(3, s.blockAt(LocalDateTime.of(2026, 11, 24, 3, 59)).streak.count)
    }

    // ─── part of day ─────────────────────────────────────────────────

    @Test
    fun `parts of the day follow the app`() {
        assertEquals(PartOfDay.EVENING, PartOfDay.at(LocalTime.of(3, 59)))
        assertEquals(PartOfDay.MORNING, PartOfDay.at(LocalTime.of(4, 0)))
        assertEquals(PartOfDay.MORNING, PartOfDay.at(LocalTime.of(11, 59)))
        assertEquals(PartOfDay.AFTERNOON, PartOfDay.at(LocalTime.of(12, 0)))
        assertEquals(PartOfDay.AFTERNOON, PartOfDay.at(LocalTime.of(18, 59)))
        assertEquals(PartOfDay.EVENING, PartOfDay.at(LocalTime.of(19, 0)))
        assertEquals(PartOfDay.EVENING, PartOfDay.at(LocalTime.MIDNIGHT))
    }

    @Test
    fun `Up next picks the section for the clock`() {
        val today = WidgetSnapshot.parse(full)!!.today
        assertEquals("Morning", today.upNextAt(LocalTime.of(4, 0))!!.label)
        assertEquals(listOf(7), today.upNextAt(LocalTime.of(12, 0))!!.habitIds)
        assertEquals("evening", today.upNextAt(LocalTime.of(19, 0))!!.icon)
        assertEquals("evening", today.upNextAt(LocalTime.of(3, 59))!!.icon)
    }

    @Test
    fun `Up next section is null on a perfect day`() {
        val s = WidgetSnapshot.parse(snapshot(today = block(habits = habits, perfect = true)))!!
        assertNull(s.today.upNextAt(LocalTime.of(9, 0)))
        assertNotNull(s.today.habits.firstOrNull())
    }

    // ─── refresh times ───────────────────────────────────────────────

    @Test
    fun `next refresh is the next boundary or the day start`() {
        val nextDay = LocalDateTime.of(2026, 11, 25, 0, 0)
        fun next(h: Int, m: Int) = WidgetClock.nextUpdate(LocalDateTime.of(2026, 11, 24, h, m), nextDay)
        assertEquals(LocalDateTime.of(2026, 11, 24, 4, 0), next(3, 59))
        assertEquals(LocalDateTime.of(2026, 11, 24, 12, 0), next(4, 0))
        assertEquals(LocalDateTime.of(2026, 11, 24, 19, 0), next(12, 0))
        assertEquals(nextDay, next(19, 0))
        assertEquals(LocalDateTime.of(2026, 11, 25, 4, 0), WidgetClock.nextUpdate(nextDay, nextDay))
    }

    @Test
    fun `a day start that is not midnight is honoured`() {
        val start = LocalDateTime.of(2026, 11, 25, 2, 30)
        assertEquals(start, WidgetClock.nextUpdate(LocalDateTime.of(2026, 11, 25, 1, 0), start))
    }
}

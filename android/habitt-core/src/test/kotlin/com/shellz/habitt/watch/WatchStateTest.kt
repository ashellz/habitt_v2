package com.shellz.habitt.watch

import com.shellz.habitt.widgets.DayBlock
import com.shellz.habitt.widgets.HabitLog
import com.shellz.habitt.widgets.StreakInfo
import com.shellz.habitt.widgets.WidgetHabit
import com.shellz.habitt.widgets.WidgetSnapshot
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDateTime

// Mirrors ios/HabittWidgetsCore/Tests/.../WatchStateTests.swift.
class WatchStateTest {

    private val day = "2026-11-25"

    private fun habit(
        id: Long,
        kind: HabitLog.Kind?,
        target: Int = 0,
        value: Int = 0,
        unit: String = "",
        state: WidgetHabit.State = WidgetHabit.State.TODO,
        optional: Boolean = false,
    ) = WidgetHabit(
        id = id,
        emoji = "📖",
        name = "H$id",
        category = 1,
        optional = optional,
        progress = if (target > 0) minOf(value.toDouble() / target, 1.0) else if (state == WidgetHabit.State.DONE) 1.0 else 0.0,
        progressText = "",
        state = state,
        log = HabitLog(
            kind = kind,
            target = target,
            value = value,
            unit = unit,
            step = if (kind == HabitLog.Kind.DURATION) 60 else 1,
            watchLoggable = kind == HabitLog.Kind.AMOUNT || kind == HabitLog.Kind.DURATION,
        ),
    )

    private fun block(habits: List<WidgetHabit>): DayBlock {
        val counted = habits.filter { !it.optional }
        return DayBlock(
            habits = habits,
            ring = counted.map { it.id },
            done = counted.count { it.isDone },
            total = counted.size,
            perfect = false,
            streak = StreakInfo(0, StreakInfo.Health.DORMANT, false, "", emptyList()),
            upNext = emptyMap(),
        )
    }

    private fun action(type: WatchAction.Type, habitId: Long, value: Int? = null, id: String = "id-$habitId-$value-$type") =
        WatchAction.create(type, habitId, day, value, LocalDateTime.of(2026, 11, 25, 8, 0), id)

    @Test
    fun `complete a simple habit`() {
        val b = WatchOverlay.apply(block(listOf(habit(1, null))), day, listOf(action(WatchAction.Type.COMPLETE, 1)))
        assertEquals(WidgetHabit.State.DONE, b.habits[0].state)
        assertTrue(b.habits[0].completed)
        assertEquals(1, b.done)
        assertTrue(b.perfect)
    }

    @Test
    fun `uncomplete resets the value`() {
        val read = habit(1, HabitLog.Kind.AMOUNT, target = 10, value = 10, unit = "pages", state = WidgetHabit.State.DONE)
        val b = WatchOverlay.apply(block(listOf(read)), day, listOf(action(WatchAction.Type.UNCOMPLETE, 1)))
        assertEquals(WidgetHabit.State.TODO, b.habits[0].state)
        assertEquals(0, b.habits[0].log.value)
        assertEquals("10 pages", b.habits[0].progressText)
        assertEquals(0, b.done)
    }

    @Test
    fun `set amount partial and reaching the target`() {
        val read = habit(1, HabitLog.Kind.AMOUNT, target = 10, value = 3, unit = "pages")
        val partial = WatchOverlay.apply(block(listOf(read)), day, listOf(action(WatchAction.Type.SET_AMOUNT, 1, 8)))
        assertEquals(WidgetHabit.State.PARTIAL, partial.habits[0].state)
        assertEquals(0.8, partial.habits[0].progress, 0.0001)
        assertEquals("8 / 10 pages", partial.habits[0].progressText)

        val done = WatchOverlay.apply(
            block(listOf(read)),
            day,
            listOf(action(WatchAction.Type.SET_AMOUNT, 1, 8), action(WatchAction.Type.SET_AMOUNT, 1, 10)),
        )
        assertEquals(WidgetHabit.State.DONE, done.habits[0].state)
        assertTrue(done.habits[0].completed)
        assertEquals("10 pages", done.habits[0].progressText)
    }

    @Test
    fun `set duration text`() {
        val meditate = habit(1, HabitLog.Kind.DURATION, target = 600)
        val b = WatchOverlay.apply(block(listOf(meditate)), day, listOf(action(WatchAction.Type.SET_DURATION, 1, 360)))
        assertEquals("6m / 10m", b.habits[0].progressText)
        assertEquals("1h5m", WatchOverlay.durationString(3900))
        assertEquals("0m", WatchOverlay.durationString(0))
        assertEquals("30s", WatchOverlay.durationString(30))
    }

    @Test
    fun `optional habit is not counted`() {
        val b = WatchOverlay.apply(
            block(listOf(habit(1, null), habit(2, null, optional = true))),
            day,
            listOf(action(WatchAction.Type.COMPLETE, 2)),
        )
        assertEquals(0, b.done)
        assertEquals(1, b.total)
        assertEquals(WidgetHabit.State.DONE, b.habits[1].state)
    }

    @Test
    fun `actions for another day are ignored`() {
        val other = action(WatchAction.Type.COMPLETE, 1).copy(day = "2026-11-24")
        val b = WatchOverlay.apply(block(listOf(habit(1, null))), day, listOf(other))
        assertEquals(WidgetHabit.State.TODO, b.habits[0].state)
    }

    @Test
    fun `prune drops acked actions and other days`() {
        val s = WidgetSnapshot.parse(
            """{ "v": 1, "dayKey": "2026-11-25", "nextDayStartsAt": "2026-11-26T00:00:00.000",
                 "today": {}, "tomorrow": {}, "watchAcks": ["done-1"] }""",
        )!!
        val old = action(WatchAction.Type.COMPLETE, 3, id = "old").copy(day = "2026-11-24")
        val outbox = listOf(action(WatchAction.Type.COMPLETE, 1, id = "done-1"), action(WatchAction.Type.COMPLETE, 2, id = "pending"), old)
        val shown = s.shownDayKey(LocalDateTime.of(2026, 11, 25, 10, 0))
        assertEquals("2026-11-25", shown)
        assertEquals(listOf("pending"), WatchOverlay.prune(outbox, s, shown).map { it.id })
    }

    @Test
    fun `shown day rolls over`() {
        val s = WidgetSnapshot.parse(
            """{ "v": 1, "dayKey": "2026-11-25", "nextDayStartsAt": "2026-11-26T00:00:00.000", "today": {}, "tomorrow": {} }""",
        )!!
        assertEquals("2026-11-26", s.shownDayKey(LocalDateTime.of(2026, 11, 26, 0, 30)))
    }

    @Test
    fun `action message matches the Apple Watch's`() {
        val a = WatchAction.create(
            WatchAction.Type.SET_AMOUNT, 1_795_574_050_137_094L, day, 8, LocalDateTime.of(2026, 11, 25, 8, 31, 2), "x",
        )
        val m = JSONObject(a.message()).getJSONObject("watchAction")
        assertEquals(1, m.getInt("v"))
        assertEquals("setAmount", m.getString("type"))
        assertEquals(1_795_574_050_137_094L, m.getLong("habitId"))
        assertEquals(8, m.getInt("value"))
        assertEquals("2026-11-25T08:31:02.000", m.getString("at"))
        val plain = JSONObject(WatchAction.create(WatchAction.Type.COMPLETE, 1, day).message()).getJSONObject("watchAction")
        assertFalse(plain.has("value"))
    }

    @Test
    fun `actions round-trip through JSON`() {
        val a = action(WatchAction.Type.SET_DURATION, 7, 480)
        assertEquals(a, WatchAction.fromJson(a.toJson()))
        assertNull(WatchAction.fromJson(JSONObject("""{"v":1,"id":"x","type":"teleport","habitId":1,"day":"2026-11-25"}""")))
    }
}

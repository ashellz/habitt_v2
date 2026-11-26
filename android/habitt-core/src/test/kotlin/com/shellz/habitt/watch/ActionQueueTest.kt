package com.shellz.habitt.watch

import org.json.JSONArray
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test
import java.time.LocalDateTime

class ActionQueueTest {

    private fun message(id: String) =
        WatchAction.create(WatchAction.Type.COMPLETE, 1, "2026-11-25", now = LocalDateTime.of(2026, 11, 25, 8, 0), id = id).message()

    private fun ids(queue: String?) = JSONArray(queue ?: "[]").let { a -> (0 until a.length()).map { a.getJSONObject(it).getString("id") } }

    @Test
    fun `reads the action of a message`() {
        val a = ActionQueue.actionOf(message("a"))
        assertNotNull(a)
        assertEquals("complete", a!!.getString("type"))
        assertNull(ActionQueue.actionOf("""{"snapshot": "{}"}"""))
        assertNull(ActionQueue.actionOf("""{"watchAction": {"type": "complete"}}"""))
        assertNull(ActionQueue.actionOf("not json"))
    }

    @Test
    fun `appends and dedupes by id`() {
        val q1 = ActionQueue.append(null, ActionQueue.actionOf(message("a"))!!)
        val q2 = ActionQueue.append(q1, ActionQueue.actionOf(message("b"))!!)
        assertEquals(listOf("a", "b"), ids(q2))
        assertNull(ActionQueue.append(q2, ActionQueue.actionOf(message("a"))!!))
    }

    @Test
    fun `keeps fields it does not know`() {
        val a = ActionQueue.actionOf("""{"watchAction": {"v": 2, "id": "x", "type": "teleport", "extra": true}}""")!!
        val q = JSONArray(ActionQueue.append("[]", a)).getJSONObject(0)
        assertEquals(2, q.getInt("v"))
        assertEquals(true, q.getBoolean("extra"))
    }

    @Test
    fun `drops the oldest beyond the cap`() {
        var q: String? = null
        for (i in 0..ActionQueue.MAX) q = ActionQueue.append(q, ActionQueue.actionOf(message("id$i"))!!)
        val list = ids(q)
        assertEquals(ActionQueue.MAX, list.size)
        assertEquals("id1", list.first())
    }

    @Test
    fun `removes only the given ids`() {
        var q: String? = null
        for (id in listOf("a", "b", "c")) q = ActionQueue.append(q, ActionQueue.actionOf(message(id))!!)
        assertEquals(listOf("b"), ids(ActionQueue.remove(q, setOf("a", "c", "zzz"))))
        assertEquals(emptyList<String>(), ids(ActionQueue.remove(null, setOf("a"))))
    }
}

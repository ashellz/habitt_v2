package com.shellz.habitt.watch

import org.json.JSONArray
import org.json.JSONObject

/**
 * The phone's durable queue of received watch actions, as a JSON array string
 * (docs/watch_app.md). Android's `WearBridge` stores it and owns every change;
 * Dart only reads it (`peekActions`) and removes applied ids (`removeActions`),
 * like `WatchBridge.swift` on iOS. Pure functions so they are JVM tested.
 */
object ActionQueue {
    /** Older entries are dropped beyond this many (a watch can't produce more). */
    const val MAX = 500

    /**
     * The action object of a watch message (`{"watchAction": {…, "id": …}}`),
     * or null when it isn't one. Unknown fields and newer versions are kept
     * as they are: Dart decides what it can apply.
     */
    fun actionOf(message: String): JSONObject? = try {
        JSONObject(message).optJSONObject("watchAction")?.takeIf { it.optString("id").isNotEmpty() }
    } catch (e: Exception) {
        null
    }

    /** [queue] with [action] appended, or null when an action with its id is already queued. */
    fun append(queue: String?, action: JSONObject): String? {
        val list = parse(queue)
        val id = action.optString("id")
        if (list.any { it.optString("id") == id }) return null
        list += action
        return serialize(list.takeLast(MAX))
    }

    /** [queue] without the actions whose id is in [ids]. */
    fun remove(queue: String?, ids: Set<String>): String = serialize(parse(queue).filter { it.optString("id") !in ids })

    private fun parse(queue: String?): MutableList<JSONObject> {
        if (queue.isNullOrBlank()) return mutableListOf()
        return try {
            val a = JSONArray(queue)
            (0 until a.length()).mapNotNull { a.optJSONObject(it) }.toMutableList()
        } catch (e: Exception) {
            mutableListOf()
        }
    }

    private fun serialize(list: List<JSONObject>): String = JSONArray().apply { list.forEach { put(it) } }.toString()
}

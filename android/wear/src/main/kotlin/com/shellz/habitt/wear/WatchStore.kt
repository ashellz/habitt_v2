package com.shellz.habitt.wear

import android.content.Context
import android.net.Uri
import android.util.Log
import com.google.android.gms.wearable.CapabilityClient
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.PutDataRequest
import com.google.android.gms.wearable.Wearable
import com.shellz.habitt.watch.WatchAction
import com.shellz.habitt.watch.WatchOverlay
import com.shellz.habitt.widgets.DayBlock
import com.shellz.habitt.widgets.WidgetHabit
import com.shellz.habitt.widgets.WidgetSnapshot
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withTimeout
import org.json.JSONArray
import org.json.JSONObject
import java.time.Duration
import java.time.LocalDateTime

/**
 * The Wear OS app's state (docs/watch_app.md), the twin of the watchOS
 * `WatchStore`: the last snapshot the phone sent, and the changes made here
 * that the phone hasn't confirmed yet. All habit logic stays on the phone;
 * this only draws, overlays and sends.
 */
class WatchStore private constructor(context: Context) {

    data class State(
        val snapshot: WidgetSnapshot? = null,
        /** The phone sent a snapshot newer than this app understands. */
        val updateNeeded: Boolean = false,
        val outbox: List<WatchAction> = emptyList(),
        /** Moves forward on start and at the day boundary, so the day rolls over without the phone. */
        val now: LocalDateTime = LocalDateTime.now(),
    ) {
        val shownDay: String? get() = snapshot?.shownDayKey(now)

        /** The day block at [now], with this watch's unconfirmed changes on top. */
        val block: DayBlock?
            get() {
                val s = snapshot ?: return null
                return WatchOverlay.apply(s.blockAt(now), s.shownDayKey(now), outbox)
            }

        val accent: Int get() = snapshot?.accentDark ?: WidgetSnapshot.DEFAULT_ACCENT_DARK
    }

    private val app = context.applicationContext
    private val prefs = app.getSharedPreferences("habitt_watch", Context.MODE_PRIVATE)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val dataClient by lazy { Wearable.getDataClient(app) }

    private val _state = MutableStateFlow(State())
    val state: StateFlow<State> = _state

    /** Actions that were also written as fallback Data Layer items (deleted once pruned). */
    private var fallbackIds: Set<String> = prefs.getStringSet(FALLBACK_KEY, emptySet()) ?: emptySet()
    private var dayTimer: Job? = null
    private var started = 0

    private val listener = DataClient.OnDataChangedListener { events ->
        for (event in events) {
            if (event.type != DataEvent.TYPE_CHANGED || event.dataItem.uri.path != SNAPSHOT_PATH) continue
            DataMapItem.fromDataItem(event.dataItem).dataMap.getString("snapshot")?.let { receive(it) }
        }
    }

    init {
        val snapshot = WidgetSnapshot.parse(prefs.getString(SNAPSHOT_KEY, null))
        val outbox = prefs.getString(OUTBOX_KEY, null)?.let { raw ->
            try {
                val a = JSONArray(raw)
                (0 until a.length()).mapNotNull { WatchAction.fromJson(a.optJSONObject(it)) }
            } catch (e: Exception) {
                emptyList()
            }
        } ?: emptyList()
        _state.value = State(snapshot = snapshot, outbox = outbox)
        refreshClock()
    }

    // ─── Lifecycle ────────────────────────────────────────

    /** Store screenshots only (debug builds, docs/watch_app.md): a fixed snapshot, no phone. */
    private var screenshotMode = false

    fun showScreenshot(json: String) {
        screenshotMode = true
        _state.value = State(snapshot = WidgetSnapshot.parse(json))
        refreshClock()
    }

    /** While the app is visible: follow the phone's snapshot. */
    fun start() {
        if (screenshotMode) return
        if (started++ == 0) {
            try {
                dataClient.addListener(listener)
            } catch (e: Exception) {
                Log.d(TAG, "listening to the Data Layer failed: $e")
            }
        }
        loadCurrentSnapshot()
        refreshClock()
    }

    fun stop() {
        if (--started > 0) return
        started = 0
        try {
            dataClient.removeListener(listener)
        } catch (e: Exception) {
            // nothing to undo
        }
    }

    /** The phone's current snapshot item, the way `receivedApplicationContext` works on iOS. */
    private fun loadCurrentSnapshot() {
        scope.launch {
            try {
                val items = dataClient.getDataItems(itemUri(SNAPSHOT_PATH)).await()
                val json = items.firstOrNull()?.let { DataMapItem.fromDataItem(it).dataMap.getString("snapshot") }
                items.release()
                json?.let { receive(it) }
            } catch (e: Exception) {
                Log.d(TAG, "reading the snapshot failed: $e")
            }
        }
    }

    // ─── Snapshot ─────────────────────────────────────────

    private fun receive(json: String) {
        val v = WidgetSnapshot.peekVersion(json)
        if (v != null && v > WidgetSnapshot.VERSION) {
            _state.update { it.copy(updateNeeded = true) }
            return
        }
        val snapshot = WidgetSnapshot.parse(json) ?: return
        prefs.edit().putString(SNAPSHOT_KEY, json).apply()
        _state.update { it.copy(snapshot = snapshot, updateNeeded = false) }
        refreshClock()
    }

    /** Re-reads the clock, drops confirmed or stale changes and arms a timer for the next day boundary. */
    fun refreshClock() {
        val now = LocalDateTime.now()
        _state.update { it.copy(now = now) }
        val s = _state.value
        val snapshot = s.snapshot
        val day = s.shownDay
        if (snapshot != null && day != null) {
            val pruned = WatchOverlay.prune(s.outbox, snapshot, day)
            if (pruned != s.outbox) {
                val gone = s.outbox.map { it.id }.toSet() - pruned.map { it.id }.toSet()
                _state.update { it.copy(outbox = pruned) }
                saveOutbox()
                deleteFallbacks(gone)
            }
        }
        dayTimer?.cancel()
        val next = snapshot?.nextDayStartsAt
        if (next != null && next.isAfter(now) && next != LocalDateTime.MAX) {
            dayTimer = scope.launch {
                delay(Duration.between(now, next).toMillis() + 1000)
                refreshClock()
            }
        }
    }

    // ─── Actions ──────────────────────────────────────────

    /** The check: completes a habit that isn't done, un-completes one that is. True when it completed. */
    fun toggle(habit: WidgetHabit): Boolean {
        val day = _state.value.shownDay ?: return false
        if (habit.watchReadOnly) return false
        val completing = !habit.isDone
        send(WatchAction.create(if (completing) WatchAction.Type.COMPLETE else WatchAction.Type.UNCOMPLETE, habit.id, day))
        return completing
    }

    /** Logs an absolute amount (count) or duration (seconds). True when it reached the target. */
    fun setValue(value: Int, habit: WidgetHabit): Boolean {
        val day = _state.value.shownDay ?: return false
        if (!habit.log.watchLoggable) return false
        val type = if (habit.log.kind == com.shellz.habitt.widgets.HabitLog.Kind.DURATION) {
            WatchAction.Type.SET_DURATION
        } else {
            WatchAction.Type.SET_AMOUNT
        }
        send(WatchAction.create(type, habit.id, day, maxOf(value, 0)))
        return !habit.isDone && habit.log.target > 0 && value >= habit.log.target
    }

    private fun send(action: WatchAction) {
        _state.update { it.copy(outbox = (it.outbox + action).takeLast(WatchOverlay.MAX_OUTBOX)) }
        saveOutbox()
        scope.launch { transmit(action) }
    }

    /**
     * A request to the phone, which answers once the action is in its durable
     * queue; without an answer, a Data Layer item the system delivers once
     * the devices reconnect. Nothing else is ever resent.
     */
    private suspend fun transmit(action: WatchAction) {
        val message = action.message()
        val queued = try {
            val nodes = Wearable.getCapabilityClient(app)
                .getCapability(PHONE_CAPABILITY, CapabilityClient.FILTER_REACHABLE).await().nodes
            val node = nodes.firstOrNull { it.isNearby } ?: nodes.firstOrNull()
            if (node == null) {
                false
            } else {
                val reply = withTimeout(REQUEST_TIMEOUT_MS) {
                    Wearable.getMessageClient(app).sendRequest(node.id, ACTION_PATH, message.toByteArray()).await()
                }
                JSONObject(String(reply)).optBoolean("queued", false)
            }
        } catch (e: Exception) {
            Log.d(TAG, "request failed, falling back to a data item: $e")
            false
        }
        if (queued) return
        try {
            val request = PutDataMapRequest.create(ACTION_ITEM_PREFIX + action.id).apply {
                dataMap.putString("action", message)
            }.asPutDataRequest().setUrgent()
            dataClient.putDataItem(request).await()
            fallbackIds = fallbackIds + action.id
            prefs.edit().putStringSet(FALLBACK_KEY, fallbackIds).apply()
        } catch (e: Exception) {
            Log.w(TAG, "putting the action item failed: $e")
        }
    }

    /** Deletes the fallback items of actions that left the outbox. */
    private fun deleteFallbacks(ids: Set<String>) {
        val mine = ids intersect fallbackIds
        if (mine.isEmpty()) return
        fallbackIds = fallbackIds - mine
        prefs.edit().putStringSet(FALLBACK_KEY, fallbackIds).apply()
        for (id in mine) {
            try {
                dataClient.deleteDataItems(itemUri(ACTION_ITEM_PREFIX + id))
            } catch (e: Exception) {
                // the phone deletes it too once queued
            }
        }
    }

    private fun saveOutbox() {
        val a = JSONArray()
        _state.value.outbox.forEach { a.put(it.toJson()) }
        prefs.edit().putString(OUTBOX_KEY, a.toString()).apply()
    }

    companion object {
        private const val TAG = "WATCH"
        const val SNAPSHOT_PATH = "/habitt/snapshot"
        const val ACTION_PATH = "/habitt/action"
        const val ACTION_ITEM_PREFIX = "/habitt/action/"
        const val PHONE_CAPABILITY = "habitt_phone"
        private const val REQUEST_TIMEOUT_MS = 5_000L

        private const val SNAPSHOT_KEY = "habitt_watch_snapshot"
        private const val OUTBOX_KEY = "habitt_watch_outbox"
        private const val FALLBACK_KEY = "habitt_watch_fallbacks"

        /** `wear:/path`: no host, so it matches the item whichever node wrote it. */
        private fun itemUri(path: String): Uri = Uri.Builder().scheme(PutDataRequest.WEAR_URI_SCHEME).path(path).build()

        @Volatile private var instance: WatchStore? = null

        fun get(context: Context): WatchStore =
            instance ?: synchronized(this) { instance ?: WatchStore(context).also { instance = it } }
    }
}

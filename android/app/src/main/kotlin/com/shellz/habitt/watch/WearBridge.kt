package com.shellz.habitt.watch

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataItem
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

// The Android phone side of the Wear OS app (docs/watch_app.md), the twin of
// ios/Runner/WatchBridge.swift.
//
// Phone → watch: Dart calls `habitt/watch#pushSnapshot(json)` whenever it
// writes the widget snapshot; it becomes the urgent Data Layer item
// /habitt/snapshot (latest wins, synced whenever the watch connects).
//
// Watch → phone: actions arrive as requests or fallback Data Layer items
// (WearActionListenerService). Each one is appended to a durable queue FIRST
// (SharedPreferences, committed), then Dart is told (`actionsAvailable`) if
// its engine is running. Dart reads and removes entries only through this
// bridge (`peekActions` / `removeActions`), under one lock, so an append can
// never be lost to a concurrent removal. When the app isn't running, the
// actions wait for the next start. Each drain also sweeps fallback items whose
// change event was missed (the app was being installed or updated).
object WearBridge {
    const val SNAPSHOT_PATH = "/habitt/snapshot"
    const val ACTION_PATH = "/habitt/action"
    /** Fallback items: `/habitt/action/<id>`, data key [ACTION_KEY]. */
    const val ACTION_ITEM_PREFIX = "/habitt/action/"
    const val ACTION_KEY = "action"

    private const val TAG = "WATCH"
    private const val PREFS = "habitt_watch"
    private const val QUEUE_KEY = "habitt_watch_pending_actions"
    private const val LAST_SNAPSHOT_KEY = "habitt_watch_last_snapshot"

    private val lock = Any()
    private val main = Handler(Looper.getMainLooper())

    @Volatile private var channel: MethodChannel? = null
    private var messenger: BinaryMessenger? = null
    /** The last push failed (e.g. no Play services yet): retried on the next drain. */
    @Volatile private var pushFailed = false

    /** Wires the `habitt/watch` channel to a Flutter engine. */
    fun register(context: Context, messenger: BinaryMessenger) {
        val app = context.applicationContext
        val channel = MethodChannel(messenger, "habitt/watch")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "pushSnapshot" -> {
                    (call.arguments as? String)?.let { pushSnapshot(app, it) }
                    result.success(null)
                }
                "peekActions" -> {
                    if (pushFailed) resendLastSnapshot(app)
                    sweepActionItems(app) { result.success(queue(app)) }
                }
                "removeActions" -> {
                    @Suppress("UNCHECKED_CAST")
                    remove(app, ((call.arguments as? List<Any?>) ?: emptyList()).filterIsInstance<String>().toSet())
                    result.success(null)
                }
                // iOS ends a background task here; Android needs nothing
                "drainDone" -> result.success(null)
                else -> result.notImplemented()
            }
        }
        this.channel = channel
        this.messenger = messenger
        // anything that arrived before Dart listened is drained on start anyway
    }

    /** Unwires the channel, if it still belongs to [messenger] (a newer activity may own it). */
    fun unregister(messenger: BinaryMessenger) {
        if (this.messenger !== messenger) return
        channel?.setMethodCallHandler(null)
        channel = null
        this.messenger = null
    }

    // ─── Phone → watch ────────────────────────────────────

    fun pushSnapshot(context: Context, json: String) {
        prefs(context).edit().putString(LAST_SNAPSHOT_KEY, json).apply()
        try {
            val request = PutDataMapRequest.create(SNAPSHOT_PATH).apply {
                dataMap.putString("snapshot", json)
            }.asPutDataRequest().setUrgent()
            Wearable.getDataClient(context).putDataItem(request)
                .addOnSuccessListener { pushFailed = false }
                .addOnFailureListener { e ->
                    // no Play services or no Wear OS app: nothing to sync to
                    if (!pushFailed) Log.d(TAG, "putting the snapshot failed: $e")
                    pushFailed = true
                }
        } catch (e: Exception) {
            pushFailed = true
            Log.d(TAG, "putting the snapshot failed: $e")
        }
    }

    private fun resendLastSnapshot(context: Context) {
        prefs(context).getString(LAST_SNAPSHOT_KEY, null)?.let { pushSnapshot(context, it) }
    }

    // ─── Watch → phone ────────────────────────────────────

    /**
     * Queues the action in [message] (`{"watchAction": {…}}`) durably, then
     * tells Dart. True when it is queued, now or before (a redelivery).
     */
    fun receive(context: Context, message: String): Boolean {
        val action = ActionQueue.actionOf(message) ?: return false
        val added = synchronized(lock) {
            val prefs = prefs(context)
            val next = ActionQueue.append(prefs.getString(QUEUE_KEY, null), action) ?: return@synchronized false
            prefs.edit().putString(QUEUE_KEY, next).commit()
        }
        if (added) main.post { channel?.invokeMethod("actionsAvailable", null) }
        return true
    }

    /**
     * Queues a fallback item's action, then deletes the item (also when it
     * can't be read: it has done its job). Ignores other paths.
     */
    fun receiveItem(context: Context, item: DataItem) {
        if (item.uri.path?.startsWith(ACTION_ITEM_PREFIX) != true) return
        val message = DataMapItem.fromDataItem(item).dataMap.getString(ACTION_KEY)
        val queued = message != null && receive(context, message)
        if (queued || message == null) Wearable.getDataClient(context).deleteDataItems(item.uri)
    }

    /** Queues fallback items still on the phone, then runs [done] on the main thread. */
    private fun sweepActionItems(context: Context, done: () -> Unit) {
        try {
            val uri = Uri.Builder().scheme("wear").path(ACTION_ITEM_PREFIX).build()
            Wearable.getDataClient(context).getDataItems(uri, DataClient.FILTER_PREFIX)
                .addOnSuccessListener { buffer ->
                    try {
                        buffer.forEach { receiveItem(context, it) }
                    } finally {
                        buffer.release()
                    }
                    done()
                }
                .addOnFailureListener { done() }
        } catch (e: Exception) {
            done()
        }
    }

    private fun queue(context: Context): String = synchronized(lock) {
        prefs(context).getString(QUEUE_KEY, null) ?: "[]"
    }

    private fun remove(context: Context, ids: Set<String>) {
        if (ids.isEmpty()) return
        synchronized(lock) {
            val prefs = prefs(context)
            prefs.edit().putString(QUEUE_KEY, ActionQueue.remove(prefs.getString(QUEUE_KEY, null), ids)).commit()
        }
    }

    private fun prefs(context: Context) = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}

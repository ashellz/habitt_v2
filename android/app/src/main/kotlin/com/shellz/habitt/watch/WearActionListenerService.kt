package com.shellz.habitt.watch

import com.google.android.gms.tasks.Task
import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.WearableListenerService
import org.json.JSONObject

/**
 * Receives Wear OS actions (docs/watch_app.md), also when the app isn't
 * running: the system starts this service for the paths in the manifest.
 * Requests are queued and then answered, so the watch knows the action is
 * safe; fallback items are queued and then deleted.
 */
class WearActionListenerService : WearableListenerService() {

    override fun onRequest(nodeId: String, path: String, request: ByteArray): Task<ByteArray>? {
        if (path != WearBridge.ACTION_PATH) return null
        val queued = WearBridge.receive(applicationContext, String(request, Charsets.UTF_8))
        return Tasks.forResult(JSONObject().put("queued", queued).toString().toByteArray(Charsets.UTF_8))
    }

    override fun onDataChanged(events: DataEventBuffer) {
        for (event in events) {
            if (event.type == DataEvent.TYPE_CHANGED) WearBridge.receiveItem(applicationContext, event.dataItem)
        }
    }
}

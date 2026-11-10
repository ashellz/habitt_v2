package com.shellz.habitt

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log

/**
 * Plays a habit alarm: the alarm ringtone on the alarm audio stream (rings in
 * silent / vibrate mode) plus vibration, until the alarm's notification
 * (posted by awesome_notifications with the same id) is gone. Every way of
 * handling the alarm (Dismiss, Complete, the full-screen page, cancelling a
 * completed habit's reminder) removes that notification, so watching it is
 * what stops the sound. See docs/habit_alarms.md.
 */
class HabitAlarmRingService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private var player: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var focusRequest: AudioFocusRequest? = null
    private var startedAt = 0L

    // alarm id -> whether its notification has been seen yet
    private val watched = mutableMapOf<Int, Boolean>()

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopRinging()
            return START_NOT_STICKY
        }
        val id = intent?.getIntExtra(HabitAlarmScheduler.EXTRA_ID, -1) ?: -1
        val title = intent?.getStringExtra(HabitAlarmScheduler.EXTRA_TITLE) ?: ""

        // Must be called right away after startForegroundService.
        startInForeground(title)
        if (id == -1) {
            stopRinging()
            return START_NOT_STICKY
        }

        watched[id] = false
        startedAt = System.currentTimeMillis()
        if (player == null) startSound()
        handler.removeCallbacks(watchTick)
        handler.postDelayed(watchTick, WATCH_INTERVAL_MS)
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        releaseSound()
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    // ─── Watching the alarm notification ──────────────────

    private val watchTick = object : Runnable {
        override fun run() {
            val active = activeNotificationIds()
            val now = System.currentTimeMillis()
            for (id in watched.keys.toList()) {
                if (id in active) {
                    watched[id] = true
                } else if (watched[id] == true || now - startedAt > APPEAR_TIMEOUT_MS) {
                    // handled, or its notification never showed up
                    watched.remove(id)
                }
            }
            if (watched.isEmpty() || now - startedAt > MAX_RING_MS) {
                stopRinging()
                return
            }
            handler.postDelayed(this, WATCH_INTERVAL_MS)
        }
    }

    private fun activeNotificationIds(): Set<Int> = try {
        getSystemService(NotificationManager::class.java)
            .activeNotifications
            .map { it.id }
            .toSet()
    } catch (e: Exception) {
        emptySet()
    }

    private fun stopRinging() {
        handler.removeCallbacksAndMessages(null)
        watched.clear()
        releaseSound()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    // ─── Sound & vibration ────────────────────────────────

    private fun startSound() {
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        val audio = getSystemService(AudioManager::class.java)
        focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
            .setAudioAttributes(attributes)
            .build()
            .also { audio.requestAudioFocus(it) }

        val uri = alarmSoundUri()
        if (uri != null) {
            try {
                player = MediaPlayer().apply {
                    setAudioAttributes(attributes)
                    setDataSource(this@HabitAlarmRingService, uri)
                    setWakeMode(this@HabitAlarmRingService, PowerManager.PARTIAL_WAKE_LOCK)
                    isLooping = true
                    prepare()
                    start()
                }
            } catch (e: Exception) {
                Log.w(TAG, "could not play alarm sound", e)
                player?.release()
                player = null
            }
        }
        startVibration()
    }

    private fun alarmSoundUri(): Uri? =
        listOf(
            RingtoneManager.TYPE_ALARM,
            RingtoneManager.TYPE_RINGTONE,
            RingtoneManager.TYPE_NOTIFICATION,
        ).firstNotNullOfOrNull { RingtoneManager.getActualDefaultRingtoneUri(this, it) }
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)

    private fun startVibration() {
        val vib = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Vibrator::class.java)
        }
        if (vib == null || !vib.hasVibrator()) return
        vibrator = vib
        val effect = VibrationEffect.createWaveform(longArrayOf(0, 800, 800), 0)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            vib.vibrate(effect, VibrationAttributes.createForUsage(VibrationAttributes.USAGE_ALARM))
        } else {
            @Suppress("DEPRECATION")
            vib.vibrate(
                effect,
                AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).build(),
            )
        }
    }

    private fun releaseSound() {
        try {
            player?.stop()
        } catch (_: Exception) {
        }
        player?.release()
        player = null
        vibrator?.cancel()
        vibrator = null
        focusRequest?.let { getSystemService(AudioManager::class.java).abandonAudioFocusRequest(it) }
        focusRequest = null
    }

    // ─── Foreground notification ──────────────────────────
    // A foreground service needs its own notification. It's kept quiet (the
    // real alarm notification is awesome_notifications'), with a button that
    // only silences the sound.

    private fun startInForeground(title: String) {
        val manager = getSystemService(NotificationManager::class.java)
        val labels = HabitAlarmScheduler.labels(this)
        manager.createNotificationChannel(
            NotificationChannel(
                RING_CHANNEL_ID,
                labels.channelName,
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                setSound(null, null)
                enableVibration(false)
                setShowBadge(false)
            }
        )

        val silence = PendingIntent.getService(
            this,
            0,
            Intent(this, HabitAlarmRingService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = Notification.Builder(this, RING_CHANNEL_ID)
            .setSmallIcon(R.drawable.res_notification_icon)
            .setContentTitle(title.ifEmpty { labels.channelName })
            .setCategory(Notification.CATEGORY_ALARM)
            .setOngoing(true)
            .setContentIntent(open)
            .addAction(Notification.Action.Builder(null, labels.silence, silence).build())
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                RING_NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
            )
        } else {
            startForeground(RING_NOTIFICATION_ID, notification)
        }
    }

    companion object {
        private const val TAG = "HabitAlarm"
        private const val ACTION_STOP = "com.shellz.habitt.HABIT_ALARM_STOP"
        private const val RING_CHANNEL_ID = "habit_alarm_ringing"
        // outside the habit-reminder id range (1000000000-1899999999)
        private const val RING_NOTIFICATION_ID = 1999999001

        private const val WATCH_INTERVAL_MS = 1_000L
        // how long to wait for the alarm notification to be posted
        private const val APPEAR_TIMEOUT_MS = 60_000L
        // stop the sound eventually even if nobody answers (the notification stays)
        private const val MAX_RING_MS = 10 * 60_000L

        fun startIntent(context: Context, id: Int, title: String): Intent =
            Intent(context, HabitAlarmRingService::class.java)
                .putExtra(HabitAlarmScheduler.EXTRA_ID, id)
                .putExtra(HabitAlarmScheduler.EXTRA_TITLE, title)

        /** Silences a ringing alarm (no-op when nothing rings). */
        fun stop(context: Context) {
            context.stopService(Intent(context, HabitAlarmRingService::class.java))
        }
    }
}

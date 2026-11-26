package com.shellz.habitt.wear

import android.content.pm.ApplicationInfo
import android.os.Bundle
import androidx.compose.runtime.LaunchedEffect
import java.io.File
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.wear.compose.material3.AppScaffold
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.TimeText
import androidx.wear.compose.navigation.SwipeDismissableNavHost
import androidx.wear.compose.navigation.composable
import androidx.wear.compose.navigation.rememberSwipeDismissableNavController
import com.shellz.habitt.wear.ui.LogScreen
import com.shellz.habitt.wear.ui.MessageKind
import com.shellz.habitt.wear.ui.MessageScreen
import com.shellz.habitt.wear.ui.ReadOnlyScreen
import com.shellz.habitt.wear.ui.TodayScreen
import com.shellz.habitt.wear.ui.WearText

/**
 * The Wear OS app (docs/watch_app.md), from the design canvas "Habitt Wear OS
 * App" (https://claude.ai/artifact/2fupC7jodFpxo4Yegahdo3).
 */
class MainActivity : ComponentActivity() {

    private val store by lazy { WatchStore.get(this) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val openHabit = screenshotSetup()
        setContent { WearApp(store, openHabit) }
    }

    /**
     * Store screenshots, debug builds only (docs/watch_app.md): extra
     * `screenshotSnapshot` names a snapshot file in the app's files dir,
     * `screenshotOpen` a habit whose screen opens. Returns that habit id.
     */
    private fun screenshotSetup(): Long? {
        if (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE == 0) return null
        val name = intent.getStringExtra("screenshotSnapshot") ?: return null
        val file = File(filesDir, name)
        if (!file.exists()) return null
        store.showScreenshot(file.readText())
        return intent.getStringExtra("screenshotOpen")?.toLongOrNull()
    }

    override fun onStart() {
        super.onStart()
        store.start()
    }

    override fun onResume() {
        super.onResume()
        store.refreshClock()
    }

    override fun onStop() {
        store.stop()
        super.onStop()
    }
}

@Composable
fun WearApp(store: WatchStore, openHabit: Long? = null) {
    val state by store.state.collectAsState()
    val context = LocalContext.current
    val text = remember(state.snapshot) { WearText(context, state.snapshot) }
    val accent = Color(state.accent)
    val nav = rememberSwipeDismissableNavController()
    LaunchedEffect(openHabit) { openHabit?.let { nav.navigate("habit/$it") } }

    MaterialTheme(colorScheme = MaterialTheme.colorScheme.copy(primary = accent)) {
        AppScaffold(timeText = { TimeText() }) {
            SwipeDismissableNavHost(navController = nav, startDestination = "today") {
                composable("today") {
                    TodayScreen(state, store, text) { id -> nav.navigate("habit/$id") }
                }
                composable("habit/{id}") { entry ->
                    val id = entry.arguments?.getString("id")?.toLongOrNull()
                    val habit = id?.let { state.block?.habit(it) }
                    when {
                        // the habit left today's list (deleted, paused, new day)
                        habit == null -> MessageScreen(MessageKind.EMPTY, text.today, null, accent)
                        habit.log.watchLoggable -> LogScreen(habit, accent, text, store)
                        else -> ReadOnlyScreen(habit, accent, text)
                    }
                }
            }
        }
    }
}

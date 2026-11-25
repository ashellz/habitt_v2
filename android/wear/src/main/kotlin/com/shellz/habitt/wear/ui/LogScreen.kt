package com.shellz.habitt.wear.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.rotary.onRotaryScrollEvent
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.Text
import com.shellz.habitt.wear.WatchStore
import com.shellz.habitt.watch.WatchOverlay
import com.shellz.habitt.widgets.HabitLog
import com.shellz.habitt.widgets.WidgetHabit
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.abs

/**
 * Logs an amount or a duration: the value in the middle, the ring along the
 * edge, −/+ and the crown or bezel in `step` increments (1, or a minute). One
 * absolute value is sent ~0.8 s after it settles, and when leaving.
 */
@Composable
fun LogScreen(habit: WidgetHabit, accent: Color, text: WearText, store: WatchStore) {
    val log = habit.log
    val step = log.step.coerceAtLeast(1)
    val isDuration = log.kind == HabitLog.Kind.DURATION
    // no practical cap, like the phone: a day (durations) or 9999 (amounts)
    val maxValue = maxOf(if (isDuration) 24 * 3600 else 9999, log.target)

    var value by remember(habit.id) { mutableIntStateOf(log.value) }
    var pending by remember { mutableStateOf<Job?>(null) }
    var rotary by remember { mutableFloatStateOf(0f) }
    val scope = rememberCoroutineScope()
    val view = LocalView.current
    val focus = remember { FocusRequester() }
    val latestHabit by rememberUpdatedState(habit)

    fun send(v: Int) {
        if (store.setValue(v, latestHabit)) view.confirmHaptic()
    }

    fun set(new: Int) {
        val clamped = new.coerceIn(0, maxValue)
        if (clamped == value) return
        value = clamped
        pending?.cancel()
        pending = scope.launch {
            delay(800)
            pending = null
            send(clamped)
        }
    }

    // the phone's value arrived (or another change): follow it unless editing
    LaunchedEffect(log.value) {
        if (pending == null && log.value != value) value = log.value
    }
    LaunchedEffect(Unit) { focus.requestFocus() }
    DisposableEffect(Unit) {
        onDispose {
            val job = pending ?: return@onDispose
            job.cancel()
            pending = null
            if (value != latestHabit.log.value) send(value)
        }
    }

    val progress = if (log.target > 0) minOf(value.toDouble() / log.target, 1.0) else 0.0
    val targetText = if (isDuration) {
        WatchOverlay.durationString(log.target)
    } else if (log.unit.isEmpty()) {
        "${log.target}"
    } else {
        "${log.target} ${log.unit}"
    }

    ScreenScaffold {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .onRotaryScrollEvent { event ->
                    // a crown sends small deltas (one step per ~40 px), a
                    // bezel or detent crown one big delta per click (one
                    // step per click, however big)
                    val delta = event.verticalScrollPixels
                    val steps = if (abs(delta) >= ROTARY_STEP_PX) {
                        if (delta > 0) 1 else -1
                    } else {
                        rotary += delta
                        (rotary / ROTARY_STEP_PX).toInt()
                    }
                    if (steps != 0) {
                        rotary = 0f
                        val before = value
                        set(value + steps * step)
                        if (value != before) view.tickHaptic()
                    }
                    true
                }
                .focusRequester(focus)
                .focusable(),
        ) {
            EdgeRing(progress, accent)
            Column(
                modifier = Modifier.fillMaxSize().padding(top = 36.dp, start = 30.dp, end = 30.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text(
                    "${habit.emoji} ${habit.name}",
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = accent,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                Spacer(Modifier.height(6.dp))
                ValueText(value, isDuration)
                Text(text.ofTarget(targetText), fontSize = 12.sp, color = WearColors.Secondary, maxLines = 1)
                Spacer(Modifier.height(12.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    StepButton(
                        label = if (isDuration) "−${step / 60}m" else "−",
                        description = text.less,
                        filled = false,
                        accent = accent,
                    ) { set(value - step) }
                    StepButton(
                        label = if (isDuration) "+${step / 60}m" else "+",
                        description = text.more,
                        filled = true,
                        accent = accent,
                    ) { set(value + step) }
                }
            }
        }
    }
}

private const val ROTARY_STEP_PX = 40f

@Composable
private fun ValueText(value: Int, isDuration: Boolean) {
    val big = 52.sp
    if (isDuration && value < 3600) {
        Text(
            buildAnnotatedString {
                append("${value / 60}")
                withStyle(SpanStyle(fontSize = 25.sp, fontWeight = FontWeight.SemiBold)) { append("m") }
            },
            fontSize = big,
            fontWeight = FontWeight.Bold,
            color = Color.White,
        )
    } else {
        Text(
            if (isDuration) WatchOverlay.durationString(value) else "$value",
            fontSize = if (isDuration) 36.sp else big,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            maxLines = 1,
        )
    }
}

@Composable
private fun StepButton(label: String, description: String, filled: Boolean, accent: Color, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .size(width = 64.dp, height = 40.dp)
            .clip(RoundedCornerShape(20.dp))
            .background(if (filled) accent else WearColors.Row)
            .clickable(role = Role.Button, onClick = onClick)
            .semantics { contentDescription = description },
        contentAlignment = Alignment.Center,
    ) {
        Text(
            label,
            fontSize = if (label.length > 1) 14.sp else 22.sp,
            fontWeight = FontWeight.Bold,
            color = if (filled) Color.Black else accent,
        )
    }
}

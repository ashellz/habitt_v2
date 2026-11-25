package com.shellz.habitt.wear.ui

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.items
import androidx.wear.compose.foundation.lazy.rememberScalingLazyListState
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.Text
import com.shellz.habitt.wear.WatchStore
import com.shellz.habitt.widgets.DayBlock
import com.shellz.habitt.widgets.WidgetHabit
import com.shellz.habitt.widgets.WidgetSnapshot

/** The app's first screen: today's list, or the state that replaces it. */
@Composable
fun TodayScreen(state: WatchStore.State, store: WatchStore, text: WearText, onOpen: (Long) -> Unit) {
    val snapshot = state.snapshot
    val block = state.block
    val accent = Color(state.accent)
    var showListWhenComplete by rememberSaveable { mutableStateOf(false) }
    LaunchedEffect(block?.perfect) {
        if (block?.perfect != true) showListWhenComplete = false
    }

    when {
        snapshot == null || block == null ->
            if (state.updateNeeded) {
                MessageScreen(MessageKind.UPDATE, text.updateNeeded, text.updateNeededBody, accent)
            } else {
                MessageScreen(MessageKind.OPEN_ON_PHONE, text.openOnPhone, text.openOnPhoneBody, accent)
            }
        !snapshot.hasHabits -> MessageScreen(MessageKind.EMPTY, snapshot.strings.noHabits, null, accent)
        block.habits.isEmpty() -> MessageScreen(MessageKind.EMPTY, snapshot.strings.nothingToday, null, accent)
        block.perfect && !showListWhenComplete ->
            DayCompleteScreen(snapshot, block, accent, text) { showListWhenComplete = true }
        else -> HabitList(snapshot, block, state.updateNeeded, accent, text, store, onOpen)
    }
}

// ─── List ─────────────────────────────────────────────────

@Composable
private fun HabitList(
    snapshot: WidgetSnapshot,
    block: DayBlock,
    updateNeeded: Boolean,
    accent: Color,
    text: WearText,
    store: WatchStore,
    onOpen: (Long) -> Unit,
) {
    // opens with the first section title in the middle, "Today" and the bar
    // above it at the top (centering "Today" leaves the top half empty)
    val listState = rememberScalingLazyListState(initialCenterItemIndex = if (updateNeeded) 3 else 2)
    val view = LocalView.current
    val sections = sections(block, text)

    ScreenScaffold(scrollState = listState) { contentPadding ->
        ScalingLazyColumn(
            state = listState,
            contentPadding = contentPadding,
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(5.dp),
        ) {
            item {
                Text(
                    text.today,
                    color = accent,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
            item { DayProgressBar(block.done, block.total, accent) }
            if (updateNeeded) {
                item {
                    Text(
                        text.updateNeededBody,
                        fontSize = 11.sp,
                        color = WearColors.Secondary,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 8.dp),
                    )
                }
            }
            for ((title, habits) in sections) {
                item {
                    Text(
                        title,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = WearColors.Secondary,
                        modifier = Modifier.fillMaxWidth().padding(start = 11.dp, top = 4.dp),
                    )
                }
                items(habits, key = { it.id }) { habit ->
                    HabitRow(
                        habit = habit,
                        accent = accent,
                        text = text,
                        onToggle = { if (store.toggle(habit)) view.confirmHaptic() },
                        onOpen = { onOpen(habit.id) },
                    )
                }
            }
        }
    }
}

/** Sections in the phone's order: Any time, Morning, Afternoon, Evening, then Optional. */
private fun sections(block: DayBlock, text: WearText): List<Pair<String, List<WidgetHabit>>> {
    val out = (1..4).mapNotNull { category ->
        val habits = block.habits.filter { !it.optional && it.category == category }
        if (habits.isEmpty()) null else text.part(category) to habits
    }.toMutableList()
    val optional = block.habits.filter { it.optional }
    if (optional.isNotEmpty()) out += text.optional to optional
    return out
}

@Composable
private fun DayProgressBar(done: Int, total: Int, accent: Color) {
    val fraction by animateFloatAsState(
        if (total > 0) done.toFloat() / total else 0f,
        tween(600),
        label = "dayProgress",
    )
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 22.dp, vertical = 2.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(7.dp),
    ) {
        Box(
            Modifier
                .weight(1f)
                .height(4.dp)
                .clip(RoundedCornerShape(2.dp))
                .background(WearColors.Track),
        ) {
            Box(
                Modifier
                    .fillMaxHeight()
                    .fillMaxWidth(fraction)
                    .clip(RoundedCornerShape(2.dp))
                    .background(accent),
            )
        }
        Text("$done/$total", fontSize = 11.sp, color = WearColors.Secondary)
    }
}

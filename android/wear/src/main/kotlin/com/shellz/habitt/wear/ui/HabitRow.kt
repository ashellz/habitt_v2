package com.shellz.habitt.wear.ui

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.Text
import com.shellz.habitt.widgets.WidgetHabit

/**
 * A habit on the Today list. Amount/duration and read-only habits open their
 * own screen ([onOpen]); a plain habit's whole row is the check. Done habits
 * turn green like the phone's card: the accent at 10% sweeping in from the
 * leading edge, with a 20% border.
 */
@Composable
fun HabitRow(
    habit: WidgetHabit,
    accent: Color,
    text: WearText,
    onToggle: () -> Unit,
    onOpen: () -> Unit,
) {
    val opensScreen = habit.log.watchLoggable || habit.watchReadOnly
    val done by animateFloatAsState(if (habit.isDone) 1f else 0f, tween(350), label = "done")
    val shape = RoundedCornerShape(26.dp)
    val checkLabel = if (habit.isDone) text.uncompleteHabit(habit.name) else text.completeHabit(habit.name)

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 52.dp)
            .clip(shape)
            .drawBehind {
                drawRect(lerp(WearColors.Row, Color.Black, done))
                drawRect(accent.copy(alpha = 0.1f), size = Size(size.width * done, size.height))
            }
            .border(1.dp, accent.copy(alpha = 0.2f * done), shape),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        // ─── Body ─────────────────────────────────────────────
        Row(
            modifier = Modifier
                .weight(1f)
                .heightIn(min = 52.dp)
                .then(
                    if (opensScreen) {
                        Modifier.clickable(onClick = onOpen)
                    } else {
                        Modifier
                            .clickable(role = Role.Checkbox, onClick = onToggle)
                            .semantics { contentDescription = checkLabel }
                    },
                )
                .padding(start = 13.dp, top = 7.dp, bottom = 7.dp, end = 2.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(7.dp),
        ) {
            Text(habit.emoji, fontSize = 18.sp)
            Column {
                Text(
                    habit.name,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    color = Color.White,
                )
                if (habit.log.kind != null && habit.progressText.isNotEmpty()) {
                    Text(habit.progressText, fontSize = 11.sp, color = WearColors.Secondary, maxLines = 1)
                }
            }
        }

        // ─── Check ────────────────────────────────────────────
        Box(
            modifier = Modifier
                .padding(end = 2.dp)
                .size(48.dp)
                .then(
                    if (habit.watchReadOnly) {
                        Modifier
                    } else {
                        Modifier
                            .clip(RoundedCornerShape(24.dp))
                            .clickable(role = Role.Checkbox, onClick = onToggle)
                            .semantics { contentDescription = checkLabel }
                    },
                ),
            contentAlignment = Alignment.Center,
        ) {
            HabitIndicator(habit.progress, habit.isDone, accent)
        }
    }
}

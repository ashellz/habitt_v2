package com.shellz.habitt.wear.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.Text
import com.shellz.habitt.wear.R
import com.shellz.habitt.widgets.WidgetHabit

/**
 * A Health Connect or time-of-day habit: its progress, read-only, and where
 * it gets logged instead.
 */
@Composable
fun ReadOnlyScreen(habit: WidgetHabit, accent: Color, text: WearText) {
    // the phone's progress text split like the log screen: "14m / 20m" → "14m"
    // big and "of 20m" under it
    val progressText = habit.progressText
    val split = progressText.indexOf(" / ")
    val main = if (split >= 0) progressText.substring(0, split) else progressText.ifEmpty { habit.emoji }
    val sub = if (split >= 0) text.ofTarget(progressText.substring(split + 3)) else null

    ScreenScaffold {
        Box(Modifier.fillMaxSize()) {
            EdgeRing(habit.progress, accent, durationMs = 1250)
            Column(
                modifier = Modifier.fillMaxSize().padding(top = 36.dp, start = 26.dp, end = 26.dp),
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
                Spacer(Modifier.height(8.dp))
                Text(main, fontSize = 34.sp, fontWeight = FontWeight.Bold, color = Color.White, maxLines = 1)
                if (sub != null) Text(sub, fontSize = 12.sp, color = WearColors.Secondary, maxLines = 1)
                Spacer(Modifier.height(10.dp))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(20.dp))
                        .background(WearColors.Row)
                        .padding(horizontal = 11.dp, vertical = 7.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    if (habit.log.healthLinked) {
                        Image(
                            painterResource(R.drawable.wear_health_connect),
                            contentDescription = null,
                            modifier = Modifier.size(18.dp),
                        )
                    } else {
                        PhoneGlyph(accent, PhoneMark.NONE, height = 18.dp)
                    }
                    Text(
                        if (habit.log.healthLinked) text.healthNote else text.logOnPhone,
                        fontSize = 10.sp,
                        color = WearColors.Note,
                    )
                }
            }
        }
    }
}

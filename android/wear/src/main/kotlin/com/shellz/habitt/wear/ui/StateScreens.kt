package com.shellz.habitt.wear.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.background
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.Text
import com.shellz.habitt.wear.R
import com.shellz.habitt.widgets.DayBlock
import com.shellz.habitt.widgets.WidgetSnapshot

// ─── Day complete ─────────────────────────────────────────

@Composable
fun DayCompleteScreen(
    snapshot: WidgetSnapshot,
    block: DayBlock,
    accent: Color,
    text: WearText,
    showList: () -> Unit,
) {
    val scroll = rememberScrollState()
    ScreenScaffold(scrollState = scroll) {
        Column(
            modifier = Modifier.fillMaxSize().verticalScroll(scroll).padding(horizontal = 32.dp, vertical = 30.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            HabitIndicator(progress = 1.0, isDone = true, accent = accent, size = 56.dp)
            Spacer(Modifier.height(8.dp))
            Text(
                snapshot.strings.dayComplete,
                fontSize = 17.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
                color = Color.White,
            )
            val count = block.streak.count
            if (count > 0) {
                Spacer(Modifier.height(4.dp))
                // the app's streak flame (assets/images/new-svg/streak.svg, as in the widgets)
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Image(painterResource(R.drawable.wear_art_streak), contentDescription = null, modifier = Modifier.size(14.dp))
                    Text("$count ${snapshot.strings.streakLabel(count)}", fontSize = 12.sp, color = WearColors.Secondary)
                }
            }
            Spacer(Modifier.height(13.dp))
            Box(
                modifier = Modifier
                    .width(130.dp)
                    .height(40.dp)
                    .clip(RoundedCornerShape(20.dp))
                    .background(WearColors.Row)
                    .clickable(role = Role.Button, onClick = showList),
                contentAlignment = Alignment.Center,
            ) {
                Text(text.showHabits, fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = accent)
            }
        }
    }
}

// ─── Messages ─────────────────────────────────────────────

enum class MessageKind { OPEN_ON_PHONE, UPDATE, EMPTY }

@Composable
fun MessageScreen(kind: MessageKind, title: String, message: String?, accent: Color) {
    val scroll = rememberScrollState()
    ScreenScaffold(scrollState = scroll) {
        Column(
            modifier = Modifier.fillMaxSize().verticalScroll(scroll).padding(horizontal = 36.dp, vertical = 34.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            when (kind) {
                MessageKind.OPEN_ON_PHONE -> PhoneGlyph(accent, PhoneMark.CHECK, height = 52.dp)
                MessageKind.UPDATE -> PhoneGlyph(accent, PhoneMark.ARROW, height = 52.dp)
                MessageKind.EMPTY -> HabitIndicator(progress = 0.0, isDone = false, accent = accent, size = 40.dp)
            }
            Spacer(Modifier.height(10.dp))
            Text(
                title,
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
                color = Color.White,
            )
            if (message != null) {
                Spacer(Modifier.height(5.dp))
                Text(message, fontSize = 11.sp, textAlign = TextAlign.Center, color = WearColors.Secondary)
            }
        }
    }
}

enum class PhoneMark { CHECK, ARROW, NONE }

/** A phone outline (accent) with a white mark inside, like the watchOS canvas' "open on your phone" art. */
@Composable
fun PhoneGlyph(accent: Color, mark: PhoneMark, height: Dp, modifier: Modifier = Modifier) {
    Canvas(modifier.size(width = height * 96f / 140f, height = height)) {
        val u = size.height / 140f
        val stroke = 6f * u
        drawRoundRect(
            accent,
            topLeft = Offset(6f * u, 4f * u),
            size = Size(84f * u, 132f * u),
            cornerRadius = CornerRadius(18f * u),
            style = Stroke(stroke),
        )
        drawLine(accent, Offset(36f * u, 16f * u), Offset(60f * u, 16f * u), stroke, StrokeCap.Round)
        val path = Path()
        when (mark) {
            PhoneMark.CHECK -> {
                path.moveTo(32f * u, 72f * u)
                path.lineTo(43f * u, 83f * u)
                path.lineTo(64f * u, 61f * u)
            }
            PhoneMark.ARROW -> {
                path.moveTo(48f * u, 50f * u)
                path.lineTo(48f * u, 90f * u)
                path.moveTo(34f * u, 77f * u)
                path.lineTo(48f * u, 91f * u)
                path.lineTo(62f * u, 77f * u)
            }
            PhoneMark.NONE -> return@Canvas
        }
        drawPath(path, Color.White, style = Stroke(7f * u, cap = StrokeCap.Round, join = StrokeJoin.Round))
    }
}

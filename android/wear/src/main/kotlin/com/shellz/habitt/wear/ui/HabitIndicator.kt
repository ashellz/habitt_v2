package com.shellz.habitt.wear.ui

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

// The habit's check, identical to the phone's habit card (NewHabitProgress)
// and the watchOS HabitIndicator: no progress → grey check (check-off-dark.svg),
// done → filled accent with a near-black check (check-on-dark.svg), partial →
// a filled pie from 12 o'clock with a faint accent ring (_CircularProgressPie).
// Geometry is the SVGs' 24×24 viewBox, scaled.

private enum class IndicatorState { OFF, PARTIAL, DONE }

@Composable
fun HabitIndicator(
    progress: Double,
    isDone: Boolean,
    accent: Color,
    modifier: Modifier = Modifier,
    size: Dp = 24.dp,
) {
    val state = when {
        isDone -> IndicatorState.DONE
        progress > 0 -> IndicatorState.PARTIAL
        else -> IndicatorState.OFF
    }
    // only the pie itself tweens slowly, like the phone's (1250 ms)
    val pie by animateFloatAsState(
        targetValue = progress.coerceIn(0.0, 1.0).toFloat(),
        animationSpec = tween(1250, easing = FastOutSlowInEasing),
        label = "pie",
    )
    // the swap between check and pie is quick
    AnimatedContent(
        targetState = state,
        transitionSpec = {
            (scaleIn(tween(300)) + fadeIn(tween(300))) togetherWith (scaleOut(tween(300)) + fadeOut(tween(200)))
        },
        modifier = modifier.size(size),
        label = "indicator",
    ) { s ->
        Canvas(Modifier.fillMaxSize()) {
            val u = this.size.width / 24f
            when (s) {
                IndicatorState.OFF -> {
                    drawCircle(WearColors.OffGrey, radius = 11.37f * u, style = Stroke(1.26f * u))
                    drawCheck(WearColors.OffGrey, u)
                }
                IndicatorState.DONE -> {
                    drawCircle(accent, radius = 12f * u)
                    drawCheck(WearColors.CheckOnDone, u)
                }
                IndicatorState.PARTIAL -> {
                    drawArc(accent, startAngle = -90f, sweepAngle = 360f * pie, useCenter = true)
                    drawCircle(accent.copy(alpha = 0.2f), radius = 11f * u, style = Stroke(2f * u))
                }
            }
        }
    }
}

/** The check mark of the app's check SVGs: (6.9, 12) → (10.3, 15.4) → (17.08, 8.62), 2.93 wide. */
private fun DrawScope.drawCheck(color: Color, u: Float) {
    val path = Path().apply {
        moveTo(6.9f * u, 12f * u)
        lineTo(10.3f * u, 15.4f * u)
        lineTo(17.08f * u, 8.62f * u)
    }
    drawPath(path, color, style = Stroke(width = 2.93f * u, cap = StrokeCap.Round, join = StrokeJoin.Round))
}

/** The progress ring along the round screen's edge (log and read-only screens); animated. */
@Composable
fun EdgeRing(progress: Double, accent: Color, modifier: Modifier = Modifier, durationMs: Int = 350) {
    val p by animateFloatAsState(
        targetValue = progress.coerceIn(0.0, 1.0).toFloat(),
        animationSpec = tween(durationMs, easing = FastOutSlowInEasing),
        label = "ring",
    )
    Box(modifier.fillMaxSize().padding(3.dp)) {
        Canvas(Modifier.fillMaxSize()) {
            val stroke = 6.dp.toPx()
            val inset = stroke / 2
            val arcSize = Size(this.size.width - stroke, this.size.height - stroke)
            val topLeft = Offset(inset, inset)
            drawArc(WearColors.Track, 0f, 360f, false, topLeft, arcSize, style = Stroke(stroke))
            if (p > 0f) {
                drawArc(accent, -90f, 360f * p, false, topLeft, arcSize, style = Stroke(stroke, cap = StrokeCap.Round))
            }
        }
    }
}

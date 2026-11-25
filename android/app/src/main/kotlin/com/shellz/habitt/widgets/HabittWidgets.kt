package com.shellz.habitt.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.min
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import com.shellz.habitt.R
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import java.time.LocalDateTime

/**
 * Base of the four read-only widgets: reads the snapshot from home_widget's
 * preferences on every render, picks today/tomorrow and the part of the day
 * from the clock. Until the app wrote one it shows no habits and a 0 streak.
 */
abstract class HabittWidget : GlanceAppWidget() {
    override val sizeMode = SizeMode.Exact
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        WidgetRefresh.scheduleNext(context)
        provideContent {
            val prefs = currentState<HomeWidgetGlanceState>().preferences
            // nothing written yet (installed, never opened): no habits, streak 0
            val snapshot = WidgetSnapshot.parse(prefs.getString(WidgetStore.SNAPSHOT_KEY, null))
                ?: WidgetStore.placeholder(context)
            val now = LocalDateTime.now()
            Content(context, snapshot, snapshot.blockAt(now), now)
        }
    }

    @Composable
    abstract fun Content(context: Context, snapshot: WidgetSnapshot, block: DayBlock, now: LocalDateTime)
}

/** Keeps the boundary updates armed whenever the system or the app updates a widget. */
abstract class HabittWidgetReceiver<T : GlanceAppWidget> : HomeWidgetGlanceWidgetReceiver<T>() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        WidgetRefresh.scheduleNext(context)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetRefresh.scheduleNext(context)
    }
}

class StreakWidgetReceiver : HabittWidgetReceiver<StreakWidget>() {
    override val glanceAppWidget = StreakWidget()
}

class StreakWeekWidgetReceiver : HabittWidgetReceiver<StreakWeekWidget>() {
    override val glanceAppWidget = StreakWeekWidget()
}

class TodayRingWidgetReceiver : HabittWidgetReceiver<TodayRingWidget>() {
    override val glanceAppWidget = TodayRingWidget()
}

class UpNextWidgetReceiver : HabittWidgetReceiver<UpNextWidget>() {
    override val glanceAppWidget = UpNextWidget()
}

// ─── Streak: the ember card ──────────────────────────────────────────

class StreakWidget : HabittWidget() {
    @Composable
    override fun Content(context: Context, snapshot: WidgetSnapshot, block: DayBlock, now: LocalDateTime) {
        val streak = block.streak
        val size = LocalSize.current
        Box(
            modifier = GlanceModifier.fillMaxSize().cornerRadius(24.dp)
                .background(ImageProvider(WidgetArt.streakCard(streak.health)))
                .clickable(WidgetLinks.home(context)),
        ) {
            Column(modifier = GlanceModifier.width(size.width * 0.66f).padding(start = 16.dp, top = 14.dp)) {
                // dormant shows 0 with the invitation as its line, like any other count
                Text("${streak.count}", style = style(48.sp, WidgetColors.text, FontWeight.Bold), maxLines = 1)
                Spacer(GlanceModifier.height(2.dp))
                Text(snapshot.strings.streakLabel(streak.count), style = style(15.sp, WidgetColors.text, FontWeight.Medium), maxLines = 1)
                Spacer(GlanceModifier.height(4.dp))
                Text(streak.line, style = style(12.sp, WidgetColors.sub), maxLines = 3)
            }
            if (streak.perfectToday) {
                Box(modifier = GlanceModifier.fillMaxSize().padding(12.dp), contentAlignment = Alignment.TopEnd) {
                    PerfectBadge(26.dp)
                }
            }
        }
    }
}

// ─── Streak week: count, line and the last 7 days ────────────────────

class StreakWeekWidget : HabittWidget() {
    @Composable
    override fun Content(context: Context, snapshot: WidgetSnapshot, block: DayBlock, now: LocalDateTime) {
        val streak = block.streak
        Box(
            modifier = GlanceModifier.fillMaxSize().cornerRadius(24.dp)
                .background(ImageProvider(WidgetArt.week(streak.health)))
                .clickable(WidgetLinks.home(context)),
        ) {
            Column(modifier = GlanceModifier.fillMaxSize().padding(start = 14.dp, top = 14.dp, end = 14.dp, bottom = 12.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Image(ImageProvider(R.drawable.widget_art_streak), null, GlanceModifier.size(22.dp))
                    Spacer(GlanceModifier.width(6.dp))
                    Text("${streak.count}", style = style(28.sp, WidgetColors.text, FontWeight.Bold), maxLines = 1)
                    Spacer(GlanceModifier.width(5.dp))
                    Text(snapshot.strings.dayLabel(streak.count), style = style(13.sp, WidgetColors.sub, FontWeight.Medium), maxLines = 1)
                }
                Spacer(GlanceModifier.height(6.dp))
                Text(streak.line, style = style(12.sp, WidgetColors.sub), maxLines = 2)
                Spacer(GlanceModifier.defaultWeight())
                Row(modifier = GlanceModifier.fillMaxWidth()) {
                    streak.week.forEachIndexed { i, day ->
                        val isLast = i == streak.week.lastIndex
                        Column(modifier = GlanceModifier.defaultWeight(), horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                day.label,
                                style = style(
                                    10.sp,
                                    if (isLast) WidgetColors.text else WidgetColors.sub,
                                    if (isLast) FontWeight.Bold else FontWeight.Medium,
                                    TextAlign.Center,
                                ),
                                maxLines = 1,
                            )
                            Spacer(GlanceModifier.height(5.dp))
                            WeekMarker(context, day)
                        }
                    }
                }
            }
        }
    }

    @Composable
    private fun WeekMarker(context: Context, day: WeekDay) {
        Box(modifier = GlanceModifier.size(18.dp), contentAlignment = Alignment.Center) {
            when (day.status) {
                WeekDay.Status.PERFECT -> Image(ImageProvider(R.drawable.widget_art_streak), null, GlanceModifier.size(17.dp))
                WeekDay.Status.PARTIAL, WeekDay.Status.TODAY -> {
                    Tinted(ImageProvider(WidgetBitmaps.weekArc(context, 1.0, full = true)), WidgetColors.weekTrack, 18.dp)
                    if (day.progress > 0) {
                        Tinted(ImageProvider(WidgetBitmaps.weekArc(context, day.progress, full = false)), WidgetColors.habittGreen, 18.dp)
                    }
                }
                WeekDay.Status.MISS -> Tinted(ImageProvider(R.drawable.widget_circle), WidgetColors.weekTrack, 6.dp)
                WeekDay.Status.NONE -> {}
            }
        }
    }
}

// ─── Today ring ("Beads") ────────────────────────────────────────────

class TodayRingWidget : HabittWidget() {
    @Composable
    override fun Content(context: Context, snapshot: WidgetSnapshot, block: DayBlock, now: LocalDateTime) {
        val next = block.firstNotDone()
        val tap = if (next == null || block.perfect) WidgetLinks.home(context) else WidgetLinks.log(context, next.id)
        Box(
            modifier = GlanceModifier.fillMaxSize().cornerRadius(24.dp)
                .background(ImageProvider(R.drawable.widget_bg_plain))
                .clickable(tap),
            contentAlignment = Alignment.Center,
        ) {
            if (!snapshot.hasHabits) {
                NoHabitsState(snapshot, 46.dp, 12.sp, GlanceModifier.padding(14.dp))
            } else if (block.total == 0) {
                Text(
                    snapshot.strings.nothingToday,
                    modifier = GlanceModifier.padding(14.dp),
                    style = style(13.sp, WidgetColors.subRing, FontWeight.Medium, TextAlign.Center),
                    maxLines = 3,
                )
            } else {
                val side: Dp = min(LocalSize.current.width, LocalSize.current.height)
                val u = side.value / 170f
                val ring = WidgetBitmaps.Ring((side.value * WidgetBitmaps.scale(context)).toInt(), block.ringHabits())
                Tinted(ImageProvider(ring.track()), WidgetColors.ringTrack, side)
                Tinted(ImageProvider(ring.fill()), WidgetColors.accent(snapshot), side)
                if (!ring.continuous) Image(ImageProvider(ring.emojis()), null, GlanceModifier.size(side))
                if (block.perfect) {
                    AccentCheck(snapshot, (40 * u).dp)
                } else {
                    Row(verticalAlignment = Alignment.Bottom) {
                        Text("${block.done}", style = style((30 * u).sp, WidgetColors.text, FontWeight.Bold), maxLines = 1)
                        Text("/${block.total}", style = style((16 * u).sp, WidgetColors.subRing, FontWeight.Medium), maxLines = 1)
                    }
                }
            }
        }
    }
}

// ─── Up next ─────────────────────────────────────────────────────────

/**
 * Android cells are taller than the iOS design (a 4×2 is about 360×220 dp
 * against 364×170): Up next keeps the iOS text sizes and lets its rows grow
 * to fill the height (40 to 56 dp).
 */
class UpNextWidget : HabittWidget() {
    /** Sizes of one layout at one widget size, in dp / sp. */
    private data class Dims(
        val pad: Float, val headerH: Float, val headerGap: Float, val icon: Float, val label: Float,
        val rowH: Float, val rowGap: Float, val disc: Float, val emoji: Float, val name: Float, val meta: Float,
        val indicator: Float, val tileW: Float, val tileCount: Float, val tileLabel: Float, val badge: Float,
    ) {
        /** How many rows fit under the header at [height]. */
        fun fit(height: Float) = ((height - 2 * pad - headerH - headerGap + rowGap) / (rowH + rowGap)).toInt().coerceIn(1, 3)
    }

    /** Three rows share the height under the header; on an iOS-sized cell this is the iOS design. */
    private fun dims(height: Float): Dims {
        val free = height - 2 * BASE.pad - BASE.headerH - BASE.headerGap
        val rowGap = 6f
        val rowH = ((free - 2 * rowGap) / 3).coerceIn(BASE.rowH, 56f)
        if (rowH <= BASE.rowH) return BASE
        return BASE.copy(rowH = rowH, rowGap = rowGap, disc = (rowH - 10).coerceAtMost(38f), emoji = 16f, indicator = 24f)
    }

    @Composable
    override fun Content(context: Context, snapshot: WidgetSnapshot, block: DayBlock, now: LocalDateTime) {
        val section = block.upNextAt(now.toLocalTime())
        val height = LocalSize.current.height.value
        val d = dims(height)
        val fit = d.fit(height)
        Box(
            modifier = GlanceModifier.fillMaxSize().cornerRadius(24.dp)
                .background(ImageProvider(R.drawable.widget_bg_upnext))
                .clickable(WidgetLinks.home(context)),
        ) {
            Row(modifier = GlanceModifier.fillMaxSize().padding(d.pad.dp)) {
                Column(modifier = GlanceModifier.defaultWeight().fillMaxHeight()) {
                    when {
                        section != null -> {
                            Row(
                                modifier = GlanceModifier.height(d.headerH.dp).padding(horizontal = 6.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                val icon = when (section.icon) {
                                    "evening" -> R.drawable.widget_moon
                                    "anyTime" -> R.drawable.widget_anytime
                                    else -> R.drawable.widget_sun
                                }
                                Tinted(ImageProvider(icon), WidgetColors.subPlain, d.icon.dp)
                                Spacer(GlanceModifier.width(5.dp))
                                Text(section.label, style = style(d.label.sp, WidgetColors.subPlain, FontWeight.Medium), maxLines = 1)
                            }
                            Spacer(GlanceModifier.height(d.headerGap.dp))
                            section.habitIds.mapNotNull { block.habit(it) }.take(fit).forEachIndexed { i, habit ->
                                if (i > 0) Spacer(GlanceModifier.height(d.rowGap.dp))
                                HabitRow(context, snapshot, habit, d)
                            }
                        }
                        !snapshot.hasHabits -> NoHabitsState(snapshot, 46.dp, 12.5.sp, GlanceModifier.fillMaxSize())
                        block.habits.isEmpty() -> EndState(snapshot, null, snapshot.strings.nothingToday)
                        else -> EndState(snapshot, snapshot.strings.dayComplete, snapshot.strings.dayCompleteBody)
                    }
                }
                Spacer(GlanceModifier.width(d.pad.dp))
                StreakTile(context, snapshot, block.streak, d)
            }
        }
    }

    @Composable
    private fun EndState(snapshot: WidgetSnapshot, title: String?, body: String) {
        Column(
            modifier = GlanceModifier.fillMaxSize().padding(start = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (title != null) {
                AccentCheck(snapshot, 40.dp)
                Spacer(GlanceModifier.height(12.dp))
                Text(title, style = style(19.sp, WidgetColors.text, FontWeight.Bold), maxLines = 1)
                Spacer(GlanceModifier.height(4.dp))
            }
            Text(body, style = style(12.5.sp, WidgetColors.subPlain), maxLines = 3)
        }
    }

    @Composable
    private fun HabitRow(context: Context, snapshot: WidgetSnapshot, habit: WidgetHabit, d: Dims) {
        val done = habit.isDone
        TintedBox(
            shape = R.drawable.widget_shape_row,
            tint = if (done) WidgetColors.doneRowBorder(snapshot) else WidgetColors.cardBorder,
            modifier = GlanceModifier.fillMaxWidth().height(d.rowH.dp).clickable(WidgetLinks.log(context, habit.id)),
        ) {
            TintedBox(
                shape = R.drawable.widget_shape_row_inner,
                tint = if (done) WidgetColors.doneRow(snapshot) else WidgetColors.card,
                modifier = GlanceModifier.fillMaxSize().padding(1.dp),
            ) {
                Row(
                    modifier = GlanceModifier.fillMaxSize().padding(start = ((d.rowH - d.disc) / 2 - 2).dp, end = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Box(modifier = GlanceModifier.size(d.disc.dp), contentAlignment = Alignment.Center) {
                        Tinted(ImageProvider(R.drawable.widget_circle), if (done) WidgetColors.doneDisc else WidgetColors.disc, d.disc.dp)
                        Text(habit.emoji, style = style(d.emoji.sp, WidgetColors.text, align = TextAlign.Center), maxLines = 1)
                    }
                    Spacer(GlanceModifier.width(9.dp))
                    Column(modifier = GlanceModifier.defaultWeight()) {
                        Text(habit.name, style = style(d.name.sp, WidgetColors.text, FontWeight.Medium), maxLines = 1)
                        // checkbox habits have no progress text: keep the name centred
                        if (habit.progressText.isNotBlank()) {
                            Text(habit.progressText, style = style(d.meta.sp, WidgetColors.subPlain), maxLines = 1)
                        }
                    }
                    Spacer(GlanceModifier.width(6.dp))
                    Indicator(context, snapshot, habit, d.indicator.dp)
                }
            }
        }
    }

    /** The app's habit indicator: grey check-circle, accent pie, or filled accent check. */
    @Composable
    private fun Indicator(context: Context, snapshot: WidgetSnapshot, habit: WidgetHabit, size: Dp) {
        when (habit.state) {
            WidgetHabit.State.DONE -> AccentCheck(snapshot, size)
            WidgetHabit.State.PARTIAL -> Box(modifier = GlanceModifier.size(size), contentAlignment = Alignment.Center) {
                Tinted(ImageProvider(WidgetBitmaps.pie(context, habit.progress)), WidgetColors.accent(snapshot), size)
                Tinted(ImageProvider(R.drawable.widget_ring_pie), WidgetColors.accentAlpha(snapshot, 0.2f), size)
            }
            WidgetHabit.State.TODO -> Box(modifier = GlanceModifier.size(size), contentAlignment = Alignment.Center) {
                Tinted(ImageProvider(R.drawable.widget_ring_thin), WidgetColors.offRing, size)
                Tinted(ImageProvider(R.drawable.widget_check), WidgetColors.offCheck, size)
            }
        }
    }

    @Composable
    private fun StreakTile(context: Context, snapshot: WidgetSnapshot, streak: StreakInfo, d: Dims) {
        Box(
            modifier = GlanceModifier.width(d.tileW.dp).fillMaxHeight().cornerRadius(18.dp)
                .background(ImageProvider(WidgetArt.streakTile(streak.health)))
                .clickable(WidgetLinks.home(context)),
        ) {
            Column(modifier = GlanceModifier.padding(start = 12.dp, top = 11.dp)) {
                Text("${streak.count}", style = style(d.tileCount.sp, WidgetColors.text, FontWeight.Bold), maxLines = 1)
                Text(snapshot.strings.streakLabel(streak.count), style = style(d.tileLabel.sp, WidgetColors.text, FontWeight.Medium), maxLines = 2)
            }
            if (streak.perfectToday) {
                Box(modifier = GlanceModifier.fillMaxSize().padding(10.dp), contentAlignment = Alignment.TopEnd) {
                    PerfectBadge(d.badge.dp)
                }
            }
        }
    }

    companion object {
        /** The iOS design at 364×170. */
        private val BASE = Dims(
            pad = 10f, headerH = 16f, headerGap = 5f, icon = 13f, label = 12f,
            rowH = 40f, rowGap = 3f, disc = 30f, emoji = 15f, name = 13.5f, meta = 11f,
            indicator = 22f, tileW = 104f, tileCount = 32f, tileLabel = 12f, badge = 22f,
        )
    }
}

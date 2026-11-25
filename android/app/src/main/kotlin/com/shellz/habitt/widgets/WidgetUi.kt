package com.shellz.habitt.widgets

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.Action
import androidx.glance.action.clickable
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.shellz.habitt.MainActivity
import com.shellz.habitt.R
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.actionStartActivity
import androidx.glance.color.ColorProvider as dayNight

/** Snapshot storage shared with the Dart side (`HomeWidgetKinds`). */
object WidgetStore {
    const val SNAPSHOT_KEY = "habitt_snapshot"

    fun load(context: Context): WidgetSnapshot? =
        WidgetSnapshot.parse(HomeWidgetPlugin.getData(context).getString(SNAPSHOT_KEY, null))
}

/** Widget taps: URIs `WidgetLaunchHandler` understands, launched through home_widget. */
object WidgetLinks {
    fun home(context: Context): Action =
        actionStartActivity<MainActivity>(context, Uri.parse("habitt://widget/home"))

    fun log(context: Context, habitId: Int): Action =
        actionStartActivity<MainActivity>(context, Uri.parse("habitt://widget/log?habit=$habitId"))
}

/** Colours from the design canvas, light / dark. The accent comes from the snapshot. */
object WidgetColors {
    private fun c(day: Long, night: Long) = dayNight(Color(day), Color(night))

    val text = c(0xFF0C0C0C, 0xFFFFFFFF)
    val sub = c(0xA80C0C0C, 0xADFFFFFF) // Streak cards
    val subPlain = c(0xFF7A7C81, 0x99FFFFFF) // Up next
    val subRing = c(0xFFA4A7AE, 0x8CFFFFFF) // Today ring
    val weekTrack = c(0xFFE4E4E6, 0xFF343536)
    val ringTrack = c(0xFFF1F1F1, 0xFF2A2B2C)
    val habittGreen = c(0xFF02D382, 0xFF11F29B)
    val card = c(0xFFFFFFFF, 0xFF1C1C1C)
    val cardBorder = c(0xFFEDECEC, 0xFF2F3030)
    val disc = c(0xFFF4F4F4, 0xFF2A2A2A)
    val doneDisc = c(0xFFFFFFFF, 0xFF0C0C0C)
    val offRing = c(0xFFEDECEC, 0xFF565963)
    val offCheck = c(0xFFDCDCDC, 0xFF565963)
    val checkInk = c(0xFFFFFFFF, 0xFF0C0C0C)
    val badge = ColorProvider(Color(0xEBFFFFFF))
    val badgeInk = ColorProvider(Color(0xFFF47200))

    private const val UP_NEXT_BG_LIGHT = 0xFFF4F4F4.toInt()
    private const val UP_NEXT_BG_DARK = 0xFF121212.toInt()

    fun accent(s: WidgetSnapshot) = dayNight(Color(s.accentLight), Color(s.accentDark))

    fun accentAlpha(s: WidgetSnapshot, alpha: Float) =
        dayNight(Color(s.accentLight).copy(alpha = alpha), Color(s.accentDark).copy(alpha = alpha))

    /** A done row's tint (10 % / 12 %) and border (20 %), blended onto the Up next background. */
    fun doneRow(s: WidgetSnapshot) =
        dayNight(Color(blend(UP_NEXT_BG_LIGHT, s.accentLight, 0.10f)), Color(blend(UP_NEXT_BG_DARK, s.accentDark, 0.12f)))

    fun doneRowBorder(s: WidgetSnapshot) =
        dayNight(Color(blend(UP_NEXT_BG_LIGHT, s.accentLight, 0.20f)), Color(blend(UP_NEXT_BG_DARK, s.accentDark, 0.20f)))

    fun blend(base: Int, over: Int, a: Float): Int {
        fun ch(shift: Int) = ((base shr shift and 0xFF) * (1 - a) + (over shr shift and 0xFF) * a).toInt().coerceIn(0, 255)
        return (0xFF shl 24) or (ch(16) shl 16) or (ch(8) shl 8) or ch(0)
    }
}

/** Per-mood background drawables (each has a -night variant). */
object WidgetArt {
    fun streakCard(h: StreakInfo.Health) = when (h) {
        StreakInfo.Health.HEALTHY -> R.drawable.widget_bg_streak_healthy
        StreakInfo.Health.FADING -> R.drawable.widget_bg_streak_fading
        StreakInfo.Health.CRITICAL -> R.drawable.widget_bg_streak_critical
        StreakInfo.Health.DORMANT -> R.drawable.widget_bg_streak_dormant
    }

    fun streakTile(h: StreakInfo.Health) = when (h) {
        StreakInfo.Health.HEALTHY -> R.drawable.widget_bg_tile_healthy
        StreakInfo.Health.FADING -> R.drawable.widget_bg_tile_fading
        StreakInfo.Health.CRITICAL -> R.drawable.widget_bg_tile_critical
        StreakInfo.Health.DORMANT -> R.drawable.widget_bg_tile_dormant
    }

    fun week(h: StreakInfo.Health) = when (h) {
        StreakInfo.Health.HEALTHY -> R.drawable.widget_bg_week_healthy
        StreakInfo.Health.FADING -> R.drawable.widget_bg_week_fading
        StreakInfo.Health.CRITICAL -> R.drawable.widget_bg_week_critical
        StreakInfo.Health.DORMANT -> R.drawable.widget_bg_week_dormant
    }
}

/**
 * Bitmaps for what RemoteViews cannot draw (arcs, ring segments). Shapes are
 * white masks that the widgets tint with day/night colours, so a light/dark
 * switch needs no redraw on Android 12+.
 */
object WidgetBitmaps {
    /** Keeps every bitmap of one widget within RemoteViews' memory budget. */
    private const val MAX_SCALE = 3f

    fun scale(context: Context) = context.resources.displayMetrics.density.coerceAtMost(MAX_SCALE)

    private fun mask(sizePx: Int, draw: Canvas.(Paint) -> Unit): Bitmap {
        val bmp = Bitmap.createBitmap(sizePx.coerceAtLeast(1), sizePx.coerceAtLeast(1), Bitmap.Config.ARGB_8888)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = android.graphics.Color.WHITE }
        Canvas(bmp).draw(paint)
        return bmp
    }

    /** Week marker arc: circle r 7 in an 18 box, stroke 2.4, round caps, clockwise from the top. */
    fun weekArc(context: Context, progress: Double, full: Boolean): Bitmap {
        val k = scale(context)
        return mask((18 * k).toInt()) { p ->
            p.style = Paint.Style.STROKE
            p.strokeWidth = 2.4f * k
            p.strokeCap = Paint.Cap.ROUND
            val r = RectF(2 * k, 2 * k, 16 * k, 16 * k)
            if (full) drawOval(r, p) else if (progress > 0) drawArc(r, -90f, (360 * progress).toFloat().coerceAtLeast(1f), false, p)
        }
    }

    /** Up next partial indicator: an edge-to-edge pie wedge in a 24 box. */
    fun pie(context: Context, progress: Double): Bitmap {
        val k = scale(context)
        return mask((22 * k).toInt()) { p ->
            val size = 22 * k
            if (progress >= 1) drawOval(RectF(0f, 0f, size, size), p)
            else if (progress > 0) drawArc(RectF(0f, 0f, size, size), -90f, (360 * progress).toFloat(), true, p)
        }
    }

    /** Today ring ("Beads") geometry on a 170 unit card: r 60, stroke 26, 4° gaps, butt caps. */
    class Ring(val sidePx: Int, val segments: List<WidgetHabit>) {
        private val u = sidePx / 170f
        private val c = sidePx / 2f
        private val step = if (segments.isEmpty()) 360f else 360f / segments.size
        private val rect = RectF(c - 60 * u, c - 60 * u, c + 60 * u, c + 60 * u)

        private fun span(i: Int): Pair<Float, Float> {
            val s0 = -90f + i * step
            return if (segments.size <= 1) s0 to 360f else (s0 + 2f) to (step - 4f)
        }

        private fun stroke(p: Paint) {
            p.style = Paint.Style.STROKE
            p.strokeWidth = 26 * u
            p.strokeCap = Paint.Cap.BUTT
        }

        fun track(): Bitmap = mask(sidePx) { p ->
            stroke(p)
            if (segments.isEmpty()) drawOval(rect, p)
            segments.indices.forEach { i -> val (a, sweep) = span(i); drawArc(rect, a, sweep, false, p) }
        }

        fun fill(): Bitmap = mask(sidePx) { p ->
            stroke(p)
            segments.forEachIndexed { i, h ->
                if (h.progress <= 0 && !h.isDone) return@forEachIndexed
                val (a, sweep) = span(i)
                val pr = if (h.isDone) 1.0 else h.progress
                drawArc(rect, a, (sweep * pr).toFloat().coerceAtLeast(0.4f), false, p)
            }
        }

        /** The habits' emojis centred on their segments; empty above eight habits. */
        fun emojis(): Bitmap {
            val bmp = Bitmap.createBitmap(sidePx, sidePx, Bitmap.Config.ARGB_8888)
            if (segments.size > MAX_EMOJIS) return bmp
            val canvas = Canvas(bmp)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                textSize = 17 * u
                textAlign = Paint.Align.CENTER
            }
            val fm = paint.fontMetrics
            segments.forEachIndexed { i, h ->
                val mid = Math.toRadians((-90.0 + i * step + step / 2))
                val x = c + 60 * u * Math.cos(mid).toFloat()
                val y = c + 60 * u * Math.sin(mid).toFloat() - (fm.ascent + fm.descent) / 2
                canvas.drawText(h.emoji, x, y, paint)
            }
            return bmp
        }

        companion object {
            const val MAX_EMOJIS = 8
        }
    }
}

// ─── Shared composables ──────────────────────────────────────────────

/** A white mask drawable or bitmap, tinted. */
@Composable
fun Tinted(provider: ImageProvider, tint: androidx.glance.unit.ColorProvider, size: Dp, modifier: GlanceModifier = GlanceModifier) {
    Image(
        provider = provider,
        contentDescription = null,
        modifier = modifier.size(size),
        contentScale = ContentScale.FillBounds,
        colorFilter = ColorFilter.tint(tint),
    )
}

/** A full-size tinted shape behind [content]. */
@Composable
fun TintedBox(
    shape: Int,
    tint: androidx.glance.unit.ColorProvider,
    modifier: GlanceModifier,
    contentAlignment: Alignment = Alignment.TopStart,
    content: @Composable () -> Unit,
) {
    Box(modifier = modifier, contentAlignment = contentAlignment) {
        Image(
            provider = ImageProvider(shape),
            contentDescription = null,
            modifier = GlanceModifier.fillMaxSize(),
            contentScale = ContentScale.FillBounds,
            colorFilter = ColorFilter.tint(tint),
        )
        content()
    }
}

/** White circle with an orange check: today is already perfect. */
@Composable
fun PerfectBadge(size: Dp) {
    Box(modifier = GlanceModifier.size(size), contentAlignment = Alignment.Center) {
        Tinted(ImageProvider(R.drawable.widget_circle), WidgetColors.badge, size)
        Tinted(ImageProvider(R.drawable.widget_check_stroke), WidgetColors.badgeInk, size * 0.55f)
    }
}

/** Filled accent circle with a check (done habit, perfect day). */
@Composable
fun AccentCheck(snapshot: WidgetSnapshot, size: Dp) {
    Box(modifier = GlanceModifier.size(size), contentAlignment = Alignment.Center) {
        Tinted(ImageProvider(R.drawable.widget_circle), WidgetColors.accent(snapshot), size)
        Tinted(ImageProvider(R.drawable.widget_check), WidgetColors.checkInk, size)
    }
}

fun style(size: TextUnit, color: androidx.glance.unit.ColorProvider, weight: FontWeight = FontWeight.Normal, align: TextAlign? = null) =
    TextStyle(color = color, fontSize = size, fontWeight = weight, textAlign = align)

/** Shown before the app has written its first snapshot. */
@Composable
fun OpenAppState(context: Context) {
    Box(
        modifier = GlanceModifier.fillMaxSize().cornerRadius(24.dp)
            .background(ImageProvider(R.drawable.widget_bg_plain))
            .clickable(WidgetLinks.home(context)),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = GlanceModifier.padding(14.dp)) {
            Image(ImageProvider(R.drawable.widget_art_streak), null, GlanceModifier.size(34.dp))
            Spacer(GlanceModifier.height(8.dp))
            Text(
                context.getString(R.string.widget_open_app),
                style = style(13.sp, WidgetColors.text, FontWeight.Medium, TextAlign.Center),
                maxLines = 3,
            )
        }
    }
}

# Habitt v2 — Home Screen Widgets

## Overview

Habitt offers four read-only home screen widgets on iOS and Android:

| Widget | Size | Shows | Tap opens |
|---|---|---|---|
| Streak | small | Perfect-days streak as an ember card (healthy, fading, critical, perfect today, dormant) | Home page |
| Streak week | small | Streak count and the last 7 days as embers | Home page |
| Today ring | small | One ring segment per habit counted today ("Beads"), done/total in the middle | Log progress for the first habit not done, home when all done |
| Up next | medium | Up to three habits of the current part of the day, plus a streak tile | Log progress for the tapped habit |

Design reference: the Claude Design canvas "Habitt Home Widgets"
(https://claude.ai/artifact/CGWtP9vUgopBYWrwkH9T9Z). Its `Flame`, `Ring`
(`variant="beads"`) and `NextList` components hold the exact colours, sizes
and states. Behaviour contract: `openspec/changes/home-widgets-readonly/`
(local only, `openspec/` is gitignored).

Widgets cannot read Hive and run while the app is closed, so **the app
precomputes everything they show** into one JSON document, the *widget
snapshot*. The native widgets (SwiftUI WidgetKit extension on iOS, Jetpack
Glance on Android) only draw it; they contain no habit, schedule or streak
logic.

```
HabitProvider ┐
StatsProvider ├─▶ WidgetSnapshotService ─▶ WidgetSnapshotBuilder.build() ─▶ JSON
ColorProvider │      (debounced, skips          (pure, unit tested)
LanguageProv. │       unchanged snapshots)
StateProvider ┘                │
                               ▼
                 home_widget: saveWidgetData('habitt_snapshot')
                 iOS: App Group group.com.shellz.habitt UserDefaults
                 Android: home_widget SharedPreferences
                               │ updateWidget(each kind)
                               ▼
                     native widgets redraw
```

## Code

| File | Role |
|---|---|
| `lib/services/widget_snapshot_builder.dart` | Builds the snapshot from plain inputs. All widget rules live here. |
| `lib/services/widget_snapshot_service.dart` | Collects inputs from the providers, debounces, skips unchanged snapshots, writes through `home_widget`. Also `HomeWidgetKinds` (App Group, storage key, widget kind / receiver names). |
| `lib/services/widget_launch_handler.dart` | Parses widget tap URIs and routes them. |
| `lib/util/habit_progress.dart` | Habit progress value and progress text, shared with the habit card so card and widgets always agree. |
| `lib/services/notification_action_handler.dart` | `openHabit` — the notification tap routine (Log progress over the main page, details as fallback, cold start replay), reused by widget taps. |

## The snapshot (`v` 1)

Stored as a JSON string under the key `habitt_snapshot`.

```jsonc
{
  "v": 1,                          // bump when a field changes meaning; natives check it
  "generatedAt": "2026-11-24T08:30:00.000",
  "dayKey": "2026-11-24",          // the local day `today` describes
  "nextDayStartsAt": "2026-11-25T00:00:00.000",
  "hasHabits": true,               // false: no habits in the app at all (not just none today)
  "theme": { "light": { "accent": "#02D382" }, "dark": { "accent": "#11F29B" } },
  "strings": { "dayStreak", "daysStreak", "day", "days", "dayComplete", "dayCompleteBody", "nothingToday", "noHabits" },
                                   // dayStreak/daysStreak: the dayStreakLabel/daysStreakLabel ARB keys
                                   // ("day streak" / "days streak"), shared with the home page card
  "today":    DayBlock,
  "tomorrow": DayBlock             // today ended as it is now; used after nextDayStartsAt
}
```

`DayBlock`:

```jsonc
{
  "habits": [{
    "id": 5, "emoji": "🚿", "name": "Shower",   // name already in the app language
    "category": 2,                              // 1 Any time, 2 Morning, 3 Afternoon, 4 Evening
    "optional": false,
    "progress": 0.8,                            // habitProgressValue, 0–1
    "progressText": "8m / 10m",                 // as on the habit card
    "state": "partial",                         // done | partial | todo (picks the indicator)
    "canLog": true                              // has a tracking type
  }],
  "ring": [5, 7],                 // ids of counted (non-optional) habits, ring order
  "done": 1, "total": 2, "perfect": false,
  "streak": {
    "count": 12,                  // includes this day once it is perfect
    "health": "healthy",          // healthy | fading | critical | dormant
    "perfectToday": false,
    "line": "Keep it up!",        // one encouragement pick per day; dormant → start-a-streak invite
    "week": [{ "label": "W", "s": "perfect", "p": 1.0 }]  // 7 entries ending this day;
                                  // s: perfect | partial | miss | none | today, p: day progress
  },
  "upNext": {                     // what Up next shows while that part of day is current
    "morning":   { "label": "Morning", "icon": "morning", "habits": [1, 5, 9] },
    "afternoon": { ... },
    "evening":   { ... }          // null in all three when the day is perfect → Day complete
  }
}
```

### Rules the builder applies

- **Counted habits**: today's list is `HabitProvider.todaysHabits` (scheduled, not
  deleted, not paused, in app order). Optional habits are listed but are not
  in `ring`, `done`, `total` or `perfect`.
- **Streak**: `today.streak.count` = `StatsProvider.perfectDaysStreak` (which
  leaves today out) + 1 when today is perfect, exactly like the home streak
  card (`StatsProvider.shownPerfectDaysStreak`), so a first perfect day
  reads "1 day streak" in both; health via `resolveStreakHealth`. `tomorrow.streak` runs
  `computeCurrentStreak` over every day status up to and including today.
- **Up next section**: for the current part P it tries P, then Any time, then
  the later parts, then the earlier ones, and takes the first that still has
  something not done. At most three rows in app order; in a longer section,
  done habits make room first.
- **Parts of day** follow `categoryIdForMinutes`: Morning 04–12, Afternoon
  12–19, Evening 19–04. Natives pick the block for the current clock time.

## When the snapshot is written

`WidgetSnapshotService.start` (after the first frame in `main.dart`) listens
to `HabitProvider`, `StatsProvider`, `ColorProvider`, `LanguageProvider` and
`StateProvider`. Every notification marks it dirty; it writes 500 ms after
the last one, and only when the JSON (ignoring `generatedAt`) changed. That
covers taps in the app, the new-day reset, Health sync, cloud/local restore
merges and notification completions drained on open, since all of them notify
`HabitProvider`.

It also refreshes on resume (the day may have changed) and writes immediately
on pause, so the widgets are current when the app is backgrounded.

**Known gap:** a notification "Complete" pressed while the app is not running
is queued (`PendingCompletionQueue`) and only applied, and shown in widgets,
the next time the app opens.

## Day boundary without the app

The snapshot carries `tomorrow` and `nextDayStartsAt`, so widgets switch days
on their own:

- **iOS**: the `TimelineProvider` returns entries for now, 12:00, 19:00 and
  `nextDayStartsAt` (then the `tomorrow` block).
- **Android**: widgets choose today/tomorrow and the part of day from the
  clock whenever they render. `WidgetRefresh` keeps one inexact alarm
  (`AlarmManager.setWindow`, `RTC`, 10 minute window, so no exact-alarm
  permission and no wake-ups) armed for the next of 00:00, 04:00, 12:00,
  19:00 and `nextDayStartsAt`; `WidgetRefreshReceiver` redraws all four
  widgets and arms the next one. It also redraws on `TIME_SET`,
  `TIMEZONE_CHANGED`, `LOCALE_CHANGED`, `BOOT_COMPLETED` and
  `MY_PACKAGE_REPLACED` (alarms do not survive the last two). The alarm is
  re-armed whenever a widget renders and cancelled when none is placed. The
  plugin's `HomeWidget.scheduleWidgetUpdates` is not used: it would use exact
  alarms here, since the app holds `SCHEDULE_EXACT_ALARM` for habit alarms.

Opening the app rewrites the snapshot from real data, correcting anything the
`tomorrow` block could not know.

## Taps

Widgets launch `habitt://widget/home` or `habitt://widget/log?habit=<id>`
(iOS appends `homeWidget` to the query, which `home_widget` needs to recognise
the launch). `WidgetLaunchHandler.start` handles the launching tap and every
later one:

- `log` → `NotificationActionHandler.openHabit(id, day: today)`: Log progress
  over the main page, or the habit's details when it has nothing to log by
  hand (no tracking type, Health-linked, already done).
- `home` → back to the first route and the main tab.

When a tap is the first open of a new day, the streak celebration waits for
that Log progress dialog to close (`NotificationActionHandler.tapOpening`,
see `docs/support_asks.md`) instead of covering it.

iOS registers the `habitt` URL scheme in `ios/Runner/Info.plist`. Android
needs the `es.antonborri.home_widget.action.LAUNCH` intent filter on
`MainActivity`.

Android, after the process died with the task still alive (memory pressure,
`kill`): the tap recreates `MainActivity` with the task's old intent and
delivers the tap through `onNewIntent` before Dart listens, so home_widget
would drop it. `MainActivity.onNewIntent` therefore keeps a widget launch as
the activity's intent (`initiallyLaunchedFromHomeWidget()` then reports it),
and `onCreate` neutralises a restored widget-launch intent so reopening the
app later does not replay an old tap.

`adb shell am force-stop` cancels all of the app's PendingIntents, widget
taps included: the first tap afterwards only wakes the app (Glance redraws
the widget with new intents), the second one opens it. Normal process death
does not do this.

## Native side

iOS is not built yet (see `openspec/changes/home-widgets-readonly/tasks.md`
groups 1 and 4). Names the Dart side uses (`HomeWidgetKinds`):

| | iOS widget `kind` | Android receiver |
|---|---|---|
| Streak | `HabittStreakWidget` | `com.shellz.habitt.widgets.StreakWidgetReceiver` |
| Streak week | `HabittStreakWeekWidget` | `com.shellz.habitt.widgets.StreakWeekWidgetReceiver` |
| Today ring | `HabittTodayRingWidget` | `com.shellz.habitt.widgets.TodayRingWidgetReceiver` |
| Up next | `HabittUpNextWidget` | `com.shellz.habitt.widgets.UpNextWidgetReceiver` |

App Group: `group.com.shellz.habitt`. Widget picker names and descriptions
are the `widget*Name` / `widget*Description` ARB keys.

### Android (Jetpack Glance)

Code in `android/app/src/main/kotlin/com/shellz/habitt/widgets/`:

| File | Role |
|---|---|
| `WidgetSnapshot.kt` | Parses the snapshot (`v` must be 1), `placeholder` for before the first one, `blockAt(now)` (tomorrow from `nextDayStartsAt` on), `PartOfDay` (04/12/19), `WidgetClock.nextUpdate`. Pure Kotlin + org.json, tested in `android/app/src/test/.../WidgetSnapshotTest.kt` (`./gradlew :app:testDebugUnitTest`). |
| `HabittWidgets.kt` | The four `GlanceAppWidget`s and receivers (`HomeWidgetGlanceWidgetReceiver`, state from home_widget's preferences, `SizeMode.Exact`). |
| `WidgetUi.kt` | Colours (light/dark pairs from the design canvas, accent from the snapshot), tap links, bitmaps for what RemoteViews cannot draw (ring segments, week arcs, pies), shared pieces. |
| `WidgetRefresh.kt` | The boundary alarm and its receiver (see above). |

How it is drawn:

- **Light/dark without a redraw**: backgrounds are drawables with `-night`
  variants (`widget_bg_streak_*`, `widget_bg_tile_*`, `widget_bg_week_*`,
  `widget_bg_plain`, `widget_bg_upnext`: gradient, radial glow and artwork in
  one `layer-list`), and every other shape is a white mask (vector or bitmap)
  tinted with a day/night `ColorProvider`. On Android 12+ the launcher switches
  both itself; older versions pick the mode at the next redraw.
- Corner radius 24 (Up next rows 20, its streak tile 18); `cornerRadius` clips
  only on Android 12+, so on 8–11 the glow can show at the corners.
- Text uses the system font (widgets cannot use Satoshi).
- Today ring: track, fill (both tinted masks) and an emoji layer drawn with
  `Canvas` at the widget's size; `done/total` or an accent check in the
  centre. Above 8 habits the segments give way to one plain ring filled to the
  day's progress (done habits count 1, partial ones their share), no emojis. Tap: Log progress of the first counted habit not
  done, home when perfect or empty.
- Up next: as many rows as fit the height (at most 3), the section's label and
  icon (sun, moon, clock for Any time); "Day complete" when the section is null
  and the day has habits, `nothingToday` when it has none. Android cells are
  taller than the iOS design (a 4×2 is about 360×220 dp against 364×170), so
  `UpNextWidget.LAYOUT` picks how to fill them: `SCALED` (the iOS design
  scaled to the height, up to 1.3×), `CENTRED` (iOS sizes, centred
  vertically) or `STRETCHED` (iOS text sizes, rows grow to fill, up to 56 dp).
  Stretched is in use until one is chosen.
- No habits in the app at all (`hasHabits` false): Today ring and Up next show
  the app's empty box art (`widget_art_empty_box`) over `noHabits`. Rows open Log
  progress, the rest of the widget the home page.
- Streak / Streak week open the home page. Dormant streak: 0, "days streak"
  and the invite line, drawn with the healthy look (as the home page streak
  card does).
- Before the app wrote its first snapshot (installed, not opened yet) the
  widgets draw `WidgetStore.placeholder`: no habits, a 0 streak and an empty
  week, from the native strings in the device language.
- Picker previews: `drawable-nodpi/widget_preview_*.png`, cropped from emulator
  screenshots of the real widgets (light, Habitt green). Recapture them when a
  widget's look changes.
- `MainActivity` has the `es.antonborri.home_widget.action.LAUNCH` intent
  filter; taps use home_widget's `actionStartActivity<MainActivity>(context, uri)`.

Generated resources (rerun after changing the source):

- `dart run tool/svg_to_vector_drawable.dart`: `widget_art_*` VectorDrawables
  from `assets/images/new-svg/streak.svg`, `streak-fade.svg`, `ice-left.svg`,
  `ice-over.svg`, `empty-box.svg` (drop shadow dropped).
- `dart run tool/gen_android_widget_strings.dart`: `values[-xx]/widget_strings.xml`
  from the `widget*Name` / `widget*Description` ARB keys, plus the strings
  the placeholder needs (`youHaventAddedAnyHabitsYet`, `dayStreakLabel`,
  `daysStreakLabel`, `day`, `days`, `widgetStartStreak`).

## Adding or changing a widget

1. Add what it needs to the snapshot in `WidgetSnapshotBuilder` (bump `v` if
   an existing field changes meaning) and cover it in
   `test/services/widget_snapshot_builder_test.dart`.
2. Add its kind / receiver to `HomeWidgetKinds`.
3. Build the native views from the snapshot only.
4. Update this file.

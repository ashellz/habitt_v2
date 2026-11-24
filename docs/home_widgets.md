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
  "theme": { "light": { "accent": "#02D382" }, "dark": { "accent": "#11F29B" } },
  "strings": { "dayStreak", "daysStreak", "dayComplete", "dayCompleteBody", "nothingToday" },
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
  card; health via `resolveStreakHealth`. `tomorrow.streak` runs
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
  clock whenever they render; updates are scheduled at those boundaries
  (`HomeWidget.scheduleWidgetUpdates`).

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

iOS registers the `habitt` URL scheme in `ios/Runner/Info.plist`. Android
needs the `es.antonborri.home_widget.action.LAUNCH` intent filter on
`MainActivity`.

## Native side

Not built yet in this repository; see `openspec/changes/home-widgets-readonly/tasks.md`
groups 1, 4 and 5. Names the Dart side already uses (`HomeWidgetKinds`):

| | iOS widget `kind` | Android receiver |
|---|---|---|
| Streak | `HabittStreakWidget` | `com.shellz.habitt.widgets.StreakWidgetReceiver` |
| Streak week | `HabittStreakWeekWidget` | `com.shellz.habitt.widgets.StreakWeekWidgetReceiver` |
| Today ring | `HabittTodayRingWidget` | `com.shellz.habitt.widgets.TodayRingWidgetReceiver` |
| Up next | `HabittUpNextWidget` | `com.shellz.habitt.widgets.UpNextWidgetReceiver` |

App Group: `group.com.shellz.habitt`. Widget picker names and descriptions
are the `widget*Name` / `widget*Description` ARB keys.

## Adding or changing a widget

1. Add what it needs to the snapshot in `WidgetSnapshotBuilder` (bump `v` if
   an existing field changes meaning) and cover it in
   `test/services/widget_snapshot_builder_test.dart`.
2. Add its kind / receiver to `HomeWidgetKinds`.
3. Build the native views from the snapshot only.
4. Update this file.

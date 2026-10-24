# Habitt v2 — Health Sync

## Overview

Habitt can link individual habits to a metric from Apple Health (iOS) or
Google Health Connect (Android) — steps, sleep, exercise minutes, mindful
minutes, activity (exercise minutes, iOS only), active calories, or total
calories. When linked, the habit's
`amountCompleted`/`durationCompleted` are pulled from Health instead of
being entered by hand.

This is **read-only**: Habitt never writes to Health/Health Connect, and
never uploads Health data anywhere — the read happens on-device and only
updates the local Hive `habits`/`days` boxes, same as a manual completion.
It fits the app's local-first, no-server-collection design.

Sync runs on app open and app resume only — there is no background
delivery/observer registration, so progress updates the next time Habitt is
opened, not the instant new Health data appears.

## Data model

- `Habit.healthMetric` (`HealthMetricType?`, [`lib/models/health_metric_type.dart`](../lib/models/health_metric_type.dart)) —
  which metric drives this habit, or `null` if unlinked. A definition field,
  threaded through `Habit` exactly like `trackingType`/`amount`/`amountLabel`
  (constructor, `copy()`, `updateHabit()`, `applyMerge()`, `merge()`,
  `toMap()`/`fromMap()`) — see [`lib/models/habit.dart`](../lib/models/habit.dart).
- `HealthMetricType` maps to a `HabitTrackingType`: `steps` /
  `activeCalories` / `totalCalories` are amount goals (a raw count);
  `sleep` is an amount goal in **minutes** (so `toleranceMinutes` can apply
  to it — `HealthService.fetchValueForDay` returns sleep in minutes, and the
  habit card formats it as a duration via `getSleepAmountString`);
  `workouts` / `mindfulness` are duration goals by default (seconds,
  matching the app's post-migration duration schema — see
  `backup_system.md`'s "Duration Schema Version" section); `activity` is a
  duration goal with no Amount choice (see "Activity");
  `bedtime` / `wakeTime` are time-of-day goals (minutes since midnight).
- `HealthMetricType` is stored by enum index, so new metrics are only ever
  added at the end (`activity` is last).
- Linking a habit to a metric pins its `trackingType` to match (see
  `StateProvider.selectedHealthMetric` in
  [`lib/providers/state_provider.dart`](../lib/providers/state_provider.dart));
  the goal value itself (e.g. "10,000 steps") stays user-editable.

## Components

- [`lib/services/health_service.dart`](../lib/services/health_service.dart) —
  the only file that imports `package:health`. Wraps availability/permission
  checks and `fetchValueForDay(metric, day)`, which returns the metric's
  value in the habit's native unit (steps/calories as a plain count,
  everything else in seconds), or `null` on any failure.
- [`lib/providers/health_provider.dart`](../lib/providers/health_provider.dart) —
  `ChangeNotifier` holding `isAvailable`/`permissionGranted`/`isSyncing`
  state. `requestPermissionIfNeeded()` drives the OS permission prompt
  (called from the habit editor the first time a habit is linked).
  `syncNow()` walks every Health-linked habit and applies fresh values;
  it no-ops safely if unavailable, unauthorized, or already running, and
  never throws — a Health read failure must not block app-open flow.
- `HabitProvider.syncHabitFromHealth(id, metric, rawValue, {day})` in
  [`lib/providers/habit_provider.dart`](../lib/providers/habit_provider.dart) —
  applies one Health-derived value to one habit. Modeled directly on the
  existing `commitTimerDuration` (no `BuildContext` needed, since this runs
  headlessly from `HealthProvider.syncNow()`), and reuses the same
  `updateHabitInDB` / notification-resync / streak-refresh path a manual
  completion goes through.

## Lifecycle

1. **Habit sheet opens** ([`lib/widgets/sheets/habit_sheet.dart`](../lib/widgets/sheets/habit_sheet.dart)) —
   `HealthProvider.ensureAvailabilityChecked()` runs once, populating
   `isAvailable` so the "Sync from Health" section can decide whether to
   render at all.
2. **User links a habit** — toggling the section on calls
   `requestPermissionIfNeeded()`; on denial the toggle reverts and a dialog
   explains the habit won't auto-update until access is granted in Settings.
3. **App open / resume** ([`lib/pages/home_page.dart`](../lib/pages/home_page.dart)) —
   `HealthProvider.syncNow()` runs alongside the existing backup-sync /
   `updateLastOpenedDate` calls, fire-and-forget (`unawaited`), so it never
   delays the rest of the open/resume sequence.
4. **New habit saved** ([`lib/widgets/sheets/habit_sheet.dart`](../lib/widgets/sheets/habit_sheet.dart)) —
   a newly created Health-linked habit calls `HealthProvider.syncHabit(habit)`
   (fire-and-forget) so it starts with today's Health progress instead of 0
   until the next app open. It reads just that one habit, so it's safe while a
   `syncNow()` is running. Editing an existing habit does not trigger it.
5. **Per-habit sync** — for each linked, non-deleted, non-paused habit,
   `HealthService.fetchValueForDay` is read and, if non-null, applied via
   `HabitProvider.syncHabitFromHealth`.

## Habit details Health card

A Health-linked habit's details page
([`habit_details_page.dart`](../lib/pages/other_pages/habit_details_page.dart))
shows a `HealthStatsCard`
([`lib/widgets/habit_details/health_stats/`](../lib/widgets/habit_details/health_stats/)),
on iOS and Android only:

- **Header** — "Apple Health" / "Health Connect" and a status line:
  syncing, not synced yet, or `Last synced: …`. On Android with Health
  Connect access missing the line becomes a tappable prompt that requests
  access and re-syncs (iOS can't report read access, so it never shows
  this). `HealthProvider.lastSyncedAt` is persisted in `SharedPreferences`
  (`healthLastSyncedAt`) so it survives restarts; it is loaded the first time
  `ensureAvailabilityChecked()` runs.
- **Last 7 days chart** (`HealthWeekChart`) — bars against a dashed target
  line for counts, durations and sleep; dots on a time axis with the target
  line (and tolerance band) for bedtime and wake time. There is no separate
  history store: [`lib/util/health_history.dart`](../lib/util/health_history.dart)
  (`buildHealthHistory`) reads each day's progress from that day's habit
  snapshot (`HabitProvider.habitForDay`), so a day with no snapshot, or a
  time-of-day habit whose progress is 0, is a gap. The window ends on
  `healthSyncDay` — the day a sync run writes to, i.e. **yesterday for a
  bedtime counted on the day before** — which `HealthService.syncDayFor`
  also uses so the two can't drift.
- **Total stat** — the details page's "Total" stat card sums the habit's
  logged amount; for a sleep habit (minutes) it's scaled to seconds and shown
  as a duration ("240h") instead of a raw "14400 times".
- **Sessions** (`HealthSessionsList`) — collapsed by default; lists the
  `Habit.healthSessions` stored on that latest day's snapshot (time range and
  duration; workout type for workouts). Not shown for steps and calories,
  which have no sessions. Bedtime habits also show which day the night
  counts on.

## Day attribution (sleep sessions)

Most metrics are read midnight-to-midnight for the day being synced. The
sleep-derived metrics (`sleep`, `bedtime`, `wakeTime`) are not cut by a clock
window. `HealthService._fetchSleepSessions` reads the day before through the
day after, groups the samples into sessions (`lib/util/sleep_sessions.dart`:
samples less than `sleepSessionMaxGap`, 3 h, apart are one session, so a nap
stays separate from the night), and keeps the sessions that belong to the day.
A session's day is always derived from the day it **ends** (the wake-up day) —
there is no clock-hour cutoff anywhere.

Which samples are read (`_iosSleepTypes` / `_androidSleepTypes`): every asleep
sample, staged or not — `SLEEP_ASLEEP`, `SLEEP_LIGHT` (Apple's "core"),
`SLEEP_DEEP`, `SLEEP_REM`. Apple Watch on iOS 16+ and most Health Connect
trackers only write the stages, so reading `SLEEP_ASLEEP` alone misses them.
Awake and in-bed samples are never read. Android also reads `SLEEP_SESSION`
(the whole record, awake time included) for sources that log a night without
stages; `groupSleepSessions` drops a session record wherever a stage sample
overlaps it. All of these sit behind the same permission (`sleepAnalysis` on
iOS, `READ_SLEEP` on Android), so no new prompt is needed.

A session's minutes are the time covered by **at least one** sample, not the
sum of the samples, so overlapping samples count once — two apps recording
the same night, or a stage inside a broader asleep block. Gaps between
samples (wake-ups) don't count.

- `sleep` — total minutes of every session that ended that day.
- `wakeTime` — end of the longest session that ended that day.
- `bedtime` — start of the longest session counted on that day. Which day that
  is is a per-habit choice, `Habit.healthBedtimeDayBefore` (editor: "Count
  bedtime on" in the bedtime health widget):
  - **Wake-up day** (default, `false`) — the session counts on the day it
    ends, same as `sleep`/`wakeTime`. Going to bed Monday night counts for
    Tuesday. Works unchanged for night-shift sleep (07:00–17:00).
  - **Day before** (`true`) — the session counts on the day before it ends.
    Going to bed Monday night counts for Monday, regardless of the hour.

Sessions are not clipped at any hour, so a night that ends at 13:00 is read
whole. `HealthService.syncDayFor` returns today for everything except a
day-before bedtime, which returns yesterday (the night that ended this
morning). The session list stored on the habit is these grouped sessions, not
the raw samples. Changing the setting does not move bedtimes already recorded
— sync only touches the current target day.

## Workouts/mindfulness tracking mode

`workouts` and `mindfulness` are the only two metrics where a habit's own
`trackingType` can diverge from the metric's fixed default (`workouts`/
`mindfulness` both default to `duration`, but the habit editor lets the user
choose Amount instead — a session count — for either one, for any workout
filter including "Any"). `HealthMetricTypeMapping.supportsTrackingChoice`
marks these two metrics; `HealthService.fetchValueForDay` already reads the
right raw value for either mode (session count in Amount mode, summed
seconds in Duration mode), and `HabitProvider.syncHabitFromHealth` routes
that value into `amountCompleted` or `durationCompleted` by the *habit's*
`trackingType`, not the metric's fixed one — this is the one place that
must read `habit.trackingType` instead of `metric.trackingType` for these
two metrics; every other metric keeps using the fixed mapping.

A workout/mindfulness habit with no target set (`amount == 0` in Amount
mode, or `duration == 0` in Duration mode) is a valid, intentional state —
it means "any logged session counts," not "always complete." Because the
normal `amountCompleted/durationCompleted >= target` comparison is
vacuously true against a target of 0, `syncHabitFromHealth` overrides
`habit.completed` in that case to `sessions.isNotEmpty` instead — complete
only if at least one matching session was logged that day, using the same
`sessions` list already fetched via `fetchSessionsForDay` for that sync
pass (no extra Health read).

## Workout reads

Both platforms read `WORKOUT` records — one record per workout, each with an
activity type. `HealthService._fetchWorkoutSessions` is the single path for
every workout habit, in both tracking modes and for the Sessions list:

- **Habit linked to one type** (Walking, Running, …) keeps only records of
  that `HealthWorkoutType`; everything else is ignored.
- **"Any" workout habit** keeps every type, including ones with no dedicated
  filter (they show as `other`).
- **Duration** is the time each session covers (`end - start`), not a sample
  value — `WORKOUT` records have no numeric value on either platform.
  **Amount** is the number of sessions.

Records that overlap in time are folded into one session by
`dedupOverlappingSessions`
([`lib/util/workout_sessions.dart`](../lib/util/workout_sessions.dart)), after
the type filter. The same workout often arrives twice (watch and phone, or
watch and a third-party app); counting both doubled the count and the
duration. A merged session spans all its records, takes the type of the
longest, and its duration counts overlapping time once. Workouts that only
touch (a run followed by a cool-down walk) stay separate.

iOS used to read Apple's `EXERCISE_TIME` for an unfiltered workout habit. That
is one-minute samples of brisk activity with no type, not workouts, so a
single walk showed up as many "workouts" (task 18). Workout habits no longer
read it: they only count real workouts. Activity Apple credits as exercise
minutes but that was never started as a workout is what the separate
**Activity** metric is for (next section).

`WORKOUT` is part of the iOS read permission set, so
`requestAuthorization()` asks for it. Users who linked a workout habit before
this were never asked, so `HealthProvider.syncNow` / `syncHabit` call
`requestAuthorization()` once per launch on iOS when a workout or activity
habit is linked (`_requestIosAccessOnce`); HealthKit only shows the sheet for
types not yet answered, so it is silent otherwise.

## Activity (exercise minutes)

`HealthMetricType.activity` mirrors the Apple Watch Exercise ring: every minute
of brisk movement counts, whether or not a workout was started. It is separate
from `workouts` on purpose — workouts are typed, user-started sessions;
exercise minutes are untyped one-minute samples. A walk to the shop can fill
the ring and leave a Workout habit at zero.

- **iOS only.** Health Connect has no exercise-minutes record, so
  `_androidTypes` has no `activity` entry, the metric picker doesn't offer it,
  and the premade "Activity" template (`PremadeHabitType.activity`,
  `PremadeHabitTemplate.iosOnly`) is hidden from the premade sheet elsewhere.
- **Needs an Apple Watch in practice.** Exercise minutes are measured by the
  watch; an iPhone on its own doesn't record them, so such users see 0. The
  picker description says so ("Tracks your exercise ring from Apple Watch").
- **Duration only** (`supportsTrackingChoice` is false): no Amount mode and no
  type filter. The default goal is 30 minutes, Apple's default ring goal.
- **Read:** `EXERCISE_TIME` samples (`HealthService._fetchActivitySamples`).
  Workouts count toward it too, but only the brisk part, so a gentle yoga
  session may add little. The habit shows what Apple credits, same as the ring.
- **Value:** the time covered by at least one sample
  (`activeTimeCovered` in
  [`lib/util/activity_sessions.dart`](../lib/util/activity_sessions.dart)), so
  the same minute reported by two sources counts once.
- **Sessions list:** `groupActivityPeriods` joins samples at most
  `activityPeriodMaxGap` (2 minutes) apart into periods, so 23 consecutive
  minutes show as one "10:02 – 10:25" row. A period's duration is its span, so
  it can be a minute or two longer than the habit's progress when small gaps
  were joined.

## Manual override

A Health-linked habit's progress can be edited by hand (log progress dialog,
or completing/uncompleting it). That's for the case where the user did the
thing but never logged it in Health, or logged it wrong.

- `Habit.healthManualOverride` is **per-day state**, living on the day's
  snapshot next to `healthSessions`. Any hand-edit of a habit with a
  `healthMetric` sets it (`HabitProvider._markHealthManualOverride`, called from
  `updateHabitAmountCompleted`, `updateHabitDurationCompleted` and
  `completeHabit` — not when un-skipping, which only resets progress to 0).
  Timer commits never set it: Health-linked duration habits have no timer
  (`Habit.supportsTimer`), so there is one writer for progress at a time.
- `syncHabitFromHealth` checks the flag on the day it's writing to. When set,
  it **only refreshes `healthSessions`** and returns: progress, completion,
  streak and notification bookkeeping are untouched. The sessions list stays
  live because it's informational, and the "Sessions" section should keep
  showing what Health actually recorded.
- The flag only protects the day it was set on. New days start clear
  (`copyResetCompletion`, `resetCompletion`, `clearDayState`), and a past day
  edited by hand stays frozen.
- **Hand it back:** `HealthOverrideTag`
  ([`lib/widgets/default/health_override_tag.dart`](../lib/widgets/default/health_override_tag.dart))
  renders "Edited manually · Use Apple Health values" (Health Connect on
  Android) in the log progress dialog and at the top of the details-page
  `HealthStatsCard`. Tapping it calls `HealthProvider.useHealthValues(habit, day)`,
  which clears the flag (`HabitProvider.clearHealthManualOverride`) and
  immediately re-syncs that exact day, so the Health value replaces the hand
  edit right away. It behaves like a sync for the Health card: `isSyncing` is
  set while it runs (header shows "Syncing…"), and when Health returned a value
  `lastSyncedAt` is stamped and persisted, so "Last synced" is current. If
  Health is unavailable or has no value at that moment the flag is still
  cleared, `lastSyncedAt` is left alone, and the next sync applies the value.
- **One-time explanation:** the first time a hand-edit pauses Health sync,
  `HealthOverrideNotice.showIfNeeded`
  ([`lib/util/health_override_notice.dart`](../lib/util/health_override_notice.dart))
  opens `HealthOverrideNoticeDialog` explaining that Apple Health / Health
  Connect is paused for that day and how to get it back. It has a single
  "Understood" button that stays disabled for 3 seconds, counting down in its
  label ("Understood (3)"), and can't be dismissed any other way. Gated by the
  `healthOverrideNoticeShown` SharedPreferences bool, set the moment the dialog
  opens so it never repeats. Triggered from `LogProgressDialog` (after it
  closes, via the root navigator's context) and from `HabitProvider.completeHabit`
  (long-press complete/uncomplete); only when the edit actually newly sets the
  flag.
- Syncing and the backup system: the flag is serialized in `toMap`/`fromMap`
  (absent in older backups = `false`) and merged with the completion tuple
  (`pickDayState`), so it travels with the progress it protects. Hive field
  index 52.

## Completion side effects

When a sync flips a habit's `completed` flag, `syncHabitFromHealth` does the
same bookkeeping as a manual completion (`completeHabit`): it updates the
weekly/monthly `timesCompletedThisWeek`/`timesCompletedThisMonth` counters on
the real habit (`_updatePeriodCountersForId`), reschedules notifications,
refreshes the perfect-streak flag, and for past days re-runs `assignStreaks`.
Timer commits (`commitTimerDuration`) and the progress dialogs do likewise.

## Habit notifications

Reminder text is built when the notification is *scheduled* (up to 7 days
ahead, on the first app open of the day and on completion changes) and handed
to the OS as a fixed string. Health only syncs on app open/resume, so a
Health-linked habit's progress can be hours out of date when the reminder
fires — a "6 of 230 calories" notification after a long workout.

So for a habit with `healthMetric` set, `HealthMetricNotificationText` and
`SleepNotificationText` never quote progress: they use only the goal wording
(the `…Start` strings; `notificationSleepGoal`). The `…Progress` strings are
used only for hand-logged habits (no `healthMetric`, e.g. a premade steps
habit with Health sync off), whose progress is always current. Completion
still cancels that day's reminder (`_syncNotificationsOnCompletionChange`).

## Tolerance (sleep, bedtime, wake time)

`Habit.toleranceMinutes` (15/30/60 presets) is a "close enough" margin and only
makes sense for `sleep` (completed at `amountCompleted >= amount - tolerance`),
`bedtime` and `wakeTime` (completed at `amountCompleted <= amount + tolerance`,
earlier is always fine). `HealthMetricType.supportsTolerance` is true for
exactly those three.

Completion logic never reads the raw field: it goes through
`Habit.effectiveToleranceMinutes`, which returns `toleranceMinutes` only when
`healthMetric.supportsTolerance` and `0` otherwise. This matters because the
stored value can be stale — the habit sheet's `StateProvider.toleranceMinutes`
is shared editor state that selecting the sleep metric sets to 30 and nothing
clears when the user switches to another metric — and a stray 30 on a plain
amount habit would otherwise make it count as completed at a fraction of its
target, with no way to uncomplete it. `updateHabitAmountCompleted`,
`updateHabitTimeOfDayCompleted` and the goal-change recompute in
`Habit.updateHabit` all use the effective value so logging progress and
editing the target agree.

## Platform differences

Health Connect (Android) has no mindfulness record type —
`mindfulMinutes` is iOS-only — and no exercise-minutes record, so `activity`
is iOS-only too. Workouts read the same `WORKOUT` records on both
platforms (see "Workout reads").
`HealthService.supportedMetrics` reflects this per-platform, and the habit
editor's metric picker only offers what's actually supported.

## Native setup

- **iOS**: `NSHealthShareUsageDescription` in `ios/Runner/Info.plist`, and
  `com.apple.developer.healthkit` in `ios/Runner/Runner.entitlements`.
  Read-only — no `NSHealthUpdateUsageDescription` needed.
- **Android**: Health Connect read permissions in
  `android/app/src/main/AndroidManifest.xml`
  (`READ_STEPS`/`READ_SLEEP`/`READ_EXERCISE`/`READ_ACTIVE_CALORIES_BURNED`/
  `READ_TOTAL_CALORIES_BURNED`/`READ_HEALTH_DATA_HISTORY`), plus
  `ACTIVITY_RECOGNITION` (the OS-level sensor permission Health Connect's
  step data sits on top of) and the permissions-rationale/privacy-policy
  intent filters Health Connect requires.
  `ACTIVITY_RECOGNITION` is a "dangerous" classic Android runtime
  permission — declaring it in the manifest isn't enough, and Health
  Connect's own consent screen (`Health.requestAuthorization`) doesn't
  request it either. `HealthService.requestAuthorization()` requests it
  separately via `permission_handler` (`Permission.activityRecognition`)
  before requesting Health Connect access, per the `health` package's own
  setup docs. A denial there isn't fatal — it only affects steps reads,
  which `fetchValueForDay` already returns `null` for on any failure.

## Maintenance rule

Any change to Health sync (new metric, changed windowing, permission flow)
must also update this document.

# Habitt v2 — Health Sync

## Overview

Habitt can link individual habits to a metric from Apple Health (iOS) or
Google Health Connect (Android) — steps, sleep, exercise minutes, mindful
minutes, active calories, or total calories. When linked, the habit's
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
  `sleep` / `exerciseMinutes` / `mindfulMinutes` are duration goals
  (seconds, matching the app's post-migration duration schema — see
  `backup_system.md`'s "Duration Schema Version" section).
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
4. **Per-habit sync** — for each linked, non-deleted, non-paused habit,
   `HealthService.fetchValueForDay` is read and, if non-null, applied via
   `HabitProvider.syncHabitFromHealth`.

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

## Platform differences

Health Connect (Android) has no mindfulness record type and no direct
"exercise time" quantity — `mindfulMinutes` is iOS-only, and
`exerciseMinutes` on Android is derived by summing workout session
durations (`dateTo - dateFrom`) rather than reading a quantity value.
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

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
opened, not the instant new Health data appears. Days the app wasn't opened on
are caught up on the next open, up to 14 days back (see "Catching up on past
days").

With several phones on one Google Drive backup, only one of them reads Health;
the others get its values through sync (see "Several devices").

## Data model

- `Habit.healthMetric` (`HealthMetricType?`, [`lib/models/health_metric_type.dart`](../lib/models/health_metric_type.dart)) —
  which metric drives this habit, or `null` if unlinked. A definition field,
  threaded through `Habit` exactly like `trackingType`/`amount`/`amountLabel`
  (constructor, `copy()`, `updateHabit()`, `applyMerge()`, `merge()`,
  `toMap()`/`fromMap()`) — see [`lib/models/habit.dart`](../lib/models/habit.dart).
- `HealthMetricType` maps to a `HabitTrackingType`: `steps` /
  `activeCalories` / `totalCalories` are amount goals (a raw count);
  `sleep` is an amount goal in **minutes** (so `toleranceMinutes` can apply
  to it — `HealthService.fetchDay` returns sleep in minutes, and the
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
  checks and `fetchDay(metric, day)`, which reads the day **once** and returns a
  `HealthDayReading`: the metric's value in the habit's native unit
  (steps/calories as a plain count, sleep in minutes, time of day in minutes
  since midnight, everything else in seconds) and the sessions behind it
  (empty for steps and calories). It is `null` on any failure, or for a
  bedtime/wake time with no sleep that day. Value and sessions come from the
  same read, so they can't disagree and a sync never reads a day twice.
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
   explains the habit won't auto-update until access is granted in Settings
   (`showHealthPermissionDeniedDialog`).
   Picking a **premade** habit with a Health metric goes through the dialog
   below first (see "Premade habits and the permission flow").
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
   `HealthProvider._catchUpHabit` reads the habit's sync day and the days it
   missed (next section). Each day goes through
   `HealthService.fetchDay` and, if non-null, is applied via
   `HabitProvider.syncHabitFromHealth`, which throws away empty or corrupt
   reads (see "Empty and corrupt reads").

## Catching up on past days

A sync used to write only the current sync day, so a day the app wasn't opened
on (a night's sleep, a bedtime, a workout) stayed empty. Each habit now keeps a
**cursor** — the last day its sync reached — and a run reads the days since it.
It never re-reads a fixed window on every open.

- **Cursor:** per habit, a date (not a timestamp), stored as a JSON map
  `habitId -> yyyy-MM-dd` in `SharedPreferences` (`healthSyncCursors`). It is
  sync bookkeeping, not habit data, so it stays out of Hive and the backup
  system. `lastSyncedAt` (`healthLastSyncedAt`) is separate and only drives the
  "Last synced" label.
- **Range:** `healthCatchUpDays`
  ([`lib/util/health_sync_range.dart`](../lib/util/health_sync_range.dart))
  returns the habit's sync day first (what the user is looking at), then the
  days from the cursor up to it, oldest to newest. The cursor day itself is read
  **again**, so a night a watch uploaded after midnight settles on the next
  open; after that it is final. A second open the same day just re-reads
  today.
- **Cap:** `kHealthBackfillMaxDays` = 14 days before the sync day. Health
  Connect only lets an app read the 30 days before its first permission grant;
  `READ_HEALTH_DATA_HISTORY` (declared in the manifest, but a separate user
  grant that isn't requested yet) lifts that. Two weeks stays well inside the
  default window and bounds the reads after a long absence. A "backfill
  everything" option is planned for later and would use that permission.
- **No cursor = no backfill.** A habit that was just linked
  (`HealthProvider.syncHabit` sets the cursor to the link day) or that has
  never synced reads only its sync day, so it never fills days before it was
  linked. Habits that were linked before this existed get their cursor on the
  first run.
- **Floor:** `healthBackfillFloor` — never before the habit's `createdAt`, and
  never before the day it was last paused or unpaused (`timestamps['isPaused']`).
- **Paused, unlinked and deleted habits lose their cursor.** `syncNow` drops the
  cursor of any habit it doesn't sync, so unpausing (or relinking) starts from
  that day. Paused habits don't appear on past days, and unpausing must not
  re-add the paused stretch.
- **Which days are written:** days the habit isn't on (before it existed, not
  scheduled) are skipped without a Health read
  (`HabitProvider.canSyncHealthDay`). Days with `healthManualOverride` keep
  their progress, as before (only the sessions list refreshes). Completed days
  in range are refreshed: Health is the source of truth for a linked habit.
- **Failures:** the new cursor is the earliest day whose read failed (`null`),
  so it is retried next open, or the sync day when every read went through. An
  empty or corrupt read that was discarded does not count as a failure.
- **Day attribution:** every day goes through `syncDayFor`/`_syncHabitDay`, so
  bedtime "day before" and sleep land on the right day. Switching a bedtime
  habit to "day before" moves its sync day back one; a cursor on or after the
  sync day just reads the sync day.
- **Streaks:** past days are written with `refreshStreaks: false`, and
  `assignStreaks(habitId)` runs once at the end of a habit's catch-up if any
  past day flipped its completion.
- **Unchanged reads write nothing.** Today and the cursor day are re-read on
  every open, so `syncHabitFromHealth` compares the result with what the day
  holds. Same progress, same completion and same sessions
  (`sameHealthSessions`) means no Hive write, no `notifyListeners`, no
  notification or streak work and no `scheduleAutoSync` (a cloud backup).
  `Habit.updateHabit*Completed` stamp their timestamps even for an identical
  value, and backup merge goes by those, so the sync restores them when nothing
  changed instead of looking like a fresh edit. The cursors are only written
  back when they moved.
- **Timing and UX:** it is the same fire-and-forget `syncNow()` as before and
  yields between habits and days, so app open isn't delayed. It is silent: no
  toast or dialog, the days just show up in the calendar and the details chart.

## Empty and corrupt reads

Health is followed, even where it is lower than what was recorded (the user
may have edited Health by hand). Only two kinds of read are thrown away, for
today and past days alike — the existing value is kept
([`lib/util/health_value_guard.dart`](../lib/util/health_value_guard.dart),
checked in `HabitProvider.syncHabitFromHealth`):

- **Empty:** `0` where the day already has progress. iOS can't report revoked
  read access, it just answers with nothing, and Health Connect returns nothing
  outside its readable window; without this a revoked permission would zero
  every day it read. An empty read on an empty day is a normal write.
  Consequence: deleting everything for a day in Health doesn't clear it in
  Habitt (a hand edit or `useHealthValues` still can).
- **Corrupt:** a value no real day has (`isPlausibleHealthValue`): negative,
  over 200k steps, over 20k kcal, over 24 h of sleep/exercise, over 200
  workout sessions, a time of day out of range.

`syncHabitFromHealth` returns a `HealthApplyOutcome` (`applied`, `skipped` or
`discarded`, plus whether the completion flipped). A discarded read doesn't
stamp `lastSyncedAt` and doesn't hold the cursor back.

## Premade habits and the permission flow

The habit sheet no longer fires the OS permission prompt by itself when a
premade template with `defaultHealthMetric` is applied (task 58). Instead the
user is asked in-app first, so the OS prompt is never a surprise:

1. **Pick a premade habit** — the habit sheet opens first with the template
   applied, then `HabitSheet._resolvePremadeHealthSync` calls
   `askPremadeHealthSync` and the dialog appears over the open sheet.
   `PremadeHealthSyncDialog`
   ([`lib/widgets/dialogs/premade_health_sync_dialog.dart`](../lib/widgets/dialogs/premade_health_sync_dialog.dart))
   asks whether to sync with Apple Health (iOS) or Health Connect (Android),
   using the What's New health graphic (`WhatsNewHealthGraphic` in a
   `WhatsNewGraphicFrame`). It isn't dismissible by tapping outside; the answer
   is explicit.
2. **Accept** — the dialog warns that the phone will ask for access next and
   that it must be allowed for syncing to work. The sheet stays open with the
   metric linked, and only then `requestHealthAccessOrRevert` asks the OS
   (`HealthProvider.requestPermissionIfNeeded()`). If the OS **denies**
   (Android only, see below), the habit is silently reverted to manual
   (`StateProvider.disablePremadeHealthSync`). Turning Health on again with the
   toggle asks the OS again; if that fails too,
   `showHealthPermissionDeniedDialog` explains the habit won't update and has
   an "Open Settings" button (`openAppSettings`).
   `premadeHealthSyncAccepted` is saved to `SharedPreferences`.
3. **Decline** — the template stays applied but sync is turned off:
   `disablePremadeHealthSync` clears `selectedHealthMetric`, the workout
   filter and tolerance, and resets the target for manual tracking. Bedtime and
   wake time (times of day) become a plain done/not-done habit; sleep becomes a
   duration of the same length; steps/calories keep their amount and
   workouts/mindfulness/activity keep their duration. The user can still link
   Health later from the sheet's toggle.
4. **Field-by-field apply** — `OverrideHabitTypeFieldsDialog` (the sheet's
   "apply a premade type" path, `PremadeTemplateField.healthSync`) asks the same
   question when the habit isn't linked yet and the Health field is ticked.
   Declining just drops the Health field from the applied set; denial reverts
   the toggle like above.

**Asked once ever, then a setting.** Whether premade Health habits sync is a
plain on/off stored as `premadeHealthSync` (`SharedPreferences`; absent = not
decided yet). The first premade Health habit picked while it's absent shows the
dialog; the answer is saved there and the dialog never shows again. Toggling
Settings → Preferences → "Health sync for premade habits" (`PremadeHealthSetting`)
also sets it, and from then on only that toggle changes it. The toggle is shown
on iOS / Android only when Health is available; not decided yet reads as off.
`decidePremadeHealthPrompt`
([`lib/util/premade_health_sync.dart`](../lib/util/premade_health_sync.dart))
decides:

- Template has no Health metric: nothing to ask, nothing changes.
- Health isn't available (web/desktop, Health Connect missing) or the platform
  doesn't support the metric (Mindfulness on Android): the sheet opens with sync
  **off**, no dialog, and the setting is left alone.
- Not decided yet: the dialog.
- Setting **on**: Health is linked without asking; the OS permission request
  still runs (silent when access is already granted, and the first time it asks
  for any newer data type such as Activity or Workouts). If Android refuses it,
  the habit reverts to manual silently and the setting stays on.
- Setting **off**: the sheet opens with sync off.
- The per-habit Health toggle in the sheet always works regardless.
- `iosOnly` templates (Activity) are only offered on iOS; the flow is identical.

**Access revoked later (Android).** `HealthProvider.syncNow` re-reads
`hasPermissions()` on every run. If access was taken away it sets `accessLost`
and skips the sync; `HomePage._syncHealth` then shows
`showHealthAccessLostDialog` once per app run, explaining that syncing no longer
works, with an "Open Settings" button (`openAppSettings`). The flag clears on the
next sync once access is back.

**iOS can't report a refusal.** HealthKit never discloses read access:
`requestAuthorization` returns `true` once the sheet was shown and
`hasPermissions` returns `null`, so a declined iOS prompt looks like a granted
one, the habit stays linked, and iOS won't show the sheet again for a type
already answered. Instead, the details-page `HealthStatsCard` shows a hint with
an "Open Settings" button when a linked habit has had no data (null or 0) for
the last 3 days (`shouldHintHealthAccess` in
[`lib/util/health_missing_data.dart`](../lib/util/health_missing_data.dart);
habits younger than 3 days are never flagged). Android reports denial reliably,
so it gets the full revert / re-ask / Settings flow above.

Demo habits (`lib/demo/`) and onboarding never create Health-linked habits
from templates, so they don't touch this flow.

## Several devices

Health stores don't sync with each other: an iPhone and an Android phone (or
two Android phones — Health Connect stays on the device) each hold their own
numbers. Before this, every phone synced its own Health into the shared habit,
each write won the backup merge (latest timestamp), and the phones overwrote
each other on every open, flipping completion and streaks.

So with two or more phones on one **Google Drive** backup, exactly one reads
Health — the **Health sync device**. The others never read Health and just
receive its values through backup sync. iCloud is left out: iCloud devices
share one Apple ID, so one Apple Health already.

- **Device list:** `SyncDevicesProvider`
  ([`lib/providers/sync_devices_provider.dart`](../lib/providers/sync_devices_provider.dart))
  holds every phone syncing the account and the pick; it travels inside Drive
  backups and deltas (`backup_system.md` § "Device List" has the format, merge
  and cost). Only iOS / Android list themselves.
- **Who reads:** the picked device while it's listed; with no pick, the device
  that has had the app longest (earliest install time, then id), skipping
  devices whose entry says Health isn't available there (`healthAvailable ==
  false`; with none able to read, the oldest still is the default). Every phone
  computes the same answer from the same list. One phone alone (or no Drive)
  always reads, exactly as before. `SyncDeviceList.healthSourceId` in
  [`lib/models/sync_device.dart`](../lib/models/sync_device.dart).
- **The others** (`readsHealthHere == false`): `syncNow` reads nothing and drops
  every catch-up cursor, so if the phone is picked later it starts from that
  day instead of backfilling over the other phone's history. `syncHabit` and
  `requestPermissionIfNeeded` skip Health too (linking a habit there asks for
  no access), and `accessLost` is cleared, so no access dialogs show for a
  phone that doesn't read.
- **Hand edits** work on every phone as before (`healthManualOverride` travels
  with the day). "Use … values" clears the override anywhere; on a phone that
  doesn't read, the reading phone applies the Health value on its next open.
  Clearing stamps the day-state so it wins the merge (`backup_system.md`,
  "Companion day-state fields").
- **Settings → Sync → Health sync from** (`HealthDeviceSetting`,
  [`lib/widgets/settings/health_device_setting.dart`](../lib/widgets/settings/health_device_setting.dart)):
  shown on every phone once two are listed. One row per phone ("iPhone 17 ·
  iOS 26.6", then "This device" or the day it last synced), a check on the
  reading one. Picking uploads on the next auto-sync; picking this phone also
  asks for Health access and syncs right away.
  - A phone that can't be the reader (`SyncDevice.canReadHealth`: its entry
    says Health isn't available, e.g. Health Connect not installed) is greyed
    out and has an info button (`info.svg`) instead of the check; it and the
    row open a `NewDefaultDialog` saying why. Older app versions don't send
    the flag, so their phones stay pickable.
  - Which metrics a phone can read follows from its platform
    (`SyncDevice.canReadMetric`: Android has no `HealthMetricType.isIosOnly`
    metric). Tapping a phone that can't read a metric some linked
    (non-deleted) habit uses, i.e. an Android phone while an Activity or
    Mindfulness habit exists, asks first (`confirmAndroidHealthSource`:
    Cancel / "Switch anyway"). Switching is allowed: everything else syncs
    from the Android phone, and those habits keep their data but stop
    updating until an iPhone reads Health again.
- **Details card:** on a phone that doesn't read, the header shows the reading
  phone's store (logo and name), "From iPhone 17 · iOS 26.6" and a
  "Last synced: Today / 2 Nov" line from the reading phone's device entry
  (`lastSeen`, refreshed about once a day, so a day, not a time), and the iOS
  no-data access hint is hidden. The card only checks for iOS / Android, not
  `isAvailable`, so a phone without Health Connect still shows the data.
- **Editor** (`HealthWidget`): the logo, title and description show the
  *incoming* store (`SyncDevicesProvider.healthPlatform`), but the metric
  picker lists only *this* phone's `supportedMetrics`, so a new habit never
  gets a metric that dies when the reader changes. A habit already linked to a
  metric this phone can't read (Activity / Mindfulness viewed on Android)
  keeps it as the selection in the pill and picker. Turning the toggle off for
  such a metric asks first (it can't be turned on again from this phone);
  normal metrics need no confirmation. The whole section is hidden on a phone
  without Health (`!isAvailable`), and then the save keeps the habit's Health
  link and targets (`keepHiddenHealthFields`, see "Editor without Health").
  `HealthOverrideTag` names the reading phone's store too
  (`SyncDevicesProvider.healthBrand`).
- **Older app versions** don't know the pick and keep reading Health. They're
  listed from their backup metadata, so picking one simply stops the updated
  phones from fighting it.

## Editor without Health

`HealthWidget` hides itself on a phone without Health (web, desktop, Android
without Health Connect, or before the sheet's availability check finished).
The habit sheet hydrates every Health field from the habit and writes them all
back on save, so to make sure such a save can never unlink a habit or change
its goal, `_saveHabit` ends with `keepHiddenHealthFields`
([`lib/util/health_editor_fields.dart`](../lib/util/health_editor_fields.dart)):
when `healthEditorShown(...)` is false and the habit was linked, it puts back
`healthMetric`, the workout filter, bedtime day, tolerance, tracking type,
amount, duration and amount label from the stored habit. Unchanged values get
no new field timestamp, so the save can't win a merge against the reading
phone either. Covered by `test/util/health_editor_fields_test.dart`.

## After a restore

Every successful restore marks `BackupProvider.markRestored()`: Drive / iCloud
auto-restore into an empty app, "Merge" and "Start fresh" from the restore
choice, restore / replace from a backup file (also with a passphrase), the
first sync after an interrupted sign-in, and the local file import
(`BackupService.importLocalData`). `HomePage` takes the flag once
(`takeHealthRestoreNotice`, not while a sync is running) and calls
`showHealthRestoreNotice`
([`lib/widgets/dialogs/health_restore_dialog.dart`](../lib/widgets/dialogs/health_restore_dialog.dart)).

It shows nothing when Health is already being synced: another device is the
reader (e.g. an iPhone reading Apple Health, whose values reach this phone
through sync; switching is left to the picker), or this phone has synced
Health before (`lastSyncedAt`, e.g. its own local file restored). Otherwise
it splits the non-deleted Health habits by whether this phone can read their
metric (`checkRestoredHealthHabits`,
[`lib/util/health_restore_check.dart`](../lib/util/health_restore_check.dart)):

- **All readable:** this phone's store logo, "Sync Health habits from this
  phone?" (Not now / Sync).
- **Some readable** (Apple Health exclusive habits restored onto Android, e.g.
  from an iPhone's local file): the same logo and title, then two groups of
  premade-style pills (`HealthRestoreHabitGroups`): the habits that will
  sync, then "Apple Health only" (dimmed, with "These habits are Apple Health
  exclusive…"). Cancel / Sync.
- **None readable** (no Health Connect, web/desktop, or only iOS-only metrics
  on Android): the logo, "{source} unavailable", and that they keep their
  data and can be edited by hand but won't update here.

"Sync from this phone": when any other device is listed, this phone lists
itself (`listForUpload`) and becomes the pick (`setHealthSource`, uploaded on
the next auto-sync); then Health access is requested and
`HealthProvider.syncNowWithCatchUp()` runs, which gives every linked habit
without a cursor one `kHealthBackfillMaxDays` back (a restored habit has none,
so a plain `syncNow` would read only today). "Not now" changes nothing. Note
that with no other device listed (e.g. a local file restore without Drive)
this phone reads Health anyway, as before; "Not now" only skips the access
prompt and the catch-up. Nothing is ever unlinked and no history is deleted.

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
window's end is the next calendar day's local midnight
(`addCalendarDays(dayStart, 1)`), not `dayStart + 24 h`, so on DST change days
the window is 23 or 25 hours and neither drops nor double-counts the shifted
hour. The sleep-derived metrics (`sleep`, `bedtime`, `wakeTime`) are not cut by a clock
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
— sync only writes the days in its catch-up range (see "Catching up on past
days").

## Workouts/mindfulness tracking mode

`workouts` and `mindfulness` are the only two metrics where a habit's own
`trackingType` can diverge from the metric's fixed default (`workouts`/
`mindfulness` both default to `duration`, but the habit editor lets the user
choose Amount instead — a session count — for either one, for any workout
filter including "Any"). `HealthMetricTypeMapping.supportsTrackingChoice`
marks these two metrics; `HealthService.fetchDay` already reads the
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
`sessions` list from the same `fetchDay` read for that sync pass (no extra
Health read).

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
refreshes the perfect-streak flag, and for past days re-runs `assignStreaks`
(once per habit at the end of a catch-up, not once per day).
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

Health-linked habits' reminders also have **no "Complete" action button**
(`NotificationService.scheduleAllHabitNotifications` passes no `actionButtons`
when `healthMetric` is set). Completing from the notification would be a hand
edit (`completeHabit` sets `healthManualOverride`), so a goal the user actually
hit on their watch would never replace it on the next sync (task 33). Tapping
the notification still opens the habit's details page, like the tap handling
in `NotificationActionHandler._logProgressTypeFor`.

On iOS this relies on `NotificationCategoryMerger` in
`ios/Runner/AppDelegate.swift`. awesome_notifications registers each
notification's buttons as an iOS category but replaces all previously
registered categories when it does, so a button-less Health reminder scheduled
last used to strip "Complete" from every other habit's reminder too. The merger
keeps every category registered.

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
  which `fetchDay` already returns `null` for on any failure.

## Maintenance rule

Any change to Health sync (new metric, changed windowing, permission flow)
must also update this document.

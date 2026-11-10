# Habitt v2 — Backup & Sync System

> **Maintenance rule:** Any time you modify backup, sync, encryption, or Drive integration code, update this document to reflect the change.

---

## Overview

Habitt uses a **delta-based, client-side encrypted** backup system supporting two cloud backends: Google Drive and iCloud. No plaintext data ever leaves the device. The system is opt-in and designed around three goals: privacy, multi-device sync, and low bandwidth usage.

**Key source files:**
- `lib/services/backup_service.dart` — encryption, serialization, delta logic
- `lib/services/cloud_storage_adapter.dart` — abstract `CloudStorageAdapter` interface
- `lib/services/drive_storage_adapter.dart` — Google Drive implementation
- `lib/services/icloud_storage_adapter.dart` — iCloud Documents implementation
- `lib/providers/backup_provider.dart` — sync orchestration, timers, state management
- `lib/models/backup_data.dart` — `BackupData`, `BackupMetadata` models

---

## Cloud Folder Structure

All files live inside a single `habitt_backups/` folder — in Drive root for Google Drive, in the iCloud container `iCloud.com.shellz.habitt` for iCloud.

```
habitt_backups/
├── DD-MM-YY-HHMM-habitt-backup.habitt          ← full backups (max 3 kept)
├── DD-MM-YY-HHMM-SHORTID-habitt-delta.habittd  ← delta files (7-day TTL)
├── metadata.meta                                ← encrypted device metadata
└── key.key                                      ← Drive only; encryption key (plain or PIN-wrapped)
```

The `SHORTID` in delta filenames is the first 8 chars of the device UUID — used to identify the source device and skip re-applying your own deltas.

`key.key` is **not used on iCloud** — `flutter_secure_storage` with `IOSOptions(synchronizable: true)` syncs all keychain slots (encryption key, PIN data, stored PIN) via iCloud Keychain automatically.

---

## Encryption

### Algorithm
- **AES-256-GCM** with a random 12-byte nonce per file
- Authenticated encryption (MAC tag) prevents tampering and detects corruption

### Device Key
- A 256-bit key is generated once per device and stored in the platform keychain:
  - **iOS:** iCloud Keychain (`synchronizable = true`)
  - **Android:** EncryptedSharedPreferences (RSA-ECB + AES-GCM)
- This key is also uploaded to Drive as `key.key` so other devices can install it

### PIN Protection
When the user enables a PIN:
1. PBKDF2 (200 000 iterations) derives a wrapping key from the PIN + random salt
2. The device key is AES-GCM encrypted with the wrapping key → stored in Drive as `key.key` with `type: "pin"`
3. On app launch the stored PIN automatically unwraps the key (no re-entry needed after first unlock)
4. Changing or removing PIN re-uploads `key.key` immediately

### Key Sync (`_syncKeyWithDrive`)
Called at the start of every sync. Handles six states to keep all devices in agreement:

| Drive `key.key` | Local key | Action |
|---|---|---|
| Missing | Any | Upload local key |
| Plain | Missing | Install Drive key locally |
| PIN-wrapped | Missing | Prompt user for PIN |
| Plain | PIN enabled | Sync: another device disabled PIN |
| PIN-wrapped | Plain | Prompt: another device enabled PIN |
| PIN-wrapped | PIN (valid) | Install in both keychain slots + cache |

### Wire Format (v2+)
Every encrypted file is a JSON envelope:
```json
{
  "version": 2,
  "nonce": "<base64 12 bytes>",
  "ciphertext": "<base64 encrypted payload>",
  "tag": "<base64 MAC>"
}
```

### Legacy (v1)
Old passphrase-encrypted local backups are detected by `version: 1`. The user is prompted once for the passphrase; on success the data is re-encrypted with the device key and re-uploaded.

---

## Backup Versions

| Version | Type | Notes |
|---|---|---|
| 1 | Passphrase full backup | Local only, deprecated |
| 2 | Device-key full backup | Google Drive |
| 3 | Device-key delta backup | Google Drive |

---

## Full Backup vs. Delta

### Full Backup (`.habitt`)
- Contains **all** habits and days
- Used on first sync, forced syncs, after compaction, and new-device restore
- Max 3 kept on Drive; oldest deleted automatically

### Delta (`.habittd`)
- Contains **only changed** records since `_lastSyncTime`
- A habit is included if: created after `fromTime` OR any per-field timestamp is newer than `fromTime`
- A day is included if its `timestamp` is after `fromTime`
- Returns `null` (no upload) when nothing changed — unless this device changed the device list (see § Device List), which uploads a delta on its own
- Deleted 7 days after creation; max 20 before compaction triggers

### Sync Cursor (`_lastSyncTime`)
The cursor is when the last successful sync **started** (`_syncCycleStartedAt`, set when `syncState` turns to `syncing`, saved by `_onSyncSuccess`), not when it finished. It used to be the end, which lost changes in two ways:
- **Local writes during a sync** (Health sync runs alongside the sync on app open) were older than the new cursor, so no delta ever carried them; only the next full backup did.
- **A delta or full backup another device uploaded during this sync** had a cloud modified time older than the new cursor, so the next listing (`modifiedAfter`) never returned it.

The delta export uses the cursor as is (local timestamps against the local clock). Cloud listings, the delta listing and the newer-full-backup check, use `_cloudListingCursor`: the cursor less `_kCloudClockSlack` (2 min), because cloud modified times come from the server's clock. Already-applied deltas are skipped by id and own deltas by device id, so the overlap costs nothing.

Because the cursor is earlier than this device's own full-backup upload, `_uploadBackupToCloud` records the backup it just uploaded as the last applied one (`_rotateOldBackups(uploadedName:)` → `_kLastAppliedBackupIdKey`), so the next sync's `_checkAndApplyNewerBackup` doesn't download this device's own data back.

---

## Conflict Resolution

### Per-Field Timestamps (`Habit.timestamps`)
Every editable field on a `Habit` carries its own `DateTime` modification timestamp stored in `timestamps: Map<String, DateTime>`. This enables field-level conflict resolution rather than last-write-wins at the object level.

### Merge Algorithm (`Habit.merge`)
For each **definition** field between incoming and local versions:
1. Values identical → no-op
2. One side has no timestamp → use the timestamped side
3. Both have timestamps → **the change closer to "now" wins** (most recently modified)
4. Tie → local wins (prevents oscillation between devices)

### Day-State vs. Definition Fields (important)

A habit's fields fall into two categories that sync differently:

- **Definition fields** (name, icon, schedule, color, order, paused, deleted, notifications, notification sound (`soundKey`), …) — global properties of the habit. Resolved per-field by the rule above. (`soundKey` is serialized in `toMap`/`fromMap`, merged via `resolve('soundKey', …)`, and timestamped under the `soundKey` key.) `isAlarm` (alarm-style reminders, see [`habit_alarms.md`](habit_alarms.md)) follows the same pattern: serialized in `toMap`/`fromMap`, merged via `resolve('isAlarm', …)`, timestamped under `isAlarm`; backups made before it existed read as `false`. `optionalOrder` (global order of optional habits when they are shown separately; `0` = not arranged yet) follows the same pattern as `order`: serialized in `toMap`/`fromMap`, merged via `resolve('optionalOrder', …)`, timestamped under `optionalOrder`; backups made before it existed read as `0`. `showIfMissed` (custom-interval habits keep showing daily after a missed scheduled day until completed) is a definition field in the same way: serialized in `toMap`/`fromMap`, merged via `resolve('showIfMissed', …)`, timestamped under `showIfMissed`; backups made before it existed read as `false`.
- **Day-state / completion tuple** — `completed`, `skipped`, `amountCompleted`, `durationCompleted`. These belong to a **specific calendar day**, not to the habit globally (`Habit.dayStateKeys`).

**Day-state flows only through dated `Day` snapshots.** Completing a habit writes into that day's dated snapshot (`updateHabitInDB` → today's `Day`), and the snapshot is what merges across devices, keyed by date. The dateless live ("master") habit record is **definition-only on receive**: `_mergeBackupData`'s master-record loop calls `existing.merge(incoming, preserveLocalDayState: true)`, so an incoming completion never lands on the live habit. (The completion flag is still *uploaded* inside the habit blob for backward compatibility with not-yet-updated clients — updated clients simply never *act* on it.)

Without this, a completion made on day *N* by a device that has not yet rolled over still carries `completed = true` on its dateless master record; the receiver, now on day *N+1*, would stamp it onto **today**, while day *N* stayed incomplete. Routing day-state exclusively through dated snapshots removes that leak.

**Today is a mirror of today's snapshot.** Because the home view reads today's completion off the live habit, `_mergeBackupData` ends with `BackupService.rehydrateTodayFromSnapshot()`: after the day loop it copies the day-state of each habit in **today's** dated snapshot back onto the matching live habit (`Habit.adoptDayState`). The same path runs after a full restore / new-device import (all cloud restore/replace paths wipe then call `_mergeBackupData`), so a fresh restore reads today from today's dated snapshot rather than the stale dateless master flag.

**A tap made while a merge runs is kept.** The merge calls it as `rehydrateTodayFromSnapshot(keepNewerLocal: true, adoptAlways: <habits the merge added>)`: a live habit whose day state is newer than its entry in today's snapshot (`Habit.hasNewerDayStateThan`, the newest of the `dayStateKeys` timestamps, the same ones `Habit.merge` compares) keeps it. That only happens when the user completes / undoes a habit while the merge is running: `completeHabit` changes the live habit, and `updateHabitInDB` awaits its save before writing today's snapshot, while the rehydrate loop reads today's snapshot once and awaits a save per habit. Without the guard the loop could copy the older snapshot state over the tap, and the tap's own snapshot write would then store the undone state, losing it for good. Otherwise the snapshot state is always at least as new as the live one (the day loop already merged it newest-wins, and the new-day reset doesn't touch day-state timestamps), so this changes nothing. Habits the merge just added are always adopted: their live state is the other device's dateless value, not a local change. The local file restore (below) calls it without the guard and takes the file's state as is.

**Reminders follow merged completions and definitions.** A completion or habit edit that arrives through a merge never passes through the local completion / edit paths, and the `init()` at the end of the merge skips the daily notification sync once it already ran that day. So `_mergeBackupData` takes `HabitProvider.reminderStateSnapshot()` before merging (per habit: today's `completed`, the effective `timesCompletedThisWeek` / `timesCompletedThisMonth`, and `NotificationService.reminderDefinitionKey`) and, after `init()`, calls `resyncRemindersAfterMerge` with it.

*Definition changes* come first: the definition key is every field the scheduler or reminder text reads apart from day state (reminder slots with their ids, times and weekdays, `notificationsEnabled`, `isAlarm`, `soundKey`, `isPaused`, the schedule fields, `createdAt`, name / localized names / icon / premade type, tracking type, amount / label / duration, `healthMetric`; a deleted habit collapses to a single `deleted` key). If any habit's key differs, or a habit appeared on or disappeared from this device (`NotificationService.reminderDefinitionsChanged`), the merge runs one forced full `_syncAllHabitNotifications(force: true)`: `scheduleAllHabitNotifications` wipes every pending habit reminder first, so slots removed or moved on the other device and habits paused or deleted there stop firing, and new habits get theirs. The full sync also covers any completion change in the same merge (see the scheduler rule below), so the per-habit pass is skipped. A merge that changes no definition never pays for a full reschedule.

*Otherwise*, per habit: a habit whose today completion flipped goes through `_syncNotificationsOnCompletionChange`, the same reminder update a local completion runs (cancel today's slots on completion; weekly/monthly reschedule from the merged period counters; restore on un-completion). A weekly/monthly habit whose period count moved without today changing (a past day of the current week/month completed elsewhere) is rescheduled. Separately, the notification scheduler never schedules today's slots for a habit completed today (`NotificationService.isCompletedToday`, which also requires the completion to be stamped today so a stale pre-rollover flag can't swallow today's reminders), so no reschedule can bring back reminders a completion cancelled.

**Local file restore applies the same rule.** `importLocalData` bypasses `_mergeBackupData` (it is a direct wipe-and-replace), so it enforces the rule itself: each habit from the file is written with `Habit.clearDayState()` applied (values zeroed, day-state timestamps dropped), and today is then rebuilt by `rehydrateTodayFromSnapshot()` after the days are restored. The file's dateless day-state is therefore never used at all — no progress is lost by dropping it, because every completion is written into that day's dated `Day` snapshot as it happens (including the day the file was exported on), so the restored days already carry the full history.

Without this, importing a file exported on day *N* onto a device now on day *N+1* pre-filled today with day *N*'s progress: the file has no snapshot for day *N+1*, but every master habit record still carried day *N*'s `completed`/`amountCompleted`/`durationCompleted`.

**Companion day-state fields.** `healthSessions` and `healthManualOverride` (Health sync, see `health_sync.md`) are not in `dayStateKeys` and have no timestamp of their own; they follow whichever side wins the completion tuple (`pickDayState`), and `adoptDayState` / `clearDayState` copy / reset them with the tuple. A backup written before `healthManualOverride` existed reads it as `false`. Because the flag has no timestamp, clearing it ("Use Apple Health / Health Connect values", `HabitProvider.clearHealthManualOverride`) stamps `timestamps['completed']`; otherwise the cleared flag would lose the tuple tie to the other device's identical day-state and never reach it.

**Completion tuple resolves as a unit.** Within a single day's per-habit merge, the four day-state fields are resolved together: the side whose day-state was modified most recently (latest timestamp among the tuple keys; tie → local) wins all four. They are never resolved independently, so a merge can no longer produce a contradictory `completed = true` with `amountCompleted = 0`.

**Known follow-ups (not yet done):**
- Weekly/monthly counters (`timesCompletedThisWeek`, `timesCompletedThisMonth`) still sync via the master record on the per-field path — a separate week/month-bound axis not covered by the day-state routing above.
- The dateless day-state fields are still physically present in the uploaded habit blob (kept for backward compatibility). Stripping them from the upload is deferred until all devices are on the definition-only-on-receive version.

### Day Merge
Days are keyed by ISO 8601 date string (`YYYY-MM-DD`). Every incoming day is merged **habit by habit** (`mergeDaySnapshot`, [`lib/util/day_merge.dart`](../lib/util/day_merge.dart)), using the per-habit rules above (completion tuple as a unit, newest wins, tie → local). The two days' own timestamps never decide anything; the stored day keeps the later of the two.

**Why not by day timestamp.** A day's `timestamp` moves on *any* write to that day (`updateHabitInDB`), whichever habit changed. The merge used to skip a whole incoming day when the local day's timestamp was the same or newer. So if one device completed habit A on a day (the iPhone's Health sync), and the other device then edited habit B on that day before it received the change, the second device dropped the whole incoming day, including A's newer completion. Merging the other way gave both devices the same day timestamp, so every later delivery was skipped too and the devices stayed different for good (a streak that differed between the two phones). With the per-habit merge, any later delivery of the day fixes it, including the full backup merged on every app launch. That launch-time merge is what keeps past days reconciled between devices.

**Unchanged days aren't rewritten.** `mergeDaySnapshot` returns `null` when the merged habit copies equal the local ones (`sameDayHabits`: the `toMap(forDay: true)` maps, in any order), so merging a full backup only writes the days that actually changed. The loop yields every 25 unchanged days so a full-backup merge doesn't block the UI.

**Schedule filtering of the merged snapshot (important).** The per-habit merge takes the **union** of habit IDs present in either device's snapshot of a day. A union can pull in habits that aren't scheduled on that day and are left incomplete (e.g. a habit the other device materialised into its snapshot at a different time, or a paused habit). The home "last week" view filters these out by schedule, but the raw streak/consistency stats would otherwise count them as unmet requirements — silently breaking streaks and dimming calendar days even though the home view shows the day complete. To keep all read paths consistent, the merged habit list is collapsed back through the same schedule filter the app uses when it writes a snapshot natively (`HabitProvider.habitsCountingForDay` → `_filteredHabitsForDay`, which keeps habits that are scheduled-or-completed, not paused, not deleted) before the `Day` is stored. Completed habits always survive the filter, so no real completion is ever dropped.

**A copy only counts on days the live habit existed and wasn't paused.** A day snapshot copy only records what the habit was like *when the copy was written*. Copies are also written later: the rollover filling the days the app wasn't opened, a past day created on demand (`getHabitsFromDay(hydrateMissing: true)`), `_loadMissingDays` after an earlier `dateJoined` arrives, or the other device's snapshot of those days. Such a copy can look active on days the habit was paused, or on days before it existed, and each of them then counted as a miss (an unpaused habit broke the perfect-day streak back to the unpause after a sync). So the filter asks the **live** habit, on past days only (`HabitProvider.inactiveOnPastDay`, used by `_filteredHabitsForDay`, `_scheduledHabitsForDaySnapshot`, the per-habit streak's `_appearedOnPastDay` and `HabitStatsProvider`):
- **Before `createdAt`:** the copy doesn't count.
- **Paused that day:** going by the habit's pause history (`Habit.pausedOnDay`), the copy doesn't count.

A copy with real progress on that day always stays. Because the merge writes through the same filter, an already affected day is cleaned the next time it merges.

**Pause history (`Habit.pausedRanges`).** A definition field: closed pause stretches as flat `[from, to, from, to, …]` UTC pairs (Hive field 56, `pausedRanges` in `toMap`/`fromMap`, left out when empty). The current pause isn't in it, it starts at `timestamps['isPaused']`. A day counts as paused when the habit was paused at its end: the pause's local day ≤ the day < the unpause's local day, so the day of a pause is paused and the day of an unpause counts.
- **Recording:** unpausing (`unpauseHabit`, or an edit through `updateHabit`) closes the current pause into a stretch before stamping `isPaused`.
- **Merge:** the union of both sides' stretches (`Habit.unionPauseRanges`), not a timestamp resolve, so no stretch is ever lost and both devices converge. When the merged habit is unpaused but no stretch ends at the merged `isPaused` time (the unpause came from an app version from before pause history), the side that still had it paused adds the stretch from its pause start to that unpause (`_mergePauseRanges`).
- **Never in day snapshots:** only the habit holds it, like the other habit-only fields (see "Day snapshot copies are slim" below).
- **Seeding (one time, `pauseHistorySeeded_v1`):** habits unpaused before the history existed only know when they were last unpaused. `_seedPauseHistory` walks back from the unpause to the last day with progress; the earliest day in that walk the habit was scheduled on but left out of the day's record is the pause start (a paused habit is left out of a snapshot, a missed one is kept as a miss). Without such a day nothing is recorded, so a habit that only carries an `isPaused` stamp from an edit keeps its misses. The seeded stretch is stamped under `timestamps['pausedRanges']` so the next delta carries it; a device that has the bad copies but not the evidence gets the stretch from the one that has it.

**Day snapshot copies are slim (`Habit.forDay`, `Habit.habitOnlyKeys`).** A day keeps a copy of every habit on it, so the habit's own details used to be repeated once per day, on the device and in every backup. A day copy now leaves out what belongs to the habit, not the day, along with those fields' timestamps: `localizedNames`, `notificationsEnabled`, `notificationTimes`, `soundKey`, `isAlarm`, `streak`, `longestStreak`, `insightPopstonedUntil`, `deletedAt`, `pausedRanges`.
- **Kept in copies:** the day-state; everything that decides whether the habit was due that day (schedule, `timesCompletedThisWeek/Month` for weekly/monthly targets, `lastCustomUpdate`, `optional`, `isPaused`, `isDeleted`, `createdAt`); goals and tracking; Health links. Also kept: what an older app version needs to read and show the copy (`name`, `iconPath`, `categoryId` are required by its `fromMap`; colour, time, order and tag are cheap and keep its past days looking right). The notes (`description`) stay too, so a day keeps the notes it had. The timestamps of kept fields stay, because day copies merge per field like habits do.
- **Writing:** every day writer stores `forDay()` copies (`saveHabitDay`, `updateHabitInDB` (for the whole day's list, not only the edited habit), `_fillToday`, `_syncTodaySnapshotSchedule`, `_sanitizeDaySnapshots`, `_mergeBackupData`'s day loop, the HabitKit import). `copyResetCompletion` leaves the pause history out. A local file restore clears them in place (`clearHabitOnlyFields`). `Day.toMap` serializes its habits with `toMap(forDay: true)`, which leaves the keys out, so an older app version reads them as their defaults. On an older version that means past days synced from an updated device show the base-language name until it updates.
- **Reading:** a past day's copies are handed out with those fields filled in from the live habit (`HabitProvider._withLiveDetails`, in `getHabitsFromDay`, `habitForDay` and `otherHabitsForDay`). That happens in memory only, and every write stores slim copies again.
- **Existing days (one time, `daySnapshotsSlimmed_v1`):** `_slimDaySnapshots` rewrites every day still holding full copies, keeping its `timestamp` and `isAutoCreated`, so nothing is re-uploaded and the merge rules don't change, then compacts the box. Each device slims its own days, and the next full backup is written slim.

**`createdAt` only moves on proof (`HabitProvider._repairHabitCreatedAt`, every load).** It used to be pulled back to the oldest snapshot holding *any* copy of the habit, stamped `now` so it won the merge. A copy written before the habit existed then made the next fill reach further back, until a new habit was "created" on the first day ever and missed on all of them.
- **Earlier:** only to a day with real progress on the habit. Old habits from before `createdAt` existed read it as "now" and are repaired by their completions.
- **Later:** back to the id's creation time when `createdAt` sits before it and nothing was logged before it, undoing an earlier pull-back. Habit ids are the creation time in microseconds (`getUniqueId`, the HabitKit importer); ids outside 2020 to now aren't read as one. Imported habits get their id at import time but have progress before it, so they're left alone.

The merge still resolves `createdAt` by timestamp, so a repair reaches the other device. A device on an older app version can pull it back again until it updates.

**Rollover never rewrites a synced gap day.** `checkForNewDay` fills the days the app wasn't opened on from the live habits. A gap day that already has a snapshot (synced in from another device) is left alone (`HabitProvider.hasRecordedDay`). Rewriting it would have wiped the other device's completions for that day and put in habits as they are now rather than as they were then.

**Syncs and the new-day check never overlap (`NewDayGate`, `update_last_date.dart`).** The check saves the last opened day from the live habits, fills the gap days and resets today. A sync merging days in at the same time could have its changes overwritten (a completion the other device logged on the last opened day), and a sync before the check merges today's data into habits still holding the last opened day's progress.
- `performSync` first calls `NewDayGate.readyForSync()`: it waits for a running check; when the check is due (`lastOpenedDate` is not today) it runs it first through the runner `updateLastOpenedDate` registers on its first call (covers the app kept open past midnight); with no runner yet (`initialize()`'s startup sync can run before the home page did the check) the sync is skipped, and the home page syncs right after its check anyway.
- The running sync is registered (`NewDayGate.syncStarted`, with how long it has shown no activity and a way to abandon it), and the check waits for it before it starts (`NewDayGate.waitForRunningSync`).
- **A stuck sync can't hold the new day back.** The check waits only while the sync shows activity: every `stuckSyncPoll` (10 s) it reads the sync's idle time, and once that reaches `stuckSyncLimit` (2 min) it abandons the sync (`BackupProvider._abandonRun`) and goes on. Activity is `_lastSyncActivity`: any cloud call (the `_adapter` getter), any `notifyListeners` (all progress goes through it), each merged day. Idle time is wall-clock, so after a night in the background a sync stuck since then is abandoned at the first poll. Before this a sync waiting on a request that never answered (a connection Android dropped in the background) held the check forever: the app opened on a new day with yesterday's completions on today, the resume handler (health sync, sync) waited behind it, **Sync now** stayed disabled, and only killing the app helped. The cloud calls have time limits of their own (see Time Limits), so this is a safety net for anything else that never answers.
- `updateLastOpenedDate` awaits the whole check now, and overlapping calls share the running one.

**A habit edit stores the persisted habit in today's snapshot.** `HabitProvider.updateHabit` passes the persisted habit to `updateHabitInDB`, not the edited copy from the habit sheet. Only the persisted habit carries the edit's timestamps. With the copy, today's snapshot held the new values under the pre-edit timestamps, so the other device's identical-timestamp copy won the tie and the edit (e.g. switching to optional) was lost from that day's snapshot there.

This invariant must be read consistently on the stats side too: `StatsProvider` schedule-filters every day snapshot via `habitsCountingForDay` before counting required/completed habits (`getDayProgress`, `_isPerfectDay`, `refreshPerfectStreak`, `recalculateLongestPerfectDaysStreak`, and the last-week rate methods). A one-time migration (`HabitProvider._sanitizeDaySnapshots`, guarded by the `daySnapshotsSanitized_v1` pref) rewrites any pre-existing snapshots that were poisoned by the old unfiltered union merge.

**`Day.isAutoCreated`** — a local-only boolean (never serialised to backup files) that is set to `true` when a day is created by the day-rollover logic (`checkForNewDay`), the missing-day backfill (`_backfillMissingDays`), or the on-demand hydration path. It used to exempt such days from the day-timestamp skip. Since the merge no longer looks at day timestamps (see Day Merge), nothing reads it any more; it stays in the Hive layout.

### Duration Schema Version (minutes → seconds)

A habit's `duration` / `durationCompleted` are stored in **seconds** (they were
minutes before the seconds migration). `BackupData` carries a
`durationSchemaVersion` (see `kDurationSecondsDataVersion`) so payloads self-describe their unit:

- **New exports** always write `durationSchemaVersion = kDurationSecondsDataVersion` (seconds).
- **Legacy payloads** — a pre-seconds client writes no such field; `BackupData.fromMap` defaults it to `0` (minutes).

`BackupData.fromMap` normalizes at the boundary: a legacy payload
(`durationSchemaVersion` absent/below the seconds version) has every `duration` /
`durationCompleted` (habits and embedded day snapshots) multiplied by 60 during
deserialization, and the resulting object reports the seconds-era version. This is the
**single chokepoint every ingest path funnels through** — local file import
(`importLocalData`, a direct wipe-and-replace that bypasses `_mergeBackupData`), cloud
download, replace, and delta merge all deserialize via `fromMap` — so a deserialized
`BackupData` is always seconds regardless of which restore/merge path consumes it.
Re-uploading the DB afterwards writes a seconds-era payload, healing the cloud copy over time.

**Export paths must tag their payload.** The export builders in `backup_service.dart`
(`exportDataLocally` v1, `exportDataForGoogleDrive` v2, `exportDeltaForGoogleDrive` v3)
build the payload map manually rather than via `BackupData.toMap`, so each explicitly
includes `'durationSchemaVersion': kDurationSecondsDataVersion`. Any new export path
carrying habits/days MUST include it, or its output would be misread as legacy minutes
and inflated 60× on restore. (The metadata-only wrapper carries no habits/days and omits it.)

Local device Hive data is migrated once on first launch of the seconds build by
`migrateDurationToSeconds` (`lib/util/duration_seconds_migration.dart`), guarded by
per-box `durationSecondsMigrated_*_v1` prefs.

**Rollout note:** while a user still has a not-yet-updated device, a habit *completed*
on that legacy device echoes its target-in-minutes, which upconverts to an over-target
seconds value on updated devices — visually over 100% but still `completed`,
non-destructive, and self-heals on the next write. The window closes once all devices update.

**Outdated-peer notice.** `BackupData.fromMap` sets a receive-side `wasUpconvertedFromLegacy`
flag when it upconverts a legacy payload. In `_mergeBackupData`, an applied **delta** with
that flag (`isDelta && wasUpconvertedFromLegacy`) sets `BackupProvider._outdatedPeerVersionDetected`
— deltas skip the local device, so this unambiguously means another connected device is still
on the pre-seconds version (full backups are excluded; they may be this device's own history).
`home_page.dart`'s backup listener shows a **one-time** dialog (`outdatedDevice*` strings) advising
the user to update the other device, guarded by an in-memory flag and the
`outdatedPeerVersionWarningShown_v1` pref.

### Deletion
`isDeleted = true` on a habit acts as a tombstone, and deleted habits are recoverable via the Deleted Habits / trash page (`lib/pages/other_pages/deleted_habits_page.dart`), so the tombstone itself must sync like any other field.

- **Export** (`exportDataForGoogleDrive`, `exportDeltaForGoogleDrive`, `exportDataLocally`) never filters by `isDeleted` — deleted habits are included in every backup exactly like active ones.
- **Incremental merge** (`_mergeBackupData`, existing local record found): `deleted` is a definition field, resolved by the normal per-field timestamp rule like any other (§ Merge Algorithm) — whichever side deleted/restored most recently wins. `deletedAt` (see below) rides along on the same `isDeleted` timestamp key (`Habit.merge`), so it always tracks whichever side's `isDeleted` value wins and can never disagree with it.
- **New-to-this-device merge** (`_mergeBackupData`, no local record): the incoming habit — deleted or not — is always added as-is. A deleted habit lands as a tombstone rather than being skipped. This matters most right after a full wipe (cloud "Replace" via `_replaceFromCloud`, or a fresh device's first merge), where every incoming habit looks "new": if the tombstone were skipped there, a later delta/backup from a stale device that never learned about the deletion would re-add the habit as active with no local tombstone to out-rank it.
- **Local file restore** (`importLocalData`) is a full wipe-and-replace: every habit in the file — including deleted ones — is re-added verbatim (only the day-state is rebuilt from today's snapshot, see § Day-State vs. Definition Fields), so the trash list survives a restore intact.

**Deletion timestamp (`Habit.deletedAt`).** A dedicated `DateTime?` field, set by `Habit.deleteHabit()` and cleared by `Habit.restore()`. It exists separately from the generic `timestamps['isDeleted']` conflict-resolution stamp because that map is overwritten on every delete/restore toggle and keeps no history — `deletedAt` is what the trash UI (`HabitCard`'s "deleted N days ago" line) and the purge sweep below actually read. Habits deleted before this field existed have it backfilled once from `timestamps['isDeleted']` by `HabitProvider._seedDeletedAtTimestamps()`, guarded by the `deletedAtSeeded_v1` pref.

**Purge sweep (local-only).** `HabitProvider._purgeExpiredDeletedHabits()` runs on every app init and permanently removes (`habit.delete()` on the Hive box) any habit that has been deleted for ≥ `HabitProvider.deletedHabitPurgeDays` (30) days. This is a **hard delete**, not a tombstone update — the record is gone from `habitBox` entirely, and nothing about the purge itself is written to `timestamps` or synced.

**Known follow-ups (not yet done):**
- The purge above is local-only and does not propagate to other synced devices. If a second device was offline for 30+ days and still holds the habit as an active (non-deleted) record, a later sync could re-introduce it here as a "new" habit, since there is nothing in the incoming payload marking it as deleted and no local record left to out-rank it (the same shape of problem the "new-to-this-device" tombstone rule above solves for normal deletes, but the tombstone itself is gone once purged). Closing this gap needs a synced `purgedHabitIds: {habitId: purgedAt}` set — uploaded like any other field, checked on every "new-to-this-device" merge before adding an incoming habit, and used to propagate the purge to any device that syncs in later still holding the habit active. Scoped as a dedicated follow-up rather than bundled with the purge sweep itself, since it touches `BackupData`, full/delta export, and `_mergeBackupData` directly.

### Device List (Google Drive only)
Every Drive backup and delta also carries `devices`: the phones syncing this account and which one reads Health (`SyncDeviceList`, [`lib/models/sync_device.dart`](../lib/models/sync_device.dart)). Health sync uses it so two Health stores (iPhone + Android, or two Androids) never overwrite each other's values — the rules and UI are in [`health_sync.md`](health_sync.md) § "Several devices". It adds no cloud requests: it rides inside files that are uploaded and downloaded anyway.

- **Owner:** `SyncDevicesProvider` ([`lib/providers/sync_devices_provider.dart`](../lib/providers/sync_devices_provider.dart)), shared by `BackupProvider` (fills it) and `HealthProvider` (follows it). Stored in `SharedPreferences` (`syncDevices`, `syncDevicesChangedAt`), not Hive: it is sync bookkeeping.
- **Entry:** `{id, model, os, platform, firstSeen, lastSeen}`. `id` is `DeviceIdentity.getOrCreateId()` (the same UUID as delta filenames); `model` is the marketing name (`DeviceIdentity.deviceInfo()['name']`, e.g. "iPhone 17", "Samsung SM-S921B"); `firstSeen` is the app's install time on that device (`PackageInfo.installTime`). Only iOS / Android list themselves; web and desktop pass the list on untouched.
- **Upload:** `listForUpload()` refreshes this device's own entry when it is missing, its name/OS changed, or it is ~20 h old, then `_uploadBackupToCloud` / `_uploadDeltaToCloud` pass the list to `exportDataForGoogleDrive` / `exportDeltaForGoogleDrive`. A delta is uploaded for the list alone only when this device changed it after `_lastSyncTime` (`changedSince`): the daily refresh or a new Health pick. So an idle day costs at most one tiny delta.
- **Merge:** `_mergeBackupData` calls `mergeIncoming` before the habits. Union by id; per device the entry with the later `lastSeen` gives name/OS/platform and the earliest `firstSeen` is kept. The Health pick (`healthSource: {deviceId, changedAt}`) goes to the latest `changedAt`. A payload without `devices` (older app version) lists its sender from `metadata` instead, iOS / Android only.
- **Pruning:** devices not seen for `kSyncDeviceActiveDays` (60) are dropped on every merge/refresh, except the picked Health device.
- **Cleared** (`SyncDevicesProvider.clear()`) on sign-out, `_clearLocalAuthState` (account deletion, revoked scope) and `activateICloud`: off Drive the device is on its own again. iCloud never carries or merges the list — iCloud devices share one Apple ID, so one Apple Health.

---

## Sync Modes

### `SyncMode` enum

| Mode | Trigger | What it does |
|---|---|---|
| `full` | App launch, stale resume (>5 min), "Back Up Now" | Check remote → download deltas/full backup → upload delta or full |
| `uploadOnly` | Auto-sync after local change | Skip remote check, only upload delta |
| `syncOnly` | "Sync Now" button | Download deltas + upload delta, no compaction |

### `SyncSpeed` enum

| Speed | Upload debounce | Periodic poll | Who uses it |
|---|---|---|---|
| `fast` | 5 s | 30 s | Power users |
| `optimized` | 15 s | 2 min | Default |

---

## Sync Lifecycle

**Only one sync runs at a time.** `performSync` sets `_activeRun` (a `_SyncRun`) before its first `await` and clears it when the run ends. `syncState` only becomes `syncing` after `NewDayGate.readyForSync()`, `_ensureKeySync()` (a network call) and `_getKey()`, so on its own it left a gap: two syncs asked for together (launch / resume plus the periodic timer or a debounced upload) both got through and ran the whole cycle twice: double merges, each one's `_onSyncSuccess` flipping the state to `success` while the other still ran, one clearing the applied-delta tracking under the other, and both optimizing over the one shared counter (which went negative). A `performSync` called while another runs (`_isSyncBusy`: `_activeRun` set or `syncState == syncing`) is dropped; nothing is lost, since the running sync's cursor is its own start time, so the next sync still picks up anything changed after it started. A dropped `uploadOnly` sets `_uploadRequestedDuringSync`, and `scheduleAutoSync()` is called once the running sync ends, so a change made mid-sync goes up within the debounce delay rather than at the next periodic sync. The periodic timer and the user-started cloud replace paths (`replaceFromBackupFile`, `confirmReplace`, `confirmUploadMine`) check `_isSyncBusy` too. `confirmReplace` also takes `_activeRun` itself before its key sync: it only turns `syncing` after that network call, and a sync starting in between would have run alongside the replace (wiping local data while the sync merged into it or uploaded from it). The other two turn `syncing` right after the check.

**Abandoning a sync.** `_abandonRun` (called by the new-day check, see Day Merge) marks the run abandoned, releases `_activeRun`, and fails the sync (`error`, `lastError` "Sync stopped: no progress", backoff, progress reset). The stuck call may still return later, so the sync body runs in a zone carrying its `_SyncRun` (`runZoned` in `performSync`), and `_ensureRunActive()` throws `_SyncAbandoned` from an abandoned run at its checkpoints: every `_adapter` access, the start of `_mergeBackupData` and `_onSyncSuccess`, after the key sync and key read in `_performSync`, and before `_clearAllDeltaFiles` clears the applied-delta tracking. `_performSync`'s catch returns quietly for it. So an abandoned sync can't merge, touch the cloud, move the cursor or change the sync state; `performSync` itself returns as soon as its run is abandoned (`_SyncRun.gaveUp`), so a caller awaiting it (the **Back up now** spinner, the resume handler) isn't left waiting on the stuck call, and its `finally` only releases the lock when it still holds it.

Every `performSync` goes through `NewDayGate.readyForSync()` first (see Day Merge): it waits for, or runs, a due new-day check, and is skipped if the check is due and nothing has registered it yet.

### Time Limits

Every cloud call has a time limit (`lib/services/cloud_stall.dart`); a call over it throws `CloudStallException`, which the adapters never swallow, so it ends the sync:
- **Drive requests** go through `StallGuardClient`: no response within 30 s, plus time for the request body at 20 KB/s (an upload of a few MB on slow mobile data isn't cut off; googleapis sends its upload length as the `content-length` header), or a response body that delivers nothing for 30 s. On a stall the client is closed, which drops the connection, so the request can't still finish later.
- **The Drive token** (`driveAccessToken`) gets 20 s.
- **iCloud** plugin calls (`gather`, `delete`, starting a transfer) get 60 s, and a transfer whose progress stream stays quiet for 60 s stalls (`ProgressWatch`); an offline iCloud transfer used to wait on that stream forever.

`_performSync` treats a stall like any failure (error state, backoff) but without the "sync failed" popup: it is usually a connection the OS dropped while the app sat in the background. Startup's cloud data check (`_checkDataExistsAtStartup`) counts a stall as "no data", so the periodic sync still gets started.

Errors that end a sync instead of being skipped:
- the Drive adapter's `_getDrive`, folder lookup, `delete` and `deleteAll` used to catch every error and carry on, so with a dead connection each following call (23 deletes when optimizing) waited out its own limit; they rethrow stalls now (other errors are still only logged).
- `DriveStorageAdapter.upload` throws when Drive or the backup folder can't be reached. It used to return quietly: the sync then counted the upload as done and moved its cursor past changes that never went up, so other devices only got them with the next full backup.

### 1. App Launch (`initialize()`)
1. Restore the Google Drive account from local state, **never by authenticating again**: email + id from prefs (`backup_user_email` / `backup_user_id`), name + photo from Firebase's persisted user (`_SavedGoogleIdentity`). The account and Drive adapter are published (`notifyListeners`) before any network call, so `isLoggedIn` — and the settings page's sync section — is true almost immediately.
   - Why: on Android `attemptLightweightAuthentication()` goes through Credential Manager, which falls back to a "sign in with Google" account sheet whenever it can't auto-select; dismissing it left the app signed out. Drive tokens don't need authentication — `driveAccessToken()` (`drive_storage_adapter.dart`) calls the platform interface's `clientAuthorizationTokensForScopes` with the saved email (Android's `AuthorizationClient` + `setAccount`), with no UI.
   - iOS / web still run `attemptLightweightAuthentication()` (silent there; their token APIs need an authenticated session) and swap in the real account when it matches.
   - No persisted Firebase user → nothing is restored this launch, saved state is kept.
2. Check if Drive scope was revoked (`driveAccessToken` returns null) → sign-out + notification. Errors (offline etc.) keep the account; sync retries later. The Firebase `reload()` check only signs out on `user-not-found` / `user-disabled`, not on network errors.
3. Call `_syncKeyWithDrive()` to ensure encryption key is consistent
4. If signed in: `performSync(force: true)` → forced full sync
5. Start periodic timer (30 s or 2 min)

### 2. User Makes a Change (`scheduleAutoSync()`)
1. Start debounce timer (5 s or 15 s)
2. If app goes to background before timer fires → flush immediately
3. On timer fire: `performSync(false, SyncMode.uploadOnly)`

### 3. Periodic Timer
- Fires every 30 s (fast) or 2 min (optimized) when there are no failures
- Backs off exponentially on consecutive `performSync` failures (doubles each time, max 30 min), resets to normal interval on next success
- Skipped if: a sync is running (`_isSyncBusy`), pending upload in queue, not signed in
- Calls `performSync(false, SyncMode.full)`

### 4. App Resume (`didChangeAppLifecycleState(resumed)`)
- If `isSyncStale` (last sync > 5 min ago or never): `performSync()` — full cycle
- If recently synced (< 5 min): `performSync(false, SyncMode.uploadOnly)` — only flush pending local upload; skip Drive read pass

The 5-minute stale threshold means the full-backup check (needed to detect compaction by another device) still runs on any meaningful resume, while rapid app-switches avoid unnecessary Drive API calls. The periodic timer catches compaction within 30 s–2 min regardless.

### 5. Manual Actions
- **"Back Up Now"** → `backupNow()` → `performSync(force: true)` + UI spinner
- **"Sync Now"** → `performSync(false, SyncMode.syncOnly)`

---

## `performSync` Decision Tree

```
performSync(force, mode)
│
├─ force=true OR _lastSyncTime=null
│   └─ _fullSyncPath()
│       ├─ Download latest full backup from Drive
│       ├─ Merge into local Hive DB
│       ├─ Re-upload entire DB as new full backup
│       └─ Delete all delta files, reset applied-delta set
│
└─ Incremental path
    ├─ _ensureKeySync()
    ├─ Check if Drive has a newer full backup (compaction recovery)
    │   └─ If yes → _fullSyncPath()
    ├─ _downloadAndApplyPendingDeltas()
    │   ├─ Drive query filtered by modifiedTime > _lastSyncTime − 2 min slack (server-side)
    │   ├─ If returned IDs == cached IDs → early return (nothing new)
    │   ├─ Skip already-applied (SharedPrefs set)
    │   ├─ Skip own device's deltas (SHORTID in filename)
    │   ├─ Apply each: merge habits+days using timestamp logic
    │   └─ Update cached file ID set in SharedPrefs
    ├─ _uploadDeltaToCloud()
    │   ├─ exportDeltaForGoogleDrive(fromTime: _lastSyncTime = start of last sync)
    │   ├─ Skip if null (no changes)
    │   └─ _rotateDeltaFiles() — throttled to once per 24 h; Drive query
    │       pre-filtered by createdTime < 7-days-ago
    └─ If delta count ≥ 20 → _compactDeltas()
        ├─ Upload new full backup
        ├─ Delete all delta files
        └─ Reset applied-delta tracking
```

Deleting the delta files after a full sync (`_clearAllDeltaFiles`) is what the pill shows as **Optimizing** with "N remaining": `_syncOptimizingRemaining` is set from that call's own file list and count of deleted files (clamped at 0), so it only ever counts down to 0.

---

## Initial Connection Behavior

When the user connects an account for the first time (no prior sync history) or after signing out, `performSync(force: true)` is always called. `force=true` sets `useDelta = false` regardless of `_lastSyncTime`, so the full-backup path is guaranteed:

- **Cloud empty + local data** — full backup uploaded immediately (else branch in `signIn()`).
- **Cloud has data + local data** — `RestoreChoiceDialog` is shown (`pendingRestoreDecision`), for **both** Google Drive (`signIn()`) and iCloud (`activateICloud()`); with an empty local DB, or an empty cloud, the dialog is skipped and `performSync(true)` runs straight away. Three choices:
  - **Merge** (`confirmMerge()`) — `performSync(true)` downloads, merges, and re-uploads the entire DB, then starts the periodic sync timer so future cross-device changes are polled.
  - **Delete** (`confirmReplace()`, behind `OverwriteLocalDataDialog`) — wipes local data and restores from the cloud (`_replaceFromCloud`). The confirmation names how recent that backup is: when the decision is raised, `_latestCloudChangeTime()` stores the newest modified time across `habitt-backup*` and `habitt-delta*` files in `restoreDecisionBackupTime` (falls back to the undated text if the listing fails).
  - **Ignore backup and upload mine** (shown as an underlined text link under the Merge / Delete buttons; `confirmUploadMine()`, behind `ReplaceCloudBackupDialog`, which warns the existing cloud backup is permanently deleted) — the found backup is never downloaded or decrypted. `adapter.deleteAll()` removes everything in `habitt_backups/` (full backups, deltas, `metadata.meta`, Drive `key.key`), the applied-delta / last-applied-backup / last-sync cursors are cleared, `_ensureKeySync()` re-uploads the local key (Drive; iCloud's key already lives in the synced keychain), and this device's data is uploaded as a new full backup. Local data is untouched. If the upload fails after the delete, the cloud is simply empty and the next sync cycle uploads the local DB (cursor is null → full path).
  - Other devices that were syncing against the replaced backup pick up the new full backup via the normal compaction-recovery check (`_checkAndApplyNewerBackup`) and merge it by timestamp.
  - iCloud previously merged silently on connect; it now asks, same as Drive.
  - **Dismissing the dialog** (it stays dismissible) leaves the choice pending: `_pendingRestoreDecision` is persisted under `backup_pending_restore_decision` (via `_setPendingRestoreDecision`), and while it is set **nothing syncs** — `performSync`, `scheduleAutoSync` and `_startPeriodicSync` all return early, and `initialize()` skips its first-sync auto-merge and the periodic timer. The dialog text says so. It is asked again on every app open (`HomePage`, after `initializationDone`, with a refreshed backup date) and whenever the user taps **Backup now** / **Sync now**. The flag is cleared by any of the three choices, by sign-out / account deletion / `_clearLocalAuthState`, and by switching off iCloud (`deactivateICloud`, `_silentlyDeactivateICloud`); `signIn()` / `activateICloud()` set or clear it for the new backend.

This guarantees Device B can always download a complete snapshot containing all changes made before and after the account was connected.

`signOut()` and `deleteAccount()` clear `_lastSyncTime` from both memory and SharedPreferences so that re-connection always starts from a clean cursor. Both also cancel all pending timers and reset `_hasPendingSync`.

**In-flight sync safety:** if a periodic or auto-sync is already in progress when the user disconnects, `_adapter` is set to `null` by `signOut()`. `_onSyncSuccess()` checks for a null adapter at its entry point and aborts without persisting a sync timestamp or broadcasting `SyncState.success`, so no stale state is left behind. The sync overlay dismisses as soon as it observes `SyncState.idle` with no active backend.

---

## New Device Setup

| Drive state | Local state | Behavior |
|---|---|---|
| Empty | Empty | Proceed, nothing to do |
| Empty | Has data | Upload full backup immediately |
| Has backups | Empty | Auto-merge (safe, merging into nothing) |
| Has backups | Has data | Show merge / replace local / ignore-backup-and-upload-mine dialog to user |
| Has PIN-wrapped key | No key | Prompt for PIN before proceeding |

---

## Error Handling

| Failure | Behavior |
|---|---|
| Network error during download | Not marked applied → retried next cycle |
| Decryption failure | Marked applied → skipped permanently (corrupted) |
| Scope revoked | Silent sign-out + user notification |
| Transient errors during upload | Silent failure → retried on next timer tick |
| User disconnects mid-sync | `_onSyncSuccess` aborts (adapter null); no sync cursor persisted; overlay dismisses immediately |

---

## Sync Progress UI

Sync progress is surfaced two ways, and they are **mutually exclusive** by construction:

- **Sync pill** (`SyncProgressOverlay`, `lib/util/sync_progress_overlay.dart`) — a floating banner inserted into the root overlay while a meaningful sync is running (incoming work, visible upload activity, or optimizing). Shows title, status text, and a determinate/indeterminate progress bar.
- **Thin top indicator** (`ThinSyncIndicator`, `lib/widgets/home_page/thin_sync_indicator.dart`) — a hairline `LinearProgressIndicator` pinned just below the status bar on the home page. It is the "minimized" form of the pill.

### Dismissal model (single source of truth)

`BackupProvider` owns one flag, `_syncPillDismissed` (getter `syncPillDismissed`):

- Reset to `false` at the **start of every sync cycle** (`performSync`, where `syncState` becomes `syncing`). This is the only reset point, so a dismissal lasts for the current cycle and the pill returns on the next sync.
- Set to `true` via `dismissSyncPill()` when the user swipes the pill away.

Visibility is **derived**, never separately stored:

| Condition | Shows |
|---|---|
| `syncState == syncing && !syncPillDismissed` (+ pill gating) | Sync pill |
| `syncState == syncing && syncPillDismissed` | Thin top indicator |
| otherwise | neither |

Because both views read the same reactive state, there is no race between them: when the sync ends, `syncState` leaves `syncing` and whichever view was showing fades out on its own (no timers/guards needed). `_maybeShowSyncOverlay` in `home_page.dart` also early-returns when `syncPillDismissed`, so a dismissed pill is never re-inserted mid-cycle.

### Swipe-to-dismiss

Both the pill and the hold-to-complete tip wrap their content in `SwipeUpToDismiss` (`lib/widgets/default/swipe_up_to_dismiss.dart`): upward drag translates the banner, a release past the distance/velocity threshold dismisses it (with a light haptic), and a release below the threshold springs it back smoothly (honoring reduce-motion). The pill's swipe path calls `dismissSyncPill()` before animating out; its auto-close paths (success/error/sign-out) do not.

---

## Data Models

### `BackupData`
```dart
int version               // 1=legacy, 2=full, 3=delta
String? type              // "delta" or null (full)
int durationSchemaVersion // 0=minutes (legacy), >=1=seconds
DateTime? fromTime        // Delta start time
BackupMetadata metadata
List<Habit> habits
List<Day> days
DateTime? dateJoined
SyncDeviceList? devices   // Drive only; null from older app versions
```

### `BackupMetadata`
```dart
String deviceId      // UUID, stable per install
String model         // e.g. "iPhone12,1"
String os            // e.g. "iOS 17.5"
DateTime createdAt   // UTC creation time
```

### `Habit.timestamps`
```dart
Map<String, DateTime>  // e.g. {"name": ..., "completed": ..., "amount": ...}
```

---

## Summary

The system achieves low-bandwidth multi-device sync by:
1. Uploading only changed fields (delta files) rather than the full DB on every change
2. Resolving conflicts at the per-field level using modification timestamps
3. Compacting automatically when deltas accumulate (≥20 files → new full backup + wipe)
4. Skipping redundant uploads (null delta when nothing changed) and redundant downloads (skipping own device's deltas)

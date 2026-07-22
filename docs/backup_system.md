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
- Returns `null` (no upload) when nothing changed
- Deleted 7 days after creation; max 20 before compaction triggers

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

- **Definition fields** (name, icon, schedule, color, order, paused, deleted, notifications, notification sound (`soundKey`), …) — global properties of the habit. Resolved per-field by the rule above. (`soundKey` is serialized in `toMap`/`fromMap`, merged via `resolve('soundKey', …)`, and timestamped under the `soundKey` key.)
- **Day-state / completion tuple** — `completed`, `skipped`, `amountCompleted`, `durationCompleted`. These belong to a **specific calendar day**, not to the habit globally (`Habit.dayStateKeys`).

**Day-state flows only through dated `Day` snapshots.** Completing a habit writes into that day's dated snapshot (`updateHabitInDB` → today's `Day`), and the snapshot is what merges across devices, keyed by date. The dateless live ("master") habit record is **definition-only on receive**: `_mergeBackupData`'s master-record loop calls `existing.merge(incoming, preserveLocalDayState: true)`, so an incoming completion never lands on the live habit. (The completion flag is still *uploaded* inside the habit blob for backward compatibility with not-yet-updated clients — updated clients simply never *act* on it.)

Without this, a completion made on day *N* by a device that has not yet rolled over still carries `completed = true` on its dateless master record; the receiver, now on day *N+1*, would stamp it onto **today**, while day *N* stayed incomplete. Routing day-state exclusively through dated snapshots removes that leak.

**Today is a mirror of today's snapshot.** Because the home view reads today's completion off the live habit, `_mergeBackupData` ends with `_rehydrateTodayFromSnapshot()`: after the day loop it copies the day-state of each habit in **today's** dated snapshot back onto the matching live habit (`Habit.adoptDayState`). The same path runs after a full restore / new-device import (all restore/replace paths wipe then call `_mergeBackupData`), so a fresh restore reads today from today's dated snapshot rather than the stale dateless master flag.

**Completion tuple resolves as a unit.** Within a single day's per-habit merge, the four day-state fields are resolved together: the side whose day-state was modified most recently (latest timestamp among the tuple keys; tie → local) wins all four. They are never resolved independently, so a merge can no longer produce a contradictory `completed = true` with `amountCompleted = 0`.

**Known follow-ups (not yet done):**
- Weekly/monthly counters (`timesCompletedThisWeek`, `timesCompletedThisMonth`) still sync via the master record on the per-field path — a separate week/month-bound axis not covered by the day-state routing above.
- The dateless day-state fields are still physically present in the uploaded habit blob (kept for backward compatibility). Stripping them from the upload is deferred until all devices are on the definition-only-on-receive version.

### Day Merge
Days are keyed by ISO 8601 date string (`YYYY-MM-DD`). Incoming day is skipped if local has real habit data AND the local day was **not** auto-created AND the incoming timestamp is older. Otherwise the day's habits are merged using the same per-field logic above.

**Schedule filtering of the merged snapshot (important).** The per-habit merge takes the **union** of habit IDs present in either device's snapshot of a day. A union can pull in habits that aren't scheduled on that day and are left incomplete (e.g. a habit the other device materialised into its snapshot at a different time, or a paused habit). The home "last week" view filters these out by schedule, but the raw streak/consistency stats would otherwise count them as unmet requirements — silently breaking streaks and dimming calendar days even though the home view shows the day complete. To keep all read paths consistent, the merged habit list is collapsed back through the same schedule filter the app uses when it writes a snapshot natively (`HabitProvider.habitsCountingForDay` → `_filteredHabitsForDay`, which keeps habits that are scheduled-or-completed, not paused, not deleted) before the `Day` is stored. Completed habits always survive the filter, so no real completion is ever dropped.

This invariant must be read consistently on the stats side too: `StatsProvider` schedule-filters every day snapshot via `habitsCountingForDay` before counting required/completed habits (`getDayProgress`, `_isPerfectDay`, `refreshPerfectStreak`, `recalculateLongestPerfectDaysStreak`, and the last-week rate methods). A one-time migration (`HabitProvider._sanitizeDaySnapshots`, guarded by the `daySnapshotsSanitized_v1` pref) rewrites any pre-existing snapshots that were poisoned by the old unfiltered union merge.

**`Day.isAutoCreated`** — a local-only boolean (never serialised to backup files) that is set to `true` when a day is created by the day-rollover logic (`checkForNewDay`), the missing-day backfill (`_backfillMissingDays`), or the on-demand hydration path. These days are blank reset snapshots with a current wall-clock timestamp; without this flag they would incorrectly beat backup data timestamped earlier (e.g. actual completions from another device). When `isAutoCreated = true` the timestamp guard is bypassed and the incoming backup data is always merged in. The saved result clears the flag (`isAutoCreated = false`).

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

### Deletion
`isDeleted = true` on a habit acts as a tombstone. Deleted habits are excluded from new backups and not re-added from incoming data.

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

### 1. App Launch (`initialize()`)
1. Attempt silent Google Sign-In (no UI)
2. Check if Drive scope was revoked → silent sign-out if so
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
- Skipped if: already syncing, pending upload in queue, not signed in
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
    │   ├─ Drive query filtered by modifiedTime > _lastSyncTime (server-side)
    │   ├─ If returned IDs == cached IDs → early return (nothing new)
    │   ├─ Skip already-applied (SharedPrefs set)
    │   ├─ Skip own device's deltas (SHORTID in filename)
    │   ├─ Apply each: merge habits+days using timestamp logic
    │   └─ Update cached file ID set in SharedPrefs
    ├─ _uploadDeltaToCloud()
    │   ├─ exportDeltaForGoogleDrive(fromTime: _lastSyncTime)
    │   ├─ Skip if null (no changes)
    │   └─ _rotateDeltaFiles() — throttled to once per 24 h; Drive query
    │       pre-filtered by createdTime < 7-days-ago
    └─ If delta count ≥ 20 → _compactDeltas()
        ├─ Upload new full backup
        ├─ Delete all delta files
        └─ Reset applied-delta tracking
```

---

## Initial Connection Behavior

When the user connects an account for the first time (no prior sync history) or after signing out, `performSync(force: true)` is always called. `force=true` sets `useDelta = false` regardless of `_lastSyncTime`, so the full-backup path is guaranteed:

- **Cloud empty + local data** — full backup uploaded immediately (else branch in `signIn()`).
- **Cloud has data + local data** — RestoreChoiceDialog shown; Merge triggers `performSync(true)` which downloads, merges, and re-uploads the entire DB, then starts the periodic sync timer so future cross-device changes are polled.

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
| Has backups | Has data | Show merge/replace dialog to user |
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

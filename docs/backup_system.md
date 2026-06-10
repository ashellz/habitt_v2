# Habitt v2 — Backup & Sync System

> **Maintenance rule:** Any time you modify backup, sync, encryption, or Drive integration code, update this document to reflect the change.

---

## Overview

Habitt uses a **delta-based, client-side encrypted** backup system built on Google Drive. No plaintext data ever leaves the device. The system is opt-in and designed around three goals: privacy, multi-device sync, and low bandwidth usage.

**Key source files:**
- `lib/services/backup_service.dart` — encryption, serialization, Drive I/O, delta logic
- `lib/providers/backup_provider.dart` — sync orchestration, timers, state management
- `lib/models/backup_data.dart` — `BackupData`, `BackupMetadata` models

---

## Drive Folder Structure

All files live inside a single `habitt_backups/` folder in the user's Google Drive root.

```
habitt_backups/
├── DD-MM-YY-HHMM-habitt-backup.habitt      ← full backups (max 3 kept)
├── DD-MM-YY-HHMM-SHORTID-habitt-delta.habittd  ← delta files (7-day TTL)
├── metadata.meta                            ← encrypted device metadata
└── key.key                                  ← encryption key (plain or PIN-wrapped)
```

The `SHORTID` in delta filenames is the first 8 chars of the device UUID — used to identify the source device and skip re-applying your own deltas.

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
For each field between incoming and local versions:
1. Values identical → no-op
2. One side has no timestamp → use the timestamped side
3. Both have timestamps → **the change closer to "now" wins** (most recently modified)
4. Tie → local wins (prevents oscillation between devices)

### Day Merge
Days are keyed by ISO 8601 date string (`YYYY-MM-DD`). Incoming day is skipped if local has real habit data AND the incoming timestamp is older. Otherwise the day's habits are merged using the same per-field logic above.

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

## New Device Setup

| Drive state | Local state | Behavior |
|---|---|---|
| Empty | Empty | Proceed, nothing to do |
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

---

## Data Models

### `BackupData`
```dart
int version          // 1=legacy, 2=full, 3=delta
String? type         // "delta" or null (full)
DateTime? fromTime   // Delta start time
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

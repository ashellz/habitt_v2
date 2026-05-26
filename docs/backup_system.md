# Backup System — Current State & Redesign

## How it works today

### Trigger & debounce
Every data mutation (habit created, completed, updated, deleted) calls `backupProvider?.scheduleAutoSync()` from `HabitProvider`. Inside `BackupProvider` a 15-second debounce timer is started — if another change arrives, the timer resets. After 15 seconds of silence the sync runs. Manual "Sync Now" bypasses the timer.

Sync is skipped entirely if the user isn't signed in or has no passphrase set.

### App-start check
`BackupProvider.initialize()` runs at startup. It silently re-signs in with the stored Google account. It then calls `_checkDataExists()` which looks for `habitt_backups/metadata.meta` on Drive. Nothing is downloaded yet at this point — it just notes whether cloud data exists, which affects what prompt is shown if the user signs in fresh.

### Sync flow (`performSync()`)
1. Download and decrypt `metadata.meta` from Drive (AES-256-GCM, PBKDF2 key from passphrase).
2. **Device check:** compare `deviceId` in cloud metadata vs local. If they match → already in sync, skip download. If different → another device uploaded this backup → download and merge.
3. **Download + merge (if needed):** decrypt the backup file, call `_mergeBackupData()`, then immediately re-upload the merged result.
4. **Upload:** delete old files in `habitt_backups/`, upload new encrypted backup + new metadata.

### Metadata (`metadata.meta`)
Stored as a small encrypted JSON blob:
```json
{ "deviceId": "uuid", "model": "iPhone 14 Pro", "os": "iOS 17.0", "createdAt": "2025-01-01T12:00:00Z" }
```
The whole file is AES-256-GCM encrypted with the user's passphrase before being written to Drive.

### Encryption
- Algorithm: AES-256-GCM
- Key derivation: PBKDF2-HMAC-SHA256, 200,000 iterations, 16-byte random salt
- Nonce: 12 random bytes per encryption
- Passphrase stored in platform keychain (`flutter_secure_storage`) under key `habitt_backup_passphrase`
- If passphrase is wrong → `SecretBoxAuthenticationError` → sync fails with "wrong passphrase" error

### What's backed up
Full snapshot of both Hive boxes:
- `habits` box — every Habit with all fields + per-field modification timestamps
- `days` box — every Day record with per-habit state + modification timestamps
- `dateJoined` — app start date for statistics
- `version` — currently 1

Payload is serialized to JSON, encrypted, and uploaded as a single file named `DD-MM-YY-habitt-backup.habitt`.

### Merge logic
Field-level conflict resolution using timestamps:
- Both have same timestamp or both null → keep local
- One side has a timestamp, other doesn't → use the timestamped version
- Both have timestamps → use the most recent one
- Tie → prefer local

Days are merged per-day, then per-habit within each day. After merge, HabitProvider is refreshed and Hive boxes are persisted.

### Google Drive structure
```
habitt_backups/
  metadata.meta          ← encrypted metadata
  DD-MM-YY-habitt-backup.habitt  ← encrypted full database snapshot
```
Old files are deleted before each upload (no versioning).

---

## Problems with the current approach

1. **Full snapshot every sync.** Every 15-second debounce uploads the entire database. For users with many habits and long history this gets heavy.
2. **Passphrase UX is a dealbreaker.** If the user forgets their passphrase → backup is permanently inaccessible. No recovery path. Most users will either skip setting one or lose their data.
3. **Passphrase requirement blocks sync.** New devices must enter passphrase before any data flows. Friction at exactly the wrong moment.
4. **Drive API is chatty.** Delete-then-upload on every sync, no delta, no chunking.
5. **No versioning.** Previous backup is deleted before new one is written — if upload fails mid-way, data is in a broken state.
6. **No sync status visibility.** User can't tell if sync succeeded, when it last ran, or what device uploaded the cloud copy.

---

## Proposed redesign options

### Option A — Switch to Firestore
Replace Google Drive with Firestore. Each habit and day is its own document, synced incrementally. Encrypt at rest using native device encryption (platform keychain holds the key) with optional user-defined code as a second layer.

**Pros:**
- Real-time sync, incremental — only changed documents are written
- No passphrase friction by default (key lives in device secure enclave)
- Firestore SDK handles offline queuing, retries, conflict resolution natively
- Much simpler sync logic in app code

**Cons:**
- **Breaks the privacy-first promise.** Data lives on Google's Firestore servers. Even if content is encrypted, Google sees access patterns, document counts, timestamps. This is a core value violation for Habitt.
- Ongoing backend cost at scale
- Requires Firestore security rules, schema design, and ongoing maintenance
- Harder to migrate existing users

---

### Option B — Optimize Google Drive + native encryption (recommended)
Keep Google Drive but fix both the UX and the performance:

**Encryption:** Ditch the user passphrase as the default. Generate a random 256-bit key on first sign-in, store it in the platform keychain (iOS Keychain / Android Keystore). The key never leaves the device's secure enclave — it encrypts the data before it goes to Drive, and decrypts it on download. User never sees a passphrase. For users who want extra paranoia, offer an optional PIN/passphrase as a second layer that wraps the keychain key — but it's opt-in, not required.

**Incremental sync:** Instead of a full snapshot, maintain a change log. Each habit write appends a small JSON delta (habitId + changed fields + timestamp). On sync, only upload deltas since last successful sync. On download, apply deltas in order. Full snapshots are only done on first sync or on explicit "full backup" request.

**Versioning:** Keep the last 3 backups on Drive instead of delete-then-replace. Rotation happens after successful upload.

**Sync trigger:** Keep the 15-second debounce but add a smarter condition — if deltas are tiny (< 1KB) sync immediately; only debounce for large changes.

**Pros:**
- Fully privacy-first — data stays on user's own Google Drive
- No passphrase to remember, no lock-out risk
- Much lighter on bandwidth and Drive API calls
- Recoverable if a sync upload fails (previous backup still exists)
- Zero backend cost

**Cons:**
- More complex to implement than current system
- Delta sync requires a reliable change log; if the log gets corrupted, fall back to full snapshot
- Still dependent on Google account (Drive)

---

### Option C — Both options, user chooses
Implement Option A and Option B and let the user pick.

**Pros:** Maximum flexibility

**Cons:**
- Double the codebase surface area
- Double the maintenance burden
- Two separate sync logic paths to keep bug-free
- Most users don't want to choose infrastructure — they want it to just work

---

## Recommendation

**Option B.** Here's the reasoning:

Habitt is explicitly privacy-first and local-first. Firestore (Option A) directly contradicts that — even with encryption, the user's data is on a third-party server with metadata Google can observe. That's a value trade-off that would need to be communicated to users and likely wouldn't sit right with the core audience.

Option C doubles the maintenance burden without a proportionate user benefit.

Option B fixes the two most painful problems — passphrase friction and full-snapshot bloat — while keeping everything on the user's own Drive. The native keychain approach is what every serious sync app (1Password, Bear, Obsidian Sync) uses. It's invisible, recoverable (keychain can be backed up with iCloud Keychain), and doesn't require user education.

### Implementation order for Option B
1. Replace passphrase encryption with keychain-derived key (biggest UX win, lowest risk)
2. Add backup versioning (keep last 3 snapshots) to eliminate data-loss-on-failed-upload
3. Implement delta sync change log (performance win, most complex)
4. Optional: add PIN as opt-in second layer for paranoid users

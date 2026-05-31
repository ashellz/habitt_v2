import 'dart:async';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive_api;
import 'package:habitt/firebase_options.dart';
import 'package:habitt/models/backup_data.dart';
import 'package:habitt/models/backup_metadata.dart';
import 'package:habitt/models/drive_backup_file.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/services/backup_service.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

enum SyncState { idle, syncing, success, error }

/// Controls which parts of the sync cycle run
enum SyncMode {
  /// full cycle: checks for remote changes from other devices (checks deltas), then uploads own
  /// delta (or full backup on first sync if forced)
  /// Used on app launch and app resume from background
  full,

  /// upload only: skips checking for remote changes, just uploads own delta
  /// used by the 15 second timer after changes - auto sync
  uploadOnly,
}

class BackupProvider extends ChangeNotifier {
  BackupProvider();

  static const String _kBackupUserEmailKey = 'backup_user_email';
  static const String _kBackupUserIdKey = 'backup_user_id';
  static const String _kAutoSyncEnabledKey = 'backup_auto_sync_enabled';
  static const String _kLastSyncTimeKey = 'backup_last_sync_time';
  static const String _kLegacyPassphraseKey = 'habitt_backup_passphrase';
  static const String _kPinEnabledKey = 'backup_pin_enabled';

  /// id of JSON-encoded List<String> of Drive file IDs for deltas already applied to
  /// this device. Cleared when a full sync runs.
  static const String _kAppliedDeltaIdsKey = 'backup_applied_delta_ids';

  /// start a full compaction sync when this many delta files accumulate:
  static const int _kDeltaCompactionThreshold = 20;

  GoogleSignInAccount? _currentUser;
  User? _firebaseUser;
  late final GoogleSignIn _googleSignIn;
  late final FlutterSecureStorage _secureStorage;
  HabitProvider? _habitProvider;

  SyncState _syncState = SyncState.idle;
  String? _lastError;
  BackupMetadata? _localMetadata;
  Timer? _autoSyncTimer;

  bool _isAutoSyncEnabled = true;
  DateTime? _lastSyncTime;

  // Set to true when the Drive has data encrypted with the old passphrase
  // system. The UI surfaces a migration prompt in this state.
  bool _needsMigration = false;
  String? _legacyPassphrase;

  bool _dataExists = false;

  /// Set after login when Drive has data and local DB is non-empty.
  /// The UI should watch this and present the merge/replace choice dialog.
  bool _pendingRestoreDecision = false;

  bool _isPinEnabled = false;
  // Decrypted keychain key cached in memory after PIN entry. Cleared on restart.
  SecretKey? _cachedKey;

  // True while a scheduleAutoSync timer is pending but hasn't fired yet.
  bool _hasPendingSync = false;

  String? _progressMessage;

  // Set when the user is silently signed out due to revoked Drive scope.
  // Consumed once by the UI to show a notification popup.
  String? _pendingNotification;

  // Set when Drive has a PIN-wrapped key.key and no stored PIN is available
  // locally. UI shows a PIN entry dialog; submitCloudPin() clears this.
  bool _pendingCloudPinEntry = false;
  Map<String, dynamic>? _cloudPinWrapped;

  // Set when a specific backup file could not be decrypted with any known key.
  // UI shows a passphrase prompt; retryRestoreWithPassphrase() clears this.
  String? _failedBackupFileId;
  Uint8List? _failedBackupFileBytes;

  // --- Getters -----------------------------------------------------------

  GoogleSignInAccount? get currentUser => _currentUser;
  User? get firebaseUser => _firebaseUser;
  bool get isLoggedIn => _currentUser != null && _firebaseUser != null;
  BackupMetadata? get localMetadata => _localMetadata;
  SyncState get syncState => _syncState;
  String? get lastError => _lastError;
  bool get dataExists => _dataExists;
  String? get progressMessage => _progressMessage;
  bool get isAutoSyncEnabled => _isAutoSyncEnabled;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get needsMigration => _needsMigration;
  bool get isPinEnabled => _isPinEnabled;
  bool get pendingCloudPinEntry => _pendingCloudPinEntry;
  bool get hasPendingBackupPassphrase => _failedBackupFileId != null;
  String? get pendingNotification => _pendingNotification;
  bool get pendingRestoreDecision => _pendingRestoreDecision;
  bool get hasPendingSync => _hasPendingSync;

  void clearPendingNotification() {
    _pendingNotification = null;
  }

  set syncState(SyncState state) {
    _syncState = state;
    notifyListeners();
  }

  set lastError(String? error) {
    _lastError = error;
    notifyListeners();
  }

  set progressMessage(String? message) {
    _progressMessage = message;
    debugPrint(_progressMessage);
    notifyListeners();
  }

  void attachHabitProvider(HabitProvider provider) {
    _habitProvider = provider;
  }

  // --- Auto-sync ---------------------------------------------------------

  void scheduleAutoSync() {
    if (!isLoggedIn || !_isAutoSyncEnabled) return;

    _autoSyncTimer?.cancel();
    _hasPendingSync = true;
    _autoSyncTimer = Timer(const Duration(seconds: 15), () {
      _hasPendingSync = false;
      // Upload-only: just push local changes as a delta — no remote check.
      // Remote checks happen on resume (SyncMode.full via didChangeAppLifecycleState).
      performSync(false, SyncMode.uploadOnly).catchError((e) {
        debugPrint('Auto-sync failed: $e');
      });
    });
  }

  /// Flush any pending auto-sync immediately. Called when the app is about
  /// to be suspended (AppLifecycleState.paused) so changes aren't lost if
  /// the user leaves before the 15-second timer fires.
  void flushPendingSyncIfNeeded() {
    if (!_hasPendingSync) return;
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    _hasPendingSync = false;
    performSync(false, SyncMode.uploadOnly).catchError((e) {
      debugPrint('Auto-sync (app pause) failed: $e');
    });
  }

  Future<void> setAutoSyncEnabled(bool value) async {
    _isAutoSyncEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoSyncEnabledKey, value);
    notifyListeners();
  }

  // --- PIN protection ----------------------------------------------------

  /// Returns the backup key. When PIN is enabled the stored PIN is read from
  /// the keychain automatically — no user prompt needed after first setup.
  /// Returns null only if PIN is enabled but no stored PIN is available yet
  /// (e.g. iCloud Keychain hasn't synced to this device yet).
  Future<SecretKey?> _getKey() async {
    if (_cachedKey != null) return _cachedKey!;
    if (!_isPinEnabled) return BackupService.getOrCreateKey(_secureStorage);

    final pin = await BackupService.readStoredPin(_secureStorage);
    if (pin == null) {
      // No stored PIN — will be resolved by _syncKeyWithDrive on next full sync.
      return null;
    }

    final key = await BackupService.unwrapKeyWithPin(_secureStorage, pin);
    if (key != null) {
      _cachedKey = key;
      return key;
    }

    // Stored PIN is wrong or corrupted — force a full sync next cycle so
    // _syncKeyWithDrive can detect the mismatch and surface a re-entry prompt.
    _lastSyncTime = null;
    return null;
  }

  /// Wraps the keychain key with [pin], stores both the wrapped key and the
  /// raw PIN (so auto-sync works on future app launches without re-entry).
  /// Also re-uploads key.key to Drive in PIN-wrapped format.
  Future<bool> enablePin(String pin) async {
    try {
      // gets existing or creates a new key
      final key = await BackupService.getOrCreateKey(_secureStorage);

      // wraps the key with entered pin
      final wrapped = await BackupService.wrapKeyWithPin(key, pin);

      // stores pin with instructions json
      await BackupService.storePinData(_secureStorage, wrapped);

      // stores raw pin for auto-unwrap on future launches
      await BackupService.storePin(_secureStorage, pin);

      final prefs = await SharedPreferences.getInstance();

      // sets PIN enabled flag
      await prefs.setBool(_kPinEnabledKey, true);
      _isPinEnabled = true;
      _cachedKey = key;
      notifyListeners();

      // uploads the key to drive
      await _uploadKeyFileToDrive();
      return true;
    } catch (e) {
      debugPrint('Enable PIN failed: $e');
      return false;
    }
  }

  /// Verifies [pin] against the stored wrapped key, then clears all PIN data.
  /// Returns false if [pin] is wrong.
  /// Also re-uploads key.key to Drive in plain format.
  Future<bool> disablePin(String pin) async {
    final key = await BackupService.unwrapKeyWithPin(_secureStorage, pin);
    if (key == null) return false;
    await BackupService.clearPinData(_secureStorage);
    await BackupService.clearStoredPin(_secureStorage);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPinEnabledKey, false);
    _isPinEnabled = false;
    _cachedKey = null;
    notifyListeners();
    await _uploadKeyFileToDrive();
    return true;
  }

  // --- Initialization ----------------------------------------------------

  Future<void> initialize() async {
    _googleSignIn = GoogleSignIn(
      scopes: [drive_api.DriveApi.driveFileScope],
      clientId: DefaultFirebaseOptions.ios.iosClientId,
      serverClientId:
          '752709751941-vt92fpp7ge9gs8cs4rrnlvrkk84aekmc.apps.googleusercontent.com',
    );

    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        keyCipherAlgorithm:
            KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      _isAutoSyncEnabled = prefs.getBool(_kAutoSyncEnabledKey) ?? true;
      _isPinEnabled = prefs.getBool(_kPinEnabledKey) ?? false;

      // Pre-load key from stored PIN so auto-sync works immediately on startup.
      if (_isPinEnabled) {
        final pin = await BackupService.readStoredPin(_secureStorage);
        if (pin != null) {
          _cachedKey = await BackupService.unwrapKeyWithPin(
            _secureStorage,
            pin,
          );
        }
      }

      final lastSyncMs = prefs.getInt(_kLastSyncTimeKey);
      if (lastSyncMs != null) {
        _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
      }

      final savedEmail = prefs.getString(_kBackupUserEmailKey);
      _localMetadata = await BackupService.buildMetadata();

      if (savedEmail != null) {
        final user = await _googleSignIn.signInSilently();
        if (user != null) {
          // If the user revoked Drive scope (e.g. from Google account settings),
          // silently sign out so they're prompted to re-authorize on next sign-in.
          bool hasScope;
          try {
            hasScope = await _googleSignIn.canAccessScopes([
              drive_api.DriveApi.driveFileScope,
            ]);
          } on UnimplementedError {
            hasScope = true; // Android enforces scope during sign-in
          }
          if (!hasScope) {
            await _googleSignIn.signOut();
            await FirebaseAuth.instance.signOut();
            _pendingNotification =
                'Google Drive access was revoked. Please sign in again to re-enable backup.';
            await _clearLocalAuthState(prefs);
            return;
          }

          _currentUser = user;
          _firebaseUser = FirebaseAuth.instance.currentUser;

          // Verify the Firebase account still exists — catches remote deletions
          // (e.g. user deleted account on another device).
          if (_firebaseUser != null) {
            try {
              await _firebaseUser!.reload();
              _firebaseUser = FirebaseAuth.instance.currentUser;
            } on FirebaseAuthException {
              await _clearLocalAuthState(prefs);
              return;
            }
          }

          if (_firebaseUser == null) {
            // Google session alive but Firebase account gone — sign out cleanly.
            await _googleSignIn.signOut();
            await _clearLocalAuthState(prefs);
            return;
          }

          // Check for legacy passphrase (old system) to surface migration UI
          _legacyPassphrase = await _secureStorage.read(
            key: _kLegacyPassphraseKey,
          );
          _needsMigration = _legacyPassphrase != null;

          _dataExists = await _checkDataExists();
          notifyListeners();

          // If the user logged in on a previous session but never completed the
          // restore-choice dialog (i.e. _lastSyncTime is still null), auto-merge
          // on the next app open. Merge is always safe — it never overwrites
          // local data, it only brings in cloud data.
          if (!_needsMigration && _dataExists && _lastSyncTime == null) {
            await performSync(true);
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to restore sign-in state: $e');
    }
  }

  // --- Sign-in / Sign-out ------------------------------------------------

  Future<void> _clearLocalAuthState(SharedPreferences prefs) async {
    _currentUser = null;
    _firebaseUser = null;
    _syncState = SyncState.idle;
    _needsMigration = false;
    _legacyPassphrase = null;
    _lastSyncTime = null;
    _cachedKey = null;
    _isPinEnabled = false;
    _pendingCloudPinEntry = false;
    _cloudPinWrapped = null;
    _failedBackupFileId = null;
    _failedBackupFileBytes = null;
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    await prefs.remove(_kBackupUserEmailKey);
    await prefs.remove(_kBackupUserIdKey);
    await prefs.remove(_kLastSyncTimeKey);
    await prefs.remove(_kAppliedDeltaIdsKey);
    notifyListeners();
  }

  Future<void> signIn(BuildContext context) async {
    try {
      final user = await _googleSignIn.signIn();
      if (user == null) return;

      // Verify Drive scope was granted — on Android 12+ users can selectively
      // deny scopes while still completing sign-in.
      bool hasScope;
      try {
        hasScope = await _googleSignIn.canAccessScopes([
          drive_api.DriveApi.driveFileScope,
        ]);
      } on UnimplementedError {
        hasScope = true; // Android enforces scope during sign-in
      }
      if (!hasScope) {
        bool granted;
        try {
          granted = await _googleSignIn.requestScopes([
            drive_api.DriveApi.driveFileScope,
          ]);
        } on UnimplementedError {
          granted = true;
        }
        if (!granted) {
          await _googleSignIn.signOut();
          _lastError =
              'Google Drive access is required for backup. Please sign in again and allow Drive access when prompted.';
          notifyListeners();
          return;
        }
      }

      final auth = await user.authentication.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Google auth timed out'),
      );

      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      _currentUser = user;
      _firebaseUser = FirebaseAuth.instance.currentUser;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kBackupUserEmailKey, user.email);
      await prefs.setString(_kBackupUserIdKey, user.id);

      // Check for legacy passphrase
      _legacyPassphrase = await _secureStorage.read(key: _kLegacyPassphraseKey);
      _needsMigration = _legacyPassphrase != null;

      _dataExists = await _checkDataExists();

      if (!_needsMigration) {
        final localIsEmpty = Hive.box<Habit>('habits').isEmpty;
        if (_dataExists && !localIsEmpty) {
          // Local data exists and Drive has a backup — let the user decide.
          _pendingRestoreDecision = true;
          notifyListeners();
        } else {
          // Empty local DB → auto-restore from cloud (merge into empty = full
          // restore). No cloud data → upload local as first backup.
          notifyListeners();
          await performSync(true);
        }
      } else {
        notifyListeners();
      }
    } catch (e) {
      _lastError = 'Failed to sign in: $e';
      debugPrint(_lastError);
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();

      _currentUser = null;
      _firebaseUser = null;
      _syncState = SyncState.idle;
      _needsMigration = false;
      _legacyPassphrase = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kBackupUserEmailKey);
      await prefs.remove(_kBackupUserIdKey);

      _autoSyncTimer?.cancel();
      _autoSyncTimer = null;

      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to sign out: $e';
      debugPrint(_lastError);
      notifyListeners();
    }
  }

  /// Permanently deletes the Firebase Auth account. Google Drive backup files
  /// are left untouched. On other devices, the next app open will detect the
  /// missing account and sign out automatically.
  Future<bool> deleteAccount() async {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;

    try {
      var firebaseUser = _firebaseUser ?? FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;

      try {
        await firebaseUser.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          // Token too old — reauthenticate with Google then retry.
          final googleUser = await _googleSignIn.signIn();
          if (googleUser == null) return false;
          final auth = await googleUser.authentication.timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Google auth timed out'),
          );
          final credential = GoogleAuthProvider.credential(
            accessToken: auth.accessToken,
            idToken: auth.idToken,
          );
          await firebaseUser.reauthenticateWithCredential(credential);
          await firebaseUser.delete();
        } else {
          rethrow;
        }
      }

      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await _clearLocalAuthState(prefs);
      return true;
    } catch (e) {
      _lastError = 'Failed to delete account: $e';
      debugPrint(_lastError);
      notifyListeners();
      return false;
    }
  }

  // --- Migration ---------------------------------------------------------

  /// Migrate a passphrase-encrypted Drive backup to the device keychain key.
  /// Returns true on success.
  Future<bool> migrateFromLegacy(String oldPassphrase) async {
    if (!isLoggedIn) return false;
    syncState = SyncState.syncing;

    try {
      final drive = await _getDriveService();
      if (drive == null) {
        lastError = 'Drive service unavailable';
        syncState = SyncState.error;
        return false;
      }

      final folderId = await _getFolderId(drive);
      if (folderId == null) {
        lastError = 'Could not access backup folder';
        syncState = SyncState.error;
        return false;
      }

      // Verify passphrase by trying to decrypt metadata
      final metadataBytes = await _downloadFileBytes(
        drive,
        folderId,
        'metadata.meta',
      );
      if (metadataBytes != null) {
        final meta = await BackupService.importMetadataLegacy(
          encryptedBytes: metadataBytes,
          passphrase: oldPassphrase,
        );
        if (meta == null) {
          lastError = 'Wrong passphrase';
          syncState = SyncState.error;
          return false;
        }
      }

      // Download and decrypt legacy backup
      final backupBytes = await _downloadLatestBackupBytes(drive, folderId);
      BackupData? backupData;
      if (backupBytes != null) {
        backupData = await BackupService.importDataFromGoogleDriveLegacy(
          encryptedBytes: backupBytes,
          passphrase: oldPassphrase,
        );
        if (backupData != null) {
          await _mergeBackupData(backupData);
        }
      }

      // Re-encrypt and upload with new keychain key
      final newKey = await BackupService.getOrCreateKey(_secureStorage);
      await _uploadBackupToCloud(newKey);

      // Clear legacy passphrase from keychain
      await _secureStorage.delete(key: _kLegacyPassphraseKey);
      _legacyPassphrase = null;
      _needsMigration = false;

      _lastSyncTime = DateTime.now();
      await _persistLastSyncTime();

      syncState = SyncState.success;
      return true;
    } catch (e) {
      lastError = 'Migration failed: $e';
      syncState = SyncState.error;
      debugPrint(lastError);
      return false;
    }
  }

  // --- Legacy discard --------------

  /// Deletes old passphrase-encrypted Drive backup, clears the local
  /// migration flag, and uploads a fresh backup with the new keychain key
  /// Safe to call when the user has forgotten their old passphrase.
  Future<void> discardLegacyBackup() async {
    if (!isLoggedIn) return;

    syncState = SyncState.syncing;
    lastError = null;

    try {
      // Clear local legacy passphrase so _needsMigration won't re-trigger
      await _secureStorage.delete(key: _kLegacyPassphraseKey);
      _legacyPassphrase = null;
      _needsMigration = false;

      // Delete all existing Drive files (old encrypted backups + metadata)
      final drive = await _getDriveService();
      if (drive != null) {
        final folderId = await _getFolderId(drive, create: false);
        if (folderId != null) {
          final found = await drive.files.list(
            q: "'$folderId' in parents and trashed = false",
            $fields: 'files(id)',
          );
          if (found.files != null) {
            for (final f in found.files!) {
              if (f.id != null) await drive.files.delete(f.id!);
            }
          }
        }
      }

      // Upload fresh backup with the new keychain key
      final key = await BackupService.getOrCreateKey(_secureStorage);
      await _uploadBackupToCloud(key);
      await _onSyncSuccess();
    } catch (e) {
      debugPrint('Discard legacy backup failed: $e');
      // Clear migration state even if Drive cleanup partially failed
      _needsMigration = false;
      syncState = SyncState.idle;
      notifyListeners();
    }
  }

  // --- Post-login restore choices ----------------------------------------

  /// Called when the user picks "Merge": pulls cloud data and merges it into
  /// the existing local DB using timestamp-based conflict resolution.
  Future<void> confirmMerge() async {
    _pendingRestoreDecision = false;
    notifyListeners();
    await performSync(true); // force=true: bypass same-device skip
  }

  /// Called when the user picks "Start fresh": wipes the local DB and
  /// restores entirely from the latest cloud backup + all deltas.
  Future<void> confirmReplace() async {
    _pendingRestoreDecision = false;
    notifyListeners();

    if (_syncState == SyncState.syncing) return;
    await _ensureKeySync();
    final key = await _getKey();
    if (key == null) return;

    progressMessage = 'Preparing restore...';
    syncState = SyncState.syncing;
    lastError = null;

    try {
      await _replaceFromCloud(key);
      await _onSyncSuccess();
    } catch (e) {
      syncState = SyncState.error;
      lastError = 'Restore failed: $e';
      debugPrint(lastError);
      notifyListeners();
    }
  }

  /// Clears the local DB, then downloads the latest full backup from Drive
  /// and applies every delta on top, giving a clean slate identical to the
  /// cloud state.
  Future<void> _replaceFromCloud(SecretKey key) async {
    progressMessage = 'Clearing local data...';
    await Hive.box<Habit>('habits').clear();
    await Hive.box<Day>('days').clear();

    // Reset applied-deltas cursor so we fetch them all fresh.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAppliedDeltaIdsKey);

    // Let the habit provider reload the (now empty) state.
    await _habitProvider?.init();

    // Restore the latest full backup.
    progressMessage = 'Downloading backup...';
    final backupData = await _downloadBackupFromCloud(key);
    if (backupData != null) {
      progressMessage = 'Restoring data...';
      await _mergeBackupData(backupData);
    }

    // Apply every delta file on top (all devices, all deltas).
    final drive = await _getDriveService();
    if (drive != null) {
      final folderId = await _getFolderId(drive, create: false);
      if (folderId != null) {
        progressMessage = 'Applying updates...';
        await _downloadAndApplyAllDeltas(drive, folderId, key);
      }
    }
  }

  /// Downloads and applies every delta file on Drive, without skipping by
  /// device ID or already-applied set. Used after a full local wipe so we
  /// reconstruct the complete cloud state.
  Future<void> _downloadAndApplyAllDeltas(
    drive_api.DriveApi drive,
    String folderId,
    SecretKey key,
  ) async {
    final res = await drive.files.list(
      q: "name contains 'habitt-delta' and '$folderId' in parents and trashed = false",
      $fields: 'files(id,name,createdTime)',
      orderBy: 'createdTime asc',
    );

    final allFiles = res.files ?? [];
    if (allFiles.isEmpty) return;

    final applied = <String>{};
    for (final f in allFiles) {
      if (f.id == null) continue;
      try {
        final response =
            await drive.files.get(
                  f.id!,
                  downloadOptions: drive_api.DownloadOptions.fullMedia,
                )
                as drive_api.Media;

        final bytes = <int>[];
        await for (final chunk in response.stream) {
          bytes.addAll(chunk);
        }

        final backupData = await BackupService.importDataFromGoogleDrive(
          encryptedBytes: Uint8List.fromList(bytes),
          secretKey: key,
        );

        if (backupData != null) {
          await _mergeBackupData(backupData);
          applied.add(f.id!);
          debugPrint('Applied delta ${f.id} (${f.name})');
        }
      } catch (e) {
        debugPrint('Skipped delta ${f.id}: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAppliedDeltaIdsKey, jsonEncode(applied.toList()));
  }

  // --- Sync --------------------------------------------------------------

  /// Main sync entry point.
  ///
  /// [force] — when true and [mode] is [SyncMode.full], always performs a full
  /// database upload regardless of which device last synced.
  ///
  /// [mode] — [SyncMode.full] (default) checks Drive for changes from other
  /// devices then uploads own delta or full backup as appropriate.
  /// [SyncMode.uploadOnly] skips the remote-check step and only uploads
  /// this device's pending changes as a delta — used by [scheduleAutoSync].
  Future<void> performSync([
    bool force = false,
    SyncMode mode = SyncMode.full,
  ]) async {
    if (_syncState == SyncState.syncing) return;

    if (!isLoggedIn) {
      lastError = 'Not signed in.';
      syncState = SyncState.error;
      return;
    }

    if (_needsMigration) {
      lastError = 'Migration required before syncing.';
      syncState = SyncState.error;
      return;
    }

    final key = await _getKey();
    if (key == null) return; // PIN locked

    progressMessage = 'Starting sync...';
    syncState = SyncState.syncing;
    lastError = null;

    try {
      // ── Upload-only path (post-write auto-sync) ──────────────────────────
      if (mode == SyncMode.uploadOnly) {
        await _uploadDeltaToCloud(key);
        await _onSyncSuccess();
        return;
      }

      // Sync the encryption key with Drive before any decrypt attempt.
      // This is what enables cross-platform restore (e.g. iOS → Android).
      await _ensureKeySync();

      // Key is PIN-protected and user hasn't entered PIN yet — pause sync.
      if (_pendingCloudPinEntry) {
        syncState = SyncState.idle;
        progressMessage = null;
        return;
      }

      // ── Full cycle: delta path or full-backup path ───────────────────────
      // Use delta when: not forced AND we have a sync cursor (_lastSyncTime).
      // First sync or forced always goes to the full backup path.
      final bool useDelta = !force && _lastSyncTime != null;

      if (useDelta) {
        final drive = await _getDriveService();
        if (drive == null) {
          // No Drive access — silently succeed to avoid error UI for a
          // transient connectivity issue.
          await _onSyncSuccess();
          return;
        }
        final folderId = await _getFolderId(drive);
        if (folderId == null) {
          await _onSyncSuccess();
          return;
        }

        progressMessage = 'Checking for updates...';
        await _downloadAndApplyPendingDeltas(drive, folderId, key);

        progressMessage = 'Uploading changes...';
        await _uploadDeltaToCloud(key);

        // Compaction: too many delta files → collapse to a full backup.
        final deltaCount = await _countDeltaFiles(drive, folderId);
        if (deltaCount >= _kDeltaCompactionThreshold) {
          progressMessage = 'Compacting backups...';
          await _fullSyncPath(key, force: true);
          await _clearAllDeltaFiles(drive, folderId);
        }
      } else {
        // Full-backup path: download latest, merge, re-upload entire DB.
        await _fullSyncPath(key, force: force);

        // Wipe all delta files — the new full backup supersedes them.
        final drive = await _getDriveService();
        if (drive != null) {
          final folderId = await _getFolderId(drive, create: false);
          if (folderId != null) await _clearAllDeltaFiles(drive, folderId);
        }
      }

      await _onSyncSuccess();
    } catch (e) {
      if (e is FormatException && e.message == 'legacy_v1') {
        // Cloud backup encrypted with the old passphrase — surface migration UI.
        _needsMigration = true;
        syncState = SyncState.idle;
        lastError = null;
        notifyListeners();
        return;
      }
      syncState = SyncState.error;
      lastError = 'Sync failed: $e';
      debugPrint(lastError);
      notifyListeners();
    }
  }

  /// Download the latest full backup from Drive, merge it, then re-upload.
  ///
  /// Skips the upload when the last backup was from this device and [force]
  /// is false — there is nothing new to pull and nothing has changed server-side.
  Future<void> _fullSyncPath(SecretKey key, {bool force = false}) async {
    progressMessage = 'Fetching cloud metadata...';
    final metadata = await _fetchCloudMetadata(key);

    final sameDevice =
        _localMetadata?.deviceId == metadata?.deviceId &&
        metadata != null &&
        _localMetadata != null;

    if (sameDevice && !force) {
      // We were the last device to upload — nothing new to pull.
      return;
    }

    if (metadata != null) {
      progressMessage = 'Downloading backup...';
      final backupData = await _downloadBackupFromCloud(key);
      if (backupData != null) {
        progressMessage = 'Merging...';
        await _mergeBackupData(backupData);
      }
      progressMessage = 'Uploading merged backup...';
      await _uploadBackupToCloud(key);
    } else {
      progressMessage = 'No cloud data. Uploading local backup...';
      await _uploadBackupToCloud(key);
    }
  }

  /// Returns the number of delta (.habittd) files currently on Drive.
  Future<int> _countDeltaFiles(
    drive_api.DriveApi drive,
    String folderId,
  ) async {
    final res = await drive.files.list(
      q: "name contains 'habitt-delta' and '$folderId' in parents and trashed = false",
      $fields: 'files(id)',
    );
    return (res.files ?? []).length;
  }

  /// Download the latest Drive backup and merge it into local data.
  Future<void> restoreFromCloud() async {
    if (_syncState == SyncState.syncing) return;
    if (!isLoggedIn) {
      lastError = 'Not signed in.';
      return;
    }

    await _ensureKeySync();
    final key = await _getKey();
    if (key == null) return;

    progressMessage = 'Downloading backup...';
    syncState = SyncState.syncing;
    lastError = null;

    try {
      final backupData = await _downloadBackupFromCloud(key);
      if (backupData != null) {
        progressMessage = 'Merging...';
        await _mergeBackupData(backupData);
        await _onSyncSuccess();
      } else {
        lastError = 'No backup found in cloud.';
        syncState = SyncState.error;
      }
    } catch (e) {
      lastError = 'Restore failed: $e';
      syncState = SyncState.error;
      debugPrint(lastError);
    }
  }

  Future<void> _onSyncSuccess() async {
    _lastSyncTime = DateTime.now();
    await _persistLastSyncTime();
    syncState = SyncState.success;
    progressMessage = null;
  }

  Future<void> _persistLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastSyncTime != null) {
      await prefs.setInt(
        _kLastSyncTimeKey,
        _lastSyncTime!.millisecondsSinceEpoch,
      );
    }
  }

  // --- Cross-platform key sync -------------------------------------------

  /// Syncs the backup encryption key with Google Drive.
  ///
  /// Always reads the Drive `key.key` envelope and reconciles with local state.
  /// Six cases are handled (see plan for full matrix):
  ///
  ///   • Drive missing  → upload local key
  ///   • Drive plain  + no local key   → install key locally
  ///   • Drive pin    + no local key   → [_handlePinWrappedDriveKey]
  ///   • Drive plain  + local + PIN off → no-op (consistent)
  ///   • Drive plain  + local + PIN on  → [_applyDriveDisabledPin] (other device disabled PIN)
  ///   • Drive pin    + local + PIN off → [_handlePinWrappedDriveKey] (other device enabled PIN)
  ///   • Drive pin    + local + PIN on + stored PIN works → no-op (consistent)
  ///   • Drive pin    + local + PIN on + stored PIN fails → [_handlePinWrappedDriveKey] (PIN changed)
  Future<void> _syncKeyWithDrive(
    drive_api.DriveApi drive,
    String folderId,
  ) async {
    try {
      const keyFileName = 'key.key';
      final driveKeyRaw = await _downloadFileBytes(
        drive,
        folderId,
        keyFileName,
      );

      if (driveKeyRaw == null) {
        await _uploadKeyFileToDrive(drive: drive, folderId: folderId);
        return;
      }

      final content = utf8.decode(driveKeyRaw);
      final hasLocal = await BackupService.hasStoredKey(_secureStorage);

      // Parse JSON envelope; fall back to old plain-base64 for backward compat.
      Map<String, dynamic> envelope;
      try {
        envelope = jsonDecode(content) as Map<String, dynamic>;
      } catch (_) {
        if (!hasLocal) {
          await BackupService.storeKeyBytes(
            _secureStorage,
            base64Decode(content),
          );
          debugPrint('Key synced (legacy plain-b64) → local keychain');
        }
        return;
      }

      final type = envelope['type'] as String?;

      if (!hasLocal) {
        // New device — install whatever Drive has.
        if (type == 'plain') {
          await BackupService.storeKeyBytes(
            _secureStorage,
            base64Decode(envelope['key'] as String),
          );
          debugPrint('Key installed (plain) → local keychain');
        } else {
          await _handlePinWrappedDriveKey(envelope);
        }
        return;
      }

      // Existing device — reconcile PIN state with Drive.
      if (type == 'plain') {
        if (_isPinEnabled) {
          // Another device disabled PIN — sync state locally.
          await _applyDriveDisabledPin(envelope);
        }
        // else: both plain, consistent — no-op.
      } else {
        // Drive is PIN-wrapped.
        if (!_isPinEnabled) {
          // Another device enabled PIN — prompt user.
          await _handlePinWrappedDriveKey(envelope);
        } else {
          // PIN enabled on both — verify stored PIN still works.
          final storedPin = await BackupService.readStoredPin(_secureStorage);
          if (storedPin != null) {
            final key = await _unwrapKeyFromEnvelope(envelope, storedPin);
            if (key == null) {
              // PIN changed on another device — prompt re-entry.
              await _handlePinWrappedDriveKey(envelope);
            } else {
              // PIN valid — ensure local key matches the Drive key.
              // Covers the case where Android had a locally-generated key
              // that differs from the iOS key used to encrypt backups.
              final keyBytes = await key.extractBytes();
              await BackupService.storeKeyBytes(_secureStorage, keyBytes);
              _cachedKey =
                  null; // force _getKey() to re-derive from updated storage
            }
          } else {
            await _handlePinWrappedDriveKey(envelope);
          }
        }
      }
    } catch (e) {
      debugPrint('Key sync skipped: $e');
    }
  }

  /// Another device disabled PIN. Downloads the plain key bytes from the Drive
  /// envelope and clears local PIN state so both devices are consistent.
  Future<void> _applyDriveDisabledPin(Map<String, dynamic> envelope) async {
    try {
      final keyBytes = base64Decode(envelope['key'] as String);
      await BackupService.storeKeyBytes(_secureStorage, keyBytes);
      await BackupService.clearPinData(_secureStorage);
      await BackupService.clearStoredPin(_secureStorage);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPinEnabledKey, false);
      _isPinEnabled = false;
      _cachedKey = null;
      notifyListeners();
      debugPrint('PIN disabled from Drive — local state updated');
    } catch (e) {
      debugPrint('_applyDriveDisabledPin failed: $e');
    }
  }

  /// Drive has a PIN-wrapped key. Tries to unwrap with any locally-stored PIN.
  /// On success, installs the key and enables local PIN state.
  /// On failure (no stored PIN, or wrong PIN), surfaces a user prompt via
  /// [_pendingCloudPinEntry] and [_pendingNotification].
  Future<void> _handlePinWrappedDriveKey(Map<String, dynamic> envelope) async {
    final storedPin = await BackupService.readStoredPin(_secureStorage);
    if (storedPin != null) {
      final key = await _unwrapKeyFromEnvelope(envelope, storedPin);
      if (key != null) {
        final keyBytes = await key.extractBytes();
        await BackupService.storeKeyBytes(_secureStorage, keyBytes);
        await BackupService.storePinData(_secureStorage, {
          'salt': envelope['salt'] as String,
          'nonce': envelope['nonce'] as String,
          'ciphertext': envelope['ciphertext'] as String,
          'tag': envelope['tag'] as String,
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kPinEnabledKey, true);
        _isPinEnabled = true;
        notifyListeners();
        debugPrint('Key synced (PIN-wrapped) → local keychain');
        return;
      }
    }
    // No stored PIN or wrong PIN — prompt the user.
    _cloudPinWrapped = envelope;
    _pendingCloudPinEntry = true;
    _pendingNotification = 'Backup sync paused — enter PIN';
    notifyListeners();
    debugPrint('Cloud key is PIN-wrapped — awaiting user PIN entry');
  }

  /// Decrypts a PIN-wrapped key envelope directly (without reading local storage).
  Future<SecretKey?> _unwrapKeyFromEnvelope(
    Map<String, dynamic> envelope,
    String pin,
  ) async {
    try {
      final salt = base64Decode(envelope['salt'] as String);
      final nonce = base64Decode(envelope['nonce'] as String);
      final cipher = base64Decode(envelope['ciphertext'] as String);
      final tag = base64Decode(envelope['tag'] as String);

      final aes = AesGcm.with256bits();
      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: 200000,
        bits: 256,
      );
      final pinKey = await pbkdf2.deriveKey(
        secretKey: SecretKey(utf8.encode(pin)),
        nonce: salt,
      );
      final decrypted = await aes.decrypt(
        SecretBox(cipher, nonce: nonce, mac: Mac(tag)),
        secretKey: pinKey,
      );
      return SecretKey(decrypted);
    } on SecretBoxAuthenticationError {
      return null;
    } catch (e) {
      debugPrint('Envelope unwrap error: $e');
      return null;
    }
  }

  /// Builds the `key.key` file content and uploads it to Drive.
  /// When [_isPinEnabled], the key is wrapped with PBKDF2 + AES-GCM so Drive
  /// readers cannot decrypt it without the PIN. When disabled, the key is
  /// stored as a plain JSON envelope.
  ///
  /// Pass [drive] and [folderId] when already available to avoid a second
  /// round-trip; they are looked up automatically when omitted.
  Future<void> _uploadKeyFileToDrive({
    drive_api.DriveApi? drive,
    String? folderId,
  }) async {
    try {
      drive ??= await _getDriveService();
      if (drive == null) return;
      folderId ??= await _getFolderId(drive);
      if (folderId == null) return;

      // Building the json content.
      final Uint8List content;
      if (_isPinEnabled) {
        final key = await BackupService.getOrCreateKey(_secureStorage);
        final pin = await BackupService.readStoredPin(_secureStorage);
        if (pin == null) {
          // Keychain failure — skip upload, next sync will resolve.
          return;
        }
        final wrapped = await BackupService.wrapKeyWithPin(key, pin);
        content = Uint8List.fromList(
          utf8.encode(jsonEncode({'type': 'pin', ...wrapped})),
        );
      } else {
        final key = await BackupService.getOrCreateKey(_secureStorage);
        final keyBytes = await key.extractBytes();
        content = Uint8List.fromList(
          utf8.encode(
            jsonEncode({'type': 'plain', 'key': base64Encode(keyBytes)}),
          ),
        );
      }

      // Delete any existing key.key, then upload fresh.
      const keyFileName = 'key.key';
      final existing = await drive.files.list(
        q: "name = '$keyFileName' and '$folderId' in parents and trashed = false",
        $fields: 'files(id)',
      );
      for (final f in (existing.files ?? [])) {
        if (f.id != null) await drive.files.delete(f.id!);
      }

      final media = drive_api.Media(
        Stream.value(content.toList()),
        content.length,
      );
      final file =
          drive_api.File()
            ..name = keyFileName
            ..parents = [folderId];
      await drive.files.create(file, uploadMedia: media);
      debugPrint('key.key uploaded to Drive (PIN: $_isPinEnabled)');
    } catch (e) {
      debugPrint('_uploadKeyFileToDrive failed: $e');
    }
  }

  /// Called when the user enters their PIN to unlock a PIN-protected cloud backup.
  ///
  /// Decrypts the cached [_cloudPinWrapped] envelope, stores the key and PIN
  /// data locally, enables PIN state, then resumes sync.
  /// Returns false if the PIN is wrong.
  Future<bool> submitCloudPin(String pin) async {
    final envelope = _cloudPinWrapped;
    if (envelope == null) return false;

    final key = await _unwrapKeyFromEnvelope(envelope, pin);
    if (key == null) return false;

    final keyBytes = await key.extractBytes();
    await BackupService.storeKeyBytes(_secureStorage, keyBytes);
    await BackupService.storePinData(_secureStorage, {
      'salt': envelope['salt'] as String,
      'nonce': envelope['nonce'] as String,
      'ciphertext': envelope['ciphertext'] as String,
      'tag': envelope['tag'] as String,
    });
    await BackupService.storePin(_secureStorage, pin);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPinEnabledKey, true);
    _isPinEnabled = true;
    _cachedKey = key;
    _pendingCloudPinEntry = false;
    _cloudPinWrapped = null;
    notifyListeners();

    performSync(true);
    return true;
  }

  /// Convenience wrapper: syncs the key with Drive when possible.
  /// Must be called before [_getKey] on any path that decrypts Drive backups.
  Future<void> _ensureKeySync() async {
    try {
      final drive = await _getDriveService();
      if (drive == null) return;
      final folderId = await _getFolderId(drive, create: false);
      if (folderId == null) return;
      await _syncKeyWithDrive(drive, folderId);
    } catch (e) {
      debugPrint('_ensureKeySync error: $e');
    }
  }

  // --- Drive helpers -----------------------------------------------------

  Future<drive_api.DriveApi?> _getDriveService() async {
    final user = _currentUser;
    if (user == null) return null;
    final headers = await user.authHeaders;
    return drive_api.DriveApi(_GoogleAuthClient(headers));
  }

  Future<String?> _getFolderId(
    drive_api.DriveApi driveApi, {
    bool create = true,
  }) async {
    const mimeType = 'application/vnd.google-apps.folder';
    const folderName = 'habitt_backups';

    try {
      final found = await driveApi.files.list(
        q: "mimeType = '$mimeType' and name = '$folderName' and trashed = false and 'root' in parents",
        $fields: 'files(id,name)',
        spaces: 'drive',
      );

      final files = found.files;
      if (files == null) return null;
      if (files.isNotEmpty) return files.first.id;

      if (!create) return null;

      final folder =
          drive_api.File()
            ..name = folderName
            ..mimeType = mimeType
            ..parents = ['root'];
      final created = await driveApi.files.create(folder, $fields: 'id');
      return created.id;
    } catch (e) {
      debugPrint('Failed to get/create folder: $e');
      return null;
    }
  }

  Future<Uint8List?> _downloadFileBytes(
    drive_api.DriveApi drive,
    String folderId,
    String name,
  ) async {
    final found = await drive.files.list(
      q: "name = '$name' and '$folderId' in parents and trashed = false",
      $fields: 'files(id)',
    );
    if (found.files == null || found.files!.isEmpty) return null;
    final fileId = found.files!.first.id;
    if (fileId == null) return null;

    final response =
        await drive.files.get(
              fileId,
              downloadOptions: drive_api.DownloadOptions.fullMedia,
            )
            as drive_api.Media;

    final bytes = <int>[];
    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
    }
    return Uint8List.fromList(bytes);
  }

  Future<Uint8List?> _downloadLatestBackupBytes(
    drive_api.DriveApi drive,
    String folderId,
  ) async {
    final found = await drive.files.list(
      q: "name contains 'habitt-backup' and '$folderId' in parents and trashed = false",
      $fields: 'files(id)',
      orderBy: 'modifiedTime desc',
    );
    if (found.files == null || found.files!.isEmpty) return null;
    final fileId = found.files!.first.id;
    if (fileId == null) return null;

    final response =
        await drive.files.get(
              fileId,
              downloadOptions: drive_api.DownloadOptions.fullMedia,
            )
            as drive_api.Media;

    final bytes = <int>[];
    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
    }
    return Uint8List.fromList(bytes);
  }

  Future<bool> _checkDataExists() async {
    final drive = await _getDriveService();
    if (drive == null) return false;

    final folderId = await _getFolderId(drive, create: false);
    if (folderId == null) return false;

    final found = await drive.files.list(
      q: "'$folderId' in parents and trashed = false",
      $fields: 'files(id,name)',
    );

    if (found.files == null || found.files!.isEmpty) return false;

    for (final file in found.files!) {
      final name = file.name;
      if (name == null) continue;
      if (name == 'metadata.meta' || name.endsWith('.habitt')) return true;
    }
    return false;
  }

  Future<BackupMetadata?> _fetchCloudMetadata(SecretKey key) async {
    final drive = await _getDriveService();
    if (drive == null) throw Exception('Drive service unavailable.');

    final folderId = await _getFolderId(drive);
    if (folderId == null) throw Exception('Could not get backup folder.');

    final metadataBytes = await _downloadFileBytes(
      drive,
      folderId,
      'metadata.meta',
    );
    if (metadataBytes == null) return null;

    return BackupService.importMetadata(
      encryptedBytes: metadataBytes,
      secretKey: key,
    );
  }

  Future<BackupData?> _downloadBackupFromCloud(SecretKey key) async {
    final drive = await _getDriveService();
    if (drive == null) return null;

    final folderId = await _getFolderId(drive);
    if (folderId == null) return null;

    final backupBytes = await _downloadLatestBackupBytes(drive, folderId);
    if (backupBytes == null) return null;

    return BackupService.importDataFromGoogleDrive(
      encryptedBytes: backupBytes,
      secretKey: key,
    );
  }

  Future<void> _uploadBackupToCloud(SecretKey key) async {
    final encryptedDatabase = await BackupService.exportDataForGoogleDrive(
      secretKey: key,
      habitProvider: _habitProvider!,
    );
    if (encryptedDatabase == null) {
      _lastError = 'Failed to export database.';
      notifyListeners();
      return;
    }

    final metadata = await BackupService.buildMetadata();
    final encryptedMetadata = await BackupService.exportEncryptedMetadata(
      secretKey: key,
      metadata: metadata,
    );

    final drive = await _getDriveService();
    if (drive == null) return;

    final folderId = await _getFolderId(drive);
    if (folderId == null) return;

    // Upload new backup file first (versioned — keep up to 3 on Drive)
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString().substring(2);
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final backupFileName =
        '$day-$month-$year-$hour$minute-habitt-backup.habitt';

    final dbMedia = drive_api.Media(
      Stream.value(encryptedDatabase.toList()),
      encryptedDatabase.length,
    );
    final dbFile =
        drive_api.File()
          ..name = backupFileName
          ..parents = [folderId];
    final dbCreation = await drive.files.create(dbFile, uploadMedia: dbMedia);

    if (dbCreation.id == null) {
      _lastError = 'Failed to upload backup file.';
      notifyListeners();
      return;
    }
    debugPrint('Uploaded backup: ${dbCreation.id}');

    // Rotate old backups — keep only the 3 most recent .habitt files
    await _rotateOldBackups(drive, folderId);

    // Overwrite metadata file
    await _replaceMetadataFile(drive, folderId, encryptedMetadata);

    _localMetadata = metadata;
    notifyListeners();
  }

  Future<void> _rotateOldBackups(
    drive_api.DriveApi drive,
    String folderId,
  ) async {
    final found = await drive.files.list(
      q: "name contains 'habitt-backup' and '$folderId' in parents and trashed = false",
      $fields: 'files(id,createdTime)',
      orderBy: 'createdTime desc',
    );

    final files = found.files;
    if (files == null || files.length <= 3) return;

    for (final file in files.skip(3)) {
      if (file.id != null) {
        await drive.files.delete(file.id!);
        debugPrint('Deleted old backup: ${file.id}');
      }
    }
  }

  /// Download and apply every delta file on Drive that was not uploaded by
  /// this device and has not already been applied to local storage.
  ///
  /// Deltas are applied in chronological order (oldest first) so that
  /// later changes win in the per-field timestamp merge.
  Future<void> _downloadAndApplyPendingDeltas(
    drive_api.DriveApi drive,
    String folderId,
    SecretKey key,
  ) async {
    final res = await drive.files.list(
      q: "name contains 'habitt-delta' and '$folderId' in parents and trashed = false",
      $fields: 'files(id,name,createdTime)',
      orderBy: 'createdTime asc',
    );

    final allFiles = res.files ?? [];
    if (allFiles.isEmpty) return;

    // The short device ID embedded in the filename (first 8 chars of deviceId).
    final deviceId = _localMetadata?.deviceId ?? '';
    final shortMyId =
        deviceId.length >= 8 ? deviceId.substring(0, 8) : deviceId;

    // Load the set of delta file IDs already applied on this device.
    final prefs = await SharedPreferences.getInstance();
    final appliedRaw = prefs.getString(_kAppliedDeltaIdsKey);
    final applied =
        appliedRaw != null
            ? Set<String>.from(jsonDecode(appliedRaw) as List<dynamic>)
            : <String>{};

    // Filter: skip our own deltas and already-applied ones.
    final pending =
        allFiles.where((f) {
          if (f.id == null) return false;
          if (applied.contains(f.id!)) return false;
          if (shortMyId.isNotEmpty && (f.name ?? '').contains(shortMyId))
            return false;
          return true;
        }).toList();

    if (pending.isEmpty) return;

    debugPrint(
      'Applying ${pending.length} pending delta(s) from other devices.',
    );

    for (final f in pending) {
      try {
        final response =
            await drive.files.get(
                  f.id!,
                  downloadOptions: drive_api.DownloadOptions.fullMedia,
                )
                as drive_api.Media;

        final bytes = <int>[];
        await for (final chunk in response.stream) {
          bytes.addAll(chunk);
        }

        final backupData = await BackupService.importDataFromGoogleDrive(
          encryptedBytes: Uint8List.fromList(bytes),
          secretKey: key,
        );

        if (backupData != null) {
          await _mergeBackupData(backupData);
          applied.add(f.id!);
          debugPrint('Applied delta ${f.id} (${f.name})');
        }
      } catch (e) {
        // Skip unreadable/corrupt deltas — do not add to applied set so we
        // can retry on the next sync cycle.
        debugPrint('Skipped delta ${f.id}: $e');
      }
    }

    await prefs.setString(_kAppliedDeltaIdsKey, jsonEncode(applied.toList()));
  }

  /// Upload only the habits and days that changed since [_lastSyncTime].
  ///
  /// Does nothing if there are no changes (delta export returns null) or if
  /// [_lastSyncTime] is null (caller should fall back to a full sync instead).
  Future<void> _uploadDeltaToCloud(SecretKey key) async {
    if (_lastSyncTime == null || _habitProvider == null) return;

    final bytes = await BackupService.exportDeltaForGoogleDrive(
      secretKey: key,
      habitProvider: _habitProvider!,
      fromTime: _lastSyncTime!,
    );
    if (bytes == null) {
      debugPrint('Delta upload skipped — no changes since last sync.');
      return;
    }

    final drive = await _getDriveService();
    if (drive == null) return;
    final folderId = await _getFolderId(drive);
    if (folderId == null) return;

    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString().substring(2);
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final deviceId = _localMetadata?.deviceId ?? 'unknown';
    final shortId = deviceId.length >= 8 ? deviceId.substring(0, 8) : deviceId;
    final fileName =
        '$day-$month-$year-$hour$minute-$shortId-habitt-delta.habittd';

    final media = drive_api.Media(Stream.value(bytes.toList()), bytes.length);
    final file =
        drive_api.File()
          ..name = fileName
          ..parents = [folderId];
    final created = await drive.files.create(file, uploadMedia: media);
    debugPrint('Uploaded delta: ${created.id} ($fileName)');

    await _rotateDeltaFiles(drive, folderId);
  }

  /// Delete delta files older than 7 days. Called after each delta upload to
  /// prevent indefinite accumulation.
  Future<void> _rotateDeltaFiles(
    drive_api.DriveApi drive,
    String folderId,
  ) async {
    final res = await drive.files.list(
      q: "name contains 'habitt-delta' and '$folderId' in parents and trashed = false",
      $fields: 'files(id,createdTime)',
      orderBy: 'createdTime asc',
    );

    final cutoff = DateTime.now().toUtc().subtract(const Duration(days: 7));
    for (final f in (res.files ?? [])) {
      if (f.id != null &&
          f.createdTime != null &&
          f.createdTime!.isBefore(cutoff)) {
        await drive.files.delete(f.id!);
        debugPrint('Rotated old delta: ${f.id}');
      }
    }
  }

  /// Delete ALL delta files from Drive and clear the local applied-delta set.
  /// Called after a successful full sync — the full backup supersedes all deltas.
  Future<void> _clearAllDeltaFiles(
    drive_api.DriveApi drive,
    String folderId,
  ) async {
    final res = await drive.files.list(
      q: "name contains 'habitt-delta' and '$folderId' in parents and trashed = false",
      $fields: 'files(id)',
    );

    for (final f in (res.files ?? [])) {
      if (f.id != null) {
        await drive.files.delete(f.id!);
        debugPrint('Cleared delta after full sync: ${f.id}');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAppliedDeltaIdsKey);
    debugPrint('Applied-delta tracking cleared.');
  }

  Future<void> _replaceMetadataFile(
    drive_api.DriveApi drive,
    String folderId,
    Uint8List? encryptedMetadata,
  ) async {
    if (encryptedMetadata == null) return;

    // Delete existing metadata
    final existing = await drive.files.list(
      q: "name = 'metadata.meta' and '$folderId' in parents and trashed = false",
      $fields: 'files(id)',
    );
    if (existing.files != null) {
      for (final f in existing.files!) {
        if (f.id != null) await drive.files.delete(f.id!);
      }
    }

    final metadataMedia = drive_api.Media(
      Stream.value(encryptedMetadata.toList()),
      encryptedMetadata.length,
    );
    final metadataFile =
        drive_api.File()
          ..name = 'metadata.meta'
          ..parents = [folderId];
    await drive.files.create(metadataFile, uploadMedia: metadataMedia);
    debugPrint('Uploaded metadata.meta');
  }

  // --- Merge -------------------------------------------------------------

  Future<void> _mergeBackupData(BackupData backupData) async {
    final habitsBox = Hive.box<Habit>('habits');
    final daysBox = Hive.box<Day>('days');

    for (final incoming in backupData.habits) {
      Habit? existing;
      for (final h in habitsBox.values) {
        if (h.id == incoming.id) {
          existing = h;
          break;
        }
      }

      if (existing != null) {
        final merged = existing.merge(incoming);
        existing.updateHabit(merged);
        await existing.save();
      } else {
        if (incoming.isDeleted ?? false) continue;
        await habitsBox.add(incoming);
      }
    }

    for (final day in backupData.days) {
      final dayKey =
          DateTime(
            day.date.year,
            day.date.month,
            day.date.day,
          ).toIso8601String().split('T').first;

      final existingDay = daysBox.get(dayKey);
      if (existingDay != null) {
        final localTs = existingDay.timestamp;
        final incomingTs = day.timestamp;
        if ((localTs == incomingTs) ||
            (localTs == null && incomingTs == null)) {
          continue;
        }
      }

      final existingById = <int, Habit>{};
      if (existingDay != null) {
        for (final h in existingDay.habits) {
          if (h.isDeleted ?? false) continue;
          existingById[h.id] = h;
        }
      }

      final mergedDayHabits = <Habit>[];
      for (final incomingHabit in day.habits) {
        final local = existingById.remove(incomingHabit.id);
        if (local != null) {
          mergedDayHabits.add(local.merge(incomingHabit));
        } else {
          if (incomingHabit.isDeleted ?? false) continue;
          mergedDayHabits.add(incomingHabit);
        }
      }
      mergedDayHabits.addAll(existingById.values);

      await daysBox.put(
        dayKey,
        Day(date: day.date, habits: mergedDayHabits, timestamp: day.timestamp),
      );
    }

    _habitProvider?.importDateJoined(backupData.dateJoined);
    await _habitProvider?.init();
    await _habitProvider?.assignStreaks();
    await _habitProvider?.recalculateLongestStreaks();
    _habitProvider?.statsProvider?.refreshStats(force: true);
    notifyListeners();
  }

  // --- Version history ---------------------------------------------------

  /// Returns the list of versioned backups on Drive, newest first (max 3).
  Future<List<DriveBackupFile>> listCloudBackups() async {
    try {
      final drive = await _getDriveService();
      if (drive == null) return [];

      final folderId = await _getFolderId(drive, create: false);
      if (folderId == null) return [];

      final found = await drive.files.list(
        q: "name contains 'habitt-backup' and '$folderId' in parents and trashed = false",
        $fields: 'files(id,name,createdTime)',
        orderBy: 'createdTime desc',
      );

      return (found.files ?? [])
          .where((f) => f.id != null && f.createdTime != null)
          .map(
            (f) => DriveBackupFile(
              id: f.id!,
              name: f.name ?? '',
              createdAt: f.createdTime!,
            ),
          )
          .take(3)
          .toList();
    } catch (e) {
      debugPrint('Failed to list cloud backups: $e');
      return [];
    }
  }

  /// Restore from a specific Drive backup file by its file ID.
  Future<void> restoreFromBackupFile(String fileId) async {
    if (_syncState == SyncState.syncing) return;

    await _ensureKeySync();
    final key = await _getKey();
    if (key == null) return;

    progressMessage = 'Downloading backup...';
    syncState = SyncState.syncing;
    lastError = null;

    try {
      final backupData = await _downloadBackupById(fileId, key);
      if (backupData != null) {
        progressMessage = 'Merging...';
        await _mergeBackupData(backupData);
        await _onSyncSuccess();
      } else {
        lastError = 'Failed to decrypt backup.';
        syncState = SyncState.error;
      }
    } catch (e) {
      lastError = 'Restore failed: $e';
      syncState = SyncState.error;
      debugPrint(lastError);
    }
  }

  /// Wipes the local DB and restores entirely from a specific Drive backup
  /// file. No deltas are applied — this is a point-in-time hard restore.
  ///
  /// Decryption fallback order:
  ///   1. Current key (_getKey)
  ///   2. Plain device key (when PIN is enabled and might differ from Try 1)
  ///
  /// Local data is only cleared after successful decryption. If all keys fail,
  /// [hasPendingBackupPassphrase] is set to true and the UI should prompt for
  /// a passphrase via [retryRestoreWithPassphrase].
  Future<void> replaceFromBackupFile(String fileId) async {
    if (_syncState == SyncState.syncing) return;
    syncState = SyncState.syncing;
    lastError = null;

    await _ensureKeySync();
    final key = await _getKey(); // includes pin if exists
    if (key == null) return;

    progressMessage = 'Downloading backup...';

    try {
      // Download bytes once; cache for passphrase retry if needed.
      final rawBytes = await _fetchRawFileBytes(fileId);
      if (rawBytes == null) {
        lastError = 'Could not download backup.';
        syncState = SyncState.error;
        return;
      }

      // Try decryption with available keys before touching local data.
      final backupData = await _tryDecryptBackupFile(rawBytes, key);

      if (backupData == null) {
        // Only offer passphrase entry for v1 (passphrase-based) backups.
        // v2/v3 backups use a device key; a passphrase cannot decrypt them.
        if (_isLegacyV1(rawBytes)) {
          _failedBackupFileId = fileId;
          _failedBackupFileBytes = rawBytes;
        }
        lastError = 'Failed to decrypt backup.';
        syncState = SyncState.error;
        notifyListeners();
        return;
      }

      // Decryption succeeded — now safe to wipe and restore.
      progressMessage = 'Clearing local data...';
      await Hive.box<Habit>('habits').clear();
      await Hive.box<Day>('days').clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kAppliedDeltaIdsKey);
      await _habitProvider?.init();

      progressMessage = 'Restoring...';
      await _mergeBackupData(backupData);
      await _onSyncSuccess();
    } catch (e) {
      lastError = 'Restore failed: $e';
      syncState = SyncState.error;
      debugPrint(lastError);
    }
  }

  /// Retries the last failed backup restore using a user-supplied passphrase.
  /// Used when decryption failed with the device key and the backup might have
  /// been created with the old passphrase-based system.
  /// Returns true on success.
  Future<bool> retryRestoreWithPassphrase(String passphrase) async {
    final bytes = _failedBackupFileBytes;
    if (bytes == null) return false;

    syncState = SyncState.syncing;
    lastError = null;
    progressMessage = 'Decrypting with passphrase...';

    try {
      final backupData = await BackupService.importDataFromGoogleDriveLegacy(
        encryptedBytes: bytes,
        passphrase: passphrase,
      );

      if (backupData == null) {
        lastError = 'Failed to decrypt backup.';
        syncState = SyncState.error;
        progressMessage = null;
        notifyListeners();
        return false;
      }

      progressMessage = 'Clearing local data...';
      await Hive.box<Habit>('habits').clear();
      await Hive.box<Day>('days').clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kAppliedDeltaIdsKey);
      await _habitProvider?.init();

      progressMessage = 'Restoring...';
      await _mergeBackupData(backupData);
      _failedBackupFileId = null;
      _failedBackupFileBytes = null;
      await _onSyncSuccess();
      return true;
    } catch (e) {
      lastError = 'Restore failed: $e';
      syncState = SyncState.error;
      progressMessage = null;
      debugPrint(lastError);
      notifyListeners();
      return false;
    }
  }

  /// Downloads raw bytes for a Drive file by its ID.
  Future<Uint8List?> _fetchRawFileBytes(String fileId) async {
    final drive = await _getDriveService();
    if (drive == null) return null;

    final response =
        await drive.files.get(
              fileId,
              downloadOptions: drive_api.DownloadOptions.fullMedia,
            )
            as drive_api.Media;

    final bytes = <int>[];
    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
    }
    return Uint8List.fromList(bytes);
  }

  /// Tries to decrypt [bytes] with the current key, then (if PIN is enabled)
  /// with the raw plain device key as a fallback.
  /// Returns null if no key works, signalling that the UI should prompt for a passphrase.
  Future<BackupData?> _tryDecryptBackupFile(
    Uint8List bytes,
    SecretKey currentKey,
  ) async {
    debugPrint('Trying to decrypt backup...');
    // Try 1: current key (may be plain or PIN-derived).
    try {
      debugPrint('Importing data with current key (may include PIN)...');
      final data = await BackupService.importDataFromGoogleDrive(
        encryptedBytes: bytes,
        secretKey: currentKey,
      );
      if (data != null) return data;
      debugPrint('Decryption with current key failed.');
    } on FormatException {
      // Legacy v1 — passphrase needed, no point trying another device key.
      return null;
    }

    // Try 2: plain device key, in case the backup was made before PIN was set.

    if (_isPinEnabled) {
      debugPrint('PIN enabled');
      final plainKey = await BackupService.getOrCreateKey(_secureStorage);
      try {
        final data = await BackupService.importDataFromGoogleDrive(
          encryptedBytes: bytes,
          secretKey: plainKey,
        );
        debugPrint('Trying to decrypt with plain device key...');
        if (data != null) return data;
      } on FormatException {
        return null;
      }
    } else {
      debugPrint('PIN not enabled');
    }

    // Try 3: hardcoded PIN "1902" — diagnostic check before prompting user.
    debugPrint('Trying hardcoded PIN 1902...');
    const debugPin = '1902';
    final pinDerivedKey = await BackupService.unwrapKeyWithPin(
      _secureStorage,
      debugPin,
    );
    if (pinDerivedKey != null) {
      try {
        final data = await BackupService.importDataFromGoogleDrive(
          encryptedBytes: bytes,
          secretKey: pinDerivedKey,
        );
        if (data != null) {
          debugPrint('Decryption succeeded with hardcoded PIN 1902.');
          return data;
        }
        debugPrint('Hardcoded PIN 1902 unwrapped a key but decryption failed.');
      } on FormatException {
        debugPrint('Hardcoded PIN 1902 key hit legacy v1 format.');
        return null;
      }
    } else {
      debugPrint('Hardcoded PIN 1902 failed to unwrap key from keychain.');
    }

    // Fallback: prompt user to enter a pin to try unwrapping the key
    debugPrint('Prompting user to enter PIN and retry decryption...');

    notifyListeners();

    return null;
  }

  bool _isLegacyV1(Uint8List bytes) {
    try {
      final wrapper = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      return (wrapper['version'] as int? ?? 1) == 1;
    } catch (_) {
      return false;
    }
  }

  Future<BackupData?> _downloadBackupById(String fileId, SecretKey key) async {
    final bytes = await _fetchRawFileBytes(fileId);
    if (bytes == null) return null;
    return BackupService.importDataFromGoogleDrive(
      encryptedBytes: bytes,
      secretKey: key,
    );
  }

  // --- Delete ------------------------------------------------------------

  Future<void> deleteCloudBackup() async {
    if (!isLoggedIn) {
      _lastError = 'Not signed in.';
      notifyListeners();
      return;
    }

    try {
      final drive = await _getDriveService();
      if (drive == null) return;

      final folderId = await _getFolderId(drive);
      if (folderId == null) return;

      final found = await drive.files.list(
        q: "'$folderId' in parents and trashed = false",
        $fields: 'files(id)',
      );
      if (found.files != null) {
        for (final f in found.files!) {
          await drive.files.delete(f.id!);
        }
      }
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to delete backup: $e';
      debugPrint(_lastError);
      notifyListeners();
    }
  }
}

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

  bool _isPinEnabled = false;
  // Decrypted keychain key cached in memory after PIN entry. Cleared on restart.
  SecretKey? _cachedKey;

  String? _progressMessage;

  // Set when the user is silently signed out due to revoked Drive scope.
  // Consumed once by the UI to show a notification popup.
  String? _pendingNotification;

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
  String? get pendingNotification => _pendingNotification;

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
    _autoSyncTimer = Timer(const Duration(seconds: 15), () {
      // Upload-only: just push local changes as a delta — no remote check.
      // Remote checks happen on app launch and resume (SyncMode.full).
      performSync(false, SyncMode.uploadOnly).catchError((e) {
        debugPrint('Auto-sync failed: $e');
      });
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
    if (pin == null) return null;
    final key = await BackupService.unwrapKeyWithPin(_secureStorage, pin);
    if (key != null) _cachedKey = key;
    return key;
  }

  /// Wraps the keychain key with [pin], stores both the wrapped key and the
  /// raw PIN (so auto-sync works on future app launches without re-entry).
  Future<bool> enablePin(String pin) async {
    try {
      final key = await BackupService.getOrCreateKey(_secureStorage);
      final wrapped = await BackupService.wrapKeyWithPin(key, pin);
      await BackupService.storePinData(_secureStorage, wrapped);
      await BackupService.storePin(_secureStorage, pin);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPinEnabledKey, true);
      _isPinEnabled = true;
      _cachedKey = key;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Enable PIN failed: $e');
      return false;
    }
  }

  /// Verifies [pin] against the stored wrapped key, then clears all PIN data.
  /// Returns false if [pin] is wrong.
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
      notifyListeners();

      if (!_needsMigration) {
        await performSync();
      }
    } catch (e) {
      _lastError = 'Failed to sign in: $e';
      debugPrint(_lastError);
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
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

    final habitById = {for (final h in habitsBox.values) h.id: h};

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

      final normalizedHabits =
          mergedDayHabits.map((h) => habitById[h.id] ?? h).toList();
      await daysBox.put(
        dayKey,
        Day(date: day.date, habits: normalizedHabits, timestamp: day.timestamp),
      );
    }

    _habitProvider?.importDateJoined(backupData.dateJoined);
    await _habitProvider?.init();
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

  Future<BackupData?> _downloadBackupById(String fileId, SecretKey key) async {
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

    return BackupService.importDataFromGoogleDrive(
      encryptedBytes: Uint8List.fromList(bytes),
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

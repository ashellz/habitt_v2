import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

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
import 'package:habitt/services/cloud_storage_adapter.dart';
import 'package:habitt/services/drive_storage_adapter.dart';
import 'package:habitt/services/icloud_storage_adapter.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SyncState { idle, syncing, success, error }

enum BackupBackend { googleDrive, iCloud }

/// How aggressively the app syncs in the background.
enum SyncSpeed {
  /// Upload delta immediately after a change; poll for remote changes every 5 min.
  fast,

  /// Upload delta 15 s after the last change; poll for remote changes every 20 min.
  optimized,
}

/// Controls which parts of the sync cycle run
enum SyncMode {
  /// full cycle: checks for remote changes from other devices (checks deltas), then uploads own
  /// delta (or full backup on first sync if forced)
  /// Used on app launch and app resume from background
  full,

  /// upload only: skips checking for remote changes, just uploads own delta
  /// used by the 15 second timer after changes - auto sync
  uploadOnly,

  /// delta cycle without compaction: downloads remote deltas + uploads own delta,
  /// but never creates a full backup. Used by the manual "Sync now" button.
  syncOnly,
}

class BackupProvider extends ChangeNotifier {
  BackupProvider();

  static const String _kBackupUserEmailKey = 'backup_user_email';
  static const String _kBackupUserIdKey = 'backup_user_id';
  static const String _kAutoSyncEnabledKey = 'backup_auto_sync_enabled';
  static const String _kSyncSpeedKey = 'backup_sync_speed';
  static const String _kLastSyncTimeKey = 'backup_last_sync_time';
  static const String _kLegacyPassphraseKey = 'habitt_backup_passphrase';
  static const String _kPinEnabledKey = 'backup_pin_enabled';

  /// id of JSON-encoded List<String> of Drive file IDs for deltas already applied to
  /// this device. Cleared when a full sync runs.
  static const String _kAppliedDeltaIdsKey = 'backup_applied_delta_ids';

  /// Cache of Drive delta file IDs seen on the last download pass. Used to
  /// skip re-processing when the file list hasn't changed.
  static const String _kLastKnownDeltaIdsKey = 'backup_known_delta_ids';

  /// SharedPrefs key storing the last time _rotateDeltaFiles ran (ms since epoch).
  static const String _kLastRotationTimeKey = 'backup_last_rotation_time';

  /// Maximum backoff interval when consecutive sync failures occur.
  static const Duration _kMaxBackoffDuration = Duration(minutes: 30);

  /// start a full compaction sync when this many delta files accumulate:
  static const int _kDeltaCompactionThreshold = 20;

  static const String _kActiveBackendKey = 'backup_active_backend';

  GoogleSignInAccount? _currentUser;
  User? _firebaseUser;
  late final GoogleSignIn _googleSignIn;
  late final FlutterSecureStorage _secureStorage;
  HabitProvider? _habitProvider;

  BackupBackend _activeBackend = BackupBackend.googleDrive;
  CloudStorageAdapter? _adapter;

  SyncState _syncState = SyncState.idle;
  bool _isBackingUp = false;
  String? _lastError;
  BackupMetadata? _localMetadata;
  Timer? _autoSyncTimer;
  Timer? _periodicSyncTimer;

  bool _isAutoSyncEnabled = true;
  SyncSpeed _syncSpeed = SyncSpeed.optimized;
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

  // Set to true inside _mergeBackupData; consumed once by _onSyncSuccess to
  // trigger streak/stats recalculation only after the full sync completes.
  bool _pendingStreakRecalc = false;

  // Counts consecutive performSync failures; resets on success. Used to
  // compute exponential backoff for the periodic sync timer.
  int _consecutiveSyncFailures = 0;

  String? _progressMessage;

  // --- Sync progress tracking ---
  int _syncTotalDeltas = 0;
  int _syncCurrentDelta = 0;
  bool _syncHasBackup = false;
  bool _syncIsUploading = false;
  bool _syncIsOptimizing = false;
  int _syncOptimizingTotal = 0;
  int _syncOptimizingRemaining = 0;
  double _syncProgress = 0.0;
  double _syncTotalWeight = 0.0;
  double _syncCompletedWeight = 0.0;

  // Used when sync pill is dismissed
  bool _syncPillDismissed = false;

  // Set when the user is silently signed out due to revoked Drive scope.
  // Consumed once by the UI to show a notification popup.
  String? _pendingNotification;
  String? _syncWarning;

  // Set when Drive has a PIN-wrapped key.key and no stored PIN is available
  // locally. UI shows a PIN entry dialog; submitCloudPin() clears this.
  bool _pendingCloudPinEntry = false;
  Map<String, dynamic>? _cloudPinWrapped;

  // Set when a specific backup file could not be decrypted with any known key.
  // UI shows a passphrase prompt; retryRestoreWithPassphrase() clears this.
  String? _failedBackupFileId;
  Uint8List? _failedBackupFileBytes;

  final Completer<void> _initCompleter = Completer<void>();

  /// Completes when [initialize] finishes (successfully or not).
  Future<void> get initializationDone => _initCompleter.future;

  bool get isInitialized => _initCompleter.isCompleted;

  // --- Getters -----------------------------------------------------------

  GoogleSignInAccount? get currentUser => _currentUser;
  User? get firebaseUser => _firebaseUser;
  bool get isLoggedIn => _currentUser != null && _firebaseUser != null;
  BackupMetadata? get localMetadata => _localMetadata;
  SyncState get syncState => _syncState;
  bool get isBackingUp => _isBackingUp;
  String? get lastError => _lastError;
  String? get syncWarning => _syncWarning;
  bool get dataExists => _dataExists;
  String? get progressMessage => _progressMessage;
  bool get isAutoSyncEnabled => _isAutoSyncEnabled;
  SyncSpeed get syncSpeed => _syncSpeed;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get needsMigration => _needsMigration;
  bool get isPinEnabled => _isPinEnabled;
  bool get pendingCloudPinEntry => _pendingCloudPinEntry;
  bool get hasPendingBackupPassphrase => _failedBackupFileId != null;
  String? get pendingNotification => _pendingNotification;
  bool get pendingRestoreDecision => _pendingRestoreDecision;
  bool get hasPendingSync => _hasPendingSync;
  int get syncTotalDeltas => _syncTotalDeltas;
  int get syncCurrentDelta => _syncCurrentDelta;
  bool get syncHasBackup => _syncHasBackup;
  bool get syncIsUploading => _syncIsUploading;
  bool get syncIsOptimizing => _syncIsOptimizing;
  int get syncOptimizingTotal => _syncOptimizingTotal;
  int get syncOptimizingRemaining => _syncOptimizingRemaining;
  double get syncProgress => _syncProgress;
  bool get isICloudConnected =>
      _activeBackend == BackupBackend.iCloud && _adapter != null;

  bool get syncPillDismissed => _syncPillDismissed;

  /// True when the last successful sync was more than 5 minutes ago (or never).
  /// Used by the resume lifecycle handler to decide whether a full sync cycle
  /// is warranted or just an upload flush.
  bool get isSyncStale =>
      _lastSyncTime == null ||
      DateTime.now().difference(_lastSyncTime!) > const Duration(minutes: 5);

  /// Backoff interval for the periodic sync timer. Doubles on each consecutive
  /// failure, capped at [_kMaxBackoffDuration]. Resets to the base interval on
  /// any successful sync.
  Duration get _currentBackoffInterval {
    final base =
        _syncSpeed == SyncSpeed.fast
            ? const Duration(seconds: 30)
            : const Duration(minutes: 2);
    if (_consecutiveSyncFailures == 0) return base;
    final factor = 1 << _consecutiveSyncFailures.clamp(0, 10);
    final backed = base * factor;
    return backed > _kMaxBackoffDuration ? _kMaxBackoffDuration : backed;
  }

  void dismissSyncPill() {
    _syncPillDismissed = true;
    notifyListeners();
  }

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

  // --- Progress helpers --------------------------------------------------

  /// Determines what incoming work this sync cycle will do and sets the
  /// total weight for the progress bar. For upload-only and full-backup paths
  /// no network calls are needed; for the delta path we preflight-list files
  /// (same calls done later in the actual sync methods).
  Future<void> _computeSyncComposition(bool force, SyncMode mode) async {
    _syncTotalDeltas = 0;
    _syncCurrentDelta = 0;
    _syncHasBackup = false;
    _syncIsUploading = false;
    _syncCompletedWeight = 0.0;
    _syncProgress = 0.0;

    if (mode == SyncMode.uploadOnly) {
      _syncTotalWeight = 3.0; // 1 overhead + 2 upload
      notifyListeners();
      return;
    }

    final useDelta = !force && _lastSyncTime != null;

    if (!useDelta) {
      // Full-backup path — always heavy.
      _syncHasBackup = true;
      _syncTotalWeight = 13.0; // 1 overhead + 10 backup + 2 upload
      notifyListeners();
      return;
    }

    // Delta path: preflight to count pending deltas and check for a newer backup.
    double weight = 3.0; // 1 overhead + 2 upload

    if (_adapter == null) {
      _syncTotalWeight = weight;
      notifyListeners();
      return;
    }

    try {
      final files = await _adapter!.listFiles(nameContains: 'habitt-backup');
      if (files.isNotEmpty) {
        files.sort((a, b) {
          final ta = b.modifiedTime ?? b.createdTime ?? DateTime(0);
          final tb = a.modifiedTime ?? a.createdTime ?? DateTime(0);
          return ta.compareTo(tb);
        });
        final latest = files.first;
        final modifiedTime = latest.modifiedTime ?? latest.createdTime;
        final prefs = await SharedPreferences.getInstance();
        final lastAppliedId = prefs.getString(_kLastAppliedBackupIdKey);
        if (lastAppliedId != latest.id &&
            modifiedTime != null &&
            (_lastSyncTime == null || modifiedTime.isAfter(_lastSyncTime!))) {
          _syncHasBackup = true;
          weight += 10;
        }
      }
    } catch (_) {}

    try {
      final allFiles = await _adapter!.listFiles(
        nameContains: 'habitt-delta',
        modifiedAfter: _lastSyncTime,
      );
      final prefs = await SharedPreferences.getInstance();
      final appliedRaw = prefs.getString(_kAppliedDeltaIdsKey);
      final applied =
          appliedRaw != null
              ? Set<String>.from(jsonDecode(appliedRaw) as List<dynamic>)
              : <String>{};
      final deviceId = _localMetadata?.deviceId ?? '';
      final shortMyId =
          deviceId.length >= 8 ? deviceId.substring(0, 8) : deviceId;

      _syncTotalDeltas =
          allFiles
              .where(
                (f) =>
                    !applied.contains(f.id) &&
                    !(shortMyId.isNotEmpty && f.name.contains(shortMyId)),
              )
              .length;
      _syncCurrentDelta = _syncTotalDeltas;
      weight += _syncTotalDeltas.toDouble();
    } catch (_) {}

    _syncTotalWeight = weight;
    notifyListeners();
  }

  void _advanceProgress(double phaseWeight) {
    if (_syncTotalWeight <= 0) return;
    _syncCompletedWeight = (_syncCompletedWeight + phaseWeight).clamp(
      0.0,
      _syncTotalWeight,
    );
    _syncProgress = (_syncCompletedWeight / _syncTotalWeight).clamp(0.0, 1.0);
    notifyListeners();
  }

  // --- Auto-sync ---------------------------------------------------------

  void scheduleAutoSync() {
    if (_adapter == null || !_isAutoSyncEnabled) return;

    _autoSyncTimer?.cancel();

    if (_syncSpeed == SyncSpeed.fast) {
      // Fast mode: debounce for 5 s to batch rapid changes.
      _hasPendingSync = true;
      _autoSyncTimer = Timer(const Duration(seconds: 5), () {
        _hasPendingSync = false;
        performSync(false, SyncMode.uploadOnly).catchError((e) {
          debugPrint('Auto-sync (fast) failed: $e');
        });
      });
    } else {
      // Optimized mode: debounce for 15 s to batch rapid changes.
      _hasPendingSync = true;
      _autoSyncTimer = Timer(const Duration(seconds: 15), () {
        _hasPendingSync = false;
        performSync(false, SyncMode.uploadOnly).catchError((e) {
          debugPrint('Auto-sync failed: $e');
        });
      });
    }
  }

  /// Flush any pending debounce-timer sync immediately. Called when the app is
  /// about to be suspended (AppLifecycleState.paused) so optimized-mode changes
  /// aren't lost if the user leaves before the 15-second timer fires.
  void flushPendingSyncIfNeeded() {
    if (!_hasPendingSync) return;
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    _hasPendingSync = false;
    performSync(false, SyncMode.uploadOnly).catchError((e) {
      debugPrint('Auto-sync (app pause) failed: $e');
    });
  }

  /// Starts a recurring timer that pulls remote changes from other devices
  /// while the app is in the foreground.
  ///
  /// Interval: 30 s for [SyncSpeed.fast], 2 min for [SyncSpeed.optimized],
  /// doubled on each consecutive failure up to [_kMaxBackoffDuration].
  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    if (_adapter == null || !_isAutoSyncEnabled) return;

    _periodicSyncTimer = Timer.periodic(_currentBackoffInterval, (_) {
      // Only run when not already syncing and no upload is pending.
      if (_syncState == SyncState.syncing || _hasPendingSync) return;
      performSync(false, SyncMode.full).catchError((e) {
        debugPrint('Periodic sync failed: $e');
      });
    });
  }

  Future<void> setSyncSpeed(SyncSpeed speed) async {
    if (_syncSpeed == speed) return;
    _syncSpeed = speed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSyncSpeedKey, speed.name);
    // Restart the periodic timer with the new interval.
    _startPeriodicSync();
    notifyListeners();
    // Switching to fast: cancel any pending debounce timer and sync immediately
    // so changes aren't held back by the optimized-mode 15-second delay.
    if (speed == SyncSpeed.fast && _adapter != null && _isAutoSyncEnabled) {
      _autoSyncTimer?.cancel();
      _autoSyncTimer = null;
      _hasPendingSync = false;
      performSync(false, SyncMode.syncOnly).catchError((e) {
        debugPrint('Post-speed-switch sync failed: $e');
      });
    }
  }

  Future<void> setAutoSyncEnabled(bool value) async {
    _isAutoSyncEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoSyncEnabledKey, value);
    if (!value) {
      _autoSyncTimer?.cancel();
      _autoSyncTimer = null;
      _periodicSyncTimer?.cancel();
      _periodicSyncTimer = null;
      _hasPendingSync = false;
    } else {
      _startPeriodicSync();
    }
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
      await _uploadKeyFile();
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
    await _uploadKeyFile();
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
      final speedName = prefs.getString(_kSyncSpeedKey);
      _syncSpeed =
          speedName == SyncSpeed.fast.name
              ? SyncSpeed.fast
              : SyncSpeed.optimized;

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

      // ── Restore iCloud backend if it was the active backend ───────────────
      final savedBackend = prefs.getString(_kActiveBackendKey);
      if (savedBackend == BackupBackend.iCloud.name &&
          !kIsWeb &&
          (Platform.isIOS || Platform.isMacOS)) {
        final candidate = ICloudStorageAdapter();
        if (await candidate.isAvailable) {
          _activeBackend = BackupBackend.iCloud;
          _adapter = candidate;
          _dataExists = await _checkDataExists();
          notifyListeners();
          if (_dataExists && _lastSyncTime == null) {
            await performSync(true);
          }
          _startPeriodicSync();
          return;
        } else {
          // iCloud unavailable (not signed in / disabled) — forget the saved
          // backend silently so the user isn't prompted about Apple accounts.
          await candidate.dispose();
          await prefs.remove(_kActiveBackendKey);
        }
      }

      // ── Restore Google Drive sign-in ───────────────────────────────────────
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

          _adapter = DriveStorageAdapter(account: user);

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

          _startPeriodicSync();
        }
      }
    } catch (e) {
      debugPrint('Failed to restore sign-in state: $e');
    } finally {
      if (!_initCompleter.isCompleted) _initCompleter.complete();
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
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    _hasPendingSync = false;
    await _adapter?.dispose();
    _adapter = null;
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
          _pendingNotification = 'Google Drive sync failed';
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
      _adapter = DriveStorageAdapter(account: user);

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
          _startPeriodicSync();
        }
      } else {
        notifyListeners();
      }
    } catch (e) {
      _lastError = 'Failed to sign in: $e';
      _pendingNotification = 'Google Drive sync failed';
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

      await _adapter?.dispose();
      _adapter = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kBackupUserEmailKey);
      await prefs.remove(_kBackupUserIdKey);
      await prefs.remove(_kLastSyncTimeKey);
      await prefs.remove(_kAppliedDeltaIdsKey);
      _lastSyncTime = null;

      _autoSyncTimer?.cancel();
      _autoSyncTimer = null;
      _periodicSyncTimer?.cancel();
      _periodicSyncTimer = null;
      _hasPendingSync = false;

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
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;

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
    if (_adapter == null) return false;
    syncState = SyncState.syncing;

    try {
      // Verify passphrase by trying to decrypt metadata
      final metadataBytes = await _adapter!.download('metadata.meta');
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
      final backupBytes = await _downloadLatestBackupBytes();
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

      if (_pendingStreakRecalc) {
        _pendingStreakRecalc = false;
        await _habitProvider?.assignStreaks();
        await _habitProvider?.recalculateLongestStreaks();
        _habitProvider?.statsProvider?.refreshStats(force: true);
      }

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
    if (_adapter == null) return;

    syncState = SyncState.syncing;
    lastError = null;

    try {
      // Clear local legacy passphrase so _needsMigration won't re-trigger
      await _secureStorage.delete(key: _kLegacyPassphraseKey);
      _legacyPassphrase = null;
      _needsMigration = false;

      // Delete all existing cloud files (old encrypted backups + metadata)
      await _adapter!.deleteAll();

      // Upload fresh backup with the new keychain key
      final key = await BackupService.getOrCreateKey(_secureStorage);
      await _uploadBackupToCloud(key);
      await _onSyncSuccess();
    } catch (e) {
      debugPrint('Discard legacy backup failed: $e');
      // Clear migration state even if cloud cleanup partially failed
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
    _startPeriodicSync();
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
      _startPeriodicSync();
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
    if (_adapter != null) {
      progressMessage = 'Applying updates...';
      await _downloadAndApplyAllDeltas(key);
    }
  }

  /// Downloads and applies every delta file without skipping by device ID or
  /// already-applied set. Used after a full local wipe to reconstruct cloud state.
  Future<void> _downloadAndApplyAllDeltas(SecretKey key) async {
    if (_adapter == null) return;
    final allFiles = await _adapter!.listFiles(nameContains: 'habitt-delta');
    if (allFiles.isEmpty) return;

    // Apply oldest-first so later changes win in the timestamp merge.
    allFiles.sort((a, b) {
      final ta = a.createdTime ?? a.modifiedTime ?? DateTime(0);
      final tb = b.createdTime ?? b.modifiedTime ?? DateTime(0);
      return ta.compareTo(tb);
    });

    final applied = <String>{};
    for (final f in allFiles) {
      try {
        final bytes = await _adapter!.downloadById(f.id);
        if (bytes == null) continue;

        final backupData = await _tryDecryptWithFallback(bytes, key);
        if (backupData != null) {
          await _mergeBackupData(backupData);
          applied.add(f.id);
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

  /// User-triggered backup entry point ("Back Up Now").
  /// Sets [isBackingUp] so the UI can show a spinner only on the backup button.
  Future<void> backupNow() async {
    _isBackingUp = true;
    notifyListeners();
    try {
      await performSync(true);
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

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

    if (_adapter == null) {
      debugPrint("Adapter is null");
      return; // No backup backend active.
    }

    if (_needsMigration) {
      lastError = 'Migration required before syncing.';
      syncState = SyncState.error;
      return;
    }

    // Always sync the Drive key first — Drive is authoritative.
    // This ensures every upload (delta or full backup) uses the same key as
    // every other device, regardless of which device created the backup.
    // Must happen before _getKey() so the cached key is the Drive key.
    try {
      await _ensureKeySync();
    } catch (e) {
      lastError = 'Failed to sync encryption key: $e';
      syncState = SyncState.error;
      debugPrint(lastError);
      return;
    }

    // Key is PIN-protected and user hasn't entered PIN yet — pause sync.
    if (_pendingCloudPinEntry) {
      debugPrint('Sync paused: pending cloud PIN entry');
      syncState = SyncState.idle;
      progressMessage = null;
      return;
    }

    final key = await _getKey();
    if (key == null) {
      debugPrint('Sync paused: encryption key is null');
      syncState = SyncState.idle;
      progressMessage = null;
      return; // PIN locked
    }

    progressMessage = 'Starting sync...';
    _syncPillDismissed = false;
    syncState = SyncState.syncing;
    lastError = null;

    await _computeSyncComposition(force, mode);

    debugPrint("Starting sync with mode $mode (force: $force)");

    try {
      // ── Upload-only path (post-write auto-sync) ──────────────────────────
      if (mode == SyncMode.uploadOnly) {
        _advanceProgress(1); // overhead
        await _uploadDeltaToCloud(key);
        await _onSyncSuccess();
        return;
      }

      // ── Sync-only path (manual "Sync now" — delta cycle, no backup) ─────
      if (mode == SyncMode.syncOnly) {
        _advanceProgress(1); // overhead
        if (_lastSyncTime != null) {
          progressMessage = 'Checking for updates...';
          await _downloadAndApplyPendingDeltas(key);
        }
        progressMessage = 'Uploading changes...';
        await _uploadDeltaToCloud(key);
        await _onSyncSuccess();
        return;
      }

      // ── Full cycle: delta path or full-backup path ───────────────────────
      // Use delta when: not forced AND we have a sync cursor (_lastSyncTime).
      // First sync or forced always goes to the full backup path.
      final bool useDelta = !force && _lastSyncTime != null;

      if (useDelta) {
        _advanceProgress(1); // overhead
        progressMessage = 'Checking for updates...';
        await _checkAndApplyNewerBackup(key);
        await _downloadAndApplyPendingDeltas(key);

        progressMessage = 'Uploading changes...';
        await _uploadDeltaToCloud(key);

        // Compaction: too many delta files → collapse to a full backup.
        final deltaCount = await _countDeltaFiles();
        if (deltaCount >= _kDeltaCompactionThreshold) {
          progressMessage = 'Compacting backups...';
          await _fullSyncPath(key, force: true);
          await _clearAllDeltaFiles();
        }
      } else {
        // Full-backup path: download latest, merge, re-upload entire DB.
        await _fullSyncPath(key, force: force);

        // Wipe all delta files — the new full backup supersedes them.
        await _clearAllDeltaFiles();
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
      if (_activeBackend == BackupBackend.iCloud &&
          ICloudStorageAdapter.isQuotaExceededError(e)) {
        // The file was written to the local ubiquity container successfully —
        // the quota error comes from the background daemon failing to push to
        // Apple's servers. Data is safe locally; warn without setting error state.
        _syncWarning = 'icloud_quota_warning';
        await _onSyncSuccess(clearWarning: false);
        return;
      }
      if (_activeBackend == BackupBackend.iCloud &&
          ICloudStorageAdapter.isUnavailableError(e)) {
        // iCloud not available (not signed in, disabled, or container invalid).
        // Drop back silently — show a one-off toast but don't set error state
        // or prompt about Apple accounts.
        _pendingNotification = 'iCloud unavailable — check Settings';
        await _silentlyDeactivateICloud(); // calls notifyListeners()
        return;
      }
      if (DriveStorageAdapter.isQuotaExceededError(e)) {
        // Drive storage full — upload failed completely (no local fallback).
        _consecutiveSyncFailures++;
        _startPeriodicSync();
        syncState = SyncState.error;
        lastError = 'drive_quota_exceeded';
        _pendingNotification = 'Google Drive storage full';
        debugPrint('[SYNC] Drive quota exceeded: $e');
        notifyListeners();
        return;
      }
      _consecutiveSyncFailures++;
      _startPeriodicSync(); // restart with backed-off interval
      syncState = SyncState.error;
      lastError = 'Sync failed: $e';
      _pendingNotification =
          _activeBackend == BackupBackend.iCloud
              ? 'iCloud unavailable — check Settings'
              : 'Google Drive sync failed';
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
    _advanceProgress(1); // overhead done

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
      _advanceProgress(10); // backup done
      progressMessage = 'Uploading merged backup...';
      _syncIsUploading = true;
      notifyListeners();
      await _uploadBackupToCloud(key);
      _syncIsUploading = false;
      _advanceProgress(2); // upload done
    } else {
      _advanceProgress(10); // no backup to download — advance past backup slot
      progressMessage = 'No cloud data. Uploading local backup...';
      _syncIsUploading = true;
      notifyListeners();
      await _uploadBackupToCloud(key);
      _syncIsUploading = false;
      _advanceProgress(2); // upload done
    }
  }

  Future<int> _countDeltaFiles() async {
    if (_adapter == null) return 0;
    return (await _adapter!.listFiles(nameContains: 'habitt-delta')).length;
  }

  /// Download the latest Drive backup and merge it into local data.
  Future<void> restoreFromCloud() async {
    if (_syncState == SyncState.syncing) return;
    if (_adapter == null) {
      lastError = 'No backup backend active.';
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

  Future<void> _onSyncSuccess({bool clearWarning = true}) async {
    // Guard: adapter was cleared mid-sync (user signed out or disconnected).
    // Do not persist the sync cursor or set success state for an aborted sync.
    if (_adapter == null) {
      _syncState = SyncState.idle;
      _progressMessage = null;
      _syncProgress = 0.0;
      _syncTotalDeltas = 0;
      _syncCurrentDelta = 0;
      _syncHasBackup = false;
      _syncIsUploading = false;
      _syncIsOptimizing = false;
      _syncOptimizingTotal = 0;
      _syncOptimizingRemaining = 0;
      _syncCompletedWeight = 0.0;
      _syncTotalWeight = 0.0;
      notifyListeners();
      return;
    }
    _lastSyncTime = DateTime.now();
    if (clearWarning) _syncWarning = null;
    await _persistLastSyncTime();
    if (_consecutiveSyncFailures > 0) {
      // Came back from backoff — reset counter and restart timer at normal rate.
      _consecutiveSyncFailures = 0;
      _startPeriodicSync();
    }
    if (_pendingStreakRecalc) {
      _pendingStreakRecalc = false;
      await _habitProvider?.assignStreaks();
      await _habitProvider?.recalculateLongestStreaks();
      _habitProvider?.statsProvider?.refreshStats(force: true);
    }
    syncState = SyncState.success;
    progressMessage = null;
    _syncProgress = 0.0;
    _syncTotalDeltas = 0;
    _syncCurrentDelta = 0;
    _syncHasBackup = false;
    _syncIsUploading = false;
    _syncIsOptimizing = false;
    _syncOptimizingTotal = 0;
    _syncOptimizingRemaining = 0;
    _syncCompletedWeight = 0.0;
    _syncTotalWeight = 0.0;
    notifyListeners();
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

  /// Syncs the backup encryption key with the active cloud backend.
  ///
  /// For iCloud: `downloadKeyFile()` returns null — iCloud Keychain already
  /// syncs all key slots automatically; no reconciliation is needed.
  ///
  /// For Drive: always reads `key.key` and reconciles with local state.
  /// Six cases are handled:
  ///
  ///   • Drive missing  → upload local key
  ///   • Drive plain  + no local key   → install key locally
  ///   • Drive pin    + no local key   → [_handlePinWrappedDriveKey]
  ///   • Drive plain  + local + PIN off → no-op (consistent)
  ///   • Drive plain  + local + PIN on  → [_applyDriveDisabledPin]
  ///   • Drive pin    + local + PIN off → [_handlePinWrappedDriveKey]
  ///   • Drive pin    + local + PIN on + stored PIN works → no-op
  ///   • Drive pin    + local + PIN on + stored PIN fails → [_handlePinWrappedDriveKey]
  Future<void> _syncKey() async {
    if (_adapter == null) return;
    try {
      debugPrint('[SYNC] _syncKey: starting key sync...');
      final driveKeyRaw = await _adapter!.downloadKeyFile();

      if (driveKeyRaw == null) {
        // iCloud: null means keychain already synced — done.
        // Drive: no key.key exists yet — upload our local key.
        if (_activeBackend == BackupBackend.googleDrive) {
          debugPrint(
            '[SYNC] _syncKey: no key.key on Drive — uploading local key.',
          );
          await _uploadKeyFile();
        }
        return;
      }

      final content = utf8.decode(driveKeyRaw);
      final hasLocal = await BackupService.hasStoredKey(_secureStorage);
      debugPrint(
        '[SYNC] _syncKey: Drive key.key found (${driveKeyRaw.length} bytes), hasLocal=$hasLocal',
      );

      // Parse JSON envelope; fall back to old plain-base64 for backward compat.
      Map<String, dynamic> envelope;
      try {
        envelope = jsonDecode(content) as Map<String, dynamic>;
      } catch (_) {
        debugPrint('[SYNC] _syncKey: legacy plain-b64 format detected.');
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
      debugPrint(
        '[SYNC] _syncKey: envelope parsed — type="$type", isPinEnabled=$_isPinEnabled, hasLocal=$hasLocal',
      );

      if (!hasLocal) {
        debugPrint('[SYNC] _syncKey: new device path.');
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

      debugPrint('[SYNC] _syncKey: existing device path.');
      if (type == 'plain') {
        if (_isPinEnabled) {
          // Another device disabled PIN — sync state locally.
          await _applyDriveDisabledPin(envelope);
        } else {
          // Drive is authoritative — always install its plain key locally.
          final driveKeyBytes = base64Decode(envelope['key'] as String);
          final df =
              driveKeyBytes
                  .take(4)
                  .map((b) => b.toRadixString(16).padLeft(2, '0'))
                  .join();
          debugPrint(
            '[SYNC] _syncKey: plain — installing Drive key ($df) into local storage.',
          );
          await BackupService.storeKeyBytes(_secureStorage, driveKeyBytes);
          _cachedKey =
              null; // force _getKey() to re-derive from updated storage
        }
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
              // PIN valid. Drive key is authoritative — install it into both
              // storage slots and cache it so _getKey() returns the right key
              // for the rest of this sync cycle and all future launches.
              //
              // Slot B (raw bytes via storeKeyBytes) — used by getOrCreateKey.
              // Slot C (PIN-wrapped blob via storePinData) — used by unwrapKeyWithPin,
              //   which is what _getKey() actually reads in PIN mode.
              // Both must be updated; comparing only slot B was the old bug.
              final driveKeyBytes = await key.extractBytes();
              final df =
                  driveKeyBytes
                      .take(4)
                      .map((b) => b.toRadixString(16).padLeft(2, '0'))
                      .join();
              debugPrint(
                '[SYNC] _syncKey: PIN valid — installing Drive key ($df) into local storage.',
              );
              await BackupService.storeKeyBytes(_secureStorage, driveKeyBytes);
              final wrapped = await BackupService.wrapKeyWithPin(
                SecretKey(driveKeyBytes),
                storedPin,
              );
              await BackupService.storePinData(_secureStorage, wrapped);
              _cachedKey = SecretKey(driveKeyBytes);
              debugPrint(
                '[SYNC] _syncKey: Drive key installed (both slots updated, cache set).',
              );
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

  /// Builds the `key.key` file content and uploads it via the active adapter.
  /// iCloud adapters are a no-op — keychain sync handles key distribution.
  Future<void> _uploadKeyFile() async {
    if (_adapter == null) return;
    try {
      final Uint8List content;
      if (_isPinEnabled) {
        final key = await BackupService.getOrCreateKey(_secureStorage);
        final pin = await BackupService.readStoredPin(_secureStorage);
        if (pin == null) return; // Keychain failure — skip, next sync resolves.
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
      await _adapter!.uploadKeyFile(content);
      debugPrint('key.key uploaded (PIN: $_isPinEnabled)');
    } catch (e) {
      debugPrint('_uploadKeyFile failed: $e');
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

  /// Syncs the key with the active cloud backend before any decrypt operation.
  Future<void> _ensureKeySync() async {
    try {
      await _syncKey();
    } catch (e) {
      debugPrint('_ensureKeySync error: $e');
    }
  }

  // --- Cloud helpers -------------------------------------------------------

  /// Returns bytes of the most recently modified full backup, or null.
  Future<Uint8List?> _downloadLatestBackupBytes() async {
    if (_adapter == null) return null;
    final files = await _adapter!.listFiles(nameContains: 'habitt-backup');
    if (files.isEmpty) return null;
    files.sort((a, b) {
      final ta = b.modifiedTime ?? b.createdTime ?? DateTime(0);
      final tb = a.modifiedTime ?? a.createdTime ?? DateTime(0);
      return ta.compareTo(tb);
    });
    return _adapter!.downloadById(files.first.id);
  }

  Future<bool> _checkDataExists() async {
    if (_adapter == null) return false;
    final backups = await _adapter!.listFiles(nameContains: 'habitt-backup');
    return backups.isNotEmpty;
  }

  Future<BackupMetadata?> _fetchCloudMetadata(SecretKey key) async {
    if (_adapter == null) return null;
    final metadataBytes = await _adapter!.download('metadata.meta');
    if (metadataBytes == null) return null;
    return BackupService.importMetadata(
      encryptedBytes: metadataBytes,
      secretKey: key,
    );
  }

  Future<BackupData?> _downloadBackupFromCloud(SecretKey key) async {
    final backupBytes = await _downloadLatestBackupBytes();
    if (backupBytes == null) return null;
    return BackupService.importDataFromGoogleDrive(
      encryptedBytes: backupBytes,
      secretKey: key,
    );
  }

  Future<void> _uploadBackupToCloud(SecretKey key) async {
    if (_adapter == null) return;

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

    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString().substring(2);
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final backupFileName =
        '$day-$month-$year-$hour$minute-habitt-backup.habitt';

    await _adapter!.upload(backupFileName, encryptedDatabase);
    debugPrint('Uploaded backup: $backupFileName');

    await _rotateOldBackups();
    await _replaceMetadataFile(encryptedMetadata);

    _localMetadata = metadata;
    notifyListeners();
  }

  Future<void> _rotateOldBackups() async {
    if (_adapter == null) return;
    final files = await _adapter!.listFiles(nameContains: 'habitt-backup');
    if (files.length <= 3) return;
    // Keep newest 3 — sort descending by createdTime/modifiedTime.
    files.sort((a, b) {
      final ta = b.createdTime ?? b.modifiedTime ?? DateTime(0);
      final tb = a.createdTime ?? a.modifiedTime ?? DateTime(0);
      return ta.compareTo(tb);
    });
    for (final f in files.skip(3)) {
      await _adapter!.delete(f.id);
      debugPrint('Deleted old backup: ${f.id}');
    }
  }

  /// Checks whether the latest full backup on Drive is newer than last sync on device
  /// if so download and merge it.
  ///
  /// This handles the compaction case: when another device accumulates
  /// [_kDeltaCompactionThreshold] deltas it creates a new full backup and
  /// wipes all delta files.  A device in delta mode would otherwise find no
  /// deltas to apply and silently miss every change captured in that backup.
  static const String _kLastAppliedBackupIdKey =
      'backup_last_applied_backup_id';

  Future<void> _checkAndApplyNewerBackup(SecretKey key) async {
    if (_adapter == null) return;
    debugPrint(
      '[SYNC] _checkAndApplyNewerBackup: checking for newer full backup...',
    );

    final files = await _adapter!.listFiles(nameContains: 'habitt-backup');
    if (files.isEmpty) {
      debugPrint('[SYNC] _checkAndApplyNewerBackup: no backup files found.');
      return;
    }

    // Find the most recently modified backup.
    files.sort((a, b) {
      final ta = b.modifiedTime ?? b.createdTime ?? DateTime(0);
      final tb = a.modifiedTime ?? a.createdTime ?? DateTime(0);
      return ta.compareTo(tb);
    });
    final latest = files.first;
    final fileId = latest.id;
    final modifiedTime = latest.modifiedTime ?? latest.createdTime;
    if (modifiedTime == null) {
      debugPrint(
        '[SYNC] _checkAndApplyNewerBackup: backup file missing modifiedTime.',
      );
      return;
    }

    debugPrint(
      '[SYNC] _checkAndApplyNewerBackup: found backup $fileId modified=$modifiedTime lastSyncTime=$_lastSyncTime',
    );

    // Skip if we already applied this exact backup file.
    final prefs = await SharedPreferences.getInstance();
    final lastAppliedId = prefs.getString(_kLastAppliedBackupIdKey);
    if (lastAppliedId == fileId) {
      debugPrint(
        '[SYNC] _checkAndApplyNewerBackup: SKIP — already applied this backup (id=$fileId).',
      );
      return;
    }

    // Skip if the backup predates our last successful sync (nothing new).
    if (_lastSyncTime != null && !modifiedTime.isAfter(_lastSyncTime!)) {
      debugPrint(
        '[SYNC] _checkAndApplyNewerBackup: SKIP — backup ($modifiedTime) is not newer than lastSyncTime ($_lastSyncTime).',
      );
      return;
    }

    debugPrint(
      '[SYNC] _checkAndApplyNewerBackup: backup is newer than last sync — downloading and merging.',
    );

    final backupData = await _downloadBackupFromCloud(key);
    if (backupData != null) {
      await _mergeBackupData(backupData);
      await prefs.setString(_kLastAppliedBackupIdKey, fileId);
      debugPrint(
        '[SYNC] _checkAndApplyNewerBackup: applied newer full backup $fileId',
      );
    } else {
      debugPrint(
        '[SYNC] _checkAndApplyNewerBackup: failed to download/decrypt backup.',
      );
    }
    _advanceProgress(10); // backup phase done (downloaded or not)
  }

  /// Download and apply every delta that was not uploaded by this device and
  /// has not already been applied to local storage.
  ///
  /// Deltas are applied oldest-first so later changes win the timestamp merge.
  Future<void> _downloadAndApplyPendingDeltas(SecretKey key) async {
    if (_adapter == null) {
      debugPrint("Adapter is null");
      return;
    }

    debugPrint("Adapter isnt null");

    // Pass modifiedTime hint so Drive can filter server-side; iCloud filters client-side.
    final allFiles = await _adapter!.listFiles(
      nameContains: 'habitt-delta',
      modifiedAfter: _lastSyncTime,
    );
    debugPrint(
      '[SYNC] _downloadAndApplyPendingDeltas: ${allFiles.length} delta file(s) found.',
    );
    if (allFiles.isEmpty) return;

    // Load SharedPrefs once for cache comparison and applied-ID tracking.
    final prefs = await SharedPreferences.getInstance();

    // Early-return if the file ID set hasn't changed since last pass.
    final currentIds = allFiles.map((f) => f.id).toSet();
    final cachedIdsRaw = prefs.getString(_kLastKnownDeltaIdsKey);
    if (cachedIdsRaw != null) {
      final cachedIds = Set<String>.from(
        jsonDecode(cachedIdsRaw) as List<dynamic>,
      );
      if (cachedIds.length == currentIds.length &&
          cachedIds.containsAll(currentIds)) {
        debugPrint(
          '[SYNC] _downloadAndApplyPendingDeltas: delta file list unchanged — skipping.',
        );
        return;
      }
    }

    // Apply oldest-first.
    allFiles.sort((a, b) {
      final ta = a.createdTime ?? a.modifiedTime ?? DateTime(0);
      final tb = b.createdTime ?? b.modifiedTime ?? DateTime(0);
      return ta.compareTo(tb);
    });

    final deviceId = _localMetadata?.deviceId ?? '';
    final shortMyId =
        deviceId.length >= 8 ? deviceId.substring(0, 8) : deviceId;
    debugPrint(
      '[SYNC] _downloadAndApplyPendingDeltas: this device shortId="$shortMyId"',
    );

    final appliedRaw = prefs.getString(_kAppliedDeltaIdsKey);
    final applied =
        appliedRaw != null
            ? Set<String>.from(jsonDecode(appliedRaw) as List<dynamic>)
            : <String>{};

    final pending =
        allFiles.where((f) {
          if (applied.contains(f.id)) {
            debugPrint(
              '[SYNC]   skip delta (already applied): ${f.name} id=${f.id}',
            );
            return false;
          }
          if (shortMyId.isNotEmpty && f.name.contains(shortMyId)) {
            debugPrint('[SYNC]   skip delta (own device): ${f.name}');
            return false;
          }
          debugPrint('[SYNC]   pending delta: ${f.name} id=${f.id}');
          return true;
        }).toList();

    if (pending.isEmpty) {
      debugPrint(
        '[SYNC] _downloadAndApplyPendingDeltas: no pending deltas to apply.',
      );
      return;
    }
    debugPrint(
      '[SYNC] _downloadAndApplyPendingDeltas: applying ${pending.length} delta(s).',
    );

    for (final f in pending) {
      try {
        debugPrint('[SYNC] Downloading delta: ${f.name} (${f.id})');
        final bytes = await _adapter!.downloadById(f.id);
        if (bytes == null) {
          debugPrint('[SYNC] ERROR: could not download delta ${f.id}');
          if (_syncCurrentDelta > 0) _syncCurrentDelta--;
          _advanceProgress(1);
          continue;
        }
        debugPrint(
          '[SYNC] Downloaded ${bytes.length} bytes for delta ${f.name}',
        );

        final backupData = await _tryDecryptWithFallback(bytes, key);
        if (backupData != null) {
          debugPrint(
            '[SYNC] Decrypted delta ${f.name}: ${backupData.habits.length} habit(s), ${backupData.days.length} day(s)',
          );
          await _mergeBackupData(backupData);
          applied.add(f.id);
          debugPrint('[SYNC] Applied delta ${f.id} (${f.name})');
        } else {
          // Permanently corrupt / wrong key — mark applied so we never retry.
          applied.add(f.id);
          debugPrint(
            '[SYNC] WARN: delta ${f.name} could not be decrypted — permanently skipping.',
          );
        }
        if (_syncCurrentDelta > 0) _syncCurrentDelta--;
        _advanceProgress(1);
      } catch (e) {
        // Network/IO error — do NOT mark applied so we retry next cycle.
        debugPrint('[SYNC] ERROR applying delta ${f.id} (${f.name}): $e');
      }
    }

    await prefs.setString(_kAppliedDeltaIdsKey, jsonEncode(applied.toList()));
    await prefs.setString(
      _kLastKnownDeltaIdsKey,
      jsonEncode(currentIds.toList()),
    );
  }

  /// Upload only the habits and days that changed since [_lastSyncTime].
  ///
  /// Does nothing if there are no changes (delta export returns null) or if
  /// [_lastSyncTime] is null (caller should fall back to a full sync instead).
  Future<void> _uploadDeltaToCloud(SecretKey key) async {
    if (_lastSyncTime == null || _habitProvider == null || _adapter == null) {
      _advanceProgress(2);
      return;
    }

    final bytes = await BackupService.exportDeltaForGoogleDrive(
      secretKey: key,
      habitProvider: _habitProvider!,
      fromTime: _lastSyncTime!,
    );
    if (bytes == null) {
      debugPrint(
        '[SYNC] _uploadDeltaToCloud: no changes since $_lastSyncTime — skipping.',
      );
      _advanceProgress(2);
      return;
    }

    _syncIsUploading = true;
    notifyListeners();
    debugPrint(
      '[SYNC] _uploadDeltaToCloud: exporting delta with fromTime=$_lastSyncTime',
    );

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

    await _adapter!.upload(fileName, bytes);
    debugPrint('Uploaded delta: $fileName');

    _syncIsUploading = false;
    _advanceProgress(2); // upload done

    await _rotateDeltaFiles();
  }

  /// Delete delta files older than 7 days. Throttled to once per 24 h.
  Future<void> _rotateDeltaFiles() async {
    if (_adapter == null) return;

    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_kLastRotationTimeKey);
    if (lastMs != null) {
      final lastRotation = DateTime.fromMillisecondsSinceEpoch(
        lastMs,
        isUtc: true,
      );
      if (DateTime.now().toUtc().difference(lastRotation) <
          const Duration(hours: 24)) {
        debugPrint('[SYNC] _rotateDeltaFiles: throttled — ran within 24 h.');
        return;
      }
    }

    final cutoff = DateTime.now().toUtc().subtract(const Duration(days: 7));
    final old = await _adapter!.listFiles(
      nameContains: 'habitt-delta',
      createdBefore: cutoff,
    );
    for (final f in old) {
      await _adapter!.delete(f.id);
      debugPrint('Rotated old delta: ${f.id}');
    }

    await prefs.setInt(
      _kLastRotationTimeKey,
      DateTime.now().toUtc().millisecondsSinceEpoch,
    );
  }

  /// Delete ALL delta files and clear local applied-delta tracking.
  Future<void> _clearAllDeltaFiles() async {
    if (_adapter == null) return;
    final files = await _adapter!.listFiles(nameContains: 'habitt-delta');
    if (files.isNotEmpty) {
      _syncIsOptimizing = true;
      _syncOptimizingTotal = files.length;
      _syncOptimizingRemaining = files.length;
      _syncTotalWeight = files.length.toDouble();
      _syncCompletedWeight = 0.0;
      _syncProgress = 0.0;
      notifyListeners();
    }
    for (final f in files) {
      await _adapter!.delete(f.id);
      debugPrint('Cleared delta after full sync: ${f.id}');
      _syncOptimizingRemaining--;
      _advanceProgress(1);
    }
    if (files.isNotEmpty) {
      _syncIsOptimizing = false;
      notifyListeners();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAppliedDeltaIdsKey);
    await prefs.remove(_kLastKnownDeltaIdsKey);
    debugPrint('Applied-delta tracking cleared.');
  }

  Future<void> _replaceMetadataFile(Uint8List? encryptedMetadata) async {
    if (encryptedMetadata == null || _adapter == null) return;
    // Remove stale copies before uploading (Drive allows multiple same-name files).
    final existing = await _adapter!.listFiles(nameContains: 'metadata.meta');
    for (final f in existing) {
      await _adapter!.delete(f.id);
    }
    await _adapter!.upload('metadata.meta', encryptedMetadata);
    debugPrint('Uploaded metadata.meta');
  }

  // --- Merge -------------------------------------------------------------

  Future<void> _mergeBackupData(BackupData backupData) async {
    final habitsBox = Hive.box<Habit>('habits');
    final daysBox = Hive.box<Day>('days');

    debugPrint(
      '[SYNC] _mergeBackupData: merging ${backupData.habits.length} habit(s), ${backupData.days.length} day(s)',
    );

    // if duration is in minutes (old version), convert to seconds
    if (backupData.isLegacyDurationMinutes) {
      void toSeconds(Habit h) {
        h.duration *= 60;
        h.durationCompleted *= 60;
      }

      for (final h in backupData.habits) {
        toSeconds(h);
      }
      for (final day in backupData.days) {
        for (final h in day.habits) {
          toSeconds(h);
        }
      }
      debugPrint(
        '[SYNC] _mergeBackupData: upconverted legacy minutes payload to seconds',
      );
    }

    // ── Habits (master records) ──────────────────────────────────────────────
    for (final incoming in backupData.habits) {
      Habit? existing;
      for (final h in habitsBox.values) {
        if (h.id == incoming.id) {
          existing = h;
          break;
        }
      }

      if (existing != null) {
        final beforeCompleted = existing.completed;
        final beforeAmountC = existing.amountCompleted;
        final beforeDurationC = existing.durationCompleted;
        // Definition-only merge: day-state (completed/skipped/amountCompleted/
        // durationCompleted) belongs to a calendar day and flows ONLY through
        // the dated Day snapshots below. Never let an incoming dateless
        // completion leak onto the live habit (it would land on the receiver's
        // "today"). The live habit's today state is rebuilt from today's
        // snapshot by _rehydrateTodayFromSnapshot after the day loop.
        final merged = existing.merge(incoming, preserveLocalDayState: true);
        existing.applyMerge(merged);
        await existing.save();
        // Log only when completion-related fields changed.
        if (existing.completed != beforeCompleted ||
            existing.amountCompleted != beforeAmountC ||
            existing.durationCompleted != beforeDurationC) {
          debugPrint(
            '[SYNC]   habit id=${incoming.id} "${incoming.name}": '
            'completed $beforeCompleted→${existing.completed} '
            'amountC $beforeAmountC→${existing.amountCompleted} '
            'durationC $beforeDurationC→${existing.durationCompleted} '
            '(local completedTs=${existing.timestamps["completed"]}, incoming completedTs=${incoming.timestamps["completed"]})',
          );
        }
      } else {
        if (incoming.isDeleted ?? false) {
          debugPrint(
            '[SYNC]   habit id=${incoming.id} "${incoming.name}": new but deleted — skip.',
          );
          continue;
        }
        debugPrint(
          '[SYNC]   habit id=${incoming.id} "${incoming.name}": new habit added.',
        );
        await habitsBox.add(incoming);
      }
    }

    // ── Days (snapshots) ─────────────────────────────────────────────────────
    for (final day in backupData.days) {
      final dayKey =
          DateTime(
            day.date.year,
            day.date.month,
            day.date.day,
          ).toIso8601String().split('T').first;

      final existingDay = daysBox.get(dayKey);
      final localTs = existingDay?.timestamp;
      final incomingTs = day.timestamp;

      // Only apply directional skip when the existing day has real habit data
      // AND was not auto-created by the day-rollover/backfill logic.
      // Auto-created days (isAutoCreated=true) are blank reset snapshots with
      // a current wall-clock timestamp — they must always lose to incoming
      // backup data which may carry actual completions from a prior session or
      // another device, even if that data is timestamped earlier.
      // Placeholder days created after a wipe (habits.isEmpty) also never
      // block incoming data.
      if (existingDay != null &&
          existingDay.habits.isNotEmpty &&
          !existingDay.isAutoCreated) {
        // Skip if incoming has no timestamp (can't be newer).
        if (incomingTs == null) {
          debugPrint(
            '[SYNC]   day $dayKey: SKIP — incoming has no timestamp (local=$localTs).',
          );
          continue;
        }
        // Skip if local is the same moment or more recent than incoming.
        if (localTs != null && !incomingTs.isAfter(localTs)) {
          debugPrint(
            '[SYNC]   day $dayKey: SKIP — local ($localTs) >= incoming ($incomingTs).',
          );
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
          final beforeCompleted = local.completed;
          final merged = local.merge(incomingHabit);
          if (merged.completed != beforeCompleted) {
            debugPrint(
              '[SYNC]   day $dayKey habit id=${incomingHabit.id} "${incomingHabit.name}": '
              'completed $beforeCompleted→${merged.completed} '
              '(local completedTs=${local.timestamps["completed"]}, incoming completedTs=${incomingHabit.timestamps["completed"]})',
            );
          }
          mergedDayHabits.add(merged);
        } else {
          if (incomingHabit.isDeleted ?? false) continue;
          mergedDayHabits.add(incomingHabit);
        }
      }
      mergedDayHabits.addAll(existingById.values);

      // The steps above union the habit lists from both devices. A union can
      // pull in habits that are not scheduled on this day (and are left
      // incomplete) — e.g. a habit the other device materialised into its
      // snapshot at a different time. The home "last week" view filters those
      // out by schedule, but the raw streak/consistency stats would miscount
      // them as unmet requirements, breaking streaks. Collapse the snapshot
      // back to the same schedule-filtered set the app writes natively (see
      // saveHabitDay) so all read paths agree. Completed habits always survive
      // the filter, so no real completion is ever dropped.
      final filteredDayHabits =
          _habitProvider?.habitsCountingForDay(day.date, mergedDayHabits) ??
          mergedDayHabits;

      // Preserve the most recent modification timestamp from either device.
      final mergedTs =
          (localTs != null && incomingTs != null)
              ? (incomingTs.isAfter(localTs) ? incomingTs : localTs)
              : (localTs ?? incomingTs);

      debugPrint(
        '[SYNC]   day $dayKey: MERGE — local=${existingDay != null ? "${existingDay.habits.length} habits, ts=$localTs, autoCreated=${existingDay.isAutoCreated}" : "none"} '
        '| incoming=${day.habits.length} habits, ts=$incomingTs '
        '| union=${mergedDayHabits.length} → filtered=${filteredDayHabits.length} habits, ts=$mergedTs',
      );

      await daysBox.put(
        dayKey,
        Day(date: day.date, habits: filteredDayHabits, timestamp: mergedTs),
      );
    }

    // Day-state is authoritative in the dated snapshots above; rebuild the live
    // habits' TODAY state from today's snapshot before init()/refreshTodaysHabits
    // reads the live records, so the home screen reflects the date-correct merge
    // rather than the stale dateless master-record flag.
    await _rehydrateTodayFromSnapshot();

    _habitProvider?.importDateJoined(backupData.dateJoined);
    await _habitProvider?.init();
    _pendingStreakRecalc = true;
    notifyListeners();
  }

  // Sends habits from daysBox of today to todaysHabits after merge
  Future<void> _rehydrateTodayFromSnapshot() async {
    final habitsBox = Hive.box<Habit>('habits');
    final daysBox = Hive.box<Day>('days');

    final now = DateTime.now();
    final todayKey =
        DateTime(
          now.year,
          now.month,
          now.day,
        ).toIso8601String().split('T').first;

    final today = daysBox.get(todayKey);
    if (today == null) return;

    final snapshotById = {for (final h in today.habits) h.id: h};
    for (final habit in habitsBox.values) {
      final snapshot = snapshotById[habit.id];
      if (snapshot == null) continue;
      habit.adoptDayState(snapshot);
      if (habit.isInBox) {
        await habit.save();
      }
    }
  }

  // --- Version history ---------------------------------------------------

  /// Returns the list of versioned backups, newest first (max 3).
  Future<List<DriveBackupFile>> listCloudBackups() async {
    if (_adapter == null) return [];
    try {
      final files = await _adapter!.listFiles(nameContains: 'habitt-backup');
      files.sort((a, b) {
        final ta = b.createdTime ?? b.modifiedTime ?? DateTime(0);
        final tb = a.createdTime ?? a.modifiedTime ?? DateTime(0);
        return ta.compareTo(tb);
      });
      return files
          .take(3)
          .where((f) => f.createdTime != null || f.modifiedTime != null)
          .map(
            (f) => DriveBackupFile(
              id: f.id,
              name: f.name,
              createdAt: f.createdTime ?? f.modifiedTime!,
            ),
          )
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
  /// file. When [includeDeltasSince] is true, all Drive delta files are applied
  /// on top of the restored backup before completing.
  ///
  /// Decryption fallback order:
  ///   1. Current key (_getKey)
  ///   2. Plain device key (when PIN is enabled and might differ from Try 1)
  ///
  /// Local data is only cleared after successful decryption. If all keys fail,
  /// [hasPendingBackupPassphrase] is set to true and the UI should prompt for
  /// a passphrase via [retryRestoreWithPassphrase].
  Future<void> replaceFromBackupFile(
    String fileId, {
    bool includeDeltasSince = false,
  }) async {
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

      if (includeDeltasSince) {
        progressMessage = 'Applying updates...';
        await _downloadAndApplyAllDeltas(key);
      }

      await _onSyncSuccess();
    } catch (e) {
      lastError = 'Restore failed: $e';
      syncState = SyncState.error;
      debugPrint(lastError);
    }
  }

  Future<bool> hasDeltaFiles() async {
    try {
      return await _countDeltaFiles() > 0;
    } catch (_) {
      return false;
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

  Future<Uint8List?> _fetchRawFileBytes(String fileId) =>
      _adapter?.downloadById(fileId) ?? Future.value(null);

  /// Tries to decrypt [bytes] with the current key, then (if PIN is enabled)
  /// with the raw plain device key as a fallback.
  /// Returns null if no key works, signalling that the UI should prompt for a passphrase.
  /// Tries [currentKey] first, then falls back to the plain device key when
  /// PIN is enabled — covers files encrypted before PIN was set or by a device
  /// without PIN. A [FormatException] from either attempt means the file is
  /// legacy v1 or corrupt; returns null immediately in that case.
  Future<BackupData?> _tryDecryptWithFallback(
    Uint8List bytes,
    SecretKey currentKey,
  ) async {
    // Try 1: current key (plain or PIN-derived).
    try {
      final data = await BackupService.importDataFromGoogleDrive(
        encryptedBytes: bytes,
        secretKey: currentKey,
      );
      if (data != null) return data;
    } on FormatException {
      return null;
    }

    // Try 2: plain device key — for files created before PIN was set.
    if (_isPinEnabled) {
      final plainKey = await BackupService.getOrCreateKey(_secureStorage);
      try {
        final data = await BackupService.importDataFromGoogleDrive(
          encryptedBytes: bytes,
          secretKey: plainKey,
        );
        if (data != null) return data;
      } on FormatException {
        return null;
      }
    }

    return null;
  }

  Future<BackupData?> _tryDecryptBackupFile(
    Uint8List bytes,
    SecretKey currentKey,
  ) async {
    debugPrint('Trying to decrypt backup...');
    final data = await _tryDecryptWithFallback(bytes, currentKey);
    if (data != null) return data;
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
    if (_adapter == null) {
      _lastError = 'No backup backend active.';
      notifyListeners();
      return;
    }
    try {
      await _adapter!.deleteAll();
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to delete backup: $e';
      debugPrint(_lastError);
      notifyListeners();
    }
  }

  // --- iCloud activation -------------------------------------------------

  /// Switch the active backend to iCloud. Signs out of Drive if needed.
  /// Only available on iOS and macOS.
  Future<void> activateICloud() async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isMacOS)) return;

    final candidate = ICloudStorageAdapter();
    if (!await candidate.isAvailable) {
      await candidate.dispose();
      _pendingNotification = 'iCloud unavailable — check Settings';
      notifyListeners();
      return;
    }

    await _adapter?.dispose();
    _adapter = candidate;
    _activeBackend = BackupBackend.iCloud;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveBackendKey, BackupBackend.iCloud.name);

    _dataExists = await _checkDataExists();
    notifyListeners();

    await performSync(true);
    _startPeriodicSync();
  }

  /// Called when iCloud becomes unavailable mid-session (E_CTR).
  /// Drops the adapter silently with no error state shown to the user.
  Future<void> _silentlyDeactivateICloud() async {
    await _adapter?.dispose();
    _adapter =
        _currentUser != null
            ? DriveStorageAdapter(account: _currentUser!)
            : null;
    _activeBackend = BackupBackend.googleDrive;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kActiveBackendKey);
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    lastError = 'icloud_unavailable';
    syncState = SyncState.error;
    if (_adapter != null) _startPeriodicSync();
    notifyListeners();
  }

  /// Switch back to Google Drive (or no backend if not signed in).
  Future<void> deactivateICloud() async {
    await _adapter?.dispose();
    _adapter =
        _currentUser != null
            ? DriveStorageAdapter(account: _currentUser!)
            : null;
    _activeBackend = BackupBackend.googleDrive;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kActiveBackendKey);

    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;

    if (_adapter != null) _startPeriodicSync();
    notifyListeners();
  }
}

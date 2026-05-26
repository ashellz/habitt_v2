import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive_api;
import 'package:habitt/firebase_options.dart';
import 'package:habitt/models/backup_data.dart';
import 'package:habitt/models/backup_metadata.dart';
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

class BackupProvider extends ChangeNotifier {
  BackupProvider();

  static const String _kBackupUserEmailKey = 'backup_user_email';
  static const String _kBackupUserIdKey = 'backup_user_id';
  static const String _kAutoSyncEnabledKey = 'backup_auto_sync_enabled';
  static const String _kLastSyncTimeKey = 'backup_last_sync_time';
  static const String _kLegacyPassphraseKey = 'habitt_backup_passphrase';

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

  String? _progressMessage;

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
      performSync(true).catchError((e) {
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

      final lastSyncMs = prefs.getInt(_kLastSyncTimeKey);
      if (lastSyncMs != null) {
        _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
      }

      final savedEmail = prefs.getString(_kBackupUserEmailKey);
      _localMetadata = await BackupService.buildMetadata();

      if (savedEmail != null) {
        final user = await _googleSignIn.signInSilently();
        if (user != null) {
          _currentUser = user;
          _firebaseUser = FirebaseAuth.instance.currentUser;

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

  Future<void> signIn(BuildContext context) async {
    try {
      final user = await _googleSignIn.signIn();
      if (user == null) return;

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
      await _uploadBackupToCloud();

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

  // --- Sync --------------------------------------------------------------

  Future<void> performSync([bool force = false]) async {
    if (_syncState == SyncState.syncing) return;

    progressMessage = 'Starting sync...';
    syncState = SyncState.syncing;

    if (!isLoggedIn) {
      lastError = 'Not signed in.';
      progressMessage = null;
      syncState = SyncState.error;
      return;
    }

    if (_needsMigration) {
      lastError = 'Migration required before syncing.';
      syncState = SyncState.error;
      return;
    }

    lastError = null;

    try {
      progressMessage = 'Fetching cloud metadata...';
      final metadata = await _fetchCloudMetadata();

      if (_localMetadata?.deviceId == metadata?.deviceId &&
          metadata != null &&
          _localMetadata != null) {
        if (force) {
          progressMessage = 'Uploading local backup...';
          await _uploadBackupToCloud();
        }
        // else: same device, nothing new to pull
        await _onSyncSuccess();
        return;
      }

      if (metadata != null) {
        progressMessage = 'New data detected. Downloading...';
        final backupData = await _downloadBackupFromCloud();
        if (backupData != null) {
          progressMessage = 'Merging...';
          await _mergeBackupData(backupData);
        }
        progressMessage = 'Uploading merged backup...';
        await _uploadBackupToCloud();
      } else {
        progressMessage = 'No cloud data. Uploading local backup...';
        await _uploadBackupToCloud();
      }

      await _onSyncSuccess();
    } catch (e) {
      syncState = SyncState.error;
      lastError = 'Sync failed: $e';
      debugPrint(lastError);
      notifyListeners();
    }
  }

  /// Download the latest Drive backup and merge it into local data.
  Future<void> restoreFromCloud() async {
    if (_syncState == SyncState.syncing) return;
    if (!isLoggedIn) {
      lastError = 'Not signed in.';
      return;
    }

    progressMessage = 'Downloading backup...';
    syncState = SyncState.syncing;
    lastError = null;

    try {
      final backupData = await _downloadBackupFromCloud();
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

  Future<BackupMetadata?> _fetchCloudMetadata() async {
    final drive = await _getDriveService();
    if (drive == null) throw Exception('Drive service unavailable.');

    final folderId = await _getFolderId(drive);
    if (folderId == null) throw Exception('Could not get backup folder.');

    final metadataBytes = await _downloadFileBytes(drive, folderId, 'metadata.meta');
    if (metadataBytes == null) return null;

    final key = await BackupService.getOrCreateKey(_secureStorage);
    return BackupService.importMetadata(
      encryptedBytes: metadataBytes,
      secretKey: key,
    );
  }

  Future<BackupData?> _downloadBackupFromCloud() async {
    final drive = await _getDriveService();
    if (drive == null) return null;

    final folderId = await _getFolderId(drive);
    if (folderId == null) return null;

    final backupBytes = await _downloadLatestBackupBytes(drive, folderId);
    if (backupBytes == null) return null;

    final key = await BackupService.getOrCreateKey(_secureStorage);
    return BackupService.importDataFromGoogleDrive(
      encryptedBytes: backupBytes,
      secretKey: key,
    );
  }

  Future<void> _uploadBackupToCloud() async {
    final key = await BackupService.getOrCreateKey(_secureStorage);

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
    final backupFileName = '$day-$month-$year-$hour$minute-habitt-backup.habitt';

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
          DateTime(day.date.year, day.date.month, day.date.day)
              .toIso8601String()
              .split('T')
              .first;

      final existingDay = daysBox.get(dayKey);
      if (existingDay != null) {
        final localTs = existingDay.timestamp;
        final incomingTs = day.timestamp;
        if ((localTs == incomingTs) || (localTs == null && incomingTs == null)) {
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

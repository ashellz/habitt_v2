import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive_api;
import 'package:habitt/firebase_options.dart';
import 'package:habitt/models/backup_data.dart';
import 'package:habitt/models/backup_metadata.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/services/backup_service.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/widgets/dialogs/passphrase_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:hive_ce/hive.dart';

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

/// Enum to track sync state.
enum SyncState { idle, syncing, success, conflict, error }

/// Provider managing backup/sync operations with Google Drive.
///
/// Responsibilities:
/// - Track Google Sign-In authentication state (persists across sessions)
/// - Manage backup metadata (device ID, last sync info)
/// - Coordinate sync operations (upload/download)
/// - Detect device conflicts (backup from different device)
class BackupProvider extends ChangeNotifier {
  BackupProvider();

  static const String _kBackupUserEmailKey = 'backup_user_email';
  static const String _kBackupUserIdKey = 'backup_user_id';

  // Google Sign-In state
  GoogleSignInAccount? _currentUser;
  User? _firebaseUser;
  late final GoogleSignIn _googleSignIn;
  late final FlutterSecureStorage _secureStorage;
  HabitProvider? _habitProvider;

  // Encryption state
  /// Passphrase stored securely in device keystore/keychain
  String? _passphrase;
  static const String _kSecurePassphraseKey = 'habitt_backup_passphrase';

  // Sync state
  SyncState _syncState = SyncState.idle;
  String? _lastError;

  BackupMetadata? _localMetadata;
  String? _currentSessionPassphrase;

  // Getters
  GoogleSignInAccount? get currentUser => _currentUser;
  User? get firebaseUser => _firebaseUser;
  bool get isLoggedIn => _currentUser != null && _firebaseUser != null;

  BackupMetadata? get localMetadata => _localMetadata;

  SyncState get syncState => _syncState;
  String? get lastError => _lastError;

  // Whether user has set up a passphrase
  bool get hasPassphraseSet => _passphrase != null;

  bool get isPassphraseLoaded => _currentSessionPassphrase != null;

  void attachHabitProvider(HabitProvider provider) {
    _habitProvider = provider;
  }

  /// Initialize provider: restore persisted sign-in state and passphrase.
  Future<void> initialize() async {
    _googleSignIn = GoogleSignIn(
      scopes: [drive_api.DriveApi.driveFileScope],
      clientId: DefaultFirebaseOptions.ios.iosClientId,
      serverClientId:
          '752709751941-vt92fpp7ge9gs8cs4rrnlvrkk84aekmc.apps.googleusercontent.com',
    );

    // Initializing secure storage
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        keyCipherAlgorithm:
            KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      ),
    );

    // Restoring previous sign-in and passphrase
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString(_kBackupUserEmailKey);

      if (savedEmail != null) {
        // Signing in the user in the background
        final user = await _googleSignIn.signInSilently();
        if (user != null) {
          _currentUser = user;
          _firebaseUser = FirebaseAuth.instance.currentUser;

          // Loading passphrase from secure storage (but don't load into session yet)
          try {
            _passphrase = await _secureStorage.read(key: _kSecurePassphraseKey);
          } catch (e) {
            debugPrint('Failed to load passphrase: $e');
          }

          // TODO: Load local metadata from storage
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Failed to restore sign-in state: $e');
    }
  }

  Future<void> signIn(BuildContext context) async {
    debugPrint('Starting Google sign-in...');

    try {
      debugPrint('Calling _googleSignIn.signIn()...');
      final user = await _googleSignIn.signIn();
      debugPrint('Sign-in returned: ${user?.email ?? "null"}');

      if (user == null) {
        debugPrint('Sign-in cancelled');
        return; // user cancelled
      }

      debugPrint('Getting authentication...');
      final auth = await user.authentication.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Authentication timeout! Check OAuth configuration.');
          throw TimeoutException('Google authentication timed out');
        },
      );
      debugPrint('Got authentication tokens');
      debugPrint(
        'AccessToken: ${auth.accessToken != null ? "present" : "null"}',
      );
      debugPrint('IdToken: ${auth.idToken != null ? "present" : "null"}');

      debugPrint('Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      debugPrint('Signing in to Firebase...');
      await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint('Firebase sign-in successful');

      _currentUser = user;
      _firebaseUser = FirebaseAuth.instance.currentUser;

      // Persist sign-in state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kBackupUserEmailKey, user.email);
      await prefs.setString(_kBackupUserIdKey, user.id);

      notifyListeners();

      // Checking if user has existing passphrase
      if (await _secureStorage.containsKey(key: _kSecurePassphraseKey)) {
        await loadPassphraseToSession();
      } else {
        // New user, prompt to set passphrase
        _passphrase = null;
        _currentSessionPassphrase = null;

        if (!context.mounted) return;

        final String? passphrase = await showDialog(
          context: context,
          builder: (context) {
            final TextEditingController controller = TextEditingController();
            return PassphraseDialog(controller: controller);
          },
        );

        if (passphrase != null && passphrase.isNotEmpty) {
          await setPassphrase(passphrase);
        }

        notifyListeners();
      }

      await performSync();
    } catch (e) {
      _lastError = 'Failed to sign in: $e';
      debugPrint(_lastError);
      notifyListeners();
    } finally {
      debugPrint('Google sign-in process completed.');
    }
  }

  /// Clears persisted sign-in state, passphrase, and provider data.
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();

      _currentUser = null;
      _firebaseUser = null;
      _syncState = SyncState.idle;
      _passphrase = null;
      _currentSessionPassphrase = null;

      // Clear persisted sign-in state
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kBackupUserEmailKey);
      await prefs.remove(_kBackupUserIdKey);

      // Clear passphrase from secure storage
      await _secureStorage.delete(key: _kSecurePassphraseKey);

      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to sign out: $e';
      debugPrint(_lastError);
      notifyListeners();
    }
  }

  /// Set or update user's backup passphrase.
  ///
  /// Passphrase is stored securely in device keystore (Android) or keychain (iOS).
  /// Automatically loaded into session for immediate use.
  Future<void> setPassphrase(String passphrase) async {
    if (passphrase.isEmpty) {
      _lastError = 'Passphrase cannot be empty';
      notifyListeners();
      return;
    }

    try {
      // Store in secure storage
      await _secureStorage.write(key: _kSecurePassphraseKey, value: passphrase);

      _passphrase = passphrase;
      _currentSessionPassphrase = passphrase;
      _lastError = null;

      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to set passphrase: $e';
      debugPrint(_lastError);
      notifyListeners();
    }
  }

  /// Load passphrase into current session for encryption/decryption.
  ///
  /// Call this if passphrase is set but not currently loaded in session.
  /// Returns true if successful.
  Future<bool> loadPassphraseToSession() async {
    try {
      if (_passphrase == null) {
        _lastError = 'No passphrase stored';
        notifyListeners();
        return false;
      }

      _currentSessionPassphrase = _passphrase;
      _lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Failed to load passphrase: $e';
      debugPrint(_lastError);
      notifyListeners();
      return false;
    }
  }

  /// Clear in-memory passphrase without signing out.
  void clearSessionPassphrase() {
    _currentSessionPassphrase = null;
    notifyListeners();
  }

  Future<void> performSync([bool force = false]) async {
    debugPrint('Starting backup sync operation...');
    if (!isLoggedIn) {
      _lastError = 'Not signed in. Cannot sync.';
      debugPrint(_lastError);
      notifyListeners();
      return;
    }

    if (!hasPassphraseSet && !isPassphraseLoaded) {
      _lastError = 'Passphrase required to sync. Please unlock backup.';
      debugPrint(_lastError);
      notifyListeners();
      return;
    }

    _lastError = null;
    notifyListeners();

    try {
      final metadata = await _fetchCloudMetadata();

      if (!force &&
          _localMetadata?.deviceId == metadata?.deviceId &&
          metadata != null) {
        // Not from different device, no need to download anything
        debugPrint('No device conflict detected, skipping download.');
        _syncState = SyncState.success;
        notifyListeners();
        return;
      }

      if (metadata != null) {
        _syncState = SyncState.syncing;
        final backupData = await _downloadBackupFromCloud();
        if (backupData != null) {
          debugPrint('Merging downloaded backup data with local data...');
          await _mergeBackupData(backupData);
        }
      } else {
        debugPrint('No cloud metadata found, uploading local backup.');
        await _uploadBackupToCloud();
      }

      _syncState = SyncState.success;
      notifyListeners();
    } catch (e) {
      _syncState = SyncState.error;
      _lastError = 'Sync failed: $e';
      debugPrint(_lastError);
      notifyListeners();
    }
  }

  Future<drive_api.DriveApi?> _getDriveService() async {
    final user = _currentUser;
    if (user == null) return null;
    final headers = await user.authHeaders;
    final client = _GoogleAuthClient(headers);
    return drive_api.DriveApi(client);
  }

  Future<String?> _getFolderId(drive_api.DriveApi driveApi) async {
    final mimeType = "application/vnd.google-apps.folder";
    String folderName = "habitt_backups";

    try {
      final found = await driveApi.files.list(
        q: "mimeType = '$mimeType' and name = '$folderName' and trashed = false and 'root' in parents",
        $fields: "files(id,name)",
        spaces: 'drive',
      );

      final files = found.files;
      if (files == null) {
        debugPrint("Drive API returned null files list");
        return null;
      }

      // The folder already exists
      if (files.isNotEmpty) {
        return files.first.id;
      }

      // Create the folder in the root
      final folder =
          drive_api.File()
            ..name = folderName
            ..mimeType = mimeType
            ..parents = ['root'];
      final folderCreation = await driveApi.files.create(folder, $fields: 'id');
      debugPrint("Folder ID: ${folderCreation.id}");

      return folderCreation.id;
    } catch (e) {
      debugPrint('Failed to get/create folder: $e');
      return null;
    }
  }

  /// Fetch metadata about the backup stored in Google Drive.
  /// Returns BackupMetadata if found
  Future<BackupMetadata?> _fetchCloudMetadata() async {
    // Checking for passphrase
    if (_passphrase == null) {
      _lastError = 'Passphrase not set. Cannot upload backup.';
      debugPrint(_lastError);
      notifyListeners();
      return null;
    }

    // Preparing google drive
    final drive = await _getDriveService();
    if (drive == null) {
      debugPrint("Sign-in first Error");
      return null;
    }

    final folderId = await _getFolderId(drive);
    if (folderId == null) {
      debugPrint("Could not get or create backup folder");
      return null;
    }

    // Looking for metadata.meta file
    try {
      final found = await drive.files.list(
        q: "name = 'metadata.meta' and '$folderId' in parents and trashed = false",
        $fields: 'files(id)',
      );

      if (found.files == null || found.files!.isEmpty) {
        debugPrint('No metadata file found in cloud');
        return null;
      }

      final metadataFileId = found.files!.first.id;
      if (metadataFileId == null) {
        debugPrint('Metadata file ID is null');
        return null;
      }

      // Download metadata file
      final response =
          await drive.files.get(
                metadataFileId,
                downloadOptions: drive_api.DownloadOptions.fullMedia,
              )
              as drive_api.Media;

      // Read bytes from stream
      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }

      // Decrypt metadata
      final metadata = await BackupService.importMetadata(
        encryptedBytes: Uint8List.fromList(bytes),
        passphrase: _passphrase!,
      );

      if (metadata != null) {
        debugPrint('Cloud metadata loaded: ${metadata.deviceId}');
        return metadata;
      } else {
        debugPrint('Failed to decrypt metadata');
        return null;
      }
    } catch (e) {
      debugPrint('Failed to fetch cloud metadata: $e');
      return null;
    }
  }

  /// Download encrypted backup file from Google Drive and decrypt/merge.
  ///
  /// Steps:
  /// 1. Download encrypted file from Drive
  /// 2. Decrypt using device key
  /// 3. Compare with local data (timestamps, checksums)
  /// 4. Merge or ask user for resolution
  Future<BackupData?> _downloadBackupFromCloud() async {
    // Checking for passphrase
    if (_passphrase == null) {
      _lastError = 'Passphrase not set. Cannot upload backup.';
      notifyListeners();
      return null;
    }

    // Preparing google drive
    final drive = await _getDriveService();
    if (drive == null) {
      debugPrint("Sign-in first Error");
      return null;
    }

    final folderId = await _getFolderId(drive);
    if (folderId == null) {
      debugPrint("Could not get or create backup folder");
      return null;
    }

    // Looking for habitt backup file
    try {
      final found = await drive.files.list(
        q: "name contains 'habitt-backup' and '$folderId' in parents and trashed = false",
        $fields: 'files(id)',
        orderBy: 'modifiedTime desc',
      );

      if (found.files == null || found.files!.isEmpty) {
        debugPrint('No metadata file found in cloud');
        return null;
      }

      final metadataFileId = found.files!.first.id;
      if (metadataFileId == null) {
        debugPrint('Metadata file ID is null');
        return null;
      }

      // Download metadata file
      final response =
          await drive.files.get(
                metadataFileId,
                downloadOptions: drive_api.DownloadOptions.fullMedia,
              )
              as drive_api.Media;

      // Read bytes from stream
      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }

      // Decrypt metadata
      final BackupData? habitBackupData =
          await BackupService.importDataFromGoogleDrive(
            encryptedBytes: Uint8List.fromList(bytes),
            passphrase: _passphrase!,
          );

      if (habitBackupData != null) {
        debugPrint('Cloud metadata loaded: $habitBackupData');
        return habitBackupData;
      } else {
        debugPrint('Failed to decrypt metadata');
        return null;
      }
    } catch (e) {
      debugPrint('Failed to fetch cloud metadata: $e');
      return null;
    }
  }

  Future<void> _deleteAllFilesInFolder(String folderId) async {
    final client = _GoogleAuthClient(await _currentUser!.authHeaders);
    final driveApi = drive_api.DriveApi(client);

    final found = await driveApi.files.list(
      q: "'$folderId' in parents and trashed = false",
      $fields: 'files(id)',
    );

    if (found.files != null) {
      for (final file in found.files!) {
        await driveApi.files.delete(file.id!);
      }
    }

    debugPrint("Deleted all files in folder ID: $folderId");
  }

  Future<void> _deleteMetadataInFolder(String folderId) async {
    final client = _GoogleAuthClient(await _currentUser!.authHeaders);
    final driveApi = drive_api.DriveApi(client);

    final found = await driveApi.files.list(
      q: "'$folderId' in parents and trashed = false",
      $fields: 'files(id)',
    );

    if (found.files != null) {
      for (final file in found.files!) {
        if (file.name == 'metadata.meta') await driveApi.files.delete(file.id!);
      }
    }

    debugPrint("Deleted metadata files in folder ID: $folderId");
  }

  Future<void> _uploadBackupToCloud() async {
    // Checking for passphrase
    if (_passphrase == null) {
      _lastError = 'Passphrase not set. Cannot upload backup.';
      notifyListeners();
      return;
    }

    // Preparing encrypted backup data
    final ecnryptedDatabase = await BackupService.exportDataForGoogleDrive(
      passphrase: _passphrase!,
    );

    if (ecnryptedDatabase == null) {
      _lastError = 'Failed to export database. Cannot upload backup.';
      notifyListeners();
      return;
    }

    // Preparing encrypted metadata
    final metadata = await BackupService.buildMetadata();
    final encryptedMetadata = await BackupService.exportEncryptedMetadata(
      passphrase: _passphrase!,
      metadata: metadata,
    );

    // Preparing google drive
    final drive = await _getDriveService();
    if (drive == null) {
      debugPrint("Sign-in first Error");
      return;
    }

    final folderId = await _getFolderId(drive);
    if (folderId == null) {
      debugPrint("Could not get or create backup folder");
      return;
    }

    // Deleting all existing files in backup folder
    await _deleteAllFilesInFolder(folderId);

    // Generating filename
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString().substring(2);
    final backupFileName = '$day-$month-$year-habitt-backup.habitt';
    final metadataFileName = 'metadata.meta';

    // Uploading database backup file
    final databaseMedia = drive_api.Media(
      Stream.value(ecnryptedDatabase.toList()),
      ecnryptedDatabase.length,
    );

    final databaseFile =
        drive_api.File()
          ..name = backupFileName
          ..parents = [folderId];

    final databaseCreation = await drive.files.create(
      databaseFile,
      uploadMedia: databaseMedia,
    );

    if (databaseCreation.id != null) {
      debugPrint('Uploaded database backup: ${databaseCreation.id}');
    } else {
      _lastError = 'Failed to upload database backup';
      notifyListeners();
      return;
    }

    // Upload metadata file if available
    if (encryptedMetadata != null) {
      final metadataMedia = drive_api.Media(
        Stream.value(encryptedMetadata.toList()),
        encryptedMetadata.length,
      );

      final metadataFile =
          drive_api.File()
            ..name = metadataFileName
            ..parents = [folderId];

      final metadataCreation = await drive.files.create(
        metadataFile,
        uploadMedia: metadataMedia,
      );

      if (metadataCreation.id != null) {
        debugPrint('Uploaded metadata: ${metadataCreation.id}');
      } else {
        _lastError = 'Failed to upload metadata';
        notifyListeners();
        return;
      }
    }

    debugPrint('Successfully uploaded backup files to Google Drive');

    if (encryptedMetadata != null) {
      _localMetadata = metadata;
    }
    notifyListeners();
  }

  Future<void> _uploadMetadataToCloud(BackupMetadata metadata) async {
    // Checking for passphrase
    if (_passphrase == null) {
      _lastError = 'Passphrase not set. Cannot upload backup.';
      notifyListeners();
      return;
    }

    final encryptedMetadata = await BackupService.exportEncryptedMetadata(
      passphrase: _passphrase!,
      metadata: metadata,
    );

    // Preparing google drive
    final drive = await _getDriveService();
    if (drive == null) {
      debugPrint("Sign-in first Error");
      return;
    }

    final folderId = await _getFolderId(drive);
    if (folderId == null) {
      debugPrint("Could not get or create backup folder");
      return;
    }

    // Deleting all existing files in backup folder
    await _deleteMetadataInFolder(folderId);

    // Generating filename
    final metadataFileName = 'metadata.meta';

    if (encryptedMetadata != null) {
      final metadataMedia = drive_api.Media(
        Stream.value(encryptedMetadata.toList()),
        encryptedMetadata.length,
      );

      final metadataFile =
          drive_api.File()
            ..name = metadataFileName
            ..parents = [folderId];

      final metadataCreation = await drive.files.create(
        metadataFile,
        uploadMedia: metadataMedia,
      );

      if (metadataCreation.id != null) {
        debugPrint('Uploaded metadata: ${metadataCreation.id}');
      } else {
        _lastError = 'Failed to upload metadata';
        notifyListeners();
        return;
      }
    }

    debugPrint('Successfully uploaded backup files to Google Drive');

    if (encryptedMetadata != null) {
      _localMetadata = metadata;
    }
    notifyListeners();
  }

  Future<void> _mergeBackupData(BackupData backupData) async {
    final habitsBox = Hive.box<Habit>('habits');
    final daysBox = Hive.box<Day>('days');

    // Merge habits using timestamp-aware resolution
    // For each habit in the backup:
    for (final incoming in backupData.habits) {
      Habit? existing;
      for (final h in habitsBox.values) {
        // For each habit in the local database, check if IDs match
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

    // Build map of final habits for day references
    // Used so that days reference the correct habit instances and not copies
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
          continue; // No change
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
          final merged = local.merge(incomingHabit);
          mergedDayHabits.add(merged);
        } else {
          if (incomingHabit.isDeleted ?? false) continue;
          mergedDayHabits.add(incomingHabit);
        }
      }

      // Preserve any local-only habits for that day
      mergedDayHabits.addAll(existingById.values);

      final normalizedHabits =
          mergedDayHabits.map((h) => habitById[h.id] ?? h).toList();

      await daysBox.put(
        dayKey,
        Day(date: day.date, habits: normalizedHabits, timestamp: day.timestamp),
      );
    }

    // Refresh dependent providers
    await _habitProvider?.init();

    notifyListeners();
  }

  /// Delete backup from Google Drive.
  Future<void> deleteCloudBackup() async {
    if (!isLoggedIn) {
      _lastError = 'Not signed in. Cannot delete cloud backup.';
      notifyListeners();
      return;
    }

    try {
      // Deleting all files in backup folder
      final drive = await _getDriveService();
      if (drive == null) {
        _lastError = 'Sign-in first';
        notifyListeners();
        return;
      }
      final folderId = await _getFolderId(drive);
      if (folderId == null) {
        _lastError = 'Could not get or create backup folder';
        notifyListeners();
        return;
      }
      await _deleteAllFilesInFolder(folderId);
      _lastError = 'Deleted cloud backup';
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to delete cloud backup: $e';
      debugPrint(_lastError);
      notifyListeners();
    }
  }
}

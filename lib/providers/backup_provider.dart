import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v2.dart' as drive_api;

/// Metadata about a backup stored in the cloud.
class BackupMetadata {
  final String deviceId;
  final DateTime lastSyncTime;
  final String? cloudFileId; // Google Drive file ID
  final String? cloudChecksum; // For detecting changes

  BackupMetadata({
    required this.deviceId,
    required this.lastSyncTime,
    this.cloudFileId,
    this.cloudChecksum,
  });

  // TODO: Add toJson/fromJson for serialization
}

/// Enum to track sync state.
enum SyncState { idle, syncing, success, conflict, error }

/// Provider managing backup/sync operations with Google Drive.
///
/// Responsibilities:
/// - Track Google Sign-In authentication state
/// - Manage backup metadata (device ID, last sync info)
/// - Coordinate sync operations (upload/download)
/// - Detect device conflicts (backup from different device)
class BackupProvider extends ChangeNotifier {
  BackupProvider();

  // Google Sign-In state
  GoogleSignInAccount? _currentUser;
  User? _firebaseUser;

  // Backup metadata
  BackupMetadata? _localMetadata;
  BackupMetadata? _cloudMetadata;

  // Sync state
  SyncState _syncState = SyncState.idle;
  String? _lastError;

  // Getters
  GoogleSignInAccount? get currentUser => _currentUser;
  User? get firebaseUser => _firebaseUser;
  bool get isLoggedIn => _currentUser != null && _firebaseUser != null;

  BackupMetadata? get localMetadata => _localMetadata;
  BackupMetadata? get cloudMetadata => _cloudMetadata;

  SyncState get syncState => _syncState;
  String? get lastError => _lastError;

  // Computed property: whether backup on cloud is from a different device
  bool get isCloudBackupFromDifferentDevice {
    if (_localMetadata == null || _cloudMetadata == null) return false;
    return _localMetadata!.deviceId != _cloudMetadata!.deviceId;
  }

  /// Initialize provider: load local backup metadata and check cloud state.
  Future<void> initialize() async {
    // TODO: Load local backup metadata from persistent storage (Hive/SharedPreferences)
    // Example:
    // _localMetadata = await _loadLocalMetadata();
  }

  /// Called when user signs in via Google (from UI).
  /// Updates Firebase auth and enables sync.
  Future<void> onSignInSuccess(GoogleSignInAccount user) async {
    try {
      _currentUser = user;
      _firebaseUser = FirebaseAuth.instance.currentUser;

      // TODO: Initialize Drive API client with authenticated user
      // TODO: Fetch cloud backup metadata

      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to complete sign-in: $e';
      debugPrint(_lastError);
      notifyListeners();
    }
  }

  /// Called when user signs out.
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();

      _currentUser = null;
      _firebaseUser = null;
      _cloudMetadata = null;
      _syncState = SyncState.idle;

      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to sign out: $e';
      debugPrint(_lastError);
      notifyListeners();
    }
  }

  /// Sync workflow: orchestrates upload/download based on device/cloud state.
  ///
  /// Logic:
  /// 1. Check if cloud backup exists
  /// 2. If cloud backup from different device: decide strategy (merge, ask user, etc.)
  /// 3. Download cloud backup if available and newer
  /// 4. Upload local backup to cloud
  Future<void> performSync() async {
    if (!isLoggedIn) {
      _lastError = 'Not signed in. Cannot sync.';
      notifyListeners();
      return;
    }

    _syncState = SyncState.syncing;
    _lastError = null;
    notifyListeners();

    try {
      // TODO: Fetch cloud metadata
      await _fetchCloudMetadata();

      // TODO: Detect conflicts
      if (isCloudBackupFromDifferentDevice) {
        _syncState = SyncState.conflict;
        _lastError =
            'Backup detected from different device. Manual resolution needed.';
        notifyListeners();
        return;
      }

      // TODO: Download cloud backup if newer
      await _downloadBackupFromCloud();

      // TODO: Upload local backup to cloud
      await _uploadBackupToCloud();

      _syncState = SyncState.success;
      notifyListeners();
    } catch (e) {
      _syncState = SyncState.error;
      _lastError = 'Sync failed: $e';
      debugPrint(_lastError);
      notifyListeners();
    }
  }

  /// Fetch metadata about the backup stored in Google Drive.
  ///
  /// Returns info like: file ID, last modified time, device info, checksum.
  Future<void> _fetchCloudMetadata() async {
    // TODO: Query Google Drive API for backup file metadata
    // TODO: Parse metadata from file properties or custom app properties
    // Example:
    // final driveService = drive_api.DriveApi(httpClient);
    // final files = await driveService.files.list(
    //   q: 'name="habitt_backup.enc" and trashed=false',
    // );
    // if (files.items != null && files.items!.isNotEmpty) {
    //   _cloudMetadata = _parseMetadata(files.items!.first);
    // }
  }

  /// Download encrypted backup file from Google Drive and decrypt/merge.
  ///
  /// Steps:
  /// 1. Download encrypted file from Drive
  /// 2. Decrypt using device key
  /// 3. Compare with local data (timestamps, checksums)
  /// 4. Merge or ask user for resolution
  Future<void> _downloadBackupFromCloud() async {
    // TODO: Download encrypted file from Google Drive
    // TODO: Decrypt using local encryption key
    // TODO: Merge with local storage (or replace based on strategy)
  }

  /// Upload encrypted backup file to Google Drive.
  ///
  /// Steps:
  /// 1. Serialize local storage (habits, days, etc.)
  /// 2. Encrypt using device key
  /// 3. Upload to Google Drive (create or update)
  /// 4. Store file ID and metadata locally
  Future<void> _uploadBackupToCloud() async {
    // TODO: Get all local data (habits, days, etc.)
    // TODO: Serialize to bytes/JSON
    // TODO: Encrypt
    // TODO: Upload to Google Drive
    // TODO: Save file ID and metadata locally
    // TODO: Update _localMetadata with new sync time
  }

  /// Delete backup from Google Drive.
  Future<void> deleteCloudBackup() async {
    if (!isLoggedIn) {
      _lastError = 'Not signed in. Cannot delete cloud backup.';
      notifyListeners();
      return;
    }

    try {
      // TODO: Delete file from Google Drive
      _cloudMetadata = null;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to delete cloud backup: $e';
      debugPrint(_lastError);
      notifyListeners();
    }
  }

  /// Resolve conflict by choosing local or cloud version.
  Future<void> resolveConflict({required bool preferCloud}) async {
    // TODO: If preferCloud=true, download and replace local
    // TODO: If preferCloud=false, upload local and overwrite cloud
  }
}

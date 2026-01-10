import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v2.dart' as drive_api;
import 'package:habitt/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  // Encryption state
  /// Passphrase stored securely in device keystore/keychain
  String? _passphrase;
  static const String _kSecurePassphraseKey = 'habitt_backup_passphrase';

  // Current session passphrase (in-memory only)
  BackupMetadata? _cloudMetadata;

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
  BackupMetadata? get cloudMetadata => _cloudMetadata;

  SyncState get syncState => _syncState;
  String? get lastError => _lastError;

  // Computed property: whether backup on cloud is from a different device
  bool get isCloudBackupFromDifferentDevice {
    if (_localMetadata == null || _cloudMetadata == null) return false;
    return _localMetadata!.deviceId != _cloudMetadata!.deviceId;
  }

  // Whether user has set up a passphrase
  bool get hasPassphraseSet => _passphrase != null;

  bool get isPassphraseLoaded => _currentSessionPassphrase != null;

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

  Future<void> signIn() async {
    try {
      final user = await _googleSignIn.signIn();
      if (user == null) return; // user cancelled

      final auth = await user.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      _currentUser = user;
      _firebaseUser = FirebaseAuth.instance.currentUser;

      // Persist sign-in state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kBackupUserEmailKey, user.email);
      await prefs.setString(_kBackupUserIdKey, user.id);

      notifyListeners();

      // TODO: Initialize Drive API client with authenticated user
      // TODO: Fetch cloud backup metadata
    } catch (e) {
      _lastError = 'Failed to sign in: $e';
      debugPrint(_lastError);
      notifyListeners();
    }
  }

  /// Clears persisted sign-in state, passphrase, and provider data.
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();

      _currentUser = null;
      _firebaseUser = null;
      _cloudMetadata = null;
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

  /// Sync workflow: orchestrates upload/download based on device/cloud state.
  ///
  /// Logic:
  /// 1. Check if cloud backup exists
  /// 2. If cloud backup from different device: decide strategy (merge, ask user, etc.)
  /// 3. Download cloud backup if available and newer
  /// 4. Upload local backup to cloud
  ///
  /// Requires passphrase to be loaded in current session.
  Future<void> performSync() async {
    if (!isLoggedIn) {
      _lastError = 'Not signed in. Cannot sync.';
      notifyListeners();
      return;
    }

    if (hasPassphraseSet && !isPassphraseLoaded) {
      _lastError = 'Passphrase required to sync. Please unlock backup.';
      notifyListeners();
      return;
    }

    _syncState = SyncState.syncing;
    _lastError = null;
    notifyListeners();

    try {
      // TODO: Fetch cloud metadata
      await _fetchCloudMetadata();

      if (!isCloudBackupFromDifferentDevice) {
        // Not from different device, no need to download anything
        return;
      }

      // TODO: Download cloud backup
      await _downloadBackupFromCloud();

      // Since the backup is now same, only upload local metadata

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
}

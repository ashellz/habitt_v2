import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:habitt/models/backup_data.dart';
import 'package:habitt/models/backup_metadata.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:hive_ce/hive.dart';
import 'package:provider/provider.dart';

enum BackupOperationResult {
  success,
  cancelled,
  failed,
  wrongPassphrase;

  void operator [](String other) {}
}

class BackupService {
  BackupService._();

  static final _rng = Random.secure();
  static final _aes = AesGcm.with256bits();

  static const _kBackupKeyStorageKey = 'habitt_backup_key';
  static const _kPinDataStorageKey = 'habitt_backup_pin_data';
  static const _kPinValueStorageKey = 'habitt_backup_pin_value';

  // --- Keychain key management -------------------------------------------

  /// Returns the 256-bit device key for Drive encryption.
  /// Creates one on first call and persists it in the platform keychain.
  /// On iOS, synchronizable=true syncs the key via iCloud Keychain so a new
  /// device with the same Apple ID can decrypt existing Drive backups.
  /// For cross-platform restore (iOS→Android), the key is synced via Drive
  /// using [storeKeyBytes] before this is called.
  static Future<SecretKey> getOrCreateKey(FlutterSecureStorage storage) async {
    const iOSOpts = IOSOptions(synchronizable: true);
    const androidOpts = AndroidOptions(encryptedSharedPreferences: true);

    // getting stored key if exists and returning it
    final stored = await storage.read(
      key: _kBackupKeyStorageKey,
      iOptions: iOSOpts,
      aOptions: androidOpts,
    );

    if (stored != null) {
      return SecretKey(base64Decode(stored));
    }

    // generating new key, storing and returning it
    final bytes = List<int>.generate(32, (_) => _rng.nextInt(256));
    await storage.write(
      key: _kBackupKeyStorageKey,
      value: base64Encode(bytes),
      iOptions: iOSOpts,
      aOptions: androidOpts,
    );
    return SecretKey(bytes);
  }

  /// Returns true if  backup key is already stored in the keychain.
  /// Used to gate Drive download — local always wins over Drive on existing devices.
  static Future<bool> hasStoredKey(FlutterSecureStorage storage) async {
    const iOSOpts = IOSOptions(synchronizable: true);
    const androidOpts = AndroidOptions(encryptedSharedPreferences: true);
    final stored = await storage.read(
      key: _kBackupKeyStorageKey,
      iOptions: iOSOpts,
      aOptions: androidOpts,
    );
    return stored != null;
  }

  /// Overwrites the stored device backup key with [keyBytes].
  /// Used when downloading the shared key from Google Drive so all platforms
  /// (iOS, Android) use the same encryption key.
  static Future<void> storeKeyBytes(
    FlutterSecureStorage storage,
    List<int> keyBytes,
  ) async {
    const iOSOpts = IOSOptions(synchronizable: true);
    const androidOpts = AndroidOptions(encryptedSharedPreferences: true);
    await storage.write(
      key: _kBackupKeyStorageKey,
      value: base64Encode(keyBytes),
      iOptions: iOSOpts,
      aOptions: androidOpts,
    );
  }

  // --- PIN key wrapping --------------------------------------------------

  /// Wraps [key] with a PBKDF2-derived key from [pin]. Returns a JSON-ready map.
  static Future<Map<String, String>> wrapKeyWithPin(
    SecretKey key, // The key to wrap
    String pin, // The user PIN to derive the wrapping key from
  ) async {
    final keyBytes = await key.extractBytes();
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final pinKey = await _deriveKey(pin, salt);
    final box = await _aes.encrypt(keyBytes, secretKey: pinKey, nonce: nonce);

    // Key gets wrapped with pin and a JSON is made
    // with salt, nonce, ciphertext and tag as instructions to unwrap it
    // for the other side
    return {
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(box.cipherText),
      'tag': base64Encode(box.mac.bytes),
    };
  }

  /// Reads the stored PIN-wrapped key and decrypts it using [pin].
  /// Returns null if PIN is wrong or no data is stored.
  static Future<SecretKey?> unwrapKeyWithPin(
    FlutterSecureStorage storage,
    String pin,
  ) async {
    const iOSOpts = IOSOptions(synchronizable: true);
    const androidOpts = AndroidOptions(encryptedSharedPreferences: true);

    final storedJson = await storage.read(
      key: _kPinDataStorageKey,
      iOptions: iOSOpts,
      aOptions: androidOpts,
    );
    if (storedJson == null) return null;

    try {
      final w = jsonDecode(storedJson) as Map<String, dynamic>;
      final pinKey = await _deriveKey(pin, base64Decode(w['salt'] as String));
      final decrypted = await _aes.decrypt(
        SecretBox(
          base64Decode(w['ciphertext'] as String),
          nonce: base64Decode(w['nonce'] as String),
          mac: Mac(base64Decode(w['tag'] as String)),
        ),
        secretKey: pinKey,
      );
      return SecretKey(decrypted);
    } on SecretBoxAuthenticationError {
      return null;
    } catch (e) {
      debugPrint('PIN unwrap error: $e');
      return null;
    }
  }

  static Future<void> storePinData(
    FlutterSecureStorage storage,
    Map<String, String> wrapped,
  ) async {
    const iOSOpts = IOSOptions(synchronizable: true);
    const androidOpts = AndroidOptions(encryptedSharedPreferences: true);
    await storage.write(
      key: _kPinDataStorageKey,
      value: jsonEncode(wrapped),
      iOptions: iOSOpts,
      aOptions: androidOpts,
    );
  }

  static Future<void> clearPinData(FlutterSecureStorage storage) async {
    const iOSOpts = IOSOptions(synchronizable: true);
    const androidOpts = AndroidOptions(encryptedSharedPreferences: true);
    await storage.delete(
      key: _kPinDataStorageKey,
      iOptions: iOSOpts,
      aOptions: androidOpts,
    );
  }

  /// Persists the raw PIN string so it can be used automatically on next launch.
  static Future<void> storePin(FlutterSecureStorage storage, String pin) async {
    const iOSOpts = IOSOptions(synchronizable: true);
    const androidOpts = AndroidOptions(encryptedSharedPreferences: true);
    await storage.write(
      key: _kPinValueStorageKey,
      value: pin,
      iOptions: iOSOpts,
      aOptions: androidOpts,
    );
  }

  static Future<String?> readStoredPin(FlutterSecureStorage storage) async {
    const iOSOpts = IOSOptions(synchronizable: true);
    const androidOpts = AndroidOptions(encryptedSharedPreferences: true);
    return storage.read(
      key: _kPinValueStorageKey,
      iOptions: iOSOpts,
      aOptions: androidOpts,
    );
  }

  static Future<void> clearStoredPin(FlutterSecureStorage storage) async {
    const iOSOpts = IOSOptions(synchronizable: true);
    const androidOpts = AndroidOptions(encryptedSharedPreferences: true);
    await storage.delete(
      key: _kPinValueStorageKey,
      iOptions: iOSOpts,
      aOptions: androidOpts,
    );
  }

  // --- Key-based encryption ---

  static Future<Map<String, dynamic>> _encryptWithKey(
    Map<String, dynamic> payload,
    SecretKey secretKey,
  ) async {
    final plainBytes = utf8.encode(jsonEncode(payload));
    final nonce = _randomBytes(12);

    final secretBox = await _aes.encrypt(
      plainBytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    return {
      'version': 2,
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'tag': base64Encode(secretBox.mac.bytes),
    };
  }

  static Future<BackupData> _decryptWithKey(
    Map<String, dynamic> wrapper,
    SecretKey secretKey,
  ) async {
    final version = wrapper['version'] as int? ?? 1;
    if (version == 1) {
      throw const FormatException('legacy_v1');
    }

    final nonce = base64Decode(wrapper['nonce'] as String);
    final cipher = base64Decode(wrapper['ciphertext'] as String);
    final tag = base64Decode(wrapper['tag'] as String);

    final clear = await _aes.decrypt(
      SecretBox(cipher, nonce: nonce, mac: Mac(tag)),
      secretKey: secretKey,
    );

    return BackupData.fromMap(jsonDecode(utf8.decode(clear)));
  }

  static Future<BackupMetadata?> _decryptMetadataWithKey(
    Map<String, dynamic> wrapper,
    SecretKey secretKey,
  ) async {
    final version = wrapper['version'] as int? ?? 1;
    if (version == 1) {
      throw const FormatException('legacy_v1');
    }

    final nonce = base64Decode(wrapper['nonce'] as String);
    final cipher = base64Decode(wrapper['ciphertext'] as String);
    final tag = base64Decode(wrapper['tag'] as String);

    final clear = await _aes.decrypt(
      SecretBox(cipher, nonce: nonce, mac: Mac(tag)),
      secretKey: secretKey,
    );

    final map = jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
    return BackupMetadata.fromMap(map['metadata']);
  }

  /// Export all Hive data (habits + days) as a single encrypted JSON file.
  /// Returns [BackupOperationResult.success] on success, [BackupOperationResult.cancelled] if user canceled, or [BackupOperationResult.failed] on error.
  static Future<BackupOperationResult> exportDataLocally({
    required BuildContext context,
    required String passphrase,
  }) async {
    try {
      final habitsBox = Hive.box<Habit>('habits');
      final daysBox = Hive.box<Day>('days');
      final dateJoined = context.read<HabitProvider>().dateJoined;
      final metadata = await buildMetadata();

      final payload = <String, dynamic>{
        'version': 1,
        'metadata': metadata.toMap(),
        'habits': habitsBox.values.map((h) => h.toMap()).toList(),
        'days': daysBox.values.map((d) => d.toMap()).toList(),
        'dateJoined': dateJoined.toIso8601String(),
      };

      final backupWrapper = await _encryptPayload(payload, passphrase);
      final exportBytes = Uint8List.fromList(
        utf8.encode(jsonEncode(backupWrapper)),
      );

      final savePath = await _pickSavePath(exportBytes);
      if (savePath == null) {
        return BackupOperationResult.cancelled; // User canceled
      }

      final file = File(savePath);
      if (!await file.exists()) {
        await file.create(recursive: true);
      }
      await file.writeAsBytes(exportBytes, flush: true);
      return BackupOperationResult.success;
    } catch (e, st) {
      debugPrint('Export failed: $e\n$st');
      return BackupOperationResult.failed; // Export failed
    }
  }

  /// Import data from an encrypted file. Replaces existing box contents.
  /// Returns [BackupOperationResult.success] on success, [BackupOperationResult.cancelled] if user canceled, or [BackupOperationResult.failed] on error.
  static Future<BackupOperationResult> importLocalData({
    required BuildContext context,
    required String passphrase,
  }) async {
    try {
      final path = await _pickImportPath();
      if (path == null) return BackupOperationResult.cancelled;

      debugPrint('Importing from $path');

      final file = File(path);
      if (!await file.exists()) return BackupOperationResult.failed;

      try {
        final BackupData payload = await _decryptPayload(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>,
          passphrase,
        );
        if ((payload.version) != 1) {
          throw Exception('Unsupported backup version');
        }

        final metadata = _parseInlineMetadata(payload.metadata);
        _logMetadata(metadata);

        final habitsBox = Hive.box<Habit>('habits');
        final daysBox = Hive.box<Day>('days');

        final importedHabits = payload.habits;
        // Merge habits using timestamp-aware conflict resolution
        for (final incoming in importedHabits) {
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

        final importedDays = payload.days;

        for (final day in importedDays) {
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
              final merged = local.merge(incomingHabit);
              mergedDayHabits.add(merged);
            } else {
              if (incomingHabit.isDeleted ?? false) continue;
              mergedDayHabits.add(incomingHabit);
            }
          }

          // Preserve any local-only habits for that day
          mergedDayHabits.addAll(existingById.values);

          await daysBox.put(
            dayKey,
            Day(
              date: day.date,
              habits: mergedDayHabits,
              timestamp: day.timestamp,
            ),
          );

          final dateJoined = payload.dateJoined;
          if (context.mounted) {
            await context.read<HabitProvider>().importDateJoined(dateJoined);
          }
        }
      } on SecretBoxAuthenticationError {
        debugPrint('Decryption failed: invalid passphrase or corrupted file');
        return BackupOperationResult.wrongPassphrase;
      }

      if (!context.mounted) {
        debugPrint('Mount check failed');
        return BackupOperationResult.success;
      }

      await context.read<HabitProvider>().init();

      return BackupOperationResult.success;
    } catch (e, st) {
      debugPrint('Import failed: $e\n$st');
      return BackupOperationResult.failed;
    }
  }

  // --- Helpers ------------------------------------------------------------

  static List<int> _randomBytes(int length) {
    return List<int>.generate(length, (_) => _rng.nextInt(256));
  }

  static Future<Map<String, dynamic>> _encryptPayload(
    Map<String, dynamic> payload,
    String passphrase,
  ) async {
    final plainBytes = utf8.encode(jsonEncode(payload));
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final secretKey = await _deriveKey(passphrase, salt);

    final secretBox = await _aes.encrypt(
      plainBytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    return {
      'version': 1,
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'tag': base64Encode(secretBox.mac.bytes),
    };
  }

  static Future<BackupData> _decryptPayload(
    Map<String, dynamic> wrapper,
    String passphrase,
  ) async {
    final salt = base64Decode(wrapper['salt'] as String);
    final nonce = base64Decode(wrapper['nonce'] as String);
    final cipher = base64Decode(wrapper['ciphertext'] as String);
    final tag = base64Decode(wrapper['tag'] as String);

    final secretKey = await _deriveKey(passphrase, salt);
    final clear = await _aes.decrypt(
      SecretBox(cipher, nonce: nonce, mac: Mac(tag)),
      secretKey: secretKey,
    );

    return BackupData.fromMap(jsonDecode(utf8.decode(clear)));
  }

  static Future<SecretKey> _deriveKey(String pass, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 200000,
      bits: 256,
    );
    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(pass)),
      nonce: salt,
    );
  }

  static Future<String?> _pickSavePath(Uint8List bytes) async {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString().substring(2);
    final suggestedName = '$day-$month-$year-habitt-backup.habitt';

    final path = await FilePicker.saveFile(
      bytes: bytes,
      dialogTitle: 'Export backup',
      fileName: suggestedName,
    );

    if (path != null) return path;

    // Fallback: save to documents directory
    return null;
  }

  static Future<String?> _pickImportPath() async {
    return FilePicker.pickFiles(
      dialogTitle: 'Import backup',
      type: FileType.custom,
      allowedExtensions: ['habitt'],
    ).then((result) => result?.files.single.path);
  }

  static BackupMetadata? _parseInlineMetadata(dynamic rawMeta) {
    if (rawMeta is Map<String, dynamic>) {
      return BackupMetadata.fromMap(rawMeta);
    }
    if (rawMeta is Map) {
      return BackupMetadata.fromMap(Map<String, dynamic>.from(rawMeta));
    }
    return null;
  }

  static void _logMetadata(BackupMetadata? metadata) {
    if (metadata == null) return;
    debugPrint(
      'Importing backup from device ${metadata.model} (${metadata.os}) created at ${metadata.createdAt.toIso8601String()}',
    );
  }

  static Future<BackupMetadata> buildMetadata() async {
    final deviceId = await DeviceIdentity.getOrCreateId();
    final info = await DeviceIdentity.deviceInfo();
    return BackupMetadata(
      deviceId: deviceId,
      model: info['model'] ?? 'unknown',
      os: info['os'] ?? 'unknown',
      createdAt: DateTime.now().toUtc(),
    );
  }

  // --- Google Drive Backup Functions -----------------------------------

  /// Export all Hive data as encrypted bytes for uploading to Google Drive.
  /// Uses the device keychain key (v2 format — no passphrase required).
  static Future<Uint8List?> exportDataForGoogleDrive({
    required SecretKey secretKey,
    required HabitProvider habitProvider,
  }) async {
    try {
      final habitsBox = Hive.box<Habit>('habits');
      final daysBox = Hive.box<Day>('days');
      final dateJoined = habitProvider.dateJoined;
      final metadata = await buildMetadata();

      final payload = <String, dynamic>{
        'version': 2,
        'metadata': metadata.toMap(),
        'habits': habitsBox.values.map((h) => h.toMap()).toList(),
        'days': daysBox.values.map((d) => d.toMap()).toList(),
        'dateJoined': dateJoined.toIso8601String(),
      };

      final backupWrapper = await _encryptWithKey(payload, secretKey);
      return Uint8List.fromList(utf8.encode(jsonEncode(backupWrapper)));
    } catch (e, st) {
      debugPrint('Google Drive export failed: $e\n$st');
      return null;
    }
  }

  /// Export only the habits and days that have changed since [fromTime].

  /// Returns null when there are no changes — skips the
  /// upload step, not writing an empty delta file to Drive.
  static Future<Uint8List?> exportDeltaForGoogleDrive({
    required SecretKey secretKey,
    required HabitProvider habitProvider,
    required DateTime fromTime,
  }) async {
    try {
      final habits = habitProvider.habitBox.values.toList();
      final days = habitProvider.daysBox.values.toList();

      // A habit is changed if it was created after fromTime, or if any
      // per-field timestamp is newer than fromTime (covers edits, completes,
      // deletes, reorders, etc.).
      final changedHabits =
          habits.where((h) {
            if (h.createdAt.isAfter(fromTime)) return true;
            return h.timestamps.values.any((t) => t.isAfter(fromTime));
          }).toList();

      // A day is changed if its single modification timestamp is after fromTime.
      final changedDays =
          days
              .where(
                (d) => d.timestamp != null && d.timestamp!.isAfter(fromTime),
              )
              .toList();

      if (changedHabits.isEmpty && changedDays.isEmpty) return null;

      final metadata = await buildMetadata();
      final payload = <String, dynamic>{
        'version': 3,
        'type': 'delta',
        'fromTime': fromTime.toIso8601String(),
        'metadata': metadata.toMap(),
        'habits': changedHabits.map((h) => h.toMap()).toList(),
        'days': changedDays.map((d) => d.toMap()).toList(),
        'dateJoined': habitProvider.dateJoined.toIso8601String(),
      };

      final backupWrapper = await _encryptWithKey(payload, secretKey);
      return Uint8List.fromList(utf8.encode(jsonEncode(backupWrapper)));
    } catch (e, st) {
      debugPrint('Google Drive delta export failed: $e\n$st');
      return null;
    }
  }

  /// Decrypt Drive backup bytes using the device keychain key.
  /// Throws [FormatException] with message 'legacy_v1' if the file was
  /// encrypted with the old passphrase system — caller should handle migration.
  static Future<BackupData?> importDataFromGoogleDrive({
    required Uint8List encryptedBytes,
    required SecretKey secretKey,
  }) async {
    try {
      final content = utf8.decode(encryptedBytes);
      final wrapper = jsonDecode(content) as Map<String, dynamic>;
      final BackupData payload = await _decryptWithKey(wrapper, secretKey);
      return payload;
    } on FormatException {
      rethrow; // 'legacy_v1' — let provider handle migration
    } on SecretBoxAuthenticationError {
      debugPrint('Decryption failed: wrong key or corrupted file');
      return null;
    } catch (e, st) {
      debugPrint('Google Drive import failed: $e\n$st');
      return null;
    }
  }

  // --- Google Drive Metadata Functions ---------------------------------

  /// Export metadata as encrypted bytes using the device keychain key.
  static Future<Uint8List?> exportEncryptedMetadata({
    required SecretKey secretKey,
    BackupMetadata? metadata,
  }) async {
    try {
      metadata ??= await buildMetadata();

      final payload = <String, dynamic>{
        'version': 2,
        'metadata': metadata.toMap(),
      };

      final metadataWrapper = await _encryptWithKey(payload, secretKey);
      return Uint8List.fromList(utf8.encode(jsonEncode(metadataWrapper)));
    } catch (e, st) {
      debugPrint('Google Drive metadata export failed: $e\n$st');
      return null;
    }
  }

  /// Decrypt Drive metadata bytes using the device keychain key.
  /// Throws [FormatException] with message 'legacy_v1' if old passphrase format.
  static Future<BackupMetadata?> importMetadata({
    required Uint8List encryptedBytes,
    required SecretKey secretKey,
  }) async {
    try {
      final content = utf8.decode(encryptedBytes);
      final wrapper = jsonDecode(content) as Map<String, dynamic>;
      final metadata = await _decryptMetadataWithKey(wrapper, secretKey);
      _logMetadata(metadata);
      return metadata;
    } on FormatException {
      rethrow; // 'legacy_v1' — let provider handle migration
    } on SecretBoxAuthenticationError {
      debugPrint('Metadata decryption failed: wrong key or corrupted file');
      return null;
    } catch (e, st) {
      debugPrint('Google Drive metadata import failed: $e\n$st');
      return null;
    }
  }

  // --- Legacy passphrase helpers (kept for migration only) --------------

  static Future<BackupData?> importDataFromGoogleDriveLegacy({
    required Uint8List encryptedBytes,
    required String passphrase,
  }) async {
    try {
      final content = utf8.decode(encryptedBytes);
      final wrapper = jsonDecode(content) as Map<String, dynamic>;
      final BackupData payload = await _decryptPayload(wrapper, passphrase);
      return payload;
    } on SecretBoxAuthenticationError {
      return null;
    } catch (e) {
      debugPrint('Legacy import failed: $e');
      return null;
    }
  }

  static Future<BackupMetadata?> importMetadataLegacy({
    required Uint8List encryptedBytes,
    required String passphrase,
  }) async {
    try {
      final content = utf8.decode(encryptedBytes);
      final wrapper = jsonDecode(content) as Map<String, dynamic>;

      final salt = base64Decode(wrapper['salt'] as String);
      final nonce = base64Decode(wrapper['nonce'] as String);
      final cipher = base64Decode(wrapper['ciphertext'] as String);
      final tag = base64Decode(wrapper['tag'] as String);

      final secretKey = await _deriveKey(passphrase, salt);
      final clear = await _aes.decrypt(
        SecretBox(cipher, nonce: nonce, mac: Mac(tag)),
        secretKey: secretKey,
      );

      final map = jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
      return BackupMetadata.fromMap(map['metadata']);
    } on SecretBoxAuthenticationError {
      return null;
    } catch (e) {
      debugPrint('Legacy metadata import failed: $e');
      return null;
    }
  }
}

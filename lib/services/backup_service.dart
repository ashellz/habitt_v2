import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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

  /// Export all Hive data (habits + days) as a single encrypted JSON file.
  /// Returns [BackupOperationResult.success] on success, [BackupOperationResult.cancelled] if user canceled, or [BackupOperationResult.failed] on error.
  static Future<BackupOperationResult> exportDataLocally({
    required BuildContext context,
    required String passphrase,
  }) async {
    try {
      final habitsBox = Hive.box<Habit>('habits');
      final daysBox = Hive.box<Day>('days');
      final metadata = await buildMetadata();

      final payload = <String, dynamic>{
        'version': 1,
        'metadata': metadata.toMap(),
        'habits': habitsBox.values.map((h) => h.toMap()).toList(),
        'days': daysBox.values.map((d) => d.toMap()).toList(),
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

        // Build a map for consistent references when saving days
        final habitById = {for (final h in habitsBox.values) h.id: h};

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

          final normalizedHabits =
              mergedDayHabits.map((h) => habitById[h.id] ?? h).toList();

          await daysBox.put(
            dayKey,
            Day(
              date: day.date,
              habits: normalizedHabits,
              timestamp: day.timestamp,
            ),
          );
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

    final path = await FilePicker.platform.saveFile(
      bytes: bytes,
      dialogTitle: 'Export backup',
      fileName: suggestedName,
    );

    if (path != null) return path;

    // Fallback: save to documents directory
    return null;
  }

  static Future<String?> _pickImportPath() async {
    return FilePicker.platform
        .pickFiles(
          dialogTitle: 'Import backup',
          type: FileType.custom,
          allowedExtensions: ['habitt'],
        )
        .then((result) => result?.files.single.path);
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
  /// Returns encrypted bytes on success, or null on failure.
  static Future<Uint8List?> exportDataForGoogleDrive({
    required String passphrase,
  }) async {
    try {
      final habitsBox = Hive.box<Habit>('habits');
      final daysBox = Hive.box<Day>('days');
      final metadata = await buildMetadata();

      final payload = <String, dynamic>{
        'version': 1,
        'metadata': metadata.toMap(),
        'habits': habitsBox.values.map((h) => h.toMap()).toList(),
        'days': daysBox.values.map((d) => d.toMap()).toList(),
      };

      final backupWrapper = await _encryptPayload(payload, passphrase);
      return Uint8List.fromList(utf8.encode(jsonEncode(backupWrapper)));
    } catch (e, st) {
      debugPrint('Google Drive export failed: $e\n$st');
      return null;
    }
  }

  static Future<BackupData?> importDataFromGoogleDrive({
    required Uint8List encryptedBytes,
    required String passphrase,
  }) async {
    try {
      final content = utf8.decode(encryptedBytes);
      final wrapper = jsonDecode(content) as Map<String, dynamic>;

      try {
        final BackupData payload = await _decryptPayload(wrapper, passphrase);
        if ((payload.version) != 1) {
          throw Exception('Unsupported backup version');
        }

        return payload;
      } on SecretBoxAuthenticationError {
        debugPrint('Decryption failed: invalid passphrase or corrupted file');
        return null;
      }
    } catch (e, st) {
      debugPrint('Google Drive import failed: $e\n$st');
      return null;
    }
  }

  // --- Google Drive Metadata Functions ---------------------------------

  /// Export metadata as encrypted bytes for uploading to Google Drive.
  /// Returns encrypted metadata bytes on success, or null on failure.
  static Future<Uint8List?> exportEncryptedMetadata({
    required String passphrase,
    BackupMetadata? metadata,
  }) async {
    try {
      metadata ??= await buildMetadata();

      final payload = <String, dynamic>{
        'version': 1,
        'metadata': metadata.toMap(),
      };

      final metadataWrapper = await _encryptPayload(payload, passphrase);
      return Uint8List.fromList(utf8.encode(jsonEncode(metadataWrapper)));
    } catch (e, st) {
      debugPrint('Google Drive metadata export failed: $e\n$st');
      return null;
    }
  }

  static Future<BackupMetadata?> _decryptMetadata({
    required Map<String, dynamic> wrapper,
    required String passphrase,
  }) async {
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
  }

  /// Import encrypted metadata from Google Drive.
  /// Returns [BackupMetadata] on success, or null on failure or wrong passphrase.
  static Future<BackupMetadata?> importMetadata({
    required Uint8List encryptedBytes,
    required String passphrase,
  }) async {
    try {
      debugPrint('Importing metadata: ${encryptedBytes.length} bytes');
      final content = utf8.decode(encryptedBytes);
      debugPrint('Decoded metadata content');
      final wrapper = jsonDecode(content) as Map<String, dynamic>;
      debugPrint('Parsed metadata wrapper: ${wrapper.keys}');

      try {
        debugPrint(
          'Attempting to decrypt metadata with passphrase length: ${passphrase.length}',
        );
        final BackupMetadata? metadata = await _decryptMetadata(
          wrapper: wrapper,
          passphrase: passphrase,
        );
        debugPrint('Metadata decryption successful');

        _logMetadata(metadata);
        return metadata;
      } on SecretBoxAuthenticationError {
        debugPrint(
          'Metadata decryption failed: invalid passphrase or corrupted file',
        );
        return null;
      }
    } catch (e, st) {
      debugPrint('Google Drive metadata import failed: $e\n$st');
      return null;
    }
  }
}

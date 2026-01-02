import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

class BackupService {
  BackupService._();

  static final _rng = Random.secure();
  static final _aes = AesGcm.with256bits();

  /// Export all Hive data (habits + days) as a single encrypted JSON file.
  /// Returns true on success.
  static Future<bool> exportData({
    required BuildContext context,
    required String passphrase,
  }) async {
    try {
      final habitsBox = Hive.box<Habit>('habits');
      final daysBox = Hive.box<Day>('days');

      final payload = <String, dynamic>{
        'version': 1,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'habits': habitsBox.values.map(_habitToMap).toList(),
        'days': daysBox.values.map(_dayToMap).toList(),
      };

      final plainBytes = utf8.encode(jsonEncode(payload));

      final salt = _randomBytes(16);
      final nonce = _randomBytes(12);
      final secretKey = await _deriveKey(passphrase, salt);

      final secretBox = await _aes.encrypt(
        plainBytes,
        secretKey: secretKey,
        nonce: nonce,
      );

      final exportJson = jsonEncode({
        'version': 1,
        'salt': base64Encode(salt),
        'nonce': base64Encode(nonce),
        'ciphertext': base64Encode(secretBox.cipherText),
        'tag': base64Encode(secretBox.mac.bytes),
      });
      final exportBytes = Uint8List.fromList(utf8.encode(exportJson));

      final savePath = await _pickSavePath(exportBytes);
      if (savePath == null) return false;

      final file = File(savePath);
      if (!await file.exists()) {
        await file.create(recursive: true);
      }
      await file.writeAsBytes(exportBytes, flush: true);
      return true;
    } catch (e, st) {
      debugPrint('Export failed: $e\n$st');
      return false;
    }
  }

  /// Import data from an encrypted file. Replaces existing box contents.
  /// Returns true on success.
  static Future<bool> importData({
    required BuildContext context,
    required String passphrase,
  }) async {
    try {
      final path = await _pickImportPath();
      if (path == null) return false;

      final file = File(path);
      if (!await file.exists()) return false;

      final content = await file.readAsString();
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

      final payload = jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
      if ((payload['version'] as int? ?? 0) != 1) {
        throw Exception('Unsupported backup version');
      }

      final habitsBox = Hive.box<Habit>('habits');
      final daysBox = Hive.box<Day>('days');

      // Clear current data
      await habitsBox.clear();
      await daysBox.clear();

      final habitsList =
          (payload['habits'] as List<dynamic>? ?? [])
              .map((e) => _habitFromMap(Map<String, dynamic>.from(e)))
              .toList();
      for (final h in habitsList) {
        await habitsBox.add(h);
      }

      final daysList =
          (payload['days'] as List<dynamic>? ?? [])
              .map((e) => _dayFromMap(Map<String, dynamic>.from(e)))
              .toList();
      for (final d in daysList) {
        await daysBox.add(d);
      }

      return true;
    } catch (e, st) {
      debugPrint('Import failed: $e\n$st');
      return false;
    }
  }

  // --- Helpers ------------------------------------------------------------

  static List<int> _randomBytes(int length) {
    return List<int>.generate(length, (_) => _rng.nextInt(256));
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

  static Map<String, dynamic> _habitToMap(Habit h) {
    return {
      'id': h.id,
      'name': h.name,
      'description': h.description,
      'iconPath': h.iconPath,
      'categoryId': h.categoryId,
      'tag': h.tag,
      'completed': h.completed,
      'skipped': h.skipped,
      'amountLabel': h.amountLabel,
      'amount': h.amount,
      'amountCompleted': h.amountCompleted,
      'duration': h.duration,
      'durationCompleted': h.durationCompleted,
      'streak': h.streak,
      'longestStreak': h.longestStreak,
      'additional': h.additional,
      'timeIntervalEnabled': h.timeIntervalEnabled,
      'timeIntervalStart': h.timeIntervalStart,
      'timeIntervalEnd': h.timeIntervalEnd,
      'colorName': h.colorName,
      'color': h.color,
    };
  }

  static Habit _habitFromMap(Map<String, dynamic> m) {
    return Habit(
      id: m['id'] as int,
      name: m['name'] as String,
      description: (m['description'] as String?) ?? '',
      iconPath: m['iconPath'] as String,
      categoryId: m['categoryId'] as int,
      amountLabel: (m['amountLabel'] as String?) ?? 'times',
      tag: (m['tag'] as String?) ?? 'No tag',
      completed: (m['completed'] as bool?) ?? false,
      skipped: (m['skipped'] as bool?) ?? false,
      amount: (m['amount'] as int?) ?? 0,
      amountCompleted: (m['amountCompleted'] as int?) ?? 0,
      duration: (m['duration'] as int?) ?? 0,
      durationCompleted: (m['durationCompleted'] as int?) ?? 0,
      streak: (m['streak'] as int?) ?? 0,
      longestStreak: (m['longestStreak'] as int?) ?? 0,
      additional: (m['additional'] as bool?) ?? false,
      timeIntervalEnabled: (m['timeIntervalEnabled'] as bool?) ?? false,
      timeIntervalStart: (m['timeIntervalStart'] as int?) ?? 420,
      timeIntervalEnd: (m['timeIntervalEnd'] as int?) ?? 450,
      colorName: m['colorName'] as String?,
    )..color = m['color'] as String?;
  }

  static Map<String, dynamic> _dayToMap(Day d) {
    return {
      'date': d.date.toIso8601String(),
      'habits': d.habits.map(_habitToMap).toList(),
    };
  }

  static Day _dayFromMap(Map<String, dynamic> m) {
    final habits =
        (m['habits'] as List<dynamic>? ?? [])
            .map((e) => _habitFromMap(Map<String, dynamic>.from(e)))
            .toList();
    return Day(date: DateTime.parse(m['date'] as String), habits: habits);
  }

  static Future<String?> _pickSavePath(Uint8List bytes) async {
    final suggestedName =
        'habitt-backup-${DateTime.now().toIso8601String().split('T').first}.habitt';
    final path = await FilePicker.platform.saveFile(
      bytes: bytes,
      dialogTitle: 'Export backup',
      fileName: suggestedName,
    );

    if (path != null) return path;

    // Fallback: save to documents directory
    final docs = await getApplicationDocumentsDirectory();
    return '${docs.path}/$suggestedName';
  }

  static Future<String?> _pickImportPath() async {
    return FilePicker.platform
        .pickFiles(dialogTitle: 'Import backup', type: FileType.any)
        .then((result) => result?.files.single.path);
  }
}

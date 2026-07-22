import 'package:habitt/models/backup_metadata.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/util/duration_seconds_migration.dart';

class BackupData {
  final int version;
  final BackupMetadata metadata;
  final List<Habit> habits;
  final List<Day> days;
  final DateTime dateJoined;

  final bool isDelta;

  // if doesnt exist in payload then its legacy minutes based habit duration
  // the number will convert to seconds for the current version of the app
  final int durationSchemaVersion;

  final bool wasUpconvertedFromLegacy;

  BackupData({
    required this.version,
    required this.metadata,
    required this.habits,
    required this.days,
    required this.dateJoined,
    this.isDelta = false,
    this.durationSchemaVersion = kDurationSecondsDataVersion,
    this.wasUpconvertedFromLegacy = false,
  });

  bool get isLegacyDurationMinutes =>
      durationSchemaVersion < kDurationSecondsDataVersion;

  Map<String, dynamic> toMap() => {
    'version': version,
    'type': isDelta ? 'delta' : 'full',
    'durationSchemaVersion': durationSchemaVersion,
    'metadata': metadata.toMap(),
    'habits': habits.map((h) => h.toMap()).toList(),
    'days': days.map((d) => d.toMap()).toList(),
    'dateJoined': dateJoined.toIso8601String(),
  };

  factory BackupData.fromMap(Map<String, dynamic> map) {
    final rawDurationVersion = (map['durationSchemaVersion'] as int?) ?? 0;

    final habits =
        (map['habits'] as List<dynamic>? ?? [])
            .map((e) => Habit.fromMap(Map<String, dynamic>.from(e)))
            .toList();
    final days =
        (map['days'] as List<dynamic>? ?? [])
            .map((e) => Day.fromMap(Map<String, dynamic>.from(e)))
            .toList();

    // duration is in MINUTES for older versions (before 88)
    // here we convert to seconds in all cases (local import, cloud download, replace, delta merge)
    // in all backup restore cases, its handled here
    if (rawDurationVersion < kDurationSecondsDataVersion) {
      for (final h in habits) {
        h.duration *= 60;
        h.durationCompleted *= 60;
      }
      for (final day in days) {
        for (final h in day.habits) {
          h.duration *= 60;
          h.durationCompleted *= 60;
        }
      }
    }

    return BackupData(
      version: map['version'] as int,
      isDelta: (map['type'] as String?) == 'delta',
      durationSchemaVersion: kDurationSecondsDataVersion,
      wasUpconvertedFromLegacy:
          rawDurationVersion < kDurationSecondsDataVersion,
      metadata: BackupMetadata.fromMap(map['metadata']),
      habits: habits,
      days: days,
      dateJoined: DateTime.parse(map['dateJoined'] as String),
    );
  }
}

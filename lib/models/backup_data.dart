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

  BackupData({
    required this.version,
    required this.metadata,
    required this.habits,
    required this.days,
    required this.dateJoined,
    this.isDelta = false,
    this.durationSchemaVersion = kDurationSecondsDataVersion,
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
    return BackupData(
      version: map['version'] as int,
      isDelta: (map['type'] as String?) == 'delta',
      durationSchemaVersion: (map['durationSchemaVersion'] as int?) ?? 0,
      metadata: BackupMetadata.fromMap(map['metadata']),
      habits:
          (map['habits'] as List<dynamic>? ?? [])
              .map((e) => Habit.fromMap(Map<String, dynamic>.from(e)))
              .toList(),
      days:
          (map['days'] as List<dynamic>? ?? [])
              .map((e) => Day.fromMap(Map<String, dynamic>.from(e)))
              .toList(),
      dateJoined: DateTime.parse(map['dateJoined'] as String),
    );
  }
}

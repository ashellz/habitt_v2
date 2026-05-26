import 'package:habitt/models/backup_metadata.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';

class BackupData {
  final int version;
  final BackupMetadata metadata;
  final List<Habit> habits;
  final List<Day> days;
  final DateTime dateJoined;

  /// True when this payload is a delta (only changed entities since the last
  /// sync) rather than a full database snapshot. The merge logic is identical
  /// for both — absent entities are simply not touched.
  final bool isDelta;

  BackupData({
    required this.version,
    required this.metadata,
    required this.habits,
    required this.days,
    required this.dateJoined,
    this.isDelta = false,
  });

  Map<String, dynamic> toMap() => {
    'version': version,
    'type': isDelta ? 'delta' : 'full',
    'metadata': metadata.toMap(),
    'habits': habits.map((h) => h.toMap()).toList(),
    'days': days.map((d) => d.toMap()).toList(),
    'dateJoined': dateJoined.toIso8601String(),
  };

  factory BackupData.fromMap(Map<String, dynamic> map) {
    return BackupData(
      version: map['version'] as int,
      isDelta: (map['type'] as String?) == 'delta',
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

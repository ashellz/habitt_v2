import 'package:habitt/models/backup_metadata.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';

class BackupData {
  final int version;
  final BackupMetadata metadata;
  final List<Habit> habits;
  final List<Day> days;

  BackupData({
    required this.version,
    required this.metadata,
    required this.habits,
    required this.days,
  });

  Map<String, dynamic> toMap() => {
    'version': version,
    'metadata': metadata.toMap(),
    'habits': habits.map((h) => h.toMap()).toList(),
    'days': days.map((d) => d.toMap()).toList(),
  };

  factory BackupData.fromMap(Map<String, dynamic> map) {
    return BackupData(
      version: map['version'] as int,
      metadata: BackupMetadata.fromMap(map['metadata']),
      habits:
          (map['habits'] as List<dynamic>? ?? [])
              .map((e) => Habit.fromMap(Map<String, dynamic>.from(e)))
              .toList(),
      days:
          (map['days'] as List<dynamic>? ?? [])
              .map((e) => Day.fromMap(Map<String, dynamic>.from(e)))
              .toList(),
    );
  }
}

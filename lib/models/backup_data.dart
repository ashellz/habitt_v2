import 'package:habitt/models/backup_metadata.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:hive_ce/hive.dart';

class BackupData {
  final int version;
  final BackupMetadata metadata;
  final Box<Habit> habits;
  final Box<Day> days;

  BackupData({
    required this.version,
    required this.metadata,
    required this.habits,
    required this.days,
  });

  Map<String, dynamic> toMap() => {
    'version': version,
    'metadata': metadata.toMap(),
    'habits': habits.values.map((h) => h.toMap()).toList(),
    'days': days.values.map((d) => d.toMap()).toList(),
  };

  factory BackupData.fromMap(Map<String, dynamic> map) {
    return BackupData(
      version: map['version'] as int,
      metadata: BackupMetadata.fromMap(map['metadata']),
      habits: Hive.box<Habit>('habits'),
      days: Hive.box<Day>('days'),
    );
  }
}

import 'package:habitt/models/health_workout_type.dart';

/// One individual Health session in a day linked to a habit
/// such as a single workout, or a single sleep session
/// [workoutType] is null for sleep sessions, calories...
class HealthSessionDetail {
  final DateTime start;
  final DateTime end;
  final HealthWorkoutType? workoutType;

  HealthSessionDetail({
    required this.start,
    required this.end,
    this.workoutType,
  });

  Duration get duration => end.difference(start);

  HealthSessionDetail copy() {
    return HealthSessionDetail(
      start: start,
      end: end,
      workoutType: workoutType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'workoutType': workoutType?.name,
    };
  }

  factory HealthSessionDetail.fromMap(Map<String, dynamic> map) {
    return HealthSessionDetail(
      start:
          DateTime.tryParse(map['start']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      end:
          DateTime.tryParse(map['end']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      workoutType: _parseWorkoutType(map['workoutType']?.toString()),
    );
  }

  static HealthWorkoutType? _parseWorkoutType(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final type in HealthWorkoutType.values) {
      if (type.name == value) return type;
    }
    return null;
  }
}

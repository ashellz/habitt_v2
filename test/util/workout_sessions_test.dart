import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/health_session_detail.dart';
import 'package:habitt/models/health_workout_type.dart';
import 'package:habitt/util/workout_sessions.dart';

HealthSessionDetail _workout(
  int startMinute,
  int endMinute, [
  HealthWorkoutType? type,
]) => HealthSessionDetail(
  start: DateTime(2026, 9, 14, 7, startMinute),
  end: DateTime(2026, 9, 14, 7, endMinute),
  workoutType: type,
);

void main() {
  group('dedupOverlappingSessions', () {
    test('folds the same workout recorded by two sources into one', () {
      final sessions = dedupOverlappingSessions([
        _workout(0, 30, HealthWorkoutType.running),
        _workout(1, 29, HealthWorkoutType.running),
      ]);

      expect(sessions, hasLength(1));
      expect(sessions.single.start, DateTime(2026, 9, 14, 7, 0));
      expect(sessions.single.end, DateTime(2026, 9, 14, 7, 30));
      expect(sessions.single.duration, const Duration(minutes: 30));
    });

    test('keeps back-to-back workouts separate', () {
      final sessions = dedupOverlappingSessions([
        _workout(0, 30, HealthWorkoutType.running),
        _workout(30, 40, HealthWorkoutType.walking),
      ]);

      expect(sessions, hasLength(2));
      expect(sessions[0].workoutType, HealthWorkoutType.running);
      expect(sessions[1].workoutType, HealthWorkoutType.walking);
    });

    test('keeps workouts with a gap between them separate', () {
      final sessions = dedupOverlappingSessions([
        _workout(0, 10),
        _workout(20, 30),
      ]);

      expect(sessions, hasLength(2));
    });

    test('takes the type of the longest record when sources disagree', () {
      final sessions = dedupOverlappingSessions([
        _workout(0, 5, HealthWorkoutType.walking),
        _workout(0, 30, HealthWorkoutType.running),
      ]);

      expect(sessions, hasLength(1));
      expect(sessions.single.workoutType, HealthWorkoutType.running);
    });

    test('chains records that overlap one after another', () {
      final sessions = dedupOverlappingSessions([
        _workout(0, 10),
        _workout(8, 20),
        _workout(18, 30),
      ]);

      expect(sessions, hasLength(1));
      expect(sessions.single.end, DateTime(2026, 9, 14, 7, 30));
    });

    test('sorts unordered input', () {
      final sessions = dedupOverlappingSessions([
        _workout(30, 40),
        _workout(0, 10),
      ]);

      expect(sessions.map((s) => s.start.minute), [0, 30]);
    });

    test('drops empty records and returns nothing for no input', () {
      expect(dedupOverlappingSessions(const []), isEmpty);
      expect(dedupOverlappingSessions([_workout(5, 5)]), isEmpty);
    });
  });
}

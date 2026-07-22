import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/backup_data.dart';
import 'package:habitt/models/backup_metadata.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/util/duration_seconds_migration.dart';

import '../fixtures/habit_factory.dart';

BackupMetadata _meta() => BackupMetadata(
      deviceId: 'test-device',
      model: 'test',
      os: 'test',
      createdAt: DateTime.utc(2026, 7, 18),
    );

void main() {
  test('new BackupData defaults to the seconds schema version', () {
    final data = BackupData(
      version: 3,
      metadata: _meta(),
      habits: const [],
      days: const [],
      dateJoined: DateTime.utc(2026, 1, 1),
    );

    expect(data.durationSchemaVersion, kDurationSecondsDataVersion);
    expect(data.isLegacyDurationMinutes, isFalse);
    expect(data.toMap()['durationSchemaVersion'], kDurationSecondsDataVersion);
  });

  test('legacy payload (no durationSchemaVersion) upconverts minutes → seconds',
      () {
    final legacyHabit = buildTestHabit(
      id: 3,
      duration: 10, // minutes on a legacy payload
      durationCompleted: 3,
      trackingType: HabitTrackingType.duration,
    );
    final map = {
      'version': 3,
      'type': 'delta',
      // durationSchemaVersion intentionally absent ⇒ legacy minutes.
      'metadata': _meta().toMap(),
      'habits': <dynamic>[legacyHabit.toMap()],
      'days': <dynamic>[],
      'dateJoined': DateTime.utc(2026, 1, 1).toIso8601String(),
    };

    final parsed = BackupData.fromMap(map);

    // Values are upconverted, and the object now reports the seconds-era version.
    expect(parsed.habits.single.duration, 600);
    expect(parsed.habits.single.durationCompleted, 180);
    expect(parsed.durationSchemaVersion, kDurationSecondsDataVersion);
    expect(parsed.isLegacyDurationMinutes, isFalse);
  });

  test('seconds-era payload round-trips as non-legacy', () {
    final original = BackupData(
      version: 2,
      metadata: _meta(),
      habits: const [],
      days: const [],
      dateJoined: DateTime.utc(2026, 1, 1),
    );

    final parsed = BackupData.fromMap(original.toMap());
    expect(parsed.isLegacyDurationMinutes, isFalse);
    expect(parsed.durationSchemaVersion, kDurationSecondsDataVersion);
  });
}

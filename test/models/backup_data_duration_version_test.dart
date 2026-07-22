import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/backup_data.dart';
import 'package:habitt/models/backup_metadata.dart';
import 'package:habitt/util/duration_seconds_migration.dart';

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

  test('payload without durationSchemaVersion is treated as legacy minutes',
      () {
    final map = {
      'version': 3,
      'type': 'delta',
      'metadata': _meta().toMap(),
      'habits': <dynamic>[],
      'days': <dynamic>[],
      'dateJoined': DateTime.utc(2026, 1, 1).toIso8601String(),
    };

    final parsed = BackupData.fromMap(map);
    expect(parsed.durationSchemaVersion, 0);
    expect(parsed.isLegacyDurationMinutes, isTrue);
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

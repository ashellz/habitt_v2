import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/backup_data.dart';
import 'package:habitt/models/backup_metadata.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/sync_device.dart';

final _now = DateTime.utc(2026, 11, 2, 12);

DateTime _daysAgo(int days) => _now.subtract(Duration(days: days));

SyncDevice _device(
  String id, {
  int installedDaysAgo = 100,
  int seenDaysAgo = 0,
  String model = 'Phone',
  String os = 'Android 16',
  String platform = 'android',
  bool? healthAvailable,
}) => SyncDevice(
  id: id,
  model: model,
  os: os,
  platform: platform,
  firstSeen: _daysAgo(installedDaysAgo),
  lastSeen: _daysAgo(seenDaysAgo),
  healthAvailable: healthAvailable,
);

void main() {
  group('Health source', () {
    test('a single device is not a choice', () {
      final list = SyncDeviceList.empty.withDevice(_device('a'));
      expect(list.isMultiDevice, isFalse);
      expect(list.healthSourceId, 'a');
    });

    test('defaults to the device that has had the app longest', () {
      final list = SyncDeviceList.empty
          .withDevice(_device('new', installedDaysAgo: 3))
          .withDevice(_device('old', installedDaysAgo: 400));
      expect(list.isMultiDevice, isTrue);
      expect(list.healthSourceId, 'old');
    });

    test('a tie on install time is broken by id, the same on every device', () {
      final list = SyncDeviceList.empty
          .withDevice(_device('b', installedDaysAgo: 5))
          .withDevice(_device('a', installedDaysAgo: 5));
      expect(list.healthSourceId, 'a');
    });

    test('a pick beats the default', () {
      final list = SyncDeviceList.empty
          .withDevice(_device('old', installedDaysAgo: 400))
          .withDevice(_device('new', installedDaysAgo: 3))
          .withHealthSource(
            HealthSourceChoice(deviceId: 'new', changedAt: _now),
          );
      expect(list.healthSourceId, 'new');
    });

    test('a pick of a device that is not listed falls back to the default', () {
      final list = SyncDeviceList.empty
          .withDevice(_device('old', installedDaysAgo: 400))
          .withDevice(_device('new', installedDaysAgo: 3))
          .withHealthSource(
            HealthSourceChoice(deviceId: 'gone', changedAt: _now),
          );
      expect(list.healthSourceId, 'old');
    });
  });

  group('merge', () {
    test('the latest pick wins, whichever side has it', () {
      final ours = SyncDeviceList.empty.withHealthSource(
        HealthSourceChoice(deviceId: 'a', changedAt: _daysAgo(1)),
      );
      final theirs = SyncDeviceList.empty.withHealthSource(
        HealthSourceChoice(deviceId: 'b', changedAt: _now),
      );
      expect(ours.mergedWith(theirs).healthSource!.deviceId, 'b');
      expect(theirs.mergedWith(ours).healthSource!.deviceId, 'b');
    });

    test('a device keeps its fresher name and its earliest install time', () {
      final stale = _device(
        'a',
        installedDaysAgo: 300,
        seenDaysAgo: 5,
        os: 'iOS 26.5',
        platform: 'ios',
      );
      final fresh = _device(
        'a',
        installedDaysAgo: 2,
        seenDaysAgo: 0,
        os: 'iOS 26.6',
        platform: 'ios',
      );
      final merged =
          SyncDeviceList.empty
              .withDevice(stale)
              .mergedWith(SyncDeviceList.empty.withDevice(fresh))
              .devices['a']!;
      expect(merged.os, 'iOS 26.6');
      expect(merged.lastSeen, fresh.lastSeen);
      expect(merged.firstSeen, stale.firstSeen);
    });

    test('devices from both sides are kept', () {
      final merged = SyncDeviceList.empty
          .withDevice(_device('a'))
          .mergedWith(SyncDeviceList.empty.withDevice(_device('b')));
      expect(merged.devices.keys, unorderedEquals(['a', 'b']));
    });
  });

  group('pruning', () {
    test('drops devices not seen for the active window', () {
      final list = SyncDeviceList.empty
          .withDevice(_device('recent', seenDaysAgo: 3))
          .withDevice(_device('old', seenDaysAgo: kSyncDeviceActiveDays + 1));
      expect(list.pruned(_now).devices.keys, ['recent']);
    });

    test('keeps a stale device that is the picked Health source', () {
      final list = SyncDeviceList.empty
          .withDevice(_device('recent', seenDaysAgo: 3))
          .withDevice(_device('old', seenDaysAgo: kSyncDeviceActiveDays + 1))
          .withHealthSource(
            HealthSourceChoice(deviceId: 'old', changedAt: _now),
          );
      expect(
        list.pruned(_now).devices.keys,
        unorderedEquals(['recent', 'old']),
      );
    });
  });

  group('serialization', () {
    test('round-trips through a map', () {
      final list = SyncDeviceList.empty
          .withDevice(_device('a', model: 'iPhone 17', os: 'iOS 26.6'))
          .withDevice(_device('b'))
          .withHealthSource(HealthSourceChoice(deviceId: 'a', changedAt: _now));
      final parsed = SyncDeviceList.fromMap(list.toMap());
      expect(parsed.toMap(), list.toMap());
      expect(parsed.devices['a']!.displayName, 'iPhone 17 · iOS 26.6');
    });

    test('skips malformed entries instead of failing', () {
      final parsed = SyncDeviceList.fromMap({
        'devices': [
          {'id': 'ok', 'firstSeen': '2026-01-01', 'lastSeen': '2026-11-01'},
          {'id': 'no-dates'},
          'nonsense',
        ],
        'healthSource': {'deviceId': 'ok'},
      });
      expect(parsed.devices.keys, ['ok']);
      expect(parsed.healthSource, isNull);
      expect(SyncDeviceList.fromMap(null).devices, isEmpty);
    });

    test('a device from an older app version is listed from its metadata', () {
      final device = SyncDevice.fromLegacyMetadata(
        BackupMetadata(
          deviceId: 'legacy',
          model: 'iPhone18,3',
          os: 'iOS 26.1',
          createdAt: _now,
        ),
      );
      expect(device.isIos, isTrue);
      expect(device.lastSeen, _now);
    });

    test('BackupData carries the list and reads its absence as null', () {
      final metadata = BackupMetadata(
        deviceId: 'a',
        model: 'Phone',
        os: 'Android 16',
        createdAt: _now,
      );
      final withDevices = BackupData(
        version: 3,
        metadata: metadata,
        habits: const [],
        days: const [],
        dateJoined: _now,
        devices: SyncDeviceList.empty.withDevice(_device('a')),
      );
      final parsed = BackupData.fromMap(withDevices.toMap());
      expect(parsed.devices!.devices.keys, ['a']);

      final without = BackupData(
        version: 3,
        metadata: metadata,
        habits: const [],
        days: const [],
        dateJoined: _now,
      );
      expect(BackupData.fromMap(without.toMap()).devices, isNull);
    });
  });

  group('Health availability flag', () {
    test('an entry without the flag (older app version) is unknown', () {
      final parsed =
          SyncDevice.fromMap({
            'id': 'a',
            'model': 'Phone',
            'os': 'Android 16',
            'platform': 'android',
            'firstSeen': '2026-01-01T00:00:00Z',
            'lastSeen': '2026-11-01T00:00:00Z',
          })!;
      expect(parsed.healthAvailable, isNull);
      expect(parsed.canReadHealth, isTrue);
      // and it is written back without the flag, exactly as it came
      expect(parsed.toMap().containsKey('healthAvailable'), isFalse);
    });

    test('round-trips true and false', () {
      for (final value in [true, false]) {
        final device = _device('a', healthAvailable: value);
        final parsed = SyncDevice.fromMap(device.toMap())!;
        expect(parsed.healthAvailable, value);
        expect(parsed.toMap(), device.toMap());
      }
    });

    test('a malformed flag reads as unknown instead of failing', () {
      final raw = _device('a').toMap()..['healthAvailable'] = 'yes';
      expect(SyncDevice.fromMap(raw)!.healthAvailable, isNull);
    });

    test('older app versions keep the rest of the list readable', () {
      // the new key sits next to the old ones, so the old parser, which only
      // reads the keys it knows, still finds every device
      final map =
          SyncDeviceList.empty
              .withDevice(_device('a', healthAvailable: false))
              .withDevice(_device('b', healthAvailable: true))
              .toMap();
      final parsed = SyncDeviceList.fromMap(map);
      expect(parsed.devices.keys, unorderedEquals(['a', 'b']));
      expect(parsed.devices['a']!.healthAvailable, isFalse);
    });

    test('the fresher entry gives the flag', () {
      final stale = _device('a', seenDaysAgo: 5, healthAvailable: false);
      final fresh = _device('a', seenDaysAgo: 0, healthAvailable: true);
      expect(stale.mergedWith(fresh).healthAvailable, isTrue);
      expect(fresh.mergedWith(stale).healthAvailable, isTrue);
    });

    test('a fresher entry without the flag keeps the known one', () {
      final known = _device('a', seenDaysAgo: 5, healthAvailable: false);
      final legacy = _device('a', seenDaysAgo: 0);
      expect(known.mergedWith(legacy).healthAvailable, isFalse);
      expect(legacy.mergedWith(known).healthAvailable, isFalse);
      expect(
        known.mergedWith(legacy).lastSeen,
        legacy.lastSeen,
        reason: 'the rest still comes from the fresher entry',
      );
    });

    test('merging lists keeps the flag', () {
      final merged = SyncDeviceList.empty
          .withDevice(_device('a'))
          .mergedWith(
            SyncDeviceList.empty.withDevice(
              _device('a', seenDaysAgo: 0, healthAvailable: false),
            ),
          );
      expect(merged.devices['a']!.healthAvailable, isFalse);
    });

    test('the default reader skips a device without Health', () {
      final list = SyncDeviceList.empty
          .withDevice(
            _device('old', installedDaysAgo: 400, healthAvailable: false),
          )
          .withDevice(_device('new', installedDaysAgo: 3));
      expect(list.healthSourceId, 'new');
    });

    test('with no device able to read, the oldest still is the default', () {
      final list = SyncDeviceList.empty
          .withDevice(
            _device('old', installedDaysAgo: 400, healthAvailable: false),
          )
          .withDevice(
            _device('new', installedDaysAgo: 3, healthAvailable: false),
          );
      expect(list.healthSourceId, 'old');
    });

    test('a pick still wins over the flag', () {
      final list = SyncDeviceList.empty
          .withDevice(_device('old', installedDaysAgo: 400))
          .withDevice(
            _device('new', installedDaysAgo: 3, healthAvailable: false),
          )
          .withHealthSource(
            HealthSourceChoice(deviceId: 'new', changedAt: _now),
          );
      expect(list.healthSourceId, 'new');
    });

    test('an Android phone cannot read the iOS-only metrics', () {
      final android = _device('a');
      final iphone = _device('b', platform: 'ios', os: 'iOS 26.6');
      expect(android.canReadMetric(HealthMetricType.mindfulness), isFalse);
      expect(android.canReadMetric(HealthMetricType.activity), isFalse);
      expect(android.canReadMetric(HealthMetricType.steps), isTrue);
      expect(iphone.canReadMetric(HealthMetricType.activity), isTrue);
      expect(
        _device(
          'c',
          healthAvailable: false,
        ).canReadMetric(HealthMetricType.steps),
        isFalse,
      );
    });
  });
}

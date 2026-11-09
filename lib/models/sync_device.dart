import 'package:habitt/models/backup_metadata.dart';
import 'package:habitt/models/health_metric_type.dart';

/// Devices not seen for this long are dropped from the list (unless one is
/// the chosen Health device), so reinstalls and old phones don't pile up.
const int kSyncDeviceActiveDays = 60;

/// One install syncing this account through Google Drive. Each device writes
/// its own entry into every backup it uploads; the others learn it from there.
class SyncDevice {
  const SyncDevice({
    required this.id,
    required this.model,
    required this.os,
    required this.platform,
    required this.firstSeen,
    required this.lastSeen,
    this.healthAvailable,
  });

  final String id;

  // "iPhone 17", "Samsung SM-S921B"
  final String model;

  // "iOS 26.6", "Android 16"
  final String os;

  // 'ios', 'android' or another Platform.operatingSystem value
  final String platform;

  // app install time on that device, which makes the default Health device
  // the one the user had first
  final DateTime firstSeen;

  // the last time the device uploaded its entry (refreshed about once a day)
  final DateTime lastSeen;

  // whether Health can be read on that device (HealthKit, or Health Connect
  // installed). Null when unknown: older app versions don't send it, and an
  // unknown device counts as able to read
  final bool? healthAvailable;

  String get displayName => os.isEmpty ? model : '$model · $os';

  bool get isIos => platform == 'ios';

  /// Whether this device can be the one that reads Health: a phone whose
  /// Health store isn't known to be missing.
  bool get canReadHealth =>
      (platform == 'ios' || platform == 'android') && healthAvailable != false;

  /// Whether this device's Health store has [metric] at all (Health Connect
  /// has no record for the iOS-only ones).
  bool canReadMetric(HealthMetricType metric) =>
      canReadHealth && (isIos || !metric.isIosOnly);

  /// Same device seen through two payloads: the fresher one has the current
  /// name and OS, the earliest first-seen is the real one.
  SyncDevice mergedWith(SyncDevice other) {
    final newer = other.lastSeen.isAfter(lastSeen) ? other : this;
    return SyncDevice(
      id: id,
      model: newer.model,
      os: newer.os,
      platform: newer.platform,
      firstSeen:
          other.firstSeen.isBefore(firstSeen) ? other.firstSeen : firstSeen,
      lastSeen: newer.lastSeen,
      // an entry from an older app version has no flag; keep the known one
      healthAvailable:
          newer.healthAvailable ??
          (identical(newer, this) ? other : this).healthAvailable,
    );
  }

  /// A device on an app version from before the device list only sends its
  /// backup metadata. Listing it still lets the user pick another device as
  /// the Health source, and the old device keeps reading Health either way.
  factory SyncDevice.fromLegacyMetadata(BackupMetadata metadata) {
    final os = metadata.os == 'unknown' ? '' : metadata.os;
    return SyncDevice(
      id: metadata.deviceId,
      model: metadata.model,
      os: os,
      platform:
          os.startsWith('iOS')
              ? 'ios'
              : os.startsWith('Android')
              ? 'android'
              : '',
      firstSeen: metadata.createdAt,
      lastSeen: metadata.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'model': model,
    'os': os,
    'platform': platform,
    'firstSeen': firstSeen.toUtc().toIso8601String(),
    'lastSeen': lastSeen.toUtc().toIso8601String(),
    // left out while unknown, exactly like an older app version's entry
    if (healthAvailable != null) 'healthAvailable': healthAvailable,
  };

  static SyncDevice? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final firstSeen = DateTime.tryParse(raw['firstSeen']?.toString() ?? '');
    final lastSeen = DateTime.tryParse(raw['lastSeen']?.toString() ?? '');
    if (id is! String || id.isEmpty || firstSeen == null || lastSeen == null) {
      return null;
    }
    return SyncDevice(
      id: id,
      model: raw['model']?.toString() ?? '',
      os: raw['os']?.toString() ?? '',
      platform: raw['platform']?.toString() ?? '',
      firstSeen: firstSeen,
      lastSeen: lastSeen,
      healthAvailable:
          raw['healthAvailable'] is bool
              ? raw['healthAvailable'] as bool
              : null,
    );
  }
}

/// The device the user picked to read Health. The latest pick wins a merge.
class HealthSourceChoice {
  const HealthSourceChoice({required this.deviceId, required this.changedAt});

  final String deviceId;
  final DateTime changedAt;

  Map<String, dynamic> toMap() => {
    'deviceId': deviceId,
    'changedAt': changedAt.toUtc().toIso8601String(),
  };

  static HealthSourceChoice? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['deviceId'];
    final changedAt = DateTime.tryParse(raw['changedAt']?.toString() ?? '');
    if (id is! String || id.isEmpty || changedAt == null) return null;
    return HealthSourceChoice(deviceId: id, changedAt: changedAt);
  }
}

/// Every device syncing this account plus the Health device choice. Travels
/// inside full and delta backups (Google Drive only), merged like the rest.
class SyncDeviceList {
  const SyncDeviceList({this.devices = const {}, this.healthSource});

  static const empty = SyncDeviceList();

  final Map<String, SyncDevice> devices;
  final HealthSourceChoice? healthSource;

  /// Only with two or more devices is there anything to choose.
  bool get isMultiDevice => devices.length >= 2;

  /// The device that reads Health: the user's pick while it's still listed,
  /// otherwise the device that has had the app longest, skipping devices
  /// known to have no Health store (all of them count when none has one). Every device computes the same
  /// answer from the same list, so they agree without coordinating.
  String? get healthSourceId {
    final picked = healthSource?.deviceId;
    if (picked != null && devices.containsKey(picked)) return picked;
    final sorted = sortedDevices;
    return (sorted.where((d) => d.healthAvailable != false).firstOrNull ??
            sorted.firstOrNull)
        ?.id;
  }

  /// Oldest install first, by id on a tie so every device sorts the same.
  List<SyncDevice> get sortedDevices =>
      devices.values.toList()..sort((a, b) {
        final byAge = a.firstSeen.compareTo(b.firstSeen);
        return byAge != 0 ? byAge : a.id.compareTo(b.id);
      });

  SyncDeviceList withDevice(SyncDevice device) {
    final existing = devices[device.id];
    return SyncDeviceList(
      devices: {
        ...devices,
        device.id: existing == null ? device : existing.mergedWith(device),
      },
      healthSource: healthSource,
    );
  }

  SyncDeviceList withHealthSource(HealthSourceChoice choice) =>
      SyncDeviceList(devices: devices, healthSource: choice);

  SyncDeviceList mergedWith(SyncDeviceList other) {
    var merged = this;
    for (final device in other.devices.values) {
      merged = merged.withDevice(device);
    }
    final theirs = other.healthSource;
    final ours = healthSource;
    if (theirs != null &&
        (ours == null || theirs.changedAt.isAfter(ours.changedAt))) {
      merged = merged.withHealthSource(theirs);
    }
    return merged;
  }

  /// Drops devices not seen for [kSyncDeviceActiveDays], except the picked
  /// Health device: dropping it would quietly hand Health to another device.
  SyncDeviceList pruned(DateTime now) {
    final cutoff = now.subtract(const Duration(days: kSyncDeviceActiveDays));
    final kept = {
      for (final e in devices.entries)
        if (e.value.lastSeen.isAfter(cutoff) || e.key == healthSource?.deviceId)
          e.key: e.value,
    };
    if (kept.length == devices.length) return this;
    return SyncDeviceList(devices: kept, healthSource: healthSource);
  }

  Map<String, dynamic> toMap() => {
    'devices': devices.values.map((d) => d.toMap()).toList(),
    if (healthSource != null) 'healthSource': healthSource!.toMap(),
  };

  static SyncDeviceList fromMap(Object? raw) {
    if (raw is! Map) return empty;
    final list = raw['devices'];
    final devices = <String, SyncDevice>{};
    if (list is List) {
      for (final item in list) {
        final device = SyncDevice.fromMap(item);
        if (device != null) devices[device.id] = device;
      }
    }
    return SyncDeviceList(
      devices: devices,
      healthSource: HealthSourceChoice.fromMap(raw['healthSource']),
    );
  }
}

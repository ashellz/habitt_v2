import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceIdentity {
  static const _storage = FlutterSecureStorage();
  static const _key = 'installation_id';
  static final _uuid = Uuid();

  /// Stable per-installation ID (survives app restarts; on iOS often survives reinstall).
  static Future<String> getOrCreateId() async {
    final existing = await _storage.read(key: _key);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _uuid.v4();
    await _storage.write(key: _key, value: id);
    return id;
  }

  /// Human-friendly metadata. `name` is what a person calls the device
  /// ("iPhone 17", "Samsung SM-S921B"), shown in the Health device picker.
  static Future<Map<String, String>> deviceInfo() async {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final a = await info.androidInfo;
      return {
        'model': a.model,
        'manufacturer': a.manufacturer,
        'name': _androidName(a.manufacturer, a.model),
        'os': 'Android ${a.version.release}',
      };
    }
    if (Platform.isIOS) {
      final i = await info.iosInfo;
      return {
        'model': i.utsname.machine,
        'name': i.modelName,
        'os': 'iOS ${i.systemVersion}',
      };
    }
    if (Platform.isLinux) {
      final l = await info.linuxInfo;
      return {'model': l.prettyName, 'os': l.version ?? 'Linux'};
    }
    if (Platform.isMacOS) {
      final m = await info.macOsInfo;
      return {'model': m.model, 'os': 'macOS ${m.osRelease}'};
    }
    if (Platform.isWindows) {
      final w = await info.windowsInfo;
      return {'model': w.computerName, 'os': 'Windows ${w.displayVersion}'};
    }
    return {'model': 'unknown', 'os': 'unknown'};
  }

  // "samsung" + "SM-S921B" -> "Samsung SM-S921B"; "Google" + "Pixel 9" stays
  // "Google Pixel 9", but a model that already names the maker isn't doubled
  static String _androidName(String manufacturer, String model) {
    if (manufacturer.isEmpty) return model;
    if (model.toLowerCase().startsWith(manufacturer.toLowerCase())) {
      return model;
    }
    final maker = manufacturer[0].toUpperCase() + manufacturer.substring(1);
    return '$maker $model';
  }
}

class BackupMetadata {
  final String deviceId;
  final String model;
  final String os;
  final DateTime createdAt;

  BackupMetadata({
    required this.deviceId,
    required this.model,
    required this.os,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'model': model,
      'os': os,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BackupMetadata.fromMap(Map<String, dynamic> m) {
    return BackupMetadata(
      deviceId: (m['deviceId'] as String?) ?? '',
      model: (m['model'] as String?) ?? 'unknown',
      os: (m['os'] as String?) ?? 'unknown',
      createdAt:
          DateTime.tryParse(m['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

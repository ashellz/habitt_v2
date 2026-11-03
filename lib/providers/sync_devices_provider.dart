import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:habitt/models/backup_metadata.dart';
import 'package:habitt/models/sync_device.dart';
import 'package:habitt/util/health_source_name.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kDevicesKey = 'syncDevices';
const String _kChangedAtKey = 'syncDevicesChangedAt';

// if device didnt upload anything for this long
// it will upload its entry again to refresh despite no changes
const Duration _kSelfRefreshInterval = Duration(hours: 20);

// shows devices from gdrive and which one reads its health data
// filled only by drive syncs and cleared on sign-out
class SyncDevicesProvider extends ChangeNotifier {
  SyncDevicesProvider({@visibleForTesting String? selfId}) : _selfId = selfId;

  SyncDeviceList _list = SyncDeviceList.empty;
  String? _selfId;

  // when this device last changed the list itself (its own entry or the
  // Health pick): a delta is uploaded for it even with no habit changes
  DateTime? _changedAt;

  Future<void>? _loading;
  Future<({String name, String os, DateTime? installedAt})>? _selfInfo;

  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    try {
      _selfId ??= await DeviceIdentity.getOrCreateId();
    } catch (_) {
      // without an id this device can't tell which entry is its own, so it
      // keeps reading Health itself (see readsHealthHere)
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kDevicesKey);
      if (raw != null) _list = SyncDeviceList.fromMap(jsonDecode(raw));
      final ms = prefs.getInt(_kChangedAtKey);
      if (ms != null) _changedAt = DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      // an unreadable list starts empty and refills on the next sync
    }
    notifyListeners();
  }

  String? get selfId => _selfId;

  static bool get _canReadHealth =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  /// The Health device choice only exists with two or more devices.
  bool get isMultiDevice => _list.isMultiDevice;

  /// Oldest install first.
  List<SyncDevice> get devices => _list.sortedDevices;

  SyncDevice? get healthSource => _list.devices[_list.healthSourceId];

  /// Whether this device reads Health into its habits. Every other device
  /// only gets the values through sync, so two Health stores never fight.
  bool get readsHealthHere =>
      !isMultiDevice || _selfId == null || _list.healthSourceId == _selfId;

  /// The platform whose Health store the habits' values come from: this
  /// device's own, or the chosen device's when another device reads Health.
  String get healthPlatform {
    final source = healthSource;
    if (readsHealthHere || source == null || source.platform.isEmpty) {
      return Platform.operatingSystem;
    }
    return source.platform;
  }

  /// "Apple Health" or "Health Connect", for [healthPlatform].
  String get healthBrand => healthSourceNameFor(healthPlatform);

  // ─── Health device pick ───────────────────────────────

  Future<void> setHealthSource(String deviceId) async {
    if (_list.healthSourceId == deviceId) return;
    final now = DateTime.now().toUtc();
    _list = _list.withHealthSource(
      HealthSourceChoice(deviceId: deviceId, changedAt: now),
    );
    _changedAt = now;
    await _save();
    notifyListeners();
  }

  // ─── Backup hooks (Google Drive only) ─────────────────

  /// The list to upload, with this device's own entry refreshed first when
  /// it's missing, about a day old, or its name or OS changed. Only devices
  /// that can read Health list themselves; web and desktop just pass it on.
  Future<SyncDeviceList> listForUpload() async {
    await ensureLoaded();
    final selfId = _selfId;
    if (selfId == null || !_canReadHealth) return _list;

    final info = await (_selfInfo ??= _readSelfInfo());
    final now = DateTime.now().toUtc();
    final current = _list.devices[selfId];
    final isFresh =
        current != null &&
        current.model == info.name &&
        current.os == info.os &&
        now.difference(current.lastSeen) < _kSelfRefreshInterval;
    if (isFresh) return _list;

    _list = _list
        .withDevice(
          SyncDevice(
            id: selfId,
            model: info.name,
            os: info.os,
            platform: Platform.operatingSystem,
            firstSeen: info.installedAt ?? now,
            lastSeen: now,
          ),
        )
        .pruned(now);
    _changedAt = now;
    await _save();
    notifyListeners();
    return _list;
  }

  /// Whether this device changed the list after [time] (the last sync), so
  /// it has to be uploaded even when no habit changed.
  bool changedSince(DateTime time) =>
      _changedAt != null && _changedAt!.isAfter(time);

  /// Folds in the list from a downloaded backup or delta. A payload without
  /// one comes from an older app version: its device is listed from the
  /// backup's metadata instead.
  Future<void> mergeIncoming(
    SyncDeviceList? incoming,
    BackupMetadata metadata,
  ) async {
    await ensureLoaded();
    var theirs = incoming;
    if (theirs == null) {
      final legacy = SyncDevice.fromLegacyMetadata(metadata);
      // web and desktop can't read Health, so they're never a candidate
      final canReadHealth =
          legacy.platform == 'ios' || legacy.platform == 'android';
      theirs =
          metadata.deviceId.isNotEmpty && canReadHealth
              ? SyncDeviceList.empty.withDevice(legacy)
              : SyncDeviceList.empty;
    }
    final merged = _list.mergedWith(theirs).pruned(DateTime.now());
    if (jsonEncode(merged.toMap()) == jsonEncode(_list.toMap())) return;
    _list = merged;
    await _save();
    notifyListeners();
  }

  /// Drive sync stopped (sign-out, disconnect, iCloud instead): this device
  /// is on its own again and reads Health itself.
  Future<void> clear() async {
    await ensureLoaded();
    if (_list.devices.isEmpty && _changedAt == null) return;
    _list = SyncDeviceList.empty;
    _changedAt = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kDevicesKey);
      await prefs.remove(_kChangedAtKey);
    } catch (_) {
      // a leftover list is replaced by the next Drive sync anyway
    }
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kDevicesKey, jsonEncode(_list.toMap()));
      if (_changedAt != null) {
        await prefs.setInt(_kChangedAtKey, _changedAt!.millisecondsSinceEpoch);
      }
    } catch (_) {
      // the in-memory list still holds; it's saved again on the next change
    }
  }

  Future<({String name, String os, DateTime? installedAt})>
  _readSelfInfo() async {
    final info = await DeviceIdentity.deviceInfo();
    DateTime? installedAt;
    try {
      installedAt = (await PackageInfo.fromPlatform()).installTime?.toUtc();
    } catch (_) {
      // without an install time the device counts as new from today
    }
    return (
      name: info['name'] ?? info['model'] ?? '',
      os: info['os'] == 'unknown' ? '' : info['os'] ?? '',
      installedAt: installedAt,
    );
  }
}

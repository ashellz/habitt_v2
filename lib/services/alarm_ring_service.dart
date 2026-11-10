import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android bridge for the ringing half of habit alarms (see
/// `HabitAlarmScheduler.kt`, `HabitAlarmRingService.kt` and
/// docs/habit_alarms.md). The notification is still posted by
/// awesome_notifications, on a silent channel; this schedules a native alarm
/// at the same time that plays the alarm ringtone on the alarm audio stream,
/// so it rings in silent / vibrate mode, until that notification is handled.
///
/// Every method is a safe no-op / `false` on other platforms, so callers fall
/// back to the regular sounding alarm channel.
class AlarmRingService {
  static const MethodChannel _channel = MethodChannel('habitt/alarm_ring');

  /// True when native ringing can be scheduled (Android with the exact alarm
  /// permission; without it the sound could start minutes late).
  static Future<bool> canRing() async {
    if (!Platform.isAndroid) return false;
    return await _invoke<bool>('canRing') ?? false;
  }

  static Future<bool> schedule({
    required int id,
    required DateTime at,
    required String title,
  }) async {
    if (!Platform.isAndroid) return false;
    return await _invoke<bool>('schedule', {
          'id': id,
          'epochMs': at.millisecondsSinceEpoch,
          'title': title,
        }) ??
        false;
  }

  static Future<void> cancel(int id) async {
    if (!Platform.isAndroid) return;
    await _invoke<void>('cancel', {'id': id});
  }

  static Future<void> cancelAll() async {
    if (!Platform.isAndroid) return;
    await _invoke<void>('cancelAll');
  }

  /// Whether alarms ring while Do Not Disturb is on. When off, an alarm
  /// firing during DND only shows its notification. Silent / vibrate mode
  /// always rings.
  static Future<void> setRingDuringDnd(bool ring) async {
    if (!Platform.isAndroid) return;
    await _invoke<void>('setRingDuringDnd', {'ring': ring});
  }

  /// Labels for the ringing service's own (quiet) notification, which runs
  /// without Flutter.
  static Future<void> configure({
    required String channelName,
    required String silenceLabel,
  }) async {
    if (!Platform.isAndroid) return;
    await _invoke<void>('configure', {
      'channelName': channelName,
      'silenceLabel': silenceLabel,
    });
  }

  /// Silences a ringing alarm right away (it also stops by itself once the
  /// alarm notification is gone).
  static Future<void> stopRinging() async {
    if (!Platform.isAndroid) return;
    await _invoke<void>('stopRinging');
  }

  static Future<T?> _invoke<T>(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } catch (e) {
      debugPrint('AlarmRing $method failed: $e');
      return null;
    }
  }
}

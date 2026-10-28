import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// iOS 26+ AlarmKit bridge (see `HabitAlarmKitBridge` in
/// `ios/Runner/AppDelegate.swift` and docs/habit_alarms.md). Every method is a
/// safe no-op / `false` on other platforms and older iOS, so callers fall back
/// to a regular notification.
class AlarmKitService {
  static const MethodChannel _channel = MethodChannel('habitt/alarmkit');

  /// True when AlarmKit exists on this OS and the user has authorized alarms.
  static Future<bool> isAvailable() async {
    if (!Platform.isIOS) return false;
    return await _invoke<bool>('isAvailable') ?? false;
  }

  /// Prompts for AlarmKit permission (iOS 26+ only).
  static Future<bool> requestAuthorization() async {
    if (!Platform.isIOS) return false;
    return await _invoke<bool>('requestAuthorization') ?? false;
  }

  static Future<bool> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String stopLabel,
  }) async {
    if (!Platform.isIOS) return false;
    return await _invoke<bool>('schedule', {
          'id': id,
          'epochMs': at.millisecondsSinceEpoch,
          'title': title,
          'stopLabel': stopLabel,
        }) ??
        false;
  }

  static Future<void> cancel(int id) async {
    if (!Platform.isIOS) return;
    await _invoke<void>('cancel', {'id': id});
  }

  /// Cancels every AlarmKit alarm the app has scheduled (all are habit alarms).
  static Future<void> cancelAll() async {
    if (!Platform.isIOS) return;
    await _invoke<void>('cancelAll');
  }

  static Future<T?> _invoke<T>(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } catch (e) {
      debugPrint('AlarmKit $method failed: $e');
      return null;
    }
  }
}

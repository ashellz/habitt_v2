import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android bridge for the full-screen alarm page (see `MainActivity.kt` and
/// docs/habit_alarms.md). Every method is a safe no-op on other platforms.
class AlarmScreenService {
  static const MethodChannel _channel = MethodChannel('habitt/alarm_screen');

  /// Android 14+ turns full-screen notifications off for most apps, and
  /// awesome_notifications can't tell (it reports the permission as granted).
  static Future<bool> canUseFullScreenIntent() async {
    if (!Platform.isAndroid) return true;
    return await _invoke<bool>('canUseFullScreenIntent') ?? true;
  }

  /// Opens the system "Full screen notifications" toggle for Habitt.
  static Future<void> openFullScreenIntentSettings() async {
    if (!Platform.isAndroid) return;
    await _invoke<bool>('openFullScreenIntentSettings');
  }

  /// Lets the app show over the lock screen (set natively when an alarm opens
  /// it). Cleared when the alarm page closes so the rest of the app never
  /// shows without unlocking.
  static Future<void> setShowOverLockScreen(bool show) async {
    if (!Platform.isAndroid) return;
    await _invoke<void>('setShowOverLockScreen', {'show': show});
  }

  static Future<T?> _invoke<T>(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } catch (e) {
      debugPrint('AlarmScreen $method failed: $e');
      return null;
    }
  }
}

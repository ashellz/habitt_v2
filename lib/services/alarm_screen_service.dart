import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android bridge for the full-screen alarm page (see `MainActivity.kt` and
/// docs/habit_alarms.md). Every method is a safe no-op on other platforms.
class AlarmScreenService {
  static const MethodChannel _channel = MethodChannel('habitt/alarm_screen');

  /// True while a ringing alarm page is on screen. Automatic sheets
  /// ([showDialogSheet]), the review prompt and the sync pill wait or hide
  /// until it closes, so nothing ever shows over a ringing alarm.
  static final ValueNotifier<bool> isOnScreen = ValueNotifier<bool>(false);
  static int _openPages = 0;

  /// Called by the alarm page when it's created / disposed.
  static void markOpened() {
    _openPages++;
    isOnScreen.value = true;
  }

  static void markClosed() {
    if (_openPages > 0) _openPages--;
    isOnScreen.value = _openPages > 0;
  }

  /// Completes once no alarm page is on screen (immediately if none is).
  static Future<void> waitUntilClosed() {
    if (!isOnScreen.value) return Future<void>.value();
    final done = Completer<void>();
    void listener() {
      if (isOnScreen.value) return;
      isOnScreen.removeListener(listener);
      done.complete();
    }

    isOnScreen.addListener(listener);
    return done.future;
  }

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

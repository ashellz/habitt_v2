import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:habitt/services/main_tab_controller.dart';
import 'package:habitt/services/notification_action_handler.dart';
import 'package:habitt/services/unsaved_changes_guard.dart';
import 'package:home_widget/home_widget.dart';

/// Where a home screen widget tap asks the app to go.
sealed class WidgetLaunch {
  const WidgetLaunch();
}

/// Open the home page (Streak widgets, or Today ring with nothing left).
class WidgetLaunchHome extends WidgetLaunch {
  const WidgetLaunchHome();
}

/// Open Log progress for a habit (Up next rows, Today ring).
class WidgetLaunchLog extends WidgetLaunch {
  const WidgetLaunchLog(this.habitId);
  final int habitId;
}

/// Routes home screen widget taps. The widgets open `habitt://widget/home` or
/// `habitt://widget/log?habit=<id>` (iOS adds `homeWidget` to the query so
/// the plugin recognises it). See docs/home_widgets.md.
class WidgetLaunchHandler {
  WidgetLaunchHandler._();

  static StreamSubscription<Uri?>? _clicks;

  /// Parses a widget launch URI; null for anything that is not one.
  static WidgetLaunch? parse(Uri? uri) {
    if (uri == null || uri.scheme != 'habitt' || uri.host != 'widget') {
      return null;
    }
    switch (uri.path) {
      case '/home':
        return const WidgetLaunchHome();
      case '/log':
        final id = int.tryParse(uri.queryParameters['habit'] ?? '');
        return id == null ? const WidgetLaunchHome() : WidgetLaunchLog(id);
      default:
        return null;
    }
  }

  /// Acts on [uri]. [openHabit] and [openHome] are swappable for tests.
  static void handle(
    Uri? uri, {
    void Function(int habitId, DateTime day)? openHabit,
    VoidCallback? openHome,
    DateTime Function()? now,
  }) {
    final launch = parse(uri);
    if (launch == null) return;
    switch (launch) {
      case WidgetLaunchHome():
        (openHome ?? _openHome)();
      case WidgetLaunchLog(:final habitId):
        final t = (now ?? DateTime.now)();
        (openHabit ?? _openHabit)(habitId, DateTime(t.year, t.month, t.day));
    }
  }

  /// Handles the tap that started the app, then every later one. Call once
  /// after the first frame.
  static Future<void> start() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      handle(await HomeWidget.initiallyLaunchedFromHomeWidget());
      _clicks ??= HomeWidget.widgetClicked.listen(handle);
    } catch (e) {
      debugPrint('[WIDGETS] widget launch handling unavailable: $e');
    }
  }

  // same routine as a notification tap: Log progress over the main page, or
  // the habit's details when it has nothing to log by hand
  static void _openHabit(int habitId, DateTime day) =>
      NotificationActionHandler.openHabit(habitId, day: day);

  static void _openHome() {
    if (UnsavedChangesGuard.isBlocking) return;
    final nav = NotificationActionHandler.navigatorKey.currentState;
    nav?.popUntil((route) => route.isFirst);
    MainTabController.resetToMainTab();
  }
}

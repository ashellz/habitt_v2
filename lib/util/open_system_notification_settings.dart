import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Opens the OS settings where the user can allow notifications for Habitt.
///
/// iOS goes through permission_handler: awesome_notifications opens the
/// settings URL with the deprecated `openURL:`, which iOS 18+ ignores
/// (nothing happens).
Future<void> openSystemNotificationSettings() async {
  if (Platform.isIOS) {
    final opened = await ph.openAppSettings();
    if (!opened) debugPrint('Could not open the app settings page');
    return;
  }
  await AwesomeNotifications().showNotificationConfigPage();
}

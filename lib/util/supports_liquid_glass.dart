import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

Future<bool> supportsLiquidGlass() async {
  if (Platform.isIOS) {
    debugPrint("Checking iOS version for Liquid Glass support... Is iOS: true");
    final deviceInfo = DeviceInfoPlugin();
    final iosInfo = await deviceInfo.iosInfo;
    final version = iosInfo.systemVersion;
    final majorVersion = int.tryParse(version.split('.').first) ?? 0;
    debugPrint("iOS Major Version: $majorVersion");

    return majorVersion >= 26;
  }
  return false;
}

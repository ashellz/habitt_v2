import 'package:flutter/foundation.dart';

// brand names, the same in every language
String healthSourceName() =>
    defaultTargetPlatform == TargetPlatform.iOS
        ? 'Apple Health'
        : 'Health Connect';

// the brand of another device's Health store, by its Platform.operatingSystem
// value ('ios', 'android'); unknown platforms fall back to this device's
String healthSourceNameFor(String platform) => switch (platform) {
  'ios' => 'Apple Health',
  'android' => 'Health Connect',
  _ => healthSourceName(),
};

import 'package:flutter/foundation.dart';

class MainTabController {
  MainTabController._();

  static VoidCallback? _resetToMainTab;

  static void register(VoidCallback resetToMainTab) {
    _resetToMainTab = resetToMainTab;
  }

  static void unregister(VoidCallback resetToMainTab) {
    if (_resetToMainTab == resetToMainTab) {
      _resetToMainTab = null;
    }
  }

  static void resetToMainTab() => _resetToMainTab?.call();
}

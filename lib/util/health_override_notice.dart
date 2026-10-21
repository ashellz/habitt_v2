import 'package:flutter/material.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/dialogs/health_override_notice_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

// one-time explanation that a hand-edit paused Health sync for that day
class HealthOverrideNotice {
  static const shownKey = 'healthOverrideNoticeShown';
  static bool _showing = false;

  // shows the notice the first time only, [context] must stay mounted after
  // the call site closes its own dialog (use the root navigator's context)
  static Future<void> showIfNeeded(BuildContext context) async {
    if (_showing) return;
    _showing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(shownKey) == true) return;
      if (!context.mounted) return;

      // marked before it opens, so it never repeats even if the app is
      // killed while it's up
      await prefs.setBool(shownKey, true);
      if (!context.mounted) return;

      await showDialogSheet(
        context: context,
        dismissible: false,
        builder: (_) => const HealthOverrideNoticeDialog(),
      );
    } finally {
      _showing = false;
    }
  }
}

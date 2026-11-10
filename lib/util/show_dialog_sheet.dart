import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/alarm_screen_service.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

Future<T?> showDialogSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  // false: not closable by tapping outside or dragging down, only by the
  // dialog's own buttons
  bool dismissible = true,
}) async {
  // nothing opens over a ringing alarm: automatic sheets (insights, streak
  // celebration, what's new...) wait until it's closed. The user can't open
  // one themselves while it's up.
  if (AlarmScreenService.isOnScreen.value) {
    await AlarmScreenService.waitUntilClosed();
    if (!context.mounted) return null;
  }
  final cp = context.read<ColorProvider>();
  return await showModalBottomSheet<T>(
    backgroundColor: Colors.transparent,
    barrierColor: cp.greyText.darken().withOpacity(0.3),
    isScrollControlled: true,
    // keeps a tall sheet below the status bar, its content scrolls instead
    useSafeArea: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    context: context,
    builder: builder,
  );
}

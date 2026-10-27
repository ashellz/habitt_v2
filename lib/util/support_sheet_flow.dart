import 'package:flutter/widgets.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/support_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/support/support_sheet.dart';
import 'package:provider/provider.dart';

/// Shows the "free for everyone" sheet if it is due: asks are not hidden and it
/// has not been shown in the last [SupportProvider.sheetRepeatDays] days. Called
/// when the user picks a new theme or opens cloud backup setup.
///
/// It is stamped as shown BEFORE it is presented, so however it is dismissed
/// (a button, a swipe, backgrounding) it waits out the full period. The user
/// opened the feature themselves, so it does not use the ask budget.
Future<void> maybeShowSupportSheet(BuildContext context) async {
  final support = context.read<SupportProvider>();
  if (!support.sheetDue) return;

  // never on top of the streak celebration, it would stay due for next time
  if (context.read<StateProvider>().streakCelebrationPendingOrActive) return;

  support.markSheetShown();
  await showDialogSheet<void>(
    context: context,
    builder: (_) => const SupportSheet(),
  );
}

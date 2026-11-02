import 'package:flutter/widgets.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/support_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/support/support_sheet.dart';
import 'package:provider/provider.dart';

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

import 'package:flutter/material.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/util/whats_new.dart';
import 'package:habitt/widgets/dialogs/whats_new_dialog.dart';
import 'package:provider/provider.dart';

/// Shows the one-time "What's new" sheet if it is due, see
/// [shouldShowWhatsNew]. Call it once the habits have loaded, as the join date
/// is only valid then (it reads as today before, which counts as a new user).
///
/// It is not a support ask: it has none inside and never touches the ask
/// budget. It is skipped while anything else is on screen or the streak
/// celebration is running, and stays due for the next launch. The current
/// version is saved once it is dismissed, however it is dismissed.
Future<void> maybeShowWhatsNew(BuildContext context) async {
  if (!context.mounted) return;

  final prefs = context.read<PreferencesProvider>();
  final due = shouldShowWhatsNew(
    dateJoined: context.read<HabitProvider>().dateJoined,
    lastSeenVersion: prefs.lastSeenVersion,
  );
  if (!due) return;

  if (context.read<StateProvider>().streakCelebrationPendingOrActive) return;
  // another sheet, dialog or page is above the home page
  if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;

  await showDialogSheet<void>(
    context: context,
    builder: (_) => const WhatsNewDialog(),
  );
  prefs.setLastSeenVersion(kWhatsNewVersion);
}

import 'package:flutter/widgets.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/dialogs/streak_celebration/streak_celebration_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only dedup state for the perfect-days streak celebration dialog.
/// Never synced — a rare duplicate celebration on a second device is harmless.
const String _kCelebratedStreakKey = 'celebratedPerfectStreak';
const String _kShownDateKey = 'streakDialogShownDate';

/// Date-only key (`yyyy-MM-dd`), matching the insight flow's format, used for
/// the once-per-day gate.
String dateKey(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return normalized.toIso8601String().split('T').first;
}

/// Evaluates whether to show the streak celebration dialog and shows it.
///
/// Rules (see the `perfect-streak-celebration` spec):
/// - The "Streak celebration" preference must be ON (checked first).
/// - The streak is recomputed fresh (never the queued/stale value).
/// - First run / post-restore seeds the celebrated value without showing.
/// - Shows when `streak >= 1 && streak > celebrated && shownDate != today`.
/// - Dedup state is written BEFORE the dialog is presented.
/// - A shared gate makes the insight sheet defer so the two never overlap.
Future<void> maybeShowStreakCelebration(BuildContext context) async {
  // Toggle check first — before any refresh or dedup work.
  if (!context.read<PreferencesProvider>().showStreakCelebration) {
    return;
  }

  final stateProvider = context.read<StateProvider>();
  final statsProvider = context.read<StatsProvider>();
  final habitProvider = context.read<HabitProvider>();

  // Hold the gate from evaluation through dismissal so the insight sheet
  // defers; always clear it, even on early return or error.
  stateProvider.streakCelebrationPendingOrActive = true;
  try {
    final prefs = await SharedPreferences.getInstance();

    // Force a fresh streak; never trust the lazily-queued value at startup.
    final streak = statsProvider.refreshPerfectStreak();
    statsProvider.perfectDaysStreak = streak;

    // First run / post-restore: seed the celebrated value silently so a
    // long-standing restored streak does not fire a "new streak" dialog.
    if (!prefs.containsKey(_kCelebratedStreakKey)) {
      await prefs.setInt(_kCelebratedStreakKey, streak);
      return;
    }

    final celebrated = prefs.getInt(_kCelebratedStreakKey) ?? 0;
    final shownDate = prefs.getString(_kShownDateKey);
    final now = DateTime.now();
    final today = dateKey(now);

    // The dialog always anchors on yesterday, so only celebrate when yesterday
    // is genuinely a perfect day. This also closes the "silent older-day
    // increase then restart" leak, where the streak rose without yesterday
    // being the cause.
    final dayStatuses = statsProvider.getDayCompletionStatuses(habitProvider);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final yesterdayPerfect =
        dayStatuses[yesterday] == DayCompletionStatus.perfect;

    final shouldShow =
        streak >= 1 &&
        streak > celebrated &&
        shownDate != today &&
        yesterdayPerfect;
    if (!shouldShow || !context.mounted) {
      return;
    }

    // Persist dedup BEFORE showing so backgrounding mid-dialog can't double-fire.
    await prefs.setString(_kShownDateKey, today);
    await prefs.setInt(_kCelebratedStreakKey, streak);

    if (!context.mounted) {
      return;
    }

    final allStats = statsProvider.getAllDaysProgress(habitProvider);

    await showDialogSheet(
      context: context,
      builder:
          (_) => StreakCelebrationDialog(
            streak: streak,
            dayStatuses: dayStatuses,
            allStats: allStats,
            today: now,
          ),
    );
  } finally {
    stateProvider.streakCelebrationPendingOrActive = false;
  }
}

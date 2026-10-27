import 'package:flutter/widgets.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/util/date_key.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/dialogs/streak_celebration/streak_celebration_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only dedup state for the perfect-days streak celebration dialog.
/// Never synced — a rare duplicate celebration on a second device is harmless.
const String _kCelebratedStreakKey = 'celebratedPerfectStreak';
const String _kShownDateKey = 'streakDialogShownDate';

/// A celebration that [evaluateStreakCelebration] decided should be shown.
class StreakCelebration {
  const StreakCelebration({
    required this.streak,
    required this.celebratedBefore,
    required this.dayStatuses,
    required this.allStats,
    required this.today,
    required this.persistShown,
  });

  final int streak;

  /// The last celebrated streak before this one (already lowered if the streak
  /// broke), so callers can tell which milestones this increase crossed.
  final int celebratedBefore;
  final Map<DateTime, DayCompletionStatus> dayStatuses;
  final Map<DateTime, double> allStats;
  final DateTime today;

  /// Writes the dedup state. Must run BEFORE the dialog is presented so
  /// backgrounding mid-dialog can't double-fire.
  final Future<void> Function() persistShown;
}

/// Decides whether the streak celebration should show for [streak], a freshly
/// recomputed value (never the queued/stale one). Returns null when it should
/// not. The caller checks the "Streak celebration" preference first.
///
/// Rules (see the `perfect-streak-celebration` spec):
/// - First run / post-restore seeds the celebrated value without showing.
/// - When the streak drops below the celebrated value (it broke), the
///   celebrated value follows it down so the new run can celebrate again.
/// - Shows when `streak >= 1 && streak > celebrated && shownDate != today`
///   and yesterday is genuinely a perfect day.
Future<StreakCelebration?> evaluateStreakCelebration(
  BuildContext context, {
  required int streak,
}) async {
  final statsProvider = context.read<StatsProvider>();
  final habitProvider = context.read<HabitProvider>();
  final prefs = await SharedPreferences.getInstance();

  // First run / post-restore: seed the celebrated value silently so a
  // long-standing restored streak does not fire a "new streak" dialog.
  if (!prefs.containsKey(_kCelebratedStreakKey)) {
    await prefs.setInt(_kCelebratedStreakKey, streak);
    return null;
  }

  var celebrated = prefs.getInt(_kCelebratedStreakKey) ?? 0;

  // The streak broke (or shrank) since the last celebration. Lower the
  // celebrated value so the new run celebrates again as it grows, instead of
  // staying silent until it beats the old run.
  if (streak < celebrated) {
    celebrated = streak;
    await prefs.setInt(_kCelebratedStreakKey, streak);
  }
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
  if (!shouldShow) return null;

  return StreakCelebration(
    streak: streak,
    celebratedBefore: celebrated,
    dayStatuses: dayStatuses,
    allStats: statsProvider.getAllDaysProgress(habitProvider),
    today: now,
    persistShown: () async {
      await prefs.setString(_kShownDateKey, today);
      await prefs.setInt(_kCelebratedStreakKey, streak);
    },
  );
}

/// Records the dedup state, then presents the celebration dialog and completes
/// when it is dismissed. [showSupportCard] adds the milestone support card.
Future<void> showStreakCelebration(
  BuildContext context,
  StreakCelebration celebration, {
  bool showSupportCard = false,
}) async {
  await celebration.persistShown();
  if (!context.mounted) return;

  await showDialogSheet(
    context: context,
    builder:
        (_) => StreakCelebrationDialog(
          streak: celebration.streak,
          dayStatuses: celebration.dayStatuses,
          allStats: celebration.allStats,
          today: celebration.today,
          showSupportCard: showSupportCard,
        ),
  );
}

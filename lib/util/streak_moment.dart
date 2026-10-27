import 'package:flutter/widgets.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/providers/support_provider.dart';
import 'package:habitt/services/ask_budget.dart';
import 'package:habitt/services/feedback_service.dart';
import 'package:habitt/util/perfect_streak_celebration.dart';
import 'package:habitt/util/streak_milestones.dart';
import 'package:provider/provider.dart';

// Flipped on once the milestone support card exists in the celebration dialog
// (task 38). Until then it must not claim the day's budget.
const bool _kMilestoneCardEnabled = false;

// delay between streak celebration and review ask
const Duration _kReviewDelay = Duration(milliseconds: 400);

bool _running = false;

/// Everything that can happen when the app opens, resumes or a past day is
/// completed and the perfect-days streak may have grown, in one place so the
/// surfaces can never collide:
///
/// 1. holds the shared gate so the insight sheet defers,
/// 2. recomputes the streak and records whether it reached the review milestone,
/// 3. evaluates the celebration (when its preference is ON),
/// 4. picks at most one ask via the daily budget (review first, then the
///    milestone support card), never claiming before it knows the ask can show,
/// 5. shows the celebration, then the review AFTER the dialog is dismissed.
///
/// [celebrationOnly] is for the past-day completion hook, where only the
/// celebration is worth reacting to in the moment: with the celebration
/// preference OFF it does nothing, and a due review waits for the next
/// launch/resume.
Future<void> runStreakMoment(
  BuildContext context, {
  bool celebrationOnly = false,
}) async {
  final prefsProvider = context.read<PreferencesProvider>();
  if (celebrationOnly && !prefsProvider.showStreakCelebration) return;

  // A second trigger while one is running (launch + resume, or a past-day
  // completion) would otherwise clear the gate early or repeat an ask.
  if (_running) return;
  _running = true;

  final stateProvider = context.read<StateProvider>();
  final statsProvider = context.read<StatsProvider>();
  final support = context.read<SupportProvider>();

  stateProvider.streakCelebrationPendingOrActive = true;
  try {
    // Force a fresh streak; never trust the lazily-queued value at startup.
    final streak = statsProvider.refreshPerfectStreak();
    statsProvider.perfectDaysStreak = streak;
    support.noteStreak(streak);

    StreakCelebration? celebration;
    if (prefsProvider.showStreakCelebration) {
      celebration = await evaluateStreakCelebration(context, streak: streak);
    }
    if (!context.mounted) return;

    final crossed =
        celebration == null
            ? null
            : crossedMilestone(
              celebrated: celebration.celebratedBefore,
              streak: celebration.streak,
            );
    final reviewPossible =
        support.reviewMilestoneReached &&
        await FeedbackService.canRequestReview();

    final ask = planMomentAsk(
      budgetFree: !support.claimedToday,
      possible: {
        if (reviewPossible) AskKind.review,
        if (_kMilestoneCardEnabled && crossed != null && !support.asksHidden)
          AskKind.milestoneBanner,
      },
    );
    if (ask != null) support.tryClaimAsk(ask);

    if (celebration != null) {
      if (!context.mounted) return;
      await showStreakCelebration(context, celebration);
    }

    if (ask == AskKind.review) {
      await Future<void>.delayed(_kReviewDelay);
      await FeedbackService.requestReview();
    }
  } finally {
    stateProvider.streakCelebrationPendingOrActive = false;
    _running = false;
  }
}

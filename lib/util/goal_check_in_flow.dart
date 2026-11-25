import 'dart:async';

import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/notifications_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/goal_check_in_analyzer.dart';
import 'package:habitt/services/goal_check_in_notifications.dart';
import 'package:habitt/services/goal_check_in_store.dart';
import 'package:habitt/services/lighter_day_offers.dart';
import 'package:habitt/services/lighter_day_policy.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/dialogs/log_progress_dialog.dart';
import 'package:habitt/widgets/goal_check_in/goal_check_in_sheet.dart';
import 'package:habitt/widgets/goal_check_in/goal_suggestion_card.dart';
import 'package:habitt/widgets/goal_check_in/lighter_day_sheet.dart';
import 'package:provider/provider.dart';

/// Decides when the goal check-in sheets show on the main page: the evening
/// lighter-day sheet first, then the weekly check-in. Replaces the old
/// per-habit insight sheets. See docs/goal_check_in.md.
class GoalCheckInFlow {
  /// A habit whose lighter-day sheet a goal check-in notification asked for.
  /// The main page listens and evaluates right away.
  static final ValueNotifier<int?> requestedHabit = ValueNotifier(null);

  static void requestLighterDay(int habitId) => requestedHabit.value = habitId;

  Timer? _debounce;
  bool _sheetOpen = false;
  bool _evaluating = false;

  void dispose() {
    _debounce?.cancel();
  }

  void scheduleEvaluation(
    BuildContext context, {
    required bool Function() isActive,
    bool immediate = false,
  }) {
    if (!context.mounted || !isActive()) return;

    _debounce?.cancel();
    if (immediate) {
      unawaited(_evaluate(context: context, isActive: isActive));
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_evaluate(context: context, isActive: isActive));
    });
  }

  bool _canProceed(BuildContext context, bool Function() isActive) =>
      context.mounted && isActive();

  Future<void> _evaluate({
    required BuildContext context,
    required bool Function() isActive,
  }) async {
    if (!_canProceed(context, isActive) || _sheetOpen || _evaluating) return;

    final backupProvider = context.read<BackupProvider>();
    if (!backupProvider.isInitialized ||
        backupProvider.syncState == SyncState.syncing) {
      return;
    }
    // the streak celebration takes precedence, the two sheets never overlap
    if (context.read<StateProvider>().streakCelebrationPendingOrActive) return;

    _evaluating = true;
    try {
      final hp = context.read<HabitProvider>();
      if (!hp.isInitialized) return;
      unawaited(
        GoalCheckInNotifications.refresh(
          hp,
          context.read<NotificationsProvider>(),
        ),
      );
      final store = await GoalCheckInStore.load();
      if (!_canProceed(context, isActive)) return;
      final now = DateTime.now();

      // ─── Asked for by a notification ──────────────────────
      final requested = requestedHabit.value;
      if (requested != null) {
        requestedHabit.value = null;
        LighterDayOffer? offer;
        for (final o in LighterDayOffers.forToday(hp, now: now)) {
          if (o.habit.id == requested) offer = o;
        }
        if (offer != null) {
          await store.markLighterShown(offer.habit.id);
          if (!_canProceed(context, isActive)) return;
          await _showLighterDay(context, offer);
          return;
        }
      }

      // ─── Evening lighter-day sheet ────────────────────────
      if (LighterDayOffers.isEvening(now)) {
        final offer = LighterDayOffers.best(
          hp,
          now: now,
          skip: store.lighterShownToday,
        );
        if (offer != null) {
          await store.markLighterShown(offer.habit.id);
          if (!_canProceed(context, isActive)) return;
          await _showLighterDay(context, offer);
          return;
        }
      }

      // ─── Weekly check-in ──────────────────────────────────
      if (!store.weeklyDue) return;
      final items = weeklyItems(hp, store, now: now);
      if (items.isEmpty || !_canProceed(context, isActive)) return;
      await store.markShown();
      if (!_canProceed(context, isActive)) return;
      await _showWeekly(context, items, store);
    } finally {
      _evaluating = false;
    }
  }

  /// Every active habit's goal suggestion, in app order.
  static List<GoalCheckInItem> weeklyItems(
    HabitProvider hp,
    GoalCheckInStore store, {
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final days = hp.daysBox.values.toList();
    final items = <GoalCheckInItem>[];
    for (final habit in hp.habits) {
      if (habit.isDeleted == true || habit.isPaused == true) continue;
      if (!GoalCheckInAnalyzer.supports(habit)) continue;
      final isDuration = habit.trackingType == HabitTrackingType.duration;
      final suggestion = GoalCheckInAnalyzer.analyze(
        currentGoal: isDuration ? habit.duration : habit.amount,
        isDuration: isDuration,
        days: GoalCheckInAnalyzer.collect(
          days: days,
          habitId: habit.id,
          today: today,
          isInactiveOnDay: (d) => hp.inactiveOnPastDay(habit.id, d),
        ),
        blocked: store.blocked(habit.id),
      );
      if (suggestion != null) {
        items.add(GoalCheckInItem(habit: habit, suggestion: suggestion));
      }
    }
    return items;
  }

  Future<void> _showWeekly(
    BuildContext context,
    List<GoalCheckInItem> items,
    GoalCheckInStore store,
  ) async {
    _sheetOpen = true;
    try {
      await showDialogSheet(
        context: context,
        builder:
            (_) => GoalCheckInSheet(
              items: items,
              actions: _WeeklyActions(context.read<HabitProvider>(), store),
            ),
      );
    } finally {
      _sheetOpen = false;
    }
  }

  Future<void> _showLighterDay(
    BuildContext context,
    LighterDayOffer offer,
  ) async {
    _sheetOpen = true;
    final hp = context.read<HabitProvider>();
    try {
      await showDialogSheet(
        context: context,
        builder:
            (sheetContext) => LighterDaySheet(
              offer: offer,
              onSetGoal:
                  (goal) =>
                      hp.setTodayGoal(offer.habit.id, goal, context: context),
              onLogProgress: () => openLogProgress(context, offer.habit),
            ),
      );
    } finally {
      _sheetOpen = false;
    }
  }

  /// Opens the log progress dialog for today's [habit] (the "save your
  /// streak" path).
  static void openLogProgress(BuildContext context, Habit habit) {
    if (!context.mounted) return;
    context.read<HabitProvider>().setSelectedDate(DateTime.now());
    final type =
        habit.trackingType == HabitTrackingType.duration
            ? ProgressType.duration
            : ProgressType.amount;
    unawaited(
      showDialogSheet(
        context: context,
        builder: (_) => LogProgressDialog(progressType: type, habit: habit),
      ),
    );
  }
}

/// Apply / not now / undo for the weekly sheet: goal changes go through
/// [HabitProvider.updateHabit], cooldowns through [GoalCheckInStore].
class _WeeklyActions implements GoalCheckInActions {
  _WeeklyActions(this._hp, this._store);

  final HabitProvider _hp;
  final GoalCheckInStore _store;
  final Map<int, int> _previousGoal = {};

  Habit? _live(int id) {
    for (final h in _hp.habits) {
      if (h.id == id) return h;
    }
    return null;
  }

  void _setGoal(Habit live, int value) {
    final edited = live.copy();
    if (edited.trackingType == HabitTrackingType.duration) {
      edited.duration = value;
    } else {
      edited.amount = value;
    }
    _hp.updateHabit(edited);
  }

  @override
  Future<void> apply(GoalCheckInItem item) async {
    final live = _live(item.habit.id);
    if (live == null) return;
    _previousGoal[live.id] =
        live.trackingType == HabitTrackingType.duration
            ? live.duration
            : live.amount;
    _setGoal(live, item.suggestion.suggestedValue);
    await _store.startCooldown(live.id, GoalDirection.values);
  }

  @override
  Future<void> notNow(GoalCheckInItem item) =>
      _store.startCooldown(item.habit.id, [item.suggestion.direction]);

  @override
  Future<void> undo(GoalCheckInItem item, GoalCardStatus from) async {
    if (from == GoalCardStatus.applied) {
      final live = _live(item.habit.id);
      final previous = _previousGoal.remove(item.habit.id);
      if (live != null && previous != null) _setGoal(live, previous);
      await _store.clearCooldown(item.habit.id, GoalDirection.values);
    } else if (from == GoalCardStatus.skipped) {
      await _store.clearCooldown(item.habit.id, [item.suggestion.direction]);
    }
  }
}

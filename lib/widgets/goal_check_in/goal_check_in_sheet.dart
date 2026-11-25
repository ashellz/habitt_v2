import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/services/goal_check_in_analyzer.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/goal_check_in/goal_suggestion_card.dart';

/// A habit and its goal suggestion, one card in [GoalCheckInSheet].
class GoalCheckInItem {
  const GoalCheckInItem({required this.habit, required this.suggestion});

  final Habit habit;
  final GoalSuggestion suggestion;
}

/// What the sheet's buttons do. Undo gets the status the card is leaving.
abstract class GoalCheckInActions {
  Future<void> apply(GoalCheckInItem item);
  Future<void> notNow(GoalCheckInItem item);
  Future<void> undo(GoalCheckInItem item, GoalCardStatus from);
}

/// The weekly check-in: every goal suggestion on one sheet. See
/// docs/goal_check_in.md.
class GoalCheckInSheet extends StatefulWidget {
  const GoalCheckInSheet({
    super.key,
    required this.items,
    required this.actions,
  });

  final List<GoalCheckInItem> items;
  final GoalCheckInActions actions;

  @override
  State<GoalCheckInSheet> createState() => _GoalCheckInSheetState();
}

class _GoalCheckInSheetState extends State<GoalCheckInSheet> {
  late final List<GoalCardStatus> _status = List.filled(
    widget.items.length,
    GoalCardStatus.open,
  );
  bool _busy = false;

  bool get _anyOpen => _status.contains(GoalCardStatus.open);

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    try {
      await action();
    } finally {
      _busy = false;
    }
  }

  void _apply(int i) => _run(() async {
    await widget.actions.apply(widget.items[i]);
    if (mounted) setState(() => _status[i] = GoalCardStatus.applied);
  });

  void _notNow(int i) => _run(() async {
    await widget.actions.notNow(widget.items[i]);
    if (mounted) setState(() => _status[i] = GoalCardStatus.skipped);
  });

  void _undo(int i) => _run(() async {
    await widget.actions.undo(widget.items[i], _status[i]);
    if (mounted) setState(() => _status[i] = GoalCardStatus.open);
  });

  void _applyAll() => _run(() async {
    for (var i = 0; i < widget.items.length; i++) {
      if (_status[i] != GoalCardStatus.open) continue;
      await widget.actions.apply(widget.items[i]);
      if (mounted) setState(() => _status[i] = GoalCardStatus.applied);
    }
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return NewDefaultDialog(
      title: _anyOpen ? loc.goalCheckInTitle : loc.goalCheckInAllSet,
      desc: loc.goalCheckInSubtitle,
      showCloseButton: true,
      secondaryButtonLabel: loc.later,
      showSecondaryButton: _anyOpen,
      primaryButtonLabel: _anyOpen ? loc.goalCheckInApplyAll : loc.done,
      onPrimaryButtonPressed:
          _anyOpen ? _applyAll : () => Navigator.of(context).pop(),
      child: Column(
        spacing: 12,
        children: [
          for (var i = 0; i < widget.items.length; i++)
            GoalSuggestionCard(
              habit: widget.items[i].habit,
              suggestion: widget.items[i].suggestion,
              status: _status[i],
              onApply: () => _apply(i),
              onNotNow: () => _notNow(i),
              onUndo: () => _undo(i),
            ),
        ],
      ),
    );
  }
}

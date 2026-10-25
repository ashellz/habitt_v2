import 'package:flutter/material.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/category_for_minutes.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/habit_details/new/editable/dialogs/day_schedule_dialog.dart';
import 'package:habitt/widgets/habit_details/new/editable/dialogs/schedule_time_picker_dialog.dart';
import 'package:habitt/widgets/habit_details/new/editable/dialogs/time_range_dialog.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

/// When during the day a habit happens. The first four map to a category with
/// no time interval; the last two set the habit's interval and pick the
/// category from its start time.
enum DaySchedule {
  anyTime,
  morning,
  afternoon,
  evening,
  specificTime,
  timeRange;

  /// Category for the category options (ids match the seeded categories).
  int? get categoryId => switch (this) {
    DaySchedule.anyTime => 1,
    DaySchedule.morning => 2,
    DaySchedule.afternoon => 3,
    DaySchedule.evening => 4,
    _ => null,
  };

  bool get isTimed => categoryId == null;
}

// a range is never shorter than this when it starts from a specific time
const int _defaultRangeLength = 60;

/// The schedule the sheet currently holds. A specific time is stored as an
/// interval that starts and ends at the same minute.
DaySchedule currentDaySchedule(StateProvider sp) {
  if (sp.timeIntervalEnabled) {
    return sp.timeIntervalStart == sp.timeIntervalEnd
        ? DaySchedule.specificTime
        : DaySchedule.timeRange;
  }
  return switch (sp.habitCategoryId) {
    2 => DaySchedule.morning,
    3 => DaySchedule.afternoon,
    4 => DaySchedule.evening,
    _ => DaySchedule.anyTime,
  };
}

/// Day schedule picker → (start time picker | time range dialog → time
/// pickers). Each step closes the previous dialog before opening the next.
/// Nothing is applied until the flow finishes: picking a category, Done on
/// the specific time picker, or Done on the time range dialog. Back returns to
/// the previous step; dismissing a dialog ends the flow.
Future<void> showDayScheduleFlow(BuildContext context) async {
  final sp = context.read<StateProvider>();
  final loc = AppLocalizations.of(context)!;
  var selected = currentDaySchedule(sp);

  while (context.mounted) {
    final choice = await showDialogSheet<DaySchedule>(
      context: context,
      builder: (_) => DayScheduleDialog(initial: selected),
    );
    if (choice == null || !context.mounted) return;
    selected = choice;

    final categoryId = choice.categoryId;
    if (categoryId != null) {
      // stored times stay, so switching back to a timed option shows them
      sp.timeIntervalEnabled = false;
      sp.habitCategoryId = categoryId;
      return;
    }

    if (choice == DaySchedule.specificTime) {
      final result = await showScheduleTimePicker(
        context,
        title: loc.setStartTime,
        // stored times are kept while a category is picked, so reuse them
        initialMinutes: sp.timeIntervalStart,
      );
      if (result == null || !context.mounted) return;
      if (result == ScheduleTimePickerDialog.back) continue;
      _applyInterval(sp, result, result);
      return;
    }

    final finished = await _timeRangeSteps(context, sp, loc);
    if (finished != false) return;
  }
}

/// Time range dialog and its start / end pickers. Returns true when applied,
/// false to go back to the day schedule picker, null when dismissed.
Future<bool?> _timeRangeSteps(
  BuildContext context,
  StateProvider sp,
  AppLocalizations loc,
) async {
  // stored times survive switching to a category; a specific time grows into
  // an hour-long range
  var start = sp.timeIntervalStart;
  var end =
      sp.timeIntervalStart != sp.timeIntervalEnd
          ? sp.timeIntervalEnd
          : (start + _defaultRangeLength) % (24 * 60);

  while (context.mounted) {
    final action = await showDialogSheet<TimeRangeAction>(
      context: context,
      builder: (_) => TimeRangeDialog(start: start, end: end),
    );
    if (action == null || !context.mounted) return null;

    switch (action) {
      case TimeRangeAction.back:
        return false;
      case TimeRangeAction.done:
        _applyInterval(sp, start, end);
        return true;
      case TimeRangeAction.editStart:
      case TimeRangeAction.editEnd:
        final editingStart = action == TimeRangeAction.editStart;
        final result = await showScheduleTimePicker(
          context,
          title: editingStart ? loc.setStartTime : loc.setEndTime,
          initialMinutes: editingStart ? start : end,
        );
        if (result == null) return null;
        if (result == ScheduleTimePickerDialog.back) continue;
        if (editingStart) {
          start = result;
        } else {
          end = result;
        }
    }
  }
  return null;
}

void _applyInterval(StateProvider sp, int start, int end) {
  sp.timeIntervalStart = start;
  sp.timeIntervalEnd = end;
  sp.timeIntervalEnabled = true;
  sp.habitCategoryId = categoryIdForMinutes(start);
}

/// Hour and minute picker. Resolves to the picked minutes of the day,
/// [ScheduleTimePickerDialog.back] for Back, or null when dismissed.
Future<int?> showScheduleTimePicker(
  BuildContext context, {
  required String title,
  required int initialMinutes,
}) {
  return showDialogSheet<int>(
    context: context,
    builder:
        (_) => ScheduleTimePickerDialog(
          title: title,
          initialMinutes: initialMinutes,
        ),
  );
}

/// Edits one end of the habit's interval straight from the sheet. A specific
/// time moves both ends together.
Future<void> editScheduleTime(
  BuildContext context, {
  required bool editingStart,
}) async {
  final sp = context.read<StateProvider>();
  final loc = AppLocalizations.of(context)!;
  final isSpecific = sp.timeIntervalStart == sp.timeIntervalEnd;

  final result = await showScheduleTimePicker(
    context,
    title: editingStart ? loc.setStartTime : loc.setEndTime,
    initialMinutes: editingStart ? sp.timeIntervalStart : sp.timeIntervalEnd,
  );
  if (result == null || result == ScheduleTimePickerDialog.back) return;

  if (isSpecific) {
    _applyInterval(sp, result, result);
  } else if (editingStart) {
    // a range can't collapse into a specific time from here
    if (result == sp.timeIntervalEnd) return;
    _applyInterval(sp, result, sp.timeIntervalEnd);
  } else {
    if (result == sp.timeIntervalStart) return;
    _applyInterval(sp, sp.timeIntervalStart, result);
  }
}

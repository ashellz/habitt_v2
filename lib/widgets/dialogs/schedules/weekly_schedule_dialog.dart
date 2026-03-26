import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/increment_decrement_text_field.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/dialogs/schedules/schedule_dialog_snapshot.dart';
import 'package:habitt/widgets/dialogs/schedules/set_schedule_dialog.dart';
import 'package:habitt/widgets/habit_details/new/editable/dialogs/clear_selected_days_dialog.dart';
import 'package:habitt/widgets/habit_details/new/editable/select_days_weekly_schedule.dart';
import 'package:provider/provider.dart';

class WeeklyScheduleDialog extends StatefulWidget {
  const WeeklyScheduleDialog({super.key, required this.rootSnapshot});

  final ScheduleDialogSnapshot rootSnapshot;

  @override
  State<WeeklyScheduleDialog> createState() => _WeeklyScheduleDialogState();
}

class _WeeklyScheduleDialogState extends State<WeeklyScheduleDialog> {
  static const _switchDuration = Duration(milliseconds: 400);
  late bool showMoreOptions;
  late int initialWeeklyTarget;
  late Set<int> initialWeeklyDays;
  late final TextEditingController weeklyTargetController;
  bool _isClearDaysDialogOpen = false;

  @override
  void initState() {
    super.initState();
    final sp = context.read<StateProvider>();
    showMoreOptions = sp.selectedDaysAWeek.isNotEmpty;
    initialWeeklyTarget = sp.weeklyTarget;
    initialWeeklyDays = sp.selectedDaysAWeek;
    weeklyTargetController = TextEditingController(
      text: sp.weeklyTarget.toString(),
    );
  }

  @override
  void dispose() {
    weeklyTargetController.dispose();
    super.dispose();
  }

  bool _hasUnsavedChanges(StateProvider sp) {
    return sp.weeklyTarget != initialWeeklyTarget ||
        !_setEquals(sp.selectedDaysAWeek, initialWeeklyDays);
  }

  bool _setEquals(Set<int> first, Set<int> second) {
    if (first.length != second.length) {
      return false;
    }

    for (final value in first) {
      if (!second.contains(value)) {
        return false;
      }
    }

    return true;
  }

  void _returnToSetSchedule(ColorProvider cp) {
    Navigator.of(context).pop();
    showDialogSheet(
      context: context,
      builder:
          (context) => SetScheduleDialog(rootSnapshot: widget.rootSnapshot),
    );
  }

  Future<void> _handleExitAttempt(StateProvider sp, ColorProvider cp) async {
    if (!_hasUnsavedChanges(sp)) {
      _returnToSetSchedule(cp);
      return;
    }

    await showDialogSheet(
      context: context,
      builder:
          (dialogContext) => NewDefaultDialog(
            title: "Exit without saving?",
            primaryButtonLabel: "Exit",
            onPrimaryButtonPressed: () {
              sp.weeklyTarget = initialWeeklyTarget;
              sp.selectedDaysAWeek = initialWeeklyDays;
              Navigator.of(dialogContext).pop();
              _returnToSetSchedule(cp);
            },
          ),
    );
  }

  Future<void> _handleWeeklyTargetChange(
    StateProvider sp,
    ColorProvider cp,
    int nextValue,
  ) async {
    if (sp.weeklyTarget == nextValue) {
      return;
    }

    if (sp.selectedDaysAWeek.isEmpty) {
      sp.weeklyTarget = nextValue;
      return;
    }

    if (_isClearDaysDialogOpen) {
      return;
    }

    _isClearDaysDialogOpen = true;
    final bool shouldClear =
        await showDialogSheet(
          context: context,
          builder:
              (dialogContext) => ClearSelectedDaysDialog(
                type: ScheduleType.weekly,
                dialogContext: dialogContext,
                nextValue: nextValue,
              ),
        ) ??
        false;
    _isClearDaysDialogOpen = false;

    if (!shouldClear) {
      weeklyTargetController.value = weeklyTargetController.value.copyWith(
        text: sp.weeklyTarget.toString(),
        selection: TextSelection.collapsed(
          offset: sp.weeklyTarget.toString().length,
        ),
        composing: TextRange.empty,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StateProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && result == null) {
          _handleExitAttempt(sp, cp);
        }
      },
      child: NewDefaultDialog(
        title: "Weekly",
        onPrimaryButtonPressed: () {
          Navigator.of(context).pop(true);
        },
        onSecondaryButtonPressed: () {
          _handleExitAttempt(sp, cp);
        },
        child: Column(
          spacing: 20,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Times per week:',
                  style: TextStyle(
                    color: cp.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12),
                IncrementDecrementTextField(
                  controller:
                      weeklyTargetController..text = sp.weeklyTarget.toString(),
                  minValue: 1,
                  maxValue: 6,
                  onValueChanged: (value) {
                    _handleWeeklyTargetChange(sp, cp, value);
                  },
                  onIncrement: () {
                    final next = sp.weeklyTarget == 6 ? 1 : sp.weeklyTarget + 1;
                    _handleWeeklyTargetChange(sp, cp, next);
                  },
                  onDecrement: () {
                    final next = sp.weeklyTarget == 1 ? 6 : sp.weeklyTarget - 1;
                    _handleWeeklyTargetChange(sp, cp, next);
                  },
                ),
                AnimatedSwitcher(
                  duration: _switchDuration,
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        axisAlignment: -1,
                        child: child,
                      ),
                    );
                  },
                  child:
                      !showMoreOptions
                          ? Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              key: const ValueKey('weekly-helper-text'),
                              'This habit will appear ${sp.weeklyTarget} time${sp.weeklyTarget == 1 ? '' : 's'} per week until completed',
                              style: TextStyle(
                                color: cp.greyText,
                                fontSize: 13,
                              ),
                            ),
                          )
                          : const SizedBox.shrink(
                            key: ValueKey('weekly-helper-text-hidden'),
                          ),
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: _switchDuration,
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              layoutBuilder: (currentChild, previousChildren) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1,
                    child: child,
                  ),
                );
              },
              child:
                  showMoreOptions
                      ? Column(
                        key: const ValueKey('weekly-options-column'),
                        spacing: 12,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SelectDaysWeekly(),
                          Text(
                            'Leave unselected if you want the habit too appear every day of the week until completed',
                            style: TextStyle(
                              color: cp.greyText,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      )
                      : NewDefaultButton.secondary(
                        key: const ValueKey('weekly-add-more-button'),
                        onPressed: () {
                          setState(() {
                            showMoreOptions = true;
                          });
                        },
                        height: 40,
                        prefix: SvgPicture.asset(
                          "assets/images/new-svg/add.svg",
                          colorFilter: ColorFilter.mode(
                            cp.text,
                            BlendMode.srcIn,
                          ),
                        ),
                        width: double.infinity,
                        label: "Add more options",
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

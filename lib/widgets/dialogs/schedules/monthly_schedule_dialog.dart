import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/increment_decrement_text_field.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/dialogs/schedules/schedule_dialog_snapshot.dart';
import 'package:habitt/widgets/dialogs/schedules/set_schedule_dialog.dart';
import 'package:habitt/widgets/habit_details/new/editable/dialogs/clear_selected_days_dialog.dart';
import 'package:habitt/widgets/habit_details/new/editable/select_days_monthly_schedule.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class MonthlyScheduleDialog extends StatefulWidget {
  const MonthlyScheduleDialog({super.key, required this.rootSnapshot});

  final ScheduleDialogSnapshot rootSnapshot;

  @override
  State<MonthlyScheduleDialog> createState() => _MonthlyScheduleDialogState();
}

class _MonthlyScheduleDialogState extends State<MonthlyScheduleDialog> {
  static const _switchDuration = Duration(milliseconds: 400);
  late bool showMoreOptions;
  late int initialMonthlyTarget;
  late Set<int> initialMonthlyDays;
  late final TextEditingController monthlyTargetController;
  bool _isClearDaysDialogOpen = false;

  @override
  void initState() {
    super.initState();
    final sp = context.read<StateProvider>();
    showMoreOptions = sp.selectedDaysAMonth.isNotEmpty;
    initialMonthlyTarget = sp.monthlyTarget;
    initialMonthlyDays = sp.selectedDaysAMonth;
    monthlyTargetController = TextEditingController(
      text: sp.monthlyTarget.toString(),
    );
  }

  @override
  void dispose() {
    monthlyTargetController.dispose();
    super.dispose();
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

  bool _hasUnsavedChanges(StateProvider sp) {
    return sp.monthlyTarget != initialMonthlyTarget ||
        !_setEquals(sp.selectedDaysAMonth, initialMonthlyDays);
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
          (dialogContext) => ExitWithoutSavingDialog(
            onExit: () {
              sp.monthlyTarget = initialMonthlyTarget;
              sp.selectedDaysAMonth = initialMonthlyDays;
              Navigator.of(dialogContext).pop();
              _returnToSetSchedule(cp);
            },
          ),
    );
  }

  Future<void> _handleMonthlyTargetChange(
    StateProvider sp,
    ColorProvider cp,
    int nextValue,
  ) async {
    if (sp.monthlyTarget == nextValue) {
      return;
    }

    if (sp.selectedDaysAMonth.isEmpty) {
      sp.monthlyTarget = nextValue;
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
                type: ScheduleType.monthly,
                dialogContext: dialogContext,
                nextValue: nextValue,
              ),
        ) ??
        false;
    _isClearDaysDialogOpen = false;

    if (!shouldClear) {
      monthlyTargetController.value = monthlyTargetController.value.copyWith(
        text: sp.monthlyTarget.toString(),
        selection: TextSelection.collapsed(
          offset: sp.monthlyTarget.toString().length,
        ),
        composing: TextRange.empty,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StateProvider>();
    final loc = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && result == null) {
          _handleExitAttempt(sp, cp);
        }
      },
      child: NewDefaultDialog(
        title: loc.monthly,
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
                  loc.timesPerMonth,
                  style: TextStyle(
                    color: cp.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12),
                IncrementDecrementTextField(
                  controller:
                      monthlyTargetController
                        ..text = sp.monthlyTarget.toString(),
                  minValue: 1,
                  maxValue: 30,
                  onValueChanged: (value) {
                    _handleMonthlyTargetChange(sp, cp, value);
                  },
                  onIncrement: () {
                    final next =
                        sp.monthlyTarget == 30 ? 1 : sp.monthlyTarget + 1;
                    _handleMonthlyTargetChange(sp, cp, next);
                  },
                  onDecrement: () {
                    final next =
                        sp.monthlyTarget == 1 ? 30 : sp.monthlyTarget - 1;
                    _handleMonthlyTargetChange(sp, cp, next);
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
                              key: const ValueKey('monthly-helper-text'),
                              loc.habitWillAppearMonthly(
                                sp.monthlyTarget.toString(),
                                sp.monthlyTarget == 1 ? loc.time : loc.times,
                              ),
                              style: TextStyle(
                                color: cp.greyText,
                                fontSize: 13,
                              ),
                            ),
                          )
                          : const SizedBox.shrink(
                            key: ValueKey('monthly-helper-text-hidden'),
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
                        key: const ValueKey('monthly-options-column'),
                        spacing: 12,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SelectDaysMonthly(),
                          Text(
                            loc.leaveUnselected(loc.month2),
                            style: TextStyle(
                              color: cp.greyText,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      )
                      : NewDefaultButton.secondary(
                        key: const ValueKey('monthly-add-more-button'),
                        onPressed: () {
                          setState(() {
                            showMoreOptions = true;
                          });
                        },
                        height: 40,
                        width: double.infinity,
                        prefix: SvgPicture.asset(
                          "assets/images/new-svg/add.svg",
                          colorFilter: ColorFilter.mode(
                            cp.text,
                            BlendMode.srcIn,
                          ),
                        ),
                        label: loc.addMoreOptions,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExitWithoutSavingDialog extends StatelessWidget {
  const ExitWithoutSavingDialog({super.key, this.onExit});

  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return NewDefaultDialog(
      title: loc.exitWithoutSaving,
      primaryButtonLabel: loc.exit,
      onPrimaryButtonPressed: () {},
    );
  }
}

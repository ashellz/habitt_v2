import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/services/emoji_service.dart';
import 'package:habitt/util/color_converting.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/util/show_emoji_dialog.dart';
import 'package:habitt/widgets/default/animated_checkbox.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:habitt/widgets/habit_details/new/editable/select_habit_day_period.dart';
import 'package:habitt/widgets/habit_details/new/editable/select_habit_schedule_type.dart';
import 'package:habitt/widgets/habit_details/new/editable/select_habit_type_widgets.dart';
import 'package:habitt/widgets/habit_widget/text_icon.dart';
import 'package:provider/provider.dart';

class HabitSheet extends StatefulWidget {
  const HabitSheet({super.key, this.habit});

  final Habit? habit;

  @override
  State<HabitSheet> createState() => _HabitSheetState();
}

class _HabitSheetState extends State<HabitSheet> {
  late final VoidCallback _nameListener;
  late final VoidCallback _descListener;
  bool _allowPop = false;
  bool _isExitDialogOpen = false;
  bool _isInitializing = true;

  bool get _isEditMode => widget.habit != null;

  @override
  void initState() {
    super.initState();

    final sp = context.read<StateProvider>();

    _nameListener = () {
      if (mounted && !_isInitializing) {
        setState(() {});
      }
    };
    _descListener = () {
      if (mounted && !_isInitializing) {
        setState(() {});
      }
    };
    sp.nameController.addListener(_nameListener);
    sp.descController.addListener(_descListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (_isEditMode) {
        _setEditInitialValues(sp, widget.habit!);
      } else {
        sp.reset();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = false;
      });
    });
  }

  void _setEditInitialValues(StateProvider stateProvider, Habit habit) {
    stateProvider.selectedHabitId = habit.id;
    stateProvider.habitCategoryId = habit.categoryId;
    stateProvider.nameController.text = habit.name;
    stateProvider.descController.text = habit.description;
    stateProvider.habitAmount = habit.amount;
    stateProvider.habitDuration = Duration(minutes: habit.duration);
    stateProvider.habitAmountLabelController.text = habit.amountLabel;
    stateProvider.setIconPathImmediately(habit.iconPath);
    stateProvider.isOptional = habit.optional;
    stateProvider.timeIntervalEnabled = habit.timeIntervalEnabled;
    stateProvider.timeIntervalStart = habit.timeIntervalStart;
    stateProvider.timeIntervalEnd = habit.timeIntervalEnd;
    stateProvider.setScheduleFromHabit(
      scheduleType: habit.scheduleType,
      weeklyTarget: habit.weeklyTarget,
      monthlyTarget: habit.monthlyTarget,
      customIntervalDays: habit.customIntervalDays,
      selectedDaysAWeek: habit.selectedDaysAWeek,
      selectedDaysAMonth: habit.selectedDaysAMonth,
    );
    stateProvider.habitColorName = habit.colorName;
    stateProvider.habitColor = habit.resolveColor(
      context.read<ThemeProvider>(),
    );
  }

  bool _hasEditChanges(StateProvider sp, ThemeProvider tp) {
    final habit = widget.habit;
    if (habit == null) {
      return true;
    }

    final changedName = sp.nameController.text.trim() != habit.name;
    final changedDesc = sp.descController.text.trim() != habit.description;
    final changedCategory = sp.habitCategoryId != habit.categoryId;
    final changedDuration = sp.habitDuration.inMinutes != habit.duration;
    final changedAmount = sp.habitAmount != habit.amount;
    final changedOptionalHabit = sp.isOptional != habit.optional;
    final changedIcon = sp.iconPath != habit.iconPath;
    final changedTimeIntervalEnabled =
        sp.timeIntervalEnabled != habit.timeIntervalEnabled;
    final changedTimeIntervalStart =
        sp.timeIntervalStart != habit.timeIntervalStart;
    final changedTimeIntervalEnd = sp.timeIntervalEnd != habit.timeIntervalEnd;
    final changedScheduleType = sp.selectedScheduleOption != habit.scheduleType;
    final changedWeeklyTarget = sp.weeklyTarget != habit.weeklyTarget;
    final changedMonthlyTarget = sp.monthlyTarget != habit.monthlyTarget;
    final changedCustomInterval =
        sp.customIntervalDays != habit.customIntervalDays;
    final changedSelectedWeekDays =
        sp.selectedDaysAWeek.length != habit.selectedDaysAWeek.length ||
        !sp.selectedDaysAWeek.every((d) => habit.selectedDaysAWeek.contains(d));
    final changedSelectedMonthDays =
        sp.selectedDaysAMonth.length != habit.selectedDaysAMonth.length ||
        !sp.selectedDaysAMonth.every(
          (d) => habit.selectedDaysAMonth.contains(d),
        );
    final changedHabitColor =
        sp.getHabitColor(tp) != habit.resolveColor(tp) ||
        sp.habitColorName != habit.colorName;

    return changedName ||
        changedDesc ||
        changedCategory ||
        changedDuration ||
        changedAmount ||
        changedOptionalHabit ||
        changedIcon ||
        changedTimeIntervalEnabled ||
        changedTimeIntervalStart ||
        changedTimeIntervalEnd ||
        changedScheduleType ||
        changedWeeklyTarget ||
        changedMonthlyTarget ||
        changedCustomInterval ||
        changedSelectedWeekDays ||
        changedSelectedMonthDays ||
        changedHabitColor;
  }

  bool _hasCreateChanges(StateProvider sp) {
    final changedName = sp.nameController.text.trim().isNotEmpty;
    final changedDesc = sp.descController.text.trim().isNotEmpty;
    final changedCategory = sp.habitCategoryId != 1;
    final changedAmount = sp.habitAmount != 0;
    final changedDuration = sp.habitDuration != Duration.zero;
    final changedAmountLabel = sp.habitAmountLabelController.text != "times";
    final changedIcon =
        sp.iconPath.isNotEmpty && sp.iconPath != EmojiService.defaultEmoji;
    final changedOptional = sp.isOptional;
    final changedTimeIntervalEnabled = sp.timeIntervalEnabled;
    final changedTimeIntervalStart = sp.timeIntervalStart != 420;
    final changedTimeIntervalEnd = sp.timeIntervalEnd != 450;
    final changedScheduleType = sp.selectedScheduleOption != ScheduleType.daily;
    final changedWeeklyTarget = sp.weeklyTarget != 1;
    final changedMonthlyTarget = sp.monthlyTarget != 1;
    final changedCustomInterval = sp.customIntervalDays != 2;
    final changedSelectedWeekDays = sp.selectedDaysAWeek.isNotEmpty;
    final changedSelectedMonthDays = sp.selectedDaysAMonth.isNotEmpty;
    final changedColorName = sp.habitColorName != null;

    return changedName ||
        changedDesc ||
        changedCategory ||
        changedAmount ||
        changedDuration ||
        changedAmountLabel ||
        changedIcon ||
        changedOptional ||
        changedTimeIntervalEnabled ||
        changedTimeIntervalStart ||
        changedTimeIntervalEnd ||
        changedScheduleType ||
        changedWeeklyTarget ||
        changedMonthlyTarget ||
        changedCustomInterval ||
        changedSelectedWeekDays ||
        changedSelectedMonthDays ||
        changedColorName;
  }

  bool _hasUnsavedChanges(StateProvider sp, ThemeProvider tp) {
    if (_isEditMode) {
      return _hasEditChanges(sp, tp);
    }
    return _hasCreateChanges(sp);
  }

  void _popSheet() {
    if (!mounted) {
      return;
    }
    setState(() {
      _allowPop = true;
    });
    Navigator.of(context).pop();
  }

  Future<void> _showExitConfirmation() async {
    if (_isExitDialogOpen) {
      return;
    }

    _isExitDialogOpen = true;
    await showDialogSheet(
      context: context,
      builder:
          (dialogContext) => NewDefaultDialog(
            title: "Exit without saving?",
            desc: "All changes you made will be discarded.",
            primaryButtonLabel: "Exit",
            onPrimaryButtonPressed: () {
              Navigator.of(dialogContext).pop();
              _popSheet();
            },
          ),
    );
    _isExitDialogOpen = false;
  }

  Future<void> _handleCloseAttempt(StateProvider sp, ThemeProvider tp) async {
    if (_allowPop || !_hasUnsavedChanges(sp, tp)) {
      _popSheet();
      return;
    }

    await _showExitConfirmation();
  }

  Future<void> _saveHabit(StateProvider sp) async {
    final habitProvider = context.read<HabitProvider>();

    if (_isEditMode) {
      final tp = context.read<ThemeProvider>();
      final habit = widget.habit!;

      if (sp.habitAmount != habit.amount) {
        await habit.resetCompletion();
        habit.amount = sp.habitAmount;
      } else if (sp.habitDuration.inMinutes != habit.duration) {
        await habit.resetCompletion();
        habit.duration = sp.habitDuration.inMinutes;
      }

      habit.name = sp.nameController.text;
      habit.description = sp.descController.text;
      habit.categoryId = sp.habitCategoryId;
      habit.amountLabel = sp.habitAmountLabelController.text;
      habit.iconPath = sp.iconPath;
      habit.optional = sp.isOptional;
      habit.timeIntervalEnabled = sp.timeIntervalEnabled;
      habit.timeIntervalStart = sp.timeIntervalStart;
      habit.timeIntervalEnd = sp.timeIntervalEnd;
      habit.scheduleType = sp.selectedScheduleOption;
      habit.weeklyTarget = sp.weeklyTarget;
      habit.monthlyTarget = sp.monthlyTarget;
      habit.customIntervalDays = sp.customIntervalDays;
      habit.selectedDaysAWeek = sp.selectedDaysAWeek.toList()..sort();
      habit.selectedDaysAMonth = sp.selectedDaysAMonth.toList()..sort();

      if (habit.scheduleType == ScheduleType.custom) {
        habit.customAppearance = buildCustomAppearance(
          habit.customIntervalDays,
        );
        habit.lastCustomUpdate = DateTime.now().toUtc();
      }

      habit.colorName = sp.habitColorName;
      habit.color = colorToHex(sp.getHabitColor(tp) ?? tp.primaryColor);

      habitProvider.updateHabit(habit);
      sp.alertText = "Changes saved!";
      sp.toggleAlert(show: true);
      if (mounted) {
        _popSheet();
      }
      return;
    }

    habitProvider.addHabit(
      Habit(
        id: getUniqueId(),
        name: sp.nameController.text,
        description: sp.descController.text,
        iconPath: sp.iconPath,
        categoryId: sp.habitCategoryId,
        tag: "No tag",
        completed: false,
        skipped: false,
        amount: sp.habitAmount,
        amountLabel: sp.habitAmountLabelController.text,
        amountCompleted: 0,
        duration: sp.habitDuration.inMinutes,
        durationCompleted: 0,
        streak: 0,
        longestStreak: 0,
        optional: sp.isOptional,
        timeIntervalEnabled: sp.timeIntervalEnabled,
        timeIntervalStart: sp.timeIntervalStart,
        timeIntervalEnd: sp.timeIntervalEnd,
        scheduleType: sp.selectedScheduleOption,
        weeklyTarget: sp.weeklyTarget,
        monthlyTarget: sp.monthlyTarget,
        customIntervalDays: sp.customIntervalDays,
        selectedDaysAWeek: sp.selectedDaysAWeek.toList()..sort(),
        selectedDaysAMonth: sp.selectedDaysAMonth.toList()..sort(),
        customAppearance: buildCustomAppearance(sp.customIntervalDays),
        timesCompletedThisWeek: 0,
        timesCompletedThisMonth: 0,
        createdAt: DateTime.now().toUtc(),
        lastCustomUpdate: DateTime.now().toUtc(),
        colorName: sp.habitColorName,
      ),
    );

    if (mounted) {
      _popSheet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StateProvider>();
    final tp = context.watch<ThemeProvider>();
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    final maxSheetHeight = mediaQuery.size.height - 59 - 16;

    final hasName = sp.nameController.text.trim().isNotEmpty;
    final canSave =
        !_isInitializing &&
        hasName &&
        (!_isEditMode || _hasEditChanges(sp, tp));
    final hasUnsavedChanges = !_isInitializing && _hasUnsavedChanges(sp, tp);

    return PopScope(
      canPop: _allowPop || !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        await _handleCloseAttempt(sp, tp);
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: GestureDetector(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                child: Column(
                  spacing: 20,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    topSection(context, cp, sp, tp, canSave),
                    chooseIcon(cp, sp, context),
                    habitDetails(cp),
                    habitScheduling(cp),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Optional habit",
                          style: TextStyle(
                            color: cp.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        AnimatedCheckbox(
                          value: sp.isOptional,
                          onChanged: (value) {
                            setState(() {
                              sp.isOptional = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Column habitScheduling(ColorProvider cp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            'Schedule',
            style: TextStyle(
              color: cp.text,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SelectHabitScheduleType(),
        SelectHabitTypeWidgets(),
      ],
    );
  }

  Column habitDetails(ColorProvider cp) {
    final sp = context.read<StateProvider>();
    final habitNameController = sp.nameController;
    final habitNotesController = sp.descController;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            'Habit Details',
            style: TextStyle(
              color: cp.text,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        NewDefaultTextField(
          title: "Habit Name",
          hint: "Habit Name",
          controller: habitNameController,
        ),
        NewDefaultTextField(
          hint: "Notes",
          maxLines: 4,
          controller: habitNotesController,
        ),

        SelectHabitDayPeriod(),
      ],
    );
  }

  Column chooseIcon(ColorProvider cp, StateProvider sp, BuildContext context) {
    return Column(
      spacing: 20,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose icon',
          style: TextStyle(
            color: cp.text,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        NewDefaultButton(
          onPressed: () async {
            final emoji = await showEmojiKeyboardDialog(context, cp);
            if (emoji != null && context.mounted) {
              sp.iconPath = emoji;
            }
          },
          width: 84,
          height: 84,
          color: cp.field,
          padding: EdgeInsets.all(20),
          child: TextIcon(sp.iconPath.isEmpty ? "🏀" : sp.iconPath, size: 44),
        ),
      ],
    );
  }

  Padding topSection(
    BuildContext context,
    ColorProvider cp,
    StateProvider sp,
    ThemeProvider tp,
    bool canSave,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 36,
            width: 66,
            child: GestureDetector(
              onTap: () {
                _handleCloseAttempt(sp, tp);
              },
              child: Align(
                alignment: Alignment.centerLeft,
                child: SvgPicture.asset(
                  "assets/images/new-svg/back.svg",
                  colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          Text(
            _isEditMode ? 'Edit Habit' : 'New Habit',
            style: TextStyle(
              color: cp.text,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          NewDefaultButton.primarySmall(
            enabled: canSave,
            onPressed: () async {
              if (!canSave) {
                return;
              }
              await _saveHabit(sp);
            },
            label: "Save",
          ),
        ],
      ),
    );
  }
}

int getUniqueId() {
  final now = DateTime.now();
  final timeComponent = now.millisecondsSinceEpoch;
  final random = Random().nextInt(1000);
  return timeComponent * 1000 + random;
}

List<String> buildCustomAppearance(int intervalDays) {
  final start = DateTime.now();
  final anchor = DateTime(start.year, start.month, start.day);
  final output = <String>[];
  for (int i = 0; i < 180; i += intervalDays) {
    output.add(
      anchor.add(Duration(days: i)).toIso8601String().split('T').first,
    );
  }
  return output;
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/util/show_emoji_dialog.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:habitt/widgets/habit_details/new/select_habit_day_period.dart';
import 'package:habitt/widgets/habit_details/new/select_habit_schedule_type.dart';
import 'package:habitt/widgets/habit_details/new/select_habit_type.dart';
import 'package:habitt/widgets/habit_widget/text_icon.dart';
import 'package:provider/provider.dart';

class AddNewHabitSheet extends StatefulWidget {
  const AddNewHabitSheet({super.key});

  @override
  State<AddNewHabitSheet> createState() => _AddNewHabitSheetState();
}

class _AddNewHabitSheetState extends State<AddNewHabitSheet> {
  late final VoidCallback _nameListener;

  @override
  void initState() {
    super.initState();
    final sp = context.read<StateProvider>();
    _nameListener = () {
      if (mounted) {
        setState(() {});
      }
    };
    sp.nameController.addListener(_nameListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      sp.reset();
    });
  }

  @override
  void dispose() {
    context.read<StateProvider>().nameController.removeListener(_nameListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StateProvider>();
    final mediaQuery = MediaQuery.of(context);

    final maxSheetHeight = mediaQuery.size.height - 59 - 16;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          child: Column(
            spacing: 20,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              topSection(context, cp),
              chooseIcon(cp, sp, context),
              habitDetails(cp),
              habitScheduling(cp, context, sp),
            ],
          ),
        ),
      ),
    );
  }

  Column habitScheduling(
    ColorProvider cp,
    BuildContext context,
    StateProvider sp,
  ) {
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
        SelectHabitType(),
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

  Padding topSection(BuildContext context, ColorProvider cp) {
    final sp = context.read<StateProvider>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 36, // button height
            width: 66,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
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
            'New Habit',
            style: TextStyle(
              color: cp.text,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          NewDefaultButton.small(
            enabled: sp.nameController.text.isNotEmpty,
            onPressed: () {
              final habitProvider = context.read<HabitProvider>();
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
                  customAppearance: buildCustomAppearance(
                    sp.customIntervalDays,
                  ),
                  timesCompletedThisWeek: 0,
                  timesCompletedThisMonth: 0,
                  lastCustomUpdate: DateTime.now().toUtc(),
                  colorName: sp.habitColorName,
                ),
              );
              Navigator.of(context).pop();
            },
            label: "Done",
          ),
        ],
      ),
    );
  }
}

int getUniqueId() {
  final now = DateTime.now();
  // Milliseconds since epoch provides the time component
  final timeComponent = now.millisecondsSinceEpoch;

  // Generate a random number between 0 and 999
  final random = Random().nextInt(1000);

  // Combine them. This makes the ID much more unique.
  // The multiplication shifts the time component to make space for the random part.
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

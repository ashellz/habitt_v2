import 'package:cupertino_native/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/new_default_switch.dart';
import 'package:habitt/widgets/default/new_circle_button.dart';
import 'package:habitt/widgets/habit_widget/habit_icon.dart';
import 'package:habitt/widgets/habit_widget/new_habit_icon.dart';
import 'package:habitt/widgets/main_page/categories/new_categories_list.dart';
import 'package:habitt/widgets/main_page/habits/habit_widget/main_habit_info.dart';
import 'package:habitt/widgets/sheets/edit_habit_sheet.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  bool _isScheduledTodayOn = false;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final hp = context.watch<HabitProvider>();
    final habits = _isScheduledTodayOn ? hp.todaysHabits : hp.habits;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: ListView(
          children: [
            topSection(context, cp),
            NewCategoriesList(padding: null, standardColor: true),
            scheduledTodayToggle(cp),
            ReorderingHabits(todaysOnly: _isScheduledTodayOn),
          ],
        ),
      ),
    );
  }

  Container scheduledTodayToggle(ColorProvider cp) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cp.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Scheduled today',
            style: TextStyle(
              color: cp.text,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          NewDefaultSwitch(
            value: _isScheduledTodayOn,
            onChanged: (value) {
              debugPrint("Scheduled Today toggled: $value");
              setState(() {
                _isScheduledTodayOn = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Padding topSection(BuildContext context, ColorProvider cp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 16.0, right: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Habits List ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cp.text,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          NewCircleButton(
            svgPath: "assets/images/new-svg/plus.svg",
            cnIcon: CNSymbol("plus", size: 16),
            width: 36,
            height: 36,
            textColor: cp.bg,
            padding: EdgeInsets.all(10),
            color: cp.main,
            onPressed: () {
              final stateProvider = context.read<StateProvider>();
              stateProvider.reset();

              showModalBottomSheet(
                context: context,
                backgroundColor: cp.isDark ? cp.habitBg : cp.bg,
                barrierColor: cp.greyText.darken().withOpacity(0.3),
                isScrollControlled: true,
                builder: (context) {
                  return HabitSheet();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class ReorderingHabits extends StatelessWidget {
  const ReorderingHabits({super.key, required this.todaysOnly});

  final bool todaysOnly;

  @override
  Widget build(BuildContext context) {
    final hp = context.watch<HabitProvider>();
    final habits = todaysOnly ? hp.todaysHabits : hp.habits;
    final cp = context.watch<ColorProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,

            children: [
              for (final habit in habits)
                Container(
                  alignment: Alignment.topLeft,
                  width: (constraints.maxWidth - 10) / 2,
                  height: (constraints.maxWidth - 10) / 2,
                  key: ValueKey(habit.id),
                  padding: const EdgeInsets.all(16),
                  decoration: ShapeDecoration(
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(width: 1, color: cp.border),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          NewHabitIcon(
                            iconPath: habit.iconPath,
                            isCompleted: false,
                          ),
                          SvgPicture.asset(
                            "assets/images/new-svg/reorder.svg",
                            colorFilter: ColorFilter.mode(
                              cp.disabled,
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ),
                      MainHabitInfo(habit: habit, cp: cp),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

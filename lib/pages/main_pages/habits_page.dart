import 'package:cupertino_native/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/pages/other_pages/habit_details_page.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/util/show_new_habit_creation_flow.dart';
import 'package:habitt/widgets/default/new_default_switch.dart';
import 'package:habitt/widgets/default/new_circle_button.dart';
import 'package:habitt/widgets/habit_widget/new_habit_icon.dart';
import 'package:habitt/widgets/main_page/categories/new_categories_list.dart';
import 'package:habitt/widgets/main_page/habits/habit_widget/main_habit_info.dart';
import 'package:habitt/widgets/main_page/habits/new_habits.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';

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

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: ListView(
          children: [
            topSection(context, cp),
            NewCategoriesList(
              padding: null,
              standardColor: true,
              showAll: !_isScheduledTodayOn,
            ),
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
            'Habits List',
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
            onPressed: () => showNewHabitCreationFlow(context),
          ),
        ],
      ),
    );
  }
}

class ReorderingHabits extends StatefulWidget {
  const ReorderingHabits({super.key, required this.todaysOnly});

  final bool todaysOnly;

  @override
  State<ReorderingHabits> createState() => _ReorderingHabitsState();
}

class _ReorderingHabitsState extends State<ReorderingHabits> {
  @override
  Widget build(BuildContext context) {
    final hp = context.watch<HabitProvider>();
    final cp = context.watch<ColorProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    final scopedHabits = widget.todaysOnly ? hp.todaysHabits : hp.habits;
    final selectedCategoryId = categoryProvider.selectedCategoryId;
    final categories = categoryProvider.categories;
    final showCategoryTitles = selectedCategoryId == 0;

    final visibleCategories =
        categories.where((category) {
          if (selectedCategoryId != 0 && category.id != selectedCategoryId) {
            return false;
          }
          return scopedHabits.any((habit) => habit.categoryId == category.id);
        }).toList();

    if (visibleCategories.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: EmptyHabitsWidget(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (
            int sectionIndex = 0;
            sectionIndex < visibleCategories.length;
            sectionIndex++
          ) ...[
            if (sectionIndex > 0) const SizedBox(height: 18),
            if (showCategoryTitles)
              Text(
                visibleCategories[sectionIndex].name,
                style: TextStyle(
                  color: cp.lightGreyText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (showCategoryTitles) const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final categoryHabits =
                    scopedHabits
                        .where(
                          (habit) =>
                              habit.categoryId ==
                              visibleCategories[sectionIndex].id,
                        )
                        .toList()
                      ..sort((a, b) {
                        final orderCompare = a.order.compareTo(b.order);
                        if (orderCompare != 0) {
                          return orderCompare;
                        }
                        return a.id.compareTo(b.id);
                      });

                final cardSize = (constraints.maxWidth - 10) / 2;

                return ReorderableWrap(
                  spacing: 10,
                  runSpacing: 10,
                  onReorder: (oldIndex, newIndex) {
                    hp.reorderHabitsInCategory(
                      categoryId: visibleCategories[sectionIndex].id,
                      oldIndex: oldIndex,
                      newIndex: newIndex,
                      todaysOnly: widget.todaysOnly,
                    );
                  },
                  children: [
                    for (int index = 0; index < categoryHabits.length; index++)
                      _HabitCard(
                        key: ValueKey(categoryHabits[index].id),
                        habit: categoryHabits[index],
                        cp: cp,
                        size: cardSize,
                      ),
                  ],
                );
              },
            ),
          ],
          SizedBox(height: 50),
        ],
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.habit,
    required this.cp,
    required this.size,
    required Key key,
  }) : super(key: key);

  final Habit habit;
  final ColorProvider cp;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HabitDetailsPage(habitId: habit.id),
          ),
        );
      },
      child: Container(
        alignment: Alignment.topLeft,
        width: size,
        height: size,
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
                NewHabitIcon(iconPath: habit.iconPath, isCompleted: false),
                SvgPicture.asset(
                  "assets/images/new-svg/reorder.svg",
                  colorFilter: ColorFilter.mode(cp.disabled, BlendMode.srcIn),
                ),
              ],
            ),
            MainHabitInfo(habit: habit, cp: cp),
          ],
        ),
      ),
    );
  }
}

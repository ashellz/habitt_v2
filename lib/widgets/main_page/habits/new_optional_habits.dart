import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/pages/other_pages/habit_details_page.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/widgets/default/optional_habits_section.dart';
import 'package:habitt/widgets/main_page/habits/habit_widget/new_habit_widget.dart';
import 'package:provider/provider.dart';

/// Optional habits of the main page, shown under their own collapsible title
/// instead of inside the real categories.
class NewOptionalHabits extends StatelessWidget {
  const NewOptionalHabits({
    super.key,
    required this.habits,
    required this.dayKey,
  });

  final List<Habit> habits;
  final String dayKey;

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<PreferencesProvider>();

    return OptionalHabitsSection(
      count: habits.length,
      expanded: preferences.optionalHabitsExpanded,
      onToggle:
          () => preferences.setOptionalHabitsExpanded(
            !preferences.optionalHabitsExpanded,
          ),
      builder: (context, reveal) {
        return Column(
          children: [
            for (int index = 0; index < habits.length; index++)
              reveal(
                index,
                Padding(
                  key: ValueKey(
                    'optional-habit-fade-$dayKey-${habits[index].id}',
                  ),
                  padding: EdgeInsets.only(
                    bottom: index == habits.length - 1 ? 0 : 10,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      final habit = habits[index];

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          settings: RouteSettings(arguments: habit.id),
                          builder: (_) => HabitDetailsPage(habitId: habit.id),
                        ),
                      );
                    },
                    child: NewHabitWidget(
                      key: ValueKey('habit-row-$dayKey-${habits[index].id}'),
                      habit: habits[index],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

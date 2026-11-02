import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/pages/other_pages/habit_details_page.dart';
import 'package:habitt/widgets/default/optional_habits_section.dart';
import 'package:habitt/widgets/main_page/habits/habit_widget/new_habit_widget.dart';

// Collapsed by default and kept for the session, so it stays the way the user
// left it while they move between past days
bool _otherHabitsExpanded = false;

/// "Other habits" of a past day: habits that weren't scheduled that day (see
/// HabitProvider.otherHabitsForDay), so one that was done off-schedule, or a
/// "show if missed" habit the user forgot to tick, can still be logged late.
/// Logging progress moves it into the regular list for that day.
class NewOtherHabits extends StatefulWidget {
  const NewOtherHabits({super.key, required this.habits, required this.dayKey});

  final List<Habit> habits;
  final String dayKey;

  @override
  State<NewOtherHabits> createState() => _NewOtherHabitsState();
}

class _NewOtherHabitsState extends State<NewOtherHabits> {
  @override
  Widget build(BuildContext context) {
    final habits = widget.habits;

    return OptionalHabitsSection(
      title: AppLocalizations.of(context)!.otherHabits,
      count: habits.length,
      expanded: _otherHabitsExpanded,
      onToggle:
          () => setState(() => _otherHabitsExpanded = !_otherHabitsExpanded),
      builder: (context, reveal) {
        return Column(
          children: [
            for (int index = 0; index < habits.length; index++)
              reveal(
                index,
                Padding(
                  key: ValueKey(
                    'other-habit-fade-${widget.dayKey}-${habits[index].id}',
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
                      key: ValueKey(
                        'other-habit-row-${widget.dayKey}-${habits[index].id}',
                      ),
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

import 'package:flutter/material.dart';
import 'package:habitt/demo/demo_habits.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/habit_widget/habit_card.dart';
import 'package:provider/provider.dart';

/// Shows the sample habits from [demoHabits] as a card grid on the Habits
/// page when PreferencesProvider.showDemoHabits is on. Purely visual — these
/// habits are never written into HabitProvider/Hive, and unlike
/// [ReorderingHabits] this grid is a plain (non-reorderable) [Wrap] so there
/// is no drag-to-reorder callback that could try to look a demo habit up in
/// HabitProvider. [HabitCard]'s `isDemo` flag also disables tap-to-open.
class DemoHabitsGrid extends StatelessWidget {
  const DemoHabitsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.demoMode,
            style: TextStyle(
              color: cp.lightGreyText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardSize = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final habit in demoHabits)
                    HabitCard(
                      key: ValueKey('demo-habit-card-${habit.id}'),
                      habit: habit,
                      cp: cp,
                      size: cardSize,
                      isDemo: true,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/health_workout_type.dart';
import 'package:habitt/models/premade_habit_template.dart';
import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/premade_habit_catalog.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/habit_widget/text_icon.dart';
import 'package:provider/provider.dart';

class WorkoutTypePickerDialog extends StatelessWidget {
  const WorkoutTypePickerDialog({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final HealthWorkoutType? selected;
  final ValueChanged<HealthWorkoutType?> onSelected;

  static PremadeHabitTemplate get _anyTemplate =>
      PremadeHabitCatalog.byType(PremadeHabitType.workoutCombined)!;

  static List<PremadeHabitTemplate> get _workoutTemplates =>
      PremadeHabitCatalog.sections
          .firstWhere((section) => section.title == 'Workouts')
          .habits;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;
    final templates = [_anyTemplate, ..._workoutTemplates];

    return NewDefaultDialog(
      title: loc.healthWorkoutTypePickerTitle,
      overrideDefaultButtons: true,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children:
            templates
                .map((template) => _choice(context, cp, template, loc))
                .toList(),
      ),
    );
  }

  Widget _choice(
    BuildContext context,
    ColorProvider cp,
    PremadeHabitTemplate template,
    AppLocalizations loc,
  ) {
    final type = template.defaultWorkoutFilter;
    final isSelected = type == selected;

    return NewDefaultButton(
      onPressed: () {
        onSelected(type);
        if (Navigator.canPop(context)) Navigator.pop(context);
      },
      height: 50,
      color: isSelected ? cp.main : cp.field,
      textColor: isSelected ? cp.bg : cp.text,
      isGradient: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextIcon(template.iconPath, size: 24),
          const SizedBox(width: 10),
          Text(
            type == null ? loc.healthWorkoutFilterAny : type.label(loc),
            style: TextStyle(color: isSelected ? cp.bg : cp.text, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

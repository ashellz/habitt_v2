import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/health_provider.dart';
import 'package:habitt/util/health_source_name.dart';
import 'package:provider/provider.dart';

class HealthOverrideTag extends StatelessWidget {
  const HealthOverrideTag({
    super.key,
    required this.habit,
    required this.day,
    this.onReset,
    this.alignment = WrapAlignment.start,
  });

  final Habit habit;

  // the day the habit's progress is stored on
  final DateTime day;

  // called once the day is back on Health values
  final VoidCallback? onReset;

  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    if (habit.healthMetric == null || !habit.healthManualOverride) {
      return const SizedBox.shrink();
    }

    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    final source = healthSourceName();

    return Wrap(
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '${loc.healthEditedManually} · ',
          style: TextStyle(color: cp.lightGreyText, fontSize: 13),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _useHealthValues(context),
          child: Text(
            loc.healthUseSourceValues(source),
            style: TextStyle(
              color: cp.main,
              decoration: TextDecoration.underline,
              decorationColor: cp.main,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _useHealthValues(BuildContext context) async {
    final health = context.read<HealthProvider>();
    await health.useHealthValues(habit, day);
    onReset?.call();
  }
}

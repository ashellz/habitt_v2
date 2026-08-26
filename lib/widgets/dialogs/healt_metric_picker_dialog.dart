import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/premade_habit_catalog.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';

class HealthMetricPickerDialog extends StatelessWidget {
  const HealthMetricPickerDialog({super.key, required this.metrics});

  final List<HealthMetricType> metrics;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return NewDefaultDialog(
      title: loc.healthMetricPickerTitle,
      overrideDefaultButtons: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children:
            metrics
                .map((metric) => metricChoice(metric, context, loc))
                .toList(),
      ),
    );
  }

  Widget metricChoice(
    HealthMetricType metric,
    BuildContext context,
    AppLocalizations loc,
  ) {
    final selected = context.select<StateProvider, bool>(
      (s) => s.selectedHealthMetric == metric,
    );

    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StateProvider>();

    return GestureDetector(
      onTap: () {
        sp.selectedHealthMetric = metric;
        sp.selectedPremadeHabitType =
            PremadeHabitCatalog.byHealthConfig(
              metric,
              sp.selectedHealthWorkoutFilter,
            )?.type;
        if (Navigator.canPop(context)) Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? cp.main.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? cp.main.withValues(alpha: 0.2) : cp.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 12,
          children: [
            Image.asset(metric.iconPath, width: 28, height: 28),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.label(loc),
                    style: TextStyle(
                      color: cp.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    metric.desc(loc),
                    style: TextStyle(color: cp.greyText, fontSize: 13),
                  ),
                ],
              ),
            ),
            RotatedBox(
              quarterTurns: 3,
              child: SvgPicture.asset(
                "assets/images/new-svg/dropdown.svg",
                colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

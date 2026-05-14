import 'package:flutter/widgets.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/selectable_weekdays.dart';
import 'package:provider/provider.dart';

class SelectDaysWeekly extends StatefulWidget {
  const SelectDaysWeekly({super.key});

  @override
  State<SelectDaysWeekly> createState() => _SelectDaysWeeklyState();
}

class _SelectDaysWeeklyState extends State<SelectDaysWeekly> {
  Map<String, int> _weekdayMap(AppLocalizations loc) {
    return {
      loc.mon: 1,
      loc.tue: 2,
      loc.wed: 3,
      loc.thu: 4,
      loc.fri: 5,
      loc.sat: 6,
      loc.sun: 7,
    };
  }

  Set<String> _labelsFromIndices(Set<int> indices, AppLocalizations loc) {
    return _weekdayMap(loc).entries
        .where((entry) => indices.contains(entry.value))
        .map((entry) => entry.key)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StateProvider>();
    final selectedDays = _labelsFromIndices(sp.selectedDaysAWeek, loc);
    final weekdayMap = _weekdayMap(loc);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: cp.field,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(
            'Select days for this habit:',
            style: TextStyle(color: cp.greyText, fontSize: 16),
          ),
          SelectableWeekdays(
            selectedDays: selectedDays,
            onDaySelected: (day) {
              final dayValue = weekdayMap[day];
              if (dayValue == null) return;
              sp.toggleWeeklyDay(dayValue);
            },
          ),
        ],
      ),
    );
  }
}

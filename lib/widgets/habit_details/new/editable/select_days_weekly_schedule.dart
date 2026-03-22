import 'package:flutter/widgets.dart';
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
  static const Map<String, int> _weekdayMap = {
    'Mon': 1,
    'Tue': 2,
    'Wed': 3,
    'Thu': 4,
    'Fri': 5,
    'Sat': 6,
    'Sun': 7,
  };

  Set<String> _labelsFromIndices(Set<int> indices) {
    return _weekdayMap.entries
        .where((entry) => indices.contains(entry.value))
        .map((entry) => entry.key)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StateProvider>();
    final selectedDays = _labelsFromIndices(sp.selectedDaysAWeek);

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
              final dayValue = _weekdayMap[day];
              if (dayValue == null) return;
              sp.toggleWeeklyDay(dayValue);
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/default/selectable_month.dart';
import 'package:provider/provider.dart';

class SelectDaysMonthly extends StatefulWidget {
  const SelectDaysMonthly({super.key});

  @override
  State<SelectDaysMonthly> createState() => _SelectDaysMonthlyState();
}

class _SelectDaysMonthlyState extends State<SelectDaysMonthly> {
  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StateProvider>();
    final selectedDays = sp.selectedDaysAMonth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(
          'Select days for this habit:',
          style: TextStyle(color: cp.greyText, fontSize: 16),
        ),
        SelectableMonth(
          selectedDays: selectedDays,
          onDaySelected: (day) {
            sp.toggleMonthlyDay(day);
          },
        ),
      ],
    );
  }
}

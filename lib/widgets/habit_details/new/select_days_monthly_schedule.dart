import 'package:flutter/widgets.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/default/selectable_month.dart';
import 'package:provider/provider.dart';

class SelectDaysMonthly extends StatefulWidget {
  const SelectDaysMonthly({super.key});

  @override
  State<SelectDaysMonthly> createState() => _SelectDaysMonthlyState();
}

class _SelectDaysMonthlyState extends State<SelectDaysMonthly> {
  final Set<String> _selectedDays = {};

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(
          'Select days for this habit:',
          style: TextStyle(color: cp.greyText, fontSize: 16),
        ),
        SelectableMonth(
          selectedDays: _selectedDays,
          onDaySelected: (day) {
            setState(() {
              if (_selectedDays.contains(day)) {
                _selectedDays.remove(day);
              } else {
                _selectedDays.add(day);
              }
            });
          },
        ),
      ],
    );
  }
}

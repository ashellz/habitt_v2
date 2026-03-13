import 'package:flutter/widgets.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/default/selectable_weekdays.dart';
import 'package:provider/provider.dart';

class SelectDaysWeekly extends StatefulWidget {
  const SelectDaysWeekly({super.key});

  @override
  State<SelectDaysWeekly> createState() => _SelectDaysWeeklyState();
}

class _SelectDaysWeeklyState extends State<SelectDaysWeekly> {
  final Set<String> _selectedDays = {};

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

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
      ),
    );
  }
}

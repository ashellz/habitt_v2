import 'package:flutter/material.dart';
import 'package:habitt/widgets/select_habit_type_widget.dart';

class SelectHabitTypeOptions extends StatefulWidget {
  const SelectHabitTypeOptions({super.key});

  @override
  State<SelectHabitTypeOptions> createState() => _SelectHabitTypeOptionsState();
}

class _SelectHabitTypeOptionsState extends State<SelectHabitTypeOptions> {
  HabitType selectedType = HabitType.none;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            SelectHabitTypeWidget(
              type: HabitType.amount,
              selectedType: selectedType,
              onTap:
                  () => setState(() {
                    selectedType =
                        selectedType == HabitType.amount
                            ? HabitType.none
                            : HabitType.amount;
                  }),
            ),

            SelectHabitTypeWidget(
              type: HabitType.duration,
              selectedType: selectedType,
              onTap:
                  () => setState(() {
                    selectedType =
                        selectedType == HabitType.duration
                            ? HabitType.none
                            : HabitType.duration;
                  }),
            ),
          ],
        ),
      ),
    );
  }
}

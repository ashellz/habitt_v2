import 'package:flutter/material.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/select_habit_type_widget.dart';
import 'package:habitt/pages/other_pages/enter_amount_page.dart';
import 'package:provider/provider.dart';

class SelectHabitTypeOptions extends StatefulWidget {
  const SelectHabitTypeOptions({super.key});

  @override
  State<SelectHabitTypeOptions> createState() => _SelectHabitTypeOptionsState();
}

class _SelectHabitTypeOptionsState extends State<SelectHabitTypeOptions> {
  HabitType selectedType = HabitType.none;

  @override
  Widget build(BuildContext context) {
    final stateProvider = context.watch<StateProvider>();

    return Padding(
      padding: EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            SelectHabitTypeWidget(
              type: HabitType.amount,
              selectedType: selectedType,
              onTap: () {
                setState(() {
                  selectedType =
                      selectedType == HabitType.amount
                          ? HabitType.none
                          : HabitType.amount;
                });

                if (selectedType == HabitType.none) {
                  stateProvider.habitAmount = 0;
                } else if (selectedType == HabitType.amount) {
                  stateProvider.habitDuration = Duration.zero;
                  stateProvider.habitAmount = 2;
                  Future.delayed(Duration(milliseconds: 150)).then((value) {
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => NumberPickerScreen(),
                        ),
                      );
                    }
                  });
                }
              },
            ),

            SelectHabitTypeWidget(
              type: HabitType.duration,
              selectedType: selectedType,
              onTap: () {
                setState(() {
                  selectedType =
                      selectedType == HabitType.duration
                          ? HabitType.none
                          : HabitType.duration;
                });

                if (selectedType == HabitType.none) {
                  stateProvider.habitDuration = Duration.zero;
                } else if (selectedType == HabitType.duration) {
                  stateProvider.habitAmount = 0;
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

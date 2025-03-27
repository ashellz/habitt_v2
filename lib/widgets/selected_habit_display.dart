import 'package:flutter/material.dart';
import 'package:habitt/generated/assets.gen.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/habit_widget/habit_widget.dart';
import 'package:provider/provider.dart';

class SelectedHabitDisplay extends StatelessWidget {
  const SelectedHabitDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final stateProvider = context.watch<StateProvider>();
    final descController = stateProvider.descController;
    final nameController = stateProvider.nameController;
    final amount = stateProvider.habitAmount;
    final duration = stateProvider.habitDuration.inMinutes;
    final iconPath = stateProvider.iconPath;

    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: descController,
        builder:
            (context, value, child) => ValueListenableBuilder<TextEditingValue>(
              valueListenable: nameController,
              builder:
                  (context, value, child) => HabitWidget(
                    name: value.text == "" ? "Habit Name" : value.text,
                    desc: descController.text,
                    iconPath:
                        iconPath == ""
                            ? Assets.images.icons.book.path
                            : iconPath,
                    streak: 0,
                    amount: amount,
                    duration: duration,
                    amountCompleted: 0,
                    durationCompleted: 0,
                    completed: false,
                    editable: true,
                  ),
            ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/emoji_service.dart';
import 'package:habitt/widgets/habit_widget/old_habit_widget.dart';
import 'package:provider/provider.dart';

// DEPRACATED, LEGACY, NOT USED

class SelectedHabitDisplay extends StatelessWidget {
  const SelectedHabitDisplay({
    super.key,
    required this.streak,
    required this.amountCompleted,
    required this.durationCompleted,
    required this.completed,
    required this.skipped,
  });

  final int streak;
  final int amountCompleted;
  final int durationCompleted;
  final bool completed;
  final bool skipped;

  @override
  Widget build(BuildContext context) {
    final stateProvider = context.watch<StateProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final descController = stateProvider.descController;
    final nameController = stateProvider.nameController;
    final amount = stateProvider.habitAmount;
    final duration = stateProvider.habitDuration.inSeconds;
    final iconPath = stateProvider.iconPath;

    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: descController,
        builder:
            (context, value, child) => ValueListenableBuilder<TextEditingValue>(
              valueListenable: nameController,
              builder:
                  (context, value, child) => OldHabitWidget(
                    isFirstCategory: true,
                    habit: Habit(
                      id: 0,
                      categoryId: categoryProvider.selectedCategoryId,
                      name: value.text == "" ? "Habit name" : value.text,
                      description: descController.text,
                      iconPath:
                          iconPath == "" ? EmojiService.defaultEmoji : iconPath,
                      streak: streak,
                      amount: amount,
                      duration: duration,
                      amountCompleted: amountCompleted,
                      durationCompleted: durationCompleted,
                      completed: completed,
                      skipped: skipped,
                      colorName: stateProvider.habitColorName,
                    ),
                    editable: true,
                  ),
            ),
      ),
    );
  }
}

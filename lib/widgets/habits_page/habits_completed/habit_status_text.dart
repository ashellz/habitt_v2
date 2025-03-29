import 'package:flutter/material.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:habitt/util/get_category_length.dart';
import 'package:provider/provider.dart';

class HabitsStatus extends StatelessWidget {
  const HabitsStatus({super.key, required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final int selectedCategoryId = categoryProvider.selectedCategoryId;
    final textColor = colorProvider.textColor;
    final colorScheme = colorProvider.colorScheme;
    final localizations = AppLocalizations.of(context)!;

    int numberOfHabits = 0;

    if (isCompleted) {
      for (var category in categoryProvider.categories) {
        if (category.id == selectedCategoryId) {
          numberOfHabits = getCompletedHabits(category, context);
        }
      }
    } else {
      for (var category in categoryProvider.categories) {
        if (category.id == selectedCategoryId) {
          numberOfHabits = getNotCompletedHabits(category, context);
        }
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isCompleted
                        ? colorScheme.vividColor
                        : colorScheme.strokeColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Text(
                isCompleted
                    ? localizations.completed
                    : localizations.notCompleted,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        Text(
          "$numberOfHabits ${numberOfHabits == 1 ? localizations.habit : localizations.habits}",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

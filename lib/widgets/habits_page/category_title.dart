import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/get_category_length.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class HabitCategoryTitle extends StatelessWidget {
  const HabitCategoryTitle({super.key, required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final localizations = AppLocalizations.of(context)!;
    final int categoryHabits = getCategoryLength(category, context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          category.name,
          style: TextStyle(color: colorProvider.mutedTextColor),
        ),
        Text(
          "$categoryHabits ${categoryHabits == 1 ? localizations.habit : localizations.habits}",
          style: TextStyle(color: colorProvider.mutedTextColor),
        ),
      ],
    );
  }
}

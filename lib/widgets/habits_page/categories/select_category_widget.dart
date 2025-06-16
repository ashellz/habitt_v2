import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/get_category_length.dart';
import 'package:habitt/util/get_localized_category_name.dart';
import 'package:provider/provider.dart';

class SelectCategoryWidget extends StatelessWidget {
  const SelectCategoryWidget({
    super.key,
    required this.category,
    this.onTap,
    required this.habitsCount,
    required this.standardColor,
    this.useHabitCategory = false,
  });

  final Category category;
  final VoidCallback? onTap;
  final bool habitsCount;
  final bool standardColor;
  final bool useHabitCategory;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final ColorProvider colorProvider = context.watch<ColorProvider>();
    final StateProvider stateProvider = context.watch<StateProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    final colorScheme = colorProvider.colorScheme;
    final int selectedId =
        useHabitCategory
            ? stateProvider.habitCategoryId
            : categoryProvider.selectedCategoryId;
    final bool isSelected = category.id == selectedId;
    final int categoryHabits = getCategoryLength(category, context);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.decelerate,
          decoration: BoxDecoration(
            color:
                isSelected
                    ? standardColor
                        ? colorProvider.standardColor
                        : colorScheme.standardColor
                    : standardColor
                    ? colorProvider.disabledColor
                    : colorScheme.disabledColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected
                      ? standardColor
                          ? colorScheme.strokeColor
                          : colorScheme.vividColor
                      : colorScheme.standardColor,
              width: 2,
            ),
          ),
          padding: EdgeInsets.fromLTRB(12, 8, isSelected ? 63 : 12, 8),
          height: 56,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                curve: Curves.decelerate,
                alignment: isSelected ? Alignment.center : Alignment.centerLeft,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: isSelected ? 1.0 : 0.5,
                  child: Text(
                    getLocalizedCategoryName(category, localizations),
                    style: TextStyle(
                      color: colorProvider.textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 150),
                curve: Curves.decelerate,
                child:
                    isSelected
                        ? Text(
                          habitsCount
                              ? "$categoryHabits ${categoryHabits == 1 ? localizations.habit : localizations.habits}"
                              : localizations.selected,
                          style: TextStyle(
                            fontSize: 10,
                            color: colorProvider.mutedTextColor,
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

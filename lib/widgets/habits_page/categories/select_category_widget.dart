import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/calendar_provider.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
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
    this.selectedDay,
  });

  final Category category;
  final VoidCallback? onTap;
  final bool habitsCount;
  final bool standardColor;
  final bool useHabitCategory;
  final DateTime? selectedDay;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final tp = context.watch<ThemeProvider>();
    final StateProvider stateProvider = context.watch<StateProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final calendarProvider = context.watch<CalendarProvider>();

    final int selectedId =
        useHabitCategory
            ? stateProvider.habitCategoryId
            : selectedDay == null
            ? categoryProvider.selectedCategoryId
            : calendarProvider.selectedCategoryId;
    final bool isSelected = category.id == selectedId;
    final int categoryHabits = getCategoryLength(
      category,
      context,
      true,
      selectedDay,
    );

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
                        ? tp.surfaceColor
                        : tp.elevatedSurfaceColor
                    : standardColor
                    ? tp.surfaceColor
                    : tp.surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
                  isSelected
                      ? standardColor
                          ? tp.primaryColor
                          : tp.primaryColor
                      : tp.surfaceColor,
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
                    getLocalizedCategoryName(category, loc),
                    style: TextStyle(
                      color: tp.primaryTextColor,
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
                              ? "$categoryHabits ${categoryHabits == 1 ? loc.habit : loc.habits}"
                              : loc.selected,
                          style: TextStyle(
                            fontSize: 10,
                            color: tp.secondaryTextColor,
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

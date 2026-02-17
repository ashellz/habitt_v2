import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/providers/calendar_provider.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/util/get_localized_category_name.dart';
import 'package:provider/provider.dart';

class NewSelectCategoryWidget extends StatelessWidget {
  const NewSelectCategoryWidget({
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
    final localizations = AppLocalizations.of(context)!;
    final cp = context.watch<ColorProvider>();
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

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(
          right: category.id == 4 ? 16.0 : 8.0,
          left: category.id == 0 ? 16.0 : 0,
        ), // Add left padding for the first item
        child: Container(
          decoration: ShapeDecoration(
            shape: StadiumBorder(),
            color: isSelected ? cp.main : cp.bg,
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
          child: Text(
            getLocalizedCategoryName(category, localizations),
            style: TextStyle(
              color: isSelected ? cp.bg : cp.lightGreyText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

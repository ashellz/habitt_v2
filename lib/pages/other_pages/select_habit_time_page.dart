import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/get_localized_category_name.dart';
import 'package:habitt/widgets/faded_list_view.dart';
import 'package:habitt/widgets/gradient_background.dart';
import 'package:provider/provider.dart';

class SelectHabitTimePage extends StatelessWidget {
  const SelectHabitTimePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final stateProvider = context.watch<StateProvider>();

    final selectedCategory = stateProvider.habitCategoryId;

    Category getCategoryById(int id) {
      final categoryProvider = context.read<CategoryProvider>();
      return categoryProvider.categories.firstWhere((c) => c.id == id);
    }

    final listViewHeight = MediaQuery.of(context).size.height - 293;

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: colorProvider.backgroundColor,
        statusBarIconBrightness:
            colorProvider.isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            colorProvider.isDarkMode
                ? Brightness.dark
                : Brightness.light, // for iOS
      ),
      child: Scaffold(
        backgroundColor: colorProvider.backgroundColor,
        body: GradientBackground(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SELECT HABIT TIME FOR",
                    style: TextStyle(
                      letterSpacing: 2,
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      height: 1.2,
                      color: colorProvider.colorScheme.vividColor,
                    ),
                  ),
                  Text(
                    getLocalizedCategoryName(
                      getCategoryById(selectedCategory),
                      AppLocalizations.of(context)!,
                    ),
                    style: TextStyle(
                      fontSize: 56,
                      height: 0,
                      fontWeight: FontWeight.bold,
                      color: colorProvider.textColor,
                    ),
                  ),
                  FadedListView(
                    scrollDirection: Axis.vertical,
                    height: listViewHeight,
                    children: [
                      for (int i = 0; i < 24; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            "${i.toString().padLeft(2, '0')}:00",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colorProvider.textColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

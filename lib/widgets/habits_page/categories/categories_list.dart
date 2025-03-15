import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/widgets/habits_page/categories/select_category_widget.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CategoriesList extends StatefulWidget {
  const CategoriesList({super.key});

  @override
  State<CategoriesList> createState() => _CategoriesListState();
}

class _CategoriesListState extends State<CategoriesList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedCategory();
    });
  }

  void _scrollToSelectedCategory() {
    final categoryProvider = context.read<CategoryProvider>();
    final selectedId = categoryProvider.selectedCategoryId;
    List<Category> categories = categoryProvider.categories;

    if (_scrollController.hasClients && categories.isNotEmpty) {
      int selectedIndex = categories.indexWhere((c) => c.id == selectedId) + 1;
      if (selectedIndex != -1) {
        // Estimate position by multiplying index by item width (assumed 120px)
        double itemWidth = 120.0; // Adjust based on actual category width
        double screenWidth = MediaQuery.of(context).size.width;
        double scrollOffset =
            (selectedIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

        // (selectedIndex * itemWidth) --> Gets to the end of the selected category
        // (screenWidth / 2) --> Gets to the middle of the screen
        // (itemWidth / 2) --> Gets to the middle of the category

        _scrollController.animateTo(
          scrollOffset.clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          ), // Keep within bounds
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final categoryProvider = context.watch<CategoryProvider>();
    final habitProvider = context.watch<HabitProvider>();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: SizedBox(
        height: 56,
        child: ListView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          children: [
            SelectCategoryWidget(
              category: Category(
                id: 0,
                name: localizations.all,
                habits: habitProvider.habits.length,
              ),
              onTap: () {
                categoryProvider.selectCategory(0);
                _scrollToSelectedCategory();
              },
            ),
            for (final category in categoryProvider.categories)
              SelectCategoryWidget(
                category: category,
                onTap: () {
                  categoryProvider.selectCategory(category.id);
                  _scrollToSelectedCategory();
                },
              ),
          ],
        ),
      ),
    );
  }
}

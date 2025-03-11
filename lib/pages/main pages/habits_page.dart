import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/gradient_background.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:habitt/widgets/habits_page/greeting.dart';
import 'package:provider/provider.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorProvider = context.watch<ColorProvider>();

    return Scaffold(
      body: DefaultTextStyle(
        style: TextStyle(color: Color(0xFF212529)),
        child: GradientBackground(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView(
              physics: BouncingScrollPhysics(),
              children: [Greeting(), CategoriesList()],
            ),
          ),
        ),
      ),
    );
  }
}

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
    final categories = categoryProvider.categories;

    if (_scrollController.hasClients && categories.isNotEmpty) {
      int selectedIndex = categories.indexWhere((c) => c.id == selectedId);
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
    final categoryProvider = context.watch<CategoryProvider>();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: SizedBox(
        height: 56,
        child: ListView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          children: [
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

class SelectCategoryWidget extends StatelessWidget {
  const SelectCategoryWidget({super.key, required this.category, this.onTap});

  final Category category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = context.watch<ColorProvider>().colorScheme;
    final categoryProvider = context.watch<CategoryProvider>();
    final int selectedId = categoryProvider.selectedCategoryId;
    final bool isSelected = category.id == selectedId;

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
                    ? colorScheme.standardColor
                    : colorScheme.disabledColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected
                      ? colorScheme.vividColor
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
                    category.name,
                    style: const TextStyle(
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
                          "${category.habits} ${localizations.habits}",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6C757D),
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

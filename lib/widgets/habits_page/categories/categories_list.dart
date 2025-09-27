import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/pages/other_pages/select_habit_time_page.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/habits_page/categories/select_category_widget.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class CategoriesList extends StatefulWidget {
  const CategoriesList({
    super.key,
    this.topPadding = 16,
    this.standardColor = false,
    this.showAll = true,
    this.habitsCount = true,
    this.useHabitCategory = false,
  });

  final double topPadding;
  final bool standardColor;
  final bool showAll;
  final bool habitsCount;
  final bool useHabitCategory;

  @override
  State<CategoriesList> createState() => _CategoriesListState();
}

class _CategoriesListState extends State<CategoriesList> {
  final ScrollController _scrollController = ScrollController();

  // --- NEW: State variables to control the fade visibility ---
  bool _showLeftFade = false;
  bool _showRightFade = false;

  @override
  void initState() {
    super.initState();
    // --- NEW: Add a listener to the scroll controller ---
    _scrollController.addListener(_updateFadeVisibility);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // --- NEW: Check initial scroll state after first layout ---
      _updateFadeVisibility();
      _scrollToSelectedCategory();
    });
  }

  // --- NEW: Clean up the controller and listener ---
  @override
  void dispose() {
    _scrollController.removeListener(_updateFadeVisibility);
    _scrollController.dispose();
    super.dispose();
  }

  // --- NEW: Method to update fade state based on scroll position ---
  void _updateFadeVisibility() {
    // Ensure the controller is attached to a widget
    if (!_scrollController.hasClients) return;

    // Determine if the list can scroll at all
    final bool canScroll = _scrollController.position.maxScrollExtent > 0;

    // Check if we are at the very beginning
    final bool atLeftEdge =
        _scrollController.position.pixels <=
        _scrollController.position.minScrollExtent;

    // Check if we are at the very end
    final bool atRightEdge =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent;

    // Update the state variables and rebuild if necessary
    if (mounted) {
      setState(() {
        _showLeftFade = canScroll && !atLeftEdge;
        _showRightFade = canScroll && !atRightEdge;
      });
    }
  }

  void _scrollToSelectedCategory() {
    final categoryProvider = context.read<CategoryProvider>();
    final stateProvider = context.read<StateProvider>();
    final selectedId =
        widget.useHabitCategory
            ? stateProvider.habitCategoryId
            : categoryProvider.selectedCategoryId;
    List<Category> categories = categoryProvider.categories;

    if (_scrollController.hasClients && categories.isNotEmpty) {
      int selectedIndex = categories.indexWhere((c) => c.id == selectedId) + 1;
      if (selectedIndex != -1) {
        // Estimate position by multiplying index by item width (assumed 120px)
        double itemWidth = 110.0; // Adjust based on actual category width
        double screenWidth = MediaQuery.of(context).size.width;
        double scrollOffset =
            (selectedIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

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
    final stateProvider = context.watch<StateProvider>();
    final habitsList = habitProvider.habits;
    final List<bool> hasHabits = [];

    for (Category category in categoryProvider.categories) {
      int categoryHabits =
          habitsList
              .where((habit) => habit.categoryId == category.id)
              .toList()
              .length;
      hasHabits.add(categoryHabits > 0);
    }

    return Padding(
      padding: EdgeInsets.only(top: widget.topPadding),
      // --- NEW: Wrap the list with ShaderMask to apply the fade effect ---
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: _showLeftFade ? 1 : 0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.decelerate,
        builder: (context, double leftValue, child) {
          return TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: _showRightFade ? 1 : 0),
            duration: const Duration(milliseconds: 500),

            curve: Curves.decelerate,
            builder: (context, double rightValue, child) {
              return ShaderMask(
                shaderCallback: (Rect bounds) {
                  // Create a linear gradient for the mask
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    // Dynamically set colors based on fade visibility state
                    colors: <Color>[
                      Color.lerp(Colors.white, Colors.transparent, leftValue)!,
                      Colors.white,
                      Colors.white,
                      Color.lerp(Colors.white, Colors.transparent, rightValue)!,
                    ],
                    // Define the stops to control where the fade starts and ends
                    // 0.0 to 0.05: Left fade area
                    // 0.05 to 0.95: Fully visible area
                    // 0.95 to 1.0: Right fade area
                    stops: const <double>[0.0, 0.05, 0.95, 1.0],
                  ).createShader(bounds);
                },
                // This blend mode applies the alpha channel of the shader to the child.
                // Where the shader is transparent, the child becomes transparent.
                blendMode: BlendMode.dstIn,
                child: SizedBox(
                  height: 56,
                  child: ListView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (widget.showAll)
                        SelectCategoryWidget(
                          standardColor: widget.standardColor,
                          habitsCount: widget.habitsCount,
                          category: Category(id: 0, name: localizations.all),
                          onTap: () {
                            categoryProvider.selectCategory(0);
                            _scrollToSelectedCategory();
                          },
                        ),
                      Row(
                        children: List.generate(
                          categoryProvider.categories.length,
                          (index) {
                            Category category =
                                categoryProvider.categories[index];
                            if (widget.showAll) {
                              if (!hasHabits[index]) {
                                return Container();
                              }
                            }

                            return SelectCategoryWidget(
                              useHabitCategory: widget.useHabitCategory,
                              standardColor: widget.standardColor,
                              habitsCount: widget.habitsCount,
                              category: category,
                              onTap: () {
                                if (widget.useHabitCategory) {
                                  stateProvider.habitCategoryId = category.id;
                                  _scrollToSelectedCategory();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) => SelectHabitTimePage(),
                                    ),
                                  );
                                  return;
                                }
                                categoryProvider.selectCategory(category.id);
                                _scrollToSelectedCategory();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

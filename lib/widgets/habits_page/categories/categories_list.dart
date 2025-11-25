import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
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
    if (!_scrollController.hasClients) return;

    final categoryProvider = context.read<CategoryProvider>();
    final habitProvider = context.read<HabitProvider>();
    final stateProvider = context.read<StateProvider>();
    final localizations = AppLocalizations.of(context)!;

    final viewportWidth = _scrollController.position.viewportDimension;
    if (viewportWidth == 0) return;

    // Build the actually visible items (respecting showAll + hasHabits filter)
    final categories = categoryProvider.categories;
    final habits = habitProvider.habits;

    final List<int> ids = [];
    final List<String> labels = [];

    if (widget.showAll) {
      ids.add(0);
      labels.add(localizations.all);
    }

    for (int i = 0; i < categories.length; i++) {
      final c = categories[i];
      if (widget.showAll) {
        final count = habits.where((h) => h.categoryId == c.id).length;
        if (count == 0) continue; // matches the UI filter
      }
      ids.add(c.id);
      labels.add(c.name);
    }

    if (ids.isEmpty) return;

    // Resolve selected id/index within the visible items
    final selectedId =
        widget.useHabitCategory
            ? stateProvider.habitCategoryId
            : categoryProvider.selectedCategoryId;
    int selectedIndex = ids.indexOf(selectedId);
    if (selectedIndex == -1) selectedIndex = 0;

    // Measure text widths like in the commented example
    final textStyle =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final textPainters =
        labels.map((text) {
          final tp = TextPainter(
            text: TextSpan(text: text, style: textStyle),
            textDirection: TextDirection.ltr,
          );
          tp.layout();
          return tp;
        }).toList();

    final textsSpace = textPainters.fold<double>(
      0.0,
      (sum, tp) => sum + tp.width,
    );

    // Distribute remaining space as horizontal padding per item
    final sidePadding = math.max(
      12.0,
      (viewportWidth - textsSpace) / ids.length / 2,
    );

    // Item widths = text width + horizontal padding on both sides
    final itemWidths = List<double>.generate(
      ids.length,
      (i) => textPainters[i].width + (sidePadding * 2),
    );

    // Center the selected item
    final leading = itemWidths
        .take(selectedIndex)
        .fold<double>(0.0, (a, b) => a + b);
    final selectedWidth = itemWidths[selectedIndex];
    final itemCenterOffset = leading + (selectedWidth / 2);
    final targetScroll = itemCenterOffset - (viewportWidth / 2);

    _scrollController.animateTo(
      targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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

/*
import 'dart:math';

import 'package:eyelan/functions/is_tablet.dart';
import 'package:eyelan/services/color_service.dart';
import 'package:eyelan/widgets/faded_list_view.dart';
import 'package:flutter/material.dart';

class AnimatedTabBar extends StatefulWidget {
  const AnimatedTabBar({
    super.key,
    required this.tabs,
    required this.onTabSelected,
    required this.index,
  });

  final List<String> tabs;
  final ValueChanged<int>? onTabSelected;
  final int index;

  @override
  State<AnimatedTabBar> createState() => _AnimatedTabBarState();
}

class _AnimatedTabBarState extends State<AnimatedTabBar> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _animateToTab(int index, List<double> itemWidths, double viewportWidth) {
    // sum widths of items before 'index'

    final leading = itemWidths.take(index).fold(0.0, (sum, w) => sum + w);
    final selectedWidth = itemWidths[index];
    final itemCenterOffset = leading + (selectedWidth / 2);
    final targetScroll = itemCenterOffset - (viewportWidth / 2);

    final maxScroll = _scrollController.position.maxScrollExtent;
    final clamped = targetScroll.clamp(0.0, maxScroll);
    _scrollController.animateTo(
      clamped,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tabsSpace =
        screenWidth -
        (isTablet(context) ? 64 : 32) -
        (isTablet(context) ? 48 : 24); // outer and inner padding

    final textPainters = widget.tabs.map((text) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(letterSpacing: -0.28),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      return textPainter;
    }).toList();

    final textsSpace = textPainters
        .map((textPainter) => textPainter.width)
        .fold(0.0, (a, b) => a + b);
    final double sidePadding = max(
      12,
      (tabsSpace - textsSpace) / widget.tabs.length / 2,
    );

    final itemWidths = List<double>.generate(
      widget.tabs.length,
      (i) => textPainters[i].width + (sidePadding * 2),
    );

    return SizedBox(
      height: 44, // fixed height for tabs
      width: tabsSpace,
      child: FadedListView(
        height: 44,
        scrollDirection: Axis.horizontal,
        scrollController: _scrollController,
        children: List.generate(widget.tabs.length, (index) {
          final bool isSelected = index == widget.index;

          return GestureDetector(
            onTap: () {
              widget.onTabSelected!(index);
              _animateToTab(index, itemWidths, tabsSpace);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 8),
              height: 44,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? ColorService.blue200
                        : ColorService.white25,
                    width: isSelected ? 2 : 1,
                  ),
                ),
              ),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: isSelected
                        ? ColorService.blue200
                        : Colors.grey.shade600,
                    letterSpacing: -0.28,
                  ),
                  child: Text(widget.tabs[index], textAlign: TextAlign.center),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

 */

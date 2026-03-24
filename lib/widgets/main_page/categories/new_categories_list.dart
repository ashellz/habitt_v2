import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/widgets/main_page/categories/new_select_category.dart';
import 'package:provider/provider.dart';

class NewCategoriesList extends StatefulWidget {
  const NewCategoriesList({
    super.key,
    this.padding = const EdgeInsets.only(top: 16.0),
    this.standardColor = false,
    this.habitsCount = true,
    this.selectedDay,
  });

  final EdgeInsets? padding;
  final bool standardColor;
  final bool habitsCount;
  final DateTime? selectedDay;

  @override
  State<NewCategoriesList> createState() => _NewCategoriesListState();
}

class _NewCategoriesListState extends State<NewCategoriesList> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listKey = GlobalKey();
  final Map<int, GlobalKey> _itemKeys = {};

  GlobalKey _keyFor(int id) => _itemKeys.putIfAbsent(id, () => GlobalKey());

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedCategory();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<int> _visibleCategoryIds(List habitsList) {
    final categoryProvider = context.read<CategoryProvider>();
    final visibleIds = <int>[];

    visibleIds.add(0);

    for (final category in categoryProvider.categories) {
      final hasHabits =
          habitsList
              .where((habit) => habit.categoryId == category.id)
              .isNotEmpty;
      if (!hasHabits) {
        continue;
      }

      visibleIds.add(category.id);
    }

    return visibleIds;
  }

  void _animateToTab(int index, List<double> itemWidths, double viewportWidth) {
    final leading = itemWidths.take(index).fold(0.0, (sum, w) => sum + w);
    final selectedWidth = itemWidths[index];
    final itemCenterOffset = leading + (selectedWidth / 2);
    debugPrint(
      "Leading: $leading, Selected width: $selectedWidth, Item center offset: $itemCenterOffset",
    );
    final targetScroll = itemCenterOffset - ((viewportWidth + 32) / 2);
    debugPrint("Calculated target scroll: $targetScroll");

    final maxScroll = _scrollController.position.maxScrollExtent;

    final clamped = targetScroll.clamp(0.0, maxScroll);
    debugPrint("Clamped target scroll: $clamped (Max scroll: $maxScroll)");
    _scrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToSelectedCategory() {
    if (!_scrollController.hasClients) return;

    final categoryProvider = context.read<CategoryProvider>();
    final habitProvider = context.read<HabitProvider>();
    final habitsList =
        widget.selectedDay == null
            ? habitProvider.todaysHabits
            : habitProvider.getHabitsForDate(widget.selectedDay!);

    final selectedId = categoryProvider.selectedCategoryId;
    final visibleIds = _visibleCategoryIds(habitsList);
    for (var id in visibleIds) {
      debugPrint("Visible category ID: $id");
    }
    final index = visibleIds.indexOf(selectedId);
    if (index == -1) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final listContext = _listKey.currentContext;
      if (listContext == null) return;

      final listBox = listContext.findRenderObject() as RenderBox?;
      if (listBox == null) return;

      final viewportWidth = _scrollController.position.viewportDimension;
      debugPrint("Viewport width: $viewportWidth");
      final listWidth = listBox.size.width;
      debugPrint("List width: $listWidth");
      final deviceWidth = MediaQuery.of(context).size.width;
      debugPrint("Device width: $deviceWidth");
      if (viewportWidth == 0) return;

      final itemWidths = <double>[];
      for (final id in visibleIds) {
        final itemContext = _itemKeys[id]?.currentContext;
        final itemBox = itemContext?.findRenderObject() as RenderBox?;
        if (itemBox == null) return;
        itemWidths.add(itemBox.size.width);
      }

      if (index >= itemWidths.length) return;
      _animateToTab(index, itemWidths, viewportWidth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final categoryProvider = context.watch<CategoryProvider>();
    final habitProvider = context.watch<HabitProvider>();
    final habitsList =
        widget.selectedDay == null
            ? habitProvider.todaysHabits
            : habitProvider.getHabitsForDate(widget.selectedDay!);
    final List<bool> hasHabits = [];
    final List<Category> visibleCategories = [];

    for (Category category in categoryProvider.categories) {
      int categoryHabits =
          habitsList
              .where((habit) => habit.categoryId == category.id)
              .toList()
              .length;
      hasHabits.add(categoryHabits > 0);
    }

    visibleCategories.add(Category(id: 0, name: localizations.all));

    for (int index = 0; index < categoryProvider.categories.length; index++) {
      final category = categoryProvider.categories[index];
      if (!hasHabits[index]) {
        continue;
      }
      visibleCategories.add(category);
    }

    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      // --- NEW: Wrap the list with ShaderMask to apply the fade effect ---
      child: SizedBox(
        height: 36,
        child: ListView(
          key: _listKey,
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          children: [
            Row(
              children: List.generate(visibleCategories.length, (index) {
                final category = visibleCategories[index];

                return KeyedSubtree(
                  key: _keyFor(category.id),
                  child: NewSelectCategoryWidget(
                    selectedDay: widget.selectedDay,
                    standardColor: widget.standardColor,
                    habitsCount: widget.habitsCount,
                    category: category,
                    isFirst: index == 0,
                    isLast: index == visibleCategories.length - 1,
                    onTap: () {
                      if (category.id == categoryProvider.selectedCategoryId) {
                        return;
                      }

                      categoryProvider.selectCategory(category.id);
                      _scrollToSelectedCategory();
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

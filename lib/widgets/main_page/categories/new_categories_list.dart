import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/main_page/categories/new_select_category.dart';
import 'package:provider/provider.dart';

class NewCategoriesList extends StatefulWidget {
  const NewCategoriesList({
    super.key,
    this.topPadding = 16,
    this.standardColor = false,
    this.showAll = true,
    this.habitsCount = true,
    this.selectedDay,
  });

  final double topPadding;
  final bool standardColor;
  final bool showAll;
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

  void _scrollToSelectedCategory() {
    if (!_scrollController.hasClients) return;

    final stateProvider = context.read<StateProvider>();

    // Determine the selected ID within the currently visible items.
    final selectedId = stateProvider.habitCategoryId;

    // Defer measurement to next frame to ensure layout is up-to-date.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final listContext = _listKey.currentContext;
      final itemKey = _itemKeys[selectedId] ?? _itemKeys[0];
      final itemContext = itemKey?.currentContext;

      if (listContext == null || itemContext == null) return;

      final listBox = listContext.findRenderObject() as RenderBox?;
      final itemBox = itemContext.findRenderObject() as RenderBox?;
      if (listBox == null || itemBox == null) return;

      final viewportWidth = _scrollController.position.viewportDimension;
      if (viewportWidth == 0) return;

      // Position of the item relative to the ListView's coordinate space.
      final itemOffset = itemBox.localToGlobal(Offset.zero, ancestor: listBox);
      final itemCenterX = itemOffset.dx + (itemBox.size.width / 2);

      final currentScroll = _scrollController.offset;
      final targetScroll = (currentScroll + itemCenterX) - (viewportWidth / 2);
      final clamped = targetScroll.clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );

      _scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final categoryProvider = context.watch<CategoryProvider>();
    final habitProvider = context.watch<HabitProvider>();
    final habitsList =
        widget.selectedDay == null
            ? habitProvider.habits
            : habitProvider.getHabitsFromDay(widget.selectedDay!);
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
      child: SizedBox(
        height: 36,
        child: ListView(
          key: _listKey,
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          children: [
            if (widget.showAll)
              KeyedSubtree(
                key: _keyFor(0),
                child: NewSelectCategoryWidget(
                  selectedDay: widget.selectedDay,
                  standardColor: widget.standardColor,
                  habitsCount: widget.habitsCount,
                  category: Category(id: 0, name: localizations.all),
                  onTap: () {
                    categoryProvider.selectCategory(0);
                    _scrollToSelectedCategory();
                  },
                ),
              ),
            Row(
              children: List.generate(categoryProvider.categories.length, (
                index,
              ) {
                Category category = categoryProvider.categories[index];
                if (widget.showAll) {
                  if (!hasHabits[index]) {
                    return SizedBox.shrink();
                  }
                }

                return KeyedSubtree(
                  key: _keyFor(category.id),
                  child: NewSelectCategoryWidget(
                    selectedDay: widget.selectedDay,
                    standardColor: widget.standardColor,
                    habitsCount: widget.habitsCount,
                    category: category,
                    onTap: () {
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

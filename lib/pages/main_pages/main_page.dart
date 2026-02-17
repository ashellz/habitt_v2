import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/providers/calendar_provider.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/habits_page/categories/select_category_widget.dart';
import 'package:habitt/widgets/main_page/main_page_top_section.dart';
import 'package:provider/provider.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Scaffold(
      backgroundColor: cp.bg,
      body: SafeArea(
        child: Column(
          spacing: 20,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: MainPageTopSection(),
            ),
            Expanded(
              child: Container(
                color: cp.habitBg,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 16, left: 16),
                      child: NewCategoriesList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewCategoriesList extends StatefulWidget {
  const NewCategoriesList({
    super.key,
    this.topPadding = 16,
    this.standardColor = false,
    this.showAll = true,
    this.habitsCount = true,
    this.useHabitCategory = false,
    this.selectedDay,
  });

  final double topPadding;
  final bool standardColor;
  final bool showAll;
  final bool habitsCount;
  final bool useHabitCategory;
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

    final categoryProvider = context.read<CategoryProvider>();
    final stateProvider = context.read<StateProvider>();
    final calendarProvider = context.read<CalendarProvider>();

    // Determine the selected ID within the currently visible items.
    final selectedId =
        widget.useHabitCategory
            ? stateProvider.habitCategoryId
            : widget.selectedDay == null
            ? categoryProvider.selectedCategoryId
            : calendarProvider.selectedCategoryId;

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
    final stateProvider = context.watch<StateProvider>();
    final calendarProvider = context.watch<CalendarProvider>();
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
        height: 56,
        child: ListView(
          key: _listKey,
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          children: [
            if (widget.showAll)
              KeyedSubtree(
                key: _keyFor(0),
                child: SelectCategoryWidget(
                  selectedDay: widget.selectedDay,
                  standardColor: widget.standardColor,
                  habitsCount: widget.habitsCount,
                  category: Category(id: 0, name: localizations.all),
                  onTap: () {
                    if (widget.selectedDay != null) {
                      calendarProvider.selectCategory(0);
                    } else {
                      categoryProvider.selectCategory(0);
                    }
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
                    return Container();
                  }
                }

                return KeyedSubtree(
                  key: _keyFor(category.id),
                  child: SelectCategoryWidget(
                    selectedDay: widget.selectedDay,
                    useHabitCategory: widget.useHabitCategory,
                    standardColor: widget.standardColor,
                    habitsCount: widget.habitsCount,
                    category: category,
                    onTap: () {
                      if (widget.useHabitCategory) {
                        stateProvider.habitCategoryId = category.id;
                        _scrollToSelectedCategory();
                        return;
                      } else if (widget.selectedDay != null) {
                        calendarProvider.selectCategory(category.id);
                      } else {
                        categoryProvider.selectCategory(category.id);
                      }
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

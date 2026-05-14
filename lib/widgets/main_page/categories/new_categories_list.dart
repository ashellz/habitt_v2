import 'dart:async';

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
    this.showAll = false,
    this.selectedDay,
  });

  final EdgeInsets? padding;
  final bool standardColor; // Different variant of colors for habits page
  final bool habitsCount;
  final bool showAll; // shows habits instead of todaysHabits
  final DateTime?
  selectedDay; // shows habits for the selected day instead of today

  @override
  State<NewCategoriesList> createState() => _NewCategoriesListState();
}

class _NewCategoriesListState extends State<NewCategoriesList> {
  static const Duration _animationDuration = Duration(milliseconds: 260);

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listKey = GlobalKey();
  final Map<int, GlobalKey> _itemKeys = {};
  final Set<int> _exitingCategoryIds = <int>{};
  final Map<int, Timer> _exitTimers = <int, Timer>{};
  List<int> _lastVisibleIds = <int>[0];

  bool _isSchedulingFallback = false; // Avoid multiple schedules

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime? _effectiveSelectedDay([HabitProvider? habitProvider]) {
    final provider = habitProvider ?? context.read<HabitProvider>();
    final source = provider.selectedDate ?? widget.selectedDay;
    if (source == null) {
      return null;
    }
    return _normalizeDate(source);
  }

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
    for (final timer in _exitTimers.values) {
      timer.cancel();
    }

    _scrollController.dispose();
    super.dispose();
  }

  Category _allCategory(AppLocalizations localizations) {
    return Category(id: 0, name: localizations.all);
  }

  void _scheduleFallbackToAll(CategoryProvider categoryProvider) {
    if (_isSchedulingFallback) return; // Avoid multiple schedules

    debugPrint(AppLocalizations.of(context)!.schedulingFallbackToAll);

    _isSchedulingFallback = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _isSchedulingFallback = false;
        return;
      }

      categoryProvider.selectCategory(0);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          _isSchedulingFallback = false;
          return;
        }
        _scrollToSelectedCategory();
        _isSchedulingFallback = false;
      });
    });
  }

  void _startExitAnimation(int categoryId) {
    if (_exitingCategoryIds.contains(categoryId)) return;

    _exitingCategoryIds.add(categoryId);
    _exitTimers[categoryId]?.cancel();
    _exitTimers[categoryId] = Timer(_animationDuration, () {
      if (!mounted) return;

      setState(() {
        _exitingCategoryIds.remove(categoryId);
        _exitTimers.remove(categoryId);
        _itemKeys.remove(categoryId);
      });

      _scrollToSelectedCategory();
    });
  }

  void _cancelExitAnimation(int categoryId) {
    _exitTimers[categoryId]?.cancel();
    _exitTimers.remove(categoryId);
    _exitingCategoryIds.remove(categoryId);
  }

  List<int> _buildRenderedIds(List<int> currentVisibleIds) {
    final renderedIds = List<int>.from(currentVisibleIds);

    final removedIds =
        _lastVisibleIds
            .where((id) => !currentVisibleIds.contains(id) && id != 0)
            .toList();

    for (final id in removedIds) {
      _startExitAnimation(id);
    }

    for (final id in _exitingCategoryIds.toList()) {
      if (currentVisibleIds.contains(id)) {
        _cancelExitAnimation(id);
        continue;
      }

      if (renderedIds.contains(id)) {
        continue;
      }

      final previousIndex = _lastVisibleIds.indexOf(id);
      if (previousIndex >= 0 && previousIndex <= renderedIds.length) {
        renderedIds.insert(previousIndex, id);
      } else {
        renderedIds.add(id);
      }
    }

    return renderedIds;
  }

  void _cleanupItemKeys(Set<int> renderedIds) {
    _itemKeys.removeWhere(
      (id, _) => !renderedIds.contains(id) && !_exitingCategoryIds.contains(id),
    );
  }

  List<int> _visibleCategoryIds(List habitsList) {
    final categoryProvider = context.read<CategoryProvider>();
    final visibleIds = <int>[0];
    final categoryIdsWithHabits = <int>{};

    for (final habit in habitsList) {
      categoryIdsWithHabits.add(habit.categoryId);
    }

    for (final category in categoryProvider.categories) {
      if (!categoryIdsWithHabits.contains(category.id)) {
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
      AppLocalizations.of(context)!.leadingLeadingSelectedWidthSelectedwidthItemCenterOffsetItemcenteroffset,
    );
    final targetScroll = itemCenterOffset - ((viewportWidth + 32) / 2);
    debugPrint(AppLocalizations.of(context)!.calculatedTargetScrollTargetscroll);

    final maxScroll = _scrollController.position.maxScrollExtent;

    final clamped = targetScroll.clamp(0.0, maxScroll);
    debugPrint(AppLocalizations.of(context)!.clampedTargetScrollClampedMaxScrollMaxscroll);
    _scrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToSelectedCategory() {
    if (!_scrollController.hasClients) return;
    // Scrolls to selected category

    final categoryProvider = context.read<CategoryProvider>();
    final habitProvider = context.read<HabitProvider>();
    final selectedDay = _effectiveSelectedDay(habitProvider);
    // Get habits accordingly
    final habitsList =
        selectedDay == null
            ? widget.showAll
                ? habitProvider.habits
                : habitProvider.todaysHabits
            : habitProvider.getHabitsForDate(selectedDay);

    final selectedId = categoryProvider.selectedCategoryId;
    final visibleIds = _visibleCategoryIds(habitsList);
    for (var id in visibleIds) {
      debugPrint(AppLocalizations.of(context)!.visibleCategoryIdId);
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
      debugPrint(AppLocalizations.of(context)!.viewportWidthViewportwidth);
      final listWidth = listBox.size.width;
      debugPrint(AppLocalizations.of(context)!.listWidthListwidth);
      final deviceWidth = MediaQuery.of(context).size.width;
      debugPrint(AppLocalizations.of(context)!.deviceWidthDevicewidth);
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
    final selectedDay = _effectiveSelectedDay(habitProvider);

    // Get habits accordingly
    final habitsList =
        selectedDay == null
            ? widget.showAll
                ? habitProvider.habits
                : habitProvider.todaysHabits
            : habitProvider.getHabitsForDate(selectedDay);

    final List<Category> visibleCategories = [];
    final allCategory = _allCategory(localizations);
    final categoryIdsWithHabits = <int>{};

    for (final habit in habitsList) {
      categoryIdsWithHabits.add(habit.categoryId);
    }

    visibleCategories.add(allCategory);

    for (final category in categoryProvider.categories) {
      if (!categoryIdsWithHabits.contains(category.id)) {
        continue;
      }
      visibleCategories.add(category);
    }

    final visibleIds =
        visibleCategories.map((category) => category.id).toList();
    final selectedId = categoryProvider.selectedCategoryId;
    final wasSelectedVisibleInPreviousFrame = _lastVisibleIds.contains(
      selectedId,
    );
    debugPrint("Selected id: $selectedId | showAll=${widget.showAll}");
    final isSelectedVisible = visibleIds.contains(selectedId);
    debugPrint(
      AppLocalizations.of(context)!.isSelectedVisibleIsselectedvisibleWasvisiblepreviouslywasselectedvisibleinpreviousframeIdsvisibleids,
    );

    if (!isSelectedVisible && wasSelectedVisibleInPreviousFrame) {
      // If selected category is not visible fallback to "All"
      _scheduleFallbackToAll(categoryProvider);
    }

    final renderedIds = _buildRenderedIds(visibleIds);
    final visibleById = <int, Category>{
      for (final c in visibleCategories) c.id: c,
    };
    final categoriesById = {
      for (final c in categoryProvider.categories) c.id: c,
      allCategory.id: allCategory,
    };

    _cleanupItemKeys(renderedIds.toSet());
    _lastVisibleIds = List<int>.from(visibleIds);

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
              children: List.generate(renderedIds.length, (index) {
                final categoryId = renderedIds[index];
                final isExiting =
                    _exitingCategoryIds.contains(categoryId) &&
                    !visibleById.containsKey(categoryId);
                final category =
                    visibleById[categoryId] ?? categoriesById[categoryId];

                if (category == null) {
                  return const SizedBox.shrink();
                }

                final chip = KeyedSubtree(
                  key: _keyFor(category.id),
                  child: NewSelectCategoryWidget(
                    selectedDay: selectedDay,
                    standardColor: widget.standardColor,
                    category: category,
                    isFirst: index == 0,
                    isLast: index == renderedIds.length - 1,
                    onTap: () {
                      if (isExiting) {
                        return;
                      }

                      if (category.id == categoryProvider.selectedCategoryId) {
                        return;
                      }

                      categoryProvider.selectCategory(category.id);
                      _scrollToSelectedCategory();
                    },
                  ),
                );

                return TweenAnimationBuilder<double>(
                  key: ValueKey<int>(categoryId),
                  tween: Tween<double>(begin: 1.0, end: isExiting ? 0.0 : 1.0),
                  duration: _animationDuration,
                  curve: Curves.easeInOut,
                  child: IgnorePointer(ignoring: isExiting, child: chip),
                  builder: (context, value, child) {
                    return ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                        child: Opacity(opacity: value, child: child),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

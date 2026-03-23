import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:habitt/models/category.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/get_category_length.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/main_page/habits/new_habit_category.dart';
import 'package:habitt/widgets/sheets/add_new_habit_sheet.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class NewHabits extends StatefulWidget {
  final DateTime? daySelected;
  final bool hasMainCategory;

  const NewHabits({super.key, this.daySelected, this.hasMainCategory = false});

  @override
  State<NewHabits> createState() => _NewHabitsState();
}

class _NewHabitsState extends State<NewHabits>
    with SingleTickerProviderStateMixin {
  static const double _swapPoint = 0.48;
  static const int _fallbackVisibleHabits = 3;

  late AnimationController _reorderController;
  late List<Habit> habits;
  List<int> _lastProviderOrderIds = const [];
  List<int> _displayOrderIds = const [];
  List<int>? _queuedProviderOrderIds;
  bool _hasSwappedToTargetOrder = false;
  bool _isReorderActive = false;
  int? _previousMainCategoryId;
  int? _newMainCategoryId;
  int _newMainOldIndex = -1;
  int _previousMainNewIndex = -1;
  Set<int> _fallbackCategoryIds = <int>{};

  @override
  void initState() {
    super.initState();
    _reorderController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 760),
          )
          ..addListener(_onReorderTick)
          ..addStatusListener(_onReorderStatusChanged);

    habits = _getHabits();
  }

  bool _isTodayView() {
    final selected = widget.daySelected;
    if (selected == null) {
      return true;
    }

    final today = DateTime.now();
    final todayShort = DateTime(today.year, today.month, today.day);
    final selectedShort = DateTime(selected.year, selected.month, selected.day);
    return selectedShort == todayShort;
  }

  void _onReorderTick() {
    if (!_isReorderActive || _hasSwappedToTargetOrder) {
      return;
    }

    if (_reorderController.value < _swapPoint) {
      return;
    }

    _hasSwappedToTargetOrder = true;
    if (!mounted) {
      return;
    }

    setState(() {
      _displayOrderIds = List<int>.from(_lastProviderOrderIds);
    });
  }

  void _onReorderStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isReorderActive = false;
      _hasSwappedToTargetOrder = false;
      _fallbackCategoryIds = <int>{};
      _previousMainCategoryId = null;
      _newMainCategoryId = null;
      _newMainOldIndex = -1;
      _previousMainNewIndex = -1;
      _displayOrderIds = List<int>.from(_lastProviderOrderIds);
    });

    final queued = _queuedProviderOrderIds;
    _queuedProviderOrderIds = null;
    if (queued == null || listEquals(queued, _lastProviderOrderIds)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _scheduleReorderAnimation(
        oldOrderIds: List<int>.from(_lastProviderOrderIds),
        newOrderIds: List<int>.from(queued),
      );
    });
  }

  int _habitCountForCategory(int categoryId) {
    return habits
        .where((habit) => habit.categoryId == categoryId && !habit.optional)
        .length;
  }

  void _syncOrderState(List<int> providerOrderIds, bool shouldAnimate) {
    if (_lastProviderOrderIds.isEmpty) {
      _lastProviderOrderIds = List<int>.from(providerOrderIds);
      _displayOrderIds = List<int>.from(providerOrderIds);
      return;
    }

    if (listEquals(providerOrderIds, _lastProviderOrderIds)) {
      if (!_isReorderActive &&
          !listEquals(_displayOrderIds, providerOrderIds)) {
        _displayOrderIds = List<int>.from(providerOrderIds);
      }
      return;
    }

    if (_isReorderActive) {
      _queuedProviderOrderIds = List<int>.from(providerOrderIds);
      _lastProviderOrderIds = List<int>.from(providerOrderIds);
      return;
    }

    if (!shouldAnimate ||
        providerOrderIds.isEmpty ||
        _lastProviderOrderIds.isEmpty ||
        providerOrderIds.first == _lastProviderOrderIds.first) {
      _lastProviderOrderIds = List<int>.from(providerOrderIds);
      _displayOrderIds = List<int>.from(providerOrderIds);
      return;
    }

    final oldOrder = List<int>.from(_lastProviderOrderIds);
    final newOrder = List<int>.from(providerOrderIds);
    _lastProviderOrderIds = List<int>.from(providerOrderIds);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _scheduleReorderAnimation(oldOrderIds: oldOrder, newOrderIds: newOrder);
    });
  }

  void _scheduleReorderAnimation({
    required List<int> oldOrderIds,
    required List<int> newOrderIds,
  }) {
    if (oldOrderIds.isEmpty || newOrderIds.isEmpty) {
      return;
    }

    final previousMainId = oldOrderIds.first;
    final newMainId = newOrderIds.first;
    if (previousMainId == newMainId) {
      setState(() {
        _displayOrderIds = List<int>.from(newOrderIds);
      });
      return;
    }

    final fallbackIds = <int>{};
    final previousMainCount = _habitCountForCategory(previousMainId);
    final newMainCount = _habitCountForCategory(newMainId);

    if (previousMainCount > _fallbackVisibleHabits) {
      fallbackIds.add(previousMainId);
    }
    if (newMainCount > _fallbackVisibleHabits) {
      fallbackIds.add(newMainId);
    }

    setState(() {
      _isReorderActive = true;
      _hasSwappedToTargetOrder = false;
      _queuedProviderOrderIds = null;
      _previousMainCategoryId = previousMainId;
      _newMainCategoryId = newMainId;
      _newMainOldIndex = oldOrderIds.indexOf(newMainId);
      _previousMainNewIndex = newOrderIds.indexOf(previousMainId);
      _fallbackCategoryIds = fallbackIds;
      _displayOrderIds = List<int>.from(oldOrderIds);
    });

    _reorderController
      ..value = 0
      ..forward();
  }

  Widget _buildAnimatedCategoryBlock({
    required Category category,
    required int categoryIndex,
    required bool isFirst,
    required bool isToday,
    required double progress,
  }) {
    final categoryId = category.id;
    final bool isInPrimaryPhase = progress <= _swapPoint;
    final double primaryT = isInPrimaryPhase ? (progress / _swapPoint) : 1;
    final double settleT =
        isInPrimaryPhase ? 0 : (progress - _swapPoint) / (1 - _swapPoint);

    double translateY = 0;
    double scale = 1;

    if (_isReorderActive && _newMainCategoryId != null) {
      if (isInPrimaryPhase) {
        if (categoryId == _newMainCategoryId) {
          translateY = Tween<double>(
            begin: 0,
            end: -28,
          ).transform(Curves.easeOut.transform(primaryT));
          scale = Tween<double>(
            begin: 1,
            end: 1.03,
          ).transform(Curves.easeOut.transform(primaryT));
        } else if (_newMainOldIndex > 0 && categoryIndex < _newMainOldIndex) {
          translateY = Tween<double>(
            begin: 0,
            end: 44,
          ).transform(Curves.easeInOut.transform(primaryT));
        }
      } else {
        if (categoryId == _newMainCategoryId) {
          translateY = Tween<double>(
            begin: 38,
            end: 0,
          ).transform(Curves.easeOutCubic.transform(settleT));
          scale = Tween<double>(
            begin: 1.03,
            end: 1,
          ).transform(Curves.easeOut.transform(settleT));
        } else if (categoryId == _previousMainCategoryId &&
            _previousMainNewIndex > 0) {
          translateY = Tween<double>(
            begin: -14,
            end: 0,
          ).transform(Curves.easeOut.transform(settleT));
        }
      }
    }

    return Padding(
      key: ValueKey('category-$categoryId'),
      padding: const EdgeInsets.only(top: 12),
      child: Transform.translate(
        offset: Offset(0, translateY),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: NewHabitCategory(
            key: ValueKey(categoryId),
            reorderActive: _isReorderActive,
            reorderProgress: progress,
            reorderSwapPoint: _swapPoint,
            fallbackVisibleHabits: _fallbackVisibleHabits,
            useFallbackAnimation: _fallbackCategoryIds.contains(categoryId),
            isToday: isToday,
            habits: habits,
            isFirst: isFirst,
            category: category,
            showOptionalHabits: false,
          ),
        ),
      ),
    );
  }

  double _calculateHabitsListHeight(
    BuildContext context,
    int perfectDaysStreak,
  ) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = 0;
    const bottomNavBar = 160;

    final baseHeight =
        topPadding +
        20 +
        40 +
        79 +
        20 +
        (36 + 40) +
        bottomNavBar +
        bottomPadding;
    final baseHeightWithStreak =
        topPadding +
        20 +
        60 +
        79 +
        82 +
        20 +
        (36 + 40) +
        bottomNavBar +
        bottomPadding;

    final height = perfectDaysStreak > 0 ? baseHeightWithStreak : baseHeight;
    return MediaQuery.of(context).size.height - height;
  }

  double _calculateContentHeight(
    List<Category> categories,
    BuildContext context,
  ) {
    const double categoryTitleHeight = 26;
    const double habitHeight = 74; // 42 icon + 32 padding
    const double categoryTopPadding = 12;
    const double categorySpacing = 10;

    double totalHeight = 0;

    for (final category in categories) {
      final categoryLength = getCategoryLength(
        category,
        context,
        false,
        widget.daySelected,
      );

      if (categoryLength > 0) {
        // Add category top padding
        totalHeight += categoryTopPadding;

        // Add category title height
        totalHeight += categoryTitleHeight;

        // Add spacing after title
        totalHeight += categorySpacing;

        // Add all habits with spacing between them
        totalHeight += (habitHeight * categoryLength);
        totalHeight += (categorySpacing * (categoryLength - 1));

        totalHeight += 50; // button
      }
    }

    return totalHeight;
  }

  List<Habit> _getHabits() {
    debugPrint(
      "Getting habits for Habits widget ======================================== new DAY SELECTED: ${widget.daySelected} ",
    );
    final habitProvider = context.read<HabitProvider>();
    final today = DateTime.now();
    final todayShort = DateTime(today.year, today.month, today.day);
    if (widget.daySelected == null || widget.daySelected == todayShort) {
      return habitProvider.todaysHabits;
    }

    return habitProvider.getHabitsForDate(widget.daySelected!);
  }

  @override
  void dispose() {
    _reorderController
      ..removeListener(_onReorderTick)
      ..removeStatusListener(_onReorderStatusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    habits = _getHabits();
    final categoryProvider = context.watch<CategoryProvider>();
    final selectedCategoryId = categoryProvider.selectedCategoryId;

    final optionalHabitsCount = habits.where((habit) => habit.optional).length;
    final cp = context.watch<ColorProvider>();

    final perfectDaysStreak = context.watch<StatsProvider>().perfectDaysStreak;
    final habitsListHeight = _calculateHabitsListHeight(
      context,
      perfectDaysStreak,
    );

    if (habits.isEmpty) {
      return SizedBox(
        height: habitsListHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 16,
          children: [
            Spacer(),
            SvgPicture.asset("assets/images/new-svg/empty-box.svg"),
            Text(
              "You haven’t added any habits yet",
              style: TextStyle(color: cp.lightGreyText, fontSize: 16),
            ),
            const Spacer(),
            addHabitButton(cp),
          ],
        ),
      );
    }

    final List<Category> categories = categoryProvider.categoriesOrdered;
    final visibleCategories =
        categories
            .where(
              (category) =>
                  getCategoryLength(
                    category,
                    context,
                    false,
                    widget.daySelected,
                  ) >
                  0,
            )
            .toList();

    final providerOrderIds =
        visibleCategories.map((category) => category.id).toList();
    final shouldAnimateReorder = _isTodayView() && selectedCategoryId == 0;
    _syncOrderState(providerOrderIds, shouldAnimateReorder);

    final idToCategory = {
      for (final category in visibleCategories) category.id: category,
    };
    final displayedCategories =
        _displayOrderIds
            .map((id) => idToCategory[id])
            .whereType<Category>()
            .toList();

    // Calculate remaining height for bottom spacing
    final contentHeight = _calculateContentHeight(displayedCategories, context);
    final bottomSpacing = (habitsListHeight - contentHeight).clamp(
      0.0,
      double.infinity,
    );

    if (selectedCategoryId != 0) {
      final selectedCategory = categoryProvider.categories.firstWhere(
        (c) => c.id == selectedCategoryId,
      );
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: NewHabitCategory(
              key: ValueKey(selectedCategoryId),
              reorderActive: false,
              reorderProgress: 0,
              reorderSwapPoint: _swapPoint,
              fallbackVisibleHabits: _fallbackVisibleHabits,
              useFallbackAnimation: false,
              isToday: widget.daySelected == null,
              habits: habits,
              showOptionalHabits: true,
              category: selectedCategory,
            ),
          ),
          if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
        ],
      );
    }

    return AnimatedBuilder(
      animation: _reorderController,
      builder: (context, child) {
        final reorderProgress =
            _isReorderActive ? _reorderController.value : 0.0;

        return Column(
          children: [
            for (int index = 0; index < displayedCategories.length; index++)
              _buildAnimatedCategoryBlock(
                category: displayedCategories[index],
                categoryIndex: index,
                isFirst: index == 0,
                isToday: widget.daySelected == null,
                progress: reorderProgress,
              ),

            Padding(
              padding: EdgeInsets.only(
                top: optionalHabitsCount == habits.length ? 12 : 0,
              ),
              // child additional tasks
            ),

            addHabitButton(cp),

            if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
          ],
        );
      },
    );
  }

  Padding addHabitButton(ColorProvider cp) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: NewDefaultButton.secondary(
        height: 40,
        label: "Add habit",
        onPressed: () {
          final stateProvider = context.read<StateProvider>();
          stateProvider.reset();

          showModalBottomSheet(
            context: context,
            backgroundColor: cp.isDark ? cp.habitBg : cp.bg,
            barrierColor: cp.greyText.darken().withOpacity(0.3),
            isScrollControlled: true,
            builder: (context) {
              return AddNewHabitSheet();
            },
          );
        },
        prefix: SvgPicture.asset(
          "assets/images/new-svg/add.svg",
          colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
        ),
      ),
    );
  }
}

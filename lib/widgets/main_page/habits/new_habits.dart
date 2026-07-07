import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:habitt/models/category.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/get_category_length.dart';
import 'package:habitt/widgets/main_page/add_habit_button.dart';
import 'package:habitt/widgets/main_page/habits/new_habit_category.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

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
  String? _activeDayKey;

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime? _effectiveSelectedDay([HabitProvider? habitProvider]) {
    final provider = habitProvider ?? context.read<HabitProvider>();
    final source = provider.selectedDate ?? widget.daySelected;
    if (source == null) {
      return null;
    }
    return _normalizeDate(source);
  }

  String _dateIdentityKey(DateTime? date) {
    final normalized = date ?? _normalizeDate(DateTime.now());
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

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
    final selected = _effectiveSelectedDay();
    if (selected == null) {
      return true;
    }

    final todayShort = _normalizeDate(DateTime.now());
    return selected == todayShort;
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
        .where((habit) => habit.categoryId == categoryId) //  && !habit.optional
        .length;
  }

  void _syncOrderState(
    List<int> providerOrderIds,
    bool shouldAnimate,
    String dayKey,
  ) {
    if (_activeDayKey != dayKey) {
      _activeDayKey = dayKey;
      _reorderController.stop();
      _isReorderActive = false;
      _hasSwappedToTargetOrder = false;
      _queuedProviderOrderIds = null;
      _fallbackCategoryIds = <int>{};
      _previousMainCategoryId = null;
      _newMainCategoryId = null;
      _newMainOldIndex = -1;
      _previousMainNewIndex = -1;
      _lastProviderOrderIds = List<int>.from(providerOrderIds);
      _displayOrderIds = List<int>.from(providerOrderIds);
      return;
    }

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
    required String dayKey,
    required DateTime? selectedDay,
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
      key: ValueKey('category-$dayKey-$categoryId'),
      padding: EdgeInsets.only(top: 12),
      child: Transform.translate(
        offset: Offset(0, translateY),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: NewHabitCategory(
            key: ValueKey('category-body-$dayKey-$categoryId'),
            reorderActive: _isReorderActive,
            reorderProgress: progress,
            reorderSwapPoint: _swapPoint,
            reorderDurationMs:
                _reorderController.duration?.inMilliseconds ?? 760,
            fallbackVisibleHabits: _fallbackVisibleHabits,
            useFallbackAnimation: _fallbackCategoryIds.contains(categoryId),
            isToday: isToday,
            selectedDate: selectedDay,
            habits: habits,
            isFirst: isFirst,
            category: category,
            showOptionalHabits: true,
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
    int? selectedCategoryId,
  ) {
    const double categoryTitleHeight = 26;
    const double habitHeight = 74; // 42 icon + 32 padding
    const double categoryTopPadding = 12;
    const double categorySpacing = 10;

    double totalHeight = 0;

    for (final category in categories) {
      if (selectedCategoryId != 0 && category.id != selectedCategoryId) {
        continue;
      }
      final categoryLength = getCategoryLength(
        category,
        context,
        true,
        _effectiveSelectedDay(),
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
    final habitProvider = context.read<HabitProvider>();
    final selectedDay = _effectiveSelectedDay(habitProvider);

    final todayShort = _normalizeDate(DateTime.now());
    if (selectedDay == null || selectedDay == todayShort) {
      return habitProvider.todaysHabits;
    }

    return habitProvider.getHabitsForDate(selectedDay);
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
    final selectedDay = _effectiveSelectedDay();
    final dayKey = _dateIdentityKey(selectedDay);
    final categoryProvider = context.watch<CategoryProvider>();
    final selectedCategoryId = categoryProvider.selectedCategoryId;

    final optionalHabitsCount = habits.where((habit) => habit.optional).length;

    final perfectDaysStreak = context.watch<StatsProvider>().perfectDaysStreak;
    final habitsListHeight = _calculateHabitsListHeight(
      context,
      perfectDaysStreak,
    );

    if (habits.isEmpty) {
      return SizedBox(
        height: habitsListHeight - MediaQuery.of(context).padding.bottom,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 16,
          children: [
            Spacer(),
            EmptyHabitsWidget(),
            const Spacer(),
            AddHabitButton(),
          ],
        ),
      );
    }

    final List<Category> categories = categoryProvider.categoriesOrdered;
    final visibleCategories =
        categories
            .where(
              (category) =>
                  getCategoryLength(category, context, true, selectedDay) > 0,
            )
            .toList();

    final providerOrderIds =
        visibleCategories.map((category) => category.id).toList();
    final shouldAnimateReorder = _isTodayView() && selectedCategoryId == 0;
    _syncOrderState(providerOrderIds, shouldAnimateReorder, dayKey);

    final idToCategory = {
      for (final category in visibleCategories) category.id: category,
    };
    final displayedCategories =
        _displayOrderIds
            .map((id) => idToCategory[id])
            .whereType<Category>()
            .toList();

    // Calculate remaining height for bottom spacing
    final contentHeight = _calculateContentHeight(
      displayedCategories,
      context,
      selectedCategoryId,
    );
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
              showTitle: false,
              key: ValueKey('selected-category-$dayKey-$selectedCategoryId'),
              reorderActive: false,
              reorderProgress: 0,
              reorderSwapPoint: _swapPoint,
              reorderDurationMs:
                  _reorderController.duration?.inMilliseconds ?? 760,
              fallbackVisibleHabits: _fallbackVisibleHabits,
              useFallbackAnimation: false,
              isToday: _isTodayView(),
              selectedDate: selectedDay,
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
                isToday: _isTodayView(),
                dayKey: dayKey,
                selectedDay: selectedDay,
                progress: reorderProgress,
              ),

            Padding(
              padding: EdgeInsets.only(
                top: optionalHabitsCount == habits.length ? 12 : 0,
              ),
              // child additional tasks
            ),

            AddHabitButton(),
            if (Platform.isAndroid) SizedBox(height: 24),

            if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
          ],
        );
      },
    );
  }
}

class EmptyHabitsWidget extends StatelessWidget {
  const EmptyHabitsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    final loc = AppLocalizations.of(context)!;
    return Column(
      spacing: 16,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset("assets/images/new-svg/empty-box.svg"),
        Text(
          loc.youHaventAddedAnyHabitsYet,
          style: TextStyle(color: cp.lightGreyText, fontSize: 16),
        ),
      ],
    );
  }
}

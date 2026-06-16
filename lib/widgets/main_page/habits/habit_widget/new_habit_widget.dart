import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/widgets/habit_widget/new_habit_icon.dart';
import 'package:habitt/widgets/main_page/habits/habit_widget/main_habit_info.dart';
import 'package:habitt/widgets/main_page/habits/habit_widget/new_habit_progress.dart';
import 'package:habitt/widgets/main_page/habits/habit_widget/streak_badge.dart';

import 'package:provider/provider.dart';

class NewHabitWidget extends StatefulWidget {
  const NewHabitWidget({super.key, required this.habit, this.isDemo = false});

  final Habit habit;
  final bool isDemo;

  @override
  State<NewHabitWidget> createState() => _NewHabitWidgetState();
}

class _NewHabitWidgetState extends State<NewHabitWidget>
    with TickerProviderStateMixin {
  static const int _segmentCount = 12;
  late AnimationController _controller;
  late List<Animation<double>> _segmentAnimations;
  late bool _previousCompleted;

  late AnimationController _streakEntryController;
  late Animation<double> _streakFadeAnimation;
  late Animation<Offset> _streakSlideAnimation;
  int _lastEpoch = -1;
  // Epoch already presented (animated) by any instance. Mutated only in a
  // post-frame callback so all siblings in the same frame read a stable value.
  static int _displayedEpoch = -1;

  @override
  void initState() {
    super.initState();
    _previousCompleted = widget.habit.completed;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buildAnimations();
    _controller.value = widget.habit.completed ? 1.0 : 0.0;

    _streakEntryController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    // Visible by default. Widgets recreated by navigation (page/day switch that
    // doesn't change the epoch) keep the badge shown without re-animating; the
    // animate path resets this to 0 before the first paint.
    _streakEntryController.value = 1.0;
    _streakFadeAnimation = CurvedAnimation(
      parent: _streakEntryController,
      curve: Curves.easeOut,
    );
    _streakSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _streakEntryController,
      curve: Curves.easeOut,
    ));
  }

  void _buildAnimations() {
    // Each segment gets a staggered interval, right-to-left order
    _segmentAnimations = List.generate(_segmentCount, (index) {
      // Reverse index so rightmost segment animates first
      final reversedIndex = _segmentCount - 1 - index;
      final segmentDuration = 0.4;
      final totalStagger = 1.0 - segmentDuration;
      final start = (reversedIndex / (_segmentCount - 1)) * totalStagger;
      final end = start + segmentDuration;
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(
          start.clamp(0.0, 1.0),
          end.clamp(0.0, 1.0),
          curve: Curves.easeInOut,
        ),
      );
    });
  }

  @override
  void didUpdateWidget(NewHabitWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.habit.completed != oldWidget.habit.completed) {
      if (widget.habit.completed) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _streakEntryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final today = DateTime.now();
    final habitProvider = context.watch<HabitProvider>();
    final selectedDate = habitProvider.selectedDate ?? today;
    final isToday =
        selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;

    final categoryProvider = context.watch<CategoryProvider>();

    final currentEpoch = habitProvider.streakEntryEpoch;
    if (currentEpoch != _lastEpoch) {
      _lastEpoch = currentEpoch;

      // Animate only the first time this epoch is presented. Navigation that
      // recreates widgets without bumping the epoch (tab/day switch back) skips
      // this and leaves the badge visible; cold start and return-to-today bump
      // the epoch, so they animate.
      if (isToday && currentEpoch != _displayedEpoch) {
        // Index by the displayed category order, then habit order within it.
        final orderedCatIds =
            categoryProvider.categoriesOrdered.map((c) => c.id).toList();
        final catRank = {
          for (int i = 0; i < orderedCatIds.length; i++) orderedCatIds[i]: i,
        };
        final sorted = [...habitProvider.todaysHabits]
          ..sort((a, b) {
            final ca = catRank[a.categoryId] ?? 999;
            final cb = catRank[b.categoryId] ?? 999;
            if (ca != cb) return ca.compareTo(cb);
            final ao = a.order <= 0 ? 1 << 30 : a.order;
            final bo = b.order <= 0 ? 1 << 30 : b.order;
            if (ao != bo) return ao.compareTo(bo);
            return a.id.compareTo(b.id);
          });
        final globalIndex =
            sorted.indexWhere((h) => h.id == widget.habit.id).clamp(0, 99);

        _streakEntryController.value = 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Mark the epoch presented after every sibling in this frame has built,
          // so they all observe the un-presented value and animate together.
          _displayedEpoch = currentEpoch;
          if (!mounted) return;
          final delayMs = globalIndex * 100;
          if (delayMs == 0) {
            _streakEntryController.forward();
          } else {
            Future.delayed(Duration(milliseconds: delayMs), () {
              if (mounted && habitProvider.streakEntryEpoch == currentEpoch) {
                _streakEntryController.forward();
              }
            });
          }
        });
      }
    }

    // Check if completed state changed and trigger animation
    if (widget.habit.completed != _previousCompleted) {
      _previousCompleted = widget.habit.completed;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (widget.habit.completed) {
            _controller.forward();
          } else {
            _controller.reverse();
          }
        }
      });
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final colors = <Color>[];
        final stops = <double>[];

        for (int i = 0; i < _segmentCount; i++) {
          final t = _segmentAnimations[i].value;
          final color = Color.lerp(cp.widget, cp.main.withOpacity(0.1), t)!;
          stops.add(i / (_segmentCount - 1));
          colors.add(color);
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
          decoration: ShapeDecoration(
            gradient: LinearGradient(colors: colors, stops: stops),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                color:
                    widget.habit.completed
                        ? cp.main.withOpacity(0.2)
                        : cp.border,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: child,
        );
      },
      child: Row(
        spacing: 16,
        children: [
          NewHabitIcon(
            iconPath: widget.habit.iconPath,
            isCompleted: widget.habit.completed,
          ),
          Expanded(child: MainHabitInfo(habit: widget.habit, cp: cp)),
          Row(
            spacing: 4,
            children: [
              if (isToday)
                FadeTransition(
                  opacity: _streakFadeAnimation,
                  child: SlideTransition(
                    position: _streakSlideAnimation,
                    child: StreakBadge(
                      streak:
                          widget.habit.streak +
                          (widget.habit.streak > 0 && widget.habit.completed
                              ? 1
                              : 0),
                    ),
                  ),
                ),
              NewHabitProgress(habit: widget.habit, isDemo: widget.isDemo),
            ],
          ),
        ],
      ),
    );
  }
}

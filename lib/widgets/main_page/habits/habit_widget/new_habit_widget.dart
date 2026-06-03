import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
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
    with SingleTickerProviderStateMixin {
  static const int _segmentCount = 12;
  late AnimationController _controller;
  late List<Animation<double>> _segmentAnimations;
  late bool _previousCompleted;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

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
              StreakBadge(
                streak: widget.habit.streak +
                    (widget.habit.streak > 0 && widget.habit.completed ? 1 : 0),
              ),
              NewHabitProgress(habit: widget.habit, isDemo: widget.isDemo),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/pages/other_pages/edit_habit_page.dart';
import 'package:habitt/providers/calendar_provider.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/widgets/habit_widget/habit_completion/habit_completion.dart';
import 'package:habitt/widgets/habit_widget/habit_icon.dart';
import 'package:habitt/widgets/habit_widget/habit_streak.dart';
import 'package:habitt/widgets/habit_widget/habit_text.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class HabitWidget extends StatefulWidget {
  const HabitWidget({
    super.key,
    required this.editable,
    required this.habit,
    required this.isFirstCategory,
    this.isToday = true,
  });

  final Habit habit;
  final bool editable;
  final bool isFirstCategory;
  final bool isToday;

  @override
  State<HabitWidget> createState() => _HabitWidgetState();
}

class _HabitWidgetState extends State<HabitWidget>
    with TickerProviderStateMixin {
  double _swipeOffset = 0;

  // Animation controllers for swipe
  late AnimationController _controller;
  late Animation<double> _animation;

  // Animation controllers for svg rotation
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  bool _hasTriggeredRotation = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeOut),
    );
  }

  void animateBack() {
    _animation = Tween<double>(begin: _swipeOffset, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    )..addListener(() {
      setState(() {
        _swipeOffset = _animation.value;
      });
    });

    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _rotationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final colorProvider = context.watch<ColorProvider>();
    final focusedDay = context.watch<CalendarProvider>().focusedDay;
    final int alpha = 100;

    // Main container
    return TweenAnimationBuilder(
      tween: Tween<double>(
        begin: 0,
        end: widget.habit.completed || widget.habit.skipped ? 0 : 1,
      ),
      duration: const Duration(milliseconds: 150),
      builder: (context, double value, child) {
        return StatefulBuilder(
          builder: (context, setStateTile) {
            return GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (widget.habit.skipped ||
                    widget.habit.completed ||
                    widget.editable) {
                  return;
                }
                setStateTile(() {
                  _swipeOffset = (_swipeOffset + details.delta.dx).clamp(
                    0.0,
                    100,
                  );

                  // Trigger rotation animation once when swipe crosses 100
                  if (_swipeOffset >= 100 && !_hasTriggeredRotation) {
                    _rotationController.forward(from: 0);
                    HapticFeedback.selectionClick();
                    _hasTriggeredRotation = true;
                  } else if (_swipeOffset < 100 && _hasTriggeredRotation) {
                    _hasTriggeredRotation = false;
                  }
                });
              },
              onHorizontalDragEnd: (details) {
                if (widget.habit.skipped ||
                    widget.habit.completed ||
                    widget.editable) {
                  return;
                }
                if (_swipeOffset >= 100) {
                  debugPrint('Swiped enough to trigger action');

                  habitProvider.skipHabit(
                    widget.habit.id,
                    context,
                    day: widget.isToday ? DateTime.now() : focusedDay,
                  );

                  // Reset position after action, reset it gradually so its animated
                  animateBack(); // Smooth reset
                } else {
                  // Reset position, reset it gradually so its animated
                  animateBack(); // Smooth reset
                }
              },

              onTap:
                  widget.editable || !widget.isToday
                      ? null
                      : () {
                        // For navigating to edit habit page

                        final CategoryProvider categoryProvider =
                            context.read<CategoryProvider>();

                        // Save the selected category
                        final int temp = categoryProvider.selectedCategoryId;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => EditHabitPage(habit: widget.habit),
                          ),
                        ).whenComplete(() {
                          // Select the saved category
                          categoryProvider.selectCategory(temp);
                        });
                      },
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Background action color
                  Positioned.fill(
                    child: AnimatedOpacity(
                      opacity: (_swipeOffset / 150).clamp(0, 1),
                      duration: const Duration(milliseconds: 50),
                      child: Container(
                        margin: EdgeInsets.only(top: 8, left: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            stops: [0, 0.7],
                            colors: [
                              _swipeOffset >= 100
                                  ? colorProvider.colorScheme.vividColor
                                      .withAlpha(alpha)
                                  : colorProvider.colorScheme.strokeColor
                                      .withAlpha(alpha),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: AnimatedBuilder(
                          animation: _rotationAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle:
                                  _rotationAnimation.value * 2 * 3.1416, // 360°
                              child: child,
                            );
                          },
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 50),
                            scale: _swipeOffset >= 100 ? 1.2 : 1,
                            child: SizedBox(
                              height: 40,
                              width: 40,
                              child: SvgPicture.asset(
                                "assets/images/svg/skip.svg",
                                colorFilter: ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Main container
                  Transform.translate(
                    offset: Offset(_swipeOffset, 0),
                    child: Container(
                      margin: EdgeInsets.only(
                        top: 8,
                        left: widget.isFirstCategory ? 0 : 16,
                        right: widget.isFirstCategory ? 0 : 16,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      height: 74,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: colorProvider.habitColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),

                      // Inside of the container
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left side
                          Row(
                            children: [
                              // Icon circle container
                              HabitIcon(
                                editable: widget.editable,
                                colorProvider: colorProvider,
                                alpha: alpha,
                                habit: widget.habit,
                                value: value,
                              ),
                              // Text
                              HabitText(
                                habit: widget.habit,
                                colorProvider: colorProvider,
                                alpha: alpha,
                                value: value,
                              ),
                            ],
                          ),
                          // Completion and streak
                          Row(
                            children: [
                              if (widget.isToday)
                                if (widget.habit.streak > 0 ||
                                    widget.habit.completed)
                                  StreakDisplay(
                                    streak: widget.habit.streak,
                                    completed: widget.habit.completed,
                                    colorProvider: colorProvider,
                                  ),

                              // Completion
                              CompletionDisplay(
                                editable: widget.editable,
                                colorProvider: colorProvider,
                                habit: widget.habit,
                                isToday: widget.isToday,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 24,
                    left: widget.isFirstCategory ? 0 : 16,
                    bottom: 16,

                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: 2,
                      margin: EdgeInsets.symmetric(
                        vertical:
                            widget.habit.completed || widget.habit.skipped
                                ? 0
                                : (40), // Initial size from the middle
                      ),
                      decoration: BoxDecoration(
                        color:
                            widget.habit.completed
                                ? colorProvider.colorScheme.vividColor
                                : widget.habit.skipped
                                ? colorProvider.colorScheme.strokeColor.darken(
                                  colorProvider.isDarkMode ? 20 : 50,
                                )
                                : Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

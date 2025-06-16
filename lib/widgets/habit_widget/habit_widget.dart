import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/pages/other_pages/edit_habit_page.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/habit_widget/habit_completion/habit_completion.dart';
import 'package:habitt/widgets/habit_widget/habit_icon.dart';
import 'package:habitt/widgets/habit_widget/habit_streak.dart';
import 'package:habitt/widgets/habit_widget/habit_text.dart';
import 'package:provider/provider.dart';

class HabitWidget extends StatefulWidget {
  const HabitWidget({super.key, required this.editable, required this.habit});

  final Habit habit;
  final bool editable;

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
      duration: const Duration(milliseconds: 150),
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
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
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
    final colorProvider = context.watch<ColorProvider>();
    final int alpha = 100;

    // Main container
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: widget.habit.completed ? 0 : 1),
      duration: const Duration(milliseconds: 150),
      builder: (context, double value, child) {
        return StatefulBuilder(
          builder: (context, setStateTile) {
            return GestureDetector(
              onHorizontalDragUpdate: (details) {
                setStateTile(() {
                  _swipeOffset = (_swipeOffset + details.delta.dx).clamp(
                    0.0,
                    150.0,
                  );

                  // Trigger rotation animation once when swipe crosses 100
                  if ((_swipeOffset / 150).clamp(0, 1) >= 0.67 &&
                      !_hasTriggeredRotation) {
                    _rotationController.forward(from: 0);
                    _hasTriggeredRotation = true;
                  } else if ((_swipeOffset / 150).clamp(0, 1) < 0.67 &&
                      _hasTriggeredRotation) {
                    _hasTriggeredRotation = false;
                  }
                });
              },
              onHorizontalDragEnd: (details) {
                if (_swipeOffset > 100) {
                  // Trigger your action
                  print('Swiped enough to trigger action');
                  // Reset position after action, reset it gradually so its animated
                  animateBack(); // Smooth reset
                } else {
                  // Reset position, reset it gradually so its animated
                  animateBack(); // Smooth reset
                }
              },

              onTap:
                  widget.editable
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
                children: [
                  // Background action color
                  Positioned.fill(
                    child: AnimatedOpacity(
                      opacity: (_swipeOffset / 150).clamp(0, 1),
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        margin: EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            stops: [0, 0.7],
                            colors: [
                              (_swipeOffset / 150).clamp(0, 1) >= 0.67
                                  ? colorProvider.colorScheme.vividColor
                                      .withAlpha(alpha)
                                  : colorProvider.colorScheme.strokeColor
                                      .withAlpha(alpha),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
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
                            scale:
                                (_swipeOffset / 150).clamp(0, 1) >= 0.67
                                    ? 1.2
                                    : 1,
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

                  Transform.translate(
                    offset: Offset(_swipeOffset, 0),
                    child: Container(
                      margin: EdgeInsets.only(top: 8),
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      height: 74,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color.lerp(
                              colorProvider.habitColor.withAlpha(alpha),
                              colorProvider.habitColor.withAlpha(alpha + 100),
                              value,
                            )!,
                            Color.lerp(
                              colorProvider.colorScheme.standardColor.withAlpha(
                                alpha,
                              ),
                              colorProvider.colorScheme.standardColor.withAlpha(
                                alpha + 100,
                              ),
                              value,
                            )!,
                          ],
                        ),
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
                              if (widget.habit.streak > 0 ||
                                  widget.habit.completed)
                                // TODO: Add animation for the streak first appearing
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
                              ),
                            ],
                          ),
                        ],
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

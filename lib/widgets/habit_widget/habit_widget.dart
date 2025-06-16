import 'package:flutter/material.dart';
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

class _HabitWidgetState extends State<HabitWidget> with SingleTickerProviderStateMixin {
   double _swipeOffset = 0;

   late AnimationController _controller;
  late Animation<double> _animation;


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
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
                  _swipeOffset =
                      (_swipeOffset + details.delta.dx).clamp(0.0, 150.0);
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
                            builder: (context) => EditHabitPage(habit: widget.habit),
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
                      opacity: (_swipeOffset/150).clamp(0, 1),
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        margin: EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: colorProvider.colorScheme.strokeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: Text("Skip", style: TextStyle(color: colorProvider.textColor, fontSize: 16),),
                      ),
                    ),
                  ),

                  Transform.translate(
                    offset: Offset(_swipeOffset, 0),
                    child: Container(
                      margin: EdgeInsets.only(top: 8),
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                              colorProvider.colorScheme.standardColor.withAlpha(alpha),
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
                              if (widget.habit.streak > 0 || widget.habit.completed)
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
          }
        );
      },
    );
  }
}

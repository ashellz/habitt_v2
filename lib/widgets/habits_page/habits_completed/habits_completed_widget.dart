import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/util/get_category_length.dart';
import 'package:habitt/widgets/default/animated_completion_checkmark.dart';
import 'package:habitt/widgets/default/glass_feel_container.dart';
import 'package:habitt/widgets/habits_page/habits_completed/habit_status_text.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class HabitsCompletedWidget extends StatefulWidget {
  const HabitsCompletedWidget({super.key});

  @override
  State<HabitsCompletedWidget> createState() => _HabitsCompletedWidgetState();
}

class _HabitsCompletedWidgetState extends State<HabitsCompletedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _curvedAnimation;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      reverseDuration: const Duration(milliseconds: 150),
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeInQuad,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final categoryProvider = context.watch<CategoryProvider>();
    final selectedCategoryId = categoryProvider.selectedCategoryId;

    final Category category =
        selectedCategoryId == 0
            ? Category(id: 0, name: "All")
            : categoryProvider.categories.firstWhere(
              (cat) => cat.id == selectedCategoryId,
              orElse: () => Category(id: 0, name: "All"),
            );

    final completedCount = getCompletedHabits(category, context);
    final notCompletedCount = getNotCompletedHabits(category, context);
    final totalCount = completedCount + notCompletedCount;

    final allCompleted = totalCount > 0 && notCompletedCount == 0;

    if (!_initialized) {
      // Set initial state without animating on first build
      if (allCompleted) {
        _animationController.value = 1.0;
      } else {
        _animationController.value = 0.0;
      }
      _initialized = true;
      return;
    }

    if (allCompleted && _animationController.isDismissed) {
      _animationController.forward();
    } else if (!allCompleted && _animationController.isCompleted) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final bg = tp.backgroundColor;
    final categoryProvider = context.watch<CategoryProvider>();
    final selectedCategoryId = categoryProvider.selectedCategoryId;

    final Category category =
        selectedCategoryId == 0
            ? Category(id: 0, name: "All")
            : categoryProvider.categories.firstWhere(
              (cat) => cat.id == selectedCategoryId,
              orElse: () => Category(id: 0, name: "All"),
            );

    final completedCount = getCompletedHabits(category, context);
    final notCompletedCount = getNotCompletedHabits(category, context);
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Stack(
        children: [
          // Main content
          GlassFeelContainer(
            child: Column(
              children: [
                HabitsStatus(isCompleted: true, numberOfHabits: completedCount),
                const SizedBox(height: 8),
                HabitsStatus(
                  isCompleted: false,
                  numberOfHabits: notCompletedCount,
                ),
              ],
            ),
          ),
          // Animated "Complete" overlay if all habits are completed
          AnimatedBuilder(
            animation: _curvedAnimation,
            builder: (context, child) {
              return Positioned.fill(
                child: Opacity(
                  opacity: _curvedAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _curvedAnimation.value)),
                    child:
                        _curvedAnimation.value > 0
                            ? Container(
                              margin: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: bg.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      loc.complete,
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: tp.primaryTextColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    if (_curvedAnimation.value > 0)
                                      AnimatedCompletionCheckmark(
                                        size: 24,
                                        duration: Duration(milliseconds: 800),
                                      ),
                                  ],
                                ),
                              ),
                            )
                            : SizedBox.shrink(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

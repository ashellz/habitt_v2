import 'package:flutter/widgets.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/widgets/habits_page/scroll_transformed_habit_category_title.dart';
import 'package:habitt/widgets/scroll_transformed_habit_widget.dart';
import 'package:provider/provider.dart';

class HabitCategory extends StatefulWidget {
  const HabitCategory({
    super.key,
    this.isFirst = false,
    required this.category,
    required this.scrollController,
    required this.bottomViewportEdgeGlobalY,
    required this.effectZoneHeight,
    required this.minScale,
    required this.stackOffsetFactor,
  });

  final bool isFirst;
  final Category category;
  // These parameters are passed down from HabitsPage -> Habits -> HabitCategory
  final ScrollController scrollController;
  final double bottomViewportEdgeGlobalY;
  final double effectZoneHeight;
  final double minScale;
  final double stackOffsetFactor;

  @override
  State<HabitCategory> createState() => _HabitCategoryState();
}

class _HabitCategoryState extends State<HabitCategory> {
  double _opacity = 0; // From your original code for initial fade-in

  @override
  void initState() {
    super.initState();
    // Original fade-in animation
    Future.delayed(Duration.zero, () {
      if (mounted) {
        setState(() {
          _opacity = 1;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final categoryHabits =
        habitProvider.habits
            .where((habit) => habit.categoryId == widget.category.id)
            .toList();

    if (categoryHabits.isEmpty) return Container();

    return AnimatedOpacity(
      opacity: _opacity, // For the initial fade-in of the whole category block
      duration: const Duration(milliseconds: 150),
      child: Column(
        children: [
          // Use the new ScrollTransformedHabitCategoryTitle
          ScrollTransformedHabitCategoryTitle(
            isFirst: widget.isFirst,
            category: widget.category,
            scrollController: widget.scrollController,
            bottomViewportEdgeGlobalY: widget.bottomViewportEdgeGlobalY,
            effectZoneHeight: widget.effectZoneHeight,
            minScale: widget.minScale,
            stackOffsetFactor: widget.stackOffsetFactor,
          ),
          // Individual habits also use their transforming wrapper
          for (final habit in categoryHabits)
            ScrollTransformedHabitWidget(
              // Assuming this is the widget from the previous answer
              habit: habit,
              editable: false, // Or your logic for this
              scrollController: widget.scrollController,
              bottomViewportEdgeGlobalY: widget.bottomViewportEdgeGlobalY,
              effectZoneHeight: widget.effectZoneHeight,
              minScale: widget.minScale,
              stackOffsetFactor: widget.stackOffsetFactor,
            ),
        ],
      ),
    );
  }
}

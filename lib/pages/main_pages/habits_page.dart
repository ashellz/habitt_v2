import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/pages/other_pages/add_habit_page.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/get_category_length.dart';
import 'package:habitt/widgets/gradient_background.dart';
import 'package:habitt/widgets/habits_page/categories/categories_list.dart';
import 'package:habitt/widgets/habits_page/category_title.dart';
import 'package:habitt/widgets/habits_page/greeting.dart';
import 'package:habitt/widgets/habits_page/habits_completed/habits_completed_widget.dart';
import 'package:habitt/widgets/scroll_transformed_habit_widget.dart';
import 'package:provider/provider.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listViewKey = GlobalKey();

  // Configuration for the stacking effect
  final double _effectZoneHeight =
      120.0; // Pixels from bottom of viewport where effect starts
  final double _minScale = 0.85; // Smallest scale for a stacked item
  final double _stackOffsetFactor =
      0.15; // Factor of item height for upward offset (e.g., 0.15 = 15% of its height)

  double _bottomViewportEdgeGlobalY = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Get initial geometry after the first frame
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateListViewportGeom(),
    );
  }

  void _updateListViewportGeom() {
    if (!mounted || !_scrollController.hasClients) {
      // If not mounted or scroll controller not ready, try again after next frame
      if (mounted)
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _updateListViewportGeom(),
        );
      return;
    }

    final RenderBox? listViewRenderBox =
        _listViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (listViewRenderBox != null && listViewRenderBox.hasSize) {
      final listViewGlobalOffset = listViewRenderBox.localToGlobal(Offset.zero);
      final currentBottomViewportY =
          listViewGlobalOffset.dy +
          _scrollController.position.viewportDimension;

      // Only update state if the value actually changes to avoid unnecessary rebuilds
      if (_bottomViewportEdgeGlobalY != currentBottomViewportY) {
        setState(() {
          _bottomViewportEdgeGlobalY = currentBottomViewportY;
        });
      }
    } else {
      // If renderbox not available yet, retry
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _updateListViewportGeom(),
      );
    }
  }

  void _onScroll() {
    if (!mounted) return;
    // We need to call _updateListViewportGeom in case the listview's position/size changes
    // for example, due to keyboard or other dynamic UI elements above it.
    // However, for pure scrolling, its global Y and viewportDimension are often stable.
    // The primary need for setState is to make children re-evaluate their position.
    // _updateListViewportGeom(); // Call if you suspect ListView geometry changes during scroll
    setState(() {
      // This will cause visible HabitWidgets to rebuild and update their transforms
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorProvider colorProvider = context.watch<ColorProvider>();

    // Ensure viewport geometry is updated if screen size changes (e.g. orientation)
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateListViewportGeom(),
    );

    return Scaffold(
      backgroundColor: colorProvider.backgroundColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorProvider.colorScheme.darkerStandardColor,

        onPressed:
            () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => AddHabitPage()))
                .whenComplete(() {
                  // Reset the state provider

                  if (!context.mounted) return;

                  final stateProvider = context.read<StateProvider>();

                  stateProvider.reset();

                  // Reset the category provider

                  final categoryProvider = context.read<CategoryProvider>();

                  categoryProvider.selectCategory(0);
                }),

        child: Icon(Icons.add, color: Colors.white),
      ),
      body: GradientBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView(
            key: _listViewKey, // Assign the GlobalKey
            controller: _scrollController, // Assign the ScrollController
            physics: const BouncingScrollPhysics(),
            children: [
              const Greeting(),
              const CategoriesList(),
              const HabitsCompletedWidget(),
              // Pass down the necessary parameters for the effect
              Habits(
                scrollController: _scrollController,
                bottomViewportEdgeGlobalY: _bottomViewportEdgeGlobalY,
                effectZoneHeight: _effectZoneHeight,
                minScale: _minScale,
                stackOffsetFactor: _stackOffsetFactor,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

// Step 2: Modify Habits and HabitCategory to pass parameters down

class Habits extends StatelessWidget {
  final ScrollController scrollController;
  final double bottomViewportEdgeGlobalY;
  final double effectZoneHeight;
  final double minScale;
  final double stackOffsetFactor;

  const Habits({
    super.key,
    required this.scrollController,
    required this.bottomViewportEdgeGlobalY,
    required this.effectZoneHeight,
    required this.minScale,
    required this.stackOffsetFactor,
  });

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final habitProvider = context.watch<HabitProvider>();
    final habits = habitProvider.habits;
    final ColorProvider colorProvider = context.watch<ColorProvider>();

    if (habits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Text(
          "No habits yet.",
          style: TextStyle(color: colorProvider.mutedTextColor),
        ),
      );
    }

    if (categoryProvider.selectedCategoryId != 0) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: HabitCategory(
              category: categoryProvider.categories.firstWhere(
                (c) => c.id == categoryProvider.selectedCategoryId,
              ),
              // Pass parameters
              scrollController: scrollController,
              bottomViewportEdgeGlobalY: bottomViewportEdgeGlobalY,
              effectZoneHeight: effectZoneHeight,
              minScale: minScale,
              stackOffsetFactor: stackOffsetFactor,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        for (final category in categoryProvider.categories)
          if (getCategoryLength(category, context) > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: HabitCategory(
                category: category,

                scrollController: scrollController,
                bottomViewportEdgeGlobalY: bottomViewportEdgeGlobalY,
                effectZoneHeight: effectZoneHeight,
                minScale: minScale,
                stackOffsetFactor: stackOffsetFactor,
              ),
            ),
      ],
    );
  }
}

class HabitCategory extends StatefulWidget {
  final Category category;

  final ScrollController scrollController;
  final double bottomViewportEdgeGlobalY;
  final double effectZoneHeight;
  final double minScale;
  final double stackOffsetFactor;

  const HabitCategory({
    super.key,
    required this.category,
    required this.scrollController,
    required this.bottomViewportEdgeGlobalY,
    required this.effectZoneHeight,
    required this.minScale,
    required this.stackOffsetFactor,
  });

  @override
  State<HabitCategory> createState() => _HabitCategoryState();
}

class _HabitCategoryState extends State<HabitCategory> {
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
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
      opacity: _opacity,
      duration: const Duration(milliseconds: 150),
      child: Column(
        children: [
          HabitCategoryTitle(category: widget.category),
          for (final habit in categoryHabits)
            // Use the new ScrollTransformedHabitWidget
            ScrollTransformedHabitWidget(
              habit: habit,
              editable: false, // Or however you determine this
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

import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/pages/other_pages/add_habit_page.dart';
import 'package:habitt/pages/other_pages/setup_name_page.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/get_category_length.dart';
import 'package:habitt/widgets/gradient_background.dart';
import 'package:habitt/widgets/habits_page/categories/categories_list.dart';
import 'package:habitt/widgets/habits_page/greeting.dart';
import 'package:habitt/widgets/habits_page/habits_completed/habits_completed_widget.dart';
import 'package:habitt/widgets/habits_page/scroll_transformed_habit_category_title.dart';
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
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _updateListViewportGeom(),
        );
      }
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

class Habits extends StatefulWidget {
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
  State<Habits> createState() => _HabitsState();
}

class _HabitsState extends State<Habits> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
              scrollController: widget.scrollController,
              bottomViewportEdgeGlobalY: widget.bottomViewportEdgeGlobalY,
              effectZoneHeight: widget.effectZoneHeight,
              minScale: widget.minScale,
              stackOffsetFactor: widget.stackOffsetFactor,
            ),
          ),
        ],
      );
    }

    final List<Category> categories = categoryProvider.categoriesOrdered;

    return Column(
      children: [
        for (final category in categories)
          if (getCategoryLength(category, context) > 0)
            // Check if category is first
            if (category == categories.first)
              // Put it in a glass box with animated gradient
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: colorProvider.colorScheme.standardColor.withAlpha(
                      255,
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: GradientWavePainter(
                          _animation.value,
                          colorProvider,
                        ),
                        child: HabitCategory(
                          isFirst: true,
                          category: category,

                          scrollController: widget.scrollController,
                          bottomViewportEdgeGlobalY:
                              widget.bottomViewportEdgeGlobalY,
                          effectZoneHeight: widget.effectZoneHeight,
                          minScale: widget.minScale,
                          stackOffsetFactor: widget.stackOffsetFactor,
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: HabitCategory(
                  category: category,

                  scrollController: widget.scrollController,
                  bottomViewportEdgeGlobalY: widget.bottomViewportEdgeGlobalY,
                  effectZoneHeight: widget.effectZoneHeight,
                  minScale: widget.minScale,
                  stackOffsetFactor: widget.stackOffsetFactor,
                ),
              ),
      ],
    );
  }
}

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

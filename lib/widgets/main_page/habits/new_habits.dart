import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/util/get_category_length.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/habit_widget/habit_icon.dart';
import 'package:habitt/widgets/habit_widget/text_icon.dart';
import 'package:habitt/widgets/main_page/habits/new_habit_category.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class NewHabits extends StatefulWidget {
  final DateTime? daySelected;
  final bool hasMainCategory;

  const NewHabits({super.key, this.daySelected, this.hasMainCategory = false});

  @override
  State<NewHabits> createState() => _NewHabitsState();
}

class _NewHabitsState extends State<NewHabits>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Habit> habits;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    habits = _getHabits();
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
  ) {
    const double categoryTitleHeight = 26;
    const double habitHeight = 74; // 42 icon + 32 padding
    const double categoryTopPadding = 12;
    const double categorySpacing = 10;

    double totalHeight = 0;

    for (final category in categories) {
      final categoryLength = getCategoryLength(
        category,
        context,
        false,
        widget.daySelected,
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
      }
    }

    return totalHeight;
  }

  List<Habit> _getHabits() {
    debugPrint(
      "Getting habits for Habits widget ======================================== new DAY SELECTED: ${widget.daySelected} ",
    );
    final habitProvider = context.read<HabitProvider>();
    final today = DateTime.now();
    final todayShort = DateTime(today.year, today.month, today.day);
    if (widget.daySelected == null || widget.daySelected == todayShort) {
      return habitProvider.habits;
    }

    return habitProvider.getHabitsFromDay(widget.daySelected!);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final selectedCategoryId = categoryProvider.selectedCategoryId;

    final optionalHabitsCount = habits.where((habit) => habit.optional).length;
    final cp = context.watch<ColorProvider>();

    final perfectDaysStreak = context.watch<StatsProvider>().perfectDaysStreak;
    final habitsListHeight = _calculateHabitsListHeight(
      context,
      perfectDaysStreak,
    );

    if (habits.isEmpty) {
      return SizedBox(
        height: habitsListHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 16,
          children: [
            Spacer(),
            SvgPicture.asset("assets/images/new-svg/empty-box.svg"),
            Text(
              "You haven’t added any habits yet",
              style: TextStyle(color: cp.lightGreyText, fontSize: 16),
            ),
            const Spacer(),
            addHabitButton(cp),
          ],
        ),
      );
    }

    final List<Category> categories = categoryProvider.categoriesOrdered;

    // Calculate remaining height for bottom spacing
    final contentHeight = _calculateContentHeight(categories, context);
    final bottomSpacing = (habitsListHeight - contentHeight).clamp(
      0.0,
      double.infinity,
    );

    if (selectedCategoryId != 0) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: NewHabitCategory(
              key: ValueKey(selectedCategoryId),
              isToday: widget.daySelected == null,
              habits: habits,
              showOptionalHabits: true,
              category: categoryProvider.categories.firstWhere(
                (c) => c.id == selectedCategoryId,
              ),
            ),
          ),
          if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
        ],
      );
    }

    return Column(
      children: [
        for (final category in categories)
          if (getCategoryLength(category, context, false, widget.daySelected) >
              0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: NewHabitCategory(
                isToday: widget.daySelected == null,
                habits: habits,
                isFirst: category == categories.first,
                category: category,
                showOptionalHabits: false,
              ),
            ),

        Padding(
          padding: EdgeInsets.only(
            top: optionalHabitsCount == habits.length ? 12 : 0,
          ),
          // child additional tasks
        ),

        addHabitButton(cp),

        if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
      ],
    );
  }

  Padding addHabitButton(ColorProvider cp) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: NewDefaultButton.secondary(
        height: 40,
        label: "Add habit",
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: cp.bg,
            barrierColor: cp.greyText.darken().withOpacity(0.3),
            isScrollControlled: true,
            builder: (context) {
              return AddNewHabitSheet();
            },
          );
        },
        prefix: SvgPicture.asset(
          "assets/images/new-svg/add.svg",
          colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
        ),
      ),
    );
  }
}

class AddNewHabitSheet extends StatelessWidget {
  const AddNewHabitSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final stateProvider = context.watch<StateProvider>();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      child: Column(
        spacing: 20,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          topSection(context, cp),
          chooseIcon(cp, stateProvider, context),
        ],
      ),
    );
  }

  Column chooseIcon(
    ColorProvider cp,
    StateProvider stateProvider,
    BuildContext context,
  ) {
    return Column(
      spacing: 20,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose icon',
          style: TextStyle(
            color: cp.text,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        NewDefaultButton(
          onPressed: () async {
            final emoji = await showEmojiKeyboardDialog(context, cp);
            if (emoji != null && context.mounted) {
              stateProvider.iconPath = emoji;
            }
          },
          width: 84,
          height: 84,
          color: cp.secondaryButton,
          padding: EdgeInsets.all(20),
          child: TextIcon(
            stateProvider.iconPath.isEmpty ? "🏀" : stateProvider.iconPath,
            size: 44,
          ),
        ),
      ],
    );
  }

  Padding topSection(BuildContext context, ColorProvider cp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 36, // button height
            width: 66,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Align(
                alignment: Alignment.centerLeft,
                child: SvgPicture.asset("assets/images/new-svg/back.svg"),
              ),
            ),
          ),
          Text(
            'New Habit',
            style: TextStyle(
              color: cp.text,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          NewDefaultButton.small(onPressed: () {}, label: "Done"),
        ],
      ),
    );
  }
}

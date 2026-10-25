import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:habitt/demo/demo_habits.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/pages/other_pages/habit_details_page.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/util/build_plan_sections.dart';
import 'package:habitt/util/format_minutes_of_day.dart';
import 'package:habitt/widgets/main_page/add_habit_button.dart';
import 'package:habitt/widgets/main_page/habits/empty_habits_widget.dart';
import 'package:habitt/widgets/main_page/habits/habit_widget/new_habit_widget.dart';
import 'package:habitt/widgets/main_page/habits/new_habits.dart';
import 'package:provider/provider.dart';

/// Home page plan view: the day's habits that have a time interval, laid out
/// on a timeline. Display only, cards complete and open details like the list.
class PlanHabits extends StatefulWidget {
  const PlanHabits({super.key});

  @override
  State<PlanHabits> createState() => _PlanHabitsState();
}

class _PlanHabitsState extends State<PlanHabits> {
  // cards are indented so the time titles have room on the left
  static const double _cardIndent = 45;

  Timer? _minuteTimer;

  @override
  void initState() {
    super.initState();
    _scheduleMinuteTick();
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    super.dispose();
  }

  // rebuilds on every minute boundary so the current-time highlight moves
  void _scheduleMinuteTick() {
    final now = DateTime.now();
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    _minuteTimer = Timer(nextMinute.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _scheduleMinuteTick();
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final selectedDay = DateUtils.dateOnly(habitProvider.selectedDate ?? now);
    final isToday = selectedDay == today;

    final habits =
        isToday
            ? habitProvider.todaysHabits
            : habitProvider.getHabitsForDate(selectedDay);

    final orderedCategories = categoryProvider.categoriesOrdered;
    final nowMinutes = isToday ? now.hour * 60 + now.minute : null;
    final sections = buildPlanSections(
      habits: habits,
      nowMinutes: nowMinutes,
      scheduledYesterdayIds:
          isToday
              ? habitProvider
                  .getHabitsForDate(today.subtract(const Duration(days: 1)))
                  .map((habit) => habit.id)
                  .toSet()
              : const {},
      categoryRank: {
        for (int i = 0; i < orderedCategories.length; i++)
          orderedCategories[i].id: i,
      },
    );

    // demo habits are display only, treated as scheduled every day
    final demoSections =
        context.watch<PreferencesProvider>().showDemoHabits
            ? buildPlanSections(
              habits: demoHabits,
              nowMinutes: nowMinutes,
              scheduledYesterdayIds: {for (final habit in demoHabits) habit.id},
            )
            : const <PlanSection>[];

    final dayKey =
        '${selectedDay.year}-${selectedDay.month}-${selectedDay.day}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (demoSections.isNotEmpty) _demoBlock(context, demoSections, dayKey),
        _plan(context, habitProvider, habits, sections, isToday, dayKey),
      ],
    );
  }

  Widget _plan(
    BuildContext context,
    HabitProvider habitProvider,
    List<Habit> habits,
    List<PlanSection> sections,
    bool isToday,
    String dayKey,
  ) {
    final perfectDaysStreak = context.watch<StatsProvider>().perfectDaysStreak;
    final listHeight = calculateHabitsListHeight(context, perfectDaysStreak);

    if (sections.isEmpty) {
      final hasAnyHabits = habitProvider.habits.any(
        (habit) => habit.isDeleted != true,
      );
      return SizedBox(
        height: listHeight,
        child: Column(
          spacing: 16,
          children: [
            const Spacer(),
            EmptyHabitsWidget(
              variant:
                  !hasAnyHabits
                      ? EmptyHabitsVariant.noHabits
                      : habits.isEmpty
                      ? EmptyHabitsVariant.noneScheduled
                      : EmptyHabitsVariant.noneTimed,
              isToday: isToday,
            ),
            const Spacer(),
            const AddHabitButton(),
          ],
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: listHeight),
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            ..._timeline(context, sections, dayKey),
            const AddHabitButton(),
            if (Platform.isAndroid) const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<Widget> _timeline(
    BuildContext context,
    List<PlanSection> sections,
    String dayKey, {
    bool isDemo = false,
  }) {
    return [
      for (final section in sections) ...[
        _timeTitle(context, section.start),
        for (final entry in section.entries)
          _habitCard(context, entry, dayKey, isDemo: isDemo),
      ],
    ];
  }

  // ─── Demo mode ────────────────────────────────────────

  Widget _demoBlock(
    BuildContext context,
    List<PlanSection> sections,
    String dayKey,
  ) {
    final cp = context.watch<ColorProvider>();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Text("Demo mode", style: TextStyle(color: cp.greyText)),
          ..._timeline(context, sections, dayKey, isDemo: true),
        ],
      ),
    );
  }

  // ─── Time title ───────────────────────────────────────

  Widget _timeTitle(BuildContext context, int minutes) {
    final cp = context.watch<ColorProvider>();

    return Row(
      spacing: 8,
      children: [
        Text(
          formatMinutesOfDay(context, minutes),
          style: TextStyle(
            color: cp.isDark ? cp.lightGreyText : cp.greyText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: CustomPaint(
            size: const Size.fromHeight(1),
            painter: _DashedLinePainter(color: cp.disabled),
          ),
        ),
      ],
    );
  }

  // ─── Habit card ───────────────────────────────────────

  Widget _habitCard(
    BuildContext context,
    PlanEntry entry,
    String dayKey, {
    bool isDemo = false,
  }) {
    final Habit habit = entry.habit;

    if (isDemo) {
      return Padding(
        key: ValueKey('plan-demo-habit-${habit.id}'),
        padding: const EdgeInsets.only(left: _cardIndent),
        child: NewHabitWidget(
          habit: habit,
          isDemo: true,
          isCurrent: entry.isCurrent,
        ),
      );
    }

    return Padding(
      key: ValueKey('plan-habit-$dayKey-${habit.id}'),
      padding: const EdgeInsets.only(left: _cardIndent),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              settings: RouteSettings(arguments: habit.id),
              builder: (_) => HabitDetailsPage(habitId: habit.id),
            ),
          );
        },
        child: NewHabitWidget(habit: habit, isCurrent: entry.isCurrent),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  static const double _dash = 10;
  static const double _gap = 10;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1;
    final y = size.height / 2;
    for (double x = 0; x < size.width; x += _dash + _gap) {
      final end = (x + _dash).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

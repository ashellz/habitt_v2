import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/pages/main_pages/calendar_page.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/habit_details/habit_primary_action_button.dart';
import 'package:habitt/widgets/main_page/habits/habit_widget/new_habit_widget.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class OnboardingStep1 extends StatefulWidget {
  const OnboardingStep1({super.key});

  @override
  State<OnboardingStep1> createState() => _OnboardingStep1State();
}

class _OnboardingStep1State extends State<OnboardingStep1>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animCalendar;
  late Animation<double> _animHabit;
  late Animation<double> _animButton;

  late Habit _demoHabit;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animCalendar = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.40, curve: Curves.easeOut),
    );
    _animHabit = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.20, 0.60, curve: Curves.easeOut),
    );
    _animButton = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.40, 0.80, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final loc = AppLocalizations.of(context)!;
      _demoHabit = Habit(
        id: -1,
        name: loc.onboardingDemoHabitStudying,
        iconPath: '📚',
        categoryId: 1,
        duration: 30,
        durationCompleted: 30,
        completed: true,
        trackingType: HabitTrackingType.duration,
      );
      _initialized = true;
    }
  }

  void _toggleDemo() {
    setState(() {
      _demoHabit.completed = !_demoHabit.completed;
      _demoHabit.durationCompleted =
          _demoHabit.completed ? _demoHabit.duration : 0;
    });
  }

  Widget _slide(Widget child, Animation<double> anim) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, -40 * (1 - anim.value)),
          child: child,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Container(
      width: double.infinity,
      height: double.infinity,
      margin: const EdgeInsets.only(right: 16, left: 16),
      child: Stack(
        children: [
          _slide(
            Transform.scale(
              scale: 0.8,
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cp.border,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(38),
                  child: CalendarPage.demo(),
                ),
              ),
            ),
            _animCalendar,
          ),
          Positioned(
            top: 160,
            left: 12,
            right: 12,
            child: _slide(
              Container(
                height: 86,
                decoration: BoxDecoration(
                  color: cp.habitBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: NewHabitWidget(habit: _demoHabit),
              ),
              _animHabit,
            ),
          ),
          Positioned(
            top: 95,
            left: 20,
            child: _slide(
              Transform.rotate(
                angle: -0.2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: cp.border.withValues(alpha: 0.2),
                        blurRadius: 16,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: HabitPrimaryActionButton(
                    habit: _demoHabit,
                    isDemo: true,
                    onDemoTap: _toggleDemo,
                  ),
                ),
              ),
              _animButton,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.2,
              widthFactor: 1.0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [cp.main, cp.main.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

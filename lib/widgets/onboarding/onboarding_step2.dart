import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/main_page/habits/habit_widget/new_habit_widget.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class OnboardingStep2 extends StatefulWidget {
  const OnboardingStep2({super.key});

  @override
  State<OnboardingStep2> createState() => _OnboardingStep2State();
}

class _OnboardingStep2State extends State<OnboardingStep2>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim1;
  late Animation<double> _anim2;
  late Animation<double> _anim3;
  late Animation<double> _anim4;

  late Habit _habit1;
  late Habit _habit2;
  late Habit _habit3;
  late Habit _habit4;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _anim1 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.36, curve: Curves.easeOut),
    );
    _anim2 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.18, 0.55, curve: Curves.easeOut),
    );
    _anim3 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.36, 0.73, curve: Curves.easeOut),
    );
    _anim4 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.91, curve: Curves.easeOut),
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
      _habit1 = Habit(
        id: -1,
        name: loc.onboardingDemoHabitStudying,
        iconPath: '📚',
        categoryId: 1,
        duration: 30,
        durationCompleted: 30,
        completed: true,
        trackingType: HabitTrackingType.duration,
      );
      _habit2 = Habit(
        id: -2,
        name: loc.onboardingDemoHabitBrushTeeth,
        iconPath: '🪥',
        categoryId: 1,
      );
      _habit3 = Habit(
        id: -3,
        name: loc.onboardingDemoHabitReadBook,
        iconPath: '📖',
        categoryId: 1,
        amount: 15,
        amountLabel: 'pages',
        amountCompleted: 7,
        trackingType: HabitTrackingType.amount,
      );
      _habit4 = Habit(
        id: -4,
        name: loc.onboardingDemoHabitPushUps,
        iconPath: '💪',
        categoryId: 1,
        amount: 30,
        amountCompleted: 0,
        trackingType: HabitTrackingType.amount,
      );
      _initialized = true;
    }
  }

  Widget _card(Habit habit, ColorProvider cp) {
    return DecoratedBox(
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
      child: Container(
        height: 86,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: cp.habitBg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: NewHabitWidget(habit: habit, isDemo: true),
      ),
    );
  }

  Widget _slide(Widget child, Animation<double> anim) {
    return AnimatedBuilder(
      animation: anim,
      builder:
          (context, child) => Opacity(
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
      margin: const EdgeInsets.only(right: 16, left: 16, top: 78),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 358,
              height: 358,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.24),
                shape: BoxShape.circle,
              ),
            ),
          ),
          _slide(
            Transform.translate(
              offset: const Offset(0, 0),
              child: _card(_habit1, cp),
            ),
            _anim1,
          ),
          _slide(
            Transform.translate(
              offset: const Offset(0, 300),
              child: Transform.rotate(angle: -0.01, child: _card(_habit4, cp)),
            ),
            _anim4,
          ),
          _slide(
            Transform.translate(
              offset: const Offset(0, 210),
              child: Transform.rotate(angle: 0.07, child: _card(_habit2, cp)),
            ),
            _anim3,
          ),
          _slide(
            Transform.translate(
              offset: const Offset(0, 115),
              child: Transform.rotate(angle: -0.05, child: _card(_habit3, cp)),
            ),
            _anim2,
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

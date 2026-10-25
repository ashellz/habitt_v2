import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/widgets/default/dual_option_selector.dart';
import 'package:habitt/widgets/main_page/categories/new_categories_list.dart';
import 'package:habitt/widgets/main_page/habits/demo_habits_section.dart';
import 'package:habitt/widgets/main_page/habits/new_habits.dart';
import 'package:habitt/widgets/main_page/plan/plan_habits.dart';
import 'package:provider/provider.dart';

/// Date label with the plan / list toggle, and the habits below it. Switching
/// slides the views sideways (plan sits on the left) with a horizontal blur.
class HomeHabitsView extends StatelessWidget {
  const HomeHabitsView({super.key, required this.dayLabel});

  final String dayLabel;

  static const Duration _switchDuration = Duration(milliseconds: 400);
  static const double _maxBlur = 12;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final prefs = context.watch<PreferencesProvider>();
    final showPlan = prefs.showPlanView;

    return Column(
      children: [
        // ─── Date label & view toggle ─────────────────────
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  dayLabel,
                  style: TextStyle(
                    fontSize: 16,
                    color: cp.isDark ? cp.lightGreyText : cp.greyText,
                  ),
                ),
              ),
              DualOptionSelector<bool>.icons(
                firstValue: true,
                secondValue: false,
                selectedValue: showPlan,
                onSelect: (value) {
                  if (value != null) prefs.setShowPlanView(value);
                },
                firstIcon:
                    (color) => _toggleIcon(
                      'assets/images/new-svg/plan-view.svg',
                      color,
                    ),
                secondIcon:
                    (color) => _toggleIcon(
                      'assets/images/new-svg/list-view.svg',
                      color,
                    ),
              ),
            ],
          ),
        ),

        // ─── Habits ───────────────────────────────────────
        ClipRect(
          child: AnimatedSize(
            duration: _switchDuration,
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: _switchDuration,
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              layoutBuilder:
                  (current, previous) => Stack(
                    alignment: Alignment.topCenter,
                    children: [...previous, if (current != null) current],
                  ),
              transitionBuilder:
                  (child, animation) => _slideTransition(
                    child: child,
                    animation: animation,
                    isIncoming: child.key == ValueKey(showPlan),
                    toPlan: showPlan,
                  ),
              child:
                  showPlan
                      ? const Padding(
                        key: ValueKey(true),
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: PlanHabits(),
                      )
                      : Column(
                        key: const ValueKey(false),
                        children: [
                          if (prefs.showCategoriesOnMainPage)
                            NewCategoriesList(),
                          if (prefs.showDemoHabits) const DemoHabitsSection(),
                          const Padding(
                            padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 8,
                            ),
                            child: NewHabits(),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _toggleIcon(String path, Color color) {
    return SizedBox.square(
      dimension: 20,
      child: Center(
        child: SvgPicture.asset(
          path,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    );
  }

  // The incoming view slides in from the side of the tapped option and the
  // outgoing one leaves the opposite way. Each blurs by how far it is from
  // resting, so the blur peaks mid-slide.
  Widget _slideTransition({
    required Widget child,
    required Animation<double> animation,
    required bool isIncoming,
    required bool toPlan,
  }) {
    final direction = (isIncoming ? -1.0 : 1.0) * (toPlan ? 1.0 : -1.0);

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final distance = 1 - animation.value;
        final blur = distance * _maxBlur;
        return FractionalTranslation(
          translation: Offset(direction * distance, 0),
          child: ImageFiltered(
            enabled: blur > 0.01,
            imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: 0),
            child: child,
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/habit_details/new/editable/enter_habit_duration.dart';
import 'package:habitt/widgets/habit_details/new/select_habit_type.dart';
import 'package:provider/provider.dart';

enum HabitType { none, amount, duration }

class SelectHabitType extends StatefulWidget {
  const SelectHabitType({super.key});

  @override
  State<SelectHabitType> createState() => _SelectHabitTypeState();
}

class _SelectHabitTypeState extends State<SelectHabitType> {
  HabitType selectedType = HabitType.none;
  HabitType lastSelectedType = HabitType.amount;
  bool useSlideTransition = false;
  Offset slideBeginOffset = Offset.zero;

  // Align duration usage:
  // We tweak it so if you enable amount from none but it was previously duration
  // It would slide fade the indicator to left from right
  // Looks unpurposeful so we disable duration for that moment
  Duration alignDuration = Duration(milliseconds: 350);

  Alignment _getIndicatorAlignment() {
    if (selectedType == HabitType.amount) {
      return Alignment.centerLeft;
    }

    if (selectedType == HabitType.duration) {
      return Alignment.centerRight;
    }

    return lastSelectedType == HabitType.duration
        ? Alignment.centerRight
        : Alignment.centerLeft;
  }

  void _setTransitionState(HabitType nextType) {
    final previousType = selectedType;

    final shouldSlide =
        previousType != HabitType.none &&
        nextType != HabitType.none &&
        previousType != nextType;

    useSlideTransition = shouldSlide;
    slideBeginOffset =
        nextType == HabitType.amount ? const Offset(-1, 0) : const Offset(1, 0);
  }

  // This toggles the amount type on tap, and navigates if selected
  void onTapAmount() {
    debugPrint("Tapped amount");

    setState(() {
      alignDuration = Duration(milliseconds: 350);
    });

    final stateProvider = context.read<StateProvider>();

    if (lastSelectedType == HabitType.duration &&
        selectedType == HabitType.none) {
      alignDuration = Duration.zero;
    }

    setState(() {
      final nextType =
          selectedType == HabitType.amount ? HabitType.none : HabitType.amount;
      _setTransitionState(nextType);

      // Toggles the selected type between amount and none
      selectedType = nextType;

      if (selectedType == HabitType.amount) {
        lastSelectedType = HabitType.amount;
      }
    });

    if (selectedType == HabitType.none) {
      // If deselected, clear amount
      stateProvider.habitAmount = 0;
    } else if (selectedType == HabitType.amount) {
      // If selected, we reset duration and set default amount
      stateProvider.habitDuration = Duration.zero;
      stateProvider.habitAmount = 2;

      debugPrint("Selected type: $selectedType");
    }
  }

  // This toggles the duration type on tap, and navigates if selected
  void onTapDuration() {
    debugPrint("Tapped duration");
    setState(() {
      alignDuration = Duration(milliseconds: 350);
    });
    final stateProvider = context.read<StateProvider>();

    if (lastSelectedType == HabitType.amount &&
        selectedType == HabitType.none) {
      alignDuration = Duration.zero;
    }

    setState(() {
      final nextType =
          selectedType == HabitType.duration
              ? HabitType.none
              : HabitType.duration;
      _setTransitionState(nextType);

      // Toggles the selected type between duration and none
      selectedType = nextType;

      if (selectedType == HabitType.duration) {
        lastSelectedType = HabitType.duration;
      }
    });

    if (selectedType == HabitType.none) {
      // If deselected, clear duration
      stateProvider.habitDuration = Duration.zero;
    } else if (selectedType == HabitType.duration) {
      // If selected, reset amount and set default duration
      stateProvider.habitAmount = 0;
      stateProvider.habitDuration = Duration(hours: 0, minutes: 20);
    }
  }

  int amount = 0;
  int duration = 0;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    final selectedBg = cp.text;
    final selectedTextColor = cp.bg;

    return Column(
      spacing: 10,
      children: [
        Container(
          height: 46,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: cp.field,
            borderRadius: BorderRadius.circular(100),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  AnimatedAlign(
                    duration: alignDuration,
                    curve: Curves.easeOutCubic,
                    alignment: _getIndicatorAlignment(),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      opacity: selectedType == HabitType.none ? 0 : 1,
                      child: Container(
                        width: constraints.maxWidth / 2,
                        decoration: BoxDecoration(
                          color: selectedBg,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _TypeButton(
                          label: 'Amount',
                          type: HabitType.amount,
                          selected: selectedType,
                          selectedTextColor: selectedTextColor,
                          unselectedTextColor: cp.lightGreyText,
                          onTap: onTapAmount,
                        ),
                      ),
                      Expanded(
                        child: _TypeButton(
                          label: 'Duration',
                          type: HabitType.duration,
                          selected: selectedType,
                          selectedTextColor: selectedTextColor,
                          unselectedTextColor: cp.lightGreyText,

                          onTap: onTapDuration,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              if (!useSlideTransition) {
                return FadeTransition(opacity: animation, child: child);
              }

              return SlideTransition(
                position: Tween<Offset>(
                  begin: slideBeginOffset,
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child:
                selectedType == HabitType.duration
                    ? EnterHabitDuration()
                    : selectedType == HabitType.amount
                    ? EnterHabitAmount()
                    : SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.type,
    required this.selected,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.onTap,
  });

  final String label;
  final HabitType type;
  final HabitType selected;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool selected = this.selected == type;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            color: selected ? selectedTextColor : unselectedTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

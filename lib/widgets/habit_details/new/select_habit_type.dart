import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/get_duration_string.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:habitt/widgets/habit_widget/progress_inputs/amount_progress_input.dart';
import 'package:habitt/widgets/habit_widget/progress_inputs/duration_progress_input.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

enum HabitType { none, amount, duration }

class SelectHabitType extends StatefulWidget {
  const SelectHabitType({super.key});

  @override
  State<SelectHabitType> createState() => _SelectHabitTypeState();
}

class _SelectHabitTypeState extends State<SelectHabitType> {
  HabitType selectedType = HabitType.none;
  HabitType lastSelectedType = HabitType.amount;

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

  // We use this function to edit duration without resetting it
  void longPressDuration() {
    final stateProvider = context.read<StateProvider>();

    setState(() {
      selectedType =
          HabitType.duration; // Setting the selected type to duration
      lastSelectedType = HabitType.duration;
    });

    // Resetting the amount just in case
    stateProvider.habitAmount = 0;

    if (stateProvider.habitDuration.inMinutes == 0) {
      // If the duration hasn't been selected before, we set it to 20 minutes as default
      stateProvider.habitDuration = Duration(hours: 0, minutes: 20);
    }
  }

  // We use this function to edit amount without resetting it
  void longPressAmount() {
    final stateProvider = context.read<StateProvider>();

    setState(() {
      selectedType = HabitType.amount; // Setting the selected type to amount
      lastSelectedType = HabitType.amount;
    });

    // Resetting duration to zero just in case
    stateProvider.habitDuration = Duration.zero;

    if (stateProvider.habitAmount == 0) {
      // If amount hasn't been set, we default it to 2
      stateProvider.habitAmount = 2;
    }
  }

  // This toggles the amount type on tap, and navigates if selected
  void onTapAmount() {
    debugPrint("Tapped amount");

    final stateProvider = context.read<StateProvider>();

    setState(() {
      // Toggles the selected type between amount and none
      selectedType =
          selectedType == HabitType.amount ? HabitType.none : HabitType.amount;

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
    final stateProvider = context.read<StateProvider>();

    setState(() {
      // Toggles the selected type between duration and none
      selectedType =
          selectedType == HabitType.duration
              ? HabitType.none
              : HabitType.duration;

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
    final sp = context.watch<StateProvider>();

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
                    duration: const Duration(milliseconds: 220),
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
                          onLongPress: longPressAmount,
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
                          onLongPress: longPressDuration,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        if (selectedType == HabitType.duration)
          _enterDuration(cp, context, sp)
        else if (selectedType == HabitType.amount)
          _enterAmount(sp, cp),
      ],
    );
  }

  Widget _enterDuration(
    ColorProvider cp,
    BuildContext context,
    StateProvider sp,
  ) {
    final duration = sp.habitDuration.inMinutes;

    return GestureDetector(
      onTap:
          () => showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            barrierColor: cp.greyText.darken().withOpacity(0.3),
            isScrollControlled: true,
            builder: (context) {
              return NewDefaultDialog(
                title: "Set duration",
                desc: "How long will this habit take?",
                child: DurationProgressInput(
                  duration: sp.habitDuration.inMinutes,
                  durationCompleted: 0,
                ),
              );
            },
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Time',
            style: TextStyle(
              color: cp.lightGreyText,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: ShapeDecoration(
              color: cp.field,
              shape: StadiumBorder(),
            ),
            child: Row(
              spacing: 16,
              children: [
                Text(
                  getDurationString(duration),
                  style: TextStyle(color: cp.text, fontWeight: FontWeight.w500),
                ),
                SvgPicture.asset("assets/images/new-svg/clock.svg"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Row _enterAmount(StateProvider sp, ColorProvider cp) {
    return Row(
      spacing: 10,
      children: [
        Expanded(child: AmountProgressInput(amount: sp.habitAmount)),
        Expanded(
          child: NewDefaultTextField(
            controller: TextEditingController(),
            title: "Amount name",
            fontWeight: FontWeight.w500,
            hint: "Amount name",
            suffix: GestureDetector(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: SvgPicture.asset(
                  "assets/images/new-svg/dropdown.svg",
                  colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
                ),
              ),
            ),
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
    required this.onLongPress,
  });

  final String label;
  final HabitType type;
  final HabitType selected;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final bool selected = this.selected == type;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
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

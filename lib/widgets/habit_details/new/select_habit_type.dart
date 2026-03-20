import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/util/get_duration_string.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:habitt/widgets/habit_widget/progress_inputs/amount_progress_input.dart';
import 'package:habitt/widgets/habit_widget/progress_inputs/duration_progress_input.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

enum NewHabitType { amount, duration }

class SelectHabitType extends StatelessWidget {
  const SelectHabitType({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StateProvider>();

    final selectedType =
        sp.habitDuration.inMinutes > 0
            ? NewHabitType.duration
            : NewHabitType.amount;
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
              final bool isAmountSelected = selectedType == NewHabitType.amount;

              return Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment:
                        isAmountSelected
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                    child: Container(
                      width: constraints.maxWidth / 2,
                      decoration: BoxDecoration(
                        color: selectedBg,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _TypeButton(
                          label: 'Amount',
                          selected: isAmountSelected,
                          selectedTextColor: selectedTextColor,
                          unselectedTextColor: cp.lightGreyText,
                          onTap: () {
                            sp.habitDuration = Duration.zero;
                            if (sp.habitAmount <= 0) {
                              sp.habitAmount = 2;
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: _TypeButton(
                          label: 'Duration',
                          selected: !isAmountSelected,
                          selectedTextColor: selectedTextColor,
                          unselectedTextColor: cp.lightGreyText,
                          onTap: () {
                            sp.habitAmount = 0;
                            if (sp.habitDuration.inMinutes <= 0) {
                              sp.habitDuration = const Duration(minutes: 20);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        if (selectedType == NewHabitType.duration)
          _enterDuration(cp, context, sp)
        else
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
        Expanded(
          child: AmountProgressInput(
            amount: sp.habitAmount,
            amountCompleted: 0,
          ),
        ),
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
    required this.selected,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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

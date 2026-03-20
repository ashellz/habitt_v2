import 'package:flutter/material.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:provider/provider.dart';

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
    final selectedBg = cp.pill;
    final selectedTextColor = cp.bg;

    return Container(
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

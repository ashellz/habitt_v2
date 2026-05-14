import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/habit_details/new/editable/select_habit_type_widgets.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class SelectHabitType extends StatefulWidget {
  const SelectHabitType({
    super.key,
    required this.selectedType,
    required this.lastSelectedType,
    required this.onTapAmount,
    required this.onTapDuration,
    required this.alignDuration,
  });

  final HabitType selectedType;
  final HabitType lastSelectedType;
  final VoidCallback onTapAmount;
  final VoidCallback onTapDuration;
  final Duration alignDuration;

  @override
  State<SelectHabitType> createState() => _SelectHabitTypeState();
}

class _SelectHabitTypeState extends State<SelectHabitType> {
  Alignment _getIndicatorAlignment() {
    if (widget.selectedType == HabitType.amount) {
      return Alignment.centerLeft;
    }

    if (widget.selectedType == HabitType.duration) {
      return Alignment.centerRight;
    }

    return widget.lastSelectedType == HabitType.duration
        ? Alignment.centerRight
        : Alignment.centerLeft;
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Container(
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
                duration: widget.alignDuration,
                curve: Curves.easeOutCubic,
                alignment: _getIndicatorAlignment(),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  opacity: widget.selectedType == HabitType.none ? 0 : 1,
                  child: Container(
                    width: constraints.maxWidth / 2,
                    decoration: BoxDecoration(
                      color: cp.text,
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
                      selected: widget.selectedType,
                      onTap: widget.onTapAmount,
                    ),
                  ),
                  Expanded(
                    child: _TypeButton(
                      label: 'Duration',
                      type: HabitType.duration,
                      selected: widget.selectedType,
                      onTap: widget.onTapDuration,
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
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final HabitType type;
  final HabitType selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool selected = this.selected == type;
    final cp = context.watch<ColorProvider>();
    final selectedTextColor = cp.bg;
    final unselectedTextColor = cp.lightGreyText;

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
            fontFamily: AppLocalizations.of(context)!.satoshi,
            fontWeight: FontWeight.w500,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/get_duration_string.dart';
import 'package:provider/provider.dart';

enum HabitType { none, amount, duration }

class SelectHabitTypeWidget extends StatelessWidget {
  const SelectHabitTypeWidget({
    super.key,
    this.onTap,
    required this.type,
    required this.selectedType,
  });

  final HabitType type;
  final HabitType selectedType;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final ColorProvider colorProvider = context.watch<ColorProvider>();
    final colorScheme = colorProvider.colorScheme;
    final bool isSelected = type == selectedType;
    final double screenWidth = MediaQuery.of(context).size.width - 40;

    final stateProvider = context.watch<StateProvider>();
    final String habitAmount = stateProvider.habitAmount.toString();
    final String habitDuration = getDurationString(
      stateProvider.habitDuration.inMinutes,
    );

    return GestureDetector(
      // Used for selecting the widget
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(right: type == HabitType.amount ? 8 : 0),
        child: AnimatedContainer(
          width:
              // Only works when in a row with one more of this widget
              selectedType == HabitType.none
                  ? screenWidth / 2
                  : isSelected
                  ? screenWidth / 1.75
                  : screenWidth / 2.35,
          duration: const Duration(milliseconds: 150),
          curve: Curves.decelerate,
          decoration: BoxDecoration(
            color:
                isSelected
                    ? colorProvider.standardColor
                    : colorProvider.disabledColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected
                      ? colorScheme.strokeColor
                      : colorScheme.disabledColor,
              width: 2,
            ),
          ),
          padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
          height: 56,
          child: Row(
            children: [
              // Expanded used for alignment
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.decelerate,
                      alignment:
                          isSelected ? Alignment.centerLeft : Alignment.center,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: isSelected ? 1.0 : 0.5,
                        child: FittedBox(
                          child: Text(
                            type == HabitType.amount
                                ? localizations.amount
                                : localizations.duration,
                            style: TextStyle(
                              color: colorProvider.textColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.decelerate,
                      child:
                          isSelected
                              ? Text(
                                "${localizations.selected}: ${type == HabitType.amount ? habitAmount : habitDuration}",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colorProvider.mutedTextColor,
                                ),
                              )
                              : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                width: isSelected ? 40 : 0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.decelerate,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: isSelected ? 1.0 : 0,
                  curve: Curves.decelerate,
                  child: Image.asset(
                    type == HabitType.amount
                        ? "assets/images/icons/counter.png"
                        : "assets/images/icons/duration.png",
                    width: 40,
                    height: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

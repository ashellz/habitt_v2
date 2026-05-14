import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/util/get_duration_string.dart';
import 'package:provider/provider.dart';

enum OldHabitType { none, amount, duration }

class SelectHabitTypeWidget extends StatelessWidget {
  const SelectHabitTypeWidget({
    super.key,
    this.onTap,
    this.onLongPress,
    required this.type,
    required this.selectedType,
  });

  final OldHabitType type;
  final OldHabitType selectedType;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final tp = context.watch<ThemeProvider>();
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
      onLongPress: onLongPress,
      child: Padding(
        padding: EdgeInsets.only(right: type == OldHabitType.amount ? 8 : 0),
        child: AnimatedContainer(
          width:
              // Only works when in a row with one more of this widget
              selectedType == OldHabitType.none
                  ? screenWidth / 2
                  : isSelected
                  ? screenWidth / 1.75
                  : screenWidth / 2.35,
          duration: const Duration(milliseconds: 150),
          curve: Curves.decelerate,
          decoration: BoxDecoration(
            color: tp.surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? tp.secondaryButtonBorder : tp.borderColor,
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
                            type == OldHabitType.amount
                                ? loc.amount
                                : loc.duration,
                            style: TextStyle(
                              color: tp.primaryTextColor,
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
                                "${loc.selected}: ${type == OldHabitType.amount ? habitAmount : habitDuration}",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: tp.primaryTextColor,
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
                    type == OldHabitType.amount
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

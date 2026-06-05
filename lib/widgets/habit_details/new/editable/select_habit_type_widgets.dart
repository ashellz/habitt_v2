import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/habit_details/new/editable/enter_habit_amount.dart';
import 'package:habitt/widgets/habit_details/new/editable/enter_habit_duration.dart';
import 'package:habitt/widgets/habit_details/new/editable/select_habit_type.dart';
import 'package:provider/provider.dart';

enum HabitType { none, amount, duration }

class SelectHabitTypeWidgets extends StatefulWidget {
  const SelectHabitTypeWidgets({super.key});

  @override
  State<SelectHabitTypeWidgets> createState() => _SelectHabitTypeWidgetsState();
}

class _SelectHabitTypeWidgetsState extends State<SelectHabitTypeWidgets> {
  HabitType selectedType = HabitType.none;
  HabitType lastSelectedType = HabitType.amount;
  bool useSlideTransition = false;
  bool useDelayedEntryOpacity = false;
  double entryOpacity = 1;
  int _entryOpacityTicket = 0;
  Offset slideBeginOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sp = context.read<StateProvider>();
      final trackingType = sp.selectedHabitTrackingType;

      setState(() {
        selectedType =
            trackingType == HabitTrackingType.amount
                ? HabitType.amount
                : trackingType == HabitTrackingType.duration
                ? HabitType.duration
                : HabitType.none;
        lastSelectedType =
            selectedType == HabitType.none ? lastSelectedType : selectedType;
      });
    });
  }

  // Align duration usage:
  // We tweak it so if you enable amount from none but it was previously duration
  // It would slide fade the indicator to left from right
  // Looks unpurposeful so we disable duration for that moment
  Duration alignDuration = Duration(milliseconds: 250);

  void _setTransitionState(HabitType nextType) {
    final previousType = selectedType;

    final shouldSlide =
        previousType != HabitType.none &&
        nextType != HabitType.none &&
        previousType != nextType;

    useSlideTransition = shouldSlide;
    slideBeginOffset =
        nextType == HabitType.amount ? const Offset(-1, 0) : const Offset(1, 0);

    _setEntryOpacityState(previousType, nextType);
  }

  void _setEntryOpacityState(HabitType previousType, HabitType nextType) {
    final shouldUseDelayedOpacity =
        previousType == HabitType.none && nextType != HabitType.none;

    useDelayedEntryOpacity = shouldUseDelayedOpacity;

    if (!shouldUseDelayedOpacity) {
      entryOpacity = 1;
      _entryOpacityTicket++;
      return;
    }

    entryOpacity = 0;
    final ticket = ++_entryOpacityTicket;

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted || ticket != _entryOpacityTicket) {
        return;
      }

      if (selectedType == HabitType.none) {
        return;
      }

      setState(() {
        entryOpacity = 1;
      });
    });
  }

  // This toggles the amount type on tap, and navigates if selected
  void onTapAmount() {
    debugPrint("Tapped amount");

    setState(() {
      alignDuration = Duration(milliseconds: 250);
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
      stateProvider.selectedHabitTrackingType = null;
      // If deselected, clear amount
      Future.delayed(const Duration(milliseconds: 100), () {
        stateProvider.habitAmount = 0;
      });
    } else if (selectedType == HabitType.amount) {
      stateProvider.selectedHabitTrackingType = HabitTrackingType.amount;
      // If selected, we reset duration and set default amount
      setState(() {
        stateProvider.habitAmount =
            stateProvider.habitAmount < 1 ? 1 : stateProvider.habitAmount;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        stateProvider.habitDuration = Duration.zero;
      });

      debugPrint("Selected type: $selectedType");
    }
  }

  // This toggles the duration type on tap
  void onTapDuration() {
    debugPrint("Tapped duration");
    setState(() {
      alignDuration = Duration(milliseconds: 250);
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
      stateProvider.selectedHabitTrackingType = null;
      // If deselected, clear duration
      Future.delayed(const Duration(milliseconds: 100), () {
        stateProvider.habitDuration = Duration.zero;
      });
    } else if (selectedType == HabitType.duration) {
      stateProvider.selectedHabitTrackingType = HabitTrackingType.duration;
      setState(() {
        stateProvider.habitDuration =
            stateProvider.habitDuration == Duration.zero
                ? Duration(hours: 0, minutes: 20)
                : stateProvider.habitDuration;
      });
      // If selected, reset amount and set default duration
      Future.delayed(const Duration(milliseconds: 100), () {
        stateProvider.habitAmount = 0;
      });
    }
  }

  int amount = 0;
  int duration = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        SelectHabitType(
          selectedType: selectedType,
          lastSelectedType: lastSelectedType,
          onTapAmount: onTapAmount,
          onTapDuration: onTapDuration,
          alignDuration: alignDuration,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
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
            child: () {
              final Widget content =
                  selectedType == HabitType.duration
                      ? EnterHabitDuration()
                      : selectedType == HabitType.amount
                      ? EnterHabitAmount()
                      : const SizedBox.shrink();

              if (selectedType == HabitType.none || !useDelayedEntryOpacity) {
                return content;
              }

              return AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeIn,
                opacity: entryOpacity,
                child: content,
              );
            }(),
          ),
        ),
      ],
    );
  }
}

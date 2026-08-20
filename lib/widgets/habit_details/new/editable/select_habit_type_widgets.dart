import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/dual_option_selector.dart';
import 'package:habitt/widgets/habit_details/new/editable/enter_habit_amount.dart';
import 'package:habitt/widgets/habit_details/new/editable/enter_habit_duration.dart';
import 'package:provider/provider.dart';

enum HabitType { none, amount, duration }

class SelectHabitTypeWidgets extends StatefulWidget {
  const SelectHabitTypeWidgets({super.key});

  @override
  State<SelectHabitTypeWidgets> createState() => _SelectHabitTypeWidgetsState();
}

class _SelectHabitTypeWidgetsState extends State<SelectHabitTypeWidgets> {
  HabitType selectedType = HabitType.none;
  bool useSlideTransition = false;
  bool useDelayedEntryOpacity = false;
  double entryOpacity = 1;
  int _entryOpacityTicket = 0;
  Offset slideBeginOffset = Offset.zero;
  StateProvider? _stateProvider;
  VoidCallback? _stateProviderListener;

  @override
  void initState() {
    super.initState();
    final sp = context.read<StateProvider>();
    _stateProvider = sp;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final trackingType = sp.selectedHabitTrackingType;

      setState(() {
        selectedType =
            trackingType == HabitTrackingType.amount
                ? HabitType.amount
                : trackingType == HabitTrackingType.duration
                ? HabitType.duration
                : HabitType.none;
      });
    });

    // Tracking type can also change from outside this widget (e.g. linking
    // the habit to a Health metric elsewhere in the sheet) — stay in sync.
    _stateProviderListener = () {
      if (!mounted) return;
      final externalTrackingType = sp.selectedHabitTrackingType;
      final mappedType =
          externalTrackingType == HabitTrackingType.amount
              ? HabitType.amount
              : externalTrackingType == HabitTrackingType.duration
              ? HabitType.duration
              : HabitType.none;
      if (mappedType == selectedType) return;

      setState(() {
        useSlideTransition = false;
        _setEntryOpacityState(selectedType, mappedType);
        selectedType = mappedType;
      });
    };
    sp.addListener(_stateProviderListener!);
  }

  @override
  void dispose() {
    if (_stateProviderListener != null) {
      _stateProvider?.removeListener(_stateProviderListener!);
    }
    super.dispose();
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
      if (!mounted || ticket != _entryOpacityTicket) return;
      if (selectedType == HabitType.none) return;

      setState(() {
        entryOpacity = 1;
      });
    });
  }

  void _onSelect(HabitType? nextTypeRaw) {
    final nextType = nextTypeRaw ?? HabitType.none;
    final previousType = selectedType;

    final shouldSlide =
        previousType != HabitType.none &&
        nextType != HabitType.none &&
        previousType != nextType;

    final stateProvider = context.read<StateProvider>();

    setState(() {
      useSlideTransition = shouldSlide;
      slideBeginOffset =
          nextType == HabitType.amount
              ? const Offset(-1, 0)
              : const Offset(1, 0);
      _setEntryOpacityState(previousType, nextType);
      selectedType = nextType;
    });

    if (nextType == HabitType.none) {
      stateProvider.selectedHabitTrackingType = null;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (previousType == HabitType.amount) {
          stateProvider.habitAmount = 0;
        } else {
          stateProvider.habitDuration = Duration.zero;
        }
      });
    } else if (nextType == HabitType.amount) {
      stateProvider.selectedHabitTrackingType = HabitTrackingType.amount;
      setState(() {
        stateProvider.habitAmount =
            stateProvider.habitAmount < 1 ? 1 : stateProvider.habitAmount;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        stateProvider.habitDuration = Duration.zero;
      });
    } else if (nextType == HabitType.duration) {
      stateProvider.selectedHabitTrackingType = HabitTrackingType.duration;
      setState(() {
        stateProvider.habitDuration =
            stateProvider.habitDuration == Duration.zero
                ? const Duration(hours: 0, minutes: 20)
                : stateProvider.habitDuration;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        stateProvider.habitAmount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final selectedValue = selectedType == HabitType.none ? null : selectedType;

    return Column(
      spacing: 10,
      children: [
        DualOptionSelector<HabitType>(
          firstLabel: loc.amount,
          firstValue: HabitType.amount,
          secondLabel: loc.duration,
          secondValue: HabitType.duration,
          selectedValue: selectedValue,
          onSelect: _onSelect,
          allowDeselect: true,
          showDeselectHint: true,
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

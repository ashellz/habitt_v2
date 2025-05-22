import 'package:flutter/material.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/select_habit_type_widget.dart';
import 'package:habitt/pages/other_pages/enter_amount_page.dart';
import 'package:provider/provider.dart';

class SelectHabitTypeOptions extends StatefulWidget {
  const SelectHabitTypeOptions({super.key});

  @override
  State<SelectHabitTypeOptions> createState() => _SelectHabitTypeOptionsState();
}

class _SelectHabitTypeOptionsState extends State<SelectHabitTypeOptions> {
  HabitType selectedType = HabitType.none;

  void longPressDuration() {
    final stateProvider = context.read<StateProvider>();
    final previousType = selectedType;

    setState(() {
      selectedType = HabitType.duration;
    });

    if (selectedType == HabitType.duration) {
      stateProvider.habitAmount = 0;
      if (stateProvider.habitDuration.inMinutes == 0) {
        stateProvider.habitDuration = Duration(hours: 0, minutes: 20);
      }

      if (previousType == HabitType.amount) {
        Future.delayed(Duration(milliseconds: 150)).then((value) {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EnterAmountPage(type: selectedType),
              ),
            );
          }
        });
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => EnterAmountPage(
                  type: selectedType,
                  durationValue: stateProvider.habitDuration,
                ),
          ),
        );
      }
    }
  }

  void longPressAmount() {
    final stateProvider = context.read<StateProvider>();
    final previousType = selectedType;

    setState(() {
      selectedType = HabitType.amount;
    });

    if (selectedType == HabitType.amount) {
      stateProvider.habitDuration = Duration.zero;
      if (stateProvider.habitAmount == 0) {
        stateProvider.habitAmount = 2;
      }

      if (previousType == HabitType.duration) {
        Future.delayed(Duration(milliseconds: 150)).then((value) {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EnterAmountPage(type: selectedType),
              ),
            );
          }
        });
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => EnterAmountPage(
                  type: selectedType,
                  wheelValue: stateProvider.habitAmount,
                ),
          ),
        );
      }
    }
  }

  void onTapAmount() {
    final stateProvider = context.read<StateProvider>();
    setState(() {
      selectedType =
          selectedType == HabitType.amount ? HabitType.none : HabitType.amount;
    });

    if (selectedType == HabitType.none) {
      stateProvider.habitAmount = 0;
    } else if (selectedType == HabitType.amount) {
      stateProvider.habitDuration = Duration.zero;
      stateProvider.habitAmount = 2;

      Future.delayed(Duration(milliseconds: 150)).then((value) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EnterAmountPage(type: selectedType),
            ),
          );
        }
      });
    }
  }

  void onTapDuration() {
    final stateProvider = context.read<StateProvider>();
    setState(() {
      selectedType =
          selectedType == HabitType.duration
              ? HabitType.none
              : HabitType.duration;
    });

    if (selectedType == HabitType.none) {
      stateProvider.habitDuration = Duration.zero;
    } else if (selectedType == HabitType.duration) {
      stateProvider.habitAmount = 0;
      stateProvider.habitDuration = Duration(hours: 0, minutes: 20);

      Future.delayed(Duration(milliseconds: 150)).then((value) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EnterAmountPage(type: selectedType),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateProvider = context.watch<StateProvider>();
    final amount = stateProvider.habitAmount;
    final duration = stateProvider.habitDuration.inMinutes;

    if (amount > 0) {
      selectedType = HabitType.amount;
    } else if (duration > 0) {
      selectedType = HabitType.duration;
    }

    return Padding(
      padding: EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            SelectHabitTypeWidget(
              type: HabitType.amount,
              selectedType: selectedType,
              onLongPress: longPressAmount,
              onTap: onTapAmount,
            ),

            SelectHabitTypeWidget(
              type: HabitType.duration,
              selectedType: selectedType,
              onLongPress: longPressDuration,
              onTap: onTapDuration,
            ),
          ],
        ),
      ),
    );
  }
}

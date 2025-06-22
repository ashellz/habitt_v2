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
  // We use this function to edit duration without resetting it
  void longPressDuration() {
    final stateProvider = context.read<StateProvider>();
    final previousType =
        selectedType; // Temporarily saving the previous habit type

    setState(() {
      selectedType =
          HabitType.duration; // Setting the selected type to duration
    });

    // Resetting the amount just in case
    stateProvider.habitAmount = 0;

    if (stateProvider.habitDuration.inMinutes == 0) {
      // If the duration hasn't been selected before, we set it to 20 minutes as default
      stateProvider.habitDuration = Duration(hours: 0, minutes: 20);
    }

    if (previousType == HabitType.amount) {
      // If the previous type was amount, we delay the navigation slightly for smoother UI
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
      // If the previous type was not amount, we navigate directly
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

  // We use this function to edit amount without resetting it
  void longPressAmount() {
    final stateProvider = context.read<StateProvider>();
    final previousType =
        selectedType; // Temporarily saving the previous habit type

    setState(() {
      selectedType = HabitType.amount; // Setting the selected type to amount
    });

    // Resetting duration to zero just in case
    stateProvider.habitDuration = Duration.zero;

    if (stateProvider.habitAmount == 0) {
      // If amount hasn't been set, we default it to 2
      stateProvider.habitAmount = 2;
    }

    if (previousType == HabitType.duration) {
      // If switching from duration, we delay navigation
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
      // Otherwise navigating immediately
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

  // This toggles the amount type on tap, and navigates if selected
  void onTapAmount() {
    final stateProvider = context.read<StateProvider>();

    setState(() {
      // Toggles the selected type between amount and none
      selectedType =
          selectedType == HabitType.amount ? HabitType.none : HabitType.amount;
    });

    if (selectedType == HabitType.none) {
      // If deselected, clear amount
      stateProvider.habitAmount = 0;
    } else if (selectedType == HabitType.amount) {
      // If selected, we reset duration and set default amount
      stateProvider.habitDuration = Duration.zero;
      stateProvider.habitAmount = 2;

      // Navigates to input page after short delay
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

  // This toggles the duration type on tap, and navigates if selected
  void onTapDuration() {
    final stateProvider = context.read<StateProvider>();

    setState(() {
      // Toggles the selected type between duration and none
      selectedType =
          selectedType == HabitType.duration
              ? HabitType.none
              : HabitType.duration;
    });

    if (selectedType == HabitType.none) {
      // If deselected, clear duration
      stateProvider.habitDuration = Duration.zero;
    } else if (selectedType == HabitType.duration) {
      // If selected, reset amount and set default duration
      stateProvider.habitAmount = 0;
      stateProvider.habitDuration = Duration(hours: 0, minutes: 20);

      // Navigates to input page after short delay
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

  int amount = 0;
  int duration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stateProvider = context.read<StateProvider>();
      amount = stateProvider.habitAmount;
      duration = stateProvider.habitDuration.inMinutes;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (amount > 1) {
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

import 'package:flutter/material.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/habit_details/select_habit_type_widget.dart';
import 'package:habitt/pages/other_pages/enter_amount_page.dart';
import 'package:provider/provider.dart';

class SelectHabitTypeOptions extends StatefulWidget {
  const SelectHabitTypeOptions({super.key});

  @override
  State<SelectHabitTypeOptions> createState() => _SelectHabitTypeOptionsState();
}

class _SelectHabitTypeOptionsState extends State<SelectHabitTypeOptions> {
  OldHabitType selectedType = OldHabitType.none;
  // We use this function to edit duration without resetting it
  void longPressDuration() {
    final stateProvider = context.read<StateProvider>();
    final previousType =
        selectedType; // Temporarily saving the previous habit type

    setState(() {
      selectedType =
          OldHabitType.duration; // Setting the selected type to duration
    });

    // Resetting the amount just in case
    stateProvider.habitAmount = 0;

    if (stateProvider.habitDuration.inMinutes == 0) {
      // If the duration hasn't been selected before, we set it to 20 minutes as default
      stateProvider.habitDuration = Duration(hours: 0, minutes: 20);
    }

    if (previousType == OldHabitType.amount) {
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
      selectedType = OldHabitType.amount; // Setting the selected type to amount
    });

    // Resetting duration to zero just in case
    stateProvider.habitDuration = Duration.zero;

    if (stateProvider.habitAmount == 0) {
      // If amount hasn't been set, we default it to 2
      stateProvider.habitAmount = 2;
    }

    if (previousType == OldHabitType.duration) {
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
    debugPrint("Tapped amount");

    final stateProvider = context.read<StateProvider>();

    setState(() {
      // Toggles the selected type between amount and none
      selectedType =
          selectedType == OldHabitType.amount
              ? OldHabitType.none
              : OldHabitType.amount;
    });

    if (selectedType == OldHabitType.none) {
      // If deselected, clear amount
      stateProvider.habitAmount = 0;
    } else if (selectedType == OldHabitType.amount) {
      // If selected, we reset duration and set default amount
      stateProvider.habitDuration = Duration.zero;
      stateProvider.habitAmount = 2;

      debugPrint("Selected type: $selectedType");

      // Navigates to input page after short delay
      Future.delayed(Duration(milliseconds: 150)).then((value) {
        if (mounted) {
          debugPrint("Selected type right before navigation: $selectedType");
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
    debugPrint("Tapped duration");
    final stateProvider = context.read<StateProvider>();

    setState(() {
      // Toggles the selected type between duration and none
      selectedType =
          selectedType == OldHabitType.duration
              ? OldHabitType.none
              : OldHabitType.duration;
    });

    if (selectedType == OldHabitType.none) {
      // If deselected, clear duration
      stateProvider.habitDuration = Duration.zero;
    } else if (selectedType == OldHabitType.duration) {
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

      setState(() {
        if (amount > 1) {
          selectedType = OldHabitType.amount;
        } else if (duration > 0) {
          selectedType = OldHabitType.duration;
        } else {
          selectedType = OldHabitType.none;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final stateProvider = context.read<StateProvider>();
    if (selectedType == OldHabitType.duration &&
        stateProvider.habitDuration == Duration.zero) {
      selectedType = OldHabitType.none;
    }

    return Padding(
      padding: EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            SelectHabitTypeWidget(
              type: OldHabitType.amount,
              selectedType: selectedType,
              onLongPress: longPressAmount,
              onTap: onTapAmount,
            ),

            SelectHabitTypeWidget(
              type: OldHabitType.duration,
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

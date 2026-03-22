import 'package:flutter/material.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/number_picker.dart';
import 'package:provider/provider.dart';

class DurationProgressInput extends StatefulWidget {
  const DurationProgressInput({
    super.key,
    required this.duration,
    this.durationCompleted,
  });

  final int duration;
  final int? durationCompleted;

  @override
  State<DurationProgressInput> createState() => _DurationProgressInputState();
}

class _DurationProgressInputState extends State<DurationProgressInput> {
  late FixedExtentScrollController hoursController =
      FixedExtentScrollController();
  late FixedExtentScrollController minutesController =
      FixedExtentScrollController();

  @override
  void initState() {
    super.initState();

    final initialDuration = widget.durationCompleted ?? widget.duration;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Sets the initial amount or duration
      final stateProvider = context.read<StateProvider>();
      stateProvider.habitDuration = Duration(
        hours: initialDuration ~/ 60,
        minutes: initialDuration % 60,
      );
    });

    hoursController = FixedExtentScrollController(
      initialItem: initialDuration ~/ 60,
    );
    minutesController = FixedExtentScrollController(
      initialItem: initialDuration % 60,
    );
  }

  @override
  void dispose() {
    hoursController.dispose();
    minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final sp = context.watch<StateProvider>();

    return NumberPicker(
      height: 211,
      hoursController: hoursController,
      minutesController: minutesController,
      width: width,
      padZero: false,
      onChangedHours:
          (value) =>
              sp.habitDuration = Duration(
                hours: value,
                minutes: sp.habitDuration.inMinutes % 60,
              ),

      onChangedMinutes:
          (value) =>
              sp.habitDuration = Duration(
                hours: sp.habitDuration.inMinutes ~/ 60,
                minutes: value,
              ),
    );
  }
}

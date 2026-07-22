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

  /// Target duration in seconds.
  final int duration;

  /// Progress in seconds, if any.
  final int? durationCompleted;

  @override
  State<DurationProgressInput> createState() => _DurationProgressInputState();
}

class _DurationProgressInputState extends State<DurationProgressInput> {
  late FixedExtentScrollController hoursController =
      FixedExtentScrollController();
  late FixedExtentScrollController minutesController =
      FixedExtentScrollController();
  late FixedExtentScrollController secondsController =
      FixedExtentScrollController();

  @override
  void initState() {
    super.initState();

    // Duration fields are stored in seconds.
    final initialSeconds = widget.durationCompleted ?? widget.duration;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Sets the initial duration for the state provider.
      final stateProvider = context.read<StateProvider>();
      stateProvider.habitDuration = Duration(seconds: initialSeconds);
    });

    hoursController = FixedExtentScrollController(
      initialItem: initialSeconds ~/ 3600,
    );
    minutesController = FixedExtentScrollController(
      initialItem: (initialSeconds % 3600) ~/ 60,
    );
    secondsController = FixedExtentScrollController(
      initialItem: initialSeconds % 60,
    );
  }

  @override
  void dispose() {
    hoursController.dispose();
    minutesController.dispose();
    secondsController.dispose();
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
      secondsController: secondsController,
      width: width,
      padZero: false,
      onChangedHours: (value) {
        final d = sp.habitDuration;
        sp.habitDuration = Duration(
          hours: value,
          minutes: d.inMinutes % 60,
          seconds: d.inSeconds % 60,
        );
      },
      onChangedMinutes: (value) {
        final d = sp.habitDuration;
        sp.habitDuration = Duration(
          hours: d.inHours,
          minutes: value,
          seconds: d.inSeconds % 60,
        );
      },
      onChangedSeconds: (value) {
        final d = sp.habitDuration;
        sp.habitDuration = Duration(
          hours: d.inHours,
          minutes: d.inMinutes % 60,
          seconds: value,
        );
      },
    );
  }
}

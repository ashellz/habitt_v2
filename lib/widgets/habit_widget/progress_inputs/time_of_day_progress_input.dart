import 'package:flutter/material.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/number_picker.dart';
import 'package:provider/provider.dart';

/// Clock-time wheel for logging a bedtime or wake time by hand. Writes the
/// picked time into [StateProvider.habitAmount] as minutes since midnight, with
/// bedtimes before noon pushed past 1440 like Health-synced ones.
class TimeOfDayProgressInput extends StatefulWidget {
  const TimeOfDayProgressInput({
    super.key,
    required this.initialMinutes,
    required this.isBedtime,
  });

  /// Time to start the wheel on, in minutes since midnight (may exceed 1440).
  final int initialMinutes;
  final bool isBedtime;

  @override
  State<TimeOfDayProgressInput> createState() => _TimeOfDayProgressInputState();
}

class _TimeOfDayProgressInputState extends State<TimeOfDayProgressInput> {
  late final FixedExtentScrollController hoursController;
  late final FixedExtentScrollController minutesController;
  late int hour;
  late int minute;

  @override
  void initState() {
    super.initState();
    final normalized = widget.initialMinutes % (24 * 60);
    hour = normalized ~/ 60;
    minute = normalized % 60;
    hoursController = FixedExtentScrollController(initialItem: hour);
    minutesController = FixedExtentScrollController(initialItem: minute);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _publish();
    });
  }

  @override
  void dispose() {
    hoursController.dispose();
    minutesController.dispose();
    super.dispose();
  }

  void _publish() {
    final minutes = hour * 60 + minute;
    context.read<StateProvider>().habitAmount =
        widget.isBedtime && minutes < 12 * 60 ? minutes + 24 * 60 : minutes;
  }

  @override
  Widget build(BuildContext context) {
    return NumberPicker(
      hoursController: hoursController,
      minutesController: minutesController,
      width: MediaQuery.of(context).size.width,
      onChangedHours: (value) {
        hour = value;
        _publish();
      },
      onChangedMinutes: (value) {
        minute = value;
        _publish();
      },
    );
  }
}

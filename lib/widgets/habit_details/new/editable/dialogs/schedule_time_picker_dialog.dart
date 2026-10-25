import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/number_picker.dart';

/// Hour and minute wheel used by the day schedule flow, the same picker as
/// notification times. Pops the picked minutes of the day, or [back].
class ScheduleTimePickerDialog extends StatefulWidget {
  const ScheduleTimePickerDialog({
    super.key,
    required this.title,
    required this.initialMinutes,
  });

  /// Popped by the Back button, never a valid minutes-of-day value.
  static const int back = -1;

  final String title;
  final int initialMinutes;

  @override
  State<ScheduleTimePickerDialog> createState() =>
      _ScheduleTimePickerDialogState();
}

class _ScheduleTimePickerDialogState extends State<ScheduleTimePickerDialog> {
  late int _hour = (widget.initialMinutes ~/ 60) % 24;
  late int _minute = widget.initialMinutes % 60;
  late final FixedExtentScrollController _hoursController =
      FixedExtentScrollController(initialItem: _hour);
  late final FixedExtentScrollController _minutesController =
      FixedExtentScrollController(initialItem: _minute);

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return NewDefaultDialog(
      title: widget.title,
      primaryButtonLabel: loc.done,
      secondaryButtonLabel: loc.back,
      onSecondaryButtonPressed:
          () => Navigator.of(context).pop(ScheduleTimePickerDialog.back),
      onPrimaryButtonPressed:
          () => Navigator.of(context).pop(_hour * 60 + _minute),
      child: NumberPicker(
        hoursController: _hoursController,
        minutesController: _minutesController,
        width: MediaQuery.of(context).size.width,
        onChangedHours: (value) => _hour = value,
        onChangedMinutes: (value) => _minute = value,
      ),
    );
  }
}

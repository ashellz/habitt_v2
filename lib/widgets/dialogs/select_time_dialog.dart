import 'package:cupertino_native_better/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/circle_button.dart';
import 'package:habitt/widgets/default/glass_feel_container.dart';
import 'package:habitt/widgets/default/number_picker.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class SelectTimeDialog extends StatefulWidget {
  const SelectTimeDialog({
    super.key,
    required this.isStartTime,
    required this.stateProvider,
  });

  final bool isStartTime;
  final StateProvider stateProvider;

  @override
  State<SelectTimeDialog> createState() => _SelectTimeDialogState();
}

class _SelectTimeDialogState extends State<SelectTimeDialog> {
  FixedExtentScrollController hoursController = FixedExtentScrollController();
  FixedExtentScrollController minutesController = FixedExtentScrollController();

  // Track if this is the first time setting each value
  bool isFirstStartTimeChange = true;
  bool isFirstEndTimeChange = true;

  @override
  void initState() {
    super.initState();

    // Check if values have been changed from defaults (420 = 7:00, 450 = 7:30)
    isFirstStartTimeChange = widget.stateProvider.timeIntervalStart == 420;
    isFirstEndTimeChange = widget.stateProvider.timeIntervalEnd == 450;

    setState(() {
      hoursController = FixedExtentScrollController(
        initialItem:
            widget.isStartTime
                ? widget.stateProvider.timeIntervalStart ~/ 60
                : widget.stateProvider.timeIntervalEnd ~/ 60,
      );
      minutesController = FixedExtentScrollController(
        initialItem:
            widget.isStartTime
                ? widget.stateProvider.timeIntervalStart % 60
                : widget.stateProvider.timeIntervalEnd % 60,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StateProvider>();
    final tp = context.watch<ThemeProvider>();
    final width = MediaQuery.of(context).size.width - 200;
    final loc = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor:
          Colors.transparent, // Important for the blur to show through
      insetPadding: EdgeInsets.zero,
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: Row(
            children: [
              SizedBox(width: 8 + 50),
              GlassFeelContainer(
                width: width,
                child: Column(
                  children: [
                    Text(
                      widget.isStartTime ? loc.startTime : loc.endTime,
                      style: TextStyle(
                        color: tp.primaryTextColor,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Stack(
                      children: [
                        NumberPicker(
                          hoursController: hoursController,
                          minutesController: minutesController,
                          width: width,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Column(
                children: [
                  CircleButton(
                    cnIcon: CNSymbol('checkmark', size: 20),
                    tp: tp,
                    icon: Icon(Icons.check, color: Colors.white),
                    color: tp.primaryColor,
                    onPressed: () {
                      final hours = hoursController.selectedItem % 24;
                      final minutes = minutesController.selectedItem % 60;
                      final time = hours * 60 + minutes;

                      if (widget.isStartTime) {
                        sp.timeIntervalStart = time;
                        // Only set end time if this is the first start time change and end time hasn't been changed
                        if (isFirstStartTimeChange && isFirstEndTimeChange) {
                          isFirstStartTimeChange = false;

                          sp.timeIntervalEnd = (time + 30) % (24 * 60);
                        }
                      } else if (!widget.isStartTime) {
                        sp.timeIntervalEnd = time;
                        // Only set start time if this is the first end time change and start time hasn't been changed
                        if (isFirstEndTimeChange && isFirstStartTimeChange) {
                          isFirstEndTimeChange = false;
                          sp.timeIntervalStart =
                              (time - 30 + (24 * 60)) % (24 * 60);
                        }
                      }

                      Navigator.pop(context);
                    },
                  ),
                  SizedBox(height: 4),
                  CircleButton(
                    cnIcon: CNSymbol('xmark', size: 20),
                    tp: tp,
                    icon: Icon(Icons.close, color: tp.primaryTextColor),
                    color: tp.surfaceColor,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:habitt/models/notification.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/widgets/default/default_button.dart';
import 'package:habitt/widgets/default/glass_feel_container.dart';
import 'package:habitt/widgets/default/number_picker.dart';
import 'package:provider/provider.dart';

class TimePickerSheet extends StatefulWidget {
  const TimePickerSheet({
    super.key,
    required this.currentTime,
    required this.notificationPeriod,
  });

  final TimeOfDay currentTime;
  final NotificationPeriod notificationPeriod;

  @override
  State<TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<TimePickerSheet> {
  late FixedExtentScrollController hoursController;
  late FixedExtentScrollController minutesController;

  @override
  void initState() {
    super.initState();
    hoursController = FixedExtentScrollController(
      initialItem: widget.currentTime.hour,
    );

    minutesController = FixedExtentScrollController(
      initialItem: widget.currentTime.minute,
    );

    debugPrint(
      "Initialized TimePickerSheet with time: ${widget.currentTime.hour}:${widget.currentTime.minute}",
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
    final tp = context.watch<ThemeProvider>();
    final width = MediaQuery.of(context).size.width;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Transform.translate(
              offset: const Offset(0, 2), // to hide bottom border
              child: GlassFeelContainer(
                width: width,
                child: Column(
                  children: [
                    Text(
                      "Select Time",
                      style: TextStyle(
                        color: tp.primaryTextColor,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: NumberPicker(
                        hoursController: hoursController,
                        minutesController: minutesController,
                        minHours: widget.notificationPeriod.hourRange.$1,
                        maxHours: widget.notificationPeriod.hourRange.$2 - 1,
                        width: width,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        key: const ValueKey("value"),
                        children: [
                          Expanded(
                            child: DefaultButton(
                              onPressed: () => Navigator.pop(context),
                              label: "Cancel",
                              outlined: true,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: DefaultButton(
                              onPressed: () {
                                debugPrint(
                                  "Selected time: ${hoursController.selectedItem}:${minutesController.selectedItem}",
                                );

                                final numberOfHours =
                                    widget.notificationPeriod.hourRange.$2 -
                                    widget.notificationPeriod.hourRange.$1;

                                debugPrint("Number of hours: $numberOfHours");

                                final fixedHour =
                                    widget.notificationPeriod.hourRange.$1 +
                                    (hoursController.selectedItem %
                                        numberOfHours);

                                final fixedMinute =
                                    minutesController.selectedItem % 60;

                                debugPrint(
                                  "Fixed time: $fixedHour:$fixedMinute",
                                );

                                Navigator.pop(
                                  context,
                                  TimeOfDay(
                                    hour: fixedHour,
                                    minute: fixedMinute,
                                  ),
                                );
                              },
                              label: "Confirm",
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 18,
                    ), // to center content because of transform
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

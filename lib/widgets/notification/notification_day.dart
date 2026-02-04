import 'package:flutter/material.dart';
import 'package:habitt/models/notification.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/services/notification_service.dart';
import 'package:habitt/widgets/default/default_dialog.dart';
import 'package:habitt/widgets/default/default_switch.dart';
import 'package:habitt/widgets/default/glass_feel_container.dart';
import 'package:habitt/widgets/notification/time_picker_sheet.dart';
import 'package:habitt/widgets/notification/weekday_selector.dart';
import 'package:provider/provider.dart';

class NotificationDay extends StatelessWidget {
  const NotificationDay({
    super.key,
    required this.notificationPeriod,
    required this.settings,
    required this.onToggleEnabled,
    required this.onTimeChanged,
    required this.onWeekdayToggled,
  });

  final NotificationPeriod notificationPeriod;
  final NotificationSettings settings;
  final ValueChanged<bool> onToggleEnabled;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final ValueChanged<int> onWeekdayToggled;

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TimePickerSheet(
          currentTime: settings.time,
          notificationPeriod: notificationPeriod,
        );
      },
    );

    if (picked != null && context.mounted) {
      // Validate time is within period range
      if (!notificationPeriod.isTimeInRange(picked)) {
        _showInvalidTimeDialog(context);
        return;
      }

      onTimeChanged(picked);
    }
  }

  void _showInvalidTimeDialog(BuildContext context) {
    final (start, end) = notificationPeriod.hourRange;
    final rangeText =
        notificationPeriod == NotificationPeriod.evening
            ? '7:00 PM - 3:59 AM'
            : '$start:00 - ${end - 1}:59';

    showDialog(
      context: context,
      builder:
          (context) => DefaultDialog(
            title: "Invalid Time",
            desc:
                'Please select a time within the ${notificationPeriod.name} period ($rangeText)',
            rightButtonText: "Got it",
          ),
    );
  }

  Future<void> _handleToggle(BuildContext context) async {
    // If trying to enable, check permissions first
    if (!settings.enabled) {
      final allowed = await NotificationService.areNotificationsAllowed();
      if (!allowed && context.mounted) {
        final granted = await NotificationService.requestPermissions(context);
        if (!granted) return; // User denied permission
      }
    }

    onToggleEnabled(!settings.enabled);
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final timeString =
        '${settings.time.hour.toString().padLeft(2, '0')}:${settings.time.minute.toString().padLeft(2, '0')}';

    return GlassFeelContainer(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  notificationPeriod.name,
                  style: TextStyle(
                    color: tp.primaryTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                DefaultSwitch(
                  onTap: () => _handleToggle(context),
                  switchValue: settings.enabled,
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder:
                  (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SizeTransition(sizeFactor: animation, child: child),
                  ),
              child:
                  settings.enabled
                      ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => _selectTime(context),
                            child: GlassFeelContainer(
                              child: Text(
                                timeString,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: tp.primaryTextColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          WeekdaySelector(
                            notificationPeriod: notificationPeriod,
                            selectedWeekdays: settings.weekdays,
                            onToggleWeekday: onWeekdayToggled,
                          ),
                        ],
                      )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

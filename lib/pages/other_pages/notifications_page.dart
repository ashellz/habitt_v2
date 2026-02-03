import 'package:flutter/material.dart';
import 'package:habitt/models/notification.dart';
import 'package:habitt/providers/notifications_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/services/notification_service.dart';
import 'package:habitt/util/color_contrast.dart';
import 'package:habitt/widgets/default/default_annotated_region.dart';
import 'package:habitt/widgets/default/default_dialog.dart';
import 'package:habitt/widgets/default/default_switch.dart';
import 'package:habitt/widgets/default/glass_feel_container.dart';
import 'package:habitt/widgets/default/nav_back_button.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final allowed = await NotificationService.areNotificationsAllowed();

    if (!allowed && mounted) {
      _showPermissionDialog();
    }
  }

  Future<void> _showPermissionDialog() async {
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder:
          (context) => DefaultDialog(
            title: "Missing Permissions",
            desc:
                "To receive reminders, please enable notification permissions for Habitt.",
            rightButtonText: "Enable",
            rightButtonCallback: () {
              Navigator.of(context).pop(true);
            },
            leftButtonText: "Cancel",
            leftButtonCallback: () {
              Navigator.of(context).pop(false);
            },
          ),
    );

    if (shouldRequest == true && mounted) {
      await NotificationService.requestPermissions(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

    return DefaultAnnotatedRegion(
      child: Scaffold(
        backgroundColor: tp.backgroundColor,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            children: [
              ListView(
                children: [
                  NavBackButton(tp: tp),
                  Text(
                    "Notifications",
                    style: TextStyle(
                      fontSize: 38,
                      color: tp.primaryTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Control when and how you get notified about your habits.",
                    style: TextStyle(
                      fontSize: 16,
                      color: tp.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Column(
                    spacing: 16,
                    children: [
                      NotificationDay(
                        notificationPeriod: NotificationPeriod.morning,
                      ),
                      NotificationDay(
                        notificationPeriod: NotificationPeriod.afternoon,
                      ),
                      NotificationDay(
                        notificationPeriod: NotificationPeriod.evening,
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationDay extends StatelessWidget {
  const NotificationDay({super.key, required this.notificationPeriod});

  final NotificationPeriod notificationPeriod;

  Future<void> _selectTime(BuildContext context) async {
    final provider = context.read<NotificationsProvider>();
    final tp = context.read<ThemeProvider>();
    final currentTime = provider.getTime(notificationPeriod);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme:
                tp.isDark
                    ? ColorScheme.dark(
                      primary: tp.primaryColor,
                      surface: tp.surfaceColor,
                    )
                    : ColorScheme.light(
                      primary: tp.primaryColor,
                      surface: tp.surfaceColor,
                    ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      // Validate time is within period range
      if (!notificationPeriod.isTimeInRange(picked)) {
        _showInvalidTimeDialog(context);
        return;
      }

      await provider.setTime(notificationPeriod, picked);
      await NotificationService.reschedulePeriod(notificationPeriod, provider);
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
    final provider = context.read<NotificationsProvider>();
    final currentlyEnabled = provider.isEnabled(notificationPeriod);

    // If trying to enable, check permissions first
    if (!currentlyEnabled) {
      final allowed = await NotificationService.areNotificationsAllowed();
      if (!allowed && context.mounted) {
        final granted = await NotificationService.requestPermissions(context);
        if (!granted) return; // User denied permission
      }
    }

    await provider.toggleEnabled(notificationPeriod);

    if (!context.mounted) return;

    // Reschedule notifications
    await NotificationService.reschedulePeriod(notificationPeriod, provider);
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final notificationsProvider = context.watch<NotificationsProvider>();
    final settings = notificationsProvider.getSettings(notificationPeriod);

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

class WeekdaySelector extends StatelessWidget {
  const WeekdaySelector({
    super.key,
    required this.notificationPeriod,
    required this.selectedWeekdays,
  });

  final NotificationPeriod notificationPeriod;
  final Set<int> selectedWeekdays;

  static const List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final provider = context.read<NotificationsProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final weekday = index + 1; // 1 = Monday, 7 = Sunday
        final isSelected = selectedWeekdays.contains(weekday);

        return GestureDetector(
          onTap: () async {
            await provider.toggleWeekday(notificationPeriod, weekday);
            await NotificationService.reschedulePeriod(
              notificationPeriod,
              provider,
            );
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? tp.primaryColor : tp.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? tp.primaryColor : tp.borderColor,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _dayLabels[index],
                style: TextStyle(
                  color:
                      isSelected
                          ? bestContrastingOn(tp.backgroundColor)
                          : tp.mutedTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

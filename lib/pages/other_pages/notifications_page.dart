import 'dart:io';

import 'package:flutter/material.dart';
import 'package:habitt/models/notification.dart';
import 'package:habitt/providers/notifications_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/services/notification_service.dart';
import 'package:habitt/widgets/default/custom_switcher_wrapper.dart';
import 'package:habitt/widgets/default/default_annotated_region.dart';
import 'package:habitt/widgets/default/default_dialog.dart';
import 'package:habitt/widgets/default/default_button.dart';
import 'package:habitt/widgets/default/nav_back_button.dart';
import 'package:habitt/widgets/notification/notification_day.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // A copy from the real provider data
  // All changes first go to this map, then from this map to the real provider when the user saves
  final Map<NotificationPeriod, NotificationSettings> _realDataCopy = {};

  // This map tracks which periods have been changed
  // so we only save and reschedule those periods
  final Set<NotificationPeriod> _changedPeriods = {};
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final notificationsProvider = context.read<NotificationsProvider>();
    for (final period in NotificationPeriod.values) {
      _realDataCopy[period] = notificationsProvider.getSettings(period);
    }
    _initialized = true;
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

  void _updatePeriod(
    NotificationPeriod period,
    NotificationSettings newSettings,
  ) {
    setState(() {
      _realDataCopy[period] = newSettings;
      _changedPeriods.add(period);
    });
  }

  void _handleToggle(NotificationPeriod period, bool enabled) {
    final current = _realDataCopy[period]!;
    _updatePeriod(period, current.copyWith(enabled: enabled));
  }

  void _handleTime(NotificationPeriod period, TimeOfDay time) {
    final current = _realDataCopy[period]!;
    _updatePeriod(period, current.copyWith(time: time));
  }

  void _handleWeekday(NotificationPeriod period, int weekday) {
    final current = _realDataCopy[period]!;
    final next = Set<int>.from(current.weekdays);
    if (next.contains(weekday)) {
      next.remove(weekday);
      if (next.isEmpty) return; // don't allow empty selection
    } else {
      next.add(weekday);
    }
    _updatePeriod(period, current.copyWith(weekdays: next));
  }

  void _resetChanges() {
    final notificationsProvider = context.read<NotificationsProvider>();
    setState(() {
      for (final period in NotificationPeriod.values) {
        _realDataCopy[period] = notificationsProvider.getSettings(period);
      }
      _changedPeriods.clear();
    });
  }

  Future<void> _saveChanges() async {
    if (_changedPeriods.isEmpty) return;
    final notificationsProvider = context.read<NotificationsProvider>();

    for (final period in _changedPeriods) {
      final settings = _realDataCopy[period]!;
      await notificationsProvider.setSettings(period, settings);
      await NotificationService.reschedulePeriod(period, notificationsProvider);
    }

    if (!mounted) return;
    setState(() {
      _changedPeriods.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final extraPadding = Platform.isAndroid ? 12.0 : 0.0;

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
                        settings: _realDataCopy[NotificationPeriod.morning]!,
                        onToggleEnabled:
                            (enabled) => _handleToggle(
                              NotificationPeriod.morning,
                              enabled,
                            ),
                        onTimeChanged:
                            (time) =>
                                _handleTime(NotificationPeriod.morning, time),
                        onWeekdayToggled:
                            (weekday) => _handleWeekday(
                              NotificationPeriod.morning,
                              weekday,
                            ),
                      ),
                      NotificationDay(
                        notificationPeriod: NotificationPeriod.afternoon,
                        settings: _realDataCopy[NotificationPeriod.afternoon]!,
                        onToggleEnabled:
                            (enabled) => _handleToggle(
                              NotificationPeriod.afternoon,
                              enabled,
                            ),
                        onTimeChanged:
                            (time) =>
                                _handleTime(NotificationPeriod.afternoon, time),
                        onWeekdayToggled:
                            (weekday) => _handleWeekday(
                              NotificationPeriod.afternoon,
                              weekday,
                            ),
                      ),
                      NotificationDay(
                        notificationPeriod: NotificationPeriod.evening,
                        settings: _realDataCopy[NotificationPeriod.evening]!,
                        onToggleEnabled:
                            (enabled) => _handleToggle(
                              NotificationPeriod.evening,
                              enabled,
                            ),
                        onTimeChanged:
                            (time) =>
                                _handleTime(NotificationPeriod.evening, time),
                        onWeekdayToggled:
                            (weekday) => _handleWeekday(
                              NotificationPeriod.evening,
                              weekday,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),

              Positioned(
                left: 0,
                right: 0,

                bottom:
                    MediaQuery.of(context).padding.bottom +
                    extraPadding, // bottom safe area,
                child: CustomSwitcherWrapper(
                  value: _changedPeriods.isNotEmpty,
                  widget: Row(
                    children: [
                      Expanded(
                        child: DefaultButton(
                          label: "Cancel",
                          onPressed: _resetChanges,
                          outlined: true,
                          color: tp.backgroundColor,
                          borderColor: tp.primaryButtonBackground,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DefaultButton(
                          label: "Save",
                          onPressed: _saveChanges,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

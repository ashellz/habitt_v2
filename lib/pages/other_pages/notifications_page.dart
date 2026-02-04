import 'package:flutter/material.dart';
import 'package:habitt/models/notification.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/services/notification_service.dart';
import 'package:habitt/widgets/default/default_annotated_region.dart';
import 'package:habitt/widgets/default/default_dialog.dart';
import 'package:habitt/widgets/default/nav_back_button.dart';
import 'package:habitt/widgets/notification/notification_day.dart';
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

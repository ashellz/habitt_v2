import 'package:flutter/material.dart';
import 'package:habitt/providers/notifications_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/widgets/default/default_annotated_region.dart';
import 'package:habitt/widgets/default/default_switch.dart';
import 'package:habitt/widgets/default/glass_feel_container.dart';
import 'package:habitt/widgets/default/nav_back_button.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

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
                  SizedBox(height: 24),
                  //
                  Column(
                    spacing: 8,
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

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

    return GlassFeelContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                notificationPeriod.name,
                style: TextStyle(color: tp.primaryTextColor),
              ),
              Spacer(),
              DefaultSwitch(onTap: () {}, switchValue: true),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: GlassFeelContainer(
              child: Text(
                "08:00",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: tp.primaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

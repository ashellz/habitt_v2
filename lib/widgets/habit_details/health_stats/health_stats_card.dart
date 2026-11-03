import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/health_provider.dart';
import 'package:habitt/providers/sync_devices_provider.dart';
import 'package:habitt/util/health_history.dart';
import 'package:habitt/util/health_missing_data.dart';
import 'package:habitt/widgets/default/health_override_tag.dart';
import 'package:habitt/widgets/habit_details/health_stats/health_sessions_list.dart';
import 'package:habitt/widgets/habit_details/health_stats/health_week_chart.dart';
import 'package:habitt/widgets/default/health_connect_icon.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

// health stats widget for details page
class HealthStatsCard extends StatelessWidget {
  const HealthStatsCard({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final metric = habit.healthMetric;
    if (metric == null || !(Platform.isIOS || Platform.isAndroid)) {
      return const SizedBox.shrink();
    }

    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;
    final habitProvider = context.watch<HabitProvider>();
    final today = DateTime.now();

    final history = buildHealthHistory(
      habit,
      (day) => habitProvider.habitForDay(habit.id, day: day),
      today: today,
    );
    final latest = habitProvider.habitForDay(
      habit.id,
      day: history.points.last.day,
    );
    final sessions = latest?.healthSessions ?? const [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: cp.bg,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: cp.border),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          _Header(),
          if (Platform.isIOS &&
              context.watch<SyncDevicesProvider>().readsHealthHere &&
              shouldHintHealthAccess(
                history: history,
                createdAt: habit.createdAt.toLocal(),
                today: today,
              ))
            _AccessHint(),
          if (latest != null)
            HealthOverrideTag(habit: latest, day: history.points.last.day),
          _chartSection(cp, loc, history),
          if (metric == HealthMetricType.bedtime) _countingNote(cp, loc),
          if (metric.hasSessions) ...[
            Divider(height: 1, color: cp.border),
            HealthSessionsList(habit: habit, sessions: sessions),
          ],
        ],
      ),
    );
  }

  // ─── Chart ────────────────────────────────────────────

  Widget _chartSection(
    ColorProvider cp,
    AppLocalizations loc,
    HealthHistory history,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Text(
          loc.healthCardLast7Days,
          style: TextStyle(
            color: cp.lightGreyText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (history.hasData)
          HealthWeekChart(history: history)
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                loc.healthCardNoData,
                textAlign: TextAlign.center,
                style: TextStyle(color: cp.lightGreyText, fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Counting note ────────────────────────────────────

  Widget _countingNote(ColorProvider cp, AppLocalizations loc) {
    return Text(
      habit.healthBedtimeDayBefore
          ? loc.healthBedtimeDayBeforeDesc
          : loc.healthBedtimeDayWakeDesc,
      style: TextStyle(color: cp.lightGreyText, fontSize: 12),
    );
  }
}

extension on HealthMetricType {
  // steps and calories are one running total, so there is nothing to list
  bool get hasSessions =>
      this != HealthMetricType.steps &&
      this != HealthMetricType.activeCalories &&
      this != HealthMetricType.totalCalories;
}

// iOS can't report a refused Health prompt, so after a few empty days we ask
// the user to check the access themselves
class _AccessHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          loc.healthNoRecentDataHintIos('Apple Health'),
          style: TextStyle(color: cp.lightGreyText, fontSize: 13),
        ),
        GestureDetector(
          onTap: openAppSettings,
          child: Text(
            loc.healthOpenSettings,
            style: TextStyle(
              color: cp.main,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Header ─────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;
    final health = context.watch<HealthProvider>();
    final devices = context.watch<SyncDevicesProvider>();

    // with another device reading Health, the card shows that device's store
    final readsHere = devices.readsHealthHere;
    final isAppleHealth = devices.healthPlatform == 'ios';
    final needsPermission =
        readsHere && Platform.isAndroid && !health.permissionGranted;

    return Row(
      spacing: 12,
      children: [
        isAppleHealth
            ? SvgPicture.asset(
              'assets/images/widget-images/apple-health.svg',
              width: 36,
              height: 36,
            )
            : const HealthConnectIcon(size: 36),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                devices.healthBrand,
                style: TextStyle(
                  color: cp.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: needsPermission ? () => _requestAccess(context) : null,
                child: Text(
                  readsHere
                      ? _status(context, loc, health, needsPermission)
                      : loc.healthCardFromDevice(
                        devices.healthSource?.displayName ?? '',
                      ),
                  style: TextStyle(
                    color: needsPermission ? cp.main : cp.lightGreyText,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _requestAccess(BuildContext context) async {
    final health = context.read<HealthProvider>();
    final granted = await health.requestPermissionIfNeeded();
    if (granted) await health.syncNow();
  }

  String _status(
    BuildContext context,
    AppLocalizations loc,
    HealthProvider health,
    bool needsPermission,
  ) {
    if (needsPermission) return loc.healthCardPermissionNeeded;
    if (health.isSyncing) return loc.healthCardSyncing;
    final synced = health.lastSyncedAt;
    if (synced == null) return loc.healthCardNotSyncedYet;

    final materialLoc = MaterialLocalizations.of(context);
    final time = materialLoc.formatTimeOfDay(TimeOfDay.fromDateTime(synced));
    final now = DateTime.now();
    final isToday =
        synced.year == now.year &&
        synced.month == now.month &&
        synced.day == now.day;
    final when =
        isToday
            ? '${loc.today}, $time'
            : '${DateFormat('d MMM', Localizations.localeOf(context).toString()).format(synced)}, $time';
    return loc.lastSynced(when);
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/health_provider.dart';
import 'package:habitt/util/health_history.dart';
import 'package:habitt/widgets/habit_details/health_stats/health_sessions_list.dart';
import 'package:habitt/widgets/habit_details/health_stats/health_week_chart.dart';
import 'package:intl/intl.dart';
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

// ─── Header ─────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;
    final health = context.watch<HealthProvider>();

    final needsPermission = Platform.isAndroid && !health.permissionGranted;

    return Row(
      spacing: 12,
      children: [
        Platform.isIOS
            ? SvgPicture.asset(
              'assets/images/widget-images/apple-health.svg',
              width: 36,
              height: 36,
            )
            : Image.asset(
              'assets/images/widget-images/health-connect.png',
              width: 36,
              height: 36,
            ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              // brand names, the same in every language
              Text(
                Platform.isIOS ? 'Apple Health' : 'Health Connect',
                style: TextStyle(
                  color: cp.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: needsPermission ? () => _requestAccess(context) : null,
                child: Text(
                  _status(context, loc, health, needsPermission),
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

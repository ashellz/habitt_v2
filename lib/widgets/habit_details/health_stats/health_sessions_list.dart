import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/health_session_detail.dart';
import 'package:habitt/models/health_workout_type.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/get_duration_string.dart';
import 'package:provider/provider.dart';

/// The individual sessions behind a day's Health progress, collapsed to a
/// single row until tapped.
class HealthSessionsList extends StatefulWidget {
  const HealthSessionsList({
    super.key,
    required this.habit,
    required this.sessions,
  });

  final Habit habit;
  final List<HealthSessionDetail> sessions;

  @override
  State<HealthSessionsList> createState() => _HealthSessionsListState();
}

class _HealthSessionsListState extends State<HealthSessionsList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;
    final sessions = widget.sessions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Header ─────────────────────────────────────
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    sessions.isEmpty
                        ? loc.healthCardSessions
                        : '${loc.healthCardSessions} (${sessions.length})',
                    style: TextStyle(
                      color: cp.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: SvgPicture.asset(
                    'assets/images/new-svg/dropdown.svg',
                    colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
                  ),
                ),
              ],
            ),
          ),
        ),
        // ─── Body ───────────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child:
              !_expanded
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child:
                        sessions.isEmpty
                            ? Text(
                              loc.healthCardNoSessions,
                              style: TextStyle(
                                color: cp.lightGreyText,
                                fontSize: 13,
                              ),
                            )
                            : Column(
                              spacing: 8,
                              children: [
                                for (final session in sessions)
                                  _sessionRow(context, cp, loc, session),
                              ],
                            ),
                  ),
        ),
      ],
    );
  }

  Widget _sessionRow(
    BuildContext context,
    ColorProvider cp,
    AppLocalizations loc,
    HealthSessionDetail session,
  ) {
    final materialLoc = MaterialLocalizations.of(context);
    String time(DateTime t) =>
        materialLoc.formatTimeOfDay(TimeOfDay.fromDateTime(t.toLocal()));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cp.habitBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        spacing: 10,
        children: [
          _sessionIcon(cp, session),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  _sessionTitle(loc, session),
                  style: TextStyle(
                    color: cp.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${time(session.start)} – ${time(session.end)}',
                  style: TextStyle(color: cp.lightGreyText, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            getDurationString(session.duration.inSeconds),
            style: TextStyle(color: cp.text, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _sessionIcon(ColorProvider cp, HealthSessionDetail session) {
    final metric = widget.habit.healthMetric;
    if (metric == HealthMetricType.workouts) {
      return Icon(session.workoutType.icon, color: cp.text, size: 22);
    }
    if (metric == null) return const SizedBox(width: 22, height: 22);
    return Image.asset(metric.iconPath, width: 22, height: 22);
  }

  String _sessionTitle(AppLocalizations loc, HealthSessionDetail session) {
    switch (widget.habit.healthMetric) {
      case HealthMetricType.workouts:
        return session.workoutType.label(loc);
      case HealthMetricType.mindfulness:
        return loc.healthMetricMindfulMinutes;
      case HealthMetricType.activity:
        return loc.healthMetricActivity;
      case HealthMetricType.sleep:
      case HealthMetricType.bedtime:
      case HealthMetricType.wakeTime:
        return loc.healthMetricSleep;
      default:
        return widget.habit.resolvedName(null);
    }
  }
}

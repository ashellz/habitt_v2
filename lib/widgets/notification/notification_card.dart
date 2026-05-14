import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/notification.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/notifications_provider.dart';
import 'package:habitt/widgets/default/new_default_switch.dart';
import 'package:habitt/widgets/default/selectable_weekdays.dart';
import 'package:habitt/widgets/notification/notification_time_row.dart';
import 'package:provider/provider.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.period,
    this.settings,
    this.enabled,
    this.onToggleEnabled,
    this.onTimeChanged,
    this.onWeekdayToggled,
  });

  final NotificationPeriod period;
  final NotificationSettings? settings;
  final bool? enabled;
  final ValueChanged<bool>? onToggleEnabled;
  final ValueChanged<TimeOfDay>? onTimeChanged;
  final ValueChanged<int>? onWeekdayToggled;

  Map<int, String> _indexToLabel(AppLocalizations loc) {
    return {
      1: loc.mon,
      2: loc.tue,
      3: loc.wed,
      4: loc.thu,
      5: loc.fri,
      6: loc.sat,
      7: loc.sun,
    };
  }

  Set<String> _labelsFromIndices(Set<int> indices, AppLocalizations loc) {
    return _indexToLabel(loc).entries
        .where((entry) => indices.contains(entry.key))
        .map((entry) => entry.value)
        .toSet();
  }

  int _indexFromLabel(String label, AppLocalizations loc) {
    return _indexToLabel(loc).entries
        .firstWhere(
          (entry) => entry.value == label,
          orElse: () => MapEntry(1, loc.mon),
        )
        .key;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cp = context.watch<ColorProvider>();
    final np = context.watch<NotificationsProvider>();
    final resolvedSettings = settings ?? np.getSettings(period);
    final resolvedEnabled = enabled ?? np.isEnabled(period);

    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 16),
      decoration: ShapeDecoration(
        color: cp.isDark ? cp.habitBg : cp.bg,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: cp.border),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              spacing: 12,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: SvgPicture.asset(
                    period.iconPath,
                    colorFilter: ColorFilter.mode(
                      cp.lightGreyText,
                      BlendMode.srcIn,
                    ),
                  ),
                ),

                Expanded(
                  child: Text(
                    period.getLocalizedName(context),
                    style: TextStyle(
                      color: cp.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                NewDefaultSwitch(
                  value: resolvedSettings.enabled,
                  onChanged: (value) async {
                    if (onToggleEnabled != null) {
                      onToggleEnabled!(value);
                      return;
                    }
                    await np.toggleEnabled(period, context);
                  },
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder:
                (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(sizeFactor: animation, child: child),
                ),
            child:
                resolvedEnabled
                    ? Column(
                      key: ValueKey('notification-expanded-${period.name}'),
                      spacing: 16,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: NotificationTimeRow(
                            isHabit: false,
                            minutesOfDay:
                                (resolvedSettings.time.hour * 60) +
                                resolvedSettings.time.minute,
                            onTimeSelected: (minutes) async {
                              final tod = TimeOfDay(
                                hour: minutes ~/ 60,
                                minute: minutes % 60,
                              );
                              if (onTimeChanged != null) {
                                onTimeChanged!(tod);
                                return;
                              }
                              await np.setTime(period, tod);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16),
                          child: SelectableWeekdays(
                            isNotification: true,
                            selectedDays: _labelsFromIndices(
                              resolvedSettings.weekdays,
                              loc,
                            ),
                            onDaySelected: (label) {
                              final idx = _indexFromLabel(label, loc);
                              if (onWeekdayToggled != null) {
                                onWeekdayToggled!(idx);
                                return;
                              }
                              np.toggleWeekday(period, idx);
                            },
                          ),
                        ),
                      ],
                    )
                    : const SizedBox.shrink(key: ValueKey('notification-off')),
          ),
        ],
      ),
    );
  }
}

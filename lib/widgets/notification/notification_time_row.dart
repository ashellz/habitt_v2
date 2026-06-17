import 'package:cupertino_native_better/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_circle_button.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/new_default_switch.dart';
import 'package:habitt/widgets/default/number_picker.dart';
import 'package:habitt/widgets/default/selectable_weekdays.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class NotificationTimeRow extends StatefulWidget {
  const NotificationTimeRow({
    super.key,
    required this.isHabit,
    required this.minutesOfDay,
    this.days = const [],
    this.onDelete,
    this.onOpenTimeDialog,
    this.onTimeSelected,
  });

  final bool isHabit;
  final int minutesOfDay;
  final List<int> days;
  final VoidCallback? onDelete;
  final Future<void> Function()? onOpenTimeDialog;
  final ValueChanged<int>? onTimeSelected;

  @override
  State<NotificationTimeRow> createState() => _NotificationTimeRowState();
}

class _NotificationTimeRowState extends State<NotificationTimeRow> {
  final bool _isHeld = false;

  void _handleOpenTimeDialog() async {
    if (widget.onOpenTimeDialog != null) {
      await widget.onOpenTimeDialog!();
      return;
    }

    // Fallback to the local dialog implementation if no callback provided
    await showNotificationTimeDialog(
      initialMinutes: widget.minutesOfDay,
      onTimeSelected: widget.onTimeSelected ?? (_) {},
      context: context,
      isNew: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    final content = Container(
      padding: const EdgeInsets.only(top: 4, left: 12, right: 4, bottom: 4),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: cp.isDark ? cp.habitBg : cp.bg,
        shape:
            !widget.isHabit
                ? RoundedRectangleBorder(
                  side: BorderSide(width: 1, color: cp.border),
                  borderRadius: BorderRadius.circular(24),
                )
                : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.days.isEmpty
                  ? loc.time2
                  : _weekdayInitials(widget.days, loc),
              style: TextStyle(color: cp.lightGreyText, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: _handleOpenTimeDialog,
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: ShapeDecoration(
                color: cp.field,
                shape: StadiumBorder(),
              ),
              child: Row(
                spacing: 16,
                children: [
                  Text(
                    _formatTimeOfDayFromMinutes(widget.minutesOfDay),
                    style: TextStyle(
                      color: cp.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SvgPicture.asset(
                    "assets/images/new-svg/clock.svg",
                    colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // Habit mode: add press/hold interactions and scale animation
    if (widget.isHabit) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          children: [
            Expanded(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                scale: _isHeld ? 1.04 : 1.0,
                child: content,
              ),
            ),

            const SizedBox(width: 12),
            NewCircleButton(
              svgPath: 'assets/images/new-svg/close.svg',
              cnIcon: CNSymbol('xmark', size: 16),
              color: cp.error,
              textColor: cp.text,
              width: 46,
              height: 46,
              onPressed: () {
                widget.onDelete?.call();
              },
            ),
          ],
        ),
      );
    }

    // Non-habit mode: simple tappable row
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: content,
    );
  }
}

String _formatTimeOfDayFromMinutes(int minutesOfDay) {
  final hour = (minutesOfDay ~/ 60) % 24;
  final minute = minutesOfDay % 60;
  return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
}

/// Maps ISO weekday numbers (1 = Monday … 7 = Sunday) to localized short labels.
Map<int, String> _weekdayLabels(AppLocalizations loc) => {
  1: loc.mon,
  2: loc.tue,
  3: loc.wed,
  4: loc.thu,
  5: loc.fri,
  6: loc.sat,
  7: loc.sun,
};

/// Comma-separated localized labels for the given weekdays, in week order.
String _weekdayInitials(List<int> days, AppLocalizations loc) {
  final labels = _weekdayLabels(loc);
  final sorted = [...days]..sort();
  return sorted.map((d) => labels[d]).whereType<String>().join(", ");
}

Future<void> showNotificationTimeDialog({
  required int initialMinutes,
  required BuildContext context,
  ValueChanged<int>? onTimeSelected,
  void Function(int minutesOfDay, List<int> days)? onSaved,
  bool isNew = false,
  bool isHabit = false,
  List<int> initialDays = const [],
}) async {
  int selectedHour = initialMinutes ~/ 60;
  int selectedMinute = initialMinutes % 60;

  final hoursController = FixedExtentScrollController(
    initialItem: selectedHour,
  );
  final minutesController = FixedExtentScrollController(
    initialItem: selectedMinute,
  );
  final loc = AppLocalizations.of(context)!;

  // Habit schedule context drives the grey-out / tip behavior. Only read it
  // for habit reminders; global notifications never show the day selector.
  final sp = isHabit ? context.read<StateProvider>() : null;
  final scheduleType = sp?.selectedScheduleOption ?? ScheduleType.daily;
  final scheduledWeekdays = sp?.selectedDaysAWeek ?? <int>{};
  final bool isDaily = scheduleType == ScheduleType.daily;
  final bool isWeeklyFixed =
      scheduleType == ScheduleType.weekly && scheduledWeekdays.isNotEmpty;
  // Days the user is allowed to pick. For weekly-fixed habits this is the
  // habit's scheduled days, so the schedule∩reminder intersection is never
  // empty; otherwise all seven days are selectable.
  final List<int> selectableDays =
      isWeeklyFixed
          ? (scheduledWeekdays.toList()..sort())
          : const [1, 2, 3, 4, 5, 6, 7];

  bool followSchedule = initialDays.isEmpty;
  final Set<int> selectedDays = {
    ...initialDays.where((d) => selectableDays.contains(d)),
  };

  const switchDuration = Duration(milliseconds: 300);

  try {
    await showDialogSheet(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final cp = dialogContext.watch<ColorProvider>();
              final weekdayLabels = _weekdayLabels(loc);
              final disabledLabels =
                  weekdayLabels.entries
                      .where((e) => !selectableDays.contains(e.key))
                      .map((e) => e.value)
                      .toSet();
              final selectedLabels =
                  selectedDays
                      .map((d) => weekdayLabels[d])
                      .whereType<String>()
                      .toSet();
              final bool canSave = followSchedule || selectedDays.isNotEmpty;

              return NewDefaultDialog(
                title: loc.setNotificationTime,
                primaryButtonLabel: isNew ? loc.add : loc.save,
                primaryButtonEnabled: canSave,
                onPrimaryButtonPressed: () {
                  final minutes = (selectedHour * 60) + selectedMinute;
                  final days =
                      followSchedule
                          ? <int>[]
                          : (selectedDays.toList()..sort());
                  if (onSaved != null) {
                    onSaved(minutes, days);
                  } else {
                    onTimeSelected?.call(minutes);
                  }
                  Navigator.of(dialogContext).pop();
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NumberPicker(
                      hoursController: hoursController,
                      minutesController: minutesController,
                      width: MediaQuery.of(dialogContext).size.width,
                      onChangedHours: (value) {
                        setDialogState(() {
                          selectedHour = value;
                        });
                      },
                      onChangedMinutes: (value) {
                        setDialogState(() {
                          selectedMinute = value;
                        });
                      },
                    ),
                    if (isHabit) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              loc.followHabitSchedule,
                              style: TextStyle(
                                color: cp.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          NewDefaultSwitch(
                            value: followSchedule,
                            onChanged: (value) {
                              setDialogState(() {
                                followSchedule = value;
                                if (!value && selectedDays.isEmpty) {
                                  // Toggling off pre-selects every selectable
                                  // day (the habit's scheduled days when
                                  // weekly-fixed, otherwise all seven).
                                  selectedDays.addAll(selectableDays);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      AnimatedSwitcher(
                        duration: switchDuration,
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SizeTransition(
                              sizeFactor: animation,
                              axisAlignment: -1,
                              child: child,
                            ),
                          );
                        },
                        child:
                            followSchedule
                                ? const SizedBox.shrink(
                                  key: ValueKey('notif-days-hidden'),
                                )
                                : Column(
                                  key: const ValueKey('notif-days-shown'),
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 12),
                                    SelectableWeekdays(
                                      isNotification: true,
                                      selectedDays: selectedLabels,
                                      disabledDays: disabledLabels,
                                      onDaySelected: (label) {
                                        final dayValue =
                                            weekdayLabels.entries
                                                .firstWhere(
                                                  (e) => e.value == label,
                                                )
                                                .key;
                                        setDialogState(() {
                                          if (selectedDays.contains(dayValue)) {
                                            selectedDays.remove(dayValue);
                                          } else {
                                            selectedDays.add(dayValue);
                                          }
                                        });
                                      },
                                    ),
                                    if (!isDaily) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        isWeeklyFixed
                                            ? loc.notificationWeekdaysFixedTip
                                            : loc
                                                .notificationScheduleDependencyTip,
                                        style: TextStyle(
                                          color: cp.greyText,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
    );
  } finally {
    hoursController.dispose();
    minutesController.dispose();
  }
}

import 'package:cupertino_native_better/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_circle_button.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/number_picker.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class NotificationTimeRow extends StatefulWidget {
  const NotificationTimeRow({
    super.key,
    required this.isHabit,
    required this.minutesOfDay,
    this.onOpenTimeDialog,
    this.onTimeSelected,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onLongPress,
  });

  final bool isHabit;
  final int minutesOfDay;
  final Future<void> Function()? onOpenTimeDialog;
  final ValueChanged<int>? onTimeSelected;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;
  final VoidCallback? onTapCancel;
  final VoidCallback? onLongPress;

  @override
  State<NotificationTimeRow> createState() => _NotificationTimeRowState();
}

class _NotificationTimeRowState extends State<NotificationTimeRow> {
  bool _isHeld = false;

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
          Text(
            loc.time2,
            style: TextStyle(color: cp.lightGreyText, fontSize: 16),
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
              child: GestureDetector(
                onTapDown: (_) {
                  setState(() {
                    _isHeld = true;
                  });
                  widget.onTapDown?.call();
                },
                onTapUp: (_) {
                  setState(() {
                    _isHeld = false;
                  });
                  widget.onTapUp?.call();
                },
                onTapCancel: () {
                  setState(() {
                    _isHeld = false;
                  });
                  widget.onTapCancel?.call();
                },
                onLongPress: () async {
                  widget.onLongPress?.call();
                },
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  scale: _isHeld ? 1.04 : 1.0,
                  child: content,
                ),
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
                widget.onLongPress?.call();
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

Future<void> showNotificationTimeDialog({
  required int initialMinutes,
  required ValueChanged<int> onTimeSelected,
  required BuildContext context,
  bool isNew = false,
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
  try {
    await showDialogSheet(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return NewDefaultDialog(
                title: loc.setNotificationTime,
                desc: loc.thisReminderWillTriggerOnlyOnScheduledHabitDays,
                onPrimaryButtonPressed: () {
                  onTimeSelected((selectedHour * 60) + selectedMinute);
                  Navigator.of(dialogContext).pop();
                },
                primaryButtonLabel: isNew ? loc.add : loc.save,

                child: NumberPicker(
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
              );
            },
          ),
    );
  } finally {
    hoursController.dispose();
    minutesController.dispose();
  }
}

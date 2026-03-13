import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/dialogs/schedules/set_schedule_dialog.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class WeeklyScheduleDialog extends StatefulWidget {
  const WeeklyScheduleDialog({super.key});

  @override
  State<WeeklyScheduleDialog> createState() => _WeeklyScheduleDialogState();
}

class _WeeklyScheduleDialogState extends State<WeeklyScheduleDialog> {
  static const _switchDuration = Duration(milliseconds: 400);
  bool showMoreOptions = false;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return NewDefaultDialog(
      title: "Weekly",
      onSecondaryButtonPressed: () {
        Navigator.pop(context);
        showModalBottomSheet(
          backgroundColor: Colors.transparent,
          barrierColor: cp.greyText.darken().withOpacity(0.3),
          isScrollControlled: true,
          context: context,
          builder: (context) => SetScheduleDialog(),
        );
      },
      child: Column(
        spacing: 20,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Times per week:',
                style: TextStyle(
                  color: cp.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: cp.field,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("1", style: TextStyle(fontSize: 16, color: cp.text)),
                    SvgPicture.asset("assets/images/new-svg/dropdown.svg"),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: _switchDuration,
                switchInCurve: Curves.easeOut,
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
                    !showMoreOptions
                        ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            key: const ValueKey('weekly-helper-text'),
                            'This habit will appear once a week until completed',
                            style: TextStyle(color: cp.greyText, fontSize: 13),
                          ),
                        )
                        : const SizedBox.shrink(
                          key: ValueKey('weekly-helper-text-hidden'),
                        ),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: _switchDuration,
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            layoutBuilder: (currentChild, previousChildren) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
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
                showMoreOptions
                    ? Column(
                      key: const ValueKey('weekly-options-column'),
                      spacing: 12,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SelectDaysWeekly(),
                        Text(
                          'Leave unselected if you want the habit too appear every day of the week until completed',
                          style: TextStyle(
                            color: cp.greyText,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    )
                    : NewDefaultButton.secondary(
                      key: const ValueKey('weekly-add-more-button'),
                      onPressed: () {
                        setState(() {
                          showMoreOptions = true;
                        });
                      },
                      height: 40,
                      prefix: SvgPicture.asset("assets/images/new-svg/add.svg"),
                      label: "Add more options",
                    ),
          ),
        ],
      ),
    );
  }
}

class SelectDaysWeekly extends StatefulWidget {
  const SelectDaysWeekly({super.key});

  @override
  State<SelectDaysWeekly> createState() => _SelectDaysWeeklyState();
}

class _SelectDaysWeeklyState extends State<SelectDaysWeekly> {
  static const _selectionDuration = Duration(milliseconds: 200);
  static const List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  final Set<String> _selectedDays = {};

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: cp.field,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(
            'Select days for this habit:',
            style: TextStyle(color: cp.greyText, fontSize: 16),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                _weekDays.map((day) {
                  final isSelected = _selectedDays.contains(day);

                  return _SelectableWeekDayButton(
                    label: day,
                    isSelected: isSelected,
                    selectionDuration: _selectionDuration,
                    onPressed: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDays.remove(day);
                        } else {
                          _selectedDays.add(day);
                        }
                      });
                    },
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SelectableWeekDayButton extends StatelessWidget {
  const _SelectableWeekDayButton({
    required this.label,
    required this.isSelected,
    required this.selectionDuration,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final Duration selectionDuration;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    return AnimatedContainer(
      duration: selectionDuration,
      curve: Curves.easeOut,
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? cp.pill : Colors.transparent,
        border: Border.all(width: 1, color: isSelected ? cp.pill : cp.disabled),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          splashFactory: isAndroid ? null : NoSplash.splashFactory,
          elevation: const WidgetStatePropertyAll(0),
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (!states.contains(WidgetState.pressed)) {
              return null;
            }

            if (isAndroid) {
              return null;
            }

            return cp.bg.withValues(alpha: 0.2);
          }),
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: const WidgetStatePropertyAll(CircleBorder()),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? cp.bg : cp.text,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

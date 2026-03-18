import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/dialogs/schedules/set_schedule_dialog.dart';
import 'package:habitt/widgets/habit_details/new/select_days_weekly_schedule.dart';
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
    final sp = context.watch<StateProvider>();

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
                    Text(
                      sp.weeklyTarget.toString(),
                      style: TextStyle(fontSize: 16, color: cp.text),
                    ),
                    GestureDetector(
                      onTap: () {
                        final next = sp.weeklyTarget == 6 ? 1 : sp.weeklyTarget + 1;
                        sp.weeklyTarget = next;
                      },
                      child: SvgPicture.asset("assets/images/new-svg/dropdown.svg"),
                    ),
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
                            'This habit will appear ${sp.weeklyTarget} time${sp.weeklyTarget == 1 ? '' : 's'} per week until completed',
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

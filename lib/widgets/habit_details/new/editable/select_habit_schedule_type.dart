import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/dialogs/schedules/set_schedule_dialog.dart';
import 'package:provider/provider.dart';

class SelectHabitScheduleType extends StatelessWidget {
  const SelectHabitScheduleType({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StateProvider>();

    return GestureDetector(
      onTap:
          () => showDialogSheet(
            context: context,
            builder: (context) => SetScheduleDialog(),
          ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: cp.field,
          borderRadius: BorderRadius.circular(24),
        ),
        height: 46,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              sp.scheduleSummary,
              style: TextStyle(color: cp.text, fontSize: 16),
            ),
            SvgPicture.asset(
              "assets/images/new-svg/calendar.svg",
              colorFilter: ColorFilter.mode(cp.lightGreyText, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }
}

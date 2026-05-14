import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/get_duration_string.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/habit_widget/progress_inputs/duration_progress_input.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class EnterHabitDuration extends StatelessWidget {
  const EnterHabitDuration({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StateProvider>();
    final loc = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap:
          () => showDialogSheet(
            context: context,
            builder: (context) {
              return NewDefaultDialog(
                title: loc.setDuration,
                desc: loc.howLongWillThisHabitTake,
                child: DurationProgressInput(
                  duration: sp.habitDuration.inMinutes,
                ),
              );
            },
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            loc.time2,
            style: TextStyle(
              color: cp.lightGreyText,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          Container(
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
                  getDurationString(sp.habitDuration.inMinutes),
                  style: TextStyle(color: cp.text, fontWeight: FontWeight.w500),
                ),
                SvgPicture.asset("assets/images/new-svg/clock.svg"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

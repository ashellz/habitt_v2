import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/dialogs/log_progress_dialog.dart';
import 'package:habitt/widgets/habit_widget/text_icon.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class TimerDialog extends StatelessWidget {
  const TimerDialog({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;
    // TODO all strings need to be translated

    return NewDefaultDialog(
      title: "Start a timer",
      showCloseButton: true,
      overrideDefaultButtons: true,
      tip: "Your can close this screen. The timer will keep running",
      child: Column(
        children: [
          Column(
            spacing: 24,
            children: [
              _timerCircle(cp),
              _timerControls(cp),
              Column(
                spacing: 12,
                children: [
                  NewDefaultButton(
                    width: double.infinity,
                    label: "Complete habit",
                    prefix: Container(
                      height: 24,
                      width: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cp.bg.withValues(alpha: 0.4),
                      ),
                      child: SvgPicture.asset(
                        "assets/images/new-svg/check.svg",
                        colorFilter: ColorFilter.mode(cp.bg, BlendMode.srcIn),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  NewDefaultButton.secondary(
                    width: double.infinity,
                    label: "Log progress",
                    prefix: Container(
                      height: 24,
                      width: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cp.text.withValues(alpha: 0.4),
                      ),
                      child: SvgPicture.asset(
                        "assets/images/new-svg/clock.svg",
                        colorFilter: ColorFilter.mode(cp.bg, BlendMode.srcIn),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      showDialogSheet(
                        context: context,
                        builder: (context) {
                          return LogProgressDialog(
                            progressType: ProgressType.duration,
                            habit: habit,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Row _timerControls(ColorProvider cp) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            Row(
              children: [
                // timer status indicator - red dot
                Container(
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cp.error,
                  ),
                ),
                SizedBox(width: 8),

                Text(
                  "18:24", // TODO timer value
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: cp.text,
                  ),
                ),
                SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    "/30:00", // TODO habit duration
                    style: TextStyle(
                      fontSize: 14,
                      color: cp.isDark ? cp.lightGreyText : cp.greyText,
                    ),
                  ),
                ),
              ],
            ),

            Text(
              "In progress...", // TODO visible only if timer is in progress or paused with text "Paused"
              style: TextStyle(
                fontSize: 14,
                color: cp.isDark ? cp.lightGreyText : cp.greyText,
              ),
            ),
          ],
        ),
        // controls
        Row(
          spacing: 8,
          children: [
            // start or puase timer TODO
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cp.main.withValues(alpha: 0.2),
              ),
              padding: const EdgeInsets.all(6.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: const Alignment(0.09, 0.11),
                    end: const Alignment(0.86, 0.90),
                    colors: [
                      cp.mainButtonLeftGradient,
                      cp.mainButtonRightGradient,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(10),

                child: Center(
                  child: SvgPicture.asset(
                    "assets/images/new-svg/pause-timer.svg", // TODO start-timer.svg if not paused or not started
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ),
            // stop timer TODO
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cp.error.withValues(alpha: 0.1),
              ),
              padding: const EdgeInsets.all(10),
              child: Center(
                child: SvgPicture.asset(
                  "assets/images/new-svg/stop-timer.svg",
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Center _timerCircle(ColorProvider cp) {
    return Center(
      child: Container(
        color: cp.habitBg,
        height: 240,
        width: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 12,
                children: [
                  TextIcon(habit.iconPath, size: 32),
                  Text(
                    habit.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: cp.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/util/show_emoji_dialog.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:habitt/widgets/habit_details/new/schedule_option_widget.dart';
import 'package:habitt/widgets/habit_details/new/select_habit_day_period.dart';
import 'package:habitt/widgets/habit_widget/text_icon.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class AddNewHabitSheet extends StatelessWidget {
  const AddNewHabitSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final stateProvider = context.watch<StateProvider>();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      child: Column(
        spacing: 20,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          topSection(context, cp),
          chooseIcon(cp, stateProvider, context),
          habitDetails(cp),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(
                  'Schedule',
                  style: TextStyle(
                    color: cp.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap:
                    () => showModalBottomSheet(
                      context: context,

                      backgroundColor: Colors.transparent,
                      barrierColor: cp.greyText.darken().withOpacity(0.3),
                      isScrollControlled: true,
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
                        'Daily',
                        style: TextStyle(color: cp.text, fontSize: 16),
                      ),
                      SvgPicture.asset(
                        "assets/images/new-svg/calendar.svg",
                        colorFilter: ColorFilter.mode(
                          cp.lightGreyText,
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Column habitDetails(ColorProvider cp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            'Habit Details',
            style: TextStyle(
              color: cp.text,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        NewDefaultTextField(
          title: "Habit Name",
          hint: "Habit Name",
          controller: TextEditingController(),
        ),
        NewDefaultTextField(
          hint: "Notes",
          maxLines: 4,
          controller: TextEditingController(),
        ),
        SelectHabitDayPeriod(),
      ],
    );
  }

  Column chooseIcon(
    ColorProvider cp,
    StateProvider stateProvider,
    BuildContext context,
  ) {
    return Column(
      spacing: 20,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose icon',
          style: TextStyle(
            color: cp.text,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        NewDefaultButton(
          onPressed: () async {
            final emoji = await showEmojiKeyboardDialog(context, cp);
            if (emoji != null && context.mounted) {
              stateProvider.iconPath = emoji;
            }
          },
          width: 84,
          height: 84,
          color: cp.field,
          padding: EdgeInsets.all(20),
          child: TextIcon(
            stateProvider.iconPath.isEmpty ? "🏀" : stateProvider.iconPath,
            size: 44,
          ),
        ),
      ],
    );
  }

  Padding topSection(BuildContext context, ColorProvider cp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 36, // button height
            width: 66,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Align(
                alignment: Alignment.centerLeft,
                child: SvgPicture.asset("assets/images/new-svg/back.svg"),
              ),
            ),
          ),
          Text(
            'New Habit',
            style: TextStyle(
              color: cp.text,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          NewDefaultButton.small(onPressed: () {}, label: "Done"),
        ],
      ),
    );
  }
}

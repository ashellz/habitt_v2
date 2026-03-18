import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/dialogs/schedules/set_schedule_dialog.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class CustomScheduleDialog extends StatelessWidget {
  const CustomScheduleDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return NewDefaultDialog(
      title: "Custom",
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Repeat every:',
            style: TextStyle(
              color: cp.text,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  "Other day",
                  style: TextStyle(fontSize: 16, color: cp.text),
                ),
                SvgPicture.asset("assets/images/new-svg/dropdown.svg"),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'This habit will appear every other day starting from today',
              style: TextStyle(color: cp.greyText, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

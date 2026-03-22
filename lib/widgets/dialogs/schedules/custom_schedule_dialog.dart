import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/dialogs/schedules/set_schedule_dialog.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class CustomScheduleDialog extends StatelessWidget {
  const CustomScheduleDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StateProvider>();

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
                  'Every ${sp.customIntervalDays} day${sp.customIntervalDays == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 16, color: cp.text),
                ),
                GestureDetector(
                  onTap: () {
                    final next =
                        sp.customIntervalDays == 30
                            ? 1
                            : sp.customIntervalDays + 1;
                    sp.customIntervalDays = next;
                  },
                  child: SvgPicture.asset("assets/images/new-svg/dropdown.svg"),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'This habit will appear every ${sp.customIntervalDays} day${sp.customIntervalDays == 1 ? '' : 's'} starting from today',
              style: TextStyle(color: cp.greyText, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

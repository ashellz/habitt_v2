import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/sheets/edit_habit_sheet.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class AddHabitButton extends StatelessWidget {
  const AddHabitButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: NewDefaultButton.secondary(
        height: 40,
        width: double.infinity,
        label: "Add habit",
        onPressed: () {
          final stateProvider = context.read<StateProvider>();
          stateProvider.reset();

          showModalBottomSheet(
            context: context,
            backgroundColor: cp.isDark ? cp.habitBg : cp.bg,
            barrierColor: cp.greyText.darken().withOpacity(0.3),
            isScrollControlled: true,
            builder: (context) {
              return HabitSheet();
            },
          );
        },
        prefix: SvgPicture.asset(
          "assets/images/new-svg/add.svg",
          colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
        ),
      ),
    );
  }
}

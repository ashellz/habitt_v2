import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/show_new_habit_creation_flow.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:provider/provider.dart';

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
        onPressed: () => showNewHabitCreationFlow(context),
        prefix: SvgPicture.asset(
          "assets/images/new-svg/add.svg",
          colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
        ),
      ),
    );
  }
}

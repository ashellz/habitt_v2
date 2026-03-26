import 'package:cupertino_native/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/new_circle_button.dart';
import 'package:habitt/widgets/main_page/categories/new_categories_list.dart';
import 'package:habitt/widgets/sheets/edit_habit_sheet.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class HabitsPage extends StatelessWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: ListView(
          children: [
            topSection(context, cp),
            NewCategoriesList(padding: null, standardColor: true),
          ],
        ),
      ),
    );
  }

  Padding topSection(BuildContext context, ColorProvider cp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 16.0, right: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Habits List ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cp.text,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          NewCircleButton(
            svgPath: "assets/images/new-svg/plus.svg",
            cnIcon: CNSymbol("plus", size: 16),
            width: 36,
            height: 36,
            textColor: cp.bg,
            padding: EdgeInsets.all(10),
            color: cp.main,
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
          ),
        ],
      ),
    );
  }
}

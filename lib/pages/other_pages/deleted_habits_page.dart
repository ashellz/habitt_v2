import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/pages/main_pages/habits_page.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/widgets/habit_widget/habit_card.dart';
import 'package:provider/provider.dart';

class DeletedHabitsPage extends StatelessWidget {
  const DeletedHabitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final habits =
        context
            .watch<HabitProvider>()
            .habits
            .where((habit) => habit.isDeleted == true)
            .toList();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: cp.isDark ? cp.bg : cp.habitBg,

        child: ListView(
          children: [
            const SizedBox(height: 20),
            topSection(context, cp, false),
            Padding(
              padding: EdgeInsets.only(top: 24, left: 16, right: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardSize = (constraints.maxWidth - 10) / 2;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      for (int index = 0; index < habits.length; index++)
                        HabitCard(
                          deleted: true,
                          key: ValueKey(habits[index].id),
                          habit: habits[index],
                          cp: cp,
                          size: cardSize,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Padding topSection(BuildContext context, ColorProvider cp, bool canSave) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.only(left: 16),
                  color: Colors.transparent,
                  height: 36,
                  width: 66 + 16,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SvgPicture.asset(
                      "assets/images/new-svg/back.svg",
                      colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: SizedBox(width: 66),
              ),
            ],
          ),
          Center(
            child: Text(
              "Recently deleted",
              style: TextStyle(
                color: cp.text,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

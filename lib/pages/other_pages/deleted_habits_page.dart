import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/util/status_overlay_popup.dart';
import 'package:habitt/widgets/habit_widget/habit_card.dart';
import 'package:provider/provider.dart';

class DeletedHabitsPage extends StatefulWidget {
  const DeletedHabitsPage({super.key});

  @override
  State<DeletedHabitsPage> createState() => _DeletedHabitsPageState();
}

class _DeletedHabitsPageState extends State<DeletedHabitsPage>
    with TickerProviderStateMixin {
  late final StatusOverlayPopupController _statusOverlay;

  @override
  void initState() {
    super.initState();
    _statusOverlay = StatusOverlayPopupController(vsync: this);
  }

  @override
  void dispose() {
    _statusOverlay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final habits =
        context
            .watch<HabitProvider>()
            .habits
            .where((habit) => habit.isDeleted == true)
            .toList();

    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: cp.bg,

        child: ListView(
          children: [
            const SizedBox(height: 20),
            topSection(context, cp, false),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                loc.deletedHabitsPageDesc,
                style: TextStyle(
                  color: cp.greyText,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 24, left: 16, right: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardSize = (constraints.maxWidth - 10) / 2;

                  if (habits.isEmpty) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            "assets/images/new-svg/no-trash.svg",
                          ),
                          SizedBox(height: 16),
                          Text(
                            loc.noDeletedHabits,
                            style: TextStyle(
                              color: cp.isDark ? cp.lightGreyText : cp.greyText,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

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
                          onRestored: () {
                            _statusOverlay.show(
                              context: context,
                              cp: cp,
                              title: loc.habitRestored,
                              isError: false,
                            );
                          },
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
              loc.deletedHabits,
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

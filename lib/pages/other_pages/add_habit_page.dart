import 'package:flutter/material.dart';
import 'package:habitt/pages/main_pages/habits_page.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/habits_page/categories/categories_list.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddHabitPage extends StatelessWidget {
  const AddHabitPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorProvider colorProvider = context.watch<ColorProvider>();
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          children: [
            Text(
              localizations.newHabit,
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: colorProvider.colorScheme.darkerStandardColor,
              ),
            ),
            Padding(padding: EdgeInsets.only(top: 8), child: HabitWidget()),
            CategoriesList(
              topPadding: 8,
              showAll: false,
              standardColor: true,
              habitsCount: false,
            ),
          ],
        ),
      ),
    );
  }
}

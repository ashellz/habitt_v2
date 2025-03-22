import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/pages/main_pages/habits_page.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/custom_text_field.dart';
import 'package:habitt/widgets/habits_page/categories/categories_list.dart';
import 'package:habitt/widgets/select_habit_type_options.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddHabitPage extends StatefulWidget {
  const AddHabitPage({super.key});

  @override
  State<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> {
  @override
  void initState() {
    super.initState();
    final categoryProvider = context.read<CategoryProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      categoryProvider.selectCategory(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorProvider colorProvider = context.watch<ColorProvider>();
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Padding(
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
              CustomTextField(
                title: localizations.habitName,
                controller: TextEditingController(),
              ),
              CustomTextField(
                topPadding: 16,
                title: localizations.notes,
                controller: TextEditingController(),
                maxLines: 5,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Row(
                  children: [
                    SvgPicture.asset("assets/images/svg/slider.svg"),
                    Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Text(localizations.moreOptions),
                    ),
                  ],
                ),
              ),

              SelectHabitTypeOptions(),
            ],
          ),
        ),
      ),
    );
  }
}

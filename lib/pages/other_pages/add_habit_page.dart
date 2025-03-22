import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      appBar: AppBar(backgroundColor: Colors.transparent),
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
            CustomTextField(
              title: localizations.habitName,
              controller: TextEditingController(),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.title,
    required this.controller,
    this.maxTextLength = 9999,
  });

  final String title;
  final TextEditingController controller;
  final int maxTextLength;

  @override
  Widget build(BuildContext context) {
    final ColorProvider colorProvider = context.watch<ColorProvider>();

    return Padding(
      padding: EdgeInsets.only(top: 24),
      child: TextFormField(
        textInputAction: TextInputAction.done,
        keyboardAppearance:
            Theme.of(context).brightness == Brightness.dark
                ? Brightness.dark
                : Brightness.light,
        inputFormatters: [LengthLimitingTextInputFormatter(maxTextLength)],
        cursorColor: colorProvider.textColor,
        cursorWidth: 1.0,
        cursorHeight: 20.0,
        cursorRadius: const Radius.circular(12.0),
        cursorOpacityAnimates: true,
        enableInteractiveSelection: true,

        // Main input text style
        style: TextStyle(color: colorProvider.textColor, fontSize: 14),

        // Decoration
        decoration: InputDecoration(
          // Borders
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
            borderSide: BorderSide(
              color: colorProvider.colorScheme.strokeColor,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(
              color: colorProvider.colorScheme.strokeColor,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
            borderSide: BorderSide(
              color: colorProvider.colorScheme.strokeColor,
            ),
          ),

          // Fill color
          filled: true,
          fillColor: colorProvider.standardColor,

          // Content padding
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),

          //Label (Title)
          labelStyle: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: colorProvider.textColor,
          ),
          labelText: title,
        ),
      ),
    );
  }
}

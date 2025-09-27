import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/additional_task_switch.dart';
import 'package:habitt/widgets/custom_switcher_wrapper.dart';
import 'package:habitt/widgets/custom_text_field.dart';
import 'package:habitt/widgets/default_button.dart';
import 'package:habitt/widgets/default_dialog.dart';
import 'package:habitt/widgets/delete_habit_dialog.dart';
import 'package:habitt/widgets/gradient_background.dart';
import 'package:habitt/widgets/habits_page/categories/categories_list.dart';
import 'package:habitt/widgets/more_options_text.dart';
import 'package:habitt/widgets/nav_back_button.dart';
import 'package:habitt/widgets/select_habit_type_options.dart';
import 'package:habitt/widgets/selected_habit_display.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class EditHabitPage extends StatefulWidget {
  const EditHabitPage({super.key, required this.habit});

  final Habit habit;

  @override
  State<EditHabitPage> createState() => _EditHabitPageState();
}

class _EditHabitPageState extends State<EditHabitPage> {
  Duration initialDuration = Duration.zero;
  int initialAmount = 1;
  bool showButtons = false;

  void setInitialValues() {
    final stateProvider = context.read<StateProvider>();

    initialDuration = Duration(minutes: widget.habit.duration);
    initialAmount = widget.habit.amount;

    stateProvider.habitCategoryId = widget.habit.categoryId;
    stateProvider.nameController.text = widget.habit.name;
    stateProvider.descController.text = widget.habit.description;
    stateProvider.habitAmount = widget.habit.amount;
    stateProvider.habitDuration = Duration(minutes: widget.habit.duration);
    stateProvider.habitAmountLabelController.text = widget.habit.amountLabel;
    stateProvider.iconPath = widget.habit.iconPath;
    stateProvider.isAdditional = widget.habit.additional;
  }

  @override
  void initState() {
    super.initState();
    final stateProvider = context.read<StateProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Sets initial habit amount and duration
      initialDuration = Duration(minutes: widget.habit.duration);
      initialAmount = widget.habit.amount;

      // Loads habit values
      stateProvider.habitCategoryId = widget.habit.categoryId;
      stateProvider.nameController.text = widget.habit.name;
      stateProvider.descController.text = widget.habit.description;
      stateProvider.habitAmount = widget.habit.amount;
      stateProvider.habitDuration = Duration(minutes: widget.habit.duration);
      stateProvider.habitAmountLabelController.text = widget.habit.amountLabel;
      stateProvider.iconPath = widget.habit.iconPath;
      stateProvider.isAdditional = widget.habit.additional;
    });
  }

  bool getShowButtonsValue(
    StateProvider stateProvider,
    TextEditingController nameController,
    TextEditingController descController,
  ) {
    return stateProvider.habitCategoryId != widget.habit.categoryId ||
        nameController.text != widget.habit.name ||
        descController.text != widget.habit.description ||
        stateProvider.habitAmount != widget.habit.amount ||
        stateProvider.habitDuration !=
            Duration(minutes: widget.habit.duration) ||
        stateProvider.habitAmountLabelController.text !=
            widget.habit.amountLabel ||
        stateProvider.iconPath != widget.habit.iconPath ||
        stateProvider.isAdditional != widget.habit.additional;
  }

  @override
  Widget build(BuildContext context) {
    final ColorProvider colorProvider = context.watch<ColorProvider>();
    final localizations = AppLocalizations.of(context)!;

    final stateProvider = context.watch<StateProvider>();
    final nameController = stateProvider.nameController;
    final descController = stateProvider.descController;

    showButtons = getShowButtonsValue(
      stateProvider,
      nameController,
      descController,
    );

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: colorProvider.backgroundColor,
        statusBarIconBrightness:
            colorProvider.isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            colorProvider.isDarkMode
                ? Brightness.dark
                : Brightness.light, // for iOS
      ),
      child: Scaffold(
        backgroundColor: colorProvider.backgroundColor,
        body: GradientBackground(
          child: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      NavBackButton(colorProvider: colorProvider),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: GestureDetector(
                          onTap:
                              () => showDialog(
                                context: context,
                                builder:
                                    (context) =>
                                        DeleteHabitDialog(widget: widget),
                              ),
                          child: Icon(
                            Icons.delete,
                            color: colorProvider.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    localizations.editHabit,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: colorProvider.colorScheme.vividColor,
                    ),
                  ),
                  SelectedHabitDisplay(
                    completed: widget.habit.completed,
                    amountCompleted: widget.habit.amountCompleted,
                    durationCompleted: widget.habit.durationCompleted,
                    streak: widget.habit.streak,
                  ),
                  CategoriesList(
                    useHabitCategory: true,
                    topPadding: 16,
                    showAll: false,
                    standardColor: true,
                    habitsCount: false,
                  ),
                  CustomTextField(
                    title: localizations.habitName,
                    controller: nameController,
                  ),
                  CustomTextField(
                    topPadding: 16,
                    title: localizations.notes,
                    controller: descController,
                    maxLines: 5,
                  ),
                  MoreOptionsText(localizations: localizations),
                  SelectHabitTypeOptions(),
                  AdditionalTaskSwitch(
                    colorProvider: colorProvider,
                    stateProvider: stateProvider,
                  ),
                  CustomSwitcherWrapper(
                    value: showButtons,
                    widget: Row(
                      key: const ValueKey("value"),
                      children: [
                        Expanded(
                          child: DefaultButton(
                            onPressed:
                                () => showDialog(
                                  context: context,
                                  builder:
                                      (context) => DefaultDialog(
                                        title: "Reset changes?",
                                        desc:
                                            "All changes you've made now will be reset.",
                                        content: Row(
                                          children: [
                                            Expanded(
                                              child: DefaultButton(
                                                label: "Cancel",
                                                outlined: true,
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            Expanded(
                                              child: DefaultButton(
                                                label: "Reset",
                                                onPressed: () {
                                                  setInitialValues();
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                ),
                            label: "Reset",
                            outlined: true,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: EditHabitButton(
                            nameController: nameController,
                            stateProvider: stateProvider,
                            initialAmount: initialAmount,
                            widget: widget,
                            initialDuration: initialDuration,
                            descController: descController,
                            localizations: localizations,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EditHabitButton extends StatelessWidget {
  const EditHabitButton({
    super.key,
    required this.nameController,
    required this.stateProvider,
    required this.initialAmount,
    required this.widget,
    required this.initialDuration,
    required this.descController,
    required this.localizations,
  });

  final TextEditingController nameController;
  final StateProvider stateProvider;
  final int initialAmount;
  final EditHabitPage widget;
  final Duration initialDuration;
  final TextEditingController descController;
  final AppLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    bool canEditHabit() {
      return nameController.text.isNotEmpty;
    }

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: nameController,
      builder:
          (context, value, child) => DefaultButton(
            enabled: canEditHabit(),
            onPressed: () {
              if (!canEditHabit()) return;

              // Edit habit in state and database
              final HabitProvider habitProvider = context.read<HabitProvider>();

              // Checks for amount/duration changes

              if (stateProvider.habitAmount != initialAmount) {
                widget.habit.resetCompletion();
                widget.habit.amount = stateProvider.habitAmount;
              } else if (stateProvider.habitDuration != initialDuration) {
                widget.habit.resetCompletion();
                widget.habit.duration = stateProvider.habitDuration.inMinutes;
              }

              widget.habit.name = nameController.text;
              widget.habit.description = descController.text;
              widget.habit.categoryId = stateProvider.habitCategoryId;
              widget.habit.amountLabel =
                  stateProvider.habitAmountLabelController.text;
              widget.habit.iconPath = stateProvider.iconPath;
              widget.habit.additional = stateProvider.isAdditional;

              habitProvider.updateHabit(widget.habit);

              Navigator.of(context).pop();

              stateProvider.alertText = "Changes saved!";
              stateProvider.toggleAlert(show: true);
            },
            label: localizations.saveChanges,
          ),
    );
  }
}

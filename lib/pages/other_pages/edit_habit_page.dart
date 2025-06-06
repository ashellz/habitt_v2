import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/custom_text_field.dart';
import 'package:habitt/widgets/default_button.dart';
import 'package:habitt/widgets/default_dialog.dart';
import 'package:habitt/widgets/habits_page/categories/categories_list.dart';
import 'package:habitt/widgets/more_options_text.dart';
import 'package:habitt/widgets/nav_back_button.dart';
import 'package:habitt/widgets/select_habit_type_options.dart';
import 'package:habitt/widgets/selected_habit_display.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditHabitPage extends StatefulWidget {
  const EditHabitPage({super.key, required this.habit});

  final Habit habit;

  @override
  State<EditHabitPage> createState() => _EditHabitPageState();
}

class _EditHabitPageState extends State<EditHabitPage> {
  bool shouldReset = true;
  Duration initialDuration = Duration.zero;
  int initialAmount = 1;

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorProvider colorProvider = context.watch<ColorProvider>();
    final localizations = AppLocalizations.of(context)!;

    final stateProvider = context.watch<StateProvider>();
    final nameController = stateProvider.nameController;
    final descController = stateProvider.descController;

    return Scaffold(
      backgroundColor: colorProvider.backgroundColor,
      body: GestureDetector(
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
                                (context) => DeleteHabitDialog(widget: widget),
                          ),
                      child: Icon(Icons.delete, color: colorProvider.textColor),
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
                topPadding: 8,
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
              EditHabitButton(
                nameController: nameController,
                stateProvider: stateProvider,
                initialAmount: initialAmount,
                widget: widget,
                initialDuration: initialDuration,
                descController: descController,
                localizations: localizations,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeleteHabitDialog extends StatelessWidget {
  const DeleteHabitDialog({super.key, required this.widget});

  final EditHabitPage widget;

  @override
  Widget build(BuildContext context) {
    return DefaultDialog(
      danger: true,
      title: "Delete '${widget.habit.name}'?",
      desc: "Are you sure you want to delete this habit?",
      content: Row(
        children: [
          Expanded(
            child: DefaultButton(
              danger: true,
              outlined: true,
              onPressed: () => Navigator.pop(context),
              label: "Cancel",
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: DefaultButton(
              danger: true,
              onPressed: () {
                context.read<HabitProvider>().removeHabit(widget.habit);
                Navigator.pop(context);
                Navigator.pop(context);
                Future.delayed(Duration(milliseconds: 150)).then((value) {
                  if (!context.mounted) {
                    debugPrint("context not mounted");
                    return;
                  }
                  showGeneralDialog(
                    context: context,
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return const SizedBox.shrink(); // Content handled by transitionBuilder
                    },
                    transitionBuilder: (
                      context,
                      animation,
                      secondaryAnimation,
                      child,
                    ) {
                      return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(
                                begin: 0.5,
                                end: 1.0,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutBack,
                                ),
                              ),
                              child: DefaultDialog(
                                title: "Success!",
                                desc: "Habit has been deleted successfully.",
                                content: DefaultButton(
                                  onPressed: () => Navigator.pop(context),
                                  label: "Close",
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .fade(
                            begin: 0.0,
                            end: 1.0,
                            curve: Curves.easeOut,
                            duration: 300.ms,
                          )
                          .scale(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1.0, 1.0),
                            curve: Curves.easeOutBack,
                            duration: 300.ms,
                          );
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                    barrierDismissible: true,
                    barrierLabel:
                        MaterialLocalizations.of(
                          context,
                        ).modalBarrierDismissLabel,
                    barrierColor: Colors.black54,
                  );
                });
              },
              label: "Delete",
            ),
          ),
        ],
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
              final CategoryProvider categoryProvider =
                  context.read<CategoryProvider>();

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
              widget.habit.categoryId = categoryProvider.selectedCategoryId;
              widget.habit.amountLabel =
                  stateProvider.habitAmountLabelController.text;
              widget.habit.iconPath = stateProvider.iconPath;

              habitProvider.updateHabit(widget.habit);

              Navigator.of(context).pop();
            },
            label: localizations.saveChanges,
          ),
    );
  }
}

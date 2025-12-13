import 'package:cupertino_native/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/blur_circle_button.dart';
import 'package:habitt/widgets/habit_details/additional_task_switch.dart';
import 'package:habitt/widgets/default/custom_switcher_wrapper.dart';
import 'package:habitt/widgets/default/default_text_field.dart';
import 'package:habitt/widgets/default/default_annotated_region.dart';
import 'package:habitt/widgets/default/default_button.dart';
import 'package:habitt/widgets/default/default_dialog.dart';
import 'package:habitt/widgets/dialogs/delete_habit_dialog.dart';
import 'package:habitt/widgets/default/discard_changes_dialog.dart';
import 'package:habitt/widgets/habit_details/edit_habit_button.dart';
import 'package:habitt/widgets/default/gradient_background.dart';
import 'package:habitt/widgets/habit_details/scheduling_and_alerts.dart';
import 'package:habitt/widgets/habits_page/categories/categories_list.dart';
import 'package:habitt/widgets/habit_details/more_options_text.dart';
import 'package:habitt/widgets/default/nav_back_button.dart';
import 'package:habitt/widgets/habit_details/select_habit_type_options.dart';
import 'package:habitt/widgets/habit_details/selected_habit_display.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class EditHabitPage extends StatefulWidget {
  const EditHabitPage({super.key, required this.habit});

  final Habit habit;

  @override
  State<EditHabitPage> createState() => _EditHabitPageState();
}

class _EditHabitPageState extends State<EditHabitPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  Duration initialDuration = Duration.zero;
  int initialAmount = 1;
  bool showButtons = false;

  void setInitialValues() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stateProvider = context.read<StateProvider>();
      final tp = context.read<ThemeProvider>();
      stateProvider.selectedHabitId = widget.habit.id;
      stateProvider.habitCategoryId = widget.habit.categoryId;
      stateProvider.nameController.text = widget.habit.name;
      stateProvider.descController.text = widget.habit.description;
      stateProvider.habitAmount = widget.habit.amount;
      stateProvider.habitDuration = Duration(minutes: widget.habit.duration);
      stateProvider.habitAmountLabelController.text = widget.habit.amountLabel;
      stateProvider.iconPath = widget.habit.iconPath;
      stateProvider.isAdditional = widget.habit.additional;
      stateProvider.timeIntervalEnabled = widget.habit.timeIntervalEnabled;
      stateProvider.timeIntervalStart = widget.habit.timeIntervalStart;
      stateProvider.timeIntervalEnd = widget.habit.timeIntervalEnd;
      stateProvider.habitColorName = widget.habit.colorName;
      stateProvider.habitColor = widget.habit.resolveColor(tp);
    });

    initialDuration = Duration(minutes: widget.habit.duration);
    initialAmount = widget.habit.amount;

    _nameController.text = widget.habit.name;
    _descController.text = widget.habit.description;
  }

  void _recomputeShowButtons() {
    final stateProvider = context.read<StateProvider>();
    final changedName = _nameController.text.trim() != widget.habit.name;
    final changedDesc = _descController.text.trim() != widget.habit.description;
    final changedCategory =
        stateProvider.habitCategoryId != widget.habit.categoryId;
    final changedDuration =
        stateProvider.habitDuration.inMinutes != initialDuration.inMinutes;
    final changedAmount = stateProvider.habitAmount != initialAmount;
    final changedAdditionalTask =
        stateProvider.isAdditional != widget.habit.additional;
    final changedIcon = stateProvider.iconPath != widget.habit.iconPath;
    final changedTimeIntervalEnabled =
        stateProvider.timeIntervalEnabled != widget.habit.timeIntervalEnabled;
    final changedTimeIntervalStart =
        stateProvider.timeIntervalStart != widget.habit.timeIntervalStart;
    final changedTimeIntervalEnd =
        stateProvider.timeIntervalEnd != widget.habit.timeIntervalEnd;
    final changedHabitColor =
        stateProvider.getHabitColor !=
            widget.habit.resolveColor(context.read<ThemeProvider>()) ||
        stateProvider.habitColorName != widget.habit.colorName;

    final newValue =
        changedName ||
        changedDesc ||
        changedCategory ||
        changedDuration ||
        changedAmount ||
        changedAdditionalTask ||
        changedIcon ||
        changedTimeIntervalEnabled ||
        changedTimeIntervalStart ||
        changedTimeIntervalEnd ||
        changedHabitColor;

    if (newValue != showButtons) {
      setState(() {
        showButtons = newValue;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    setInitialValues();

    _nameController.addListener(_recomputeShowButtons);
    _descController.addListener(_recomputeShowButtons);
  }

  @override
  void dispose() {
    _nameController.removeListener(_recomputeShowButtons);
    _descController.removeListener(_recomputeShowButtons);
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  bool getShowButtonsValue(TextEditingController descController) {
    return showButtons;
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final localizations = AppLocalizations.of(context)!;

    final platform = Theme.of(context).platform;
    final double extraPadding = platform == TargetPlatform.android ? 12 : 0;

    final stateProvider = context.watch<StateProvider>();

    // Call recompute if provider-driven fields changed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recomputeShowButtons();
    });

    return PopScope(
      canPop: !showButtons,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        // User tried to pop but we prevented it, show dialog
        showDialog(
          context: context,
          builder: (context) => DiscardChangesDialog(),
        );
      },
      child: DefaultAnnotatedRegion(
        child: Scaffold(
          backgroundColor: tp.backgroundColor,
          body: GradientBackground(
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Stack(
                  children: [
                    ListView(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            NavBackButton(
                              tp: tp,
                              onPressed: () {
                                // check if there are unsaved changes
                                if (showButtons) {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => DiscardChangesDialog(),
                                  );
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                            ),

                            Padding(
                              padding: const EdgeInsets.only(bottom: 30),
                              child: CircleButton(
                                cnIcon: CNSymbol('trash.fill', size: 16),
                                color: tp.surfaceColor,
                                tp: tp,
                                onPressed:
                                    () => showDialog(
                                      context: context,
                                      builder:
                                          (context) =>
                                              DeleteHabitDialog(widget: widget),
                                    ),
                                icon: Icon(
                                  Icons.delete,
                                  color: tp.primaryTextColor,
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
                            color: tp.primaryColor,
                          ),
                        ),
                        SelectedHabitDisplay(
                          completed: widget.habit.completed,
                          amountCompleted: widget.habit.amountCompleted,
                          durationCompleted: widget.habit.durationCompleted,
                          streak: widget.habit.streak,
                          skipped: widget.habit.skipped,
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
                          controller: _nameController,
                        ),
                        CustomTextField(
                          topPadding: 16,
                          title: localizations.notes,
                          controller: _descController,
                          maxLines: 5,
                        ),
                        MoreOptionsText(localizations: localizations),
                        SelectHabitTypeOptions(),
                        SchedulingAndAlerts(tp: tp),
                        AdditionalTaskSwitch(
                          tp: tp,
                          stateProvider: stateProvider,
                        ),
                        SizedBox(height: 56 + extraPadding),
                      ],
                    ),
                    Positioned(
                      bottom:
                          MediaQuery.of(context).padding.bottom +
                          extraPadding, // bottom safe area
                      left: 0,
                      right: 0,
                      child: CustomSwitcherWrapper(
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
                                                        () => Navigator.pop(
                                                          context,
                                                        ),
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
                                nameController: _nameController,
                                stateProvider: stateProvider,
                                initialAmount: initialAmount,
                                widget: widget,
                                initialDuration: initialDuration,
                                descController: _descController,
                                localizations: localizations,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

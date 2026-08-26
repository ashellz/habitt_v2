import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/health_workout_type.dart';
import 'package:habitt/models/premade_habit_template.dart';
import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/health_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/premade_habit_catalog.dart';
import 'package:habitt/util/get_duration_string.dart';
import 'package:habitt/util/health_workout_amount_label.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/dual_option_selector.dart';
import 'package:habitt/widgets/default/multiple_option_selector.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/new_default_switch.dart';
import 'package:habitt/widgets/dialogs/healt_metric_picker_dialog.dart';
import 'package:habitt/widgets/dialogs/health_time_of_day_dialog.dart';
import 'package:habitt/widgets/dialogs/workout_type_picker_dialog.dart';
import 'package:habitt/widgets/habit_details/new/editable/enter_habit_duration.dart';
import 'package:habitt/widgets/habit_details/new/editable/select_habit_type_widgets.dart';
import 'package:habitt/widgets/habit_widget/progress_inputs/amount_progress_input.dart';
import 'package:habitt/widgets/habit_widget/text_icon.dart';
import 'package:provider/provider.dart';

class HealthWidget extends StatefulWidget {
  const HealthWidget({super.key, this.habit});

  final Habit? habit;

  @override
  State<HealthWidget> createState() => _HealthWidgetState();
}

class _HealthWidgetState extends State<HealthWidget> {
  Widget _appIcon() {
    if (Platform.isIOS) {
      return SvgPicture.asset(
        "assets/images/widget-images/apple-health.svg",
        width: 46,
        height: 46,
      );
    }
    return Image.asset(
      "assets/images/widget-images/health-connect.png",
      width: 46,
      height: 46,
    );
  }

  PremadeHabitTemplate? _selectedTemplate(StateProvider sp) {
    final type = sp.selectedPremadeHabitType;
    return type != null ? PremadeHabitCatalog.byType(type) : null;
  }

  Future<void> _handleToggle(bool value) async {
    final sp = context.read<StateProvider>();
    final healthProvider = context.read<HealthProvider>();
    final loc = AppLocalizations.of(context)!;

    if (!value) {
      sp.selectedHealthMetric = null;
      sp.selectedHealthWorkoutFilter = null;
      return;
    }

    final granted = await healthProvider.requestPermissionIfNeeded();
    if (!mounted) return;
    if (!granted) {
      await _showHealthPermissionDeniedDialog(loc);
      return;
    }

    final fixedMetric = _selectedTemplate(sp)?.defaultHealthMetric;
    if (fixedMetric != null) {
      sp.selectedHealthMetric = fixedMetric;
      sp.selectedHealthWorkoutFilter =
          _selectedTemplate(sp)?.defaultWorkoutFilter;
      return;
    }

    if (!mounted) return;
    await _openMetricPicker(healthProvider);
  }

  Future<void> _openMetricPicker(HealthProvider healthProvider) async {
    await showDialogSheet(
      context: context,
      builder:
          (_) => HealthMetricPickerDialog(
            metrics: healthProvider.supportedMetrics,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StateProvider>();
    final healthProvider = context.watch<HealthProvider>();
    final loc = AppLocalizations.of(context)!;

    if (!Platform.isIOS && !Platform.isAndroid) return const SizedBox.shrink();
    if (!healthProvider.isAvailable) return const SizedBox.shrink();

    final selectedTemplate = _selectedTemplate(sp);
    final isFixedByTemplate = selectedTemplate?.defaultHealthMetric != null;
    final metric = sp.selectedHealthMetric;
    final enabled = metric != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cp.field,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 10,
            children: [
              SizedBox(width: 46, child: _appIcon()),
              Expanded(
                child: Column(
                  spacing: 8,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Platform.isIOS
                          ? loc.healthSyncSectionTitleApple
                          : loc.healthSyncSectionTitleAndroid,
                      style: TextStyle(
                        color: cp.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      Platform.isIOS
                          ? loc.healthSyncSectionDescApple
                          : loc.healthSyncSectionDescAndroid,
                      style: TextStyle(color: cp.lightGreyText, fontSize: 13),
                    ),
                  ],
                ),
              ),
              NewDefaultSwitch(value: enabled, onChanged: _handleToggle),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder:
                (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(sizeFactor: animation, child: child),
                ),
            child:
                !enabled
                    ? const SizedBox.shrink()
                    : Column(
                      key: ValueKey('health-body-${metric.name}'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: _metricPickerPill(cp, sp, healthProvider),
                        ),
                        _bodyForMetric(cp, sp, metric),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _metricPickerPill(
    ColorProvider cp,
    StateProvider sp,
    HealthProvider healthProvider,
  ) {
    final loc = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => _openMetricPicker(healthProvider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: cp.isDark ? cp.habitBg : cp.bg,
          borderRadius: BorderRadius.circular(24),
        ),
        height: 46,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              spacing: 10,
              children: [
                Image.asset(
                  sp.selectedHealthMetric!.iconPath,
                  width: 22,
                  height: 22,
                ),
                Text(
                  sp.selectedHealthMetric!.label(loc),
                  style: TextStyle(color: cp.text, fontSize: 16),
                ),
              ],
            ),
            RotatedBox(
              quarterTurns: 3,
              child: SvgPicture.asset(
                "assets/images/new-svg/dropdown.svg",
                colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bodyForMetric(
    ColorProvider cp,
    StateProvider sp,
    HealthMetricType metric,
  ) {
    switch (metric) {
      case HealthMetricType.bedtime:
      case HealthMetricType.wakeTime:
        return _timeOfDayBody(cp, sp, metric);
      case HealthMetricType.sleep:
        return _sleepBody(cp, sp);
      case HealthMetricType.workouts:
      case HealthMetricType.mindfulness:
        return _workoutOrMindfulnessBody(cp, sp, metric);
      case HealthMetricType.steps:
      case HealthMetricType.activeCalories:
      case HealthMetricType.totalCalories:
        return _stepsOrCaloriesBody(sp, cp);
    }
  }

  Widget _stepsOrCaloriesBody(StateProvider sp, ColorProvider cp) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: AmountProgressInput(
        amount: sp.habitAmount,
        minValue: 1,
        color: cp.isDark ? cp.habitBg : cp.bg,
      ),
    );
  }

  Widget _workoutOrMindfulnessBody(
    ColorProvider cp,
    StateProvider sp,
    HealthMetricType metric,
  ) {
    final loc = AppLocalizations.of(context)!;
    final isWorkout = metric == HealthMetricType.workouts;
    final trackingType = sp.selectedHabitTrackingType;
    final isAmountMode = trackingType == HabitTrackingType.amount;

    final selectedHabitType = switch (trackingType) {
      HabitTrackingType.amount => HabitType.amount,
      HabitTrackingType.duration => HabitType.duration,
      _ => null,
    };

    if (isAmountMode) {
      final expectedLabel =
          isWorkout
              ? healthWorkoutAmountLabel(
                sp.selectedHealthWorkoutFilter,
                sp.habitAmount,
                loc,
              )
              : healthMindfulnessAmountLabel(sp.habitAmount, loc);
      if (sp.habitAmountLabelController.text != expectedLabel) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          sp.habitAmountLabelController.text = expectedLabel;
        });
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          DualOptionSelector<HabitType>(
            showDeselectHint: true,
            allowDeselect: true,
            color: cp.isDark ? cp.habitBg : cp.bg,
            firstLabel: loc.amount,
            firstValue: HabitType.amount,
            secondLabel: loc.duration,
            secondValue: HabitType.duration,
            selectedValue: selectedHabitType,
            onSelect: (value) {
              sp.selectedHabitTrackingType = switch (value) {
                HabitType.amount => HabitTrackingType.amount,
                HabitType.duration => HabitTrackingType.duration,
                _ => null,
              };
            },
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder:
                  (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
              child: KeyedSubtree(
                key: ValueKey(
                  'health-tracking-${selectedHabitType?.name ?? 'none'}',
                ),
                child: switch (trackingType) {
                  HabitTrackingType.amount => _workoutOrMindfulnessAmountRow(
                    cp,
                    sp,
                    loc,
                    isWorkout,
                  ),
                  HabitTrackingType.duration => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      EnterHabitDuration(color: cp.isDark ? cp.habitBg : cp.bg),
                      if (isWorkout) _workoutTypeSelector(cp, sp, loc),
                    ],
                  ),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _workoutOrMindfulnessAmountRow(
    ColorProvider cp,
    StateProvider sp,
    AppLocalizations loc,
    bool isWorkout,
  ) {
    final stepper = AmountProgressInput(
      amount: sp.habitAmount,
      minValue: 0,
      color: cp.isDark ? cp.habitBg : cp.bg,
    );

    if (!isWorkout) {
      return stepper;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Expanded(child: stepper),
        Expanded(child: _workoutTypeSelector(cp, sp, loc)),
      ],
    );
  }

  Widget _workoutTypeSelector(
    ColorProvider cp,
    StateProvider sp,
    AppLocalizations loc,
  ) {
    final selected = sp.selectedHealthWorkoutFilter;
    // Same emoji the picker shows for this type, not the Material IconData
    // used elsewhere — keeps the collapsed pill and the picker in sync.
    final iconPath =
        PremadeHabitCatalog.byHealthConfig(
          HealthMetricType.workouts,
          selected,
        )?.iconPath ??
        PremadeHabitCatalog.byType(PremadeHabitType.workoutCombined)!.iconPath;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(
          loc.premadeHabitWorkoutCombined,
          style: TextStyle(
            color: cp.lightGreyText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: () => _openWorkoutTypePicker(sp),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cp.isDark ? cp.habitBg : cp.bg,
              borderRadius: BorderRadius.circular(24),
            ),
            height: 46,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  spacing: 10,
                  children: [
                    TextIcon(iconPath, size: 22),
                    Text(
                      selected == null
                          ? loc.healthWorkoutFilterAny
                          : selected.label(loc),
                      style: TextStyle(color: cp.text, fontSize: 16),
                    ),
                  ],
                ),
                RotatedBox(
                  quarterTurns: 3,
                  child: SvgPicture.asset(
                    "assets/images/new-svg/dropdown.svg",
                    colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openWorkoutTypePicker(StateProvider sp) async {
    await showDialogSheet(
      context: context,
      builder:
          (_) => WorkoutTypePickerDialog(
            selected: sp.selectedHealthWorkoutFilter,
            onSelected: (type) {
              sp.selectedHealthWorkoutFilter = type;

              sp.selectedPremadeHabitType =
                  PremadeHabitCatalog.byHealthConfig(
                    HealthMetricType.workouts,
                    type,
                  )?.type;
            },
          ),
    );
  }

  Widget _timeOfDayBody(
    ColorProvider cp,
    StateProvider sp,
    HealthMetricType metric,
  ) {
    final loc = AppLocalizations.of(context)!;
    final isBedtime = metric == HealthMetricType.bedtime;
    final targetTime = _minutesOfDayToTimeOfDay(sp.habitAmount);
    final materialLoc = MaterialLocalizations.of(context);
    final label =
        isBedtime ? loc.healthTargetBedtime : loc.healthTargetWakeTime;

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          _targetRow(
            cp,
            label: label,
            valueText: materialLoc.formatTimeOfDay(targetTime),
            onTap: () async {
              await showHealthTimeOfDayDialog(
                context: context,
                initialMinutes: targetTime.hour * 60 + targetTime.minute,
                title: label,
                onSaved: (rawMinutes) {
                  sp.habitAmount =
                      isBedtime
                          ? _bedtimeMinutesOfDay(
                            TimeOfDay(
                              hour: rawMinutes ~/ 60,
                              minute: rawMinutes % 60,
                            ),
                          )
                          : rawMinutes;
                },
              );
            },
          ),
          _toleranceRow(cp, sp, metric),
        ],
      ),
    );
  }

  Widget _sleepBody(ColorProvider cp, StateProvider sp) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          _targetRow(
            cp,
            label: loc.healthMetricSleep,
            valueText: getDurationString(sp.habitAmount * 60),
            onTap: () async {
              await showHealthTimeOfDayDialog(
                context: context,
                initialMinutes: sp.habitAmount,
                title: loc.healthMetricSleep,
                onSaved: (rawMinutes) {
                  sp.habitAmount = rawMinutes;
                },
              );
            },
          ),
          _toleranceRow(cp, sp, HealthMetricType.sleep),
        ],
      ),
    );
  }

  Widget _targetRow(
    ColorProvider cp, {
    required String label,
    required String valueText,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: cp.text,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        NewDefaultButton(
          height: 46,
          color: cp.isDark ? cp.habitBg : cp.bg,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onPressed: onTap,
          child: Text(
            valueText,
            style: TextStyle(
              color: cp.text,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _toleranceRow(
    ColorProvider cp,
    StateProvider sp,
    HealthMetricType metric,
  ) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        MultipleOptionSelector<int>(
          bgColor: cp.isDark ? cp.habitBg : cp.bg,
          labels: [
            loc.healthToleranceLoose,
            loc.healthToleranceRegular,
            loc.healthToleranceStrict,
          ],
          values: const [60, 30, 15],
          selectedValue: sp.toleranceMinutes,
          onSelect: (value) {
            if (value != null) sp.toleranceMinutes = value;
          },
          allowDeselect: false,
        ),
        Text(
          _toleranceDescription(loc, metric, sp.toleranceMinutes),
          style: TextStyle(color: cp.lightGreyText, fontSize: 12),
        ),
      ],
    );
  }

  String _toleranceDescription(
    AppLocalizations loc,
    HealthMetricType metric,
    int minutes,
  ) {
    final duration =
        minutes >= 60
            ? loc.healthToleranceHourValue
            : loc.healthToleranceMinutesValue(minutes);
    switch (metric) {
      case HealthMetricType.bedtime:
        return loc.healthToleranceDescBedtime(duration);
      case HealthMetricType.wakeTime:
        return loc.healthToleranceDescWakeTime(duration);
      case HealthMetricType.sleep:
        return loc.healthToleranceDescSleep(duration);
      default:
        return '';
    }
  }

  Future<void> _showHealthPermissionDeniedDialog(AppLocalizations loc) async {
    await showDialogSheet(
      context: context,
      builder:
          (dialogContext) => NewDefaultDialog(
            title:
                Platform.isIOS
                    ? loc.healthSyncSectionTitleApple
                    : loc.healthSyncSectionTitleAndroid,
            desc: loc.healthPermissionDeniedMessage,
            showSecondaryButton: false,
            primaryButtonLabel: loc.gotIt,
          ),
    );
  }
}

int _bedtimeMinutesOfDay(TimeOfDay time) {
  final minutes = time.hour * 60 + time.minute;
  return minutes < 12 * 60 ? minutes + 24 * 60 : minutes;
}

TimeOfDay _minutesOfDayToTimeOfDay(int minutes) {
  final normalized = minutes % (24 * 60);
  return TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
}

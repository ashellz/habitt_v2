import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/habit_notification_time.dart';
import 'package:habitt/models/premade_habit_template.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/services/premade_habit_catalog.dart';
import 'package:habitt/services/emoji_service.dart';
import 'package:habitt/services/notification_service.dart';
import 'package:habitt/util/amount_label_preset.dart';
import 'package:habitt/util/color_converting.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/util/show_emoji_dialog.dart';
import 'package:habitt/util/status_overlay_popup.dart';
import 'package:habitt/widgets/default/animated_checkbox.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:habitt/widgets/default/new_default_switch.dart';
import 'package:habitt/widgets/dialogs/override_current_config_dialog.dart';
import 'package:habitt/widgets/habit_details/new/editable/dialogs/delete_notification_dialog.dart';
import 'package:habitt/widgets/habit_details/new/editable/select_habit_day_period.dart';
import 'package:habitt/widgets/habit_details/new/editable/select_habit_schedule_type.dart';
import 'package:habitt/widgets/habit_details/new/editable/select_habit_type_widgets.dart';
import 'package:habitt/widgets/habit_widget/text_icon.dart';
import 'package:habitt/widgets/notification/notification_time_row.dart';
import 'package:habitt/widgets/sheets/premade_habits_sheet.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';
import 'package:habitt/l10n/app_localizations.dart';

enum HabitSheetCloseResult { saved, dismissed, reopenPremade }

class HabitSheet extends StatefulWidget {
  const HabitSheet({
    super.key,
    this.habit,
    this.initialPremadeTemplate,
    this.reopenPremadeOnTopBack = false,
  });

  final Habit? habit;
  final PremadeHabitTemplate? initialPremadeTemplate;
  final bool reopenPremadeOnTopBack;

  @override
  State<HabitSheet> createState() => _HabitSheetState();
}

class _HabitSheetState extends State<HabitSheet> with TickerProviderStateMixin {
  late final VoidCallback _nameListener;
  late final VoidCallback _descListener;
  late final StateProvider _sp;
  late final StatusOverlayPopupController _statusOverlay;
  bool _allowPop = false;
  bool _isExitDialogOpen = false;
  bool _isInitializing = true;
  int? heldNotificationId;
  ScrollController scrollController = ScrollController();

  bool get _isEditMode => widget.habit != null;

  @override
  void initState() {
    super.initState();

    _sp = context.read<StateProvider>();
    _statusOverlay = StatusOverlayPopupController(vsync: this);

    _nameListener = () {
      if (mounted && !_isInitializing) {
        setState(() {});
      }
    };
    _descListener = () {
      if (mounted && !_isInitializing) {
        setState(() {});
      }
    };
    _sp.nameController.addListener(_nameListener);
    _sp.descController.addListener(_descListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (_isEditMode) {
        _setEditInitialValues(_sp, widget.habit!);
      } else {
        _sp.reset();
        final initialTemplate = widget.initialPremadeTemplate;
        if (initialTemplate != null) {
          final loc = AppLocalizations.of(context)!;
          _sp.applyPremadeHabitTemplate(
            initialTemplate,
            localizedName: initialTemplate.localizedName(loc),
          );
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = false;
      });
    });
  }

  @override
  void dispose() {
    _statusOverlay.dispose();
    _sp.nameController.removeListener(_nameListener);
    _sp.descController.removeListener(_descListener);
    super.dispose();
  }

  void _setEditInitialValues(StateProvider stateProvider, Habit habit) {
    stateProvider.selectedHabitId = habit.id;
    stateProvider.habitCategoryId = habit.categoryId;
    stateProvider.nameController.text = habit.name;
    stateProvider.descController.text = habit.description;
    stateProvider.habitAmount = habit.amount;
    stateProvider.habitDuration = Duration(minutes: habit.duration);
    stateProvider.selectedHabitTrackingType = habit.trackingType;
    stateProvider.habitAmountLabelController.text = habit.amountLabel;
    stateProvider.setIconPathImmediately(habit.iconPath);
    stateProvider.isOptional = habit.optional;
    stateProvider.timeIntervalEnabled = habit.timeIntervalEnabled;
    stateProvider.timeIntervalStart = habit.timeIntervalStart;
    stateProvider.timeIntervalEnd = habit.timeIntervalEnd;
    stateProvider.setScheduleFromHabit(
      scheduleType: habit.scheduleType,
      weeklyTarget: habit.weeklyTarget,
      monthlyTarget: habit.monthlyTarget,
      customIntervalDays: habit.customIntervalDays,
      selectedDaysAWeek: habit.selectedDaysAWeek,
      selectedDaysAMonth: habit.selectedDaysAMonth,
    );
    stateProvider.habitColorName = habit.colorName;
    stateProvider.habitColor = habit.resolveColor(
      context.read<ThemeProvider>(),
    );
    stateProvider.selectedPremadeHabitType = habit.premadeHabitType;
    stateProvider.setNotificationsFromHabit(
      enabled: habit.notificationsEnabled,
      notificationTimes: habit.notificationTimes,
    );
  }

  bool _sameNotificationTimes(
    List<HabitNotificationTime> a,
    List<HabitNotificationTime> b,
  ) {
    if (a.length != b.length) {
      return false;
    }

    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].minutesOfDay != b[i].minutesOfDay) {
        return false;
      }
    }

    return true;
  }

  bool _hasEditChanges(StateProvider sp, ThemeProvider tp) {
    final habit = widget.habit;
    if (habit == null) {
      return true;
    }

    final changedName = sp.nameController.text.trim() != habit.name;
    final changedDesc = sp.descController.text.trim() != habit.description;
    final changedCategory = sp.habitCategoryId != habit.categoryId;
    final changedDuration = sp.habitDuration.inMinutes != habit.duration;
    final changedAmount = sp.habitAmount != habit.amount;
    final changedTrackingType =
        sp.selectedHabitTrackingType != habit.trackingType;
    final changedOptionalHabit = sp.isOptional != habit.optional;
    final changedIcon = sp.iconPath != habit.iconPath;
    final changedTimeIntervalEnabled =
        sp.timeIntervalEnabled != habit.timeIntervalEnabled;
    final changedTimeIntervalStart =
        sp.timeIntervalStart != habit.timeIntervalStart;
    final changedTimeIntervalEnd = sp.timeIntervalEnd != habit.timeIntervalEnd;
    final changedScheduleType = sp.selectedScheduleOption != habit.scheduleType;
    final changedWeeklyTarget = sp.weeklyTarget != habit.weeklyTarget;
    final changedMonthlyTarget = sp.monthlyTarget != habit.monthlyTarget;
    final changedCustomInterval =
        sp.customIntervalDays != habit.customIntervalDays;
    final changedSelectedWeekDays =
        sp.selectedDaysAWeek.length != habit.selectedDaysAWeek.length ||
        !sp.selectedDaysAWeek.every((d) => habit.selectedDaysAWeek.contains(d));
    final changedSelectedMonthDays =
        sp.selectedDaysAMonth.length != habit.selectedDaysAMonth.length ||
        !sp.selectedDaysAMonth.every(
          (d) => habit.selectedDaysAMonth.contains(d),
        );
    final changedHabitColor =
        sp.getHabitColor(tp) != habit.resolveColor(tp) ||
        sp.habitColorName != habit.colorName;
    final changedPremadeHabitType =
        sp.selectedPremadeHabitType != habit.premadeHabitType;
    final changedNotificationsEnabled =
        sp.habitNotificationsEnabled != habit.notificationsEnabled;
    final changedNotificationTimes =
        !_sameNotificationTimes(
          sp.habitNotificationTimes,
          habit.notificationTimes,
        );

    return changedName ||
        changedDesc ||
        changedCategory ||
        changedDuration ||
        changedAmount ||
        changedTrackingType ||
        changedOptionalHabit ||
        changedIcon ||
        changedTimeIntervalEnabled ||
        changedTimeIntervalStart ||
        changedTimeIntervalEnd ||
        changedScheduleType ||
        changedWeeklyTarget ||
        changedMonthlyTarget ||
        changedCustomInterval ||
        changedSelectedWeekDays ||
        changedSelectedMonthDays ||
        changedHabitColor ||
        changedPremadeHabitType ||
        changedNotificationsEnabled ||
        changedNotificationTimes;
  }

  bool _hasCreateChanges(StateProvider sp) {
    final changedName = sp.nameController.text.trim().isNotEmpty;
    final changedDesc = sp.descController.text.trim().isNotEmpty;
    final changedCategory = sp.habitCategoryId != 1;
    final changedAmount = sp.habitAmount != 0;
    final changedDuration = sp.habitDuration != Duration.zero;
    final changedTrackingType = sp.selectedHabitTrackingType != null;
    final changedAmountLabel =
        sp.habitAmountLabelController.text != AmountLabelPreset.times.plural;
    final changedIcon =
        sp.iconPath.isNotEmpty && sp.iconPath != EmojiService.defaultEmoji;
    final changedOptional = sp.isOptional;
    final changedTimeIntervalEnabled = sp.timeIntervalEnabled;
    final changedTimeIntervalStart = sp.timeIntervalStart != 420;
    final changedTimeIntervalEnd = sp.timeIntervalEnd != 450;
    final changedScheduleType = sp.selectedScheduleOption != ScheduleType.daily;
    final changedWeeklyTarget = sp.weeklyTarget != 1;
    final changedMonthlyTarget = sp.monthlyTarget != 1;
    final changedCustomInterval = sp.customIntervalDays != 2;
    final changedSelectedWeekDays = sp.selectedDaysAWeek.isNotEmpty;
    final changedSelectedMonthDays = sp.selectedDaysAMonth.isNotEmpty;
    final changedColorName = sp.habitColorName != null;
    final changedPremadeHabitType = sp.selectedPremadeHabitType != null;
    final changedNotificationsEnabled = sp.habitNotificationsEnabled;
    final changedNotificationTimes =
        sp.habitNotificationTimes.length != 1 ||
        sp.habitNotificationTimes.first.minutesOfDay != 8 * 60;

    return changedName ||
        changedDesc ||
        changedCategory ||
        changedAmount ||
        changedDuration ||
        changedTrackingType ||
        changedAmountLabel ||
        changedIcon ||
        changedOptional ||
        changedTimeIntervalEnabled ||
        changedTimeIntervalStart ||
        changedTimeIntervalEnd ||
        changedScheduleType ||
        changedWeeklyTarget ||
        changedMonthlyTarget ||
        changedCustomInterval ||
        changedSelectedWeekDays ||
        changedSelectedMonthDays ||
        changedColorName ||
        changedPremadeHabitType ||
        changedNotificationsEnabled ||
        changedNotificationTimes;
  }

  bool _hasUnsavedChanges(StateProvider sp, ThemeProvider tp) {
    if (_isEditMode) {
      return _hasEditChanges(sp, tp);
    }
    return _hasCreateChanges(sp);
  }

  HabitSheetCloseResult get _topBackCloseResult {
    if (_isEditMode) {
      return HabitSheetCloseResult.dismissed;
    }
    return widget.reopenPremadeOnTopBack
        ? HabitSheetCloseResult.reopenPremade
        : HabitSheetCloseResult.dismissed;
  }

  void _popSheet({
    HabitSheetCloseResult result = HabitSheetCloseResult.dismissed,
  }) {
    if (!mounted) {
      return;
    }
    setState(() {
      _allowPop = true;
    });
    Navigator.of(context).pop(result);
  }

  Future<void> _openPremadeHabitSheet(StateProvider sp) async {
    final cp = context.read<ColorProvider>();

    final result = await showModalBottomSheet<PremadeHabitSheetResult>(
      context: context,
      backgroundColor: cp.isDark ? cp.habitBg : cp.bg,
      barrierColor: cp.greyText.darken().withValues(alpha: 0.3),
      isScrollControlled: true,
      builder:
          (_) => PremadeHabitsSheet(
            mode: PremadeHabitSheetMode.editFromHabitSheet,
            selectedPremadeHabitType: sp.selectedPremadeHabitType,
          ),
    );

    if (!mounted || result == null) {
      return;
    }

    if (result.action == PremadeHabitSheetAction.clear) {
      sp.clearSelectedPremadeHabitType();
      return;
    }

    if (result.action != PremadeHabitSheetAction.select ||
        result.template == null) {
      return;
    }

    await _showPremadeOverrideConfirmation(sp, result.template!);
  }

  Future<void> _showPremadeOverrideConfirmation(
    StateProvider sp,
    PremadeHabitTemplate template,
  ) async {
    await showDialogSheet(
      context: context,
      builder:
          (dialogContext) => OverrideCurrentConfigDialog(
            dialogContext: dialogContext,
            template: template,
          ),
    );
  }

  Future<void> _showExitConfirmation(HabitSheetCloseResult closeResult) async {
    if (_isExitDialogOpen) {
      return;
    }

    final loc = AppLocalizations.of(context)!;

    final title = _isEditMode ? loc.exitWithoutSaving : loc.leaveSetup;
    final desc =
        _isEditMode
            ? loc.allChangesYouMadeWillBeDiscarded
            : loc.habitConfigDiscardDesc;

    _isExitDialogOpen = true;
    await showDialogSheet(
      context: context,
      builder:
          (dialogContext) => NewDefaultDialog(
            title: title,
            desc: desc,
            primaryButtonLabel: loc.exit,
            onPrimaryButtonPressed: () {
              Navigator.of(dialogContext).pop();
              _popSheet(result: closeResult);
            },
          ),
    );
    _isExitDialogOpen = false;
  }

  Future<void> _showDeleteNotificationConfirmation(
    StateProvider sp,
    HabitNotificationTime slot,
  ) async {
    await showDialogSheet(
      context: context,
      builder:
          (dialogContext) => DeleteNotificationDialog(
            dialogContext: dialogContext,
            mounted: mounted,
            statusOverlay: _statusOverlay,
            slot: slot,
          ),
    );
  }

  Future<void> _handleCloseAttempt(
    StateProvider sp,
    ThemeProvider tp, {
    HabitSheetCloseResult closeResult = HabitSheetCloseResult.dismissed,
  }) async {
    if (_allowPop || !_hasUnsavedChanges(sp, tp)) {
      _popSheet(result: closeResult);
      return;
    }

    await _showExitConfirmation(closeResult);
  }

  // Fire-and-forget after save: request permission and disable habit notifications
  // on the already-saved habit if the user ultimately denies.
  Future<void> _requestNotificationPermissionOrDisable(
    HabitProvider habitProvider,
    Habit habit,
  ) async {
    final allowed = await NotificationService.areNotificationsAllowed();
    if (allowed) return;

    final lockedBeforeRequest =
        await AwesomeNotifications().shouldShowRationaleToRequest();
    if (lockedBeforeRequest.isNotEmpty) {
      habit.notificationsEnabled = false;
      habitProvider.updateHabit(habit);
      return;
    }

    await AwesomeNotifications().requestPermissionToSendNotifications();

    final allowedAfterRequest =
        await NotificationService.areNotificationsAllowed();
    if (allowedAfterRequest) return;

    habit.notificationsEnabled = false;
    habitProvider.updateHabit(habit);
  }

  Future<void> _saveHabit(StateProvider sp) async {
    if (!mounted) {
      debugPrint("Not mounted, aborting save");
      return;
    }

    final habitProvider = context.read<HabitProvider>();

    if (_isEditMode) {
      final tp = context.read<ThemeProvider>();
      final habit = widget.habit!;

      habit.amount = sp.habitAmount;
      habit.duration = sp.habitDuration.inMinutes;
      habit.trackingType = sp.selectedHabitTrackingType;
      habit.name = sp.nameController.text;
      habit.description = sp.descController.text;
      habit.categoryId = sp.habitCategoryId;
      habit.amountLabel = sp.habitAmountLabelController.text;
      habit.iconPath = sp.iconPath;
      habit.optional = sp.isOptional;
      habit.timeIntervalEnabled = sp.timeIntervalEnabled;
      habit.timeIntervalStart = sp.timeIntervalStart;
      habit.timeIntervalEnd = sp.timeIntervalEnd;
      habit.scheduleType = sp.selectedScheduleOption;
      habit.weeklyTarget = sp.weeklyTarget;
      habit.monthlyTarget = sp.monthlyTarget;
      habit.customIntervalDays = sp.customIntervalDays;
      habit.selectedDaysAWeek = sp.selectedDaysAWeek.toList()..sort();
      habit.selectedDaysAMonth = sp.selectedDaysAMonth.toList()..sort();
      habit.premadeHabitType = sp.selectedPremadeHabitType;
      habit.notificationsEnabled = sp.habitNotificationsEnabled;
      habit.notificationTimes =
          sp.habitNotificationTimes.map((slot) => slot.copy()).toList();

      if (habit.scheduleType == ScheduleType.custom) {
        habit.customAppearance = buildCustomAppearance(
          habit.customIntervalDays,
        );
        habit.lastCustomUpdate = DateTime.now().toUtc();
      }

      habit.colorName = sp.habitColorName;
      habit.color = colorToHex(sp.getHabitColor(tp) ?? tp.primaryColor);

      habitProvider.updateHabit(habit);
      sp.alertText = "Changes saved";
      sp.toggleAlert(show: true);
      if (mounted) {
        _popSheet(result: HabitSheetCloseResult.saved);
      }
      if (habit.notificationsEnabled) {
        _requestNotificationPermissionOrDisable(habitProvider, habit);
      }
      return;
    }

    final loc = AppLocalizations.of(context)!;

    final newHabit = Habit(
      id: getUniqueId(),
      name: sp.nameController.text,
      description: sp.descController.text,
      iconPath: sp.iconPath,
      categoryId: sp.habitCategoryId,
      tag: loc.noTag,
      completed: false,
      skipped: false,
      amount: sp.habitAmount,
      amountLabel: sp.habitAmountLabelController.text,
      amountCompleted: 0,
      duration: sp.habitDuration.inMinutes,
      trackingType: sp.selectedHabitTrackingType,
      durationCompleted: 0,
      streak: 0,
      longestStreak: 0,
      optional: sp.isOptional,
      timeIntervalEnabled: sp.timeIntervalEnabled,
      timeIntervalStart: sp.timeIntervalStart,
      timeIntervalEnd: sp.timeIntervalEnd,
      scheduleType: sp.selectedScheduleOption,
      weeklyTarget: sp.weeklyTarget,
      monthlyTarget: sp.monthlyTarget,
      customIntervalDays: sp.customIntervalDays,
      selectedDaysAWeek: sp.selectedDaysAWeek.toList()..sort(),
      selectedDaysAMonth: sp.selectedDaysAMonth.toList()..sort(),
      customAppearance: buildCustomAppearance(sp.customIntervalDays),
      timesCompletedThisWeek: 0,
      timesCompletedThisMonth: 0,
      createdAt: DateTime.now().toUtc(),
      lastCustomUpdate: DateTime.now().toUtc(),
      colorName: sp.habitColorName,
      notificationsEnabled: sp.habitNotificationsEnabled,
      notificationTimes:
          sp.habitNotificationTimes.map((slot) => slot.copy()).toList(),
      premadeHabitType: sp.selectedPremadeHabitType,
    );

    habitProvider.addHabit(newHabit);

    if (mounted) {
      _popSheet(result: HabitSheetCloseResult.saved);
    }
    if (newHabit.notificationsEnabled) {
      _requestNotificationPermissionOrDisable(habitProvider, newHabit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StateProvider>();
    final tp = context.watch<ThemeProvider>();
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    final hasName = sp.nameController.text.trim().isNotEmpty;
    final canSave =
        !_isInitializing &&
        hasName &&
        (!_isEditMode || _hasEditChanges(sp, tp));
    final hasUnsavedChanges = !_isInitializing && _hasUnsavedChanges(sp, tp);

    final maxSheetHeight = mediaQuery.size.height - 59 - 16;
    // viewInsets.bottom tracks keyboard per-frame; padding.bottom is safe area
    // (on iOS, safe area collapses to 0 when keyboard is shown, so summing both is correct)
    final bottomInset = keyboardInset + mediaQuery.padding.bottom;

    return PopScope(
      canPop: _allowPop || !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        await _handleCloseAttempt(
          sp,
          tp,
          closeResult: HabitSheetCloseResult.dismissed,
        );
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: GestureDetector(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: SingleChildScrollView(
              controller: scrollController,
              child: Container(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    topSection(context, cp, sp, tp, canSave),
                    Padding(
                      padding: EdgeInsets.only(left: 16, right: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 20,
                        children: [
                          chooseIcon(cp, sp, context),
                          habitDetails(cp),
                          habitScheduling(cp),
                          habitTypeRow(cp, sp),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Column(
                        children: [
                          optionalHabitCheck(cp, sp),
                          Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: notificationSection(cp, sp),
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
      ),
    );
  }

  Row optionalHabitCheck(ColorProvider cp, StateProvider sp) {
    final loc = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          loc.optionalHabit,
          style: TextStyle(
            color: cp.text,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap:
              () => setState(() {
                sp.isOptional = !sp.isOptional;
              }),
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: AnimatedCheckbox(
              value: sp.isOptional,
              onChanged: (value) {
                setState(() {
                  sp.isOptional = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openNotificationTimeDialog(
    StateProvider sp,
    HabitNotificationTime slot,
  ) async {
    await showNotificationTimeDialog(
      initialMinutes: slot.minutesOfDay,
      onTimeSelected: (minutesOfDay) {
        sp.updateHabitNotificationTime(slot.id, minutesOfDay);
      },
      isNew: false,
      context: context,
    );
  }

  Future<void> _openAddNotificationTimeDialog(StateProvider sp) async {
    final notificationTimes = sp.habitNotificationTimes;
    final initialMinutes =
        notificationTimes.isNotEmpty
            ? notificationTimes.last.minutesOfDay
            : 9 * 60;

    await showNotificationTimeDialog(
      isNew: true,
      initialMinutes: initialMinutes,
      onTimeSelected: (minutesOfDay) {
        sp.addHabitNotificationTime(minutesOfDay: minutesOfDay);
      },
      context: context,
    );
  }

  Widget notificationSection(ColorProvider cp, StateProvider sp) {
    final loc = AppLocalizations.of(context)!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cp.field,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              spacing: 10,
              children: [
                Container(
                  width: 46,
                  padding: const EdgeInsets.all(13),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: cp.orange100,
                    shape: BoxShape.circle,
                    border: Border.all(color: cp.orange200, width: 1),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      "assets/images/new-svg/notifications.svg",
                      colorFilter: ColorFilter.mode(
                        cp.orange300,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: Column(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.notifications,
                        style: TextStyle(
                          color: cp.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        loc.getRemindedAboutYourHabit,
                        style: TextStyle(color: cp.lightGreyText, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                NewDefaultSwitch(
                  value: sp.habitNotificationsEnabled,
                  onChanged: (value) async {
                    sp.habitNotificationsEnabled = value;
                    if (value) {
                      await Future.delayed(const Duration(milliseconds: 300));
                      scrollController.animateTo(
                        scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.decelerate,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder:
                (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(sizeFactor: animation, child: child),
                ),
            child:
                sp.habitNotificationsEnabled
                    ? Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        key: const ValueKey('notifications-expanded'),
                        spacing: 10,
                        children: [
                          ...sp.habitNotificationTimes.map(
                            (slot) => NotificationTimeRow(
                              onOpenTimeDialog: () async {
                                await _openNotificationTimeDialog(sp, slot);
                              },
                              onTimeSelected: (minutesOfDay) {
                                sp.updateHabitNotificationTime(
                                  slot.id,
                                  minutesOfDay,
                                );
                              },
                              isHabit: true,
                              minutesOfDay: slot.minutesOfDay,
                              onTapDown: () {
                                setState(() {
                                  heldNotificationId = slot.id;
                                });
                              },
                              onTapUp: () {
                                setState(() {
                                  heldNotificationId = null;
                                });
                              },
                              onTapCancel: () {
                                setState(() {
                                  heldNotificationId = null;
                                });
                              },
                              onLongPress: () async {
                                if (sp.habitNotificationTimes.length <= 1) {
                                  _statusOverlay.show(
                                    context: context,
                                    cp: cp,
                                    title: loc.thisNotificationCantBeDeleted,
                                    isError: true,
                                  );
                                  setState(() {
                                    heldNotificationId = null;
                                  });
                                  return;
                                }

                                await _showDeleteNotificationConfirmation(
                                  sp,
                                  slot,
                                );
                                if (!mounted) {
                                  return;
                                }
                                setState(() {
                                  heldNotificationId = null;
                                });
                              },
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                            child: NewDefaultButton.secondary(
                              width: double.infinity,
                              height: 40,
                              label: loc.addANotification,
                              prefix: SvgPicture.asset(
                                "assets/images/new-svg/add.svg",
                                colorFilter: ColorFilter.mode(
                                  cp.text,
                                  BlendMode.srcIn,
                                ),
                              ),
                              onPressed: () async {
                                await _openAddNotificationTimeDialog(sp);
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                    : const SizedBox.shrink(key: ValueKey('notifications-off')),
          ),
        ],
      ),
    );
  }

  Row habitTypeRow(ColorProvider cp, StateProvider sp) {
    final selectedType = sp.selectedPremadeHabitType;
    final selectedTemplate =
        selectedType == null ? null : PremadeHabitCatalog.byType(selectedType);
    final loc = AppLocalizations.of(context)!;
    final label = selectedTemplate?.localizedName(loc) ?? loc.select;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          loc.habitType,
          style: TextStyle(
            color: cp.text,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        NewDefaultButton(
          height: 46,
          color: cp.field,
          textColor: cp.text,
          isGradient: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          onPressed: () async {
            await _openPremadeHabitSheet(sp);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              if (selectedTemplate != null)
                TextIcon(selectedTemplate.iconPath, size: 24),
              Text(label, style: TextStyle(color: cp.text, fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Column habitScheduling(ColorProvider cp) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            loc.schedule,
            style: TextStyle(
              color: cp.text,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SelectHabitScheduleType(),
        SelectHabitTypeWidgets(),
      ],
    );
  }

  Column habitDetails(ColorProvider cp) {
    final sp = context.read<StateProvider>();
    final habitNameController = sp.nameController;
    final habitNotesController = sp.descController;
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            loc.habitDetails,
            style: TextStyle(
              color: cp.text,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        NewDefaultTextField(
          title: loc.habitName,
          hint: loc.habitName,
          controller: habitNameController,
        ),
        NewDefaultTextField(
          title: loc.notes,
          maxLines: 4,
          controller: habitNotesController,
        ),

        SelectHabitDayPeriod(),
      ],
    );
  }

  Column chooseIcon(ColorProvider cp, StateProvider sp, BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      spacing: 20,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.chooseIcon,
          style: TextStyle(
            color: cp.text,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        NewDefaultButton(
          onPressed: () async {
            final emoji = await showEmojiKeyboardDialog(context, cp);
            if (emoji != null && context.mounted) {
              sp.iconPath = emoji;
            }
          },
          width: 84,
          height: 84,
          color: cp.field,
          padding: EdgeInsets.all(20),
          child: TextIcon(sp.iconPath.isEmpty ? "🏀" : sp.iconPath, size: 44),
        ),
      ],
    );
  }

  Padding topSection(
    BuildContext context,
    ColorProvider cp,
    StateProvider sp,
    ThemeProvider tp,
    bool canSave,
  ) {
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
                  _handleCloseAttempt(sp, tp, closeResult: _topBackCloseResult);
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
                child: NewDefaultButton.primarySmall(
                  width: null,
                  enabled: canSave,
                  onPressed: () async {
                    if (!canSave) {
                      return;
                    }
                    await _saveHabit(sp);
                  },
                  label: loc.save,
                ),
              ),
            ],
          ),
          Center(
            child: Text(
              _isEditMode ? loc.editHabit : loc.newHabit,
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

int getUniqueId() {
  final now = DateTime.now();
  final timeComponent = now.millisecondsSinceEpoch;
  final random = Random().nextInt(1000);
  return timeComponent * 1000 + random;
}

List<String> buildCustomAppearance(int intervalDays) {
  final start = DateTime.now();
  final anchor = DateTime(start.year, start.month, start.day);
  final output = <String>[];
  for (int i = 0; i < 180; i += intervalDays) {
    output.add(
      anchor.add(Duration(days: i)).toIso8601String().split('T').first,
    );
  }
  return output;
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/models/notification.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/notifications_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/new_default_switch.dart';
import 'package:habitt/widgets/notification/notification_card.dart';
import 'package:provider/provider.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _isInitialized = false;
  bool _isSaving = false;
  bool _isExitDialogOpen = false;

  late bool _draftMasterEnabled;
  late bool _draftPeriodEnabled;
  late bool _draftHabitsEnabled;
  final Map<NotificationPeriod, NotificationSettings> _draftSettings = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) {
      return;
    }

    final np = context.read<NotificationsProvider>();
    _draftMasterEnabled = np.isMasterEnabled;
    _draftPeriodEnabled = np.arePeriodNotificationsEnabled;
    _draftHabitsEnabled = np.areHabitNotificationsEnabled;
    for (final period in NotificationPeriod.values) {
      _draftSettings[period] = np.getSettings(period);
    }
    _isInitialized = true;
  }

  bool _sameWeekdays(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b) && b.containsAll(a);
  }

  bool _settingsEqual(NotificationSettings a, NotificationSettings b) {
    return a.enabled == b.enabled &&
        a.time.hour == b.time.hour &&
        a.time.minute == b.time.minute &&
        _sameWeekdays(a.weekdays, b.weekdays);
  }

  bool _hasUnsavedChanges(NotificationsProvider np) {
    if (!_isInitialized) {
      return false;
    }

    if (_draftMasterEnabled != np.isMasterEnabled ||
        _draftPeriodEnabled != np.arePeriodNotificationsEnabled ||
        _draftHabitsEnabled != np.areHabitNotificationsEnabled) {
      return true;
    }

    for (final period in NotificationPeriod.values) {
      final draft = _draftSettings[period];
      if (draft == null) {
        continue;
      }
      final live = np.getSettings(period);
      if (!_settingsEqual(draft, live)) {
        return true;
      }
    }

    return false;
  }

  Set<NotificationPeriod> _changedPeriods(NotificationsProvider np) {
    final changed = <NotificationPeriod>{};
    for (final period in NotificationPeriod.values) {
      final draft = _draftSettings[period];
      if (draft == null) {
        continue;
      }
      if (!_settingsEqual(draft, np.getSettings(period))) {
        changed.add(period);
      }
    }
    return changed;
  }

  void _updatePeriod(
    NotificationPeriod period,
    NotificationSettings newSettings,
  ) {
    setState(() {
      _draftSettings[period] = newSettings;
    });
  }

  void _handleToggle(NotificationPeriod period, bool enabled) {
    final current = _draftSettings[period]!;
    _updatePeriod(period, current.copyWith(enabled: enabled));
  }

  void _handleTime(NotificationPeriod period, TimeOfDay time) {
    final current = _draftSettings[period]!;
    _updatePeriod(period, current.copyWith(time: time));
  }

  void _handleWeekday(NotificationPeriod period, int weekday) {
    final current = _draftSettings[period]!;
    final next = Set<int>.from(current.weekdays);
    if (next.contains(weekday)) {
      next.remove(weekday);
      if (next.isEmpty) {
        return;
      }
    } else {
      next.add(weekday);
    }
    _updatePeriod(period, current.copyWith(weekdays: next));
  }

  Future<void> _saveChanges(NotificationsProvider np) async {
    if (_isSaving) {
      return;
    }

    final hasChanges = _hasUnsavedChanges(np);
    if (!hasChanges) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final habitProvider = context.read<HabitProvider>();

    final togglesApplied = await np.applyGlobalToggles(
      context: context,
      masterEnabled: _draftMasterEnabled,
      periodsEnabled: _draftPeriodEnabled,
      habitsEnabled: _draftHabitsEnabled,
      habits: habitProvider.habits,
      appearsOnDay: habitProvider.appearsOnDay,
    );

    if (togglesApplied) {
      final changedPeriods = _changedPeriods(np);
      for (final period in changedPeriods) {
        final draft = _draftSettings[period];
        if (draft == null) {
          continue;
        }
        await np.setSettings(period, draft);
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });
  }

  Future<void> _showExitConfirmation() async {
    if (_isExitDialogOpen) {
      return;
    }

    _isExitDialogOpen = true;
    await showDialogSheet(
      context: context,
      builder:
          (dialogContext) => NewDefaultDialog(
            title: "Exit without saving?",
            desc: "All changes you made will be discarded.",
            primaryButtonLabel: "Exit",
            onPrimaryButtonPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
          ),
    );
    _isExitDialogOpen = false;
  }

  Future<void> _handleCloseAttempt(NotificationsProvider np) async {
    if (!_hasUnsavedChanges(np)) {
      Navigator.of(context).pop();
      return;
    }

    await _showExitConfirmation();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final np = context.watch<NotificationsProvider>();
    final hasUnsavedChanges = _hasUnsavedChanges(np);

    return PopScope(
      canPop: !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        await _handleCloseAttempt(np);
      },
      child: Scaffold(
        body: ListView(
          children: [
            _topBar(cp, np, hasUnsavedChanges),
            SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      Text(
                        'Notifications',
                        textAlign: TextAlign.start,
                        style: TextStyle(color: cp.lightGreyText, fontSize: 16),
                      ),
                      AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: ShapeDecoration(
                          color: cp.isDark ? cp.habitBg : cp.bg,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 1, color: cp.border),
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 32,
                              color: Colors.transparent,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'All notifications',
                                    style: TextStyle(
                                      color: cp.text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  NewDefaultSwitch(
                                    value: _draftMasterEnabled,
                                    onChanged: (value) {
                                      setState(() {
                                        _draftMasterEnabled = value;
                                      });

                                      if (!value) {
                                        setState(() {
                                          _draftPeriodEnabled = false;
                                          _draftHabitsEnabled = false;
                                          for (final p
                                              in NotificationPeriod.values) {
                                            final cur = _draftSettings[p];
                                            if (cur != null && cur.enabled) {
                                              _draftSettings[p] = cur.copyWith(
                                                enabled: false,
                                              );
                                            }
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),

                            Divider(color: cp.border, height: 32),
                            Container(
                              height: 32,
                              color: Colors.transparent,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Habit notifications',
                                    style: TextStyle(
                                      color: cp.text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  NewDefaultSwitch(
                                    value: _draftHabitsEnabled,
                                    onChanged: (value) {
                                      setState(() {
                                        _draftHabitsEnabled = value;
                                      });

                                      if (value) {
                                        setState(() {
                                          _draftMasterEnabled = true;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Divider(color: cp.border, height: 32),
                            Container(
                              height: 32,
                              color: Colors.transparent,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Daily reminders',
                                    style: TextStyle(
                                      color: cp.text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  NewDefaultSwitch(
                                    value: _draftPeriodEnabled,
                                    onChanged: (value) {
                                      setState(() {
                                        _draftPeriodEnabled = value;

                                        // If the user disables daily reminders, reflect
                                        // that immediately in the local draft state
                                        // by disabling all period drafts so the UI
                                        // matches the toggle.
                                        if (value) {
                                          setState(() {
                                            _draftMasterEnabled = true;
                                          });
                                        } else if (!value) {
                                          for (final p
                                              in NotificationPeriod.values) {
                                            final cur = _draftSettings[p];
                                            if (cur != null && cur.enabled) {
                                              _draftSettings[p] = cur.copyWith(
                                                enabled: false,
                                              );
                                            }
                                          }
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      Text(
                        'Daily reminders',
                        textAlign: TextAlign.start,
                        style: TextStyle(color: cp.lightGreyText, fontSize: 16),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder:
                            (child, animation) => FadeTransition(
                              opacity: animation,
                              child: SizeTransition(
                                sizeFactor: animation,
                                child: child,
                              ),
                            ),
                        child: Column(
                          key: const ValueKey('notifications-expanded'),
                          spacing: 12,
                          children: [
                            NotificationCard(
                              period: NotificationPeriod.morning,
                              settings:
                                  _draftSettings[NotificationPeriod.morning],
                              enabled:
                                  _draftMasterEnabled &&
                                  _draftPeriodEnabled &&
                                  (_draftSettings[NotificationPeriod.morning]
                                          ?.enabled ??
                                      false),
                              onToggleEnabled:
                                  (enabled) => _handleToggle(
                                    NotificationPeriod.morning,
                                    enabled,
                                  ),
                              onTimeChanged:
                                  (time) => _handleTime(
                                    NotificationPeriod.morning,
                                    time,
                                  ),
                              onWeekdayToggled:
                                  (weekday) => _handleWeekday(
                                    NotificationPeriod.morning,
                                    weekday,
                                  ),
                            ),
                            NotificationCard(
                              period: NotificationPeriod.midday,
                              settings:
                                  _draftSettings[NotificationPeriod.midday],
                              enabled:
                                  _draftMasterEnabled &&
                                  _draftPeriodEnabled &&
                                  (_draftSettings[NotificationPeriod.midday]
                                          ?.enabled ??
                                      false),
                              onToggleEnabled:
                                  (enabled) => _handleToggle(
                                    NotificationPeriod.midday,
                                    enabled,
                                  ),
                              onTimeChanged:
                                  (time) => _handleTime(
                                    NotificationPeriod.midday,
                                    time,
                                  ),
                              onWeekdayToggled:
                                  (weekday) => _handleWeekday(
                                    NotificationPeriod.midday,
                                    weekday,
                                  ),
                            ),
                            NotificationCard(
                              period: NotificationPeriod.wrapUp,
                              settings:
                                  _draftSettings[NotificationPeriod.wrapUp],
                              enabled:
                                  _draftMasterEnabled &&
                                  _draftPeriodEnabled &&
                                  (_draftSettings[NotificationPeriod.wrapUp]
                                          ?.enabled ??
                                      false),
                              onToggleEnabled:
                                  (enabled) => _handleToggle(
                                    NotificationPeriod.wrapUp,
                                    enabled,
                                  ),
                              onTimeChanged:
                                  (time) => _handleTime(
                                    NotificationPeriod.wrapUp,
                                    time,
                                  ),
                              onWeekdayToggled:
                                  (weekday) => _handleWeekday(
                                    NotificationPeriod.wrapUp,
                                    weekday,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(
    ColorProvider cp,
    NotificationsProvider np,
    bool hasUnsavedChanges,
  ) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              await _handleCloseAttempt(np);
            },
            child: Container(
              padding: const EdgeInsets.only(left: 16),
              color: Colors.transparent,
              height: 36,
              width: 76,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SvgPicture.asset(
                  "assets/images/new-svg/back.svg",
                  colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Notification Settings',
                style: TextStyle(
                  color: cp.text,
                  fontSize: 34 / 1.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder:
                (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
            child:
                hasUnsavedChanges || _isSaving
                    ? Padding(
                      key: const ValueKey('save-visible'),
                      padding: const EdgeInsets.only(right: 16.0),
                      child: NewDefaultButton.primarySmall(
                        width: 60,
                        padding:
                            _isSaving
                                ? EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 22,
                                )
                                : EdgeInsets.zero,
                        enabled: !_isSaving,
                        isLoading: _isSaving,
                        onPressed: () async {
                          await _saveChanges(np);
                        },
                        label: 'Save',
                      ),
                    )
                    : SizedBox(key: ValueKey('save-hidden'), width: 76),
          ),
        ],
      ),
    );
  }
}
